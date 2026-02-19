-- mtj_arrest: Wanted-Level-Überwachung
-- Überwacht den Wanted-Level und startet/beendet das Szenario automatisch.

local Config = Config or {}
Config.RequiredWantedLevel = Config.RequiredWantedLevel or 1

CreateThread(function()
  while true do
    Wait(1000)
    local wanted = GetPlayerWantedLevel(PlayerId())
    if wanted >= (Config.RequiredWantedLevel or 1) then
      TriggerEvent('mtj_arrest:startScenario')
    end
    Wait(2000)
  end
end)
