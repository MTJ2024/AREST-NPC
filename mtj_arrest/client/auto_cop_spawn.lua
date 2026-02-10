-- MTJ Arrest: Aggressive Police System - 100% functional, always engaged
-- Police spawn at wanted >= 2 and stay aggressive, never passive

local DEBUG = Config and Config.Debug or false
local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][POLICE] %s"):format(table.concat(t, " ")))
end

local activeCops = {}
local maxCops = 7
local minCops = 2
local spawnRadiusMin = 25.0
local spawnRadiusMax = 45.0
local engageRadius = 80.0  -- Cops stay engaged within this radius
local policeModels = {
    "s_m_y_cop_01", "s_f_y_cop_01", "s_m_y_sheriff_01", "s_m_m_sheriff_01"
}

-- Make cop fully aggressive and combat-ready
local function makeAggressiveCop(cop, playerPed)
    if not DoesEntityExist(cop) then return end
    
    -- Maximum aggression settings
    SetPedCombatAbility(cop, 100)  -- Maximum combat ability
    SetPedCombatRange(cop, 2)      -- Medium range
    SetPedCombatMovement(cop, 2)   -- Offensive movement
    SetPedAlertness(cop, 3)        -- Maximum alertness
    SetPedAccuracy(cop, 60)        -- Good accuracy
    
    -- Combat attributes
    SetPedFleeAttributes(cop, 0, false)  -- Never flee
    SetPedCombatAttributes(cop, 46, true)  -- Always fight
    SetPedCombatAttributes(cop, 5, true)   -- Can use cover
    SetPedCombatAttributes(cop, 1, true)   -- Can use vehicles
    
    -- Disable blocking so they react dynamically
    SetBlockingOfNonTemporaryEvents(cop, false)
    
    -- Set as cop
    SetPedRelationshipGroupHash(cop, GetHashKey("COP"))
    
    -- Give weapon and ammo
    GiveWeaponToPed(cop, GetHashKey("WEAPON_PISTOL"), 250, false, true)
    SetPedInfiniteAmmoClip(cop, true)
    SetCurrentPedWeapon(cop, GetHashKey("WEAPON_PISTOL"), true)
    
    -- Armor
    SetPedArmour(cop, 100)
    
    -- Make them target the player
    SetPedAsEnemy(cop, true)
    
    -- Initial combat task
    TaskCombatPed(cop, playerPed, 0, 16)
    
    dbg("Cop configured for maximum aggression")
end

-- Spawn aggressive cop near player
local function spawnAggressiveCop(playerCoords, playerPed)
    local angle = math.random() * 2 * math.pi
    local dist = math.random() * (spawnRadiusMax - spawnRadiusMin) + spawnRadiusMin
    local x = playerCoords.x + math.cos(angle) * dist
    local y = playerCoords.y + math.sin(angle) * dist
    local z = playerCoords.z
    
    -- Get ground Z
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 50.0, false)
    if found then z = groundZ end
    
    local model = policeModels[math.random(1, #policeModels)]
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeout do 
        Wait(10) 
    end
    
    if not HasModelLoaded(modelHash) then
        dbg("Failed to load model: " .. model)
        return nil
    end
    
    -- Spawn cop facing player
    local heading = GetHeadingFromVector_2d(playerCoords.x - x, playerCoords.y - y)
    local cop = CreatePed(4, modelHash, x, y, z, heading, true, true)
    
    if not DoesEntityExist(cop) then
        dbg("Failed to create ped")
        return nil
    end
    
    SetEntityAsMissionEntity(cop, true, true)
    SetEntityLoadCollisionFlag(cop, true)
    
    -- Make aggressive
    makeAggressiveCop(cop, playerPed)
    
    table.insert(activeCops, cop)
    dbg(("Spawned aggressive cop #%d at distance %.1fm"):format(#activeCops, dist))
    
    return cop
end

-- Keep all cops engaged and in combat
local function maintainCombat()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for i = #activeCops, 1, -1 do
        local cop = activeCops[i]
        
        if not DoesEntityExist(cop) or IsEntityDead(cop) then
            -- Remove dead/missing cops
            table.remove(activeCops, i)
            dbg("Removed dead/invalid cop")
        else
            local copCoords = GetEntityCoords(cop)
            local dist = #(playerCoords - copCoords)
            
            -- If cop wandered too far, bring them back into combat
            if dist > engageRadius then
                dbg(("Cop too far (%.1fm), re-engaging"):format(dist))
                TaskCombatPed(cop, playerPed, 0, 16)
            else
                -- Check if cop is still in combat, if not re-engage
                if not IsPedInCombat(cop, playerPed) then
                    dbg("Cop not in combat, re-engaging")
                    TaskCombatPed(cop, playerPed, 0, 16)
                end
            end
        end
    end
end

-- Clear all cops
local function clearCops()
    for i, cop in ipairs(activeCops) do
        if DoesEntityExist(cop) then
            DeleteEntity(cop)
        end
    end
    activeCops = {}
    dbg("All cops cleared")
end

-- Main loop: Spawn and maintain aggressive police
CreateThread(function()
    while true do
        Wait(1000)
        
        local wanted = GetPlayerWantedLevel(PlayerId())
        
        if wanted >= 2 then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Spawn cops if needed
            if #activeCops < maxCops then
                local toSpawn = math.max(minCops, math.min(maxCops, wanted + 1)) - #activeCops
                
                if toSpawn > 0 then
                    dbg(("Spawning %d cops (wanted: %d, active: %d)"):format(toSpawn, wanted, #activeCops))
                    
                    for i = 1, toSpawn do
                        spawnAggressiveCop(playerCoords, playerPed)
                        Wait(300)  -- Small delay between spawns
                    end
                end
            end
            
            -- Maintain combat every second
            maintainCombat()
        else
            -- No wanted level: clear all cops
            if #activeCops > 0 then
                clearCops()
            end
            Wait(2000)  -- Less frequent checks when no wanted level
        end
    end
end)

-- Periodic aggressive re-engage (every 3 seconds)
CreateThread(function()
    while true do
        Wait(3000)
        
        if GetPlayerWantedLevel(PlayerId()) >= 2 and #activeCops > 0 then
            local playerPed = PlayerPedId()
            
            for _, cop in ipairs(activeCops) do
                if DoesEntityExist(cop) and not IsEntityDead(cop) then
                    -- Re-apply aggression to ensure they stay aggressive
                    if not IsPedInCombat(cop, playerPed) then
                        TaskCombatPed(cop, playerPed, 0, 16)
                    end
                end
            end
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearCops()
end)

dbg("Aggressive police system loaded - police will always engage at wanted >= 2")