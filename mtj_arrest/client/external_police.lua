-- mtj_arrest: Externe Polizei Erkennung + Auto-Start des Szenarios
-- Erkennt NPC-Polizei (RelationGroups/Modelle) und optional Spieler-Cops (ESX-Job).
-- Triggert automatisch 'mtj_arrest:startScenario', sobald nahe genug.

local DEBUG = true
local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][EXT] %s"):format(table.concat(t, " ")))
end

-- Defaults, falls Config-Einträge fehlen
local function cfg()
  local c = Config and Config.ExternalPolice or {}
  c.enabled = (c.enabled ~= false)
  c.autoStartScenario = (c.autoStartScenario ~= false)
  c.scanInterval = c.scanInterval or 600
  c.scanRadius = c.scanRadius or 80.0
  c.relationshipGroups = c.relationshipGroups or { "COP", "SECURITY_GUARD" }
  c.players = c.players or { enabled = true, jobs = { "police", "sheriff", "fib" }, scanInterval = 900, maxRadius = 150.0 }
  return c
end

local function enumeratePeds()
  return coroutine.wrap(function()
    local handle, ped = FindFirstPed()
    if handle == -1 then return end
    local ok = true
    repeat
      coroutine.yield(ped)
      ok, ped = FindNextPed(handle)
    until not ok
    EndFindPed(handle)
  end)
end

local function isExternalPolicePed(ped)
  if not ped or ped == 0 then return false end
  if ped == PlayerPedId() then return false end
  if IsPedDeadOrDying(ped, true) then return false end
  if IsPedAPlayer(ped) then return false end

  local c = cfg()

  -- RelationshipGroups prüfen
  if c.relationshipGroups and #c.relationshipGroups > 0 then
    local grpHash = GetPedRelationshipGroupHash(ped)
    for _, grp in ipairs(c.relationshipGroups) do
      if grpHash == GetHashKey(grp) then
        return true
      end
    end
  end

  -- Modelle prüfen
  if c.models and #c.models > 0 then
    local mdl = GetEntityModel(ped)
    for _, name in ipairs(c.models) do
      if mdl == GetHashKey(name) then
        return true
      end
    end
  end

  return false
end

local function getNearestExternalPoliceNPCDist(maxRadius)
  maxRadius = maxRadius or cfg().scanRadius
  local ply = PlayerPedId()
  local ppos = GetEntityCoords(ply)
  local best = 999999.0

  for ped in enumeratePeds() do
    if isExternalPolicePed(ped) then
      local d = #(GetEntityCoords(ped) - ppos)
      if d < best then best = d end
    end
  end

  return best < 999999.0 and best or 999999.0
end

-- Spieler-Cops Distanz (vom Server geliefert)
local nearestPolicePlayerDist = 999999.0
RegisterNetEvent('mtj_arrest:cl:nearestPoliceDist', function(dist)
  if type(dist) == "number" then
    nearestPolicePlayerDist = dist
  end
end)

-- Server-Polling für Spieler-Cops
CreateThread(function()
  local c = cfg()
  if not c.enabled or not (c.players and c.players.enabled) then return end
  while true do
    TriggerServerEvent('mtj_arrest:sv:getNearestPoliceDist', c.players.maxRadius or 150.0, c.players.jobs or { "police" })
    Wait(c.players.scanInterval or 900)
  end
end)

-- Auto-Start des Szenarios, wenn externe Polizei (NPC oder Spieler) in Reichweite
CreateThread(function()
  local c = cfg()
  if not c.enabled or not c.autoStartScenario then return end

  local lastAnnounce = 0
  while true do
    local distNPC = getNearestExternalPoliceNPCDist(c.scanRadius)
    local distPLY = nearestPolicePlayerDist
    local nearest = math.min(distNPC, distPLY)

    local compliance = (Config and Config.ComplianceDistance) or 25.0
    if nearest <= compliance then
      local now = GetGameTimer()
      if now - lastAnnounce > 1500 then
        dbg(("External police near (%.1fm) -> startScenario"):format(nearest))
        lastAnnounce = now
      end
      -- main.lua ignoriert Doppelaufrufe (prüft scenarioActive intern)
      TriggerEvent('mtj_arrest:startScenario')
      Wait(2000)
    else
      Wait(c.scanInterval)
    end
  end
end)

-- Debug-Kommando
RegisterCommand('mtj_extpolice_debug', function()
  local c = cfg()
  local dNPC = getNearestExternalPoliceNPCDist(c.scanRadius)
  local dPLY = nearestPolicePlayerDist
  print(("[mtj_arrest][EXT] Debug distances -> NPC: %.2fm | PlayerCops: %.2fm"):format(dNPC, dPLY))
end, false)