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
    };

    // Initial hide to ensure clean state
    setHidden(el.scenario, true);
    setHidden(el.toast, true);
    setHidden(el.jail, true);
    setHidden(el.aLog, true);

    // Ensure UI is hidden globally until something is shown
    setUiVisible(false);

    state.initialized = true;
  }

  function fmt(sec) {
    sec = Number(sec) || 0;
    if (sec < 0) sec = 0;
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }

  function setUiVisible(show) {
    try {
      if (show) {
        document.body.classList.add('ui-on');
      } else {
        document.body.classList.remove('ui-on');
      }
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

  /* ═══ Gegenseitige Panel-Ausschliessung: nur 1 Panel gleichzeitig ═══ */
  function hideAllPanels() {
    setHidden(el.scenario, true);
    if (el.scenario) el.scenario.classList.remove('pulse-ui');
    setHidden(el.jail, true);
    if (el.jail) el.jail.classList.remove('pulse-ui');
    setHidden(el.aLog, true);
    if (el.aLog) el.aLog.classList.remove('pulse-ui');
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
      if (el.aLog) el.aLog.classList.add('pulse-ui');
    } else {
      setHidden(el.aLog, true);
      if (el.aLog) el.aLog.classList.remove('pulse-ui');
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

  function onMessage(e) {
    const d = e.data || {};
    switch (d.action) {
      case 'scenarioToggle':
        handleScenarioToggle(d);
        break;
      case 'scenarioCountdown':
        handleScenarioCountdown(d);
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
})();