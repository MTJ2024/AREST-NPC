fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mtj_arrest'
author 'MTJ'
version '2.0.0'
description 'Immersives RP-Festnahme-Szenario mit NPC-Polizei, ESX Jail, UI-Timer, Enhanced Effects: Helicopter, Roadblocks, Slow Motion, Cinematic Camera, Particle Effects & More'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/app.js'
}

shared_scripts {
  'config/config.lua'
}

client_scripts {
  'client/main.lua',                 -- <--- FEHLTE!
  'client/effects.lua',
  'client/effects_handler.lua',
  'client/helicopter.lua',
  'client/roadblock.lua',
  'client/wanted_display.lua',
  'client/wanted_generator.lua',
  'client/nui_focus_handlers.lua',
  'client/auto_cop_spawn.lua',
  'client/controls.lua',
  'client/external_police.lua',  
  'client/debug.lua'
}

server_scripts {
  'server/police_players.lua',  
  'server/main.lua'
}

dependencies {
  'es_extended'
}