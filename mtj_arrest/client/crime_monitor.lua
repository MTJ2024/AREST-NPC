-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- client/crime_monitor.lua
-- GTA Online-Stil Verbrechenserkennung: Vergibt Wanted-Sterne fuer Verbrechen.
-- FiveMs natives Verbrechenssystem (GTA V Engine) funktioniert im Multiplayer
-- nicht zuverlaessig — GetPlayerWantedLevel() gibt nach Verbrechen oft 0 zurueck.
-- Dieser Thread erkennt Taten client-seitig und ruft SetPlayerWantedLevel direkt auf.

local SCAN_MS      = 500    -- Prüfintervall in ms
local SCAN_RADIUS  = 100.0  -- Tötungsdetektierung innerhalb dieses Radius (Meter)
local SHOOT_WARMUP = 2500   -- ms Dauerschießen bis der erste Stern vergeben wird

-- State
local shootingSince  = 0     -- GetGameTimer() Zeitstempel Schießbeginn (0 = schießt nicht)
local shootingWanted = false -- Hat Schießen bereits 1★ ausgelöst (Reset bei Stop)
local deathSeen      = {}    -- [entityHandle] → GameTimer-ts (bereits gezählt, no double-count)
local lastCleanup    = 0

-- pendingWanted: der Wanted-Level den crime_monitor setzen will.
-- GTA/FiveM loescht Wanted sofort im naechsten Frame (Multiplayer-Eigenheit).
-- Diesen Wert halten wir jedes Tick aufrecht bis das Szenario startet und
-- selbst die Wanted-Verwaltung uebernimmt (main.lua WantedMaintenance).
local pendingWanted = 0

-- Sobald das Szenario startet, uebernimmt main.lua die Wanted-Verwaltung.
-- pendingWanted zuruecksetzen damit crime_monitor nicht mehr eingreift.
AddEventHandler('mtj_arrest:startScenario', function()
  pendingWanted = 0
end)
-- Nach Szenario-Ende (Verhaftung, Entkommen, Neustart) ebenfalls zuruecksetzen.
AddEventHandler('mtj_arrest:endScenario', function()
  pendingWanted = 0
end)

-- Cop-Modell-Hashes (lazy built once): Tötung von Cops zählt NICHT als Crime
-- (Cops werden vom Szenario selbst verwaltet und sterben im Kampf)
local COP_HASHES = nil
local function getCopHashes()
  if COP_HASHES then return COP_HASHES end
  local models = (Config and Config.PoliceModels) or {
    "s_m_y_cop_01", "s_f_y_cop_01",
    "s_m_y_sheriff_01", "s_m_m_sheriff_01",
    "s_m_y_swat_01",   "s_m_y_ranger_01",
    "s_m_m_fibsec_01", "s_m_y_hwaycop_01",
  }
  COP_HASHES = {}
  for _, m in ipairs(models) do
    COP_HASHES[GetHashKey(m)] = true
  end
  return COP_HASHES
end

local function isCopPed(ped)
  return getCopHashes()[GetEntityModel(ped)] == true
end

-- Wanted-Level erhöhen (respektiert Config.CrimeMonitor.MaxWanted)
-- Setzt auch pendingWanted, damit der Wert per Tick aufrechterhalten wird
-- bis das Szenario startet.
local function addWanted(stars)
  local cfg  = Config and Config.CrimeMonitor
  local maxW = (cfg and cfg.MaxWanted) or 5
  local pid  = PlayerId()
  local cur  = math.max(GetPlayerWantedLevel(pid), pendingWanted)
  local nw   = math.min(cur + stars, maxW)
  if nw > cur then
    pendingWanted = nw
    SetPlayerWantedLevel(pid, nw, false)
    SetPlayerWantedLevelNow(pid, false)
  end
end

CreateThread(function()
  while true do
    Wait(SCAN_MS)

    local cfg = Config and Config.CrimeMonitor
    -- CrimeMonitor deaktiviert?
    if cfg and cfg.Aktiviert == false then goto continue end

    -- Spieler ist tot: sofort alles zuruecksetzen, kein Crime-Wanted
    -- Diese Pruefung laeuft BEVOR der DeathLock gesetzt wird (200ms Fenster nach Tod)
    -- und verhindert, dass pendingWanted in dieser Luecke wiederholt angewendet wird.
    if IsPedDeadOrDying(PlayerPedId(), true) then
      shootingSince = 0; shootingWanted = false; pendingWanted = 0
      goto continue
    end

    -- Grace-Period nach Tod / Respawn: kein Crime-Wanted (Spieler ist gerade gestorben)
    local deathLock = (GetWantedDeathLockUntil and GetWantedDeathLockUntil()) or 0
    if deathLock > 0 and GetGameTimer() < deathLock then
      shootingSince = 0; shootingWanted = false; pendingWanted = 0
      goto continue
    end

    -- Exempt-Spieler (Police/Admin): niemals Wanted vergeben
    if IsPlayerExempt and IsPlayerExempt() then
      shootingSince = 0; shootingWanted = false; pendingWanted = 0
      goto continue
    end

    -- ── pendingWanted aufrechterhalten (vor Szenario-Start) ─────────────────
    -- GTA/FiveM loescht SetPlayerWantedLevel() sofort im naechsten Frame.
    -- Wir stellen den Wert jedes Tick (500 ms) wieder her, bis das Szenario
    -- startet und main.lua die Verwaltung uebernimmt.
    if pendingWanted > 0 then
      local curW = GetPlayerWantedLevel(PlayerId())
      if curW == 0 then
        SetPlayerWantedLevel(PlayerId(), pendingWanted, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
      elseif curW > pendingWanted then
        pendingWanted = curW  -- extern erhoeht (z.B. durch Eskalation)
      end
    end

    -- Szenario läuft bereits: Wanted wird vom Szenario selbst verwaltet (Eskalation, Nachlassen etc.)
    -- Hier nicht eingreifen – sonst Konflikte mit Kleindelikt-Schwelle und Fluchtversuch-Logik
    if IsArrestScenarioActive and IsArrestScenarioActive() then
      shootingSince = 0; shootingWanted = false
      goto continue
    end

    local playerPed = PlayerPedId()
    local now       = GetGameTimer()

    -- ── Schießen-Erkennung ──────────────────────────────────────────────────
    -- Nach SchiessWarmupMs Dauerschießen → 1★ (verhindert Fehlalarme durch kurze Schüsse)
    local schiessGibt = (cfg == nil or cfg.SchiessGibtWanted ~= false)
    local warmupMs    = (cfg and cfg.SchiessWarmupMs) or SHOOT_WARMUP
    if schiessGibt then
      if IsPedShooting(playerPed) then
        if shootingSince == 0 then
          shootingSince  = now
          shootingWanted = false
        elseif not shootingWanted and (now - shootingSince) >= warmupMs then
          shootingWanted = true
          addWanted(1)
        end
      else
        -- Schießen gestoppt: State zurücksetzen damit nächste Salve neu zählt
        shootingSince  = 0
        shootingWanted = false
      end
    end

    -- ── Tötungs-Erkennung ───────────────────────────────────────────────────
    -- Scannt nahe Peds: tot + vom Spieler beschädigt + kein Cop + im Radius
    local killGibt   = (cfg == nil or cfg.KillGibtWanted ~= false)
    local killSterne = (cfg and cfg.KillSterne) or 1
    if killGibt then
      local ppos = GetEntityCoords(playerPed)
      local handle, firstPed = FindFirstPed()
      if handle ~= -1 then
        local ok  = true
        local ped = firstPed
        repeat
          if ped ~= 0 and DoesEntityExist(ped)
              and not IsPedAPlayer(ped)
              and IsPedDeadOrDying(ped, true)
              and not isCopPed(ped) then
            -- Distanz zuerst prüfen (günstig) — bevor HasEntityBeenDamagedByEntity (teuer)
            local dist = #(GetEntityCoords(ped) - ppos)
            if dist <= SCAN_RADIUS
                and not deathSeen[ped]
                and HasEntityBeenDamagedByEntity(ped, playerPed, false) then
              deathSeen[ped] = now
              addWanted(killSterne)
            end
          end
          ok, ped = FindNextPed(handle)
        until not ok
        EndFindPed(handle)
      end
    end

    -- ── deathSeen Cleanup ───────────────────────────────────────────────────
    -- Alle 60s: Entities die nicht mehr existieren aus der Tabelle entfernen
    -- (verhindert ungebremsten Speicherwachstum bei langer Spielsession)
    if now - lastCleanup > 60000 then
      lastCleanup = now
      for handle in pairs(deathSeen) do
        if not DoesEntityExist(handle) then
          deathSeen[handle] = nil
        end
      end
    end

    ::continue::
  end
end)
