<!--
Thanks for filing a pull request against On Consensus. This template
covers the most common case (a new post). For docs / code / design PRs,
delete the post checklist and write a short description in its place.
-->

## What & why

<!-- One paragraph. What does this PR change, and what problem does it solve? -->

## New post checklist

- [ ] Filename matches `YYYY-MM-DD-slug.md` and lives in `_posts/`.
- [ ] Frontmatter has the four required fields: `title`, `author`, `date`, `section`.
- [ ] `section:` is one of: `governance`, `research`, `development`, `cryptography`, `culture`, `dispatches`.
- [ ] `author:` is the slug of an entry in `_authors/`.
- [ ] `excerpt:` is set (~155 chars) — feeds, cards, and meta description use it.
- [ ] `featured_image:` and `featured_caption:` are set if a hero image is used (1280×720 ideal).
- [ ] No more than **one** post in the repo has `featured: true`. If this is the new lead, the previous lead has been demoted.
- [ ] Footnotes use kramdown syntax: `[^1]` inline, `[^1]: …` block.
- [ ] Glossary terms link via `<dfn data-term="slug">term</dfn>` and the slug exists in `_data/glossary.yml`.
- [ ] If `pgp_signed: true`, a matching `signatures/<slug>.sig` and `_data/signatures.yml` entry exist.
- [ ] If cross-posted, `canonical_url:` points to the original.
- [ ] Tags are lowercased and hyphenated.

## Editorial review

- [ ] Sources are linked or named in-line; no anonymous claims of fact.
- [ ] Author conflicts of interest declared in-line where relevant (see `/ethos/`).
- [ ] Corrections to existing posts go in the post's `corrections:` array, dated, with a one-line note.

## Build

- [ ] `bundle exec jekyll build` runs clean locally.
- [ ] The CI `build-check` workflow is green (Jekyll build + htmlproofer).
