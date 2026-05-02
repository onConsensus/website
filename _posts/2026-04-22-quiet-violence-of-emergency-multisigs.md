---
title: "The Quiet Violence of Emergency Multisigs"
subtitle: "Every protocol has an undocumented constitution. It usually lives behind a 4-of-7 wallet."
author: k-arnaud
date: 2026-04-22 09:00:00 +0000
section: governance
tags: [multisig, governance, emergency-powers, dao]
excerpt: "On the un-amendable layer beneath every on-chain constitution: the small group of keys that can override every other rule, and what they reveal about who actually governs a protocol."
featured_image: /images/posts/multisig-broadsheet.svg
featured_caption: "Diagram: an emergency multisig as the apex of a notional constitutional pyramid. — On Consensus"
featured: true
block_height: 891204
license: CC-BY-SA-4.0
---

Most decentralized protocols arrive with a constitution. Often it is gestured
at — a forum post, a snapshot vote, a yellow paper — and rarely is it
reckoned with as a constitution in the political sense. Buried inside almost
every one of these documents, however, is a clause whose plain reading is
this: *in case of emergency, the rules do not apply.*

## What the multisig actually does

The emergency multisig is not, on its face, a governance organ. It is
presented as a fire extinguisher. The framing matters: a fire extinguisher is
defensive, occasional, technical. A constitution is offensive, permanent,
political. By rendering the multisig in the first vocabulary while granting
it the powers of the second, protocols achieve a useful confusion.

In practice the multisig can — and in nearly every documented case has —
done the following:

- **Override on-chain votes** when the result is judged unsafe.
- **Pause core contracts** without the assent of the broader token-holder
  body.
- **Migrate funds** from drained or compromised positions, sometimes after
  socializing the loss to other depositors.
- **Replace itself** with a smaller, faster signer set when speed is judged
  necessary.

Each of these is, in the language of constitutional theory, a sovereign act.

## A short typology

The cleanest way to classify these arrangements is by the relationship
between the multisig and the token-holder body. Three patterns recur.

1. **The Cincinnatus model.** The multisig is meant to dissolve once the
   protocol is "mature." It rarely does.
2. **The Senate model.** The multisig governs the rate at which the
   token-holder body's decisions take effect — a delay-and-veto layer dressed
   as a security council.
3. **The Praetorian model.** The multisig is plainly the seat of power.
   Token votes are advisory. Governance forums are reading rooms.

> The hardest question to ask of a decentralized protocol is the oldest
> question in political theory: *who decides the exception?* It is almost
> never the token holders.

## Why this is not a complaint

There are excellent reasons to keep emergency powers in a small, fast hand.
Smart-contract bugs are discovered at three in the morning. Bridge exploits
move millions before the next block. The argument here is not that the
multisig should be abolished — it is that calling it a fire extinguisher
makes it harder to govern.

The next entries in this dispatch will look at three case studies — Lido,
Optimism, and a now-defunct lending protocol whose name we will redact for
legal reasons — to see what the multisig was *actually* asked to do, and
what it did instead.

[^1]: We borrow the framing from Carl Schmitt — uncomfortably, knowingly —
      because the analytical tool is sharper than its provenance.

[^2]: The legal redaction is real. The events are public. The lawyers are
      cautious people, and we like our lawyers.
