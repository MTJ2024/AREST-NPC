-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- mtj_arrest: Wanted-Level-Ueberwachung
-- Ueberwacht den Wanted-Level und startet das Szenario automatisch.
-- Re-triggert das Szenario wenn es haengt (Stuck-Erkennung).

local Config = Config or {}
Config.RequiredWantedLevel = Config.RequiredWantedLevel or 2

local scenarioTriggered = false
local lastTriggerTime = 0
local SCENARIO_STALE_TIMEOUT_MS = 600000 -- 10 Minuten: Szenario laeuft so lange wie Wanted aktiv ist
local consecutiveZeroChecks = 0  -- Zaehlt wie oft hintereinander Wanted=0 gelesen wurde
local ZERO_CHECKS_REQUIRED = 3  -- 3x hintereinander Wanted=0 (= 6 Sekunden) bevor Reset

-- Listen for scenario end to allow re-triggering
AddEventHandler('mtj_arrest:endScenario', function()
  scenarioTriggered = false
end)

AddEventHandler('playerSpawned', function()
  scenarioTriggered = false
  lastTriggerTime = 0
  consecutiveZeroChecks = 0
end)

-- Robuste Wanted-Pruefung: Liest GTA-Wanted UND main.lua's lastKnownWanted
-- GTA setzt Wanted manchmal fuer 1-2 Frames auf 0 (Race Condition)
local function getWantedRobust()
  local w = GetPlayerWantedLevel(PlayerId())
  if w > 0 then return w end
  -- Fallback: main.lua haelt lastKnownWanted als Backup
  local mainWanted = (GetMainLuaLastKnownWanted and GetMainLuaLastKnownWanted()) or 0
  if mainWanted > 0 then return mainWanted end
  return 0
end

CreateThread(function()
  while true do
    Wait(2000)
    -- Wanted-Sperre nach Tod pruefen (5 Sekunden nach Tod kein Re-Trigger)
    -- GetWantedDeathLockUntil ist in main.lua definiert, defensive Pruefung fuer Ladereihenfolge
    local deathLock = (GetWantedDeathLockUntil and GetWantedDeathLockUntil()) or 0
    local deathLockActive = deathLock > 0 and GetGameTimer() < deathLock
    if deathLockActive then
      consecutiveZeroChecks = 0
      scenarioTriggered = false
    else
      local wanted = getWantedRobust()
      if wanted >= Config.RequiredWantedLevel then
        consecutiveZeroChecks = 0  -- Wanted aktiv → Reset Zero-Counter
        if not scenarioTriggered then
          -- Normaler Start: Szenario triggern
          scenarioTriggered = true
          lastTriggerTime = GetGameTimer()
          TriggerEvent('mtj_arrest:startScenario')
        else
          -- Stuck-Erkennung: Wenn Szenario laenger als STALE_TIMEOUT aktiv
          -- und Wanted immer noch > 0, Reset + Neustart
          local elapsed = GetGameTimer() - lastTriggerTime
          if elapsed > SCENARIO_STALE_TIMEOUT_MS then
            scenarioTriggered = false
            lastTriggerTime = 0
            -- endScenario zum Aufraeumen, dann Neustart im naechsten Tick
            TriggerEvent('mtj_arrest:endScenario')
          end
        end
      else
        -- Wanted = 0: Nur resetten wenn MEHRFACH hintereinander 0 gelesen
        -- Verhindert False-Positives durch GTA Race Conditions
        if scenarioTriggered then
          consecutiveZeroChecks = consecutiveZeroChecks + 1
          if consecutiveZeroChecks >= ZERO_CHECKS_REQUIRED then
            scenarioTriggered = false
            lastTriggerTime = 0
            consecutiveZeroChecks = 0
          end
        end
      end
    end
  end
end)
