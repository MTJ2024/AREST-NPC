/**
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
 * ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
 * ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */
(() => {
  const REFRESH_BTN_LABEL = '\uD83D\uDD04 Aktualisieren';
  const REFRESH_BTN_LOADING = '\u23F3 ...';
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
      voz: byId('vorozahlung'),
      vozOfficer: byId('voz-officer'),
      vozDelikt: byId('voz-delikt'),
      vozBetrag: byId('voz-betrag'),
      vozBar: byId('voz-progress-bar'),
      vozStatus: byId('voz-status'),
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
    setHidden(el.scenario, true);
    setHidden(el.toast, true);
    setHidden(el.jail, true);
    setHidden(el.aLog, true);
    setHidden(el.voz, true);

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

  function enqueueToast(text) { /* deaktiviert */ }
  function showNextToast() { /* deaktiviert */ }

  /* ═══ Custom Notification (links mittig) — deaktiviert ═══ */
  function showNotify(text, type) { /* deaktiviert: nur Einsatz- und Knast-Panel */ }

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
    document.body.style.cursor = 'default'; // NUI-Cursor wiederherstellen
    // Vorherige Close-Operation abbrechen falls noch laufend
    if (akteAutoCloseTimer) { clearTimeout(akteAutoCloseTimer); akteAutoCloseTimer = null; }
    akteClosing = false;
    setUiVisible(true);
    // Heartbeat starten: sendet alle 800ms 'akteAlive' an Lua solange Overlay sichtbar ist
    startAkteHeartbeat();

    // Auto-Close Timer auf JS-Seite: nach 60s automatisch schliessen (Sicherheitsnetz)
    // clearTimeout hier redundant aber sicher gegen eventuelle Race-Conditions
    if (akteAutoCloseTimer) { clearTimeout(akteAutoCloseTimer); akteAutoCloseTimer = null; }
    akteAutoCloseTimer = setTimeout(function() {
      var ov = byId('akte-overlay');
      if (ov && !ov.classList.contains('hidden')) {
        closePolizeiakte();
      }
    }, 60000);

    // Refresh-Button zuruecksetzen falls noch im Lade-Zustand
    var refreshBtn = byId('akte-refresh');
    if (refreshBtn) {
      refreshBtn.classList.remove('loading');
      refreshBtn.textContent = REFRESH_BTN_LABEL;
    }

    // Reduce-Button: sichtbar wenn Feature aktiv und Festnahmen > Mindest
    var reduceBtn = byId('akte-reduce');
    var stufenWrap = byId('akte-stufen-wrap');
    var stufenList = byId('akte-stufen-list');
    if (reduceBtn) {
      var canReduce = !!akte.kriminalLevelSenkenAktiviert &&
                      (akte.festnahmen || 0) > (akte.mindestFestnahmen || 0);
      reduceBtn.style.display = canReduce ? 'inline-flex' : 'none';
      reduceBtn.disabled = false;
      reduceBtn.classList.remove('loading');
      var currentCost = akte.aktuelleReduktionsKosten || 0;
      var cost = currentCost.toLocaleString('de-DE');
      reduceBtn.textContent = '\u2B07 Kriminallevel senken (' + cost + '\u00A0\u20AC)';
    }

    // Stufentabelle rendern
    if (stufenWrap && stufenList) {
      var stufen = akte.reduktionsStufen;
      if (akte.kriminalLevelSenkenAktiviert && stufen && stufen.length > 0) {
        stufenList.innerHTML = '';
        var currentFestnahmen = akte.festnahmen || 0;
        stufen.forEach(function(s, i) {
          var isActive = currentFestnahmen >= s.AbFestnahmen &&
            (i === stufen.length - 1 || currentFestnahmen < stufen[i + 1].AbFestnahmen);
          var row = document.createElement('div');
          row.className = 'akte-stufe-row' + (isActive ? ' active' : '');
          var badge = isActive ? '\u25B6 ' : '';
          var bis = (i < stufen.length - 1)
            ? ('ab ' + s.AbFestnahmen + ' bis ' + (stufen[i + 1].AbFestnahmen - 1))
            : ('ab ' + s.AbFestnahmen + '+');
          row.innerHTML = badge + '<span class="akte-stufe-badge">' + bis + ' Festnahmen:</span> '
            + (s.Kosten || 0).toLocaleString('de-DE') + '\u00A0\u20AC';
          stufenList.appendChild(row);
        });
        stufenWrap.classList.remove('hidden');
      } else {
        stufenWrap.classList.add('hidden');
      }
    }
  }

  var akteClosing = false;
  var akteAutoCloseTimer = null;
  // Heartbeat: sendet alle 800ms 'akteAlive' an Lua solange die Akte sichtbar ist.
  // Lua-seitiger Safety-Net schliesst nach 2s ohne Heartbeat (HEARTBEAT_CLOSE_DELAY).
  // Dies ist der primaere Fallback-Mechanismus wenn closePolizeiakte-Fetch fehlschlaegt.
  var akteHeartbeatInterval = null;

  function startAkteHeartbeat() {
    stopAkteHeartbeat();
    akteHeartbeatInterval = setInterval(function() {
      var ov = byId('akte-overlay');
      if (!ov || ov.classList.contains('hidden')) {
        // Overlay wurde inzwischen versteckt — Heartbeat beenden (Lua erkennt Ausfall)
        stopAkteHeartbeat();
        return;
      }
      fetch('https://mtj_arrest/akteAlive', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      }).catch(function() {});  // Fire-and-forget, kein Fehler-Handling noetig
    }, 800);
  }

  function stopAkteHeartbeat() {
    if (akteHeartbeatInterval) {
      clearInterval(akteHeartbeatInterval);
      akteHeartbeatInterval = null;
    }
  }

  function sendCloseRequest() {
    // Kein AbortController: lass den Fetch natuerlich abschliessen.
    // Lua antwortet mit cb('ok') sofort (vor forceCloseAkte), daher normaler Fall < 100ms.
    // Parallel laeuft der Heartbeat-Timeout (2s) als Fallback falls dieser Fetch fehlschlaegt.
    fetch('https://mtj_arrest/closePolizeiakte', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    }).then(function() {
      akteClosing = false;
    }).catch(function() {
      akteClosing = false;
    });
  }

  function closePolizeiakte() {
    var overlay = byId('akte-overlay');
    if (overlay) overlay.classList.add('hidden');
    document.body.style.cursor = 'none'; // NUI-Cursor sofort ausblenden (kein Warten auf Lua-Callback)
    stopAkteHeartbeat();   // Heartbeat sofort stoppen: Lua erkennt Ausfall und schliesst
    evaluateUiVisibility();
    if (akteAutoCloseTimer) { clearTimeout(akteAutoCloseTimer); akteAutoCloseTimer = null; }
    if (!akteClosing) {
      akteClosing = true;
      sendCloseRequest();
    }
  }

  function forceHideAkte() {
    var overlay = byId('akte-overlay');
    if (overlay) overlay.classList.add('hidden');
    document.body.style.cursor = 'none'; // NUI-Cursor sofort ausblenden
    stopAkteHeartbeat();
    akteClosing = false;
    if (akteAutoCloseTimer) { clearTimeout(akteAutoCloseTimer); akteAutoCloseTimer = null; }
    evaluateUiVisibility();
  }

  // Close-Button & Refresh-Button & Reduce-Button & ESC & Klick ausserhalb
  document.addEventListener('click', function(e) {
    if (e.target && (e.target.id === 'akte-close' || e.target.id === 'akte-overlay')) closePolizeiakte();
    if (e.target && e.target.id === 'akte-refresh') {
      var btn = e.target;
      btn.classList.add('loading');
      btn.textContent = REFRESH_BTN_LOADING;
      fetch('https://mtj_arrest/refreshPolizeiakte', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      }).catch(function() {
        btn.classList.remove('loading');
        btn.textContent = REFRESH_BTN_LABEL;
      });
    }
    if (e.target && e.target.id === 'akte-reduce') {
      var reduceBtn = e.target;
      if (reduceBtn.disabled) return;
      reduceBtn.disabled = true;
      reduceBtn.classList.add('loading');
      fetch('https://mtj_arrest/reduceKriminalLevel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      }).catch(function() {
        reduceBtn.disabled = false;
        reduceBtn.classList.remove('loading');
      });
    }
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
      el && el.scenario && !el.scenario.classList.contains('hidden'),
      el && el.jail && !el.jail.classList.contains('hidden'),
      el && el.voz && !el.voz.classList.contains('hidden'),
    ];
    const anyVisible = panels.some(Boolean);
    setUiVisible(anyVisible);
  }

  /* ═══ Gegenseitige Panel-Ausschliessung: nur 1 Panel gleichzeitig ═══ */
  function hideAllPanels() {
    setHidden(el.scenario, true);
    if (el.scenario) el.scenario.classList.remove('pulse-ui');
    setHidden(el.jail, true);
    if (el.jail) el.jail.classList.remove('pulse-ui');
    setHidden(el.aLog, true);
    setHidden(el.voz, true);
    if (el.voz) el.voz.classList.remove('show-ui');
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
    // Festnahmeprotokoll deaktiviert: nur Einsatz- und Knast-Panel werden angezeigt
    setHidden(el.aLog, true);
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

  // Dauer (ms) die das Abschluss-Panel nach der Zahlung sichtbar bleibt.
  // Muss mit dem Wait() in playFineSequence (main.lua) synchron sein.
  var VOZ_DONE_DISPLAY_MS = 2800;

  var vozAutoHideTimer = null;
  function handleFineToggle(d) {
    if (vozAutoHideTimer) { clearTimeout(vozAutoHideTimer); vozAutoHideTimer = null; }
    if (d.show) {
      hideAllPanels();
      safeText(el.vozOfficer, d.officer || 'Polizeibeamter');
      safeText(el.vozDelikt, d.delikt || 'Ordnungswidrigkeit');
      var fineAmount = Number(d.fine) || 0;
      safeText(el.vozBetrag, fineAmount > 0 ? fineAmount.toLocaleString('de-DE') + '\u00A0\u20AC' : '\u2014');
      if (el.vozBar) el.vozBar.style.width = '0%';
      if (el.vozStatus) {
        el.vozStatus.classList.remove('done');
        safeText(el.vozStatus, d.statusText || 'Zahlung wird verarbeitet\u2026');
      }
      setHidden(el.voz, false);
      if (el.voz) {
        el.voz.classList.remove('show-ui');
        void el.voz.offsetWidth; // DOM-Reflow: CSS-Animation bei Wiederverwendung zuruecksetzen
        el.voz.classList.add('show-ui');
      }
      // Kurze Verzoegerung damit CSS transition nach dem initialen width=0% greift
      setTimeout(function() {
        if (el.vozBar) el.vozBar.style.width = '100%';
      }, 120);
      evaluateUiVisibility();
    } else {
      // Abschluss-Status kurz zeigen, dann ausblenden
      if (d.done && el.vozStatus) {
        el.vozStatus.classList.add('done');
        safeText(el.vozStatus, d.doneText || '\u2705 Strafe bezahlt \u2014 Auf freiem Fu\u00df!');
        if (el.vozBar) el.vozBar.style.width = '100%';
        vozAutoHideTimer = setTimeout(function() {
          setHidden(el.voz, true);
          if (el.voz) el.voz.classList.remove('show-ui');
          evaluateUiVisibility();
          vozAutoHideTimer = null;
        }, VOZ_DONE_DISPLAY_MS);
      } else {
        setHidden(el.voz, true);
        if (el.voz) el.voz.classList.remove('show-ui');
        evaluateUiVisibility();
      }
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
      case 'fineToggle':
        handleFineToggle(d);
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
      case 'kriminalLevelFail':
        var btn = byId('akte-reduce');
        if (btn) { btn.disabled = false; btn.classList.remove('loading'); }
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
