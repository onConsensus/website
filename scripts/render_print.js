#!/usr/bin/env node
/* render_print.js — turn _site/print/YYYY-MM/index.html into a
 * four-column broadsheet PDF at _site/print/YYYY-MM.pdf using
 * headless Chromium via Playwright.
 *
 * Usage:
 *   node scripts/render_print.js                # render every month
 *   node scripts/render_print.js 2026-04        # render one month
 *   node scripts/render_print.js --png 2026-04  # also rasterise PDF to
 *                                               # one PNG per page at
 *                                               # _site/print/2026-04-page-NN.png
 *                                               # (used by the broadsheet
 *                                               #  visual-regression check)
 *
 * The --png mode shells out to `pdftoppm` (poppler-utils). On CI we
 * install it via apt; locally `brew install poppler` or
 * `apt-get install poppler-utils` does the trick. Default raster DPI
 * is 120 — high enough to catch column-break, drop-cap and
 * `column-span: all` regressions, low enough that baselines stay
 * cheap to commit.
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
const { spawnSync } = require('child_process');

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
  const opts = browser.__renderOpts || {};
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

  if (opts.png) {
    rasterizePdf(out, ym, opts.pngDpi);
  }
  return true;
}

// Rasterise the PDF to one PNG per page using pdftoppm. Output files
// are written next to the PDF as `<ym>-page-NN.png` (zero-padded to
// match `pdftoppm -W 2`-style sort order). The broadsheet visual-
// regression workflow diffs these against committed baselines under
// `tests/broadsheet/baselines/`.
function rasterizePdf(pdfPath, ym, dpi) {
  const which = spawnSync('pdftoppm', ['-v'], { encoding: 'utf8' });
  if (which.error) {
    throw new Error('[render_print] --png requires pdftoppm (poppler-utils): ' + which.error.message);
  }
  // Clear any stale page PNGs from a previous run.
  for (const f of fs.readdirSync(PRINT_DIR)) {
    if (f.startsWith(`${ym}-page-`) && f.endsWith('.png')) {
      fs.unlinkSync(path.join(PRINT_DIR, f));
    }
  }
  const prefix = path.join(PRINT_DIR, `${ym}-page`);
  const r = spawnSync('pdftoppm', [
    '-r', String(dpi || 120),
    '-png',
    '-aa', 'yes',
    '-aaVector', 'yes',
    pdfPath,
    prefix
  ], { encoding: 'utf8' });
  if (r.status !== 0) {
    throw new Error('[render_print] pdftoppm failed: ' + (r.stderr || r.stdout || '').trim());
  }
  // pdftoppm names files `<prefix>-1.png` (or `-01.png` for >9 pages).
  // Normalise to a fixed two-digit zero-padded suffix so baselines
  // sort lexically and a 9→10 page transition doesn't reshuffle the
  // list.
  const pages = fs.readdirSync(PRINT_DIR)
    .filter((f) => f.startsWith(`${ym}-page-`) && f.endsWith('.png'));
  for (const f of pages) {
    const m = f.match(/^(.*-page-)(\d+)\.png$/);
    if (!m) continue;
    const padded = m[1] + m[2].padStart(2, '0') + '.png';
    if (padded !== f) {
      fs.renameSync(path.join(PRINT_DIR, f), path.join(PRINT_DIR, padded));
    }
  }
  const finalPages = fs.readdirSync(PRINT_DIR)
    .filter((f) => f.startsWith(`${ym}-page-`) && f.endsWith('.png'))
    .sort();
  console.log(`[render_print] rasterised ${finalPages.length} page(s) of ${ym}.pdf at ${dpi || 120} dpi`);
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

  // CLI: a single optional `YYYY-MM` positional, plus optional flags
  //   --png             also emit per-page PNGs of the rendered PDF
  //   --png-dpi=<n>     raster DPI for --png (default 120)
  const argv = process.argv.slice(2);
  const opts = { png: false, pngDpi: 120 };
  let positional = null;
  for (const a of argv) {
    if (a === '--png') opts.png = true;
    else if (a.startsWith('--png-dpi=')) opts.pngDpi = parseInt(a.split('=')[1], 10) || 120;
    else if (/^\d{4}-\d{2}$/.test(a)) positional = a;
    else {
      console.error(`[render_print] unrecognised arg: ${a}`);
      process.exit(2);
    }
  }
  const months = positional
    ? [positional]
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
  browser.__renderOpts = opts;
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
