/* On Consensus — client-side search.
 *
 * Two responsibilities:
 *
 * 1. Site-wide:  bind the `/` keyboard shortcut so it focuses the masthead
 *    search input (or, if we're already on /search/, the page input). Mirrors
 *    the GitHub / DuckDuckGo pattern. Skipped while another input/textarea/
 *    contenteditable is focused, while a modifier key is held, and inside
 *    composition events (so it never eats CJK IME input).
 *
 * 2. On /search/ only:  fetch /search.json once, build a Lunr index, and
 *    render results live as the user types (debounced). If the URL already
 *    carries `?q=…` (because the masthead form just submitted), pre-run that
 *    query so the page lands with results already on screen.
 *
 * No third-party network calls. Lunr is vendored under /js/vendor/.
 */
(function () {
  'use strict';

  // ---------------------------------------------------------------------------
  // 1. `/` keyboard shortcut — site-wide.
  // ---------------------------------------------------------------------------

  function isTypingTarget(el) {
    if (!el) return false;
    if (el.isContentEditable) return true;
    var tag = el.tagName;
    if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return true;
    return false;
  }

  var composing = false;
  document.addEventListener('compositionstart', function () { composing = true; });
  document.addEventListener('compositionend',   function () { composing = false; });

  document.addEventListener('keydown', function (e) {
    if (e.key !== '/') return;
    if (composing) return;
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    if (isTypingTarget(document.activeElement)) return;

    var target = document.querySelector('[data-search-input]');
    if (!target) return;
    e.preventDefault();
    target.focus();
    if (typeof target.select === 'function') target.select();
  });

  // ---------------------------------------------------------------------------
  // 2. /search/ page — Lunr index + live results.
  // ---------------------------------------------------------------------------

  var pageInput   = document.getElementById('search-input');
  var resultsEl   = document.getElementById('search-results');
  var statusEl    = document.getElementById('search-status');
  if (!pageInput || !resultsEl || !statusEl) return; // not on /search/

  var script      = document.currentScript ||
                    document.querySelector('script[data-search-index]');
  var indexUrl    = (script && script.getAttribute('data-search-index')) || '/search.json';

  var idx         = null;   // built lunr index
  var docs        = null;   // raw records, keyed by url
  var pendingQuery = null;  // query typed before index finished loading

  function setStatus(text) {
    statusEl.textContent = text;
  }

  function escapeHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function renderEmpty() {
    resultsEl.innerHTML = '';
  }

  function renderResults(query, hits) {
    if (!hits.length) {
      resultsEl.innerHTML = '';
      setStatus('No matches for “' + query + '”.');
      return;
    }
    setStatus(hits.length + ' result' + (hits.length === 1 ? '' : 's') +
              ' for “' + query + '”.');

    var html = '';
    for (var i = 0; i < hits.length; i++) {
      var doc = hits[i];
      if (!doc) continue;
      var tagsHtml = '';
      if (doc.tags && doc.tags.length) {
        tagsHtml = '<ul class="search__hit-tags">';
        for (var t = 0; t < doc.tags.length; t++) {
          tagsHtml += '<li>#' + escapeHtml(doc.tags[t]) + '</li>';
        }
        tagsHtml += '</ul>';
      }
      html +=
        '<li class="search__hit">' +
          '<a class="search__hit-link" href="' + escapeHtml(doc.url) + '">' +
            '<p class="search__hit-meta">' +
              (doc.section ? '<span class="search__hit-section">' + escapeHtml(doc.section) + '</span>' : '') +
              (doc.date ? '<time datetime="' + escapeHtml(doc.date) + '">' + escapeHtml(doc.date_long || doc.date) + '</time>' : '') +
              (doc.author ? '<span class="search__hit-author">' + escapeHtml(doc.author) + '</span>' : '') +
            '</p>' +
            '<h2 class="search__hit-title">' + escapeHtml(doc.title) + '</h2>' +
            (doc.excerpt ? '<p class="search__hit-excerpt">' + escapeHtml(doc.excerpt) + '</p>' : '') +
            tagsHtml +
          '</a>' +
        '</li>';
    }
    resultsEl.innerHTML = html;
  }

  function runQuery(raw) {
    var query = (raw || '').trim();
    if (!query) {
      renderEmpty();
      setStatus('Type to search the archive.');
      return;
    }
    if (!idx) {
      pendingQuery = query;
      setStatus('Loading index…');
      return;
    }

    var hits = [];
    try {
      // Default Lunr query: AND across terms, with title/tags weighted in the index.
      hits = idx.search(query);
    } catch (_) {
      // Lunr throws on bare special characters (`:`, `*`, etc). Fall back to a
      // forgiving wildcard query built from each whitespace-split term.
      try {
        var safe = query
          .replace(/[:~^*+\-]/g, ' ')
          .split(/\s+/)
          .filter(Boolean)
          .map(function (t) { return t + '*'; })
          .join(' ');
        hits = safe ? idx.search(safe) : [];
      } catch (__) {
        hits = [];
      }
    }

    var resolved = [];
    for (var i = 0; i < hits.length; i++) {
      var doc = docs[hits[i].ref];
      if (doc) resolved.push(doc);
    }
    renderResults(query, resolved);
  }

  function debounce(fn, wait) {
    var t = null;
    return function () {
      var ctx = this, args = arguments;
      if (t) clearTimeout(t);
      t = setTimeout(function () { t = null; fn.apply(ctx, args); }, wait);
    };
  }

  function buildIndex(records) {
    docs = Object.create(null);

    idx = lunr(function () {
      this.ref('url');
      this.field('title',   { boost: 10 });
      this.field('tags',    { boost: 5  });
      this.field('section', { boost: 3  });
      this.field('author',  { boost: 2  });
      this.field('excerpt');
      // Keep the original casing/diacritics in the documents we hand back to
      // the renderer — Lunr only sees the tokenised form.
      this.metadataWhitelist = [];

      for (var i = 0; i < records.length; i++) {
        var r = records[i];
        if (!r || !r.url) continue;
        docs[r.url] = r;
        this.add({
          url:     r.url,
          title:   r.title   || '',
          tags:    (r.tags   || []).join(' '),
          section: r.section || '',
          author:  r.author  || '',
          excerpt: r.excerpt || ''
        });
      }
    });
  }

  function readQueryFromUrl() {
    try {
      var params = new URLSearchParams(window.location.search);
      return params.get('q') || '';
    } catch (_) {
      return '';
    }
  }

  function bootstrap() {
    var initial = readQueryFromUrl();
    if (initial) pageInput.value = initial;

    pageInput.addEventListener('input', debounce(function (e) {
      runQuery(e.target.value);
    }, 120));

    // Submitting the form on the search page itself shouldn't reload — we are
    // already here, just run the query.
    var form = pageInput.form;
    if (form) {
      form.addEventListener('submit', function (e) {
        e.preventDefault();
        runQuery(pageInput.value);
      });
    }

    setStatus('Loading index…');
    fetch(indexUrl, { credentials: 'omit' })
      .then(function (res) {
        if (!res.ok) throw new Error('HTTP ' + res.status);
        return res.json();
      })
      .then(function (records) {
        buildIndex(records);
        setStatus('Indexed ' + records.length + ' article' +
                  (records.length === 1 ? '' : 's') + '. Type to search.');
        if (pendingQuery !== null) {
          var q = pendingQuery; pendingQuery = null; runQuery(q);
        } else if (initial) {
          runQuery(initial);
        }
      })
      .catch(function (err) {
        setStatus('Could not load search index (' + err.message + ').');
      });
  }

  if (typeof lunr === 'undefined') {
    // Lunr loads via a separate <script defer>. With both scripts deferred and
    // Lunr listed first, it should be defined by the time we run, but guard
    // against load order changes anyway.
    setStatus('Loading search engine…');
    var wait = setInterval(function () {
      if (typeof lunr !== 'undefined') {
        clearInterval(wait);
        bootstrap();
      }
    }, 50);
    setTimeout(function () {
      if (typeof lunr === 'undefined') {
        clearInterval(wait);
        setStatus('Search engine failed to load.');
      }
    }, 5000);
  } else {
    bootstrap();
  }
})();
