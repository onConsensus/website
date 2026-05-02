---
layout: page
title: Colophon
permalink: /colophon/
description: "How On Consensus is built — design system, fonts, hosting, licensing, and the keys we sign with. No trackers, no third-party scripts, no surveillance by default."
image: '/images/h3.png'
kicker: "Colophon"
sitemap: true
---

A colophon is a printer's signature. This is ours.

## Design

*Plaintext Cypherpunk Broadsheet*. Newsprint paper, near-black ink,
a single oxidized red accent (`#b8412e`) used sparingly. Hairline
rules where a broadsheet would have hairline rules; thick rules
where a broadsheet would have thick rules. Never pure white, never
pure black. Dark mode inverts the paper/ink relationship and
softens the red so it does not burn at low luminance.

A 12-column responsive grid sits underneath every layout, but the
reading column is fixed at 680px because we trust the typographers
who set every newspaper of the last hundred years more than we
trust the urge to fill the viewport.

## Type

Four families, all self-hosted as woff2 with `font-display: swap`.
No fonts.googleapis.com. No CDN font hairpins.

- **Newsreader** — display headings (Production Type, OFL).
- **Source Serif 4** — body text at 19px / 1.65 (Adobe, OFL).
- **IBM Plex Mono** — UI, metadata, kickers, datelines (IBM, OFL).
- **Cormorant Garamond** italic — drop caps and section openers
  (Catharsis Fonts, OFL).

The body face, the display 700, and the mono 400 are
`<link rel="preload">`-ed in the `<head>`; everything else
hydrates as referenced. The fluid type scale is a 1.250 (major
third) ratio anchored at 17px (320px viewport) to 19px (1280px+).

## Build

Static, generated at publish time, hosted on GitHub Pages.

- **Generator.** Jekyll 3.10 (pinned via the `github-pages` gem,
  the same runtime GitHub Pages uses). No Node toolchain.
- **Plugins.** GitHub-Pages-allowed only: `jekyll-feed`,
  `jekyll-seo-tag`, `jekyll-redirect-from`, `jekyll-sitemap`,
  `jekyll-paginate`. Nothing else.
- **Templating.** Liquid. Markdown via kramdown.
- **Styles.** Sass/SCSS with CSS custom properties for every
  token. Cascade entered through `assets/css/main.scss`.
- **JavaScript.** Two files. `js/search.js` (vanilla, ~3 KB,
  loaded site-wide for the `/` keyboard shortcut) and
  `js/reading.js` (vanilla, footnote rail + glossary popovers +
  reading-progress fallback, post pages only). Both `defer`-ed.
  Lunr.js (~30 KB) loads only on `/search/`.
- **Source.** [github.com/onConsensus](https://github.com/onConsensus).
  The footer of every page links to the build's commit SHA so
  readers can verify the binary they served against the public
  source.

## Network

- No third-party JavaScript by default. Analytics are *off*; the
  `_includes/analytics.html` include is a no-op unless
  `analytics.enabled: true` is set in `_config.yml`, and the only
  providers ever wired in are Plausible and Umami (privacy-respecting,
  cookie-free, self-hostable).
- No trackers, no cookies, no fingerprinting. We do not need them
  and we do not want them.
- No images served from third parties. All assets are first-party.
- We respect the Do-Not-Track header. We respect
  `prefers-reduced-motion`. We respect `prefers-color-scheme`.

## Feeds

We publish three feeds, all on the same wire:

- [`/feed.xml`](/feed.xml) — Atom 1.0 via `jekyll-feed`.
- [`/atom.xml`](/atom.xml) — hand-rolled Atom with editorial
  fields (per-item licence, summaries, section, series, PGP-signed
  flag).
- [`/feed.json`](/feed.json) — JSON Feed 1.1, with an
  `_on_consensus` extension exposing `section`, `series`,
  `license`, `pgp_signed`, and `block_height`.

Each editorial section also publishes its own RSS 2.0 feed at
`/sections/<slug>/feed.xml`.

## Cryptography

Selected articles are PGP-signed. The signature is rendered inline
at the foot of the article and a detached `.sig` file is published
under `/signatures/<slug>.sig` so that anyone can run
`gpg --verify` against a byte-identical artefact.

The editorial PGP key for tips and corrections:

```
On Consensus Editors <editors@onconsensus.com>
Fingerprint: 9F4E 22B7 1A0C 5E84 D3F6  8B71 4E20 9C5A 6F0D 33E1
```

(*Fingerprint above is illustrative; the live key lives at
[/.well-known/openpgpkey/onconsensus.com/](/.well-known/openpgpkey/onconsensus.com/) and on
[keys.openpgp.org](https://keys.openpgp.org). Editors' personal
keys are listed on their author pages.*)

## Licensing

- **Words.** Articles are licensed
  [Creative Commons Attribution-ShareAlike 4.0
  International](https://creativecommons.org/licenses/by-sa/4.0/),
  unless an article overrides it in frontmatter. Republish with
  attribution and the same licence and you are welcome.
- **Code.** Templates, layouts, includes, and the SCSS design
  system are [MIT-licensed](https://opensource.org/license/mit/).

## Funding

- Reader support, processed without intermediaries who would
  collect tracking data.
- One-off grants from non-profit foundations whose mandates do
  not conflict with our coverage. Each grant is disclosed below
  the masthead within thirty days of receipt; the historical
  list lives in the [conflicts of interest log](/ethos/#conflicts).

We accept no advertising, no sponsored posts, no "media
partnerships", and no token grants — including stablecoin grants.
We do not run affiliate links.

## Acknowledgements

Open-source typefaces: SIL Open Font License contributors. Open-source
toolchain: the Jekyll, Ruby, GitHub Pages, kramdown, and Rouge
maintainers. Inspirations: *The Baffler*, *n+1*, *The London Review of
Books*, the printers of the underground press of every century.

— *The editors. Set in Source Serif 4 and Newsreader. Built {{ site.time | date: "%-d %B %Y" }}.*
