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
    -- Collision laden fuer zuverlaessige Bodenhoehe
    RequestCollisionAtCoord(x, y, z)
    Wait(100)
    local gFound, gz = GetGroundZFor_3dCoord(x, y, z + 10.0, false)
    if gFound then
        z = gz + 0.5
    end
    -- Fallback: playerCoords.z + 0.5 (bereits oben gesetzt)
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

-- Haupt-Loop (koordiniert mit main.lua ueber globale Funktionen)
CreateThread(function()
    while true do
        Wait(1500)

        -- Waehrend Vorwarnung: NICHT spawnen (main.lua braucht Kontrolle)
        -- Waehrend aktivem Szenario aber NICHT Kampfphase: main.lua uebernimmt
        -- Waehrend Kampfphase: auto_cop_spawn darf supplementaer spawnen
        local vwActive = (IsVorwarnungActive and IsVorwarnungActive()) or false
        local scenActive = (IsArrestScenarioActive and IsArrestScenarioActive()) or false
        local combatActive = (IsCombatPhaseActive and IsCombatPhaseActive()) or false
        if vwActive or (scenActive and not combatActive) then
            -- Tote entfernen, aber NICHT nachspawnen
            for i = #activeCops, 1, -1 do
                local cop = activeCops[i]
                if not DoesEntityExist(cop) or IsEntityDead(cop) then
                    table.remove(activeCops, i)
                end
            end
            goto continue
        end

        local wanted = GetPlayerWantedLevel(PlayerId())
        -- Fallback: main.lua's lastKnownWanted (GTA setzt Wanted manchmal kurz auf 0)
        if wanted < 2 then
            local mainWanted = (GetMainLuaLastKnownWanted and GetMainLuaLastKnownWanted()) or 0
            if mainWanted >= 2 then wanted = mainWanted end
        end
        if wanted >= 2 then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            -- Tote und zu weit entfernte Cops entfernen (100m Radius)
            for i = #activeCops, 1, -1 do
                local cop = activeCops[i]
                if not DoesEntityExist(cop) or IsEntityDead(cop) then
                    table.remove(activeCops, i)
                elseif #(GetEntityCoords(cop) - playerCoords) > 100.0 then
                    DeleteEntity(cop)
                    table.remove(activeCops, i)
                end
            end

            -- Globales Limit pruefen: main.lua Cops + eigene Cops < MaxActiveCops
            local mainCops = (GetMainLuaAliveCopCount and GetMainLuaAliveCopCount()) or 0
            local maxGlobal = (Config and Config.MaxActiveCops) or 20
            local maxForWanted = getMaxCopsForWanted(wanted)
            local totalAlive = mainCops + #activeCops
            local canSpawn = math.min(maxForWanted - #activeCops, maxGlobal - totalAlive)

            if canSpawn > 0 then
                -- Max 2 pro Tick (statt alle auf einmal)
                for i = 1, math.min(canSpawn, 2) do
                    spawnCopNearPlayer(playerCoords)
                    Wait(500)
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
        ::continue::
    end
end)