-- EnemyAmbush_Utils_HostilityRegion.lua
-- Phase 6 Task 6.5 compatibility shim.
--
-- This legacy filename remains in the bootstrap order so older require paths and
-- load-order assumptions continue to hold while Phase 6 finishes.
--
-- It no longer owns runtime behavior or state for:
--   - champion queue / armed state
--   - support-join windows and throttling
--   - region policy / safe-zone state
--   - hostility conversion / retry ownership
--
-- Canonical owners:
--   EnemyAmbush_Systems_ChampionState.lua
--   EnemyAmbush_Systems_RegionPolicy.lua
--   EnemyAmbush_Systems_SupportJoinService.lua
--   EnemyAmbush_Systems_HostilityService.lua
--
-- Shared compatibility exports and legacy config seeding now live in
-- EnemyAmbush_Utils_Exports.lua.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local ModuleUUID = EA.ModuleUUID or "96f24297-6ed9-455c-aaa1-ac9c358a8d35"
EA.ModuleUUID = ModuleUUID

EA._LegacyShims = EA._LegacyShims or {}
EA._LegacyShims.HostilityRegion = "phase6_compat_only"
