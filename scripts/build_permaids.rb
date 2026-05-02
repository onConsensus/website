#!/usr/bin/env ruby
# build_permaids.rb — assign immutable `oc:YYYY/NNNN` identifiers.
#
# A permaid is a stable handle for a published article that survives
# URL changes, slug rewrites, and section reshuffles. The binding is
# made to a *seed* string, not to the post's current filename slug.
#
# How a post acquires a permaid
# -----------------------------
# 1. On first publish, the script keys the entry by:
#       fm['permaid_seed']  if present, else  the current slug
#    The slug is then *also* recorded as that seed unless seed was
#    given explicitly.
#
# 2. To rename a post (slug change) without orphaning the citation,
#    the editor adds `permaid_seed: <original-slug>` to the post's
#    frontmatter before renaming. The script keeps the seed key →
#    permaid binding untouched; the new slug never collides because
#    the old key is honoured.
#
# 3. To migrate an existing post that has a `slug:` keyed entry to a
#    seed-based one, the script will, on first run, copy the
#    slug-keyed entry into a seed-keyed entry whenever a frontmatter
#    `permaid_seed` is set. Old entries are preserved for safety.
#
# `_data/permaids.yml` is the source of truth; entries are additive
# and never deleted by this script.

require 'yaml'
require 'date'
require 'time'
require 'fileutils'

ROOT  = File.expand_path('..', __dir__)
POSTS = File.join(ROOT, '_posts')
DATA  = File.join(ROOT, '_data', 'permaids.yml')
META  = File.join(ROOT, '_data', 'permaids-meta.yml')

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
  base.sub(/^\d{4}-\d{2}-\d{2}-/, '')
end

def year_for(path, fm)
  if fm['date']
    Time.parse(fm['date'].to_s).year
  else
    File.basename(path)[/^(\d{4})/, 1].to_i
  end
end

records = {}
if File.exist?(DATA)
  records = YAML.safe_load(File.read(DATA), permitted_classes: [Symbol]) || {}
  records = {} unless records.is_a?(Hash)
end

# Seed counters from the existing IDs so we never collide with a
# previously-issued permaid, even if the corresponding source file
# has since been renamed or removed.
year_counters = Hash.new(0)
records.each_value do |id|
  if id.is_a?(String) && id =~ %r{\Aoc:(\d{4})/(\d+)\z}
    yr = Regexp.last_match(1).to_i
    n  = Regexp.last_match(2).to_i
    year_counters[yr] = n if n > year_counters[yr]
  end
end

issued_new = 0

Dir[File.join(POSTS, '*.md')].sort.each do |path|
  body = File.binread(path)
  fm   = parse_frontmatter(body)
  slug = slug_for(path)
  seed = (fm['permaid_seed'] || slug).to_s

  # If the seed already has an ID, that's the binding — stable.
  if records[seed]
    # Mirror onto the slug key as well so cite.html (which falls back
    # to post.slug when no permaid_seed is set) finds the same ID
    # even if the editor only sets permaid_seed at rename time.
    records[slug] ||= records[seed]
    next
  end

  # If the slug already has an ID (legacy data) but no seed entry
  # exists yet, alias the seed onto the existing slug binding rather
  # than issue a fresh one.
  if records[slug] && seed != slug
    records[seed] = records[slug]
    next
  end

  year = year_for(path, fm)
  year_counters[year] += 1
  id = format('oc:%d/%04d', year, year_counters[year])
  records[seed] = id
  records[slug] = id unless records.key?(slug)
  issued_new += 1
end

FileUtils.mkdir_p(File.dirname(DATA))
File.write(DATA, records.sort.to_h.to_yaml)
File.write(META, {
  'generated_at' => Time.now.utc.iso8601,
  'count'        => records.size
}.to_yaml)

puts "[build_permaids] #{records.size} permaid keys (#{issued_new} newly issued)"
