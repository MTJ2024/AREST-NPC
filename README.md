# AREST-NPC
AREST NPC - Enhanced Police Arrest System with Cinematic Effects

## 🚨 Features

### Core Features
- **NPC Police Spawning** - Dynamic police NPC spawning based on wanted level
- **Surrender System** - Press [E] to surrender and avoid combat
- **Jail System** - Full jail integration with ESX
- **UI Timer** - Beautiful countdown and jail timer interface

### 🎬 Enhanced Effects (v2.0)
- **Custom Wanted Level Display** - Beautiful GTA V Online style wanted stars above minimap
- **Slow Motion** - Dramatic slow motion during arrest sequence
- **Cinematic Camera** - Automatic camera angles during cuffing
- **Screen Effects** - Blur, shake, and visual effects
- **Particle Effects** - Dust clouds and impact effects
- **Sound Effects** - Police radio, sirens, cuffing sounds
- **Police Helicopter** - Spawns at 4+ wanted stars with spotlight
- **Dynamic Roadblocks** - Police roadblocks at 3+ wanted stars
- **Flashing Lights** - Police light effects and animations
- **Enhanced UI** - Pulsing, glowing, and urgent countdown effects

## 🔧 Troubleshooting

### Nothing happens when I use the script

**Solution:** The system needs a wanted level to activate. Try these steps:

1. **Quick Start (Easiest):**
   ```
   /mtj_start
   ```
   This will set wanted level 2 and trigger the scenario instantly.

2. **Manual Wanted Level:**
   ```
   /mtj_wanted 2
   ```
   Then wait a moment for police to spawn.

3. **Auto Wanted (Default):**
   - Shoot your weapon
   - Drive recklessly at high speed (120+ km/h)
   - Get in melee combat
   - The system will auto-generate wanted level

4. **Check F8 Console:**
   - Look for debug messages from `[mtj_arrest]`
   - Check if wanted level is being set
   - See if cops are spawning

### Wanted stars not showing

- Make sure `Config.Effects.EnableCustomWantedDisplay = true` in config
- Check F8 console for NUI errors
- Try `/mtj_checkwanted` to see current level

### Police not spawning

- Wanted level must be 2 or higher for police to spawn
- Check F8 console for `[mtj_arrest][AUTO_COP]` messages
- Make sure resource is started: `ensure mtj_arrest` in server.cfg

### Scenario not starting

- Use `/mtj_start` for instant test
- Check if `Config.AutoWantedLevel.Enabled = true`
- Verify wanted level is set with `/mtj_checkwanted`

## ⚙️ Configuration

All effects and features can be configured in `config/config.lua`:

### Auto Wanted Level Generation
```lua
Config.AutoWantedLevel = {
  Enabled = true,                       -- Enable automatic wanted level generation
  SetWantedOnCrime = true,              -- Set wanted level when committing crimes
  SetWantedOnPoliceDetection = true,    -- Set wanted level when police detect you
  DefaultWantedLevel = 2,               -- Default wanted level when auto-generated
  MinWantedLevel = 2,                   -- Minimum wanted level for arrest scenario
  MaxWantedLevel = 5                    -- Maximum wanted level
}
```

### Visual Effects
```lua
Config.Effects = {
  EnableSlowMotion = true,
  EnableArrestCamera = true,
  EnableHelicopter = true,
  EnableRoadblocks = true,
  EnableScreenEffects = true,
  EnableSoundEffects = true,
  EnableParticleEffects = true,
  EnableCustomWantedDisplay = true,  -- GTA V Online style wanted stars
  SlowMotionStrength = 0.3,
  SlowMotionDuration = 4000,
  HelicopterWantedLevel = 4,
  RoadblockWantedLevel = 3
}
```

## 🎮 How It Works

1. **Get Wanted Level** 
   - The system will auto-generate wanted level when you commit crimes (shooting, reckless driving, melee combat)
   - OR use test commands: `/mtj_wanted 2` to set wanted level manually
   - OR use quick presets: `/mtj_wanted1`, `/mtj_wanted2`, `/mtj_wanted3`, `/mtj_wanted4`, `/mtj_wanted5`
2. **Police Response** - NPCs spawn at 2+ stars, roadblocks at 3+, helicopter at 4+
3. **Surrender Option** - Press [E] to surrender when surrounded
4. **Cinematic Arrest** - Enjoy the enhanced visual effects during arrest
5. **Jail Time** - Serve your time with the enhanced UI

## 🎮 Test Commands

For testing purposes, you can use these commands:

### Quick Start
- `/mtj_start` - **Quick start!** Sets wanted level to 2 and triggers scenario instantly
- `/mtj_status` - **System status check** - Shows configuration and current state

### Wanted Level Control
- `/mtj_wanted [1-5]` - Set wanted level to specific number
- `/mtj_wanted1` through `/mtj_wanted5` - Quick presets
- `/mtj_clearwanted` - Clear wanted level
- `/mtj_checkwanted` - Check current wanted level

### Testing Features
- `/mtj_test_start` - Manually trigger arrest scenario
- `/mtj_test_arrestlog` - Test arrest log UI
- `/mtj_test_cuff` - Test handcuff visuals

## 🎨 New Visual Effects

- **Custom Wanted Level Stars**: GTA V Online style display above minimap with:
  - Animated star appearance
  - Color-coded by danger level (gold → orange → red)
  - Pulsing glow effects
  - Shake effect at max wanted level
  - Smooth transitions
- **Police Arrival**: Screen flash, camera shake, dust particles
- **Surrender**: Blur effect, surrender sound
- **Arrest Sequence**: Slow motion, cinematic camera, dramatic lighting
- **Helicopter**: Spotlight from above, dynamic lighting
- **Roadblocks**: Flashing police lights, armed officers

## 🔊 Sound Effects

- Police radio chatter
- Siren sounds
- Arrest confirmation
- Handcuff sounds
- Helicopter sounds

## 📦 Installation

1. Place `mtj_arrest` folder in your resources directory
2. Add `ensure mtj_arrest` to your server.cfg
3. Restart your server
4. Configure settings in `config/config.lua` to your preference

## ⚙️ Dependencies

- es_extended (ESX)
- Optional: ox_inventory (for enhanced item management)

## 🎯 Wanted Level System

- **1-2 Stars**: Basic police NPCs
- **3 Stars**: Roadblocks + more aggressive pursuit
- **4+ Stars**: Helicopter + spotlight + maximum pressure

## 🎨 UI Customization

The UI features:
- Pulsing opacity effects
- Glowing borders
- Police light color flashing
- Urgent countdown animations
- Enhanced jail timer with gradient effects
- Fine badge with glow animation

