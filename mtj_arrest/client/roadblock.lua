-- MTJ Arrest: Dynamic Roadblock System
local DEBUG = true

local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][ROADBLOCK] %s"):format(table.concat(t, " ")))
end

local activeRoadblocks = {}
local roadblockActive = false

-- Police vehicle models
local POLICE_VEHICLES = {
  "police",
  "police2",
  "police3",
  "sheriff"
}

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

local function getStreetAndZone(coords)
  local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
  local streetName = GetStreetNameFromHashKey(streetHash)
  return streetName or "Unknown"
end

function SpawnRoadblock()
  if roadblockActive then
    dbg("Roadblock already active")
    return
  end
  
  dbg("Spawning roadblock")
  roadblockActive = true
  
  local playerPed = PlayerPedId()
  local playerCoords = GetEntityCoords(playerPed)
  local playerHeading = GetEntityHeading(playerPed)
  
  -- Calculate roadblock position ahead of player
  local forwardX = playerCoords.x + (math.cos(math.rad(playerHeading)) * 50.0)
  local forwardY = playerCoords.y + (math.sin(math.rad(playerHeading)) * 50.0)
  local forwardZ = playerCoords.z
  
  -- Get ground Z
  local found, groundZ = GetGroundZFor_3dCoord(forwardX, forwardY, forwardZ + 50.0, 0)
  if found then forwardZ = groundZ end
  
  local roadblockCoords = vector3(forwardX, forwardY, forwardZ)
  
  -- Spawn 2-3 police vehicles
  local vehicleCount = math.random(2, 3)
  
  for i = 1, vehicleCount do
    local model = POLICE_VEHICLES[math.random(1, #POLICE_VEHICLES)]
    local modelHash = loadModel(model)
    
    if modelHash then
      local offsetX = (i - 1) * 4.0 - 4.0
      local vehCoords = vector3(
        roadblockCoords.x + offsetX,
        roadblockCoords.y,
        roadblockCoords.z
      )
      
      local veh = CreateVehicle(modelHash, vehCoords.x, vehCoords.y, vehCoords.z, playerHeading + 90.0, true, true)
      
      if DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleOnGroundProperly(veh)
        SetVehicleEngineOn(veh, false, false, false)
        SetVehicleLights(veh, 2)
        SetVehicleSiren(veh, true)
        SetVehicleHasBeenOwnedByPlayer(veh, false)
        
        -- Spawn cop next to vehicle
        local copModel = loadModel("s_m_y_cop_01")
        if copModel then
          local cop = CreatePed(4, copModel, vehCoords.x + 2.0, vehCoords.y, vehCoords.z, playerHeading, true, true)
          SetEntityAsMissionEntity(cop, true, true)
          SetPedArmour(cop, 100)
          GiveWeaponToPed(cop, GetHashKey("WEAPON_PISTOL"), 120, false, true)
          SetPedRelationshipGroupHash(cop, GetHashKey("COP"))
          SetPedCombatAbility(cop, 2)
          SetPedCombatRange(cop, 2)
          
          -- Cop aims at player
          TaskAimGunAtEntity(cop, playerPed, -1, false)
          
          table.insert(activeRoadblocks, {vehicle = veh, cop = cop})
        else
          table.insert(activeRoadblocks, {vehicle = veh})
        end
        
        -- Flash police lights effect
        CreateThread(function()
          local duration = 15000
          local startTime = GetGameTimer()
          local vehCoords = GetEntityCoords(veh)
          
          while DoesEntityExist(veh) and (GetGameTimer() - startTime) < duration do
            local toggle = (GetGameTimer() % 400) < 200
            
            if toggle then
              DrawLightWithRange(vehCoords.x + 1.0, vehCoords.y, vehCoords.z + 0.5, 255, 0, 0, 8.0, 1.5)
              DrawLightWithRange(vehCoords.x - 1.0, vehCoords.y, vehCoords.z + 0.5, 0, 0, 255, 8.0, 1.5)
            else
              DrawLightWithRange(vehCoords.x + 1.0, vehCoords.y, vehCoords.z + 0.5, 0, 0, 255, 8.0, 1.5)
              DrawLightWithRange(vehCoords.x - 1.0, vehCoords.y, vehCoords.z + 0.5, 255, 0, 0, 8.0, 1.5)
            end
            
            Wait(0)
          end
        end)
      end
    end
    
    Wait(500)
  end
  
  dbg("Roadblock spawned with", vehicleCount, "vehicles")
  
  -- Play siren sound
  PlaySoundFrontend(-1, "POLICE_SCANNER_QUICK", "CAMERA_FLASH_SOUNDSET", true)
end

function DespawnRoadblocks()
  dbg("Despawning roadblocks")
  roadblockActive = false
  
  for _, rb in ipairs(activeRoadblocks) do
    if rb.vehicle and DoesEntityExist(rb.vehicle) then
      DeleteEntity(rb.vehicle)
    end
    if rb.cop and DoesEntityExist(rb.cop) then
      DeleteEntity(rb.cop)
    end
  end
  
  activeRoadblocks = {}
end

-- Event handlers
RegisterNetEvent('mtj_arrest:spawnRoadblock')
AddEventHandler('mtj_arrest:spawnRoadblock', function()
  SpawnRoadblock()
end)

RegisterNetEvent('mtj_arrest:despawnRoadblocks')
AddEventHandler('mtj_arrest:despawnRoadblocks', function()
  DespawnRoadblocks()
end)

-- Auto-spawn roadblock at wanted level 3+
CreateThread(function()
  local lastSpawnTime = 0
  
  while true do
    Wait(10000) -- Check every 10 seconds
    
    local wantedLevel = GetPlayerWantedLevel(PlayerId())
    local currentTime = GetGameTimer()
    
    if wantedLevel >= 3 and not roadblockActive and (currentTime - lastSpawnTime) > 30000 then
      dbg("Auto-spawning roadblock for wanted level", wantedLevel)
      SpawnRoadblock()
      lastSpawnTime = currentTime
    elseif wantedLevel < 2 and roadblockActive then
      dbg("Despawning roadblock, wanted level dropped")
      DespawnRoadblocks()
    end
  end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  DespawnRoadblocks()
end)

dbg("Roadblock system loaded")
