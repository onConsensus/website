---
title: Verify
permalink: /verify/
description: How to verify timestamps, sealed embargo commits, and reproducibility artefacts published by On Consensus.
---

# Verify

Every article on this site is published with primitives that let a
sufficiently determined reader confirm, without trusting the publisher,
that what they are reading is what was written and when. None of these
require an account, an API key, or a wallet. They require a terminal.

The four primitives are, in order of how often you will use them:
**timestamps**, **on-chain references**, **embargoes**, and
**reproducibility appendices**.

----

## Timestamps {#timestamps}

Every published post carries an [OpenTimestamps][ots] proof at
`/timestamps/<slug>.ots` and a SHA-256 of its source markdown. The
article footer surfaces both, plus the Bitcoin block height the proof
attests to once the calendar receipts have been upgraded (typically
within 24 hours of publication).

To verify a post yourself:

```sh
# 1. Install the OpenTimestamps client (one-time).
pip install opentimestamps-client

# 2. Pull the post source and its proof.
curl -O https://raw.githubusercontent.com/onConsensus/onconsensus/main/_posts/<file>.md
curl -O https://onconsensus.com/timestamps/<slug>.ots

# 3. Verify against a Bitcoin node, or against a public block explorer
#    using a Bitcoin header you trust.
ots verify --no-bitcoin <slug>.ots -f <file>.md
```

A successful verification prints the Bitcoin block height the post
hash was committed to and the timestamp of that block. That is the
strongest claim we can make about *when* a piece of writing existed
in its current form.

> **Why OpenTimestamps and not an L2 calldata anchor?** Because the
> proof must be readable in fifty years. OpenTimestamps reduces every
> attestation to a single Bitcoin block header, which is the most
> durable artefact our infrastructure has produced.

----

## On-chain references {#onchain}

Tx hashes, Ethereum addresses, ENS names, and explicit Bitcoin
block-height markers in our prose are auto-rewritten on the client
into multi-explorer link clusters: a primary explorer plus alternates
that surface on hover/focus, and a copy-to-clipboard button.

The explorer set is configured in `_config.yml :: onchain.explorers`;
adding a new one (e.g. another Bitcoin block explorer) is a single
line of YAML, no code edit. The full source of the rewriter is at
[`/js/onchain.js`][onchain-src] — about ninety lines, no
dependencies.

A worked example, with one of each kind:

- Tx hash: `0x90ab1f8e1b3d2a7e4c5f6a7b8c9d0e1f2a3b4c5d6e7f8091a2b3c4d5e6f7081a`
- Address: `0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045`
- ENS:     `vitalik.eth`
- Bitcoin block: <span data-onchain-block>887412</span>

Block heights in regular body copy are deliberately *not* rewritten by
default — bare digit strings produce too many false positives. Authors
who want to link a body block height wrap the number in a
`<span data-onchain-block>` and the rewriter picks it up.

----

## Embargoes {#embargoes}

A post can declare `embargo_until: 2026-12-15T14:00:00Z` (or
`embargo_block: <height>`) in its frontmatter. While the deadline is
in the future, the build hides the body and renders only the
**sealed commit**:

- the post title and author
- the SHA-256 of the post source markdown
- the byte length of the source
- a plain-prose intent statement supplied by the author

After the deadline, the next build (the site rebuilds on a daily cron)
reveals the body. A small "Embargo lifted" ribbon then sits above the
article showing the original sealed sha-256 so a reader can check that
the published text still hashes to the same value.

To verify after lift:

```sh
curl -O https://raw.githubusercontent.com/onConsensus/onconsensus/main/_posts/<file>.md
sha256sum <file>.md   # must equal the sealed sha printed on the page
```

If the hashes match, the published article is byte-for-byte the same
piece of writing that was committed under the seal — same body, same
frontmatter, same date — and you can verify that against any external
record we made of the seal before the lift.

If both `embargo_until` and `embargo_block` are set, *both* gates must
pass before the embargo lifts. This is the conservative default; the
common case is to set just one.

> **What this primitive doesn't do.** A sealed commit proves we *did
> not* substitute a different article after the deadline. It does not
> prove we wrote the original on a particular date — that's what
> [timestamps](#timestamps) are for.

----

## Methodology / reproducibility {#methodology}

Posts that ship data, queries, or scripts carry a sibling
`methodology/<slug>/` directory in the repository. Every file in that
directory is hashed at build time and listed in the article's
"Reproduce this" appendix with its SHA-256.

To verify an artefact:

```sh
curl -O https://onconsensus.com/methodology/<slug>/<file>
sha256sum <file>   # must equal the hash printed in the appendix
```

A "Reproducibility: data + code" pill appears near the byline whenever
this appendix is present. Authors who supply such a directory are
making a particular promise — the [standards page][rep] spells out
what that promise is and where it ends.

[ots]: https://opentimestamps.org/
[onchain-src]: https://github.com/onConsensus/onconsensus/blob/main/js/onchain.js
[rep]: /standards/#reproducibility
