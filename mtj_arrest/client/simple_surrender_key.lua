-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- client/simple_surrender_key.lua
-- Erzwungene Übergabe via Befehl (E-Taste wird von main.lua behandelt)

RegisterCommand('mtj_force_surrender', function()
  print("[mtj_arrest][CMD] Erzwungene Übergabe via /mtj_force_surrender")
  TriggerEvent('mtj_arrest:forceSurrender')
end, false)