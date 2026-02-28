-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  AREST-NPC — Copyright (c) 2024-2026 MTJ2024. Alle Rechte vorbehalten. ║
-- ║  Unbefugtes Kopieren, Verbreiten oder Modifizieren ist UNTERSAGT.      ║
-- ║  Plagiatschutz aktiv — Unbefugte Nutzung wird erkannt und gemeldet.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mtj_arrest'
author 'MTJ'
version '1.0.0'
description 'AREST-NPC — Immersives RP-Festnahme-Szenario mit NPC-Polizei, ESX Jail, UI-Timer'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/app.js',
  'html/police_bg.png'
}

shared_scripts {
  'config/config.lua'
}

client_scripts {
  'client/main.lua',
  'client/wanted_level.lua',
  'client/nui_focus_handlers.lua',
  'client/controls.lua'
}

server_scripts {
  'server/copyright_guard.lua',
  'server/polizeiakte.lua',
  'server/main.lua'
}

dependencies {
  'es_extended'
}