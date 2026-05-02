/* On Consensus — On-chain reference rewriter.
 *
 * Scans the article body for tx hashes, Ethereum addresses, ENS names,
 * and (opt-in) Bitcoin block heights, and replaces each match with a
 * multi-explorer link cluster + a copy-to-clipboard button. The explorer
 * set is read from a `<script type="application/json" id="onchain-config">`
 * island emitted by `_includes/onchain-config.html`, itself driven by
 * `_config.yml :: onchain.explorers`. Adding a new explorer is a
 * config-only change.
 *
 * Design notes:
 *   · Idempotent. The walker skips elements already wrapped in `.onchain`
 *     and any node inside `<a>`, `<code>`, `<pre>`, `<script>`, `<style>`,
 *     or any element marked `data-onchain="off"`.
 *   · Block heights in body copy are auto-linked by default (the
 *     `onchain_block_heights_in_body` flag in `_config.yml`). To
 *     reduce false positives the rewriter only treats a digit cluster
 *     as a block height when (a) it appears in a "block #N" / "block N"
 *     phrasing and (b) N falls inside the live Bitcoin range
 *     `[btc_block_min, btc_tip + lookahead]` published in the
 *     JSON config island. Explicit `data-onchain-block` elements are
 *     always rewritten regardless — that's how the byline opts in.
 *   · A single text node may contain multiple kinds (e.g. an address
 *     immediately followed by an ENS name). The rewriter scans all
 *     four patterns simultaneously, sorts the matches by offset,
 *     drops overlaps, and rebuilds the node in one pass.
 *   · No dependencies. ~3 KB minified.
 */
(function () {
  'use strict';

  var cfgEl = document.getElementById('onchain-config');
  if (!cfgEl) return;
  var cfg;
  try { cfg = JSON.parse(cfgEl.textContent); }
  catch (e) { return; }
  if (!cfg || !cfg.explorers) return;

  // Bitcoin block-range gate. When `btc_tip` is 0 (the data file has
  // never been refreshed) we leave the upper bound open so authors
  // can still surface heights — the lower bound alone is enough to
  // rule out years and percentages mistaken for blocks.
  var BTC_MIN = (cfg.btc_block_min && cfg.btc_block_min > 0) ? cfg.btc_block_min : 700000;
  var BTC_MAX = (cfg.btc_tip && cfg.btc_tip > 0)
    ? cfg.btc_tip + (cfg.btc_tip_lookahead || 1)
    : 0; // 0 == "no upper bound"

  var ROOTS = document.querySelectorAll('.article__body, .byline, .embargo-seal, .timestamp-footer');
  if (!ROOTS.length) return;

  var SKIP_TAGS = { A: 1, CODE: 1, PRE: 1, SCRIPT: 1, STYLE: 1, BUTTON: 1, TEXTAREA: 1 };

  // Patterns. All anchored with lookarounds-by-hand because the regex must
  // tolerate punctuation directly adjacent to the value (e.g. "vitalik.eth.")
  var PAT_TX     = /\b0x[0-9a-fA-F]{64}\b/g;
  var PAT_ADDR   = /\b0x[0-9a-fA-F]{40}\b/g;
  var PAT_ENS    = /\b([a-z0-9](?:[a-z0-9-]{1,61}[a-z0-9])?)\.eth\b/gi;
  var PAT_BLOCK  = /\bblock\s*#?\s*(\d{6,7})\b/gi;

  function truncate(value, head, tail) {
    if (value.length <= head + tail + 1) return value;
    return value.slice(0, head) + '…' + value.slice(-tail);
  }

  function makeCluster(kind, value, displayValue) {
    var explorers = cfg.explorers[kind] || [];
    var span = document.createElement('span');
    span.className = 'onchain onchain--' + kind;
    span.setAttribute('data-onchain', kind);
    span.setAttribute('data-value', value);

    var code = document.createElement('code');
    code.className = 'onchain__value';
    code.textContent = displayValue || value;
    code.setAttribute('title', value);
    span.appendChild(code);

    if (explorers.length) {
      var pop = document.createElement('span');
      pop.className = 'onchain__pop';

      var label = document.createElement('span');
      label.className = 'onchain__label';
      label.textContent = 'Open in';
      pop.appendChild(label);

      explorers.forEach(function (ex) {
        var a = document.createElement('a');
        a.className = 'onchain__link';
        a.href = ex.url.replace('{value}', encodeURIComponent(value));
        a.target = '_blank';
        a.rel = 'external noopener';
        a.textContent = ex.name;
        pop.appendChild(a);
      });

      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'onchain__copy';
      btn.textContent = 'Copy';
      btn.setAttribute('aria-label', 'Copy ' + value + ' to clipboard');
      btn.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();
        var done = function () {
          btn.classList.add('is-copied');
          btn.textContent = 'Copied';
          setTimeout(function () {
            btn.classList.remove('is-copied');
            btn.textContent = 'Copy';
          }, 1400);
        };
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(value).then(done, function () { done(); });
        } else {
          var ta = document.createElement('textarea');
          ta.value = value; document.body.appendChild(ta);
          ta.select(); try { document.execCommand('copy'); } catch (_) {}
          document.body.removeChild(ta);
          done();
        }
      });
      pop.appendChild(btn);
      span.appendChild(pop);
    }
    return span;
  }

  // Collect every match in `text` for one (regex, kindFn) pair and
  // append `{start, end, info}` records to `acc`. `kindFn` returns
  // either an `{kind, value, display}` object (rewrite) or null (skip
  // this match — used for body-block-height range gating).
  function collect(acc, text, regex, kindFn) {
    regex.lastIndex = 0;
    var m;
    while ((m = regex.exec(text)) !== null) {
      var info = kindFn(m);
      if (!info) continue;
      acc.push({ start: m.index, end: m.index + m[0].length, info: info });
    }
  }

  // Rewrite a text node against ALL four patterns at once. We collect
  // every candidate match, sort by offset, and skip any match whose
  // range overlaps an earlier (higher-priority) one — that's how the
  // 64-hex tx hash wins over the 40-hex address regex even though both
  // would match the leading 40 chars of a tx hash. This loop replaces
  // the previous "first kind that matches wins for the whole node"
  // behaviour, which silently dropped mixed-kind tokens (e.g. an
  // address followed by an ENS name in the same sentence).
  function rewriteText(node) {
    var text = node.nodeValue;
    if (!text || text.length < 5) return;
    var matches = [];
    collect(matches, text, PAT_TX, function (m) {
      return { kind: 'eth_tx', value: m[0], display: truncate(m[0], 10, 8) };
    });
    collect(matches, text, PAT_ADDR, function (m) {
      return { kind: 'eth_address', value: m[0], display: truncate(m[0], 6, 4) };
    });
    collect(matches, text, PAT_ENS, function (m) {
      return { kind: 'ens', value: m[0].toLowerCase(), display: m[0].toLowerCase() };
    });
    if (cfg.block_heights_in_body) {
      collect(matches, text, PAT_BLOCK, function (m) {
        var n = parseInt(m[1], 10);
        if (!isFinite(n)) return null;
        if (n < BTC_MIN) return null;
        if (BTC_MAX && n > BTC_MAX) return null;
        return { kind: 'btc_block', value: String(n), display: '#' + n };
      });
    }
    if (!matches.length) return;
    matches.sort(function (a, b) { return a.start - b.start; });

    // Greedy non-overlap: keep first, then drop any later match that
    // begins before the previous one ends.
    var kept = []; var cursor = -1;
    for (var i = 0; i < matches.length; i++) {
      if (matches[i].start >= cursor) {
        kept.push(matches[i]);
        cursor = matches[i].end;
      }
    }

    var frag = document.createDocumentFragment();
    var pos = 0;
    for (var j = 0; j < kept.length; j++) {
      var k = kept[j];
      if (k.start > pos) frag.appendChild(document.createTextNode(text.slice(pos, k.start)));
      frag.appendChild(makeCluster(k.info.kind, k.info.value, k.info.display));
      pos = k.end;
    }
    if (pos < text.length) frag.appendChild(document.createTextNode(text.slice(pos)));
    node.parentNode.replaceChild(frag, node);
  }

  function walk(root) {
    var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode: function (n) {
        var p = n.parentNode;
        while (p && p !== root) {
          if (SKIP_TAGS[p.nodeName]) return NodeFilter.FILTER_REJECT;
          if (p.classList && p.classList.contains('onchain')) return NodeFilter.FILTER_REJECT;
          if (p.getAttribute && p.getAttribute('data-onchain') === 'off') return NodeFilter.FILTER_REJECT;
          p = p.parentNode;
        }
        return NodeFilter.FILTER_ACCEPT;
      }
    });
    var nodes = [], n;
    while ((n = walker.nextNode())) nodes.push(n);

    nodes.forEach(rewriteText);

    // Always rewrite explicit opt-in block-height markers regardless of the
    // body-wide setting. These are how the byline + sealed-commit metadata
    // surface a clickable link cluster.
    Array.prototype.forEach.call(root.querySelectorAll('[data-onchain-block]'), function (el) {
      if (el.querySelector('.onchain')) return;
      var raw = (el.textContent || '').trim();
      var num = (raw.match(/\d+/) || [])[0];
      if (!num) return;
      var cluster = makeCluster('btc_block', num, '#' + num);
      el.textContent = '';
      el.appendChild(cluster);
    });
  }

  function run() {
    Array.prototype.forEach.call(ROOTS, walk);
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', run, { once: true });
  } else {
    run();
  }
})();
