#!/usr/bin/env ruby
# frozen_string_literal: true
#
# build_changelog.rb — derive `_data/changelog.yml` from the git history
# of `_posts/`, surfacing post-publish edits as the article changelog.
#
# Why this exists
#   Task #9 (Editorial trust signals) requires every article to expose its
#   post-publish edit history. The cheap source of truth is git itself —
#   no separate database, no extra commits to maintain. This script walks
#   `git log` once per post file and writes a slug-keyed YAML map.
#
# When it runs
#   - Locally: `scripts/build_changelog.sh` calls this before
#     `bundle exec jekyll serve` / `build`.
#   - On every merge: `scripts/post-merge.sh` re-runs it so the working
#     copy is always current.
#   - In CI: the build-check workflow runs it under a full clone
#     (`fetch-depth: 0`) before `jekyll build`.
#
# Output shape
#   _data/changelog.yml is a hash:
#     <slug>:
#       - sha:     <full sha>
#         short:   <7-char sha>
#         date:    <ISO 8601>
#         subject: <commit subject line>
#         url:     <github commit URL, when site.github.repository_url
#                   is reachable from a sibling .changelog-meta.yml>
#
#   Each post's list excludes the FIRST commit that introduced the file
#   (that's the act of publication, not an edit). A post with only its
#   publish commit therefore appears as an empty list, which the layout
#   renders as "No edits since publication".
#
# Failure modes
#   - Outside a git working tree: writes an empty hash + a comment, exits 0.
#   - Shallow clone (no history): same as above. CI must use fetch-depth: 0.

require 'yaml'
require 'open3'
require 'time'

ROOT       = File.expand_path('..', __dir__)
POSTS_DIR  = File.join(ROOT, '_posts')
OUT_PATH   = File.join(ROOT, '_data', 'changelog.yml')
META_PATH  = File.join(ROOT, '_data', 'changelog-meta.yml')

def git(*args)
  out, _err, status = Open3.capture3('git', *args, chdir: ROOT)
  return nil unless status.success?
  out
end

def in_git_repo?
  out = git('rev-parse', '--is-inside-work-tree')
  out && out.strip == 'true'
end

def shallow?
  out = git('rev-parse', '--is-shallow-repository')
  out && out.strip == 'true'
end

def repo_url
  # Single source of truth: `repository: "owner/name"` in _config.yml.
  # This matches what `site.repository` resolves to in Liquid (used by
  # the standards page and other provenance links), so all GitHub URLs
  # in the build agree on the canonical repo.
  cfg_path = File.join(ROOT, '_config.yml')
  if File.exist?(cfg_path)
    File.foreach(cfg_path) do |line|
      if line =~ /\A\s*repository:\s*["']?([^"'\s#]+)/
        return "https://github.com/#{$1}"
      end
    end
  end
  # Fallback: derive from `git remote get-url origin`.
  remote = git('config', '--get', 'remote.origin.url')
  return nil unless remote
  url = remote.strip
  if url =~ %r{git@github\.com:(.+?)(?:\.git)?\z}
    "https://github.com/#{$1}"
  elsif url =~ %r{https://github\.com/(.+?)(?:\.git)?\z}
    "https://github.com/#{$1}"
  end
end

def commits_for(rel_path)
  # Oldest-first so we can drop the first (publication) commit.
  out = git('log', '--reverse', '--pretty=format:%H%x09%aI%x09%s', '--', rel_path)
  return [] unless out && !out.empty?
  out.lines.map { |l| l.chomp.split("\t", 3) }
end

unless in_git_repo?
  warn '[build_changelog] not in a git working tree — writing empty changelog.'
  File.write(OUT_PATH, "# No git history available; changelog is empty.\n{}\n")
  exit 0
end

if shallow?
  warn '[build_changelog] shallow clone detected — set fetch-depth: 0 in CI to populate the changelog.'
end

posts = Dir.glob(File.join(POSTS_DIR, '*.md')).sort
gh = repo_url

changelog = {}
posts.each do |path|
  filename = File.basename(path, '.md')
  slug     = filename.sub(/\A\d{4}-\d{2}-\d{2}-/, '')
  rel      = path.sub("#{ROOT}/", '')

  rows = commits_for(rel)
  next if rows.empty?

  # Drop the first commit (publication). Edits = everything after.
  edits = rows.drop(1).reverse.map do |sha, date, subject|
    entry = {
      'sha'     => sha,
      'short'   => sha[0, 7],
      'date'    => date,
      'subject' => subject.to_s,
    }
    entry['url'] = "#{gh}/commit/#{sha}" if gh
    entry
  end

  changelog[slug] = edits
end

File.write(OUT_PATH, changelog.to_yaml)

# Sidecar metadata for the layout (build provenance).
meta = {
  'generated_at' => Time.now.utc.iso8601,
  'repo_url'     => gh,
  'posts_seen'   => changelog.size,
  'edits_total'  => changelog.values.sum(&:size),
}
File.write(META_PATH, meta.to_yaml)

puts "[build_changelog] wrote #{OUT_PATH}: " \
     "#{changelog.size} posts, #{meta['edits_total']} post-publish edits"
