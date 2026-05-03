---
title: "On the Wire: 29 April 2026"
author: r-okafor
date: 2026-04-29 17:30:00 +0000
section: dispatches
tags: [link-blog, on-the-wire]
excerpt: "Five short items from the past week: a sequencer-failover post-mortem, a quiet governance vote, a new BLS library, a court filing, and one piece of good news about clients."
block_height: 891987
license: CC-BY-SA-4.0
---

A short link-blog round-up. Each item is filed under a section we may return
to with a longer piece.

## Sequencer failover at $L2_REDACTED

A widely-used L2 quietly executed a sequencer failover on Tuesday
afternoon. The official status page reported a "scheduled maintenance
window." Operator chatter suggests the failover was triggered by a memory
leak that had been accumulating for weeks. We are looking for sources.
*Filed under: development.*

## A governance vote nobody noticed

A token-holder vote at a mid-sized DeFi protocol passed unanimously last
week with a 4.1% turnout. The vote authorized a parameter change that
shifted protocol fees from a public treasury to a foundation-controlled
operating fund. The forum thread received eleven comments, of which seven
were from accounts created in the past month. *Filed under: governance.*

## arkworks-bls12-381 v0.7

A new release of the *arkworks-bls12-381* implementation lands with
measurable speedups on the pairing path and a quiet, important change to
the serialization format. Library authors downstream should read the
release notes before bumping. *Filed under: cryptography.*

## A court filing worth reading

A federal court filing in the Southern District of New York names six
individual signers of a multisig as defendants in a class action over a
2024 protocol failure. The filing's theory of liability is novel and, if
it survives early motions, will reshape how multisig signers think about
their role. *Filed under: governance.*

## One piece of good news

Two reference clients of a major proof-of-stake network released
deterministic-build pipelines this week. Reproducing a client binary from
source is now possible for both, with a published Nix derivation in one
case and a Bazel toolchain in the other. *Filed under: development.*

> *Errata, corrections, or tips: editors@onconsensus.com. PGP fingerprint
> in the colophon.*
