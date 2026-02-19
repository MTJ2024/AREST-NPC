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

-- Polizei-Spawning bei Wanted (Fahndung) — skaliert nach Wanted-Level
Config.CopsPerWantedLevel = {
    [1] = 2,   -- 1 Stern: 2 Cops
    [2] = 4,   -- 2 Sterne: 4 Cops
    [3] = 6,   -- 3 Sterne: 6 Cops
    [4] = 8,   -- 4 Sterne: 8 Cops
    [5] = 20,  -- 5 Sterne: bis zu 20 Cops (verteilt, inkl. Heli-Besatzung)
}
Config.PoliceCount = 7 -- Fallback, falls CopsPerWantedLevel nicht definiert
Config.PoliceSpawnRadius = 40.0 -- Entfernung um Spieler, in der gespawnt wird (Meter)
Config.PoliceChaseWanted = true -- Wenn true: Cops spawnen und verfolgen Spieler bei Wanted automatisch
Config.MaxActiveCops = 20
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
Config.CopArrivalRadius = 10.0 -- Cops müssen auf diese Distanz (Meter) kommen, bevor Timer startet
Config.DisableAmbientCopsAfterSurrender = true

-- Helikopter ab 3 Sternen (mit bewaffneter Besatzung)
Config.HeliWantedLevel = 3              -- Ab diesem Wanted-Level spawnen Helis
Config.HeliModel = "polmav"             -- Polizei-Helikopter Modell
Config.HeliCrewModel = "s_m_y_swat_01"  -- SWAT-Modell für Besatzung
Config.HeliSpawnHeight = 80.0           -- Spawn-Höhe über dem Spieler
Config.HeliWeapon = "WEAPON_CARBINERIFLE" -- Waffe der Heli-Besatzung
Config.MaxHelis = 2                     -- Maximale Anzahl Helikopter gleichzeitig

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

return Config