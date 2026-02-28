-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- NUI Focus-Handler: Szenario/Arrest-Log dürfen NIE den Fokus blockieren (E soll funktionieren)

local function setFocusSafe()
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
end

RegisterNetEvent('mtj_arrest:nui:scenario')
AddEventHandler('mtj_arrest:nui:scenario', function(show, hint, countdown)
  SendNUIMessage({
    action = "scenarioToggle",
    show = show or false,
    hint = hint or "",
    countdown = countdown,
    title = (Config and Config.UI and Config.UI.ScenarioTitle) or "Polizei-Einsatz",
    countdownLabel = (Config and Config.UI and Config.UI.CountdownLabel) or "Letzte Chance: "
  })
  setFocusSafe()
end)

RegisterNetEvent('mtj_arrest:nui:scenario_tick')
AddEventHandler('mtj_arrest:nui:scenario_tick', function(value)
  SendNUIMessage({ action = "scenarioCountdown", value = value })
end)

RegisterNetEvent('mtj_arrest:nui:arrest_log')
AddEventHandler('mtj_arrest:nui:arrest_log', function(show, lines)
  SendNUIMessage({
    action = "arrestLog",
    show = show or false,
    lines = lines or {}
  })
  setFocusSafe()
end)

RegisterNetEvent('mtj_arrest:nui:jail')
AddEventHandler('mtj_arrest:nui:jail', function(show, seconds, title, sub, fine)
  SendNUIMessage({
    action = "jailToggle",
    show = show or false,
    seconds = seconds or 0,
    title = title or "Gefängnis",
    subtitle = sub or "",
    fine = fine or 0
  })
  setFocusSafe()
end)

RegisterNetEvent('mtj_arrest:nui:jail_tick')
AddEventHandler('mtj_arrest:nui:jail_tick', function(seconds)
  SendNUIMessage({ action = "jailTick", seconds = seconds or 0 })
end)

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  setFocusSafe()
end)