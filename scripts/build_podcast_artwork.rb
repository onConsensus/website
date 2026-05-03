#!/usr/bin/env ruby
# build_podcast_artwork.rb — render per-section + combined podcast
# cover art (1400x1400 PNG, sRGB) from `_data/sections.yml`.
#
# The art mirrors the broadsheet aesthetic: cream paper, hairline
# rules, the "On Consensus" wordmark in Newsreader, the section name
# centred large in Newsreader, an italic tagline beneath, and a
# bottom band carrying the section slug in IBM Plex Mono with a
# 4-px accent rule above it.
#
# Apple Podcasts requires a square JPEG/PNG between 1400 and 3000 px,
# sRGB. We shell out to ImageMagick (`magick`) and feed it the
# repo-vendored woff2 typefaces in `assets/fonts/`, so the artwork
# stays reproducible from source.
#
# Idempotent: skips writing when the destination already contains a
# file with the same SHA-256 content hash, so re-runs in CI don't
# churn commits.

require 'digest'
require 'fileutils'
require 'open3'
require 'tmpdir'
require 'yaml'

ROOT       = File.expand_path('..', __dir__)
SECTIONS   = YAML.load_file(File.join(ROOT, '_data', 'sections.yml'))
OUT_DIR    = File.join(ROOT, 'images', 'podcast')
FONT_DIR   = File.join(ROOT, 'assets', 'fonts')

PAPER      = '#f4f1ea'
INK        = '#1a1a1a'
RULE       = '#1a1a1a'
ACCENT_DEF = '#B8412E'
SIZE       = 1400

# Repo-vendored typefaces. ImageMagick (FreeType) reads woff2 directly.
FONT_DISPLAY      = File.join(FONT_DIR, 'newsreader-700.woff2')
FONT_DISPLAY_REG  = File.join(FONT_DIR, 'newsreader-400.woff2')
FONT_ITALIC       = File.join(FONT_DIR, 'newsreader-400-italic.woff2')
FONT_MONO         = File.join(FONT_DIR, 'ibm-plex-mono-500.woff2')

[FONT_DISPLAY, FONT_DISPLAY_REG, FONT_ITALIC, FONT_MONO].each do |f|
  abort "[build_podcast_artwork] missing font: #{f}" unless File.exist?(f)
end

def magick(args)
  out, status = Open3.capture2e('magick', *args)
  raise "magick failed: #{out}" unless status.success?
end

# Build the cover with a sequence of `magick` operations. We render
# everything onto a single canvas using -draw / -annotate so the
# layout is fully reproducible from this script.
def render_cover(title:, tagline:, kicker:, accent:, out_path:)
  # Layout (in px, on a 1400² canvas):
  #
  #   ┌────────────────────────────────────────────┐  ← hairline frame
  #   │                                            │
  #   │   ON CONSENSUS                             │  mono wordmark
  #   │   ──────────────────────────────           │  hairline rule
  #   │                                            │
  #   │              <Section Name>                │  centred display serif
  #   │                                            │
  #   │           <italic tagline, wrapped>        │  italic serif
  #   │                                            │
  #   │   ════════════════════════════════ accent  │  4-px accent rule
  #   │   <slug · podcast>      onconsensus.com    │  mono bottom band
  #   └────────────────────────────────────────────┘
  pad        = 100
  frame      = 18
  inner_w    = SIZE - 2 * pad

  wordmark    = 'ON CONSENSUS'
  wordmark_y  = 130
  hairline_y  = 200

  bottom_band_y = SIZE - 130
  accent_rule_y = bottom_band_y - 40

  # Section title — auto-fit to width with a max pointsize, falling
  # back smaller for the longer slugs ("Cryptography", "Development",
  # "Dispatches", "On Consensus"). 1400px ÷ pad leaves ~1200px usable.
  title_pt =
    case title.length
    when 0..6   then 220
    when 7..9   then 180
    when 10..11 then 150
    else             130
    end
  title_y = 360

  tagline_pt    = 38
  tagline_max_w = inner_w
  tagline_max_h = 220
  tagline_y     = title_y + title_pt + 60

  bottom_kicker = "#{kicker} · podcast"
  # Static right-hand mark — using the domain keeps the cover art
  # byte-stable across years so CI doesn't rewrite PNGs every Jan 1.
  bottom_mark   = 'onconsensus.com'

  # Render the wrapped italic tagline as a `caption:` so ImageMagick
  # handles line breaking, then composite it onto the canvas.
  Dir.mktmpdir do |tmp|
    tagline_png = File.join(tmp, 'tagline.png')
    magick([
      '-background', 'none',
      '-fill', '#3a3a3a',
      '-font', FONT_ITALIC,
      '-pointsize', tagline_pt.to_s,
      '-gravity', 'North',
      '-size', "#{tagline_max_w}x#{tagline_max_h}",
      "caption:#{tagline}",
      tagline_png,
    ])

    args = [
      '-size', "#{SIZE}x#{SIZE}",
      "xc:#{PAPER}",
      '-colorspace', 'sRGB',

      # Outer hairline frame.
      '-fill', 'none',
      '-stroke', RULE,
      '-strokewidth', '2',
      '-draw', "rectangle #{frame},#{frame} #{SIZE - frame},#{SIZE - frame}",

      # Wordmark.
      '-stroke', 'none',
      '-fill', INK,
      '-font', FONT_MONO,
      '-pointsize', '38',
      '-gravity', 'North',
      '-annotate', "+0+#{wordmark_y}", wordmark,

      # Hairline under wordmark.
      '-stroke', RULE,
      '-strokewidth', '1',
      '-draw', "line #{pad},#{hairline_y} #{SIZE - pad},#{hairline_y}",

      # Section title (display serif, bold).
      '-stroke', 'none',
      '-fill', INK,
      '-font', FONT_DISPLAY,
      '-pointsize', title_pt.to_s,
      '-gravity', 'North',
      '-annotate', "+0+#{title_y}", title,

      # Italic tagline (composited from the pre-rendered caption).
      tagline_png,
      '-gravity', 'North',
      '-geometry', "+0+#{tagline_y}",
      '-composite',

      # Accent rule above the bottom band.
      '-stroke', accent,
      '-strokewidth', '4',
      '-draw', "line #{pad},#{accent_rule_y} #{SIZE - pad},#{accent_rule_y}",

      # Bottom band: slug · podcast (left), year (right). Plex Mono.
      '-stroke', 'none',
      '-fill', INK,
      '-font', FONT_MONO,
      '-pointsize', '30',
      '-gravity', 'NorthWest',
      '-annotate', "+#{pad}+#{bottom_band_y}", bottom_kicker,
      '-gravity', 'NorthEast',
      '-annotate', "+#{pad}+#{bottom_band_y}", bottom_mark,

      # Flatten + clamp to sRGB 8-bit, strip metadata.
      '-strip',
      '-depth', '8',
      out_path,
    ]
    magick(args)
  end
end

def write_if_changed(path, &block)
  Dir.mktmpdir do |tmp|
    candidate = File.join(tmp, File.basename(path))
    block.call(candidate)
    bytes = File.binread(candidate)
    if File.exist?(path) && Digest::SHA256.hexdigest(File.binread(path)) == Digest::SHA256.hexdigest(bytes)
      puts "[build_podcast_artwork] up-to-date #{path.sub(ROOT + '/', '')}"
      return false
    end
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, bytes)
    puts "[build_podcast_artwork] wrote #{path.sub(ROOT + '/', '')} (#{bytes.bytesize} bytes)"
    true
  end
end

# ----- emit per-section + combined ------------------------------------------

SECTIONS.each do |s|
  accent = (s['accent'] || ACCENT_DEF).to_s
  accent = "##{accent.tr('#', '').rjust(6, '0')}"
  out    = File.join(OUT_DIR, "#{s['slug']}.png")
  write_if_changed(out) do |dest|
    render_cover(
      title:   s['title'],
      tagline: s['blurb'].to_s,
      kicker:  s['slug'],
      accent:  accent,
      out_path: dest,
    )
  end
end

# Combined feed. Tagline is derived from the live taxonomy so it
# tracks any section additions/removals automatically.
all_slugs = SECTIONS.map { |s| s['slug'] }.compact
write_if_changed(File.join(OUT_DIR, 'all.png')) do |dest|
  render_cover(
    title:   'On Consensus',
    tagline: "All sections · #{all_slugs.join(', ')}.",
    kicker:  'all sections',
    accent:  ACCENT_DEF,
    out_path: dest,
  )
end
