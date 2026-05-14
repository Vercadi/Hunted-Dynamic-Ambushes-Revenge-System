# Hunted - Dynamic Ambushes & Revenge System

[![Source release](https://img.shields.io/github/v/release/Vercadi/Hunted-Dynamic-Ambushes-Revenge-System?label=source%20release)](https://github.com/Vercadi/Hunted-Dynamic-Ambushes-Revenge-System/releases)
[![License](https://img.shields.io/badge/license-source--available-lightgrey)](LICENSE)
[![Nexus Mods](https://img.shields.io/badge/Nexus%20Mods-player%20download-orange)](https://www.nexusmods.com/baldursgate3/mods/22317)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-support-ff5f5f)](https://ko-fi.com/vercadi)
[![Patreon](https://img.shields.io/badge/Patreon-support-f96854)](https://www.patreon.com/cw/Vercadi)

Hunted adds dynamic ambushes and creature revenge pressure to Baldur's Gate 3. Danger can build while the party travels through hostile areas, and enemies may retaliate based on party level, effective party size, region, and creature-type pressure.

This GitHub repository is for source/reference use. Players should download the packaged mod from Nexus Mods.

## Media

Screenshots, images, and packaged player files are hosted on the [Nexus Mods page](https://www.nexusmods.com/baldursgate3/mods/22317). No screenshot asset is currently tracked in this source repository.

## Download

- Player download: [Hunted on Nexus Mods](https://www.nexusmods.com/baldursgate3/mods/22317)
- Source release: [GitHub Releases](https://github.com/Vercadi/Hunted-Dynamic-Ambushes-Revenge-System/releases)
- Source repository: [GitHub](https://github.com/Vercadi/Hunted-Dynamic-Ambushes-Revenge-System)

Do not install GitHub source archives as packaged BG3 mods. Use the Nexus file for normal play.

## Requirements

- Baldur's Gate 3
- BG3 Script Extender v30 or newer
- BG3 Mod Configuration Menu (BG3MCM)

## Installation

1. Install BG3 Script Extender.
2. Install BG3MCM.
3. Download the packaged release archive from [Nexus Mods](https://www.nexusmods.com/baldursgate3/mods/22317).
4. Install the Hunted `.pak` with your normal BG3 mod manager workflow.
5. Enable the mod and load the game.

## Update

Download the latest packaged file from Nexus Mods and replace the old version through your BG3 mod manager. Check the [changelog](CHANGELOG.md) before updating a long-running save.

## Usage

Configure Hunted through BG3MCM in game. Useful Script Extender console diagnostics:

- `!ea_test verify`
- `!ea_test settings`
- `!ea_test pressure`
- `!ea_test state`
- `!ea_test region`
- `!ea_test encountersummary`
- `!ea_test uninstallprep dryrun|confirm`

## Compatibility

Hunted exposes a server-side Script Extender API for compatibility patches, enemy-provider patches, champion-provider patches, custom ambush integrations, reputation helpers, and XP-clone mapping.

Compatibility authors should start with [API.md](API.md). This is a server-side Script Extender surface and should not be called from the client bootstrap path.

## Bug Reports / Support

Use [Nexus Mods](https://www.nexusmods.com/baldursgate3/mods/22317) for player support and [GitHub Issues](https://github.com/Vercadi/Hunted-Dynamic-Ambushes-Revenge-System/issues) for source or compatibility work. Include your Script Extender log, Hunted version, BG3MCM settings, party level/composition, region, and exact reproduction steps when possible.

Support continued work through [Ko-fi](https://ko-fi.com/vercadi) or [Patreon](https://www.patreon.com/cw/Vercadi).

## Source Layout

- `Hunted_DynamicAmbushes_Revenge_System/` - BG3 mod source folder.
- `API.md` - compatibility API notes.
- `CHANGELOG.md` - public changelog.
- `LICENSE` - source-available license terms.

Private planning docs, tooling, packaged `.pak` files, logs, and modpage art dumps are intentionally not included in this public source repository.

## License

This repository is source-available for reference, compatibility work, and personal use. See [LICENSE](LICENSE).
