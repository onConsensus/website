#!/usr/bin/env node
// visual_diff.js — Playwright-driven screenshot comparator for PR preview deploys.
//
// Behaviour
//   1. Walks a curated list of canonical pages on $PREVIEW_URL.
//   2. Captures a viewport-fixed PNG of each (1280x900, scaled
//      device pixel ratio 1).
//   3. If $BASELINES_EXIST=true, diffs against `baselines/<slug>.png`
//      using pixelmatch and writes `diffs/<slug>.png`. Pages whose
//      diff exceeds DIFF_THRESHOLD_PCT are recorded as regressed.
//   4. Emits `visual-diff-report.md` for the PR comment. When
//      $IMAGE_BASE_URL is set, the report embeds inline images
//      (current screenshot + diff overlay) for every regressed
//      page. The image-publishing step in `preview.yml` pushes the
//      images to a public `pr-screenshots` branch and passes that
//      branch's raw.githubusercontent.com base.
//
// The page list is intentionally small — the goal is to catch
// layout-relevant regressions on representative templates, not to
// fingerprint every URL.

const { chromium } = require('@playwright/test');
const fs   = require('fs');
const path = require('path');
const { PNG } = require('pngjs');
const pixelmatch = require('pixelmatch');

const PREVIEW_URL     = (process.env.PREVIEW_URL     || '').replace(/\/+$/, '');
const BASELINES_EXIST = process.env.BASELINES_EXIST  === 'true';
const IMAGE_BASE_URL  = (process.env.IMAGE_BASE_URL  || '').replace(/\/+$/, '');

if (!PREVIEW_URL) {
  console.error('[visual-diff] PREVIEW_URL is required');
  process.exit(1);
}

const PAGES = [
  { slug: 'home',        url: '/' },
  { slug: 'feed',        url: '/feed/' },
  { slug: 'section',     url: '/sections/research/' },
  { slug: 'article',     url: '/feed/folding-schemes-without-romance' },
  { slug: 'author',      url: '/m-vellum/' },
  { slug: 'series',      url: '/series/notes-on-rollup-centralization/' },
  { slug: 'tags-index',  url: '/tags/' },
  { slug: 'tag',         url: '/tags/zk/' },
  { slug: 'glossary',    url: '/glossary/' },
  { slug: 'lists',       url: '/lists/' },
  { slug: 'list',        url: '/lists/rollup-centric-ethereum-from-first-principles/' },
  { slug: 'standards',   url: '/standards/' },
];

const VIEWPORT = { width: 1280, height: 900 };
const DIFF_THRESHOLD_PCT = 0.5;  // pixel difference > 0.5% triggers a flag

async function main() {
  fs.mkdirSync('screenshots', { recursive: true });
  fs.mkdirSync('diffs',       { recursive: true });

  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: VIEWPORT, deviceScaleFactor: 1 });
  const page    = await context.newPage();

  const rows = [];
  for (const entry of PAGES) {
    const target = PREVIEW_URL + entry.url;
    const shotPath = `screenshots/${entry.slug}.png`;
    let status = 'ok', diffPct = null;

    try {
      const resp = await page.goto(target, { waitUntil: 'networkidle', timeout: 30_000 });
      if (!resp || !resp.ok()) {
        status = `http ${resp ? resp.status() : 'no-response'}`;
      } else {
        await page.waitForTimeout(400); // settle webfonts
        await page.screenshot({ path: shotPath, fullPage: false });
      }
    } catch (e) {
      status = `error: ${e.message.split('\n')[0]}`;
    }

    if (status === 'ok' && BASELINES_EXIST) {
      const basePath = `baselines/${entry.slug}.png`;
      if (fs.existsSync(basePath)) {
        const a = PNG.sync.read(fs.readFileSync(basePath));
        const b = PNG.sync.read(fs.readFileSync(shotPath));
        if (a.width === b.width && a.height === b.height) {
          const diff = new PNG({ width: a.width, height: a.height });
          const px = pixelmatch(a.data, b.data, diff.data, a.width, a.height, { threshold: 0.1 });
          fs.writeFileSync(`diffs/${entry.slug}.png`, PNG.sync.write(diff));
          diffPct = ((px / (a.width * a.height)) * 100);
        } else {
          status = `dimension-change (${a.width}x${a.height} → ${b.width}x${b.height})`;
        }
      } else {
        status = 'no-baseline';
      }
    }

    rows.push({ slug: entry.slug, url: entry.url, status, diffPct });
    console.log(`[visual-diff] ${entry.slug} ${entry.url} ${status} ${diffPct !== null ? diffPct.toFixed(3) + '%' : ''}`);
  }

  await browser.close();

  // Markdown summary.
  const lines = [];
  lines.push('## Visual diff vs `main`');
  lines.push('');
  if (!BASELINES_EXIST) {
    lines.push('_No baselines on the `screenshot-baselines` branch yet — this run produced reference screenshots only._');
    lines.push('');
  }
  lines.push('| Page | URL | Status | Diff |');
  lines.push('|---|---|---|---|');
  const flagged = [];
  for (const r of rows) {
    const overThreshold = r.diffPct !== null && r.diffPct > DIFF_THRESHOLD_PCT;
    if (overThreshold) flagged.push(r);
    const diffCell = r.diffPct === null ? '—'
      : (overThreshold ? `**${r.diffPct.toFixed(2)}%** (over ${DIFF_THRESHOLD_PCT}%)` : `${r.diffPct.toFixed(2)}%`);
    lines.push(`| \`${r.slug}\` | \`${r.url}\` | ${r.status} | ${diffCell} |`);
  }
  lines.push('');
  lines.push(`Threshold: ${DIFF_THRESHOLD_PCT}%. Pages over the threshold: **${flagged.length}**.`);
  lines.push('');

  // Inline image embeds for every regressed page. The image-publish
  // step in `preview.yml` pushes the screenshot+diff PNGs to a
  // public `pr-screenshots` branch and passes IMAGE_BASE_URL pointing
  // at raw.githubusercontent.com for that branch + this PR's
  // subdirectory. When that publish hasn't happened (e.g. first-run,
  // local dry-run), we fall back to the artifact-link line.
  if (flagged.length > 0) {
    lines.push('### Pages with layout-relevant changes');
    lines.push('');
    if (IMAGE_BASE_URL) {
      for (const r of flagged) {
        lines.push(`#### \`${r.slug}\` — ${r.diffPct.toFixed(2)}% changed`);
        lines.push('');
        lines.push(`URL on preview: \`${r.url}\``);
        lines.push('');
        lines.push(`<table><tr>`);
        lines.push(`<td><b>Current</b><br/><img src="${IMAGE_BASE_URL}/screenshots/${r.slug}.png" width="480"/></td>`);
        lines.push(`<td><b>Diff overlay</b><br/><img src="${IMAGE_BASE_URL}/diffs/${r.slug}.png" width="480"/></td>`);
        lines.push(`</tr></table>`);
        lines.push('');
      }
    } else {
      lines.push('Inline preview images unavailable (image-publish step did not run).');
      lines.push('Diff PNGs and current screenshots are attached as the `visual-diff` workflow artifact (14-day retention).');
      lines.push('');
    }
  } else {
    lines.push('Diff PNGs and current screenshots are attached as the `visual-diff` workflow artifact (14-day retention).');
  }

  fs.writeFileSync('visual-diff-report.md', lines.join('\n'));

  // Non-zero exit only on infra failure, not on diff regression — we
  // want the PR review to see the diff, not have the job fail and
  // hide it.
  const infraFailures = rows.filter(r => r.status.startsWith('error') || r.status.startsWith('http')).length;
  process.exit(infraFailures > 0 ? 1 : 0);
}

main().catch(e => { console.error(e); process.exit(1); });
