#!/usr/bin/env ruby
# build_citations.rb — emit downloadable citation files (BibTeX, RIS,
# Hayagriva YAML) for every published post.
#
# Why a sibling generator
# -----------------------
# `_includes/cite.html` already renders BibTeX / RIS / Hayagriva /
# plain-text inside the article's "Cite this" disclosure. That copy-
# to-clipboard path requires JavaScript and depends on the reader
# selecting + clicking the right tab. Reference managers (Zotero,
# BibDesk, Mendeley) prefer to ingest a sidecar file directly.
#
# This script materializes per-post:
#   feed/<slug>.bib              (BibTeX, @misc entry)
#   feed/<slug>.ris              (RIS, GEN type)
#   feed/<slug>.hayagriva.yaml   (Hayagriva, web type)
#
# The on-page disclosure (`_includes/cite.html`) gains "Download" links
# pointing at these paths. The byte-content is generated to match the
# on-page rendering field-for-field, including the OnConsensus permaid
# (`oc:YYYY/NNNN`) and the OpenTimestamps proof URL when present.
#
# Inputs:
#   `_posts/*.md`              — posts and their frontmatter
#   `_authors/*.md`            — byline name lookups
#   `_data/permaids.yml`       — immutable permaids per slug/seed
#   `_data/timestamps.yml`     — OpenTimestamps proof presence
#   `_config.yml`              — site title and url for citation fields
#
# Output:
#   `feed/<slug>.{bib,ris,hayagriva.yaml}` — static files served verbatim
#   `_data/citations-meta.yml`             — generation metadata
#
# Idempotent: re-running rewrites only the files whose contents changed.

require 'yaml'
require 'date'
require 'time'
require 'fileutils'

ROOT     = File.expand_path('..', __dir__)
POSTS    = File.join(ROOT, '_posts')
AUTHORS  = File.join(ROOT, '_authors')
OUT_DIR  = File.join(ROOT, 'feed')
META     = File.join(ROOT, '_data', 'citations-meta.yml')

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

def slug_for(path)
  base = File.basename(path, '.md')
  base.sub(/\A\d{4}-\d{2}-\d{2}-/, '')
end

def write_if_changed(path, content)
  if File.exist?(path) && File.binread(path) == content
    return false
  end
  FileUtils.mkdir_p(File.dirname(path))
  File.binwrite(path, content)
  true
end

# Liquid `strip_newlines` collapses CR/LF runs to nothing.
def strip_newlines(s)
  s.to_s.gsub(/\r?\n/, '')
end

# BibTeX field-value escaping. Mirrors the Liquid pipeline in
# `_includes/cite.html`:
#   replace: "\\", "\\\\" | replace: "&", "\\&" | replace: "%", "\\%" |
#   replace: "#", "\\#"  | replace: "_", "\\_" | replace: "$", "\\$"
# We use gsub blocks so the replacement strings are taken literally
# (gsub's pattern-replacement form treats `\&` etc. as backreferences).
def bibtex_escape(s, full: true)
  s = s.to_s.gsub("\\") { "\\\\" }
  s = s.gsub("&") { "\\&" }
  return s unless full
  s.gsub("%") { "\\%" }
   .gsub("#") { "\\#" }
   .gsub("_") { "\\_" }
   .gsub("$") { "\\$" }
end

# YAML double-quoted string escaping for Hayagriva fields.
def yaml_dq_escape(s)
  s = s.to_s.gsub("\\") { "\\\\" }
  s.gsub('"') { '\\"' }
end

def bibtex_key(byline, year, title)
  surname    = byline.to_s.split(' ').last.to_s.downcase.gsub('.', '')
  firstword  = title.to_s.split(' ').first.to_s.downcase.gsub(':', '').gsub(',', '')
  "#{surname}#{year}#{firstword}"
end

def post_date(fm, path)
  if fm['date']
    Time.parse(fm['date'].to_s)
  else
    m = File.basename(path).match(/\A(\d{4})-(\d{2})-(\d{2})/)
    Time.utc(m[1].to_i, m[2].to_i, m[3].to_i)
  end
end

MONTH_ABBR = %w[jan feb mar apr may jun jul aug sep oct nov dec].freeze

# ---------------------------------------------------------------------------
# Load shared data
# ---------------------------------------------------------------------------

config    = YAML.safe_load(File.read(File.join(ROOT, '_config.yml')), permitted_classes: [Symbol]) || {}
site_title = config['title'].to_s
site_url   = config['url'].to_s.sub(%r{/\z}, '') + config['baseurl'].to_s

permaids_path   = File.join(ROOT, '_data', 'permaids.yml')
timestamps_path = File.join(ROOT, '_data', 'timestamps.yml')
permaids   = File.exist?(permaids_path)   ? (YAML.safe_load(File.read(permaids_path))   || {}) : {}
timestamps = File.exist?(timestamps_path) ? (YAML.safe_load(File.read(timestamps_path)) || {}) : {}

# Build a slug -> author display-name map from `_authors/*.md`.
author_names = {}
Dir[File.join(AUTHORS, '*.md')].each do |path|
  fm = parse_frontmatter(File.binread(path))
  slug = (fm['slug'] || File.basename(path, '.md')).to_s
  author_names[slug] = (fm['name'] || slug).to_s
end
default_author = (config.dig('author', 'name') || site_title).to_s

# Access-date stamps mirror Liquid's `site.time` (the build-start time).
access_date = Time.now.utc.strftime('%Y-%m-%d')

# ---------------------------------------------------------------------------
# Render every post
# ---------------------------------------------------------------------------

written = 0
posts_seen = 0

Dir[File.join(POSTS, '*.md')].sort.each do |path|
  fm    = parse_frontmatter(File.binread(path))
  # Honour Jekyll's `published: false` (which Jekyll itself excludes
  # from the build). Skipping here keeps sidecar files from leaking
  # the existence of an unpublished draft.
  next if fm['published'] == false
  posts_seen += 1
  slug  = slug_for(path)
  title = fm['title'].to_s
  author_slug = fm['author'].to_s
  byline = author_names[author_slug] || (author_slug.empty? ? default_author : author_slug)

  date     = post_date(fm, path)
  year     = date.year
  iso_date = date.strftime('%Y-%m-%d')
  month    = MONTH_ABBR[date.month - 1]
  day      = date.day.to_s

  permaid_seed = (fm['permaid_seed'] || slug).to_s
  permaid = permaids[permaid_seed] || permaids[slug]

  ts = timestamps[slug] || {}
  ots_present = !!ts['ots_present']
  ots_url = "#{site_url}/timestamps/#{slug}.ots"

  post_url = "#{site_url}/feed/#{slug}"

  bib_title  = bibtex_escape(title, full: true)
  bib_author = bibtex_escape(byline, full: false)
  ris_title  = strip_newlines(title).gsub('  ', ' ')
  ris_author = strip_newlines(byline)
  yaml_title = strip_newlines(yaml_dq_escape(title))
  yaml_author = strip_newlines(yaml_dq_escape(byline))
  yaml_pub   = yaml_dq_escape(site_title)

  key = bibtex_key(byline, year, title)

  # --- BibTeX ---------------------------------------------------------------
  bib_note = String.new(permaid.to_s)
  bib_note << "; OpenTimestamps proof: #{ots_url}" if ots_present
  bibtex = +<<~BIB
    @misc{#{key},
      author       = {#{bib_author}},
      title        = {#{bib_title}},
      howpublished = {#{site_title}, #{post_url}},
      year         = {#{year}},
      month        = {#{month}},
      day          = {#{day}},
      url          = {#{post_url}},
      urldate      = {#{access_date}},
      note         = {#{bib_note}}
    }
  BIB

  # --- RIS ------------------------------------------------------------------
  ris = +"TY  - GEN\n"
  ris << "AU  - #{ris_author}\n"
  ris << "T1  - #{ris_title}\n"
  ris << "PY  - #{year}\n"
  ris << "DA  - #{iso_date}\n"
  ris << "PB  - #{strip_newlines(site_title)}\n"
  ris << "UR  - #{post_url}\n"
  ris << "Y2  - #{access_date}\n"
  ris << "ID  - #{permaid}\n" if permaid
  ris << "N1  - OpenTimestamps proof: #{ots_url}\n" if ots_present
  # Trailing space-free terminator matches the on-page Liquid rendering
  # (`{% endif %}ER  -` then stripped); the final newline is the
  # conventional file terminator and is ignored by RIS importers.
  ris << "ER  -\n"

  # --- Hayagriva (YAML) -----------------------------------------------------
  hg = +"#{key}:\n"
  hg << "  type: web\n"
  hg << "  title: \"#{yaml_title}\"\n"
  hg << "  author: \"#{yaml_author}\"\n"
  hg << "  date: #{iso_date}\n"
  hg << "  publisher: \"#{yaml_pub}\"\n"
  hg << "  url: #{post_url}\n"
  hg << "  serial-number:\n"
  hg << "    oc: #{permaid || '~'}\n"
  if ots_present
    hg << "  archive: \"OpenTimestamps\"\n"
    hg << "  archive-location: #{ots_url}\n"
  end

  written += 1 if write_if_changed(File.join(OUT_DIR, "#{slug}.bib"), bibtex)
  written += 1 if write_if_changed(File.join(OUT_DIR, "#{slug}.ris"), ris)
  written += 1 if write_if_changed(File.join(OUT_DIR, "#{slug}.hayagriva.yaml"), hg)
end

FileUtils.mkdir_p(File.dirname(META))
File.write(META, {
  'generated_at' => Time.now.utc.iso8601,
  'posts'        => posts_seen,
  'files'        => posts_seen * 3,
  'changed'      => written
}.to_yaml)

puts "[build_citations] #{posts_seen} posts · wrote #{written} citation files"
