-- mtj_arrest: Server-Helper zur Erkennung von Spieler-Cops in der Nähe
-- Sendet Distanz zum nächsten Spieler mit ESX-Job (z. B. police/sheriff) an den Client.

local DEBUG = false
local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][SV-EXT] %s"):format(table.concat(t, " ")))
end

local ESX
CreateThread(function()
  local start = GetGameTimer()
  while not ESX and (GetGameTimer() - start) < 10000 do
    pcall(function()
      if exports and exports['es_extended'] and exports['es_extended'].getSharedObject then
        ESX = exports['es_extended']:getSharedObject()
      end
    end)
    Wait(200)
  end
  if ESX then dbg("ESX loaded for police player scan.") else dbg("Warning: ESX not found; player police scan disabled.") end
end)

local function isJobInList(jobName, jobs)
  if type(jobs) ~= "table" then return false end
  for _, j in ipairs(jobs) do
    if tostring(jobName) == tostring(j) then return true end
  end
  return false
end

RegisterNetEvent('mtj_arrest:sv:getNearestPoliceDist', function(maxRadius, jobList)
  local src = source
  if not ESX then
    TriggerClientEvent('mtj_arrest:cl:nearestPoliceDist', src, 999999.0)
    return
  end

  maxRadius = tonumber(maxRadius) or 150.0
  if maxRadius < 1.0 then maxRadius = 150.0 end

  local srcPed = GetPlayerPed(src)
  if not srcPed or srcPed == 0 then
    TriggerClientEvent('mtj_arrest:cl:nearestPoliceDist', src, 999999.0)
    return
  end
  local sx, sy, sz = table.unpack(GetEntityCoords(srcPed) or vector3(0,0,0))

  local nearest = 999999.0

  local ok, list = pcall(function()
    if ESX.GetExtendedPlayers then
      return ESX.GetExtendedPlayers()
    else
      local ids = ESX.GetPlayers()
      local players = {}
      for _, id in ipairs(ids) do
        local xp = ESX.GetPlayerFromId(id)
        if xp then players[#players+1] = xp end
      end
      return players
    end
  end)

  if not ok or not list then
    TriggerClientEvent('mtj_arrest:cl:nearestPoliceDist', src, 999999.0)
    return
  end

  for _, xPlayer in pairs(list) do
    local pid = xPlayer.source or xPlayer.playerId
    if pid and pid ~= src then
      local jobName = (xPlayer.job and xPlayer.job.name) or (xPlayer.getJob and xPlayer.getJob().name)
      if isJobInList(jobName, jobList or { "police" }) then
        local ped = GetPlayerPed(pid)
        if ped and ped ~= 0 then
          local px, py, pz = table.unpack(GetEntityCoords(ped) or vector3(0,0,0))
          local dx, dy, dz = (sx - px), (sy - py), (sz - pz)
          local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
          if dist < nearest then nearest = dist end
        end
      end
    end
  end

  if nearest > maxRadius then nearest = 999999.0 end
  TriggerClientEvent('mtj_arrest:cl:nearestPoliceDist', src, nearest)
  dbg(("Player %d requested nearest police dist: %.2f m (max %.0f)"):format(src, nearest, maxRadius))
end)