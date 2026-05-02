#!/usr/bin/env ruby
# assert_embargo.rb — CI guardrail for embargoed posts.
#
# Run after `jekyll build` against the produced `_site/` tree. For every
# post listed in `_data/embargoes.yml` whose deadline has not yet passed,
# this script asserts:
#
#   1. The rendered post page exists.
#   2. The page carries `class="article article--embargoed"` on the
#      <article> tag — i.e. the layout's gating branch fired.
#   3. The page contains an `<aside class="embargo-seal">` block.
#   4. The page does NOT contain the post's <article class="article__body">
#      div, the methodology appendix, or the PGP signature block. These
#      are the three slots that hold the embargoed substance; their
#      presence in the HTML would mean the seal failed.
#   5. The post's slug does not appear in `/_site/atom.xml`,
#      `/_site/feed.json`, or `/_site/search.json`.
#
# Conversely, for every post in `_data/embargoes.yml` whose gates have
# all passed, we assert the inverse — body present, seal absent, post
# present in feeds — so a failed predicate in `_includes/visible-posts.html`
# can't silently keep a post hidden after lift.
#
# Exits non-zero on any assertion failure, with a tight diff-friendly
# error message naming the failing slug and surface.

require 'yaml'
require 'time'

site = ARGV[0] || '_site'
abort "[assert_embargo] no _site at #{site}" unless Dir.exist?(site)

data_path = File.join(File.expand_path('..', __dir__), '_data', 'embargoes.yml')
unless File.exist?(data_path)
  puts '[assert_embargo] _data/embargoes.yml absent; nothing to assert'
  exit 0
end

embargoes = YAML.safe_load(File.read(data_path),
                           permitted_classes: [Time, Date, Symbol]) || {}

bitcoin_path = File.join(File.expand_path('..', __dir__), '_data', 'bitcoin.yml')
tip = (File.exist?(bitcoin_path) ? YAML.safe_load(File.read(bitcoin_path),
        permitted_classes: [Time, Date, Symbol]) : {}) || {}
tip_height = (tip['tip_height'] || 0).to_i

now = Time.now.utc

failures = []

def read_or(slug, path)
  File.exist?(path) ? File.read(path) : nil
end

embargoes.each do |slug, rec|
  # Permalink configs vary: `/feed/:slug` produces a flat
  # `feed/<slug>.html`, while `/feed/:slug/` produces
  # `feed/<slug>/index.html`. Try both before declaring missing.
  candidates = [
    File.join(site, 'feed', "#{slug}.html"),
    File.join(site, 'feed', slug, 'index.html')
  ]
  page_path = candidates.find { |p| File.exist?(p) }
  unless page_path
    failures << "[#{slug}] post page missing (tried #{candidates.join(', ')})"
    next
  end
  html = File.read(page_path)

  time_passed = true
  if rec['embargo_until']
    until_t    = Time.parse(rec['embargo_until'].to_s)
    time_passed = (now >= until_t)
  end
  block_passed = true
  if rec['embargo_block']
    block_passed = (tip_height >= rec['embargo_block'].to_i)
  end
  embargoed_now = !(time_passed && block_passed)

  feeds = {
    'atom.xml'    => read_or(slug, File.join(site, 'atom.xml')).to_s,
    'feed.json'   => read_or(slug, File.join(site, 'feed.json')).to_s,
    'search.json' => read_or(slug, File.join(site, 'search.json')).to_s
  }

  if embargoed_now
    failures << "[#{slug}] missing article--embargoed class"        unless html.include?('article--embargoed')
    failures << "[#{slug}] missing embargo-seal aside"              unless html.include?('class="embargo-seal"')
    failures << "[#{slug}] body div leaked despite active embargo"  if     html.include?('class="article__body"')
    failures << "[#{slug}] methodology appendix leaked"             if     html.include?('class="methodology-appendix"')
    failures << "[#{slug}] PGP signature block leaked"              if     html.include?('class="pgp-signature-block"')
    feeds.each do |name, body|
      failures << "[#{slug}] embargoed slug appears in #{name}" if body.include?(slug)
    end
  else
    failures << "[#{slug}] body div absent though embargo lifted"   unless html.include?('class="article__body"')
    failures << "[#{slug}] embargo seal still rendered post-lift"   if     html.include?('class="embargo-seal"')
    feeds.each do |name, body|
      failures << "[#{slug}] lifted slug missing from #{name}" unless body.include?(slug)
    end
  end
end

if failures.empty?
  puts "[assert_embargo] ok — #{embargoes.size} embargoed posts gated correctly"
  exit 0
else
  warn "[assert_embargo] #{failures.size} assertion failures:"
  failures.each { |f| warn "  - #{f}" }
  exit 1
end
