-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  github.com/MTJ2024/AREST-NPC                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- MTJ Arrest: Automatisches Spawnen von Police-NPCs ab 2 Sternen — skaliert nach Wanted-Level

local activeCops = {}
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
    -- ARREST_COP Gruppe verwenden (HATE statt COP=RESPECT)
    -- Gruppe wird von main.lua erstellt, Hash ist immer gleich
    SetPedRelationshipGroupHash(cop, GetHashKey("ARREST_COP"))
    SetPedCombatAbility(cop, 2)
    SetPedCombatRange(cop, 2)
    SetPedCombatMovement(cop, 2)
    SetPedAlertness(cop, 3)
    SetPedSeeingRange(cop, 100.0)
    SetPedHearingRange(cop, 100.0)
    SetPedAccuracy(cop, 40)
    SetPedFleeAttributes(cop, 0, false)
    SetBlockingOfNonTemporaryEvents(cop, false)
    SetCurrentPedWeapon(cop, GetHashKey("WEAPON_PISTOL"), true)
    SetPedKeepTask(cop, true)
    TaskCombatPed(cop, PlayerPedId(), 0, 16)
    table.insert(activeCops, cop)
end

-- Hilfsfunktion: Entfernt alle gespawnten Cops
local function clearCops()
    for i, cop in ipairs(activeCops) do
        if DoesEntityExist(cop) then
            DeleteEntity(cop)
        end
    end
    activeCops = {}
end

-- Wie viele Cops für dieses Wanted-Level (aus Config oder Fallback)
local function getMaxCopsForWanted(wanted)
    if Config and Config.CopsPerWantedLevel and Config.CopsPerWantedLevel[wanted] then
        return Config.CopsPerWantedLevel[wanted]
    end
    -- Fallback: wanted + 1, max 10
    return math.min(wanted + 1, 10)
end

-- Haupt-Loop
CreateThread(function()
    while true do
        Wait(1500)
        local wanted = GetPlayerWantedLevel(PlayerId())
        if wanted >= 2 then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local maxCops = getMaxCopsForWanted(wanted)
            -- Falls zu wenige Cops: Nachspawnen
            if #activeCops < maxCops then
                local toSpawn = maxCops - #activeCops
                for i=1, toSpawn do
                    spawnCopNearPlayer(playerCoords)
                    Wait(500)
                end
            end
            -- Remove dead cops from tracking list (entity deleted by main.lua deadBodies system)
            for i = #activeCops, 1, -1 do
                local cop = activeCops[i]
                if not DoesEntityExist(cop) or IsEntityDead(cop) then
                    table.remove(activeCops, i)
                end
            end
            -- Bestehende Cops neu bewaffnen und Kampf sicherstellen
            local pistolHash = GetHashKey("WEAPON_PISTOL")
            for _, cop in ipairs(activeCops) do
                if DoesEntityExist(cop) and not IsEntityDead(cop) then
                    if not HasPedGotWeapon(cop, pistolHash, false) then
                        GiveWeaponToPed(cop, pistolHash, 120, false, true)
                    end
                    if not IsPedInCombat(cop) then
                        TaskCombatPed(cop, PlayerPedId(), 0, 16)
                    end
                end
            end
        else
            -- Wanted-Level < 2: Alle Cops despawnen
            if #activeCops > 0 then
                clearCops()
            end
        end
    end
end)