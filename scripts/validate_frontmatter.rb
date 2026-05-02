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
#   2. Every required *and* optional field has a value of the type
#      the schema implies (see TYPES below for the explicit type map
#      covering every field name listed in schemas.yml).
#   3. Cross-references resolve (author → `_authors/`, section →
#      `_data/sections.yml`, series → `_series/`, list entry slug →
#      `_posts/`).
#
# When the schema and this script disagree on a *required* field, the
# schema wins — adding a field name under `required:` in schemas.yml
# automatically makes it a CI-blocking requirement here. The TYPES
# map below should be kept in sync when new fields are added to
# schemas.yml; CI runs `scripts/test_validator.rb` to flag drift.
#
# Exit codes
#   0  every file validates.
#   1  one or more files fail; details written to stderr.
#
# Optional CLI flag
#   --root <path>  validate a different root (used by the self-test
#                  fixture in scripts/test_validator.rb).
#
# Dependency-free — runs in pre-commit on the editor's machine and in
# CI without `bundle install`.

require 'yaml'
require 'date'
require 'time'

ROOT = if (idx = ARGV.index('--root'))
         ARGV[idx + 1]
       else
         File.expand_path('..', __dir__)
       end

# ---------------------------------------------------------------------------
# Schema source of truth
# ---------------------------------------------------------------------------

SCHEMA_PATH = File.join(File.expand_path('..', __dir__), '_data', 'schemas.yml')
SCHEMA = YAML.safe_load_file(SCHEMA_PATH, permitted_classes: [Date, Time])

def required_keys(kind)  ; (SCHEMA.dig(kind, 'required') || {}).keys end
def optional_keys(kind)  ; (SCHEMA.dig(kind, 'optional') || {}).keys end
def all_keys(kind)       ; required_keys(kind) + optional_keys(kind) end

# Explicit type map per kind. Every field name appearing in
# `_data/schemas.yml` MUST also appear here — the `test_validator.rb`
# fixture script asserts this drift-detection invariant. Type symbols:
#   :string, :nonempty_string, :int, :positive_int, :bool,
#   :date_or_time, :array_of_strings, :hash, :url
# Custom symbols (per kind) are handled inline:
#   :section_slug, :author_slug, :series_slug, :corrections,
#   :retracted, :disclosures, :author_links, :list_entries, :bundle.
TYPES = {
  'post' => {
    'title'                  => :nonempty_string,
    'author'                  => :author_slug,
    'date'                    => :date_or_time,
    'section'                 => :section_slug,
    'subtitle'                => :nonempty_string,
    'series'                  => :series_slug,
    'tags'                    => :array_of_strings,
    'excerpt'                 => :nonempty_string,
    'featured_image'          => :nonempty_string,
    'featured_caption'        => :nonempty_string,
    'image'                   => :nonempty_string,
    'reading_time_override'   => :positive_int,
    'canonical_url'           => :url,
    'license'                 => :nonempty_string,
    'pgp_signed'              => :bool,
    'featured'                => :bool,
    'block_height'            => :positive_int,
    'corrections'             => :corrections,
    'retracted'               => :retracted,
    'embargo_until'           => :date_or_time,
    'embargo_block'           => :positive_int,
    'intent_statement'        => :nonempty_string,
  },
  'author' => {
    'name'                    => :nonempty_string,
    'slug'                    => :nonempty_string,
    'bio'                     => :nonempty_string,
    'avatar'                  => :nonempty_string,
    'pgp_fingerprint'         => :nonempty_string,
    'joined_date'             => :date_or_time,
    'links'                   => :author_links,
    'disclosures'             => :disclosures,
  },
  'series' => {
    'title'                   => :nonempty_string,
    'slug'                    => :nonempty_string,
    'description'             => :nonempty_string,
    'editor'                  => :author_slug,
    'status'                  => :series_status,
    'cover'                   => :nonempty_string,
    'started'                 => :date_or_time,
  },
  'post_permaid' => {
    'permaid_seed'            => :nonempty_string,
  },
  'list' => {
    'title'                   => :nonempty_string,
    'slug'                    => :nonempty_string,
    'description'             => :nonempty_string,
    'curator'                 => :author_slug,
    'entries'                 => :list_entries,
    'last_revised'            => :date_or_time,
    'bundle'                  => :bundle,
  },
}

# ---------------------------------------------------------------------------
# Reference data (resolved at process start)
# ---------------------------------------------------------------------------

def load_reference(root)
  yaml = YAML.safe_load_file(File.join(root, '_data', 'sections.yml'))
  sections = yaml.is_a?(Array) ? yaml.map { |s| s['slug'] } : []
  {
    sections: sections,
    authors:  Dir[File.join(root, '_authors', '*.md')].map { |p| File.basename(p, '.md') },
    series:   Dir[File.join(root, '_series',  '*.md')].map { |p| File.basename(p, '.md') },
    posts:    Dir[File.join(root, '_posts',   '*.md')].map { |p| File.basename(p, '.md').sub(/^\d{4}-\d{2}-\d{2}-/, '') }
  }
end

REF = load_reference(ROOT)

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

def relpath(path)  ; path.sub("#{ROOT}/", '') end

def date_or_time?(v)
  return true if v.is_a?(Date) || v.is_a?(Time)
  return false unless v.is_a?(String)
  Time.parse(v); true
rescue ArgumentError
  false
end

def url?(v)
  v.is_a?(String) && v.match?(/\Ahttps?:\/\/\S+\z/)
end

# ---------------------------------------------------------------------------
# Per-type validators
# ---------------------------------------------------------------------------

def check_type(kind, key, val, errors, file)
  type = TYPES.dig(kind, key)
  unless type
    errors << "[#{file}] field `#{key}` is not in the type map for `#{kind}` " \
              "— add it to TYPES in scripts/validate_frontmatter.rb (or remove " \
              "from _data/schemas.yml)"
    return
  end

  case type
  when :string
    err(errors, file, key, 'must be a string') unless val.is_a?(String)
  when :nonempty_string
    err(errors, file, key, 'must be a non-empty string') unless val.is_a?(String) && !val.strip.empty?
  when :int
    err(errors, file, key, 'must be an integer') unless val.is_a?(Integer)
  when :positive_int
    err(errors, file, key, 'must be a positive integer') unless val.is_a?(Integer) && val >= 1
  when :bool
    err(errors, file, key, 'must be true or false') unless [true, false].include?(val)
  when :date_or_time
    err(errors, file, key, "does not parse as a date/time: #{val.inspect}") unless date_or_time?(val)
  when :url
    err(errors, file, key, 'must be an http(s) URL') unless url?(val)
  when :array_of_strings
    unless val.is_a?(Array) && val.all? { |x| x.is_a?(String) && !x.strip.empty? }
      err(errors, file, key, 'must be an array of non-empty strings')
    end
  when :hash
    err(errors, file, key, 'must be a map') unless val.is_a?(Hash)

  when :section_slug
    if val.is_a?(String) && !REF[:sections].include?(val)
      err(errors, file, key, "references unknown section `#{val}` (not in _data/sections.yml)")
    elsif !val.is_a?(String)
      err(errors, file, key, 'must be a section slug string')
    end
  when :author_slug
    if val.is_a?(String) && !REF[:authors].include?(val)
      err(errors, file, key, "references unknown author slug `#{val}` (no file at _authors/#{val}.md)")
    elsif !val.is_a?(String)
      err(errors, file, key, 'must be an author slug string')
    end
  when :series_slug
    if val.is_a?(String) && !REF[:series].include?(val)
      err(errors, file, key, "references unknown series slug `#{val}` (no file at _series/#{val}.md)")
    elsif !val.is_a?(String)
      err(errors, file, key, 'must be a series slug string')
    end
  when :series_status
    err(errors, file, key, "must be `open` or `closed` (got `#{val}`)") unless %w[open closed].include?(val)

  when :corrections
    unless val.is_a?(Array) && val.all? { |c| c.is_a?(Hash) && date_or_time?(c['date']) && c['note'].is_a?(String) && !c['note'].strip.empty? }
      err(errors, file, key, 'must be an array of `{date, note}` maps with parseable date and non-empty note')
    end
  when :retracted
    unless val.is_a?(Hash) && date_or_time?(val['date']) && val['reason'].is_a?(String) && !val['reason'].strip.empty?
      err(errors, file, key, 'must be a `{date, reason}` map')
    end

  when :author_links
    unless val.is_a?(Hash)
      err(errors, file, key, 'must be a map of {provider: url}')
    else
      val.each do |provider, link|
        next if provider == 'nostr' && link.is_a?(String) && link.start_with?('npub')
        unless url?(link)
          err(errors, file, "#{key}.#{provider}", "must be an http(s) URL (or `npub…` for nostr); got #{link.inspect}")
        end
      end
    end
  when :disclosures
    unless val.is_a?(Hash)
      err(errors, file, key, 'must be a map')
    else
      err(errors, file, "#{key}.employer", 'must be a non-empty string') if val.key?('employer') && !(val['employer'].is_a?(String) && !val['employer'].strip.empty?)
      %w[holdings grants advisory paid_writing recusals].each do |k|
        next unless val.key?(k)
        unless val[k].is_a?(Array) && val[k].all? { |x| x.is_a?(String) && !x.strip.empty? }
          err(errors, file, "#{key}.#{k}", 'must be an array of non-empty strings')
        end
      end
      if val.key?('last_reviewed') && !date_or_time?(val['last_reviewed'])
        err(errors, file, "#{key}.last_reviewed", 'does not parse as a date')
      end
    end

  when :list_entries
    unless val.is_a?(Array) && !val.empty?
      err(errors, file, key, 'must be a non-empty array')
    else
      val.each_with_index do |e, i|
        unless e.is_a?(Hash) && e['slug'].is_a?(String) && !e['slug'].strip.empty?
          err(errors, file, "#{key}[#{i}]", 'is missing `slug`')
          next
        end
        unless REF[:posts].include?(e['slug'])
          err(errors, file, "#{key}[#{i}].slug", "`#{e['slug']}` does not match any post in _posts/")
        end
        if e.key?('annotation') && !(e['annotation'].is_a?(String))
          err(errors, file, "#{key}[#{i}].annotation", 'must be a string')
        end
      end
    end
  when :bundle
    unless val.is_a?(Hash)
      err(errors, file, key, 'must be a `{pdf, epub}` map')
    else
      %w[pdf epub].each do |fmt|
        next unless val.key?(fmt)
        v = val[fmt]
        unless v.is_a?(String) # empty string allowed = "pending"
          err(errors, file, "#{key}.#{fmt}", 'must be a string (empty = pending)')
        end
      end
    end
  end
end

def err(errors, file, key, msg)
  errors << "[#{file}] field `#{key}` #{msg}"
end

# ---------------------------------------------------------------------------
# Per-file validation
# ---------------------------------------------------------------------------

def validate_file(kind, path, errors)
  rel = relpath(path)
  fm, e = parse_frontmatter(path)
  if e
    errors << "[#{rel}] #{e}"
    return
  end

  # 1. Schema-driven required-field presence.
  required_keys(kind).each do |k|
    v = fm[k]
    if v.nil?
      errors << "[#{rel}] required field `#{k}` is missing (per _data/schemas.yml :: #{kind}.required)"
    elsif v.is_a?(String) && v.strip.empty?
      errors << "[#{rel}] required field `#{k}` is an empty string (per _data/schemas.yml)"
    elsif (v.is_a?(Array) || v.is_a?(Hash)) && v.empty?
      errors << "[#{rel}] required field `#{k}` is empty (per _data/schemas.yml)"
    end
  end

  # 2. Type checks for every schema-listed field that is present.
  all_keys(kind).each do |k|
    next unless fm.key?(k)
    next if fm[k].nil? # absence handled above
    check_type(kind, k, fm[k], errors, rel)
  end

  # 3. Slug ↔ filename coupling for non-post collections.
  if %w[author series list].include?(kind) && fm['slug'].is_a?(String) && fm['slug'] != File.basename(path, '.md')
    errors << "[#{rel}] field `slug` (`#{fm['slug']}`) must equal the filename (`#{File.basename(path, '.md')}`)"
  end
end

# ---------------------------------------------------------------------------
# Drift detection: every schema field name has a TYPES entry.
# ---------------------------------------------------------------------------

def detect_schema_drift(errors)
  %w[post author series list].each do |kind|
    schema_fields = (required_keys(kind) + optional_keys(kind)).uniq
    type_fields   = (TYPES[kind] || {}).keys
    (schema_fields - type_fields).each do |missing|
      errors << "[scripts/validate_frontmatter.rb] schema drift: `#{kind}.#{missing}` is in _data/schemas.yml but missing from TYPES map"
    end
  end
end

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

def run
  errors = []
  detect_schema_drift(errors)

  Dir[File.join(ROOT, '_posts',   '*.md')].sort.each { |p| validate_file('post',   p, errors) }
  Dir[File.join(ROOT, '_authors', '*.md')].sort.each { |p| validate_file('author', p, errors) }
  Dir[File.join(ROOT, '_series',  '*.md')].sort.each { |p| validate_file('series', p, errors) }
  Dir[File.join(ROOT, '_lists',   '*.md')].sort.each { |p| validate_file('list',   p, errors) }

  if errors.empty?
    puts "[validate_frontmatter] ok — " \
         "#{REF[:posts].size} posts, #{REF[:authors].size} authors, " \
         "#{REF[:series].size} series, #{Dir[File.join(ROOT, '_lists', '*.md')].size} lists " \
         "(schema source: _data/schemas.yml; required: " \
         "post=#{required_keys('post').size}, author=#{required_keys('author').size}, " \
         "series=#{required_keys('series').size}, list=#{required_keys('list').size})"
    return 0
  else
    warn "[validate_frontmatter] FAIL — #{errors.size} issue(s):"
    errors.each { |e| warn "  · #{e}" }
    return 1
  end
end

exit(run) if $PROGRAM_NAME == __FILE__
