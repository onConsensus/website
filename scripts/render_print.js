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
const path = require('path');

const SITE = path.resolve(__dirname, '..', '_site');
const PRINT_DIR = path.join(SITE, 'print');

async function renderMonth(browser, ym) {
  const html = path.join(PRINT_DIR, ym, 'index.html');
  if (!fs.existsSync(html)) {
    console.warn(`[render_print] missing ${html} — did Jekyll build?`);
    return false;
  }
  const out = path.join(PRINT_DIR, `${ym}.pdf`);
  const ctx = await browser.newContext();
  const page = await ctx.newPage();
  await page.goto('file://' + html, { waitUntil: 'networkidle' });
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

  const browser = await chromium.launch();
  let ok = 0;
  try {
    for (const m of months) {
      if (await renderMonth(browser, m)) ok++;
    }
  } finally {
    await browser.close();
  }
  console.log(`[render_print] rendered ${ok} of ${months.length} month(s)`);
})().catch((e) => {
  console.error('[render_print] fatal:', e);
  process.exit(1);
});
