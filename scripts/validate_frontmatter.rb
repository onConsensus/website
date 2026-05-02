#!/usr/bin/env ruby
# validate_frontmatter.rb — assert every collection file's frontmatter
# satisfies the contract documented in `_data/schemas.yml`.
#
# What this catches
#   · A required field is missing (e.g. a post without `section`).
#   · A required field is present but the value is wrong shape
#     (e.g. `tags` is a string instead of an array; `date` doesn't
#     parse as ISO 8601).
#   · `section` references a slug that isn't in `_data/sections.yml`.
#   · `author` references a slug that doesn't have a file in `_authors/`.
#   · `series` references a slug that doesn't have a file in `_series/`.
#   · A list `entries[].slug` references a post that doesn't exist.
#   · A required field has an empty / blank string value.
#
# What this *doesn't* catch
#   · Prose quality (Vale's job).
#   · Whether the body is well-formed Markdown (htmlproofer's job).
#
# Exit codes
#   0  every file validates.
#   1  one or more files fail; details written to stderr.
#
# This script is intentionally dependency-free — it runs in
# pre-commit hooks on the editor's machine and in CI on the GitHub
# Actions runner without `bundle install`.

require 'yaml'
require 'date'
require 'time'

ROOT = File.expand_path('..', __dir__)

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

def slug_from_filename(path, strip_date: false)
  base = File.basename(path, '.md')
  strip_date ? base.sub(/^\d{4}-\d{2}-\d{2}-/, '') : base
end

def relpath(path)
  path.sub("#{ROOT}/", '')
end

# ---------------------------------------------------------------------------
# Reference data
# ---------------------------------------------------------------------------

SECTION_SLUGS = begin
  yaml = YAML.safe_load(File.read(File.join(ROOT, '_data', 'sections.yml')))
  yaml.is_a?(Array) ? yaml.map { |s| s['slug'] } : []
end

AUTHOR_SLUGS = Dir[File.join(ROOT, '_authors', '*.md')]
                 .map { |p| File.basename(p, '.md') }

SERIES_SLUGS = Dir[File.join(ROOT, '_series', '*.md')]
                 .map { |p| File.basename(p, '.md') }

POST_SLUGS = Dir[File.join(ROOT, '_posts', '*.md')]
               .map { |p| slug_from_filename(p, strip_date: true) }

errors = []

# ---------------------------------------------------------------------------
# Validators
# ---------------------------------------------------------------------------

def require_string(fm, key, errors, file)
  v = fm[key]
  return errors << "[#{file}] required field `#{key}` is missing" if v.nil?
  return errors << "[#{file}] required field `#{key}` must be a non-empty string" \
    unless v.is_a?(String) && !v.strip.empty?
end

def require_array_of_strings(fm, key, errors, file)
  v = fm[key]
  return if v.nil? # optional handling done by caller
  unless v.is_a?(Array) && v.all? { |x| x.is_a?(String) && !x.strip.empty? }
    errors << "[#{file}] field `#{key}` must be an array of non-empty strings"
  end
end

def parses_as_iso8601?(v)
  return false if v.nil?
  return true if v.is_a?(Date) || v.is_a?(Time)
  Time.parse(v.to_s)
  true
rescue ArgumentError
  false
end

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

  require_string(fm, 'title', errors, rel)
  require_string(fm, 'author', errors, rel)
  require_string(fm, 'section', errors, rel)

  if fm['date'].nil?
    errors << "[#{rel}] required field `date` is missing"
  elsif !parses_as_iso8601?(fm['date'])
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

  require_array_of_strings(fm, 'tags', errors, rel) if fm.key?('tags')

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

  require_string(fm, 'name', errors, rel)
  require_string(fm, 'slug', errors, rel)

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

  %w[title slug description editor status].each { |k| require_string(fm, k, errors, rel) }

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

  %w[title slug description curator].each { |k| require_string(fm, k, errors, rel) }

  if fm['slug'].is_a?(String) && fm['slug'] != File.basename(path, '.md')
    errors << "[#{rel}] field `slug` must equal the filename (`#{File.basename(path, '.md')}`)"
  end

  if fm['curator'].is_a?(String) && !AUTHOR_SLUGS.include?(fm['curator'])
    errors << "[#{rel}] field `curator` references unknown author slug `#{fm['curator']}`"
  end

  if fm['entries'].nil?
    errors << "[#{rel}] required field `entries` is missing"
  elsif !fm['entries'].is_a?(Array) || fm['entries'].empty?
    errors << "[#{rel}] field `entries` must be a non-empty array"
  else
    fm['entries'].each_with_index do |e, i|
      unless e.is_a?(Hash) && e['slug'].is_a?(String) && !e['slug'].strip.empty?
        errors << "[#{rel}] entries[#{i}] is missing `slug`"
        next
      end
      unless POST_SLUGS.include?(e['slug'])
        errors << "[#{rel}] entries[#{i}].slug `#{e['slug']}` does not match any post in _posts/"
      end
    end
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
       "#{Dir[File.join(ROOT, '_lists', '*.md')].size} lists"
  exit 0
else
  warn "[validate_frontmatter] FAIL — #{errors.size} issue(s):"
  errors.each { |e| warn "  · #{e}" }
  exit 1
end
