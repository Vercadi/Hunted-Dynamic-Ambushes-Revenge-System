# Changelog

## 1.0.2 - Stability and Loot Defaults

- Fixed `!ea_test settings` crashing when an old save does not have the removed arrival-cue chance-scale setting.
- Changed all presets, including Hunted, to allow generated ambush loot and champion loot by default.
- Moved `Steel Watcher Titan` to Construct champion-only and removed Titan-form Steel Watcher rows from random Legendary ambushes.
- Moved `Adamantine Golem` into the normal Legendary Construct pool.
- Bumped packaged metadata and runtime version to `1.0.2`.

## 1.0.1 - Needle Blight Hotfix

- Removed `Needle Blight` from the normal Plant ambush pool after runtime feedback showed its `Needle Blast` burst could one-turn level 6 parties.
- Preserved Plant champion selection; this template was not promoted to champion because champion scaling would amplify the same burst-risk corridor.
- Bumped packaged metadata and runtime version to `1.0.1`.

## 1.0.0 - Initial Nexus Release

- Added dynamic exploration and rest ambushes with region and safety gating.
- Added creature-type reputation and revenge escalation.
- Added champion retaliation encounters.
- Added champion retinues for harder presets and larger parties.
- Added BG3MCM-backed preset and advanced settings.
- Added Combat Extender-aware scaling support.
- Added sub-100% ambush XP support through zero-XP clone templates and manual payout.
- Added server-side API surface `1.5.0` for compatibility patches, including provider registration, custom ambush triggering, reputation helpers, and XP-clone mapping support.

This public changelog is intentionally concise. The full development changelog is kept in the private development repository.
