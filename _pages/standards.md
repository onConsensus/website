---
layout: page
title: Standards
permalink: /standards/
description: "The procedural rules On Consensus operates by — who can publish, conflict and recusal rules, sourcing requirements, when corrections vs. retractions apply, anonymity policy, AI policy. Versioned and dated."
image: '/images/h2.png'
kicker: "Editorial constitution"
sitemap: true
version: "1.0"
last_revised: 2026-04-29
---

<p class="article__deck">
  This is the operating manual. The <a href="/ethos/">ethos</a> page
  states <em>what</em> we believe; this page states <em>how</em> we run
  the desk. Both documents are versioned. This is version
  <strong>{{ page.version }}</strong>, last revised
  <time datetime="{{ page.last_revised }}">{{ page.last_revised | date: "%-d %B %Y" }}</time>.
  Material revisions are recorded as commits to <code>_pages/standards.md</code>;
  the running history is in <a href="https://github.com/{{ site.repository }}/commits/main/_pages/standards.md" rel="external">git</a>.
</p>

<nav class="ethos__toc" aria-labelledby="standards-toc-heading">
  <h2 class="ethos__toc-heading" id="standards-toc-heading">Sections</h2>
  <ol class="ethos__toc-list">
    <li class="ethos__toc-item"><a class="ethos__toc-link" href="#publishing"><span class="ethos__toc-title">Who can publish</span><span class="ethos__toc-summary">Mastheads, contributors, guests, and the bar each must clear.</span></a></li>
    <li class="ethos__toc-item"><a class="ethos__toc-link" href="#sourcing"><span class="ethos__toc-title">Sourcing</span><span class="ethos__toc-summary">On-the-record by default; anonymity granted only with cause and disclosure.</span></a></li>
    <li class="ethos__toc-item"><a class="ethos__toc-link" href="#conflicts"><span class="ethos__toc-title">Conflicts &amp; recusal</span><span class="ethos__toc-summary">Disclosed financial interests; recusal rules; when an editor cannot cover a story.</span></a></li>
    <li class="ethos__toc-item"><a class="ethos__toc-link" href="#corrections"><span class="ethos__toc-title">Corrections &amp; retractions</span><span class="ethos__toc-summary">When we correct, when we clarify, when we retract — and what each looks like.</span></a></li>
    <li class="ethos__toc-item"><a class="ethos__toc-link" href="#anonymity"><span class="ethos__toc-title">Anonymity &amp; source protection</span><span class="ethos__toc-summary">How we evaluate, accept, and protect anonymous sources.</span></a></li>
    <li class="ethos__toc-item"><a class="ethos__toc-link" href="#ai"><span class="ethos__toc-title">AI-generated content</span><span class="ethos__toc-summary">What machines may and may not do under our byline.</span></a></li>
    <li class="ethos__toc-item"><a class="ethos__toc-link" href="#changes"><span class="ethos__toc-title">Changing this document</span><span class="ethos__toc-summary">How standards are revised; how revisions are announced.</span></a></li>
  </ol>
</nav>

<article class="ethos__principle" id="publishing">
  <header class="ethos__principle-head">
    <p class="ethos__principle-kicker">§ 01 · Publishing</p>
    <h2 class="ethos__principle-title">Who can publish</h2>
    <p class="ethos__principle-summary">A byline on On Consensus carries a standing commitment to these standards. We are deliberate about granting it.</p>
  </header>
  <div class="ethos__principle-body article__body" markdown="1">

Three classes of contributor publish under the masthead.

**Editors** are listed on the [masthead](/authors/) and have signing
authority on their desk. They commit to keeping a current
[disclosures](#conflicts) record and to the recusal rules below.

**Contributing editors** publish regularly but do not run a desk. They
maintain the same disclosures.

**Guest contributors** publish a single piece (or a short series) under
the editorial supervision of the relevant desk editor. Their disclosures
are recorded against the piece.

In every class, a piece is published only after a second editor has
read it end to end, checked sourcing, and signed off. We do not
self-publish into the feed without that second pair of eyes — even the
founding editor's pieces clear that bar.

  </div>
</article>

<article class="ethos__principle" id="sourcing">
  <header class="ethos__principle-head">
    <p class="ethos__principle-kicker">§ 02 · Sourcing</p>
    <h2 class="ethos__principle-title">Sourcing</h2>
    <p class="ethos__principle-summary">On the record by default. Anonymity granted only when the alternative is silence — and only when we can name the reason.</p>
  </header>
  <div class="ethos__principle-body article__body" markdown="1">

Every claim of fact in a piece is either (a) cited to public sources
the reader can verify, (b) attributed to a named source, or (c)
attributed to an anonymous source whose anonymity is itself explained
in the piece.

Where (c) applies, two further conditions hold. First, at least one
editor on the desk has independently confirmed the source's identity
and access; second, the piece states *why* anonymity was granted
("the source is not authorised by their employer to speak publicly",
"the source has received credible threats", and so on). We do not run
"a person familiar with the matter" without that explanation.

Quotation is verbatim or it is paraphrase. If quotation marks appear,
the speaker said exactly those words. Light edits for grammar are
allowed; substantive edits are paraphrased.

  </div>
</article>

<article class="ethos__principle" id="conflicts">
  <header class="ethos__principle-head">
    <p class="ethos__principle-kicker">§ 03 · Conflicts &amp; recusal</p>
    <h2 class="ethos__principle-title">Conflicts of interest and recusal</h2>
    <p class="ethos__principle-summary">Every byline carries a structured disclosures record. Coverage of any entity in which an editor has a material interest is either recused or flagged.</p>
  </header>
  <div class="ethos__principle-body article__body" markdown="1">

Every editor maintains a public **disclosures** record listing
employer, financial holdings, grants, advisory roles, paid outside
writing in the last twelve months, and standing recusals. Disclosures
are reviewed at minimum every six months and on any material change.

A material interest in this publication includes:

- A position greater than 1% of the editor's net worth, or any position
  exceeding $25,000 USD-equivalent, in any token, equity, or debt of an
  entity covered by the piece.
- Past employment by, or active consulting for, the entity covered by
  the piece, in the prior twelve months.
- A grant from the entity within the prior twelve months.
- A close personal relationship with a named source.

Where a material interest exists, the editor is recused from writing
the piece, from editing it, and from the second-eyes sign-off. Where a
non-material interest exists, the piece runs with an explicit
[disclosures](/about/#disclosures) note in the byline.

  </div>
</article>

<article class="ethos__principle" id="corrections">
  <header class="ethos__principle-head">
    <p class="ethos__principle-kicker">§ 04 · Corrections &amp; retractions</p>
    <h2 class="ethos__principle-title">Corrections, clarifications, retractions</h2>
    <p class="ethos__principle-summary">We log every change in plain sight. We never silently rewrite.</p>
  </header>
  <div class="ethos__principle-body article__body" markdown="1">

We distinguish three kinds of post-publication change.

**Typo fixes** — a misspelling, a broken link, a punctuation slip — are
made silently. These do not change meaning and do not contribute to
the corrections log.

**Corrections** are any change that affects the meaning of a sentence
or the accuracy of a claim. They are recorded in the article's
`corrections:` frontmatter and surface (a) at the top of the article
as a banner, (b) at the bottom of the article in full, and (c) on the
public [corrections log](/corrections/). The original sentence is
never rewritten in place; the correction notes what was wrong and
what is now correct.

**Retractions** are reserved for pieces whose central claim cannot be
defended. A retracted piece carries a full-width retraction banner with
the date and reason; the original text remains visible beneath, struck
through where appropriate, so the record is preserved. We do not delete
retracted pieces. The retraction is announced once on the
corrections feed and once on the home page.

The article changelog (visible from the byline of every piece) records
post-publish edits derived from git history. It is not a substitute for
the corrections log: minor edits and copy-fixes appear in the changelog
but not in the corrections log.

  </div>
</article>

<article class="ethos__principle" id="anonymity">
  <header class="ethos__principle-head">
    <p class="ethos__principle-kicker">§ 05 · Anonymity</p>
    <h2 class="ethos__principle-title">Anonymity and source protection</h2>
    <p class="ethos__principle-summary">We accept anonymous tips, we protect anonymous sources, and we say so in the piece.</p>
  </header>
  <div class="ethos__principle-body article__body" markdown="1">

Tips arrive via email (PGP-signed where possible), via OnionShare, and
via in-person handoff at conferences. The editor receiving a tip
records it, evaluates it against the sourcing rules above, and brings
it to the desk only if it survives that filter.

Source protection is operational, not aspirational. We take notes on
paper, we do not log identifying metadata, we destroy intermediate
files after the piece runs, and we do not turn over notes to any party
absent a court order we have exhausted appeals against.

If a source asks to withdraw consent before publication, we honour the
request. After publication, the piece stands; we will, on request,
publish a follow-up clarification.

  </div>
</article>

<article class="ethos__principle" id="ai">
  <header class="ethos__principle-head">
    <p class="ethos__principle-kicker">§ 06 · AI</p>
    <h2 class="ethos__principle-title">AI-generated content</h2>
    <p class="ethos__principle-summary">A byline on On Consensus is a human commitment to the words above it.</p>
  </header>
  <div class="ethos__principle-body article__body" markdown="1">

No piece on On Consensus is written by a language model. Editors may
use machine tools for transcription, translation, search, and
copy-editing of their own prose; they may not generate analytical
content under their byline. The line is editorial responsibility: an
editor must be able to defend every sentence appearing under their
name.

Machine-generated illustration is permitted only where labelled as
such in the caption. Machine-generated quotation is never permitted.

When in doubt, we err toward labelling. Readers should never have to
guess whether a sentence was written by a human.

  </div>
</article>

<article class="ethos__principle" id="changes">
  <header class="ethos__principle-head">
    <p class="ethos__principle-kicker">§ 07 · Changes</p>
    <h2 class="ethos__principle-title">Changing this document</h2>
    <p class="ethos__principle-summary">Standards are revised in public; revisions are announced.</p>
  </header>
  <div class="ethos__principle-body article__body" markdown="1">

This document is versioned. The current version appears at the top of
the page; every prior version is reachable via the git history of
`_pages/standards.md`.

Material changes — anything that alters the obligations above — are
announced on the corrections feed and noted in the colophon. Editorial
revisions (typography, examples, cross-links) are not announced but
remain visible in git.

A change to these standards is effective the moment it is merged. We
do not retroactively apply new standards to old pieces; we *do* apply
them to any piece whose corrections, retractions, or republication
falls after the effective date.

  </div>
</article>

<hr class="divider divider--accent" aria-hidden="true">

<p>
  Questions about these standards go to
  <a href="mailto:editors@onconsensus.com">editors@onconsensus.com</a>.
  Specific complaints — a missed disclosure, an unmet sourcing bar,
  an editorial conflict we should have caught — go to
  <a href="mailto:corrections@onconsensus.com">corrections@onconsensus.com</a>.
</p>
