# Broadsheet visual-regression baselines

PNGs in this directory are the committed reference rasters of the
monthly broadsheet PDF, one per A3 page, named
`YYYY-MM-page-NN.png`. They are produced by:

```
node scripts/render_print.js --png YYYY-MM
```

against the corresponding `_site/print/YYYY-MM/index.html`, then
rasterised at 120 dpi via `pdftoppm`.

The `broadsheet-vrt` GitHub Actions workflow diffs the freshly
rendered pages against these baselines on every PR that touches
`_layouts/broadsheet.html`, `assets/css/broadsheet.scss`, `_sass/`,
`scripts/render_print.js`, or `scripts/diff_broadsheet.js`. A single
page drifting past the per-page pixel-diff threshold (0.2 % by
default) fails the job.

To intentionally accept a new design, run the `broadsheet-vrt`
workflow manually with `refresh_baselines: true` — this is the
"accept-broadsheet-baseline" operator action. It re-renders the
most recent month (or the `month` input you provide) and commits
the new PNGs in place of the old ones on the dispatched ref.

## Monthly cadence

Because the workflow defaults to the most recent `YYYY-MM` directory
under `_site/print/`, baselines need to be refreshed once per month
shortly after a new month appears (the broadsheet cron job runs at
06:05 UTC on the 1st). Until that refresh happens, PRs that touch
broadsheet-relevant files will fail with "no baselines matching
`<new-month>-page-NN.png`". Operator runbook: dispatch
`broadsheet-vrt` with `refresh_baselines: true` against `main`
once a month, immediately after the broadsheet cron lands the
new `print/YYYY-MM.pdf`.
