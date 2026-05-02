#!/usr/bin/env ruby
# build_print.rb — emit a Jekyll source stub for every YYYY-MM that
# contains at least one published post, plus the human-readable
# /print/ archive page.
#
# Each stub selects the `_layouts/broadsheet.html` layout, which
# Jekyll renders into `_site/print/YYYY-MM/index.html`. The CI job
# `.github/workflows/broadsheet.yml` then loads that HTML in headless
# Chromium and prints it to `_site/print/YYYY-MM.pdf`. Because the
# stub generation is checked into git, GitHub Pages (which doesn't
# run this script) sees the same source as a CI build.
#
# Idempotent: re-running just rewrites the stubs.

require 'date'
require 'fileutils'
require 'yaml'

ROOT  = File.expand_path('..', __dir__)
POSTS = File.join(ROOT, '_posts')
WROTE = []

def write_if_changed(path, content)
  return false if File.exist?(path) && File.read(path) == content
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
  WROTE << path
  true
end

months = Dir[File.join(POSTS, '*.md')].map do |f|
  m = File.basename(f).match(/\A(\d{4})-(\d{2})-/)
  m ? "#{m[1]}-#{m[2]}" : nil
end.compact.uniq.sort

months.each do |ym|
  label = Date.parse("#{ym}-01").strftime('%B %Y')
  fm = {
    'layout'    => 'broadsheet',
    'sitemap'   => false,
    'permalink' => "/print/#{ym}/",
    'month'     => ym,
    'title'     => "On Consensus — #{label} broadsheet"
  }
  write_if_changed(File.join(ROOT, 'print', ym, 'index.html'),
                   fm.to_yaml + "---\n")
end

# /print/ archive index — listing every monthly broadsheet.
listing = +<<~HTML
  ---
  layout: page
  title: Print broadsheet
  permalink: /print/
  sitemap: true
  ---

  <p class="article__deck">
    Every month, every On Consensus article published in that month is
    typeset into a single four-column broadsheet PDF — masthead, table
    of contents, drop caps, page numbers. Suitable for paper. Compiled
    on the first of each month by GitHub Actions; reproducible
    locally with <code>ruby scripts/build_print.rb &amp;&amp; bundle
    exec jekyll build &amp;&amp; node scripts/render_print.js YYYY-MM</code>.
  </p>

  <ul class="print-archive">
HTML

months.reverse.each do |ym|
  label = Date.parse("#{ym}-01").strftime('%B %Y')
  listing << "    <li><strong>#{label}</strong> &mdash; <a href=\"/print/#{ym}.pdf\" rel=\"external\">PDF</a> · <a href=\"/print/#{ym}/\">view in browser</a></li>\n"
end
listing << "  </ul>\n"

write_if_changed(File.join(ROOT, '_pages', 'print.html'), listing)

puts "[build_print] wrote #{WROTE.size} file(s)"
WROTE.each { |p| puts "  · #{p.sub(ROOT + '/', '')}" }
