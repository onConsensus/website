---
title: "Paxos Made Simple"
slug: paxos-made-simple
paper_authors: ["Leslie Lamport"]
venue: "ACM SIGACT News 32(4), pp. 51–58"
year: 2001
paper_url: "https://lamport.azurewebsites.net/pubs/paxos-simple.pdf"
annotator: m-vellum
annotated: 2026-05-12
deck: "The paper that made Paxos legible, and in doing so quietly relocated all of the difficulty into the part it does not cover."
abstract: |
  The Paxos algorithm, when presented in plain English, is very simple.
key_results:
  - "Single-decree Paxos is **safe under full asynchrony**: no run, however adversarially scheduled, can cause two proposers to have different values chosen."
  - "Safety rests on one structural fact — any two majorities of acceptors intersect — plus the rule that a proposer must adopt the highest-numbered value already accepted by its quorum."
  - "Liveness is *not* guaranteed, and cannot be: FLP forbids it. Progress requires a distinguished proposer, which the paper explicitly places outside the algorithm."
tags: [consensus, paxos, classical, replication]
math: true
---

The joke about this paper is that it was needed at all. Lamport had already
published the algorithm in *The Part-Time Parliament* (1998), wrapped in an
extended allegory about a Greek island's legislature. The allegory did not
land. *Paxos Made Simple* is the retraction of the joke: eight pages, no
archaeologists, one sentence of abstract.

It is worth reading now for a reason that has nothing to do with 1998. Almost
every consensus protocol in production today is a descendant of the safety
argument in Section 2, and almost every *outage* in those systems comes from
Section 3 — the part Lamport declines to specify.

## The safety argument is one sentence long

Strip the prose and single-decree Paxos is a quorum-intersection argument.
Acceptors accept numbered proposals. A value is chosen when a majority accept
the same numbered proposal. The entire correctness burden falls on one
constraint on proposers, `P2c`:

> For any $$v$$ and $$n$$, if a proposal with value $$v$$ and number $$n$$ is issued,
> then there is a set $$S$$ consisting of a majority of acceptors such that
> either (a) no acceptor in $$S$$ has accepted any proposal numbered less than
> $$n$$, or (b) $$v$$ is the value of the highest-numbered proposal among all
> proposals numbered less than $$n$$ accepted by the acceptors in $$S$$.

Clause (b) is the whole algorithm. A proposer is not free to propose its own
value; if the quorum it polls has already accepted something, it must adopt
that something. Because any two majorities share at least one acceptor, a
later proposer cannot miss an earlier chosen value. Since
$$|S_1| + |S_2| > N$$ for any two majorities of $$N$$ acceptors,
$$S_1 \cap S_2 \neq \emptyset$$.

That is it. The two-phase structure everyone memorises — *prepare/promise*,
then *accept/accepted* — is the mechanism for discovering (b) safely. The
prepare phase is a read; the accept phase is a write; the proposal number is a
logical clock that lets acceptors reject stale writers.

## What the paper deliberately does not solve

Section 3 concedes, in about a paragraph, that two proposers can duel
indefinitely: each preempts the other's prepare phase with a higher number,
and neither ever reaches an accept. Lamport does not patch this. He notes that
FLP makes it unpatchable in general and says a *distinguished proposer* must
be selected — then declines to say how.

This is the honest move, and it is also where the field's real complexity
went. "Elect a leader" is not a smaller problem than consensus; under
asynchrony it *is* consensus, with the safety requirement relaxed. Every
production Paxos deployment therefore contains a second, usually undocumented,
protocol handling leases, failure detection, and fencing — and that protocol is
where the incidents come from. The paper is simple because it exported its
hardest requirement to a footnote.

## Multi-Paxos is not in this paper

Section 3's "implementing a state machine" sketch is four paragraphs, and it
is the origin of a decade of confusion. It gestures at running an instance per
log slot, at collapsing the prepare phase across slots once a leader is
stable, and at the reconfiguration problem. It does not specify any of them.

Practitioners call the result *Multi-Paxos*, but there is no canonical
Multi-Paxos to point at — which is exactly the complaint Ongaro and Ousterhout
[open Raft with](/papers/in-search-of-an-understandable-consensus-algorithm/).
Two engineers who have both "implemented Paxos" have probably implemented
different protocols, and the difference usually lives in log compaction,
membership change, or leader handover: the three areas this paper does not
cover.

## How it gets misquoted

Two claims travel under this paper's name that it does not make.

The first is that Paxos is slow. Nothing here implies that. Steady-state
Multi-Paxos under a stable leader is one round trip to a quorum — the same
cost as Raft, the same cost as the commit phase of PBFT without the Byzantine
overhead. The prepare phase is amortised away. What is slow is *leader
churn*, which is the undocumented part.

The second is that Paxos "tolerates $$f$$ failures with $$2f+1$$ nodes" as though
that were a Byzantine claim. It is not. Paxos assumes crash-stop or omission
faults and a non-adversarial network: acceptors may die, messages may be lost,
delayed, duplicated or reordered, but nothing lies. An acceptor that sends
different promises to different proposers breaks the safety argument outright.
For that threat model you need
[PBFT](/papers/practical-byzantine-fault-tolerance/), $$3f+1$$ replicas, and an
extra all-to-all round.

## Why the desk keeps returning to it

The reason to reread *Paxos Made Simple* is not to implement Paxos. It is that
the paper models a discipline the field lacks: it states its safety property
precisely, proves it from one structural fact, and then says plainly which
property it cannot provide and why. Most protocol write-ups we cover invert
this — extensive liveness benchmarking, gestural safety argument, and no clear
statement of the fault model at all.
