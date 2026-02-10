-- mtj_arrest: Server main (crashsicher für ox_inventory, Jail-Teleport läuft IMMER)

local DEBUG = true
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
      -- Waffen im Loadout
      if xPlayer.getLoadout and xPlayer.removeWeapon then
        local loadout = xPlayer.getLoadout()
        if loadout then
          for _, w in pairs(loadout) do
            local wname = (w and (w.name or w.weapon)) or nil
            if wname then
              xPlayer.removeWeapon(wname)
              removed_esx = removed_esx + 1
            end
          end
        end
      end
      -- Alles aus dem Inventory
      local inv = (xPlayer.getInventory and xPlayer.getInventory()) or xPlayer.inventory
      if inv then
        for _, item in pairs(inv) do
          if item and item.name and item.count and item.count > 0 then
            xPlayer.removeInventoryItem(item.name, item.count)
            removed_esx = removed_esx + item.count
          end
        end
      end
    end
  end

  dbg(("[mtj_arrest] clearAllWeaponsAndItems finished for %d removed: ox=%d esx=%d"):format(src, removed_ox, removed_esx))
end

-- Strafe abziehen: erst money, dann bank (ESX & ox_inventory)
local function takeJailFine(src)
  if not Config.EnableJailFine or (Config.JailFine or 0) < 1 then return end
  local fine = Config.JailFine
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

AddEventHandler('playerDropped', function()
  local src = source
  activeJails[src] = nil
end)

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

  minutes = tonumber(minutes) or 10
  dbg(("[mtj_arrest] clearAllWeaponsAndItems invoked by %d"):format(src))
  pcall(function() clearAllWeaponsAndItems(src) end)

  -- Strafe abziehen (money, dann bank)
  pcall(function() takeJailFine(src) end)

  -- Teleport & Timer auf Client (immer ausführen)
  TriggerClientEvent('mtj_arrest:clientBeginJail', src, minutes)
  dbg(("[mtj_arrest] Player %d jailed for %d minutes"):format(src, minutes))

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

-- Optional: expliziter Server-Event zum Waffen-Clear
RegisterNetEvent('mtj_arrest:serverClearWeapons', function()
  local src = source
  dbg(("[mtj_arrest] clearAllWeaponsAndItems invoked by %d (manual)"):format(src))
  pcall(function() clearAllWeaponsAndItems(src) end)
end)