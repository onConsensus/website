#!/usr/bin/env node
/* render_print.js — turn _site/print/YYYY-MM/index.html into a
 * four-column broadsheet PDF at _site/print/YYYY-MM.pdf using
 * headless Chromium via Playwright.
 *
 * Usage:
 *   node scripts/render_print.js                # render every month
 *   node scripts/render_print.js 2026-04        # render one month
 *
 * Reproducible locally:
 *   npm i -D playwright && npx playwright install --with-deps chromium
 *   bundle exec jekyll build
 *   node scripts/render_print.js
 */
'use strict';

const fs   = require('fs');
const http = require('http');
const path = require('path');

const SITE = path.resolve(__dirname, '..', '_site');
const PRINT_DIR = path.join(SITE, 'print');

// Mime map sufficient for what the broadsheet ever loads. Chromium
// only fetches CSS, fonts, and inline images; we don't need a full
// table.
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

// Serve _site/ over HTTP so the broadsheet's root-relative
// stylesheet (`/assets/css/broadsheet.css`) and any image refs
// resolve. file:// would map `/assets/...` to the filesystem root,
// which is the bug we're avoiding.
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

async function renderMonth(browser, baseUrl, ym) {
  const html = path.join(PRINT_DIR, ym, 'index.html');
  if (!fs.existsSync(html)) {
    console.warn(`[render_print] missing ${html} — did Jekyll build?`);
    return false;
  }
  const out = path.join(PRINT_DIR, `${ym}.pdf`);
  const ctx = await browser.newContext();
  const page = await ctx.newPage();
  const url = `${baseUrl}/print/${ym}/`;
  const resp = await page.goto(url, { waitUntil: 'networkidle' });
  if (!resp || !resp.ok()) {
    throw new Error(`[render_print] ${url} returned ${resp && resp.status()}`);
  }
  // Hard-fail if the broadsheet stylesheet didn't load — that means
  // the PDF would silently render unstyled, which is the regression
  // class this server is here to prevent.
  const cssOk = await page.evaluate(() => {
    return Array.from(document.styleSheets).some((s) =>
      (s.href || '').includes('/assets/css/broadsheet.css') &&
      s.cssRules && s.cssRules.length > 0
    );
  });
  if (!cssOk) {
    throw new Error('[render_print] broadsheet stylesheet did not load — aborting to avoid shipping an unstyled PDF');
  }
  await page.pdf({
    path: out,
    width: '297mm',
    height: '420mm',
    printBackground: true,
    margin: { top: '20mm', right: '14mm', bottom: '20mm', left: '14mm' },
    displayHeaderFooter: true,
    headerTemplate:
      '<div style="font:8pt \'IBM Plex Mono\',monospace;color:#444;width:100%;padding:0 14mm;display:flex;justify-content:space-between;">' +
      '<span>On Consensus</span><span>' + ym + '</span></div>',
    footerTemplate:
      '<div style="font:8pt \'IBM Plex Mono\',monospace;color:#444;width:100%;padding:0 14mm;text-align:center;">' +
      'Page <span class="pageNumber"></span> of <span class="totalPages"></span></div>'
  });
  await ctx.close();
  console.log('[render_print] wrote', path.relative(SITE, out));
  return true;
}

(async () => {
  let chromium;
  try {
    ({ chromium } = require('playwright'));
  } catch (e) {
    console.error('[render_print] playwright not installed: ' + e.message);
    console.error('  npm i -D playwright && npx playwright install --with-deps chromium');
    process.exit(2);
  }

  if (!fs.existsSync(PRINT_DIR)) {
    console.error(`[render_print] ${PRINT_DIR} missing — run \`bundle exec jekyll build\` first.`);
    process.exit(2);
  }

  const arg = process.argv[2];
  const months = arg
    ? [arg]
    : fs.readdirSync(PRINT_DIR)
        .filter((d) => /^\d{4}-\d{2}$/.test(d))
        .filter((d) => fs.statSync(path.join(PRINT_DIR, d)).isDirectory())
        .sort();

  if (!months.length) {
    console.log('[render_print] no months found under', PRINT_DIR);
    return;
  }

  const { server, port } = await startStaticServer(SITE);
  const baseUrl = `http://127.0.0.1:${port}`;
  console.log(`[render_print] static server at ${baseUrl} (rooted at _site/)`);

  const browser = await chromium.launch();
  let ok = 0;
  try {
    for (const m of months) {
      if (await renderMonth(browser, baseUrl, m)) ok++;
    }
  } finally {
    await browser.close();
    await new Promise((r) => server.close(r));
  }
  console.log(`[render_print] rendered ${ok} of ${months.length} month(s)`);
})().catch((e) => {
  console.error('[render_print] fatal:', e);
  process.exit(1);
});
