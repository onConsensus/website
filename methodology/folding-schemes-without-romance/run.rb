#!/usr/bin/env ruby
# run.rb — turn the concatenated bench output of four folding-scheme
# implementations into the single-CSV form cited in the article.
#
# Usage:
#   cat nova.log sonobe.log arkworks.log hypernova.log | ruby run.rb > measurements.csv
#
# The expected per-line input format is the lowest-common-denominator
# we found across the four upstreams' bench harnesses, after we
# patched their output formatters to emit a single line per
# (impl, step_size) measurement:
#
#   IMPL=<name> STEP=<n> PROVER=<seconds> WITNESS=<seconds> SNARK=<seconds> CYCLE=<curve> COMMIT=<sha7>

require 'csv'

CSV($stdout, headers: %w[implementation step_size prover_seconds witness_seconds final_snark_seconds curve_cycle commit], write_headers: true) do |out|
  $stdin.each_line do |line|
    next unless line =~ /\AIMPL=(\S+)\s+STEP=(\d+)\s+PROVER=(\S+)\s+WITNESS=(\S+)\s+SNARK=(\S+)\s+CYCLE=(\S+)\s+COMMIT=(\S+)/
    out << [$1, $2.to_i, $3.to_f, $4.to_f, $5.to_f, $6, $7]
  end
end
