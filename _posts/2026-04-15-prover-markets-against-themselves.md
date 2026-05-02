---
title: "Prover Markets Against Themselves"
subtitle: "The economic argument for decentralized provers keeps being made by the same three companies."
author: m-vellum
date: 2026-04-15 09:00:00 +0000
section: research
series: notes-on-rollup-centralization
tags: [zk, provers, rollups, market-design]
excerpt: "A first cut at the prover-market literature, and why almost every published analysis quietly assumes a competitive supply curve that does not exist."
featured_image: /images/posts/prover-market.svg
featured_caption: "Sketch: notional supply and demand curves for SNARK proof generation, with the long tail of would-be provers compressed into a margin. — On Consensus"
block_height: 890318
license: CC-BY-SA-4.0
---

If you spend any time around zero-knowledge rollup discourse you will have
heard a particular argument: that *prover markets*, once they mature, will
decentralize themselves. The argument is appealing. It is also, on the
evidence available, false in a specific and instructive way.

## The argument as usually stated

The standard case proceeds in three steps.

1. As demand for proofs grows, marginal cost compresses.
2. As marginal cost compresses, capital with cheaper energy and silicon
   enters the market.
3. As capital enters, the prover set fragments and the rollup decentralizes.

Each step is plausible. Each step is also a model assumption — and the
assumptions that make the model work are exactly the assumptions that fail in
the field.

## What the field actually shows

The four largest rollup ecosystems with publicly inspectable prover sets, as
of the first quarter of 2026, share a striking property: each has fewer than
five active prover entities, and the top entity in each case generates
between sixty and seventy-five percent of submitted proofs.

This is not a transient state. It is what we will tentatively call the
**prover oligopoly equilibrium** — the durable outcome of three structural
forces that the standard model abstracts away.

> A market in which the top supplier generates two-thirds of the supply is a
> market by the courtesy of the dictionary. It is, in the relevant sense, a
> coordination layer wearing a market's clothing.

### Force one: silicon as moat

SNARK proving is GPU- and FPGA-bound. The capital cost of a competitive
prover farm is in the low tens of millions and rising. The standard model
assumes a continuous supply curve; the actual supply curve has a step at the
hardware threshold and is nearly empty below it.

### Force two: latency as moat

Rollup contracts almost universally reward the *first* valid proof.
Geographic and network proximity to the sequencer is therefore a hard
constraint, and the entities best placed to satisfy it are the ones that
already operate the sequencer.

### Force three: integration as moat

The prover stack — circuits, witness generation, recursion — is co-evolved
with the rollup's specific implementation. Switching costs for a prover
joining a new rollup are non-trivial. New entrants face a build that the
incumbents amortized over years.

## Where the argument needs to go

None of this is fatal to the rollup project. It is, however, fatal to the
*specific story* that prover markets will decentralize themselves without
intervention. The next step in this series is to ask what intervention
looks like — and which interventions are even possible inside the
constraints rollups have already accepted.

[^1]: The rollups in question are named in the appendix of the working
      paper accompanying this piece, available on request from the editor.
