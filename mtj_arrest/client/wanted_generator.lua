-- MTJ Arrest: Auto Wanted Level Generator
-- Automatically generates wanted level based on player actions

local Config = Config or {}
local DEBUG = Config.Debug or false

local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][WANTED_GEN] %s"):format(table.concat(t, " ")))
end

-- Check if auto wanted is enabled
local function isAutoWantedEnabled()
  return Config.AutoWantedLevel and Config.AutoWantedLevel.Enabled
end

-- Set wanted level with bounds checking
local function setWantedLevel(level)
  if not isAutoWantedEnabled() then return end
  
  local minLevel = (Config.AutoWantedLevel and Config.AutoWantedLevel.MinWantedLevel) or 1
  local maxLevel = (Config.AutoWantedLevel and Config.AutoWantedLevel.MaxWantedLevel) or 5
  
  level = math.max(minLevel, math.min(maxLevel, level))
  
  SetPlayerWantedLevel(PlayerId(), level, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  
  dbg(("Set wanted level to %d"):format(level))
end

-- Increase wanted level by amount
local function increaseWantedLevel(amount)
  if not isAutoWantedEnabled() then return end
  
  local current = GetPlayerWantedLevel(PlayerId())
  setWantedLevel(current + amount)
end

-- Monitor for crimes/actions that should trigger wanted level
CreateThread(function()
  if not isAutoWantedEnabled() then 
    dbg("Auto wanted level generation is disabled")
    return 
  end
  
  dbg("Auto wanted level generator started")
  
  local lastCrimeCheck = 0
  local checkInterval = 2000 -- Check every 2 seconds
  
  while true do
    Wait(checkInterval)
    
    local playerPed = PlayerPedId()
    local currentWanted = GetPlayerWantedLevel(PlayerId())
    
    -- Check if player is shooting
    if IsPedShooting(playerPed) then
      if currentWanted == 0 then
        dbg("Player shooting - setting wanted level")
        setWantedLevel(1)
      end
    end
    
    -- Check if player is in a vehicle and driving recklessly
    if IsPedInAnyVehicle(playerPed, false) then
      local vehicle = GetVehiclePedIsIn(playerPed, false)
      local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
      
      -- High speed driving
      if speed > 120 and currentWanted == 0 then
        local now = GetGameTimer()
        if now - lastCrimeCheck > 10000 then -- Only once per 10 seconds
          dbg("Reckless driving detected - setting wanted level")
          setWantedLevel(1)
          lastCrimeCheck = now
        end
      end
    end
    
    -- Check if player is attacking peds
    if IsPedInMeleeCombat(playerPed) then
      if currentWanted == 0 then
        local now = GetGameTimer()
        if now - lastCrimeCheck > 5000 then
          dbg("Melee combat detected - setting wanted level")
          setWantedLevel(1)
          lastCrimeCheck = now
        end
      end
    end
  end
end)

-- Event to manually set wanted level
RegisterNetEvent('mtj_arrest:setWantedLevel')
AddEventHandler('mtj_arrest:setWantedLevel', function(level)
  setWantedLevel(level)
end)

-- Event to increase wanted level
RegisterNetEvent('mtj_arrest:increaseWantedLevel')
AddEventHandler('mtj_arrest:increaseWantedLevel', function(amount)
  increaseWantedLevel(amount or 1)
end)

-- Export functions for other resources
exports('SetWantedLevel', setWantedLevel)
exports('IncreaseWantedLevel', increaseWantedLevel)
exports('GetWantedLevel', function() return GetPlayerWantedLevel(PlayerId()) end)

dbg("Wanted level generator loaded")
