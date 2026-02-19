-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  github.com/MTJ2024/AREST-NPC                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- mtj_arrest: Wanted-Level-Überwachung
-- Überwacht den Wanted-Level und startet das Szenario automatisch.

local Config = Config or {}
Config.RequiredWantedLevel = Config.RequiredWantedLevel or 1

local scenarioTriggered = false

-- Listen for scenario end to allow re-triggering
AddEventHandler('mtj_arrest:endScenario', function()
  scenarioTriggered = false
end)

AddEventHandler('playerSpawned', function()
  scenarioTriggered = false
end)

CreateThread(function()
  while true do
    Wait(2000)
    local wanted = GetPlayerWantedLevel(PlayerId())
    if wanted >= Config.RequiredWantedLevel then
      if not scenarioTriggered then
        scenarioTriggered = true
        TriggerEvent('mtj_arrest:startScenario')
      end
    else
      scenarioTriggered = false
    end
  end
end)
