---
title: "Bitcoin: A Peer-to-Peer Electronic Cash System"
slug: bitcoin-a-peer-to-peer-electronic-cash-system
paper_authors: ["Satoshi Nakamoto"]
venue: "Self-published white paper, bitcoin.org"
year: 2008
paper_url: "https://bitcoin.org/bitcoin.pdf"
annotator: k-arnaud
annotated: 2026-06-23
deck: "Nine pages that solved a problem the consensus literature had ruled out, by quietly changing what counts as agreement."
key_results:
  - "Replaces a **known, fixed validator set** with an open one weighted by computational work — the Sybil problem the classical literature had assumed away."
  - "Substitutes **probabilistic finality** for the deterministic finality of BFT: confirmation confidence rises with depth but never reaches certainty."
  - "Section 11 models an attacker's catch-up as a random walk and shows failure probability decays exponentially in confirmations $$z$$, given honest majority hashpower."
  - "The security argument is **economic, not fault-tolerant**: it assumes a rational majority, not a bounded number of arbitrary faults."
tags: [consensus, bitcoin, proof-of-work, nakamoto, classical]
math: true
---

The most useful way to read this paper in 2026 is as a document that solves a
*different* problem from the one it is usually filed under, and gets its
strength from the substitution.

[PBFT](/papers/practical-byzantine-fault-tolerance/) answers: given $$3f+1$$
known replicas, how do they agree despite $$f$$ liars? That question presumes
someone has already decided who the replicas are. Nakamoto attacks the
presumption. The contribution is not a better agreement protocol — by every
classical metric it is a worse one — it is a membership rule that does not
need an administrator.

## What was actually traded away

Three things, and all three are still the live design axes.

**Deterministic finality becomes probabilistic.** PBFT commits: once
`committed-local`, the ordering is final, full stop. Bitcoin never commits.
A block six deep is overwhelmingly likely to be permanent and is *not*
guaranteed to be. Section 11 gives the model: an attacker with a fraction $$q$$
of hashpower trying to catch up from $$z$$ blocks behind is a random walk with
negative drift, and for $$q < 0.5$$ the success probability decays exponentially
in $$z$$. "Six confirmations" is a risk threshold, not a state transition.

**A bounded-fault assumption becomes an economic one.**
BFT (Byzantine fault tolerance) tolerates $$f$$ arbitrary faults with no
assumption about *why* a replica misbehaves. Bitcoin
assumes the honest majority is honest because deviating is unprofitable. That
is a strictly weaker guarantee against a well-funded adversary who does not
care about profit, and a strictly stronger one against the open-membership
problem, which BFT cannot address at all.

**Message complexity falls out of the design.** PBFT's all-to-all rounds are
$$O(n^2)$$ and cap $$n$$ in the tens. Gossip plus longest-chain is closer to
$$O(n)$$ and admits an unbounded, unknown, churning participant set. This is the
purchase the other two trades pay for.

## It does not solve the Byzantine Generals Problem

This is the most persistent misattribution in the field, and Nakamoto's own
early mailing-list remarks helped it along.

The classical result requires agreement among a *known* set of generals with
deterministic termination. Bitcoin provides none of that: membership is open
and unknown, and agreement is probabilistic and never terminates — the chain
can always reorganise. What it provides is a way for an open population to
converge on a shared history with high probability under an honest-majority
assumption. Genuinely valuable, genuinely not the classical problem, and the
conflation is what produces claims that Bitcoin "beat" a known impossibility
result. It did not; it changed the question.

## Where the analysis is thinner than its reputation

Section 11 is a clean piece of work with a narrow scope, and the gap between
its scope and its citation is wide.

It models one attack: a miner with $$q < 0.5$$ attempting a private-chain
double-spend, against a network of otherwise honest miners. It assumes block
discovery is Poisson, mining is independent, propagation is instantaneous, and
hashpower is exogenous — not itself a strategic response to the reward.

Relax any of those and the picture moves. Selfish mining (Eyal and Sirer,
2014) shows a miner with materially less than 50% can gain by strategically
withholding blocks, because propagation is *not* instantaneous. Pool
formation makes "hashpower distribution" a governance variable, not a
constant. Fee-market dynamics as the subsidy declines introduce incentives the
1% honest-majority framing does not model. None of this refutes Section 11;
all of it lies outside the model, and the paper is regularly cited as though
it covered them.

## The part that aged best

Not the proof-of-work. The *incentive* section.

Earlier distributed systems papers, this desk's other three annotations
included, treat participation as given: replicas replicate because that is
what replicas do. Nakamoto asks why anyone runs a node at all, and answers
with block subsidy plus fees — an argument about motive, not correctness.
Mechanism design belongs inside the protocol specification, not adjacent to
it.

That framing is now assumed everywhere. Every staking design, every
sequencer-decentralisation proposal, every [prover
market](/feed/prover-markets-against-themselves) we cover is arguing about
the same thing: not whether the protocol is safe if participants follow it,
but whether anyone will. Nine pages, and the durable idea turned out to be the
economics, not the hashcash.
