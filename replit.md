# On Consensus

## Overview
**On Consensus** (onconsensus.com) is an editorial publication on
decentralized & distributed technologies — governance, research, development,
cryptography, and culture. Static site, Jekyll-only, designed to ship from
GitHub Pages without a Node toolchain.

Aesthetic: *Plaintext Cypherpunk Broadsheet*. No hype, no gradients.

## Tech Stack
- **Static site generator:** Jekyll 3.10.0 (pinned via the `github-pages` gem,
  the same runtime GitHub Pages uses).
- **Plugins (GitHub-Pages allow-list only):** `jekyll-feed`, `jekyll-seo-tag`,
  `jekyll-redirect-from`, `jekyll-sitemap`, `jekyll-paginate`.
- **Templating:** Liquid.
- **Styles:** Sass/SCSS — *Plaintext Cypherpunk Broadsheet* design system
  living in `_sass/` and entered through `assets/css/main.scss`. Self-hosted
  woff2 fonts under `assets/fonts/`. See "Design system" below.
- **Package manager:** Bundler.
- **No Node toolchain.** No npm, no Webpack, no Vite — by design.

## Project Structure
- `_config.yml` — site identity, plugins, collections, **sections taxonomy**,
  social block, defaults.
- `_data/schemas.yml` — frontmatter contracts for posts, authors, series.
- `_authors/` — author collection (slug = filename).
- `_series/` — multi-part series collection (`/series/:name`).
- `_posts/` — articles (`/feed/:slug`).
- `_pages/` — static pages (about, etc).
- `_includes/`, `_layouts/` — *Plaintext Cypherpunk Broadsheet* layouts and
  reusable includes (Task #3). Layouts: `default`, `home`, `page`, `post`,
  `author`, `section`, `series`. Includes: `head`, `masthead`, `footer`,
  `article-card` (lead/standard/dispatch variants), `byline` (with reading
  time), `series-banner`, `related`, `footnotes` (marginalia hook),
  `analytics` (off by default).
- `_sass/` — *Plaintext Cypherpunk Broadsheet* design system partials.
- `assets/css/main.scss` — single SCSS entry point that wires the cascade.
- `assets/fonts/` — self-hosted woff2 (Newsreader, Source Serif 4,
  IBM Plex Mono, Cormorant Garamond italic).
- `signatures/` — PGP signature blocks for `pgp_signed: true` posts. Lives
  *outside* `_posts/` so Jekyll never ingests sigs as posts.
- `images/` — static image assets.
- `CNAME` — `onconsensus.com` (apex domain on GitHub Pages).

## Editorial Sections
Defined in `_config.yml` under `sections:` and used as the `section:` value on
every post.

| Slug          | Title          |
| ------------- | -------------- |
| `governance`  | Governance     |
| `research`    | Research       |
| `development` | Development    |
| `cryptography`| Cryptography   |
| `culture`     | Culture        |
| `dispatches`  | Dispatches (link-blog) |

## Social
Decentralized stack only — no X/Twitter, by editorial decision. Mastodon,
Bluesky, Nostr, GitHub, Farcaster, RSS.

## Development
- Run: `bundle exec jekyll serve --host 0.0.0.0 --port 5000`
- Workflow `Start application` runs this on port 5000.

## Deployment
- Type: Static site (GitHub Pages-compatible).
- Build command: `bundle exec jekyll build`.
- Public directory: `_site`.
- Apex domain: `onconsensus.com` (CNAME committed).

## Design system — Plaintext Cypherpunk Broadsheet
*Built in Task #2.* All visual tokens live in CSS custom properties on `:root`
so dark/print modes inherit them and Liquid never has to know about colour.

- **Entry:** `assets/css/main.scss` (front-matter triggers Jekyll's SCSS
  converter; output → `/assets/css/main.css`).
- **Cascade order:** `_tokens` → `_reset` → `_typography` → `_layout` →
  components (`_masthead`, `_card`, `_article`, `_author`, `_pagination`,
  `_glossary`, `_code`) → modes (`_dark`, `_print`) → `_utilities`.
- **Palette:** paper `#f4f1ea`, ink `#1a1a1a`, accent `#b8412e`,
  muted `#6b6258`, highlight `#e8dfc9`. Dark mode inverts and softens the red.
- **Type stack (self-hosted woff2, `font-display: swap`):** Newsreader
  (display), Source Serif 4 (body, 19px / 1.65), IBM Plex Mono (UI / metadata),
  Cormorant Garamond italic (drop caps & section openers). Body face +
  display 700 + mono 400 are `<link rel="preload">`-ed in `<head>`.
- **Fluid type scale:** `clamp()` based on a 1.250 (major third) ratio,
  anchored 17px → 19px between 320px and 1280px viewports.
- **Layout:** 12-col CSS grid container, fixed 680px reading measure,
  right-hand marginalia gutter (`14rem`) activates above 72em — the Reading
  Experience task wires footnotes / pull-quotes / glossary popovers into it.
- **Sass runtime caveat:** the github-pages gem pins
  `jekyll-sass-converter 1.5.2` (Ruby Sass 3.7.4 — pre-modules), so the
  partials are wired with `@import`. The architecture is Dart-Sass-friendly
  (no `nth()` / `math.div()` / colour arithmetic on Sass variables — every
  dynamic value is a CSS custom property), so a future migration to Dart Sass
  + `@use` is a one-pass refactor of `assets/css/main.scss` alone.

## Roadmap (Tasks)
1. **Foundation: config, collections & seed content** — *complete.*
2. **Design system: Plaintext Cypherpunk Broadsheet SCSS** — *complete.*
3. **Layouts & includes** — *complete.*
4. Home, sections, archives & feeds.
5. Client-side search.
6. Reading experience polish.
7. Accessibility, SEO & editorial pages.
8. Decap CMS, GitHub workflows & pre-launch QA.
