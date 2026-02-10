# Testing Guide for Wanted Level System

This document describes how to test the new wanted level system that was implemented to fix the issue where no police came when shooting/killing NPCs.

## What Was Fixed

The issue was that the game did not automatically give wanted stars when the player committed crimes (shooting, killing). This has been fixed by adding a new `wanted_level.lua` client script that monitors player actions and sets wanted levels accordingly.

## How to Test

### Prerequisites
1. Start your FiveM server with the `mtj_arrest` resource loaded
2. Join the server

### Test Case 1: Shooting Weapon
1. Acquire any weapon (pistol, rifle, etc.)
2. Fire the weapon in the air or at objects
3. **Expected Result**: You should receive 2 wanted stars immediately after shooting
4. **Expected Result**: After ~1-2 seconds, police NPCs should spawn around you (auto_cop_spawn.lua)
5. **Expected Result**: You should see the surrender UI appear with "[E] to surrender"

### Test Case 2: Injuring a Ped
1. Acquire a weapon
2. Shoot an NPC ped but don't kill them (aim for legs/arms)
3. **Expected Result**: You should receive 3 wanted stars
4. **Expected Result**: Police should spawn and pursue you

### Test Case 3: Killing a Ped
1. Acquire a weapon
2. Kill an NPC ped
3. **Expected Result**: You should receive 4 wanted stars
4. **Expected Result**: More police should spawn (up to 7 cops based on wanted level)

### Test Case 4: Multiple Crimes
1. Shoot weapon (2 stars)
2. Kill a ped (should increase to 4 stars)
3. Kill another ped (should stay at 4 stars but be tracked)
4. **Expected Result**: Wanted level should max at the highest crime committed

### Test Case 5: Safety Checks
1. Get arrested and sent to jail
2. While in jail (frozen position), try to shoot
3. **Expected Result**: No wanted level should increase while in jail
4. After release, shoot again
5. **Expected Result**: Wanted level should work normally after release

## Debug Commands

The following commands are available for testing:

- `/mtj_test_wanted [1-5]` - Manually set wanted level (e.g., `/mtj_test_wanted 3`)
- `/mtj_test_start` - Manually trigger the arrest scenario
- `/mtj_popon` - Enable NPC population (if disabled)
- `/mtj_cops` - Toggle police ignore player status

## Configuration

The wanted level system can be configured in `mtj_arrest/config/config.lua`:

```lua
Config.WantedSystem = {
  enabled = true,                    -- Enable/disable the system
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

## Known Behavior

1. **Wanted Cooldown**: There's a 3-second cooldown between wanted level increases to prevent spam
2. **Police Spawn Threshold**: Police only spawn at wanted level 2 or higher (auto_cop_spawn.lua)
3. **Scenario Trigger**: The arrest scenario requires wanted level > 0 to start
4. **Jail Reset**: Wanted level is cleared when sent to jail

## Troubleshooting

If wanted levels are not being set:
1. Check the F8 console for `[mtj_arrest][WANTED]` debug messages
2. Verify the resource is started: `/status` or `/resources`
3. Restart the resource: `/restart mtj_arrest`
4. Check if DEBUG is enabled in wanted_level.lua (should be `local DEBUG = true`)

If police are not spawning:
1. Check that wanted level is >= 2 using `/mtj_test_wanted 3`
2. Check if auto_cop_spawn.lua is loaded in fxmanifest.lua
3. Enable population with `/mtj_popon` if NPCs are disabled
4. Check F8 console for spawn errors
