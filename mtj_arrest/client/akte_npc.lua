-- mtj_arrest: Akte-NPC – stationärer Polizist bei der Wache
-- Drücke [E] in der Nähe, um deine Festnahme-Akte einzusehen.

local aktePed          = nil
local akteBlip         = nil   -- Minimap-Blip für den Akte-NPC
local akteOpen         = false
local isScenarioActive = false  -- gesetzt, wenn Szenario läuft
local isPlayerInJail   = false  -- gesetzt, wenn Spieler im Knast ist

-- === Szenario-Zustand verfolgen (lokale Events aus main.lua) ===

AddEventHandler('mtj_arrest:startScenario', function()
  isScenarioActive = true
  if akteOpen then
    akteOpen = false
    TriggerEvent('mtj_arrest:nui:akte', false)
  end
end)

AddEventHandler('mtj_arrest:endScenario', function()
  isScenarioActive = false
end)

RegisterNetEvent('mtj_arrest:clientBeginJail')
AddEventHandler('mtj_arrest:clientBeginJail', function()
  isPlayerInJail = true
  if akteOpen then
    akteOpen = false
    TriggerEvent('mtj_arrest:nui:akte', false)
  end
end)

RegisterNetEvent('mtj_arrest:clientRelease')
AddEventHandler('mtj_arrest:clientRelease', function()
  isPlayerInJail   = false
  isScenarioActive = false
end)

AddEventHandler('playerSpawned', function()
  isScenarioActive = false
  isPlayerInJail   = false
  if akteOpen then
    akteOpen = false
    TriggerEvent('mtj_arrest:nui:akte', false)
  end
  -- NPC nach dem Laden der Welt spawnen
  CreateThread(function()
    Wait(4000)
    spawnAkteNPC()
  end)
end)

-- === NPC spawnen ===

function spawnAkteNPC()
  local cfg = Config and Config.AkteNPC
  if not cfg or not cfg.Position then return end

  -- Bereits vorhanden?
  if aktePed and DoesEntityExist(aktePed) then return end

  local model = GetHashKey(cfg.Model or "s_f_y_cop_01")
  RequestModel(model)
  local t = GetGameTimer() + 5000
  while not HasModelLoaded(model) do
    if GetGameTimer() > t then return end
    Wait(50)
  end

  local pos = cfg.Position
  aktePed = CreatePed(4, model, pos.x, pos.y, pos.z, cfg.Heading or 0.0, false, true)
  if DoesEntityExist(aktePed) then
    SetEntityAsMissionEntity(aktePed, true, true)
    FreezeEntityPosition(aktePed, true)
    SetEntityInvincible(aktePed, true)
    SetPedCanRagdoll(aktePed, false)
    SetBlockingOfNonTemporaryEvents(aktePed, true)
    RemoveAllPedWeapons(aktePed, true)
    -- Neutral halten: nicht als Polizist erkennbar (kein COP-RelationshipGroup)
    SetPedRelationshipGroupHash(aktePed, GetHashKey("CIVMALE"))
    TaskStartScenarioInPlace(aktePed, "WORLD_HUMAN_STAND_GUARD", 0, true)
  end
  SetModelAsNoLongerNeeded(model)

  -- Minimap-Blip am NPC erstellen
  if akteBlip and DoesBlipExist(akteBlip) then RemoveBlip(akteBlip) end
  if DoesEntityExist(aktePed) then
    akteBlip = AddBlipForEntity(aktePed)
    SetBlipSprite(akteBlip, cfg.BlipSprite or 60)
    SetBlipColour(akteBlip, cfg.BlipColor  or 3)
    SetBlipScale(akteBlip,  cfg.BlipScale  or 0.8)
    SetBlipAsShortRange(akteBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(cfg.BlipName or "Ermittlungsakte")
    EndTextCommandSetBlipName(akteBlip)
  end
end

-- Beim Resource-Start (Spieler schon in der Welt)
AddEventHandler('onClientResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  CreateThread(function()
    Wait(2000)
    spawnAkteNPC()
  end)
end)

-- === Interaktions-Loop ===

CreateThread(function()
  while true do
    -- NPC ggf. neu spawnen wenn gelöscht
    if not (aktePed and DoesEntityExist(aktePed)) then
      aktePed = nil
      spawnAkteNPC()
      Wait(2000)
    end

    if aktePed and DoesEntityExist(aktePed) and not isScenarioActive and not isPlayerInJail then
      local ppos  = GetEntityCoords(PlayerPedId())
      local npos  = GetEntityCoords(aktePed)
      local dist  = #(ppos - npos)
      local radius = (Config and Config.AkteNPC and Config.AkteNPC.InteractRadius) or 3.0

      if dist <= radius then
        -- Hilfstext anzeigen
        BeginTextCommandDisplayHelp("STRING")
        if akteOpen then
          AddTextComponentSubstringPlayerName("~g~[E]~s~ Akte schließen")
        else
          AddTextComponentSubstringPlayerName("~g~[E]~s~ Ermittlungsakte einsehen")
        end
        EndTextCommandDisplayHelp(0, false, true, -1)

        if IsControlJustReleased(0, 38) then  -- E
          if akteOpen then
            akteOpen = false
            TriggerEvent('mtj_arrest:nui:akte', false)
          else
            TriggerServerEvent('mtj_arrest:sv:getAkte')
          end
        end
        Wait(0)
      else
        -- Zu weit weg: Akte schließen
        if akteOpen then
          akteOpen = false
          TriggerEvent('mtj_arrest:nui:akte', false)
        end
        Wait(200)
      end
    else
      Wait(500)
    end
  end
end)

-- === 3D-Bodenmarker am NPC ===

CreateThread(function()
  -- Konfigurationswerte einmalig lesen
  local mcfg   = Config.AkteNPC
  local r      = (mcfg.MarkerColor and mcfg.MarkerColor.r) or 40
  local g      = (mcfg.MarkerColor and mcfg.MarkerColor.g) or 120
  local b      = (mcfg.MarkerColor and mcfg.MarkerColor.b) or 255
  local a      = (mcfg.MarkerColor and mcfg.MarkerColor.a) or 120
  local radius = mcfg.MarkerRadius or 1.5
  local renderDist = 40.0

  while true do
    if aktePed and DoesEntityExist(aktePed) then
      local ppos = GetEntityCoords(PlayerPedId())
      local npos = GetEntityCoords(aktePed)

      if #(ppos - npos) <= renderDist then
        -- Marker-Typ 1 = Zylinder auf dem Boden
        DrawMarker(1,
          npos.x, npos.y, npos.z - 0.05,
          0.0, 0.0, 0.0,
          0.0, 0.0, 0.0,
          radius, radius, 0.8,
          r, g, b, a,
          false, false, 2, false, nil, nil, false)
        Wait(0)
      else
        Wait(500)
      end
    else
      Wait(1000)
    end
  end
end)

-- === Akte-Daten vom Server empfangen ===

RegisterNetEvent('mtj_arrest:cl:showAkte')
AddEventHandler('mtj_arrest:cl:showAkte', function(data)
  akteOpen = true
  TriggerEvent('mtj_arrest:nui:akte', true, data)
end)

-- === Cleanup ===

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  if akteBlip and DoesBlipExist(akteBlip) then
    RemoveBlip(akteBlip)
    akteBlip = nil
  end
  if aktePed and DoesEntityExist(aktePed) then
    DeleteEntity(aktePed)
    aktePed = nil
  end
  TriggerEvent('mtj_arrest:nui:akte', false)
end)
