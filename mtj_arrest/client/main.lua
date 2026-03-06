-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
local DEBUG = false

local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][DEBUG] %s"):format(table.concat(t, " ")))
end

local function nativeNotify(text, ntype) end -- deaktiviert: nur Einsatz- und Knast-Anzeige

-- === GTA NATIVE 2D TEXT FALLBACK (100% zuverlaessig, kein NUI noetig) ===
-- Zeichnet Texte direkt auf den Bildschirm als Backup falls NUI ausfaellt
local nativeHudLines = {}   -- { {text=, expire=, r=, g=, b=} }
local nativeHudPersist = {} -- { key = {text=, r=, g=, b=} } (dauerhaft bis entfernt)

local function nativeHudShow(text, durationSec, r, g, b)
  table.insert(nativeHudLines, {
    text = tostring(text or ""),
    expire = GetGameTimer() + ((durationSec or 8) * 1000),
    r = r or 255, g = g or 255, b = b or 255
  })
end

local function nativeHudSet(key, text, r, g, b)
  if text then
    nativeHudPersist[key] = { text = tostring(text), r = r or 255, g = g or 255, b = b or 255 }
  else
    nativeHudPersist[key] = nil
  end
end

local function nativeHudClear()
  nativeHudLines = {}
  nativeHudPersist = {}
end

-- Native Text Draw Helper (GTA V)
local function drawText2D(text, x, y, scale, r, g, b, a)
  SetTextFont(4)
  SetTextProportional(true)
  SetTextScale(scale, scale)
  SetTextColour(r or 255, g or 255, b or 255, a or 255)
  SetTextDropShadow()
  SetTextOutline()
  SetTextEntry("STRING")
  AddTextComponentString(tostring(text))
  DrawText(x, y)
end

-- nativeHud Render-Thread deaktiviert: gleichzeitige GTA-Text-Native-Aufrufe aus
-- mehreren Wait(0)-Threads (nativeHud + DrawText3D im NPC-Loop) korruptierten
-- gegenseitig den Draw-Zustand und verursachten Crashes. NUI übernimmt alle Anzeigen.

-- State
local playerName = GetPlayerName(PlayerId()) or "Unbekannt"
local cops = {}
local scenarioActive = false
local canSurrender = false
local surrendered = false
local cuffed = false
local cuffing = false

-- === VOLLSTAENDIGE GTA V WAFFEN-HASHLISTE ===
-- Entfernt ALLE Waffen vom Ped (Client-seitig), nicht nur was ESX/ox kennt
local ALL_WEAPON_HASHES = {
  -- Nahkampf
  "WEAPON_DAGGER", "WEAPON_BAT", "WEAPON_BOTTLE", "WEAPON_CROWBAR",
  "WEAPON_UNARMED", "WEAPON_FLASHLIGHT", "WEAPON_GOLFCLUB", "WEAPON_HAMMER",
  "WEAPON_HATCHET", "WEAPON_KNUCKLE", "WEAPON_KNIFE", "WEAPON_MACHETE",
  "WEAPON_SWITCHBLADE", "WEAPON_NIGHTSTICK", "WEAPON_WRENCH", "WEAPON_BATTLEAXE",
  "WEAPON_POOLCUE", "WEAPON_STONE_HATCHET", "WEAPON_CANDYCANE",
  -- Pistolen
  "WEAPON_PISTOL", "WEAPON_PISTOL_MK2", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL",
  "WEAPON_STUNGUN", "WEAPON_PISTOL50", "WEAPON_SNSPISTOL", "WEAPON_SNSPISTOL_MK2",
  "WEAPON_HEAVYPISTOL", "WEAPON_VINTAGEPISTOL", "WEAPON_FLAREGUN", "WEAPON_MARKSMANPISTOL",
  "WEAPON_REVOLVER", "WEAPON_REVOLVER_MK2", "WEAPON_DOUBLEACTION", "WEAPON_RAYPISTOL",
  "WEAPON_CERAMICPISTOL", "WEAPON_NAVYREVOLVER", "WEAPON_GADGETPISTOL",
  "WEAPON_STUNGUN_MP", "WEAPON_PISTOLXM3", "WEAPON_TECPISTOL",
  -- SMGs
  "WEAPON_MICROSMG", "WEAPON_SMG", "WEAPON_SMG_MK2", "WEAPON_ASSAULTSMG",
  "WEAPON_COMBATPDW", "WEAPON_MACHINEPISTOL", "WEAPON_MINISMG", "WEAPON_RAYCARBINE",
  -- Schrotflinten
  "WEAPON_PUMPSHOTGUN", "WEAPON_PUMPSHOTGUN_MK2", "WEAPON_SAWNOFFSHOTGUN",
  "WEAPON_ASSAULTSHOTGUN", "WEAPON_BULLPUPSHOTGUN", "WEAPON_MUSKET",
  "WEAPON_HEAVYSHOTGUN", "WEAPON_DBSHOTGUN", "WEAPON_AUTOSHOTGUN",
  "WEAPON_COMBATSHOTGUN",
  -- Sturmgewehre
  "WEAPON_ASSAULTRIFLE", "WEAPON_ASSAULTRIFLE_MK2", "WEAPON_CARBINERIFLE",
  "WEAPON_CARBINERIFLE_MK2", "WEAPON_ADVANCEDRIFLE", "WEAPON_SPECIALCARBINE",
  "WEAPON_SPECIALCARBINE_MK2", "WEAPON_BULLPUPRIFLE", "WEAPON_BULLPUPRIFLE_MK2",
  "WEAPON_COMPACTRIFLE", "WEAPON_MILITARYRIFLE", "WEAPON_HEAVYRIFLE",
  "WEAPON_TACTICALRIFLE", "WEAPON_SERVICE_CARBINE",
  -- MGs
  "WEAPON_MG", "WEAPON_COMBATMG", "WEAPON_COMBATMG_MK2", "WEAPON_GUSENBERG",
  -- Sniper
  "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER", "WEAPON_HEAVYSNIPER_MK2",
  "WEAPON_MARKSMANRIFLE", "WEAPON_MARKSMANRIFLE_MK2", "WEAPON_PRECISIONRIFLE",
  -- Schwere Waffen
  "WEAPON_RPG", "WEAPON_GRENADELAUNCHER", "WEAPON_GRENADELAUNCHER_SMOKE",
  "WEAPON_MINIGUN", "WEAPON_FIREWORK", "WEAPON_RAILGUN", "WEAPON_HOMINGLAUNCHER",
  "WEAPON_COMPACTLAUNCHER", "WEAPON_RAYMINIGUN", "WEAPON_EMPLAUNCHER",
  "WEAPON_RAILGUNXM3",
  -- Wurfwaffen
  "WEAPON_GRENADE", "WEAPON_BZGAS", "WEAPON_SMOKEGRENADE", "WEAPON_FLARE",
  "WEAPON_MOLOTOV", "WEAPON_STICKYBOMB", "WEAPON_PROXMINE", "WEAPON_SNOWBALL",
  "WEAPON_PIPEBOMB", "WEAPON_BALL", "WEAPON_ACIDPACKAGE",
  -- Sonstige
  "WEAPON_PETROLCAN", "WEAPON_FIREEXTINGUISHER", "WEAPON_PARACHUTE",
  "WEAPON_HAZARDCAN", "WEAPON_FERTILIZERCAN",
}

local function removeAllWeaponsComplete(ped)
  -- GTA-Native: entfernt die meisten Waffen auf einmal
  RemoveAllPedWeapons(ped, true)
  -- Einzeln nacharbeiten: GTA V uebersieht manchmal DLC/Addon-Waffen
  for _, wname in ipairs(ALL_WEAPON_HASHES) do
    local hash = GetHashKey(wname)
    if HasPedGotWeapon(ped, hash, false) then
      RemoveWeaponFromPed(ped, hash)
    end
  end
  SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
end

-- Tod-Erkennung: Beendet Szenario sofort wenn Spieler stirbt
local wantedDeathLockUntil = 0 -- GameTimer-Zeitstempel bis zu dem Wanted gesperrt ist
function GetWantedDeathLockUntil() return wantedDeathLockUntil end

-- Vorwaerts-Deklarationen: Diese local-Variablen werden in Threads verwendet,
-- die vor den eigentlichen Funktionsdefinitionen im Code stehen.
-- Ohne Vorwaerts-Deklaration wuerde Lua sie als globale Variablen suchen (nil).
local clearHelis, clearPoliceVehicles, clearCops, clearRoadblocks, setAmbientCopsIgnore, isAnyCopNearPlayer

CreateThread(function()
  local wasDead = false
  while true do
    Wait(200)
    local ped = PlayerPedId()
    local isDead = IsPedDeadOrDying(ped, true)
    if isDead and not wasDead then
      -- Spieler ist gerade gestorben
      diedDuringScenario = scenarioActive
      -- Tod-Strafe: gestaffelte Geldstrafe basierend auf Wanted-Level
      local ts = Config.TodStrafe
      if ts and ts.Aktiviert and scenarioActive then
        local wanted = math.max(1, math.max(lastKnownWanted, GetPlayerWantedLevel(PlayerId())))
        local fine = ts.StrafeProStern and ts.StrafeProStern[wanted] or 0
        if fine > 0 then
          TriggerServerEvent('mtj_arrest:serverTodStrafe', fine, wanted)
          local msg = (ts.Nachricht or "~r~Tod im Einsatz~s~: Strafe von %d EUR"):format(fine, wanted)
          nativeNotify(msg, "warnung")
          dbg("Tod-Strafe: wanted=" .. wanted .. " fine=" .. fine)
        end
      end
      if scenarioActive then
        dbg("Spieler waehrend Polizeieinsatz gestorben → Szenario beenden")
        scenarioActive = false
        canSurrender = false
        complianceWindow = 0
        combatMaintenanceActive = false
        -- Cops und Fahrzeuge sofort aufraeumen
        clearCops()
        clearRoadblocks()
        clearHelis()
        clearPoliceVehicles()
      end
      -- Sofort: Ambient-Cops ignorieren + Wanted auf 0 setzen.
      -- SetPoliceIgnorePlayer(PlayerId(), true) kommt ZUERST, damit keine einzige Frame-Luecke
      -- existiert in der Wanted>0 und aktive Cops gleichzeitig vorhanden sind.
      -- Gilt auch wenn kein Szenario aktiv war (z.B. Tod vor Szenario-Start).
      SetPoliceIgnorePlayer(PlayerId(), true)
      SetPlayerWantedLevel(PlayerId(), 0, false)
      SetPlayerWantedLevelNow(PlayerId(), false)
      ClearPlayerWantedLevel(PlayerId())
      lastKnownWanted = 0
      wantedDeathLockUntil = GetGameTimer() + 5000
      dbg("Spieler gestorben: Wanted=0, Sperre bis", wantedDeathLockUntil)
      -- Szenario-Event feuern damit wanted_level.lua reset erhaelt
      TriggerEvent('mtj_arrest:endScenario')
    end
    wasDead = isDead
  end
end)
local inJail = false
local jailTime = 0
local jailRequested = false
local complianceWindow = 0
local complianceCountdownThreadActive = false
local helis = {}
local combatMaintenanceActive = false
local combatStartTime = 0 -- GameTimer wann Kampfphase begann (fuer Nachlassen)
local nachlassenNotifiedStage = 0 -- Letzte angezeigte Nachlassen-Stufe (0=keine, 1=start, 2=mitte, 3=ende)
local pursuitStartTime = 0 -- GameTimer wann Verfolgung insgesamt begann (persistent ueber Szenario-Neustarts)
local lastScenarioStart = 0
local scenarioCooldown = 5000 -- 5 seconds cooldown between scenario starts
local scenarioStartPos = nil  -- Position bei Szenario-Start (für Fluchtversuch)
local fluchtversuchTriggered = false -- Fluchtversuch nur einmal pro Szenario
local releaseWarningShown = false -- Entlassungswarnung nur einmal
local playerAkteStatus = "unbescholten" -- Polizeiakte-Status (vom Server geladen)
local policeVehicles = {} -- Gespawnte Polizeifahrzeuge
local RESPAWN_RADIUS = 350.0 -- Cops verwalten im 350m Radius (GTA Online style: Respawn im Radius)

local diedDuringScenario = false -- Spieler ist waehrend Polizeieinsatz gestorben
local lastKnownWanted = 0 -- Letzter bekannter Wanted-Level (fuer Wiederherstellung bei GTA-Reset)
local evasionStartTime = 0 -- GameTimer wann Evasion-Countdown begann (0 = nicht aktiv)
local evasionNotifiedAt = 0 -- Letzter Zeitpunkt einer Evasion-HUD-Nachricht
local wantedDropCount = 0 -- Zaehlt wie oft WantedMaintenance Wanted=0 gelesen hat (Grace Period)
local gpsTrackerActive = false  -- GPS-Tracker-Thread laeuft
local gpsLastHeliUpdate = 0     -- Letztes Heli-Mission-Update (GameTimer)

-- Gibt den effektiven Wanted-Level zurueck: GTA-Wert ODER lastKnownWanted als Fallback.
-- GTA V setzt Wanted manchmal kurz auf 0 wenn keine Cops sichtbar sind.
-- Diese Funktion stellt sicher, dass Spawn-Logik immer den korrekten Level hat.
local function getEffectiveWanted()
  local w = GetPlayerWantedLevel(PlayerId())
  if w > 0 then return w end
  if lastKnownWanted > 0 then return lastKnownWanted end
  return 0
end

-- Gibt true zurueck wenn Kleindelikt-NichtSchiessen-Modus gilt:
-- Config.KleindeliktNichtSchiessen=true UND aktueller Wanted <= KleindeliktSchwelle.
-- In diesem Modus naehern sich Cops nur und zielen — schiessen aber nicht (TaskAimGunAtEntity).
-- Sofortiges Schiessen wird erst bei Flucht oder abgelaufener Compliance-Zeit aktiviert.
local function isKleindeliktNichtSchiessen()
  if not Config.KleindeliktNichtSchiessen then return false end
  local wanted = getEffectiveWanted()
  local schwelle = Config.KleindeliktSchwelle or 2
  return wanted > 0 and wanted <= schwelle
end

-- === GLOBALER COP-ZAEHLER (fuer auto_cop_spawn.lua Koordination) ===
-- Zaehlt nur LEBENDE Cops im Radius von 100m um den Spieler
function GetMainLuaAliveCopCount()
  local count = 0
  local ppos = GetEntityCoords(PlayerPedId())
  for _, ped in ipairs(cops) do
    if DoesEntityExist(ped) and not IsEntityDead(ped) then
      if #(GetEntityCoords(ped) - ppos) <= RESPAWN_RADIUS then count = count + 1 end
    end
  end
  for _, h in ipairs(helis) do
    if h.gunners then
      for _, g in ipairs(h.gunners) do
        if DoesEntityExist(g) and not IsEntityDead(g) then count = count + 1 end
      end
    end
    if h.pilot and DoesEntityExist(h.pilot) and not IsEntityDead(h.pilot) then count = count + 1 end
  end
  for _, pv in ipairs(policeVehicles) do
    if pv.crew then
      for _, c in ipairs(pv.crew) do
        if DoesEntityExist(c) and not IsEntityDead(c) then
          if #(GetEntityCoords(c) - ppos) <= RESPAWN_RADIUS then count = count + 1 end
        end
      end
    end
  end
  return count
end

function IsArrestScenarioActive()
  return scenarioActive
end

function IsCombatPhaseActive()
  return combatMaintenanceActive
end

-- Fuer wanted_level.lua: Gibt lastKnownWanted zurueck damit
-- die Wanted-Pruefung nicht auf GTA's Race-Condition reinfaellt
function GetMainLuaLastKnownWanted()
  return lastKnownWanted
end

-- === RELATIONSHIP GROUP (Cops MÜSSEN den Spieler hassen, sonst keine Interaktion) ===
local ARREST_COP_GROUP = nil
CreateThread(function()
  local ok, hash = AddRelationshipGroup("ARREST_COP")
  if ok then
    ARREST_COP_GROUP = hash
    SetRelationshipBetweenGroups(5, hash, GetHashKey("PLAYER")) -- 5 = HATE
    SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), hash)
    dbg("ARREST_COP relationship group erstellt (HATE)")
  else
    -- Fallback: Gruppe existiert schon
    ARREST_COP_GROUP = GetHashKey("ARREST_COP")
    SetRelationshipBetweenGroups(5, ARREST_COP_GROUP, GetHashKey("PLAYER"))
    SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), ARREST_COP_GROUP)
    dbg("ARREST_COP relationship group wiederverwendet")
  end
  -- Max-Wanted-Level auf 5 setzen (GTA/FiveM begrenzt sonst oft auf 3!)
  SetMaxWantedLevel(5)
  dbg("SetMaxWantedLevel(5) gesetzt")
end)

-- === WANTED-LEVEL WARTUNG (haelt Wanted-Level aktiv solange Szenario laeuft) ===
-- GTA V setzt Wanted auf 0 wenn keine Cops in Sichtlinie — dieses Thread verhindert das.
-- Prinzip: "Solange Sterne, solange Aktion" — Wanted bleibt aktiv ab Szenario-Start.
-- ENTKOMMEN: Wenn Spieler lange genug ALLEN Cops entwischt, Wanted sinkt → Szenario endet.
local lastMaxWantedCheck = 0
CreateThread(function()
  while true do
    Wait(500)
    -- SetMaxWantedLevel(5) alle 10 Sekunden erneuern (GTA/FiveM setzt es manchmal zurueck)
    local now = GetGameTimer()
    if now - lastMaxWantedCheck > 10000 then
      SetMaxWantedLevel(5)
      lastMaxWantedCheck = now
    end
    -- Spieler tot: keine Wanted-Wartung, sofort weiter
    if IsPedDeadOrDying(PlayerPedId(), true) then
      goto continue_wm
    end
    if scenarioActive and not surrendered and not cuffed and not inJail then
      local esc = Config.Entkommen
      local escapeEnabled = esc and esc.Aktiviert
      local copNearby = false
      if escapeEnabled then
        local escRadius = esc.FreiRadius or 80.0
        local ppos = GetEntityCoords(PlayerPedId())
        -- Pruefe Fusscops
        copNearby = isAnyCopNearPlayer(escRadius)
        -- Pruefe Heli-Besatzung
        if not copNearby then
          for _, h in ipairs(helis) do
            if h.vehicle and DoesEntityExist(h.vehicle) and not IsEntityDead(h.vehicle) then
              if #(GetEntityCoords(h.vehicle) - ppos) <= escRadius then
                copNearby = true
                break
              end
            end
          end
        end
        -- Pruefe Fahrzeug-Besatzung
        if not copNearby then
          for _, pv in ipairs(policeVehicles) do
            if pv.crew then
              for _, c in ipairs(pv.crew) do
                if DoesEntityExist(c) and not IsEntityDead(c) then
                  if #(GetEntityCoords(c) - ppos) <= escRadius then
                    copNearby = true
                    break
                  end
                end
              end
            end
            if copNearby then break end
          end
        end
      end

      -- === Entkommen-Logik ===
      if escapeEnabled and not copNearby then
        local now = GetGameTimer()
        if evasionStartTime == 0 then
          evasionStartTime = now
          dbg("Evasion gestartet: kein Cop in Reichweite")
        end
        local elapsed = (now - evasionStartTime) / 1000.0
        local escTime = esc.ZeitBisEntkommen or 45
        local remaining = math.ceil(escTime - elapsed)

        if remaining <= 0 then
          -- ENTKOMMEN! Wanted abbauen, Szenario beenden
          dbg("ENTKOMMEN! Spieler hat alle Cops abgehaengt fuer", escTime, "Sekunden")
          lastKnownWanted = 0
          evasionStartTime = 0
          evasionNotifiedAt = 0
          SetPlayerWantedLevel(PlayerId(), 0, false)
          SetPlayerWantedLevelNow(PlayerId(), false)
          nativeNotify(esc.NachrichtEntkommen or "~g~ENTKOMMEN!~s~ Du hast die Polizei abgehängt!", "erfolg")
          nativeHudSet("evasion", nil)
          -- Kein wantedDeathLockUntil: wuerde crime_monitor fuer 5s blockieren.
          -- scenarioCooldown (5s via lastScenarioStart) genuegt als Sofort-Neustart-Schutz.
          lastScenarioStart = GetGameTimer()
          TriggerServerEvent('mtj_arrest:dispatch:pursuitEnd', "entkommen")
          TriggerEvent('mtj_arrest:endScenario')
        else
          -- Evasion laeuft: HUD-Feedback alle 5 Sekunden
          if now - evasionNotifiedAt >= 5000 then
            evasionNotifiedAt = now
            local hudMsg = (esc.NachrichtEvasion or "~b~Polizei verliert dich...~s~ Noch %ds bis Entkommen!"):format(remaining)
            dbg("Evasion:", remaining, "s verbleibend", hudMsg)
          end
          -- Wanted-Level waehrend Evasion aufrechterhalten — wie GTA V Online.
          -- GTA loescht Fahndungssterne sofort wenn keine Cops in Sichtlinie sind.
          -- Wir stellen sie sofort wieder her, damit der Spieler die Sterne sieht und
          -- das Szenario erst nach der vollen Evasion-Zeit (ZeitBisEntkommen) endet.
          local wanted = GetPlayerWantedLevel(PlayerId())
          if wanted > 0 then
            lastKnownWanted = wanted
            wantedDropCount = 0
          elseif lastKnownWanted > 0 then
            SetPlayerWantedLevel(PlayerId(), lastKnownWanted, false)
            SetPlayerWantedLevelNow(PlayerId(), false)
            wantedDropCount = 0
          end
        end
      else
        -- Cop in der Naehe oder Entkommen deaktiviert: Reset Evasion-Timer
        if evasionStartTime > 0 then
          dbg("Evasion abgebrochen: Cop in der Naehe!")
          if escapeEnabled then
            nativeNotify(esc.NachrichtVerloren or "~r~ENTDECKT!~s~ Die Polizei hat dich wieder im Visier!", "warnung")
          end
          evasionStartTime = 0
          evasionNotifiedAt = 0
          nativeHudSet("evasion", nil) -- HUD-Zeile entfernen
        end
        -- Wanted aktiv halten: GTA loescht Fahndungssterne sobald Spieler aus Sichtlinie verschwindet.
        -- Im aktiven Szenario (Cop in Naehe oder Entkommen deaktiviert) Wanted sofort wieder anwenden —
        -- das Szenario endet nur noch ueber explizite Pfade (E-Taste, Timer-Ablauf, Entkommen, endScenario).
        local wanted = GetPlayerWantedLevel(PlayerId())
        if wanted > 0 then
          lastKnownWanted = wanted
          wantedDropCount = 0
        elseif lastKnownWanted > 0 then
          -- GTA hat Wanted gecleart (Sichtlinienverlust o.ae.) → sofort wieder anwenden.
          SetPlayerWantedLevel(PlayerId(), lastKnownWanted, false)
          SetPlayerWantedLevelNow(PlayerId(), false)
          wantedDropCount = 0
        end
      end
    else
      -- Szenario nicht aktiv oder Spieler bereits verhaftet → Reset Evasion
      if evasionStartTime > 0 then
        evasionStartTime = 0
        evasionNotifiedAt = 0
        nativeHudSet("evasion", nil)
      end
      -- Wanted auch im Gap zwischen Szenario-Neustarts aufrechterhalten.
      -- GTA loescht Fahndungssterne schnell ohne aktiven Einsatz; wir stellen sie
      -- sofort wieder her, damit wanted_level.lua beim naechsten Tick zuverlaessig
      -- einen gueltigen Wanted-Level vorfindet und das Szenario neu startet.
      if lastKnownWanted > 0 and not inJail and not IsPedDeadOrDying(PlayerPedId(), true) then
        local wanted = GetPlayerWantedLevel(PlayerId())
        if wanted > 0 then
          wantedDropCount = 0
        elseif wanted == 0 then
          SetPlayerWantedLevel(PlayerId(), lastKnownWanted, false)
          SetPlayerWantedLevelNow(PlayerId(), false)
          wantedDropCount = 0
        end
      end
    end
    ::continue_wm::
  end
end)

-- === TOTE NPC LEICHEN-CLEANUP (nach 3 Sekunden verschwinden) ===
local deadBodies = {} -- { ped = deathGameTimer }

CreateThread(function()
  while true do
    Wait(1000)
    local now = GetGameTimer()
    -- Track newly dead cops
    for _, ped in ipairs(cops) do
      if DoesEntityExist(ped) and IsEntityDead(ped) and not deadBodies[ped] then
        deadBodies[ped] = now
      end
    end
    -- Track dead helis/vehicle crew
    for _, h in ipairs(helis) do
      if h.crew then
        for _, c in ipairs(h.crew) do
          if DoesEntityExist(c) and IsEntityDead(c) and not deadBodies[c] then
            deadBodies[c] = now
          end
        end
      end
    end
    for _, pv in ipairs(policeVehicles) do
      if pv.crew then
        for _, c in ipairs(pv.crew) do
          if DoesEntityExist(c) and IsEntityDead(c) and not deadBodies[c] then
            deadBodies[c] = now
          end
        end
      end
    end
    -- Delete bodies after 3 seconds
    for ped, deathTime in pairs(deadBodies) do
      if now - deathTime >= 3000 then
        if DoesEntityExist(ped) then
          NetworkFadeOutEntity(ped, false, true)
          Wait(400)
          DeleteEntity(ped)
        end
        deadBodies[ped] = nil
      end
    end
  end
end)

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
  -- Collision vorladen fuer zuverlaessige Z-Ermittlung
  RequestCollisionAtCoord(p.x, p.y, p.z)
  -- Versuche bis zu 5x eine gueltige Position zu finden
  for attempt = 1, 5 do
    local angle = math.random() * math.pi * 2
    -- Bei jedem Fehlversuch naeher spawnen (garantiert Sichtbarkeit)
    local effectiveMax = maxDist - (attempt - 1) * 10.0
    if effectiveMax < minDist then effectiveMax = minDist + 5.0 end
    local dist = math.random() * (effectiveMax - minDist) + minDist
    local nx = p.x + math.cos(angle) * dist
    local ny = p.y + math.sin(angle) * dist
    -- Collision am Zielpunkt laden
    RequestCollisionAtCoord(nx, ny, p.z)
    -- Methode 1: GetSafeCoordForPed (FiveM gibt einen vector3 zurueck, nicht 3 Floats)
    local safeFound, safePos = GetSafeCoordForPed(nx, ny, p.z, true, 16)
    if safeFound and safePos then
      dbg("randomPos: SafeCoord gefunden bei Versuch", attempt, "dist:", dist)
      return safePos
    end
    -- Methode 2: GetGroundZFor_3dCoord mit mehreren Hoehen
    for _, zOff in ipairs({0.0, 10.0, 20.0, 50.0}) do
      local gFound, gz = GetGroundZFor_3dCoord(nx, ny, p.z + zOff, false)
      if gFound then
        dbg("randomPos: GroundZ gefunden bei Versuch", attempt, "zOff:", zOff, "dist:", dist)
        return vector3(nx, ny, gz + 0.5)
      end
    end
  end
  -- Fallback: Spawne direkt hinter dem Spieler (10-18m, nahe genug fuer zuverlaessige Z)
  dbg("randomPos: ALLE Versuche fehlgeschlagen, spawne nahe am Spieler")
  local heading = GetEntityHeading(ped)
  local rad = math.rad(heading + 180.0 + math.random(-45, 45))
  local fallbackDist = 10.0 + math.random() * 8.0
  local fx = p.x + math.cos(rad) * fallbackDist
  local fy = p.y + math.sin(rad) * fallbackDist
  local fz = p.z
  local gFound, gz = GetGroundZFor_3dCoord(fx, fy, fz + 10.0, false)
  if gFound then fz = gz + 0.5 end
  return vector3(fx, fy, fz)
end

clearHelis = function()
  for _, heli in ipairs(helis) do
    if heli.gunners then
      for _, g in ipairs(heli.gunners) do
        if DoesEntityExist(g) then DeleteEntity(g) end
      end
    end
    if heli.pilot and DoesEntityExist(heli.pilot) then DeleteEntity(heli.pilot) end
    if heli.vehicle and DoesEntityExist(heli.vehicle) then DeleteEntity(heli.vehicle) end
  end
  helis = {}
  dbg("clearHelis")
end

clearPoliceVehicles = function()
  for _, pv in ipairs(policeVehicles) do
    if pv.crew then
      for _, c in ipairs(pv.crew) do
        if DoesEntityExist(c) then DeleteEntity(c) end
      end
    end
    if pv.vehicle and DoesEntityExist(pv.vehicle) then DeleteEntity(pv.vehicle) end
  end
  policeVehicles = {}
  dbg("clearPoliceVehicles")
end

clearCops = function()
  for _, ped in ipairs(cops) do
    if DoesEntityExist(ped) then
      SetPedKeepTask(ped, false)
      ClearPedTasksImmediately(ped)
      RemoveAllPedWeapons(ped, true)
      DeleteEntity(ped)
    end
  end
  cops = {}
  clearHelis()
  clearPoliceVehicles()
  dbg("clearCops")
end

setAmbientCopsIgnore = function(toggle)
  SetPoliceIgnorePlayer(PlayerId(), toggle)
  dbg(toggle and "Ambient cops ignored" or "Ambient cops restored")
end

local function createCopAt(pos, modelName)
  local modelHash = loadModel(modelName)
  if not modelHash then return nil end
  -- Collision am Zielpunkt laden fuer zuverlaessige Z-Ermittlung
  -- OHNE diesen Schritt scheitert GetGroundZFor_3dCoord ausserhalb vorgeladener Gebiete!
  RequestCollisionAtCoord(pos.x, pos.y, pos.z)
  Wait(150)
  -- Boden-Z ermitteln damit Cop nicht unterirdisch spawnt
  local gFound, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 10.0, false)
  if gFound then
    pos = vector3(pos.x, pos.y, gz + 0.5)
  else
    -- Zweiter Versuch mit hoeherer Z-Abfrage
    gFound, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 50.0, false)
    if gFound then
      pos = vector3(pos.x, pos.y, gz + 0.5)
    else
      -- Letzter Fallback: Spieler-Z verwenden (immer gueltig, Cop ist in der Naehe)
      local playerZ = GetEntityCoords(PlayerPedId()).z
      pos = vector3(pos.x, pos.y, playerZ + 0.5)
      dbg("createCopAt: GroundZ fehlgeschlagen, verwende Spieler-Z:", playerZ)
    end
  end
  local heading = GetEntityHeading(PlayerPedId()) + 180.0
  local ped = CreatePed(4, modelHash, pos.x, pos.y, pos.z, heading, true, true)
  if not ped or ped == 0 or not DoesEntityExist(ped) then
    dbg("createCopAt FAILED: model=", tostring(modelName), "pos=", tostring(pos))
    return nil
  end
  SetEntityAsMissionEntity(ped, true, true)
  local netId = NetworkGetNetworkIdFromEntity(ped)
  if netId and netId ~= 0 then
    SetNetworkIdCanMigrate(netId, false)
    SetNetworkIdExistsOnAllMachines(netId, true)
  end
  PlaceObjectOnGroundProperly(ped)
  SetBlockingOfNonTemporaryEvents(ped, true)
  SetPedArmour(ped, 100)
  SetPedFleeAttributes(ped, 0, false)
  SetPedRelationshipGroupHash(ped, GetHashKey("COP"))
  GiveWeaponToPed(ped, GetHashKey("WEAPON_PISTOL"), 120, false, true)
  SetCurrentPedWeapon(ped, GetHashKey("WEAPON_PISTOL"), true)
  SetPedSeeingRange(ped, 80.0)
  SetPedHearingRange(ped, 80.0)
  SetPedAlertness(ped, 3)
  SetPedCombatAbility(ped, 0)
  SetPedCombatRange(ped, 0)
  SetPedCombatMovement(ped, 0)
  SetPedAccuracy(ped, 0)
  -- Kleindelikt: Cop naehert sich nur — schiesst noch nicht
  if isKleindeliktNichtSchiessen() then
    TaskGoToEntity(ped, PlayerPedId(), -1, 2.0, 1.0, 1073741824, 0)
  else
    TaskGoToEntity(ped, PlayerPedId(), -1, 3.0, 3.0, 1073741824, 0)
  end
  dbg("createCopAt OK: ped=", ped, "model=", tostring(modelName))
  return ped
end

local function spawnCopsAroundPlayer()
  if not (Config and Config.PoliceOffsets and #Config.PoliceOffsets > 0) then dbg("No PoliceOffsets"); return end
  if not (Config and Config.PoliceModels and #Config.PoliceModels > 0) then dbg("No PoliceModels"); return end
  local maxActive = Config.MaxActiveCops or 12
  local wanted = getEffectiveWanted()
  local toSpawn = Config.PoliceCount or 7
  if Config.CopsPerWantedLevel and Config.CopsPerWantedLevel[wanted] then
    toSpawn = Config.CopsPerWantedLevel[wanted]
  end
  toSpawn = math.min(toSpawn, maxActive - #cops)
  if toSpawn <= 0 then return end
  local ppos = GetEntityCoords(PlayerPedId())
  -- Collision laden damit GetGroundZFor_3dCoord funktioniert
  RequestCollisionAtCoord(ppos.x, ppos.y, ppos.z)
  for i = 1, toSpawn do
    local off = Config.PoliceOffsets[((i - 1) % #Config.PoliceOffsets) + 1]
    local model = Config.PoliceModels[((i - 1) % #Config.PoliceModels) + 1]
    local pos = vector3(ppos.x + off.x, ppos.y + off.y, ppos.z + (off.z or 0))
    -- Nur bei extrem nahen Offsets (<5m) auf Zufallsposition ausweichen
    -- Config-Offsets (8-12m) direkt verwenden — nah genug fuer zuverlaessige Z-Ermittlung
    if #(pos - ppos) < 5.0 then
      pos = randomPosAroundPlayer(15.0, 35.0)
    end
    local ped = createCopAt(pos, model)
    if ped then table.insert(cops, ped) end
    Wait(40)
  end
  dbg("spawned cops:", #cops)
end

local function spawnPoliceHeli()
  local w = getEffectiveWanted()
  local ht = Config.HelisPerWantedLevel
  local maxH = (ht and ht[w]) or Config.MaxHelis or 1
  if #helis >= maxH then return end

  local heliModelName = Config.HeliModel or "polmav"
  local crewModelName = Config.HeliCrewModel or "s_m_y_swat_01"
  local heliWeaponName = Config.HeliWeapon or "WEAPON_CARBINERIFLE"
  local spawnH = Config.HeliSpawnHeight or 80.0

  local heliHash = loadModel(heliModelName)
  if not heliHash then dbg("heli model load failed"); return end
  local crewHash = loadModel(crewModelName)
  if not crewHash then dbg("crew model load failed"); return end

  local ppos = GetEntityCoords(PlayerPedId())
  local ox = math.random(-40, 40)
  local oy = math.random(-40, 40)
  local spawnPos = vector3(ppos.x + ox, ppos.y + oy, ppos.z + spawnH)

  local veh = CreateVehicle(heliHash, spawnPos.x, spawnPos.y, spawnPos.z, math.random(0, 360) + 0.0, true, true)
  if not DoesEntityExist(veh) then dbg("heli vehicle creation failed"); return end
  SetEntityAsMissionEntity(veh, true, true)
  local vehNetId = NetworkGetNetworkIdFromEntity(veh)
  if vehNetId and vehNetId ~= 0 then
    SetNetworkIdCanMigrate(vehNetId, false)
    SetNetworkIdExistsOnAllMachines(vehNetId, true)
  end
  SetVehicleEngineOn(veh, true, true, false)
  SetHeliBladesFullSpeed(veh)

  -- Pilot erstellen
  local pilot = CreatePedInsideVehicle(veh, 4, crewHash, -1, true, true)
  if not DoesEntityExist(pilot) then
    DeleteEntity(veh)
    dbg("heli pilot creation failed")
    return
  end
  SetEntityAsMissionEntity(pilot, true, true)
  local pilotNetId = NetworkGetNetworkIdFromEntity(pilot)
  if pilotNetId and pilotNetId ~= 0 then
    SetNetworkIdCanMigrate(pilotNetId, false)
  end
  if ARREST_COP_GROUP then
    SetPedRelationshipGroupHash(pilot, ARREST_COP_GROUP)
  else
    SetPedRelationshipGroupHash(pilot, GetHashKey("COP"))
  end
  SetBlockingOfNonTemporaryEvents(pilot, true)
  SetPedFleeAttributes(pilot, 0, false)
  SetPedKeepTask(pilot, true)
  TaskHeliMission(pilot, veh, 0, PlayerPedId(), 0.0, 0.0, 0.0, 9, 50.0, 40.0, -1.0, 0, 10, -1.0, 0)

  -- Bewaffnete Besatzung erstellen (Sitze 1 und 2)
  local gunners = {}
  local weaponHash = GetHashKey(heliWeaponName)
  for seat = 1, 2 do
    local gunner = CreatePedInsideVehicle(veh, 4, crewHash, seat, true, true)
    if DoesEntityExist(gunner) then
      SetEntityAsMissionEntity(gunner, true, true)
      if ARREST_COP_GROUP then
        SetPedRelationshipGroupHash(gunner, ARREST_COP_GROUP)
      else
        SetPedRelationshipGroupHash(gunner, GetHashKey("COP"))
      end
      SetBlockingOfNonTemporaryEvents(gunner, true)
      SetPedFleeAttributes(gunner, 0, false)
      SetPedCombatAbility(gunner, 2)
      SetPedCombatRange(gunner, 2)
      SetPedAlertness(gunner, 3)
      SetPedSeeingRange(gunner, 200.0)
      SetPedHearingRange(gunner, 200.0)
      SetPedKeepTask(gunner, true)
      GiveWeaponToPed(gunner, weaponHash, 999, false, true)
      TaskCombatPed(gunner, PlayerPedId(), 0, 16)
      table.insert(gunners, gunner)
    end
  end

  table.insert(helis, {vehicle = veh, pilot = pilot, gunners = gunners})
  dbg("spawned police helicopter with", #gunners, "gunners")
end

-- Polizeifahrzeug spawnen (Streifenwagen mit bewaffneter Besatzung)
local policeVehicleModels = {"police", "police2", "police3", "policet"}
local function getMaxVehiclesForWanted()
  local w = getEffectiveWanted()
  local ft = Config.FahrzeugePerWantedLevel
  if ft and ft[w] then return ft[w] end
  return 2
end

local function spawnPoliceVehicle()
  if #policeVehicles >= getMaxVehiclesForWanted() then return end

  local vehModel = policeVehicleModels[math.random(1, #policeVehicleModels)]
  local vehHash = loadModel(vehModel)
  if not vehHash then dbg("police vehicle model load failed:", vehModel); return end

  local crewModel = Config.PoliceModels and Config.PoliceModels[math.random(1, #Config.PoliceModels)] or "s_m_y_cop_01"
  local crewHash = loadModel(crewModel)
  if not crewHash then dbg("police vehicle crew model load failed"); return end

  local ppos = GetEntityCoords(PlayerPedId())
  -- Spawn-Position suchen: 80-150m entfernt, nicht auf Bergen oder Gebaeuden
  local MAX_HEIGHT_DIFF_WITH_ROAD = 30.0  -- Max. Hoehenunterschied zum Spieler bei Strassenposition
  local MAX_HEIGHT_DIFF_FALLBACK  = 15.0  -- Max. Hoehenunterschied bei flachem Gelände (ohne Strasse)
  local spawnPos = nil
  for attempt = 1, 8 do
    local angle = math.random() * 2 * math.pi
    local dist = 80.0 + math.random() * 70.0 -- 80-150m entfernt (schnelle Ankunft, innerhalb 350m Radius)
    local candidate = vector3(ppos.x + math.cos(angle) * dist, ppos.y + math.sin(angle) * dist, ppos.z)
    RequestCollisionAtCoord(candidate.x, candidate.y, candidate.z)
    Wait(150)
    local found, gz = GetGroundZFor_3dCoord(candidate.x, candidate.y, candidate.z + 100.0, 0)
    if found then
      -- Hoehenunterschied zum Spieler pruefen (verhindert Spawns auf Bergen/Haeuserdaechern)
      local heightDiff = math.abs(gz - ppos.z)
      local onRoad = IsPointOnRoad(candidate.x, candidate.y, gz, 0)
      if heightDiff <= MAX_HEIGHT_DIFF_WITH_ROAD and onRoad then
        spawnPos = vector3(candidate.x, candidate.y, gz + 0.5)
        break
      end
      -- Secundaer-Fallback: Gelände ist sehr flach (kein Berg/Dach), auch ohne Strasse akzeptabel
      -- z.B. Parkplaetze, Wiesen oder Industriegelaende neben Strassen
      if heightDiff <= MAX_HEIGHT_DIFF_FALLBACK then
        spawnPos = vector3(candidate.x, candidate.y, gz + 0.5)
        break
      end
    end
  end
  if not spawnPos then
    -- Letzte Fallback: nahe am Spieler (garantiert flach)
    local angle = math.random() * 2 * math.pi
    spawnPos = vector3(ppos.x + math.cos(angle) * 80.0, ppos.y + math.sin(angle) * 80.0, ppos.z + 0.5)
    dbg("spawnPoliceVehicle: kein guter Spawn gefunden, spawne 80m vom Spieler")
  end

  local heading = math.deg(math.atan(ppos.y - spawnPos.y, ppos.x - spawnPos.x)) - 90.0
  local veh = CreateVehicle(vehHash, spawnPos.x, spawnPos.y, spawnPos.z, heading, true, true)
  if not DoesEntityExist(veh) then dbg("police vehicle creation failed"); return end
  SetEntityAsMissionEntity(veh, true, true)
  local vehNetId = NetworkGetNetworkIdFromEntity(veh)
  if vehNetId and vehNetId ~= 0 then
    SetNetworkIdCanMigrate(vehNetId, false)
    SetNetworkIdExistsOnAllMachines(vehNetId, true)
  end
  SetVehicleEngineOn(veh, true, true, false)
  SetVehicleSiren(veh, true) -- Sirene an

  local crew = {}
  local pistolHash = GetHashKey("WEAPON_PISTOL")
  local playerPed = PlayerPedId()

  -- Fahrer (Sitz -1)
  for seat = -1, 0 do
    local ped = CreatePedInsideVehicle(veh, 4, crewHash, seat, true, true)
    if DoesEntityExist(ped) then
      SetEntityAsMissionEntity(ped, true, true)
      local pedNetId = NetworkGetNetworkIdFromEntity(ped)
      if pedNetId and pedNetId ~= 0 then
        SetNetworkIdCanMigrate(pedNetId, false)
      end
      if ARREST_COP_GROUP then
        SetPedRelationshipGroupHash(ped, ARREST_COP_GROUP)
      end
      SetPedFleeAttributes(ped, 0, false)
      SetPedCombatAbility(ped, 2)
      SetPedCombatRange(ped, 2)
      SetPedCombatMovement(ped, 2)
      SetPedAlertness(ped, 3)
      SetPedSeeingRange(ped, 100.0)
      SetPedHearingRange(ped, 100.0)
      SetPedAccuracy(ped, 40)
      GiveWeaponToPed(ped, pistolHash, 120, false, true)
      SetPedKeepTask(ped, true)
      if seat == -1 then
        -- Fahrer: zum Spieler fahren
        TaskVehicleDriveToCoordLongrange(ped, veh, ppos.x, ppos.y, ppos.z, 30.0, POLICE_CHASE_DRIVING_MODE, 5.0)
      else
        -- Beifahrer: bei Kleindelikt nur zielen, sonst sofort schiessen
        if isKleindeliktNichtSchiessen() then
          TaskAimGunAtEntity(ped, playerPed, -1, false)
        else
          TaskCombatPed(ped, playerPed, 0, 16)
        end
      end
      table.insert(crew, ped)
      table.insert(cops, ped) -- In cops-Liste für Reactivation
    end
  end

  table.insert(policeVehicles, {vehicle = veh, crew = crew})
  dbg("spawned police vehicle with", #crew, "crew:", vehModel)
end

local roadblocks = {}
local function spawnRoadblock()
  local maxBlocks = Config.Roadblock and Config.Roadblock.MaxAnzahl or 2
  if #roadblocks >= maxBlocks then return end
  local ppos = GetEntityCoords(PlayerPedId())
  local heading = GetEntityHeading(PlayerPedId())
  local rad = math.rad(heading)
  local dist = 80.0 + math.random() * 40.0
  local bx = ppos.x + math.sin(rad) * dist
  local by = ppos.y + math.cos(rad) * dist
  RequestCollisionAtCoord(bx, by, ppos.z)
  Wait(150)
  local found, gz = GetGroundZFor_3dCoord(bx, by, ppos.z + 50.0, false)
  local bz = found and (gz + 0.5) or (ppos.z + 0.5)
  local blockHeading = heading + 90.0 + math.random(-15, 15)
  local blockModels = {"police", "police2", "police3"}
  local blockModel = blockModels[math.random(1, #blockModels)]
  local vehHash = loadModel(blockModel)
  if not vehHash then return end
  local veh = CreateVehicle(vehHash, bx, by, bz, blockHeading, true, true)
  if not DoesEntityExist(veh) then return end
  SetEntityAsMissionEntity(veh, true, true)
  local vehNetId = NetworkGetNetworkIdFromEntity(veh)
  if vehNetId and vehNetId ~= 0 then
    SetNetworkIdCanMigrate(vehNetId, false)
    SetNetworkIdExistsOnAllMachines(vehNetId, true)
  end
  SetVehicleSiren(veh, true)
  SetVehicleEngineOn(veh, false, true, true)
  FreezeEntityPosition(veh, true)
  local crewModel = Config.PoliceModels and Config.PoliceModels[math.random(1, #Config.PoliceModels)] or "s_m_y_cop_01"
  local crewHash = loadModel(crewModel)
  local blockCops = {}
  if crewHash then
    for i = 1, 2 do
      local angle = math.rad(blockHeading + (i == 1 and 90 or -90))
      local cx = bx + math.sin(angle) * 3.0
      local cy = by + math.cos(angle) * 3.0
      local cop = CreatePed(4, crewHash, cx, cy, bz, blockHeading + 180.0, true, true)
      if DoesEntityExist(cop) then
        SetEntityAsMissionEntity(cop, true, true)
        local copNetId = NetworkGetNetworkIdFromEntity(cop)
        if copNetId and copNetId ~= 0 then
          SetNetworkIdCanMigrate(copNetId, false)
        end
        if ARREST_COP_GROUP then
          SetPedRelationshipGroupHash(cop, ARREST_COP_GROUP)
        end
        SetPedArmour(cop, 100)
        SetPedFleeAttributes(cop, 0, false)
        SetPedCombatAbility(cop, 2)
        SetPedCombatRange(cop, 2)
        SetPedCombatMovement(cop, 1)
        SetPedAlertness(cop, 3)
        SetPedAccuracy(cop, 50)
        GiveWeaponToPed(cop, GetHashKey("WEAPON_PUMPSHOTGUN"), 50, false, true)
        SetCurrentPedWeapon(cop, GetHashKey("WEAPON_PUMPSHOTGUN"), true)
        SetPedKeepTask(cop, true)
        TaskAimGunAtEntity(cop, PlayerPedId(), -1, false)
        table.insert(blockCops, cop)
        table.insert(cops, cop)
      end
    end
  end
  table.insert(roadblocks, {vehicle = veh, crew = blockCops})
  nativeNotify("~r~STRASSENSPERRE~s~ voraus!", "polizei")
  dbg("Roadblock gespawnt bei", bx, by, bz)
end

clearRoadblocks = function()
  for _, rb in ipairs(roadblocks) do
    if rb.crew then
      for _, c in ipairs(rb.crew) do
        if DoesEntityExist(c) then DeleteEntity(c) end
      end
    end
    if rb.vehicle and DoesEntityExist(rb.vehicle) then
      FreezeEntityPosition(rb.vehicle, false)
      DeleteEntity(rb.vehicle)
    end
  end
  roadblocks = {}
end

local updateCombatHUD
local hideCombatHUD

-- === GPS-TRACKER: GTA Online Style ===
-- Waehrend der Verfolgung hat der Spieler einen unsichtbaren GPS-Sender.
-- Alle Polizeifahrzeuge und Helikopter werden kontinuierlich zu seiner
-- aktuellen Position navigiert. Stoppt automatisch wenn Wanted = 0.
local GPS_VEH_INTERVAL  = 1000  -- Fahrzeug-Navi jede Sekunde aktualisieren
local GPS_HELI_INTERVAL = 4000  -- Heli-Mission alle 4 Sekunden erneuern
-- GTAV nativer Polizei-Verfolgung Fahrstil (aggressiv, Ampeln ignorieren, Hindernisse umfahren)
local POLICE_CHASE_DRIVING_MODE = 786603

local function startGpsTracker()
  if gpsTrackerActive then return end
  if not scenarioActive then return end  -- Kein Start wenn Szenario bereits beendet
  gpsTrackerActive = true
  dbg("GPS-Tracker: gestartet")
  CreateThread(function()
    while scenarioActive and not inJail do
      Wait(GPS_VEH_INTERVAL)
      if not scenarioActive then break end
      local playerPed = PlayerPedId()
      local ppos      = GetEntityCoords(playerPed)
      local now       = GetGameTimer()

      -- Polizeifahrzeuge: Fahrer immer zur aktuellen Spielerposition navigieren
      for _, pv in ipairs(policeVehicles) do
        if pv.vehicle and DoesEntityExist(pv.vehicle) and not IsEntityDead(pv.vehicle) then
          local driver = GetPedInVehicleSeat(pv.vehicle, -1)
          if driver ~= 0 and DoesEntityExist(driver) and not IsEntityDead(driver) then
            local vdist = #(GetEntityCoords(pv.vehicle) - ppos)
            if vdist > 8.0 then
              TaskVehicleDriveToCoordLongrange(driver, pv.vehicle,
                ppos.x, ppos.y, ppos.z, 30.0, POLICE_CHASE_DRIVING_MODE, 5.0)
            end
          end
        end
      end

      -- Helikopter: Pilot-Mission periodisch erneuern damit Heli immer ueber dem Spieler bleibt
      if (now - gpsLastHeliUpdate) >= GPS_HELI_INTERVAL then
        gpsLastHeliUpdate = now
        for _, h in ipairs(helis) do
          if h.vehicle and DoesEntityExist(h.vehicle) and not IsEntityDead(h.vehicle) then
            if h.pilot and DoesEntityExist(h.pilot) and not IsEntityDead(h.pilot) then
              TaskHeliMission(h.pilot, h.vehicle, 0, playerPed,
                0.0, 0.0, 0.0, 9, 50.0, 40.0, -1.0, 0, 10, -1.0, 0)
            end
          end
        end
      end
    end
    gpsTrackerActive = false
    dbg("GPS-Tracker: gestoppt")
  end)
end

local function startCombatMaintenance()
  if combatMaintenanceActive then return end
  combatMaintenanceActive = true
  combatStartTime = GetGameTimer()
  nachlassenNotifiedStage = 0
  startGpsTracker() -- GPS-Tracker starten: Cops + Helis immer zum Spieler navigieren
  CreateThread(function()
    local pistolHash = GetHashKey("WEAPON_PISTOL")
    local heliWeaponHash = GetHashKey(Config.HeliWeapon or "WEAPON_CARBINERIFLE")
    -- Laufe solange Szenario aktiv UND Spieler nicht verhaftet/ergeben
    -- Wanted-Level wird vom globalen WantedMaintenance-Thread aktiv gehalten
    while scenarioActive and not surrendered and not cuffed and not inJail do
      Wait(1500) -- 1.5s statt 3s fuer schnellere Verstaerkung
      updateCombatHUD()
      local playerPed = PlayerPedId()
      local wanted = getEffectiveWanted()

      -- === NACHLASSEN: Verfolgungsdruck berechnen ===
      -- Verwendet pursuitStartTime (persistiert ueber Szenario-Neustarts)
      -- statt combatStartTime (wird bei jedem Neustart zurueckgesetzt)
      local nl = Config.Nachlassen
      local nachlassenFaktor = 1.0 -- 1.0 = voller Druck, 0.0 = kein Druck
      if nl and nl.Aktiviert and pursuitStartTime > 0 then
        local pursuitElapsed = (GetGameTimer() - pursuitStartTime) / 1000.0
        local abSek = nl.AbSekunden or 300
        local nlDauer = nl.NachlassDauer or 180
        if pursuitElapsed >= abSek then
          local progress = math.min((pursuitElapsed - abSek) / nlDauer, 1.0)
          local minFaktor = nl.MinCopFaktor or 0.0
          nachlassenFaktor = 1.0 - progress * (1.0 - minFaktor)
          -- Nachlassen-Benachrichtigungen
          if progress > 0 and nachlassenNotifiedStage < 1 then
            nachlassenNotifiedStage = 1
            dbg("Nachlassen gestartet nach", math.floor(pursuitElapsed), "s Verfolgung")
          end
          if progress >= 0.5 and nachlassenNotifiedStage < 2 then
            nachlassenNotifiedStage = 2
            dbg("Nachlassen 50%: Druck halbiert")
          end
          if progress >= 1.0 and nachlassenNotifiedStage < 3 then
            nachlassenNotifiedStage = 3
            nativeHudSet("nachlassen", nil)
            dbg("Nachlassen 100%: Keine Verstaerkung mehr")
          end
        end
      end
      local minAccuracy = (nl and nl.MinGenauigkeit) or 5
      local nachlassenAccuracy = math.floor(40 * nachlassenFaktor + minAccuracy * (1.0 - nachlassenFaktor))

      -- Tote und zu weit entfernte Cops aus Liste entfernen (350m Radius)
      local ppos = GetEntityCoords(playerPed)
      for i = #cops, 1, -1 do
        local ped = cops[i]
        if not DoesEntityExist(ped) or IsEntityDead(ped) then
          if DoesEntityExist(ped) then DeleteEntity(ped) end
          table.remove(cops, i)
        elseif #(GetEntityCoords(ped) - ppos) > RESPAWN_RADIUS then
          DeleteEntity(ped)
          table.remove(cops, i)
          dbg("Cop zu weit entfernt, entfernt (>350m)")
        end
      end

      -- Lebende Cops: Waffen, Kampf, Suchverhalten
      -- Bei Kleindelikt (1-2 Sterne, NichtSchiessen=true): nur zielen, nicht schiessen
      local kleindeliktMode = isKleindeliktNichtSchiessen()
      for _, ped in ipairs(cops) do
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
          if ARREST_COP_GROUP then
            SetPedRelationshipGroupHash(ped, ARREST_COP_GROUP)
          end
          SetPedAccuracy(ped, nachlassenAccuracy)
          if not HasPedGotWeapon(ped, pistolHash, false) then
            GiveWeaponToPed(ped, pistolHash, 120, false, true)
          end
          if not IsPedInCombat(ped) then
            ClearPedTasks(ped)
            SetBlockingOfNonTemporaryEvents(ped, kleindeliktMode) -- true bei Kleindelikt: blockiert Auto-Kampf
            SetPedAlertness(ped, 3)
            SetPedSeeingRange(ped, 100.0)
            SetPedHearingRange(ped, 100.0)
            SetPedCombatAbility(ped, kleindeliktMode and 0 or 2)
            SetPedCombatRange(ped, kleindeliktMode and 0 or 2)
            SetPedCombatMovement(ped, kleindeliktMode and 0 or 2)
            SetCurrentPedWeapon(ped, pistolHash, true)
            SetPedKeepTask(ped, true)
            local copDist = #(GetEntityCoords(ped) - ppos)
            if kleindeliktMode then
              -- Kleindelikt: Cop naehert sich und zielt, schiesst aber NICHT
              if copDist > 3.0 then
                TaskGoToEntity(ped, playerPed, -1, 2.0, 1.0, 1073741824, 0)
              else
                TaskAimGunAtEntity(ped, playerPed, -1, false)
              end
            elseif copDist < 50.0 then
              TaskCombatPed(ped, playerPed, 0, 16)
            else
              TaskGoToEntity(ped, playerPed, -1, 5.0, 2.0, 1073741824, 0)
            end
          end
        end
      end

      -- Verstaerkung nachspawnen wenn Cops gestorben sind
      -- Globales Limit: main.lua Cops vs MaxActiveCops (inkl. lebende Cops-Zaehlung)
      -- Nachlassen: targetCount wird durch nachlassenFaktor reduziert
      local targetCount = Config.PoliceCount or 7
      if Config.CopsPerWantedLevel and Config.CopsPerWantedLevel[wanted] then
        targetCount = Config.CopsPerWantedLevel[wanted]
      end
      targetCount = math.floor(targetCount * nachlassenFaktor)
      local maxActive = Config.MaxActiveCops or 20
      local aliveCops = GetMainLuaAliveCopCount()
      targetCount = math.min(targetCount, maxActive)
      local toSpawn = math.min(targetCount - aliveCops, maxActive - aliveCops)
      if toSpawn > 0 then
        dbg("Verstärkung: spawne", math.min(toSpawn, 4), "neue Cops (alive:", aliveCops, "target:", targetCount, "max:", maxActive, "nachlassen:", nachlassenFaktor, ")")
        for i = 1, math.min(toSpawn, 4) do -- Max 4 pro Tick (alle 1.5s)
          local pos = randomPosAroundPlayer(20.0, 60.0)
          local model = Config.PoliceModels[math.random(1, #Config.PoliceModels)]
          local ped = createCopAt(pos, model)
          if ped then
            table.insert(cops, ped)
            ClearPedTasks(ped)
            -- Bei Kleindelikt: auch Verstaerkung zielt nur, schiesst nicht
            SetBlockingOfNonTemporaryEvents(ped, kleindeliktMode)
            if ARREST_COP_GROUP then
              SetPedRelationshipGroupHash(ped, ARREST_COP_GROUP)
            end
            GiveWeaponToPed(ped, pistolHash, 120, false, true)
            SetPedAlertness(ped, 3)
            SetPedSeeingRange(ped, 100.0)
            SetPedHearingRange(ped, 100.0)
            SetPedCombatAbility(ped, kleindeliktMode and 0 or 2)
            SetPedCombatRange(ped, kleindeliktMode and 0 or 2)
            SetPedCombatMovement(ped, kleindeliktMode and 0 or 2)
            SetPedAccuracy(ped, nachlassenAccuracy)
            SetCurrentPedWeapon(ped, pistolHash, true)
            SetPedKeepTask(ped, true)
            if kleindeliktMode then
              TaskGoToEntity(ped, playerPed, -1, 2.0, 1.0, 1073741824, 0)
            else
              TaskCombatPed(ped, playerPed, 0, 16)
            end
          end
          Wait(200)
        end
      end

      -- Polizeifahrzeuge spawnen (laut Config.FahrzeugePerWantedLevel) — nicht bei vollem Nachlassen
      if nachlassenFaktor > 0.3 then
        spawnPoliceVehicle()
      end

      -- Helikopter ab konfiguriertem Wanted-Level
      local heliLevel = Config.HeliWantedLevel or 3
      if wanted >= heliLevel and nachlassenFaktor > 0.5 then
        spawnPoliceHeli()
        for _, heli in ipairs(helis) do
          if heli.gunners then
            for _, g in ipairs(heli.gunners) do
              if DoesEntityExist(g) and not IsEntityDead(g) then
                if not HasPedGotWeapon(g, heliWeaponHash, false) then
                  GiveWeaponToPed(g, heliWeaponHash, 999, false, true)
                end
                if not IsPedInCombat(g) then
                  TaskCombatPed(g, playerPed, 0, 16)
                end
              end
            end
          end
        end
      end

      -- Strassensperren ab 4 Sternen
      local rbLevel = Config.Roadblock and Config.Roadblock.AbWantedLevel or 4
      if wanted >= rbLevel and nachlassenFaktor > 0.5 then
        spawnRoadblock()
      end

      -- Zerstörte Helis aufräumen
      for i = #helis, 1, -1 do
        local h = helis[i]
        if not h.vehicle or not DoesEntityExist(h.vehicle) or IsEntityDead(h.vehicle) then
          if h.gunners then
            for _, g in ipairs(h.gunners) do
              if DoesEntityExist(g) then DeleteEntity(g) end
            end
          end
          if h.pilot and DoesEntityExist(h.pilot) then DeleteEntity(h.pilot) end
          if h.vehicle and DoesEntityExist(h.vehicle) then DeleteEntity(h.vehicle) end
          table.remove(helis, i)
        end
      end

      -- Zerstörte Fahrzeuge aufräumen
      for i = #policeVehicles, 1, -1 do
        local pv = policeVehicles[i]
        if not pv.vehicle or not DoesEntityExist(pv.vehicle) or IsEntityDead(pv.vehicle) then
          if pv.crew then
            for _, c in ipairs(pv.crew) do
              if DoesEntityExist(c) then DeleteEntity(c) end
            end
          end
          if pv.vehicle and DoesEntityExist(pv.vehicle) then DeleteEntity(pv.vehicle) end
          table.remove(policeVehicles, i)
        end
      end
    end
    combatMaintenanceActive = false
    dbg("combatMaintenance ended")
    -- Wenn Szenario noch aktiv aber Loop beendet (z.B. durch Verhaftung),
    -- nichts tun. Aber wenn Wanted > 0 und Szenario irgendwie haengt,
    -- endScenario triggern damit wanted_level.lua neu starten kann.
    if scenarioActive and not surrendered and not cuffed and not inJail then
      local wanted = getEffectiveWanted()
      if wanted > 0 then
        dbg("combatMaintenance: Loop beendet aber Wanted > 0, resette Szenario fuer Neustart")
        TriggerEvent('mtj_arrest:endScenario')
      end
    end
  end)
end

local function reactivatePolice()
  local playerPed = PlayerPedId()
  for _, ped in ipairs(cops) do
    if DoesEntityExist(ped) and not IsEntityDead(ped) then
      -- Alte Tasks löschen damit TaskCombatPed greift
      ClearPedTasks(ped)
      SetBlockingOfNonTemporaryEvents(ped, false)
      SetPedCanRagdoll(ped, true)
      SetPedCombatAbility(ped, 2)
      SetPedCombatRange(ped, 2)
      SetPedCombatMovement(ped, 2) -- Offensiv
      SetPedAlertness(ped, 3)
      SetPedSeeingRange(ped, 100.0)
      SetPedHearingRange(ped, 100.0)
      SetPedFleeAttributes(ped, 0, false)
      SetPedAccuracy(ped, 50)
      -- Von COP (RESPECT) → ARREST_COP (HATE) umschalten + bewaffnen
      if ARREST_COP_GROUP then
        SetPedRelationshipGroupHash(ped, ARREST_COP_GROUP)
      end
      GiveWeaponToPed(ped, GetHashKey("WEAPON_PISTOL"), 120, false, true)
      SetCurrentPedWeapon(ped, GetHashKey("WEAPON_PISTOL"), true)
      SetPedKeepTask(ped, true)
      TaskCombatPed(ped, playerPed, 0, 16)
    end
  end
  setAmbientCopsIgnore(false)
  dbg("reactivatePolice: cops can shoot again, count:", #cops)
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

local function getScenarioHint()
  local wanted = getEffectiveWanted()
  local schwelle = Config.KleindeliktSchwelle or 2
  if wanted <= schwelle then
    return Config.UI.ScenarioHintKleindelikt or "Kleindelikt! Drücke [E] um Strafe zu akzeptieren und frei zu kommen."
  end
  local pa = Config.Polizeiakte
  if pa and pa.ScenarioHintPerStatus and pa.ScenarioHintPerStatus[playerAkteStatus] then
    return pa.ScenarioHintPerStatus[playerAkteStatus]
  end
  return Config.UI.ScenarioHint
end

updateCombatHUD = function()
  -- Vorwarner-Anzeige deaktiviert: nur Einsatz- und Knast-Panel werden angezeigt
end

hideCombatHUD = function()
  nativeHudSet("combat_stars", nil)
  nativeHudSet("combat_cops", nil)
  nativeHudSet("combat_time", nil)
  nativeHudSet("combat_status", nil)
end

-- Alle Panels verstecken (gegenseitige Ausschliessung, nur 1 Panel gleichzeitig)
local function hideAllUI()
  TriggerEvent('mtj_arrest:nui:scenario', false)
  TriggerEvent('mtj_arrest:nui:jail', false)
  hideCombatHUD()
  nativeHudClear()
  dbg("hideAllUI: alle Panels versteckt")
end

local function showScenarioUI(timerOverride)
  hideAllUI() -- Alle anderen Panels ausblenden
  local displayTimer = timerOverride or Config.ComplianceWindow
  TriggerEvent('mtj_arrest:nui:scenario', true, getScenarioHint(), displayTimer)
  -- GTA Native Fallback
  local hint = getScenarioHint() or ""
  -- Entferne GTA Farbcodes fuer Native HUD
  local cleanHint = hint:gsub("~[^~]+~", "")
  nativeHudSet("scenario", "POLIZEI-EINSATZ: " .. cleanHint, 255, 50, 50)
  local wanted = getEffectiveWanted()
  local schwelle = Config.KleindeliktSchwelle or 2
  if wanted <= schwelle then
    local fine = Config.KleindeliktStrafe or 500
    nativeHudSet("scenario_cd", "[E] Strafe akzeptieren: " .. fine .. " EUR — frei kommen (" .. displayTimer .. "s) | Sonst +1 Stern!", 50, 220, 100)
  else
    nativeHudSet("scenario_cd", "Letzte Chance: " .. displayTimer .. "s — [E] Ergeben", 100, 180, 255)
  end
  dbg("showScenarioUI: NUI + Native HUD")
end

local function hideScenarioUI()
  TriggerEvent('mtj_arrest:nui:scenario', false)
  nativeHudSet("scenario", nil)
  nativeHudSet("scenario_cd", nil)
  dbg("hideScenarioUI")
end

-- Prüft ob mindestens ein Cop innerhalb des Radius ist
isAnyCopNearPlayer = function(radius)
  local ppos = GetEntityCoords(PlayerPedId())
  for _, ped in ipairs(cops) do
    if DoesEntityExist(ped) and not IsEntityDead(ped) then
      if #(GetEntityCoords(ped) - ppos) <= radius then
        return true
      end
    end
  end
  return false
end

-- Fluchtversuch: Spieler rennt weg → Wanted +1, Extra-Cops
local function checkFluchtversuch()
  local fc = Config.Fluchtversuch
  if not fc or not fc.Aktiviert then return end
  if fluchtversuchTriggered then return end
  if not scenarioStartPos then return end
  local ppos = GetEntityCoords(PlayerPedId())
  local dist = #(ppos - scenarioStartPos)
  local radius = fc.Fluchtradius or 25.0
  if dist >= radius then
    fluchtversuchTriggered = true
    dbg("FLUCHTVERSUCH erkannt! Distanz:", dist)
    local current = GetPlayerWantedLevel(PlayerId())
    local increase = fc.WantedErhoehung or 1
    local newLevel = math.min(current + increase, 5)
    if newLevel > current then
      SetPlayerWantedLevel(PlayerId(), newLevel, false)
      SetPlayerWantedLevelNow(PlayerId(), false)
      dbg("Wanted-Level erhoeht:", current, "->", newLevel)
    end
    local extraCops = fc.ExtraCops or 3
    for i = 1, extraCops do
      local model = Config.PoliceModels[((i - 1) % #Config.PoliceModels) + 1]
      local pos = randomPosAroundPlayer(15.0, 30.0)
      local ped = createCopAt(pos, model)
      if ped then table.insert(cops, ped) end
    end
    reactivatePolice()
    startCombatMaintenance()
    TriggerServerEvent('mtj_arrest:serverFluchtversuch')
    nativeNotify(fc.Nachricht or ("~r~FLUCHTVERSUCH~s~: " .. playerName .. " — Wanted-Level erhoeht!"), "warnung")
    canSurrender = false
    hideScenarioUI()
  end
end

-- NPC-Cops rufen Befehle basierend auf Polizeiakte-Status (RP-Immersion)
local copSpeechDefaults = {
  "ARREST_PLAYER",
  "DRAW_GUN",
  "CHALLENGE_THREATEN",
  "FOOT_CHASE",
  "FOOT_CHASE_LOSING",
}
local function makeCopsShout()
  local lines = copSpeechDefaults
  local pa = Config.Polizeiakte
  if pa and pa.CopSpeech and pa.CopSpeech[playerAkteStatus] then
    lines = pa.CopSpeech[playerAkteStatus]
  end
  for i, ped in ipairs(cops) do
    if DoesEntityExist(ped) and not IsEntityDead(ped) then
      local speech = lines[((i - 1) % #lines) + 1]
      PlayPedAmbientSpeechNative(ped, speech, "SPEECH_PARAMS_FORCE_SHOUTED_CRITICAL")
      if i >= 3 then break end
    end
  end
end

-- === COMPLIANCE-COUNTDOWN (Countdown vor Zugriff) ===
local function runNegotiationAndCompliance()
  canSurrender = true
  local initWanted = getEffectiveWanted()
  local schwelle = Config.KleindeliktSchwelle or 2

  -- ── KLEINDELIKT-PHASE (1-2 Sterne): 10s-Entscheidungsfenster ─────────────
  -- Spieler hat 10 Sekunden um per [E] die Geldstrafe zu akzeptieren (→ frei).
  -- Reagiert er nicht, steigt der Wanted-Level auf schwelle+1 und der
  -- normale Kampf-Verlauf beginnt.
  if initWanted <= schwelle then
    local kleindeliktWindow = Config.KleindeliktPromptDauer or 10
    showScenarioUI(kleindeliktWindow)
    makeCopsShout()
    nativeNotify("~r~POLIZEI~s~ an " .. playerName .. ": " .. getScenarioHint(), "polizei")
    complianceCountdownThreadActive = true
    while scenarioActive and canSurrender and not surrendered and not cuffing and not cuffed and not inJail and kleindeliktWindow > 0 do
      Wait(1000)
      kleindeliktWindow = kleindeliktWindow - 1
      TriggerEvent('mtj_arrest:nui:scenario_tick', kleindeliktWindow)
      local fine = Config.KleindeliktStrafe or 500
      nativeHudSet("scenario_cd", "[E] Strafe zahlen: " .. fine .. " EUR → frei (" .. kleindeliktWindow .. "s) | Sonst +1 Stern!", 50, 220, 100)
      checkFluchtversuch()
    end
    complianceCountdownThreadActive = false
    -- Spieler hat [E] gedrückt, wurde verhaftet, oder Szenario wurde anderweitig beendet → nicht eskalieren
    if surrendered or not scenarioActive or cuffing or cuffed or inJail then return end
    -- 10s abgelaufen ohne Reaktion → Eskalation
    canSurrender = false
    hideScenarioUI()
    local escalatedWanted = schwelle + 1
    SetPlayerWantedLevel(PlayerId(), escalatedWanted, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    lastKnownWanted = escalatedWanted
    dbg("Kleindelikt: Prompt abgelaufen, Eskalation auf " .. escalatedWanted .. " Sterne")
    nativeNotify(("~r~Keine Reaktion!~s~ Fahndungslevel erhöht auf %d Stern(e)!"):format(escalatedWanted), "warnung")
    nativeHudSet("combat_status", "POLIZEI-EINSATZ: Zugriff!", 255, 30, 30)
    reactivatePolice()
    startCombatMaintenance()
    return
  end

  -- ── STANDARD-COMPLIANCE-PHASE (3+ Sterne) ────────────────────────────────
  showScenarioUI()
  makeCopsShout()
  nativeNotify("~r~POLIZEI~s~ an " .. playerName .. ": " .. getScenarioHint(), "polizei")
  complianceCountdownThreadActive = true
  while scenarioActive and canSurrender and not surrendered and not cuffing and not cuffed and not inJail and complianceWindow > 0 do
    Wait(1000)
    if scenarioActive and canSurrender and not surrendered and not cuffing and not cuffed and not inJail then
      complianceWindow = complianceWindow - 1
      TriggerEvent('mtj_arrest:nui:scenario_tick', complianceWindow)
      nativeHudSet("scenario_cd", "Letzte Chance: " .. complianceWindow .. "s — [E] Ergeben", 100, 180, 255)
      checkFluchtversuch()
      if complianceWindow <= 0 then
        canSurrender = false
        hideScenarioUI()
        nativeHudSet("combat_status", "POLIZEI-EINSATZ: Zugriff!", 255, 30, 30)
        reactivatePolice()
        startCombatMaintenance()
        dbg("Surrender window abgelaufen!")
      end
    else
      break
    end
  end
  complianceCountdownThreadActive = false
end


-- Festnahme-Protokoll Texte basierend auf Akte-Status
local function getArrestLogLines()
  local pa = Config.Polizeiakte
  if pa and pa.ArrestLogPerStatus and pa.ArrestLogPerStatus[playerAkteStatus] then
    return pa.ArrestLogPerStatus[playerAkteStatus]
  end
  return Config.UI.ArrestLogLines
end

-- Szenario-Hint basierend auf Akte-Status
-- === KLEINDELIKT-ABLAUF (1-2 Sterne: Strafe vor Ort, dann frei) ===
local function playFineSequence()
  if cuffing or cuffed or inJail then
    dbg("playFineSequence: guard (cuffing/cuffed/inJail) -> abort")
    return
  end
  if not scenarioActive then
    dbg("playFineSequence: scenarioActive=false -> abort")
    return
  end
  cuffing = true
  deescalateAllPolice()  -- Alle Cops sofort entschaerfen
  forceExitVehicleIfIn()
  if not scenarioActive then cuffing = false; return end

  local player = PlayerPedId()
  local ppos = GetEntityCoords(player)

  -- Naechsten Cop finden
  local nearest, bestD = nil, 9999
  for _, ped in ipairs(cops) do
    if DoesEntityExist(ped) and not IsEntityDead(ped) then
      local d = #(GetEntityCoords(ped) - ppos)
      if d < bestD then nearest, bestD = ped, d end
    end
  end

  -- Cop laeuft zum Spieler
  if nearest and DoesEntityExist(nearest) and bestD > 2.0 then
    TaskGoToEntity(nearest, player, -1, 1.2, 1.0, 1073741824, 0)
    local timeout = GetGameTimer() + 8000
    while #(GetEntityCoords(nearest) - GetEntityCoords(player)) > 2.2 and GetGameTimer() < timeout do
      Wait(100)
      if not scenarioActive then cuffing = false; return end
    end
  end
  if not scenarioActive then cuffing = false; return end

  -- Kurze Haende-hoch-Animation
  if loadAnimDict("random@arrests") then
    TaskPlayAnim(player, "random@arrests", "idle_2_hands_up", 8.0, -8.0, 3000, 49, 0, false, false, false)
    Wait(2500)
    if not scenarioActive then cuffing = false; return end
  end

  -- Strafe ausstellen und Spieler freilassen
  local fine = Config.KleindeliktStrafe or 500
  local msg = (Config.KleindeliktNachricht or "~g~Kleindelikt~s~: Strafe von %d EUR ausgestellt. Du bist auf freiem Fuß!"):format(fine)
  hideScenarioUI()
  hideAllUI()

  -- Vor-Ort-Zahlung NUI-Panel anzeigen
  local deliktText = Config.KleindeliktDeliktText or "Ordnungswidrigkeit / Kleindelikt"
  local officerName = Config.KleindeliktOfficerName or "Beamter (NPC)"
  TriggerEvent('mtj_arrest:nui:fine', true, fine, officerName, deliktText, false, nil)

  TriggerServerEvent('mtj_arrest:serverFineOnly', fine)
  TriggerServerEvent('mtj_arrest:dispatch:pursuitEnd', "entlassen")

  -- Wanted sofort auf 0 setzen
  SetPlayerWantedLevel(PlayerId(), 0, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  ClearPlayerWantedLevel(PlayerId())
  lastKnownWanted = 0
  -- wantedDeathLockUntil hier NICHT setzen: crime_monitor.lua interpretiert diesen
  -- Lock als Tod/Respawn-Sperre und nullt pendingWanted jede 500ms — neue Verbrechen
  -- nach dem Kleindelikt wuerden dadurch fuer mehrere Sekunden keine Sterne bekommen.
  -- Stattdessen: lastScenarioStart erneuern → scenarioCooldown (5s) verhindert
  -- Sofort-Neustart, ohne crime_monitor zu blockieren.
  lastScenarioStart = GetGameTimer()
  local vozPanelMs = Config.KleindeliktPanelDauer or 2800

  -- Abschluss-Status nach kurzer Verzoegerung setzen (Fortschrittsbalken laeuft 2.8s;
  -- muss mit VOZ_DONE_DISPLAY_MS in app.js synchron bleiben)
  Wait(vozPanelMs)
  -- Szenario koennte waehrend der Animation durch Tod/Sicherheitsnetz beendet worden sein
  if not scenarioActive then cuffing = false; return end
  local doneMsg = ("✅ Strafe von %d EUR bezahlt — Auf freiem Fuß!"):format(fine)
  TriggerEvent('mtj_arrest:nui:fine', false, fine, officerName, deliktText, true, doneMsg)
  nativeNotify(msg, "erfolg")

  Wait(vozPanelMs)
  -- Nochmals pruefen: Falls Spieler in der Zwischenzeit gestorben ist, kein zweites endScenario
  if not scenarioActive then cuffing = false; return end
  cuffing = false
  TriggerEvent('mtj_arrest:endScenario')
  dbg("playFineSequence: Kleindelikt abgeschlossen, Spieler frei")
end

-- === FESTNAHME-ABLAUF ===
local function playCuffSequence()
  if cuffing or cuffed or inJail then
    dbg("playCuffSequence: guard (cuffing/cuffed/inJail) -> abort")
    return
  end
  if not scenarioActive then
    dbg("playCuffSequence: scenarioActive=false -> abort")
    return
  end
  cuffing = true
  deescalateAllPolice()  -- SOFORT alle Cops entschaerfen: kein Schiessen mehr nach Ergeben
  forceExitVehicleIfIn()
  if not scenarioActive then cuffing = false; return end
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
      if not scenarioActive then cuffing = false; return end
    end
  end
  if not scenarioActive then cuffing = false; return end
  if not loadAnimDict("random@arrests") then cuffing = false return end
  if not loadAnimDict("mp_arrest_paired") then cuffing = false return end
  TaskPlayAnim(player, "random@arrests", "idle_2_hands_up", 8.0, -8.0, 2500, 49, 0, false, false, false)
  Wait(2200)
  if not scenarioActive then cuffing = false; return end
  if nearest and DoesEntityExist(nearest) then
    TaskPlayAnim(nearest, "mp_arrest_paired", "cop_p2_back_left", 6.0, -4.0, 4500, 49, 0, false, false, false)
    TaskLookAtEntity(nearest, player, 5000, 2048, 3)
  end
  TaskPlayAnim(player, "random@arrests", "kneeling_arrest_idle", 8.0, -8.0, 4500, 49, 0, false, false, false)
  Wait(3500)
  if not scenarioActive then cuffing = false; return end

  -- Handschellen anlegen + Freeze
  SetEnableHandcuffs(player, true)
  FreezeEntityPosition(player, true)
  cuffed = true

  -- Kurze Pause damit Handschellen-Visuals sichtbar sind
  Wait(1000)

  -- JETZT erst Festnahme-Info anzeigen (nach Animation + Handschellen)
  deescalateAllPolice()
  hideAllUI() -- Alle vorherigen Panels ausblenden
  nativeHudSet("arrest", "FESTNAHME: " .. playerName .. " wird verhaftet!", 255, 50, 50)
  -- Status-basierte Festnahme-Texte
  if playerAkteStatus ~= "unbescholten" then
    local pa = Config.Polizeiakte
    local msg = (pa and pa.NachrichtVorbestraft) or ("~r~Festnahme~s~: " .. playerName .. " (" .. playerAkteStatus .. ") — verschaerftes Verfahren!")
    nativeNotify(msg, "polizei")
  else
    nativeNotify("~r~Festnahme~s~: " .. playerName .. " wird verhaftet!", "polizei")
  end
  Wait(3000)
  nativeHudSet("arrest", nil)
  cuffing = false
  dbg("cuff sequence done")
  hideScenarioUI()
  -- Jail-Trigger immer ausführen
  if not inJail and scenarioActive then
    jailRequested = true
    TriggerServerEvent('mtj_arrest:serverBeginJail', Config.JailMinutesDefault)
    TriggerServerEvent('mtj_arrest:dispatch:pursuitEnd', "verhaftet")
  end
end

-- === JAIL-TELEPORT / JAIL-TIMER ===
RegisterNetEvent('mtj_arrest:clientBeginJail')
AddEventHandler('mtj_arrest:clientBeginJail', function(minutes, fineAmount)
  local jailPos = Config.JailPosition
  local jailHeading = Config.JailHeading
  local player = PlayerPedId()

  -- Tatsaechliche Geldstrafe verwenden (vom Server berechnet mit Multiplikatoren)
  local actualFine = tonumber(fineAmount) or Config.JailFine or 15000

  -- Waffen vom Ped entfernen BEVOR Teleport (Spieler soll mit Handschellen spawnen, nicht mit Waffe)
  RemoveAllPedWeapons(player, true)
  SetCurrentPedWeapon(player, GetHashKey("WEAPON_UNARMED"), true)

  DoScreenFadeOut(1000)
  Wait(1200)
  SetEntityCoords(player, jailPos.x, jailPos.y, jailPos.z)
  SetEntityHeading(player, jailHeading)
  FreezeEntityPosition(player, true)
  SetEnableHandcuffs(player, true)

  -- Nochmal Waffen entfernen nach Teleport (Sicherheit)
  RemoveAllPedWeapons(player, true)
  SetCurrentPedWeapon(player, GetHashKey("WEAPON_UNARMED"), true)

  inJail = true

  -- HIER: WANTED LEVEL AUF NULL SETZEN
  if GetPlayerWantedLevel(PlayerId()) ~= 0 then
    SetPlayerWantedLevel(PlayerId(), 0, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    dbg("[Jail] Setze Wanted Level auf 0!")
  end

  local jailSeconds = math.floor((tonumber(minutes) or 10) * 60)
  local jailTotalSeconds = jailSeconds -- Gesamtzeit fuer Progress-Bar (einmalig gesetzt)
  dbg(("Spieler wurde ins Jail teleportiert für %d Minuten! Strafe: %d€"):format(minutes, actualFine))
  hideAllUI() -- Alle vorherigen Panels ausblenden vor Jail
  nativeNotify(("~r~Inhaftiert~s~: " .. playerName .. " — %d Minuten in %s | Strafe: %s€"):format(math.ceil(jailSeconds/60), Config.JailName or "Gefaengnis", tostring(actualFine)), "polizei")
  nativeHudSet("jail", "GEFAENGNIS: " .. playerName .. " — " .. (Config.JailName or "JVA"), 255, 50, 50)
  nativeHudSet("jail_timer", "Verbleibend: " .. math.ceil(jailSeconds/60) .. " Min", 100, 180, 255)
  nativeHudSet("jail_fine", "Geldstrafe: " .. tostring(actualFine) .. " EUR", 255, 200, 50)
  DoScreenFadeIn(1000)
  releaseWarningShown = false
  -- Jail-Panel NUI: EINMAL oeffnen mit Gesamtzeit + Geldstrafe
  TriggerEvent('mtj_arrest:nui:jail', true, jailTotalSeconds, Config.JailName, Config.JailReason, actualFine)
  -- Jail-Countdown-Timer UI
  CreateThread(function()
    while jailSeconds > 0 and inJail do
      jailTime = jailSeconds
      -- NUR jail_tick senden (NICHT jailToggle wiederholt — das wuerde jailTotal zuruecksetzen!)
      local mins = math.floor(jailSeconds / 60)
      local secs = jailSeconds % 60
      nativeHudSet("jail_timer", ("Verbleibend: %02d:%02d"):format(mins, secs), 100, 180, 255)
      Wait(1000)
      jailSeconds = jailSeconds - 1
      TriggerEvent('mtj_arrest:nui:jail_tick', jailSeconds)

      -- Entlassungswarnung
      local ew = Config.Entlassungswarnung
      if ew and ew.Aktiviert and not releaseWarningShown then
        local warnAt = ew.SekundenVorher or 30
        if jailSeconds <= warnAt and jailSeconds > 0 then
          releaseWarningShown = true
          local msg = ew.Nachricht or "~g~Entlassung~s~: Du wirst in %d Sekunden freigelassen!"
          nativeNotify(msg:format(jailSeconds), "erfolg")
          dbg("Entlassungswarnung bei", jailSeconds, "Sekunden")
        end
      end
    end
    if inJail then
      -- Jailzeit vorbei: Entlassen UND vor das Tor teleportieren!
      TriggerEvent('mtj_arrest:nui:jail', false)
      nativeHudSet("jail", nil)
      nativeHudSet("jail_timer", nil)
      nativeHudSet("jail_fine", nil)
      FreezeEntityPosition(player, false)
      SetEnableHandcuffs(player, false)
      inJail = false
      jailTime = 0

      -- Waffen entfernen (Client-Ped) — Server prüft Waffenschein
      RemoveAllPedWeapons(player, true)
      SetCurrentPedWeapon(player, GetHashKey("WEAPON_UNARMED"), true)
      TriggerServerEvent('mtj_arrest:serverJailRelease')

      local release = Config.JailReleasePosition
      local heading = Config.JailReleaseHeading
      DoScreenFadeOut(1000)
      Wait(1100)
      SetEntityCoords(player, release.x, release.y, release.z)
      SetEntityHeading(player, heading)
      Wait(600)
      DoScreenFadeIn(1000)
      nativeNotify("~g~Entlassen~s~: " .. playerName .. " ist nun wieder auf freiem Fuss!", "erfolg")
      dbg("Jailzeit vorbei, Spieler vor das Gefängnis gesetzt!")
    end
  end)
end)

-- === POLIZEIAKTE BENACHRICHTIGUNG (vom Server) ===
RegisterNetEvent('mtj_arrest:clientAkteInfo')
AddEventHandler('mtj_arrest:clientAkteInfo', function(akte)
  if not akte then return end
  playerAkteStatus = akte.status or "unbescholten"
  dbg("Polizeiakte empfangen: Status =", playerAkteStatus, "Festnahmen =", akte.festnahmen or 0)
  -- Akte-Notification anzeigen wenn vorbestraft
  if playerAkteStatus ~= "unbescholten" then
    local pa = Config.Polizeiakte
    if pa and pa.NachrichtAkte then
      nativeNotify(pa.NachrichtAkte:format(playerAkteStatus, akte.festnahmen or 0, akte.fluchtversuche or 0), "warnung")
    end
  end
end)

-- === STRAFREGISTER BENACHRICHTIGUNG ===
RegisterNetEvent('mtj_arrest:clientVorstrafeInfo')
AddEventHandler('mtj_arrest:clientVorstrafeInfo', function(arrestCount)
  if not arrestCount or arrestCount <= 1 then return end
  local sr = Config.Strafregister
  if not sr or not sr.Aktiviert then return end
  local vorstrafen = arrestCount - 1
  local msg = sr.NachrichtVorstrafe or "~o~Strafregister~s~: %d Vorstrafe(n) — Strafe erhöht!"
  nativeNotify(msg:format(vorstrafen), "warnung")
  dbg("Strafregister: Vorstrafen =", vorstrafen)
end)

-- === SCENARIO-STATE ===

RegisterNetEvent('mtj_arrest:startScenario')
AddEventHandler('mtj_arrest:startScenario', function()
  -- Job-Freigabe: Spieler mit freigegebenen Jobs (z.B. police) sind exempt → kein Szenario.
  if IsPlayerExempt and IsPlayerExempt() then
    dbg("startScenario: Spieler ist Job-exempt — abgebrochen")
    SetPlayerWantedLevel(PlayerId(), 0, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    ClearPlayerWantedLevel(PlayerId())
    return
  end
  if scenarioActive then
    dbg("startScenario: already active")
    return
  end
  local now = GetGameTimer()
  -- Kein Szenario wenn Spieler tot ist (z.B. Race Condition vor Tod-Erkennung)
  if IsPedDeadOrDying(PlayerPedId(), true) then
    dbg("startScenario: Spieler ist tot — abgebrochen")
    return
  end
  -- Spawn-Sperre pruefen: verhindert Szenario-Start waehrend des Spawn-Vorgangs (Respawn-Grace).
  -- Gilt fuer ALLE Aufrufer (auch external_police.lua), nicht nur fuer wanted_level.lua.
  if wantedDeathLockUntil > 0 and now < wantedDeathLockUntil then
    dbg("startScenario: Spawn-Sperre aktiv, ignoriere")
    return
  end
  if (now - lastScenarioStart) < scenarioCooldown then
    dbg("startScenario: cooldown active, ignoring")
    return
  end
  if GetPlayerWantedLevel(PlayerId()) == 0 and lastKnownWanted == 0 then
    dbg("startScenario abgebrochen: Kein Wanted Level (GTA + lastKnownWanted beide 0)!")
    return
  end
  lastScenarioStart = now
  scenarioActive = true
  SetMaxWantedLevel(5) -- Sicherstellen dass 4+5 Sterne möglich sind
  canSurrender = false -- Noch nicht ergeben erlaubt bis Cops da sind
  jailRequested = false
  surrendered = false
  cuffed = false
  cuffing = false
  complianceCountdownThreadActive = false
  combatMaintenanceActive = false
  combatStartTime = 0
  nachlassenNotifiedStage = 0
  wantedDropCount = 0
  -- pursuitStartTime bleibt bestehen ueber Szenario-Neustarts (Stale-Timeout)
  -- Wird nur gesetzt wenn noch keine aktive Verfolgung laeuft
  if pursuitStartTime == 0 then
    pursuitStartTime = GetGameTimer()
    dbg("pursuitStartTime gesetzt (neue Verfolgung)")
  end
  complianceWindow = Config.ComplianceWindow
  fluchtversuchTriggered = false
  scenarioStartPos = GetEntityCoords(PlayerPedId())
  -- Wanted-Level sofort speichern fuer WantedMaintenance-Thread
  lastKnownWanted = GetPlayerWantedLevel(PlayerId())
  if lastKnownWanted < 1 then lastKnownWanted = Config.RequiredWantedLevel or 2 end

  -- Erkennung: Ist dies ein Neustart waehrend laufender Verfolgung?
  -- Nur wenn pursuitStartTime > 0 UND mindestens ein lebender Cop existiert
  local hasAliveCop = false
  local ppos = GetEntityCoords(PlayerPedId())
  for _, ped in ipairs(cops) do
    if DoesEntityExist(ped) and not IsEntityDead(ped) then
      hasAliveCop = true
      break
    end
  end
  local isRestart = pursuitStartTime > 0 and hasAliveCop

  -- Polizeiakte vom Server laden (fuer status-basierte Texte)
  TriggerServerEvent('mtj_arrest:requestAkte')
  TriggerServerEvent('mtj_arrest:dispatch:pursuitStart', lastKnownWanted)

  CreateThread(function()
    if isRestart then
      -- === CONTINUATION RESTART: Verfolgung laeuft weiter ===
      -- Keine neuen Cops spawnen, direkt in Kampfphase
      dbg("startScenario: CONTINUATION RESTART (pursuitStartTime>0, cops:", #cops, ") → direkt in Kampfphase")
      setAmbientCopsIgnore(true)
      -- Cops die noch leben sofort reaktivieren
      reactivatePolice()
      startCombatMaintenance()
    else
      -- === NEUER START: Polizei spawnen ===
    -- ETAPPE 1: Polizei spawnen (Cops, Fahrzeuge, Helikopter — alles laut Config)
    clearCops()
    clearRoadblocks()
    spawnCopsAroundPlayer()
    -- Fahrzeuge und Helikopter sofort spawnen (laut Config pro Wanted-Level)
    local initWanted = getEffectiveWanted()
    local maxVeh = getMaxVehiclesForWanted()
    for v = 1, maxVeh do
      spawnPoliceVehicle()
      Wait(200)
    end
    local heliLevel = Config.HeliWantedLevel or 3
    if initWanted >= heliLevel then
      local ht = Config.HelisPerWantedLevel
      local maxHeli = (ht and ht[initWanted]) or Config.MaxHelis or 1
      for h = 1, maxHeli do
        spawnPoliceHeli()
        Wait(200)
      end
    end
    setAmbientCopsIgnore(true)
    dbg("startScenario: cops/vehicles/helis spawned, warte auf Ankunft...")

    -- ETAPPE 2: Warten bis mindestens ein Cop im Aktionsradius ist
    local arrivalRadius = Config.Aktionsradius
    local arrivalTimeout = GetGameTimer() + ((Config.AktionsradiusTimeout or 20) * 1000)
    while scenarioActive and not isAnyCopNearPlayer(arrivalRadius) and GetGameTimer() < arrivalTimeout do
      Wait(500)
    end
    if not scenarioActive then
      dbg("startScenario: Szenario waehrend Warten beendet")
      return
    end
    dbg("startScenario: Cops angekommen, starte Compliance-Countdown")

    -- ETAPPE 3: Compliance-Countdown
    runNegotiationAndCompliance()
    end -- Ende: else (NEUER START)
  end)
end)

RegisterNetEvent('mtj_arrest:endScenario')
AddEventHandler('mtj_arrest:endScenario', function()
  local wasInPursuit = lastKnownWanted > 0
  scenarioActive = false
  canSurrender = false
  surrendered = false
  cuffed = false
  cuffing = false
  jailRequested = false
  complianceWindow = 0
  complianceCountdownThreadActive = false
  combatMaintenanceActive = false
  combatStartTime = 0
  nachlassenNotifiedStage = 0
  wantedDropCount = 0
  fluchtversuchTriggered = false
  scenarioStartPos = nil
  evasionStartTime = 0
  evasionNotifiedAt = 0
  gpsTrackerActive = false  -- GPS-Tracker freigeben fuer naechstes Szenario
  gpsLastHeliUpdate = 0
  hideScenarioUI()
  hideCombatHUD()
  nativeHudClear()
  -- Spieler-Freeze aufheben wenn er gerade in einer Festnahme-Animation war
  -- (verhindert ewige Bewegungseinschraenkung wenn Sterne waehrend Festnahme weggehen)
  if not inJail then
    FreezeEntityPosition(PlayerPedId(), false)
    SetEnableHandcuffs(PlayerPedId(), false)
  end
  -- Cops NUR loeschen wenn Verfolgung WIRKLICH vorbei ist
  -- Bei Stale-Timeout-Neustarts (lastKnownWanted > 0) bleiben Cops bestehen!
  -- Das verhindert das "alles wird geloescht" Problem bei laufender Verfolgung
  if wasInPursuit then
    -- Verfolgung laeuft noch → Cops behalten, sie kaempfen weiter
    dbg("endScenario: Cops BEIBEHALTEN (lastKnownWanted > 0, Verfolgung laeuft noch)")
    -- Cops trotzdem kampfbereit halten (Relationship bleibt HATE)
  else
    -- Wanted wirklich 0 → alles aufraeumen
    clearCops()
    clearRoadblocks()
    -- Ambient-Cops NUR zurueckschalten wenn Spieler lebt.
    -- Beim Tod setzt der death-handler SetPoliceIgnorePlayer(true) — wuerden wir es hier sofort
    -- auf false setzen, griffen GTA-Ambient-Cops den Spieler ohne Wanted-Sterne an.
    if not IsPedDeadOrDying(PlayerPedId(), true) then
      setAmbientCopsIgnore(false)
    end
  end
  dbg("endScenario: scenario ended, lastKnownWanted:", lastKnownWanted)
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
        local wanted = getEffectiveWanted()
        local schwelle = Config.KleindeliktSchwelle or 2
        if wanted <= schwelle then
          dbg("Kleindelikt-Flow (wanted=" .. wanted .. " <= schwelle=" .. schwelle .. ")")
          playFineSequence()
        else
          playCuffSequence()
        end
      end
    else
      Wait(250)
    end
  end
end)

-- Erzwungene Übergabe via /mtj_force_surrender Befehl
AddEventHandler('mtj_arrest:forceSurrender', function()
  if not scenarioActive then
    dbg("forceSurrender: kein aktives Szenario")
    return
  end
  if surrendered or cuffing or cuffed or inJail then
    dbg("forceSurrender: Guard aktiv — nicht ausfuehrbar")
    return
  end
  dbg("forceSurrender: Erzwungene Übergabe")
  surrendered = true
  canSurrender = false
  local wanted = getEffectiveWanted()
  local schwelle = Config.KleindeliktSchwelle or 2
  if wanted <= schwelle then
    playFineSequence()
  else
    playCuffSequence()
  end
end)

-- === WANTED-LEVEL-ÜBERWACHUNG ===
-- Prueft ob Wanted WIRKLICH auf 0 ist (nicht nur GTA Race-Condition)
-- Erfordert 3 aufeinanderfolgende Checks mit Wanted=0 UND lastKnownWanted=0

local wantedZeroStreak = 0 -- Zaehler fuer aufeinanderfolgende Wanted=0 Checks (Sicherheitsnetz)

CreateThread(function()
  while true do
    Wait(1000)
    if scenarioActive then
      local gtaWanted = GetPlayerWantedLevel(PlayerId())
      if gtaWanted == 0 and lastKnownWanted == 0 then
        -- Beide 0: primärer Pfad ist WantedMaintenance; dieser Thread ist reines Sicherheitsnetz.
        -- 1 Sekunde Wartezeit reicht, da WantedMaintenance bereits 3s Grace-Period abgewartet hat.
        wantedZeroStreak = wantedZeroStreak + 1
        if wantedZeroStreak >= 3 then
          -- Erst nach 3 aufeinanderfolgenden Checks (3s) sicher szenario beenden.
          -- Kein wantedDeathLockUntil setzen: das Szenario endet wegen echtem Wanted=0,
          -- nicht wegen Tod/Entkommen — ein Lock wuerde neue Verbrechen 5s lang blockieren.
          dbg("Wanted-Ueberwachung (Sicherheitsnetz): Wanted = 0 (3x), beende Szenario")
          pursuitStartTime = 0
          wantedZeroStreak = 0
          TriggerEvent('mtj_arrest:endScenario')
        end
      else
        wantedZeroStreak = 0
      end
    else
      wantedZeroStreak = 0
      Wait(2000)
    end
  end
end)

-- === AUTOHIDE UI, falls Spieler stirbt oder despawnt ===

-- ═══════════════════════════════════════════════════════════════
-- RESET SCRIPT STATE — gemeinsamer Reset für Refresh, Spawn, Stop
-- ═══════════════════════════════════════════════════════════════
local function resetScriptState()
  scenarioActive = false
  canSurrender = false
  surrendered = false
  cuffed = false
  cuffing = false
  jailRequested = false
  complianceWindow = 0
  complianceCountdownThreadActive = false
  combatMaintenanceActive = false
  combatStartTime = 0
  nachlassenNotifiedStage = 0
  pursuitStartTime = 0
  wantedDropCount = 0
  fluchtversuchTriggered = false
  scenarioStartPos = nil
  lastKnownWanted = 0
  evasionStartTime = 0
  evasionNotifiedAt = 0
  gpsTrackerActive = false
  gpsLastHeliUpdate = 0
  releaseWarningShown = false
  inJail = false
  wantedDeathLockUntil = 0
  deadBodies = {}
  FreezeEntityPosition(PlayerPedId(), false)
  SetEnableHandcuffs(PlayerPedId(), false)
  SetPlayerWantedLevel(PlayerId(), 0, false)
  SetPlayerWantedLevelNow(PlayerId(), false)
  ClearPlayerWantedLevel(PlayerId())
  hideScenarioUI()
  hideCombatHUD()
  nativeHudClear()
  TriggerEvent('mtj_arrest:nui:jail', false)
  clearCops()
  clearRoadblocks()
  clearHelis()
  clearPoliceVehicles()
  setAmbientCopsIgnore(false)
end

-- Refresh-Event: kann von /mtj_refresh oder externen Systemen gefeuert werden
AddEventHandler('mtj_arrest:refreshScript', function()
  resetScriptState()
  nativeNotify("~g~[MTJ] Script-Zustand zurückgesetzt!", "erfolg")
  dbg("mtj_arrest:refreshScript: resetScriptState() aufgerufen")
end)

AddEventHandler('playerSpawned', function()
  resetScriptState()
  -- Sperre nach Wiederbelebung: kein Wanted-Neustart fuer RespawnGraceSek Sekunden
  wantedDeathLockUntil = GetGameTimer() + ((Config.RespawnGraceSek or 10) * 1000)
  -- Aktive Wanted-Unterdrueckung: GTA weist nach Respawn sofort 1 Stern zu wenn Cops in der Naehe sind.
  -- SetPoliceIgnorePlayer(true) + periodisches ClearPlayerWantedLevel fuer die gesamte Grace Period.
  SetPoliceIgnorePlayer(PlayerId(), true)
  local suppressUntil = wantedDeathLockUntil
  CreateThread(function()
    while GetGameTimer() < suppressUntil do
      SetPlayerWantedLevel(PlayerId(), 0, false)
      SetPlayerWantedLevelNow(PlayerId(), false)
      ClearPlayerWantedLevel(PlayerId())
      Wait(500)
    end
    if not scenarioActive then
      SetPoliceIgnorePlayer(PlayerId(), false)
    end
    dbg("playerSpawned: Wanted-Grace-Period abgelaufen, SetPoliceIgnorePlayer(false)")
  end)
  -- Waffen NUR entfernen wenn Spieler waehrend Polizeieinsatz gestorben ist
  local wbt = Config.WaffenBeiTod
  if wbt and wbt.Aktiviert and diedDuringScenario then
    removeAllWeaponsComplete(PlayerPedId())
    TriggerServerEvent('mtj_arrest:serverClearWeapons')
    nativeNotify(wbt.Nachricht or ("Waffen von " .. playerName .. " nach dem Polizeieinsatz sichergestellt!"), "warnung")
    dbg("playerSpawned: Waffen bei Einsatz-Tod entfernt (Client + Server)")
  end
  diedDuringScenario = false
  playerName = GetPlayerName(PlayerId()) or "Unbekannt"
  dbg("playerSpawned: resetScriptState() + wanted auf 0")
end)

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  resetScriptState()
  dbg("onResourceStop: resetScriptState() aufgerufen")
end)

-- === DISPATCH SYSTEM: Verfolgungen anderer Spieler empfangen ===
RegisterNetEvent('mtj_arrest:dispatch:notify')
AddEventHandler('mtj_arrest:dispatch:notify', function(data)
  if not data then return end
  local myId = GetPlayerServerId(PlayerId())
  if data.playerId == myId then return end
  local dc = Config.Dispatch
  if not dc or not dc.Aktiviert then return end
  if data.type == "start" then
    local stars = string.rep("★", data.wanted or 2)
    nativeNotify(("~r~POLIZEIFUNK~s~: Verfolgungsjagd! %s | %s"):format(data.player or "?", stars), "polizei")
    if data.coords and dc.BlipAktiv then
      local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
      SetBlipSprite(blip, 58)
      SetBlipScale(blip, 1.2)
      SetBlipColour(blip, 1)
      SetBlipFlashes(blip, true)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString("Polizeieinsatz: " .. (data.player or "?"))
      EndTextCommandSetBlipName(blip)
      SetTimeout(30000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
      end)
    end
  elseif data.type == "end" then
    local reason = data.reason or "unbekannt"
    if reason == "verhaftet" then
      nativeNotify(("~g~POLIZEIFUNK~s~: %s wurde verhaftet."):format(data.player or "?"), "erfolg")
    elseif reason == "entkommen" then
      nativeNotify(("~o~POLIZEIFUNK~s~: %s ist entkommen!"):format(data.player or "?"), "warnung")
    end
  end
end)

print("[mtj_arrest] main.lua loaded")