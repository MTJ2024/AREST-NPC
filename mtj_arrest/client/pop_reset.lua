-- Debug/Hotfix: Population & Cops schnell resetten
-- Befehle:
--  /mtj_popon  -> stellt Peds/Traffic/Cops sichtbar und aktiv
--  /mtj_popoff -> stellt Peds/Traffic auf 0 (zum Testen)
--  /mtj_cops   -> toggelt SetPoliceIgnorePlayer off/on (zeigt Status)

local forceThread = nil
local copsIgnored = false

local function setDensities(ped, veh, rndVeh, scenarioPed)
  ped = ped or 1.0
  veh = veh or 1.0
  rndVeh = rndVeh or 1.0
  scenarioPed = scenarioPed or 1.0

  -- Diese natives müssen pro Frame gesetzt werden:
  SetPedDensityMultiplierThisFrame(ped)
  SetScenarioPedDensityMultiplierThisFrame(scenarioPed, scenarioPed)
  SetVehicleDensityMultiplierThisFrame(veh)
  SetRandomVehicleDensityMultiplierThisFrame(rndVeh)
  SetParkedVehicleDensityMultiplierThisFrame(veh)
end

local function setRandomCops(enable)
  SetCreateRandomCops(enable)
  SetCreateRandomCopsNotOnScenarios(enable)
  SetCreateRandomCopsOnScenarios(enable)
end

local function ensureForSeconds(seconds, enable)
  if forceThread then
    TerminateThread(forceThread)
    forceThread = nil
  end
  local untilTime = GetGameTimer() + (math.max(1, seconds) * 1000)
  forceThread = Citizen.CreateThread(function()
    while GetGameTimer() < untilTime do
      if enable then
        setDensities(1.0, 1.0, 1.0, 1.0)
        setRandomCops(true)
      else
        setDensities(0.0, 0.0, 0.0, 0.0)
        setRandomCops(false)
      end
      Wait(0)
    end
    forceThread = nil
  end)
end

RegisterCommand('mtj_popon', function()
  print('[mtj_arrest][POP] Population ON (15s)')
  ensureForSeconds(15, true)
  -- Cops nicht ignorieren
  SetPoliceIgnorePlayer(PlayerId(), false)
  copsIgnored = false
end, false)

RegisterCommand('mtj_popoff', function()
  print('[mtj_arrest][POP] Population OFF (15s)')
  ensureForSeconds(15, false)
end, false)

RegisterCommand('mtj_cops', function()
  copsIgnored = not copsIgnored
  SetPoliceIgnorePlayer(PlayerId(), copsIgnored)
  print(('[mtj_arrest][POP] SetPoliceIgnorePlayer = %s'):format(tostring(copsIgnored)))
end, false)

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  -- Beim Stop wieder auf normal setzen
  SetPoliceIgnorePlayer(PlayerId(), false)
  setRandomCops(true)
end)