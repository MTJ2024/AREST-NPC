-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- Polizeiakte NPC: Spieler kann an einem NPC seine Strafakte einsehen

local akteNpc = nil
local akteBlip = nil
local akteOpen = false

-- Global fuer nui_focus_handlers.lua: verhindert dass SetNuiFocus(false) die Akte-Session killt
function IsPolizeiakteOpen() return akteOpen end
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

-- NPC spawnen (Funktion fuer Start und Respawn)
local function spawnAkteNpc()
  local cfg = Config.PolizeiakteNPC
  if not cfg or not cfg.Aktiviert then return end
  -- Nicht doppelt spawnen
  if akteNpc and DoesEntityExist(akteNpc) then return end

  local pos = cfg.Position
  local heading = cfg.Heading or 180.0
  local model = cfg.Model or "s_m_y_cop_01"

  local hash = loadModel(model)
  if not hash then
    print("[mtj_arrest] Polizeiakte-NPC Modell konnte nicht geladen werden: " .. tostring(model))
    return
  end

  -- Kollisionsdaten am NPC-Standort laden und kurz warten
  RequestCollisionAtCoord(pos.x, pos.y, pos.z)
  Wait(200)

  -- Bodenhoehe ermitteln mit Fallback auf Config-Z
  local groundZ = pos.z
  for zOffset = 0.0, 10.0, 2.0 do
    local ok, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + zOffset, false)
    if ok then
      groundZ = gz
      break
    end
    Wait(50)
  end

  akteNpc = CreatePed(4, hash, pos.x, pos.y, groundZ, heading, false, true)
  SetEntityAsMissionEntity(akteNpc, true, true)
  SetBlockingOfNonTemporaryEvents(akteNpc, true)
  SetPedFleeAttributes(akteNpc, 0, false)
  SetPedCombatAttributes(akteNpc, 46, true)
  SetEntityInvincible(akteNpc, true)
  FreezeEntityPosition(akteNpc, true)
  SetPedKeepTask(akteNpc, true)
  TaskStartScenarioInPlace(akteNpc, cfg.Scenario or "WORLD_HUMAN_CLIPBOARD", 0, true)
  SetModelAsNoLongerNeeded(hash)

  -- Blip auf der Karte (nur wenn noch keiner existiert)
  if cfg.Blip and (not akteBlip or not DoesBlipExist(akteBlip)) then
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
end

-- NPC beim Start spawnen
CreateThread(function()
  spawnAkteNpc()
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
        -- 3D-Text über NPC anzeigen (hoeher fuer bessere Sichtbarkeit)
        local label = cfg.InteraktionsText or "[E] Polizeiakte einsehen"
        DrawText3D(npcPos.x, npcPos.y, npcPos.z + 1.3, label)

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
    SetTextScale(0.50, 0.50)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 240)
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

-- Akte-Daten vom Server empfangen -> UI oeffnen
local akteOpenTime = 0
local AKTE_TIMEOUT = 60000  -- 60 Sekunden absoluter Max-Timeout
local safetyNetFastUntil = 0  -- Zeitstempel bis zu dem der Safety-Net-100ms-Modus gilt
-- Heartbeat-Tracking: JS sendet alle 800ms 'akteAlive' waehrend die Akte sichtbar ist.
-- Wenn die Signale ausbleiben (Overlay geschlossen), schliesst das Safety-Net nach
-- HEARTBEAT_CLOSE_DELAY Millisekunden selbst. lastJsHeartbeat==0 = noch kein Heartbeat
-- empfangen (Fallback: AKTE_TIMEOUT bleibt aktiv).
local lastJsHeartbeat = 0
local HEARTBEAT_CLOSE_DELAY = 2000  -- ms ohne Heartbeat -> Force-Close

local function forceCloseAkte()
  -- IMMER ausfuehren, auch wenn akteOpen==false (Sicherheitsnetz)
  akteOpen = false
  akteOpenTime = 0
  lastJsHeartbeat = 0
  -- Sicherheitsnetz fuer 3s in den 100ms-Schnellmodus schalten
  safetyNetFastUntil = GetGameTimer() + 3000
  SendNUIMessage({ action = "polizeiakteClose" })
  -- Kamera direkt freigeben. cb('ok') wurde bereits VOR diesem Aufruf gesetzt,
  -- daher ist hier kein NUI-Bridge-Deadlock mehr moeglich.
  SetNuiFocusKeepInput(false)
  SetNuiFocus(false, false)
end

-- Script-Refresh: Akte schliessen wenn /mtj_refresh gerufen wird
AddEventHandler('mtj_arrest:refreshScript', forceCloseAkte)

RegisterNetEvent('mtj_arrest:clientFullAkte')
AddEventHandler('mtj_arrest:clientFullAkte', function(akte)
  if not akte then
    forceCloseAkte()
    return
  end
  SendNUIMessage({
    action = "polizeiakteOpen",
    akte = akte
  })
  SetNuiFocus(true, true)
  akteOpenTime = GetGameTimer()
  lastJsHeartbeat = 0  -- wird beim ersten JS-Heartbeat gesetzt

  -- Eigener Timer-Thread fuer DIESE Oeffnung: schliesst nach AKTE_TIMEOUT garantiert
  local openedAt = akteOpenTime
  CreateThread(function()
    Wait(AKTE_TIMEOUT)
    -- Nur schliessen wenn DIESE Oeffnung noch aktiv ist (nicht eine neuere)
    if akteOpen and akteOpenTime == openedAt then
      print("[mtj_arrest] Polizeiakte Timeout (" .. AKTE_TIMEOUT .. "ms) - Zwangsschliessung")
      forceCloseAkte()
    end
  end)
end)

-- NUI Callback: Akte schliessen (primaerer Pfad)
-- cb('ok') ZUERST aufrufen: gibt den JS-Fetch sofort frei.
-- forceCloseAkte() laeuft danach und ruft SetNuiFocus direkt auf (kein CreateThread).
RegisterNUICallback('closePolizeiakte', function(data, cb)
  cb('ok')
  forceCloseAkte()
end)

-- NUI Callback: Heartbeat — JS sendet diesen alle 800ms waehrend die Akte sichtbar ist.
-- Wenn die Akte geschlossen wird (Overlay hidden), stoppt JS den Heartbeat.
-- Das Safety-Net erkennt den Ausfall und schliesst nach HEARTBEAT_CLOSE_DELAY ms.
RegisterNUICallback('akteAlive', function(data, cb)
  lastJsHeartbeat = GetGameTimer()  -- immer updaten, Safety-Net-Check ist separat durch akteOpen gewaehrt
  cb('ok')
end)

-- NUI Callback: Akte aktualisieren (Refresh-Button im UI)
RegisterNUICallback('refreshPolizeiakte', function(data, cb)
  -- Timeout zuruecksetzen damit Akte offen bleibt waehrend Daten geladen werden
  akteOpenTime = GetGameTimer()
  TriggerServerEvent('mtj_arrest:requestFullAkte')
  cb('ok')
end)

-- NUI Callback: Kriminallevel senken anfordern
RegisterNUICallback('reduceKriminalLevel', function(data, cb)
  if not akteOpen then cb('error'); return end
  akteOpenTime = GetGameTimer() -- Timeout zuruecksetzen
  TriggerServerEvent('mtj_arrest:reduceKriminalLevel')
  cb('ok')
end)

-- Server: Kriminallevel-Reduktion fehlgeschlagen → Button wieder freigeben
RegisterNetEvent('mtj_arrest:kriminalLevelFail')
AddEventHandler('mtj_arrest:kriminalLevelFail', function()
  SendNUIMessage({ action = "kriminalLevelFail" })
end)

-- Sicherheitsnetz: Focus freigeben + Timeouts pruefen.
-- Laeuft alle 100ms wenn im Fast-Modus (3s nach forceCloseAkte), sonst alle 500ms.
-- Heartbeat-Check: wenn JS kein akteAlive mehr sendet (Overlay wurde geschlossen),
-- nach HEARTBEAT_CLOSE_DELAY ms schliessen. Greift auch wenn closePolizeiakte-Callback
-- nicht ankommt (z.B. bei transienten NUI-HTTP-Problemen).
CreateThread(function()
  while true do
    local interval = (GetGameTimer() < safetyNetFastUntil) and 100 or 500
    Wait(interval)
    if akteOpen then
      local now = GetGameTimer()
      -- Heartbeat-Timeout: JS hat Overlay geschlossen aber closePolizeiakte-Callback kam nicht an
      if lastJsHeartbeat > 0 and (now - lastJsHeartbeat) >= HEARTBEAT_CLOSE_DELAY then
        print("[mtj_arrest] Heartbeat-Timeout: Akte JS-seitig geschlossen, zwangsschliesse")
        forceCloseAkte()
      -- Absoluter Timeout als letzter Fallback
      elseif akteOpenTime > 0 and (now - akteOpenTime) >= AKTE_TIMEOUT then
        print("[mtj_arrest] Sicherheitsnetz: Polizeiakte absoluter Timeout, zwangsgeschlossen")
        forceCloseAkte()
      end
    end
    -- Wenn akteOpen==false aber NUI-Focus noch aktiv (Restfehler nach Schliessen)
    if not akteOpen then
      SetNuiFocusKeepInput(false)
      SetNuiFocus(false, false)
    end
  end
end)

-- Cleanup
AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  if akteOpen then forceCloseAkte() end
  if akteNpc and DoesEntityExist(akteNpc) then DeleteEntity(akteNpc) end
  if akteBlip and DoesBlipExist(akteBlip) then RemoveBlip(akteBlip) end
end)

AddEventHandler('playerSpawned', function()
  if akteOpen then forceCloseAkte() end
  -- NPC neu spawnen falls er durch Tod oder Streaming verloren ging
  CreateThread(function()
    Wait(1000) -- kurz warten bis Welt geladen ist
    spawnAkteNpc()
  end)
end)

-- Bei Tod NPC/Blip entfernen (werden bei Respawn neu gespawnt); Akte-UI bleibt offen
CreateThread(function()
  local wasDead = false
  while true do
    Wait(500)
    local isDead = IsPedDeadOrDying(PlayerPedId(), true)
    if isDead and not wasDead then
      -- NPC und Blip entfernen damit sie bei Respawn sauber neu gespawnt werden
      if akteNpc and DoesEntityExist(akteNpc) then
        DeleteEntity(akteNpc)
        akteNpc = nil
      end
      if akteBlip and DoesBlipExist(akteBlip) then
        RemoveBlip(akteBlip)
        akteBlip = nil
      end
    end
    wasDead = isDead
  end
end)
