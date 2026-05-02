#!/usr/bin/env ruby
# validate_frontmatter.rb — assert every collection file's frontmatter
# satisfies the contract documented in `_data/schemas.yml`.
#
# `_data/schemas.yml` is the single source of truth for *which fields
# are required* on each kind of content (posts, authors, series,
# lists). This script loads that file, then for every file in the
# corresponding collection, asserts:
#
#   1. Every key listed under `<kind>.required` is present and
#      non-empty.
#   2. Optional keys, when present, satisfy the type rules below.
#   3. Cross-references (author → `_authors/`, section →
#      `_data/sections.yml`, series → `_series/`, list entry slug →
#      `_posts/`) resolve.
#
# When the schema and this script disagree on a *required* field, the
# schema wins — adding a field name under `required:` in schemas.yml
# automatically makes it a CI-blocking requirement here. Type checks
# are scoped to the field set the script knows about; unknown
# optional fields are accepted as documentation-only metadata.
#
# Exit codes
#   0  every file validates.
#   1  one or more files fail; details written to stderr.
#
# Dependency-free — runs in pre-commit on the editor's machine and in
# CI without `bundle install`.

require 'yaml'
require 'date'
require 'time'

ROOT = File.expand_path('..', __dir__)

# ---------------------------------------------------------------------------
# Schema source of truth
# ---------------------------------------------------------------------------

SCHEMA_PATH = File.join(ROOT, '_data', 'schemas.yml')
SCHEMA = YAML.safe_load_file(SCHEMA_PATH, permitted_classes: [Date, Time])

# Required keys for each kind, sourced directly from schemas.yml.
# These are authoritative; the script flags any missing required key
# regardless of whether type-checking machinery exists for it below.
def required_keys(kind)
  (SCHEMA.dig(kind, 'required') || {}).keys
end

def optional_keys(kind)
  (SCHEMA.dig(kind, 'optional') || {}).keys
end

# ---------------------------------------------------------------------------
# Reference data
# ---------------------------------------------------------------------------

SECTION_SLUGS = begin
  yaml = YAML.safe_load_file(File.join(ROOT, '_data', 'sections.yml'))
  yaml.is_a?(Array) ? yaml.map { |s| s['slug'] } : []
end

AUTHOR_SLUGS = Dir[File.join(ROOT, '_authors', '*.md')]
                 .map { |p| File.basename(p, '.md') }

SERIES_SLUGS = Dir[File.join(ROOT, '_series', '*.md')]
                 .map { |p| File.basename(p, '.md') }

POST_SLUGS = Dir[File.join(ROOT, '_posts', '*.md')]
               .map { |p| File.basename(p, '.md').sub(/^\d{4}-\d{2}-\d{2}-/, '') }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def parse_frontmatter(path)
  body = File.binread(path)
  return [nil, 'no frontmatter (file does not start with `---`)'] unless body.start_with?('---')
  fm_end = body.index("\n---", 3)
  return [nil, 'unterminated frontmatter (missing closing `---`)'] unless fm_end
  fm = YAML.safe_load(body[4..fm_end], permitted_classes: [Time, Date])
  [fm.is_a?(Hash) ? fm : {}, nil]
rescue Psych::SyntaxError => e
  [nil, "YAML syntax error: #{e.message}"]
end

def relpath(path)
  path.sub("#{ROOT}/", '')
end

def parses_as_iso8601?(v)
  return false if v.nil?
  return true if v.is_a?(Date) || v.is_a?(Time)
  Time.parse(v.to_s)
  true
rescue ArgumentError
  false
end

# Apply schema-driven required-field check.
# Each `required:` key in schemas.yml must exist in the frontmatter
# and be a non-empty value. Empty arrays / hashes / strings count as
# missing because the schema description for every required field
# implies actual content.
def assert_required(kind, fm, errors, file)
  required_keys(kind).each do |key|
    v = fm[key]
    if v.nil?
      errors << "[#{file}] required field `#{key}` is missing (per _data/schemas.yml :: #{kind}.required)"
    elsif v.is_a?(String) && v.strip.empty?
      errors << "[#{file}] required field `#{key}` is an empty string (per _data/schemas.yml)"
    elsif (v.is_a?(Array) || v.is_a?(Hash)) && v.empty?
      errors << "[#{file}] required field `#{key}` is empty (per _data/schemas.yml)"
    end
  end
end

errors = []

# ---------------------------------------------------------------------------
# Posts
# ---------------------------------------------------------------------------

Dir[File.join(ROOT, '_posts', '*.md')].sort.each do |path|
  rel = relpath(path)
  fm, err = parse_frontmatter(path)
  if err
    errors << "[#{rel}] #{err}"
    next
  end

  assert_required('post', fm, errors, rel)

  # Type / cross-reference checks (scoped to fields the script knows).
  if fm['date'] && !parses_as_iso8601?(fm['date'])
    errors << "[#{rel}] field `date` does not parse as a date/time: #{fm['date'].inspect}"
  end

  if fm['author'].is_a?(String) && !AUTHOR_SLUGS.include?(fm['author'])
    errors << "[#{rel}] field `author` references unknown slug `#{fm['author']}` (no file at _authors/#{fm['author']}.md)"
  end

  if fm['section'].is_a?(String) && !SECTION_SLUGS.include?(fm['section'])
    errors << "[#{rel}] field `section` references unknown slug `#{fm['section']}` (not in _data/sections.yml)"
  end

  if fm.key?('series') && fm['series'].is_a?(String) && !SERIES_SLUGS.include?(fm['series'])
    errors << "[#{rel}] field `series` references unknown slug `#{fm['series']}` (no file at _series/#{fm['series']}.md)"
  end

  if fm.key?('tags')
    unless fm['tags'].is_a?(Array) && fm['tags'].all? { |x| x.is_a?(String) && !x.strip.empty? }
      errors << "[#{rel}] field `tags` must be an array of non-empty strings"
    end
  end

  if fm.key?('reading_time_override')
    unless fm['reading_time_override'].is_a?(Integer) && fm['reading_time_override'] >= 1
      errors << "[#{rel}] field `reading_time_override` must be a positive integer"
    end
  end

  if fm.key?('embargo_until') && !parses_as_iso8601?(fm['embargo_until'])
    errors << "[#{rel}] field `embargo_until` does not parse as a date/time: #{fm['embargo_until'].inspect}"
  end

  if fm.key?('embargo_block') && !fm['embargo_block'].is_a?(Integer)
    errors << "[#{rel}] field `embargo_block` must be an integer block height"
  end

  if fm.key?('corrections')
    unless fm['corrections'].is_a?(Array) &&
           fm['corrections'].all? { |c| c.is_a?(Hash) && c['date'] && c['note'] }
      errors << "[#{rel}] field `corrections` must be an array of `{date, note}` maps"
    end
  end

  if fm.key?('retracted')
    r = fm['retracted']
    unless r.is_a?(Hash) && r['date'] && r['reason']
      errors << "[#{rel}] field `retracted` must be a `{date, reason}` map"
    end
  end
end

# ---------------------------------------------------------------------------
# Authors
# ---------------------------------------------------------------------------

Dir[File.join(ROOT, '_authors', '*.md')].sort.each do |path|
  rel = relpath(path)
  fm, err = parse_frontmatter(path)
  if err
    errors << "[#{rel}] #{err}"
    next
  end

  assert_required('author', fm, errors, rel)

  if fm['slug'].is_a?(String) && fm['slug'] != File.basename(path, '.md')
    errors << "[#{rel}] field `slug` (`#{fm['slug']}`) must equal the filename (`#{File.basename(path, '.md')}`)"
  end

  if fm.key?('joined_date') && !parses_as_iso8601?(fm['joined_date'])
    errors << "[#{rel}] field `joined_date` does not parse as a date: #{fm['joined_date'].inspect}"
  end

  if fm.key?('disclosures')
    d = fm['disclosures']
    unless d.is_a?(Hash)
      errors << "[#{rel}] field `disclosures` must be a map"
    else
      %w[holdings grants advisory paid_writing recusals].each do |k|
        next unless d.key?(k)
        unless d[k].is_a?(Array) && d[k].all? { |x| x.is_a?(String) && !x.strip.empty? }
          errors << "[#{rel}] field `disclosures.#{k}` must be an array of non-empty strings"
        end
      end
      if d.key?('last_reviewed') && !parses_as_iso8601?(d['last_reviewed'])
        errors << "[#{rel}] field `disclosures.last_reviewed` does not parse as a date"
      end
    end
  end
end

# ---------------------------------------------------------------------------
# Series
# ---------------------------------------------------------------------------

Dir[File.join(ROOT, '_series', '*.md')].sort.each do |path|
  rel = relpath(path)
  fm, err = parse_frontmatter(path)
  if err
    errors << "[#{rel}] #{err}"
    next
  end

  assert_required('series', fm, errors, rel)

  if fm['slug'].is_a?(String) && fm['slug'] != File.basename(path, '.md')
    errors << "[#{rel}] field `slug` must equal the filename (`#{File.basename(path, '.md')}`)"
  end

  if fm['editor'].is_a?(String) && !AUTHOR_SLUGS.include?(fm['editor'])
    errors << "[#{rel}] field `editor` references unknown author slug `#{fm['editor']}`"
  end

  if fm['status'].is_a?(String) && !%w[open closed].include?(fm['status'])
    errors << "[#{rel}] field `status` must be `open` or `closed` (got `#{fm['status']}`)"
  end

  if fm.key?('started') && !parses_as_iso8601?(fm['started'])
    errors << "[#{rel}] field `started` does not parse as a date"
  end
end

# ---------------------------------------------------------------------------
# Reading lists
# ---------------------------------------------------------------------------

Dir[File.join(ROOT, '_lists', '*.md')].sort.each do |path|
  rel = relpath(path)
  fm, err = parse_frontmatter(path)
  if err
    errors << "[#{rel}] #{err}"
    next
  end

  assert_required('list', fm, errors, rel)

  if fm['slug'].is_a?(String) && fm['slug'] != File.basename(path, '.md')
    errors << "[#{rel}] field `slug` must equal the filename (`#{File.basename(path, '.md')}`)"
  end

  if fm['curator'].is_a?(String) && !AUTHOR_SLUGS.include?(fm['curator'])
    errors << "[#{rel}] field `curator` references unknown author slug `#{fm['curator']}`"
  end

  if fm['entries'].is_a?(Array)
    fm['entries'].each_with_index do |e, i|
      unless e.is_a?(Hash) && e['slug'].is_a?(String) && !e['slug'].strip.empty?
        errors << "[#{rel}] entries[#{i}] is missing `slug`"
        next
      end
      unless POST_SLUGS.include?(e['slug'])
        errors << "[#{rel}] entries[#{i}].slug `#{e['slug']}` does not match any post in _posts/"
      end
    end
  elsif fm.key?('entries')
    errors << "[#{rel}] field `entries` must be an array"
  end

  if fm.key?('last_revised') && !parses_as_iso8601?(fm['last_revised'])
    errors << "[#{rel}] field `last_revised` does not parse as a date"
  end
end

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------

if errors.empty?
  puts "[validate_frontmatter] ok — #{POST_SLUGS.size} posts, " \
       "#{AUTHOR_SLUGS.size} authors, #{SERIES_SLUGS.size} series, " \
       "#{Dir[File.join(ROOT, '_lists', '*.md')].size} lists " \
       "(schema source: _data/schemas.yml; required keys: " \
       "post=#{required_keys('post').size}, author=#{required_keys('author').size}, " \
       "series=#{required_keys('series').size}, list=#{required_keys('list').size})"
  exit 0
else
  warn "[validate_frontmatter] FAIL — #{errors.size} issue(s):"
  errors.each { |e| warn "  · #{e}" }
  exit 1
end
