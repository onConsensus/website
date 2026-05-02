#!/usr/bin/env ruby
# build_methodology.rb — Reproducibility appendix data.
#
# Convention: a post may carry a sibling `methodology/<post-slug>/` directory
# at the repository root. Any files placed there (data, notebooks, queries,
# scripts) are static-served by Jekyll under `/methodology/<slug>/<file>`.
#
# This script walks those directories, computes a SHA-256 for each file,
# and writes `_data/methodology.yml` so the post layout can render the
# appendix with download links + integrity hashes. The "Reproduce this"
# badge near the byline is gated on the same data — no frontmatter flag
# needed; presence of a sibling directory is the contract.

require 'digest'
require 'yaml'
require 'fileutils'
require 'time'

ROOT = File.expand_path('..', __dir__)
SRC  = File.join(ROOT, 'methodology')
DATA = File.join(ROOT, '_data', 'methodology.yml')
META = File.join(ROOT, '_data', 'methodology-meta.yml')

FileUtils.mkdir_p(File.dirname(DATA))

records = {}
total_files = 0

if Dir.exist?(SRC)
  Dir.children(SRC).sort.each do |slug|
    dir = File.join(SRC, slug)
    next unless File.directory?(dir)
    files = []
    Dir.glob(File.join(dir, '**', '*'), File::FNM_DOTMATCH).sort.each do |path|
      next if File.directory?(path)
      next if File.basename(path).start_with?('.')
      rel = path.sub(dir + '/', '')
      bytes = File.binread(path)
      files << {
        'name'   => rel,
        'sha256' => Digest::SHA256.hexdigest(bytes),
        'bytes'  => bytes.bytesize,
        'url'    => "/methodology/#{slug}/#{rel}"
      }
    end
    next if files.empty?
    total_files += files.size
    records[slug] = { 'files' => files }
  end
end

File.write(DATA, records.sort.to_h.to_yaml)
File.write(META, {
  'generated_at' => Time.now.utc.iso8601,
  'posts'        => records.size,
  'files'        => total_files
}.to_yaml)

puts "[build_methodology] #{records.size} posts; #{total_files} files"
