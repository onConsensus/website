# Contributing

Thanks for helping keep *On Consensus* sharp. This document covers
the editorial workflows that aren't obvious from `README.md`.

For the full architectural picture, read `replit.md`.

---

## Audio editions: the pronunciation lexicon

Posts are narrated in CI by [Piper](https://github.com/rhasspy/piper)
using the `en_US-amy-medium` voice. Out of the box Piper mangles
crypto vocabulary — "ZK" becomes a syllable, "EVM" becomes a word,
hex addresses become forty seconds of letter-soup. We fix this with
a pronunciation lexicon that rewrites the prose *before* it reaches
Piper.

**File:** `_data/pronunciation.yml`
**Applied by:** `scripts/build_audio.rb` (during the pre-processing
pass, after markdown is stripped to plain prose, before sha256 +
synthesis)

### Adding a term

Open `_data/pronunciation.yml`. The file has two sections:

```yaml
tokens:
  EVM: "ee vee em"      # whole-word, case-sensitive
  Nimbus: "Nim-bus"

patterns:
  - match: '\bEIP-?(\d+)\b'   # Ruby regex, applied in order
    to:    'E I P \1'
```

Use **tokens** for plain whole-word substitutions. Each key is matched
with word boundaries on both sides and replaced verbatim. Case
matters — add lowercase variants too if the term appears in prose
that way (e.g. both `ZK` and `zk`).

Use **patterns** for anything that needs a regex: numbered standards
(`EIP-1559`, `ERC-4337`), hex addresses (`0xabcdef…`), ENS names,
scientific notation. Patterns run **before** tokens so compound
forms ("ERC-4337") are rewritten before the bare token rule for
"ERC" can clobber the digits.

Replacement guidance:

- Spell phonetically in plain English ("zee kay", not IPA or eSpeak
  phonemes — Piper will not consume them from this file).
- Hyphens are your friend ("multi-sig", "Nether-mind") — Piper
  treats them as syllable hints.
- Keep replacements short. The audio hash is computed *after* the
  rewrite, so a verbose substitution will regenerate every post that
  contains the term.

### Verifying a change

After editing the lexicon, regenerate audio locally and listen:

```bash
PIPER_BIN=piper PIPER_VOICE=/path/to/en_US-amy-medium.onnx \
  ruby scripts/build_audio.rb
```

The script will re-hash any post whose rewritten prose changed and
re-synthesize only those. Spot-check a representative post that
contains the term. If it sounds wrong, iterate — most fixes are a
hyphen or an extra space.

If you don't have Piper installed locally, push the change and let
the `audio.yml` GitHub Actions workflow render it; the PR preview
will surface the new MP3s.

### What not to put in the lexicon

- Per-author idiosyncrasies — keep the lexicon to terms that recur
  across the publication.
- One-off proper nouns from a single article — fix those by editing
  the prose.
- Anything you can't pronounce yourself out loud. If you're guessing,
  ask in the editorial channel before committing.
