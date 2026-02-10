-- MTJ Arrest: Automatisches Spawnen von 2-7 Police-NPCs ab 2 Sternen im Radius um den Spieler

local Config = Config or {}
local DEBUG = Config.Debug
if DEBUG == nil then DEBUG = false end -- Default to false if not configured

local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][AUTO_COP] %s"):format(table.concat(t, " ")))
end

local activeCops = {}
local maxCops = 7
local minCops = 2
local spawnRadiusMin = 20.0
local spawnRadiusMax = 40.0
local policeModels = {
    "s_m_y_cop_01", "s_f_y_cop_01", "s_m_y_sheriff_01", "s_m_m_sheriff_01"
}

-- Hilfsfunktion: Police-NPC spawnen
local function spawnCopNearPlayer(playerCoords)
    local angle = math.random() * 2 * math.pi
    local dist = math.random() * (spawnRadiusMax - spawnRadiusMin) + spawnRadiusMin
    local x = playerCoords.x + math.cos(angle) * dist
    local y = playerCoords.y + math.sin(angle) * dist
    local z = playerCoords.z + 0.5
    local model = policeModels[math.random(1, #policeModels)]
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(10) end
    local cop = CreatePed(6, modelHash, x, y, z, 0.0, true, true)
    SetEntityAsMissionEntity(cop, true, true)
    GiveWeaponToPed(cop, GetHashKey("WEAPON_PISTOL"), 120, false, true)
    SetPedRelationshipGroupHash(cop, GetHashKey("COP"))
    SetPedCombatAbility(cop, 2)
    SetPedCombatRange(cop, 2)
    SetBlockingOfNonTemporaryEvents(cop, true)
    TaskCombatPed(cop, PlayerPedId(), 0, 16)
    table.insert(activeCops, cop)
    dbg("Spawned cop:", model, "at distance:", math.floor(dist))
end

-- Hilfsfunktion: Entfernt alle gespawnten Cops
local function clearCops()
    for i, cop in ipairs(activeCops) do
        if DoesEntityExist(cop) then
            DeleteEntity(cop)
        end
    end
    activeCops = {}
    dbg("Cleared all cops")
end

-- Haupt-Loop
CreateThread(function()
    dbg("Auto cop spawn system started")
    local lastWanted = 0
    
    while true do
        Wait(1500)
        local wanted = GetPlayerWantedLevel(PlayerId())
        
        -- Debug when wanted level changes
        if wanted ~= lastWanted then
            dbg("Wanted level changed:", lastWanted, "->", wanted)
            lastWanted = wanted
        end
        
        if wanted >= 2 then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            -- Falls zu wenige Cops: Nachspawnen
            if #activeCops < maxCops then
                local toSpawn = math.max(minCops, math.min(maxCops, wanted + 1)) - #activeCops
                dbg("Spawning", toSpawn, "cops (wanted:", wanted, "active:", #activeCops, ")")
                for i=1, toSpawn do
                    spawnCopNearPlayer(playerCoords)
                    Wait(500)
                end
            end
            -- Entferne tote Cops aus Liste
            for i = #activeCops, 1, -1 do
                if not DoesEntityExist(activeCops[i]) or IsEntityDead(activeCops[i]) then
                    table.remove(activeCops, i)
                end
            end
        else
            -- Wanted-Level < 2: Alle Cops despawnen
            if #activeCops > 0 then
                dbg("Wanted < 2, clearing cops")
                clearCops()
            end
        end
    end
end)

dbg("Auto cop spawn loaded")