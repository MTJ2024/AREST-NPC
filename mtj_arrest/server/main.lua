-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- mtj_arrest: Server main (crashsicher für ox_inventory, Jail-Teleport läuft IMMER)

local DEBUG = false
local function dbg(...)
  if not DEBUG then return end
  local t = {}
  for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end
  print(("[mtj_arrest] %s"):format(table.concat(t, " ")))
end

-- Config laden
local Config = Config or {}
if not Config.JailFine then Config.JailFine = 15000 end
if Config.EnableJailFine == nil then Config.EnableJailFine = true end
if not Config.JailFineMessage then Config.JailFineMessage = "Dir wurden %s€ als Strafe abgezogen!" end

-- ESX holen
local ESX
CreateThread(function()
  local start = GetGameTimer()
  while not ESX and (GetGameTimer() - start) < 10000 do
    pcall(function()
      if exports and exports['es_extended'] and exports['es_extended'].getSharedObject then
        ESX = exports['es_extended']:getSharedObject()
      end
    end)
    Wait(200)
  end
  if ESX then dbg("ESX loaded") else dbg("Warning: ESX not found") end
end)

-- ox_inventory-Helper
local function hasOx()
  return GetResourceState('ox_inventory') == 'started' and exports.ox_inventory ~= nil
end

local function oxGetItems(src)
  if not hasOx() then return nil end
  local ok, items = pcall(function() return exports.ox_inventory:Inventory(src) end)
  if ok and items then return items end
  ok, items = pcall(function() return exports.ox_inventory:GetPlayerItems(src) end)
  if ok and items then return items end
  return nil
end

-- ALLES ENTFERNEN: Waffen & Items
local function clearAllWeaponsAndItems(src)
  local removed_ox, removed_esx = 0, 0

  -- ox_inventory: Alle Waffen & Items löschen
  if hasOx() then
    local weapons = exports.ox_inventory:GetPlayerWeapons(src)
    if weapons then
      for _, weapon in pairs(weapons) do
        pcall(function()
          exports.ox_inventory:RemoveWeapon(src, weapon.name)
          removed_ox = removed_ox + 1
        end)
      end
    end
    local items = oxGetItems(src)
    if items then
      for _, item in pairs(items) do
        if item and item.name and item.count and item.count > 0 then
          pcall(function()
            exports.ox_inventory:RemoveItem(src, item.name, item.count, nil, item.slot)
            removed_ox = removed_ox + item.count
          end)
        end
      end
    end
  end

  -- ESX: Loadout & Inventory
  if ESX then
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
      -- Waffen im Loadout (WICHTIG: Colon-Syntax fuer ESX-Methoden!)
      if xPlayer.getLoadout and xPlayer.removeWeapon then
        local loadout = xPlayer:getLoadout()
        if loadout then
          for _, w in pairs(loadout) do
            local wname = (w and (w.name or w.weapon)) or nil
            if wname then
              xPlayer:removeWeapon(wname)
              removed_esx = removed_esx + 1
            end
          end
        end
      end
      -- Alles aus dem Inventory
      local inv = (xPlayer.getInventory and xPlayer:getInventory()) or xPlayer.inventory
      if inv then
        for _, item in pairs(inv) do
          if item and item.name and item.count and item.count > 0 then
            xPlayer:removeInventoryItem(item.name, item.count)
            removed_esx = removed_esx + item.count
          end
        end
      end
    end
  end

  dbg(("[mtj_arrest] clearAllWeaponsAndItems finished for %d removed: ox=%d esx=%d"):format(src, removed_ox, removed_esx))
end

-- Strafe abziehen: erst money, dann bank (ESX & ox_inventory)
local function takeJailFine(src, fineOverride)
  if not Config.EnableJailFine then return end
  local fine = fineOverride or Config.JailFine or 0
  if fine < 1 then return end
  local remaining = fine
  local paid = 0

  -- ox_inventory
  if hasOx() then
    local getMoney = function(acc)
      local ok, val = pcall(function()
        return exports.ox_inventory:GetItem(src, acc)
      end)
      if ok and val and val.count then return tonumber(val.count) or 0 end
      return 0
    end
    local remove = function(acc, amount)
      pcall(function() exports.ox_inventory:RemoveItem(src, acc, amount) end)
    end

    local cash = getMoney("money")
    if cash > 0 then
      local take = math.min(remaining, cash)
      remove("money", take)
      remaining = remaining - take
      paid = paid + take
    end

    if remaining > 0 then
      local bank = getMoney("bank")
      if bank > 0 then
        local take = math.min(remaining, bank)
        remove("bank", take)
        remaining = remaining - take
        paid = paid + take
      end
    end

    if paid > 0 then
      dbg(("JailFine %d€ abgezogen (ox_inventory) [Player %d]"):format(paid, src))
      if Config.JailFineMessage then
        TriggerClientEvent('chat:addMessage', src, {
          color = {255, 50, 50},
          multiline = true,
          args = {"Gefängnis", string.format(Config.JailFineMessage, paid)}
        })
      end
      return
    end
  end

  -- ESX
  if ESX then
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer and xPlayer.getAccount and xPlayer.removeAccountMoney and xPlayer.getAccounts then
      local cash = xPlayer.getAccount('money') and xPlayer.getAccount('money').money or 0
      if cash > 0 then
        local take = math.min(remaining, cash)
        xPlayer.removeAccountMoney('money', take)
        remaining = remaining - take
        paid = paid + take
      end
      if remaining > 0 then
        local bank = xPlayer.getAccount('bank') and xPlayer.getAccount('bank').money or 0
        if bank > 0 then
          local take = math.min(remaining, bank)
          xPlayer.removeAccountMoney('bank', take)
          remaining = remaining - take
          paid = paid + take
        end
      end
      if paid > 0 then
        dbg(("JailFine %d€ abgezogen (ESX) [Player %d]"):format(paid, src))
        if Config.JailFineMessage then
          TriggerClientEvent('chat:addMessage', src, {
            color = {255, 50, 50},
            multiline = true,
            args = {"Gefängnis", string.format(Config.JailFineMessage, paid)}
          })
        end
      end
    end
  end
end

-- Anti-Doppel-Guard für Jail
local activeJails = {}

-- Strafregister: Festnahmen pro Spieler (Session-basiert)
local arrestHistory = {}

AddEventHandler('playerDropped', function()
  local src = source
  activeJails[src] = nil
  arrestHistory[src] = nil
end)

-- Strafregister: Anzahl der Festnahmen für Spieler
local function getArrestCount(src)
  return arrestHistory[src] or 0
end

local function incrementArrestCount(src)
  arrestHistory[src] = (arrestHistory[src] or 0) + 1
  return arrestHistory[src]
end

-- Strafregister: Multiplikator berechnen
local function getStrafregisterMultiplier(arrestCount, configKey)
  local sr = Config.Strafregister
  if not sr or not sr.Aktiviert or arrestCount <= 1 then return 1.0 end
  local vorstrafen = arrestCount - 1
  local perVorstrafe = sr[configKey] or 0.5
  local maxMult = sr.MaxMultiplikator or 3.0
  local mult = 1.0 + (vorstrafen * perVorstrafe)
  return math.min(mult, maxMult)
end

-- Public: von Client aufgerufen
RegisterNetEvent('mtj_arrest:serverBeginJail')
AddEventHandler('mtj_arrest:serverBeginJail', function(minutes)
  local src = source
  local now = GetGameTimer()
  if activeJails[src] and (now - activeJails[src]) < 5000 then
    dbg(("[mtj_arrest] duplicate serverBeginJail ignored for %d"):format(src))
    return
  end
  activeJails[src] = now

  -- Strafregister (Session): Festnahme zählen
  local arrestCount = incrementArrestCount(src)
  dbg(("[mtj_arrest] Strafregister: Spieler %d — Festnahme Nr. %d"):format(src, arrestCount))

  minutes = tonumber(minutes) or 10
  local baseFine = Config.JailFine or 15000

  -- Polizeiakte (Persistent): Multiplikatoren aus DB-Akte holen
  local haftMult, geldMult = 1.0, 1.0
  if PolizeiakteMultiplier then
    haftMult, geldMult = PolizeiakteMultiplier(src)
    dbg(("[mtj_arrest] Polizeiakte-Multiplikator: Haft x%.1f, Geld x%.1f"):format(haftMult, geldMult))
  end

  -- Session-Strafregister obendrauf (für Wiederholung in gleicher Session)
  local sessionJailMult = getStrafregisterMultiplier(arrestCount, "HaftzeitMultiplikator")
  local sessionFineMult = getStrafregisterMultiplier(arrestCount, "GeldstrafeMultiplikator")

  -- Gesamtmultiplikator = Akte × Session (max von Config)
  local totalJailMult = haftMult * sessionJailMult
  local totalFineMult = geldMult * sessionFineMult
  local maxMult = (Config.Polizeiakte and Config.Polizeiakte.MaxMultiplikator) or 5.0
  totalJailMult = math.min(totalJailMult, maxMult)
  totalFineMult = math.min(totalFineMult, maxMult)

  -- Haftzeit anpassen
  if totalJailMult > 1.0 then
    local origMinutes = minutes
    minutes = math.ceil(minutes * totalJailMult)
    dbg(("[mtj_arrest] Strafe erhöht: Haftzeit %d → %d Min (x%.1f)"):format(origMinutes, minutes, totalJailMult))
  end

  -- Geldstrafe anpassen
  local fineAmount = math.ceil(baseFine * totalFineMult)

  dbg(("[mtj_arrest] clearAllWeaponsAndItems invoked by %d"):format(src))
  pcall(function() clearAllWeaponsAndItems(src) end)
  pcall(function() takeJailFine(src, fineAmount) end)

  -- Polizeiakte (Persistent): Festnahme eintragen
  if PolizeiakteRecord then
    local count, status = PolizeiakteRecord(src, minutes, fineAmount)
    dbg(("[mtj_arrest] Polizeiakte: Festnahme #%d, Status: %s"):format(count or 0, status or "?"))
  end

  -- Session-Strafregister: Client über Vorstrafen informieren
  if arrestCount > 1 then
    TriggerClientEvent('mtj_arrest:clientVorstrafeInfo', src, arrestCount)
  end

  -- Teleport & Timer auf Client (immer ausführen) — inkl. tatsaechlicher Geldstrafe
  TriggerClientEvent('mtj_arrest:clientBeginJail', src, minutes, fineAmount)
  dbg(("[mtj_arrest] Player %d jailed for %d minutes (Arrest #%d, Mult x%.1f)"):format(src, minutes, arrestCount, totalJailMult))

  -- Optional: nochmalige Waffenbereinigung nach 1s
  SetTimeout(1000, function()
    dbg(("[mtj_arrest] clearAllWeaponsAndItems invoked by %d (post-Teleport)"):format(src))
    pcall(function() clearAllWeaponsAndItems(src) end)
  end)

  -- Guard nach 8s freigeben
  SetTimeout(8000, function()
    if activeJails[src] == now then
      activeJails[src] = nil
    end
  end)
end)

-- Kleindelikt: nur Geldstrafe, kein Knast
RegisterNetEvent('mtj_arrest:serverFineOnly')
AddEventHandler('mtj_arrest:serverFineOnly', function(fineAmount)
  local src = source
  local fine = tonumber(fineAmount) or Config.KleindeliktStrafe or 500
  if fine < 1 then return end
  pcall(function() takeJailFine(src, fine) end)
  dbg(("[mtj_arrest] Kleindelikt-Strafe %d EUR fuer Spieler %d"):format(fine, src))
end)

-- Tod-Strafe: gestaffelte Geldstrafe bei Tod im Polizeieinsatz
RegisterNetEvent('mtj_arrest:serverTodStrafe')
AddEventHandler('mtj_arrest:serverTodStrafe', function(fineAmount, wanted)
  local src = source
  local fine = tonumber(fineAmount) or 0
  if fine < 1 then return end
  pcall(function() takeJailFine(src, fine) end)
  dbg(("[mtj_arrest] Tod-Strafe %d EUR fuer Spieler %d (Stern %s)"):format(fine, src, tostring(wanted)))
end)

-- Optional: expliziter Server-Event zum Waffen-Clear
RegisterNetEvent('mtj_arrest:serverClearWeapons', function()
  local src = source
  dbg(("[mtj_arrest] clearAllWeaponsAndItems invoked by %d (manual)"):format(src))
  pcall(function() clearAllWeaponsAndItems(src) end)
end)

-- Jail-Release: Waffen entfernen wenn kein Waffenschein
local function playerHasWeaponLicense(src)
  if not ESX then return false end
  local xPlayer = ESX.GetPlayerFromId(src)
  if not xPlayer then return false end

  -- ESX Lizenzen prüfen
  if xPlayer.getLicenses then
    local licenses = xPlayer:getLicenses()
    if licenses then
      for _, lic in pairs(licenses) do
        if lic and lic.type == "weapon" then
          return true
        end
      end
    end
  end

  return false
end

RegisterNetEvent('mtj_arrest:serverJailRelease')
AddEventHandler('mtj_arrest:serverJailRelease', function()
  local src = source
  local hasLicense = playerHasWeaponLicense(src)
  dbg(("[mtj_arrest] Jail release for %d — Waffenschein: %s"):format(src, tostring(hasLicense)))

  if not hasLicense then
    -- Waffen aus Inventar/Loadout entfernen
    if ESX then
      local xPlayer = ESX.GetPlayerFromId(src)
      if xPlayer then
        if xPlayer.getLoadout and xPlayer.removeWeapon then
          local loadout = xPlayer:getLoadout()
          if loadout then
            for _, w in pairs(loadout) do
              local wname = (w and (w.name or w.weapon)) or nil
              if wname then
                xPlayer:removeWeapon(wname)
              end
            end
          end
        end
      end
    end
    if hasOx() then
      pcall(function()
        local weapons = exports.ox_inventory:GetPlayerWeapons(src)
        if weapons then
          for _, weapon in pairs(weapons) do
            pcall(function() exports.ox_inventory:RemoveWeapon(src, weapon.name) end)
          end
        end
      end)
    end
    dbg(("[mtj_arrest] Waffen entfernt (kein Waffenschein) für Spieler %d"):format(src))
    TriggerClientEvent('chat:addMessage', src, {
      color = {255, 165, 0},
      multiline = true,
      args = {"Gefängnis", "Deine Waffen wurden eingezogen (kein Waffenschein)."}
    })
  end
end)

-- === DISPATCH SYSTEM: Verfolgung fuer andere Spieler sichtbar ===
local activePursuits = {}

RegisterNetEvent('mtj_arrest:dispatch:pursuitStart')
AddEventHandler('mtj_arrest:dispatch:pursuitStart', function(wanted)
  local src = source
  activePursuits[src] = { wanted = wanted or 2, start = os.time() }
  local ped = GetPlayerPed(src)
  local coords = GetEntityCoords(ped)
  local name = GetPlayerName(src) or "Unbekannt"
  TriggerClientEvent('mtj_arrest:dispatch:notify', -1, {
    type = "start",
    player = name,
    playerId = src,
    wanted = wanted or 2,
    coords = { x = coords.x, y = coords.y, z = coords.z }
  })
  dbg(("[mtj_arrest][Dispatch] Verfolgung gestartet: %s (Wanted %d)"):format(name, wanted or 2))
end)

RegisterNetEvent('mtj_arrest:dispatch:pursuitEnd')
AddEventHandler('mtj_arrest:dispatch:pursuitEnd', function(reason)
  local src = source
  if activePursuits[src] then
    local name = GetPlayerName(src) or "Unbekannt"
    TriggerClientEvent('mtj_arrest:dispatch:notify', -1, {
      type = "end",
      player = name,
      playerId = src,
      reason = reason or "unbekannt"
    })
    activePursuits[src] = nil
    dbg(("[mtj_arrest][Dispatch] Verfolgung beendet: %s (%s)"):format(name, reason or "?"))
  end
end)

RegisterNetEvent('mtj_arrest:dispatch:pursuitUpdate')
AddEventHandler('mtj_arrest:dispatch:pursuitUpdate', function(wanted)
  local src = source
  if activePursuits[src] then
    activePursuits[src].wanted = wanted or activePursuits[src].wanted
  end
end)

AddEventHandler('playerDropped', function()
  local src = source
  if activePursuits[src] then
    activePursuits[src] = nil
  end
end)

RegisterNetEvent('mtj_arrest:serverFluchtversuch')
AddEventHandler('mtj_arrest:serverFluchtversuch', function()
  local src = source
  if PolizeiakteRecordFlucht then
    PolizeiakteRecordFlucht(src)
  end
  dbg(("[mtj_arrest] Fluchtversuch registriert fuer Spieler %d"):format(src))
end)

-- ══════════════════════════════════════════════════════════════════
--  KRIMINALLEVEL SENKEN: Spieler zahlt um Festnahmen zu reduzieren
-- ══════════════════════════════════════════════════════════════════

RegisterNetEvent('mtj_arrest:reduceKriminalLevel')
AddEventHandler('mtj_arrest:reduceKriminalLevel', function()
  local src = source
  local cfg = Config.PolizeiakteNPC and Config.PolizeiakteNPC.KriminalLevelSenken
  if not cfg or not cfg.Aktiviert then
    TriggerClientEvent('mtj_arrest:kriminalLevelFail', src)
    return
  end

  local akte = PolizeiakteGet and PolizeiakteGet(src)
  if not akte then
    TriggerClientEvent('mtj_arrest:kriminalLevelFail', src)
    return
  end

  local mindest = cfg.MindestFestnahmen or 0
  if akte.festnahmen <= mindest then
    TriggerClientEvent('mtj_arrest:kriminalLevelFail', src)
    TriggerClientEvent('chat:addMessage', src, {
      color = {255, 100, 100}, multiline = true,
      args = {"[MTJ]", "Kriminallevel kann nicht weiter gesenkt werden."}
    })
    return
  end

  local kosten = cfg.KostenProFestnahme or 10000
  local paid   = false

  -- ox_inventory
  if hasOx() then
    local getMoney = function(acc)
      local ok, val = pcall(function() return exports.ox_inventory:GetItem(src, acc) end)
      if ok and val and val.count then return tonumber(val.count) or 0 end
      return 0
    end
    local removeMoney = function(acc, amount)
      pcall(function() exports.ox_inventory:RemoveItem(src, acc, amount) end)
    end
    local cash = getMoney("money")
    local bank = getMoney("bank")
    if cash + bank >= kosten then
      local fromCash = math.min(cash, kosten)
      local fromBank = kosten - fromCash
      if fromCash > 0 then removeMoney("money", fromCash) end
      if fromBank > 0 then removeMoney("bank",  fromBank) end
      paid = true
    end
  end

  -- ESX
  if not paid and ESX then
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer and xPlayer.getAccount then
      local cash = (xPlayer.getAccount('money') and xPlayer.getAccount('money').money) or 0
      local bank = (xPlayer.getAccount('bank')  and xPlayer.getAccount('bank').money)  or 0
      if cash + bank >= kosten then
        local fromCash = math.min(cash, kosten)
        local fromBank = kosten - fromCash
        if fromCash > 0 then xPlayer.removeAccountMoney('money', fromCash) end
        if fromBank > 0 then xPlayer.removeAccountMoney('bank',  fromBank) end
        paid = true
      end
    end
  end

  if not paid then
    TriggerClientEvent('mtj_arrest:kriminalLevelFail', src)
    TriggerClientEvent('chat:addMessage', src, {
      color = {255, 100, 100}, multiline = true,
      args = {"[MTJ]", ("Nicht genug Geld. Benoetigt: %d EUR"):format(kosten)}
    })
    return
  end

  -- Festnahmen um 1 reduzieren
  local newFestnahmen = math.max(mindest, akte.festnahmen - 1)
  if PolizeiakteSetFestnahmen then
    PolizeiakteSetFestnahmen(src, newFestnahmen)
  end

  TriggerClientEvent('chat:addMessage', src, {
    color = {50, 255, 50}, multiline = true,
    args = {"[MTJ]", ("Kriminallevel gesenkt! Festnahmen: %d → %d (-%d EUR)"):format(akte.festnahmen, newFestnahmen, kosten)}
  })

  -- Aktualisierte vollstaendige Akte an Client senden
  if PolizeiakteBuildFull then
    local updatedAkte = PolizeiakteBuildFull(src)
    if updatedAkte then
      TriggerClientEvent('mtj_arrest:clientFullAkte', src, updatedAkte)
    end
  end

  dbg(("[mtj_arrest] Kriminallevel gesenkt fuer Spieler %d: %d → %d (-%d)"):format(src, akte.festnahmen, newFestnahmen, kosten))
end)