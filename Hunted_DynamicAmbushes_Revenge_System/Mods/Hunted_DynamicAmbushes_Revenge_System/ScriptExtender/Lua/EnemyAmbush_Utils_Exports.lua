-- EnemyAmbush_Utils_Exports.lua
-- Extracted from monolithic EnemyAmbush_Utils.lua for local-budget stability.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local ModuleUUID = EA.ModuleUUID or "96f24297-6ed9-455c-aaa1-ac9c358a8d35"
EA.ModuleUUID = ModuleUUID

-- Phase 6 Task 6.5:
-- EnemyAmbush_Utils_HostilityRegion.lua is now a compatibility shim only.
-- Seed the remaining shared bootstrap/config helpers here so later modules no
-- longer depend on side effects from that legacy filename.

local function EA_GetCompatSettingFromSnapshot(key, default)
    local getter = EA and EA["EA_GetSettingFromSnapshot"]
    if type(getter) == "function" then
        local ok, out = pcall(getter, key, default)
        if ok then
            return out
        end
    end
    return default
end

local function EA_IsRobustCompatMode()
    return EA_GetCompatSettingFromSnapshot("MCM_RobustMode", false) == true
end

local function EA_ExportsSafeOsiExec(...)
    local fn = EA and EA["SafeOsiExec"]
    if type(fn) == "function" then
        return fn(...)
    end
    return false
end

local function EA_GetRobustCreateRetriesCompat()
    local getter = EA and EA["EA_GetRobustCreateRetries"]
    if type(getter) == "function" then
        local ok, out = pcall(getter)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    return 4
end

local function EA_IsRobustRuntime()
    return EA_IsRobustCompatMode()
end

local EA_VFX_ALIAS = {
    VFX_Spells_Cast_Bane_Hand_01 = "VFX_Spells_Cast_Intent_Utility_TargetJump_MistyStep_BodyFX_01",
    VFX_Spells_Cast_Rogue_SmokeBomb_Sound_01 = "VFX_Sound_Spell_Impact_GenericPoison_01",
}

local function EA_PlayVFX_OnEntityRuntime(entity, vfx, scale)
    if not entity or entity == "" then return end
    if vfx and vfx ~= "" then
        local resolved = EA_VFX_ALIAS[vfx] or vfx
        EA_ExportsSafeOsiExec(Osi.PlayEffect, entity, resolved, "", scale or 1.0)
    end
end

local function EA_GetSpawnRetryCountRuntime()
    local retries = EA_GetRobustCreateRetriesCompat()
    return EA_IsRobustCompatMode() and retries or 1
end

local function EA_GetSpawnRetryBackoffMsRuntime(attempt)
    return EA_IsRobustCompatMode() and (150 * attempt) or 0
end

local function EA_GetSpawnRadiusBonusRuntime(attempt)
    return EA_IsRobustCompatMode() and ((attempt - 1) * 2.0) or 0.0
end

local function EA_ReadCompatCfgNumber(cfg, key, default)
    local value = tonumber(cfg[key])
    if value ~= nil then
        return value
    end
    cfg[key] = default
    return default
end

local function EA_ReadCompatCfgBool(cfg, key, default)
    local value = cfg[key]
    if value == nil then
        cfg[key] = default
        return default
    end
    return value ~= false
end

local function EA_SeedLegacyHostilityRegionCompat()
    EA.CFG = EA.CFG or {}
    local cfg = EA.CFG

    cfg.MAX_AMBUSH_ENTITIES = tonumber(cfg.MAX_AMBUSH_ENTITIES) or 6
    cfg.SHORT_TRIGGER_MIN = tonumber(cfg.SHORT_TRIGGER_MIN) or 0
    cfg.SHORT_TRIGGER_MAX = tonumber(cfg.SHORT_TRIGGER_MAX) or (10 * 60)
    cfg.LONG_TRIGGER_MIN = tonumber(cfg.LONG_TRIGGER_MIN) or (2 * 60)
    cfg.LONG_TRIGGER_MAX = tonumber(cfg.LONG_TRIGGER_MAX) or (20 * 60)
    cfg.LONG_REST_SAFETY_DELAY = tonumber(cfg.LONG_REST_SAFETY_DELAY) or 30
    cfg.SUMMON_CHANCE_SHORT = tonumber(cfg.SUMMON_CHANCE_SHORT) or 0.06
    cfg.SUMMON_CHANCE_LONG = tonumber(cfg.SUMMON_CHANCE_LONG) or 0.20

    cfg.AMBUSH_PRESSURE_MAX = EA_ReadCompatCfgNumber(cfg, "AMBUSH_PRESSURE_MAX", 100)
    cfg.AMBUSH_PRESSURE_GAIN_SHORT = EA_ReadCompatCfgNumber(cfg, "AMBUSH_PRESSURE_GAIN_SHORT", 5)
    cfg.AMBUSH_PRESSURE_GAIN_LONG = EA_ReadCompatCfgNumber(cfg, "AMBUSH_PRESSURE_GAIN_LONG", 20)
    cfg.AMBUSH_PRESSURE_DECAY_ENABLED = EA_ReadCompatCfgBool(cfg, "AMBUSH_PRESSURE_DECAY_ENABLED", true)
    cfg.AMBUSH_PRESSURE_DECAY_INTERVAL_MS = EA_ReadCompatCfgNumber(cfg, "AMBUSH_PRESSURE_DECAY_INTERVAL_MS", 120000)
    cfg.AMBUSH_PRESSURE_DECAY_MINUTES_QUANTUM = EA_ReadCompatCfgNumber(cfg, "AMBUSH_PRESSURE_DECAY_MINUTES_QUANTUM", 1)
    cfg.AMBUSH_PRESSURE_USE_REGION_MULT = EA_ReadCompatCfgBool(cfg, "AMBUSH_PRESSURE_USE_REGION_MULT", true)
    cfg.ENEMY_DURATION_MIN = EA_ReadCompatCfgNumber(cfg, "ENEMY_DURATION_MIN", (5 * 60))
    cfg.ENEMY_DURATION_MAX = EA_ReadCompatCfgNumber(cfg, "ENEMY_DURATION_MAX", (10 * 60))
    cfg.ENABLE_HOSTILE_SPAWNS = EA_ReadCompatCfgBool(cfg, "ENABLE_HOSTILE_SPAWNS", true)
end

EA_SeedLegacyHostilityRegionCompat()

-- ========= EXPORTS (Utils -> EnemyAmbush table) =========
EA["EA_WallClockMs"] = EA["EA_WallClockMs"] or EA_WallClockMs
EA["EA_GameTimeMs"] = EA["EA_GameTimeMs"] or EA_GameTimeMs
EA["EA_NowMs"] = EA["EA_NowMs"] or EA_NowMs
EA["EA_PersistedNowMs"] = EA["EA_PersistedNowMs"] or EA_PersistedNowMs
EA["EA_GetGameTimeDiagnostics"] = EA["EA_GetGameTimeDiagnostics"] or EA_GetGameTimeDiagnostics
EA["EA_ProbeGameTimeMs"] = EA["EA_ProbeGameTimeMs"] or EA_ProbeGameTimeMs
EA["HasLineOfSight"] = EA["HasLineOfSight"] or EA_HasLoS
EA["EA_HasLoS"] = EA["EA_HasLoS"] or EA_HasLoS
EA["CheckVersion"] = CheckVersion
EA["DebugPrint"] = DebugPrint
EA["EA_AddAmbushPressure"] = EA_AddAmbushPressure
EA["EA_AggressiveSpawnedCleanup"] = EA_AggressiveSpawnedCleanup
EA["EA_MarkSessionLoadedForCleanup"] = EA_MarkSessionLoadedForCleanup
EA["EA_AmbushPressure"] = EA_AmbushPressure
EA["EA_AmbushPressureLastUpdate"] = EA_AmbushPressureLastUpdate
EA["EA_ApplySettingsToLocals"] = EA_ApplySettingsToLocals
EA["EA_CalcKillXP"] = EA_CalcKillXP
EA["EA_ClearLootButKeepCorpseClickable"] = EA_ClearLootButKeepCorpseClickable
EA["EA_Dirty"] = EA_Dirty
EA["EA_EvictOldSpawned"] = EA_EvictOldSpawned
EA["EA_GetAmbushPressure"] = EA_GetAmbushPressure
EA["EA_ClearAllTimeInDangerState"] = EA_ClearAllTimeInDangerState
EA["EA_GetTimeInDangerAccumulatedMs"] = EA_GetTimeInDangerAccumulatedMs
EA["EA_GetTimeInDangerRiskUnit"] = EA_GetTimeInDangerRiskUnit
EA["EA_ResetTimeInDangerState"] = EA_ResetTimeInDangerState
EA["EA_GetTypePressure"] = EA_GetTypePressure
EA["EA_AddTypePressure"] = EA_AddTypePressure
EA["EA_ConsumeTypePressure"] = EA_ConsumeTypePressure
EA["EA_TypePressure"] = EA_TypePressure
EA["EA_TypePressureLastUpdate"] = EA_TypePressureLastUpdate
EA["EA_TimeInDangerState"] = EA_TimeInDangerState
EA["EA_TickTimeInDangerRisk"] = EA_TickTimeInDangerRisk
EA["EA_TypePressureKey"] = EA_TypePressureKey
EA["EA_GetTypePressureSignature"] = EA_GetTypePressureSignature
EA["EA_RecordRecentAmbushType"] = EA_RecordRecentAmbushType
EA["EA_GetRecentAmbushTypePenalty"] = EA_GetRecentAmbushTypePenalty
EA["EA_AmbushTypeHistory"] = EA_AmbushTypeHistory
EA["EA_WorldRepWindow"] = EA_WorldRepWindow
EA["EA_ResetWorldRepWindow"] = EA_ResetWorldRepWindow
EA["EA_DefeatedSpawned"] = EA_DefeatedSpawned
EA["EA_IsDefeatedSpawned"] = EA_IsDefeatedSpawned
EA["EA_RememberDefeatedSpawned"] = EA_RememberDefeatedSpawned
EA["EA_GetCooldownEnabled"] = EA_GetCooldownEnabled
EA["EA_GetCooldownMinutes"] = EA_GetCooldownMinutes
EA["EA_GetTimeInDangerPressureEnabled"] = EA_GetTimeInDangerPressureEnabled
EA["EA_GetChanceMultiplier"] = EA_GetChanceMultiplier
EA["EA_IsQuickTestMode"] = EA_IsQuickTestMode
EA["EA_GetRestDelayWindowMinutes"] = EA_GetRestDelayWindowMinutes
EA["EA_GetStrictProgressionGates"] = EA_GetStrictProgressionGates
EA["EA_GetUseCompositionGuards"] = EA_GetUseCompositionGuards
EA["EA_GetBalanceProfile"] = EA_GetBalanceProfile
EA["EA_GetBalanceProfileLabel"] = EA_GetBalanceProfileLabel
EA["EA_GetArrivalCuePolicy"] = EA_GetArrivalCuePolicy
EA["EA_GetArrivalCuePolicyLabel"] = EA_GetArrivalCuePolicyLabel
EA["EA_GetArrivalCueChanceScale"] = EA_GetArrivalCueChanceScale
EA["EA_GetSpawnPlacementMode"] = EA_GetSpawnPlacementMode
EA["EA_GetSpawnPlacementModeLabel"] = EA_GetSpawnPlacementModeLabel
EA["EA_ShouldSkipBeachTutorialAmbush"] = EA_ShouldSkipBeachTutorialAmbush
EA["EA_GetEffectiveAllowChampionLoot"] = EA_GetEffectiveAllowChampionLoot
EA["EA_GetEffectiveAmbushIntensity"] = EA_GetEffectiveAmbushIntensity
EA["EA_GetEffectiveAmbushXPPercent"] = EA_GetEffectiveAmbushXPPercent
EA["EA_GetEffectiveDisableAmbushLoot"] = EA_GetEffectiveDisableAmbushLoot
EA["EA_GetEffectiveScaleWithPartySize"] = EA_GetEffectiveScaleWithPartySize
EA["EA_GuaranteedChampionQueue"] = EA["EA_GuaranteedChampionQueue"] or EA_GuaranteedChampionQueue
EA["EA_GetGuaranteedChampionQueueSafe"] = EA["EA_GetGuaranteedChampionQueueSafe"] or function()
    if type(EA_GuaranteedChampionQueue) == "function" then
        local ok, out = pcall(EA_GuaranteedChampionQueue)
        if ok and type(out) == "table" then
            return out
        end
    end
    return {}
end
EA["EA_GetGuaranteedChampionArmed"] = EA["EA_GetGuaranteedChampionArmed"] or EA_GetGuaranteedChampionArmed
EA["EA_GetPreset"] = EA_GetPreset
EA["EA_GetRegionPressureMult"] = EA_GetRegionPressureMult
EA["EA_GetRestAmbushChance"] = EA_GetRestAmbushChance
EA["EA_GetVengefulChampionChance"] = EA_GetVengefulChampionChance
EA["EA_GetTierFromDelta"] = EA_GetTierFromDelta
EA["EA_InitPressureDecayState"] = EA_InitPressureDecayState
EA["EA_IsAdvancedMode"] = EA_IsAdvancedMode
EA["EA_IsCXMode"] = EA_IsCXMode
EA["EA_IsRestAmbushEnabled"] = EA_IsRestAmbushEnabled
EA["EA_LogEvent"] = EA_LogEvent
EA["EA_P0EnsureStats"] = EA_P0EnsureStats
EA["EA_P0Inc"] = EA_P0Inc
EA["EA_P0Set"] = EA_P0Set
EA["EA_P0SetFlag"] = EA_P0SetFlag
EA["EA_P0PushNote"] = EA_P0PushNote
EA["EA_P0BumpKeyedCount"] = EA_P0BumpKeyedCount
EA["EA_GetPhase0Stats"] = EA_GetPhase0Stats
EA["EA_ResetPhase0Stats"] = EA_ResetPhase0Stats
EA["EA_GetPhase0Summary"] = EA_GetPhase0Summary
EA["EA_NormalizeUUID"] = EA_NormalizeUUID
EA["EA_Pending"] = EA_Pending
EA["EA_SanitizePersistedTimes"] = EA_SanitizePersistedTimes
EA["EA_SetLastError"] = EA_SetLastError
EA["EA_Spawned"] = EA_Spawned
EA["EA_StartPressureDecayLoop"] = EA_StartPressureDecayLoop
EA["EA_SyncAdvancedFromPreset"] = EA_SyncAdvancedFromPreset
EA["EA_ToBool"] = EA_ToBool
EA["EA_Vars"] = EA_Vars
EA["GetMetricsSummary"] = GetMetricsSummary
EA["GetTableSize"] = EA["GetTableSize"] or GetTableSize
EA["IsDebug"] = IsDebug
EA["EA_IsRobust"] = EA["EA_IsRobust"] or EA_IsRobustRuntime
EA["EA_GetRobustLogArgs"] = EA_GetRobustLogArgs
EA["EA_GetRobustCreateRetries"] = EA_GetRobustCreateRetries
EA["EA_GetRobustCreateRetryDelayMs"] = EA_GetRobustCreateRetryDelayMs
EA["EA_GetRobustHostileRetries"] = EA_GetRobustHostileRetries
EA["EA_GetRobustHostileRetryDelayMs"] = EA_GetRobustHostileRetryDelayMs
EA["EA_GetSpawnRetryCount"] = EA["EA_GetSpawnRetryCount"] or EA_GetSpawnRetryCountRuntime
EA["EA_GetSpawnRetryBackoffMs"] = EA["EA_GetSpawnRetryBackoffMs"] or EA_GetSpawnRetryBackoffMsRuntime
EA["EA_GetSpawnRadiusBonus"] = EA["EA_GetSpawnRadiusBonus"] or EA_GetSpawnRadiusBonusRuntime
EA["PlayVFX_OnEntity"] = EA["PlayVFX_OnEntity"] or EA_PlayVFX_OnEntityRuntime
EA["RobustRetry"] = RobustRetry
EA["SafeAddBoosts"] = EA["SafeAddBoosts"] or SafeAddBoosts
EA["SafeApplyStatus"] = SafeApplyStatus
EA["SafeGetPosition"] = EA["SafeGetPosition"] or SafeGetPosition
EA["SafeOsiCall"] = EA["SafeOsiCall"] or SafeOsiCall
EA["SafeOsiExec"] = EA["SafeOsiExec"] or SafeOsiExec
EA["SafeRemoveStatus"] = SafeRemoveStatus
EA["PerformanceMetrics"] = PerformanceMetrics
EA["EA_GetPerformanceMetrics"] = function() return PerformanceMetrics end
EA["UpdateMetric"] = UpdateMetric
EA["ApplyMCMSettings"] = ApplyMCMSettings
EA["LoadReputation"] = LoadReputation
EA["EA_SyncAdvancedFromPresetPersisted"] = EA_SyncAdvancedFromPresetPersisted
EA["EA_LastAmbushTime"] = EA["EA_LastAmbushTime"] or EA_LastAmbushTime
EA["EA_MAX_AMBUSH_ENTITIES"] = ((EA.CFG and EA.CFG.MAX_AMBUSH_ENTITIES) or 6)
EA["EA_ModVarsReady"] = EA_ModVarsReady
EA["EA_IsModVarsContainer"] = EA_IsModVarsContainer
EA["EA_GetModVarsReadyDiagnostics"] = EA_GetModVarsReadyDiagnostics
EA["EA_NormalizeUUIDFast"] = EA_NormalizeUUIDFast
EA["EA_ResolveLocaText"] = EA_ResolveLocaText
EA["EA_ResetStatusExistenceCache"] = EA_ResetStatusExistenceCache
EA["EA_GetSettingsSnapshot"] = EA_GetSettingsSnapshot
EA["EA_GetSettingFromSnapshot"] = EA_GetSettingFromSnapshot
EA["EA_ValidateBuildDeps"] = EA["EA_ValidateBuildDeps"] or EA_ValidateBuildDeps
