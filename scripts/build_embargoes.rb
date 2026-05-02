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

records = {}

Dir[File.join(POSTS, '*.md')].sort.each do |path|
  body = File.binread(path)
  fm   = parse_frontmatter(body)
  next unless fm['embargo_until'] || fm['embargo_block']

  slug = slug_for(path)
  sha  = Digest::SHA256.hexdigest(body)

  embargo_until = fm['embargo_until']
  embargo_until = embargo_until.iso8601 if embargo_until.respond_to?(:iso8601)

  records[slug] = {
    'source_sha256'    => sha,
    'embargo_until'    => embargo_until,
    'embargo_block'    => fm['embargo_block'],
    'intent_statement' => fm['intent_statement'],
    'sealed_at'        => Time.now.utc.iso8601,
    'source_bytes'     => body.bytesize
  }.compact
end

File.write(DATA, records.sort.to_h.to_yaml)
File.write(META, {
  'generated_at' => Time.now.utc.iso8601,
  'embargoed'    => records.size
}.to_yaml)

puts "[build_embargoes] #{records.size} embargoed posts sealed"
