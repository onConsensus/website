#!/usr/bin/env ruby
# build_list_bundles.rb — for every `_lists/<slug>.md` reading list:
#
#   1. Filter the entries against the same embargo predicate the layout
#      uses (`_includes/visible-posts.html`), so embargoed posts are
#      kept out of the bundles until lift, mirroring the on-page list.
#   2. Emit a Jekyll source stub at `lists/<slug>/bundle.html` that
#      selects `_layouts/list-bundle.html`. After Jekyll builds, the
#      resulting `_site/lists/<slug>/bundle/index.html` is what
#      `scripts/render_list_bundles.js` opens in headless Chromium and
#      prints to `/lists/<slug>.pdf`.
#   3. Build a self-contained EPUB at `lists/<slug>.epub` directly from
#      the visible entries' source markdown, so the EPUB does not need
#      a browser pipeline. Uses the system `zip` binary with EPUB's
#      mandatory uncompressed-mimetype-first quirk.
#   4. Update each `_lists/<slug>.md`'s frontmatter so `bundle.pdf`
#      and `bundle.epub` point at the produced URLs. The layout's
#      existing slot then surfaces the download links automatically.
#
# Idempotent: a second run on the same inputs writes the same bytes
# and leaves frontmatter untouched.

require 'date'
require 'digest'
require 'fileutils'
require 'kramdown'
require 'time'
require 'yaml'

ROOT      = File.expand_path('..', __dir__)
LISTS_SRC = File.join(ROOT, '_lists')
POSTS_SRC = File.join(ROOT, '_posts')
LISTS_OUT = File.join(ROOT, 'lists')
WROTE     = []

# ---- helpers ---------------------------------------------------------------

def write_if_changed(path, content, binary: false)
  if File.exist?(path)
    existing = binary ? File.binread(path) : File.read(path)
    return false if existing == content
  end
  FileUtils.mkdir_p(File.dirname(path))
  binary ? File.binwrite(path, content) : File.write(path, content)
  WROTE << path
  true
end

# Split a Jekyll source file into [frontmatter Hash, body String, raw_fm String].
def parse_jekyll_source(path)
  raw = File.read(path)
  m = raw.match(/\A---\n(.*?)\n---\n?(.*)\z/m)
  raise "no frontmatter in #{path}" unless m
  fm  = YAML.safe_load(m[1], permitted_classes: [Date, Time], aliases: false) || {}
  [fm, m[2], m[1]]
end

def post_path_for(slug)
  Dir[File.join(POSTS_SRC, "*-#{slug}.md")].first
end

# Mirror `_includes/visible-posts.html`: a post is visible unless an
# embargo gate is still in force. Only posts with embargo metadata are
# evaluated; everything else passes.
def visible?(post_fm, now_epoch, tip_height)
  return true unless post_fm['embargo_until'] || post_fm['embargo_block']
  if post_fm['embargo_until']
    until_ts = Time.parse(post_fm['embargo_until'].to_s).to_i
    return false if now_epoch < until_ts
  end
  if post_fm['embargo_block']
    return false if tip_height < post_fm['embargo_block'].to_i
  end
  true
end

def load_bitcoin_tip
  path = File.join(ROOT, '_data', 'bitcoin.yml')
  return 0 unless File.exist?(path)
  data = YAML.safe_load_file(path, permitted_classes: [Date, Time]) || {}
  data['tip_height'].to_i
end

def html_escape(s)
  s.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
   .gsub('"', '&quot;').gsub("'", '&#39;')
end

# Replace the `bundle:` block in a frontmatter string with the supplied
# pdf / epub URLs. If absent, append it to the end. Preserves the rest
# of the frontmatter (formatting, comments, block scalars) byte-for-byte
# so we don't churn `_lists/*.md` on every build.
def update_bundle_frontmatter(raw_fm, pdf_url, epub_url)
  block = "bundle:\n  pdf: #{pdf_url}\n  epub: #{epub_url}"
  # Match a top-level `bundle:` key plus its indented children, up to
  # the next top-level key or end-of-string.
  re = /^bundle:[ \t]*\n(?:[ \t]+.*\n?)*/
  if raw_fm.match?(re)
    raw_fm.sub(re, block).sub(/\n+\z/, '')
  else
    raw_fm.sub(/\n+\z/, '') + "\n" + block
  end
end

# ---- EPUB writer -----------------------------------------------------------

EPUB_CSS = <<~CSS
  @charset "utf-8";
  body { font-family: Georgia, "Times New Roman", serif; line-height: 1.55; margin: 0 1.2em; }
  h1, h2, h3 { font-family: Georgia, serif; line-height: 1.2; }
  h1 { font-size: 1.6em; }
  h2 { font-size: 1.3em; margin-top: 1.4em; }
  h3 { font-size: 1.1em; margin-top: 1.2em; }
  blockquote { margin: 1em 0; padding-left: 1em; border-left: 3px solid #000; font-style: italic; }
  pre, code { font-family: "Courier New", monospace; font-size: 0.92em; }
  pre { background: #f4f4f4; padding: 0.6em 0.8em; white-space: pre-wrap; }
  .annotation { border-left: 3px solid #000; background: #f4f4f4; padding: 0.6em 0.9em; margin: 1em 0; }
  .annotation .label { font-family: "Courier New", monospace; text-transform: uppercase; letter-spacing: 0.1em; font-size: 0.75em; margin: 0 0 0.3em; }
  .kicker { font-family: "Courier New", monospace; text-transform: uppercase; letter-spacing: 0.1em; font-size: 0.8em; }
  .deck { font-style: italic; }
  .byline { font-family: "Courier New", monospace; font-size: 0.85em; color: #444; }
  .toc ol { padding-left: 1.4em; }
  hr { border: 0; border-top: 1px solid #000; margin: 2em 0; }
CSS

def render_epub(list_fm, list_body, posts_fm_body, out_path)
  slug = list_fm['slug']
  title = list_fm['title'].to_s
  curator = list_fm['curator'].to_s
  uid = "urn:onconsensus:list:#{slug}:#{Digest::SHA256.hexdigest("#{slug}|#{posts_fm_body.map{|p|p[0]['title']}.join('|')}")[0,16]}"
  modified = (list_fm['last_revised'] || Date.today).to_s + 'T00:00:00Z'

  files = {}

  files['mimetype'] = "application/epub+zip"

  files['META-INF/container.xml'] = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
      <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
      </rootfiles>
    </container>
  XML

  files['OEBPS/style.css'] = EPUB_CSS

  # Cover / curator-note chapter
  cover_html = +""
  cover_html << "<h1>#{html_escape(title)}</h1>\n"
  if list_fm['description']
    cover_html << "<p class=\"deck\">#{html_escape(list_fm['description'].to_s.strip)}</p>\n"
  end
  cover_html << "<p class=\"byline\">"
  cover_html << "Curated by #{html_escape(curator)}" unless curator.empty?
  cover_html << " · Revised #{html_escape(list_fm['last_revised'].to_s)}" if list_fm['last_revised']
  cover_html << " · #{posts_fm_body.size} #{posts_fm_body.size == 1 ? 'entry' : 'entries'}"
  cover_html << "</p>\n"
  if list_body && !list_body.strip.empty?
    cover_html << Kramdown::Document.new(list_body).to_html
  end
  files['OEBPS/cover.xhtml'] = wrap_xhtml("Cover", cover_html)

  # Per-entry chapters
  chapter_files = []
  posts_fm_body.each_with_index do |(post_fm, post_body, entry_meta), i|
    chap_id = format('ch-%02d-%s', i + 1, post_fm['slug'].to_s.gsub(/[^a-z0-9-]/i, '-'))
    chap_path = "OEBPS/#{chap_id}.xhtml"
    body = +""
    body << "<p class=\"kicker\">Entry #{format('%02d', i + 1)}</p>\n"
    body << "<h1>#{html_escape(post_fm['title'].to_s)}</h1>\n"
    body << "<p class=\"deck\">#{html_escape(post_fm['subtitle'].to_s)}</p>\n" if post_fm['subtitle']
    body << "<p class=\"byline\">By #{html_escape(post_fm['author'].to_s)} · #{html_escape(post_fm['date'].to_s)}</p>\n"
    if entry_meta && entry_meta['annotation']
      body << "<aside class=\"annotation\"><p class=\"label\">Curator's note</p><p>#{html_escape(entry_meta['annotation'].to_s.strip)}</p></aside>\n"
    end
    body << Kramdown::Document.new(post_body || '').to_html
    files[chap_path] = wrap_xhtml(post_fm['title'].to_s, body)
    chapter_files << [chap_id, post_fm['title'].to_s]
  end

  # Navigation document
  nav_html = +"<h1>Contents</h1>\n<nav epub:type=\"toc\" id=\"toc\" class=\"toc\">\n<ol>\n"
  nav_html << "<li><a href=\"cover.xhtml\">#{html_escape(title)}</a></li>\n"
  chapter_files.each do |id, label|
    nav_html << "<li><a href=\"#{id}.xhtml\">#{html_escape(label)}</a></li>\n"
  end
  nav_html << "</ol>\n</nav>\n"
  files['OEBPS/nav.xhtml'] = wrap_xhtml("Contents", nav_html, with_epub_ns: true)

  # OPF package
  manifest = +""
  manifest << %(    <item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"/>\n)
  manifest << %(    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>\n)
  manifest << %(    <item id="css" href="style.css" media-type="text/css"/>\n)
  chapter_files.each do |id, _|
    manifest << %(    <item id="#{id}" href="#{id}.xhtml" media-type="application/xhtml+xml"/>\n)
  end
  spine = +%(    <itemref idref="cover"/>\n    <itemref idref="nav"/>\n)
  chapter_files.each { |id, _| spine << %(    <itemref idref="#{id}"/>\n) }

  files['OEBPS/content.opf'] = <<~OPF
    <?xml version="1.0" encoding="UTF-8"?>
    <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id" xml:lang="en">
      <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
        <dc:identifier id="pub-id">#{html_escape(uid)}</dc:identifier>
        <dc:title>#{html_escape(title)}</dc:title>
        <dc:language>en</dc:language>
        <dc:creator>#{html_escape(curator.empty? ? 'On Consensus' : curator)}</dc:creator>
        <dc:publisher>On Consensus</dc:publisher>
        <dc:rights>CC-BY-SA-4.0</dc:rights>
        <meta property="dcterms:modified">#{html_escape(modified)}</meta>
      </metadata>
      <manifest>
    #{manifest.rstrip}
      </manifest>
      <spine>
    #{spine.rstrip}
      </spine>
    </package>
  OPF

  # Pack into the EPUB zip. mimetype must come first and be stored
  # uncompressed; everything else is deflated. We write the archive
  # ourselves rather than shelling out to `zip` so the script works
  # identically on a vanilla Ruby install — no external binary, no
  # gem outside what Jekyll already pulls in.
  FileUtils.mkdir_p(File.dirname(out_path))
  write_epub_archive(out_path, files)
  WROTE << out_path
end

# Minimal ZIP writer for EPUB. Implements just the parts of APPNOTE.TXT
# we need: store-or-deflate per entry, fixed mtime for byte-stable
# output, and the central directory + end-of-central-directory record.
def write_epub_archive(out_path, files)
  require 'zlib'
  # EPUB ordering convention: mimetype must be the first entry and stored,
  # not deflated. The rest follow in insertion order.
  ordered_keys = ['mimetype'] + files.keys.reject { |k| k == 'mimetype' }
  entries = []
  buffer = String.new(encoding: 'ASCII-8BIT')
  dos_time, dos_date = 0, 0x21 # 1980-01-01 00:00:00, deterministic

  ordered_keys.each do |name|
    data = files[name].to_s.b
    crc  = Zlib.crc32(data)
    if name == 'mimetype'
      method = 0 # store
      payload = data
    else
      method = 8 # deflate
      z = Zlib::Deflate.new(Zlib::BEST_COMPRESSION, -Zlib::MAX_WBITS)
      payload = z.deflate(data, Zlib::FINISH).b
      z.close
    end
    name_b = name.b
    local_offset = buffer.bytesize
    # Local file header (signature 0x04034b50)
    local = [
      0x04034b50, 20, 0, method, dos_time, dos_date,
      crc, payload.bytesize, data.bytesize, name_b.bytesize, 0
    ].pack('VvvvvvVVVvv') + name_b + payload
    buffer << local
    entries << {
      name: name_b, method: method, crc: crc,
      csize: payload.bytesize, usize: data.bytesize,
      offset: local_offset
    }
  end

  cd_start = buffer.bytesize
  entries.each do |e|
    cdh = [
      0x02014b50, 20, 20, 0, e[:method], dos_time, dos_date,
      e[:crc], e[:csize], e[:usize], e[:name].bytesize,
      0, 0, 0, 0, 0, e[:offset]
    ].pack('VvvvvvvVVVvvvvvVV') + e[:name]
    buffer << cdh
  end
  cd_size = buffer.bytesize - cd_start
  eocd = [
    0x06054b50, 0, 0, entries.size, entries.size, cd_size, cd_start, 0
  ].pack('VvvvvVVv')
  buffer << eocd

  File.binwrite(out_path, buffer)
end

require 'tmpdir'

def wrap_xhtml(title, body, with_epub_ns: false)
  ns = with_epub_ns ? %( xmlns:epub="http://www.idpf.org/2007/ops") : ""
  <<~XHTML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml"#{ns} xml:lang="en" lang="en">
    <head>
      <meta charset="utf-8"/>
      <title>#{html_escape(title)}</title>
      <link rel="stylesheet" type="text/css" href="style.css"/>
    </head>
    <body>
    #{body}
    </body>
    </html>
  XHTML
end

# ---- main ------------------------------------------------------------------

now_epoch  = Time.now.utc.to_i
tip_height = load_bitcoin_tip

list_files = Dir[File.join(LISTS_SRC, '*.md')].sort
if list_files.empty?
  puts '[build_list_bundles] no `_lists/*.md` found — nothing to do'
  exit 0
end

list_files.each do |list_path|
  list_fm, list_body, raw_fm = parse_jekyll_source(list_path)
  slug = list_fm['slug'] || File.basename(list_path, '.md')

  entries = list_fm['entries'] || []
  visible_entries = []
  entries.each do |entry|
    entry_slug = entry.is_a?(Hash) ? entry['slug'] : entry.to_s
    pp = post_path_for(entry_slug)
    next unless pp
    pfm, pbody, _ = parse_jekyll_source(pp)
    next unless visible?(pfm, now_epoch, tip_height)
    pfm['slug'] ||= entry_slug
    visible_entries << [pfm, pbody, entry.is_a?(Hash) ? entry : { 'slug' => entry_slug }]
  end

  # 1. Source stub for the PDF — Jekyll renders this with list-bundle layout.
  stub_path = File.join(LISTS_OUT, slug, 'bundle.html')
  stub_fm = {
    'layout'    => 'list-bundle',
    'permalink' => "/lists/#{slug}/bundle/",
    'sitemap'   => false,
    'list_slug' => slug
  }
  write_if_changed(stub_path, stub_fm.to_yaml + "---\n")

  # 2. EPUB rendered straight from source — no browser needed.
  epub_path = File.join(LISTS_OUT, "#{slug}.epub")
  render_epub(list_fm, list_body, visible_entries, epub_path)

  # 3. Frontmatter — wire up bundle URLs so the layout's slot lights up.
  pdf_url  = "/lists/#{slug}.pdf"
  epub_url = "/lists/#{slug}.epub"
  new_raw_fm = update_bundle_frontmatter(raw_fm, pdf_url, epub_url)
  if new_raw_fm != raw_fm
    File.write(list_path, "---\n#{new_raw_fm}\n---\n#{list_body}")
    WROTE << list_path
  end
end

puts "[build_list_bundles] wrote #{WROTE.size} file(s)"
WROTE.each { |p| puts "  · #{p.sub(ROOT + '/', '')}" }
