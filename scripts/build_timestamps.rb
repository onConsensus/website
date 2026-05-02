#!/usr/bin/env ruby
# build_timestamps.rb — OpenTimestamps anchoring for every published post.
#
# Done responsibility:
#   1. Walk `_posts/`, compute SHA-256 over the source markdown of each post.
#   2. Ensure a sidecar proof exists at `timestamps/<slug>.ots`. If the
#      `ots` CLI from `opentimestamps-client` is on PATH and no proof is
#      present, run `ots stamp <hash>` so CI generates a fresh attestation.
#      Local sandboxes without `ots` installed simply skip the call — the
#      sha + the absence of an .ots is recorded faithfully.
#   3. If a proof is present and `ots verify` returns a Bitcoin block, parse
#      the block height + UTC attestation timestamp out of stderr.
#   4. Write `_data/timestamps.yml` mapping post slug to:
#        sha256, ots_path, ots_present (bool), block_height (int|nil),
#        attested_at (iso|nil), status (verified|pending|unstamped).
#
# Output is always deterministic and side-effect-free at the Liquid layer.
# The article footer reads `site.data.timestamps[page.slug]` and renders
# whatever level of attestation is currently available.

require 'digest'
require 'yaml'
require 'open3'
require 'time'
require 'fileutils'

ROOT  = File.expand_path('..', __dir__)
POSTS = File.join(ROOT, '_posts')
OUT   = File.join(ROOT, 'timestamps')
DATA  = File.join(ROOT, '_data', 'timestamps.yml')
META  = File.join(ROOT, '_data', 'timestamps-meta.yml')

FileUtils.mkdir_p(OUT)
FileUtils.mkdir_p(File.dirname(DATA))

def have_ots?
  out, _ = Open3.capture2('which', 'ots')
  !out.strip.empty?
rescue Errno::ENOENT
  false
end

def slug_for(filename)
  # _posts/<YYYY-MM-DD>-<slug>.md → <slug>
  base = File.basename(filename, '.md')
  base.sub(/\A\d{4}-\d{2}-\d{2}-/, '')
end

def parse_verify(stderr)
  # `ots verify` prints something like:
  #   Got 1 attestation(s) from https://btc.calendar.catallaxy.com
  #   Success! Bitcoin block 887412 attests existence as of 2026-04-01 UTC
  block = stderr[/Bitcoin block (\d+)/, 1]
  ts    = stderr[/as of (\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}(?::\d{2})?)?)/, 1]
  [
    block ? block.to_i : nil,
    ts ? "#{ts.tr(' ', 'T')}Z".sub(/Z+\z/, 'Z') : nil
  ]
end

ots_available = have_ots?
records = {}
stamped = 0
verified = 0

Dir[File.join(POSTS, '*.md')].sort.each do |path|
  slug = slug_for(path)
  body = File.binread(path)
  sha  = Digest::SHA256.hexdigest(body)

  # We keep the canonical proof adjacent to its source (`_posts/<file>.md.ots`)
  # so `ots upgrade <file>.md.ots` from the dedicated `timestamps`
  # workflow can refresh it as Bitcoin confirms calendar attestations.
  # We additionally publish a copy at `timestamps/<slug>.ots` for
  # public download — that path is what `_data/timestamps.yml` exposes
  # to the post footer and to `/verify/`.
  ots_src    = "#{path}.ots"          # canonical, lives next to the .md
  ots_public = File.join(OUT, "#{slug}.ots")

  if !File.exist?(ots_src) && ots_available
    out, status = Open3.capture2e('ots', 'stamp', path)
    if status.success?
      stamped += 1
    else
      warn "[build_timestamps] ots stamp failed for #{slug}: #{out.lines.last}"
    end
  end

  # Mirror the canonical proof into the public download tree on every
  # run so upgrades that the timestamps workflow has applied
  # (`ots upgrade _posts/*.md.ots`) reach `/timestamps/<slug>.ots`.
  if File.exist?(ots_src)
    FileUtils.cp(ots_src, ots_public) unless \
      File.exist?(ots_public) && FileUtils.identical?(ots_src, ots_public)
  end

  block_height = nil
  attested_at  = nil
  status_label = 'unstamped'

  if File.exist?(ots_src)
    status_label = 'pending'
    if ots_available
      _stdout, stderr, st = Open3.capture3('ots', 'verify', ots_src, '-f', path)
      if st.success?
        block_height, attested_at = parse_verify(stderr)
        status_label = block_height ? 'verified' : 'pending'
        verified += 1 if block_height
      end
    end
  end

  records[slug] = {
    'sha256'       => sha,
    'ots_path'     => "/timestamps/#{slug}.ots",
    'ots_present'  => File.exist?(ots_public),
    'block_height' => block_height,
    'attested_at'  => attested_at,
    'status'       => status_label
  }
end

File.write(DATA, records.sort.to_h.to_yaml)
File.write(META, {
  'generated_at'   => Time.now.utc.iso8601,
  'ots_available'  => ots_available,
  'posts'          => records.size,
  'stamped_now'    => stamped,
  'verified'       => verified
}.to_yaml)

puts "[build_timestamps] #{records.size} posts; ots_available=#{ots_available}; " \
     "newly stamped=#{stamped}; verified=#{verified}"
