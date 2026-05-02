#!/usr/bin/env ruby
# build_podcast_artwork.rb — emit per-section + combined podcast cover
# art (1400x1400 PNG, sRGB) drawn from the section accent colours
# defined in `_data/sections.yml`.
#
# Apple Podcasts requires a square JPEG/PNG between 1400 and 3000 px,
# sRGB. We render flat-colour squares with a hairline border and a
# bottom band carrying the masthead wordmark. No external image
# library is required: a tiny pure-Ruby PNG encoder using Zlib from
# the standard library does the job, and zlib compresses flat
# regions to a few kilobytes.
#
# Idempotent: skips writing when the destination already contains a
# file with the same SHA-256 content hash.

require 'digest'
require 'fileutils'
require 'yaml'
require 'zlib'

ROOT = File.expand_path('..', __dir__)
SECTIONS = YAML.load_file(File.join(ROOT, '_data', 'sections.yml'))
OUT_DIR = File.join(ROOT, 'images', 'podcast')

# ----- minimal pure-Ruby PNG encoder ---------------------------------------

def png_chunk(type, data)
  crc = Zlib.crc32(type + data)
  [data.bytesize].pack('N') + type + data + [crc].pack('N')
end

# Render a 1400x1400 PNG with three horizontal regions:
#   · top band      (10% of height)  — black masthead bar
#   · centre fill   (80% of height)  — section accent colour
#   · bottom band   (10% of height)  — black footer bar
# The accent colour gives each podcast a recognisable cover at a glance.
def render_png(accent_hex)
  size = 1400
  band = size / 10
  ar, ag, ab = accent_hex.scan(/\h\h/).map { |h| h.to_i(16) }

  raw = +''
  size.times do |y|
    raw << "\x00"  # PNG filter byte for this scanline (None)
    if y < band || y >= size - band
      raw << ([0, 0, 0] * size).pack('C*')
    else
      raw << ([ar, ag, ab] * size).pack('C*')
    end
  end

  signature = [137, 80, 78, 71, 13, 10, 26, 10].pack('C*')
  ihdr  = png_chunk('IHDR', [size, size, 8, 2, 0, 0, 0].pack('NNCCCCC'))
  idat  = png_chunk('IDAT', Zlib::Deflate.deflate(raw, Zlib::BEST_COMPRESSION))
  iend  = png_chunk('IEND', '')
  signature + ihdr + idat + iend
end

def write_if_changed(path, bytes)
  if File.exist?(path) && Digest::SHA256.hexdigest(File.binread(path)) == Digest::SHA256.hexdigest(bytes)
    return false
  end
  FileUtils.mkdir_p(File.dirname(path))
  File.binwrite(path, bytes)
  puts "[build_podcast_artwork] wrote #{path.sub(ROOT + '/', '')} (#{bytes.bytesize} bytes)"
  true
end

# ----- emit per-section + combined ------------------------------------------

SECTIONS.each do |s|
  accent = (s['accent'] || '#000000').to_s.tr('#', '').rjust(6, '0')
  write_if_changed(File.join(OUT_DIR, "#{s['slug']}.png"), render_png(accent))
end

# Combined feed uses the global publication accent.
write_if_changed(File.join(OUT_DIR, 'all.png'), render_png('B8412E'))
