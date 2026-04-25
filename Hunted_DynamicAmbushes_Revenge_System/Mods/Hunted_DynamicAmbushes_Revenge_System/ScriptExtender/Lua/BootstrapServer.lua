-- BootstrapServer.lua
-- Entry point for Hunted - Dynamic Ambushes & Revenge System

print("[Hunted] Loading Dynamic Ambushes & Revenge System...")

-- Seed mod-local RNG for deterministic mod-owned randomness.
Ext.Require("EnemyAmbush_RNG.lua")
if EnemyAmbush and EnemyAmbush.SeedRng then
    pcall(EnemyAmbush.SeedRng)
end

-- Load API first
Ext.Require("EnemyAmbush_API.lua")

-- Load the data module next (providers register here)
local EnemyData = Ext.Require("EnemyAmbush_Data.lua")

-- Then load the main module
Ext.Require("EnemyAmbush_Main.lua")

local EA = EnemyAmbush or {}
local required = {
    "BuildActiveSummonList",
    "TriggerAmbush",
    "SpawnHostileNearPlayer",
    "ExecuteAmbushSpawn",
    "EA_NormalizeUUID",
    "EA_PersistedNowMs",
}
local consumerRequired = {
    "EA_SessionLoadedInit",
    "CleanupPendingAmbushes",
    "SaveReputation",
    "LoadReputation",
    "EA_ResetReputationForMigration",
    "EA_GetCreatureReputationTable",
    "EA_GetReputationThresholds",
    "SpawnChampionNow",
    "EA_ResolveChampionSpawnData",
    "EA_GetChampionFallbackPolicyMode",
    "EA_SetChampionFallbackPolicyMode",
    "EA_GetChampionResolveTelemetrySnapshot",
    "EA_GetChampionDiagnosticsMode",
    "EA_SetChampionDiagnosticsMode",
    "EA_ResetChampionCooldowns",
    "EA_RunStartupTemplateAudit",
}
local missing = {}
for _, key in ipairs(required) do
    if type(EA[key]) ~= "function" then
        missing[#missing + 1] = key
    end
end
local missingConsumer = {}
for _, key in ipairs(consumerRequired) do
    if type(EA[key]) ~= "function" then
        missingConsumer[#missingConsumer + 1] = key
    end
end

if #missing == 0 then
    print("[Hunted] Dynamic Ambushes & Revenge System loaded successfully!")
    if #missingConsumer > 0 then
        print(string.format(
            "[Hunted] Consumer export contract warnings: %s",
            table.concat(missingConsumer, ", ")
        ))
    end
else
    print(string.format(
        "[Hunted] Dynamic Ambushes loaded with missing exports: %s (check Script Extender log for parse/runtime errors).",
        table.concat(missing, ", ")
    ))
end
