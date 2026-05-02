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
- **Styles:** Sass/SCSS (legacy `_sass/` from prior theme; will be replaced in
  Task #2 — Design system).
- **Package manager:** Bundler.
- **No Node toolchain.** No npm, no Webpack, no Vite — by design.

## Project Structure
- `_config.yml` — site identity, plugins, collections, **sections taxonomy**,
  social block, defaults.
- `_data/schemas.yml` — frontmatter contracts for posts, authors, series.
- `_data/settings.yml` — legacy theme settings (header menu, footer widgets);
  to be retired in Tasks #2/#3.
- `_authors/` — author collection (slug = filename).
- `_series/` — multi-part series collection (`/series/:name`).
- `_posts/` — articles (`/feed/:slug`).
- `_pages/` — static pages (about, etc).
- `_includes/`, `_layouts/` — current layouts are inherited from the legacy
  *VJs Mag* theme and will be fully replaced in Task #3.
- `_sass/` — legacy SCSS, to be replaced in Task #2.
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

## Roadmap (Tasks)
1. **Foundation: config, collections & seed content** — *complete.*
2. Design system: Plaintext Cypherpunk Broadsheet SCSS.
3. Layouts & includes.
4. Home, sections, archives & feeds.
5. Client-side search.
6. Reading experience polish.
7. Accessibility, SEO & editorial pages.
8. Decap CMS, GitHub workflows & pre-launch QA.
