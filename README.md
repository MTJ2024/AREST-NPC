# AREST-NPC

Immersive RP arrest scenario with NPC police, ESX jail integration, and automatic wanted level system for FiveM.

## Features

- **Automatic Wanted Level System**: Automatically gives wanted stars when players commit crimes
  - 2 stars for shooting weapons
  - 3 stars for injuring NPCs
  - 4 stars for killing NPCs
  - Configurable detection radii and wanted levels
  
- **Aggressive NPC Police System**: (NEW - 100% RELIABLE)
  - **Aggressive Mode** (default): Police spawn and immediately attack - NO PASSIVE STANDING
  - Police stay engaged and within combat radius - NO WANDERING OFF
  - All police maintain combat with player - ALWAYS ACTIVE
  - Periodic re-engagement to ensure 100% combat reliability
  - Alternative **Surrender Mode**: 10-second window to surrender before combat
  
- **NPC Police Spawning**: Automatically spawns police NPCs when wanted level >= 2
  - Spawns 2-7 cops based on wanted level
  - Police NPCs engage in combat and pursue the player
  - Maximum aggression settings ensure active combat
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
Config.PoliceMode = "aggressive"      -- "aggressive" = police always attack immediately
                                       -- "surrender" = police wait for surrender (10s window)
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

### Aggressive Mode (Default - 100% Reliable)
1. **Crime Detection**: The wanted level system monitors player actions (shooting, injuring, killing)
2. **Wanted Level**: Appropriate wanted level is set based on the crime committed
3. **Aggressive Police Spawn**: At wanted level >= 2, police NPCs spawn with maximum aggression
4. **Continuous Combat**: Police stay engaged, never wander off, and continuously attack
5. **Re-engagement System**: Every 3 seconds, police are forced back into combat if they stop
6. **Surrender Option**: Player can still press [E] to surrender at any time
7. **Arrest**: Upon surrender, arrest animations play and player is sent to jail
8. **Jail**: Player is teleported to jail, weapons/items confiscated, and fine deducted
9. **Release**: After serving time, player is released outside the prison

### Surrender Mode (Alternative)
1. **Crime Detection**: Same as aggressive mode
2. **Wanted Level**: Same as aggressive mode  
3. **Police Spawn**: At wanted level >= 2, police NPCs spawn in passive mode
4. **Surrender Window**: Player has 10 seconds to press [E] to surrender
5. **Combat Activation**: If surrender window expires, police become aggressive
6. **Rest of process**: Same as aggressive mode from step 6 onwards

## Credits

- Author: MTJ
- Version: 1.0.0
- Framework: ESX
