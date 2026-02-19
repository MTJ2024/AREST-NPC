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
-- ║              FLUCHTVERSUCH                                      ║
-- ║  Was passiert, wenn der Spieler während der Ergeben-Phase       ║
-- ║  wegrennt statt [E] zu drücken                                  ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Fluchtversuch = {
    Aktiviert           = true,     -- true = Fluchtversuch-System aktiv
    Fluchtradius        = 25.0,     -- Meter: Wenn Spieler sich SO WEIT entfernt → Flucht erkannt
    WantedErhöhung      = 1,       -- Wanted-Level wird um diesen Wert erhöht (+1 Stern)
    ExtraCops           = 3,        -- Zusätzliche Polizisten bei Fluchtversuch
    Nachricht           = "~r~FLUCHTVERSUCH~s~: Wanted-Level erhöht! Weitere Einheiten unterwegs!",
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              STRAFREGISTER (Wiederholungstäter)                  ║
-- ║  Mehrfach verhaftete Spieler bekommen härtere Strafen           ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Strafregister = {
    Aktiviert           = true,     -- true = Strafregister aktiv
    HaftzeitMultiplikator = 0.5,   -- Pro Vorstrafe: +50% Haftzeit (z.B. 3. Arrest = +100%)
    GeldstrafeMultiplikator = 0.25, -- Pro Vorstrafe: +25% Geldstrafe
    MaxMultiplikator    = 3.0,      -- Maximaler Gesamtmultiplikator (3x = dreifache Strafe)
    NachrichtVorstrafe  = "~o~Strafregister~s~: %d Vorstrafe(n) — Strafe erhöht!",
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              POLIZEIAKTE (Persistente NPC-Akte)                  ║
-- ║  Dauerhafte Erfassung aller Polizei-Vorgänge pro Spieler        ║
-- ║  Bleibt über Reconnects & Restarts gespeichert (KVP)            ║
-- ║  Vollautomatisch — kein MySQL nötig                             ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Polizeiakte = {
    Aktiviert           = true,     -- true = Persistente Akte aktiv (KVP-Datenbank)

    -- Straf-Stufen: Je mehr Festnahmen, desto härter die Strafe
    -- Die höchste passende Stufe wird verwendet
    Stufen = {
        {   -- Stufe 1: Ersttäter (keine Erhöhung)
            AbFestnahmen            = 0,
            Status                  = "unbescholten",
            HaftzeitMultiplikator   = 1.0,      -- Normale Haftzeit
            GeldstrafeMultiplikator = 1.0,      -- Normale Geldstrafe
        },
        {   -- Stufe 2: Vorbestraft (ab 2 Festnahmen)
            AbFestnahmen            = 2,
            Status                  = "vorbestraft",
            HaftzeitMultiplikator   = 1.5,      -- +50% Haftzeit
            GeldstrafeMultiplikator = 1.25,     -- +25% Geldstrafe
        },
        {   -- Stufe 3: Mehrfach vorbestraft (ab 4 Festnahmen)
            AbFestnahmen            = 4,
            Status                  = "mehrfach vorbestraft",
            HaftzeitMultiplikator   = 2.0,      -- Doppelte Haftzeit
            GeldstrafeMultiplikator = 1.5,      -- +50% Geldstrafe
        },
        {   -- Stufe 4: Schwerkriminell (ab 7 Festnahmen)
            AbFestnahmen            = 7,
            Status                  = "schwerkriminell",
            HaftzeitMultiplikator   = 3.0,      -- Dreifache Haftzeit
            GeldstrafeMultiplikator = 2.0,      -- Doppelte Geldstrafe
        },
        {   -- Stufe 5: Staatsfeind (ab 12 Festnahmen)
            AbFestnahmen            = 12,
            Status                  = "Staatsfeind",
            HaftzeitMultiplikator   = 4.0,      -- Vierfache Haftzeit
            GeldstrafeMultiplikator = 3.0,      -- Dreifache Geldstrafe
        },
    },

    FluchtversuchExtra  = 0.1,      -- Pro Fluchtversuch in Akte: +10% auf alles
    MaxMultiplikator    = 5.0,      -- Absolutes Maximum (5x)

    -- Nachrichten (automatisch angezeigt)
    NachrichtAkte       = "~y~POLIZEIAKTE~s~: Status: ~r~%s~s~ | Festnahmen: %d | Fluchtversuche: %d",
    NachrichtVorbestraft = "~o~VORBESTRAFT~s~: Aufgrund deiner Akte wird die Strafe erhöht!",
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              ENTLASSUNGSWARNUNG                                 ║
-- ║  Spieler wird vor Ende der Haftzeit benachrichtigt              ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Entlassungswarnung = {
    Aktiviert           = true,     -- true = Warnung vor Entlassung aktiv
    SekundenVorher      = 30,       -- Sekunden vor Entlassung: Warnung anzeigen
    Nachricht           = "~g~Entlassung~s~: Du wirst in %d Sekunden freigelassen!",
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              DEBUG                                              ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Debug                    = false   -- true = Debug-Ausgaben in Konsole

return Config