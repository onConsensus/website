#!/usr/bin/env node
/* diff_broadsheet.js — compare freshly rasterised broadsheet pages
 * against committed baselines and fail if any page drifts past the
 * pixel-diff threshold.
 *
 * Used by `.github/workflows/broadsheet-vrt.yml` to catch CSS
 * regressions in the monthly broadsheet PDF before they ship.
 *
 * Usage:
 *   node scripts/diff_broadsheet.js \
 *     --current=_site/print \
 *     --baseline=tests/broadsheet/baselines \
 *     --diff-out=tests/broadsheet/diffs \
 *     --month=2026-04 \
 *     [--threshold=0.2]   # max %-pixels-changed per page (default 0.2)
 *
 * Exit codes:
 *   0 — all pages within threshold
 *   1 — at least one page over threshold, page count mismatch, or
 *       missing baseline (the failure mode this whole job exists for)
 *   2 — bad invocation
 */
'use strict';

const fs   = require('fs');
const path = require('path');
const { PNG } = require('pngjs');
const pixelmatch = require('pixelmatch');

function arg(name, def) {
  const m = process.argv.find((a) => a.startsWith(`--${name}=`));
  return m ? m.split('=').slice(1).join('=') : def;
}

const CURRENT   = arg('current',   '_site/print');
const BASELINE  = arg('baseline',  'tests/broadsheet/baselines');
const DIFF_OUT  = arg('diff-out',  'tests/broadsheet/diffs');
const MONTH     = arg('month',     null);
const THRESHOLD = parseFloat(arg('threshold', '0.2'));

if (!MONTH || !/^\d{4}-\d{2}$/.test(MONTH)) {
  console.error('[diff_broadsheet] --month=YYYY-MM is required');
  process.exit(2);
}

fs.mkdirSync(DIFF_OUT, { recursive: true });

const pageRe = new RegExp(`^${MONTH}-page-\\d+\\.png$`);
const currentPages  = fs.existsSync(CURRENT)
  ? fs.readdirSync(CURRENT).filter((f) => pageRe.test(f)).sort()
  : [];
const baselinePages = fs.existsSync(BASELINE)
  ? fs.readdirSync(BASELINE).filter((f) => pageRe.test(f)).sort()
  : [];

if (currentPages.length === 0) {
  console.error(`[diff_broadsheet] no current pages matching ${MONTH}-page-NN.png under ${CURRENT}`);
  console.error('  did `node scripts/render_print.js --png ' + MONTH + '` run?');
  process.exit(1);
}

if (baselinePages.length === 0) {
  console.error(`[diff_broadsheet] no baselines matching ${MONTH}-page-NN.png under ${BASELINE}`);
  console.error('  populate baselines via the `accept-broadsheet-baseline` workflow_dispatch.');
  process.exit(1);
}

let regressions = 0;
const rows = [];

// 1) Page-count mismatch is itself a layout regression — a CSS edit
// that adds or drops a page is exactly the class of bug this guard
// is here to catch.
if (currentPages.length !== baselinePages.length) {
  console.error(`[diff_broadsheet] page count changed: baseline ${baselinePages.length}, current ${currentPages.length}`);
  regressions++;
}

const pageNames = Array.from(new Set([...currentPages, ...baselinePages])).sort();
for (const name of pageNames) {
  const cur = path.join(CURRENT, name);
  const base = path.join(BASELINE, name);
  if (!fs.existsSync(cur)) {
    console.error(`[diff_broadsheet] ${name}: MISSING in current render (baseline expects this page)`);
    rows.push({ name, status: 'missing-current' });
    regressions++;
    continue;
  }
  if (!fs.existsSync(base)) {
    console.error(`[diff_broadsheet] ${name}: MISSING baseline (current render produced this page)`);
    rows.push({ name, status: 'missing-baseline' });
    regressions++;
    continue;
  }
  const a = PNG.sync.read(fs.readFileSync(base));
  const b = PNG.sync.read(fs.readFileSync(cur));
  if (a.width !== b.width || a.height !== b.height) {
    console.error(`[diff_broadsheet] ${name}: dimension change ${a.width}x${a.height} -> ${b.width}x${b.height}`);
    rows.push({ name, status: `dim-change ${a.width}x${a.height}->${b.width}x${b.height}` });
    regressions++;
    continue;
  }
  const diff = new PNG({ width: a.width, height: a.height });
  const px = pixelmatch(a.data, b.data, diff.data, a.width, a.height, { threshold: 0.1 });
  const pct = (px / (a.width * a.height)) * 100;
  fs.writeFileSync(path.join(DIFF_OUT, name), PNG.sync.write(diff));
  const over = pct > THRESHOLD;
  if (over) regressions++;
  rows.push({ name, status: over ? `OVER ${pct.toFixed(3)}%` : `${pct.toFixed(3)}%` });
  console.log(`[diff_broadsheet] ${name}: ${pct.toFixed(3)}% changed${over ? ' (over threshold)' : ''}`);
}

console.log('');
console.log('Threshold: ' + THRESHOLD + '% per page.');
console.log('Pages compared: ' + rows.length);
console.log('Regressions:    ' + regressions);

process.exit(regressions > 0 ? 1 : 0);
