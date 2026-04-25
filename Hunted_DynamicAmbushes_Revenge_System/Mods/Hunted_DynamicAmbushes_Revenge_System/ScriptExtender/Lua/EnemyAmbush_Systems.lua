EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

-- v4 architectural guardrails:
-- - Layered load order is one-way: Base -> Logic -> Execution -> Triggers.
-- - Keep split runtime files under ~1200 lines and functions under ~150 lines.
-- - Avoid cross-layer requires; signal upward via EA.Emit/EA.On.

EA.SystemsModules = EA.SystemsModules or {}
if EA.SystemsModules.LoaderInitialized == true then
    return EA
end
EA.SystemsModules.LoaderInitialized = true

local LOAD_ORDER = {
    "EnemyAmbush_Systems_Exports.lua",
    "EnemyAmbush_Systems_SpawnPlacement.lua",
    "EnemyAmbush_Systems_SpawnExecution.lua",
    "EnemyAmbush_Systems_EffectsDB.lua",
    "EnemyAmbush_Systems_Immersion.lua",
    "EnemyAmbush_Systems_Surprise.lua",
    "EnemyAmbush_Systems_ChampionSpawn.lua",
    "EnemyAmbush_Systems_TriggerRestFlow.lua",
    "EnemyAmbush_Systems_SpawnPipeline.lua",
    "EnemyAmbush_Systems_CompositionRoot.lua",
}

local function EA_ValidateSystemsSeams()
    local requiredFunctions = {
        "BuildActiveSummonList",
        "EA_GetPoolOwnerId",
        "EA_GetPoolActiveSummonList",
        "EA_GetPoolTemplateEntryById",
        "EA_GetPoolTemplateVariantsById",
        "EA_GetPoolTemplateVariantEntry",
        "EA_ResetPoolActiveListState",
        "EA_FlushPoolCacheState",
        "EA_MarkPoolNeedsRebuild",
        "EA_RequestPoolRebuild",
        "EA_NotifyPoolProviderChanged",
        "EA_ResetPoolTemplateLookups",
        "EA_ResolveChampionSpawnData",
        "EA_GetChampionFallbackPolicyMode",
        "EA_SetChampionFallbackPolicyMode",
        "EA_GetChampionResolveTelemetrySnapshot",
        "EA_GetChampionDiagnosticsMode",
        "EA_SetChampionDiagnosticsMode",
        "EA_ResetChampionCooldowns",
        "ExecuteAmbushSpawn",
        "GetPointBudget",
        "IsSafeToSpawnAmbush",
        "CleanupPendingAmbushes",
        "SaveReputation",
        "LoadReputation",
        "EA_ResetReputationForMigration",
        "EA_GetCreatureReputationTable",
        "EA_GetReputationThresholds",
        "EA_SessionLoadedInit",
        "EA_RunStartupTemplateAudit",
        "SpawnChampionNow",
        "SpawnHostileNearPlayer",
        "TriggerAmbush",
        "EA_GetLocationAppropriateEnemies",
        "EA_PlayApproachBeatFromData",
        "EA_TryApplyPartySurprise",
        "EA_HandleSurpriseRollResult",
    }

    local missing = {}
    for _, key in ipairs(requiredFunctions) do
        if type(EA[key]) ~= "function" then
            missing[#missing + 1] = key
        end
    end

    if #missing > 0 then
        print(string.format(
            "[EnemyAmbush][Seam] Systems bind incomplete, missing exports: %s",
            table.concat(missing, ", ")
        ))
        return false
    end

    print("[EnemyAmbush][Seam] Systems bind contract: OK")
    return true
end

for _, modulePath in ipairs(LOAD_ORDER) do
    local ok, err = pcall(Ext.Require, modulePath)
    if not ok then
        print(string.format("[EnemyAmbush] Systems loader failed: %s (%s)", tostring(modulePath), tostring(err)))
    end
end

EA_ValidateSystemsSeams()

return EA

