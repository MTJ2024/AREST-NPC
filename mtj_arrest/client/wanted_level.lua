-- mtj_arrest: Wanted Level System
-- Automatically sets wanted levels when player commits crimes (shooting, killing NPCs)

local DEBUG = Config and Config.Debug or false
local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][WANTED] %s"):format(table.concat(t, " ")))
end

-- Configuration
local Config = Config or {}
local wantedConfig = Config.WantedSystem or {
  -- Enable automatic wanted level on crimes
  enabled = true,
  
  -- Wanted level given when shooting (not hitting anyone)
  shootingWantedLevel = 2,
  
  -- Wanted level given when hitting/injuring a ped
  injuringWantedLevel = 3,
  
  -- Wanted level given when killing a ped
  killingWantedLevel = 4,
  
  -- Cooldown in milliseconds between wanted level increases (prevents spam)
  cooldownMs = 3000,
  
  -- Whether to apply wanted level for killing other players
  applyForPlayerKills = false,
  
  -- Detection radii and timeouts
  deathDetectionRadius = 50.0,
  injuryDetectionRadius = 30.0,
  combatTimeoutMs = 5000
}

-- State tracking
local lastWantedIncrease = 0
local lastShotFired = 0
local trackedPeds = {}

-- Function to safely increase wanted level
local function increaseWantedLevel(level, reason)
  local now = GetGameTimer()
  if now - lastWantedIncrease < wantedConfig.cooldownMs then
    return -- Still in cooldown
  end
  
  local currentWanted = GetPlayerWantedLevel(PlayerId())
  local newWanted = math.min(5, math.max(currentWanted, level))
  
  if newWanted > currentWanted then
    SetPlayerWantedLevel(PlayerId(), newWanted, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    lastWantedIncrease = now
    dbg(("Wanted level increased to %d - Reason: %s"):format(newWanted, reason))
  end
end

-- Check if player should get wanted (not in jail, not frozen, etc.)
local function shouldApplyWanted()
  local playerPed = PlayerPedId()
  
  -- Don't apply if player is dead
  if IsEntityDead(playerPed) then
    return false
  end
  
  -- Don't apply if entity is frozen (likely in jail or cutscene)
  if IsEntityPositionFrozen(playerPed) then
    return false
  end
  
  return true
end

-- Monitor shooting
CreateThread(function()
  if not wantedConfig.enabled then return end
  
  while true do
    Wait(0)
    
    local playerPed = PlayerPedId()
    
    -- Check if player is shooting
    if IsPedShooting(playerPed) then
      local now = GetGameTimer()
      if now - lastShotFired > 1000 then -- Only trigger once per second
        lastShotFired = now
        
        -- Give wanted level for shooting (only if should apply)
        if shouldApplyWanted() then
          increaseWantedLevel(wantedConfig.shootingWantedLevel, "Shooting weapon")
        end
      end
    else
      Wait(500) -- Reduce load when not shooting
    end
  end
end)

-- Monitor ped deaths and injuries
CreateThread(function()
  if not wantedConfig.enabled then return end
  
  while true do
    Wait(1000) -- Check every second
    
    if not shouldApplyWanted() then
      goto continue
    end
    
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    
    -- Find all peds nearby
    local handle, ped = FindFirstPed()
    if handle ~= -1 then
      repeat
        -- Only check NPCs, not players (unless configured)
        if ped ~= playerPed and DoesEntityExist(ped) then
          local isPedPlayer = IsPedAPlayer(ped)
          
          if not isPedPlayer or wantedConfig.applyForPlayerKills then
            -- Check if ped was killed by player
            if IsEntityDead(ped) and not trackedPeds[ped] then
              -- Check if player was involved in the death
              local pedPos = GetEntityCoords(ped)
              local distance = #(playerPos - pedPos)
              
              -- If ped died near player, assume player involvement
              if distance < wantedConfig.deathDetectionRadius then
                -- Check if player was recently shooting or in combat
                if IsPedInCombat(playerPed, ped) or (GetGameTimer() - lastShotFired) < wantedConfig.combatTimeoutMs then
                  trackedPeds[ped] = true
                  
                  if isPedPlayer then
                    increaseWantedLevel(wantedConfig.killingWantedLevel, "Killed a person")
                  else
                    increaseWantedLevel(wantedConfig.killingWantedLevel, "Killed a ped")
                  end
                end
              end
            end
            
            -- Check if ped was injured (has health damage)
            if not IsEntityDead(ped) and not trackedPeds[ped] then
              local health = GetEntityHealth(ped)
              local maxHealth = GetEntityMaxHealth(ped)
              
              -- If ped is injured (less than max health) and near player
              if health < maxHealth then
                local pedPos = GetEntityCoords(ped)
                local distance = #(playerPos - pedPos)
                
                if distance < wantedConfig.injuryDetectionRadius then
                  -- Check if player was attacking this ped
                  if IsPedInCombat(playerPed, ped) or HasEntityBeenDamagedByEntity(ped, playerPed, true) then
                    trackedPeds[ped] = true
                    increaseWantedLevel(wantedConfig.injuringWantedLevel, "Injured a ped")
                    ClearEntityLastDamageEntity(ped)
                  end
                end
              end
            end
          end
        end
        
        local success, nextPed = FindNextPed(handle)
        ped = nextPed
      until not success
      
      EndFindPed(handle)
    end
    
    ::continue::
    
    -- Clean up tracked peds (remove entries older than 30 seconds)
    -- This prevents the table from growing indefinitely
    local cleanupCount = 0
    for pedHandle, _ in pairs(trackedPeds) do
      if not DoesEntityExist(pedHandle) then
        trackedPeds[pedHandle] = nil
        cleanupCount = cleanupCount + 1
      end
    end
    
    if cleanupCount > 0 then
      dbg(("Cleaned up %d tracked peds"):format(cleanupCount))
    end
  end
end)

-- Reset tracked peds when player dies/spawns
AddEventHandler('playerSpawned', function()
  trackedPeds = {}
  lastWantedIncrease = 0
  lastShotFired = 0
  dbg("Player spawned - reset wanted level tracking")
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  trackedPeds = {}
end)

-- Debug command to test wanted level
RegisterCommand('mtj_test_wanted', function(source, args)
  local level = tonumber(args[1]) or 2
  level = math.max(1, math.min(5, level))
  SetPlayerWantedLevel(PlayerId(), level, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  print(("[mtj_arrest][WANTED] Set wanted level to %d"):format(level))
end, false)

dbg("Wanted level system loaded and active")
