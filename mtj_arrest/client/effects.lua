-- MTJ Arrest: Enhanced Visual & Audio Effects System
local DEBUG = true

local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][EFFECTS] %s"):format(table.concat(t, " ")))
end

-- ===== PARTICLE EFFECTS =====
local activeParticles = {}

function StartParticleEffect(particleName, coords, scale, duration)
    UseParticleFxAssetNextCall("core")
    local fx = StartParticleFxLoopedAtCoord(particleName, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, scale or 1.0, false, false, false, false)
    table.insert(activeParticles, fx)
    
    if duration then
        SetTimeout(duration, function()
            StopParticleFxLooped(fx, false)
        end)
    end
    
    return fx
end

function ClearAllParticleEffects()
    for _, fx in ipairs(activeParticles) do
        StopParticleFxLooped(fx, false)
    end
    activeParticles = {}
end

-- ===== SCREEN EFFECTS =====
function ApplyArrestScreenEffects()
    dbg("Applying arrest screen effects")
    
    -- Slow motion during arrest
    SetTimecycleModifier("Drunk")
    SetTimecycleModifierStrength(0.5)
    
    -- Camera shake for dramatic effect
    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.3)
    
    -- Clear after duration
    SetTimeout(3000, function()
        ClearTimecycleModifier()
        StopGameplayCamShaking(true)
    end)
end

function ApplySurrenderScreenEffects()
    dbg("Applying surrender screen effects")
    
    -- Brief slow motion
    SetTimecycleModifier("hud_def_blur")
    SetTimecycleModifierStrength(0.3)
    
    SetTimeout(2000, function()
        ClearTimecycleModifier()
    end)
end

function ApplyPoliceArrivalEffects(coords)
    dbg("Police arrival effects at coords")
    
    -- Screen flash
    SetFlash(0, 0, 100, 500, 100)
    
    -- Camera shake
    ShakeGameplayCam("MEDIUM_EXPLOSION_SHAKE", 0.2)
    
    -- Dust particles at spawn points
    if coords then
        UseParticleFxAssetNextCall("core")
        StartParticleFxNonLoopedAtCoord("ent_dst_dust", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 2.0, false, false, false)
    end
end

-- ===== SOUND EFFECTS =====
local activeSounds = {}

function PlayPoliceRadioChatter()
    dbg("Playing police radio chatter")
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
    
    SetTimeout(1000, function()
        PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
    end)
end

function PlayArrestSound()
    dbg("Playing arrest sound")
    PlaySoundFrontend(-1, "Arrest_Player", "GTAO_Adversary_Capture_Boss_Soundset", true)
end

function PlaySurrenderSound()
    dbg("Playing surrender sound")
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end

function PlaySirenSound()
    dbg("Playing siren approach sound")
    PlaySoundFrontend(-1, "POLICE_SCANNER_QUICK", "CAMERA_FLASH_SOUNDSET", true)
end

function PlayCuffingSound()
    dbg("Playing cuffing sound")
    PlaySoundFrontend(-1, "Cuff_Detain", "DLC_EXEC_APT_SIM_APARTMENT_SOUNDS", true)
end

-- ===== CAMERA EFFECTS =====
local arrestCam = nil

function CreateArrestCamera(targetPed, copPed)
    dbg("Creating arrest camera")
    
    local playerCoords = GetEntityCoords(targetPed)
    local camCoords = vector3(playerCoords.x + 3.0, playerCoords.y + 3.0, playerCoords.z + 1.0)
    
    arrestCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(arrestCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtEntity(arrestCam, targetPed, 0.0, 0.0, 0.0, true)
    SetCamFov(arrestCam, 50.0)
    
    -- Smooth transition
    RenderScriptCams(true, true, 1500, true, false)
    
    return arrestCam
end

function DestroyArrestCamera()
    if arrestCam then
        dbg("Destroying arrest camera")
        RenderScriptCams(false, true, 1500, true, false)
        DestroyCam(arrestCam, false)
        arrestCam = nil
    end
end

-- ===== SLOW MOTION EFFECTS =====
local slowMotionActive = false

function EnableSlowMotion(duration, strength)
    if slowMotionActive then return end
    
    dbg("Enabling slow motion")
    slowMotionActive = true
    
    -- Dramatic slow motion
    SetTimeScale(strength or 0.4)
    
    if duration then
        SetTimeout(duration, function()
            DisableSlowMotion()
        end)
    end
end

function DisableSlowMotion()
    if not slowMotionActive then return end
    
    dbg("Disabling slow motion")
    SetTimeScale(1.0)
    slowMotionActive = false
end

-- ===== POLICE LIGHTS EFFECTS =====
function CreatePoliceFlashingLights(coords, duration)
    dbg("Creating police flashing lights")
    
    local lightThread = CreateThread(function()
        local endTime = GetGameTimer() + (duration or 5000)
        local toggle = false
        
        while GetGameTimer() < endTime do
            toggle = not toggle
            
            if toggle then
                DrawLightWithRange(coords.x + 2.0, coords.y, coords.z + 1.0, 255, 0, 0, 10.0, 0.8)
                DrawLightWithRange(coords.x - 2.0, coords.y, coords.z + 1.0, 0, 0, 255, 10.0, 0.8)
            else
                DrawLightWithRange(coords.x + 2.0, coords.y, coords.z + 1.0, 0, 0, 255, 10.0, 0.8)
                DrawLightWithRange(coords.x - 2.0, coords.y, coords.z + 1.0, 255, 0, 0, 10.0, 0.8)
            end
            
            Wait(150)
        end
    end)
end

-- ===== SMOKE/DUST EFFECTS =====
function CreateArrestDustEffect(coords)
    dbg("Creating arrest dust effect")
    
    RequestNamedPtfxAsset("core")
    while not HasNamedPtfxAssetLoaded("core") do
        Wait(10)
    end
    
    UseParticleFxAssetNextCall("core")
    local fx = StartParticleFxNonLoopedAtCoord("ent_dst_dust", coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 3.0, false, false, false)
end

-- ===== HELICOPTER SPOTLIGHT =====
local helicopterSpotlight = nil

function CreateHelicopterSpotlight(targetPed)
    dbg("Creating helicopter spotlight")
    
    if helicopterSpotlight then return end
    
    CreateThread(function()
        helicopterSpotlight = true
        local duration = 10000
        local startTime = GetGameTimer()
        
        while helicopterSpotlight and (GetGameTimer() - startTime) < duration do
            if DoesEntityExist(targetPed) then
                local coords = GetEntityCoords(targetPed)
                DrawSpotLight(coords.x, coords.y, coords.z + 50.0, 0.0, 0.0, -1.0, 255, 255, 255, 100.0, 10.0, 0.0, 20.0, 1.0)
                DrawLightWithRange(coords.x, coords.y, coords.z + 2.0, 255, 255, 255, 15.0, 5.0)
            end
            Wait(0)
        end
        
        helicopterSpotlight = nil
    end)
end

function StopHelicopterSpotlight()
    helicopterSpotlight = nil
end

-- ===== EXPORT FUNCTIONS =====
exports('ApplyArrestScreenEffects', ApplyArrestScreenEffects)
exports('ApplySurrenderScreenEffects', ApplySurrenderScreenEffects)
exports('ApplyPoliceArrivalEffects', ApplyPoliceArrivalEffects)
exports('PlayPoliceRadioChatter', PlayPoliceRadioChatter)
exports('PlayArrestSound', PlayArrestSound)
exports('PlaySurrenderSound', PlaySurrenderSound)
exports('PlaySirenSound', PlaySirenSound)
exports('PlayCuffingSound', PlayCuffingSound)
exports('CreateArrestCamera', CreateArrestCamera)
exports('DestroyArrestCamera', DestroyArrestCamera)
exports('EnableSlowMotion', EnableSlowMotion)
exports('DisableSlowMotion', DisableSlowMotion)
exports('CreatePoliceFlashingLights', CreatePoliceFlashingLights)
exports('CreateArrestDustEffect', CreateArrestDustEffect)
exports('CreateHelicopterSpotlight', CreateHelicopterSpotlight)
exports('StopHelicopterSpotlight', StopHelicopterSpotlight)
exports('ClearAllParticleEffects', ClearAllParticleEffects)

dbg("Effects system loaded")
