local DEBUG = true

local Config = Config or {}
Config.Keys = Config.Keys or { Surrender = 38 }
Config.PoliceCount = Config.PoliceCount or 7
Config.MaxActiveCops = Config.MaxActiveCops or 24
Config.PoliceOffsets = Config.PoliceOffsets or {
    vector3(8.0, 4.0, 0.0),
    vector3(-6.0, 5.0, 0.0),
    vector3(4.0, -7.0, 0.0),
    vector3(-8.0, -5.0, 0.0),
    vector3(12.0, 0.0, 0.0),
    vector3(-12.0, 0.0, 0.0),
    vector3(6.0, 10.0, 0.0),
}
Config.PoliceModels = Config.PoliceModels or {
    "s_m_y_cop_01",
    "s_f_y_cop_01",
    "s_m_y_sheriff_01",
    "s_m_m_sheriff_01"
}
Config.ComplianceWindow = Config.ComplianceWindow or 10
Config.JailMinutesDefault = Config.JailMinutesDefault or 10
Config.MaxSpawnDistance = Config.MaxSpawnDistance or 40.0
Config.DisableAmbientCopsAfterSurrender = true
Config.UI = Config.UI or {
    ScenarioHint = "Du bist umzingelt! Drücke [E], um dich zu ergeben.",
    ArrestLogLines = {
        "Tatverdacht: Widerstand gegen die Staatsgewalt",
        "Maßnahme: Vorläufige Festnahme und Überstellung JVA",
        "Rechte: Aussageverweigerungsrecht, Recht auf Verteidiger"
    }
}
Config.JailPosition = Config.JailPosition or vector3(1690.5, 2565.9, 45.6)
Config.JailHeading = Config.JailHeading or 180.0
Config.JailReleasePosition = Config.JailReleasePosition or vector3(1845.0, 2585.0, 45.7)
Config.JailReleaseHeading = Config.JailReleaseHeading or 270.0
Config.JailName = Config.JailName or "JVA Bolingbroke"
Config.JailReason = Config.JailReason or "Du bist inhaftiert und verbüßt deine Strafe."

local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][DEBUG] %s"):format(table.concat(t, " ")))
end

-- State
local cops = {}
local scenarioActive = false
local canSurrender = false
local surrendered = false
local cuffed = false
local cuffing = false
local inJail = false
local jailTime = 0
local jailRequested = false
local complianceWindow = 0
local complianceCountdownThreadActive = false

-- === HILFSFUNKTIONEN ===

local function loadModel(model)
  local hash = type(model) == "number" and model or GetHashKey(model)
  if not IsModelInCdimage(hash) then dbg("Model not in CD image:", tostring(model)); return nil end
  RequestModel(hash)
  local to = GetGameTimer() + 10000
  while not HasModelLoaded(hash) do
    if GetGameTimer() > to then dbg("Model load timeout:", tostring(model)); return nil end
    Wait(10)
  end
  return hash
end

local function loadAnimDict(dict)
  RequestAnimDict(dict)
  local to = GetGameTimer() + 5000
  while not HasAnimDictLoaded(dict) do
    if GetGameTimer() > to then dbg("AnimDict load timeout:", dict); return false end
    Wait(10)
  end
  return true
end

local function randomPosAroundPlayer(minDist, maxDist)
  local ped = PlayerPedId()
  local p = GetEntityCoords(ped)
  local angle = math.random() * math.pi * 2
  local dist = math.random() * (maxDist - minDist) + minDist
  local nx = p.x + math.cos(angle) * dist
  local ny = p.y + math.sin(angle) * dist
  local nz = p.z
  local found, gz = GetGroundZFor_3dCoord(nx, ny, nz + 50.0, 0)
  if found then nz = gz end
  return vector3(nx, ny, nz)
end

local function clearCops()
  for _, ped in ipairs(cops) do
    if DoesEntityExist(ped) then
      SetPedKeepTask(ped, false)
      ClearPedTasksImmediately(ped)
      RemoveAllPedWeapons(ped, true)
      DeleteEntity(ped)
    end
  end
  cops = {}
  dbg("clearCops")
end

local function setAmbientCopsIgnore(toggle)
  SetPoliceIgnorePlayer(PlayerId(), toggle)
  dbg(toggle and "Ambient cops ignored" or "Ambient cops restored")
end

local function reactivatePolice()
  for _, ped in ipairs(cops) do
    if DoesEntityExist(ped) and not IsEntityDead(ped) then
      SetBlockingOfNonTemporaryEvents(ped, false)
      SetPedCanRagdoll(ped, true)
      SetPedCombatAbility(ped, 2)
      SetPedCombatRange(ped, 2)
      SetPedAlertness(ped, 3)
      SetPedFleeAttributes(ped, 0, false)
      SetPedRelationshipGroupHash(ped, GetHashKey("COP"))
      GiveWeaponToPed(ped, GetHashKey("WEAPON_PISTOL"), 120, false, true)
      TaskCombatPed(ped, PlayerPedId(), 0, 16)
    end
  end
  setAmbientCopsIgnore(false)
  dbg("reactivatePolice: cops can shoot again")
end

local function forceExitVehicleIfIn()
  local ped = PlayerPedId()
  if IsPedInAnyVehicle(ped, false) then
    local veh = GetVehiclePedIsIn(ped, false)
    TaskLeaveVehicle(ped, veh, 4160)
    dbg("Spieler war im Fahrzeug, wird rausgezogen.")
    local tries = 0
    while IsPedInAnyVehicle(ped, false) and tries < 50 do
      Wait(100)
      tries = tries + 1
    end
    if not IsPedInAnyVehicle(ped, false) then
      dbg("Spieler ist jetzt außerhalb des Fahrzeugs.")
    else
      dbg("Konnte Spieler nicht aus Fahrzeug holen!")
    end
  end
end

local function createCopAt(pos, modelName)
  local modelHash = loadModel(modelName)
  if not modelHash then return nil end
  local heading = GetEntityHeading(PlayerPedId()) + 180.0
  local ped = CreatePed(4, modelHash, pos.x, pos.y, pos.z, heading, true, true)
  if DoesEntityExist(ped) then
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedArmour(ped, 100)
    SetPedFleeAttributes(ped, 0, false)
    SetPedRelationshipGroupHash(ped, GetHashKey("COP"))
    RemoveAllPedWeapons(ped, true)
    SetPedSeeingRange(ped, 5.0)
    SetPedHearingRange(ped, 5.0)
    SetPedAlertness(ped, 0)
    SetPedCombatAbility(ped, 0)
    SetPedCombatRange(ped, 0)
    if SetCanAttackFriendly then SetCanAttackFriendly(ped, false, false) end
    TaskGoToEntity(ped, PlayerPedId(), -1, 2.5, 2.0, 1073741824, 0)
  end
  return ped
end

local function spawnCopsAroundPlayer()
  if not (Config and Config.PoliceOffsets and #Config.PoliceOffsets > 0) then dbg("No PoliceOffsets"); return end
  if not (Config and Config.PoliceModels and #Config.PoliceModels > 0) then dbg("No PoliceModels"); return end
  local maxActive = Config.MaxActiveCops
  local toSpawn = Config.PoliceCount
  toSpawn = math.min(toSpawn, maxActive - #cops)
  if toSpawn <= 0 then return end
  local ppos = GetEntityCoords(PlayerPedId())
  for i = 1, toSpawn do
    local off = Config.PoliceOffsets[((i - 1) % #Config.PoliceOffsets) + 1]
    local model = Config.PoliceModels[((i - 1) % #Config.PoliceModels) + 1]
    local pos = vector3(ppos.x + off.x, ppos.y + off.y, ppos.z + (off.z or 0))
    if #(pos - ppos) < 30.0 then
      pos = randomPosAroundPlayer(32.0, Config.MaxSpawnDistance)
    end
    local ped = createCopAt(pos, model)
    if ped then table.insert(cops, ped) end
    Wait(40)
  end
  dbg("spawned cops:", #cops)
end

function deescalateAllPolice()
  for _, ped in ipairs(cops) do
    if DoesEntityExist(ped) then
      ClearPedTasksImmediately(ped)
      SetBlockingOfNonTemporaryEvents(ped, true)
      RemoveAllPedWeapons(ped, true)
      TaskStandStill(ped, -1)
    end
  end
  if Config.DisableAmbientCopsAfterSurrender then
    setAmbientCopsIgnore(true)
  end
  dbg("deescalate all police")
end

local function showScenarioUI()
  TriggerEvent('mtj_arrest:nui:scenario', true, Config.UI.ScenarioHint, Config.ComplianceWindow)
  dbg("SendNUIMessage: scenarioToggle via event")
end

local function hideScenarioUI()
  TriggerEvent('mtj_arrest:nui:scenario', false)
  dbg("SendNUIMessage: scenarioToggle hide via event")
end

-- === FESTNAHME-ABLAUF ===
local function playCuffSequence()
  if cuffing or cuffed or inJail then
    dbg("playCuffSequence: guard (cuffing/cuffed/inJail) -> abort")
    return
  end
  cuffing = true
  forceExitVehicleIfIn()
  local player = PlayerPedId()
  local ppos = GetEntityCoords(player)
  local nearest, bestD = nil, 9999
  for _, ped in ipairs(cops) do
    if DoesEntityExist(ped) and not IsEntityDead(ped) then
      local d = #(GetEntityCoords(ped) - ppos)
      if d < bestD then nearest, bestD = ped, d end
    end
  end
  if not nearest or not DoesEntityExist(nearest) then
    nearest = nil
  end
  if nearest and DoesEntityExist(nearest) and bestD > 2.0 then
    TaskGoToEntity(nearest, player, -1, 1.2, 1.0, 1073741824, 0)
    local timeout = GetGameTimer() + 8000
    while #(GetEntityCoords(nearest) - GetEntityCoords(player)) > 2.2 and GetGameTimer() < timeout do
      Wait(100)
    end
  end
  if not loadAnimDict("random@arrests") then cuffing = false return end
  if not loadAnimDict("mp_arrest_paired") then cuffing = false return end
  TaskPlayAnim(player, "random@arrests", "idle_2_hands_up", 8.0, -8.0, 2500, 49, 0, false, false, false)
  Wait(2200)
  if nearest and DoesEntityExist(nearest) then
    TaskPlayAnim(nearest, "mp_arrest_paired", "cop_p2_back_left", 6.0, -4.0, 4500, 49, 0, false, false, false)
    TaskLookAtEntity(nearest, player, 5000, 2048, 3)
  end
  TaskPlayAnim(player, "random@arrests", "kneeling_arrest_idle", 8.0, -8.0, 4500, 49, 0, false, false, false)
  Wait(2000)
  SetEnableHandcuffs(player, true)
  FreezeEntityPosition(player, true)
  cuffed = true
  deescalateAllPolice()
  TriggerEvent('mtj_arrest:nui:arrest_log', true, Config.UI.ArrestLogLines)
  Wait(3000)
  TriggerEvent('mtj_arrest:nui:arrest_log', false)
  cuffing = false
  dbg("cuff sequence done")
  hideScenarioUI()
  -- Jail-Trigger immer ausführen
  if not inJail then
    jailRequested = true
    TriggerServerEvent('mtj_arrest:serverBeginJail', Config.JailMinutesDefault)
  end
end

-- === JAIL-TELEPORT / JAIL-TIMER ===
RegisterNetEvent('mtj_arrest:clientBeginJail')
AddEventHandler('mtj_arrest:clientBeginJail', function(minutes)
  local jailPos = Config.JailPosition
  local jailHeading = Config.JailHeading
  local player = PlayerPedId()
  DoScreenFadeOut(1000)
  Wait(1200)
  SetEntityCoords(player, jailPos.x, jailPos.y, jailPos.z)
  SetEntityHeading(player, jailHeading)
  FreezeEntityPosition(player, true)
  SetEnableHandcuffs(player, true)
  inJail = true

  -- HIER: WANTED LEVEL AUF NULL SETZEN
  if GetPlayerWantedLevel(PlayerId()) ~= 0 then
    SetPlayerWantedLevel(PlayerId(), 0, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    dbg("[Jail] Setze Wanted Level auf 0!")
  end

  local jailSeconds = math.floor((tonumber(minutes) or 10) * 60)
  dbg(("Spieler wurde ins Jail teleportiert für %d Minuten!"):format(minutes))
  DoScreenFadeIn(1000)
  -- Jail-Countdown-Timer UI
  CreateThread(function()
    while jailSeconds > 0 and inJail do
      jailTime = jailSeconds
      TriggerEvent('mtj_arrest:nui:jail', true, jailSeconds, Config.JailName, Config.JailReason)
      Wait(1000)
      jailSeconds = jailSeconds - 1
      TriggerEvent('mtj_arrest:nui:jail_tick', jailSeconds)
    end
    if inJail then
      -- Jailzeit vorbei: Entlassen UND vor das Tor teleportieren!
      TriggerEvent('mtj_arrest:nui:jail', false)
      FreezeEntityPosition(player, false)
      SetEnableHandcuffs(player, false)
      inJail = false
      jailTime = 0
      local release = Config.JailReleasePosition
      local heading = Config.JailReleaseHeading
      DoScreenFadeOut(1000)
      Wait(1100)
      SetEntityCoords(player, release.x, release.y, release.z)
      SetEntityHeading(player, heading)
      Wait(600)
      DoScreenFadeIn(1000)
      if ESX and ESX.ShowNotification then
        ESX.ShowNotification("Du bist nun wieder auf freiem Fuß!")
      end
      dbg("Jailzeit vorbei, Spieler vor das Gefängnis gesetzt!")
    end
  end)
end)

-- === SCENARIO-STATE ===

RegisterNetEvent('mtj_arrest:startScenario')
AddEventHandler('mtj_arrest:startScenario', function()
  if scenarioActive then
    dbg("startScenario: already active")
    return
  end
  if GetPlayerWantedLevel(PlayerId()) == 0 then
    dbg("startScenario abgebrochen: Kein Wanted Level!")
    return
  end
  
  -- Only spawn surrender cops if mode is "surrender", otherwise auto_cop_spawn handles it
  local policeMode = Config and Config.PoliceMode or "surrender"
  
  scenarioActive = true
  canSurrender = true
  jailRequested = false
  surrendered = false
  cuffed = false
  cuffing = false
  complianceWindow = Config.ComplianceWindow
  
  if policeMode == "surrender" then
    -- Spawn passive cops for surrender scenario
    clearCops()
    spawnCopsAroundPlayer()
    setAmbientCopsIgnore(true)
    showScenarioUI()
    dbg("startScenario: surrender mode - spawned passive cops with UI")
  else
    -- Aggressive mode: auto_cop_spawn handles everything, just show minimal UI
    showScenarioUI()
    dbg("startScenario: aggressive mode - auto_cop_spawn handles police")
  end
  
  if not complianceCountdownThreadActive then
    complianceCountdownThreadActive = true
    CreateThread(function()
      while scenarioActive and canSurrender and not surrendered and not cuffing and not cuffed and not inJail and complianceWindow > 0 do
        Wait(1000)
        if scenarioActive and canSurrender and not surrendered and not cuffing and not cuffed and not inJail then
          complianceWindow = complianceWindow - 1
          TriggerEvent('mtj_arrest:nui:scenario_tick', complianceWindow)
          if complianceWindow <= 0 then
            canSurrender = false
            reactivatePolice()
            dbg("Surrender window abgelaufen!")
          end
        else
          break
        end
      end
      complianceCountdownThreadActive = false
    end)
  end
end)

RegisterNetEvent('mtj_arrest:endScenario')
AddEventHandler('mtj_arrest:endScenario', function()
  scenarioActive = false
  canSurrender = false
  surrendered = false
  cuffed = false
  cuffing = false
  jailRequested = false
  complianceWindow = 0
  hideScenarioUI()
  
  local policeMode = Config and Config.PoliceMode or "surrender"
  if policeMode == "surrender" then
    -- Only clear cops in surrender mode (auto_cop_spawn manages its own in aggressive mode)
    clearCops()
    setAmbientCopsIgnore(false)
  end
  
  dbg("endScenario: scenario ended")
end)

-- === E-TASTE / SURRENDER ===

CreateThread(function()
  while true do
    Wait(0)
    if scenarioActive and canSurrender and not surrendered and not cuffing and not cuffed and not inJail then
      if IsControlJustPressed(0, Config.Keys.Surrender) then
        dbg("Surrender via E/KeyMapping")
        surrendered = true
        canSurrender = false
        playCuffSequence()
      end
    else
      Wait(250)
    end
  end
end)

-- === WANTED-LEVEL-ÜBERWACHUNG ===

CreateThread(function()
  while true do
    Wait(1000)
    if scenarioActive then
      if GetPlayerWantedLevel(PlayerId()) == 0 then
        dbg("Wanted Level = 0, beende Szenario!")
        TriggerEvent('mtj_arrest:endScenario')
      end
    else
      Wait(2000)
    end
  end
end)

-- === AUTOHIDE UI, falls Spieler stirbt oder despawnt ===

AddEventHandler('playerSpawned', function()
  scenarioActive = false
  canSurrender = false
  surrendered = false
  cuffed = false
  cuffing = false
  jailRequested = false
  complianceWindow = 0
  inJail = false
  FreezeEntityPosition(PlayerPedId(), false)
  SetEnableHandcuffs(PlayerPedId(), false)
  hideScenarioUI()
  clearCops()
  setAmbientCopsIgnore(false)
  dbg("playerSpawned: reset scenario state")
end)

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  scenarioActive = false
  canSurrender = false
  surrendered = false
  cuffed = false
  cuffing = false
  jailRequested = false
  complianceWindow = 0
  inJail = false
  FreezeEntityPosition(PlayerPedId(), false)
  SetEnableHandcuffs(PlayerPedId(), false)
  hideScenarioUI()
  clearCops()
  setAmbientCopsIgnore(false)
  dbg("onResourceStop: reset scenario state")
end)

print("[mtj_arrest][DEBUG] main.lua loaded — LAUFFÄHIG: E-Taste, Jail, AutoRausziehen, Polizei scharf, Wanted-Check.")