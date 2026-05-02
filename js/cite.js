// cite.js — wires the "Cite this" disclosure: tab switching + copy-to-clipboard.
// Progressive enhancement. Without JS, the <pre> blocks remain visible and
// selectable so a reader can copy text manually.
(function () {
  'use strict';

  function activateTab(scope, name) {
    var tabs  = scope.querySelectorAll('[data-cite-tab]');
    var panes = scope.querySelectorAll('[data-cite-pane]');
    tabs.forEach(function (t) {
      var on = t.getAttribute('data-cite-tab') === name;
      t.setAttribute('aria-selected', on ? 'true' : 'false');
      t.classList.toggle('is-active', on);
    });
    panes.forEach(function (p) {
      var on = p.getAttribute('data-cite-pane') === name;
      if (on) { p.removeAttribute('hidden'); } else { p.setAttribute('hidden', ''); }
    });
  }

  function flash(button, text) {
    var original = button.textContent;
    button.textContent = text;
    button.classList.add('is-flashing');
    setTimeout(function () {
      button.textContent = original;
      button.classList.remove('is-flashing');
    }, 1400);
  }

  function copy(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(text);
    }
    return new Promise(function (resolve, reject) {
      try {
        var ta = document.createElement('textarea');
        ta.value = text;
        ta.setAttribute('readonly', '');
        ta.style.position = 'absolute';
        ta.style.left = '-9999px';
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        document.body.removeChild(ta);
        resolve();
      } catch (e) { reject(e); }
    });
  }

  document.querySelectorAll('.cite').forEach(function (scope) {
    // Initial enhancement: with JS available, hide all but the
    // currently-active pane. Without JS, every pane stays visible so
    // the citation block is a true progressive-enhancement: a reader
    // with scripting disabled sees BibTeX, RIS, Hayagriva, and plain
    // text as four labelled <pre> blocks and can select any of them.
    var activeTab = scope.querySelector('[data-cite-tab][aria-selected="true"]')
                  || scope.querySelector('[data-cite-tab]');
    if (activeTab) {
      activateTab(scope, activeTab.getAttribute('data-cite-tab'));
    }

    scope.addEventListener('click', function (event) {
      var tab = event.target.closest('[data-cite-tab]');
      if (tab) {
        event.preventDefault();
        activateTab(scope, tab.getAttribute('data-cite-tab'));
        return;
      }
      var btn = event.target.closest('[data-cite-copy]');
      if (btn) {
        var name = btn.getAttribute('data-cite-copy');
        var pane = scope.querySelector('[data-cite-pane="' + name + '"] code');
        if (!pane) { return; }
        var text = pane.textContent;
        copy(text).then(
          function () { flash(btn, 'Copied'); },
          function () { flash(btn, 'Press Ctrl+C'); }
        );
      }
    });
  });
})();
