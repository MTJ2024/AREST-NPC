Config = {}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                    STEUERUNG & TASTEN                           ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Keys = {
    Surrender = 38,             -- Taste zum Ergeben ([E] = 38)
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              POLIZEI-EINSATZ ANZEIGE (SZENARIO-UI)              ║
-- ║  Wann und wie die "POLIZEI-EINSATZ" Info angezeigt wird         ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Aktionsradius            = 10.0    -- Meter: Polizei muss SO NAH sein, bevor Info + Timer starten
Config.AktionsradiusTimeout     = 20      -- Sekunden: Maximale Wartezeit auf Polizei-Ankunft
Config.ComplianceWindow         = 10      -- Sekunden: Zeit zum Ergeben [E], bevor Polizei schießt
Config.RequiredWantedLevel      = 1       -- Ab diesem Wanted-Level startet das Szenario (1-5)

Config.UI = {
    -- Texte im Szenario-Panel
    ScenarioHint    = "Du bist umzingelt! Drücke [E], um dich zu ergeben.",
    SurrenderKeyText = "[E]",

    -- Texte im Festnahme-Protokoll
    ArrestLogLines  = {
        "Tatverdacht: Widerstand gegen die Staatsgewalt",
        "Maßnahme: Vorläufige Festnahme und Überstellung JVA",
        "Rechte: Aussageverweigerungsrecht, Recht auf Verteidiger",
    },

    -- Texte im Jail-Panel
    JailTitle       = "JVA Greenzone420",
    JailSubtitle    = "Du bist inhaftiert.",
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              POLIZEI-SPAWNING (Anzahl pro Wanted-Level)         ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.CopsPerWantedLevel = {
    [1] = 2,                    -- 1 Stern:  2 Polizisten
    [2] = 4,                    -- 2 Sterne: 4 Polizisten
    [3] = 6,                    -- 3 Sterne: 6 Polizisten
    [4] = 8,                    -- 4 Sterne: 8 Polizisten
    [5] = 20,                   -- 5 Sterne: bis 20 Polizisten (verteilt, inkl. Heli-Besatzung)
}
Config.PoliceCount              = 7       -- Fallback, falls CopsPerWantedLevel nicht greift
Config.MaxActiveCops            = 20      -- Maximale Anzahl gleichzeitig aktiver Polizisten
Config.PoliceSpawnRadius        = 40.0    -- Meter: Entfernung um Spieler, in der gespawnt wird
Config.MaxSpawnDistance          = 40.0    -- Legacy-Alias für Kompatibilität
Config.PoliceChaseWanted        = true    -- true = Cops spawnen und verfolgen bei Wanted automatisch
Config.DisableAmbientCopsAfterSurrender = true -- Ambient-Cops ignorieren Spieler nach Ergeben

Config.PoliceModels = {
    "s_m_y_cop_01",
    "s_f_y_cop_01",
    "s_m_y_sheriff_01",
    "s_m_m_sheriff_01",
}
Config.PoliceOffsets = {
    vector3(8.0, 4.0, 0.0),
    vector3(-6.0, 5.0, 0.0),
    vector3(4.0, -7.0, 0.0),
    vector3(-8.0, -5.0, 0.0),
    vector3(12.0, 0.0, 0.0),
    vector3(-12.0, 0.0, 0.0),
    vector3(6.0, 10.0, 0.0),
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              HELIKOPTER (ab 3 Sternen Wanted)                   ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.HeliWantedLevel          = 3                 -- Ab diesem Wanted-Level spawnen Helis
Config.HeliModel                = "polmav"          -- Helikopter-Modell
Config.HeliCrewModel            = "s_m_y_swat_01"   -- SWAT-Modell für Besatzung
Config.HeliWeapon               = "WEAPON_CARBINERIFLE" -- Waffe der Heli-Besatzung
Config.HeliSpawnHeight          = 80.0              -- Spawn-Höhe über dem Spieler (Meter)
Config.MaxHelis                 = 2                 -- Maximale Anzahl Helikopter gleichzeitig

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              GEFÄNGNIS / JAIL                                   ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.JailMinutesDefault       = 1       -- Haftzeit in Minuten (Standard für Szenario-Arrest)
Config.JailMinutes              = 10      -- Alias für Server (zentral für alle)
Config.JailPosition             = vector3(460.0410, -993.4337, 24.9149)  -- Bolingbroke Prison Hof
Config.JailHeading              = 180.0   -- Blickrichtung im Gefängnis
Config.JailName                 = "JVA GreenZone420"
Config.JailReason               = "Du bist inhaftiert und verbüßt deine Strafe."

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              ENTLASSUNG / RELEASE                               ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.JailReleasePosition      = vector3(444.2502, -987.4813, 30.6896)  -- Vor dem Gefängnistor
Config.JailReleaseHeading       = 270.0   -- Blickrichtung westlich zum Parkplatz

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              GELDSTRAFE                                         ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.JailFine                 = 15000   -- Höhe der Geldstrafe (€)
Config.EnableJailFine           = true    -- true = Strafe wird abgezogen, false = keine Abbuchung
Config.JailFineMessage          = "Dir wurden %s€ als Strafe abgezogen!"

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              SICHERHEIT & BALANCING                             ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.AntiDoubleJailTime       = 5       -- Sekunden: Schutz gegen doppeltes Einsperren
Config.GuardReleaseTime         = 8       -- Sekunden: Freigabe des Anti-Doppel-Guards

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              DEBUG                                              ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Debug                    = false   -- true = Debug-Ausgaben in Konsole

return Config