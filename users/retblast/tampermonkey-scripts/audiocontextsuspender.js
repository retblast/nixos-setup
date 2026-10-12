// ==UserScript==
// @name         AudioContext Auto-Suspend (X/Twitter)
// @namespace    reina.autosuspend
// @version      1.1
// @description  Suspends AudioContext instances when the tab is hidden or idle, to stop background CPU/turbo lock from silent WebAudio playback.
// @match        https://x.com/*
// @match        https://twitter.com/*
// @run-at       document-start
// @grant        unsafeWindow
// ==/UserScript==

(function () {
  'use strict';

  // --- tunables ---
  const IDLE_SUSPEND_MS = 4000;    // suspend if page has had no user gesture for this long
  const HIDDEN_SUSPEND_MS = 3000;  // suspend once tab is backgrounded for this long
  const CHECK_INTERVAL_MS = 1000;
  const GRACE_PERIOD_MS = 10000;   // don't touch a context until it's existed this long,
                                     // so we never race the page's own init/hydration code

  const win = typeof unsafeWindow !== 'undefined' ? unsafeWindow : window;
  const NativeAudioContext = win.AudioContext || win.webkitAudioContext;
  if (!NativeAudioContext) return;

  const contexts = new Map(); // ctx -> creation timestamp
  let lastActivity = Date.now();

  ['click', 'keydown', 'mousedown', 'touchstart'].forEach((evt) =>
    document.addEventListener(evt, () => { lastActivity = Date.now(); }, true)
  );

  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) {
      // coming back into view counts as activity, so foreground idle timer restarts
      lastActivity = Date.now();
    }
  });

  function maybeSuspend(ctx, createdAt) {
    if (ctx.state !== 'running') return;
    if (Date.now() - createdAt < GRACE_PERIOD_MS) return; // still in its init window, leave it alone

    if (document.hidden) {
      if (Date.now() - hiddenSince > HIDDEN_SUSPEND_MS) {
        ctx.suspend().catch(() => {});
      }
      return;
    }

    if (Date.now() - lastActivity > IDLE_SUSPEND_MS) {
      ctx.suspend().catch(() => {});
    }
  }

  let hiddenSince = document.hidden ? Date.now() : null;
  document.addEventListener('visibilitychange', () => {
    hiddenSince = document.hidden ? Date.now() : null;
  });

  setInterval(() => {
    for (const [ctx, createdAt] of contexts) maybeSuspend(ctx, createdAt);
  }, CHECK_INTERVAL_MS);

  function patched(...args) {
    const instance = new NativeAudioContext(...args);
    contexts.set(instance, Date.now());
    return instance;
  }
  patched.prototype = NativeAudioContext.prototype;

  win.AudioContext = patched;
  if (win.webkitAudioContext) win.webkitAudioContext = patched;
})();
