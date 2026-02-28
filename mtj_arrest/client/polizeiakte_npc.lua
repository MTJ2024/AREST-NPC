-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- === POLIZEIAKTE NPC ===
-- Spawnt einen NPC an der konfigurierten Position, zeigt einen Karten-Blip,
-- und erlaubt dem Spieler via [E] seine Polizeiakte einzusehen.

local npcPed    = nil
local npcBlip   = nil
local akteLoading = false

-- NPC und Blip spawnen
local function spawnPolizeiakteNPC()
  local cfg = Config.PolizeiakteNPC
  if not cfg or not cfg.Aktiviert then return end

  local model = GetHashKey(cfg.Model)
  RequestModel(model)
  local timeout = GetGameTimer() + 5000
  while not HasModelLoaded(model) and GetGameTimer() < timeout do
    Wait(100)
  end
  if not HasModelLoaded(model) then
    print("[mtj_arrest][PolizeiakteNPC] Modell konnte nicht geladen werden: " .. tostring(cfg.Model))
    return
  end

  local pos = cfg.Position
  npcPed = CreatePed(4, model, pos.x, pos.y, pos.z, cfg.Heading or 0.0, false, true)
  SetEntityAsMissionEntity(npcPed, true, true)
  FreezeEntityPosition(npcPed, true)
  SetEntityInvincible(npcPed, true)
  SetBlockingOfNonTemporaryEvents(npcPed, true)
  TaskStartScenarioInPlace(npcPed, cfg.Scenario or "WORLD_HUMAN_CLIPBOARD", 0, true)
  SetModelAsNoLongerNeeded(model)

  -- Karten-Blip
  local blipCfg = cfg.Blip
  if blipCfg then
    npcBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(npcBlip, blipCfg.Sprite or 60)
    SetBlipScale(npcBlip, blipCfg.Scale or 0.85)
    SetBlipColour(npcBlip, blipCfg.Farbe or 3)
    SetBlipAsShortRange(npcBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(blipCfg.Name or "Polizeiakte")
    EndTextCommandSetBlipName(npcBlip)
  end
end

-- Empfängt die vollständige Akte vom Server und zeigt sie an
RegisterNetEvent('mtj_arrest:clientFullAkte')
AddEventHandler('mtj_arrest:clientFullAkte', function(akte)
  akteLoading = false
  local lines
  if not akte then
    lines = { "Keine Einträge in der Polizeiakte gefunden." }
  else
    local serverName = akte.serverName or "GreenZone420 PD"
    lines = {
      "══ POLIZEIAKTE: " .. (GetPlayerName(PlayerId()) or "Unbekannt") .. " ══",
      "Status: "                    .. tostring(akte.status             or "unbescholten"),
      "Festnahmen: "                .. tostring(akte.festnahmen         or 0),
      "Fluchtversuche: "            .. tostring(akte.fluchtversuche     or 0),
      "Gesamt-Haftzeit: "           .. tostring(akte.gesamtHaftzeit     or 0) .. " Min.",
      "Gesamt-Geldstrafe: "         .. tostring(akte.gesamtGeldstrafe   or 0) .. " €",
      "Letzte Festnahme: "          .. (akte.letztesFestnahme ~= "" and akte.letztesFestnahme or "—"),
      "Haftzeit-Multiplikator: x"   .. tostring(akte.haftzeitMultiplikator   or 1.0),
      "Geldstrafe-Multiplikator: x" .. tostring(akte.geldstrafeMultiplikator or 1.0),
    }
    if akte.naechsteStufeStatus then
      table.insert(lines, "Nächste Stufe: " .. akte.naechsteStufeStatus
        .. " ab " .. tostring(akte.naechsteStufeAb) .. " Festnahmen")
    end
    table.insert(lines, "── " .. serverName .. " ──")
  end

  TriggerEvent('mtj_arrest:nui:arrest_log', true, lines)
  Wait(8000)
  TriggerEvent('mtj_arrest:nui:arrest_log', false)
end)

-- Interaktions-Thread: Nähe erkennen, Hilfetext anzeigen, [E] abfangen
CreateThread(function()
  local cfg = Config.PolizeiakteNPC
  if not cfg or not cfg.Aktiviert then return end

  spawnPolizeiakteNPC()

  local radius         = cfg.Interaktionsradius or 5.0
  local interaktText   = cfg.InteraktionsText or "[E] Polizeiakte einsehen"
  local interactionKey = (Config.Keys and Config.Keys.Surrender) or 38

  while true do
    local ppos   = GetEntityCoords(PlayerPedId())
    local npcpos = cfg.Position
    local dist   = #(ppos - npcpos)

    if dist <= radius then
      -- Hilfetext oben links anzeigen
      BeginTextCommandDisplayHelp("STRING")
      AddTextComponentSubstringPlayerName(interaktText)
      EndTextCommandDisplayHelp(0, false, true, -1)

      -- [E] gedrückt → Akte laden (Doppel-Request verhindern)
      if IsControlJustPressed(0, interactionKey) and not akteLoading then
        akteLoading = true
        TriggerServerEvent('mtj_arrest:requestFullAkte')
      end
      Wait(0)
    else
      Wait(500)
    end
  end
end)

-- Aufräumen wenn Resource stoppt
AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  if npcPed and DoesEntityExist(npcPed) then
    DeleteEntity(npcPed)
  end
  if npcBlip and DoesBlipExist(npcBlip) then
    RemoveBlip(npcBlip)
  end
end)
