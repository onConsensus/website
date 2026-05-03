#!/usr/bin/env ruby
# check_permaids_immutable.rb — guard against silent permaid drift.
#
# Citations issued under `oc:YYYY/NNNN` permaids are an immutable
# contract with the reader. The generator (`scripts/build_permaids.rb`)
# is seed-keyed so a slug rename does not break a citation, and it
# is documented as additive — it never rewrites or deletes an entry.
# But that contract is enforced only by the generator's good behavior;
# nothing prevents a contributor (or a sloppy merge) from committing
# a `_data/permaids.yml` whose mapping for an already-published key
# has *changed*. Once a build of that ships, every external citation
# pointing at the old `oc:YYYY/NNNN` quietly resolves to the wrong
# article.
#
# This script closes that loop. It treats the previously-committed
# version of `_data/permaids.yml` (the "frozen" baseline) as the
# source of truth for already-issued bindings, and fails the build if
# the working tree disagrees with it on any pre-existing key.
#
# Append-only changes are allowed: new posts may add new keys.
#
# Baseline selection
# ------------------
#   * In a GitHub Actions pull_request build, the baseline is
#     `origin/<base_ref>` — typically `origin/main`. This catches
#     drift introduced by the PR itself.
#   * In a push build (or local run), the baseline is `HEAD^` —
#     the previous commit on this branch.
#   * If no baseline can be resolved (e.g. initial commit, shallow
#     clone with no history), the script logs and exits 0 rather
#     than failing closed on something it cannot evaluate.
#
# Re-running the generator
# ------------------------
# The script also re-runs `scripts/build_permaids.rb` against the
# current working tree to make sure the generator itself is
# idempotent on the committed file — i.e. running it would not
# change any existing key. (The generator is written to be
# additive, but a future bug there is exactly the kind of silent
# drift this check is meant to catch.)

require 'yaml'
require 'open3'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
DATA_REL = File.join('_data', 'permaids.yml')
META_REL = File.join('_data', 'permaids-meta.yml')
DATA = File.join(ROOT, DATA_REL)
META = File.join(ROOT, META_REL)
GEN  = File.join(ROOT, 'scripts', 'build_permaids.rb')

def fmt_yaml(raw)
  return {} if raw.nil? || raw.strip.empty?
  YAML.safe_load(raw, permitted_classes: [Symbol]) || {}
end

def git(*args)
  out, _err, status = Open3.capture3('git', *args, chdir: ROOT)
  [out, status.success?]
end

def baseline_ref
  if (base = ENV['GITHUB_BASE_REF']) && !base.empty?
    "origin/#{base}"
  elsif (sha = ENV['GITHUB_EVENT_BEFORE']) && !sha.empty? && sha !~ /\A0+\z/
    sha
  else
    'HEAD^'
  end
end

def baseline_permaids(ref)
  out, ok = git('show', "#{ref}:#{DATA_REL}")
  return [nil, "could not read #{DATA_REL} at #{ref}"] unless ok
  parsed = fmt_yaml(out)
  return [nil, "#{DATA_REL} at #{ref} is not a mapping"] unless parsed.is_a?(Hash)
  [parsed, nil]
end

def print_drift_help
  warn ""
  warn "  `_data/permaids.yml` is an append-only ledger of immutable"
  warn "  `oc:YYYY/NNNN` citations. Once a permaid has been issued"
  warn "  for a key, that mapping must not change — every external"
  warn "  citation depends on it."
  warn ""
  warn "  If you renamed a post and the slug-keyed entry should now"
  warn "  bind to a different post, that's not the right fix. Instead,"
  warn "  add"
  warn ""
  warn "      permaid_seed: <original-slug>"
  warn ""
  warn "  to the renamed post's frontmatter *before* renaming, as"
  warn "  documented under `post_permaid` in `_data/schemas.yml`."
  warn "  The generator will then keep the original seed -> permaid"
  warn "  binding intact and issue a fresh permaid for any genuinely"
  warn "  new post."
  warn ""
end

current = fmt_yaml(File.read(DATA)) if File.exist?(DATA)
current ||= {}
unless current.is_a?(Hash)
  warn "[check_permaids_immutable] working-tree #{DATA_REL} is not a mapping."
  exit 1
end

# ---------------------------------------------------------------
# 1. Baseline diff: working tree vs. previous committed version.
# ---------------------------------------------------------------
ref = baseline_ref
baseline, err = baseline_permaids(ref)

if baseline.nil?
  puts "[check_permaids_immutable] no baseline available (#{err}); skipping drift check."
else
  changed = []
  removed = []
  baseline.each do |key, id|
    if !current.key?(key)
      removed << [key, id]
    elsif current[key] != id
      changed << [key, id, current[key]]
    end
  end

  if !changed.empty? || !removed.empty?
    warn ""
    warn "  permaid drift detected against #{ref} — refusing to ship a"
    warn "  citation-breaking change to `_data/permaids.yml`."
    warn ""
    unless changed.empty?
      warn "  Pre-existing keys whose permaid would change:"
      changed.each { |k, old_id, new_id| warn "    - #{k}: #{old_id}  ->  #{new_id}" }
      warn ""
    end
    unless removed.empty?
      warn "  Pre-existing keys that would disappear:"
      removed.each { |k, old_id| warn "    - #{k}: #{old_id}" }
      warn ""
    end
    print_drift_help
    exit 1
  end

  added = current.keys - baseline.keys
  if added.empty?
    puts "[check_permaids_immutable] OK — #{baseline.size} bindings unchanged vs #{ref}."
  else
    puts "[check_permaids_immutable] OK — #{baseline.size} existing bindings unchanged vs " \
         "#{ref}; #{added.size} new permaid(s) appended: #{added.join(', ')}."
  end
end

# ---------------------------------------------------------------
# 2. Generator idempotency: re-run build_permaids.rb on the working
#    tree and confirm it doesn't try to rewrite any existing key.
# ---------------------------------------------------------------
data_backup = File.read(DATA) if File.exist?(DATA)
meta_backup = File.read(META) if File.exist?(META)

ok = system(RbConfig.ruby, GEN)
unless ok
  warn "[check_permaids_immutable] build_permaids.rb failed; cannot verify idempotency."
  File.write(DATA, data_backup) if data_backup
  File.write(META, meta_backup) if meta_backup
  exit 1
end

regenerated = fmt_yaml(File.read(DATA))

# Restore the working-tree files: this script is read-only.
File.write(DATA, data_backup) if data_backup
if meta_backup
  File.write(META, meta_backup)
elsif File.exist?(META)
  File.delete(META)
end

idempotency_changed = []
current.each do |key, id|
  if regenerated.key?(key) && regenerated[key] != id
    idempotency_changed << [key, id, regenerated[key]]
  end
end

unless idempotency_changed.empty?
  warn ""
  warn "  build_permaids.rb is no longer idempotent on the committed"
  warn "  `_data/permaids.yml` — re-running it rewrites existing"
  warn "  bindings. That's a generator regression; existing permaids"
  warn "  must never be rewritten."
  warn ""
  idempotency_changed.each do |k, old_id, new_id|
    warn "    - #{k}: #{old_id}  ->  #{new_id}"
  end
  print_drift_help
  exit 1
end

puts "[check_permaids_immutable] OK — generator is idempotent on the working tree."
