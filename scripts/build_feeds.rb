#!/usr/bin/env ruby
# build_feeds.rb — emit per-axis feed source files for every
# taxonomy member: sections, authors, series, tags, glossary, lists.
#
# This script writes thin Liquid stubs (frontmatter only) into the
# Jekyll source tree. Each stub points at one of the parameterized
# layouts:
#
#   _layouts/axis-rss.xml       (RSS 2.0)
#   _layouts/axis-atom.xml      (Atom 1.0)
#   _layouts/axis-jsonfeed.json (JSON Feed 1.1)
#   _layouts/axis-archive.html  (HTML index for tags/glossary/lists)
#
# It also writes per-tag, per-glossary-term, and per-list HTML index
# pages for taxonomies that don't have a Jekyll collection of their
# own (sections, authors, series, lists each render through their
# own rich layout; tags and glossary do not).
#
# Idempotent: re-running just rewrites the stubs. Safe to run on
# every build. Source files are checked into git so they're visible
# in editorial review and so GitHub Pages (which doesn't run our
# Ruby scripts) sees the same output as a CI build.

require 'yaml'
require 'date'
require 'time'
require 'fileutils'
require 'set'

ROOT  = File.expand_path('..', __dir__)
POSTS = File.join(ROOT, '_posts')
WROTE = []

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def parse_frontmatter(body)
  return {} unless body.start_with?('---')
  fm_end = body.index("\n---", 3)
  return {} unless fm_end
  YAML.safe_load(body[4..fm_end], permitted_classes: [Time, Date]) || {}
rescue Psych::SyntaxError
  {}
end

def write_if_changed(path, content)
  if File.exist?(path) && File.read(path) == content
    return false
  end
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
  WROTE << path
  true
end

def stub(layout:, axis:, axis_value:, permalink:, archive_url: nil, extra: {})
  fm = {
    'layout'           => layout,
    'sitemap'          => false,
    'axis'             => axis,
    'axis_value'       => axis_value,
    'permalink'        => permalink
  }
  fm['axis_archive_url'] = archive_url if archive_url
  fm.merge!(extra)
  "---\n#{fm.to_yaml.sub(/\A---\n/, '')}---\n"
end

def axis_feeds_for(axis:, slug:, base_url:)
  files = {
    "#{slug}/feed.xml"  => stub(layout: 'axis-rss',     axis: axis, axis_value: slug,
                                permalink: "#{base_url}#{slug}/feed.xml",
                                archive_url: "#{base_url}#{slug}/"),
    "#{slug}/feed.atom" => stub(layout: 'axis-atom',    axis: axis, axis_value: slug,
                                permalink: "#{base_url}#{slug}/feed.atom",
                                archive_url: "#{base_url}#{slug}/"),
    "#{slug}/feed.json" => stub(layout: 'axis-jsonfeed', axis: axis, axis_value: slug,
                                permalink: "#{base_url}#{slug}/feed.json",
                                archive_url: "#{base_url}#{slug}/")
  }
  files
end

def archive_stub(axis:, slug:, permalink:, title:)
  stub(layout: 'axis-archive', axis: axis, axis_value: slug,
       permalink: permalink, extra: { 'title' => title, 'sitemap' => true })
end

# ---------------------------------------------------------------------------
# Scan posts → tag set
# ---------------------------------------------------------------------------

tag_set = Set.new
Dir[File.join(POSTS, '*.md')].each do |path|
  fm = parse_frontmatter(File.binread(path))
  Array(fm['tags']).each { |t| tag_set << t.to_s.strip if t && !t.to_s.strip.empty? }
end

# ---------------------------------------------------------------------------
# Sections — feeds at /sections/<slug>/feed.{xml,atom,json}
# ---------------------------------------------------------------------------

sections_data = YAML.safe_load(File.read(File.join(ROOT, '_data', 'sections.yml')))
section_slugs = sections_data.map { |s| s['slug'] }

section_slugs.each do |slug|
  axis_feeds_for(axis: 'section', slug: slug, base_url: '/sections/').each do |rel, content|
    write_if_changed(File.join(ROOT, 'sections', rel), content)
  end
end

# ---------------------------------------------------------------------------
# Authors — feeds at /authors/<slug>/feed.{xml,atom,json}
#   The author archive page itself lives at /<slug> (collection
#   permalink), so the feed's `axis_archive_url` points back there.
# ---------------------------------------------------------------------------

author_slugs = Dir[File.join(ROOT, '_authors', '*.md')]
                 .map { |p| File.basename(p, '.md') }
                 .sort

author_slugs.each do |slug|
  %w[xml atom json].each do |ext|
    layout = { 'xml' => 'axis-rss', 'atom' => 'axis-atom', 'json' => 'axis-jsonfeed' }[ext]
    body = stub(layout: layout, axis: 'author', axis_value: slug,
                permalink: "/authors/#{slug}/feed.#{ext}",
                archive_url: "/#{slug}/")
    write_if_changed(File.join(ROOT, 'authors', slug, "feed.#{ext}"), body)
  end
end

# ---------------------------------------------------------------------------
# Series — feeds at /series/<slug>/feed.{xml,atom,json}
# ---------------------------------------------------------------------------

series_slugs = Dir[File.join(ROOT, '_series', '*.md')]
                 .map { |p| File.basename(p, '.md') }
                 .sort

series_slugs.each do |slug|
  axis_feeds_for(axis: 'series', slug: slug, base_url: '/series/').each do |rel, content|
    write_if_changed(File.join(ROOT, 'series', rel), content)
  end
end

# ---------------------------------------------------------------------------
# Tags — index page + per-tag archive + feeds at /tags/<slug>/...
# ---------------------------------------------------------------------------

tag_set.sort.each do |slug|
  axis_feeds_for(axis: 'tag', slug: slug, base_url: '/tags/').each do |rel, content|
    write_if_changed(File.join(ROOT, 'tags', rel), content)
  end
  write_if_changed(
    File.join(ROOT, 'tags', slug, 'index.html'),
    archive_stub(axis: 'tag', slug: slug,
                 permalink: "/tags/#{slug}/",
                 title: "Tag: #{slug}")
  )
end

# Tags index page lives in the source tree as `tags/index.html` and
# is hand-authored (it lists all tags); we don't overwrite it here.

# ---------------------------------------------------------------------------
# Glossary — per-term archive + feeds at /glossary/<term>/...
# ---------------------------------------------------------------------------

glossary_data = YAML.safe_load(File.read(File.join(ROOT, '_data', 'glossary.yml')))
glossary_slugs = glossary_data.is_a?(Hash) ? glossary_data.keys : []

glossary_slugs.each do |slug|
  axis_feeds_for(axis: 'glossary', slug: slug, base_url: '/glossary/').each do |rel, content|
    write_if_changed(File.join(ROOT, 'glossary', rel), content)
  end
  display = (glossary_data[slug] || {})['display'] || slug
  write_if_changed(
    File.join(ROOT, 'glossary', slug, 'index.html'),
    archive_stub(axis: 'glossary', slug: slug,
                 permalink: "/glossary/#{slug}/",
                 title: "Glossary: #{display}")
  )
end

# ---------------------------------------------------------------------------
# Lists — feeds at /lists/<slug>/feed.{xml,atom,json}
#   The list page itself lives at /lists/<slug> (collection permalink).
# ---------------------------------------------------------------------------

list_slugs = Dir[File.join(ROOT, '_lists', '*.md')]
               .map { |p| File.basename(p, '.md') }
               .sort

list_slugs.each do |slug|
  %w[xml atom json].each do |ext|
    layout = { 'xml' => 'axis-rss', 'atom' => 'axis-atom', 'json' => 'axis-jsonfeed' }[ext]
    body = stub(layout: layout, axis: 'list', axis_value: slug,
                permalink: "/lists/#{slug}/feed.#{ext}",
                archive_url: "/lists/#{slug}/")
    write_if_changed(File.join(ROOT, 'lists', slug, "feed.#{ext}"), body)
  end
end

puts "[build_feeds] sections=#{section_slugs.size} authors=#{author_slugs.size}" \
     " series=#{series_slugs.size} tags=#{tag_set.size}" \
     " glossary=#{glossary_slugs.size} lists=#{list_slugs.size}" \
     " · wrote #{WROTE.size} stub files"
