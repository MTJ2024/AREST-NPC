/**
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
 * ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
 * ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */
(() => {
  let el = {};
  const state = {
    jailTotal: 0,
    scenarioTotal: 11,
    countdownLabel: 'Letzte Chance: ',
    toastQueue: [],
    toastShowing: false,
    initialized: false,
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
      vorwarnung: byId('vorwarnung'),
      vwTitle: $('#vorwarnung .title'),
      vwText: $('#vorwarnung .vorwarnung-text'),
      vwCountdown: $('#vorwarnung .vorwarnung-countdown'),
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
      // debug elements (may be present from index.html)
      dbgRoot: byId('mtj-debug'),
      dbgStatus: byId('mtj-debug-status'),
      dbgFocus: byId('mtj-debug-focus'),
      dbgLog: byId('mtj-debug-log'),
      dbgBtnClear: byId('mtj-debug-btn-clear'),
      dbgBtnState: byId('mtj-debug-btn-state'),
      notifyStack: byId('notify-stack'),
    };

    // Initial hide to ensure clean state
    setHidden(el.vorwarnung, true);
    setHidden(el.scenario, true);
    setHidden(el.toast, true);
    setHidden(el.jail, true);
    setHidden(el.aLog, true);

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

    const DURATION = 6000;
    setTimeout(() => {
      el.toast.classList.remove('show');
      setHidden(el.toast, true);
      state.toastShowing = false;
      if (state.toastQueue.length > 0) {
        setTimeout(showNextToast, 150);
      }
    }, DURATION);
  }

  /* ═══ Custom Notification (links mittig) ═══ */
  const NOTIFY_ICONS = {
    polizei: '🚨',
    erfolg:  '✅',
    warnung: '⚠️',
    info:    'ℹ️',
  };
  const NOTIFY_DURATION = 8000;
  const NOTIFY_MAX = 5;

  function showNotify(text, type) {
    if (!el.notifyStack) return;
    type = type || 'info';
    const icon = NOTIFY_ICONS[type] || NOTIFY_ICONS.info;

    // Clean GTA formatting codes (~r~, ~s~, ~g~, ~b~ etc.)
    const cleanText = String(text || '').replace(/~[a-zA-Z]~/g, '');

    const item = document.createElement('div');
    item.className = 'notify-item type-' + type;

    const iconSpan = document.createElement('span');
    iconSpan.className = 'notify-icon';
    iconSpan.textContent = icon;

    const textSpan = document.createElement('span');
    textSpan.className = 'notify-text';
    textSpan.textContent = cleanText;

    item.appendChild(iconSpan);
    item.appendChild(textSpan);

    el.notifyStack.appendChild(item);
    setUiVisible(true);

    // Limit max visible
    while (el.notifyStack.children.length > NOTIFY_MAX) {
      el.notifyStack.removeChild(el.notifyStack.firstChild);
    }

    setTimeout(() => {
      item.classList.add('out');
      setTimeout(() => {
        if (item.parentNode) item.parentNode.removeChild(item);
        evaluateUiVisibility();
      }, 400);
    }, NOTIFY_DURATION);
  }

  /* ═══ Polizeiakte Vollbild-UI ═══ */
  function handlePolizeiakteOpen(akte) {
    const overlay = byId('akte-overlay');
    if (!overlay) return;

    // Werte befüllen
    safeText(byId('akte-server'), akte.serverName || 'Police Department');
    safeText(byId('akte-status'), (akte.status || 'unbescholten').toUpperCase());
    safeText(byId('akte-festnahmen'), String(akte.festnahmen || 0));
    safeText(byId('akte-haftzeit'), (akte.gesamtHaftzeit || 0) + ' Min');
    safeText(byId('akte-geldstrafe'), (akte.gesamtGeldstrafe || 0).toLocaleString('de-DE') + ' \u20AC');
    safeText(byId('akte-flucht'), String(akte.fluchtversuche || 0));
    safeText(byId('akte-letzte'), akte.letztesFestnahme || '\u2014');
    safeText(byId('akte-haft-mult'), '\u00D7' + (akte.haftzeitMultiplikator || 1).toFixed(1));
    safeText(byId('akte-geld-mult'), '\u00D7' + (akte.geldstrafeMultiplikator || 1).toFixed(1));

    // Nächste Stufe
    var naechsteRow = byId('akte-naechste-row');
    if (akte.naechsteStufeStatus) {
      safeText(byId('akte-naechste'), akte.naechsteStufeStatus + ' (ab ' + akte.naechsteStufeAb + ' Festnahmen)');
      if (naechsteRow) naechsteRow.style.display = '';
    } else {
      if (naechsteRow) naechsteRow.style.display = 'none';
    }

    // Status-Farbe
    var statusBar = byId('akte-status-bar');
    if (statusBar) statusBar.setAttribute('data-status', akte.status || 'unbescholten');

    overlay.classList.remove('hidden');
    // Vorherige Close-Operation abbrechen falls noch laufend
    if (akteAutoCloseTimer) { clearTimeout(akteAutoCloseTimer); akteAutoCloseTimer = null; }
    akteClosing = false;
    setUiVisible(true);

    // Auto-Close Timer auf JS-Seite: nach 5s automatisch schliessen (Sicherheitsnetz)
    if (akteAutoCloseTimer) clearTimeout(akteAutoCloseTimer);
    akteAutoCloseTimer = setTimeout(function() {
      var ov = byId('akte-overlay');
      if (ov && !ov.classList.contains('hidden')) {
        closePolizeiakte();
      }
    }, 5000);
  }

  var akteClosing = false;
  var akteAutoCloseTimer = null;

  function sendCloseRequest(attempt) {
    attempt = attempt || 1;
    fetch('https://mtj_arrest/closePolizeiakte', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    }).then(function() {
      akteClosing = false;
    }).catch(function() {
      if (attempt < 3) {
        setTimeout(function() { sendCloseRequest(attempt + 1); }, 200 * attempt);
      } else {
        akteClosing = false;
      }
    });
  }

  function closePolizeiakte() {
    var overlay = byId('akte-overlay');
    if (overlay) overlay.classList.add('hidden');
    evaluateUiVisibility();
    if (akteAutoCloseTimer) { clearTimeout(akteAutoCloseTimer); akteAutoCloseTimer = null; }
    if (!akteClosing) {
      akteClosing = true;
      sendCloseRequest(1);
    }
  }

  function forceHideAkte() {
    var overlay = byId('akte-overlay');
    if (overlay) overlay.classList.add('hidden');
    akteClosing = false;
    if (akteAutoCloseTimer) { clearTimeout(akteAutoCloseTimer); akteAutoCloseTimer = null; }
    evaluateUiVisibility();
  }

  // Close-Button & ESC & Klick ausserhalb
  document.addEventListener('click', function(e) {
    if (e.target && (e.target.id === 'akte-close' || e.target.id === 'akte-overlay')) closePolizeiakte();
  });
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      var overlay = byId('akte-overlay');
      if (overlay && !overlay.classList.contains('hidden')) {
        closePolizeiakte();
      }
    }
  });

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
      el && el.vorwarnung && !el.vorwarnung.classList.contains('hidden'),
      el && el.scenario && !el.scenario.classList.contains('hidden'),
      el && el.jail && !el.jail.classList.contains('hidden'),
      el && el.aLog && !el.aLog.classList.contains('hidden'),
      el && el.toast && !el.toast.classList.contains('hidden'),
      el && el.notifyStack && el.notifyStack.children.length > 0,
    ];
    const anyVisible = panels.some(Boolean);
    setUiVisible(anyVisible);
  }

  /* ═══ Gegenseitige Panel-Ausschliessung: nur 1 Panel gleichzeitig ═══ */
  function hideAllPanels() {
    setHidden(el.vorwarnung, true);
    if (el.vorwarnung) el.vorwarnung.classList.remove('pulse-ui');
    setHidden(el.scenario, true);
    if (el.scenario) el.scenario.classList.remove('pulse-ui');
    setHidden(el.jail, true);
    if (el.jail) el.jail.classList.remove('pulse-ui');
    setHidden(el.aLog, true);
  }

  /* ═══ Vorwarnung (grosse Warnung vor Polizei-Einsatz) ═══ */
  function handleVorwarnungToggle(d) {
    if (d.show) {
      hideAllPanels();
      safeText(el.vwTitle, d.title || 'POLIZEI-WARNUNG');
      if (el.vwText) {
        el.vwText.innerHTML = '';
        el.vwText.textContent = d.text || '';
      }
      if (d.countdown) {
        safeText(el.vwCountdown, d.countdown + 's');
      } else {
        safeText(el.vwCountdown, '');
      }
      setHidden(el.vorwarnung, false);
      if (el.vorwarnung) el.vorwarnung.classList.add('pulse-ui');
    } else {
      setHidden(el.vorwarnung, true);
      if (el.vorwarnung) el.vorwarnung.classList.remove('pulse-ui');
    }
    evaluateUiVisibility();
  }

  function handleVorwarnungCountdown(d) {
    const v = Number(d.value);
    safeText(el.vwCountdown, (isFinite(v) ? v : 0) + 's');
  }

  function handleScenarioToggle(d) {
    state.countdownLabel = (d.countdownLabel && String(d.countdownLabel)) || state.countdownLabel || 'Letzte Chance: ';
    if (d.show) {
      hideAllPanels();
      safeText(el.sTitle, d.title || 'Polizei-Einsatz');
      safeText(el.sHint, d.hint || '');
      state.scenarioTotal = Number(d.countdown) || 11;
      if (d.countdown) {
        safeText(el.sCountdown, `${state.countdownLabel}${Number(d.countdown)}s`);
      } else {
        safeText(el.sCountdown, '');
      }
      // Progress bar auf 100% setzen
      const bar = $('#scenario .scenario-progress-bar');
      if (bar) bar.style.width = '100%';
      setHidden(el.scenario, false);
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
    // Progress bar aktualisieren (100% → 0%)
    const bar = $('#scenario .scenario-progress-bar');
    if (bar && state.scenarioTotal > 0) {
      const pct = Math.max(0, Math.min(100, (v / state.scenarioTotal) * 100));
      bar.style.width = pct.toFixed(1) + '%';
    }
  }

  function handleArrestLog(d) {
    if (d.show) {
      hideAllPanels();
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
      hideAllPanels();
      state.jailTotal = Number(d.seconds) || 0;
      safeText(el.jTitle, d.title || 'Gefängnis');
      safeText(el.jSub, d.subtitle || '');
      safeText(el.jTimer, fmt(state.jailTotal));
      if (el.jBar) el.jBar.style.width = '0%';
      // Geldstrafe aktualisieren (tatsaechlicher Betrag vom Server)
      var fineEl = $('#jail .fine-amount');
      if (fineEl) {
        var fine = Number(d.fine) || 0;
        if (fine > 0) {
          safeText(fineEl, fine.toLocaleString('de-DE') + '\u00A0\u20AC');
        } else {
          safeText(fineEl, '\u2014');
        }
      }
      setHidden(el.jail, false);
      if (el.jail) el.jail.classList.add('pulse-ui');
    } else {
      setHidden(el.jail, true);
      if (el.jail) el.jail.classList.remove('pulse-ui');
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
      case 'vorwarnungToggle':
        handleVorwarnungToggle(d);
        break;
      case 'vorwarnungCountdown':
        handleVorwarnungCountdown(d);
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
      case 'uiToggle':
        if (typeof d.show !== 'undefined') setUiVisible(!!d.show);
        break;
      case 'notify':
        showNotify(d.text || '', d.type || 'info');
        break;
      case 'polizeiakteOpen':
        handlePolizeiakteOpen(d.akte || {});
        break;
      case 'polizeiakteClose':
        forceHideAkte();
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