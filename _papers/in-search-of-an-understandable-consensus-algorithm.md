---
title: "In Search of an Understandable Consensus Algorithm"
slug: in-search-of-an-understandable-consensus-algorithm
paper_authors: ["Diego Ongaro", "John Ousterhout"]
venue: "USENIX Annual Technical Conference (ATC '14), pp. 305–319"
year: 2014
paper_url: "https://www.usenix.org/conference/atc14/technical-sessions/presentation/ongaro"
pdf_url: "https://raft.github.io/raft.pdf"
annotator: r-okafor
annotated: 2026-05-26
deck: "Raft's contribution is not a better safety argument than Paxos. It is a specification complete enough that two people can implement it and get the same protocol."
abstract: |
  Raft is a consensus algorithm for managing a replicated log. It produces a
  result equivalent to (multi-)Paxos, and it is as efficient as Paxos, but its
  structure is different from Paxos; this makes Raft more understandable than
  Paxos and also provides a better foundation for building practical systems.
  In order to enhance understandability, Raft separates the key elements of
  consensus, such as leader election, log replication, and safety, and it
  enforces a stronger degree of coherency to reduce the number of states that
  must be considered.
key_results:
  - "Decomposes consensus into three separable problems — leader election, log replication, and safety — each specifiable on its own."
  - "Adopts a **strong leader**: log entries flow only from leader to followers, which removes the state space Paxos admits by allowing any node to propose."
  - "Randomised election timeouts resolve split votes without any additional mechanism — the paper's cheapest and most-copied idea."
  - "Membership changes are specified, not gestured at, via joint consensus over an overlapping old+new configuration."
  - "Understandability is treated as a measurable design goal and evaluated with a user study of 43 students."
tags: [consensus, raft, replication, leader-election]
math: true
---

Read the title as a thesis statement. This paper is not claiming a stronger
safety result than [Paxos](/papers/paxos-made-simple/) — it explicitly claims
equivalence. It is claiming that a protocol which can be *transmitted* between
engineers without loss is a different artefact from one that cannot, and that
this difference is a legitimate research contribution.

The desk's view is that this was correct, and that the field still
under-credits it.

## The strong-leader trade, stated plainly

Paxos permits any node to propose at any time. That generality is where its
state space, and most of its exposition difficulty, comes from. Raft forbids
it: entries flow in exactly one direction, leader to follower, and a term has
at most one leader.

The cost is real and worth naming. Under a strong leader every write pays a
round trip to the leader even when a closer replica could have served it,
leader failover stalls all writes instead of degrading them, and the leader is a
throughput ceiling. Raft trades steady-state flexibility for a smaller number
of reachable states. Whether that trade is right depends entirely on whether
your team will ever have to debug the thing at 3am — which is to say, it is
right.

## Randomised timeouts are the underrated result

Split votes are the obvious failure mode of any election: several candidates
time out together, each collects a minority, nobody wins, repeat. The
classical instinct is to add machinery — priorities, ranks, a tie-break
oracle.

Raft's answer is to pick each election timeout uniformly at random from an
interval, typically 150–300 ms. The probability that two candidates start
close enough to split again falls off fast with each retry, so elections
converge in a small number of rounds with overwhelming probability, and the
mechanism is one line of code. The condition for stability is only the
inequality

$$\text{broadcastTime} \ll \text{electionTimeout} \ll \text{MTBF}$$

and the paper says so directly. This is the single most-copied idea in the
paper and it is barely a paragraph.

## The parts implementers actually get wrong

Having watched several client teams build this, the errors cluster in the same
three places every time, and all three are places where the paper *is* precise
and the reader was not.

**The commitment rule for entries from previous terms.** Figure 8 exists
specifically to show that a leader may not commit an entry from an earlier
term merely because it is replicated on a majority. It must commit an entry
from its *own* term first, which carries the earlier entries with it. Skipping
this reintroduces exactly the overwrite Raft is designed to prevent. It is the
most commonly missed rule in the paper.

**The election restriction.** A candidate whose log is not at least as
up-to-date as a majority must lose. "Up-to-date" is defined by last log term
first, then index — not index alone. Implementations that compare index alone
appear to work until a partition heals.

**Persisting before responding.** `currentTerm`, `votedFor`, and the log must
be on stable storage before an RPC is answered. Skip the fsync and the tests
still pass; the protocol is no longer correct across a crash.

None of these are ambiguities in the paper. They are places where the
specification is complete and the reader skimmed — which is a meaningfully
better failure mode than Paxos's, where the specification genuinely stops.

## What "equivalent to Multi-Paxos" is doing

The equivalence claim is doing real work. It concedes that Raft's safety
properties are not new, which is what lets the paper spend its pages on
decomposition and evaluation instead of a novelty argument. But it also
inherits Paxos's limits wholesale: Raft is a crash-fault protocol. A
misbehaving leader that sends conflicting `AppendEntries` to different
followers breaks it, exactly as a lying acceptor breaks Paxos. Every
"Byzantine Raft" is a different protocol wearing the name.

## The user study

Forty-three students learned both Paxos and Raft and were quizzed on each.
The result — better Raft scores — is the paper's weakest evidence and its most
important gesture. The sample is small, the population is students, and
ordering effects are hard to fully exclude.

It does not matter much. The real evidence arrived afterwards, in the form of
etcd, Consul, TiKV, CockroachDB, and a long tail of implementations that
exist because a competent engineer can read this paper on a flight and start
writing. That is the claim being tested, and the field ran the experiment.
