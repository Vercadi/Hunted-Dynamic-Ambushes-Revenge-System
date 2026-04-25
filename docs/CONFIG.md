# Config

## Supported settings model

- supported player-facing settings path: `BG3MCM`
- supported maintainer-facing runtime settings path: server-side MCM/startup apply flow
- `BG3MCM` is required; no supported `BG3MCM`-absent settings fallback remains

This is the only supported settings authority model for the current release track.

## Effective precedence

High-level order:

1. built-in defaults
2. persisted mod state and `BG3MCM` startup pull
3. live `BG3MCM.MCM_Setting_Saved` updates

## Supported workflows

- normal players must install `BG3MCM`
- maintainers should validate runtime interpretation with `!ea_test settings`
- if `BG3MCM` is absent, startup is unsupported and the mod now logs a requirement error instead of falling back to persisted settings

## Unsupported workflows

- `hunted_settings.json`
- manual JSON settings import
- JSON watch/poll settings workflows
- `!ea_test configpoll`

These are no longer part of the supported runtime settings model.

## Operational notes

- Phase 2 Task 1 removed the runtime settings JSON mirror/import/watch path.
- Phase 2 settings authority consolidation is complete in the repo:
  - raw settings owner: `EnemyAmbush_Utils_Settings.lua`
  - normalization-rules owner: `EnemyAmbush_MCMContract.lua`
  - canonical apply path: `EA_ApplyOwnedRuntimeSettingsBatch()` / `EA_ApplyOwnedRuntimeSetting()`
  - shared read API: `EA_ReadSettingRaw()` / `EA_ReadSettingBool()` / `EA_ReadSettingNumber()`
- `MCMSettings` remains as an internal persisted mirror for save continuity and debug inspection alongside the supported `BG3MCM`-driven path; it is not a supported standalone settings authority or fallback mode.
- The verified live smoke coverage is the `BG3MCM`-present path. `BG3MCM` is now required, and the old `BG3MCM`-absent fallback branch is no longer part of supported runtime behavior.
