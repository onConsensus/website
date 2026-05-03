#!/usr/bin/env node
/* render_list_bundles.js — turn each
 *   _site/lists/<slug>/bundle/index.html
 * into a single A4 PDF at
 *   _site/lists/<slug>.pdf
 * using headless Chromium via Playwright.
 *
 * Usage:
 *   node scripts/render_list_bundles.js                # render every list
 *   node scripts/render_list_bundles.js <slug>         # render one list
 *
 * Reproducible locally:
 *   npm i -D playwright && npx playwright install --with-deps chromium
 *   ruby scripts/build_list_bundles.rb
 *   bundle exec jekyll build
 *   node scripts/render_list_bundles.js
 *
 * The static-server trick mirrors `render_print.js`: the bundle layout's
 * stylesheet at `/assets/css/list-bundle.css` is root-relative, so we
 * serve `_site/` over loopback HTTP rather than opening file:// URLs.
 */
'use strict';

const fs   = require('fs');
const http = require('http');
const path = require('path');

const SITE     = path.resolve(__dirname, '..', '_site');
const LISTS_DIR = path.join(SITE, 'lists');

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css':  'text/css; charset=utf-8',
  '.js':   'application/javascript; charset=utf-8',
  '.svg':  'image/svg+xml',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif':  'image/gif',
  '.webp': 'image/webp',
  '.woff': 'font/woff',
  '.woff2':'font/woff2',
  '.ttf':  'font/ttf',
  '.json': 'application/json'
};

function startStaticServer(root) {
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      try {
        let urlPath = decodeURIComponent(req.url.split('?')[0]);
        if (urlPath.endsWith('/')) urlPath += 'index.html';
        const fp = path.normalize(path.join(root, urlPath));
        if (!fp.startsWith(root)) { res.statusCode = 403; return res.end('forbidden'); }
        if (!fs.existsSync(fp) || fs.statSync(fp).isDirectory()) {
          const idx = path.join(fp, 'index.html');
          if (fs.existsSync(idx)) {
            res.setHeader('content-type', MIME['.html']);
            return res.end(fs.readFileSync(idx));
          }
          res.statusCode = 404; return res.end('not found: ' + urlPath);
        }
        const ext = path.extname(fp).toLowerCase();
        res.setHeader('content-type', MIME[ext] || 'application/octet-stream');
        res.end(fs.readFileSync(fp));
      } catch (e) {
        res.statusCode = 500;
        res.end('error: ' + e.message);
      }
    });
    server.on('error', reject);
    server.listen(0, '127.0.0.1', () => {
      const { port } = server.address();
      resolve({ server, port });
    });
  });
}

async function renderList(browser, baseUrl, slug) {
  const html = path.join(LISTS_DIR, slug, 'bundle', 'index.html');
  if (!fs.existsSync(html)) {
    console.warn(`[render_list_bundles] missing ${html} — did Jekyll build with the bundle stub?`);
    return false;
  }
  const out = path.join(LISTS_DIR, `${slug}.pdf`);
  const ctx = await browser.newContext();
  const page = await ctx.newPage();
  const url = `${baseUrl}/lists/${slug}/bundle/`;
  const resp = await page.goto(url, { waitUntil: 'networkidle' });
  if (!resp || !resp.ok()) {
    throw new Error(`[render_list_bundles] ${url} returned ${resp && resp.status()}`);
  }
  // Hard-fail if the bundle stylesheet didn't load — that means the PDF
  // would silently render unstyled, which is the regression class this
  // server is here to prevent.
  const cssOk = await page.evaluate(() => {
    return Array.from(document.styleSheets).some((s) =>
      (s.href || '').includes('/assets/css/list-bundle.css') &&
      s.cssRules && s.cssRules.length > 0
    );
  });
  if (!cssOk) {
    throw new Error('[render_list_bundles] bundle stylesheet did not load — aborting to avoid shipping an unstyled PDF');
  }
  await page.pdf({
    path: out,
    format: 'A4',
    printBackground: true,
    margin: { top: '18mm', right: '18mm', bottom: '22mm', left: '18mm' },
    displayHeaderFooter: true,
    headerTemplate:
      '<div style="font:8pt \'IBM Plex Mono\',monospace;color:#444;width:100%;padding:0 14mm;display:flex;justify-content:space-between;">' +
      '<span>On Consensus · Reading list</span><span>' + slug + '</span></div>',
    footerTemplate:
      '<div style="font:8pt \'IBM Plex Mono\',monospace;color:#444;width:100%;padding:0 14mm;text-align:center;">' +
      'Page <span class="pageNumber"></span> of <span class="totalPages"></span></div>'
  });
  await ctx.close();
  console.log('[render_list_bundles] wrote', path.relative(SITE, out));
  return true;
}

(async () => {
  let chromium;
  try {
    ({ chromium } = require('playwright'));
  } catch (e) {
    console.error('[render_list_bundles] playwright not installed: ' + e.message);
    console.error('  npm i -D playwright && npx playwright install --with-deps chromium');
    process.exit(2);
  }

  if (!fs.existsSync(LISTS_DIR)) {
    console.error(`[render_list_bundles] ${LISTS_DIR} missing — run \`bundle exec jekyll build\` first.`);
    process.exit(2);
  }

  const arg = process.argv[2];
  const slugs = arg
    ? [arg]
    : fs.readdirSync(LISTS_DIR)
        .filter((d) => fs.statSync(path.join(LISTS_DIR, d)).isDirectory())
        .filter((d) => fs.existsSync(path.join(LISTS_DIR, d, 'bundle', 'index.html')))
        .sort();

  if (!slugs.length) {
    console.log('[render_list_bundles] no list bundles found under', LISTS_DIR);
    return;
  }

  const { server, port } = await startStaticServer(SITE);
  const baseUrl = `http://127.0.0.1:${port}`;
  console.log(`[render_list_bundles] static server at ${baseUrl} (rooted at _site/)`);

  const browser = await chromium.launch();
  let ok = 0;
  try {
    for (const s of slugs) {
      if (await renderList(browser, baseUrl, s)) ok++;
    }
  } finally {
    await browser.close();
    await new Promise((r) => server.close(r));
  }
  console.log(`[render_list_bundles] rendered ${ok} of ${slugs.length} list(s)`);
})().catch((e) => {
  console.error('[render_list_bundles] fatal:', e);
  process.exit(1);
});
