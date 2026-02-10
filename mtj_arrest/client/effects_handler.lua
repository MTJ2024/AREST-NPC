-- MTJ Arrest: Effects Event Handlers
-- This file listens to effect events and triggers the appropriate functions

local DEBUG = true

local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][EFFECTS_HANDLER] %s"):format(table.concat(t, " ")))
end

-- Screen Effects
RegisterNetEvent('mtj_arrest:effects:applyArrestEffects')
AddEventHandler('mtj_arrest:effects:applyArrestEffects', function()
  dbg("Triggering arrest screen effects")
  ApplyArrestScreenEffects()
end)

RegisterNetEvent('mtj_arrest:effects:applySurrenderEffects')
AddEventHandler('mtj_arrest:effects:applySurrenderEffects', function()
  dbg("Triggering surrender screen effects")
  ApplySurrenderScreenEffects()
end)

RegisterNetEvent('mtj_arrest:effects:policeArrival')
AddEventHandler('mtj_arrest:effects:policeArrival', function(coords)
  dbg("Triggering police arrival effects")
  ApplyPoliceArrivalEffects(coords)
end)

-- Sound Effects
RegisterNetEvent('mtj_arrest:effects:playRadioChatter')
AddEventHandler('mtj_arrest:effects:playRadioChatter', function()
  dbg("Playing radio chatter")
  PlayPoliceRadioChatter()
end)

RegisterNetEvent('mtj_arrest:effects:playArrestSound')
AddEventHandler('mtj_arrest:effects:playArrestSound', function()
  dbg("Playing arrest sound")
  PlayArrestSound()
end)

RegisterNetEvent('mtj_arrest:effects:playSurrenderSound')
AddEventHandler('mtj_arrest:effects:playSurrenderSound', function()
  dbg("Playing surrender sound")
  PlaySurrenderSound()
end)

RegisterNetEvent('mtj_arrest:effects:playSiren')
AddEventHandler('mtj_arrest:effects:playSiren', function()
  dbg("Playing siren sound")
  PlaySirenSound()
end)

RegisterNetEvent('mtj_arrest:effects:playCuffingSound')
AddEventHandler('mtj_arrest:effects:playCuffingSound', function()
  dbg("Playing cuffing sound")
  PlayCuffingSound()
end)

-- Camera Effects
RegisterNetEvent('mtj_arrest:effects:createArrestCamera')
AddEventHandler('mtj_arrest:effects:createArrestCamera', function(targetPed, copPed)
  dbg("Creating arrest camera")
  CreateArrestCamera(targetPed, copPed)
end)

RegisterNetEvent('mtj_arrest:effects:destroyArrestCamera')
AddEventHandler('mtj_arrest:effects:destroyArrestCamera', function()
  dbg("Destroying arrest camera")
  DestroyArrestCamera()
end)

-- Slow Motion
RegisterNetEvent('mtj_arrest:effects:enableSlowMotion')
AddEventHandler('mtj_arrest:effects:enableSlowMotion', function(duration, strength)
  dbg("Enabling slow motion")
  EnableSlowMotion(duration, strength)
end)

RegisterNetEvent('mtj_arrest:effects:disableSlowMotion')
AddEventHandler('mtj_arrest:effects:disableSlowMotion', function()
  dbg("Disabling slow motion")
  DisableSlowMotion()
end)

-- Particle Effects
RegisterNetEvent('mtj_arrest:effects:createDustEffect')
AddEventHandler('mtj_arrest:effects:createDustEffect', function(coords)
  dbg("Creating dust effect")
  CreateArrestDustEffect(coords)
end)

RegisterNetEvent('mtj_arrest:effects:createPoliceFlashingLights')
AddEventHandler('mtj_arrest:effects:createPoliceFlashingLights', function(coords, duration)
  dbg("Creating police flashing lights")
  CreatePoliceFlashingLights(coords, duration)
end)

-- Helicopter Effects
RegisterNetEvent('mtj_arrest:effects:createHelicopterSpotlight')
AddEventHandler('mtj_arrest:effects:createHelicopterSpotlight', function(targetPed)
  dbg("Creating helicopter spotlight")
  CreateHelicopterSpotlight(targetPed)
end)

RegisterNetEvent('mtj_arrest:effects:stopHelicopterSpotlight')
AddEventHandler('mtj_arrest:effects:stopHelicopterSpotlight', function()
  dbg("Stopping helicopter spotlight")
  StopHelicopterSpotlight()
end)

-- Cleanup
RegisterNetEvent('mtj_arrest:effects:clearAll')
AddEventHandler('mtj_arrest:effects:clearAll', function()
  dbg("Clearing all effects")
  ClearAllParticleEffects()
  DestroyArrestCamera()
  DisableSlowMotion()
  StopHelicopterSpotlight()
end)

dbg("Effects event handlers loaded")
