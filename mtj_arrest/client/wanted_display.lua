-- MTJ Arrest: Custom Wanted Level Display (GTA V Online Style)
local Config = Config or {}
local DEBUG = Config.Debug or false

local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][WANTED] %s"):format(table.concat(t, " ")))
end

local currentWantedLevel = 0
local lastWantedLevel = 0
local wantedLevelVisible = false

--- Updates the wanted level display
-- @param level number The current wanted level (0-5)
local function updateWantedDisplay(level)
  if level ~= lastWantedLevel then
    dbg("Wanted level changed:", lastWantedLevel, "->", level)
    
    SendNUIMessage({
      action = 'updateWanted',
      level = level,
      show = level > 0
    })
    
    -- Play sound effect when wanted level changes
    if level > lastWantedLevel then
      -- Wanted level increased
      PlaySoundFrontend(-1, "WANTED_RING", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
      
      -- Flash effect
      SetFlash(0, 0, 100, 200, 100)
    elseif level < lastWantedLevel and level == 0 then
      -- Wanted level cleared
      PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
    end
    
    lastWantedLevel = level
  end
  
  wantedLevelVisible = level > 0
end

--- Hides the native GTA wanted level display
local function hideNativeWantedLevel()
  HideHudComponentThisFrame(1) -- Wanted stars
end

-- Main thread to monitor wanted level
CreateThread(function()
  -- Cache config check
  local useCustomDisplay = Config.Effects and Config.Effects.EnableCustomWantedDisplay
  
  while true do
    Wait(100)
    
    local playerId = PlayerId()
    local wantedLevel = GetPlayerWantedLevel(playerId)
    
    if wantedLevel ~= currentWantedLevel then
      currentWantedLevel = wantedLevel
      updateWantedDisplay(wantedLevel)
    end
    
    -- Hide native wanted stars if custom display is enabled
    if useCustomDisplay then
      hideNativeWantedLevel()
    end
  end
end)

-- Event to manually update wanted display
RegisterNetEvent('mtj_arrest:updateWantedDisplay')
AddEventHandler('mtj_arrest:updateWantedDisplay', function(level)
  updateWantedDisplay(level)
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  
  SendNUIMessage({
    action = 'updateWanted',
    level = 0,
    show = false
  })
end)

dbg("Wanted level display system loaded")
