# Hunted - Dynamic Ambushes & Revenge System

Hunted adds systemic retaliation gameplay to Baldur's Gate 3. Hostile territory becomes more dangerous over time, repeated creature-type kills build revenge pressure, and enemies can retaliate through exploration, rest, and champion ambushes.

## Requirements

- Baldur's Gate 3 Script Extender version `30` or newer
- BG3MCM

BG3MCM is a hard dependency. The mod uses it for the supported settings UI and server-authoritative settings sync path.

## Main Features

- Dynamic ambushes during exploration and rests
- Creature-type reputation and revenge escalation
- Region and safety gating
- Champion retaliation encounters
- Preset-based pacing and difficulty pressure
- Combat Extender-aware scaling
- Server-side Lua API for compatibility patches

## Installation

1. Install or update BG3 Script Extender.
2. Install BG3MCM.
3. Install the packaged `.pak` with your normal BG3 mod manager workflow.
4. Enable the mod and load the game.

This repository contains source files. Packaged release archives are distributed separately.

## Repository Layout

- `Hunted_DynamicAmbushes_Revenge_System/` - BG3 mod source folder.
- `docs/API.md` - public server-side API reference.
- `docs/COMPATIBILITY.md` - compatibility notes.
- `docs/CONFIG.md` - configuration notes.
- `docs/TROUBLESHOOTING.md` - support and diagnostics.
- `docs/CHANGELOG.md` - concise public changelog.

## API

The public API namespace is `EnemyAmbush` / `EnemyAmbush.API`.

Current additive API surface: `1.5.0`

See `docs/API.md` for provider registration, custom ambush triggering, reputation helpers, and XP-clone mapping support for external templates.

## Bug Reports

Please include:

- full Script Extender Runtime log
- party level and size
- region / area
- selected preset and notable settings
- whether Combat Extender was installed or enabled
- exact reproduction steps when possible

## Naming

- Public mod name: `Hunted - Dynamic Ambushes & Revenge System`
- Module folder: `Hunted_DynamicAmbushes_Revenge_System`
- Internal Lua/API namespace: `EnemyAmbush`
- Module UUID: `96f24297-6ed9-455c-aaa1-ac9c358a8d35`

## License

See `LICENSE`.
