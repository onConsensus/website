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
 *   · Block heights in body copy are off by default to avoid false
 *     positives on bare numbers. Explicit `data-onchain-block` elements
 *     are always rewritten — that's how the byline opts in.
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

  // Tag a text node with replacements for one regex/kind pair.
  function rewriteText(node, regex, kindFn) {
    var text = node.nodeValue;
    regex.lastIndex = 0;
    if (!regex.test(text)) return false;
    regex.lastIndex = 0;
    var frag = document.createDocumentFragment();
    var lastIdx = 0; var m;
    while ((m = regex.exec(text)) !== null) {
      var start = m.index;
      var end = start + m[0].length;
      if (start > lastIdx) frag.appendChild(document.createTextNode(text.slice(lastIdx, start)));
      var info = kindFn(m);
      if (info) {
        frag.appendChild(makeCluster(info.kind, info.value, info.display));
      } else {
        frag.appendChild(document.createTextNode(m[0]));
      }
      lastIdx = end;
    }
    if (lastIdx < text.length) frag.appendChild(document.createTextNode(text.slice(lastIdx)));
    node.parentNode.replaceChild(frag, node);
    return true;
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

    nodes.forEach(function (node) {
      // 64-hex tx hashes first (must precede 40-hex address pattern).
      if (rewriteText(node, PAT_TX, function (m) {
        return { kind: 'eth_tx', value: m[0], display: truncate(m[0], 10, 8) };
      })) return;
      if (rewriteText(node, PAT_ADDR, function (m) {
        return { kind: 'eth_address', value: m[0], display: truncate(m[0], 6, 4) };
      })) return;
      if (rewriteText(node, PAT_ENS, function (m) {
        return { kind: 'ens', value: m[0].toLowerCase(), display: m[0].toLowerCase() };
      })) return;
      if (cfg.block_heights_in_body) {
        rewriteText(node, PAT_BLOCK, function (m) {
          return { kind: 'btc_block', value: m[1], display: '#' + m[1] };
        });
      }
    });

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
