# Hunted Dynamic Ambushes - Changelog

## 2026-04-24 21:35 Add API XP-clone mapping support for external providers
- Added: `EnemyAmbush_API.lua` now reports `API_VERSION = 1.5.0` and exposes `RegisterXPCloneMapping(providerId, mapping)` / `UnregisterXPCloneMappings(providerId)` on both `EnemyAmbush.*` and `EnemyAmbush.API.*`.
- Changed: external provider authors can now ship their own zero-XP clone templates and register explicit original-template -> clone-template mappings so custom templates remain eligible when `Ambush XP < 100%`.
- Safety: API mappings cannot override built-in generated Hunted clone coverage or another provider's existing mapping, and `EnemyAmbush_Systems_CompositionRoot.lua` now routes XP-clone mapping changes through the existing provider-cache rebuild path.
- Docs: `API.md`, the early tester checklist, and the beta playbook now document the `1.5.0` API smoke target and XP-clone mapping path.

## 2026-04-24 21:15 Clarify external provider XP-clone compatibility
- Docs: `API.md`, `COMPATIBILITY.md`, and `HUNTED_MODPACK_HANDOFF_GUIDE.md` now state that external provider templates work normally at `Ambush XP = 100%`, but require generated Hunted XP-zero clone coverage to remain eligible when `Ambush XP < 100%`.
- Clarified: provider templates without clone coverage are skipped from the active pool in sub-100% XP mode to avoid double XP payouts from normal kill XP plus Hunted manual payout.

## 2026-04-24 20:05 Prepare early tester verification checklist
- Docs: `README.md` now reflects the current runtime snapshot for hidden preset tier-status pressure, level `5` tier packages, and the beta-deferred verification items.
- Docs: added `HUNTED_EARLY_TESTER_CHECKLIST_2026-04-24.md` with short tester steps for cooldown save/load, `CUSTOM` + Advanced MCM settings, Time-in-Danger, level `5-6` scaling, rest ambushes, and pending save/load.
- Docs: `HUNTED_RC_BETA_TEST_PLAYBOOK.md` now points testers at the April 24 checklist and names the current no-ship conditions.
- Docs: `API.md` now includes an API-focused smoke target, server-side/version expectations, precise `custom_entries` trigger-field limitations, and minimal registered/one-shot trigger examples for beta integration testers.

## 2026-04-24 19:42 Defer remaining local runtime checks to beta testing
- Docs: `feedback_audit_validated_execution_roadmap_2026-04-13.md` now marks the remaining local checks for `WS-B1`, `WS-D1`, and `WS-D1.5` as skipped locally and deferred to beta/early testers instead of verified.
- Clarified: these corridors remain unverified from local runtime proof; they should be included in the pre-Nexus beta test pass.

## 2026-04-24 19:16 Add WS-D1.5 level-5 tier-package scaling for difficulty feel
- Changed: `Status_EnemyAmbush.txt` now defines non-CX `EA_TIER_COMMON_L5`, `EA_TIER_VETERAN_L5`, `EA_TIER_ELITE_L5`, and `EA_TIER_LEGENDARY_L5` so level `5-6` ambushers no longer fall back to level `1` tier packages.
- Changed: `EnemyAmbush_Systems_TierPackages.lua` now inserts the new level `5` packages, applies a hidden preset status-threat offset only to tier-status selection, and logs `threat`, `statusThreat`, `offset`, `preset`, `tierBias`, `cx`, and selected status in `[TierDurability]`.
- Changed: `EnemyAmbush_Systems_SpawnPipeline.lua` now passes the existing preset-hidden-knob accessor into TierPackages so the offset does not depend on global load order.
- Changed: `EnemyAmbush_MCMContract.lua` / `EnemyAmbush_Utils_Settings.lua` now expose hidden `tierStatusLevelOffset` values of `Wayfarer=0`, `Marked=0`, `Relentless=1`, and `Hunted=2`; CX remains unchanged.
- Maintenance: `EnemyAmbush_DebugCommands.lua` and `EnemyAmbush_Events_TimerMain.lua` now recognize the new level `5` tier statuses for diagnostics and tier cleanup/classification.
- Docs: `feedback_audit_validated_execution_roadmap_2026-04-13.md` marks `WS-D1.5` as landed, `MCM_PRESET_SETTINGS_MATRIX.md` records the new hidden preset knob, and the level `5-6` Marked-vs-Hunted runtime verification steps remain open.

## 2026-04-24 18:38 Tune WS-D1 reputation decay, preset cooldowns, and post-ambush Time-in-Danger pacing
- Changed: `EnemyAmbush_Events_TimerFlow.lua`, `EnemyAmbush_Utils_Settings.lua`, `EnemyAmbush_MCMContract.lua`, and `MCM_blueprint.json` now default reputation decay to `0.5` per `5` minute non-combat tick, targeting roughly `50` minutes for `WARY` reputation to clear back to neutral.
- Changed: preset cooldown baselines now follow the roadmap pacing contract: `Wayfarer=60`, `Marked=45`, `Relentless=35`, and `Hunted=30` minutes; Advanced-mode, debug, and telemetry default/fallback cooldowns now align to the new `Marked` baseline of `45`.
- Changed: `EnemyAmbush_Utils_StateTime.lua` now blocks Time-in-Danger accumulation for the first `30` minutes after an ambush using the persisted `LastAmbushTime` cooldown stamp, and debug logs now include `postAmbushGateMs` / `gateStartMs` to prove the blocked-then-accumulating transition.
- Docs: `MCM_PRESET_SETTINGS_MATRIX.md` and `feedback_audit_validated_execution_roadmap_2026-04-13.md` now reflect the new pacing values and the remaining in-game verification steps.

## 2026-04-24 17:02 Add a Script Extender debug command for WS-B2 custom reputation verification
- Added: `EnemyAmbush_DebugCommands.lua` now supports debug-only `!ea_test reputation setcustom <CreatureType> <value>`, which creates or updates a custom reputation key and persists it through the existing `SaveReputation()` path.
- Docs: `ConsoleCommands_Reference.md` documents the new command, and `feedback_audit_validated_execution_roadmap_2026-04-13.md` now uses it for WS-B2 verification instead of raw Lua console API calls.
- Verified: maintainer save/load test confirmed a custom reputation value persists after reload on the current build.

## 2026-04-17 18:04 Restore custom provider/API creature-type reputation symmetrically on load
- Fixed: `EnemyAmbush_Systems_PersistenceControl.lua` no longer limits `LoadReputation()` to the seeded vanilla reputation keys; it now restores persisted non-empty string `creatureType` keys as live reputation state, which keeps provider/API custom creature types symmetric with the existing snapshot save path.
- Scope kept narrow: the change stays inside reputation hydration, preserves the current whole-table save snapshot pattern, and only filters out invalid persisted keys instead of redesigning provider registration or the wider reputation system.
- Docs: `feedback_audit_validated_execution_roadmap_2026-04-13.md` now records the exact WS-B2 provider-backed save/load verification steps in the maintainer ledger.

## 2026-04-17 17:47 Preserve `CUSTOM` advanced values across `Advanced` mode toggles
- Fixed: `EnemyAmbush_Config.lua` no longer re-syncs preset-owned values from the resolved base preset when `MCM_AdvancedMode` is saved while the visible preset is `CUSTOM`.
- Scope kept narrow: non-`CUSTOM` presets still keep preset-baseline authority on `Advanced` toggles, and no startup bootstrap, preset-resolution, or broader settings-authority logic was rewritten in this pass.
- Docs: `feedback_audit_validated_execution_roadmap_2026-04-13.md` now tracks the exact in-game WS-B1 verification steps in the maintainer ledger so the remaining live check stays in-repo instead of chat.

## 2026-04-17 17:32 Record the delayed-stagger save/load fix as runtime-verified on the current build
- Proof-only: reviewed `Extender Runtime 2026-04-17 15-18-11.log` against the resumed `SPAWN_QUEUE` corridor fixed earlier the same day.
- Verified: the delayed mirror recovery path now reaches full target count after reload instead of dying early at `combat_continue_limit`; the sampled resumed queues both finished at `spawned=5/5`, `reason=target_met`, and `Delayed ambush spawned 5 entities`.
- Clarified: if the encounter still visually reads as "only 2 spawned" during the first moments after reload, that is now a visibility/deferred-support-join read rather than a reproduced under-spawn/save-load failure.

## 2026-04-17 17:05 Fix resumed delayed-stagger save/load under-spawn and close the remaining Phase A proof items that were actually verified
- Fixed: `EnemyAmbush_Events_TimerMain.lua` now freezes a spawn queue's combat-continuation limit the first time that queue enters the engaged-combat continuation corridor, instead of recalculating the limit against a shrinking remaining gap on every timer tick.
- Fixed: `EnemyAmbush_Events_TimerMain.lua` now only spends `combatContinueCount` when a resumed `SPAWN_QUEUE` step actually adds a new spawned enemy, which closes the reproduced `2/5 -> 2/5 -> 2/5 -> 3/5 -> combat_continue_limit` early-finalize path from `Extender Runtime 2026-04-17 14-24-06.log`.
- Hardened: the same `SPAWN_QUEUE` pending-state mutations in `EnemyAmbush_Events_TimerMain.lua` now flush with `EA_Dirty(true)` instead of the debounced dirty path, keeping this mid-ambush save/load corridor aligned with the state-time contract comment that pending ambush records are critical gameplay-state mutations.
- Removed: the temporary Phase A `WS-A5` `[SpawnedTrace] transient fallback used:` instrumentation from `EnemyAmbush_Events.lua` and `EnemyAmbush_Systems_SpawnPipeline.lua` after the current runtime log showed no fallback hits during supported runtime.
- Docs: `feedback_audit_validated_execution_roadmap_2026-04-13.md` now records `WS-A3` as verified by maintainer observation, records `WS-A5` as verified/skipped-by-gate from the `2026-04-17` runtime log, keeps `WS-A2` open/inconclusive because the latest session ran with quick test enabled, and adds a concrete post-fix delayed-stagger save/load validation note so the remaining live test is tracked in-repo instead of chat.

## 2026-04-13 14:21 Add temporary Phase A `WS-A5` spawned-registry fallback trace to close the residual proof gap
- Proof instrumentation only: added a debug-gated `[SpawnedTrace] transient fallback used:` line to the file-local `EA_Spawned` wrappers in `EnemyAmbush_Events.lua` and `EnemyAmbush_Systems_SpawnPipeline.lua`.
- Scope kept narrow: no wrapper contract was rewritten, no startup behavior was intentionally changed, and the canonical persistent owner still remains `EA["EA_Spawned"]` from `EnemyAmbush_Utils_Core.lua` / `EnemyAmbush_Utils_Exports.lua`.
- Why: existing logs were sufficient to validate load order and export publication, but not to prove whether the wrapper ever falls back to transient `EA._Spawned` because strict ModVariables were not ready during supported runtime.
- Current status: `WS-A5` remains `INCONCLUSIVE` until the maintainer runs the recorded boot/session-load/save-load smoke and checks whether the new trace appears only in inert pre-runtime defense or during real supported runtime.

## 2026-04-13 13:35 Record Phase A `WS-A4` faction-hostility fallback proof as cleared without faction-data edits
- Proof-only: inspected `EnemyAmbush_Systems_HostilityService.lua` and confirmed the current owner chain is already intentionally hardened away from broad faction writes. It enforces the isolated ambush faction, applies per-target `SetIndividualRelation`, applies `SetRelationTemporaryHostile`, then escalates through `SetHostileAndEnterCombat`, `EnterCombat`, and finally the local approach/strike fallback when needed.
- Proof-only: cross-checked the current roadmap guardrails and prior hardening notes in `Hunted Docs/post_remediation_followup_plan.md` / `Hunted Docs/Changelog.md`, including the earlier isolated-faction and deferred-support join validations, before treating `Public/Hunted_DynamicAmbushes_Revenge_System/Factions/Factions.lsx` as a suspect target.
- Proof-only: reviewed the latest live hostility trace from `Extender Runtime 2026-04-12 16-42-32.log` and `Osiris Runtime 2026-04-12 16-42-50.log`; the sampled ambush showed `Precombat faction set`, repeated `Hostility settled`, `Deferred support forced catch-up enabled`, `Joined deferred supports: 4`, and later `EnteredCombat` for the delayed supports after transient `EnterCombatFailed` events.
- Decision: `WS-A4` does not reproduce a faction-hostility insufficiency on the current build. No `Factions.lsx` edit is justified from this pass, and `WS-C2` stays gated off by this corridor.

## 2026-04-13 13:10 Record Phase A `WS-A3` champion-telegraph proof as inconclusive with no patch authorized
- Proof-only: inspected `EnemyAmbush_Systems_TierPackages.lua` and the live call site in `EnemyAmbush_Systems_ChampionSpawn.lua`. `EA_ApplyChampionTelegraph()` still only targets `Humanoid` and `Giant`, applies a force-refresh enlarge immediately, then repeats the same force-refresh enlarge after `250ms`.
- Proof-only: repo history shows this double-apply path has existed since the initial tracked snapshot rather than appearing as a recent regression, and the call site still runs it immediately after `SetLevel()` / champion package application but before the later hostility retry window and HP-normalization settle callbacks.
- Proof-only: no visual runtime artifact in the repo currently proves either a stable read or a grow-reset-grow flicker. Because this corridor is presentation-only and requires human-eye confirmation at normal framerate, `WS-A3` remains inconclusive and no champion-telegraph patch is authorized from this pass.

## 2026-04-13 12:55 Record Phase A `WS-A2` cooldown-stamp save/load proof as inconclusive with no patch authorized
- Proof-only: inspected `EnemyAmbush_Systems_SpawnPipeline.lua` and `EnemyAmbush_API.lua` for the current cooldown contract. Normal successful stamps write directly into persisted `EA_LastAmbushTime`; the retry corridor is the transient in-memory table `EnemyAmbush._eaAmbushCooldownStampRetry`, used only when `EA_ModVarsReady()` or `EA_PersistedNowMs()` is temporarily unavailable.
- Proof-only: confirmed the live cooldown gate and API both read the persisted `EA_LastAmbushTime` map rather than any retry-only state, and cross-checked prior hardening already recorded in the repo (`2026-02-28` retry landing and `2026-03-22` strict persistent-state closeout).
- Proof-only: reviewed recent runtime artifacts and found readiness healthy (`EA_ModVarsReady=true`, persisted-time policy active) with no observed `Ambush cooldown stamp skipped`, retry-exhaustion, or `cooldown_active` logs in the sampled sessions. The exact save-during-retry corridor was not captured, so `WS-C1` remains gated off by `WS-A2`.

## 2026-04-13 12:35 Record Phase A `WS-A1` hostility-settlement proof as cleared without a runtime patch
- Proof-only: inspected `EnemyAmbush_Systems_SpawnPlacement.lua` and `EnemyAmbush_Systems_HostilityService.lua` against the current roadmap entry points (`EA_KickCombat`, `EA_MakeAmbushHostile`, `EA_SchedulePersistentHostileRetry`, `EA_HandlePersistentHostileRetryTimer`) before touching runtime behavior.
- Proof-only: reviewed the latest live debug artifacts from `Extender Runtime 2026-04-12 16-42-32.log` and `Osiris Runtime 2026-04-12 16-42-50.log`; the sampled ambush showed transient `EnterCombatFailed` events, but still reached `Hostility settled`, `Deferred support forced catch-up enabled`, `Joined deferred supports: 4`, and later `EnteredCombat` for the sampled ambushers instead of leaving a visible idle enemy behind.
- Decision: `WS-C2` remains gated off by `WS-A1`; current evidence does not justify a hostility-settlement patch in this corridor.

## 2026-04-12 17:18 Complete staged escapes on LeftCombat instead of canceling them
- Changed: `EnemyAmbush_Events_CombatTurnFlow.lua` now treats `LeftCombat` as a staged-escape completion path when `escapePending` is already armed, instead of blindly canceling the pending escape and letting the same enemy roll a fresh escape again later.
- Changed: `EnemyAmbush_Events_CombatFlow.lua` now exposes a targeted runtime helper that resolves a staged pending escape from the `LeftCombat` listener using the stored escape metadata/profile, which should stop the observed loop of `staged -> flee -> staged again -> skip turn`.

## 2026-04-12 14:22 Relax the fixed fodder taper so late-game fodder can still appear at low density
- Changed: `EnemyAmbush_Systems_PoolSelection.lua` now uses a softer built-in `FODDER` phase-4 curve: full weight through level `6`, `50%` from `7+`, `30%` from `10+`, and `10%` from `12+` instead of the previous near-removal/hard-cutoff path.
- Changed: `EnemyAmbush_DebugCommands.lua` and `EnemyAmbush_Utils_Telemetry.lua` now report the live fodder curve honestly as `7+:50%, 10+:30%, 12+:10%` instead of the old fixed `12+` cutoff wording.

## 2026-04-12 14:07 Tighten staged escape flow so successful attempts end the turn cleanly and failed attempts leave a readable penalty
- Changed: `EnemyAmbush_Events_CombatFlow.lua` now ends the ambusher's turn shortly after a staged successful escape begins, so enemies stop running a few meters and then re-engaging on the same turn before next-turn resolution.
- Changed: staged escape now uses a longer default flee range (`16m` instead of `10m`) so the imminent-escape movement read is clearer before the next-turn departure resolves.
- Changed: failed escape rolls now apply the new Hunted-owned `EA_ESCAPE_STAGGERED` status, implemented in `Status_EnemyAmbush.txt` as an `OFF_BALANCED`-based short debuff so failed escape attempts have visible combat fallout without introducing a harsher hard-disable.
- Changed: `EA_ESCAPE_IMMINENT` now uses the requested `statIcons_Fugitive` icon instead of `Action_Hide`; icon resolution should be checked in-game because this specific icon id is not currently verified from the local extracted data on disk.

## 2026-04-12 13:08 Apply the first full fodder-table audit pass and tighten fodder windows/classification without cutting special rows
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` now tightens the real early-fodder windows for critters and weak beasts (`Rat`, `Raven`, `Bat`, `Spider Tiny`, `Weak Imp`, `Wolf`, `Boar`, `Giant Rat`, `Feral Dog`, `Goblin Civilian`, `Necrotic Rat`, `Soporific Rat`, `Badger`) so disposable wildlife no longer lingers too far into midgame.
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` now retunes midgame fodder semantics by moving `Needle Blight`, `Shadow Creeper`, `Necromite`, `Crawling Claw`, and `Cranium Rat` into narrower party windows that match their intended encounter era under the fixed `12+` fodder cutoff.
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` now reclassifies stronger combatants out of `FODDER`, including `Dire Raven`, mephits, `Quasit`, `Worg`, `Skeleton (Caster)`, `Goblin Ranger (Male)`, the low-beast `Giant Spider` row, and `Shadow-Cursed Kuo-Toa`.
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` keeps the special/named/summon-form rows in the pool per current design direction; this pass only changes fodder windows and combat classification instead of pruning those entries out of the table.
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` now treats `Cranium Rat` as actual low-level rat-class fodder again by dropping its row level/resolved-template level to `1` and returning it to an early-game party window (`2-5`), so its budget spend matches its intended nuisance role.

## 2026-04-12 12:29 Retire the user-facing fodder-policy setting and fix Necromite back to common-tier fodder semantics
- Changed: `MCM_blueprint.json`, `EnemyAmbush_MCMContract.lua`, `EnemyAmbush_Config.lua`, `EnemyAmbush_Utils_Settings.lua`, `EnemyAmbush_Utils_Exports.lua`, `EnemyAmbush_Systems_CompositionRoot.lua`, `EnemyAmbush_DebugCommands.lua`, and `EnemyAmbush_Utils_Telemetry.lua` no longer expose `MCM_FodderPolicy` as an advanced/runtime surface; debug and telemetry now report the fixed rule as a built-in `12+` cutoff instead of a user-configurable toggle.
- Changed: `EnemyAmbush_Systems_PoolSelection.lua` now hardcodes `FODDER` to the existing shared taper curve through levels `6/8/10` and always cuts it off at `12+`, removing the old tiny residual `TAPERED` path.
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` now drops `Necromite`'s explicit `VETERAN` override so its level-3 `FODDER` row resolves back to the default `COMMON` band.
- Changed: `MCM_PRESET_SETTINGS_MATRIX.md` no longer documents `MCM_FodderPolicy` as an active advanced/global setting.

## 2026-04-12 11:57 Raise non-CX tier durability for commons and add broader offensive scaling across active tier packages
- Changed: `Status_EnemyAmbush.txt` now gives `EA_TIER_COMMON_L7/L11/L15` the earlier-discussed non-CX HP/THP bump so late-common ambushers stop collapsing too fast at mid/high levels.
- Changed: `Status_EnemyAmbush.txt` now raises non-CX damage pressure by bringing `WeaponDamage(1)` online earlier for commons, lifting `COMMON_L11/L15` to `WeaponDamage(2)`, raising `VETERAN_L7` to `WeaponDamage(2)`, and adding spell-attack bonuses (`RollBonus(MeleeSpellAttack, N)` / `RollBonus(RangedSpellAttack, N)`) across non-CX `COMMON` high brackets plus `VETERAN` / `ELITE` / `LEGENDARY` tiers to match their existing caster pressure.
- Decision: `CX` variants, champion bases, and offensive traits remain unchanged in this pass to keep the durability/damage correction narrow and easier to validate.

## 2026-04-12 11:18 Record the status-cleanup review outcome as deferred with the current visible identity model kept intact
- Changed: `post_remediation_followup_plan.md` now records that the presentation/status slice was re-reviewed and no further cleanup was accepted in the current pass.
- Decision: `EA_AMBUSHER` remains intentionally visible on ordinary ambushers, visible `VETERAN` / `ELITE` / `LEGENDARY` non-champion tier identities are kept, and the already-hidden arrival/escape cue plus champion base/trait package split stays unchanged.

## 2026-04-12 10:56 Apply a conservative common-pool goblin weight trim without flattening goblin class mix
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` now trims the heaviest `COMMON` goblin rows (`Brawler`, `Tracker`, melee guards, caster guards, warlocks, booyahgs, warriors, and sharp-eyes) while leaving civilians, devouts, basic guards, and the goblin ranger untouched.
- Rationale: low-level `Humanoid` ambush themes were still over-concentrating on goblins even after the veteran goblin cleanup, but the intended in-world result still allows all-goblin ambushes to happen sometimes instead of forcing a mixed humanoid pack every time.

## 2026-04-12 10:34 Finish the goblin common-only cleanup by removing the remaining veteran goblin rows
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` no longer keeps a separate veteran goblin block for `Goblin Warrior (Female)`, `Goblin Warrior Tier 2 (Male)`, `Goblin Sharp-Eye Tier 2 (Male)`, `Goblin Sharp-Eye Tier 2 (Female)`, or `Goblin Boss`.
- Rationale: current selector rules already allow `COMMON` rows to satisfy `VETERAN` / `ELITE` requests after hard gates pass, so the extra veteran goblin slice was unnecessary drift on top of the earlier low-level goblin-village/common cleanup.

## 2026-04-12 10:12 Extend summon data audit with weight concentration and family/power-class rollups
- Changed: `EnemyAmbush_Data.lua` now extends `EA_RunDataAudit()` with per-band weight-audit output covering top derived family clusters, dominant creature types, and `FODDER` / `STANDARD` / `BRUISER` / `DREAD` / `APEX` share, so Workstream F1 can inspect concentration before changing summon data.
- Changed: `EnemyAmbush_DebugCommands.lua` now describes `!ea_test dataaudit [verbose]` as an integrity plus weight-concentration audit instead of only a data-integrity pass.

## 2026-04-12 09:45 Record the bounded staged-escape readability slice as landed in the follow-up roadmap
- Changed: `post_remediation_followup_plan.md` now records the current escape work as a completed bounded readability/presentation slice (`EA_ESCAPE_IMMINENT`, staged flee-before-departure, cancel-on-damage/leave-combat, repaired staged-escape seams) while keeping the larger contested-roll redesign explicitly deferred.

## 2026-04-12 09:31 Repair staged escape function shape and late helper lookup in combat flow
- Fixed: `EnemyAmbush_Events_CombatFlow.lua` now forward-declares `EA_FindCombatKeyForCharacter` and resolves it directly inside `EA_CancelPendingEscape()`, so damage-triggered pending-escape cancel no longer depends on an unstable late-bound ref/upvalue.
- Fixed: `EA_TryAmbusherEscape()` now has its success-path staging block back inside the function body instead of leaking out past the failed-roll branch, which keeps staged escape arming, flee setup, and fallback resolution on the intended runtime path.

## 2026-04-12 09:18 Tone down eager bootstrap startup fallback now that first-load recovery is stable
- Changed: `EnemyAmbush_Events.lua` now treats `bootstrap_watchdog` as a later last-resort fallback instead of a 5-second eager queue, so routine loads stop racing the normal `SessionLoaded` / `SavegameLoaded` / `LevelGameplayStarted` startup path while stale-startup recovery still stays covered by the existing `startup_watchdog`.

## 2026-04-12 09:05 Fix staged-escape cancel lookup wiring for damage-triggered cancel paths
- Fixed: `EnemyAmbush_Events_CombatFlow.lua` now resolves `EA_FindCombatKeyForCharacter` through a stable local ref inside `EA_CancelPendingEscape()`, so damage-triggered staged-escape cancel paths no longer hit `attempt to call a nil value (global 'EA_FindCombatKeyForCharacter')` on enemy turns.
- Fixed: `EnemyAmbush_Events.lua` now also queues session startup from a guarded `LevelGameplayStarted` fallback, because some first main-menu-to-save loads were still reaching BG3MCM/UTAC gameplay start without Hunted’s own `SessionLoaded` / `SavegameLoaded` startup completing.
- Fixed: Hunted session startup now tracks queued vs completed state and uses a watchdog requeue path, so an early first-load startup attempt can recover instead of blocking all later fallbacks behind a stale one-shot queue flag.

## 2026-04-11 12:12 Fix staged-escape cancel export and stop incomplete BG3MCM startup pulls from writing preset defaults back into MCM
- Fixed: `EnemyAmbush_Events_CombatFlow.lua` now exports pending-escape cancel through a stable runtime ref, so staged escape cancel paths triggered by damage / leaving combat no longer hit `attempt to call a nil value (global 'EA_CancelPendingEscape')`.
- Fixed: `EnemyAmbush_Config.lua` now treats startup MCM pulls that are missing control settings (`MCM_DifficultyPreset`, `MCM_AdvancedMode`) as incomplete and defers preset sync instead of immediately writing runtime default preset values back into BG3MCM during bootstrap.
- Fixed: `EnemyAmbush_Events.lua` now backs the `SessionLoaded` startup with a guarded `SavegameLoaded` fallback, so first main-menu-to-save loads still queue Hunted startup and timer initialization even when `Ext.Events.SessionLoaded` does not reliably reach the mod.

## 2026-04-11 11:39 Add a dedicated overhead-only escape status test path
- Changed: `Status_EnemyAmbush.txt` now defines a temporary `EA_ESCAPE_IMMINENT` status using `ForceOverhead;DisableCombatlog;DisablePortraitIndicator`, so escape overhead presentation can be tested through the status system instead of `DebugText`.
- Changed: `EnemyAmbush_DebugCommands.lua` now adds `!ea_test escapestatus [target] [seconds]` to apply that status directly for in-game overhead verification without touching the live escape mechanic.
- Changed: `EA_ESCAPE_IMMINENT` now uses the same localized display-name/description pattern as the mod’s other visible statuses, plus a real icon/color and a simpler `ForceOverhead;DisableCombatlog` flag set for a closer match to shipped BG3 overhead conditions.
- Changed: `EnemyAmbush_DebugCommands.lua` now adds `!ea_test fleefrom [target] [from] [range]`, a direct `FleeFromObject(...)` harness with a matching `StartedFleeing` debug listener so staged-escape movement can be tested before wiring it into live combat flow.
- Changed: live ambusher escape is now staged. A passed escape roll applies `EA_ESCAPE_IMMINENT`, issues `FleeFromObject(...)`, and delays the real disappearance/deletion until that ambusher’s next turn. Taking damage or leaving combat cancels the pending escape and applies the normal retry cooldown.

## 2026-04-11 11:14 Record future swarm-AI / compressed first-turn research slice in the follow-up roadmap
- Changed: `Hunted Docs/post_remediation_followup_plan.md` now tracks a separate future research slice for swarm AI / compressed enemy first-turn behavior, with explicit guardrails around BG3 turn sequencing limits, shared-initiative fakery, surprise/support-join/escape interaction, and combat softlock/readability risk.

## 2026-04-10 12:20 Add hidden arrival/escape invisibility handling for ambusher presentation
- Changed: `Status_EnemyAmbush.txt` now defines hidden `EA_ARRIVAL_INVISIBLE` and `EA_ESCAPE_INVISIBLE` statuses by wrapping BG3 base `INVISIBILITY`, so ambusher presentation can reuse the engine invisibility overlay without reusing gameplay-heavy statuses like `MISTY_ESCAPE_INVISIBLE`.
- Changed: `EnemyAmbush_Systems_SpawnPlacement.lua` now applies hidden arrival invisibility after the existing arrival cue pass and strips it immediately before any direct hostility/combat-kick path, with a failsafe timeout as backup.
- Changed: `EnemyAmbush_Events_CombatFlow.lua` and `EnemyAmbush_Events_CombatTurnFlow.lua` now remove lingering arrival invisibility before deferred joins / combat retries and on actual combat entry, then apply hidden escape invisibility only on real escape success before the departure cleanup path runs.

## 2026-04-08 18:40 Repair ambusher escape wiring and switch character cleanup to documented temporary-character calls
- Fixed: `EnemyAmbush_Events.lua` now wires the combat-turn runtime to the real combat-flow helpers instead of passing unresolved nil globals for escape/softlock helpers like `EA_EnsureCombatEscapeState`, `EA_FindCombatEscapeState`, `EA_TryAmbusherEscape`, and `EA_TrySoftlockDeleteOnTurn`.
- Changed: `EnemyAmbush_Events_CombatFlow.lua` now exports the combat escape/softlock helper functions that `EnemyAmbush_Events_CombatTurnFlow.lua` depends on, so escape attempts can actually be armed and evaluated on enemy turns.
- Changed: ambusher escape and softlock cleanup in `EnemyAmbush_Events_CombatFlow.lua` now use the documented BG3 character-exit pattern (`SetCanJoinCombat(0)`, `SetCanFight(0)`, `DisappearOutOfSightTo(...)`, `RequestDeleteTemporary(...)`) instead of relying on `RequestDelete` for characters.
- Changed: `EnemyAmbush_Systems_SpawnPlacement.lua` now passes the documented `_Temporary = 1` flag to `CreateOutOfSightAtDirection` and uses temporary-character cleanup for rejected spawn probes/invalid ambushers.

## 2026-04-08 11:48 Fix MCM save-path nil call in `EnemyAmbush_Config.lua`
- Fixed: `EnemyAmbush_Config.lua` now forward-declares `EA_ConfigDebugEnabled`, so early MCM save-path calls no longer hit `attempt to call a nil value (global 'EA_ConfigDebugEnabled')` when changing settings like the escape sliders.

## 2026-04-08 11:33 Add explicit escape gate debug reasons
- Changed: `EnemyAmbush_Events_CombatFlow.lua` now logs `[Escape] blocked:` lines for the silent early-return gates in `EA_TryAmbusherEscape()`, including `champion`, `no_escape`, `turn`, `max_escapes`, `retry_cooldown`, `hp`, and `last_tracked`.

## 2026-04-08 11:12 Move `Mummy (Create Undead)` out of the legendary undead pool
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` now tags `f424693b-13f4-4cce-987b-7d75748c87e0` (`Mummy (Create Undead)`) as `ELITE` instead of `LEGENDARY`, so it no longer anchors legendary undead ambushes.

## 2026-04-08 09:04 Make tier statuses the sole normal durability owner and move HP logging to the true settled state
- Changed: `Status_EnemyAmbush.txt` no longer gives `IncreaseMaxHP` or `TemporaryHP` through `EA_AMBUSHER`; normal ambusher durability now comes only from the chosen `EA_TIER_*` status.
- Changed: the retired hidden status `EA_COMMON_SURVIVABILITY` has been removed from `Status_EnemyAmbush.txt`, and stale debug/status-audit references were removed from `EnemyAmbush_DebugCommands.lua`.
- Changed: `EnemyAmbush_Systems_TierPackages.lua` now returns the chosen durability status to the spawn layer and no longer carries dead `EA_COMMON_SURVIVABILITY` cleanup.
- Changed: `EnemyAmbush_Systems_SpawnPlacement.lua` no longer logs misleading early HP snapshots as if they were final. Spawn-settle logging now runs after the level-retry chain settles and prints the final normalized HP with the applied durability status.

## 2026-04-08 07:58 Add the `EA_AMBUSHED` failed-surprise payoff and make `time_in_danger` preset-owned/toggleable
- Changed: `EnemyAmbush_Systems_Surprise.lua`, `Status_EnemyAmbush.txt`, and both English localization files now add a Hunted-owned `EA_AMBUSHED` status on failed surprise rolls after `SURPRISED` is successfully applied. The status is based on `OFF_BALANCED` behavior, but uses mod-owned name/description handles and runtime application.
- Changed: `MCM_blueprint.json`, `EnemyAmbush_MCMContract.lua`, `EnemyAmbush_Utils_Settings.lua`, `EnemyAmbush_Utils_Exports.lua`, `EnemyAmbush_Utils_StateTime.lua`, `EnemyAmbush_Systems_TriggerRestFlow.lua`, and `EnemyAmbush_Systems_SpawnPipeline.lua` now expose `MCM_EnableTimeInDangerPressure` as a preset-owned toggle.
- Changed: preset defaults for `MCM_EnableTimeInDangerPressure` are now `Wayfarer=OFF`, `Marked=ON`, `Relentless=ON`, `Hunted=ON`.
- Changed: the live `time_in_danger` curve is now slightly softer:
  - shared full-risk horizon increased from `20` to `25` minutes
  - travel-danger threshold increased from `6` to `8` minutes
- Changed: disabling `time_in_danger` pressure now clears stored accumulation/travel-check state instead of leaving latent buildup behind.
- Docs: updated `Hunted Docs/MCM_PRESET_SETTINGS_MATRIX.md` with the new preset-owned toggle and preset baselines.

## 2026-04-08 06:44 Remove the naked common Flaming Fist template from the humanoid summon pool
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` no longer includes the common summon row `f37e77ff-18f9-466f-a860-53d3edbadcd8` (`Flaming Fist (Male)`), because runtime testing showed it can spawn as an undesirable naked template in ordinary humanoid ambushes.
- Preserved: no other humanoid rows, weights, spawn bands, or selector logic changed in this cleanup.

## 2026-04-07 19:31 Keep engaged stagger queues alive long enough to reach their stored target
- Changed: `EnemyAmbush_Events_TimerMain.lua` no longer finalizes an `EA_SPAWNQ_*` queue immediately on the first engaged ambusher when the queue is still below its stored `minEnemiesTarget`.
- Changed: the spawn-queue timer now allows a bounded combat-continuation window for the same queued ambush and logs the outcome explicitly with:
  - `Spawn queue continuing during combat ...`
  - `Spawn queue finalized by combat engagement ... reason=...`
- Changed: `EnemyAmbush_Systems_SpawnExecution.lua` now persists `minEnemiesTarget`, `entityCap`, and `adjustedBudget` into `queueState` so the timer layer can make an evidence-based finalize-versus-continue decision instead of blindly stopping on first engagement.
- Preserved: this does not reopen the general `IsSafeToSpawnAmbush(character)` combat gate for unrelated spawns; it only applies to an already active `EA_SPAWNQ_*` chain that is still trying to finish the same ambush.

## 2026-04-07 18:52 Consolidate party-size pressure so large parties drive more budget, count, and cap together
- Added: `EnemyAmbush_Systems_PartyPressure.lua` now owns the shared party-size pressure helpers for budget scaling, target-count bonuses, and live entity-cap growth.
- Changed: `EnemyAmbush_Systems_Budget.lua` now replaces the older mild multiplier plus scattered `size >= 6` / `size >= 8` threshold bonuses with the shared party-pressure owner, while preserving the existing level curve and the stronger-preset overlay path.
- Changed: `EnemyAmbush_Systems_SpawnExecution.lua` now adds a shared party-size target-count bonus on top of the existing tier adjustment and derives the live normal spawn cap from party size instead of flattening large parties against the old static `6`-entity ceiling.
- Changed: `EnemyAmbush_Systems_SpawnPipeline.lua` now aligns the older fallback budget/runtime path to the same party-pressure owner so party-size scaling does not silently drift when the composition-root budget runtime is unavailable.
- Preserved: no MCM contract changed, no selector/pool logic changed, no champion rules changed, no persistence/save-load behavior changed, and the early small-party safety clamps remain in place.

## 2026-04-07 17:38 Retune aberration summon bands so Spectator carries the legendary slot instead of Mind Flayer
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` now promotes the summon-pool `Spectator` row (`319efbbe-f9f3-4584-804e-3e17d47d1136`) from `spawnBand = "VETERAN"` to `spawnBand = "LEGENDARY"`.
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` now moves the summon-pool `Mind Flayer` row (`e4da9179-d4e9-4e3d-af1b-b2c287732e18`) out of the legendary band and into `spawnBand = "ELITE"`.
- Preserved: no champion rows changed, no weights changed, no selector/runtime logic changed, and no XP-clone coverage changes were needed because both templates were already covered.

## 2026-04-06 22:27 Start Workstream F sparse-pool support spillover as a staged selector framework slice
- Changed: `EnemyAmbush_Systems_PoolSelection.lua` now owns a small staged spillover framework for narrow creature themes instead of a one-off `Fey` / `Plant` special case.
- Changed: the first shipped spillover allowlist is intentionally narrow:
  - `Fey -> Beast`
  - `Plant -> Beast`
- Changed: the first pass is support-role only and only activates when the native themed candidate pool is below the configured threshold, so it supplements thin support packs without replacing ordinary native-theme leaders.
- Changed: `EnemyAmbush_Systems_SpawnExecution.lua` now passes role context into the selector so the new spillover path can stay role-aware without reopening the wider encounter model.
- Preserved: champion separation, requested-tier gates, progression gates, current high-tier caps/mix logic, and the broader encounter-density model are unchanged; no runtime verification is implied by this code slice alone.

## 2026-04-06 22:02 Finish D2 example/interop hardening for the authored/custom API contract docs
- Changed: `Hunted Docs/AMBUSH_FRAMEWORK_V1_API_CONTRACT.md` now uses a registered-definition example that stays on the currently supported trigger-time runtime bridge:
  - `triggerKinds = { "external" }`
  - `spawn.mode = "custom_entries"`
  - default/default/default policy subset
- Changed: the registered-definition example now demonstrates both registration and `TriggerAmbushDefinition(...)` for the same narrow supported shape instead of using a broader `pool_roll` / `region_entry` registry-only example as the copy-paste interop path.
- Changed: `tools/Run-HuntedStaticChecks.ps1` now guards that contract example so the D2 docs do not silently drift back to the older broad example.
- Changed: `Hunted Docs/post_remediation_followup_plan.md` now records this repo-side D2 example/interop hardening slice as implemented.
- Preserved: no D2 API names changed, no runtime behavior changed, `API.md` already matched the live D2 surface and therefore did not need a wording change for this slice, and no new runtime verification is implied by this docs/static-check pass.

## 2026-04-06 22:02 Finish D2 contract-drift hardening for the authored/custom API surface
- Changed: `tools/Run-HuntedStaticChecks.ps1` now locks the six currently supported D2 authored/custom API functions in `EnemyAmbush_API.lua`:
  - `RegisterAmbushDefinition`
  - `UnregisterAmbushDefinition`
  - `GetAmbushDefinition`
  - `GetAmbushState`
  - `TriggerAmbushDefinition`
  - `TriggerCustomAmbush`
- Changed: the same static check now requires the matching `EnemyAmbush.API.*` mirrors and requires both `API.md` and `AMBUSH_FRAMEWORK_V1_API_CONTRACT.md` to name the same currently supported D2 public surface.
- Changed: `Hunted Docs/post_remediation_followup_plan.md` now records that this repo-side D2 contract-hardening slice is implemented.
- Preserved: no D2 API names changed, no payload/result contract was widened, no runtime behavior changed, and no new runtime verification is implied by this hardening slice.

## 2026-04-06 21:48 Finish D1 compat-labeling and residual runtime-owner cleanup slice
- Changed: `EnemyAmbush_Systems_TriggerRestFlow.lua` now prefers `EA.SystemsModules.AuthoredAmbushRuntime.TryRunScriptedScenario` before falling back to the retained legacy `EA["EA_TryRunScriptedScenario"]` compat export for the authored rest-flow scenario hook.
- Changed: `EnemyAmbush_Scenarios.lua`, `ARCHITECTURE.md`, `HUNTED_AI_AGENT_REFERENCE.md`, and `post_remediation_followup_plan.md` now explicitly label the retained scripted-scenario `EA["EA_*"]` globals as compat re-exports rather than primary internal owner surfaces.
- Changed: `tools/Run-HuntedStaticChecks.ps1` now rejects new direct scripted-scenario compat-global references outside the narrow allowlist used by the composition wrapper and the small retained fallback consumers.
- Preserved: no D2 API names changed, no persistence schema changed, no authored/custom behavior was broadened, and no new runtime verification is implied by this cleanup slice.

## 2026-04-06 21:32 Finish D1 authored-runtime consumer cleanup and seam-lock follow-up slice
- Changed: `EnemyAmbush_Events.lua`, `EnemyAmbush_Events_ScenarioBootstrap.lua`, and `EnemyAmbush_DebugCommands.lua` now prefer `EA.SystemsModules.AuthoredAmbushRuntime` for scripted-scenario state/list/run calls before falling back to the retained legacy `EA["EA_*"]` exports.
- Changed: the retained legacy scripted-scenario globals are now clearly compat/fallback surfaces, while the dedicated authored runtime module is the primary internal owner path after the D1 extraction.
- Changed: `tools/Run-HuntedStaticChecks.ps1` now hard-checks that `EnemyAmbush_Scenarios.lua` requires and builds `EnemyAmbush_Systems_AuthoredAmbushRuntime.lua`, and that the authored runtime still exposes the expected internal/public bridge seams.
- Preserved: no D2 API names changed, no persistence schema changed, no beach/bootstrap redesign happened, and no new runtime verification is implied by this internal consumer/seam-lock slice.

## 2026-04-06 21:05 Land D1 authored-runtime owner extraction slice
- Changed: `EnemyAmbush_Scenarios.lua` is now a thin composition file that builds `AuthoredAmbushService`, registers shipped authored definitions, builds `AuthoredAmbushRuntime`, and re-exports the legacy/global scripted-scenario entry points instead of remaining the mixed runtime owner.
- Changed: the old mixed scenario/runtime implementation now lives in `EnemyAmbush_Systems_AuthoredAmbushRuntime.lua`, which becomes the explicit internal owner for authored scenario state, matching, execution, and the internal/public trigger bridge used by beach/bootstrap and the live `D2` API surface.
- Changed: `Hunted Docs/ARCHITECTURE.md`, `Hunted Docs/HUNTED_AI_AGENT_REFERENCE.md`, and `Hunted Docs/post_remediation_followup_plan.md` now describe that owner split directly instead of treating `EnemyAmbush_Scenarios.lua` as the runtime owner.
- Preserved: `EnemyAmbush_API.lua` public authored/custom ambush v1 names were not changed, `EnemyAmbush_AuthoredDefinitions.lua` remains the shipped data file, no persistence schema changed, and no new runtime verification is implied by this internal extraction slice.

## 2026-04-06 20:25 Finish Workstream B repo-side low-value normal-runtime fallback cleanup
- Changed: `EnemyAmbush_Utils_StateTime.lua` now resolves its remaining low-value settings/modvars/helper lookups through stable `EnemyAmbush["..."]` owner surfaces instead of preferring bare globals in the normal runtime path, and `EA_DirtyImmediate()` now reuses the file's existing readiness helper instead of directly consulting the old global name.
- Changed: `EnemyAmbush_Utils_Exports.lua` no longer keeps the extra bare-global fallback path inside `EA_GetCompatSettingFromSnapshot()` once the stable `EnemyAmbush["EA_GetSettingFromSnapshot"]` owner surface exists.
- Changed: `Hunted Docs/post_remediation_followup_plan.md` now records Workstream B as repo-side complete for the low-value normal-runtime `_G`/bare-global residue slice, with only intentional startup guardrails or higher-risk ownership seams still left for later judgment.
- Preserved: no compat-shim deletion happened, no bootstrap sequencing changed, no selector/tier/composition semantics changed, and no runtime verification is implied by this cleanup pass.

## 2026-04-06 19:35 Finish Workstream E repo-side MCM surface/default alignment
- Changed: `MCM_blueprint.json` now tightens the remaining obvious support/debug controls onto advanced/debug visibility paths where the matrix already classified them as support-only, while leaving the shipped preset contract and gameplay logic untouched.
- Changed: `MCM_blueprint.json`, `EnemyAmbush_Utils_Settings.lua`, and the remaining low-level runtime/debug fallback readers now align the shipped defaults for the current repo-side MCM surface:
  - `MCM_ShowUINotifications = true`
  - `MCM_ShowAmbushWarningNotifications = true`
  - `MCM_ShowReputationWarnings = true`
  - `MCM_BalanceProfile = BG3_12` / `Vanilla 1-12`
  - `MCM_EscapeStartTurn = 5`
- Changed: `Hunted Docs/MCM_PRESET_SETTINGS_MATRIX.md` and `Hunted Docs/post_remediation_followup_plan.md` now describe Workstream E as repo-side complete for preset/default/surface alignment instead of leaving the old pre-follow-up status text in place.
- Preserved: no preset math changed, no hidden preset knob contract changed, no selector/tier logic changed, and no runtime verification is implied by this doc/default pass.

## 2026-04-06 18:47 Update WS7 runtime verification packet after fresh post-patch delayed-ambush save/load retest
- Documented in `Hunted Docs/WS6_WS7_RUNTIME_VERIFICATION_PACKET.md` that the original WS7-A delayed-warning reload failure is now verified as fixed on fresh saves armed after the final delayed-mirror follow-up patch.
- Documented the exact successful recovery markers:
  - `Delayed ambush mirror armed for timer 'EA_AMBUSH_DELAYED_...'.`
  - `Delayed ambush mirror lookup for timer 'EA_AMBUSH_DELAYED_...': hit.`
  - `Recovered delayed ambush payload for timer 'EA_AMBUSH_DELAYED_...' using delayed mirror.`
- Documented honestly that earlier armed saves from before the final follow-up patch are not valid retroactive regression targets, and that two narrower coverage gaps still remain unproven:
  - save/load after the chain has already advanced into `EA_SPAWNQ_*`
  - active in-progress beach/bootstrap resume across save/load

## 2026-04-06 11:02 Start slice-1 contract cleanup for naming, BG3MCM requirement, preset drift, and retained-surface labeling
- Changed: `AGENTS.md`, `MCM_blueprint.json`, and the slice-1 static checks now align on the locked public name `Hunted - Dynamic Ambushes & Revenge System`, and `MCM_blueprint.json` now treats `BG3MCM` as required by setting `Optional` to `false`.
- Changed: `MCM_AllowChampionLoot` now tracks the shipped default preset baseline (`Marked` => `OFF`) across `MCM_blueprint.json`, `EnemyAmbush_Utils_Settings.lua`, and the debug fallback shown by `EnemyAmbush_DebugCommands.lua`.
- Changed: `EnemyAmbush_Config.lua` no longer carries the dead `EA_ApplySyncedSetting` path, and retained-surface comments now explicitly label `BuildActiveSummonList` and `MCMSettings` as kept-through-`1.0` internal/debug compatibility or persisted-mirror surfaces rather than supported authority surfaces.
- Changed: authoritative settings docs now describe `MCMSettings` as an internal persisted mirror for the supported `BG3MCM`-driven path, and `tools/Run-HuntedStaticChecks.ps1` now hard-fails on slice-1 naming, BG3MCM-contract, champion-loot-default, and `EA_ApplySyncedSetting` drift.

## 2026-04-04 18:10 Continue F2 stage 3 with COMMON tier packages, phase-4 weight tuning, and stronger preset-aware budgets
- Changed: `EnemyAmbush_Systems_TierPackages.lua` now lets normal `COMMON` ambushers use the same bracketed tier-status path as the other normal tiers instead of forcing them onto the inline-only fallback path, and non-CX `COMMON` now has a real `EA_TIER_COMMON_L15` package for higher-level ambushers.
- Changed: `Status_EnemyAmbush.txt` now hides the bracketed `COMMON` tier statuses in the UI, raises non-CX `COMMON` durability substantially at `L7` / `L11`, and adds the new hidden `EA_TIER_COMMON_L15` package so higher-level commons stop arriving far too soft.
- Changed: `EnemyAmbush_Systems_PoolSelection.lua` now performs the stage-3 weight retune in the live phase-4 multiplier layer: `FODDER` is clamped harder from level 6 onward, `BRUISER` / `DREAD` / `APEX` get a modest lift, and `Relentless` / `Hunted` now apply a small preset-aware class-weight overlay plus softer expensive-template suppression during phase 4.
- Changed: `EnemyAmbush_Systems_Budget.lua` now extends and strengthens the preset-aware midgame point-budget bonus for stronger presets so `Relentless` / `Hunted` can actually fund fuller packs after the 3A target-count relief and lower-fodder weight retune.
- Changed: `EnemyAmbush_Events_TimerMain.lua` and `EnemyAmbush_DebugCommands.lua` now recognize the new non-CX `EA_TIER_COMMON_L15` bracket as part of the current runtime/debug tier surface.
- Preserved: champion separation is unchanged, stage-1/2 selector logic is unchanged, raw summon data weights are unchanged, sparse creature-type support spillover is still deferred, and no public API surface was widened.

## 2026-04-04 17:30 Start F2 stage 3 slice 3A: preset-aware execution budget/count tuning
- Changed: `EnemyAmbush_Systems_SpawnExecution.lua` now applies a narrow preset-aware relief pass to the tier target adjustment for stronger presets in level-8+ large-party normal fights, so `Relentless` and especially `Hunted` stop losing as many bodies purely because the rolled tier is `VETERAN` / `ELITE` / `LEGENDARY`.
- Changed: debug mode now prints `[TargetPreset]` when this preset-aware target relief actually overrides the older static tier adjustment, making the count-tuning slice easier to verify without reopening selector logic or the base budget curve.
- Preserved: `Wayfarer` / `Marked` baseline count penalties are unchanged, champion target penalties are unchanged, early-game fairness clamps are unchanged, and the base point-budget curve in `EnemyAmbush_Systems_Budget.lua` is unchanged.
- Deferred: after this 3A pass, investigate whether sparse creature-type pools such as `Fey` should be allowed controlled support spillover from adjacent creature types instead of repeating the same narrow in-type entries.

## 2026-04-04 17:00 Follow up F2 stage 3 slice 2 with non-CX high-tier durability and movement retuning
- Changed: `Status_EnemyAmbush.txt` now pushes non-CX `VETERAN`, `ELITE`, and `LEGENDARY` durability higher again, adds new `EA_TIER_VETERAN_L15`, `EA_TIER_ELITE_L15`, and `EA_TIER_LEGENDARY_L15` brackets for endgame normal ambushers, and swaps the non-CX legendary tier icon to `statIcons_SpiderQueensWrath`.
- Changed: `EnemyAmbush_Systems_TierPackages.lua` now resolves the non-CX tier brackets through the new `L15` statuses and clears those new tier IDs correctly during reapplication.
- Changed: `EnemyAmbush_Events_TimerMain.lua` now recognizes the new non-CX `L15` tier statuses during runtime tier inference instead of stopping at the older `L11` / `L12` brackets.
- Changed: `EnemyAmbush_DebugCommands.lua` no longer treats the old flat `EA_VETERAN_BUFF` / `EA_ELITE_BUFF` / `EA_LEGENDARY_BUFF` statuses as part of the current core runtime surface; those status definitions are now left in place only as legacy compatibility shims.
- Changed: `EA_AMBUSHER` now carries `ActionResource(Movement,20,0)` instead of `9` so the shared ambusher base can be rechecked for remaining Dash-heavy behavior in runtime; this affects any enemy using the shared ambusher base, not just normals.
- Deferred: user runtime feel is good enough to pause further F2 validation for now, but explicit confirmation of the new non-CX `L15` brackets and the shared movement-20 experiment is still parked for a later focused check.
- Preserved: CX durability brackets are unchanged, selector logic is unchanged, density/mix wiring from slice 1 is unchanged, and no status-harshness package work started.

## 2026-04-04 16:05 Start F2 stage 3 slice 2: raise baseline survivability for normal ambushers
- Changed: `Status_EnemyAmbush.txt` now increases baseline normal-ambusher durability through `EA_AMBUSHER` and stronger COMMON / VETERAN / ELITE tier packages, including the CX lighter variants, so low-base-health ordinary ambushers gain more real staying power after the stage-3 slice-1 density/mix changes.
- Changed: `EnemyAmbush_Systems_TierPackages.lua` now keeps the inline COMMON fallback boosts aligned with the stronger status packages instead of leaving that fallback on the older softer values.
- Changed: debug mode now prints `[TierDurability]` when a normal ambusher receives a tier durability package or inline COMMON fallback, making the survivability slice easier to verify in runtime.
- Preserved: selector logic from stages 1/2 is unchanged, stage-3 slice-1 density/mix wiring is unchanged, champion packages are unchanged, and status-harshness has not started.

## 2026-04-04 15:35 Remove two verified bad summon-pool rows from runtime rotation
- Removed `Flaming Fist (Female)` (`38afed9e-1c42-41e5-86f9-294bae0b5ff4`) from `EnemyAmbush_Data_Summons_Vanilla.lua` after runtime logs tied a naked human/warmaiden spawn to that exact `xpOriginalTemplate`.
- Removed `Phase Spider` (`ce26d169-69ac-4e69-8462-1330615e5650`) from both the COMMON and VETERAN summon pools after runtime logs confirmed the template is still broken in normal ambush rotation.
- Clarified by implementation: this resolves a real contradiction with the older cleanup note that claimed the summon-pool `Phase Spider` row had already been removed from runtime rotation.

## 2026-04-04 15:10 Start F2 stage 3 slice 1: wire preset-owned density and high-tier/count bias into normal execution
- Changed: `EnemyAmbush_Systems_SpawnPipeline.lua` now makes hidden preset `tierBias` affect the rolled overlevel delta for normal ambushes, and clamps that roll against preset-owned `maxVeteran` / `maxElite` / `maxLegendary` availability so presets with zero allowance no longer silently keep those higher-tier rolls alive.
- Changed: `EnemyAmbush_Systems_Budget.lua` now gives large-party midgame density a small preset-aware budget bonus keyed off the hidden preset tier-bias profile, so `Relentless` / `Hunted` no longer share the same conservative density path as softer presets.
- Changed: `EnemyAmbush_Systems_SpawnExecution.lua` now makes hidden preset mix knobs real during normal execution:
  - `fodderEliteBias` adjusts live `powerClass` composition pressure
  - `maxVeteran` / `maxElite` / `maxLegendary` shape how many normal enemies can remain at stronger requested tiers before later support picks downgrade
- Changed: stage-3 slice-1 debug telemetry now exposes the new preset-owned runtime behavior via `[TierBias]`, `[BudgetPreset]`, `[PresetMix]`, and `[TierMix]`.
- Preserved: stage-1/2 selector gates remain intact, champions stay separate, no survivability tuning started, no status-harshness tuning started, and no public API surface was widened.

## 2026-04-04 13:55 Document deferred ambusher-durability and spawnrank HP follow-ups after stage-2 runtime smokes
- Documented in the plan that focused level-9 stage-2 selector smokes now show `[PowerClassPref]` firing for normal `COMMON` / `VETERAN` / `ELITE` requests and hard progression gates still logging live rejection counts, so the first stage-2 slice is now tracked as **PARTIALLY VERIFIED** instead of fully unverified.
- Documented in the plan that the separate "appears below full HP" report remains an HP-normalization bug follow-up, with user feedback now suggesting `!ea_test spawnrank` may expose it more often; this is still **UNVERIFIED** as a command-specific cause.
- Documented in the plan that there is also a distinct later F2 stage-3 survivability question: many normal ambushers still land at too little max HP even when they do spawn at full health, so baseline max-HP / temp-HP scaling will need a later tuning pass.
- Not changed: no runtime/code files changed, no F2 selector logic changed, no stage-3 tuning started, and no public API surface was widened.

## 2026-04-04 13:15 Document deferred pack-density and status-harshness follow-ups after level-9 Hunted runtime feedback
- Documented in the plan that current level-9 `Hunted` runtime feedback from a six-member party says ordinary ambushes still read too sparse at roughly `3-5` bodies; this is now explicitly parked under later F2 stage-3 budget/min-target/count tuning rather than being mixed into stage-2 selector work.
- Documented in the plan that a later status-harshness review should explicitly decide whether failed ambush Perception rolls stay on baseline `SURPRISED` only or gain one additional hidden ambush payoff package for harsher presets.
- Documented candidate inspiration for that later status review:
  - `DOPPELGANGER_OFFBALANCE` / `OFF_BALANCED`-style "Ambushed" payoff as a possible harsher follow-through for failed party surprise rolls
  - `Assassinate_Ambush` as a possible rare assassin-trait package rather than a baseline rule
- Documented that the externally referenced `DOPPELGANGER_OFFBALANCE`, `Assassinate_Ambush`, and `WYR_DRIBBLES_DOG_AMBUSH` entries are **UNVERIFIED** against this repo and should be treated as inspiration only, not as current Hunted runtime behavior.
- Not changed: no runtime/code files changed, no F2 selector logic changed, no stage-3 tuning started, and no public API surface was widened.

## 2026-04-04 12:05 Start F2 stage 2: make powerClass the main rolled-tier preference axis for normal selection
- Changed: `EnemyAmbush_Systems_PoolSelection.lua` now applies a post-gate `powerClass` preference stage for normal selection after the existing stage-1 safety rails have built the candidate pool.
- Changed: rolled normal tiers now prefer these `powerClass` groups before weighted selection:
  - `COMMON`: `FODDER`, `STANDARD`
  - `VETERAN`: `STANDARD`, `BRUISER`
  - `ELITE`: `BRUISER`, `DREAD`
  - `LEGENDARY`: `DREAD`, `APEX`
- Changed: if the preferred `powerClass` set is empty, selector fallback stays broad and uses the current gated candidate pool rather than beginning stage-3 weight/budget retuning early.
- Changed: selector debug telemetry now reports the new preference stage honestly as `[PowerClassPref] tier=... profile=... stage=... fallback=...`.
- Preserved: `resolvedTemplateLevel`, `minPartyLevel`, and `maxPartyLevel` hard gates remain in front of the new preference stage; the early small-party `VETERAN` safeguard still applies; and champions remain outside the normal pool.
- Not changed: stage-3 weight/budget retuning has not started, preset-owned caps/biases were not rewired, champion selection was not merged into the normal pool, and no public API surface was widened.

## 2026-04-04 11:10 Document latest F2 stage-1 runtime findings and deferred follow-ups
- Documented in the plan that later level-9 `Fey` / `Plant` runtime smokes further support the general stage-1 widening, but still did not fire the exact `fallback=relax_allowed_bands` progression-gate branch, so that branch remains **UNVERIFIED**.
- Documented that `!ea_test spawn type <CreatureType> ELITE` is not reliable proof for that unverified branch when the active list has zero native entries in the requested debug tier, because the debug command exits before selector fallback can be demonstrated.
- Documented two separate deferred follow-ups outside the next F2 stage-2 slice:
  - rewards/economy: `Disable Ambush Loot` currently strips generated/trade loot but can still leave base/equipped inventory, so observed weapon/supply drops are compatible with current runtime and need a later policy decision
  - HP: player reports of ambushers appearing below full HP are not log-proven yet, but the spawn-placement ordering has a plausible later-`SetLevel` / post-normalize risk worth a separate bug follow-up
- Not changed: no runtime/code files changed, F2 stage 2 did not start, F2 stage 3 did not start, and no public API surface was widened.

## 2026-04-03 21:40 Consolidated F2 stage-1 checkpoint: widening looks healthy, exact relax-fallback branch still unverified
- Tested in runtime: `!ea_test verifytemplates`, `!ea_test poolowner`, normal `!ea_test spawn random`, targeted `!ea_test spawn type Fey VETERAN`, and targeted `!ea_test spawn type Beast ELITE`.
- Verified enough: ordinary stage-1 widening is live in runtime, because normal `ELITE` requests can now resolve clearly lower-band non-champion Beast entries without selector breakage; `resolvedTemplateLevel` and `minPartyLevel` / `maxPartyLevel` still show live gate rejection in debug logs, and no obvious combat-side selector weirdness appeared in the focused checkpoint combat pass.
- Still unverified: the exact `fallback=relax_allowed_bands` progression-gate branch did not fire in the current save/context, so F2 stage 1 remains open for one last proof checkpoint rather than for a confirmed gameplay-model correction.
- Not changed: stage 2 `powerClass` preference logic has not started, stage 3 weight/budget retuning has not started, preset-owned caps/biases were not retuned, champion selection was not merged into the normal pool, and no public API surface was widened.

## 2026-04-03 18:05 Continue Workstream F2 stage 1: relax progression-gate fallback band inheritance for mid-tier requests
- Changed: `EnemyAmbush_Systems_PoolSelection.lua` no longer preserves the narrower pre-gate band shape when the strict progression gate has to relax fallback for normal `VETERAN` / `ELITE` requests; that fallback can now use the full allowed non-champion band set for the requested tier.
- Changed: progression-gate fallback stage labels now report the difference honestly as `relax_allowed_bands` for widened mid-tier fallback versus `relax_bandshape` where the old band-shape preservation still intentionally applies.
- Runtime status: ordinary stage-1 widening is **PARTIALLY VERIFIED** from current selector smokes, but the exact `fallback=relax_allowed_bands` branch is still **UNVERIFIED** pending a later consolidated F2 stage-1 checkpoint on a save/context that actually exhausts the primary mid-tier progression path.
- Preserved: `COMMON` requests remain `COMMON`-only, `LEGENDARY` requests keep their current high-threat shape, `resolvedTemplateLevel` and `minPartyLevel` / `maxPartyLevel` remain hard gates, the early small-party `VETERAN` safeguard still applies, and champions remain a separate pool.
- Not changed: stage 2 `powerClass` preference logic has not started, stage 3 weight/budget retuning has not started, preset-owned caps/biases were not retuned, champion selection was not merged into the normal pool, and no public API surface was widened.

## 2026-04-03 17:25 Start Workstream F2 stage 1: relax strict mid-tier `spawnBand` locking while preserving hard gates
- Changed: `EnemyAmbush_Systems_PoolSelection.lua` now allows normal `VETERAN` / `ELITE` requested-tier selection to include `COMMON` summon entries instead of hard-locking those requests to only `VETERAN` / `ELITE` `spawnBand` rows.
- Changed: selector telemetry now reports the broadened allowed mid-tier band set honestly (`COMMON+VETERAN+ELITE`) when themed/global band fallback messaging fires.
- Preserved: `resolvedTemplateLevel` still drives the early low-level template ceiling, `minPartyLevel` / `maxPartyLevel` still drive the strict progression gate, the early small-party `VETERAN` safeguard still restricts to `VETERAN` only, and champions remain a separate pool under `EnemyAmbush_Systems_ChampionSpawn.lua`.
- Not changed: stage 2 `powerClass` rolled-tier preference logic has not started, stage 3 weight/budget retuning has not started, preset-owned caps/biases were not retuned, champion selection was not merged into the normal pool, and no public API surface was widened.

## 2026-04-03 16:10 Workstream B slice 3: dedupe the remaining bounded int-RNG fallback path between SpawnPipeline and SpawnExecution
- Changed: `EnemyAmbush_Systems_SpawnExecution.lua` no longer carries its own local `EA_RandIntCompat` fallback LCG path for spawn-stagger jitter; it now consumes the existing `EA_RandIntCompat` owner injected from `EnemyAmbush_Systems_SpawnPipeline.lua`.
- Changed: `EnemyAmbush_Systems_SpawnPipeline.lua` now passes `EA_RandIntCompat` explicitly into the `SpawnExecution` runtime contract and validates it as a required callable dependency.
- Verified repo-side: `tools/Run-HuntedStaticChecks.ps1` passed after the dedupe.
- Intentionally not changed: the selector/tier/runtime-missing fallback overlap between `SpawnPipeline` and `SpawnExecution` remains in place, because that is semantically loaded and belongs to later scoped work, not this cleanup slice.
- Not changed: no public API surface was widened and F2 did not start.

## 2026-04-03 15:45 Workstream B slice 2: remove low-risk normal-runtime `_G` fallback chains in rest/bootstrap/surprise paths
- Changed: `EnemyAmbush_Systems_TriggerRestFlow.lua` no longer falls back to `_G.EA_PersistedNowMs`, `_G.EA_ModVarsReady`, `_G.EA_IsModVarsContainer`, or `_G.EA_GetRestAmbushChance`; the normal runtime now resolves those through injected deps or the existing `EA["..."]` owner surfaces.
- Changed: `EnemyAmbush_Events_ScenarioBootstrap.lua` no longer falls back to `_G.EA_ModVarsReady`; it now uses the already-wired `deps.EA_ModVarsReady` / `EA["EA_ModVarsReady"]` path only.
- Changed: `EnemyAmbush_Systems_Surprise.lua` no longer falls back to `_G.UpdateMetric` or `_G.DebugPrint`; it now uses the already-wired `deps.*` / `EA["..."]` owner surfaces only.
- Verified repo-side: no `_G.` reads remain in those three target files after the slice-2 cleanup, and `tools/Run-HuntedStaticChecks.ps1` passed.
- Not changed: no broader RNG/fallback dedupe landed, `EnemyAmbush_Utils_Compat.lua` was not reworked, no public API surface was widened, and F2 did not start.

## 2026-04-03 15:10 Workstream B slice 1: remove low-risk normal-runtime `_G` pressure/helper residue
- Changed: `EnemyAmbush_Utils_StateTime.lua` no longer reads ambush-pressure decay/gain/region knobs through bare globals; the normal runtime now reads those values from `EA.CFG` and `EA.REGION_POLICY`.
- Changed: `EnemyAmbush_Utils_Exports.lua` no longer seeds bare helper globals (`IsRobust`, `PlayVFX_OnEntity`, `GetSpawnRetryCount`, `GetSpawnRetryBackoffMs`, `GetSpawnRadiusBonus`) on normal bootstrap.
- Changed: `_G.EA_VFX_ALIAS` was removed from normal bootstrap; VFX aliasing now stays local to the exported `PlayVFX_OnEntity` helper.
- Changed: explicit legacy wrappers for those helper names now live only in `EnemyAmbush_Utils_Compat.lua`, so old `_G` callsites still have an opt-in shim path without polluting the default runtime.
- Not changed: no fallback/RNG cleanup landed yet, no selector/tier work started, and no public API surface was widened.

## 2026-04-03 14:20 Move raw blocked-sublevel fallback into explicit RC/beta evidence collection
- Docs: updated `HUNTED_RC_BETA_TEST_PLAYBOOK.md` with the real blocked-sublevel log targets and how testers should distinguish them from blocked safe-zone and blocked-region outcomes.
- Docs: recorded in the carry-forward Phase 6 notes that `raw blocked-sublevel fallback` remains **UNVERIFIED**, but is now intentionally handed off to RC/beta evidence collection instead of more low-signal local smoke grinding.

## 2026-04-03 14:05 Record deferred support join-window runtime evidence and move rare fallback coverage into RC/beta playbook
- Tested: three real `!ea_test spawn random` ambushes with deferred support spawns produced repeated `Deferred support join until anchor engages`, `Deferred support forced catch-up enabled`, and `Joined deferred supports:` logs.
- Result: the normal deferred support join-window / forced catch-up path is now **VERIFIED** from real ambush runtime evidence; the narrower anchor-never-engages fallback (`Support join fallback fired`) remains **UNVERIFIED**.
- Docs: updated the Phase 6 carry-forward status to reflect that split and added the remaining hard-to-force edge paths to `HUNTED_RC_BETA_TEST_PLAYBOOK.md` for RC/beta evidence capture.

## 2026-04-03 13:35 Fix `time_in_danger` save/load persistence
- Diagnosed: `EA_TimeInDangerState` was registered as persistent, but its live write paths still relied on nested in-place mutation. That matched the earlier hostile-retry failure pattern and could drop accumulated danger after save/load.
- Changed: `time_in_danger` write paths now rewrite `EA_TimeInDangerState` as a fresh root snapshot on accumulation, reset, travel-check stamp updates, and the load-time timestamp sanitize path.
- Not changed: host-scoped ownership remains the same, `time_in_danger` still belongs to the normal ambient risk flow, and no authored/custom API behavior was widened here.

## 2026-04-03 13:10 Verify persistent hostile retry rearm after load on the fixed build
- Tested: seeded one persistent hostile retry row with `!ea_test hostileretry arm`, confirmed `count=1` before save, saved immediately, then reloaded before expiry.
- Result: strict post-load snapshot reported `field=present_rows count=1`, rearm decision reported `rearmed=1`, `Rearmed persistent hostile retries: 1` printed, and `!ea_test hostileretry show` still reported `count=1` after load until the timer fired.
- Status: the `persistent hostile retry rearm after load` branch is now **VERIFIED** on the current build.

## 2026-04-03 12:35 Mirror reputation-style root snapshot writes for persistent hostile retry queue
- Diagnosed: forcing `EA_Dirty(true)` alone was not enough; seeded save/load smoke still came back with `Persistent hostile retry snapshot[session_loaded_pre_rearm_strict]: ... field=present_empty count=0`.
- Changed: the persistent hostile retry queue now writes `EA_PersistentHostileRetries` back as a fresh root-field snapshot on add/remove/clear instead of relying on nested in-place mutation.
- Changed: read/debug consumers for that queue now tolerate ModVars userdata rows and avoid depending on auto-init side effects for the branch under test.
- Not changed: no broader hostility ownership was rewritten; verification landed separately in the follow-up seeded rerun recorded below.

## 2026-04-03 02:05 Force immediate ModVars flush for persistent hostile retry queue mutations
- Diagnosed: the failing `persistent hostile retry rearm after load` branch was most likely losing state because queue mutations used the debounced `EA_Dirty()` path, allowing a quick save/load to happen before `EA_PersistentHostileRetries` was flushed.
- Changed: persistent hostile retry queue mutations now call `EA_Dirty(true)` when rows are added, consumed, or explicitly cleared.
- Not changed: no broader hostility logic or ownership was rewritten, and the branch is still **UNVERIFIED on the fixed build** until the seeded save/load smoke is rerun.

## 2026-04-03 01:20 Record failing seeded smoke for persistent hostile retry rearm after load
- Tested: seeded one persistent hostile retry row with `!ea_test hostileretry arm`, confirmed `count=1` before save, then saved and reloaded before the timer should have fired.
- Result: after load, `!ea_test hostileretry show` returned `count=0` and the expected `Rearmed persistent hostile retries: 1` log did not appear.
- Status: the `persistent hostile retry rearm after load` branch is no longer just unproved; the current seeded smoke **CONTRADICTS** the expected rearm behavior and should be treated as an open runtime bug until diagnosed.

## 2026-04-03 00:35 Add narrow hostile-retry load-rearm probe for Workstream C
- Changed: added a debug-only persistent hostile-retry probe so the Phase 6 `persistent hostile retry rearm after load` branch can be seeded and inspected without touching ownership/runtime behavior.
- Added: `!ea_test hostileretry show|arm <enemy> [delayMs] [tries]|clear`.
- Added: debug-only scheduling/firing logs for persistent hostile retry rows so save/load rearm evidence is easier to read.
- Status: the branch remains **UNVERIFIED** from repo-side work alone; this slice makes it instrumentable for an honest runtime proof pass.

## 2026-04-02 21:05 Raise baseline non-champion ambusher movement budget after turn-1 Dash observation
- Changed: increased the hidden `EA_AMBUSHER` baseline movement budget from `ActionResource(Movement,6,0)` to `ActionResource(Movement,9,0)` after runtime smoke still showed ordinary ambushers like `Redcap` choosing `Dash` on turn 1.
- Not changed: hidden champion base packages remain at `ActionResource(Movement,6,0)`, no selector/tier work landed, and party-wide cooldown proof remains explicitly **UNVERIFIED** for now.

## 2026-04-02 20:15 Fold baseline ambusher mobility into hidden status-owned movement budget
- Changed: `EA_AMBUSHER` now owns the baseline movement assist through a hidden `ActionResource(Movement,6,0)` boost instead of applying visible `MAG_MOMENTUM`.
- Changed: the ordinary non-champion spawn path no longer applies a separate `MAG_MOMENTUM`/`LONGSTRIDER` movement shim after `EA_AMBUSHER`; baseline ambusher mobility is now status-owned.
- Changed: champion base packages now carry the same hidden movement budget, and the explicit champion `LONGSTRIDER` application was removed.
- Not changed: hostile-retry/combat-rescue momentum still exists as emergency join logic, no selector/tier work landed, and this still is not a full AI overhaul.

## 2026-04-02 19:40 F1 status/presentation cleanup for champions and stronger ambushers
- Changed: hid the purely mechanical champion base packages and random trait statuses from the combat UI so stronger enemies stop stacking multiple internal status labels during inspection.
- Changed: hid the legacy fallback buff statuses and common survivability helper for the same reason, without altering their mechanical effects.
- Changed: cleaned up the visible champion type identities for `Fey` and `Undead` so they better match the current roster after the hag and skeleton giant updates.
- Changed: champion arrival popups/logs now read more naturally (`%s has come for you.` / `Champion arrived: ...`) instead of duplicating the word `champion` on already-named creatures.
- Not changed: no selector/tier restructuring landed, no balance/preset values changed, no public API changed, and the hidden arrival/escape cue model remains intact.

## 2026-04-02 19:00 Regenerate hag XP-zero coverage and add one more small champion promotion pass
- Changed: switched the fey champion entry from the old base green hag template to `Hag_Green_Act1Hag` (`d4edf374-6efe-463f-8899-889db26dee4e`).
- Changed: regenerated the shipped XP-zero assets so the new hag template now has clone coverage under sub-`100%` ambush XP settings.
- Changed: added `Wood Woad` as a second plant champion and `Skeleton Giant (Apostate)` as a mid-tier undead champion to widen the roster without touching the selector/tier model.
- Not changed: the current beholder entry still remains for in-game comparison, `Dark Justiciar Giant` still remains as requested, and no Workstream `F2` selector/tier restructuring has started.

## 2026-04-02 18:05 Expand the champion roster with safe vanilla-pool promotions
- Changed: added `Spectator` as a second aberration champion candidate instead of relying only on the current beholder entry.
- Changed: replaced the old plant champion template with `Shadow-Cursed Shambling Mound`, removing the shipped `BASE_ShamblingMound_A` champion entry while preserving the existing plant-champion gate.
- Changed: added `Minotaur` as a mid-tier monstrosity champion candidate so `Phase Spider Matriarch` is no longer the only shipped monstrosity champion.
- Not changed: `Dark Justiciar Giant` was kept as requested despite resolving to a `BASE_*` template, the current beholder entry was left in place for in-game comparison, and the requested hag UUID swap is still deferred until XP-zero clone assets are regenerated for that template.

## 2026-04-02 16:35 Champion follow-up gate rebalance from observed scaled threat
- Changed: tightened a subset of shipped champion `minPartyLevel` gates against observed in-game scaled champion threat rather than only the raw source template level.
- Changed: raised gates for `Planar Ally: Cambion`, `Adamantine Golem`, `Fire Elemental Prime`, `Shambling Mound Ancient`, `Skeletal Dragon`, `Red Dragon`, `Phase Spider Matriarch`, and `Oathbreaker Knight Champion`.
- Changed: champions no longer roll the weighted Haste trait directly; Haste stays confined to the non-champion `LEGENDARY` high-threat path.
- Changed: champion base labels are now shown as `Champion` / `Champion (CX)` instead of `Champion (Base)` / `Champion (Base CX)`.
- Not changed: runtime champion level scaling still uses the existing `playerLevel + 2` target floor; this pass only rebalanced champion entry gates, not champion scaling itself.
- Unchanged blocker: the requested replacement hag UUID `d4edf374-6efe-463f-8899-889db26dee4e` does not exist in the repo or generated XP-clone map, so swapping it in would currently break champion spawn coverage when non-100% XP mode is active.

## 2026-04-02 15:05 Start Workstream F1 with champion gating and Haste audit
- Changed: added shipped champion-entry `minPartyLevel` gates across the vanilla champion table, with `maxPartyLevel` used only on the two low-level rare variants (`Wild Magic Cambion` and `Planar Ally (Djinni)`).
- Changed: `EA_ResolveChampionSpawnData()` now filters provider champion candidates against party level before weighted selection instead of allowing late-game entries to resolve purely by creature type and provider weight.
- Changed: when a provider champion is level-gated out, the existing compat summon-fallback path can still engage if allowed by the current fallback policy; gated provider entries themselves are no longer selected.
- Changed: removed unconditional champion `HASTE` from `EnemyAmbush_Systems_ChampionSpawn.lua`.
- Changed: moved Haste into a rare weighted high-threat trait outcome used by champions and `LEGENDARY` enemies instead of an always-on champion spawn buff.
- Audit: the shipped vanilla champion table currently has `20` entries across `14` creature types; `9` of those types still have only one shipped champion entry, so this slice intentionally did not widen into general weight normalization or selector/tier work.
- Not changed: no public API surface was widened, no grouped-variant budgeting landed, no escape redesign started, no broad selector/tier overhaul started, and beach/bootstrap plus authored/custom D2 behavior remain untouched.

## 2026-04-02 00:21 Add passive `time_in_danger` travel ambush checks to the normal ambient flow
- Changed: added a bounded normal-flow travel ambush check sourced from shared `time_in_danger` state, evaluated from the existing `EA_RUNTIME_COMBAT_PRUNE` cadence instead of the authored/custom ambush runtime.
- Changed: the travel-risk consumer now lives in `EnemyAmbush_Systems_TriggerRestFlow.lua`, reuses the existing normal ambient safety/cooldown/spawn path with `skipScripted=true`, and keeps successful travel-risk consumption resetting the shared danger state through the existing normal ambush queue path.
- Changed: the shared `EA_TimeInDangerState` bucket now tracks the last passive-travel evaluation timestamp per character so the feature can respect a low-frequency cadence without inventing a second state bag.
- Changed: delayed-spawn logging/telemetry now preserves a distinct `TravelDanger` flow label for this internal trigger path instead of misclassifying it as a short-rest flow.
- Not changed: `time_in_danger` still does not dispatch authored/custom ambushes, the public D2 API surface was not widened, beach/bootstrap behavior was not reworked here, rest-triggered ambush behavior was preserved, and no Workstream `B` or broad `F` work started.

## 2026-04-01 23:52 Close Workstream D2 authored/custom ambush API v1 as currently scoped
- Verified: runtime smoke now covers the full shipped D2 surface through `!ea_test api authored_smoke`, `!ea_test api trigger_smoke`, and `!ea_test api custom_smoke`.
- Verified: beach/bootstrap still behaves correctly after the D2 export/runtime bridge changes.
- Changed: updated `Hunted Docs/AMBUSH_FRAMEWORK_V1_API_CONTRACT.md` to remove stale pre-implementation wording and record the current D2 closeout scope honestly.
- Changed: updated `Hunted Docs/post_remediation_followup_plan.md` to record that Workstream `D2` is complete as currently scoped.
- Not changed: no new public API surface was added, the normal ambient risk model and passive `time_in_danger` travel ambush behavior remain out of D2 scope, and no Workstream `B`, `C`, or `F` work started.

## 2026-04-01 19:30 Land Workstream D2-3 `TriggerCustomAmbush`
- Changed: added `TriggerCustomAmbush(payload)` on both `EnemyAmbush.*` and `EnemyAmbush.API.*`.
- Changed: the D2 public one-shot custom trigger path now validates payload shape separately from the persistent D2 registry path, rejects unsupported internal-only `custom_entries` fields, and routes accepted payloads through the same non-persist public runtime bridge used by D2-2.
- Changed: added internal debug verification command `!ea_test api custom_smoke` so the D2-3 one-shot custom trigger path can be runtime-smoked from the in-game Script Extender console.
- Changed: `Hunted Docs/API.md` now documents `TriggerCustomAmbush(...)` exactly as landed in this slice.
- Not changed: normal ambient risk features such as passive `time_in_danger` travel ambushes remain out of D2 scope, `pool_roll` is still not frozen as a public trigger runtime here, beach/bootstrap behavior was not reworked here, and no Workstream `B`, `C`, or `F` work started.

## 2026-04-01 18:35 Land Workstream D2-2 `TriggerAmbushDefinition`
- Changed: added `TriggerAmbushDefinition(id, ctx)` on both `EnemyAmbush.*` and `EnemyAmbush.API.*`.
- Changed: the D2 public trigger path now validates registered public definitions against current external character context and returns the minimum stable trigger result shape on success.
- Changed: the internal authored runtime now has a non-persist public trigger bridge so D2 public definitions do not write into the shipped `EA_ScriptedScenarioState` bag.
- Changed: added internal debug verification command `!ea_test api trigger_smoke` so the D2-2 trigger path can be runtime-smoked from the in-game Script Extender console.
- Changed: `Hunted Docs/API.md` now documents `TriggerAmbushDefinition(...)` exactly as landed in this slice.
- Not changed: `TriggerCustomAmbush(payload)` is still pending, `pool_roll` is not frozen as a public trigger runtime yet, beach/bootstrap behavior was not reworked here, and no Workstream `B`, `C`, or `F` work started.

## 2026-04-01 17:45 Start Workstream D2 with the first public authored-definition API slice
- Changed: added the first narrow public authored/custom ambush API surface on both `EnemyAmbush.*` and `EnemyAmbush.API.*`:
  - `RegisterAmbushDefinition`
  - `UnregisterAmbushDefinition`
  - `GetAmbushDefinition`
  - `GetAmbushState`
- Changed: the internal authored-ambush service now keeps a separate validated public-definition registry instead of trying to force D2 registrations directly into the existing D1 internal shipped-definition path.
- Changed: `Hunted Docs/API.md` now documents only the `D2-1` functions that are actually live; trigger calls remain intentionally pending.
- Changed: added internal debug verification command `!ea_test api authored_smoke` so the new D2-1 surface can be runtime-smoked from the in-game Script Extender console.
- Not changed: `TriggerAmbushDefinition` / `TriggerCustomAmbush` are still not implemented, beach/bootstrap behavior was not reworked here, and no Workstream `B`, `C`, or `F` work started.

## 2026-04-01 16:58 Stabilize D1 authored-definition boundaries before D2
- Changed: moved shipped authored ambush definition data out of `EnemyAmbush_Scenarios.lua` into the dedicated internal file `EnemyAmbush_AuthoredDefinitions.lua`.
- Changed: `EnemyAmbush_Scenarios.lua` now keeps matcher/runtime/state/execution glue, while bootstrap remains only the narrow story-wakeup adapter for beach.
- Changed: locked the intended pre-D2 split in the follow-up plan: framework core owns definitions/runtime state, thin adapters own one-off story glue, and D2 should wrap that same framework rather than adding a second path.
- Not changed: no public ambush API was added, beach/bootstrap gameplay flow was not redesigned, and selector/tier work did not start.

## 2026-04-01 11:18 Narrow the beach wake-up bootstrap exception on the D1 authored foundation
- Changed: `EA_SCN_BEACH_WAKEUP` now routes beach-triggered execution through the internal authored runtime when available, instead of having `EnemyAmbush_Events_ScenarioBootstrap.lua` hard-call the scenario id directly as the primary path.
- Changed: beach-specific escape suppression and combat-start presentation suppression now travel through generic spawned-data flags (`noEscape`, `suppressCombatStartPresentation`) instead of hardcoded `EA_SCN_BEACH_WAKEUP` checks in combat flow.
- Changed: the internal beach scenario theme label is now `GOBLIN_BEACH_WAKEUP` instead of the older `COASTAL_RAID` legacy naming.
- Not changed: beach wake-up still keeps story-wakeup/timer orchestration in `EnemyAmbush_Events_ScenarioBootstrap.lua`, no public API was added, and selector/tier behavior was not reworked.

## 2026-04-01 10:42 Fix D1 time-in-danger runtime tick sourcing
- Fixed: `time_in_danger` now uses the live host-scoped player anchor consistently for accumulation, reads camp state from `DB_InCamp` / `DB_PlayerInCamp` before falling back to region policy, and checks direct character combat before the broader party-combat signal.
- Fixed: the monotonic fallback clock in `EnemyAmbush_Utils_StateTime.lua` no longer multiplies BG3SE monotonic milliseconds by `1000`, which was causing each periodic danger tick to exceed the max-delta clamp and remain stuck at `deltaMs=0`.
- Not changed: no public API was added, authored `region_entry` / rest behavior remain intact, and beach/bootstrap was not reworked here.

## 2026-04-01 10:05 Correct D1 time-in-danger ownership into normal ambush risk flow
- Changed: removed `time_in_danger` from the internal authored/custom ambush trigger model.
- Changed: moved `time_in_danger` state into shared persistent runtime state owned with other time/risk helpers instead of `EA_ScriptedScenarioState`.
- Changed: the existing recurring runtime-combat-prune cadence now feeds shared `time_in_danger` accumulation for the normal ambush flow.
- Changed: rest-triggered normal ambush chance now consumes shared danger risk proportionally, while successful authored/champion/normal ambush consumption resets the accumulated danger state.
- Not changed: `region_entry` remains in the internal authored runtime, beach/bootstrap was not reworked here, and no public API surface was added.

## 2026-04-01 08:35 Continue Workstream D1 with internal time-in-danger trigger support
- Changed: added a repo-side experimental `time_in_danger` accumulation/evaluation path using canonical region, blocked safe-zone, camp, and combat context.
- Clarification: this landed inside the internal authored runtime, but that is now considered a misaligned intermediate step rather than the intended long-term model.
- Maintainer direction: `time_in_danger` should feed the normal ambush risk/chance flow, not dispatch authored/custom ambush definitions.
- Not changed: no public ambush API was added, no shipped `time_in_danger` authored content was introduced, and beach/bootstrap / selector-tier behavior were not reworked here.

## 2026-03-31 20:31 Continue Workstream D1 with internal region-entry trigger routing
- Changed: internal authored-ambush schema/runtime now supports `region_entry` matching using canonical region keys plus safe-zone/camp/blocked-region guards.
- Changed: `EnemyAmbush_Events.lua` now routes the existing `EnteredLevel` player signal through the internal authored-ambush runtime, while keeping the beach bootstrap path intact.
- Not changed: no public ambush API was added, no shipped region-entry authored content was introduced yet, and time-in-danger / selector-tier work remain out of scope.

## 2026-03-31 20:05 Start Workstream D1 internal authored-ambush foundation
- Changed: added `EnemyAmbush_Systems_AuthoredAmbushService.lua` as the internal owner for authored-ambush definition normalization, registry, and match selection.
- Changed: `EnemyAmbush_Scenarios.lua` now routes its current shipped scenario definition through that internal service while keeping existing spawn execution, state persistence, and beach bootstrap glue in place.
- Intentionally not changed: no public ambush API was added, beach bootstrap remains a bootstrap-driven exception, and selector/tier behavior was not touched.

## 2026-03-31 19:25 Close direct Phase 6 hostile proof and record release residue posture
- Verified: direct `!ea_test hostile <uuid>` success is now runtime-proven from a neutral NPC debug spawn through the hostility pipeline.
- Changed: updated `Hunted Docs/post_remediation_followup_plan.md`, `Hunted Docs/healthcheck_remediation.md`, and `Hunted Docs/phase6_hostility_region_boundary_split_implementation_checklist.md` to remove that branch from the open evidence-debt list.
- Deferred but acceptable for release: the remaining Phase 6 edge-path evidence debt stays explicitly **UNVERIFIED**:
  - join-window expiry / anchor-never-engages fallback
  - raw blocked-sublevel fallback
  - persistent hostile retry rearm after load
- Not changed: compat-shim smoke remains low-priority `UNVERIFIED` but non-blocking, and no Workstream `B`, `D`, or `F` work started.

## 2026-03-31 12:28 Close Workstream E verification pass
- Verified: Workstream `E` is now repo-side complete across slices 1-3:
  - shipped preset rename/migration
  - explicit preset/global/support owner map
  - locked visible preset baselines
  - hidden preset-owned balance knobs in canonical runtime contract/data
- Verified: runtime evidence now covers:
  - startup after the Workstream `E` changes
  - shipped preset switches for `Wayfarer`, `Marked`, `Relentless`, and `Hunted`
  - global/non-preset settings surviving preset switches
  - `CUSTOM` transition bookkeeping on preset-owned edits
- Deferred residue: `chanceMult` remains isolated as `temporary_hidden_preset_owned_residue`; it was not redesigned or folded back into the canonical preset map.
- Not started: Workstream `F` selector/tier overhaul still has not started, and hidden preset knobs are not yet consumed by selector/tier behavior.

## 2026-03-31 09:42 Implement Workstream E preset contract slices 1-3
- Changed: completed the shipped preset contract rename from legacy `EASY` / `NORMAL` / `HARD` to `Wayfarer` / `Marked` / `Relentless` / `Hunted`, while preserving one-way migration and `CUSTOM` bookkeeping.
- Changed: `EnemyAmbush_MCMContract.lua`, `EnemyAmbush_Utils_Settings.lua`, and `EnemyAmbush_Config.lua` now use an explicit preset/global/support owner map instead of scattered preset-ownership assumptions.
- Changed: shipped preset application now runs through a canonical preset-owned setting binding list for:
  - cooldown / chance / delay / intensity / party surprised
  - escape settings
  - XP / loot / champion loot
- Changed: hidden preset-owned balance knobs now exist as explicit canonical runtime data:
  - tier bias
  - champion weight multiplier
  - fodder-vs-elite bias
  - max veteran / elite / legendary counts
- Changed: `chanceMult` was kept explicit as bounded legacy residue instead of being silently folded back into the canonical preset map. Classification: `temporary_hidden_preset_owned_residue`.
- Changed: updated `Hunted Docs/MCM_PRESET_SETTINGS_MATRIX.md` and `Hunted Docs/post_remediation_followup_plan.md` so Workstream E status no longer describes the pre-implementation state.
- Verified: repo-side checks passed after the Workstream E slices:
  - `MCM_blueprint.json` parses
  - `tools/Run-HuntedStaticChecks.ps1` passed
- Not started: selector/tier overhaul wiring remains pending and is still outside Workstream E.

## 2026-03-30 16:10 Complete Phase 9 compatibility surface retirement closeout
- Changed: updated `Hunted Docs/phase9_compatibility_surface_retirement_implementation_checklist.md` to record the final Phase 9 closeout instead of a pre-closeout state.
- Changed: updated `Hunted Docs/healthcheck_remediation.md` to mark `CP-08` and Phase 9 complete with the final explicit compatibility-surface outcome:
  - internal runtime no longer depends on compat globals in the default runtime path
  - `EnemyAmbush_Utils_Compat.lua` is retained only as an explicit optional legacy/dev shim
  - remaining compatibility surfaces are explicitly allowlisted as `public_api`, `debug_internal`, `internal_legacy_mirror`, or `compat_global_temporary`
- Verified: final repo/static proof shows:
  - normal bootstrap no longer loads `EnemyAmbush_Utils_Compat.lua`
  - repo search leaves compat-global definitions only in the opt-in shim itself, the opt-in guard in `EnemyAmbush_Utils.lua`, and documentation
  - `tools/Run-HuntedStaticChecks.ps1` passed
- Verified: recorded runtime evidence now covers:
  - fresh boot without compat-shim activation
  - reload without new seam failures
  - `!ea_test spawnhostile`
  - `!ea_test spawn random`
  - `!ea_test poolowner`
  - no global-helper deprecation warnings during the default runtime smoke
- Unverified but non-blocking: the explicit opt-in compat-shim branch remains **UNVERIFIED**. The closeout gate was the default internal runtime path with compat globals disabled by default.

## 2026-03-30 13:05 Complete Phase 8 event/timer control simplification closeout
- Changed: updated `Hunted Docs/phase8_event_timer_simplification_implementation_checklist.md` from a pre-implementation plan into the final Phase 8 closeout record.
- Changed: updated `Hunted Docs/healthcheck_remediation.md` to mark Phase 8 complete and to record the final explicit owners:
  - listener-registration coordinator: `EnemyAmbush_Events.lua::EA_RegisterAllEventListeners()`
  - startup recurring timer owner: `EnemyAmbush_Events_TimerMain.lua::LaunchStartupRecurringTimers()`
  - session-load timer relaunch owner: `EnemyAmbush_Events_TimerMain.lua::HandleSessionLoadedTimerStartup()`
- Changed: recorded the measured Phase 8 follow-through decisions:
  - `LP-02`: justified code change; the broad `KilledBy` world-reputation path now uses deferred dirty flushes through `SaveReputation(false)` while persistence ownership stays in `EnemyAmbush_Systems_PersistenceControl.lua`
  - `LP-03`: explicit no-change decision; rescue logic remains intact because current ambush-owned evidence still classifies the issue as contained
- Verified: final runtime evidence now covers:
  - listener registration on fresh boot and reload
  - startup/session-load timer ownership and pending-timer relaunch
  - ordinary ambush timer flow
  - deferred short-rest / long-rest retry and defer-resume behavior, including save/load recovery
  - `LP-02` write-cadence verification via `phase0` counters
  - `LP-03` encounter-watch and combat-retry telemetry remaining live without evidence-driven rescue simplification
- Unverified but non-blocking: not every exact recurring / edge timer family was re-proven in isolation during final Phase 8 closeout. This was not required by the Phase 8 exit criteria.

## 2026-03-29 19:33 Complete Phase 7 spawn orchestration flattening closeout
- Changed: updated `Hunted Docs/phase7_spawn_orchestration_flattening_implementation_checklist.md` to record the final Phase 7 state instead of the pre-closeout migration target.
- Changed: updated `Hunted Docs/healthcheck_remediation.md` to mark `CP-03` and Phase 7 complete with the final explicit composition root:
  - `Hunted_DynamicAmbushes_Revenge_System/Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_CompositionRoot.lua`
- Changed: recorded that no temporary public/export forwarding seams remain at Phase 7 closeout and that `EnemyAmbush._TriggerAmbush` was removed during the final consumer/export-contract pass.
- Verified: final runtime evidence now covers:
  - bootstrap ordering from `BootstrapServer.lua`
  - session-load initialization
  - ordinary ambush trigger and spawn flow
  - provider-change invalidation
  - debug commands that consume moved exports
- Unverified: the older `MD-06` Phase 6 join-window expiry / anchor-never-engages fallback path remains explicitly **UNVERIFIED** and is still not being restated as Phase 7-complete.

## 2026-03-29 14:20 Record the maintainer exception allowing Phase 7 to start with one open Phase 6 verification gap
- Changed: updated `Hunted Docs/healthcheck_remediation.md` and `Hunted Docs/phase6_hostility_region_boundary_split_implementation_checklist.md` to state that Phase 6 is structurally complete for the repo-side split.
- Unverified: deferred support join-window expiry / anchor-never-engages fallback remains explicitly **UNVERIFIED** and is still not being represented as checklist-complete.
- Changed: recorded the explicit maintainer decision that Phase 7 may proceed anyway because the repo-side split and main runtime paths are already verified.
- Note: this exception exists because the expiry/fallback path is difficult to prove cleanly without adding a new debug probe, which is intentionally deferred for now.

## 2026-03-27 20:08 Record Phase 6 hostility/region boundary split closeout status
- Changed: finalized the repo-side Phase 6 ownership split around honest runtime owners:
  - `EnemyAmbush_Systems_ChampionState.lua`
  - `EnemyAmbush_Systems_RegionPolicy.lua`
  - `EnemyAmbush_Systems_SupportJoinService.lua`
  - `EnemyAmbush_Systems_HostilityService.lua`
- Changed: collapsed `EnemyAmbush_Utils_HostilityRegion.lua` to a thin compatibility shim only; it no longer owns champion queue state, support-join state, region policy state, or hostility conversion/retry behavior.
- Changed: moved the remaining shared compatibility export/config seeding needed by current bootstrap consumers into `EnemyAmbush_Utils_Exports.lua`, and updated `EnemyAmbush_Systems_SpawnPipeline.lua` to prefer owner exports on `EnemyAmbush` instead of old-file side effects.
- Verified: final Phase 6 repo/static proof passed through `tools/Run-HuntedStaticChecks.ps1`.
- Verified: recorded runtime evidence now covers:
  - hostile conversion on ordinary ambush and `!ea_test spawnhostile` main paths
  - deferred support join on the anchor-engages / forced-catch-up path
  - camp suppression and blocked safe-zone checks
  - guaranteed champion arming and consumption
- Unverified: the following Phase 6 edge paths remain explicitly **UNVERIFIED**:
  - deferred support join-window expiry / anchor-never-engages fallback
  - raw blocked-sublevel fallback
  - direct `!ea_test hostile <uuid>` success branch
  - persistent hostile retry rearm after load
- Status: the repo split is complete, but Phase 6 itself is not yet marked complete because the checklist requires join-window expiry verification and that path has not been reproduced.

## 2026-03-24 23:37 Complete Phase 5 champion ownership and fallback resolution closeout
- Changed: finalized `EnemyAmbush_Systems_ChampionSpawn.lua` as the authoritative champion resolver owner through `EA_ResolveChampionSpawnData(...)`; `EnemyAmbush_Systems_SpawnPipeline.lua` remains a wiring/export surface, not the resolver owner.
- Changed: final in-repo champion consumers now use resolver-owned outcomes instead of inferring source/reason from logs, nil checks, or ad hoc fallback logic:
  - `SpawnChampionNow`
  - `SpawnChampionIfNeeded`
  - `EA_TrySpawnArmedChampion`
  - long-rest champion paths
  - `!ea_test champion` debug force/direct paths
- Changed: the shipped champion fallback policy is now explicitly documented and verified:
  - supported modes: `compat`, `strict`, `debug_only`
  - shipped default: `compat`
  - long-term default tightening is intentionally deferred pending broader evidence
- Verified: final repo/static proof passed through `tools/Run-HuntedStaticChecks.ps1`, and repo cross-check now finds no in-repo champion consumer deciding `provider` / `summon_fallback` / `none` outside `EA_ResolveChampionSpawnData(...)`.
- Verified: recorded runtime smoke now covers:
  - built-in provider resolution
  - summon-fallback resolution
  - controlled `none` behavior
  - ordinary `chance_path`
  - `armed_queue`
  - `debug_force`
  - `strict` blocked fallback
  - `debug_only` debug-vs-non-debug split
- Unverified: real out-of-repo third-party/provider-style behavior remains **UNVERIFIED**. The public API/provider surface exists, but no separate third-party champion provider was runtime-verified during Phase 5.

## 2026-03-23 19:35 Complete Phase 4 pool ownership extraction closeout
- Changed: finalized `EnemyAmbush_Systems_PoolSelection.lua` as the authoritative pool owner for active summon materialization, template indexes, variant indexes, weighted caches, provider revision state, and rebuild-needed state.
- Changed: remaining internal pool consumers now use exported owner/query helpers instead of direct pool-global reads:
  - `EnemyAmbush_Systems_SpawnExecution.lua`
  - `EnemyAmbush_Systems_ChampionSpawn.lua`
  - `EnemyAmbush_Events.lua`
- Changed: Phase 4 closeout docs now record the final owner surface and the temporary compatibility mirrors that still remain:
  - `EA["BuildActiveSummonList"]`
  - `EA["EA_RequestCacheRebuild"]`
  - `EnemyAmbush.TemplateIndex`
  - `EnemyAmbush.TemplateVariants`
  - `EnemyAmbush.TemplateVariantIndex`
  - `EnemyAmbush.Cache`
- Verified: final repo/static proof passed through:
  - `Check-Phase4Task3.ps1`
  - `Check-Phase4Task4.ps1`
  - `Check-Phase4Task5.ps1`
  - `Check-Phase4Task6.ps1`
  - `Run-HuntedStaticChecks.ps1`
- Verified: recorded runtime smoke now covers:
  - provider/settings rebuilds, including `MCM_EnableVanillaSummons`
  - weighted-list reuse after rebuild
  - scenario lookup (`EA_SCN_BEACH_WAKEUP`)
  - debug lookup and `!ea_test clearcache`
  - ordinary gameplay spawn paths
  - champion consumer path via `!ea_test champion Humanoid force`

## 2026-03-22 15:05 Make BG3MCM a required dependency after Phase 3
- Changed: `EnemyAmbush_Config.lua` no longer uses the no-`BG3MCM` startup/settings fallback branch or its persisted-settings retry path.
- Changed: startup without `BG3MCM` now logs a clear requirement message instead of attempting persisted-settings fallback behavior.
- Changed: `meta.lsx` now declares `BG3MCM` as a dependency using the locally verified module UUID `755a8a72-407f-4f0d-9a33-274ac0f0b53d`.
- Changed: install/support docs now treat `BG3MCM` as required instead of optional.
- Preserved: the normal `BG3MCM`-present startup pull plus `BG3MCM.MCM_Setting_Saved` behavior is unchanged.

## 2026-03-22 13:35 Complete Phase 3 strict persistent-state contract closeout
- Changed: finalized the strict persistent-state owner surface around `EA_GetPersistentVarsStrict()` / `EA_Vars()` and the strict accessor family rooted in real ModVars fields such as `PersistentPendingAmbushes`, `Reputation`, `MCMSettings`, `MCMCustomPresetBase`, and `CXOverride`.
- Changed: removed the remaining normal-runtime shadow-persistence ownership expectations from the Phase 3 closeout docs; final runtime repo search now finds no Lua matches for `_eaRuntimeVars`, `_eaVarsUsingFallback`, `EA_MergeRuntimeFallbackVarsIntoPersistent`, or fallback-restored merge telemetry.
- Changed: recorded the surviving bounded retry paths explicitly instead of treating them as generic fallback behavior:
  - `SaveReputation()` delayed write retry protects `Reputation`
  - `LoadReputation()` delayed/verify retries protect `Reputation` restore after load
  - ambush cooldown stamp retry protects `LastAmbushTime`
  - no-`BG3MCM` persisted-settings fallback retry protects persisted `MCMSettings` / `CXOverride` when that branch is used
- Verified: final static verification passed via `tools/Run-HuntedStaticChecks.ps1`.
- Verified: final live smoke covered repeated save/load, pending-ambush reload, reputation persistence after reload, readiness diagnostics, and the beach/bootstrap path touched during the Task 4 fix.
- Unverified: the no-`BG3MCM` persisted-settings fallback branch remains code-supported, but its live smoke path is still **UNVERIFIED**.

## 2026-03-17 15:25 Complete Phase 2 settings authority consolidation
- Changed: `EnemyAmbush_Utils_Settings.lua` is now the clear settings owner for raw storage (`EnemyAmbush.Settings`, `EnemyAmbush.SettingsDefaults`, `EnemyAmbush.SettingsSnapshot`), the canonical apply path (`EA_ApplyOwnedRuntimeSettingsBatch()` / `EA_ApplyOwnedRuntimeSetting()`), and the shared read API (`EA_ReadSettingRaw()` / `EA_ReadSettingBool()` / `EA_ReadSettingNumber()`).
- Changed: `EnemyAmbush_Config.lua` now routes startup MCM pull, `BG3MCM.MCM_Setting_Saved`, and synced-setting apply through the same owner path instead of parallel ad hoc setting updates.
- Changed: rebuild/cache invalidation is now limited to explicit rebuild-sensitive settings and provider-activation changes; non-rebuild settings no longer trigger provider/cache churn just because their effective value changed.
- Changed: owner-local `MCM_*` cache sprawl was collapsed to owner-internal derived cache only, and the main Phase 2 consumer modules now read settings through the shared owner surface instead of defining their own `EA_GetSetting...` reader families.
- Fixed: preset baseline sync writes no longer falsely flip the preset to `CUSTOM`; actual advanced-owned user edits still do.
- Fixed: startup CX-mode resolution now reads through the shared owner surface, removing the post-Task 7 `EA_GetSettingBool` nil-call regression.
- Verified: supported runtime settings behavior no longer includes `hunted_settings.json`, JSON watch/import, or `!ea_test configpoll`. Historical changelog entries mentioning those older surfaces remain as history only.
## 2026-03-17 09:25 Fix normal ambush CREATE_OOS_ONLY behavior and failure spam
- Updated `EnemyAmbush_Systems_SpawnPlacement.lua` so normal ambushers can attempt `CreateOutOfSightAtDirection` using the existing safe anchor position instead of requiring raw `Osi.GetPosition(...)`.
- Changed OOS spawn validation to use `SafeGetPosition(...)` first, matching the champion path more closely.
- Added a `CREATE_OOS_ONLY` follow-up for runtimes where immediate OOS probes resolve at `0.00` distance: exact-zero probes are now treated as deferred-settle candidates instead of being rejected outright.
- Made `CREATE_OOS_ONLY` fail fast without the hidden `FindValidPosition` fallback.
- Updated `EnemyAmbush_Systems_SpawnExecution.lua` and `EnemyAmbush_Systems_SpawnPipeline.lua` so an anchor failure under `CREATE_OOS_ONLY` aborts the ambush cleanly instead of continuing the stagger loop and spamming repeated placement failures.

## 2026-03-17 09:05 Fix telemetry auto-dump nil-call after Phase 2 Task 4
- Fixed a live spawn-failure regression in `EnemyAmbush_Utils_Telemetry.lua` where the friendly settings summary called `EA_TelemetrySetting` before its local helper was in scope.
- Forward-declared the helper so telemetry auto-dumps can safely read the current settings snapshot during spawn-failure reporting.

## 2026-03-17 08:45 Fix Phase 2 Task 4 regression in SpawnExecution balance-profile fallback
- Fixed a live ambush regression in `EnemyAmbush_Systems_SpawnExecution.lua` where `ExecuteAmbushSpawn` still called the removed `EA_NormalizeBalanceProfileAlias` helper.
- Switched the remaining fallback branch to use `EnemyAmbush_MCMContract.lua` normalization like the rest of the Task 4 slice.

## 2026-03-16 22:55 Implement Phase 2 Task 4 and make MCMContract the normalization-rules owner
- Added shared normalization helpers to `EnemyAmbush_MCMContract.lua` for:
  - canonical enum/numeric value resolution
  - preset/custom-preset pair coercion
  - friendly label resolution for supported enum settings
- Reduced competing normalization logic in `EnemyAmbush_Utils_Settings.lua`:
  - `EA_NormalizeMCM()` now delegates preset/custom-preset coercion to the MCM contract
  - balance/fodder/arrival/placement getters and label helpers now read contract-owned normalization/labels instead of re-implementing alias logic
  - arrival-cue chance-scale normalization now also consumes the contract
- Replaced tiny runtime alias-normalization duplicates with contract calls in:
  - `EnemyAmbush_Systems_Budget.lua`
  - `EnemyAmbush_Systems_PoolSelection.lua`
  - `EnemyAmbush_Systems_SpawnExecution.lua`
  - `EnemyAmbush_Systems_Immersion.lua`
- Left the canonical apply-path structure untouched for later Phase 2 work.

## 2026-03-16 20:20 Implement Phase 2 Tasks 1-3 for settings authority cleanup
- Removed unsupported settings JSON runtime surfaces from `EnemyAmbush_Config.lua`:
  - deleted the settings JSON mirror/import/watch workflow
  - removed startup/live settings calls to `EA_ConfigScheduleWrite(...)`
  - removed related config-watch/import exports
- Removed unsupported settings JSON debug-command surfaces from `EnemyAmbush_DebugCommands.lua`:
  - deleted `!ea_test configpoll`
  - removed readiness output tied to config import/watch policy
- Removed the startup call to `EA_ConfigStartLiveImportPolling()` from `EnemyAmbush_Systems_SpawnPipeline.lua`.
- Moved raw settings ownership toward one module:
  - `EnemyAmbush_Utils_Settings.lua` now exposes owned raw-settings helpers
  - `EnemyAmbush_Config.lua` now consumes that owner surface instead of defining a competing raw settings owner
- Updated current docs so the supported settings model is consistently MCM/server-authority only:
  - `CONFIG.md`
  - `ConsoleCommands_Reference.md`
  - `README.md`
  - `TROUBLESHOOTING.md`
  - `ARCHITECTURE.md`
  - `HUNTED_AI_AGENT_REFERENCE.md`
  - `HUNTED_RC_BETA_TEST_PLAYBOOK.md`
  - `KNOWN_ISSUES.md`
- Historical changelog entries mentioning JSON import/watch remain as history, not current supported behavior.

## 2026-03-16 19:33 Close the Phase 1 JSON settings policy and prepare the Phase 2 checklist
- Updated `healthcheck_remediation.md` to close the JSON settings decision in `MD-01`:
  - supported settings model is now explicitly MCM/server-authority only
  - live JSON watch/import is out of supported runtime behavior
  - manual JSON import is out of supported runtime behavior
  - settings JSON export/mirror is out of supported runtime behavior
- Marked Phase 1 complete in `healthcheck_remediation.md`.
- Rewrote `LP-04` so it now tracks cleanup debt and recorded the exact affected runtime, debug-command, and documentation surfaces.
- Added `phase2_settings_authority_checklist.md` as a prep checklist for `CP-01`, explicitly assuming that JSON is no longer part of the supported settings model.
- Left runtime implementation untouched in this step and did not modify `MASTERPLAN.md`.

## 2026-03-16 19:05 Reclassify the Phase 0 remediation evidence and move the roadmap back to later phases
- Updated `phase0_results.md` so it no longer reads like a pending draft:
  - folded in later live evidence from the XP follow-up work
  - reclassified `LP-03` from unresolved to contained
  - recorded that pending-ambush reload behavior is no longer treated as a missing Phase 0 blocker
- Updated `healthcheck_remediation.md` to match the current evidence state:
  - `LP-01` contained
  - `LP-02` confirmed
  - `LP-03` contained
  - `EG-01` narrowed to contained runtime risk
  - Phase 0 marked functionally complete for the remediation roadmap
  - Phase 3 / Phase 8 gate wording narrowed so later phases no longer wait on the old unresolved Phase 0 wording

## 2026-03-16 18:29 Fully remove the last legacy XP suppressor shim/export
- Deleted the final `EA_TrySuppressEntityXP()` shim from `EnemyAmbush_Utils_Core.lua`.
- Deleted the remaining legacy export from `EnemyAmbush_Utils_Exports.lua`.
- Updated `XP_SUPPRESSION_REWRITE_PLAN.md` to reflect that the old boost-based suppressor path is now fully removed from the repo and that the only remaining deferred XP-plan item is the missing-`powerClass` tier-fallback verification.

## 2026-03-16 18:18 Reduce the old XP suppressor to a deprecated compatibility shim
- Replaced the old best-effort `EA_TrySuppressEntityXP()` logic in `EnemyAmbush_Utils_Core.lua` with an explicit deprecated shim that reports `deprecated_clone_template_path` and no longer attempts stats mutation or XP-zeroing boosts.
- Removed the orphaned internal helper code that only existed to support that legacy suppressor path.
- Updated `XP_SUPPRESSION_REWRITE_PLAN.md` to record the new cleanup state:
  - live spawn/champion wiring is already gone
  - the legacy suppressor now survives only as an exported compatibility shim
  - the missing-`powerClass` tier-fallback verification is intentionally deferred for later

## 2026-03-16 18:05 Start retiring the old boost-based XP suppressor wiring
- Updated `XP_SUPPRESSION_REWRITE_PLAN.md` to add a phased cleanup track for the old `EA_TrySuppressEntityXP()` residue.
- Removed dead in-repo `EA_TrySuppressEntityXP` dependency wiring from:
  - `EnemyAmbush_Systems_SpawnPlacement.lua`
  - `EnemyAmbush_Systems_ChampionSpawn.lua`
  - `EnemyAmbush_Systems_SpawnPipeline.lua`
- Updated stale comments in `EnemyAmbush_Systems_SpawnPipeline.lua` so they no longer describe boost-only suppression as current runtime behavior.
- Kept `EA_TrySuppressEntityXP()` and its export in place as a compatibility shim because out-of-repo dependence is still **UNVERIFIED**.

## 2026-03-16 17:40 Reintroduce the removed mummy as a normal Undead veteran entry
- Added the exact former `Mummy Champion` root template (`ca08113f-5ed5-42b3-9a50-adf2c1fe6bac`) to `EnemyAmbush_Data_Summons_Vanilla.lua` as `Mummy (Veteran)`.
- The mummy stays out of `EnemyAmbush_Data_Champions_Vanilla.lua`, so it no longer occupies the built-in Undead champion slot, but it can still appear in the normal Undead summon pool at a lower reward and threat band.
- Current veteran tuning for this reintroduced mummy:
  - `spawnBand = "VETERAN"`
  - `powerClass = "BRUISER"`
  - `level = 6`
  - `resolvedTemplateLevel = 6`
  - `minPartyLevel = 7`
  - `maxPartyLevel = 16`

## 2026-03-16 17:24 Remove the mummy from the built-in Undead champion roster
- Removed `Mummy Champion` from `EnemyAmbush_Data_Champions_Vanilla.lua` so built-in Undead champion spawns no longer select the weak mummy template.
- Reason: live in-game testing showed the mummy was too passive for the current champion reward/difficulty band and did not match the intended Undead champion pressure.
- Updated `XP_SUPPRESSION_REWRITE_PLAN.md` to record that the built-in champion `Boss` payout path is now verified in game, while the missing-`powerClass` tier-fallback edge case remains the last optional XP-plan verification item.

## 2026-03-16 17:05 Sync XP docs with verified per-party manual payout behavior
- Updated `README.md`, `COMPATIBILITY.md`, `TROUBLESHOOTING.md`, `API.md`, and `XP_SUPPRESSION_REWRITE_PLAN.md` to match the shipped sub-100% XP behavior.
- Documented the currently verified runtime behavior:
  - zero-XP clone suppression for sub-100% ambush XP
  - manual payout distributed once per validated party recipient
  - built-in fallback payout driven by `powerClass` first and tier second
- Recorded the latest built-in test evidence in the XP plan:
  - `partyMembers=5`
  - `xpRecipientSource=db_players_party_filtered`
  - two kills producing `15 XP` total for each of the 5 party members

## 2026-03-16 16:22 Distribute manual ambush XP per validated recipient instead of assuming party sharing
- Changed `EnemyAmbush_Events_Diagnostics.lua` so sub-100% ambush XP no longer makes a single `AddExplorationExperience` call against one chosen target handle.
- Manual payout now resolves a validated recipient list in this order:
  - `Osi.DB_Players:Get(nil)` filtered to player handles and same-party with the anchor player when party relations can be resolved
  - guarded fallback to the existing `EA_GetPartyXPRecipients()` helper when DB-backed enumeration does not produce any valid recipients
- Manual payout still remains one logical reward per defeated ambusher, but it is now distributed by calling `AddExplorationExperience` once per validated recipient because runtime testing contradicted the earlier single-call party-sharing assumption.
- Added recipient-source and recipient-count telemetry for this phase:
  - `xpManualPayoutRecipientsDBPlayers`
  - `xpManualPayoutRecipientsFallback`
  - `xpManualPayoutNoValidRecipients`
  - `xpManualPayoutRecipientCount`
- Updated XP payout debug logs to print resolved recipient source and the exact validated recipient list instead of a single `xpTarget` handle.

## 2026-03-16 15:39 Revise the XP follow-up plan after runtime disproved single-call party sharing
- Updated `Hunted Docs/XP_SUPPRESSION_REWRITE_PLAN.md` after in-game testing showed that a single `AddExplorationExperience(target, amount)` call only awarded the targeted character in this runtime, despite the local docs describing it as party XP.
- Recorded the new verified runtime evidence:
  - clone suppression still works
  - powerClass-first fallback payout categories are working
  - the remaining blocker is payout distribution, not suppression or fallback category selection
- Narrowed the next runtime slice to explicit validated-recipient payout instead of a single host-targeted call.
- Documented local API evidence from `osiris_api_full_documentation.txt`:
  - `AddExplorationExperience` is the only locally documented XP-award call found for this use case
  - `GetHostCharacter` is documented as a debug/extreme-edge-case query and is not suitable as the basis for assumed party-wide payout behavior
- Updated the plan's next-step design to prefer `DB_Players`-backed recipient enumeration, deduplication, and same-party filtering before payout.

## 2026-03-16 15:20 Revise the XP rewrite plan around the verified clone path and remaining payout issues
- Updated `Hunted Docs/XP_SUPPRESSION_REWRITE_PLAN.md` so it no longer describes the old pre-clone failure state as the current repo baseline.
- The subsystem plan now reflects the repo's actual state after the clone suppression pass:
  - sub-100% XP uses the verified zero-XP clone path
  - manual payout still uses the fallback table
  - the remaining documented issue is payout targeting and fallback-category tuning
- Narrowed the next planned runtime work to two follow-up items only:
  - use a stable host-first target for `AddExplorationExperience`
  - switch fallback payout category selection to `powerClass` first, with tier fallback only when `powerClass` is missing or invalid
- Explicitly documented that native reward resolution is out of scope for this follow-up and no longer blocks the current approved XP work.

## 2026-03-15 20:10 Finalize queued rest ambushes once combat starts
- Fixed a staggered rest-ambush queue bug in `EnemyAmbush_Events_TimerMain.lua` where a single delayed short-rest ambush could keep its persistent `EA_SPAWNQ_*` timer alive after the first combat had already started, then resume after combat ended and spawn what looked like a second ambush wave.
- The spawn queue now detects when any already-spawned enemy from that same `ambushId` is in combat, finalizes the queued ambush immediately, and clears the pending queue timer instead of reusing it after the fight.
- This preserves the intended “one queued ambush” behavior for a rest trigger while still allowing the queue to wait if the player is unsafe for unrelated reasons before the ambush has actually engaged.

## 2026-03-15 20:35 Harden ambush XP suppression diagnostics and try entity-local zero-reward override first
- Added `EA_TrySuppressEntityXP()` in `EnemyAmbush_Utils_Core.lua` and exported it through `EnemyAmbush_Utils_Exports.lua`.
- Ambushes and champions now try a per-entity stats-component zero-reward override first (`entity_stats.CustomXPReward` / `entity_stats.XPReward` using the vanilla zero-reward row), then fall back to the previous boost chain (`ExperienceReward(0)`, `ExperienceRewardOverride(0)`, `Gain(0)`).
- Spawned ambush metadata now records `xpSuppressMethod` and `xpSuppressVerified`, and defeat-time XP logs include both so test logs can distinguish:
  - verified entity-local suppression
  - best-effort boost fallback that may still leak native kill XP on some runtimes
- This deliberately does not restore the older global stat-row mutation flow, which was retired because mutating a shared stats row can suppress XP for unrelated vanilla enemies that use the same stat entry.

## 2026-03-15 16:32 Make rest Quick Test unconditional, coalesce pending rest timers, and apply cooldown party-wide
- Changed `EA_IsQuickTestMode()` in `EnemyAmbush_Utils_Settings.lua` to treat `MCM_QuickTestMode` as a true debug override even when `AdvancedMode` is off, so effective Quick Test behavior now matches the raw toggle and rest timers use the intended debug delay/chance path.
- Added shared active-rest-timer replacement in `EnemyAmbush_Events_RestTriggers.lua` and `EnemyAmbush_Events_TimerMain.lua` so short-rest / long-rest initial timers, retries, and deferred rest timers coalesce to one pending rest flow instead of stacking multiple independent rest ambush timers.
- Added stale-rest-timer suppression so a canceled/replaced rest timer that still fires gets logged and ignored instead of triggering a second ambush.
- Changed rest cooldown handling to apply to the full party instead of only the chosen anchor character:
  - `EnemyAmbush_Systems_TriggerRestFlow.lua` now checks cooldown across party members and stamps cooldown party-wide for scripted-rest consumption and champion-rest spawns.
  - `EnemyAmbush_Systems_SpawnPipeline.lua` now stamps cooldown for the whole party on successful ambush execution.
- Fixed `EA_SCN_BEACH_WAKEUP` eligibility in `EnemyAmbush_Scenarios.lua` so the short-rest scripted-scenario path now also respects the beach bootstrap done state and the skip-tutorial toggle, instead of relying only on scripted-scenario completion sync.
- Clarified `EnemyAmbush_Events_Diagnostics.lua` XP debug output so it reports `partyMembers`, `xpTarget`, and `partyShared=true` instead of implying one manual XP award per recipient.

## 2026-03-15 16:15 Fix missing chance-multiplier seam in rest pressure path
- Fixed a runtime seam in `EnemyAmbush_Utils_StateTime.lua` where `EA_AddAmbushPressure()` called `EA_GetChanceMultiplier` as a global even though the helper only existed as a local settings-runtime function.
- Exported `EA_GetChanceMultiplier` through `EnemyAmbush_Utils_Exports.lua`.
- Changed `EA_AddAmbushPressure()` to use a guarded seam-safe resolver with a `1.0` fallback instead of crashing the rest-timer path when the global is absent.

## 2026-03-15 16:10 Change Quick Test rest scheduling to 10 seconds
- Changed Quick Test rest scheduling in `EnemyAmbush_Events_RestTriggers.lua` to use a fixed `10s` initial delay for both short-rest and long-rest timers instead of immediate `0s` scheduling.
- Purpose: make pending rest timers easy to save/reload against during debugging and Phase 0 / readiness validation.
- This does not change the existing Quick Test retry cadence in `EnemyAmbush_Events_TimerMain.lua`; only the initial rest schedule delay changed.

## 2026-03-15 16:02 Fix rest timer character parsing for party ids with underscores
- Fixed short-rest / long-rest timer parsing in `EnemyAmbush_Events_TimerMain.lua`.
- Root cause: rest timer handlers parsed character ids with `([%w%-]+)`, which failed for normal party ids such as `S_Player_Astarion_...` because they contain underscores.
- Changed rest timer parsing to capture the full character id up to the final monotonic suffix instead of silently failing the timer branch.
- Added an explicit rest-flow log when a rest timer prefix matches but the character parse still fails, so this class of issue is visible immediately in logs instead of appearing as a silent no-op.

## 2026-03-15 15:18 Add bugbear root coverage and tighten `EnterCombatFailed` Phase 0 signal
- Added `3065382b-a148-4294-b1e9-1a34875db3ba` `Bugbear (Male)` to the common level-3 ambush pool in `EnemyAmbush_Data_Summons_Vanilla.lua` so local bugbear story kills can classify through the tracked root-template model instead of staying untracked.
- Tightened the main `EnterCombatFailed` Phase 0 metric in `EnemyAmbush_Events_CombatFlow.lua` so `listenerExec.EnterCombatFailed` now increments only for ambush-owned failures after the spawned-enemy check, instead of counting unrelated scripted/story encounter failures globally.
- Added narrow ignore counters for the filtered cases:
  - `enterCombat.ignoredNonPlayerPair`
  - `enterCombat.ignoredNonAmbush`
  - `enterCombat.ignoredDeferredJoin`
- Moved the debug `EnterCombatFailed` print behind the same ambush-owned gate so normal story encounters stop flooding debug logs with non-Hunted failures.

## 2026-03-15 15:03 Lower selected goblin-village guard roots into the common level-3 pool
- Moved four goblin-village guard roots out of the veteran level-5 bucket and into the common level-3 goblin pool in `EnemyAmbush_Data_Summons_Vanilla.lua`:
  - `69db8d35-02c6-4a5b-ac5f-719c5ade777b` `Goblin Warrior (Male)`
  - `7fa1aa7c-18a4-4946-9fe4-35e1edcdfcd8` `Goblin Warrior Tier 2 (Female)`
  - `69ce746a-c017-488d-aa2e-40f07999f0d6` `Goblin Sharp-Eye (Male)`
  - `3ac7d5f6-3125-4c75-9cb3-c2ea485129ed` `Goblin Sharp-Eye (Female)`
- These entries now sit with the earlier goblin village / checkpoint set at level 3 with `resolvedTemplateLevel = 2`, while the booyahg guard roots were left unchanged because they were already level 3.

## 2026-03-15 14:46 Normalize named root-template strings to bare UUIDs
- Fixed a follow-up issue in the local-character Phase 0 tracking path where some cached/template-resolver results arrived as named root strings such as `goblins_male_melee_<uuid>` instead of bare template UUIDs.
- Template normalization now extracts a trailing UUID from those named root strings before tracked-pool lookup, so local goblin/story-character kills can match existing summon-pool root-template entries instead of being treated as untracked.
- This keeps the strict root-template model intact; it only normalizes representation differences between runtime template strings and the summon-list UUID format.

## 2026-03-15 14:37 Guard local-template live reads on runtimes without `RootTemplate`
- Fixed a runtime crash in the new local-character Phase 0 resolver path where `ServerCharacter.Template.RootTemplate` could throw `Property does not exist: CharacterTemplate::RootTemplate` during `KilledBy` handling on some BG3SE/runtime object shapes.
- `EA_ReadEntityTemplateInfo` now reads both `RootTemplate` and `Id` through guarded `pcall` access before attempting local-template-to-root fallback, so missing properties degrade into a clean unresolved/untracked skip instead of aborting the Osiris event handler.
- This keeps the local-character tracking pass active while preserving strict-skip behavior on runtimes that do not expose `RootTemplate` directly.

## 2026-03-15 13:18 Phase 0 local-character world-reputation cache tracking
- Added a bounded runtime-only local-character template cache for Phase 0 world-reputation tracking without changing summon-pool data, persisting save data, or introducing name/stat heuristics.
- Template recovery is now cache-first for `KilledBy` / world-reputation classification:
  - authoritative priming from `EnteredLevel(_Object, _ObjectRootTemplate, _Level)`
  - opportunistic live priming from `EnteredCombat` and `AttackedBy`
  - cache-first lookup in `EA_ResolveCreatureTypeForCharacter`, then live entity root/local-template recovery, then `Osi.GetTemplate` as a last fallback
- Local story characters that resolve through tracked root templates can now classify through the existing summon list more reliably; locals that still only resolve to untracked/civilian roots remain intentionally skipped.
- Added new Phase 0 counters for the local-character path:
  - `killedBy.templateCacheHit`
  - `killedBy.templatePrime.enteredLevel`
  - `killedBy.templatePrime.enteredCombat`
  - `killedBy.templatePrime.attackedBy`
  - `killedBy.templateResolve.liveRoot`
  - `killedBy.templateResolve.liveLocalToRoot`
  - `killedBy.templateResolve.osi`
  - `killedBy.templateResolvedButUntracked`
  - `killedBy.templateStillUnresolved`
- Session load now resets the runtime local-template cache so the new tracking stays ephemeral and does not add save-state churn.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1`

## 2026-03-15 12:04 Region watch default cleanup and backlog capture
- Raised the default `!ea_test regionwatch` interval from `1s` to `30s` in `EnemyAmbush_DebugCommands.lua` so the command is usable in normal field testing without constant log spam unless a shorter interval is explicitly requested.
- Updated console-command docs to match the trigger-safe-zone region output and the new `30s` default watch interval.
- Recorded two explicit follow-up items in `MASTERPLAN.md`:
  - expand curated trigger-safe-zone coverage for more protected hubs/interiors and source stable trigger UUIDs for places such as Friendly Arm Inn
  - remove raw-region fallback blocks where they can be cleanly replaced by canonical-region or trigger-safe-zone coverage
  - revisit local-character world-reputation tracking through cache-based root-template recovery instead of adding encounter-local ids or name heuristics

## 2026-03-15 11:22 Finish trigger-based hub safe-zone integration
- Completed the trigger-safe-zone implementation that had only been partially wired:
  - exported the new region/safe-zone helpers from `EnemyAmbush_Utils_Exports.lua`
  - added `EnteredTrigger` / `LeftTrigger` listener registration in `EnemyAmbush_Events.lua`
  - session load now rebuilds safe-zone trigger registration through `TriggerRegisterForPlayers`, so current players are tracked against curated hub triggers after loading in
- Ambush safety now short-circuits on active blocked trigger safe zones before the older raw/canonical region checks:
  - `IsSafeToSpawnAmbush` in `EnemyAmbush_Systems_SpawnPipeline.lua` now consults trigger-safe-zone state and reports the active blocked zone labels
  - `ExecuteAmbushSpawn` in `EnemyAmbush_Systems_SpawnExecution.lua` now re-checks the same trigger-safe-zone state before a queued spawn resolves
- `!ea_test region` / `!ea_test getregion` and `regionwatch` now report the effective safety state instead of the misleading `GetLevel` field:
  - removed the bogus `levelName=<character level>` output
  - added `activeSafeZones` and `triggerBlocked`
  - `regionwatch` now fires on trigger safe-zone changes as well as raw/canonical region changes
- Trigger-safe-zone seed coverage in this pass:
  - Emerald Grove via curated marker-target trigger UUIDs
  - Haven / Last Light via curated marker-target trigger UUIDs
  - Friendly Arm Inn remains on raw-region fallback only until stable trigger UUIDs are sourced
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK)

## 2026-03-14 19:16 Fix raw-Osiris position spawn regression and extend Phase 0 instrumentation
- Fixed a live spawn-placement regression in raw-Osiris-limited runtimes:
  - `SafeGetPosition` now falls back to Script Extender entity-component position sources when `Osi.GetPosition` is unavailable or unusable
  - `AUTO` placement now disables `CreateOutOfSightAtDirection` for a spawn if raw `Osi.GetPosition(player)` is not usable, and the probe-validation path now uses raw Osiris positions only
  - this prevents the leaked neutral probe-body bug where `!ea_test spawn random` could create extra non-ambush NPCs that did not join combat or receive ambush setup
- Fixed world-reputation creature-type resolution for local-character kill events:
  - `EA_GetCharacterTemplate` in pool selection now normalizes character handles before `Ext.Entity.Get` / `Osi.GetTemplate` lookup instead of querying with the raw `S_CHA_*_<uuid>` string only
  - local encounter characters that still resolve only through generic civilian roots remain intentionally untracked for world-reputation purposes; those kills are skipped instead of being reclassified through name-based fallbacks
  - this keeps summon data and world-reputation classification rooted in tracked root templates rather than adding level-specific local-character ids or broad string heuristics
- Improved region debug output for Norbyte lookup workflows:
  - `!ea_test region` now prints the raw `GetRegion` value plus the separate `GetLevel` result, instead of mislabeling `GetRegion` as a sublevel name
  - added `!ea_test getregion` as an alias
  - trimmed the command back to tester-facing output only and renamed the safety field to `ambushAllowed` so it is clear that `true` means ambushes are allowed there, not protected
- Improved strict local-character world-reputation resolution without name heuristics:
  - `EA_GetCharacterTemplate` now falls back from a local actor's `ServerCharacter.Template.Id` to `Ext.Template.GetRootTemplate(localTemplateId)` before giving up
  - this lets local story actors classify through their real tracked root template when the runtime does not provide `RootTemplate` directly at kill time
  - if a local actor still only resolves to an untracked local/civilian-root chain, it remains intentionally skipped for world reputation
- Extended Phase 0 instrumentation without changing gameplay behavior:
  - added `KilledBy` / world-reputation counters for event volume, early-exit reasons, accepted reputation updates, and reputation-save activity
  - added `EnterCombatFailed` retry-stage counters, pair-repeat tracking, success-after-retry counters, and teleport-rescue attempt/applied/succeeded/failed counts
  - added save/load readiness counters for ModVars readiness reasons, `EA_Vars` fallback activation/restoration, dirty-write retry behavior, pending-timer relaunch/drop counts, and startup MCM bootstrap retry scheduling
  - expanded `!ea_test phase0 show` so it now prints nested numeric Phase 0 groups instead of only the initial registration counters
  - fixed Phase 0 duplicate-registration summary scanning so nested listener-registration counters are included
  - corrected the readiness-hook wiring in early-loaded files so `phase0` readiness counters are no longer silently no-op when telemetry exports are attached later in bootstrap
  - fixed a Phase 0 counter-path collision where `listenerExec.KilledBy` was overwriting `listenerExec.KilledBy.after` and making the execution total misleading
- Field result from current solo verification:
  - `!ea_test spawn random` now uses the `FindValidPosition/CreateAt` path when raw `Osi.GetPosition` is unavailable, and the latest test run produced only the expected 3 ambushers without leaked neutral duplicates
  - Phase 0 remains in progress; this pass extends instrumentation, but does not complete the full checklist
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK)
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Config.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_DebugCommands.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Events.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_PoolSelection.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Events_CombatFlow.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_PersistenceControl.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_SpawnPlacement.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Core.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_StateTime.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Telemetry.lua`
  - `Hunted Docs/Changelog.md`

## 2026-03-10 18:02 Switched four MCM radios to plain friendly choice values with alias-safe normalization
- Replaced handle-localized radio choices with plain friendly `Choices` strings in `MCM_blueprint.json` for:
  - `MCM_BalanceProfile`
  - `MCM_FodderPolicy`
  - `MCM_ArrivalCuePolicy`
  - `MCM_SpawnPlacementMode`
- Updated the runtime contract and settings normalization so the mod still accepts:
  - legacy raw values such as `MODDED_20`, `HARD_OFF_12PLUS`, `ALWAYS_ON`, and `FIND_VALID_ONLY`
  - previous readable underscore aliases such as `EXTENDED_13_20` and `DISABLE_AT_12_PLUS`
  - the new friendly MCM values such as `Extended 13-20`, `Disable at 12+`, `Always On`, and `Find Valid Only`
- Canonical runtime/system behavior still resolves to the existing internal keys, so this change is UI-focused and backward-compatible.
- Removed the now-unused localization handle entries that were only supporting those four radio-choice labels.
- Updated the master plan to reflect that the current source strategy is now plain friendly MCM choices plus alias normalization, not `ChoicesHandles`.
- Validation:
  - `Get-Content Mods/Hunted_DynamicAmbushes_Revenge_System/MCM_blueprint.json -Raw | ConvertFrom-Json` succeeded.
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/MCM_blueprint.json`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/Localization/English/english.xml`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/Localization/English/english.loca.xml`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_MCMContract.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_Budget.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_Immersion.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_PoolSelection.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_SpawnExecution.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Settings.lua`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/Changelog.md`

## 2026-03-10 16:17 MCM radio-label investigation: schema-complete handle blocks for choice-localized settings
- Investigated the live MCM issue where radio settings still displayed raw enum keys such as `MODDED_20`, `HARD_OFF_12PLUS`, `BALANCED`, and `AUTO`.
- Found a concrete source-side mismatch in `MCM_blueprint.json`: the affected radio settings used `ChoicesHandles` without a `NameHandle` in the same `Handles` block.
- Updated these settings to use schema-complete `Handles` blocks with `NameHandle + ChoicesHandles`:
  - `MCM_BalanceProfile`
  - `MCM_FodderPolicy`
  - `MCM_ArrivalCuePolicy`
  - `MCM_SpawnPlacementMode`
- Added matching English localization entries for the new setting-name handles in both `english.xml` and `english.loca.xml`.
- Updated the master plan to record this as the current source-side fix while keeping live in-game verification pending until the menu is checked on a rebuilt artifact.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/MCM_blueprint.json`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/Localization/English/english.xml`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/Localization/English/english.loca.xml`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/Changelog.md`

## 2026-03-10 15:53 Low-risk hardening pass, surprise wording fix, and arrival/escape test-doc cleanup
- Hardened a few low-risk runtime seams without changing gameplay behavior:
  - `EnemyAmbush_Utils_Core.lua`: `SafeGetPosition` now guards missing `Osi` / `Osi.GetPosition` before calling into Osiris
  - `EnemyAmbush_DebugCommands.lua`: replaced raw `Osi.GetPosition(player)` usage in the `spawnhostile` and `attack` branches with `SafeGetPosition`, including nil-coordinate guards
  - `EnemyAmbush_Systems_PoolSelection.lua`: `ValidateEnemyData` now wraps `Ext.Template.GetRootTemplate` in `pcall`, and the weighted-cache TTL path now uses `CACHE_DURATION` instead of a duplicated literal
- Fixed the user-facing surprise wording in `MCM_blueprint.json` so `MCM_ApplyPartySurprised` describes the real Perception-gated surprise flow rather than implying unconditional surprise.
- Updated docs/tooling to match the current runtime and testing workflow:
  - `ARCHITECTURE.md`: bootstrap order now includes the `EnemyAmbush_RNG.lua` preload before `EnemyAmbush_API.lua`
  - `ConsoleCommands_Reference.md`: added explicit `arrivalpreview`, `escapepreview`, and `escapetune` examples plus notes explaining why default escape often shows nothing in short fights
  - `HUNTED_RC_BETA_TEST_PLAYBOOK.md`: added arrival/escape cue test recipes, clarified that BG3SE-only and co-op remain unverified until release validation, and documented the current field-debug expectations
  - `HUNTED_MODPACK_HANDOFF_GUIDE.md`: softened BG3MCM-free wording to match the actual current verification state
  - `Run-HuntedStaticChecks.ps1`: step labels now match the actual number of phases
  - `MASTERPLAN.md`: marked the low-risk hardening/docs slice as implemented and recorded the confirmed future escape-design choice that one successful party member would block an ambusher escape if that redesign is promoted later
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_DebugCommands.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_PoolSelection.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Core.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/MCM_blueprint.json`
  - `Hunted Docs/ARCHITECTURE.md`
  - `Hunted Docs/ConsoleCommands_Reference.md`
  - `Hunted Docs/HUNTED_MODPACK_HANDOFF_GUIDE.md`
  - `Hunted Docs/HUNTED_RC_BETA_TEST_PLAYBOOK.md`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/Changelog.md`
  - `tools/Run-HuntedStaticChecks.ps1`

## 2026-03-09 21:36 Additive API hardening and provider lifecycle helpers
- Hardened `EnemyAmbush_API.lua` without breaking the existing flat API calls:
  - provider and champion registrations now store defensive copies instead of live caller tables
  - `GetActiveEnemyEntries()` and `GetChampionTemplate()` now return defensive snapshots instead of live mutable provider tables
  - added provider lifecycle and introspection helpers:
    - `HasEnemyProvider`, `GetEnemyProvider`, `ListEnemyProviders`, `IsEnemyProviderActive`, `UnregisterEnemyProvider`
    - `HasChampionProvider`, `GetChampionProvider`, `ListChampionProviders`, `IsChampionProviderActive`, `UnregisterChampionProvider`
  - added event lifecycle helpers `Off` and `Once`
  - added namespaced alias surface under `EnemyAmbush.API` while keeping the existing flat `EnemyAmbush.*` calls intact
  - bumped API surface version to `1.1.0`
- Updated the authoritative API docs to match the new runtime contract and return conventions.
- Aligned `EnemyAmbush_Systems_PoolSelection.lua` so its fallback `Has*Provider` helpers no longer overwrite the public API versions if they already exist.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_API.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_PoolSelection.lua`
  - `Hunted Docs/API.md`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/Changelog.md`

## 2026-03-09 21:08 Plan-doc cleanup: removed superseded `0309*` plans
- Removed these obsolete plan files from `Hunted Docs` so `MASTERPLAN.md` is the only live plan:
  - `0309 PLAN.md`
  - `03091202PLAN.md`
  - `03091213PLAN.md`
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Hunted Docs/0309 PLAN.md`
  - `Hunted Docs/03091202PLAN.md`
  - `Hunted Docs/03091213PLAN.md`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/Changelog.md`

## 2026-03-09 21:00 Deferred support cohesion window and catch-up retry cleanup
- Updated deferred support combat cohesion across `EnemyAmbush_Events_CombatFlow.lua` and `EnemyAmbush_Utils_HostilityRegion.lua`:
  - registers a per-`ambushId` join window when combat starts
  - keeps a `6s` cohesion grace window from the first join attempt
  - adds tolerance over the old `12m` in-combat catch-up boundary
  - allows forced catch-up join up to `35m` while that grace window is active
- Removed the old ambush-wide deferred-support join suppression so partial joins no longer block the rest of the wave from catching up.
- De-duplicated repeated deferred-support join logs and retry spam by `ambushId + combatId`.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Events.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Events_CombatFlow.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_HostilityRegion.lua`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/Changelog.md`

## 2026-03-09 20:30 Low-level spike gating, template ceilings, and stable party-size reads
- Updated `EnemyAmbush_Systems_SpawnPipeline.lua` low-level overlevel-delta behavior:
  - levels `1-3`: always `delta = 0`
  - level `4`, party size `<= 2`: `delta = 0`
  - level `4`, party size `>= 3`: `10%` chance of `delta = 1`
  - levels `5+`: existing delta curve unchanged
- Updated `EnemyAmbush_Systems_PoolSelection.lua` to apply low-level template ceilings before weighted selection:
  - level `1`: max template level `2`
  - level `2`: max template level `3`
  - level `3`: max template level `4`
  - level `4`: max template level `5`
- Updated the pipeline party-size read path so a `<= 1` result immediately re-probes twice and keeps the max sample without changing the cache TTL structure.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_SpawnPipeline.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_PoolSelection.lua`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/Changelog.md`

## 2026-03-09 17:23 Soft party-match spawn targets and early composition update
- Replaced the old fixed minimum-target rules in `EnemyAmbush_Systems_SpawnExecution.lua` with a soft party-match target:
  - `target = partySize + tierAdjustment`
  - `COMMON = 0`
  - `VETERAN = -1`
  - `ELITE = -1`
  - `LEGENDARY = -2`
  - `CHAMPION = -2`
- Target now clamps to `[2, cap]`, and levels `2-4` with party size `>= 3` still force a minimum target of `3`.
- Updated early composition limits:
  - levels `1-2`: `nonFodderMax = 1`
  - levels `3-4`: `nonFodderMax = 2` when party size `>= 3`, otherwise `1`
- Added explicit below-target stop reasons so short waves report whether they ended because the payload invalidated or the hard attempt ceiling was reached.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_SpawnExecution.lua`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/Changelog.md`

## 2026-03-09 16:48 Timer seam fix for despawn logging
- Wired `EA_ShouldLogDespawn` into the timer runtime dependency set so `EnemyAmbush_Events_TimerMain.lua` no longer depends on an unsafe implicit scope capture.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Events.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Events_TimerMain.lua`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/Changelog.md`

## 2026-03-09 16:34 Placement mode controls and CreateOutOfSight diagnostics
- Added Advanced MCM control `MCM_SpawnPlacementMode` with these modes:
  - `AUTO`
  - `FIND_VALID_ONLY`
  - `CREATE_OOS_ONLY`
- `AUTO` now short-circuits to `FindValidPosition` for the rest of the current spawn sequence after repeated `CreateOutOfSightAtDirection` too-close or zero-distance rejects.
- Added placement diagnostics metrics:
  - `createOutOfSightTooCloseRejected`
  - `createOutOfSightZeroDistanceRejected`
  - `createOutOfSightAutoShortCircuit`
- Updated debug/telemetry output to report the effective spawn placement mode.
- Updated docs/counts to match the new MCM inventory (`6` tabs, `45` settings).
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/MCM_blueprint.json`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/Localization/English/english.xml`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/Localization/English/english.loca.xml`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_MCMContract.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Settings.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Exports.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Telemetry.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_DebugCommands.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_SpawnPlacement.lua`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/HUNTED_AI_AGENT_REFERENCE.md`
  - `Hunted Docs/Changelog.md`

## 2026-03-09 16:02 Arrival cue controls and diagnostics
- Added Advanced MCM controls for arrival cues:
  - `MCM_ArrivalCuePolicy`
  - `MCM_ArrivalCueChanceScale`
- Arrival cue decisions now resolve through one effective server-side path:
  - `BALANCED` uses tier chance plus the chance-scale slider
  - `ALWAYS_ON` forces cue attempts
  - `OFF` disables extra arrival cues and falls back to the baseline spawn VFX
- Quick Test mode now forces arrival cues to `ALWAYS_ON` unless the policy is explicitly `OFF`.
- Normal ambush spawns and champion spawns now respect the same arrival cue policy path.
- Added structured arrival cue debug output and new arrival cue metrics:
  - `arrivalCueRolls`
  - `arrivalCueApplied`
  - `arrivalCueSuppressedByPolicy`
  - `arrivalCueSuppressedByChance`
  - `arrivalCueProfileFallbackUsed`
- Updated docs/counts to match the new MCM inventory (`6` tabs, `44` settings).
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/MCM_blueprint.json`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/Localization/English/english.xml`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/Localization/English/english.loca.xml`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_MCMContract.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Settings.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Exports.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Telemetry.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_DebugCommands.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_Immersion.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_SpawnPlacement.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_ChampionSpawn.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Systems_SpawnPipeline.lua`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/HUNTED_AI_AGENT_REFERENCE.md`
  - `Hunted Docs/Changelog.md`

## 2026-03-09 15:12 MCM/runtime label parity and layout pass
- Reorganized the MCM blueprint into the `Presets`, `Balance Core`, `Rest & Frequency`, `Spawn & Behavior`, `Rewards`, and `Debug` tabs without changing stored setting IDs or enum values.
- Updated user-facing balance wording in the MCM blueprint so friendly labels are used for the level-range and fodder behaviors while compatibility-safe stored values remain unchanged.
- Updated `!ea_test settings` to print friendly balance/fodder names alongside the stable internal values.
- Updated debug telemetry dumps to print the same friendly balance/fodder names so logs match the current MCM wording.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/MCM_blueprint.json`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Settings.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Exports.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_DebugCommands.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Telemetry.lua`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/Changelog.md`

## 2026-03-09 14:34 Hotfix: pacifist knockout support with anti-cheese suppression
- Restored ambush reputation progression for non-lethal defeats so pacifist play and knockout-focused runs still advance creature-type retaliation.
- Added persistent defeated-spawn tracking so a spawned ambusher that was already credited on knockout cannot later grant extra world-kill reputation if the player kills the unconscious target.
- Added explicit support for `Bonk Enhanced` custom downed statuses:
  - `BONK_ENHANCED_DOWNED`
  - `BONK_ENHANCED_DOWNED_AND_OUT`
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Core.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Exports.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Events.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Events_Diagnostics.lua`
  - `Hunted Docs/Changelog.md`

## 2026-03-09 14:06 Hotfix: knockouts no longer advance ambush reputation
- Fixed spawned ambusher defeat handling so non-lethal knockouts still clean up spawned-state tracking, but no longer apply reputation loss or champion-pressure progression.
- This keeps lethal kills as the reputation authority while preserving the existing knockout cleanup path.
- Added debug/metrics visibility for skipped knockout reputation handling.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Events_Diagnostics.lua`
  - `Hunted Docs/Changelog.md`

## 2026-03-09 13:37 Release prep: docs/runtime alignment, schema gating, and cleanup
- Added the authoritative player-facing docs set in `Hunted Docs`:
  - `README.md`
  - `COMPATIBILITY.md`
  - `TROUBLESHOOTING.md`
  - `KNOWN_ISSUES.md`
  - `API.md`
  - `CONFIG.md`
  - `ARCHITECTURE.md`
- Rewrote the stale release-operation docs to match the current runtime contract:
  - `HUNTED_MODPACK_HANDOFF_GUIDE.md`
  - `HUNTED_MODPACK_ONE_PAGE.md`
  - `HUNTED_RC_BETA_TEST_PLAYBOOK.md`
  - `HUNTED_AI_AGENT_REFERENCE.md`
- Updated tooling for the current folder layout:
  - `tools/Run-HuntedStaticChecks.ps1` now resolves the real Lua/docs/localization roots by default
  - static checks now fail on stale release-doc terms and English localization drift
  - `tools/Update-HuntedChangelog.ps1` now targets the in-project `Hunted Docs/Changelog.md`
- Hardened JSON config import in `EnemyAmbush_Config.lua`:
  - reject missing `schemaVersion`
  - reject mismatched `schemaVersion`
  - reject payloads missing `settings`
  - export now writes `generatedBy = "EnemyAmbush_Config.lua"`
- Standardized the MCM blueprint to the full public mod name and clarified two player-facing settings:
  - `Use Vanilla Enemy Pool` now warns that no provider patch can mean no valid ambush pool
  - `Disable Ambush Loot` now clarifies that the corpse remains interactable and equipped gear still drops
- Synchronized the two English localization XML sources and removed the `5e Spells` / `Valkrana` strings targeted for `1.0` removal.
- Removed dead runtime files from the shipped source path:
  - `EnemyAmbush_MCMClient.lua`
  - `EnemyAmbush_Systems_Compatibility.lua`
  - `EnemyAmbush_Journal.lua`
- Marked the older `0309*` plan files as historical/superseded so `MASTERPLAN.md` is the only active implementation plan.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget OK, release-doc drift OK, localization drift OK).
- Changed files:
  - `README.md`
  - `Hunted Docs/README.md`
  - `Hunted Docs/COMPATIBILITY.md`
  - `Hunted Docs/TROUBLESHOOTING.md`
  - `Hunted Docs/KNOWN_ISSUES.md`
  - `Hunted Docs/API.md`
  - `Hunted Docs/CONFIG.md`
  - `Hunted Docs/ARCHITECTURE.md`
  - `Hunted Docs/HUNTED_MODPACK_HANDOFF_GUIDE.md`
  - `Hunted Docs/HUNTED_MODPACK_ONE_PAGE.md`
  - `Hunted Docs/HUNTED_RC_BETA_TEST_PLAYBOOK.md`
  - `Hunted Docs/HUNTED_AI_AGENT_REFERENCE.md`
  - `Hunted Docs/MASTERPLAN.md`
  - `Hunted Docs/0309 PLAN.md`
  - `Hunted Docs/03091202PLAN.md`
  - `Hunted Docs/03091213PLAN.md`
  - `Hunted Docs/Changelog.md`
  - `tools/Run-HuntedStaticChecks.ps1`
  - `tools/Update-HuntedChangelog.ps1`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/MCM_blueprint.json`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/Localization/English/english.xml`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Config.lua`
  - `Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua/EnemyAmbush_Utils_Compat.lua`

## 2026-03-04 20:03 Hotfix: prevent near-point spawn pop-ins
- Fixed spawn placement regression where `CreateOutOfSightAtDirection` used a fixed distance argument (`1`), which could place ambushers almost on top of the player.
- `CreateOutOfSightAtDirection` now uses tier/roll spawn distance (`spawnDist`) with slight jitter, matching the intended encounter spacing model.
- Added minimum 2D distance guard across all spawn paths (out-of-sight, FindValidPosition, and fallback) to reject too-close candidates before finalizing spawn.
- Added debug diagnostics for rejected candidates (`too close` vs `height delta`) so placement decisions are visible in telemetry.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPlacement.lua
  - Hunted Docs\Changelog.md

## 2026-03-04 19:54 Hotfix: rest quick-test clarity + faster rest retry path
- Fixed `!ea_test settings` effective boolean reporting to preserve real `false` values from runtime functions (Lua `and/or` fallback no longer masks quick-test cooldown disable).
- Changed quick-test runtime override to use immediate rest delay windows (`0m-0m`) for both short and long rest checks.
- Updated Quick Test Mode MCM description to match runtime behavior (immediate rest checks).
- Improved rest timer resilience in `EnemyAmbush_Events_TimerMain.lua`:
  - Added rest-timer character validation with host-character fallback if parsed timer character is no longer valid.
  - Added explicit rest-flow logs when fallback/drops occur, instead of silent no-op paths.
  - Reduced rest retry/defer cadence in Quick Test Mode to `3s` (from normal safety delay), including delayed-rest queue retries.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\MCM_blueprint.json
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_DebugCommands.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_TimerMain.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Settings.lua
  - Hunted Docs\Changelog.md

## 2026-03-04 19:45 Hotfix: radio choices show localized labels instead of raw enum tokens
- Fixed MCM radio rendering regression where raw enum values with underscores were displayed (`EXTENDED_13_20`, `DISABLE_AT_12_PLUS`, etc.).
- Restored canonical internal enum values in blueprint/settings:
  - `MCM_BalanceProfile`: `MODDED_20` / `BG3_12`
  - `MCM_FodderPolicy`: `HARD_OFF_12PLUS` / `TAPERED`
- Re-enabled proper `Handles.ChoicesHandles` for those two radios using plain contentuids (no `;1` suffix), matching BG3MCM behavior used by other mods.
- Existing alias compatibility in Lua remains, so previously saved readable aliases still resolve safely.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\MCM_blueprint.json
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Settings.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Telemetry.lua
  - Hunted Docs\Changelog.md

## 2026-03-04 19:27 MCM radio value readability + expanded `!ea_test settings` diagnostics
- Reworked the two advanced radio settings to store readable values directly in MCM:
  - `MCM_BalanceProfile`: `EXTENDED_13_20` / `VANILLA_1_12`
  - `MCM_FodderPolicy`: `DISABLE_AT_12_PLUS` / `GRADUAL_TAPER`
- Added backward-compatible enum aliases so existing saves/configs using legacy values remain valid:
  - Balance profile aliases: `MODDED_20`/`EXTENDED_13_20` and `BG3_12`/`VANILLA_1_12`
  - Fodder policy aliases: `HARD_OFF_12PLUS`/`DISABLE_AT_12_PLUS` and `TAPERED`/`GRADUAL_TAPER`
- Expanded `!ea_test settings` output to include raw + effective rest/cooldown diagnostics:
  - Rest ambush enabled, quick-test mode, short/long chance %, short/long delay windows
  - Cooldown enabled + minutes
  - Existing XP/loot/champion-loot effective/raw lines kept
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\MCM_blueprint.json
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_DebugCommands.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_MCMContract.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_Budget.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_PoolSelection.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnExecution.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Settings.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Telemetry.lua
  - Hunted Docs\Changelog.md

## 2026-03-04 19:13 MCM balance labels cleanup (human-readable radio options)
- Fixed UX issue where raw enum keys were shown in MCM (`MODDED_20`, `BG3_12`, `HARD_OFF_12PLUS`, `TAPERED`).
- Kept internal values unchanged for compatibility, but added localized `ChoicesHandles` labels in MCM:
  - `MCM_BalanceProfile`: Extended 13-20 / Vanilla 1-12
  - `MCM_FodderPolicy`: Disable at Level 12+ / Gradual taper
- Improved descriptions for both settings to clarify intent and progression impact.
- Added matching localization entries in both English localization files.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\MCM_blueprint.json
  - Mods\Hunted_DynamicAmbushes_Revenge_System\Localization\English\english.xml
  - Mods\Hunted_DynamicAmbushes_Revenge_System\Localization\English\english.loca.xml
  - Hunted Docs\Changelog.md

## 2026-03-04 19:04 MCM UX/runtime wiring: presets tab split + rest chance/delay controls
- Implemented the planned MCM split and runtime wiring for tester-focused rest tuning:
  - Presets moved to a dedicated tab and Balance controls grouped into a separate tab.
  - Added advanced Balance controls:
    - `MCM_AmbushChanceShortPct`, `MCM_AmbushChanceLongPct`
    - `MCM_ShortRestDelayMinMinutes`, `MCM_ShortRestDelayMaxMinutes`
    - `MCM_LongRestDelayMinMinutes`, `MCM_LongRestDelayMaxMinutes`
    - `MCM_QuickTestMode`
- Updated MCM contract and preset baselines so the new controls sanitize correctly and preset reapply remains authoritative when Advanced Mode is OFF.
- Wired settings runtime behavior:
  - `EA_GetRestAmbushChance` now honors advanced chance sliders and quick-test override (100%).
  - `EA_GetRestDelayWindowMinutes` added; `Events_RestTriggers` now reads per-rest delay windows at runtime.
  - `EA_GetCooldownEnabled`/`EA_GetCooldownMinutes` now honor quick-test override (cooldown off / 0).
- Extended telemetry state dump with quick-test/chance/delay setting visibility.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\MCM_blueprint.json
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_MCMContract.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Settings.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Exports.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_RestTriggers.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Telemetry.lua
  - Hunted Docs\Changelog.md

## 2026-03-04 18:11 Budget pre-roll party-size cache undercount guard
- Addressed intermittent pre-roll `partySize=1` undercount during early timing when actual party has companions.
- `SpawnPipeline` party-member cache now avoids reusing a fresh single-member cached snapshot when `DB_PartyMembers` is available, forcing a refresh probe to align budget pre-roll with runtime execution party size.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua
  - Hunted Docs\Changelog.md

## 2026-03-04 18:04 Follow-up hotfix: budget party-size callable fallback
- Corrected budget module dependency fallback introduced during seam hotfix:
  - `SpawnPipeline` now passes a dynamic `GetPartySize` resolver callable into `Systems_Budget` that prefers `EA["GetPartySize"]`, then runtime `GetPartySize`, then falls back to `4`.
  - Prevents startup seam failure without forcing pre-roll budget scaling to `partySize=1`.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua
  - Hunted Docs\Changelog.md

## 2026-03-04 17:56 Hotfix: delayed ambush timers not spawning after F23 slice
- Fixed `EventsTimerFlow` runtime build failure that blocked delayed ambush execution:
  - Added missing `EA_Pending` dependency in `Events_TimerMain -> EventsTimerFlow` build deps.
  - This restored runtime-ready requeue behavior for `EA_AMBUSH_DELAYED_*` timers.
- Fixed startup seam warning for budget runtime deps:
  - `SpawnPipeline` now passes a safe callable fallback for `GetPartySize` into `Systems_Budget` build deps.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_TimerMain.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua
  - Hunted Docs\Changelog.md

## 2026-03-04 17:43 F23 first-pass constants extraction (rest/timer path)
- Centralized rest/timer tuning literals in `EnemyAmbush_Systems_DataTables.lua`:
  - `REST_DEFAULTS`
  - `TRIGGER_REST_DEFAULTS`
  - `TIMER_PREFIXES`
- Rewired split runtime consumers to use shared constants instead of scattered literals:
  - `EnemyAmbush_Systems_TriggerRestFlow.lua`
  - `EnemyAmbush_Systems_SpawnPipeline.lua`
  - `EnemyAmbush_Events.lua`
  - `EnemyAmbush_Events_TimerMain.lua`
  - `EnemyAmbush_Events_TimerFlow.lua`
  - `EnemyAmbush_Events_TimerRouter.lua`
- `Events_TimerMain` now uses shared timer-prefix constants with a prefix helper, removing hardcoded `string.sub(..., 1, N)` prefix-length checks in the main timer dispatcher.
- No behavior-targeted tuning changes were introduced; this slice is authority-path cleanup only.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, local-budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_DataTables.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_TriggerRestFlow.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_TimerMain.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_TimerFlow.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_TimerRouter.lua
  - Hunted Docs\feedback 0304 1235 triage plan.md
  - Hunted Docs\Changelog.md

## 2026-03-04 17:09 Reverted ownership-risk summon filtering by user request
- Reverted the runtime ownership-risk curation filter in `EnemyAmbush_Data.lua`.
- Summon pool curation now only merges exact duplicate profiles (weight fold) and does **not** auto-filter wildshape/companion/familiar/conjured/summon-tag entries.
- Kept duplicate-weight diagnostics from F13 unchanged.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Data.lua
  - Hunted Docs\feedback 0304 1235 triage plan.md
  - Hunted Docs\Changelog.md

## 2026-03-04 16:47 P1 slice implemented (F17 RNG fallback hardening)
- Added canonical RNG-safe helpers in `EnemyAmbush_Utils_Core.lua`:
  - `EA_RandIntSafe(min, max)`
  - `EA_RandFloatSafe()`
  - helpers auto-load `EnemyAmbush_RNG.lua` when needed and fall back to deterministic local LCG only as last resort.
- Refactored split runtime modules to use RNG-safe authority fallbacks before any local fallback logic:
  - `EnemyAmbush_Events.lua`
  - `EnemyAmbush_Events_CombatFlow.lua`
  - `EnemyAmbush_Events_CombatTurnFlow.lua`
  - `EnemyAmbush_Events_RestTriggers.lua`
  - `EnemyAmbush_Events_TimerMain.lua`
  - `EnemyAmbush_Systems_ChampionSpawn.lua`
  - `EnemyAmbush_Systems_EffectsDB.lua`
  - `EnemyAmbush_Systems_Immersion.lua`
  - `EnemyAmbush_Systems_PoolSelection.lua`
  - `EnemyAmbush_Systems_TierPackages.lua`
  - `EnemyAmbush_Systems_TriggerRestFlow.lua`
- Runtime result: direct `math.random` usage has been removed from gameplay runtime paths; only debug tooling still uses it.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Core.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_CombatFlow.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_CombatTurnFlow.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_RestTriggers.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_TimerMain.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_ChampionSpawn.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_EffectsDB.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_Immersion.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_PoolSelection.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_TierPackages.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_TriggerRestFlow.lua
  - Hunted Docs\feedback 0304 1235 triage plan.md
  - Hunted Docs\Changelog.md

## 2026-03-04 16:38 P1 slice implemented (F26 summon-template ownership-risk curation)
- Added ownership-risk detection in summon data curation (`EnemyAmbush_Data.lua`) for entries likely tied to summon/wildshape ownership behavior:
  - ranger companion markers (`RANGERS_COMPANION*`, companion naming)
  - wildshape markers (`wild shape`, `wildshape`)
  - familiar/conjured/summon-tag naming markers
- Active summon pool now excludes those flagged entries during curation, reducing problematic summon-root spawns that can ignore normal ownership/faction expectations.
- Extended startup data audit with ownership-risk filter telemetry:
  - filtered count summary
  - per-reason breakdown
  - verbose mode sample lines for quick investigation
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Data.lua
  - Hunted Docs\feedback 0304 1235 triage plan.md
  - Hunted Docs\Changelog.md

## 2026-03-04 16:35 P1 slice implemented (F21 MCM contract authority-path reduction)
- Added shared contract sanitization API in `EnemyAmbush_MCMContract.lua`:
  - `SanitizeValue(settingId, value, fallback)`
  - `IsKnownId(settingId)` and `IsBasePreset(key)` helpers
  - centralized numeric/enum normalization rules (including `MCM_CustomBasePreset`)
- Refactored `EnemyAmbush_Config.lua` synced-setting sanitize path to use `MCMContract.SanitizeValue` instead of duplicated local numeric/enum handling.
- Refactored `EnemyAmbush_Utils_Settings.lua` normalization to route numeric/enum clamps through the same contract authority path.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_MCMContract.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Config.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Settings.lua
  - Hunted Docs\feedback 0304 1235 triage plan.md
  - Hunted Docs\Changelog.md

## 2026-03-04 16:30 P1 slice implemented (F13 duplicate template weighting curation)
- Added summon-data curation pass in `EnemyAmbush_Data.lua`:
  - exact duplicate summon profiles are merged at load time
  - merged entries fold `weight` into a single canonical row
  - exported curation counters (`SummonCuratedMergeCount`, `SummonCuratedMergeWeight`) added for audit visibility
- Extended startup data audit diagnostics:
  - duplicate-template weight concentration summary added (`templates`, `totalWeight`, max-share template)
  - warning emitted when duplicate templates exceed high-share threshold (5%)
  - optional verbose mode now prints top duplicate-weight rows
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, budget check OK).
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Data.lua
  - Hunted Docs\feedback 0304 1235 triage plan.md
  - Hunted Docs\Changelog.md

## 2026-03-04 16:13 P1 slice implemented (F06 bool coercion authority cleanup)
- Added canonical bool-coercion adapter in `EnemyAmbush_Utils_Core.lua`:
  - `EA_ToBoolSafe` (routes through `EA_ToBool`, then `MCMContract.ToBool`, with strict final fallback).
- Consolidated bool conversion callsites to authority path:
  - `EnemyAmbush_API.lua` now routes local bool conversion through `EA_ToBoolSafe`.
  - `EnemyAmbush_Config.lua` `EA_ToBoolCompat` now delegates to `EA_ToBoolSafe`/`MCMContract.ToBool` instead of custom parsing branches.
  - `EnemyAmbush_Events.lua` and `EnemyAmbush_Events_RestTriggers.lua` now prefer `EA_ToBoolSafe` for setting bool coercion.
  - `EnemyAmbush_Systems_SpawnPipeline.lua` `EA_GetSettingBool` now uses `EA_ToBoolSafe`.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, budget check OK).
  - `tools/Check-LuaLocalBudget.py --lua-root Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua` passed.
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Core.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_API.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Config.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_RestTriggers.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua
  - Hunted Docs\feedback 0304 1235 triage plan.md
  - Hunted Docs\Changelog.md

## 2026-03-04 15:58 P1 slice implemented (F05 utility authority-path consolidation)
- Added centralized utility authority helpers in `EnemyAmbush_Utils_Core.lua`:
  - `EA_BuildRuntimeWithDeps` (shared runtime builder)
  - `EA_GetNowMsSafe` / `EA_GetPersistedNowMsSafe` (canonical time fallback chain)
  - `EA_NormalizeUUIDSafe` (canonical UUID normalization fallback chain)
- Refactored `EnemyAmbush_Systems_SpawnPipeline.lua` to consume canonical helpers instead of duplicated local fallback logic:
  - UUID normalization now routes through `EA_NormalizeUUIDSafe`.
  - runtime `now` resolution now routes through `EA_GetNowMsSafe`.
  - party-cache clock helper now uses the canonical runtime `EA_NowMs` wrapper directly.
  - runtime module build helper now reuses shared `EA_BuildRuntimeWithDeps` (with local fallback only if unavailable).
- Refactored `EnemyAmbush_Events.lua` and `EnemyAmbush_Events_TimerMain.lua` to reuse the shared runtime builder authority path.
- `Events -> TimerMain` dependency wiring now explicitly passes shared builder/time-safe helpers.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, budget check OK).
  - `tools/Check-LuaLocalBudget.py --lua-root Mods/Hunted_DynamicAmbushes_Revenge_System/ScriptExtender/Lua` passed.
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Core.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_TimerMain.lua
  - Hunted Docs\feedback 0304 1235 triage plan.md
  - Hunted Docs\Changelog.md

## 2026-03-04 14:10 P0 triage slice implemented (F04/F08/F01/F07/F10/F15)
- Implemented build-contract validation for runtime module composition:
  - Added `EA_ValidateBuildDeps` (schema-based deps validator) in utils core.
  - Wrapped `Build(deps)` callsites in `Events`, `Events_TimerMain`, and `SpawnPipeline` with validated + protected build helper.
- Unified time-source fallbacks in active runtime paths:
  - `Events` and `SpawnPipeline` now fall back to canonical `EA_NowMs` / `EA_PersistedNowMs` chain.
  - Removed divergent monotonic-only fallback for despawn/party-cache/stats clocks.
- Fixed manual XP payout multiplication:
  - Defeat payout now grants once to a single validated player recipient (with closest-alive fallback), instead of looping all recipients.
- Completed staged global-helper cleanup:
  - Localized `SafeOsiCall`, `SafeOsiExec`, `SafeAddBoosts`, `SafeGetPosition`, `GetTableSize`.
  - Added temporary compatibility forwarders with one-time deprecation warnings in new `EnemyAmbush_Utils_Compat.lua`.
- Added startup template audit mode:
  - New debug-gated startup template existence check (`MCM_DebugMode` only) with concise summary + sampled details.
- Hardened MCM preset reassertion behavior:
  - Advanced ON/OFF transitions now reapply preset baselines when appropriate.
  - Added rapid duplicate-save suppression window to guard BG3MCM double-fire on fast UI interaction.
- Validation:
  - `tools/Run-HuntedStaticChecks.ps1` passed (`AST OK`, budget check OK).
  - `tools/Check-LuaLocalBudget.py --lua-root ...` passed.
- Changed files:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Core.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Exports.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Compat.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_TimerMain.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_Diagnostics.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Config.lua
  - Hunted Docs\feedback 0304 1235 triage plan.md

## 2026-03-04 13:06 Feedback plan revision: execution hardening notes integrated
- Incorporated additional reviewer feedback into the disposition plan.
- Added reopen criteria and safeguards:
  - F03 now explicitly tied to continuous local-budget checks.
  - F09 now re-opens immediately on any neutral-ambusher report.
  - F11 now includes future deprecation-cleanup note.
  - F22 now keeps rejection but tracks optional debug-gated seam verbosity.
- Reordered P0 execution to: `F04 -> F08 -> F01 -> F07 -> F10 -> F15`.
- Added execution-specific details:
  - F07 shim location and forwarder strategy.
  - F10 startup audit gate bound to `MCM_DebugMode`.
  - F15 repeatable MCM transition test matrix.
  - F02 explicit defer rule if unreproducible after bounded attempts.
  - Rollback note for P0 slice.
- Changed files:
  - Hunted Docs\feedback 0304 1235 triage plan.md

## 2026-03-04 13:05 Feedback plan revision: full disposition matrix
- Re-audited `feedback 0304 1235.txt` and mapped major points to explicit statuses (`FIX_NOW`, `FIX_LATER`, `DEFER`, `DONE`, `OUTDATED`, `REJECT`).
- Updated implementation queue to prioritize high-impact correctness/stability items first.
- Applied user deferrals:
  - Skeletal Dragon removal deferred pending targeted in-game summon repro.
  - Named NPC summon pool removal deferred for now.
- Changed files:
  - Hunted Docs\feedback 0304 1235 triage plan.md

## 2026-03-04 12:46 Changelog watcher removed + feedback audit kickoff
- Disabled automatic changelog watcher flow entirely.
- Stopped running watcher process and removed watcher scripts/state/log artifacts.
- Switched to manual changelog updates after each task.
- Audited `feedback 0304 1235.txt` against current code/logs to prepare targeted optimization plan (no gameplay code changes in this task).
- Changed files:
  - Hunted_DynamicAmbushes_Revenge_System\tools\Start-HuntedChangelogWatcher.ps1 (removed)
  - Hunted_DynamicAmbushes_Revenge_System\tools\Set-HuntedChangelogWatcher.ps1 (removed)
  - Hunted_DynamicAmbushes_Revenge_System\tools\.changelog-state.json (removed)
  - Hunted_DynamicAmbushes_Revenge_System\tools\.changelog-watcher.json (removed)
  - Hunted_DynamicAmbushes_Revenge_System\tools\.changelog-watcher.pid (removed)
  - Hunted_DynamicAmbushes_Revenge_System\tools\.watcher-logs\* (removed)
  - Hunted_DynamicAmbushes_Revenge_System\tools\Update-HuntedChangelog.ps1 (default wording switched to manual)
  - Hunted Docs\feedback 0304 1235 triage plan.md (added)

## 2026-03-04 12:03 Status-driven immersion cues on ambushers
- Automated changelog entry.
- Changed files since 2026-03-04 10:35 UTC:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_EffectsDB.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_Immersion.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPlacement.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_CombatFlow.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_ChampionSpawn.lua

## 2026-03-04 11:35 EffectsDB immersion cutover + UI notification defaults
- Automated changelog entry.
- Changed files since 2026-03-04 10:25 UTC:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_EffectsDB.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_Immersion.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPlacement.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_CombatFlow.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_ChampionSpawn.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Data.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Events_Diagnostics.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua

## 2026-03-04 11:25 Watcher Update
- Watcher batch: 2 fs events under ScriptExtender\\Lua.
- Auto-generated from filesystem watcher.
- Changed files since 2026-03-04 08:03 UTC:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_MCMContract.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Utils_Settings.lua

## 2026-03-03 18:02 Balance: Lock Level-2 Random Ambush Tier to COMMON
- Adjusted Trigger/Rest tier safety so party level <=2 always downgrades random ambush tier to COMMON (independent of party size).,Prevents early VETERAN outliers like Shadow Mastiff for level-2 parties.
- Changed files since 2026-03-03 16:40 UTC:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_TriggerRestFlow.lua

## 2026-03-03 17:40 Watcher Update
- Watcher batch: 1 fs events under ScriptExtender\\Lua.
- Auto-generated from filesystem watcher.
- Changed files since 2026-03-03 16:37 UTC:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems.lua

## 2026-03-03 17:36 1.0 Extraction Slice - Trigger/Rest Flow
- Extracted TriggerAmbush rest execution path from SpawnPipeline into EnemyAmbush_Systems_TriggerRestFlow.lua.
- SpawnPipeline now delegates TriggerAmbush via TriggerRestFlow runtime with seam-safe fallback.
- Changed files since 2026-03-03 15:49 UTC:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_TriggerRestFlow.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems.lua

## 2026-03-03 16:49 Balance: Delay Flaming Fist in Early Game
- Raised Flaming Fist common variants minPartyLevel from 1 to 4 to avoid level-2 spikes.
- Raised Flaming Fist defender/protector variants minPartyLevel from 2 to 5.
- Changed files since 2026-03-03 15:30 UTC:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Data_Summons_Vanilla.lua

## 2026-03-03 16:30 1.0 Extraction Slice - Champion Spawn Branch
- Extracted champion spawn logic from SpawnPipeline into EnemyAmbush_Systems_ChampionSpawn.lua.
- SpawnPipeline now delegates SpawnChampionNow/SpawnChampionIfNeeded to ChampionSpawn runtime.
- Systems loader load-order updated to include ChampionSpawn module.
- Changed files since 2026-03-03 15:22 UTC:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_ChampionSpawn.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems.lua

## 2026-03-03 16:22 1.0 API Surface Cleanup
- Removed legacy _G.EA_API_QUEUE compatibility path.
- Providers now require direct EA.Register* calls (clean-break contract).
- Changed files since 2026-03-03 14:26 UTC:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_API.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Data.lua

## 2026-03-03 15:26 1.0 Extraction Slice - Surprise Branch
- Extracted surprise/perception logic into EnemyAmbush_Systems_Surprise.lua; SpawnPipeline now consumes runtime and seam validation covers surprise handlers.
- Changed files since 2026-03-03 14:12 UTC:
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_SpawnPipeline.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems_Surprise.lua
  - Mods\Hunted_DynamicAmbushes_Revenge_System\ScriptExtender\Lua\EnemyAmbush_Systems.lua

## 2026-03-03 15:12 Watcher Update
- Auto-generated from filesystem watcher.
- Changed files since 2026-03-03 14:09 UTC:
  - tools\Update-HuntedChangelog.ps1
  - tools\Start-HuntedChangelogWatcher.ps1

## 2026-03-03 14:54 Watcher Bootstrap
- Enabled background watcher for auto-changelog updates.
- Changed files since 2026-03-03 13:48 UTC:
  - tools\Start-HuntedChangelogWatcher.ps1
  - tools\Set-HuntedChangelogWatcher.ps1
  - tools\.changelog-watcher.pid

## 2026-03-03 1.0 Continuation (Events Branch Split + Systems Extractions + Data Safety)
- Added events branch split modules and wired seam contracts end-to-end:
  - `EnemyAmbush_Events_TimerFlow.lua`
  - `EnemyAmbush_Events_ScenarioBootstrap.lua`
  - `EnemyAmbush_Events_CombatFlow.lua`
  - `EnemyAmbush_Events_Diagnostics.lua`
  - `EnemyAmbush_Events_TimerMain.lua`
  - `EnemyAmbush_Events_CombatTurnFlow.lua`
- Changed: `EnemyAmbush_Events.lua` now operates as orchestrator/router with branch contracts validated at load (`timer-router`, `timer-flow`, `scenario-bootstrap`, `combat-flow`, `diagnostics`, `timer-main`).
- Fixed: hostility target resolution runtime error path observed in combat kick flow (`EntityProxy ... Characters`) is no longer present in smoke runs; hostility settle/join sequence now completes without Lua dispatch errors in tested traces.
- Changed early-game guardrails and fairness behavior:
  - enforced low-level small-party spawn cap + template-level cap behavior in execution path,
  - ensured min-enemy targeting respects active cap,
  - added fodder swarm compensation so ultra-weak anchor rolls can raise encounter count (e.g. 2 -> 3) instead of producing trivial 1-HP style duos.
- Data curation updates:
  - moved `Needle Blight` to late-game availability (`minPartyLevel = 12`) to prevent early OP spikes,
  - removed familiar-only beast entries from random ambush pool (while keeping normal rat entries),
  - removed broken Undead Skeletal Dragon champion entry (`80db81be-27d4-42a8-a2b0-4b7fbfd74f01`),
  - added that UUID to `BAD_CHAMPION_TEMPLATES` deny-list as hard runtime guard.
- Added architecture extractions under Systems:
  - `EnemyAmbush_Systems_ChampionControl.lua` (rest-cycle counters, champion cooldown/queue/armed flow),
  - `EnemyAmbush_Systems_PersistenceControl.lua` (pending timers/cache durability + reputation save/load ownership),
  - `EnemyAmbush_Systems_PoolSelection.lua` (active pool build, weighted cache, validation, selection pipeline).
- Added tooling: `tools/Update-HuntedChangelog.ps1` for auto-assisted changelog entries from changed-file scan + optional notes.
- Changed: `EnemyAmbush_Systems_SpawnPipeline.lua` now delegates champion-control, persistence-control, and pool/selection concerns to module runtimes while retaining stable exports and fallbacks.
- Validation:
  - repeated runtime smoke logs show successful seam binds and no new hard runtime failures,
  - `!ea_test` verification suite remains green in provided traces (`verify`, `verifytemplates`, `verifystatuses`, `validate`, repeated `spawn random`, `metrics`),
  - static checks pass after each extraction tranche (`tools/Run-HuntedStaticChecks.ps1`: AST OK, local budgets OK).

## 2026-03-02 1.0 Gate Closure (Runtime Validation + Faction Handshake Timing)
- Finalized release-gate runtime validation on active save smoke cycle.
  - `!ea_test verify`: pass.
  - `!ea_test verifytemplates`: pass.
  - `!ea_test verifystatuses`: pass.
  - `!ea_test validate`: pass.
  - repeated `!ea_test spawn random`: successful delayed queue execution and combat engagement.
  - metrics stable (`spawnsSuccessful`, no spawn placement/create/find-position failures, no hostile retry exhaustion, `LastErr: (none)`).
- Changed: hardened ambusher faction force timing in spawn finalization.
  - Added explicit pre-combat faction enforcement at combat-kick path (`kick_grace` / forced kick) and deferred-support fallback.
  - This removes transient pre-combat neutral/foreign faction windows before hostility settles.
- Changed: added centralized helper export for spawn-time faction force (`EA_ForceAmbusherFaction`) and wired it through systems spawn placement dependencies.
- Changed: optimized periodic reputation decay timer work:
  - skip decay persistence while party is in combat,
  - persist only when reputation values actually change.
  - reduces avoidable timer handler spikes during combat-heavy windows.
- Validation: static checks pass after final patch set (`tools/Run-HuntedStaticChecks.ps1`: AST OK, local budgets OK).

## 2026-03-01 Events Chunk-Local Guard + Load-Blocker Fix
- Fixed: resolved runtime parse failure `too many local variables (limit is 200) in main function` in `EnemyAmbush_Events.lua`.
  - Moved high-local listener sections behind explicit registration functions:
    - `EA_RegisterCombatEventListeners()`
    - `EA_RegisterWorldRepAndTimerListeners()`
  - This keeps helper/listener locals out of the main chunk budget while preserving behavior.
- Fixed: delayed ambush timer execution now keys on pending payload kind (`SPAWN`) instead of brittle timer-name suffix parsing.
- Fixed: beach bootstrap retry budget is no longer consumed while player is off-beach regions (e.g. Nautiloid/tutorial maps).
- Improved tooling: `tools/Check-LuaLocalBudget.py` now measures **main-chunk** locals (including locals inside top-level block scopes), not only top-level declarations.
- Improved tooling: added explicit budget coverage + warnings for hotspot files:
  - `EnemyAmbush_Events.lua` (`warn=180`, `limit=195`)
  - `EnemyAmbush_DebugCommands.lua` (`warn=180`, `limit=195`)
- Changed: removed deprecated global rest-chance constants from `_G` (`SUMMON_CHANCE_SHORT`, `SUMMON_CHANCE_LONG`).
  - Rest chance now reads from `EnemyAmbush.CFG` with safe defaults.
- Changed: `!ea_test spawn random` now forces immediate delayed-spawn timer path (`forceImmediate=true`) for deterministic QA behavior.
- Added: defeat-path XP diagnostics now log manual payout plan (`xpPct`, `xpBase`, recipients, per-recipient amount) when XP scaling is active.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes (`AST OK`; `EnemyAmbush_Events.lua=167` chunk-locals; `SpawnPipeline=120` chunk-locals).

## 2026-03-01 Perfection Plan M4 Slice (Budget/Tier Extraction)
- Added: `EnemyAmbush_Systems_Budget.lua` (single owner for point-budget + party-scaling logic).
- Added: `EnemyAmbush_Systems_TierPackages.lua` (single owner for tier/champion package selection + trait application).
- Changed: `EnemyAmbush_Systems_SpawnPipeline.lua` now composes both modules via `Build(deps)` instead of owning those blocks inline.
- Changed: preserved existing spawn/champion behavior while reducing hotspot local pressure.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes (`AST OK`; `SpawnPipeline=117` locals, below the `<=120` milestone target).

## 2026-03-01 Feedback 0301-1653 Reliability + Namespace Pass
- Fixed: same-type champion cooldown now uses persisted long-rest cycle counters instead of 72h wall-clock gating.
  - Added `EA_RestCycleCounter` and `EA_ChampionCooldownCycleByType`.
  - Long-rest completion now increments cycle via exported systems helper.
- Fixed: `EA_FindValidPositionCompat` no longer rejects valid `x=0` coordinates (`nil` is the only invalid result).
- Fixed: champion provider selection path now uses mod RNG facade instead of raw `math.random()`.
- Fixed: version migration storage now uses namespaced modvars (`EA_ModVersion`) with legacy `VarString("EA_Version")` compatibility read.
- Improved: persisted-time diagnostics and policy reporting now explicitly reflect wall-clock authority for this cycle.
- Improved: bounded continuity fallback for persisted stamps when strict wall clock is temporarily unavailable.
- Improved: queue accessor split-brain reduced with canonical safe accessor:
  - `EA["EA_GetGuaranteedChampionQueueSafe"]`.
  - Events/Systems/Debug command paths now consume the safe accessor.
- Changed: settings globals exposure remains disabled by default (snapshot/accessor path remains authoritative).
- Changed: reputation warnings use corrected grammar (`The %s are ...`) in localization and fallback strings.
- Safety: status syntax pass applied to active entries (`OnApplyFunctors`) without balance redesign.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes after this pass (`AST OK`, local budgets OK; `SpawnPipeline=130`).

## 2026-03-01 Namespace Burn-Down + SpawnPipeline Immersion Slice
- Changed: removed runtime systems compatibility alias binding from `EnemyAmbush_Systems_SpawnPipeline.lua`.
- Changed: removed `EnemyAmbush_Systems_Compatibility.lua` from active systems load order; file now remains as no-op path compatibility stub.
- Added: new contained systems module `EnemyAmbush_Systems_Immersion.lua`.
  - warning text/tier/context resolution
  - timed warning display helpers
  - combat-start bark/sfx routing
  - approach-beat + ambience helpers
  - escape profile resolver
- Changed: `SpawnPipeline` now builds immersion runtime via `Build(deps)` and uses module-owned warning/cue helpers.
- Changed: removed targeted `_G` fallback dependency reads in:
  - `EnemyAmbush_Events.lua`
  - `EnemyAmbush_Systems_SpawnPlacement.lua`
  - `EnemyAmbush_Systems_SpawnExecution.lua`
- Changed: removed remaining direct global alias writes for:
  - `EA_IsAdvancedMode`
  - `EA_MakeAmbushHostile`
  - `EA_GuaranteedChampionQueue`
  - spawn-stagger globals (`EA_SPAWN_STAGGER_ENABLED`, `EA_SPAWN_STAGGER_MS`)
- Added: debug-only legacy global surface warning scan in systems session init.
- Added docs artifacts:
  - `NamespaceBurnDown_ExecutionPlan_2026-03-01.md`
  - `GlobalSurfaceInventory_2026-03-01.md`
  - `SpawnPipeline_SliceMap_2026-03-01.md`
- Validation: `tools/Run-HuntedStaticChecks.ps1` pass (`AST OK`, budgets OK), `SpawnPipeline=120` (target met).

## 2026-03-01 Config Import Policy (CE-Style)
- Changed: moved from always-on live polling model to manual-first config import flow.
  - Startup now reports manual import policy and does not auto-start polling.
  - Added manual import path: `!ea_test configpoll import`.
  - Added optional watch mode for temporary polling: `!ea_test configpoll watch on [ms]` / `watch off`.
- Improved: config poll stats now report import mode + watch state details (`enabled`, timer armed, poll range).
- Docs: updated `ConsoleCommands_Reference.md` for new `configpoll` usage and readiness wording.

## 2026-03-01 Feedback 0301-2 Stability + Policy Pass
- Fixed: `EA_Vars()` now preserves fallback runtime state when Ext.Vars backend recovers.
  - Added one-time merge path (`EA_MergeRuntimeFallbackVarsIntoPersistent`) for key state maps (`LastAmbushTime`, pressure maps, spawned/pending, ambush type history, world rep window).
  - Added short-lived modvars handle cache + invalidation hooks to reduce hot-loop `GetModVariables` pressure.
- Fixed: global faction-matrix writes are now disabled by default for ambush hostility.
  - Added `EA_ALLOW_GLOBAL_RELATION_WRITES=false` default.
  - Runtime now relies on temporary/individual hostility paths unless explicitly debug-enabled.
- Fixed: rest timer parsing now uses strict GUID capture (`[%w%-]+`) for `EA_SR_*`, `EA_LR_*`, and retry/deferred variants.
  - Removed brittle broad-capture retry substring workaround.
- Fixed: out-of-combat reputation cap ledger is now persisted (TTL-pruned) instead of session-only.
  - Added persistent mod var registration `EA_OutOfCombatRepLedger`.
  - Rep cap behavior now survives save/reload within TTL window.
- Fixed: reputation threshold warnings are now localization-handle based (no hardcoded runtime English strings).
- Improved: KO listener hot path now uses direct status-map lookup and only uppercases on fallback miss.
- Improved: surprise dedupe cache now uses bounded TTL pruning/oldest eviction instead of full-map wipes at cap.
- Changed: persisted timestamp policy is now explicit wall-clock authority for this cycle.
  - Added readiness output line for persisted-time policy.
  - Kept game-time probe diagnostics as informational only.
- Improved: RNG seed entropy mix now includes multiple sources (monotonic, wall-clock fragment, cpu clock, host/region/module).
- Refactor: moved large ambush warning/context static tables from `EnemyAmbush_Systems_SpawnPipeline.lua` to `EnemyAmbush_Systems_DataTables.lua`.
  - `SpawnPipeline` now consumes `SystemsDataTables.AMBUSH_WARNINGS`.
- Improved: added explicit XP compatibility notice when non-100% ambush XP mode is active.
- Docs: updated `ConsoleCommands_Reference.md` readiness description and XP compatibility note.
- UX copy: clarified MCM preset/advanced descriptions to make preset-dominance behavior explicit.

## 2026-03-01 Architecture Contracts + Boundary Cleanup Pass
- Added architecture ownership artifact: `Architecture_Contracts_2026-03-01.md`.
- Added module dependency graph artifact from `Ext.Require` usage: `ModuleDependencyMap_2026-03-01.md`.
- Improved systems compatibility scoping:
  - runtime/global alias binding now explicitly uses `systems_runtime` mode in `EnemyAmbush_Systems_SpawnPipeline.lua`,
  - compatibility module now separates runtime aliases vs public legacy aliases and logs deprecated alias hits once.
- Added contained Events timer-router split:
  - new module `EnemyAmbush_Events_TimerRouter.lua`,
  - `EnemyAmbush_Events.lua` now delegates owned-timer classification, exact-handler map build, and approach-beat timer dispatch through router helpers.
- Hardened MCM authority boundaries:
  - `EnemyAmbush_Config.lua` now keeps `EnemyAmbush.SettingsSnapshot` synchronized on all server-side setting apply paths (`saved`, `bulk`, `one`, persisted-load),
  - snapshot-safe helpers added (`EA_GetSettingsTable`, `EA_SetRuntimeSetting`, `EA_GetRuntimeSetting`).
- Reduced direct gameplay dependency on raw `MCM_*` globals:
  - `EnemyAmbush_Systems_SpawnPipeline.lua` reads via snapshot-aware `EA_GetSettingRaw/Bool/Number`,
  - `EnemyAmbush_Events.lua` now uses snapshot-aware setting helpers for debug/reputation/warning/beach-skip reads.
- Local-budget hygiene preserved after boundary cleanup:
  - `EnemyAmbush_Systems_SpawnPipeline.lua` remains at `130` locals.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes (`AST OK`, local budgets OK).

## 2026-03-01 Feedback 0301-1 Correctness + Safety Pass
- Fixed: defeat routing now treats `Died` as authoritative and routes KO + lethal outcomes through shared defeat handling.
  - KO statuses handled: `KNOCKED_OUT`, `KNOCKED_OUT_TEMPORARILY`, `KNOCKED_OUT_PERMANENTLY`.
  - duplicate suppression guard retained to prevent double rep/cleanup on transition chains.
- Fixed: `Disable Ambush Loot` policy now matches lock decision: corpses are empty but still lootable.
  - removed async loot-bag spawn/move/delete timer chain from corpse clear path.
  - removed unlootable-corpse side effect (`SetCharacterLootable(..., 0)`).
- Fixed: stale delete timers are now safe (`ObjectExists` guard + `SafeOsiExec(Osi.RequestDelete, ...)`).
- Fixed: spawn SetLevel path now uses safe execution wrapper in `EnemyAmbush_Systems_SpawnPlacement.lua`.
- Fixed: config-write success check in `EA_ConfigWriteNow` now uses `pcall` result only (no false failed-write logs).
- Fixed: runtime combat maps no longer write to unregistered Ext.Vars classes.
  - combat runtime state is now in-memory only (`EnemyAmbush._RuntimeCombatState`).
- Fixed: warning resolver region match uses plain-string search (`region:find(contextKey, 1, true)`), not Lua pattern matching.
- Added: surprise diagnostics counters (`surpriseApplyAttempts`, `surpriseApplied`, `surpriseApplyFailed`, `surpriseRollPassed`, `surpriseRollFailed`, `surpriseNoRollsRequested`, `surpriseDeferredNoEligible`).
- Added: champion QA command path:
  - `!ea_test championarm <CreatureType> [run]`.
- Changed: RNG fallback in core spawn/surprise/escape paths now uses mod RNG facade + deterministic fallback LCG (no broad `math.random` fallback in those paths).
- Refactor: contained local-budget hardening in `EnemyAmbush_Systems_SpawnPipeline.lua`.
  - local count reduced from `139` to `130`.
- Refactor: moved additional static warning/cue data ownership to `EnemyAmbush_Systems_DataTables.lua` and rebound in SpawnPipeline.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes (`AST OK`, local budgets OK).

## 2026-03-01 Beach Bootstrap Key Finalization + KO Telemetry Pass
- Changed: removed beach bootstrap legacy VarString compatibility path entirely.
  - removed legacy key usage: `EA_BeachBootstrapDone`
  - canonical key is now only: `HuntedMod_96f24297_BeachBootstrapDone`
- Changed: beach bootstrap metadata keys are now namespaced to avoid cross-mod collisions:
  - `HuntedMod_96f24297_BeachBootstrapDoneReason`
  - `HuntedMod_96f24297_BeachBootstrapDoneAt`
- Added: explicit code comments documenting why character VarStrings must be namespaced.
- Added: defeat-path telemetry counters in `EnemyAmbush_Events.lua`:
  - `defeatHandledDying`
  - `defeatHandledKnockout`
  - `defeatDuplicateSuppressed`
- Fixed: KO status listener now uses existing status IDs (`KNOCKED_OUT`, `KNOCKED_OUT_TEMPORARILY`, `KNOCKED_OUT_PERMANENTLY`) and no longer references nonexistent `KNOCKED_OUT_STORY`.
- Clarified: KO listener comments now explicitly document why `StatusApplied` ID checks are preferred over broad `HasAppliedStatusOfType` scans.
- Documentation: expanded DataTables and champion deny-list rationale comments.
- Added: debug data-audit lines when a blacklisted champion template is rejected (`source=provider` / `source=active_summon`).
- Fixed: restored `EnemyAmbush`/`EA` bootstrap binding in `EnemyAmbush_Data.lua` so data audit/provider exports register on load.
- Fixed: hardened `EA_GetRuntimeCombatState` fallback path when `EA_RuntimeCombatState` modvar class is unavailable (prevents SessionLoaded nil-index crash and falls back to runtime table).
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes (AST OK; local budgets OK).

## 2026-03-01 Feedback 29 Stabilization + Contained Refactor Pass
- Fixed: TurnStarted hot-path combat resolution now uses runtime member->combat cache (`EnemyAmbush._CombatKeyByMember`) before DB fallback.
- Added: TurnStarted cache telemetry counters (`turnStartedCacheHit`, `turnStartedDbFallback`).
- Fixed: Escape success flow now uses safe combat handoff (`LeaveCombat` + `EndTurn`) before delayed `RequestDelete`.
- Fixed: Non-lethal knockout parity for ambushers/champions:
  - added `StatusApplied` listener for `KNOCKED_OUT`, `KNOCKED_OUT_TEMPORARILY`, and `KNOCKED_OUT_PERMANENTLY`,
  - routed to shared defeat handler (rep/counter/cleanup parity with lethal defeats).
- Added: status existence cache in `SafeApplyStatus` to avoid repeated `Ext.Stats.Get(...)` probe overhead.
- Added: `!ea_test clearcache` now resets status existence cache.
- Fixed: beach bootstrap var key now namespaced (`HuntedMod_96f24297_BeachBootstrapDone`) with legacy-key migration read.
- Added: `!ea_test dataaudit [verbose]`; startup audit remains non-verbose by default.
- Fixed: removed stale no-op self-assignment (`LoadReputation = LoadReputation`) from Utils Hostility module.
- Improved: duplicated loca resolver now centralized (`EA_ResolveLocaText` shared export) and consumed by Events + Scenarios.
- Fixed: deferred/retry rest flows now preserve and forward `TriggerAmbush(opts)` across queue/timer paths.
- Changed: CX auto-detect prints are debug-gated.
- Changed: JSON live-import OFF policy is explicit:
  - one-time startup policy log,
  - readiness output now surfaces live-import status.
- Refactor: added `EnemyAmbush_Systems_DataTables.lua` and moved static spawn/champion table ownership to dedicated module.
- Refactor: reduced `EnemyAmbush_Systems_SpawnPipeline.lua` local pressure from `169` to `139`.
- Refactor: RNG facade adoption in core hot paths:
  - `EnemyAmbush_Systems_SpawnPipeline.lua` now uses wrapper helpers backed by `EA_RandFloat` / `EA_RandInt` (with fallback),
  - `EnemyAmbush_Systems_SpawnPlacement.lua` now uses same wrappers,
  - Events randomization already uses wrapper path.
- Fixed: champion visual duplication resolved:
  - `EA_CHAMPION_FIEND` no longer shares `StatusEffect` UUID with `EA_CHAMPION_DRAGON` in `Status_EnemyAmbush.txt`.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes (AST OK; local budgets OK).

## 2026-02-28 MCM UX + Balance Contract Cleanup
- Added: `CUSTOM` preset state to MCM contract/UI (`MCM_DifficultyPreset`) for advanced manual tuning workflows.
- Added: automatic preset relabel to `CUSTOM` when advanced tuning knobs are edited in Advanced Mode.
- Removed: `Advanced follows Preset` setting from UI/runtime; preset behavior is now deterministic:
  - selecting `EASY/NORMAL/HARD` reapplies that baseline,
  - any advanced manual tuning moves preset to `CUSTOM`.
- Added: custom preset base tracking (`MCM_CustomBasePreset` internal) so `CUSTOM` keeps using the last explicit base preset for preset-derived multipliers (rest chance/champion chance).
- Improved: client/server MCM sync handling now treats `CUSTOM` as a valid preset enum and avoids forcing preset-derived overwrite when `CUSTOM` is selected.
- Changed: `MCM_PointBudget` is now positioned as expert/debug override:
  - UI control renamed to `Ambush Point Budget Override (Debug)`,
  - visibility gated by both `Advanced Mode` and `Debug Mode`,
  - runtime fixed-budget override now only activates when Debug Mode is ON.
- Fixed: MCM contract/UI range mismatches:
  - `MCM_ReputationDecayRate` clamp aligned to `0..1`,
  - `MCM_AmbushCooldownMinutes` clamp aligned to `0..120`.
- Text polish: `MCM_EnableOnRest` description now correctly states short + long rests.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes (`AST OK`, local-budget OK).

## 2026-02-28 Rest Frequency + Session Stats Commands
- Changed: tuned short-rest base ambush chance from `0.05` to `0.06` in `EnemyAmbush_Utils_HostilityRegion.lua` (long-rest chance remains `0.20`).
- Added: session rest-flow stats runtime collectors in `EnemyAmbush_Events.lua`:
  - schedule/retry/deferred/timer counters,
  - roll pass/fail/forced counters (wired from `EnemyAmbush_Systems_SpawnPipeline.lua`),
  - spawn conversion counters (`spawnedAmbushes`, `spawnedEntities`, `zeroSpawnAmbushes`).
- Added: session reputation stats runtime collectors in `EnemyAmbush_Events.lua`:
  - total delta, negative/positive delta, cap-blocked kills, champion resets, in/out-of-combat counts, per-creature-type breakdown.
- Added: new debug commands in `EnemyAmbush_DebugCommands.lua`:
  - `!ea_test reststats [show|reset|export]`
  - `!ea_test repstats [show|reset|export]`
- Added: JSON export support for playtester sharing:
  - `Hunted_DynamicAmbushes_Revenge_System/reststats_<timestamp>.json`
  - `Hunted_DynamicAmbushes_Revenge_System/repstats_<timestamp>.json`
- Docs: updated `ConsoleCommands_Reference.md` with `reststats` and `repstats`.

## 2026-02-28 Early-Game Party-Size Balance Tuning (Level 3 Focus)
- Changed: adjusted early spawn composition targets in `EnemyAmbush_Systems_SpawnExecution.lua`:
  - level >= 3, party size 2 -> `minEnemiesTarget = 3` (was typically 2),
  - level >= 3, party size 3-4 -> `minEnemiesTarget = 3`,
  - level >= 3, party size 5+ -> `minEnemiesTarget = 4`.
- Changed: early non-fodder cap now scales by party size:
  - level <= 4, party size <= 4 -> `nonFodderMax = 1` (unchanged),
  - level 3-4, party size >= 5 -> `nonFodderMax = 2`.
- Kept: legendary/champion add-wave limiter unchanged (`minEnemiesTarget` still clamped to max 3 for those tiers).
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes (`AST OK`, local-budget OK).

## 2026-02-28 Persistence Readiness + Game-Time Diagnostics Patch
- Added: explicit ModVariables readiness diagnostics in `EnemyAmbush_Utils_Core.lua`:
  - `EA_GetModVarsReadyDiagnostics()` with reason/detail/running/failure counters,
  - richer fallback logging when `EA_Vars()` must use runtime-only table.
- Added: game-time provider diagnostics and probing in `EnemyAmbush_Utils_StateTime.lua`:
  - `EA_ProbeGameTimeMs()`,
  - `EA_GetGameTimeDiagnostics()`,
  - improved persisted-timestamp skip logs now include provider reason/detail/raw type.
- Fixed: persistence flushes are no longer silently dropped during early load windows:
  - `EA_Dirty` now schedules retry when ModVars backend is unavailable.
- Fixed: `SaveReputation()` now queues/retries when ModVars is not ready instead of only skipping.
- Fixed: cooldown stamp writes now retry when readiness or persisted game-time is temporarily unavailable:
  - delayed ambush cooldown stamp retry (`EnemyAmbush_Events.lua`),
  - normal ambush cooldown stamp retry (`EnemyAmbush_Systems_SpawnPipeline.lua`),
  - champion per-type cooldown stamp retry (`EnemyAmbush_Systems_SpawnPipeline.lua`).
- Added: new debug command `!ea_test readiness` in `EnemyAmbush_DebugCommands.lua` for one-shot readiness/provider diagnostics.
- Improved: post-status final HP normalization pass in `EnemyAmbush_Systems_SpawnPlacement.lua` to reduce occasional 1 HP missing-on-spawn cases after SetLevel + tier/status application.
- Docs: updated `ConsoleCommands_Reference.md` with `readiness`, `configpoll`, and `spawnstagger`.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes after patch (`AST OK`, local budgets OK; `EnemyAmbush_Systems_SpawnPipeline.lua` remains `169/175`).

## 2026-02-28 Systems Shim Cleanup (Post-Refactor)
- Changed: Removed placeholder-only Systems shim files and kept only logic-bearing modules in load order:
  - removed `EnemyAmbush_Systems_Rng.lua`
  - removed `EnemyAmbush_Systems_CacheSelection.lua`
  - removed `EnemyAmbush_Systems_EffectsLootXP.lua`
  - removed `EnemyAmbush_Systems_Champion.lua`
  - removed `EnemyAmbush_Systems_ReputationLegacy.lua`
- Changed: `EnemyAmbush_Systems.lua` now loads `EnemyAmbush_RNG.lua` directly before Systems runtime modules.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes after cleanup (`AST OK`, local budgets OK).

## 2026-02-28 Full Refactor Completion (Lossless Milestone Pass)
- Refactor: Completed real Systems decomposition slice by extracting runtime blocks from `EnemyAmbush_Systems_SpawnPipeline.lua` into:
  - `EnemyAmbush_Systems_SpawnPlacement.lua`
  - `EnemyAmbush_Systems_SpawnExecution.lua`
- Changed: `EnemyAmbush_Systems_SpawnPipeline.lua` now composes placement/execution through module-runtime builders instead of owning those blocks inline.
- Changed: `EnemyAmbush_Systems.lua` load order now includes `EnemyAmbush_Systems_SpawnPlacement.lua` and `EnemyAmbush_Systems_SpawnExecution.lua`.
- Safety: Fixed extraction regressions before close:
  - restored `EA_GetBalanceProfileKeyForSystems` dependency flow into execution runtime,
  - corrected split seam formatting/runtime assignment edge cases,
  - normalized modified Lua file encodings to avoid parse-time BOM failures.
- Changed: Compatibility shim pruning pass removed confirmed-unused aliases:
  - `RobustRetry`
  - `EA_GetRegionPolicy`
- Removed: Remaining DragonDebt-facing user text from active localization/journal wording:
  - `A blood debt has been paid.` -> `Escalation has been reset.`
  - `Standing: Debt Paid` -> `Standing: Reset`
- Docs: Added full no-loss refactor artifact set:
  - `FullRefactor_ExecutionPlan_2026-02-28.md`
  - `Refactor_FunctionInventory_2026-02-28.md`
  - `Refactor_APIParityChecklist_2026-02-28.md`
  - `Refactor_VerificationLog_2026-02-28.md`
  - `DeepRedesign_Assessment_2026-02-28.md`
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes after this pass (`AST OK`, local budgets OK). Current Systems snapshot:
  - `EnemyAmbush_Systems_SpawnPipeline.lua`: `169/175`
  - `EnemyAmbush_Systems_SpawnPlacement.lua`: `2/175`
  - `EnemyAmbush_Systems_SpawnExecution.lua`: `2/175`

## 2026-02-28 Plan 28 Continuation (Refactor + Contract Sync)
- Refactor: Wired Systems one-cycle compatibility binder in `EnemyAmbush_Systems.lua`:
  - runtime now imports `EnemyAmbush_Systems_Compatibility.lua` and binds global shims from a single allowlist source.
- Refactor: Added centralized Systems export binder module `EnemyAmbush_Systems_Exports.lua`.
  - `EnemyAmbush_Systems.lua` now publishes exports via mapped binder call instead of repeated inline assignments.
- Refactor: Converted `EnemyAmbush_Systems.lua` into loader/orchestrator and moved runtime implementation to `EnemyAmbush_Systems_SpawnPipeline.lua`.
- Added: Load-ordered Systems module scaffolding for this cycle:
  - `EnemyAmbush_Systems_Rng.lua`
  - `EnemyAmbush_Systems_CacheSelection.lua`
  - `EnemyAmbush_Systems_EffectsLootXP.lua`
  - `EnemyAmbush_Systems_ReputationLegacy.lua`
  - `EnemyAmbush_Systems_Champion.lua`
- Improved: `TimerFinished` exact-timer dispatch map added in `EnemyAmbush_Events.lua` for high-frequency fixed timers:
  - `EA_VALIDATE_SPAWNED`
  - `EA_RUNTIME_COMBAT_PRUNE`
  - `EA_ENCOUNTER_REP_WATCH`
  - `EA_REPUTATION_DECAY`
  - `EA_CLEANUP_PENDING`
  - these now fast-dispatch before regex/pattern branches.
- Added: Save/load-safe persistent stagger execution for delayed/rest ambushes:
  - new queue timers `EA_SPAWNQ_*`,
  - queue-step state persisted in `EA_Pending`,
  - `ExecuteAmbushSpawn` now supports resumable `queueState` step mode (`-2` continue sentinel),
  - session-load relaunch support for `SPAWN_QUEUE` payloads.
- Changed: Removed remaining legacy-debt runtime naming from champion queue flow.
  - queue sanitization now uses generic junk-entry detection and no feature-specific naming.
- Fixed: Escape max-per-combat contract drift.
  - unified to `0..6` across:
    - `MCM_blueprint.json` (`MCM_EscapeMaxPerCombat` UI max),
    - `EnemyAmbush_MCMContract.lua` numeric clamp,
    - `EnemyAmbush_Utils_Settings.lua` normalization clamp,
    - `EnemyAmbush_Events.lua` runtime getter bounds.
- Docs: Added `MajorRefactor_ImplementationPlan_2026-02-28.md` and updated RC tracker with addendum gates (`RC-G21..RC-G23`).
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes after this pass (`AST OK`, local budgets OK; `EnemyAmbush_Systems.lua` at `165/175`).

## 2026-02-28 Feedback 28 Critical Runtime + Contract Pass
- Fixed: Startup crash on load caused by unsupported `math.randomseed()` in BG3SE sandbox.
  - Added `EnemyAmbush_RNG.lua` (mod-local RNG surface),
  - bootstrap now seeds only mod-local RNG (`EnemyAmbush.SeedRng`) and never calls `math.randomseed`.
- Fixed: `ExecuteAmbushSpawn` stagger options bug.
  - function now takes explicit `spawnOpts` parameter,
  - removed invalid `select(9, ...)` usage in non-variadic function.
- Changed: Delayed/rest ambush execution now forces synchronous spawn path for save/load safety.
  - `Ext.Timer.WaitFor` stagger chains remain available for non-persistent contexts, but delayed timer path no longer uses ephemeral stagger callbacks.
- Fixed: Long-rest candidate indexing bug in `LongRestFinished`.
  - candidate index now floors monotonic source before modulo so table lookup is always integer-safe.
- Fixed: `KilledBy` world-reputation handler no longer heuristic-parses args.
  - now maps documented event args directly to victim/attacker-owner/attacker.
- Hardened: Champion spawn fallback when vanilla providers are disabled.
  - if provider returns no champion, runtime now attempts deterministic creature-type fallback from active summon pool,
  - emits explicit fallback/no-config telemetry instead of silent dead path.
- Changed: JSON live import default policy.
  - `EA_CONFIG_LIVE_IMPORT_ENABLED` now defaults to `false` (poller remains available when explicitly enabled).
- Fixed: Timer namespace safety and `TimerFinished` hot-path.
  - moved despawn/delete timers to `EA_Despawn_*` / `EA_Delete_*`,
  - added fast prefix gate in `TimerFinished` router,
  - kept legacy `Despawn_*` / `Delete_*` pattern compatibility for existing saves.
- Hardened: Despawn timer scheduling now uses guarded launch path with failure metric (`despawnTimerLaunchFailed`) instead of blind call.
- Fixed: Removed no-op forward declaration globals in `EnemyAmbush_Utils_Settings.lua` that could leave nil placeholders during partial-load windows.
- Hardened: `EA_AmbushTypeHistory` usage in `EnemyAmbush_Utils_StateTime.lua` now guards missing function/table paths to avoid nil-call regressions.
- Changed: Removed legacy `DB_Camp:Get(character, nil, nil, nil)` fallback branch from camp safety checks; retained `DB_InCamp`/`DB_PlayerInCamp` and region policy checks.
- Fixed: Escape MCM range coherence across runtime and contract.
  - `MCM_AmbushIntensity` clamp/contract now `0.5..2.0`,
  - `MCM_EscapeStartTurn` clamp/contract now `1..30`,
  - `MCM_EscapeDC` clamp/contract now `5..25`,
  - TurnStarted escape getters now use matching limits.
- Fixed: Escape delete race cleanup.
  - successful escape now marks spawned row as escape-scheduled,
  - final spawned/combat-key cleanup happens at delete-finalization stage to avoid premature state loss windows.
- Safety pass: Disabled champion status `ApplyFunctors` entries that injected non-EA/world-affecting aura/status behavior directly from stats (champion behavior remains controlled via Lua package/status path).
- Removed: DragonDebt system end-to-end.
  - deleted world-kill DragonDebt queueing in `EnemyAmbush_Events.lua`,
  - deleted DragonDebt prelude execution path from long-rest ambush flow in `EnemyAmbush_Systems.lua`,
  - removed `!ea_test dragondebt|dragonqueue` debug command surface.
- Added: Legacy DragonDebt save migration cleanup.
  - guaranteed champion queue scan now purges stale DragonDebt entries (`kind=DRAGON_DEBT` / `reason=first_world_kill`) and persists cleanup.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passed after patching (`AST OK`, local budgets OK; `EnemyAmbush_Systems.lua` now `163/175`).

## 2026-02-24 Feedback 24-4 Stabilization Pass
- Fixed: Persisted timestamp path is now strict game-time only for save-backed cooldown state:
  - `EA_PersistedNowMs()` no longer accepts monotonic fallback writes,
  - unavailable game-time now skips writes with throttled diagnostics,
  - persisted sanitize pass now aborts when game-time is unavailable instead of clamping against non-persisted clocks.
- Fixed: Removed unsupported `IsLevelLoading` guards; runtime now relies on supported running-state checks (`IsGameStateRunning`) and existing readiness gates.
- Fixed: `SaveReputation()` now uses debounced `EA_Dirty()` persistence path (with `EA_ModVarsReady` gate) instead of direct `DirtyModVariables` calls.
- Added: Session RNG seeding in `BootstrapServer.lua` (`math.randomseed` once per process) to avoid deterministic early-roll sequences across app restarts.
- Fixed: `MCM_PointBudget` client/server contract drift:
  - shared MCM sanitizer now clamps to `0..30` (matching current blueprint UI range).
- Hardened: `EA_Vars()` fallback behavior:
  - removed fallback->persistent merge-back path,
  - added `EA_ModVarsReady()` helper,
  - dirty flush now no-ops while mod variables backend is unavailable.
- Improved: Bootstrap health diagnostics now report explicit missing core exports instead of a generic warning.
- Improved: TurnStarted hot path now prefers fast UUID normalization (`EA_NormalizeUUIDFast`) for combat-key and spawned lookups.
- Improved: Party-member query performance:
  - added short-lived party cache in Systems,
  - `GetPartySize`, `GetPartyMaxLevel`, and `EA_GetPartyMembers` now share cache results,
  - Events XP recipients now consume exported party-members helper when available.
- Improved: Reduced tier/champion status sweep overhead by removing redundant `HasActiveStatus` pre-check loops.
- Improved: Bounded HP normalization retry fanout after `SetLevel` for normal and champion spawns.
- Improved: Hostility relation writes are now deduped per faction pair to avoid repeated global `SetRelation` spam on retry loops.
- Added: Region telemetry now logs throttled prefix-heuristic mappings (`raw -> canonical`) for observability.
- Improved: API queue compatibility hardening:
  - added `EA.ProcessApiQueue()` with incremental drain,
  - invoked from API bootstrap and Data module to process late-queued registrations deterministically.
- Changed: XP MCM tooltip now explicitly documents anti-farming default rationale (0% default).
- Changed: Per-enemy spawn print spam demoted to debug-level logging (key lifecycle prints remain).
- Added: Guardrail comments for journal-dependent warning path and legacy champion status inert behavior.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passed (AST + local-budget), with `EnemyAmbush_Systems.lua` at `172/175` locals.

## 2026-02-24 Feedback 24-3 Stability + Perf Pass
- Fixed: Robust-mode propagation across split modules now uses canonical accessors (`EA_IsRobust`, robust args/retry helpers) instead of cross-chunk local assumptions.
- Fixed: Removed duplicate champion template entry for Deva in `EnemyAmbush_Data_Champions_Vanilla.lua`.
- Added: Champion duplicate audit in `EnemyAmbush_Data.lua` (duplicate + conflict counts), plus improved summon duplicate classification (`intentional_variant`, `exact_profile`, `creatureType_conflicts`).
- Fixed: Unified ambush entity cap contract through shared config (`EnemyAmbush.CFG.MAX_AMBUSH_ENTITIES`) and Systems runtime consumption.
- Fixed: World-kill attribution fallback order in `EA_SelectWorldKillPlayer` now resolves as:
  - party-aligned attacker A/B,
  - closest alive player to victim,
  - host fallback last.
- Fixed: Removed dead `EA_WallClockMs` fallback block in `EnemyAmbush_Utils_StateTime.lua`.
- Fixed: Removed legacy `ENLARGED` apply functor from `EA_VETERAN_BUFF` status definition.
- Hardened: Ownership helper calls remain guarded; added one-time debug capability logging when `ClearOwnership` is unavailable.
- Added: Staggered runtime ambush spawn dispatch path (default ON for delayed/rest execution via `EA.CFG.SPAWN_STAGGER_*`) while preserving synchronous `ExecuteAmbushSpawn` compatibility for existing debug/API call sites.
- Added: Runtime spawn-stagger diagnostics command: `!ea_test spawnstagger [show|on|off|<ms>]`.
- Improved: Warning text localization set (`h8a1b2c3...000000000001-161`) rewritten to remove previous 4-line repetition and add tier/context-specific variation.
- Fixed: Reputation encounter-cap behavior outside combat now uses a short per-type anti-chaining window (90s) so sequential out-of-combat pulls do not bypass intended cap behavior.
- Added: JSON live-import observability counters in `EnemyAmbush_Config.lua` (`poll/read/change/import/noop/invalid/write`) with debug command visibility:
  - `!ea_test configpoll [show|reset]`.
- Added: Save/load resilience for long-delay hostility retries:
  - persistent timer-backed queue,
  - `TimerFinished` retry handling hook,
  - session-load rearm integration.
- Validation: `tools/Run-HuntedStaticChecks.ps1` passes (AST + local-budget), with `EnemyAmbush_Systems.lua` still at `168/175` locals.

## 2026-02-24 Docs-Validated Addendum (Champion Safety + Cleanup Policy + Plan Gates)
- Fixed: Removed story-bound Slayer champion template (`1271757c-9edf-4f82-a446-9a436261cdba`) from `EnemyAmbush_Data_Champions_Vanilla.lua`.
- Changed: Replaced Monstrosity champion fallback with `Phase Spider Matriarch` (`6047fffd-f7d3-4956-8b7a-ef82c08f8867`) and removed that template from summon-pool runtime rotation to avoid overlap.
- Changed: Updated aggressive spawned-tracker cleanup policy in `EnemyAmbush_Utils_Core.lua`:
  - stale purge TTL reduced from 7 days to 60 minutes,
  - added post-session-load grace window before stale unload-based purges,
  - malformed/non-table entries are still purged immediately.
- Added: `EA_MarkSessionLoadedForCleanup` helper export and SessionLoaded integration in `EnemyAmbush_Systems.lua` to anchor cleanup grace timing.
- Added: Guardrail comments in `EnemyAmbush_Systems.lua`:
  - `EA_WARNING_QUESTMESSAGE_ENABLED` explicitly marked unsafe until journal/quest assets exist,
  - legacy `CHAMPION_TEMPLATES` comment now documents that non-`EA_` statuses are intentionally inert at runtime.
- Changed: Compatibility-first MCM integer policy is now explicitly documented in `EnemyAmbush_MCMContract.lua` (`slider_float` + integer clamp retained this cycle; `slider_int` deferred until dependency lock).
- Docs: Updated planning gates:
  - `RC_Stabilization_ExecutionPlan_2026-02-24.md` with addendum traceability IDs and acceptance/evidence gates,
  - `HUNTED_SYSTEMS_REFACTOR_PLAN.md` with explicit hard dependency gate before any future Events decomposition phase.

## 2026-02-24 Lua Local-Limit Hardening (Utils Refactor + Command/MCM Consolidation)
- Refactor: Split `EnemyAmbush_Utils.lua` into load-ordered modules to remove monolithic local-limit risk:
  - `EnemyAmbush_Utils_Core.lua`
  - `EnemyAmbush_Utils_Settings.lua`
  - `EnemyAmbush_Utils_StateTime.lua`
  - `EnemyAmbush_Utils_HostilityRegion.lua`
  - `EnemyAmbush_Utils_Telemetry.lua`
  - `EnemyAmbush_Utils_Exports.lua`
- Added: Shared MCM contract module `EnemyAmbush_MCMContract.lua` (`IDS`, `BOOL_IDS`, `NUMERIC_RULES`, `ENUM_RULES`) to prevent client/server contract drift.
- Changed: `EnemyAmbush_Config.lua` now consumes shared MCM contract tables for sync allowlist + sanitize/clamp/type normalization.
- Changed: `EnemyAmbush_MCMClient.lua` now consumes shared canonical setting IDs and normalization rules; initial bulk sync now includes escape settings through contract IDs.
- Changed: Telemetry command ownership moved to `EnemyAmbush_DebugCommands.lua`:
  - new/central command `!ea_test telemetry on|off|show|dump`
  - legacy aliases retained: `ea_debugtelemetry_on`, `ea_debugtelemetry_off`
- Changed: Removed direct telemetry command registration from `EnemyAmbush_Utils_Telemetry.lua` (runtime metrics/event log remain there).
- Added: Static guardrail tooling:
  - `tools/Check-LuaLocalBudget.py`
  - `tools/Run-HuntedStaticChecks.ps1` (AST parse + budget enforcement, non-zero on fail)
- Fixed: Cross-module state helper visibility regression after Utils split (`EA_AmbushTypeHistory`/type-pressure helpers were local-only in Core), which caused `!ea_test spawn random` nil-call crash in `EA_GetRecentAmbushTypePenalty`; promoted shared helpers and exported them via `EA[...]`.
- Verified: Static checks pass with current enforced budgets:
  - `EnemyAmbush_Systems.lua` top-level locals: `168/175`
  - `EnemyAmbush_Utils.lua` loader: `0/20`
  - `EnemyAmbush_Utils_*.lua` modules: all `<=120`

## 2026-02-24 Combat Escape + Champion Diagnostics Implementation
- Fixed: Resolved Script Extender parse failure (`too many local variables`) in `EnemyAmbush_Utils.lua` by reducing chunk-local declarations below Lua's 200-local limit.
- Fixed: Restored missing cross-file exports caused by the parse failure (`EA_ToBool`, `EA_NowMs`, `EA_IsRegionCamp`), which unblocked net-sync sanitization, pending-ambush cleanup, region safety checks, and `ea_debugtelemetry_on`.
- Hardened: `EnemyAmbush_Config.lua` now uses a safe bool normalizer (`EA_ToBoolCompat`) in sync/event paths so MCM net payload handling does not hard-crash if helper exports are temporarily unavailable.
- Hardened: `EnemyAmbush_Systems.lua` now has nil-safe fallbacks for `EA_NowMs` and `EA_IsRegionCamp` to prevent spawn/cleanup crashes under partial-load edge cases.
- Added: New long-combat ambusher escape system in `EnemyAmbush_Events.lua`:
  - `TurnStarted` now tracks combat turn age via `_CombatEscapeState`,
  - eligible non-champion ambushers can attempt `d20 + bonuses vs EscapeDC` after configured turn threshold,
  - failed attempts set a retry cooldown,
  - successful attempts play type-themed VFX/SFX and remove/delete the actor cleanly.
- Added: Escape safety gates:
  - excludes champions and scripted beach tutorial actors,
  - caps successful escapes per combat,
  - blocks final tracked ambusher from escaping to avoid full-fight wipe.
- Changed: `TurnStarted` fast-exit path now short-circuits only when both chatter-state and escape-state tables are empty, preserving turn chatter behavior while still reducing idle overhead.
- Added: Escape state hygiene via combat mapping/cleanup:
  - `_CombatKeyByAmbusher` mapping on `CombatStarted`/`EnteredCombat`,
  - cleanup on `LeftCombat`, despawn, and death tracking paths.
- Added: Escape profile contract in `EnemyAmbush_Systems.lua`:
  - `EA_ESCAPE_PROFILE_BY_TYPE` + default fallback profile,
  - exported `EA_GetEscapeProfileByCreatureType` for runtime consumers.
- Added: Champion diagnostics runtime telemetry in long-rest flow:
  - logs region-appropriate types,
  - logs vengeful appropriate vs not-appropriate candidates,
  - logs per-type chance evaluation reasons (`cooldown`, `chance_failed`, `spawn_failed`) with roll/chance data.
- Changed: Champion chance path now explicitly checks per-type champion cooldown before rolling, and emits diagnostics for skip/spawn outcomes.
- Added: Champion diagnostics control/debug commands:
  - `!ea_test championdiag on|off|once|show`,
  - `!ea_test championqueue <CreatureType>` (seed guaranteed queue entry).
- Added: New MCM settings and full server-sync validation support:
  - `MCM_EnableAmbusherEscape`,
  - `MCM_EscapeStartTurn`,
  - `MCM_EscapeDC`,
  - `MCM_EscapeHPThreshold`,
  - `MCM_EscapeMaxPerCombat`.
- Changed: Updated `MCM_blueprint.json` with Advanced-mode UI controls for the new escape settings.
- Added: Fast effect-preview debug tooling in `EnemyAmbush_DebugCommands.lua` to avoid waiting full combat turn windows:
  - `!ea_test vfx <effectId|alias> [target]`,
  - `!ea_test sfx <soundEvent|alias> [target]`,
  - `!ea_test arrivalpreview [target] [vfx] [sfx]`,
  - `!ea_test escapepreview [target] [vfx] [sfx] [deleteMs]`.
- Added: Escape tuning debug command for rapid in-field iteration:
  - `!ea_test escapetune quick|default|show`.
- Added: VFX aliases mapped to vetted teleport IDs for quick testing:
  - `dimdoor` => `b214ce9c-33c2-4dfc-bfc2-3af8e4124714` (Dimension Door teleport disappear),
  - `mistycast` => `71859b27-bdda-44c3-8c65-7f142a1a2f60` (Misty Step cast effect).
- Docs: Updated `CombatEscape_ChampionDiagnostics_Plan_2026-02-24.md` with execution status and validated VFX/SFX asset set.

## 2026-02-24 RC Stabilization Session (Backfill)
- Fixed: Retired runtime global XP stat mutation/restore flow; ambush XP suppression is now boost-only (`ExperienceReward(0)` fallback chain) with telemetry.
- Fixed: Removed orphaned XP override cleanup paths from `Dying`/`Died`/despawn listeners (`xpStat` + `EA_ReleaseXPStatOverride` remnants).
- Fixed: Persisted cooldown timestamp handling hardened to game-time-first persistence behavior and future-timestamp clamping to avoid restart/reload expiry drift.
- Fixed: Faction hostility hardening now enforces isolated ambush faction usage only; removed unsafe fallback behavior that could mutate vanilla world relations.
- Fixed: Shared spawn duration config exports (`ENEMY_DURATION_MIN`, `ENEMY_DURATION_MAX`) are now consumed consistently; normal despawn window remains 5-10 minutes.
- Fixed: Exposed and consumed `EA_GetVengefulChampionChance` through explicit `EA[...]` API contract to remove implicit-global nil crash risk.
- Fixed: Immediate spawned-cap enforcement now consistently calls `EA_EvictOldSpawned(spawned)` across spawn/session/timer paths.
- Fixed: `EA_MCM_SYNC` payload hardening now enforces watched-ID allowlist, value sanitize/clamp/type normalization, and debug dropped-key logging.
- Improved: `EnterCombatFailed` handling keeps teleport as strict last-resort fallback behind explicit eligibility checks.
- Fixed: `TurnStarted` fast-exit now keys off active chatter-state presence (not turn-owner ambusher status), preventing chatter stall during player turns.
- Fixed: Data contract contradiction pass included LEGENDARY spawn-band correction and debug/category consistency alignment.
- Improved: MCM blueprint/settings contract normalization (uppercase preset defaults/choices + text cleanup) and safer runtime sync normalization.
- Improved: Provider cache lifecycle now uses revision-driven invalidation flow instead of repeated expensive signature rebuilds on read.
- Improved: Debug/API category contract now exposes metadata-scoped helpers and routes debug commands through spawn-band-aligned category resolution.
- Changed: Exported static `CHAMPION_TEMPLATES` now includes explicit `_LEGACY_NOTICE` to signal debug/static fallback semantics for compatibility consumers.
- Fixed: `ValidateEnemyData` now rejects level `0` (`<= 0`), closing off invalid template metadata acceptance.
- Improved: Debug despawn telemetry map is now bounded with stale-key eviction and a hard entry cap for long debug sessions.
- Docs: Added/updated `RC_Stabilization_ExecutionPlan_2026-02-24.md` with expanded feedback IDs, RC gates, evidence criteria, and manual confirmation hooks.

## 2026-02-24 23:40 UTC
- Added: Aberration roster expansion with `Countermeasure` class replicas (`KillerReplica_*`) for late-game ambush variety:
  - `0d14b483-983b-49d5-bc54-4cfab8897e37` (`Countermeasure: Barbarian`)
  - `244b45f9-2fbd-4384-b822-71070da6f5f0` (`Countermeasure: Paladin`)
  - `53a0d484-4647-44cb-9483-af52b72f991c` (`Countermeasure: Fighter`)
  - `f710ea72-6c27-4a52-9919-4a00b2659c17` (`Countermeasure: Rogue`)
  - `98184393-7914-45ee-a89c-1c30f6ea1340` (`Countermeasure: Cleric`)
  - `e225fab6-36b8-4b35-b863-751b9d51ff34` (`Countermeasure: Ranger`)
  - `33d55bca-6c52-479c-b633-e2d10d3afa83` (`Countermeasure: Bard`)
  - `6c6b4487-cdca-45c8-b9b7-a90817a8249f` (`Countermeasure: Druid`)
  - `6eab792d-c187-4a0d-86e7-39b0e2e41005` (`Countermeasure: Warlock`)
  - `7ccc7bf1-c781-4c0c-ba9b-22948c593aea` (`Countermeasure: Monk`)
  - `a134466e-333b-4bf5-a65b-6a717fdaf044` (`Countermeasure: Sorcerer`)
  - `ca44eafa-4c35-4103-889d-fd4df47f2835` (`Countermeasure: Wizard`)
  - `ef0ef83b-56af-4203-a984-28a74975adf5` (`Countermeasure: Fallback`)
- Added: `Spectator` aberration entry (`319efbbe-f9f3-4584-804e-3e17d47d1136`) to restore spectator coverage in ambush roster.
- Changed: Remapped `Mind Flayer` legendary template from `0c8a9514-15a9-4318-ab18-79234ff22e5e` to base illithid template `e4da9179-d4e9-4e3d-af1b-b2c287732e18` to avoid non-illithid presentation mismatch.

## 2026-02-24 23:25 UTC
- Changed: Humanoid roster cleanup from in-game validation:
  - Removed `Flaming Fist (Male, Ranger)` (`f4d79969-2e36-43b3-a9d4-2b93b47c3a77`) due naked bow variant.
  - Removed `Flaming Fist (Female, Ranger)` (`7b67816a-34e7-403d-b39d-508575c46aee`) due naked bow/warmaiden variant.
  - Removed `Flaming Fist (Male, Halberd)` (`254d5482-1788-4f2c-8e07-e5357eb44719`) due naked 2H variant.
  - Removed `Flaming Fist (Female, Halberd)` (`696525ec-6f0f-41f5-a568-41fc946618b1`) due naked 2H warmaiden variant.
  - Removed `Hobgoblin` (`9e48c3f1-55fa-4686-abc2-6f900a904a9a`) due nameless in-field presentation.
  - Removed `Hobgoblin (Variant)` (`d1686869-2610-494a-8b12-93bdd2d18bba`) due nameless in-field presentation.
- Changed: Reclassified Dark Justiciar base rows from `Humanoid` to `Undead` for type consistency:
  - `44762dc3-7e35-44b9-8f90-34981c291ffc` (`Dark Justiciar`)
  - `70c3189a-ec6a-420a-86b9-865c1fe4d73d` (`Dark Justiciar (Undead Caster)`)
  - `249a5352-3455-4f61-aaae-d37b7dd6aeb7` (`Dark Justiciar (Undead Melee)`)
  - `7e33f957-e22a-4654-b1bf-c06a269f3e53` (`Dark Justiciar (Undead Ranger)`)

## 2026-02-24 23:05 UTC
- Changed: Undead roster cleanup pass based on in-game visual/name validation (removed problematic entries):
  - `61d10729-273f-470c-9168-75e64dfcd079` (`Zombie Ogre` / `zom_ogre_f` naming issue)
  - `3335c504-3da5-4036-a483-d937bab16314` (`Vampire Spawn (Female)` variant issue)
  - `47f293a2-2c45-4774-9018-70edff7cccd0` (`Vampire Spawn (Githyanki Female)` head-only issue)
  - `23befed4-4436-4dd1-bbb7-26879bfc3198` (`Spectre (Base)` naked-human issue)
  - `e5876a98-c9d8-4f49-8941-24391b37d461` (`Feeble Spectre` nameless)
  - `b98a6799-845d-471d-a4a7-cc1a63141305` (`Mundane Spectre` nameless)
  - `d4d10639-efdc-4cde-8628-138fbd377617` (`Spectre (Unique Base)` nameless)
  - `39b43208-2632-45cf-b6c3-b24091ccb67c` (`Primordial Spectre` nameless)
  - `62dea8a9-f623-4ca8-867a-cefe27f741ac` (`Ghoul (Base)` nameless)
  - `8cb19321-6a8d-4a06-889b-8abb1b559fed` (`Ghoul (Ghast Base)` nameless)
- Kept: `ef4a24bb-5df2-4901-a31e-7c55e23d7554` (`Floating Undead Face`) per review despite display-name mismatch.
- Kept: `760f2d17-de55-4f38-83c1-279399b22096` (`Apostle of Myrkul`) as `LEGENDARY` `APEX`.

## 2026-02-24 22:35 UTC
- Changed: Reverted aggressive Beast cleanup from prior pass; restored templates that `typetest` flagged but `spawnuuid` validated as spawnable:
  - `d779b7f9-2c7b-4f85-b914-f09e00c117f2` (`Rat`)
  - `087f6eef-be8d-4070-b97d-5e261e71cb3d` (`Wolf`)
  - `d7ed7e22-a442-40fd-a537-94b5ae2ae7f9` (`Polar Bear`)
  - `aa60d129-8d11-4178-a22b-836062e86010` (`Skittle`)
  - `a07f34d9-f915-4d0f-baf6-e329541e3add` (`Orsu`)
  - `041f7544-d1fc-446d-b439-2108c02896ed` (`Ursa Major` variant)
  - `4ab10523-7e35-4a68-9afa-4839c484c579` (`Verres Major` variant)
  - `62fd6540-17dd-405e-b305-1d88d77e8a08` (`Lupus Optumus`)
- Kept: Removal of non-viable/immersion-breaking entries from the same pass:
  - dead-on-spawn `Owlbear Mate` (`7a87360f-6a37-4b66-96c8-446390f3c7b3`)
  - familiar/conjured frog-spider entries (`4521a4d1-0940-41de-b4c2-0314b8c8f32d`, `739b8af1-643d-4cc9-b5bd-3628cd3acc40`, `9100d053-dfad-4e6d-b638-dbc24b89644f`)

## 2026-02-24 22:20 UTC
- Fixed: Removed non-viable Beast templates that failed `!ea_test typetest Beast all` smoke spawning:
  - `62fd6540-17dd-405e-b305-1d88d77e8a08` (`Lupus Optumus`)
  - `a07f34d9-f915-4d0f-baf6-e329541e3add` (`Orsu`)
  - `d7ed7e22-a442-40fd-a537-94b5ae2ae7f9` (`Polar Bear`)
  - `d779b7f9-2c7b-4f85-b914-f09e00c117f2` (`Rat`)
  - `aa60d129-8d11-4178-a22b-836062e86010` (`Skittle`)
  - `041f7544-d1fc-446d-b439-2108c02896ed` (`Ursa Major` variant)
  - `4ab10523-7e35-4a68-9afa-4839c484c579` (`Verres Major` variant)
  - `087f6eef-be8d-4070-b97d-5e261e71cb3d` (`Wolf`)
- Fixed: Removed dead-on-spawn Beast entry `7a87360f-6a37-4b66-96c8-446390f3c7b3` (`Owlbear Mate`).
- Changed: Removed familiar/conjured Beast entries to reduce immersion-breaking names in ambushes:
  - `4521a4d1-0940-41de-b4c2-0314b8c8f32d` (`Frog`)
  - `739b8af1-643d-4cc9-b5bd-3628cd3acc40` (`Spider`)
  - `9100d053-dfad-4e6d-b638-dbc24b89644f` (`Conjured Spider (Shooting Spider Companion)`)

## 2026-02-24 21:55 UTC (Retroactive Backfill)
- Fixed: Beach tutorial completion now syncs across host var + scripted scenario state, preventing repeat wake-up ambushes on reload/older saves.
- Changed: Beach wake-up spawn-cap logic now uses Shadowheart party membership checks (`IsInPartyWith` + `DB_PartyMembers` fallback), with `1` goblin when not in party and `2` when in party.
- Added: MCM toggle `MCM_SkipBeachTutorialAmbush` to skip the one-time beach tutorial ambush and mark the tutorial flow complete.
- Added: Advanced balance controls wired end-to-end in MCM/settings sync: `MCM_StrictProgressionGates`, `MCM_UseCompositionGuards`, `MCM_BalanceProfile` (`MODDED_20`/`BG3_12`), `MCM_FodderPolicy` (`HARD_OFF_12PLUS`/`TAPERED`).
- Added: Strict progression gate enforcement using per-row template metadata (`resolvedTemplateLevel`, `minPartyLevel`, `maxPartyLevel`) with explicit fallback telemetry (`[ProgressionGate]`).
- Added: Composition guard system using `powerClass` (`FODDER`, `STANDARD`, `BRUISER`, `DREAD`, `APEX`) with profile/tier-aware caps and controlled relax fallback (`[PowerCaps]`).
- Added: Early low-level small-party composition safeguard (`[EarlyComp]`) to limit non-fodder concentration and reduce spike encounters.
- Changed: Hostility approach logic no longer forces attack calls in the movement helper path; behavior now prioritizes movement pressure to reduce pre-combat snap/jank.
- Added: Fast template QA console coverage: `!ea_test spawn type`, `!ea_test typelist`, `!ea_test typetest`, and `!ea_test spawnuuid`.
- Changed: Roster rows now carry normalized balance metadata (`balanceSource`, `powerClass`, `resolvedTemplateLevel`, `minPartyLevel`, `maxPartyLevel`) to support deterministic progression balancing.
- Added: Audit-driven roster expansion/rebalance passes across Beast, Undead, Construct, Elemental, and Fiend categories (with named/story filtering where required).
- Changed: Removed `Find Familiar`-based template `6f65f77f-4583-4dd7-be15-b737d0175061` from the ambush roster data.
- Added: Repeatable audit/balance tooling in `tools/`: `Generate-HuntedTemplateAudit.ps1`, `Apply-HuntedRowBalanceMetadata.ps1`, `Generate-HuntedCategoryNorbyteAudit.ps1`.
- Docs: Added/generated extensive audit artifacts under `..\Hunted Docs\HUNTED_*_AUDIT*.{csv,md}` and `..\Hunted Docs\HUNTED_*_DISCOVERY*.{csv,md}` for Beast/Undead/Aberration/Construct/Elemental/Fiend passes.
- Docs: Updated `..\Hunted Docs\HUNTED_BALANCE_PROGRESSION_IMPLEMENTATION_PLAN.md` with backlog coverage tracking for lower-volume types (Giant, Ooze, Celestial, Dragon, Fey).

## 2026-02-21 22:15 UTC
- Added: Runtime settings JSON mirror now uses a mod-identifiable file path: `Hunted_DynamicAmbushes_Revenge_System/hunted_settings.json`.
- Added: Live JSON import poll loop (`~1s`) so external `hunted_settings.json` edits can be applied during gameplay without restart.
- Added: Debounced JSON writes on server setting updates (`ApplyMCMSettings`, MCM save events, net sync paths, imported setting applies).
- Added: Import guard via last-seen raw payload tracking to avoid self-write feedback loops.
- Improved: JSON import applies through tracked MCM/runtime setting paths and triggers provider rebuild guards where needed.
- Fixed: Reduced chunk-local pressure in `EnemyAmbush_Systems.lua` by converting non-critical config/sync declarations to non-local file-scope symbols, addressing parse-stop risk near safety-check declarations.
- Changed: Extracted MCM + JSON config/sync runtime block from `EnemyAmbush_Systems.lua` into new module `EnemyAmbush_Config.lua` (Phase 1 refactor), with Systems now requiring that module and retaining existing call sites.
- Improved: `!ea_test spawn` now resolves key Systems exports at runtime and fails gracefully with explicit console messages if Systems failed to load.
- Changed: Beach bootstrap pacing updated to requested flow:
  - wait `10s` after `CRA_WakeUp_WakeUpDone` is detected,
  - show wake-up message box,
  - wait `30s` before scripted ambush spawn.
- Added: Beach bootstrap now gates on story flag `CRA_WakeUp_WakeUpDone` (`c72b29a9-dcbc-487a-8ddd-707d8de73494`) before arming.
- Added: Beach scripted spawn count now supports event-driven cap (`spawnCap`) passed into scenario runner; bootstrap currently uses Shadowheart progression proxy flag `CHA_ShadowHeartRecruitment_UsedDoor` (`91d77fbb-ddb7-365a-e5af-fd67ca1b99f3`) to choose `1` vs `2` goblins.
- Docs: RC tracking cleanup pass completed in:
  - `..\Hunted Docs\TODO.md`
  - `..\Hunted Docs\RC_TestPlan.md`
  - `..\Hunted Docs\RC_Stabilization_ExecutionPlan.md`
  - `..\Hunted Docs\RC_GO_CHECKLIST.md`
  - `..\Hunted Docs\HUNTED_JSON_CONFIG_IMPLEMENTATION_PLAN.md`
  - `..\Hunted Docs\HUNTED_SYSTEMS_REFACTOR_PLAN.md`

## 2026-02-19 14:25 UTC
- Improved: `!ea_test spawn direct` now prints the exact spawn path used during stress tests (`CreateOutOfSightAtDirection` vs `FindValidPosition+CreateAt`) for unambiguous verification.

## 2026-02-19 14:17 UTC
- Changed: `!ea_test spawn direct` debug mode now supports mass-spawn stress testing up to `30` enemies (`count` arg) instead of `5`.
- Added: `!ea_test spawn direct` now supports optional placement controls:
  - `spread` pattern (varied spawn distance with `forceFindValidPosition=true`) to reduce pileups.
  - optional spawn `staggerMs` delay (`0..5000`) between direct spawns.
- Docs: Updated `!ea_test spawn` help text to reflect direct mass-spawn and spread/stagger options.

## 2026-02-19 14:11 UTC
- Added: All non-champion ambushers now receive a short spawn-time movement assist (`MAG_MOMENTUM`, 18s) immediately after tier/trait setup to reduce long run-in pacing when spawned out of sight.
- Added: Movement assist now falls back to short `LONGSTRIDER` (18s) only if `MAG_MOMENTUM` cannot be applied on the active runtime.

## 2026-02-19 14:05 UTC
- Fixed: Beach wake-up bootstrap no longer hard-blocks forever on older/tutorial-origin saves when persistent mod vars are unavailable.
- Changed: Beach bootstrap now allows runtime fallback vars after a short retry window (`~60s`, 12 retries at 5s interval) and continues arming/executing safely.
- Added: Explicit rest-flow telemetry when fallback mode is used for beach bootstrap arming.
- Fixed: Beach onboarding and post-combat messageboxes now resolve localization handles robustly (`h...` and `h...;1`) via `ResolveTranslatedString`/`Ext.Loca` probes, preventing raw handle text from showing in UI.
- Removed: `Shadow-Cursed Needle Blight` summon template (`eccd3da9-5ca0-4403-806a-439d12978dcb`) from summon pool due broken combat presentation/animation behavior.
- Changed: Beach bootstrap pacing tightened:
  - initial bootstrap check delay reduced (`8s -> 3s`),
  - retry interval reduced (`5s -> 2s`),
  - fallback-vars unlock threshold reduced (`~60s -> ~16s`),
  - beach spawn delay after arming reduced (`30s -> 8s`).
- Fixed: Beach scripted spawns now honor controlled distance placement (skip `CreateOutOfSightAtDirection` when `forceFindValidPosition=true`) to avoid unexpectedly far first-wave spawns.
- Tuned: Beach goblin scripted `spawnDist` reduced (`8 -> 6`) for closer, more immediate wake-up encounter pacing.

## 2026-02-19 13:20 UTC
- Changed: Moved `Hamster` (`MiniatureGiantSpaceHamster_Boo`) out of `COMMON` and into the `VETERAN` summon band table.
- Changed: Added an in-combat deferred-support distance guard in `EA_MakeAmbushHostile` so far supports do not run aggressive catch-up retries while the player is already in active combat.
- Changed: `EA_CommandApproachAndStrike` now disables `CharacterMoveToPosition` fallback during active player-combat retries (keeps only `CharacterMoveTo` in that path) to reduce snap-like catch-up movement.
- Docs: Updated RC tracking docs with a current evidence snapshot and in-progress stabilization status:
  - `..\Hunted Docs\RC_TestPlan.md`
  - `..\Hunted Docs\RC_Stabilization_ExecutionPlan.md`

## 2026-02-18 12:32 UTC
- Added: Region debugging commands for live safe-hub/blocklist discovery:
  - `!ea_test region` (one-shot raw + canonical region safety snapshot)
  - `!ea_test regionwatch on [seconds]|off|once` (walk-around logger, prints on sublevel/region change)
- Added: Region debug output includes `raw`, `canonical`, `rawBlocked`, `canonicalBlocked`, `camp`, and `safe` fields.

## 2026-02-17 16:18 UTC
- Added: Raw sublevel safety blocks for friendly social hubs so queued ambushes stay deferred until the player leaves:
  - `WLD_DruidSubs_*` (Emerald Grove druid enclave)
  - `WLD_DenSubs_*` (Emerald Grove Hollow/tiefling enclave)
  - `SCL_Haven_*` (Last Light/Haven hub)
  - `BGO_FriendlyArmInn_*` (friendly inn hub)
- Changed: These hubs now use the same existing defer flow (`queued until safe`) instead of spawning immediately when a rest timer fires there.

## 2026-02-17 15:18 UTC
- Removed: `Flaming Fist (Male, Melee)` summon template (`e135793f-301a-47a6-9880-c9d766e17df7`) from vanilla summon data due poor/naked loadout quality.
- Changed: Disabled `EnterCombatFailed` teleport fallback by default (`EA_ENTER_COMBAT_ENABLE_TELEPORT_FALLBACK=false`) to eliminate visible in-combat warp jank.
- Added: Enter-combat retry movement assist now applies `MAG_MOMENTUM` from retry tier 4 onward instead of teleporting.
- Improved: Surprise roll source normalization now uses normalized GUID (`EA_NormalizeUUID(source)`) before versus-skill checks, with debug showing both raw and normalized source when invalid.

## 2026-02-17 14:52 UTC
- Changed: Cleaned hostile spawn display names for immersion by removing summon-style labels (`Find Familiar`, `Conjure`, `Summoned`) from ambush entries.
- Changed: Renamed cat/dog entries to `Feral Cat` and `Feral Dog`.
- Changed: Updated familiar-style entry names to plain creature names (`Crab`, `Frog`, `Raven`, `Rat`, `Spider`, `Hamster`).

## 2026-02-17 14:49 UTC
- Changed: `EA_MakeAmbushHostile` now avoids forced combat-join calls (`SetHostileAndEnterCombat` / `EnterCombat`) while the player is already in combat (default), reducing visible snap/warp joins.
- Added: In-combat join fallback now favors movement pressure (`MAG_MOMENTUM` + approach/attack) instead of forced combat insertion.
- Added: Debug reason when forced join is intentionally skipped due active player combat.

## 2026-02-17 14:34 UTC
- Fixed: Surprise roll source resolution now prefers a live source handle (raw handle first, normalized GUID second) before calling `RequestPassiveRollVersusSkill`; this prevents false `source_invalid` skips that were forcing weak fallback rolls.
- Improved: Surprise debug telemetry now logs raw/normalized/resolved source identifiers when versus-skill checks are skipped.
- Changed: Removed `Flaming Fist (Female, Melee)` template (`23390aab-1411-42de-80b9-14043cc50bc5`) from summon data.
- Added: Replaced legacy melee Flaming Fist picks with safer parent variants:
  - `Flaming Fist (Male)` (`f37e77ff-18f9-466f-a860-53d3edbadcd8`)
  - `Flaming Fist (Female)` (`38afed9e-1c42-41e5-86f9-294bae0b5ff4`)

## 2026-02-17 12:24 UTC
- Fixed: Scripted scenario checks in `TriggerAmbush` now require persistent mod variables to be available; this prevents one-shot scenarios (including beach wake-up) from running out of transient fallback state during early load windows.
- Fixed: `EA_Vars()` now performs a one-time merge from runtime fallback state into persistent mod vars when backend access is restored, preserving session writes made while mod vars were temporarily unavailable.
- Added: Surprise direct-fallback debug output now includes a structured failure reason summary (`versus_failed`, `passive_failed`, `*_api_missing`, etc.) to diagnose runtime-specific Osiris roll signature mismatches faster.

## 2026-02-17 12:19 UTC
- Fixed: COMMON tier labels are now fully hidden at runtime by skipping visible `EA_TIER_COMMON_*`/`EA_TIER_COMMON_CX_*` status application (`EA_SelectTierStatus` now returns `nil` for COMMON).
- Changed: COMMON scaling buffs are now applied via direct `AddBoosts` bracket logic (L1/L7/L11, CX-aware) instead of visible tier statuses.
- Fixed: Surprise roll request now uses `RollType="RawAbility"` for `RequestPassiveRollVersusSkill` and probes both full 8-arg and legacy variants.
- Added: Proper `RequestPassiveRoll` fallback chain (7-arg + legacy 5-arg) using `DIFFICULTYCLASS` id `DC_Legacy_10` when versus-skill API is unavailable on a runtime.
- Added: Detailed surprise API diagnostics for missing functions, invalid source subject, and fallback call failures.

## 2026-02-17 11:30 UTC
- Fixed: Surprise perception checks now call `RequestPassiveRollVersusSkill` with the documented full signature (`RollType`, both skills, both advantage args, event id) in `EnemyAmbush_Systems.lua`.
- Added: Runtime compatibility probe for legacy 6-argument `RequestPassiveRollVersusSkill` signature if the full signature is not accepted.
- Changed: Removed broken `RequestPassiveRoll` surprise fallback probes (invalid runtime signatures were causing repeated errors); surprise now falls back directly to legacy apply only if versus-skill roll APIs are unavailable.
- Changed: `RollResult` handling now treats only `resultType == 0` as failure (so `1=success` and `2=cancelled` do not apply `SURPRISED`).

## 2026-02-17 10:21 UTC
- Changed: Added party-size-aware overlevel delta roll logic in `EnemyAmbush_Systems.lua` (`EA_RollOverlevelDelta`) so low-level 1-2 member parties roll `VETERAN` less often.
- Changed: Added early small-party tier-pool safeguard in `PickEnemyTemplate`: `VETERAN` requests for low-level duos now restrict to `VETERAN` band only (prevents `ELITE` spillover picks like Flaming Fist Defender from veteran rolls).
- Changed: Added early small-party spawn-level cap in `EA_GetScaledAmbushLevel` so high-native templates can be downleveled in early duo brackets (instead of always preserving native high level).
- Changed: Updated spawn-level callsites to pass party context into scaling (`EA_GetScaledAmbushLevel(..., playerLevel, GetPartySize(player))`).

## 2026-02-17 10:10 UTC
- Changed: Hidden `COMMON` tier status presentation only (no visible `Common Ambusher` label/description/icon), while keeping `VETERAN`/`ELITE`/`LEGENDARY`/`CHAMPION` tier visibility unchanged.
- Changed: `EA_COMMON_SURVIVABILITY`, `EA_TIER_COMMON_L1/L7/L11`, and `EA_TIER_COMMON_CX_L1/L7/L11` now use empty icon values in `Status_EnemyAmbush.txt`.
- Changed: Common-tier localization handles (`h4c8e2a1gbf9dg4f8ag9a1bg6c0d1122aa10`, `h7b2d9c5ga1e3g4f9bg8c2dg5e6f3344bb20`) are now empty in both English localization files.

## 2026-02-17 10:01 UTC
- Fixed: `EA_SR_RETRY_*` / `EA_LR_RETRY_*` timers no longer mis-parse as fresh `EA_SR_*` / `EA_LR_*` timers in `EnemyAmbush_Events.lua` (prevents retry-name prefix growth like `RETRY_RETRY_*` and runaway pressure gains during combat).
- Changed: `EnterCombatFailed` teleport rescue is now stricter in `EnemyAmbush_Events.lua`:
  - requires final retry tier,
  - requires at least `~9s` failed-combat age,
  - requires enemy-player distance `>=16m`,
  - still blocked if party is already in combat.
- Changed: Low-level small-party weighting smoother in `EnemyAmbush_Systems.lua` (for party size `<=2` at level `<=3`, overleveled templates are heavily downweighted), reducing high-spike picks like Dire Wolf in early fights.
- Changed: Dire Wolf summon templates (`4c928f84-e72e-4a10-9e15-3549f2c65dc0`, `67f39af3-b9ea-4e95-8237-7aa4f6bd7cef`) are now explicitly `spawnBand = VETERAN` in `EnemyAmbush_Data_Summons_Vanilla.lua` (removed from COMMON pool).
- Changed: `!ea_test spawn random` now bypasses scripted scenarios/tutorial/cooldown (`TriggerAmbush(..., { skipScripted=true, skipTutorial=true, skipCooldown=true })`) so debug random tests are deterministic.
- Added: Optional flow label support in `TriggerAmbush` for clearer rest-flow diagnostics (`flowLabel`).
- Changed: First tutorial popup text moved to localization and shortened to non-spoilery copy (`You are hunted. Stay vigilant.`) via new handle `h63b0e40eg6c0ag4d86gb8f5g5d2f58f91c91`.
- Changed: Beach post-fight onboarding text adjusted to global scope (`No place is truly safe ... Ambushes may now strike as you travel ... Be careful where you rest.`).

## 2026-02-17 07:17 UTC
- Changed: Shortened pre-ambush warning localization entries (`h8a1b2c3dg4e5fg6a7bg8c9dg000000000001` through `...161`) in `Localization/English/english.xml` and `Localization/English/english.loca.xml` for faster readability.
- Kept: Warning text source remains localization-driven (no hardcoded warning prose in Lua).

## 2026-02-17 07:14 UTC
- Changed: Reverted pre-ambush warning text selection back to localization-driven flow (`EA_AMBUSH_WARNINGS` + loca handle resolution) and removed the temporary hardcoded warning text generator.
- Changed: Warning fallback now uses a localization handle (not hardcoded prose); if warning localization is unavailable, warning notification is skipped with debug log.

## 2026-02-17 07:12 UTC
- Changed: Kept `ShowNotification` only for pre-ambush warning delivery (`EA_ShowTimedWarning` in `EnemyAmbush_Systems.lua`); removed all other notification usage paths.
- Changed: Pre-ambush warnings continue to use localization entries; no non-localized warning prose is used.
- Changed: Removed extra warning text expansion (tier telegraph sentence + distance suffix) to keep warning popups short.
- Changed: Beach wake-up onboarding message now starts with `You are hunted.` and uses a more immersive warning line in the message box.
- Changed: Non-warning notification flows in scenario/journal/utils are now suppressed (debug log only where useful) instead of using `ShowNotification`.

## 2026-02-15 14:30 UTC
- Changed: Removed beach wake-up VO/taunt presentation path from combat start/turn chatter for `EA_SCN_BEACH_WAKEUP` (ambush spawn behavior unchanged).
- Added: Beach bootstrap now opens an immersive pre-ambush message box when the scripted encounter arms (30s before spawn).
- Added: Message-box telemetry listeners in `EnemyAmbush_Events.lua` for `MessageBoxClosed` and `MessageBoxYesNoClosed`.
- Added: `!ea_test msgbox` debug commands to test `OpenMessageBox`/`OpenMessageBoxYesNo` in-game:
  - `!ea_test msgbox open [text]`
  - `!ea_test msgbox yesno [text]`
  - `!ea_test msgbox demo [text]`

## 2026-02-15 13:12 UTC
- Changed: Final beach VO test pass now layers explicit goblin encounter/combat sound events with bark playback (`UniqueNPC_GOB_GoblinKing_Combat_Shout`, `UniqueNPC_GOB_GoblinPriest_Combat_Shout`, `GOB_Festivities_AD_Goblin_001/002_Combat`, `GOB_Checkpoint_Goblin_Klaw_Attack`) for maximum audibility.
- Added: Beach scripted spawns now persist `scriptedScenario` into spawned enemy metadata so event handlers can apply scenario-scoped presentation logic safely.
- Added: Beach-only taunt text fallback in combat-start/turn chatter (`DisplayText` with `ShowNotification` fallback) so players get visible encounter flavor even if voice bark resources are inaudible on their setup.

## 2026-02-15 12:53 UTC
- Fixed: Reduced chunk-local pressure in `EnemyAmbush_Systems.lua` around tier/spawn helpers by converting several late-file locals to non-local helpers/constants (`EA_TIER_ORDER`, `EA_TIER_FROM_INDEX`, `EA_NormalizeTierLabel`, `EA_DowngradeTier`, `EA_CopyRollWithTier`, `EA_GetMinAmbushTemplateCostForPartyLevel`, `EA_GetEffectiveAmbushTemplateCost`, `ExecuteAmbushSpawn`).
- Impact: Addresses BG3SE parse failure `too many local variables (limit is 200)` that was preventing full script load and causing beach bootstrap retries with `scenario_not_ran:spawn_function_unavailable`.

## 2026-02-15 12:36 UTC
- Added: Beach goblin intro now prioritizes checkpoint/story goblin dialog bark resources (`GOB_Checkpoint_Trespassing`, `GOB_Checkpoint_CliffWarning`, `GOB_Checkpoint_TopCliffWarning`, `GOB_Checkpoint_AlarmUsedReaction`) before bravado fallback lines.
- Added: Beach turn-chatter bark pool now includes checkpoint guard/backup dialog resources for more spoken-line variety in the first combat rounds.
- Improved: Bark playback now retries multiple bark candidates per cue (combat-start + turn chatter) so one non-playable line does not result in silence.
- Research: Confirmed via BG3 Search data that the selected checkpoint bark GUIDs are valid `DialogResourceId` entries tied to goblin checkpoint dialog timelines.

## 2026-02-15 12:27 UTC
- Changed: Beach wake-up goblin VO is now line-first: removed forced `Goblin_Voice_*` sound overlays from combat-start and turn chatter.
- Changed: Beach goblin bark pools now use only `GOB_Bravado_Goblin_001/002/003` for more taunt-like delivery (dropped generic `GLO_Goblin_CombatVocals` from this scripted intro).
- Kept: `combatStartNoFallback=true` for beach goblins so non-voice fallback stingers do not replace immersive taunt VO when bark resources are available.

## 2026-02-15 11:57 UTC
- Added: Beach goblin scripted spawns now carry first-turn combat chatter settings (`combatTurnBarks`, `combatTurnSounds`, `combatTurnLimit=2`) so early surprised rounds can play additional ambient VO.
- Added: Scenario/system payload plumbing for per-spawn turn chatter fields (`combatTurnBarks`, `combatTurnSounds`, `combatTurnSoundAlways`, `combatTurnEnemyOnly`, `combatTurnLimit`).
- Added: `TurnStarted` chatter playback hook that plays random bark/sound on configured early turns and then auto-disarms.
- Fixed: Turn chatter combat-key matching now normalizes and GUID-matches combat IDs to avoid missed playback when `CombatStarted` and `TurnStarted` expose different key formats.

## 2026-02-15 12:47 UTC
- Added: Beach goblin intro now includes combat-start sound backups (`Goblin_Voice_Female_Attack`, `Goblin_Voice_Male_Attack`, `Goblin_Voice_Mixed_Idle_Combat`) to ensure audible VO cues during combat start testing.
- Added: Scenario spawn rolls now support `combatStartSounds` and `combatStartSoundAlways` payload fields.
- Added: Combat-start cue system now plays per-scenario sound backups when configured (either always or when bark fails) and logs the selected sound in debug mode.

## 2026-02-15 12:39 UTC
- Changed: Beach goblin combat bark list now uses dialog resource GUIDs instead of symbolic names for higher `StartVoiceBark` compatibility.
- Added: Debug telemetry for combat-start bark attempts (`enemy`, selected bark id, and call result) to speed up VO troubleshooting in live logs.

## 2026-02-15 12:06 UTC
- Changed: Beach wake-up scripted encounter now spawns two low-threat goblins (female/male basic guard templates) instead of frog/crab familiars.
- Added: Scenario-specific combat-start bark list support for scripted spawns (`combatStartBarks`) so encounters can drive explicit bark/dialog choices.
- Added: Beach wake-up goblins now use goblin dialog bark IDs on combat start (`GLO_Goblin_CombatVocals`, `GOB_Bravado_Goblin_001/002/003`).
- Added: Scenario option to suppress generic combat-start fallback sounds when bark playback fails (`combatStartNoFallback=true`) for cleaner VO testing.

## 2026-02-15 00:36 UTC
- Changed: Beach bootstrap now has a true delayed execution phase (`EA_BOOTSTRAP_BEACH_EXEC`) so the scripted beach ambush **spawns after** a 30s delay, not immediately.
- Added: Beach bootstrap arming/retry state tracking (`EA_BeachBootstrapArmed`, host pinning, exec retries) with explicit rest-flow logging for delayed execution.
- Changed: Beach scripted scenario onboarding now runs after combat prompt instead of pre-spawn, reducing early fast-fade notification noise.
- Added: Beach scripted spawns now set `noReputation=true` so the intro fight does not alter creature reputation or trigger immediate rep-journal spam.
- Improved: Spawn integrity watchdog now respects per-spawn grace windows (`preCombatGraceMs`) and `disableAggressiveAdvance` before deleting non-combat entities as `NeverEnteredCombat`.
- Added: Journal onboarding supports a silent mode (`suppressNotify=true`) for scenarios that use custom message-box onboarding.

## 2026-02-15 00:24 UTC
- Changed: Beach scripted ambush now uses a 30-second pre-combat grace window (`preCombatGraceMs=30000`) so combat does not snap-start immediately on wake-up.
- Changed: Added scripted spawn flag `disableAggressiveAdvance` and wired it into hostility logic to suppress forced chase/attack movement for marked spawns (reduces visible teleport/jank).
- Added: Beach scenario now shows a post-combat `OpenMessageBox` onboarding prompt (one-time) instead of relying on fast-fading notifications.
- Changed: Beach scenario intro/completion notification text spam disabled; onboarding messaging is now delivered through the post-combat prompt.
- Fixed: Removed fragile `QuestAdd` call attempts from journal update path to stop repeated `No function named 'QuestAdd'` runtime errors.
- Fixed: Surprise fallback passive-roll call now tries both known API signatures to avoid `String expected for argument 4, got number` errors.

## 2026-02-15 00:09 UTC
- Fixed: Added resilient `EA_Vars()` runtime fallback in `EnemyAmbush_Utils.lua` so systems continue operating when `Ext.Vars.GetModVariables` is temporarily unavailable.
- Fixed: `SaveReputation` / `LoadReputation` in `EnemyAmbush_Systems.lua` now use `EA_Vars()` instead of direct raw `Ext.Vars.GetModVariables` calls, preventing repeated early-session `ModVariables unavailable` dead paths.
- Added: Fallback-mode debug traces for `EA_Vars` backend loss/restore to make save/runtime backend issues visible without hard failures.

## 2026-02-14 23:52 UTC
- Fixed: Beach bootstrap now force-runs scripted scenario execution once readiness checks pass, instead of re-running a second context gate that could cause repeated `scenario_not_ran`.
- Added: Beach bootstrap retry logs now include scenario reason suffixes (for example `scenario_not_ran:no_spawned_entities`) for faster field debugging.
- Improved: `EnemyAmbush_Scenarios.lua` now uses dynamic function lookups (`EA_*`) with safe fallbacks to avoid stale/nil cached references during load-order edge cases.
- Improved: Scripted scenario runner now emits specific non-fatal failure reasons (`state_unavailable`, `context_mismatch`, `no_spawned_entities`, etc.) and debug lines for failed per-entry spawns.
- Tuned: Beach wake-up scripted spawn entries now set `spawnDist=8` to increase near-beach placement reliability.

## 2026-02-14 23:39 UTC
- Fixed: Added nil-safe dynamic wrappers for `EA_Pending`, `EA_Spawned`, and `EA_NormalizeUUID` in `EnemyAmbush_Systems.lua` to prevent late-load nil callback crashes.
- Fixed: Hardened pending ambush maintenance paths in `EnemyAmbush_Systems.lua` (`CleanupPendingAmbushes`, `StorePendingAmbush`, `EA_RelaunchPendingTimersOnLoad`) to tolerate invalid/non-table pending state.
- Fixed: Strengthened `EnemyAmbush_Events.lua` wrappers for `EA_Pending`/`EA_Spawned`/`EA_NormalizeUUID` with guarded `pcall` and persistent table fallback.
- Fixed: Added safe fallback wrapper for `CleanupPendingAmbushes` in `EnemyAmbush_Events.lua` when Systems export is not yet available.

## 2026-02-14 23:33 UTC
- Fixed: Deferred beach bootstrap `TimerLaunch` out of `SessionLoaded` restricted context in `EnemyAmbush_Events.lua` to prevent `Attempted to call Osiris function in restricted context`.
- Fixed: Added nil-safe fallbacks for `EA_Spawned` and `EA_NormalizeUUID` in `EnemyAmbush_Events.lua` to prevent cascading nil upvalue crashes if exports are temporarily unavailable.
- Fixed: Hardened MCM net-sync handling in `EnemyAmbush_Systems.lua` so `EnemyAmbush.Settings` is initialized before indexing in `bulk`/`one` sync paths.
- Fixed: Hardened legacy reputation persistence in `EnemyAmbush_Systems.lua` (`SaveReputation` / `LoadReputation`) with guarded mod-var access so missing/unavailable mod-var classes fail gracefully instead of crashing.

## 2026-02-14 18:46 UTC
- Fixed: Resolved BG3SE Lua parse failures caused by chunk-local limit (`too many local variables`) in `EnemyAmbush_Systems.lua` and `EnemyAmbush_Utils.lua`.
- Changed: Inlined new budget/min-enemy helper logic in `EnemyAmbush_Systems.lua` to avoid adding extra top-level local function symbols.
- Changed: Converted metrics helper declarations in `EnemyAmbush_Utils.lua` to non-local function declarations to reduce chunk-local pressure.
- Fixed: Hardened `!ea_test` commands against missing Systems exports by adding `EA_BuildActiveListSafe()` in `EnemyAmbush_DebugCommands.lua`.
- Fixed: `!ea_test verifytemplates` no longer crashes when `BuildActiveSummonList` is unavailable; it now reports gracefully and continues.

## 2026-02-14 14:26 UTC
- Added: Wave 1 curated summon pool expansion (+28 vanilla templates) focused on safe combat entries across `COMMON`, `VETERAN`, `ELITE`, and `LEGENDARY`.
- Added: New families include Bhaal cultists, Githyanki variants, Hobgoblin Devastator, Mimic, Intellect Detonator, Shadow, Skeleton Hound, Mind Flayer Caster, Cloaker Phantasm, Mummy (Create Undead), and Steel Watchers.
- Changed: Spawn mix now has additional mid/high-tier variety without reintroducing champion overlap in summon data.

## 2026-02-14 12:44 UTC
- Changed: Moved vanilla `CHAMPION_ONLY` summon entries out of summon data and into `EnemyAmbush_Data_Champions_Vanilla.lua` (champions now owned by champion data only).
- Changed: `EnemyAmbush_Data_Summons_Vanilla.lua` keeps an empty `CHAMPION_ONLY` band for compatibility, but no summon entries are `championOnly=true`.
- Changed: Champion spawn selection now uses champion providers (`EnemyAmbush.GetChampionTemplate`) as primary source.
- Changed: Removed legacy champion provider registration from `EnemyAmbush_Systems.lua` (`CHAMPION_TEMPLATES` now debug/static fallback only).
- Added: Data audit warning text for accidental `championOnly` entries in summon pools.

## 2026-02-14 11:57 UTC
- Changed: Refactored vanilla data into split modules:
  - `EnemyAmbush_Data_Summons_Vanilla.lua`
  - `EnemyAmbush_Data_Champions_Vanilla.lua`
  - `EnemyAmbush_Data.lua` now acts as entrypoint/registration + audit only.
- Changed: Summon data is now structurally grouped by resolved band:
  - `COMMON`, `VETERAN`, `ELITE`, `LEGENDARY`, `CHAMPION_ONLY`.
- Added: Stable exported compatibility surface preserved:
  - `SummonList_Vanilla`, `SummonList_L1_3`, `SummonList_L4_5`, `SummonList_L6_9`, `SummonBuckets_Vanilla`,
  - `ChampionList_Vanilla`, `ChampionsByType_Vanilla`.
- Changed: Canonical field order normalized in new data files:
  - `template, name, creatureType, level, weight, status, spawnBand, championOnly`.
- Added: Data audit now reports grouped band counts, bucket counts, explicit band/championOnly usage, duplicate/conflict counts, and summon/champion overlap counts.

## 2026-02-14 11:41 UTC
- Changed: Tier pool rules now isolate `COMMON` entries (`COMMON` pulls `COMMON` only).
- Changed: `VETERAN` and `ELITE` now share one selection pool (`VETERAN+ELITE`).
- Added: Strict tier lock fallback messaging for `COMMON` and `VETERAN+ELITE` pools in debug logs.
- Added: Active pool debug band summary (`COMMON`, `VETERAN`, `ELITE`, `LEGENDARY`, `CHAMPION_ONLY`) after summon list rebuild.
- Changed: Summon data structure now builds level buckets (`L1_3`, `L4_5`, `L6_9`) and merges them into canonical `SummonList_Vanilla`.
- Added: Data audit summary on load for resolved band counts, bucket sizes, and duplicate/conflict detection.
- Fixed: `Giant Shadow Creeper` duplicate creature-type conflict (normalized to `Plant`).
- Fixed: `ChampionsByType_Vanilla` is now built before API registration/fallback queue usage.

## 2026-02-14 11:08 UTC
- Added: Debug console command `!ea_test dragondebt` (alias `!ea_test dragonqueue`) for compact dragon retaliation debt telemetry.
- Added: Dragon debt debug output fields: `state`, `minLevel`, `preludeCount/preludeMax`, `lastCycle`, current world-rep cycle, debt kind, and armed champion type.

## 2026-02-14 11:05 UTC
- Changed: Dragon first tracked world kill now queues a dormant retaliation debt instead of immediate guaranteed champion arming.
- Added: Dragon debt queue metadata for staged unlock and pacing (`state`, `minLevel`, `preludeCount`, `preludeMax`, `preludeCooldownCycles`).
- Added: Dragon debt prelude ambushes on long rest (small draconic packs) before late-game unlock.
- Added: Dragon debt prelude guards to preserve immersion: only in dragon-appropriate regions and never in shadow-cursed regions.
- Changed: Guaranteed champion arming now uses the triggering player context so level-gated debt unlock checks are accurate.
- Added: Special retaliation debt cap (`3`) for future scripted debt expansion.

## 2026-02-14 10:50 UTC (Backfilled)
- Added: World vanilla kills grant reputation only for templates present in the tracked ambush template index.
- Added: World-kill reputation cap per long-rest window (`per type = 3.0`, `global = 6.0`, `step = -0.5`).
- Added: Per-creature-type pressure from world kills (`+8`) and ambush kills (`+12`).
- Added: Type pressure spend when that creature type successfully ambushes (`-20`).
- Added: Anti-repeat variety penalty through recent ambush type history.
- Added: Initial dragon first-kill retaliation queue hook (superseded by dormant debt model above).

- Reclassified `Guardian of Faith` out of the low-level COMMON Construct pool. It now spawns as a `VETERAN` `BRUISER` with `minPartyLevel = 6`, matching observed live threat more closely and preventing level-3 Construct ambushes from rolling an 80+ HP anchor.
- Extended the deferred zero-distance `CreateOutOfSightAtDirection` acceptance path to `AUTO` placement mode. In runtimes where immediate OOS position reads settle as `0.00`, `AUTO` can now keep successful OOS probes instead of short-circuiting to `FindValidPosition`.
