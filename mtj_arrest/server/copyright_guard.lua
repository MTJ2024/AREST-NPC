-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

local AUTHOR        = "MTJ"
local AUTHOR_FULL   = "MTJ2024"
local RES_NAME      = "mtj_arrest"
local COPYRIGHT     = "Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten."
local SIGNATURE     = "AREST-NPC-MTJ2024-PLAGIATSCHUTZ"
local violations    = 0
local MAX_WARNINGS  = 3

local function warn(msg)
  print("^1[PLAGIATSCHUTZ] " .. msg .. "^7")
end

local function info(msg)
  print("^2[mtj_arrest] " .. msg .. "^7")
end

local function critical(msg)
  print("^1^5[!!!] " .. msg .. " [!!!]^7")
end

local function isKnownResourceName(resName)
  return string.find(resName, "AREST", 1, true) or string.find(resName, AUTHOR, 1, true)
end

local function checkAuthor()
  local resName = GetCurrentResourceName()
  -- Resource-Name selbst (z.B. "AREST-NPC") ist ein gueltiger Nachweis
  if isKnownResourceName(resName) then
    return true
  end
  local metaAuthor = GetResourceMetadata(resName, 'author', 0) or ""
  if not string.find(metaAuthor, AUTHOR, 1, true) then
    return false, "Author-Metadaten manipuliert (erwartet: " .. AUTHOR_FULL .. ", gefunden: " .. metaAuthor .. ")"
  end
  return true
end

local function checkDescription()
  local resName = GetCurrentResourceName()
  -- Resource-Name selbst (z.B. "AREST-NPC") ist ein gueltiger Nachweis
  if isKnownResourceName(resName) then
    return true
  end
  local metaDesc = GetResourceMetadata(resName, 'description', 0) or ""
  if metaDesc ~= "" and not string.find(metaDesc, "MTJ", 1, true) and not string.find(metaDesc, "AREST", 1, true) and not string.find(metaDesc, "Arrest", 1, true) then
    return false, "Beschreibung verdaechtig veraendert"
  end
  return true
end

local function checkResourceFiles()
  local resName = GetCurrentResourceName()
  local expectedFiles = {
    "client/main.lua",
    "config/config.lua",
    "fxmanifest.lua"
  }
  for _, file in ipairs(expectedFiles) do
    local content = LoadResourceFile(resName, file)
    if not content then
      return false, "Kritische Datei fehlt: " .. file
    end
    if not string.find(content, AUTHOR_FULL, 1, true) then
      return false, "Copyright-Header entfernt aus: " .. file
    end
    if not string.find(content, "Plagiatschutz", 1, true) then
      return false, "Plagiatschutz-Markierung entfernt aus: " .. file
    end
  end
  return true
end

local function checkSignature()
  local resName = GetCurrentResourceName()
  local guard = LoadResourceFile(resName, "server/copyright_guard.lua")
  if not guard then
    return false, "copyright_guard.lua geloescht!"
  end
  if not string.find(guard, SIGNATURE, 1, true) then
    return false, "Plagiatschutz-Signatur manipuliert!"
  end
  return true
end

local function checkFxManifest()
  local resName = GetCurrentResourceName()
  local manifest = LoadResourceFile(resName, "fxmanifest.lua")
  if not manifest then
    return false, "fxmanifest.lua fehlt!"
  end
  if not string.find(manifest, "copyright_guard", 1, true) then
    return false, "copyright_guard.lua aus fxmanifest entfernt!"
  end
  return true
end

local function runAllChecks()
  local checks = {
    { name = "Author-Metadaten",     fn = checkAuthor },
    { name = "Beschreibung",         fn = checkDescription },
    { name = "Datei-Integritaet",    fn = checkResourceFiles },
    { name = "Signatur",             fn = checkSignature },
    { name = "Manifest-Integritaet", fn = checkFxManifest },
  }

  local allOk = true
  local issues = {}

  for _, check in ipairs(checks) do
    local ok, reason = check.fn()
    if not ok then
      allOk = false
      table.insert(issues, check.name .. ": " .. (reason or "Fehler"))
    end
  end

  return allOk, issues
end

local function handleViolation(issues)
  violations = violations + 1
  critical("╔═══════════════════════════════════════════════════════╗")
  critical("║         PLAGIAT / URHEBERRECHTSVERLETZUNG            ║")
  critical("║  Diese Software ist Eigentum von " .. AUTHOR_FULL .. ".           ║")
  critical("║  Unbefugte Nutzung wird rechtlich verfolgt.          ║")
  critical("╚═══════════════════════════════════════════════════════╝")
  for _, issue in ipairs(issues) do
    warn("  → " .. issue)
  end
  warn("Verstoss Nr. " .. violations .. " von max. " .. MAX_WARNINGS)

  if violations >= MAX_WARNINGS then
    critical("MAXIMALE VERSTOESSE ERREICHT — Resource wird gestoppt!")
    Wait(5000)
    local resName = GetCurrentResourceName()
    StopResource(resName)
  end
end

CreateThread(function()
  Wait(2000)
  local ok, issues = runAllChecks()
  if ok then
    info(COPYRIGHT)
    info("Plagiatschutz: Alle Pruefungen bestanden.")
    info("Signatur: " .. SIGNATURE)
  else
    handleViolation(issues)
  end

  while true do
    Wait(1800000)
    local ok2, issues2 = runAllChecks()
    if not ok2 then
      handleViolation(issues2)
    end
  end
end)
