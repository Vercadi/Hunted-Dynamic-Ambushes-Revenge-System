# Hunted - Dynamic Ambushes & Revenge System

Hunted adds dynamic ambushes and creature revenge pressure to Baldur's Gate 3. Danger can build while the party travels through hostile areas, and enemies may retaliate based on party level, effective party size, region, and creature-type pressure.

## Download

- Nexus Mods: https://www.nexusmods.com/baldursgate3/mods/22317

## Requirements

- Baldur's Gate 3 with Script Extender v30 or newer
- BG3 Mod Configuration Menu (BG3MCM)

## Install

1. Install BG3 Script Extender.
2. Install BG3MCM.
3. Download the release archive from Nexus Mods.
4. Install the Hunted `.pak` with your normal BG3 mod manager workflow.
5. Enable the mod and load the game.

## Compatibility API

Hunted exposes a server-side Script Extender API for compatibility patches, enemy-provider patches, champion-provider patches, custom ambush integrations, reputation helpers, and XP-clone mapping.

Compatibility authors should start here:

- `API.md`

## Support Commands

Useful in-game Script Extender console commands:

- `!ea_test verify`
- `!ea_test settings`
- `!ea_test pressure`
- `!ea_test region`
- `!ea_test encountersummary`

## Source Layout

The packaged mod source is in:

- `Hunted_DynamicAmbushes_Revenge_System/`

Private planning docs, tooling, and modpage assets are intentionally not included in this public release-source repo.

## License

This repository is source-available for reference, compatibility work, and personal use. See `LICENSE`.
