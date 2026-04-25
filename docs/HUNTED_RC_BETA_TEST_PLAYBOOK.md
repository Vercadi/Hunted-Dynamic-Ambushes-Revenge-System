# Hunted - RC and Beta Test Playbook

Audience: release candidate prep, beta validation, and final `1.0` ship/no-ship review.

Purpose: validate the real release artifact, not just the source tree.

## Release snapshot

- Mod: `Hunted - Dynamic Ambushes & Revenge System`
- Module UUID: `96f24297-6ed9-455c-aaa1-ac9c358a8d35`
- Script Extender requirement: `30`
- Dedicated ambush faction UUID: `2b1660d2-9742-4217-91cc-24d1421c9772`
- `BG3MCM`: required

Current architecture assumptions:

- the runtime now requires `BG3MCM`; BG3SE-only validation is no longer a supported release path
- settings sync is server-authoritative through the `BG3MCM` event flow plus startup pull
- settings JSON workflows are not part of the supported runtime model
- multiplayer is intended to support one ambush schedule per party rest flow, not one per party member, but co-op still requires release validation before it is documented as verified behavior

## Hard release gate

Do not ship the release candidate until all of the following are true.

Artifact verification:

- `meta.lsx` name, folder, UUID, and `Version64` match the intended release
- `ScriptExtender/Config.json` still requires version `30`
- compiled localization output is present in the built artifact in the form the game consumes
- the shipped file list matches the authoritative docs and changelog
- the packaged zip created from the Multitool workflow matches the final release notes

Install/save matrix:

- new save + `BG3SE + BG3MCM`
- existing save + `BG3SE + BG3MCM`

Behavior verification:

- no startup/load errors in the Script Extender console
- `!ea_test verify`, `!ea_test verifytemplates`, and `!ea_test verifystatuses` produce no blocking failures
- at least one successful short-rest and one successful long-rest ambush occur in allowed regions
- camp and blocked-region safety gates behave as documented
- reputation thresholds and champion retaliation behave consistently
- save/load preserves pending state, reputation, and spawned tracking
- co-op validation passes with host and non-host players in different area or camp-state combinations

No-ship conditions:

- ambushers fail to become hostile reliably
- repeated duplicate schedules or duplicate spawns come from one rest flow
- supported settings behavior contradicts the written troubleshooting docs
- packaged localization is missing or clearly out of sync with the source/docs
- the final packaged artifact does not match the release notes or authoritative docs

## Pre-beta setup

1. Build the `.pak` with BG3 Modder's Multitool.
2. Prepare the final shipped zip you intend to publish.
3. Keep one clean profile and one stress profile.
4. Turn `MCM_DebugMode = ON` for diagnostic runs.
5. Leave the vanilla provider enabled unless you are explicitly testing provider-only behavior.

## Fast smoke pass

Run this after each RC build:

1. `!ea_test verify`
2. `!ea_test verifytemplates`
3. `!ea_test verifystatuses`
4. `!ea_test settings`
5. `!ea_test spawn random`
6. `!ea_test spawnrank Veteran`
7. `!ea_test champion Humanoid force`
8. `!ea_test region`
9. `!ea_test metrics`

Expected result:

- commands execute without fatal errors
- spawned units appear and engage
- champion spawn path works when forced
- settings output matches the install mode being tested

## April 24 early tester focus

Use `HUNTED_EARLY_TESTER_CHECKLIST_2026-04-24.md` as the short handoff checklist for the current pre-Nexus tester build.

These items are intentionally treated as beta/runtime evidence, not locally closed proof:

- cooldown save/load: a real cooldown-gated ambush should block immediate re-ambush after reload
- `CUSTOM` + Advanced MCM settings: custom values should survive save/load and Advanced toggles
- Time-in-Danger pacing: no accumulation during the first `30` minutes after ambush/cooldown start
- level `5-6` scaling: non-CX normal tiers should use level `5` tier packages where applicable, with harder presets able to select stronger packages
- rest ambushes: short-rest and long-rest paths should schedule once and respect cooldown
- save/load: pending delayed/staggered ambushes should resume cleanly without duplicate waves or under-spawn
- API smoke: external server-side patches should be able to call the documented `1.5.0` provider, XP-clone mapping, reputation, state, and `custom_entries` trigger surface

No-ship if any of these corridors produce a Lua error, immediate post-reload cooldown bypass, `CUSTOM` reset, Time-in-Danger accumulation during the post-ambush gate, level `5-6` enemies stuck on level `1` tier packages, or duplicate/aborted rest ambush waves.

## Focused regression matrix

### Rest loop

1. Short rest to ambush flow.
2. Long rest to ambush flow.
3. Cooldown enforcement when enabled.
4. Forced debug spawn path still works.

### Safety gates

1. Camp with `MCM_CampAmbushes = OFF`.
2. Camp with `MCM_CampAmbushes = ON`.
3. Dialogue or cinematic state.
4. Forced turn-based state.
5. Blocked region or blocked sublevel.

### Reputation and champion escalation

1. Repeated kills of one creature type.
2. Threshold transitions for `WARY`, `HOSTILE`, and `VENGEFUL`.
3. Champion retaliation after vengeful escalation.
4. Champion kill reset behavior for that creature type.

### Rewards and economy

1. `MCM_AmbushXPPercent = 100`.
2. `MCM_AmbushXPPercent < 100`.
3. `MCM_DisableAmbushLoot = ON`.
4. `MCM_AllowChampionLoot = ON`.

### Arrival and escape cues

1. Set `Arrival Cue Policy = Always On`.
2. Run `!ea_test arrivalpreview player mistycast stinger`.
3. Run `!ea_test spawn random` and confirm arrival cue debug lines plus `arrivalCueApplied`, `arrivalCueStatusApplied`, and `arrivalFxApplied` in `!ea_test metrics`.
4. Run `!ea_test escapetune quick`.
5. Run `!ea_test escapepreview last dimdoor stinger 600`.
6. In a live combat, verify that escape logs only appear after the configured start-turn and HP gates are met.
7. Restore defaults with `!ea_test escapetune default`.

### Persistence

1. Save with pending timer state.
2. Save with active spawned enemies.
3. Reload and verify no duplicate registry or hostility artifacts.
4. If `time_in_danger` is non-zero before save, reload and confirm it does not reset to `0` unexpectedly.

### Hard-to-force edge paths

These are still useful pre-release checks, but they are expensive to force deterministically and may be best treated as RC/beta evidence collection rather than everyday smoke tests.

1. Deferred support join window / forced catch-up:
   - real `!ea_test spawn random` multi-enemy ambushes already proved this path in maintainer testing
   - useful logs:
     - `Deferred support join until anchor engages`
     - `Deferred support forced catch-up enabled`
     - `Joined deferred supports:`
2. Anchor-never-engages fallback:
   - still **UNVERIFIED**
   - useful log:
     - `Support join fallback fired`
   - if seen, capture the full surrounding ambush log and whether the support eventually entered combat
3. Raw blocked-sublevel fallback:
   - still **UNVERIFIED**
   - best test route:
     - enable `MCM_DebugMode`
     - go to an area that appears to be suppressed by a raw sublevel/setpiece/tutorial denylist rather than by camp or a named blocked region
     - try either a normal rest-triggered ambush flow or `!ea_test spawn random`
   - useful logs:
     - `Skipping ambush - blocked sublevel: <rawRegion>`
     - `Spawn cancelled - player in blocked sublevel: <rawRegion>`
   - distinguish from these non-matching outcomes:
     - `Skipping ambush - blocked safe zone: ...`
     - `Spawn cancelled - player in blocked safe zone: ...`
     - `Spawn cancelled - player moved to blocked region: ...`
   - if seen, capture:
     - the full surrounding log block
     - the exact area/sublevel name
     - whether this came from rest flow, `!ea_test spawn random`, or another trigger

### Co-op

1. Host triggers rest.
2. Non-host triggers rest.
3. Host and non-host in different areas.
4. Host and non-host split between camp and wilderness states.

## Specific release notes to verify in testing

- the runtime requires `BG3MCM`; missing it is now an unsupported startup state
- API-focused testers should use `API.md` as the source of truth; the stable surface is server-side `EnemyAmbush` / `EnemyAmbush.API` version `1.5.0`
- `Combat Extender` compatibility still auto-detects or respects manual override
- turning off `Use Vanilla Enemy Pool` without an external provider patch can leave no valid ambush pool
- lowering ambush XP below `100%` uses manual XP payout and may not follow third-party XP multiplier mods
- uninstalling from an existing save can produce normal missing-mod warnings because persistent mod variables exist

## Field-debug notes

- if a tester reports more visible enemies than the `Spawned ...` lines or ambush metrics show, capture the GUIDs and compare them against the spawned-registry/log output before treating that as a confirmed extra-spawn bug
- if no escape lines appear in a short fight, that is not automatically a bug; default escape tuning is late-combat and often produces no attempts in brief low-level encounters
- if a tester happens to capture `Support join fallback fired`, `DeferredJoinTimeout`, or a blocked-sublevel suppression line, keep the full surrounding log block; those are high-value edge-path evidence, not normal noise

## Final artifact inspection

Inspect the actual zip you intend to ship, not just the repo:

1. confirm the `.pak` is the one built from the current source state
2. confirm the release zip contents match what the docs say you ship
3. if the zip contains only the `.pak`, make sure the release page carries the install and troubleshooting guidance
4. if the zip contains extra docs, make sure they are derived from `Hunted Docs`

## Beta bug report template

- build tag:
- install mode:
- single player or co-op:
- save context:
- settings profile used:
- expected behavior:
- actual behavior:
- reproduction steps:
- relevant command outputs:
- Script Extender errors, if any:

## Cross-reference

- pack handoff: `HUNTED_MODPACK_HANDOFF_GUIDE.md`
- runtime architecture: `HUNTED_AI_AGENT_REFERENCE.md`
- troubleshooting: `TROUBLESHOOTING.md`
