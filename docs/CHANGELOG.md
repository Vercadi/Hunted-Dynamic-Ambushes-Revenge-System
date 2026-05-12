# Changelog

## 1.0.5 - Balance and Safe-Zone Patch

- Migrated older saved `AUTO` spawn placement settings to `Create OOS Only`; explicit `Find Valid Only` is preserved.
- Changed party-size scaling to use effective party size: real party members count fully, while non-player party members, summons, and followers count as one extra member per four.
- Fixed small-party entity caps so 3-person parties no longer inherit the 6-enemy default cap.
- Added early-game spawn-count clamps for levels 1-4.
- Changed small parties to stop closer to the target enemy count unless the encounter is intentionally using a fodder/swarm path.
- Reduced Combat Extender normal ambusher durability packages while leaving non-CX durability, champions, rewards, cooldowns, and reputation unchanged.
- Fixed OOS ambushers that repeatedly fail to join combat being cleaned up as Hunted-only spawns.
- Added Act 3 story/interior safe-zone coverage for major Lower City interiors and setpieces while keeping Lower City streets eligible.
- Bumped packaged metadata and runtime version to `1.0.5`.

## 1.0.4 - Safety and Placement Patch

- Removed broken `Vampire Squid Tentacle` and `Vampire Squid` templates from the active vanilla summon pool.
- Raised min-party-level gates for selected heavy midgame and DREAD templates, including Owlbears, Driders, Cambions, Mind Flayers, and stronger Githyanki variants.
- Tightened early min-party-level gates for several non-beach spike/weirdness picks.
- Changed default spawn placement to `Create OOS Only`; explicit `AUTO` and `Find Valid Only` remain available as Advanced/debug placement modes.
- Reduced Combat Extender ambush budget/intensity trimming from `0.90` to `0.80`.
- Added broader safe-zone coverage for Kagha/Druid lair, Emerald Grove hub areas, Last Light Inn, Moonrise Towers, major Act 2 interiors, and Auntie Ethel's lair.
- Added a separate 5-minute post-vanilla-combat grace window that resets Time-in-Danger after non-Hunted party combat.
- Fixed Nautiloid/tutorial time carrying into immediate normal beach ambush pressure.
- Bumped packaged metadata and runtime version to `1.0.4`.

## 1.0.3.2 - MCM Persistence Hotfix

- Hid `Apply Surprise on Ambush` until Advanced Mode is enabled, matching its preset-owned behavior.
- Changed `Enable Time-In-Danger Pressure` to a global/simple setting so turning it off is no longer overwritten by preset sync on save load.
- Bumped packaged metadata and runtime version to `1.0.3.2`.

## 1.0.3.1 - Template Safety Hotfix

- Removed `Redcap Blood Sage` from the ordinary Fey ambush pool after runtime testing showed it could pull neutral hag-swamp Redcaps into unrelated combat.
- Removed `Green Hag Matriarch` / Auntie Ethel from Fey champion rotation and temporarily disabled generic Fey champion fallback until a safe non-story Fey champion candidate is audited.
- Removed `Addled Frog` from the ordinary Beast ambush pool because its generic spawned combat kit was not usable.
- Bumped packaged metadata and runtime version to `1.0.3.1`.

## 1.0.3 - Diagnostics and Safety Guards

- Added concise encounter summaries and the `!ea_test encountersummary` debug command.
- Added clearer diagnostics for selected templates, placement, runtime blockers, XP payout, cleanup, and champion retinues.
- Added short post-load ambush grace/requeue handling so pending ambushes do not fire immediately after loading a save.
- Added dialogue/cutscene safety requeue behavior with blocker reason `dialog_or_cutscene`.
- Added Hunted-only stuck/unreachable cleanup for bad placements and combat softlock cases.
- Fixed party-fled cleanup so remaining Hunted ambushers are removed when the party fully leaves/flees an ambush combat.
- Added `!ea_test cleanupabandoned [current|combatGuid|all] [force]` for debug cleanup validation.
- Bumped packaged metadata and runtime version to `1.0.3`.

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
