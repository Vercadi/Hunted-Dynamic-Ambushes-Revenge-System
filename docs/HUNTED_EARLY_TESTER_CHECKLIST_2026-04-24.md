# Hunted Early Tester Checklist - 2026-04-24

Scope: pre-Nexus beta checks for the currently deferred runtime items. This checklist is intentionally short; capture full Script Extender logs for any failure.

## Setup

- Install the current early tester build with `BG3 Script Extender` version `30+` and `BG3MCM`.
- Use a clean save or a save where Hunted is already installed and stable.
- In MCM, enable `Debug Mode` for diagnostic runs.
- In the server Script Extender console, run `!ea_test debug on`, `!ea_test telemetry on`, `!ea_test verify`, `!ea_test verifystatuses`, and `!ea_test settings`.

## 1. Cooldown And Save/Load

Goal: prove a real ambient ambush starts cooldown and that cooldown survives reload.

- Use a normal ambient/rest-triggered ambush path, not only `!ea_test spawn random`.
- After the ambush starts, save and reload.
- Immediately try another cooldown-gated rest/ambient trigger.
- Expected: immediate re-ambush is blocked while cooldown remains active.
- Capture logs containing cooldown, `EA_LastAmbushTime`, `cooldown_active`, or any cooldown stamp retry messages.

No-ship if: a real ambush occurs, you reload soon after, and another real cooldown-gated ambush can trigger immediately.

## 2. MCM CUSTOM + Advanced Settings

Goal: prove `CUSTOM` preset values are not overwritten by toggling Advanced mode.

- Select a normal preset such as `Marked`.
- Enable `Advanced Mode`.
- Change one preset-owned value so the visible preset becomes `CUSTOM`.
- Save, reload, and toggle `Advanced Mode` off/on.
- Expected: the custom value remains the same after reload and Advanced toggles.
- Capture `!ea_test settings` before save and after reload.

No-ship if: a `CUSTOM` value resets to the base preset after reload or Advanced toggling.

## 3. Time-in-Danger Pacing

Goal: prove Time-in-Danger does not begin accumulating during the first `30` minutes after ambush/cooldown start.

- Trigger a real ambush and stay in a dangerous eligible area.
- Watch telemetry for `postAmbushGateMs`, `gateStartMs`, and Time-in-Danger accumulation.
- Expected: Time-in-Danger remains gated for the first `30` minutes after the ambush stamp, then resumes afterward.
- Also verify preset cooldown feel: `Hunted` should be at least about `30` minutes, `Wayfarer` should be about `60` minutes or more.

No-ship if: Time-in-Danger starts accumulating immediately after a real ambush.

## 4. Level 5-6 Scaling

Goal: prove early-mid ambushers no longer feel like level-1 status packages.

- Test with a level `5` or `6` party.
- Compare at least `Marked` and `Hunted`.
- Run a few real or debug ambushes and capture `[TierDurability]` logs.
- Expected logs include `threat`, `statusThreat`, `offset`, `preset`, `tierBias`, `cx`, and selected `status`.
- Expected behavior: non-CX normal tiers can select level `5` tier packages, and harder presets can select stronger status packages through the hidden offset.

No-ship if: level `5-6` ambushers consistently use only level `1` tier statuses or difficulty presets feel identical.

## 5. Rest Ambushes

Goal: prove short-rest and long-rest ambush paths still work without duplicate schedules.

- Test one short-rest ambush in an allowed region.
- Test one long-rest ambush in an allowed region.
- Repeat a rest while cooldown should still be active.
- Expected: one schedule per rest flow, no duplicate ambush wave, and cooldown blocks immediate repeat triggers.

No-ship if: one rest creates duplicate schedules/spawns or cooldown is ignored.

## 6. Save/Load During Pending Ambush

Goal: prove pending delayed/staggered ambush state survives reload.

- If practical, save while a delayed/rest ambush has started but before all support spawns finish.
- Reload and continue.
- Expected: the spawn queue resumes or resolves cleanly, reaches intended count, and does not duplicate already spawned enemies.
- Useful logs: `SPAWN_QUEUE`, `Delayed ambush`, `spawned=`, `target_met`, `combat_continue_limit`, and `EA_Dirty`.

No-ship if: reload causes an under-spawn, duplicate wave, orphaned visible neutral enemies, or a Lua error.

## 7. API Smoke

Goal: prove the documented compatibility surface is callable by an external server-side patch.

- Include `API.md` in the tester docs bundle.
- In a server-side compatibility patch, confirm `EnemyAmbush.API_VERSION` and `EnemyAmbush.API.API_VERSION` both report `1.5.0`.
- Register/list/query/unregister one enemy provider.
- Register/list/query/unregister one champion provider.
- Call `GetAmbushState()` in a normal loaded save.
- Call `SetReputation()`, `GetReputation()`, and `ModifyReputation()` on a test creature-type key.
- Trigger one one-shot `TriggerCustomAmbush(...)` with `spawn.mode = "custom_entries"` in an eligible non-camp, non-combat, non-blocked area.
- If testing external templates with `Ambush XP < 100%`, register an XP-zero clone through `RegisterXPCloneMapping(...)` and confirm the template remains eligible.
- Optional: register and trigger one public external `RegisterAmbushDefinition(...)` using `custom_entries`.

No-ship if: documented API calls are missing, version fields are missing or wrong, provider snapshots mutate live state unexpectedly, `TriggerCustomAmbush(...)` fails in a valid area with a valid root template, or unsupported fields are silently required for the smoke path.

## What To Send Back

- Full Script Extender runtime log.
- Save context: level, party size, region, preset, and whether Combat Extender was enabled.
- Which checklist item failed or passed.
- Exact in-game observation, especially if logs look healthy but gameplay felt wrong.
