print("[mtj_arrest][DEBUG] debug.lua loaded")
print("[mtj_arrest][DEBUG] Hinweis: playCuffSequence ist lokal in main.lua; externer Hook nicht möglich ohne Anpassung.")

-- Startet das Festnahme-Szenario wie im echten Ablauf
RegisterCommand('mtj_test_start', function()
  print("[mtj_arrest][TEST] Trigger mtj_arrest:startScenario (event)")
  TriggerEvent('mtj_arrest:startScenario')
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

-- Zeigt Handschellen-Visuals für 8 Sekunden (zum Testen)
RegisterCommand('mtj_test_cuff', function()
  print("[mtj_arrest][TEST] cuff visuals (local) for 8s")
  TriggerEvent('mtj_arrest:controls:cuffed', true, GetPlayerServerId(PlayerId()))
  Citizen.SetTimeout(8000, function()
    TriggerEvent('mtj_arrest:controls:cuffed', false, GetPlayerServerId(PlayerId()))
    print("[mtj_arrest][TEST] uncuffed")
  end)
end, false)