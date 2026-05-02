---
title: "Post-mortem: The Shadow Fork of March Third"
subtitle: "What three node operators saw before the rest of the network noticed."
author: r-okafor
date: 2026-04-08 09:00:00 +0000
section: development
tags: [postmortem, consensus, fork, node-ops]
excerpt: "A detailed timeline of the brief two-block consensus split on March 3, 2026, reconstructed from operator logs and client team notes. Less dramatic than the threads, more instructive."
featured_image: /images/posts/shadow-fork.svg
featured_caption: "Reconstructed timeline of the March 3 split. Times in UTC. Block heights elided pending publication of the official client report. — On Consensus"
block_height: 889205
license: CC-BY-SA-4.0
---

On the evening of March 3, 2026, between 21:14 and 21:21 UTC, the network
briefly held two competing canonical heads. The split was resolved within
seven minutes, before most users noticed and before any exchange paused
withdrawals. The thread post-mortems were, predictably, breathless. The
actual sequence of events is more interesting and considerably more
mundane.

## The timeline

What follows is reconstructed from operator logs voluntarily shared by three
of the four implicated node operators,[^1] and from a draft client-team
incident report we were shown on background.

- **20:58** — A consensus client release candidate is shipped to a small
  pre-production cohort. The release contains an off-by-one in the
  attestation-aggregation path that only fires under a specific quorum
  arrangement.
- **21:14** — Three of the cohort's nodes begin attesting to a slightly
  different head than the rest of the network. The attestation gossip
  layer propagates the divergence.
- **21:16** — A second cohort, running an unrelated but coincident
  fork-choice optimization, begins amplifying the minority head.
- **21:18** — Two further nodes pick up the minority head as their preferred
  fork. The split is now three blocks long on the minority side.
- **21:21** — A coordinated client-team Discord call yields a temporary
  fork-choice override. The minority head is orphaned. Total reorg depth on
  the affected nodes: two blocks. No finalized state was rewritten.

## Why this matters more than the lack of damage suggests

The network self-healed. Finality held. The damage was zero. These are
genuinely good outcomes. They are also exactly the conditions under which
*the next* incident gets less attention than it should.

> Resilience is the most dangerous property a system can have, because it is
> the property most easily mistaken for correctness.

Three things in this incident were not resilient and deserve to be treated
as findings rather than footnotes.

1. **The release-candidate cohort was self-selected.** The bug fired in a
   quorum arrangement no one had test-vector coverage for, because the
   cohort over-represented operators with similar topology.
2. **The fork-choice override was discretionary.** It was the right call.
   It was also a call made by a Discord channel of fewer than twenty
   people, none of whom hold a formal role in protocol governance.
3. **The post-mortem we are writing here is the most detailed account
   currently public.** The official report is still in legal review at
   the time of writing.

## What we are watching for next

The client team has committed to a structural change in how
release-candidate cohorts are sampled. We will follow up when the change
ships. We are also watching, with concern, the normalization of the Discord
override channel — a body whose authority is exactly proportional to the
discretion it exercises and inversely proportional to its accountability.

[^1]: The fourth operator declined to share logs. Their reasoning was sound
      and we declined to press the matter.
