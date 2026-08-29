---
title: "Practical Byzantine Fault Tolerance"
slug: practical-byzantine-fault-tolerance
paper_authors: ["Miguel Castro", "Barbara Liskov"]
venue: "3rd Symposium on Operating Systems Design and Implementation (OSDI '99)"
year: 1999
paper_url: "https://pmg.csail.mit.edu/papers/osdi99.pdf"
annotator: m-vellum
annotated: 2026-06-09
deck: "The paper that moved Byzantine agreement from a complexity result to something you could actually deploy — and set the quorum arithmetic every modern BFT chain still inherits."
key_results:
  - "Tolerates $$f$$ Byzantine faults with $$3f+1$$ replicas — and the paper shows $$3f+1$$ is optimal, not merely sufficient."
  - "Three-phase commit (**pre-prepare → prepare → commit**) provides total order under arbitrary faults; the third phase is what survives view changes."
  - "Safety holds under **full asynchrony**; only liveness depends on partial synchrony, which is the correct place to put the timing assumption."
  - "Optimisations — MAC-based authentication instead of public-key signatures on the common path, request batching, tentative execution — bring overhead to roughly 3% over an unreplicated NFS."
tags: [consensus, bft, byzantine, replication, classical]
math: true
---

Before this paper, Byzantine agreement was something you cited. After it, it
was something you could run. The word doing the work in the title is
*practical*, and the measured claim behind it — around 3% overhead over an
unreplicated system, in a real NFS implementation — is why every
BFT (Byzantine fault tolerance) blockchain protocol traces its quorum
arithmetic to here.

## Why $$3f+1$$, and why that bound is tight

The number is not a safety margin someone chose. It falls out of a
requirement that cannot be relaxed.

A replica must make progress after hearing from $$N - f$$ others, because $$f$$
may be crashed and will never answer. So quorums have size $$N - f$$. But the
$$f$$ silent replicas might merely be slow, and the $$f$$ faulty ones might be
among those that *did* answer. For any two quorums to agree on history, their
intersection must contain at least one honest replica:

$$2(N-f) - N > f \;\;\Longrightarrow\;\; N > 3f$$

With $$N = 3f+1$$ any two quorums of size $$2f+1$$ overlap in at least $$f+1$$
replicas, of which at least one is honest — and one honest witness is enough,
because an honest replica will not testify to two conflicting histories.
Crash-fault protocols like [Paxos](/papers/paxos-made-simple/) need only
$$2f+1$$ because a non-faulty-but-slow replica still tells the truth when it
speaks; here the overlap has to survive replicas that lie.

## The third phase is the one people delete

Pre-prepare assigns a sequence number. Prepare establishes that a quorum
agrees on that assignment *within the current view*. It is tempting to stop
there — after prepare, $$2f+1$$ replicas hold the same ordering, which looks
sufficient.

It is not, and the reason is view change. `prepared` is a statement about one
view only. Without the commit phase, a request could be prepared at some
replicas, the view could change before others learn of it, and the new primary
could legitimately assign that sequence number to a different request. Commit
makes the ordering durable *across* views: a replica that reaches
`committed-local` knows $$f+1$$ honest replicas hold the same order and will
carry it into any future view.

This is why PBFT is $$O(n^2)$$ in messages: prepare and commit are both
all-to-all. Every leader-based BFT protocol since —
Tendermint (now CometBFT), HotStuff (which routes the phases through the
leader) and its descendants — is in some sense an argument about how to
keep the safety
property of that third phase while reducing its cost. HotStuff's contribution
is precisely to linearise it, at the price of an extra phase.

## The optimisations are the actual contribution

Strip them and PBFT is a clean protocol with unusable constants. The paper's
engineering is where "practical" is earned:

- **MACs instead of digital signatures on the common path.** Public-key
  operations dominated 1999 cost budgets. PBFT uses symmetric MAC vectors for
  ordinary messages and reserves signatures for view changes, where the
  non-repudiation actually matters. This one change is most of the
  order-of-magnitude.
- **Request batching** under load, amortising the three phases.
- **Tentative execution**, replying after prepare and before commit, cutting
  latency for the common non-faulty case.
- **Checkpointing and garbage collection**, without which the log and the
  view-change message grow unboundedly — the thing that actually kills naive
  implementations.

## What it does not give you

Two limits are routinely elided when this paper is invoked as a blockchain
ancestor.

**It assumes a fixed, known membership.** All $$3f+1$$ replicas are known in
advance. There is no Sybil resistance here and none is claimed; PBFT answers
"how do these $$N$$ known parties agree", not "who gets to be a party". That
second question is what proof-of-work and proof-of-stake exist to answer, and
[Bitcoin](/papers/bitcoin-a-peer-to-peer-electronic-cash-system/) is best read
as an attack on it, not on this.

**It does not scale to large $$N$$.** Quadratic message complexity and the
view-change protocol's cost mean PBFT is comfortable in the tens of replicas.
Every modern deployment that claims "PBFT-based" with hundreds of validators
has changed something structural — committee sampling, threshold signatures,
aggregation — and those changes carry their own assumptions that the original
safety proof does not cover.

## Why it still reads well

The fault model is stated first and honestly, safety is separated from
liveness with the timing assumption confined to the latter, the bound is
proved optimal, not asserted, and the optimisations are measured
against a real workload. Twenty-seven years on, the structure of the argument
is still the template — and a fair number of protocols we cover would be
improved by copying the structure even where they cannot copy the protocol.
