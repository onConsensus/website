/* On Consensus — TeX rendering for pages that opt in with `math: true`.
 *
 * Loaded only where the frontmatter asks for it (see `_includes/head.html`),
 * so the ~300KB of KaTeX never reaches a page that has no equations on it.
 *
 * Why not KaTeX's auto-render extension:
 *
 *   auto-render walks prose text nodes looking for `$` delimiters. This desk
 *   writes about fee markets, block subsidies and prover economics, so `$` in
 *   running copy is ordinary currency — and auto-render would try to typeset
 *   it. Instead kramdown marks math for us at build time: with
 *   `math_engine: ~` in _config.yml it wraps each expression in
 *   `.kdmath` — a <span> for inline, a <div> for block — keeping the `$$`
 *   delimiters inside. We render exactly those elements and touch nothing
 *   else on the page.
 *
 * Degradation: if KaTeX fails to load, or an expression does not parse, the
 * original TeX stays visible and readable. That is the correct fallback for a
 * publication — a reader who can read `N > 3f` loses nothing.
 */
(function () {
  'use strict';

  var nodes = document.querySelectorAll('.kdmath');
  if (!nodes.length) return;

  if (typeof katex === 'undefined') {
    // Deferred scripts run in source order and KaTeX is emitted first, so
    // this should not happen. Leaving the raw TeX in place is a fine outcome
    // if it ever does.
    return;
  }

  Array.prototype.forEach.call(nodes, function (el) {
    var tex = el.textContent.trim();

    // kramdown keeps the delimiters, but not symmetrically: block math
    // (a <div>) retains the full `$$…$$`, while inline math (a <span>)
    // comes back with a single `$…$`. Strip whichever pair is present,
    // longest first — `$$x$$` must not be mistaken for `$` + `$x$$`.
    if (tex.length > 3 && tex.slice(0, 2) === '$$' && tex.slice(-2) === '$$') {
      tex = tex.slice(2, -2).trim();
    } else if (tex.length > 1 && tex.charAt(0) === '$' && tex.slice(-1) === '$') {
      tex = tex.slice(1, -1).trim();
    }
    if (!tex) return;

    // Trust the element type rather than sniffing the content: kramdown has
    // already decided block vs inline, and it is the authority on that.
    var displayMode = el.tagName === 'DIV';

    try {
      katex.render(tex, el, {
        displayMode: displayMode,
        // Render the offending TeX in the accent colour instead of throwing,
        // so one bad expression cannot blank out a whole article.
        throwOnError: false,
        errorColor: 'var(--accent)',
        strict: 'ignore'
      });
    } catch (err) {
      // katex.render already handles parse errors under throwOnError:false;
      // this catches anything structural. Leave the source TeX untouched.
      if (window.console && console.warn) {
        console.warn('[math] could not render an expression; leaving TeX as-is.', err);
      }
    }
  });
})();
