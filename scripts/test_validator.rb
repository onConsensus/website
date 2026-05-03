#!/usr/bin/env ruby
# test_validator.rb — self-test for scripts/validate_frontmatter.rb.
#
# Builds an in-memory tmp tree under /tmp with a minimum viable
# project (an author, a series, a section, sample posts, a list),
# then runs the validator under each of the following scenarios:
#
#   1. clean fixtures  → must exit 0.
#   2. missing required field → must exit 1, must mention the field.
#   3. unknown section slug   → must exit 1, must mention the slug.
#   4. bad list entry slug    → must exit 1.
#   5. malformed author link  → must exit 1.
#   6. retraction without reason → must exit 1.
#   7. bad date string        → must exit 1.
#   8. schema drift simulation → must report the drift.
#
# Plus a Vale-rule self-check: every per-acronym rule file binds the
# same acronym in `first` and `second`. This is what makes the rules
# loophole-free; if any rule file deviates, the build should fail.

require 'fileutils'
require 'tmpdir'
require 'open3'
require 'yaml'

ROOT     = File.expand_path('..', __dir__)
SCRIPT   = File.join(ROOT, 'scripts', 'validate_frontmatter.rb')
VALE_DIR = File.join(ROOT, '.github', 'vale', 'styles', 'OnConsensus')

def run_validator(root)
  out, err, st = Open3.capture3('ruby', SCRIPT, '--root', root)
  [st.exitstatus, out + err]
end

def fixture_root
  dir = Dir.mktmpdir('oc-fm-')
  FileUtils.mkdir_p File.join(dir, '_posts')
  FileUtils.mkdir_p File.join(dir, '_authors')
  FileUtils.mkdir_p File.join(dir, '_series')
  FileUtils.mkdir_p File.join(dir, '_lists')
  FileUtils.mkdir_p File.join(dir, '_data')

  # Copy the real schema into the fixture so SCHEMA_PATH (now
  # rooted at --root) resolves. Drift tests overwrite this file
  # with a doctored copy.
  FileUtils.cp(File.join(ROOT, '_data', 'schemas.yml'),
               File.join(dir, '_data', 'schemas.yml'))

  File.write(File.join(dir, '_data', 'sections.yml'), [
    { 'slug' => 'research',     'title' => 'Research',     'editor' => 'a-test', 'accent' => '#000', 'blurb' => 'x' },
    { 'slug' => 'cryptography', 'title' => 'Cryptography', 'editor' => 'a-test', 'accent' => '#000', 'blurb' => 'x' }
  ].to_yaml)

  File.write(File.join(dir, '_authors', 'a-test.md'), <<~MD)
    ---
    name: A Test
    slug: a-test
    bio: |
      Test author.
    links:
      mastodon: "https://mastodon.example/@a"
      nostr: "npub1aaaa"
    ---

    body
  MD

  File.write(File.join(dir, '_series', 's-test.md'), <<~MD)
    ---
    title: "Test Series"
    slug: s-test
    description: "Series description."
    editor: a-test
    status: open
    started: 2026-01-01
    ---

    body
  MD

  File.write(File.join(dir, '_posts', '2026-01-01-hello-world.md'), <<~MD)
    ---
    title: "Hello, World"
    author: a-test
    date: 2026-01-01 00:00:00 +0000
    section: research
    series: s-test
    tags: [test, fixture]
    excerpt: "A test post."
    ---

    body
  MD

  File.write(File.join(dir, '_lists', 's-test-list.md'), <<~MD)
    ---
    title: "Test List"
    slug: s-test-list
    description: "Test list description."
    curator: a-test
    entries:
      - slug: hello-world
        annotation: "the only post."
    ---

    body
  MD

  dir
end

failures = []

def assert(label, cond, &detail)
  if cond
    puts "  ok    #{label}"
  else
    msg = block_given? ? "\n        #{detail.call}" : ''
    puts "  FAIL  #{label}#{msg}"
    failures << label
  end
end

failures = []
def fail!(failures, label, detail = nil)
  puts "  FAIL  #{label}"
  puts "        #{detail}" if detail
  failures << label
end
def pass!(label)
  puts "  ok    #{label}"
end

# Test 1: clean fixtures pass.
puts "[test_validator] 1. clean fixtures"
dir = fixture_root
status, output = run_validator(dir)
status == 0 ? pass!('clean fixtures exit 0') : fail!(failures, 'clean fixtures exit 0', output)
FileUtils.rm_rf dir

# Test 2: missing required field.
puts "[test_validator] 2. missing required field"
dir = fixture_root
post = File.join(dir, '_posts', '2026-01-01-hello-world.md')
File.write(post, File.read(post).sub(/^section: research\n/, ''))
status, output = run_validator(dir)
status == 1 ? pass!('missing field exit 1') : fail!(failures, 'missing field exit 1', output)
output.include?('section') ? pass!('mentions `section`') : fail!(failures, 'mentions `section`', output)
FileUtils.rm_rf dir

# Test 3: unknown section.
puts "[test_validator] 3. unknown section slug"
dir = fixture_root
post = File.join(dir, '_posts', '2026-01-01-hello-world.md')
File.write(post, File.read(post).sub('section: research', 'section: nosuch'))
status, output = run_validator(dir)
status == 1 && output.include?('nosuch') ? pass!('unknown section caught') : fail!(failures, 'unknown section caught', output)
FileUtils.rm_rf dir

# Test 4: bad list entry slug.
puts "[test_validator] 4. bad list entry slug"
dir = fixture_root
list = File.join(dir, '_lists', 's-test-list.md')
File.write(list, File.read(list).sub('hello-world', 'no-such-post'))
status, output = run_validator(dir)
status == 1 && output.include?('no-such-post') ? pass!('bad list entry caught') : fail!(failures, 'bad list entry caught', output)
FileUtils.rm_rf dir

# Test 5: malformed author link.
puts "[test_validator] 5. malformed author link"
dir = fixture_root
auth = File.join(dir, '_authors', 'a-test.md')
File.write(auth, File.read(auth).sub('https://mastodon.example/@a', 'not-a-url'))
status, output = run_validator(dir)
status == 1 && output.include?('mastodon') ? pass!('bad mastodon URL caught') : fail!(failures, 'bad mastodon URL caught', output)
FileUtils.rm_rf dir

# Test 6: retraction missing reason.
puts "[test_validator] 6. retraction without reason"
dir = fixture_root
post = File.join(dir, '_posts', '2026-01-01-hello-world.md')
File.write(post, File.read(post).sub("---\n\nbody", "retracted:\n  date: 2026-02-01\n---\n\nbody"))
status, output = run_validator(dir)
status == 1 ? pass!('incomplete retraction caught') : fail!(failures, 'incomplete retraction caught', output)
FileUtils.rm_rf dir

# Test 7: bad date.
puts "[test_validator] 7. unparseable date"
dir = fixture_root
post = File.join(dir, '_posts', '2026-01-01-hello-world.md')
File.write(post, File.read(post).sub('date: 2026-01-01 00:00:00 +0000', 'date: "not-a-date"'))
status, output = run_validator(dir)
status == 1 && output.include?('date') ? pass!('bad date caught') : fail!(failures, 'bad date caught', output)
FileUtils.rm_rf dir

# Test 7a: excerpt over 300 chars.
puts "[test_validator] 7a. overlong excerpt"
dir = fixture_root
post = File.join(dir, '_posts', '2026-01-01-hello-world.md')
long = 'x' * 301
File.write(post, File.read(post).sub('excerpt: "A test post."', "excerpt: \"#{long}\""))
status, output = run_validator(dir)
status == 1 && output.include?('301') && output.include?('300') ? pass!('overlong excerpt caught') : fail!(failures, 'overlong excerpt caught', output)
FileUtils.rm_rf dir

# Test 7b: featured_image referencing a missing file.
puts "[test_validator] 7b. featured_image missing on disk"
dir = fixture_root
post = File.join(dir, '_posts', '2026-01-01-hello-world.md')
File.write(post, File.read(post).sub("excerpt: \"A test post.\"\n",
                                       "excerpt: \"A test post.\"\nfeatured_image: /images/nope.svg\nfeatured_caption: \"x\"\n"))
status, output = run_validator(dir)
status == 1 && output.include?('nope.svg') ? pass!('missing featured_image caught') : fail!(failures, 'missing featured_image caught', output)
FileUtils.rm_rf dir

# Test 7c: featured_image without featured_caption.
puts "[test_validator] 7c. featured_image without featured_caption"
dir = fixture_root
FileUtils.mkdir_p File.join(dir, 'images')
File.write(File.join(dir, 'images', 'cover.svg'), '<svg/>')
post = File.join(dir, '_posts', '2026-01-01-hello-world.md')
File.write(post, File.read(post).sub("excerpt: \"A test post.\"\n",
                                       "excerpt: \"A test post.\"\nfeatured_image: /images/cover.svg\n"))
status, output = run_validator(dir)
status == 1 && output.include?('featured_caption') ? pass!('missing featured_caption caught') : fail!(failures, 'missing featured_caption caught', output)
FileUtils.rm_rf dir

# Test 7d: malformed pgp_fingerprint.
puts "[test_validator] 7d. malformed pgp_fingerprint"
dir = fixture_root
auth = File.join(dir, '_authors', 'a-test.md')
File.write(auth, File.read(auth).sub("links:\n", "pgp_fingerprint: \"NOTHEX 1234\"\nlinks:\n"))
status, output = run_validator(dir)
status == 1 && output.include?('pgp_fingerprint') ? pass!('bad pgp_fingerprint caught') : fail!(failures, 'bad pgp_fingerprint caught', output)
FileUtils.rm_rf dir

# Test 7e: well-formed 40-hex pgp_fingerprint with whitespace passes.
puts "[test_validator] 7e. spaced 40-hex pgp_fingerprint accepted"
dir = fixture_root
auth = File.join(dir, '_authors', 'a-test.md')
fp = '9F4E 22B7 1A0C 5E84 D3F6  8B71 4E20 9C5A 6F0D 33E1'
File.write(auth, File.read(auth).sub("links:\n", "pgp_fingerprint: \"#{fp}\"\nlinks:\n"))
status, output = run_validator(dir)
status == 0 ? pass!('spaced fingerprint accepted') : fail!(failures, 'spaced fingerprint accepted', output)
FileUtils.rm_rf dir

# Test 7f: malformed nostr npub.
puts "[test_validator] 7f. malformed nostr key"
dir = fixture_root
auth = File.join(dir, '_authors', 'a-test.md')
File.write(auth, File.read(auth).sub('npub1aaaa', 'npub-bogus'))
status, output = run_validator(dir)
status == 1 && output.include?('nostr') ? pass!('bad nostr key caught') : fail!(failures, 'bad nostr key caught', output)
FileUtils.rm_rf dir

# Test 8: Vale per-acronym rule integrity.
puts "[test_validator] 8. Vale acronym rules — first/second token agreement"
yaml_files = Dir[File.join(VALE_DIR, 'Acronym*.yml')]
fail!(failures, 'no acronym rule files found') if yaml_files.empty?
yaml_files.each do |f|
  rule = YAML.safe_load_file(f)
  first  = rule['first']
  second = rule['second']
  unless first && second
    fail!(failures, "#{File.basename(f)} missing first/second")
    next
  end
  m = first.match(/\\b([A-Za-z0-9]+)\\b/)
  unless m
    fail!(failures, "#{File.basename(f)} `first` is not a single \\b<token>\\b pattern")
    next
  end
  acr = m[1]
  unless second.include?("\\b#{acr}\\b")
    fail!(failures, "#{File.basename(f)} `second` does not bind same token `#{acr}`")
    next
  end
end
pass!("#{yaml_files.size} per-acronym rules verified") if failures.empty? || !failures.last.to_s.include?('Acronym')

# Test 9: schema drift detection actually fires when a schema field
# lacks a TYPES entry. Now that SCHEMA_PATH honours --root, we can
# substitute a doctored schema in the fixture root and assert the
# validator's true behaviour (not just output presence).
puts "[test_validator] 9. schema drift detection"
dir = fixture_root
schema_path = File.join(dir, '_data', 'schemas.yml')
real = YAML.load_file(File.join(ROOT, '_data', 'schemas.yml'))
real['post']['optional']['unmapped_field'] = 'A test field with no TYPES entry'
File.write(schema_path, real.to_yaml)
status, output = run_validator(dir)
fired = output.include?('schema drift') && output.include?('unmapped_field')
fired ? pass!('drift detector flagged unmapped_field') : fail!(failures, 'drift detector flagged unmapped_field', output)
FileUtils.rm_rf dir

if failures.empty?
  puts "\n[test_validator] PASS"
  exit 0
else
  puts "\n[test_validator] FAIL — #{failures.size} test(s) failed:"
  failures.each { |f| puts "  · #{f}" }
  exit 1
end
