# onConsensus Jekyll Site

## Overview
A fast, modern, mobile-friendly Jekyll blog/magazine site focused on decentralized futures, blockchain foundations, and consensus mechanisms. Based on the "VJs Mag" theme by Artem Sheludko.

## Tech Stack
- **Static Site Generator:** Jekyll 4.x (Ruby)
- **Styles:** Sass/SCSS (modular architecture in `_sass/`)
- **Templating:** Liquid
- **Package Manager:** Bundler (Ruby gems)
- **Plugins:** jekyll-paginate, jekyll-sitemap

## Project Structure
- `_config.yml` — Jekyll configuration, plugins, collections
- `_data/settings.yml` — Site-wide metadata, navigation, feature toggles
- `_includes/` — Reusable HTML partials (header, footer, head, etc.)
- `_layouts/` — Page templates (default, post, page, author)
- `_posts/` — Blog post markdown files
- `_pages/` — Static pages (About, Contact, etc.)
- `_authors/` — Author profiles collection
- `_sass/` — SCSS partials (Settings/Tools/Base/Modules/Layouts)
- `js/` — Client-side JS (common.js, scripts.js with vendor libs)
- `images/` — Static image assets

## Development
- Run: `bundle exec jekyll serve --host 0.0.0.0 --port 5000`
- The site is served on port 5000

## Deployment
- Type: Static site
- Build command: `bundle exec jekyll build`
- Public directory: `_site`

## External Services
- Disqus (comments)
- Mailchimp (newsletter)
- Formspree (contact forms)
- Google Analytics
