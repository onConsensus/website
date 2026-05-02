// audio-player.js — wire speed-control buttons to the article narration.
//
// Plain HTML5 <audio> with custom playback-rate buttons; no third-party
// widget. Each .audio-player block is independently wired so multiple
// players on a page (unlikely, but cheap) work without interference.
(function () {
  'use strict';

  function wire(player) {
    var audio = player.querySelector('.audio-player__audio');
    if (!audio) return;
    var buttons = player.querySelectorAll('.audio-player__speed');
    buttons.forEach(function (btn) {
      btn.addEventListener('click', function () {
        var rate = parseFloat(btn.getAttribute('data-speed'));
        if (!Number.isFinite(rate)) return;
        audio.playbackRate = rate;
        buttons.forEach(function (b) {
          b.setAttribute('aria-pressed', b === btn ? 'true' : 'false');
        });
      });
    });
  }

  document.querySelectorAll('.audio-player').forEach(wire);
})();
