-- MTJ Arrest: Police Helicopter System for High Wanted Levels
local DEBUG = true

local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][HELI] %s"):format(table.concat(t, " ")))
end

local activeHelicopters = {}
local helicopterActive = false

-- Police helicopter model
local HELI_MODEL = "polmav" -- Police Maverick

local function loadModel(model)
  local hash = type(model) == "number" and model or GetHashKey(model)
  if not IsModelInCdimage(hash) then 
    dbg("Model not in CD image:", tostring(model))
    return nil 
  end
  RequestModel(hash)
  local timeout = GetGameTimer() + 10000
  while not HasModelLoaded(hash) do
    if GetGameTimer() > timeout then 
      dbg("Model load timeout:", tostring(model))
      return nil 
    end
    Wait(10)
  end
  return hash
end

function SpawnPoliceHelicopter(targetPed)
  if helicopterActive then
    dbg("Helicopter already active")
    return
  end
  
  dbg("Spawning police helicopter")
  helicopterActive = true
  
  local modelHash = loadModel(HELI_MODEL)
  if not modelHash then
    dbg("Failed to load helicopter model")
    helicopterActive = false
    return
  end
  
  local playerCoords = GetEntityCoords(targetPed)
  local spawnCoords = vector3(
    playerCoords.x + math.random(-100, 100),
    playerCoords.y + math.random(-100, 100),
    playerCoords.z + 80.0
  )
  
  local heli = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, true)
  
  if not DoesEntityExist(heli) then
    dbg("Failed to create helicopter")
    helicopterActive = false
    return
  end
  
  SetEntityAsMissionEntity(heli, true, true)
  SetVehicleEngineOn(heli, true, true, false)
  SetHeliBladesFullSpeed(heli)
  SetVehicleForwardSpeed(heli, 20.0)
  
  -- Create pilot
  local pilotHash = loadModel("s_m_m_pilot_02")
  if pilotHash then
    local pilot = CreatePedInsideVehicle(heli, 4, pilotHash, -1, true, true)
    SetEntityAsMissionEntity(pilot, true, true)
    SetBlockingOfNonTemporaryEvents(pilot, true)
    SetPedFleeAttributes(pilot, 0, false)
    SetPedCombatAttributes(pilot, 46, true)
  end
  
  -- Turn on searchlight
  SetVehicleSearchlight(heli, true, true)
  
  -- Make helicopter hover and follow player
  TaskHeliMission(heli, heli, targetPed, 0, 0, 0, 2, 40.0, 40.0, -1.0, 0, 10, -1.0, 0)
  
  table.insert(activeHelicopters, heli)
  
  -- Play helicopter arrival sound
  PlaySoundFromEntity(-1, "POLICE_SCANNER_QUICK", heli, "CAMERA_FLASH_SOUNDSET", false, 0)
  
  -- Create spotlight effect
  CreateThread(function()
    local heliExists = true
    while heliExists and DoesEntityExist(heli) and helicopterActive do
      local heliCoords = GetEntityCoords(heli)
      local targetCoords = GetEntityCoords(targetPed)
      
      -- Draw spotlight from heli to player
      DrawSpotLight(
        heliCoords.x, heliCoords.y, heliCoords.z - 2.0,
        0.0, 0.0, -1.0,
        255, 255, 255,
        150.0, 10.0, 0.0, 20.0, 1.0
      )
      
      -- Additional light at target
      DrawLightWithRange(targetCoords.x, targetCoords.y, targetCoords.z + 2.0, 255, 255, 255, 20.0, 8.0)
      
      Wait(0)
    end
  end)
  
  dbg("Helicopter spawned successfully")
  
  return heli
end

function DespawnPoliceHelicopters()
  dbg("Despawning helicopters")
  helicopterActive = false
  
  for _, heli in ipairs(activeHelicopters) do
    if DoesEntityExist(heli) then
      -- Make it fly away first
      local heliCoords = GetEntityCoords(heli)
      local flyAwayCoords = vector3(heliCoords.x + 500.0, heliCoords.y + 500.0, heliCoords.z + 100.0)
      
      TaskVehicleDriveToCoord(heli, flyAwayCoords.x, flyAwayCoords.y, flyAwayCoords.z, 50.0, 0, GetEntityModel(heli), 262144, 1.0, true)
      
      -- Delete after 10 seconds
      SetTimeout(10000, function()
        if DoesEntityExist(heli) then
          DeleteEntity(heli)
        end
      end)
    end
  end
  
  activeHelicopters = {}
end

-- Event handlers
RegisterNetEvent('mtj_arrest:spawnHelicopter')
AddEventHandler('mtj_arrest:spawnHelicopter', function()
  local playerPed = PlayerPedId()
  SpawnPoliceHelicopter(playerPed)
end)

RegisterNetEvent('mtj_arrest:despawnHelicopters')
AddEventHandler('mtj_arrest:despawnHelicopters', function()
  DespawnPoliceHelicopters()
end)

-- Auto-spawn helicopter at wanted level 4+
CreateThread(function()
  while true do
    Wait(5000)
    
    local wantedLevel = GetPlayerWantedLevel(PlayerId())
    
    if wantedLevel >= 4 and not helicopterActive then
      dbg("Auto-spawning helicopter for wanted level", wantedLevel)
      SpawnPoliceHelicopter(PlayerPedId())
    elseif wantedLevel < 4 and helicopterActive then
      dbg("Despawning helicopter, wanted level dropped")
      DespawnPoliceHelicopters()
    end
  end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  DespawnPoliceHelicopters()
end)

dbg("Helicopter system loaded")
