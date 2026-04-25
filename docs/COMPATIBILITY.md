# Compatibility

## Requirements

- `BG3 Script Extender` is required
- required version: `30`
- `BG3MCM` is required

## BG3MCM

- the mod requires `BG3MCM`
- settings changes are handled by the server-authoritative MCM event flow
- packaging now declares `BG3MCM` as a dependency, and startup without it is unsupported

## Combat Extender

- native `Combat Extender` support exists
- the mod can auto-detect `Combat Extender`
- there is also an `MCM_CombatExtenderMode` setting for manual control
- this mode reduces tier/champion scaling pressure to avoid double-stacking difficulty

## XP multiplier mods

- if `Ambush XP` is left at `100%`, normal kill XP behavior is preserved
- if `Ambush XP` is set below `100%`, the mod uses verified zero-XP clone suppression and manual payout distributed to validated party recipients
- built-in sub-100% fallback payout currently resolves `powerClass` first and tier fallback second
- third-party XP multiplier mods may not scale that manual payout path

Recommended player guidance:

- if you rely on XP multiplier mods, leave `Ambush XP` at `100%`

## External provider patches

- compatibility patches should register enemy/champion content through the live `EnemyAmbush` API
- provider entries should include `powerClass` if they want sub-100% manual payout to follow the same fallback-category logic as the built-in roster
- provider entries without `powerClass` currently fall back to tier-based payout categories when `Ambush XP < 100`
- provider templates without XP-zero clone coverage are only fully compatible when `Ambush XP = 100`
- when `Ambush XP < 100`, provider templates that are not present in Hunted's XP-clone map are skipped from the active pool for safety
- provider authors can use `RegisterXPCloneMapping(providerId, mapping)` if their compatibility patch ships its own zero-XP clone templates
- there is no legacy queued registration fallback in `1.0`
- if you disable `Use Vanilla Enemy Pool` without installing an external provider patch, ambushes may have no valid enemy pool

## Faction behavior

- spawned ambushers use the dedicated `EA_AMBUSHERS` faction
- this isolates ambush hostility from broader world faction logic

## Multiplayer

- `1.0` is intended to support multiplayer
- release verification should confirm host/non-host rest flow in different area and camp-state combinations
- expected behavior is one ambush schedule per party rest flow, not one schedule per party member
