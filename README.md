# AREST-NPC
AREST NPC - Enhanced Police Arrest System with Cinematic Effects

## 🚨 Features

### Core Features
- **NPC Police Spawning** - Dynamic police NPC spawning based on wanted level
- **Surrender System** - Press [E] to surrender and avoid combat
- **Jail System** - Full jail integration with ESX
- **UI Timer** - Beautiful countdown and jail timer interface

### 🎬 Enhanced Effects (v2.0)
- **Slow Motion** - Dramatic slow motion during arrest sequence
- **Cinematic Camera** - Automatic camera angles during cuffing
- **Screen Effects** - Blur, shake, and visual effects
- **Particle Effects** - Dust clouds and impact effects
- **Sound Effects** - Police radio, sirens, cuffing sounds
- **Police Helicopter** - Spawns at 4+ wanted stars with spotlight
- **Dynamic Roadblocks** - Police roadblocks at 3+ wanted stars
- **Flashing Lights** - Police light effects and animations
- **Enhanced UI** - Pulsing, glowing, and urgent countdown effects

## 📋 Configuration

All effects can be configured in `config/config.lua`:

```lua
Config.Effects = {
  EnableSlowMotion = true,
  EnableArrestCamera = true,
  EnableHelicopter = true,
  EnableRoadblocks = true,
  EnableScreenEffects = true,
  EnableSoundEffects = true,
  EnableParticleEffects = true,
  SlowMotionStrength = 0.3,
  SlowMotionDuration = 4000,
  HelicopterWantedLevel = 4,
  RoadblockWantedLevel = 3
}
```

## 🎮 How It Works

1. **Get Wanted Stars** - Commit crimes to get a wanted level
2. **Police Response** - NPCs spawn at 2+ stars, roadblocks at 3+, helicopter at 4+
3. **Surrender Option** - Press [E] to surrender when surrounded
4. **Cinematic Arrest** - Enjoy the enhanced visual effects during arrest
5. **Jail Time** - Serve your time with the enhanced UI

## 🎨 New Visual Effects

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

