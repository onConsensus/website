/* On Consensus — Reading Experience polish.
 *
 * Wires three orthogonal long-form features. None of them block initial
 * paint; the script is loaded with `defer` from `_includes/head.html` and
 * is post-pages-only.
 *
 *   1. Footnote rail.   Kramdown emits a `<div class="footnotes">` block at
 *      the foot of the article and `<sup class="footnote-ref">` markers
 *      inline. We:
 *        a. Clone every `<li>` from that block into the right-hand
 *           marginalia rail (`[data-footnotes-target]` inside
 *           `_includes/footnotes.html`).
 *        b. Wrap the original block in a <details> so it collapses cleanly
 *           on mobile (CSS hides the rail below the marginalia breakpoint
 *           and hides the inline block above it).
 *        c. Mount an IntersectionObserver on every footnote *reference* so
 *           the matching rail item is highlighted (`is-active`) as the
 *           reader scrolls past it.
 *
 *   2. Glossary popovers.  Reads the `#glossary-data` JSON island injected
 *      by `_includes/glossary-data.html`. For every `<dfn data-term="…">`
 *      on the page, copies the matching definition onto a `data-definition`
 *      attribute and ensures the element is keyboard-focusable. The popover
 *      itself is CSS-only and lives in `_sass/_glossary.scss` — this script
 *      only hydrates the data.
 *
 *   3. Reading progress.  Modern browsers drive the bar via CSS
 *      `animation-timeline: scroll(root)` (see `_sass/_article.scss`), so
 *      the JS path is a *fallback* only. We sniff support via
 *      `CSS.supports('animation-timeline', 'scroll()')` and wire a
 *      requestAnimationFrame-throttled listener only when the browser
 *      cannot drive the bar itself. `prefers-reduced-motion` hides the bar
 *      in CSS — the JS bows out in that case too.
 *
 * No external dependencies. Vanilla JS. Safe to run on pages that lack any
 * of the three feature surfaces — each setup function early-returns when
 * its target nodes are missing.
 */
(function () {
  'use strict';

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init, { once: true });
  } else {
    init();
  }

  function init() {
    setupFootnotes();
    setupGlossary();
    setupReadingProgress();
  }

  // ---------------------------------------------------------------------------
  // Helpers.
  // ---------------------------------------------------------------------------

  function cssEscape(s) {
    if (window.CSS && typeof CSS.escape === 'function') return CSS.escape(s);
    // Minimal fallback covering the kramdown id alphabet (`fn:1`, `fnref:2`).
    return String(s).replace(/([\\:.#\[\]\(\)])/g, '\\$1');
  }

  // ---------------------------------------------------------------------------
  // 1. Footnotes — clone into rail, wrap inline block in <details>, observe.
  // ---------------------------------------------------------------------------

  function setupFootnotes() {
    var article = document.querySelector('.article__body');
    if (!article) return;

    var source = article.querySelector('.footnotes');
    if (!source) return;

    var sourceList = source.querySelector('ol');
    if (!sourceList || !sourceList.children.length) return;

    var rail   = document.querySelector('[data-footnotes-rail]');
    var target = rail && rail.querySelector('[data-footnotes-target]');

    // a. Clone <li> items into the rail. Re-attribute the kramdown id onto a
    //    `data-fn-for` so we can match it from the IntersectionObserver
    //    without colliding with the original `id` (which still anchors the
    //    inline-block accordion).
    if (target) {
      var items = sourceList.children;
      for (var i = 0; i < items.length; i++) {
        var clone = items[i].cloneNode(true);
        if (clone.id) {
          clone.dataset.fnFor = clone.id;
          clone.removeAttribute('id');
        }
        // Strip the kramdown back-arrow from the rail clone — there's no
        // round-trip from the rail to the inline marker.
        var revs = clone.querySelectorAll('.reversefootnote');
        for (var r = 0; r < revs.length; r++) revs[r].remove();
        target.appendChild(clone);
      }
      if (target.children.length) rail.removeAttribute('hidden');
    }

    // b. Wrap the original block in a <details> for the mobile accordion.
    //    Idempotent: bail if a previous run already wrapped it.
    if (!source.querySelector('details.footnotes-accordion')) {
      var details = document.createElement('details');
      details.className = 'footnotes-accordion';
      var summary = document.createElement('summary');
      var n = sourceList.children.length;
      summary.textContent = 'Footnotes (' + n + ')';
      details.appendChild(summary);
      // Move (don't clone) the original ol inside the <details>. Existing
      // `id="fn:N"` anchors are preserved so back-arrow links still work.
      details.appendChild(sourceList);
      // Replace any kramdown-emitted heading element with the details.
      var existingHeading = source.querySelector(':scope > h2, :scope > h3, :scope > h4');
      if (existingHeading) existingHeading.remove();
      source.appendChild(details);
    }

    // c. IntersectionObserver — highlight the rail entry whose reference is
    //    nearest the reading line. Multiple refs can be visible at once; we
    //    pick the highest in document order so the rail tracks the top of
    //    the viewport rather than thrashing.
    if (!('IntersectionObserver' in window) || !target) return;

    var refs = article.querySelectorAll('sup[id^="fnref"]');
    if (!refs.length) return;

    // Document-order-stable list for tie-breaking.
    var refsOrdered = Array.prototype.slice.call(refs);
    var visible = Object.create(null);

    var io = new IntersectionObserver(function (entries) {
      for (var i = 0; i < entries.length; i++) {
        var id = entries[i].target.id;
        if (entries[i].isIntersecting) visible[id] = true;
        else delete visible[id];
      }
      paintActive();
    }, {
      // A "reading line" band: refs are considered active when they sit in
      // the upper-middle of the viewport.
      rootMargin: '-20% 0px -55% 0px',
      threshold: 0
    });

    for (var i = 0; i < refsOrdered.length; i++) io.observe(refsOrdered[i]);

    function paintActive() {
      var actives = target.querySelectorAll('li.is-active');
      for (var i = 0; i < actives.length; i++) actives[i].classList.remove('is-active');

      var pick = null;
      for (var j = 0; j < refsOrdered.length; j++) {
        if (visible[refsOrdered[j].id]) { pick = refsOrdered[j]; break; }
      }
      if (!pick) return;

      // `fnref:1` → `fn:1`
      var fnId = pick.id.replace(/^fnref/, 'fn');
      var li = target.querySelector('li[data-fn-for="' + cssEscape(fnId) + '"]');
      if (li) li.classList.add('is-active');
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Glossary — hydrate `<dfn data-term>` with definitions from the JSON
  //    island. The popover is CSS-only.
  // ---------------------------------------------------------------------------

  function setupGlossary() {
    var island = document.getElementById('glossary-data');
    if (!island) return;

    var data;
    try { data = JSON.parse(island.textContent || '{}'); }
    catch (_) { return; }
    if (!data || typeof data !== 'object') return;

    var dfns = document.querySelectorAll('dfn[data-term]');
    for (var i = 0; i < dfns.length; i++) {
      var dfn = dfns[i];
      var key = dfn.getAttribute('data-term');
      if (!key) continue;
      var entry = data[key];
      if (!entry || !entry.definition) continue;

      // Trim surrounding whitespace (YAML `>-` folded blocks leave a single
      // trailing newline that would break tight popover layouts).
      var definition = String(entry.definition).replace(/\s+/g, ' ').trim();
      dfn.setAttribute('data-definition', definition);

      // Keyboard accessibility — the CSS popover triggers on :focus, so the
      // element needs to be focusable.
      if (!dfn.hasAttribute('tabindex')) dfn.setAttribute('tabindex', '0');
      // Mark it semantically as a definition tooltip target.
      if (!dfn.hasAttribute('role')) dfn.setAttribute('role', 'note');
      if (!dfn.hasAttribute('aria-label')) {
        dfn.setAttribute('aria-label',
          (entry.display || dfn.textContent || key) + ': ' + definition);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Reading progress — JS fallback for browsers without scroll-timeline.
  // ---------------------------------------------------------------------------

  function setupReadingProgress() {
    var bar = document.querySelector('.reading-progress__bar');
    if (!bar) return;

    // Modern browsers: CSS `animation-timeline: scroll(root)` drives the bar.
    var supportsScrollTL = !!(window.CSS && typeof CSS.supports === 'function' &&
      CSS.supports('animation-timeline', 'scroll()'));
    if (supportsScrollTL) return;

    // Reduced-motion: CSS already hides the bar; nothing to wire.
    if (window.matchMedia &&
        window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      return;
    }

    var ticking = false;
    function update() {
      var doc = document.documentElement;
      var top = window.pageYOffset || doc.scrollTop || 0;
      var height = (doc.scrollHeight || 0) - (doc.clientHeight || 0);
      var pct = height > 0 ? Math.max(0, Math.min(100, (top / height) * 100)) : 0;
      bar.style.width = pct.toFixed(2) + '%';
      ticking = false;
    }
    function onScroll() {
      if (ticking) return;
      ticking = true;
      window.requestAnimationFrame(update);
    }
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll);
    update();
  }
})();
