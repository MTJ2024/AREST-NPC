-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  github.com/MTJ2024/AREST-NPC                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
--
-- COPYRIGHT GUARD: Integritaetspruefung und Diebstahlschutz
-- Prueft beim Start ob die Resource-Metadaten korrekt sind
-- und gibt bei Manipulation eine Warnung aus.

local AUTHOR    = "MTJ"
local RES_NAME  = "mtj_arrest"
local COPYRIGHT = "Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten."
local REPO      = "github.com/MTJ2024/AREST-NPC"

local function warn(msg)
  print("^1[COPYRIGHT WARNING] " .. msg .. "^7")
end

local function info(msg)
  print("^2[mtj_arrest] " .. msg .. "^7")
end

-- Prueft Resource-Metadaten
local function checkIntegrity()
  local resName = GetCurrentResourceName()
  local metaAuthor = GetResourceMetadata(resName, 'author', 0) or ""
  local metaName   = GetResourceMetadata(resName, 'name', 0) or ""

  local ok = true

  -- Author-Check
  if not string.find(metaAuthor, "MTJ") then
    warn("Resource-Author wurde veraendert! Original-Author: " .. AUTHOR)
    warn("Dies ist urheberrechtlich geschuetzte Software von " .. AUTHOR)
    warn("Weitere Infos: " .. REPO)
    ok = false
  end

  -- Name-Check (weich — Umbenennung ist erlaubt, aber wird geloggt)
  if metaName ~= RES_NAME then
    info("Resource umbenannt: '" .. metaName .. "' (Original: " .. RES_NAME .. ")")
  end

  if ok then
    info(COPYRIGHT)
    info("Lizenziert fuer: " .. REPO)
    info("Integritaetspruefung bestanden.")
  else
    warn("=============================================")
    warn(" URHEBERRECHTSVERLETZUNG ERKANNT!")
    warn(" Diese Software ist Eigentum von MTJ2024.")
    warn(" Unbefugte Nutzung wird rechtlich verfolgt.")
    warn(" " .. REPO)
    warn("=============================================")
  end

  return ok
end

-- Periodischer Copyright-Hinweis (alle 30 Min im Server-Log)
CreateThread(function()
  -- Initialpruefung
  checkIntegrity()

  -- Periodisch
  while true do
    Wait(1800000) -- 30 Minuten
    local resName = GetCurrentResourceName()
    local metaAuthor = GetResourceMetadata(resName, 'author', 0) or ""
    if not string.find(metaAuthor, "MTJ") then
      warn("LAUFENDE URHEBERRECHTSVERLETZUNG — Author veraendert!")
      warn("Original: " .. AUTHOR .. " | " .. REPO)
    end
  end
end)
