# Vendored KaTeX

Version **0.16.11**, MIT licensed (see `LICENSE.txt`).

Provenance: extracted from the official npm tarball `katex@0.16.11`
(`npm pack katex@0.16.11`, shasum `4bc84d5584f996abece5f01c6ad11304276a33f5`),
which ships the prebuilt `dist/`. The GitHub repository contains source only —
`dist/` is produced by the project's rollup build and is not committed there.

Vendored, not loaded from a CDN, for the same reason the body faces and
Lunr are vendored: pages on this site make no third-party network calls. See
`_includes/head.html` and `js/search.js`.

## What is here, and what was left out

| Kept | Why |
| --- | --- |
| `katex.min.js` | The renderer. |
| `katex.min.css` | Unmodified upstream. |
| `fonts/*.woff2` | 20 faces, ~296 KB. |

The upstream `dist/fonts/` also ships `.woff` and `.ttf` of every face, tripling
the payload to ~1.2 MB. Those are omitted. `katex.min.css` still lists them in
each `@font-face` `src:`, which is deliberate and harmless: `woff2` is listed
first, every browser that can run this site supports it, and a browser stops at
the first `src` entry it can load — so the absent files are never requested. The
CSS is left byte-identical to upstream so a version bump is a straight recopy.

`contrib/auto-render.min.js` is **not** vendored. Auto-render scans prose text
nodes for `$` delimiters, which would mangle ordinary currency in copy — a real
hazard on a publication that writes about fee markets and block subsidies.
Instead kramdown marks math explicitly (`math_engine: ~` in `_config.yml`
emits `.kdmath` wrappers) and `js/math.js` renders only those elements.

Note kramdown's wrappers are not symmetric: a block `<div class="kdmath">`
retains the full `$$…$$`, while an inline `<span class="kdmath">` comes back
with a single `$…$`. `js/math.js` strips whichever pair is present.

## Upgrading

```
npm pack katex@<version>
tar xzf katex-<version>.tgz
cp package/dist/katex.min.js package/dist/katex.min.css assets/katex/
cp package/dist/fonts/*.woff2 assets/katex/fonts/
cp package/LICENSE assets/katex/LICENSE.txt
```

Then update the version at the top of this file.
