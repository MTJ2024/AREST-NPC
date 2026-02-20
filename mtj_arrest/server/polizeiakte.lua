-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  github.com/MTJ2024/AREST-NPC                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  POLIZEIAKTE — Persistente NPC-Akte pro Spieler                 ║
-- ║  Speichert Festnahmen, Strafen, Fluchtversuche dauerhaft        ║
-- ║  Verwendet FiveM Server KVP (kein MySQL nötig)                  ║
-- ╚══════════════════════════════════════════════════════════════════╝

local DEBUG = true
local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest][Polizeiakte] %s"):format(table.concat(t, " ")))
end

local Config = Config or {}

-- ══════════════════════════════════════════════════════════════════
--  KVP HELPER: Lesen / Schreiben (persistiert über Restarts)
-- ══════════════════════════════════════════════════════════════════

local KVP_PREFIX = "mtj_akte:"

local function kvpKey(identifier, field)
  return KVP_PREFIX .. identifier .. ":" .. field
end

local function kvpGetInt(identifier, field, default)
  local val = GetResourceKvpInt(kvpKey(identifier, field))
  if val == 0 and default and default ~= 0 then
    return default
  end
  return val
end

local function kvpSetInt(identifier, field, value)
  SetResourceKvpInt(kvpKey(identifier, field), value)
end

local function kvpGetString(identifier, field, default)
  local val = GetResourceKvpString(kvpKey(identifier, field))
  if not val or val == "" then return default or "" end
  return val
end

local function kvpSetString(identifier, field, value)
  SetResourceKvp(kvpKey(identifier, field), tostring(value))
end

-- ══════════════════════════════════════════════════════════════════
--  SPIELER-IDENTIFIKATION (License-basiert, funktioniert ohne DB)
-- ══════════════════════════════════════════════════════════════════

local playerIdentifiers = {} -- Cache: src → identifier

local function getPlayerIdentifier(src)
  if playerIdentifiers[src] then return playerIdentifiers[src] end
  local identifiers = GetPlayerIdentifiers(src)
  if identifiers then
    for _, id in ipairs(identifiers) do
      if string.find(id, "license:") then
        playerIdentifiers[src] = id
        return id
      end
    end
    -- Fallback: erster Identifier
    if #identifiers > 0 then
      playerIdentifiers[src] = identifiers[1]
      return identifiers[1]
    end
  end
  return nil
end

AddEventHandler('playerDropped', function()
  playerIdentifiers[source] = nil
end)

-- ══════════════════════════════════════════════════════════════════
--  POLIZEIAKTE: Daten lesen / schreiben
-- ══════════════════════════════════════════════════════════════════

-- Komplette Akte eines Spielers laden
local function getAkte(src)
  local id = getPlayerIdentifier(src)
  if not id then return nil end
  return {
    identifier      = id,
    festnahmen      = kvpGetInt(id, "festnahmen", 0),
    gesamtHaftzeit  = kvpGetInt(id, "gesamt_haftzeit", 0),    -- Minuten gesamt
    gesamtGeldstrafe = kvpGetInt(id, "gesamt_geldstrafe", 0), -- € gesamt
    fluchtversuche  = kvpGetInt(id, "fluchtversuche", 0),
    letztesFestnahme = kvpGetString(id, "letzte_festnahme", ""),
    status          = kvpGetString(id, "status", "unbescholten"),
  }
end

-- Festnahme in Akte eintragen
local function recordArrest(src, haftMinuten, geldstrafe)
  local id = getPlayerIdentifier(src)
  if not id then return nil end

  local festnahmen = kvpGetInt(id, "festnahmen", 0) + 1
  local gesamtHaft = kvpGetInt(id, "gesamt_haftzeit", 0) + (haftMinuten or 0)
  local gesamtGeld = kvpGetInt(id, "gesamt_geldstrafe", 0) + (geldstrafe or 0)

  kvpSetInt(id, "festnahmen", festnahmen)
  kvpSetInt(id, "gesamt_haftzeit", gesamtHaft)
  kvpSetInt(id, "gesamt_geldstrafe", gesamtGeld)
  kvpSetString(id, "letzte_festnahme", os.date("!%Y-%m-%d %H:%M"))

  -- Status automatisch berechnen
  local cfg = Config.Polizeiakte or {}
  local stufen = cfg.Stufen or {}
  local status = "unbescholten"
  for i = #stufen, 1, -1 do
    if festnahmen >= stufen[i].AbFestnahmen then
      status = stufen[i].Status
      break
    end
  end
  kvpSetString(id, "status", status)

  dbg(("Festnahme #%d eingetragen für %s — Status: %s"):format(festnahmen, id, status))
  return festnahmen, status
end

-- Fluchtversuch in Akte eintragen
local function recordFluchtversuch(src)
  local id = getPlayerIdentifier(src)
  if not id then return end
  local count = kvpGetInt(id, "fluchtversuche", 0) + 1
  kvpSetInt(id, "fluchtversuche", count)
  dbg(("Fluchtversuch #%d eingetragen für %s"):format(count, id))
end

-- Strafmultiplikator aus Akte berechnen
local function getAkteMultiplier(src)
  local id = getPlayerIdentifier(src)
  if not id then return 1.0, 1.0 end

  local cfg = Config.Polizeiakte or {}
  if not cfg.Aktiviert then return 1.0, 1.0 end

  local festnahmen = kvpGetInt(id, "festnahmen", 0)
  local fluchtversuche = kvpGetInt(id, "fluchtversuche", 0)
  local stufen = cfg.Stufen or {}

  -- Passende Stufe finden (höchste zuerst)
  local haftMult = 1.0
  local geldMult = 1.0
  for i = #stufen, 1, -1 do
    if festnahmen >= stufen[i].AbFestnahmen then
      haftMult = stufen[i].HaftzeitMultiplikator or 1.0
      geldMult = stufen[i].GeldstrafeMultiplikator or 1.0
      break
    end
  end

  -- Fluchtversuche erhöhen Multiplikator zusätzlich
  local fluchtExtra = (cfg.FluchtversuchExtra or 0.1) * fluchtversuche
  haftMult = haftMult + fluchtExtra
  geldMult = geldMult + fluchtExtra

  -- Max-Cap
  local maxMult = cfg.MaxMultiplikator or 5.0
  haftMult = math.min(haftMult, maxMult)
  geldMult = math.min(geldMult, maxMult)

  return haftMult, geldMult
end

-- ══════════════════════════════════════════════════════════════════
--  EXPORTS: Für server/main.lua
-- ══════════════════════════════════════════════════════════════════

-- Globale Funktionen (im gleichen Resource-Kontext)
_G.PolizeiakteGet         = getAkte
_G.PolizeiakteRecord      = recordArrest
_G.PolizeiakteFlucht      = recordFluchtversuch
_G.PolizeiakteMultiplier  = getAkteMultiplier
_G.PolizeiakteGetIdentifier = getPlayerIdentifier

-- ══════════════════════════════════════════════════════════════════
--  SERVER EVENT: Fluchtversuch vom Client melden
-- ══════════════════════════════════════════════════════════════════

RegisterNetEvent('mtj_arrest:serverFluchtversuch')
AddEventHandler('mtj_arrest:serverFluchtversuch', function()
  local src = source
  recordFluchtversuch(src)
end)

-- ══════════════════════════════════════════════════════════════════
--  SERVER EVENT: Akte abfragen (für Client-Anzeige)
-- ══════════════════════════════════════════════════════════════════

RegisterNetEvent('mtj_arrest:requestAkte')
AddEventHandler('mtj_arrest:requestAkte', function()
  local src = source
  local akte = getAkte(src)
  if akte then
    TriggerClientEvent('mtj_arrest:clientAkteInfo', src, akte)
  end
end)

-- Vollständige Akte für NPC-Einsicht (mit Stufen-Details)
RegisterNetEvent('mtj_arrest:requestFullAkte')
AddEventHandler('mtj_arrest:requestFullAkte', function()
  local src = source
  local akte = getAkte(src)
  if not akte then
    TriggerClientEvent('mtj_arrest:clientFullAkte', src, nil)
    return
  end

  -- Stufen-Info hinzufügen
  local cfg = Config.Polizeiakte or {}
  local stufen = cfg.Stufen or {}
  local currentStufe = nil
  for i = #stufen, 1, -1 do
    if akte.festnahmen >= stufen[i].AbFestnahmen then
      currentStufe = stufen[i]
      break
    end
  end

  -- Nächste Stufe berechnen
  local naechsteStufe = nil
  for _, s in ipairs(stufen) do
    if akte.festnahmen < s.AbFestnahmen then
      naechsteStufe = s
      break
    end
  end

  akte.haftzeitMultiplikator = currentStufe and currentStufe.HaftzeitMultiplikator or 1.0
  akte.geldstrafeMultiplikator = currentStufe and currentStufe.GeldstrafeMultiplikator or 1.0
  akte.naechsteStufeStatus = naechsteStufe and naechsteStufe.Status or nil
  akte.naechsteStufeAb = naechsteStufe and naechsteStufe.AbFestnahmen or nil
  akte.serverName = cfg.ServerName or "GreenZone420 PD"

  TriggerClientEvent('mtj_arrest:clientFullAkte', src, akte)
  dbg(("Vollständige Akte gesendet an Spieler %d"):format(src))
end)

dbg("Polizeiakte-System geladen (KVP-persistent)")
