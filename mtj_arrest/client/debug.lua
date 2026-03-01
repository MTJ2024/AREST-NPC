-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- mtj_arrest: Debug-Befehle (nur für Entwickler)

-- Startet das Festnahme-Szenario wie im echten Ablauf (setzt Wanted=2 für den Test)
RegisterCommand('mtj_test_start', function()
  print("[mtj_arrest][TEST] Setze Wanted=2 und triggere startScenario")
  SetPlayerWantedLevel(PlayerId(), 2, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  CreateThread(function()
    Wait(200) -- Kurze Pause damit GTA den Wanted-Level verarbeitet, bevor das Szenario startet
    TriggerEvent('mtj_arrest:startScenario')
  end)
end, false)

-- Zeigt das Arrest-Log-UI für 5 Sekunden an (Testanzeige)
RegisterCommand('mtj_test_arrestlog', function()
  print("[mtj_arrest][TEST] show arrest_log NUI for 5s")
  TriggerEvent('mtj_arrest:nui:arrest_log', true, {
    "TEST: Du wurdest festgenommen.",
    "Grund: Test",
    "Officer: Debug"
  })
  Citizen.SetTimeout(5000, function()
    TriggerEvent('mtj_arrest:nui:arrest_log', false)
    print("[mtj_arrest][TEST] hide arrest_log")
  end)
end, false)

-- Erzwingt Handschellen-Sequenz für 8 Sekunden (Test)
RegisterCommand('mtj_test_cuff', function()
  print("[mtj_arrest][TEST] Force cuff via mtj_arrest:forceSurrender")
  TriggerEvent('mtj_arrest:forceSurrender')
end, false)

-- Script-Zustand komplett zurücksetzen (Cops, Fahrzeuge, UI, Wanted)
RegisterCommand('mtj_refresh', function()
  print("[mtj_arrest][REFRESH] Script-Zustand wird zurückgesetzt...")
  TriggerEvent('mtj_arrest:refreshScript')
end, false)