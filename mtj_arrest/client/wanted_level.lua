-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  github.com/MTJ2024/AREST-NPC                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- mtj_arrest: Wanted-Level-Ueberwachung
-- Ueberwacht den Wanted-Level und startet das Szenario automatisch.
-- Re-triggert das Szenario wenn es haengt (Stuck-Erkennung).

local Config = Config or {}
Config.RequiredWantedLevel = Config.RequiredWantedLevel or 1

local scenarioTriggered = false
local lastTriggerTime = 0
local STALE_TIMEOUT = 45000 -- 45 Sekunden: Wenn Szenario so lange "aktiv" war ohne Ergebnis, Reset

-- Listen for scenario end to allow re-triggering
AddEventHandler('mtj_arrest:endScenario', function()
  scenarioTriggered = false
end)

AddEventHandler('playerSpawned', function()
  scenarioTriggered = false
  lastTriggerTime = 0
end)

CreateThread(function()
  while true do
    Wait(2000)
    local wanted = GetPlayerWantedLevel(PlayerId())
    if wanted >= Config.RequiredWantedLevel then
      if not scenarioTriggered then
        -- Normaler Start: Szenario triggern
        scenarioTriggered = true
        lastTriggerTime = GetGameTimer()
        TriggerEvent('mtj_arrest:startScenario')
      else
        -- Stuck-Erkennung: Wenn Szenario laenger als STALE_TIMEOUT aktiv
        -- und Wanted immer noch > 0, Reset + Neustart
        local elapsed = GetGameTimer() - lastTriggerTime
        if elapsed > STALE_TIMEOUT then
          scenarioTriggered = false
          lastTriggerTime = 0
          -- endScenario zum Aufraeumen, dann Neustart im naechsten Tick
          TriggerEvent('mtj_arrest:endScenario')
        end
      end
    else
      -- Wanted = 0: Reset
      if scenarioTriggered then
        scenarioTriggered = false
        lastTriggerTime = 0
      end
    end
  end
end)
