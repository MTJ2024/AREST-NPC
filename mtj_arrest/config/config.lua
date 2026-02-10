Config = {}

-- Steuerung & UI
Config.Keys = { Surrender = 38 } -- [E] Taste
Config.UI = {
    ScenarioHint = "Du bist umzingelt! Drücke [E], um dich zu ergeben.",
    ArrestLogLines = {
        "Tatverdacht: Widerstand gegen die Staatsgewalt",
        "Maßnahme: Vorläufige Festnahme und Überstellung JVA",
        "Rechte: Aussageverweigerungsrecht, Recht auf Verteidiger"
    },
    JailTitle = "JVA Greenzone420",
    JailSubtitle = "Du bist inhaftiert.",
    SurrenderKeyText = "[E]"
}

-- Polizei-Spawning bei Wanted (Fahndung)
Config.PoliceCount = 7 -- Wie viele Cops maximal spawnen
Config.PoliceSpawnRadius = 40.0 -- Entfernung um Spieler, in der gespawnt wird (Meter)
Config.PoliceChaseWanted = true -- Wenn true: Cops spawnen und verfolgen Spieler bei Wanted automatisch
Config.MaxActiveCops = 24
Config.PoliceModels = {
    "s_m_y_cop_01",
    "s_f_y_cop_01",
    "s_m_y_sheriff_01",
    "s_m_m_sheriff_01"
}
Config.PoliceOffsets = {
    vector3(8.0, 4.0, 0.0),
    vector3(-6.0, 5.0, 0.0),
    vector3(4.0, -7.0, 0.0),
    vector3(-8.0, -5.0, 0.0),
    vector3(12.0, 0.0, 0.0),
    vector3(-12.0, 0.0, 0.0),
    vector3(6.0, 10.0, 0.0)
}
Config.MaxSpawnDistance = 40.0 -- Legacy, für Kompatibilität
Config.ComplianceWindow = 10
Config.DisableAmbientCopsAfterSurrender = true

-- Jail (realistische Koordinaten: Bolingbroke Prison Hof)
Config.JailMinutesDefault = 1  -- <<< HIER Haftzeit zentral einstellen (in Minuten)
Config.JailMinutes = 10         -- <<< Alias für server/main.lua (zentral für alle, z.B. 12 für 12 Minuten)
Config.JailPosition = vector3(460.0410, -993.4337, 24.9149)
Config.JailHeading = 180.0
Config.JailName = "JVA GreenZone420"
Config.JailReason = "Du bist inhaftiert und verbüßt deine Strafe."

-- Release-Position nach Ende der Haftzeit (vor dem Gefängnistor)
Config.JailReleasePosition = vector3(444.2502, -987.4813, 30.6896) -- Vor dem Tor von Bolingbroke Prison
Config.JailReleaseHeading = 270.0 -- Blickrichtung westlich zum Parkplatz

-- Strafe/Geldstrafe Einstellungen
Config.JailFine = 15000                  -- Höhe der Strafe (€)
Config.EnableJailFine = true             -- true = Strafe wird abgezogen, false = keine Abbuchung
Config.JailFineMessage = "Dir wurden %s€ als Strafe abgezogen!"

-- Sicherheit & Balancing
Config.AntiDoubleJailTime = 5
Config.GuardReleaseTime = 8
Config.RequiredWantedLevel = 1

-- Debug
Config.Debug = false

-- WantedSystem Configuration
Config.WantedSystem = {
  enabled = true,                    -- Enable/disable automatic wanted levels on crimes
  shootingWantedLevel = 2,          -- Wanted level for shooting a weapon
  injuringWantedLevel = 3,          -- Wanted level for injuring a ped
  killingWantedLevel = 4,           -- Wanted level for killing a ped
  cooldownMs = 3000,                -- Cooldown in milliseconds between wanted level increases
  applyForPlayerKills = false,      -- Whether to apply wanted levels for killing other players
  deathDetectionRadius = 50.0,      -- Radius in meters to detect ped deaths caused by player
  injuryDetectionRadius = 30.0,     -- Radius in meters to detect ped injuries caused by player
  combatTimeoutMs = 5000            -- Milliseconds after shooting to consider player in combat
}

return Config