(() => {
  let el = {};
  const state = {
    jailTotal: 0,
    countdownLabel: 'Letzte Chance: ',
    toastQueue: [],
    toastShowing: false,
    initialized: false,
    urgentCountdownThreshold: 3, // Seconds at which countdown becomes urgent
  };

  function $(sel) { return document.querySelector(sel); }
  function byId(id) { return document.getElementById(id); }

  function safeText(node, text) {
    if (node) node.textContent = text != null ? String(text) : '';
  }

  function setHidden(node, hidden) {
    if (!node) return;
    if (hidden) {
      node.classList.add('hidden');
      node.classList.remove('show');
    } else {
      node.classList.remove('hidden');
    }
  }

  function initDom() {
    if (state.initialized) return;
    el = {
      scenario: byId('scenario'),
      sTitle: $('#scenario .title'),
      sHint: $('#scenario .hint'),
      sCountdown: $('#scenario .countdown'),
      toast: byId('toast'),
      jail: byId('jail'),
      jTitle: $('#jail .title'),
      jSub: $('#jail .subtitle'),
      jTimer: $('#jail .timer'),
      jBar: $('#jail .bar'),
      aLog: byId('arrest-log'),
      aLogTitle: $('#arrest-log .title'),
      aLogLines: $('#arrest-log .lines'),
      // Wanted display elements
      wantedDisplay: byId('wanted-display'),
      wantedStars: document.querySelectorAll('.wanted-stars .star'),
      // debug elements (may be present from index.html)
      dbgRoot: byId('mtj-debug'),
      dbgStatus: byId('mtj-debug-status'),
      dbgFocus: byId('mtj-debug-focus'),
      dbgLog: byId('mtj-debug-log'),
      dbgBtnClear: byId('mtj-debug-btn-clear'),
      dbgBtnState: byId('mtj-debug-btn-state'),
    };

    // Initial hide to ensure clean state
    setHidden(el.scenario, true);
    setHidden(el.toast, true);
    setHidden(el.jail, true);
    setHidden(el.aLog, true);
    setHidden(el.wantedDisplay, true);

    // Ensure UI is hidden globally until something is shown
    setUiVisible(false);

    // Initialize debug (if debug DOM exists)
    initDebug();

    state.initialized = true;
  }

  function fmt(sec) {
    sec = Number(sec) || 0;
    if (sec < 0) sec = 0;
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }

  function enqueueToast(text) {
    const t = (text != null ? String(text) : '').trim();
    if (!t) return;
    state.toastQueue.push(t);
    if (!state.toastShowing) showNextToast();
  }

  function showNextToast() {
    if (state.toastShowing) return;
    const text = state.toastQueue.shift();
    if (!text) return;

    state.toastShowing = true;
    safeText(el.toast, text);
    el.toast.classList.add('show');
    setHidden(el.toast, false);

    const DURATION = 2400;
    setTimeout(() => {
      el.toast.classList.remove('show');
      setHidden(el.toast, true);
      state.toastShowing = false;
      if (state.toastQueue.length > 0) {
        setTimeout(showNextToast, 150);
      }
    }, DURATION);
  }

  function setUiVisible(show) {
    try {
      if (show) {
        document.body.classList.add('ui-on');
      } else {
        document.body.classList.remove('ui-on');
      }
      if (el && el.dbgStatus) safeText(el.dbgStatus, show ? 'ui-on' : 'ui-off');
    } catch (e) {}
  }

  function evaluateUiVisibility() {
    const panels = [
      el && el.scenario && !el.scenario.classList.contains('hidden'),
      el && el.jail && !el.jail.classList.contains('hidden'),
      el && el.aLog && !el.aLog.classList.contains('hidden'),
      el && el.toast && !el.toast.classList.contains('hidden'),
    ];
    const anyVisible = panels.some(Boolean);
    setUiVisible(anyVisible);
  }

  function handleScenarioToggle(d) {
    state.countdownLabel = (d.countdownLabel && String(d.countdownLabel)) || state.countdownLabel || 'Letzte Chance: ';
    if (d.show) {
      safeText(el.sTitle, d.title || 'Polizei-Einsatz');
      safeText(el.sHint, d.hint || '');
      if (d.countdown) {
        safeText(el.sCountdown, `${state.countdownLabel}${Number(d.countdown)}s`);
      } else {
        safeText(el.sCountdown, '');
      }
      setHidden(el.scenario, false);
      // GANZES UI pulsiert langsam (sicht <-> transparent)
      if (el.scenario) el.scenario.classList.add('pulse-ui');
    } else {
      setHidden(el.scenario, true);
      if (el.scenario) el.scenario.classList.remove('pulse-ui');
    }
    evaluateUiVisibility();
  }

  function handleScenarioCountdown(d) {
    const v = Number(d.value);
    safeText(el.sCountdown, `${state.countdownLabel}${isFinite(v) ? v : 0}s`);
    
    // Add urgent class when countdown is low
    if (el.sCountdown) {
      if (v <= state.urgentCountdownThreshold) {
        el.sCountdown.classList.add('urgent');
      } else {
        el.sCountdown.classList.remove('urgent');
      }
    }
  }

  function handleArrestLog(d) {
    if (d.show) {
      safeText(el.aLogTitle, d.title || 'Festnahmeprotokoll');
      if (el.aLogLines) {
        el.aLogLines.innerHTML = '';
        const lines = Array.isArray(d.lines) ? d.lines : [];
        for (const line of lines) {
          const li = document.createElement('li');
          li.textContent = String(line);
          el.aLogLines.appendChild(li);
        }
      }
      setHidden(el.aLog, false);
    } else {
      setHidden(el.aLog, true);
    }
    evaluateUiVisibility();
  }

  function handleJailToggle(d) {
    if (d.show) {
      state.jailTotal = Number(d.seconds) || 0;
      safeText(el.jTitle, d.title || 'Gefängnis');
      safeText(el.jSub, d.subtitle || '');
      safeText(el.jTimer, fmt(state.jailTotal));
      if (el.jBar) el.jBar.style.width = '0%';
      setHidden(el.jail, false);
    } else {
      setHidden(el.jail, true);
    }
    evaluateUiVisibility();
  }

  function handleJailTick(d) {
    const secs = Number(d.seconds) || 0;
    safeText(el.jTimer, fmt(secs));
    if (el.jBar && state.jailTotal > 0) {
      const done = Math.max(0, Math.min(1, 1 - (secs / state.jailTotal)));
      el.jBar.style.width = `${(done * 100).toFixed(2)}%`;
    }
  }

  function handleWantedUpdate(d) {
    const level = Number(d.level) || 0;
    const show = d.show !== false;
    
    if (!el.wantedDisplay || !el.wantedStars) return;
    
    // Show/hide the wanted display
    setHidden(el.wantedDisplay, !show);
    
    // Update star states
    el.wantedStars.forEach((star, index) => {
      const starNumber = index + 1;
      const wasActive = star.classList.contains('active');
      const shouldBeActive = starNumber <= level;
      
      if (shouldBeActive && !wasActive) {
        // Star is becoming active
        star.classList.add('active', 'new-active');
        setTimeout(() => star.classList.remove('new-active'), 600);
      } else if (!shouldBeActive && wasActive) {
        // Star is becoming inactive
        star.classList.remove('active', 'new-active');
      }
    });
    
    // Add flash effect when wanted level increases
    if (show && level > 0) {
      el.wantedDisplay.classList.add('flash');
      setTimeout(() => el.wantedDisplay.classList.remove('flash'), 500);
    }
    
    // Add special styling for max wanted level
    if (level >= 5) {
      el.wantedDisplay.classList.add('level-5');
    } else {
      el.wantedDisplay.classList.remove('level-5');
    }
  }

  function initDebug() {
    if (!el || !el.dbgRoot) return;
    if (el.dbgBtnClear) {
      el.dbgBtnClear.addEventListener('click', () => {
        appendDebugLog('-> clear focus requested');
        fetch('https://mtj_arrest/clear_focus', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({}),
        }).then(() => {
          appendDebugLog('<- clear_focus sent');
          requestState();
        }).catch((err) => appendDebugLog('ERROR clear_focus: ' + String(err)));
      });
    }
    if (el.dbgBtnState) {
      el.dbgBtnState.addEventListener('click', () => {
        appendDebugLog('-> state requested');
        requestState();
      });
    }
    safeText(el.dbgStatus, 'loaded');
    safeText(el.dbgFocus, 'unknown');
    appendDebugLog('mtj NUI debug ready');
  }

  function appendDebugLog(msg) {
    if (!el || !el.dbgLog) return;
    const now = new Date();
    const ts = now.toLocaleTimeString();
    el.dbgLog.textContent = `${ts} ${msg}\n` + el.dbgLog.textContent;
  }

  function updateDebugState(obj) {
    if (!el) return;
    try {
      if (typeof obj === 'object' && obj !== null) {
        if (el.dbgStatus) safeText(el.dbgStatus, obj.statusText || 'ok');
        if (el.dbgFocus) safeText(el.dbgFocus, (obj.isNuiFocused ? 'focused' : 'not focused') + (obj.mtj_nuiOpen ? ' (mtj_open)' : ''));
        appendDebugLog('<- state: ' + JSON.stringify(obj));
      } else {
        if (el.dbgStatus) safeText(el.dbgStatus, String(obj));
        appendDebugLog('<- state: ' + String(obj));
      }
    } catch (e) {}
  }

  function requestState() {
    fetch('https://mtj_arrest/request_state', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    }).then((r) => r.json()).then((data) => {
      updateDebugState(data);
    }).catch((err) => {
      appendDebugLog('ERROR request_state: ' + String(err));
      if (el.dbgStatus) safeText(el.dbgStatus, 'request failed');
    });
  }

  function handleDebugMessage(d) {
    if (!d) return;
    if (d.action === 'mtj_debug_state') {
      updateDebugState(d.payload || {});
    } else if (d.action === 'mtj_debug_log') {
      appendDebugLog(d.text || '');
    }
  }

  function onMessage(e) {
    const d = e.data || {};
    switch (d.action) {
      case 'scenarioToggle':
        handleScenarioToggle(d);
        break;
      case 'scenarioCountdown':
        handleScenarioCountdown(d);
        break;
      case 'toast':
        enqueueToast(d.text || '');
        if (d.text) {
          setHidden(el.toast, false);
          evaluateUiVisibility();
        }
        break;
      case 'arrestLog':
        handleArrestLog(d);
        break;
      case 'jailToggle':
        handleJailToggle(d);
        break;
      case 'jailTick':
        handleJailTick(d);
        break;
      case 'updateWanted':
        handleWantedUpdate(d);
        break;
      case 'uiToggle':
        if (typeof d.show !== 'undefined') setUiVisible(!!d.show);
        break;
      case 'mtj_debug_state':
      case 'mtj_debug_log':
        handleDebugMessage(d);
        break;
      default:
        break;
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      initDom();
      window.addEventListener('message', onMessage);
    });
  } else {
    initDom();
    window.addEventListener('message', onMessage);
  }

  window.mtj = window.mtj || {};
  window.mtj.requestState = requestState;
  window.mtj.appendDebug = appendDebugLog;
  window.mtj.setUiVisible = setUiVisible;
})();