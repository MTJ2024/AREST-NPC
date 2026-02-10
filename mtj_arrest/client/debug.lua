print("[mtj_arrest][DEBUG] debug.lua loaded")
print("[mtj_arrest][DEBUG] Hinweis: playCuffSequence ist lokal in main.lua; externer Hook nicht möglich ohne Anpassung.")

-- === TEST COMMANDS FOR WANTED LEVEL ===

-- Quick start - Set wanted and trigger scenario
RegisterCommand('mtj_start', function()
  print("[mtj_arrest][TEST] Quick start: Setting wanted level 2 and triggering scenario")
  SetPlayerWantedLevel(PlayerId(), 2, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  Wait(500)
  TriggerEvent('mtj_arrest:startScenario')
  print("[mtj_arrest][TEST] Scenario should start in a moment...")
end, false)

-- Set wanted level manually (for testing)
RegisterCommand('mtj_wanted', function(source, args)
  local level = tonumber(args[1]) or 3
  level = math.max(0, math.min(5, level)) -- Clamp between 0-5
  SetPlayerWantedLevel(PlayerId(), level, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  print(("[mtj_arrest][TEST] Set wanted level to %d"):format(level))
end, false)

-- Quick wanted level presets
RegisterCommand('mtj_wanted1', function() 
  SetPlayerWantedLevel(PlayerId(), 1, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  print("[mtj_arrest][TEST] Set wanted level to 1")
end, false)

RegisterCommand('mtj_wanted2', function() 
  SetPlayerWantedLevel(PlayerId(), 2, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  print("[mtj_arrest][TEST] Set wanted level to 2")
end, false)

RegisterCommand('mtj_wanted3', function() 
  SetPlayerWantedLevel(PlayerId(), 3, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  print("[mtj_arrest][TEST] Set wanted level to 3")
end, false)

RegisterCommand('mtj_wanted4', function() 
  SetPlayerWantedLevel(PlayerId(), 4, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  print("[mtj_arrest][TEST] Set wanted level to 4 (helicopter)")
end, false)

RegisterCommand('mtj_wanted5', function() 
  SetPlayerWantedLevel(PlayerId(), 5, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  print("[mtj_arrest][TEST] Set wanted level to 5 (max)")
end, false)

RegisterCommand('mtj_clearwanted', function() 
  SetPlayerWantedLevel(PlayerId(), 0, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  print("[mtj_arrest][TEST] Cleared wanted level")
end, false)

-- Check current wanted level
RegisterCommand('mtj_checkwanted', function()
  local wanted = GetPlayerWantedLevel(PlayerId())
  print(("[mtj_arrest][TEST] Current wanted level: %d"):format(wanted))
end, false)

-- === EXISTING TEST COMMANDS ===

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