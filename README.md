# On Consensus

> An editorial publication on decentralized & distributed technologies —
> governance, research, development, cryptography, and culture.
> No hype, no gradients, just the wire.

Production: **<https://onconsensus.com>**

A static, Jekyll-only site designed to ship from GitHub Pages with no
Node toolchain. Aesthetic: *Plaintext Cypherpunk Broadsheet*.

---

## Local development

The site is plain Jekyll on the GitHub-Pages allow-list of plugins.

```bash
bundle install
bundle exec jekyll serve --host 0.0.0.0 --port 5000
```

The Replit "Start application" workflow runs the same command on
port 5000. Build a production bundle with:

```bash
JEKYLL_ENV=production bundle exec jekyll build
```

Output lands in `_site/`. CI runs the same command and then validates
the result with `htmlproofer` (see
`.github/workflows/build-check.yml`).

## Repository layout

| Path | What lives there |
| ---- | ---------------- |
| `_config.yml` | Site identity, plugins, collections, defaults. |
| `_posts/` | Articles. `YYYY-MM-DD-slug.md`. Permalink: `/feed/:slug`. |
| `_authors/`, `_series/`, `_pages/` | Collections. |
| `_data/` | `sections.yml` (taxonomy), `principles.yml`, `schemas.yml`, `glossary.yml`, `signatures.yml`. |
| `_layouts/`, `_includes/` | Liquid templates. |
| `_sass/`, `assets/css/main.scss` | *Plaintext Cypherpunk Broadsheet* design system. |
| `assets/fonts/` | Self-hosted woff2. |
| `signatures/` | Detached PGP signatures (kept outside `_posts/` so Jekyll never ingests them). |
| `admin/` | Decap CMS — editorial admin (see below). |
| `.github/` | PR and issue templates, build-check workflow. |
| `CNAME` | Apex domain pin (`onconsensus.com`). |

`replit.md` carries the deeper architectural notes — read it before
making structural changes.

## Editorial workflow

Three states, all backed by GitHub pull requests:

1. **Draft** — opened in `/admin/` (Decap) or by hand. PR labelled `draft`.
2. **In review** — editor has assigned themselves; copy-edit and fact-check
   in progress.
3. **Ready** — passes the PR checklist
   (`.github/PULL_REQUEST_TEMPLATE.md`) and the `build-check` workflow,
   then merges to `main`.

Pitches go through `.github/ISSUE_TEMPLATE/pitch.md`; corrections through
`correction.md`. Editorial principles are documented at
[`/ethos/`](https://onconsensus.com/ethos/).

## Decap CMS — `/admin/`

Non-developer authors edit through Decap CMS at
[`/admin/`](https://onconsensus.com/admin/). Decap commits to a branch
on GitHub and the editorial-workflow toggle in
`admin/config.yml` makes every save a pull request — the same path
developers take.

Collections mirror the repo: **posts**, **authors**, **series**,
**pages**. The preview pane registers `/assets/css/main.css` and a
`PostPreview` template so what editors see in `/admin/` matches the
published article on production.

### Authentication

Decap needs a GitHub OAuth handshake. We support two paths.

#### Option A — Decap-hosted OAuth (default)

The repo ships configured to use Decap's hosted OAuth gateway via
`base_url: https://api.netlify.com` and `auth_endpoint: auth` in
`admin/config.yml`. To use it:

1. Create a GitHub OAuth App at
   <https://github.com/settings/developers>.
   - **Homepage URL:** `https://onconsensus.com`
   - **Authorization callback URL:**
     `https://api.netlify.com/auth/done`
2. Sign in to Netlify (free tier is enough — the site itself stays on
   GitHub Pages) and add the OAuth App's **Client ID** and **Client
   Secret** under *Site settings → Access control → OAuth → Install
   provider*.
3. Visit `https://onconsensus.com/admin/`. The login button hands off
   to Netlify's gateway, which hands off to GitHub, then back. Decap
   is gated by repository write permission — invite editors to the
   `onConsensus/onconsensus` repo and they can sign in.

This is the lowest-overhead path. The only Netlify dependency is the
OAuth proxy.

#### Option B — Cloudflare Worker proxy (self-hosted)

If you want zero Netlify dependency, run your own OAuth proxy. A
single Cloudflare Worker is enough.

1. Create the same kind of GitHub OAuth App as above. Set the callback
   URL to
   `https://oauth.onconsensus.com/callback` (or whichever route you
   choose).
2. Deploy a Worker that implements the
   [Decap external OAuth handshake][decap-oauth]. There is a
   maintained reference implementation:
   [`sterlingwes/decap-proxy`][decap-proxy]. Configure it with your
   GitHub OAuth Client ID + Secret as Worker secrets.
3. Bind the Worker to a route on your domain (e.g.
   `oauth.onconsensus.com/*`).
4. Override the backend block in `admin/config.yml`:

   ```yaml
   backend:
     name: github
     repo: onConsensus/onconsensus
     branch: main
     base_url: https://oauth.onconsensus.com
     auth_endpoint: auth
   ```

5. Visit `/admin/`. The login button now hands off to your Worker
   instead of Netlify's gateway.

Either path keeps the OAuth client secret off the static site —
Decap, the static site, and the editor never see it. Only the proxy
does.

[decap-oauth]: https://decapcms.org/docs/external-oauth-clients/
[decap-proxy]: https://github.com/sterlingwes/decap-proxy

## Continuous integration

`.github/workflows/build-check.yml` runs on every pull request and
push to `main`:

1. `bundle exec jekyll build` with `JEKYLL_ENV=production`.
2. `htmlproofer` against `_site/` — internal links, image refs, HTML
   validity, OpenGraph tags, HTTPS enforcement.

External link checks are disabled in CI to avoid flakes from
third-party outages; rerun `htmlproofer` locally without
`--disable-external` before a release if you want to sweep them.

## Licensing

The repository is **dual-licensed**:

- **Editorial content** (every `_posts/` article, the prose copy in
  layouts / includes / `_pages/`, author bios, series notes, images
  under `images/`) is licensed under
  **[CC BY-SA 4.0](./LICENSE-CONTENT)**.
- **Code, configuration, and stylesheets** (Liquid structural markup,
  `_sass/`, `js/`, `_config.yml`, `admin/config.yml`, the GitHub
  Actions workflows, the Jekyll chassis) is licensed under the
  **[MIT License](./LICENSE-CODE)**.

When a single file mixes prose and code, the prose portion is
CC BY-SA 4.0 and the structural portion is MIT. See [`LICENSE`](./LICENSE)
for the dual-license notice.

The On Consensus name, masthead, and logo are **not** licensed for
reuse.

## Contributing

- Read the [Code of Conduct](./CODE_OF_CONDUCT.md).
- File a pitch via the **Pitch** issue template.
- File a correction via the **Correction** issue template.
- Open a pull request with the new-post checklist filled in.
- Pitches and corrections that go nowhere because nobody could fact-check
  them go nowhere.

## Contact

Editorial: **editors@onconsensus.com**.
For sources, embargoes, and retractions, prefer encrypted mail — PGP
fingerprints are listed on each author's page.
