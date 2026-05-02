---
title: "Folding Schemes Without Romance"
subtitle: "What Nova, SuperNova, and HyperNova actually buy you, and what they don't."
author: m-vellum
date: 2026-04-01 09:00:00 +0000
section: cryptography
series: notes-on-rollup-centralization
tags: [zk, folding, nova, supernova, hypernova]
excerpt: "A working cryptographer's tour of the folding-scheme literature, with attention to the gap between the asymptotic story and the engineering bill."
featured_image: /images/posts/folding-schemes.svg
featured_caption: "Schematic: instance accumulation under a notional folding scheme, before and after recursion. — On Consensus"
block_height: 887412
pgp_signed: true
license: CC-BY-SA-4.0
---

Folding schemes are the most discussed and least understood family of
cryptographic constructions of the last three years. The discussion is loud
because the asymptotic story is genuinely beautiful. The understanding is
thin because the engineering story is, as always, where the cost lives.

## The asymptotic story, briefly

A folding scheme takes two instances of a relation and produces a single
instance whose satisfiability implies the satisfiability of both. The cost
of folding is, in the strongest constructions, sub-linear in the size of
the folded instances. The implication, repeated everywhere: you can build
incrementally verifiable computation without paying for a full SNARK at
every step. You only need a SNARK at the very end, and only over the final
folded instance.

This is true. It is also where most of the discussion ends.

## The engineering bill

The engineering bill comes in three line items.

- **Curve choice.** Nova-family schemes want a *cycle* of curves so that
  scalar arithmetic on one curve can be checked by a circuit over the
  other. The cycles available to us are not free. The pasta cycle is
  excellent for proof generation and bad for many existing verifier
  ecosystems. The bn254/grumpkin cycle is the inverse trade-off.
- **Witness generation.** The folded instance grows in dimensionality, not
  size. Witness generation for the next fold therefore involves matrix
  operations whose cost is asymptotically negligible and whose constant
  factors are not. We have measured constant factors of three to four
  times the optimistic estimates in three out of four open implementations.
- **Final SNARK.** The asymptotic story says you only need one final SNARK.
  This is true. The size of the final SNARK is, however, a function of the
  arithmetization used during folding, and that arithmetization is
  *bigger* than the per-step arithmetization a non-folding scheme would
  use. The savings are real. They are smaller than the talks suggest.

> The right way to read every folding-scheme talk is to ask, at each
> asymptotic claim, *what is the constant factor and at what input size
> does it dominate?* The answers are usually publishable. They are usually
> not published.

## Where folding wins

Folding wins clearly and unambiguously when:

1. The per-step computation is small relative to a baseline SNARK.
2. The number of steps is large.
3. The verifier ecosystem can accept the curve cycle the prover wants to
   use.

The first two conditions describe a great many real workloads. The third
is the live political question of the next eighteen months.

## Where folding loses

Folding loses, sometimes badly, when the per-step computation is itself
the size of a small SNARK — which is a not-uncommon situation in the
rollup setting we have been writing about. The right thing to do in that
regime is to use a non-folding recursive SNARK over a smaller per-step
circuit and accept the constant overhead. The folding literature does not
say this loudly, and it should.

[^1]: The implementations we measured are listed, with versions and
      commit hashes, in the appendix of our working paper. We are happy
      to share raw measurement scripts with anyone who wants to argue.
