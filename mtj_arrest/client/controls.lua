-- mtj_arrest: Freie Bewegung im Jail, Waffen- und Kampfcontrols geblockt

local jail_control_until = 0

RegisterNetEvent('mtj_arrest:clientBeginJail', function(minutes)
  local ped = PlayerPedId()
  -- Nach Teleport: Charakter komplett freigeben und unbewaffnet setzen
  CreateThread(function()
    Wait(750)
    ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)
    ClearPedSecondaryTask(ped)
    ResetPedMovementClipset(ped, 0.0)
    RemoveAnimDict('mp_arresting')
    SetEnableHandcuffs(ped, false)
    SetPedCanPlayGestureAnims(ped, true)
    SetPedCanPlayAmbientAnims(ped, true)
    SetPedCanRagdoll(ped, true)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    SetNuiFocus(false, false)
  end)

  minutes = tonumber(minutes) or 10
  jail_control_until = GetGameTimer() + (minutes * 60 * 1000)
end)

-- Waffen- & Kampfcontrols blocken, Bewegung bleibt frei
CreateThread(function()
  while true do
    if jail_control_until > GetGameTimer() then
      DisableControlAction(0, 24, true)   -- Schießen
      DisableControlAction(0, 25, true)   -- Zielen
      DisableControlAction(0, 37, true)   -- Waffenrad
      DisableControlAction(0, 45, true)   -- Nachladen
      DisableControlAction(0, 44, true)   -- Deckung
      DisableControlAction(0, 140, true)  -- Nahkampf leicht
      DisableControlAction(0, 141, true)  -- Nahkampf schwer
      DisableControlAction(0, 142, true)  -- Nahkampf
      DisableControlAction(0, 263, true)  -- Nahkampf (div)
      DisablePlayerFiring(PlayerId(), true)
      -- KEINE Bewegungscontrols blocken!!
      Wait(0)
    else
      Wait(500)
    end
  end
end)