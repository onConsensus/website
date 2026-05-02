# Folding Schemes Without Romance — methodology

This directory contains the artefacts cited in
[Folding Schemes Without Romance](/feed/folding-schemes-without-romance).
Every file is hashed at build time; the post's "Reproduce this"
appendix lists the SHA-256 of each file alongside a download link.

## Files

- `measurements.csv` — constant-factor measurements across four
  open folding-scheme implementations. One row per (implementation,
  step-size) pair. All numbers are wall-clock prover seconds on the
  reference hardware described in the working paper.
- `run.rb` — the small Ruby driver that aggregated raw measurement
  output into the CSV. It does not run any cryptographic code; it is
  a parser for the per-impl logs the working paper enumerates.

## How to reproduce

1. Clone the four upstream implementations at the commits listed in
   the working paper appendix.
2. Run each implementation's bench harness against the step-size set
   `{2^14, 2^16, 2^18, 2^20}` on hardware comparable to the reference
   machine.
3. Concatenate the per-impl logs into a single file, then:

   ```sh
   ruby run.rb < combined.log > measurements.csv
   ```

4. Compare the resulting CSV against the published `measurements.csv`.
   Differences in the constant factors are expected; differences in
   relative ordering are not.

## What this isn't

This is not a self-contained reproduction. The cryptographic work
runs in the upstream implementations; this directory only contains
the bookkeeping that turned their output into the article's claims.
The reproducibility promise is therefore: given the upstream commits,
this driver, and comparable hardware, the relative-ordering result in
the article should hold.
