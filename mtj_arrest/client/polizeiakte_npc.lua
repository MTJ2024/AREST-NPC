-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  github.com/MTJ2024/AREST-NPC                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- Polizeiakte NPC: Spieler kann an einem NPC seine Strafakte einsehen

local akteNpc = nil
local akteBlip = nil
local akteOpen = false

local function loadModel(model)
  local hash = type(model) == "number" and model or GetHashKey(model)
  if not IsModelInCdimage(hash) then return nil end
  RequestModel(hash)
  local to = GetGameTimer() + 10000
  while not HasModelLoaded(hash) do
    if GetGameTimer() > to then return nil end
    Wait(10)
  end
  return hash
end

-- NPC spawnen
CreateThread(function()
  local cfg = Config.PolizeiakteNPC
  if not cfg or not cfg.Aktiviert then return end

  local pos = cfg.Position
  local heading = cfg.Heading or 180.0
  local model = cfg.Model or "s_m_y_cop_01"

  local hash = loadModel(model)
  if not hash then
    print("[mtj_arrest] Polizeiakte-NPC Modell konnte nicht geladen werden: " .. tostring(model))
    return
  end

  akteNpc = CreatePed(4, hash, pos.x, pos.y, pos.z, heading, false, true)
  SetEntityAsMissionEntity(akteNpc, true, true)
  SetBlockingOfNonTemporaryEvents(akteNpc, true)
  SetPedFleeAttributes(akteNpc, 0, false)
  SetPedCombatAttributes(akteNpc, 46, true)
  SetEntityInvincible(akteNpc, true)
  FreezeEntityPosition(akteNpc, true)
  SetPedKeepTask(akteNpc, true)
  TaskStartScenarioInPlace(akteNpc, cfg.Scenario or "WORLD_HUMAN_CLIPBOARD", 0, true)
  SetModelAsNoLongerNeeded(hash)

  -- Blip auf der Karte
  if cfg.Blip then
    akteBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(akteBlip, cfg.Blip.Sprite or 60)
    SetBlipDisplay(akteBlip, 4)
    SetBlipScale(akteBlip, cfg.Blip.Scale or 0.85)
    SetBlipColour(akteBlip, cfg.Blip.Farbe or 3)
    SetBlipAsShortRange(akteBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(cfg.Blip.Name or "Polizeiakte")
    EndTextCommandSetBlipName(akteBlip)
  end

  print("[mtj_arrest] Polizeiakte-NPC gespawnt")
end)

-- Interaktions-Loop (E drücken in der Nähe)
CreateThread(function()
  local cfg = Config.PolizeiakteNPC
  if not cfg or not cfg.Aktiviert then return end

  local interactDist = cfg.Interaktionsradius or 2.5

  while true do
    Wait(0)
    if akteNpc and DoesEntityExist(akteNpc) and not akteOpen then
      local playerPed = PlayerPedId()
      local ppos = GetEntityCoords(playerPed)
      local npcPos = GetEntityCoords(akteNpc)
      local dist = #(ppos - npcPos)

      if dist < interactDist then
        -- 3D-Text über NPC anzeigen
        local label = cfg.InteraktionsText or "[E] Polizeiakte einsehen"
        DrawText3D(npcPos.x, npcPos.y, npcPos.z + 1.1, label)

        if IsControlJustPressed(0, 38) then -- E
          akteOpen = true
          -- Akte vom Server anfordern
          TriggerServerEvent('mtj_arrest:requestFullAkte')
        end
      else
        Wait(200) -- weiter weg = seltener prüfen
      end
    else
      Wait(500)
    end
  end
end)

-- 3D-Text-Hilfsfunktion
function DrawText3D(x, y, z, text)
  local onScreen, sx, sy = World3dToScreen2d(x, y, z)
  if onScreen then
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 230)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(sx, sy)
  end
end

-- Akte-Daten vom Server empfangen → UI öffnen
RegisterNetEvent('mtj_arrest:clientFullAkte')
AddEventHandler('mtj_arrest:clientFullAkte', function(akte)
  if not akte then
    akteOpen = false
    return
  end
  -- NUI öffnen mit Akte-Daten
  SendNUIMessage({
    action = "polizeiakteOpen",
    akte = akte
  })
  SetNuiFocus(true, true)
end)

-- NUI Callback: Akte schließen
RegisterNUICallback('closePolizeiakte', function(data, cb)
  akteOpen = false
  SetNuiFocus(false, false)
  cb('ok')
end)

-- Cleanup
AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  if akteNpc and DoesEntityExist(akteNpc) then DeleteEntity(akteNpc) end
  if akteBlip and DoesBlipExist(akteBlip) then RemoveBlip(akteBlip) end
  akteOpen = false
end)
