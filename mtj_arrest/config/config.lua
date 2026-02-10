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

-- Enhanced Effects Settings
Config.Effects = {
  EnableSlowMotion = true,          -- Enable slow motion during arrest
  EnableArrestCamera = true,         -- Enable cinematic camera during arrest
  EnableHelicopter = true,           -- Enable helicopter spawning at high wanted levels
  EnableRoadblocks = true,           -- Enable dynamic roadblock spawning
  EnableScreenEffects = true,        -- Enable screen effects (blur, shake, etc.)
  EnableSoundEffects = true,         -- Enable sound effects
  EnableParticleEffects = true,      -- Enable particle effects
  EnableCustomWantedDisplay = true,  -- Enable custom GTA V Online style wanted display
  SlowMotionStrength = 0.3,          -- Slow motion speed (0.0-1.0, lower = slower)
  SlowMotionDuration = 4000,         -- Slow motion duration in milliseconds
  HelicopterWantedLevel = 4,         -- Wanted level to spawn helicopter
  RoadblockWantedLevel = 3           -- Wanted level to spawn roadblocks
}

return Config