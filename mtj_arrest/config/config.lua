-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  github.com/MTJ2024/AREST-NPC                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
Config = {}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                    STEUERUNG & TASTEN                           ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Keys = {
    Surrender = 38,             -- Taste zum Ergeben ([E] = 38)
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              VORWARNUNG (vor Polizei-Einsatz)                   ║
-- ║  Grosse Warnung BEVOR Polizei spawnt:                           ║
-- ║  "Hoer auf zu schiessen, sonst Gegenwehr!"                     ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Vorwarnung = {
    Aktiviert           = true,     -- true = Vorwarnung wird angezeigt
    Dauer               = 5,        -- Sekunden: Wie lange die Warnung angezeigt wird
    Titel               = "POLIZEI-WARNUNG",
    Text                = "Stellen Sie sofort Ihre Waffen ab!\nBei Widerstand wird mit Gegenwehr gerechnet!",
    TextKurz            = "Waffen ablegen oder Konsequenzen!",
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              WAFFEN BEI TOD IM POLIZEI-EINSATZ                  ║
-- ║  NUR wenn der Spieler waehrend eines aktiven Polizei-Einsatzes  ║
-- ║  stirbt, werden alle Waffen entfernt. Normaler Tod = KEINE      ║
-- ║  Waffenentfernung (dieses Script hat damit nichts zu tun!)      ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.WaffenBeiTod = {
    Aktiviert           = true,     -- true = Waffen NUR bei Tod im Polizeieinsatz entfernt
    Nachricht           = "Deine Waffen wurden nach dem Polizeieinsatz sichergestellt!",
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              KI-VERHANDLUNG (Negotiation vor Zugriff)           ║
-- ║  Mehrstufige Verhandlung BEVOR Polizei schiesst:                ║
-- ║  Stufe 1: Aufforderung — Stufe 2: Warnung — Stufe 3: Zugriff   ║
-- ║  Spieler kann jederzeit [E] zum Ergeben druecken                ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Verhandlung = {
    Aktiviert           = true,     -- true = KI-Verhandlung aktiv
    Stufen = {
        {   -- Stufe 1: Aufforderung (ruhiger Ton)
            Dauer   = 5,            -- Sekunden
            Text    = "POLIZEI! Legen Sie sofort Ihre Waffen ab!",
            Farbe   = {255, 200, 50},   -- Gelb/Orange
            Speech  = "ARREST_PLAYER",  -- GTA Speech Kontext
        },
        {   -- Stufe 2: Warnung (aggressiver)
            Dauer   = 5,
            Text    = "LETZTE WARNUNG! Ergeben Sie sich SOFORT oder wir schiessen!",
            Farbe   = {255, 100, 30},   -- Orange/Rot
            Speech  = "CHALLENGE_THREATEN",
        },
        {   -- Stufe 3: Zugriff (Cops schiessen)
            Dauer   = 0,            -- 0 = Sofort Zugriff, kein weiteres Warten
            Text    = "ZUGRIFF! Feuer frei!",
            Farbe   = {255, 30, 30},    -- Rot
            Speech  = "DRAW_GUN",
        },
    },
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              POLIZEI-EINSATZ ANZEIGE (SZENARIO-UI)              ║
-- ║  Wann und wie die "POLIZEI-EINSATZ" Info angezeigt wird         ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Aktionsradius            = 40.0    -- Meter: Polizei muss SO NAH sein, bevor Info + Timer starten
Config.AktionsradiusTimeout     = 20      -- Sekunden: Maximale Wartezeit auf Polizei-Ankunft
Config.ComplianceWindow         = 15      -- Sekunden: Zeit zum Ergeben [E], bevor Polizei schiesst
Config.RequiredWantedLevel      = 2       -- Ab diesem Wanted-Level startet das Szenario (1-5)

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
    WantedErhoehung     = 1,       -- Wanted-Level wird um diesen Wert erhoeht (+1 Stern)
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

    -- ── NPC-Cop Sprüche je nach Akte-Status ──
    -- GTA V Native Speech Contexts (was die Cops rufen)
    -- Jede Stufe hat eigene Sprach-Befehle für mehr Immersion
    CopSpeech = {
        unbescholten = {                        -- Ersttäter: normaler Ton
            "ARREST_PLAYER",
            "DRAW_GUN",
            "CHALLENGE_THREATEN",
        },
        vorbestraft = {                         -- Vorbestraft: aggressiver
            "ARREST_PLAYER",
            "DRAW_GUN",
            "CHALLENGE_THREATEN",
            "FOOT_CHASE",
            "PROVOKE_TRESPASS",
        },
        ["mehrfach vorbestraft"] = {            -- Mehrfachtäter: sehr aggressiv
            "CHALLENGE_THREATEN",
            "DRAW_GUN",
            "FOOT_CHASE",
            "FOOT_CHASE_LOSING",
            "PROVOKE_TRESPASS",
        },
        schwerkriminell = {                     -- Schwerkriminell: feindlich
            "CHALLENGE_THREATEN",
            "FOOT_CHASE",
            "FOOT_CHASE_LOSING",
            "PROVOKE_TRESPASS",
            "DRAW_GUN",
        },
        Staatsfeind = {                         -- Staatsfeind: maximale Aggression
            "CHALLENGE_THREATEN",
            "FOOT_CHASE_LOSING",
            "PROVOKE_TRESPASS",
            "DRAW_GUN",
            "FOOT_CHASE",
        },
    },

    -- ── Festnahme-Protokoll Texte je nach Akte-Status ──
    -- Diese Texte erscheinen im Arrest-Log UI statt der Standard-Texte
    ArrestLogPerStatus = {
        unbescholten = {
            "Tatverdacht: Widerstand gegen die Staatsgewalt",
            "Maßnahme: Vorläufige Festnahme",
            "Rechte: Aussageverweigerungsrecht, Recht auf Verteidiger",
        },
        vorbestraft = {
            "ACHTUNG: Person ist vorbestraft!",
            "Tatverdacht: Wiederholte Straftaten",
            "Maßnahme: Sofortige Festnahme und verschärfte Überstellung",
            "Rechte: Aussageverweigerungsrecht, Pflichtverteidiger wird bestellt",
            "Vermerk: Erhöhtes Strafmaß aufgrund Vorstrafen",
        },
        ["mehrfach vorbestraft"] = {
            "⚠ WARNUNG: Mehrfach vorbestrafte Person!",
            "Tatverdacht: Serientäter — wiederholter Gesetzesbruch",
            "Maßnahme: Sofortige Festnahme unter erhöhter Sicherheit",
            "Anordnung: Verschärfte Haftbedingungen",
            "Vermerk: Maximales Strafmaß empfohlen",
        },
        schwerkriminell = {
            "🚨 SCHWERKRIMINELL — Höchste Sicherheitsstufe!",
            "Tatverdacht: Schwere wiederholte Straftaten",
            "Maßnahme: Sofortige Festnahme — Sondereinheit",
            "Anordnung: Isolationshaft und Sicherheitsverwahrung",
            "Vermerk: Antrag auf Höchststrafe wird gestellt",
        },
        Staatsfeind = {
            "🔴 STAATSFEIND — Allerhöchste Priorität!",
            "Tatverdacht: Schwerstverbrechen, Gefährdung der öffentlichen Sicherheit",
            "Maßnahme: Sofortige Festnahme mit Spezialeinheit",
            "Anordnung: Hochsicherheitstrakt, keine Besuchserlaubnis",
            "Warnung: Person gilt als extrem gefährlich",
            "Vermerk: Staatsanwaltschaft ist informiert",
        },
    },

    -- ── Szenario-Hint je nach Akte-Status ──
    -- Was der Spieler sieht wenn Polizei ankommt
    ScenarioHintPerStatus = {
        unbescholten        = "Du bist umzingelt! Drücke [E], um dich zu ergeben.",
        vorbestraft         = "POLIZEI! Du bist VORBESTRAFT! Sofort ergeben mit [E]!",
        ["mehrfach vorbestraft"] = "ACHTUNG WIEDERHOLUNGSTÄTER! Hände hoch! [E] zum Ergeben!",
        schwerkriminell     = "SCHWERKRIMINELLER! Letzte Warnung! [E] oder wir schießen!",
        Staatsfeind         = "STAATSFEIND ERKANNT! Sofort aufgeben [E] — KEINE weitere Warnung!",
    },
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
-- ║              POLIZEIAKTE-NPC (Akte einsehen am NPC)             ║
-- ║  Ein NPC vor dem Spieler hinfahren kann, um seine Akte zu       ║
-- ║  sehen — vollautomatisch, kein echter Spieler nötig             ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.PolizeiakteNPC = {
    Aktiviert           = true,                                    -- true = NPC wird gespawnt
    Position            = vector3(441.6784, -978.5231, 30.6896),    -- Vor dem Polizeirevier (Mission Row PD)
    Heading             = 149.8703,                                -- Blickrichtung des NPC
    Model               = "s_m_y_cop_01",                          -- NPC-Modell (Polizist)
    Scenario            = "WORLD_HUMAN_CLIPBOARD",                 -- Animation (Clipboard halten)
    Interaktionsradius  = 5.0,                                     -- Meter: wie nah der Spieler sein muss
    InteraktionsText    = "[E] Polizeiakte einsehen",              -- Text über dem NPC

    -- Blip auf der Karte
    Blip = {
        Sprite          = 60,                                      -- Blip-Icon (60 = Stern/Polizei)
        Scale           = 0.85,                                    -- Größe des Blips
        Farbe           = 3,                                       -- Farbe (3 = blau)
        Name            = "Polizeiakte",                           -- Name auf der Karte
    },
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              DEBUG                                              ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Debug                    = false   -- true = Debug-Ausgaben in Konsole

return Config