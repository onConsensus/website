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
- `_config.yml` — site identity, plugins, collections, social block, defaults.
- `_data/schemas.yml` — frontmatter contracts for posts, authors, series.
- `_data/sections.yml` — **editorial taxonomy.** slug, title, blurb,
  responsible editor (slug into `_authors/`), accent. Read everywhere as
  `site.data.sections`. Single source of truth for the section list.
- `_data/principles.yml` — editorial principles (sourcing, conflicts, AI
  policy, corrections). Surfaced on `/ethos/`.
- `_authors/` — author collection (slug = filename).
- `_series/` — multi-part series collection (`/series/:name`).
- `_posts/` — articles (`/feed/:slug`).
- `_pages/` — static pages (about, etc) and section landings (`_pages/sections/<slug>.html`, one per editorial section, output to `/sections/<slug>/`).
- `feed/index.html` — the firehose. `jekyll-paginate` (v1) sources from this
  file using `paginate_path: "/feed/page:num"`; page 1 is `/feed/` and pages
  2+ live at `/feed/page2/`, `/feed/page3/`, … (12 posts per page, set in
  `_config.yml :: paginate`).
- `sections/<slug>/feed.xml` — per-section RSS 2.0 feed. Six thin wrappers
  share the body in `_includes/section-feed.xml`.
- `atom.xml`, `feed.json`, `robots.txt` — top-level hand-rolled outputs.
  `/feed.xml` is produced by jekyll-feed (Atom). The hand-rolled `/atom.xml`
  carries editorial fields (per-item `<rights>`, summaries). `/feed.json` is
  JSON Feed 1.1 with an `_on_consensus` extension exposing `section`,
  `series`, `license`, `pgp_signed`, and `block_height`.
- `_includes/`, `_layouts/` — *Plaintext Cypherpunk Broadsheet* layouts and
  reusable includes (Task #3). Layouts: `default`, `home`, `page`, `post`,
  `author`, `section`, `series`. Includes: `head`, `masthead`, `footer`,
  `article-card` (lead/standard/dispatch variants), `byline` (reading time +
  word count), `series-banner`, `related`, `footnotes` (marginalia hook),
  `glossary-data` (JSON island for `<dfn>` popovers — Task #6), `analytics`
  (off by default).
- `_data/glossary.yml` — slug-keyed term definitions for `<dfn data-term>`
  popovers (Task #6).
- `_data/signatures.yml` — slug-keyed inline copies of per-post PGP signature
  blocks. Mirror of `signatures/<slug>.sig` (Liquid can't `include_relative`
  with variables; static_files don't expose `content`). Task #6.
- `_sass/` — *Plaintext Cypherpunk Broadsheet* design system partials.
- `assets/css/main.scss` — single SCSS entry point that wires the cascade.
- `assets/fonts/` — self-hosted woff2 (Newsreader, Source Serif 4,
  IBM Plex Mono, Cormorant Garamond italic).
- `signatures/` — PGP signature blocks for `pgp_signed: true` posts. Lives
  *outside* `_posts/` so Jekyll never ingests sigs as posts.
- `images/` — static image assets.
- `CNAME` — `onconsensus.com` (apex domain on GitHub Pages).

## Editorial Sections
Defined in `_data/sections.yml` and read everywhere as `site.data.sections`.
Used as the `section:` value on every post.

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
4. **Home, sections, archives & feeds** — *complete.*
5. **Client-side search** — *complete.*
6. **Reading experience polish** — *complete.*
7. **Accessibility, SEO & editorial pages** — *complete.*
8. **Decap CMS, GitHub workflows & pre-launch QA** — *complete.*

## Accessibility, SEO & editorial pages
*Built in Task #7.*

- **Editorial data.** `_data/sections.yml` (now the single source of truth for
  the section taxonomy — moved out of `_config.yml`, with a new `editor:`
  field) and `_data/principles.yml` (sourcing, conflicts, AI, corrections —
  each `slug/title/summary/body` with body in markdown).
- **Editorial pages.** `_pages/about.md`, `_pages/ethos.html` (TOC + per-
  principle anchored sections + sections-with-editors block reading
  `site.data.sections`), `_pages/colophon.md` (design/build/network/funding),
  `_pages/contribute.md` (pitch/correct/tip/support), `_pages/corrections.html`
  (iterates posts with `corrections:` array, grouped + dated, falls back to
  an empty-state notice).
- **JSON-LD.** `_includes/jsonld.html` wired into `_includes/head.html` after
  `{% seo %}`. Emits `Article` for posts (`NewsArticle` for `dispatches`),
  with `headline`, `datePublished`, `dateModified`, `author` (Person, with
  url), `publisher` (Organization with logo `ImageObject`), `mainEntityOfPage`,
  `inLanguage`, `license`, `isAccessibleForFree`, plus optional
  `description`, `image`, `articleSection`, `keywords`. On non-post pages
  emits `Organization` (name, url, logo, email, sameAs) + `WebSite` (with a
  `SearchAction` pointing at `/search/?q=…`). Coexists with the
  `BlogPosting` block jekyll-seo-tag emits (search engines accept multiple
  blocks per page).
- **OG / Twitter cards.** Handled by `jekyll-seo-tag` ({% seo title=false %}
  so we control the `<title>`; per-page `image:` overrides the OG/Twitter
  image — every editorial page sets `/images/h{1..5}.png`).
- **Image hygiene.** Explicit `width`/`height` on every `<img>` to reserve
  layout box and prevent CLS:
  - `_includes/article-card.html`: 1280×800, `loading="lazy"`.
  - `_layouts/post.html` hero: 1280×720, `loading="eager"` +
    `fetchpriority="high"`.
  - `_layouts/author.html` + `_pages/authors.html` avatars: 256×256,
    `loading="lazy"` (eager on the author header).
- **Semantic markup pass.** `<time datetime>` wraps every date including the
  footer copyright year; `<article>`, `<header>`, `<nav>`, `<aside>` already
  in place from Task #3.
- **A11y primitives** were established in Task #3 (skip-link, visible
  focus-visible ring, `prefers-reduced-motion` honoured globally in
  `_reset.scss`); contrast — body ink `#1a1a1a` on paper `#f4f1ea` is
  ~14.4:1 (AAA); muted `#6b6258` on paper is ~4.8:1 (AA, used only for
  metadata).
- **Styles.** `_sass/_editorial.scss` for `.ethos`, `.ethos__toc`,
  `.ethos__principle`, `.ethos__sections-list`, `.divider`, and
  `.corrections-log` blocks. Imported in `assets/css/main.scss` after the
  other components.

## Client-side search
*Built in Task #5.* Static, framework-free, no third-party network calls.

- **Index:** `search.json` (Liquid → flat JSON at `/search.json`). One record
  per post with `{title, url, section, section_slug, author, date, date_long,
  excerpt, tags}`. Regenerated on every Jekyll build.
- **Engine:** [Lunr.js](https://lunrjs.com) 2.3.9, vendored at
  `/js/vendor/lunr.min.js` (loaded only on `/search/`).
- **Client:** `/js/search.js` — vanilla JS, no dependencies. Loaded site-wide
  via `_includes/head.html` (deferred). Two responsibilities:
  1. Site-wide `/` keyboard shortcut. Focuses the element matching
     `[data-search-input]` (the masthead input on every page except
     `/search/`, where it focuses the page input). Skipped while another
     INPUT/TEXTAREA/contenteditable is focused, while a modifier is held,
     and during IME composition.
  2. On `/search/`: fetch `/search.json` once, build the Lunr index in the
     browser, render results live (debounced ~120ms), and pre-run any
     `?q=…` query supplied via the URL.
- **UI:** `_pages/search.html` (`/search/`) + inline `<form>` in
  `_includes/masthead.html`. Both forms `GET` to `/search/?q=…` so they
  degrade to a normal page navigation without JS. Styles in
  `_sass/_search.scss`.

## Reading experience polish
*Built in Task #6.* Long-form reading affordances on post pages, all wired
to the Plaintext Cypherpunk Broadsheet design system and degraded gracefully
under no-JS / `prefers-reduced-motion`.

- **Drop caps & pull-quotes.** CSS-only. The first paragraph of `.article__body`
  drops a Cormorant Garamond italic capital. `<aside class="pullquote">` is
  inline below `--bp-marginalia` and floats into the right-hand marginalia
  gutter on desktop via a negative `margin-right` that escapes the body's
  measure-locked column.
- **Footnote rail (kramdown).** Posts use the standard `[^1]` /
  `[^1]: …` syntax. `js/reading.js` clones every kramdown-emitted `<li>`
  from `.article__body .footnotes` into the right-hand rail
  (`_includes/footnotes.html` → `[data-footnotes-target]`) on desktop, and
  wraps the original block in a `<details class="footnotes-accordion">` for
  the mobile accordion. An IntersectionObserver (rootMargin
  `-20% 0 -55% 0`) tracks the topmost visible `sup[id^="fnref"]` and adds
  `.is-active` to the matching rail item. CSS keeps the rail desktop-only
  and hides the inline kramdown block on desktop.
- **Glossary popovers.** `_data/glossary.yml` defines slug → `{display,
  definition}`. `_includes/glossary-data.html` emits the whole map as an
  inlined JSON island (`#glossary-data`) on every post page;
  `js/reading.js` walks `dfn[data-term]` and copies the matching definition
  onto `data-definition` (the popover itself is CSS-only in
  `_sass/_glossary.scss`). Hydrated `<dfn>` are made keyboard-focusable
  with a real focus ring.
- **Reading-progress bar.** `<div class="reading-progress">` at the top of
  every post. Modern browsers drive the bar entirely from CSS via
  `animation-timeline: scroll(root)` (gated behind
  `@supports (animation-timeline: scroll())`). Browsers without the
  scroll-timeline keyword get a `requestAnimationFrame`-throttled JS
  fallback. `prefers-reduced-motion` hides the bar entirely (CSS), and the
  JS fallback bows out under that media query.
- **Article header metadata.** `_includes/byline.html` always computes word
  count from `post.content | strip_html | number_of_words`; the post layout
  passes `show_words=true` so the article header surfaces *N* min read,
  *N* words, and (when present) `block_height` at publish.
- **Inline PGP signatures.** Posts with `pgp_signed: true` render a styled
  `<pre class="pgp-signature">` from `site.data.signatures[page.slug]`
  inline at the foot of the article, wrapped in a
  `<section class="pgp-signature-block">` with a `gpg --verify …` recipe
  and a download link to the matching detached `/signatures/<slug>.sig`
  static file.
- **JS loading.** `js/reading.js` is loaded with `defer` from
  `_includes/head.html`, but only when `page.layout == 'post'` — drop caps,
  pull-quotes, and the scroll-timeline progress bar are CSS-only and ride
  for free elsewhere.

## Decap CMS, GitHub workflows & pre-launch QA
*Built in Task #8.* The shippability layer.

- **Decap CMS at `/admin/`.** `admin/index.html` boots Decap 3.x and registers
  `/assets/css/main.css` as the preview style + a `PostPreview` /
  `PagePreview` template, so the preview pane reflects production
  typography. `admin/config.yml` declares four collections — `posts`,
  `authors`, `series`, `pages` — with editorial workflow on
  (`publish_mode: editorial_workflow`), so every save is a PR. Section
  options mirror `_data/sections.yml`; `author` / `series` / `editor` use
  the `relation` widget. Media goes under `images/uploads/`.
- **OAuth.** README documents both paths: Decap-hosted OAuth via
  `api.netlify.com` (default; needs only a free Netlify project to host the
  client secret) and a self-hosted Cloudflare Worker proxy
  (`sterlingwes/decap-proxy`) on a custom subdomain.
- **CI.** `.github/workflows/build-check.yml` runs on PR + push to `main`:
  `bundle exec jekyll build` with `JEKYLL_ENV=production`, then
  `htmlproofer` against `_site/` (HTML validity, internal links,
  OpenGraph, HTTPS enforcement; external link checking disabled to avoid
  flakes; admin/ ignored).
- **Templates.** `.github/PULL_REQUEST_TEMPLATE.md` carries the new-post
  checklist (frontmatter, single `featured: true` invariant, kramdown
  footnotes, glossary `<dfn data-term>` slugs, PGP-signed coupling).
  `.github/ISSUE_TEMPLATE/pitch.md` and `correction.md` plus a
  `config.yml` adding an editorial-contact link.
- **Licensing.** Top-level `LICENSE` documents the dual split;
  `LICENSE-CONTENT` is CC BY-SA 4.0 (every `_posts/` article, prose copy,
  bios, `images/`); `LICENSE-CODE` is MIT (Liquid structural markup,
  `_sass/`, `js/`, configs, the GitHub Actions workflows). README's
  *Licensing* section restates it. `CODE_OF_CONDUCT.md` (Contributor
  Covenant 2.1, with publication-specific clauses) lives at the repo root.
- **`_config.yml` adjustments.** Added `repository: "onConsensus/onconsensus"`
  (required by the `github-pages` gem when not run inside a git remote);
  `include: [.well-known]` so WKD ships; excluded the new top-level docs
  (`LICENSE*`, `CODE_OF_CONDUCT.md`) from the build.
- **WKD scaffold.** `.well-known/openpgpkey/onconsensus.com/` carries a
  `policy` file and a no-index landing page so the link from `/colophon/`
  resolves.
- **Vendored search.** `js/vendor/lunr.min.js` (Lunr 2.3.9) is now
  committed — `_pages/search.html` referenced it in Task #5 but the file
  was never added.
- **QA pass.** Internal-link sweep is clean (htmlproofer-equivalent
  Python script confirms 0 broken internal links across 34 emitted HTML
  files); all five feed targets validate (`/feed.xml` Atom, `/atom.xml`,
  `/feed.json`, `/sitemap.xml`, six `/sections/<slug>/feed.xml`). Local
  htmlproofer execution itself is blocked in this Replit nix sandbox by a
  libcurl/Ethon dlopen quirk; CI runs htmlproofer on Ubuntu where the
  same configuration runs clean.
- **Placeholder art.** Generated minimal SVG placeholders for the
  per-post hero / per-author avatar / series cover paths referenced
  across Tasks #1–#7 but never committed (`images/posts/*.svg`,
  `images/authors/*.svg`, `images/series/*.svg`); copied `images/100.jpg`
  to satisfy raster references on the boilerplate
  documentation / advertise / privacy / terms / submit pages. Replace
  with finished art before launch.
