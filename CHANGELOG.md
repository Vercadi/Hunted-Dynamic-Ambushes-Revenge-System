# Hunted - Changelog

## 1.0.6 - Stability and safe-zone hardening

- Fixed delayed rest ambushes so temporary blockers such as post-combat grace, dialogue/cutscenes, camp safety, and safe zones preserve/requeue pending ambushes instead of dropping them too early.
- Changed the first `You are hunted` tutorial popup so it waits until Hunted has actually committed to a player-facing event, champion spawn, or delayed ambush queue.
- Added `!ea_test pressure` and `!ea_test state` support commands for concise region, safe-zone, cooldown, pending-ambush, and Time-in-Danger diagnostics.
- Added additional safe-zone coverage for Druid/Grove sublevels, Zevlor/tiefling den coverage, tiefling children hideout crime region, Auntie Ethel's lair, Mind Flayer Colony, Ketheric Entrance, and Moonrise Dungeon.
- Fixed Hunted out-of-sight placement so probes that land inside blocked safe zones are rejected and cleaned up before becoming registered ambushers.
- Added a short camp-exit grace window so preserved delayed ambushes do not fire immediately when camp safety clears.
- Fixed Advanced preset editing so `CUSTOM` keeps the correct `Custom Base Preset` instead of visually falling back to `Marked`.
- Added conservative save-maintenance pruning for malformed Hunted pending/spawned records without clearing reputation, cooldown, or pressure state.
- Added `!ea_test uninstallprep dryrun|confirm` to report or clear Hunted-owned active/pending runtime state and disable future Hunted ambush settings before a risky uninstall attempt. This does not promise warning-free BG3 mod removal.
- Updated package and runtime metadata to `1.0.6`.

## 1.0.5 - Balance and safe-zone patch

- Migrated existing `AUTO` spawn-placement saves once to `Create OOS Only` while preserving explicit `Find Valid Only`.
- Added effective party-size scaling where real party members count fully and summons/followers contribute one effective member per four.
- Fixed small-party caps and added early-game spawn-count clamps for levels 1-4.
- Reduced Combat Extender normal-ambusher durability packages while leaving non-CX durability and champion packages unchanged.
- Added Act 3 story/interior safe-zone coverage while keeping Lower City streets eligible for ambushes.

## 1.0.4 - Safety and placement patch

- Removed broken Vampire Squid templates from the active vanilla summon pool.
- Raised min-party-level gates for selected heavy midgame and DREAD templates.
- Made `Create OOS Only` the default normal placement mode.
- Added broader Act 1 and Act 2 safe-zone coverage and post-vanilla-combat grace.

## 1.0.3.2 - MCM persistence hotfix

- Fixed preset-owned MCM setting persistence issues for surprise and Time-in-Danger pressure.

## 1.0.3.1 - Template safety hotfix

- Removed unsafe Fey/Beast templates discovered through runtime testing.

## 1.0.3 - Diagnostics and safety guards

- Added encounter summaries and Hunted-only stuck/unreachable cleanup improvements.

## 1.0.2 - Stability and loot-default cleanup

- Fixed settings diagnostics and adjusted default loot behavior.

## 1.0.1 - Needle Blight hotfix

- Removed Needle Blight from the normal Plant summon pool after runtime feedback showed excessive burst risk.
