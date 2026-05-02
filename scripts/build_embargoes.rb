#!/usr/bin/env ruby
# build_embargoes.rb — Sealed commits for embargoed posts.
#
# For every post carrying `embargo_until` or `embargo_block` in frontmatter,
# compute a SHA-256 over the post's source markdown (frontmatter + body)
# and write it to `_data/embargoes.yml`. The post layout reads this map
# and either:
#   · pre-deadline: renders the seal (title + author + intent + sha256)
#                   and suppresses the body;
#   · post-deadline: renders the full body plus a small "Embargo lifted"
#                   ribbon linking back to the original sealed sha so any
#                   reader can verify the article matches the seal.
#
# The seal is computed against the *current* source. To use the seal as
# a real precommitment, an author commits the embargoed source first
# (with empty/placeholder content if needed), captures the resulting
# sha from the build artefact, and publishes the sha out of band before
# the lift date. After lift, the same script run produces the same sha
# only if the body has not been altered.

require 'digest'
require 'yaml'
require 'time'
require 'fileutils'
require 'open3'

# Resolve the git commit that first introduced a path on the current
# branch. This is the durable provenance anchor for the seal: the
# sealed sha-256 was computed over the bytes that landed in *that*
# commit. We surface the commit + a blob URL in `_data/embargoes.yml`
# so the post-lift ribbon can link directly to the immutable artefact
# (`<repo>/blob/<sha>/_posts/...md`) — readers no longer have to take
# our word for which version was sealed.
def first_commit_for(path)
  out, status = Open3.capture2('git', '-C', ROOT, 'log',
                               '--diff-filter=A', '--follow',
                               '--pretty=format:%H', '--', path)
  return nil unless status.success?
  sha = out.strip.lines.last
  sha && !sha.empty? ? sha.strip : nil
rescue Errno::ENOENT
  nil
end

ROOT  = File.expand_path('..', __dir__)
POSTS = File.join(ROOT, '_posts')
DATA  = File.join(ROOT, '_data', 'embargoes.yml')
META  = File.join(ROOT, '_data', 'embargoes-meta.yml')

FileUtils.mkdir_p(File.dirname(DATA))

def slug_for(filename)
  File.basename(filename, '.md').sub(/\A\d{4}-\d{2}-\d{2}-/, '')
end

def parse_frontmatter(text)
  # naive but sufficient: leading --- ... --- block, YAML-loaded.
  return {} unless text.start_with?("---\n") || text.start_with?("---\r\n")
  m = text.match(/\A---\s*\n(.*?\n)---\s*\n/m)
  return {} unless m
  YAML.safe_load(m[1], permitted_classes: [Time, Date, Symbol]) || {}
rescue Psych::SyntaxError
  {}
end

# Load any existing seals so first-generated values are preserved across
# runs. The seal is a *precommitment* — once we publish a sha-256, the
# value is meant to be immutable for the lifetime of the embargo. If
# an author edits the post mid-embargo (typo fix, broken-link patch),
# subsequent runs MUST keep the original sealed sha so verifiers can
# detect the drift. We track the live sha separately as `current_sha256`
# and surface a `tampered: true` flag when the two diverge — that's
# what makes the seal trustworthy rather than just a build artefact.
existing = {}
if File.exist?(DATA)
  loaded = YAML.safe_load(File.read(DATA),
                          permitted_classes: [Time, Date, Symbol]) || {}
  existing = loaded.is_a?(Hash) ? loaded : {}
end

records = {}

Dir[File.join(POSTS, '*.md')].sort.each do |path|
  body = File.binread(path)
  fm   = parse_frontmatter(body)
  next unless fm['embargo_until'] || fm['embargo_block']

  slug = slug_for(path)
  sha  = Digest::SHA256.hexdigest(body)

  embargo_until = fm['embargo_until']
  embargo_until = embargo_until.iso8601 if embargo_until.respond_to?(:iso8601)

  rel_path = path.sub("#{ROOT}/", '')
  prior    = existing[slug] || {}

  # First-seen wins for every immutable field. The current frontmatter
  # supplies `embargo_until` / `embargo_block` only as a fallback when
  # this is the first run; once sealed, the deadline is part of the
  # precommitment and is not mutable from frontmatter.
  sealed_sha    = prior['source_sha256'] || sha
  sealed_at     = prior['sealed_at']     || Time.now.utc.iso8601
  sealed_commit = prior['sealed_commit'] || first_commit_for(rel_path)
  sealed_path   = prior['sealed_path']   || rel_path
  sealed_until  = prior['embargo_until'] || embargo_until
  sealed_block  = prior['embargo_block'] || fm['embargo_block']
  sealed_intent = prior['intent_statement'] || fm['intent_statement']
  sealed_bytes  = prior['source_bytes']     || body.bytesize

  records[slug] = {
    'source_sha256'    => sealed_sha,
    'embargo_until'    => sealed_until,
    'embargo_block'    => sealed_block,
    'intent_statement' => sealed_intent,
    'sealed_at'        => sealed_at,
    'source_bytes'     => sealed_bytes,
    # Provenance anchor for the post-lift ribbon. The path is repo-relative
    # so the layout can interpolate `site.github.repository_url` against it.
    'sealed_commit'    => sealed_commit,
    'sealed_path'      => sealed_path,
    # Drift signal: live sha and a tamper flag set when the current
    # source no longer hashes to the sealed value. The post layout
    # surfaces this in the lifted ribbon so readers can see the seal
    # was broken even though the article is now public.
    'current_sha256'   => sha,
    'tampered'         => sealed_sha != sha
  }.compact
end

File.write(DATA, records.sort.to_h.to_yaml)
File.write(META, {
  'generated_at' => Time.now.utc.iso8601,
  'embargoed'    => records.size
}.to_yaml)

puts "[build_embargoes] #{records.size} embargoed posts sealed"
