-- MTJ Arrest: Auto Wanted Level Generator
-- Automatically generates wanted level based on player actions

local Config = Config or {}
local DEBUG = Config.Debug
if DEBUG == nil then DEBUG = true end -- Enable debug by default if not set

local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][WANTED_GEN] %s"):format(table.concat(t, " ")))
end

-- Configuration defaults
local function getCheckInterval()
  return (Config.AutoWantedLevel and Config.AutoWantedLevel.CrimeCheckInterval) or 2000
end

local function getRecklessDrivingSpeed()
  return (Config.AutoWantedLevel and Config.AutoWantedLevel.RecklessDrivingSpeed) or 120
end

local function getRecklessDrivingCooldown()
  return (Config.AutoWantedLevel and Config.AutoWantedLevel.RecklessDrivingCooldown) or 10000
end

local function getMeleeCombatCooldown()
  return (Config.AutoWantedLevel and Config.AutoWantedLevel.MeleeCombatCooldown) or 5000
end

-- Check if auto wanted is enabled
local function isAutoWantedEnabled()
  return Config.AutoWantedLevel and Config.AutoWantedLevel.Enabled
end

-- Set wanted level with bounds checking
local function setWantedLevel(level)
  if not isAutoWantedEnabled() then 
    dbg("Auto wanted disabled, not setting level")
    return 
  end
  
  local minLevel = (Config.AutoWantedLevel and Config.AutoWantedLevel.MinWantedLevel) or 1
  local maxLevel = (Config.AutoWantedLevel and Config.AutoWantedLevel.MaxWantedLevel) or 5
  
  level = math.max(minLevel, math.min(maxLevel, level))
  
  SetPlayerWantedLevel(PlayerId(), level, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  
  dbg(("✓ Set wanted level to %d"):format(level))
  
  -- Show notification if ESX is available and initialized
  if ESX and ESX.ShowNotification and type(ESX.ShowNotification) == "function" then
    pcall(function()
      ESX.ShowNotification(("~r~Wanted Level: %d Stars"):format(level))
    end)
  end
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
  
  local lastRecklessDrivingCheck = 0
  local lastMeleeCombatCheck = 0
  
  while true do
    Wait(getCheckInterval())
    
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
      if speed > getRecklessDrivingSpeed() and currentWanted == 0 then
        local now = GetGameTimer()
        if now - lastRecklessDrivingCheck > getRecklessDrivingCooldown() then
          dbg("Reckless driving detected - setting wanted level")
          setWantedLevel(1)
          lastRecklessDrivingCheck = now
        end
      end
    end
    
    -- Check if player is attacking peds
    if IsPedInMeleeCombat(playerPed) then
      if currentWanted == 0 then
        local now = GetGameTimer()
        if now - lastMeleeCombatCheck > getMeleeCombatCooldown() then
          dbg("Melee combat detected - setting wanted level")
          setWantedLevel(1)
          lastMeleeCombatCheck = now
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
