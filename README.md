# AREST-NPC

Immersive RP arrest scenario with NPC police, ESX jail integration, and automatic wanted level system for FiveM.

## Features

- **Automatic Wanted Level System**: Automatically gives wanted stars when players commit crimes
  - 2 stars for shooting weapons
  - 3 stars for injuring NPCs
  - 4 stars for killing NPCs
  - Configurable detection radii and wanted levels
  
- **NPC Police Spawning**: Automatically spawns police NPCs when wanted level >= 2
  - Spawns 2-7 cops based on wanted level
  - Police NPCs engage in combat and pursue the player
  - Despawns when wanted level drops below 2

- **Arrest Scenario**: 
  - Surrender system with [E] key
  - 10-second compliance window
  - Realistic handcuffing animations
  - Arrest log display

- **ESX Jail Integration**:
  - Automatic teleportation to Bolingbroke Prison
  - Configurable jail time
  - Automatic weapon and item confiscation
  - Configurable jail fine (money/bank deduction)
  - Release teleportation after time served

## Installation

1. Ensure you have `es_extended` installed
2. Place `mtj_arrest` folder in your `resources` directory
3. Add `ensure mtj_arrest` to your `server.cfg`
4. Restart your server or use `/restart mtj_arrest`

## Configuration

Edit `mtj_arrest/config/config.lua` to customize the resource:

### Wanted Level System
```lua
Config.WantedSystem = {
  enabled = true,                    -- Enable/disable automatic wanted levels
  shootingWantedLevel = 2,          -- Stars for shooting
  injuringWantedLevel = 3,          -- Stars for injuring
  killingWantedLevel = 4,           -- Stars for killing
  cooldownMs = 3000,                -- Cooldown between increases
  applyForPlayerKills = false,      -- Apply to PvP kills
  deathDetectionRadius = 50.0,      -- Radius to detect deaths
  injuryDetectionRadius = 30.0,     -- Radius to detect injuries
  combatTimeoutMs = 5000            -- Combat timeout after shooting
}
```

### Police Spawning
```lua
Config.PoliceCount = 7                -- Max cops to spawn
Config.PoliceSpawnRadius = 40.0       -- Spawn radius around player
Config.PoliceChaseWanted = true       -- Auto-chase on wanted
```

### Jail Settings
```lua
Config.JailMinutes = 10               -- Jail time in minutes
Config.JailFine = 15000               -- Fine amount
Config.EnableJailFine = true          -- Enable/disable fine
Config.JailPosition = vector3(...)    -- Jail coordinates
```

## Commands

- `/mtj_test_wanted [1-5]` - Set wanted level (debug)
- `/mtj_test_start` - Start arrest scenario (debug)
- `/mtj_popon` - Enable NPC population
- `/mtj_popoff` - Disable NPC population
- `/mtj_cops` - Toggle police ignore player

## Testing

See [TESTING.md](TESTING.md) for comprehensive testing instructions.

## How It Works

1. **Crime Detection**: The wanted level system monitors player actions (shooting, injuring, killing)
2. **Wanted Level**: Appropriate wanted level is set based on the crime committed
3. **Police Spawn**: At wanted level >= 2, police NPCs spawn and engage the player
4. **Surrender Option**: Player can press [E] to surrender within a 10-second window
5. **Arrest**: Upon surrender, arrest animations play and arrest log is displayed
6. **Jail**: Player is teleported to jail, weapons/items confiscated, and fine deducted
7. **Release**: After serving time, player is released outside the prison

## Credits

- Author: MTJ
- Version: 1.0.0
- Framework: ESX
