-- client/simple_surrender_key.lua
-- Einfacher, verlässlicher Key-Handler für "E ergibt sich".
-- Lege Datei: mtj_arrest/client/simple_surrender_key.lua

local function isPolicePedModelHash(hash)
  if not Config or not Config.PoliceModels then return false end
  for _, name in ipairs(Config.PoliceModels) do
    if GetHashKey(name) == hash then
      return true
    end
  end
  return false
end

local function countNearbyPolicePeds(maxDist)
  maxDist = tonumber(maxDist) or 25.0
  local px, py, pz = table.unpack(GetEntityCoords(PlayerPedId(), true))
  local handle, ped = FindFirstPed()
  local success = handle and true or false
  local count = 0
  while success and ped and ped ~= 0 do
    if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
      local mx, my, mz = table.unpack(GetEntityCoords(ped, true))
      local dist = Vdist(px, py, pz, mx, my, mz)
      if dist <= maxDist then
        local mh = GetEntityModel(ped)
        if isPolicePedModelHash(mh) then
          count = count + 1
        else
          -- fallback heuristic: ped is in combat with player or is armed and aiming
          if IsPedInCombat(ped, PlayerPedId()) or (IsPedArmed(ped, 7) and HasEntityClearLosToEntity(ped, PlayerPedId(), 17)) then
            count = count + 1
          end
        end
      end
    end
    success, ped = FindNextPed(handle)
  end
  if handle then EndFindPed(handle) end
  return count
end

-- When E is pressed and there are cops nearby (or wanted > 0), trigger surrender flow
Citizen.CreateThread(function()
  while true do
    Wait(0)
    if IsControlJustReleased(0, 38) then -- E
      local wanted = GetPlayerWantedLevel(PlayerId()) or 0
      local nearby = countNearbyPolicePeds(25.0)
      if wanted > 0 or nearby > 0 then
        print(("[mtj_arrest][KEY] E pressed - wanted=%s nearby=%s -> firing surrender events"):format(tostring(wanted), tostring(nearby)))
        -- Local event for spawn logic (peaceful_spawn listens to this)
        TriggerEvent('mtj_arrest:localSurrender')
        -- Local handler that shows UI and notifies server
        TriggerEvent('mtj_arrest:playerSurrendered')
        -- Also notify server
        TriggerServerEvent('mtj_arrest:playerSurrendered')
      else
        print("[mtj_arrest][KEY] E pressed but no cops nearby and wanted == 0 - not surrendering")
      end
    end
  end
end)

-- Extra debug commands
RegisterCommand('mtj_force_surrender', function()
  print("[mtj_arrest][CMD] Forced surrender via command")
  TriggerEvent('mtj_arrest:localSurrender')
  TriggerEvent('mtj_arrest:playerSurrendered')
  TriggerServerEvent('mtj_arrest:playerSurrendered')
end, false)