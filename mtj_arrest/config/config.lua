-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
Config = {}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                    STEUERUNG & TASTEN                           ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Keys = {
    Surrender = 38,             -- Taste zum Ergeben ([E] = 38)
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
-- ║              POLIZEI-EINSATZ ANZEIGE (SZENARIO-UI)              ║
-- ║  Wann und wie die "POLIZEI-EINSATZ" Info angezeigt wird         ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Aktionsradius            = 60.0    -- Meter: Polizei muss SO NAH sein, bevor Info + Timer starten
Config.AktionsradiusTimeout     = 20      -- Sekunden: Maximale Wartezeit auf Polizei-Ankunft
Config.ComplianceWindow         = 11      -- Sekunden: Zeit zum Ergeben [E], bevor Polizei schiesst
Config.RequiredWantedLevel      = 1       -- Ab diesem Wanted-Level startet das Szenario (1-5)

Config.UI = {
    -- Texte im Szenario-Panel
    ScenarioHint    = "Du bist umzingelt! Drücke [E], um dich zu ergeben.",
    SurrenderKeyText = "[E]",
    ScenarioHintKleindelikt = "Kleindelikt! Drücke [E] um die Strafe zu akzeptieren und frei zu kommen.",

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
    [1] = 2,                    -- 1 Stern:  2 Polizisten (Kleindelikt-Einsatz)
    [2] = 4,                    -- 2 Sterne: 4 Polizisten
    [3] = 6,                    -- 3 Sterne: 6 Polizisten
    [4] = 10,                   -- 4 Sterne: 10 Polizisten (grosse Einsatzkraefte)
    [5] = 15,                   -- 5 Sterne: bis 15 Polizisten (verteilt, inkl. Heli-Besatzung)
}
Config.HelisPerWantedLevel = {
    [1] = 0,                    -- 1 Stern:  kein Heli
    [2] = 0,                    -- 2 Sterne: kein Heli
    [3] = 1,                    -- 3 Sterne: 1 Helikopter
    [4] = 1,                    -- 4 Sterne: 1 Helikopter
    [5] = 2,                    -- 5 Sterne: 2 Helikopter
}
Config.FahrzeugePerWantedLevel = {
    [1] = 0,                    -- 1 Stern:  kein Fahrzeug
    [2] = 0,                    -- 2 Sterne: kein Fahrzeug
    [3] = 2,                    -- 3 Sterne: 2 Polizeifahrzeuge
    [4] = 3,                    -- 4 Sterne: 3 Polizeifahrzeuge
    [5] = 4,                    -- 5 Sterne: 4 Polizeifahrzeuge
}
Config.PoliceCount              = 4       -- Fallback, falls CopsPerWantedLevel nicht greift
Config.MaxActiveCops            = 15      -- Maximale Anzahl gleichzeitig aktiver Polizisten
Config.PoliceSpawnRadius        = 200.0   -- Meter: Spawn-Radius um Spieler
Config.MaxSpawnDistance          = 200.0   -- Legacy-Alias fuer Kompatibilitaet
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
Config.MaxHelis                 = 2                 -- Maximale Anzahl Helikopter (Fallback)

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              STRASSENSPERREN (ab 4 Sternen Wanted)              ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Roadblock = {
    Aktiviert           = true,     -- true = Strassensperren aktiv
    AbWantedLevel       = 4,        -- Ab diesem Wanted-Level spawnen Sperren
    MaxAnzahl           = 2,        -- Maximale Anzahl gleichzeitiger Sperren
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              DISPATCH (Polizeifunk fuer alle Spieler)           ║
-- ║  Alle Spieler auf dem Server erhalten Polizeifunk-Meldungen     ║
-- ║  wenn eine Verfolgungsjagd stattfindet — RP-Immersion           ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Dispatch = {
    Aktiviert           = true,     -- true = Dispatch-System aktiv
    BlipAktiv           = true,     -- true = Blip auf der Karte bei Verfolgung
}

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
Config.RespawnGraceSek          = 30     -- Sekunden: kein Wanted-Neustart nach Tod/Respawn (30s für Spawn-Systeme mit längerer Wartezeit)

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              TOD-STRAFE (Stufenstrafe bei Tod im Einsatz)       ║
-- ║  Wenn der Spieler waehrend eines Polizeieinsatzes stirbt,       ║
-- ║  wird eine gestaffelte Geldstrafe faellig (je nach Sternzahl).  ║
-- ║  Keine Waffenentfernung noetig — Strafe reicht als Konsequenz.  ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.TodStrafe = {
    Aktiviert           = true,
    StrafeProStern = {
        [1] = 500,            -- 1 Stern:  500 EUR
        [2] = 1000,           -- 2 Sterne: 1.000 EUR
        [3] = 2500,           -- 3 Sterne: 2.500 EUR
        [4] = 5000,           -- 4 Sterne: 5.000 EUR
        [5] = 10000,          -- 5 Sterne: 10.000 EUR
    },
    Nachricht = "~r~Tod im Einsatz~s~: Strafe von %d EUR (Fahndungsstufe %d ★)",
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              KLEINDELIKT (1-2 Sterne: Strafe statt Knast)       ║
-- ║  Bei 1-2 Sternen: Spieler kann [E] drücken → Strafe zahlen     ║
-- ║  und sofort frei kommen (kein Knast, wanted = 0)                ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.KleindeliktSchwelle      = 2       -- 1-2 Sterne: Strafe vor Ort, kein Knast; ab 3 Sternen: Knast
Config.KleindeliktStrafe        = 500     -- Geldstrafe in EUR beim Kleindelikt (1-2 Sterne)
Config.KleindeliktPromptDauer   = 10      -- Sekunden: Entscheidungsfenster "Strafe zahlen?" bei 1-2 Sternen; bei Ablauf → Wanted +1
Config.KleindeliktNachricht     = "~g~Kleindelikt~s~: Strafe von %d EUR ausgestellt. Du bist auf freiem Fuß!"
Config.KleindeliktDeliktText    = "Ordnungswidrigkeit / Kleindelikt"  -- Text im Vor-Ort-Zahlung UI
Config.KleindeliktOfficerName   = "Beamter (NPC)"                     -- Beamtenname im Vor-Ort-Zahlung UI
Config.KleindeliktPanelDauer    = 2800   -- ms: Anzeigedauer des Vor-Ort-Zahlung Panels (muss mit VOZ_DONE_DISPLAY_MS in app.js uebereinstimmen)
-- true = Cops schiessen bei Kleindelikt NICHT sofort; sie naehern sich nur und zielen.
-- Erst wenn der Spieler flieht oder die Compliance-Zeit ablaeuft wird scharfgeschossen.
Config.KleindeliktNichtSchiessen = true

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              NACHLASSEN (Verfolgungsdruck laesst nach)          ║
-- ║  Ab einer bestimmten Verfolgungsdauer laesst der Polizeidruck  ║
-- ║  nach und nach nach: weniger Cops, weniger Genauigkeit,        ║
-- ║  keine Verstaerkung mehr — bis der Spieler entkommen kann.     ║
-- ║  Verhindert unfaire Endlos-Verfolgungen.                       ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Nachlassen = {
    Aktiviert           = true,     -- true = Nachlassen-System aktiv
    AbSekunden          = 300,      -- Sekunden (5 Min): Ab dieser Verfolgungsdauer beginnt das Nachlassen
    NachlassDauer       = 180,      -- Sekunden (3 Min): Ueber diesen Zeitraum laesst der Druck komplett nach
    MinCopFaktor        = 0.0,      -- Minimaler Cop-Faktor (0.0 = am Ende keine neuen Cops mehr)
    MinGenauigkeit      = 5,        -- Minimale Cop-Genauigkeit (normal: 40-50, hier fast harmlos)
    NachrichtStart      = "~y~Die Polizei verliert langsam die Kontrolle...",
    NachrichtMitte      = "~o~Der Verfolgungsdruck lässt nach! Nutze deine Chance!",
    NachrichtEnde       = "~g~Die Polizei zieht sich zurück! Jetzt entkommen!",
    NachrichtFortschritt = "~y~Nachlassen~s~: %d%% — Halte durch!",
}

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
-- ║              ENTKOMMEN (Flucht gelingt bei guter Evasion)       ║
-- ║  Wenn der Spieler lange genug ALLEN Cops entwischt (kein Cop    ║
-- ║  in Sichtweite), sinkt das Wanted-Level und er entkommt.        ║
-- ║  Belohnt geschickte Spieler, die wirklich gut entkommen!        ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Entkommen = {
    Aktiviert           = true,     -- true = Entkommen möglich
    FreiRadius          = 80.0,     -- Meter: Kein Cop darf SO NAH sein (dann zählt Evasion)
    ZeitBisEntkommen    = 45,       -- Sekunden: So lange muss Spieler ALLEN Cops entwischt sein
    NachrichtEvasion    = "~b~Polizei verliert dich...~s~ Noch %ds bis Entkommen!",
    NachrichtEntkommen  = "~g~ENTKOMMEN!~s~ Du hast die Polizei abgehängt!",
    NachrichtVerloren   = "~r~ENTDECKT!~s~ Die Polizei hat dich wieder im Visier!",
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

    -- Kriminallevel senken: Spieler kann Festnahmen gegen Geld reduzieren
    -- Gestaffelte Kosten: je mehr Festnahmen, desto teurer jede Reduktion.
    -- Die passende Stufe wird anhand der aktuellen Festnahmenanzahl ermittelt.
    KriminalLevelSenken = {
        Aktiviert           = true,     -- true = Spieler kann Level am NPC senken
        MindestFestnahmen   = 0,        -- Mindest-Festnahmen die erhalten bleiben (0 = alles loeschbar)
        -- Stufen: AbFestnahmen = Schwelle ab der diese Kosten gelten
        -- PFLICHT: aufsteigend nach AbFestnahmen sortieren, sonst falsche Kostenberechnung!
        Stufen = {
            { AbFestnahmen = 1,  Kosten = 2500  },   -- 1-2 Festnahmen:  2.500 EUR pro Reduktion
            { AbFestnahmen = 3,  Kosten = 5000  },   -- 3-4 Festnahmen:  5.000 EUR
            { AbFestnahmen = 5,  Kosten = 10000 },   -- 5-9 Festnahmen: 10.000 EUR
            { AbFestnahmen = 10, Kosten = 25000 },   -- 10-19 Festnahmen: 25.000 EUR
            { AbFestnahmen = 20, Kosten = 50000 },   -- 20+ Festnahmen:  50.000 EUR
        },
    },
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              JOB-WHITELIST (Exemption vom Wanted-System)        ║
-- ║  Spieler mit diesen Jobs oder Admin-Ace erhalten KEINEN         ║
-- ║  Wanted-Level und das Szenario startet nicht fuer sie.          ║
-- ║  Aktiviert = false  →  alle Spieler sind betroffen              ║
-- ║  Aktiviert = true   →  Jobs/Admins sind exempt                  ║
-- ║  Job-Wechsel wird live erkannt (esx:setJob).                    ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.JobWhitelist = {
    Aktiviert   = true,
    Jobs        = { "police", "sheriff", "fib", "swat", "ambulance", "doj" },  -- ESX-Jobnamen
    AdminAce    = "command.mtj_admin",                     -- Ace-Permission fuer Admin-Exempt
}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              DEBUG                                              ║
-- ╚══════════════════════════════════════════════════════════════════╝
Config.Debug                    = false   -- true = Debug-Ausgaben in Konsole

return Config
