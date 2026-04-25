EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

EA.SystemsModules = EA.SystemsModules or {}
if EA.SystemsModules.CompositionRootInitialized == true then
    return EA
end
EA.SystemsModules.CompositionRootInitialized = true

local SystemsExports = Ext.Require("EnemyAmbush_Systems_Exports.lua")
local compositionInputs = EA.SystemsModules.CompositionInputs or {}
local spawnPipelineInputs = compositionInputs.SpawnPipeline
local STARTUP_BANNED_LEGACY_GLOBALS = {
    "CreatureReputation",
    "REPUTATION_THRESHOLDS",
    "SaveReputation",
    "LoadReputation",
    "EA_AddAmbushPressure",
    "EA_ApplySettingsToLocals",
    "EA_ClearLootButKeepCorpseClickable",
    "EA_GameTimeMs",
    "EA_GetAmbushPressure",
    "EA_GetPreset",
    "EA_GetRegionPressureMult",
    "EA_IsRestAmbushEnabled",
    "EA_SyncAdvancedFromPreset",
    "EA_SyncAdvancedFromPresetPersisted",
    "EA_WallClockMs",
    "EA_WorldRepWindow",
}
local OWNER_EXPORT_BINDINGS = {
    {
        owner = "PoolSelection",
        exports = {
            BuildActiveSummonList = "BuildActiveSummonList",
            EA_GetPoolOwnerId = "EA_GetPoolOwnerId",
            EA_GetPoolActiveSummonList = "EA_GetPoolActiveSummonList",
            EA_GetPoolTemplateEntryById = "EA_GetPoolTemplateEntryById",
            EA_GetPoolTemplateVariantsById = "EA_GetPoolTemplateVariantsById",
            EA_GetPoolTemplateVariantEntry = "EA_GetPoolTemplateVariantEntry",
            EA_ResetPoolActiveListState = "EA_ResetPoolActiveListState",
            EA_FlushPoolCacheState = "EA_FlushPoolCacheState",
            EA_MarkPoolNeedsRebuild = "EA_MarkPoolNeedsRebuild",
            EA_RequestPoolRebuild = "EA_RequestPoolRebuild",
            EA_NotifyPoolProviderChanged = "EA_NotifyPoolProviderChanged",
            EA_ResetPoolTemplateLookups = "EA_ResetPoolTemplateLookups",
            EA_GetEntrySpawnBand = "EA_GetEntrySpawnBand",
            ThemeAllowsEnemy = "ThemeAllowsEnemy",
            ValidateEnemyData = "ValidateEnemyData",
            EA_ResetLocalCharacterTemplateCache = "EA_ResetLocalCharacterTemplateCache",
            EA_PrimeCharacterTemplateCache = "EA_PrimeCharacterTemplateCache",
            EA_GetCharacterTemplate = "EA_GetCharacterTemplate",
            EA_ResolveCreatureTypeByTemplate = "EA_ResolveCreatureTypeByTemplate",
            EA_ResolveCreatureTypeForCharacter = "EA_ResolveCreatureTypeForCharacter",
            EA_WEIGHT_MULTIPLIER_CAP = "EA_WEIGHT_MULTIPLIER_CAP",
            EA_RunStartupTemplateAudit = "EA_RunStartupTemplateAudit",
        },
    },
    {
        owner = "ChampionControl",
        exports = {
            EA_ArmGuaranteedChampion = "EA_ArmGuaranteedChampion",
            EA_CanSpawnChampionForType = "EA_CanSpawnChampionForType",
            EA_IncrementRestCycleCounter = "EA_IncrementRestCycleCounter",
            EA_GetRestCycleCounter = "EA_GetRestCycleCounterValue",
            EA_ResetChampionCooldowns = "EA_ResetChampionCooldowns",
        },
    },
    {
        owner = "ChampionSpawn",
        exports = {
            SpawnChampionNow = "SpawnChampionNow",
            EA_GetChampionFallbackPolicyMode = "EA_GetChampionFallbackPolicyMode",
            EA_SetChampionFallbackPolicyMode = "EA_SetChampionFallbackPolicyMode",
            EA_ResolveChampionSpawnData = "EA_ResolveChampionSpawnData",
            EA_GetChampionResolveTelemetrySnapshot = "EA_GetChampionResolveTelemetrySnapshot",
        },
    },
    {
        owner = "PersistenceControl",
        exports = {
            CleanupPendingAmbushes = "CleanupPendingAmbushes",
            SaveReputation = "SaveReputation",
            LoadReputation = "LoadReputation",
            EA_ResetReputationForMigration = "EA_ResetReputationForMigration",
            EA_GetCreatureReputationTable = "EA_GetCreatureReputationTable",
            EA_GetReputationThresholds = "EA_GetReputationThresholds",
        },
    },
    {
        owner = "Budget",
        exports = {
            GetPointBudget = "GetPointBudget",
        },
    },
    {
        owner = "Immersion",
        exports = {
            EA_PlayApproachBeatFromData = "EA_PlayApproachBeatFromData",
            EA_PlayCombatStartVoiceOrSfx = "EA_PlayCombatStartVoiceOrSfx",
            EA_PlaySoundEvent = "EA_PlaySoundEvent",
            EA_SelectEffectProfile = "EA_SelectEffectProfile",
            EA_SelectArrivalCue = "EA_SelectArrivalCue",
            EA_ShouldApplyArrivalCue = "EA_ShouldApplyArrivalCue",
            EA_DESPAWN_FADE_SOUND = "EA_DESPAWN_FADE_SOUND",
            EA_GetEscapeProfileByCreatureType = "EA_GetEscapeProfileByCreatureType",
        },
    },
    {
        owner = "Surprise",
        exports = {
            EA_TryApplyPartySurprise = "EA_TryApplyPartySurprise",
            EA_HandleSurpriseRollResult = "EA_HandleSurpriseRollResult",
            EA_IsMemberSurpriseImmune = "EA_IsMemberSurpriseImmune",
        },
    },
    {
        owner = "SpawnPlacement",
        exports = {
            SpawnHostileNearPlayer = "SpawnHostileNearPlayer",
        },
    },
    {
        owner = "SpawnExecution",
        exports = {
            ExecuteAmbushSpawn = "ExecuteAmbushSpawn",
        },
    },
    {
        owner = "TriggerRestFlow",
        exports = {
            TriggerAmbush = "TriggerAmbush",
            EA_TryTriggerTravelDangerAmbush = "EA_TryTriggerTravelDangerAmbush",
        },
    },
}
local SUPPORT_EXPORT_BINDINGS = {
    EA_GetChampionDiagnosticsMode = "EA_GetChampionDiagnosticsMode",
    EA_SetChampionDiagnosticsMode = "EA_SetChampionDiagnosticsMode",
    EA_IsChampionDiagnosticsEnabled = "EA_IsChampionDiagnosticsEnabled",
    EA_IsAnyPartyInCombat = "EA_IsAnyPartyInCombat",
    EA_GetLocationAppropriateEnemies = "EA_GetLocationAppropriateEnemies",
    EA_RegisterTestSpawn = "EA_RegisterTestSpawn",
    EA_GetStaticMetadataCategory = "EA_GetStaticMetadataCategory",
    GetEnemyCategory = "GetEnemyCategory",
    GetPartySize = "GetPartySize",
    EA_GetPartyMembers = "EA_GetPartyMembers",
    GetSafeLevel = "GetSafeLevel",
    IsSafeToSpawnAmbush = "IsSafeToSpawnAmbush",
    RandomSeconds = "RandomSeconds",
    EA_RollOverlevelDelta = "EA_RollOverlevelDelta",
    EA_SetDebugHasteAllAmbushers = "EA_SetDebugHasteAllAmbushers",
    EA_IsDebugHasteAllAmbushers = "EA_IsDebugHasteAllAmbushers",
    EA_ENCOUNTER_REP_MAX_LOSS = "EA_ENCOUNTER_REP_MAX_LOSS",
}

local function EA_WarnLegacyGlobalSurface(isDebugFn)
    if not (type(isDebugFn) == "function" and isDebugFn()) then
        return
    end
    local found = {}
    for _, key in ipairs(STARTUP_BANNED_LEGACY_GLOBALS) do
        if rawget(_G, key) ~= nil then
            found[#found + 1] = key
        end
    end
    if #found > 0 then
        table.sort(found)
        print(string.format(
            "[EnemyAmbush][Compat] Legacy global aliases still present: %s",
            table.concat(found, ", ")
        ))
    end
end

local function CopyMap(map)
    local copy = {}
    if type(map) ~= "table" then
        return copy
    end
    for key, value in pairs(map) do
        copy[key] = value
    end
    return copy
end

local function BuildOwnerRuntimeBag(existingRuntimes, supportBag)
    local runtimes = CopyMap(existingRuntimes)
    supportBag = type(supportBag) == "table" and supportBag or {}

    local buildRuntimeWithDeps = EA and EA["EA_BuildRuntimeWithDeps"]
    local function BuildRuntime(moduleName, modulePath, deps, schema)
        local moduleTable = Ext.Require(modulePath)
        if type(moduleTable) ~= "table" or type(moduleTable.Build) ~= "function" then
            return nil
        end
        if type(buildRuntimeWithDeps) == "function" then
            return buildRuntimeWithDeps(moduleName, moduleTable, deps, schema)
        end
        local ok, runtimeOrErr = pcall(moduleTable.Build, deps)
        if not ok then
            print(string.format("[EnemyAmbush][Seam] %s Build() failed: %s", tostring(moduleName), tostring(runtimeOrErr)))
            return nil
        end
        return runtimeOrErr
    end

    local function GetRuntimeFunction(runtimeName, fnName)
        local runtime = runtimes[runtimeName]
        local fn = runtime and runtime[fnName]
        if type(fn) == "function" then
            return fn
        end
        return nil
    end

    local EnemyData = supportBag.EnemyData
    local SystemsDataTables = supportBag.SystemsDataTables
    local Cache = supportBag.Cache
    local CreatureReputation = supportBag.CreatureReputation
    local REPUTATION_THRESHOLDS = supportBag.REPUTATION_THRESHOLDS
    local ModuleUUID = supportBag.ModuleUUID
    local EA_IsDebugMode = (EA and EA["IsDebug"]) or function() return false end
    local EA_IsRobust = (EA and EA["EA_IsRobust"]) or function() return false end
    local EA_MakeAmbushHostile = (EA and EA["EA_MakeAmbushHostile"]) or function() end
    local SafeOsiCall = (EA and EA["SafeOsiCall"]) or function() return nil end
    local SafeOsiExec = (EA and EA["SafeOsiExec"]) or function() return nil end
    local SafeAddBoosts = (EA and EA["SafeAddBoosts"]) or function() return false end
    local SafeGetPosition = (EA and EA["SafeGetPosition"]) or function() return nil end
    local GetTableSize = (EA and EA["GetTableSize"]) or function(t)
        local n = 0
        for _ in pairs(t or {}) do
            n = n + 1
        end
        return n
    end
    local PlayVFX_OnEntity = (EA and EA["PlayVFX_OnEntity"]) or function() end
    local EA_GetSpawnRetryCount = (EA and EA["EA_GetSpawnRetryCount"]) or function() return 1 end
    local EA_GetPresetHiddenBalanceKnobs = (EA and EA["EA_GetPresetHiddenBalanceKnobs"]) or function() return nil end

    runtimes.PartyPressure = BuildRuntime("Systems_PartyPressure", "EnemyAmbush_Systems_PartyPressure.lua", {
        EA_IsDebugMode = EA_IsDebugMode,
        DebugPrint = DebugPrint,
    }, {
        DebugPrint = "callable",
    })

    runtimes.Budget = BuildRuntime("Systems_Budget", "EnemyAmbush_Systems_Budget.lua", {
        EA_GetSettingRaw = EA["EA_ReadSettingRaw"],
        EA_GetSettingNumber = EA["EA_ReadSettingNumber"],
        EA_IsAdvancedMode = EA_IsAdvancedMode,
        EA_GetEffectiveScaleWithPartySize = EA_GetEffectiveScaleWithPartySize,
        EA_GetPresetHiddenBalanceKnobs = EA_GetPresetHiddenBalanceKnobs,
        EA_GetScaledBudgetPoints = function(...)
            local fn = GetRuntimeFunction("PartyPressure", "GetScaledBudgetPoints")
            if type(fn) == "function" then
                return fn(...)
            end
            return ...
        end,
        EA_GetBudgetPartyBonus = function(...)
            local fn = GetRuntimeFunction("PartyPressure", "GetBudgetPartyBonus")
            if type(fn) == "function" then
                return fn(...)
            end
            return 0, 0
        end,
        EA_IsDebugMode = EA_IsDebugMode,
        GetPartySize = supportBag.GetPartySize,
        DebugPrint = DebugPrint,
    }, {
        EA_GetSettingRaw = "callable",
        EA_GetSettingNumber = "callable",
        EA_IsAdvancedMode = "callable",
        EA_GetEffectiveScaleWithPartySize = "callable",
        EA_GetPresetHiddenBalanceKnobs = "callable",
        EA_GetScaledBudgetPoints = "callable",
        EA_GetBudgetPartyBonus = "callable",
        GetPartySize = "callable",
        DebugPrint = "callable",
    })

    runtimes.Surprise = BuildRuntime("Systems_Surprise", "EnemyAmbush_Systems_Surprise.lua", {
        EA = EA,
        SystemsDataTables = SystemsDataTables,
        EA_NowMs = EA_NowMs,
        EA_NormalizeUUID = EA_NormalizeUUID,
        EA_GetPartyMembers = supportBag.EA_GetPartyMembers,
        EA_GetSettingBool = EA["EA_ReadSettingBool"],
        SafeOsiCall = SafeOsiCall,
        SafeApplyStatus = SafeApplyStatus,
        UpdateMetric = UpdateMetric,
        DebugPrint = DebugPrint,
        EA_IsDebugMode = EA_IsDebugMode,
    }, {
        EA = "tablelike",
        SystemsDataTables = "tablelike",
        EA_NowMs = "callable",
        EA_NormalizeUUID = "callable",
        EA_GetPartyMembers = "callable",
        SafeOsiCall = "callable",
        SafeApplyStatus = "callable",
        UpdateMetric = "callable",
        DebugPrint = "callable",
    })

    runtimes.PersistenceControl = BuildRuntime("Systems_PersistenceControl", "EnemyAmbush_Systems_PersistenceControl.lua", {
        EnemyAmbush = EnemyAmbush,
        EA = EA,
        Cache = Cache,
        GetTableSize = GetTableSize,
        EA_Pending = EA_Pending,
        EA_NowMs = EA_NowMs,
        EA_Dirty = EA_Dirty,
        EA_Vars = EA_Vars,
        EA_IsModVarsContainer = EA_IsModVarsContainer,
        EA_IsDebugMode = EA_IsDebugMode,
        DebugPrint = DebugPrint,
        CreatureReputation = CreatureReputation,
        REPUTATION_THRESHOLDS = REPUTATION_THRESHOLDS,
        ModuleUUID = ModuleUUID,
        EA_ModVarsReady = EA_ModVarsReady,
        EA_GetModVarsReadyDiagnostics = EA_GetModVarsReadyDiagnostics,
        EA_IsRobust = EA_IsRobust,
        EA_FlushPoolCacheState = function(...)
            local fn = GetRuntimeFunction("PoolSelection", "EA_FlushPoolCacheState")
            if type(fn) == "function" then
                return fn(...)
            end
            return nil
        end,
        EA_PENDING_CAP = 80,
        EA_PENDING_TTL_MS = 120000,
    }, {
        EnemyAmbush = "tablelike",
        EA = "tablelike",
        Cache = "tablelike",
        GetTableSize = "callable",
        EA_Pending = "callable",
        EA_NowMs = "callable",
        EA_Dirty = "callable",
        DebugPrint = "callable",
        EA_FlushPoolCacheState = "callable",
    })

    runtimes.PoolSelection = BuildRuntime("Systems_PoolSelection", "EnemyAmbush_Systems_PoolSelection.lua", {
        EnemyAmbush = EnemyAmbush,
        EA = EA,
        Cache = Cache,
        EnemyData = EnemyData,
        SystemsDataTables = SystemsDataTables,
        CreatureReputation = CreatureReputation,
        REPUTATION_THRESHOLDS = REPUTATION_THRESHOLDS,
        DebugPrint = DebugPrint,
        EA_IsDebugMode = EA_IsDebugMode,
        EA_GetSettingBool = EA["EA_ReadSettingBool"],
        EA_GetSettingRaw = EA["EA_ReadSettingRaw"],
        EA_NowMs = EA_NowMs,
        GetTableSize = GetTableSize,
        GetPartyMaxLevel = supportBag.GetPartyMaxLevel,
        GetPartySize = supportBag.GetPartySize,
        GetPointBudget = function(...)
            local fn = GetRuntimeFunction("Budget", "GetPointBudget")
            if type(fn) == "function" then
                return fn(...)
            end
            return 1
        end,
        GetLocationAppropriateEnemies = supportBag.EA_GetLocationAppropriateEnemies,
        GetRegionalStrengthModifier = supportBag.GetRegionalStrengthModifier,
        EA_RandFloatCompat = EA_RandFloatCompat,
        UpdateMetric = UpdateMetric,
        RequestCacheRebuild = function(reason, hard, immediate)
            local fn = GetRuntimeFunction("PersistenceControl", "RequestCacheRebuild")
            if type(fn) == "function" then
                return fn(reason, hard, immediate)
            end
            return nil
        end,
        EA_GetTypePressureSignature = EA_GetTypePressureSignature,
        EA_GetTypePressure = EA_GetTypePressure,
        EA_GetRecentAmbushTypePenalty = EA_GetRecentAmbushTypePenalty,
        EA_GetStrictProgressionGates = EA_GetStrictProgressionGates,
        EA_GetBalanceProfile = EA_GetBalanceProfile,
        EA_GetRegionForCharacter = EA_GetRegionForCharacter,
        EA_NormalizeUUID = EA_NormalizeUUID,
        EA_GetEffectiveAmbushXPPercent = EA_GetEffectiveAmbushXPPercent,
    }, {
        EnemyAmbush = "tablelike",
        EA = "tablelike",
        Cache = "tablelike",
        EnemyData = "tablelike",
        SystemsDataTables = "tablelike",
        DebugPrint = "callable",
        EA_NowMs = "callable",
        GetTableSize = "callable",
        GetPartyMaxLevel = "callable",
        GetPartySize = "callable",
        GetPointBudget = "callable",
        RequestCacheRebuild = "callable",
        EA_GetEffectiveAmbushXPPercent = "callable",
    })

    local effectsDBModule = Ext.Require("EnemyAmbush_Systems_EffectsDB.lua")
    if type(effectsDBModule) == "table" and type(effectsDBModule.Build) == "function" then
        local okEffects, runtimeOrErr = pcall(effectsDBModule.Build, {
            DebugPrint = DebugPrint,
            UpdateMetric = UpdateMetric,
            EA_RandIntCompat = EA_RandIntCompat,
        })
        if okEffects and type(runtimeOrErr) == "table" then
            runtimes.EffectsDB = runtimeOrErr
        else
            print(string.format("[EnemyAmbush] EffectsDB module build failed: %s", tostring(runtimeOrErr)))
        end
    else
        print("[EnemyAmbush] EffectsDB module unavailable; cosmetic cue routing will use fallbacks.")
    end

    runtimes.Immersion = BuildRuntime("Systems_Immersion", "EnemyAmbush_Systems_Immersion.lua", {
        EnemyAmbush = EnemyAmbush,
        EnemyData = EnemyData,
        SystemsDataTables = SystemsDataTables,
        DebugPrint = DebugPrint,
        EA_IsDebugMode = EA_IsDebugMode,
        EA_GetSettingBool = EA["EA_ReadSettingBool"],
        UpdateMetric = UpdateMetric,
        EA_RandIntCompat = EA_RandIntCompat,
        EA_NowMs = EA_NowMs,
        EA_NormalizeUUID = EA_NormalizeUUID,
        EA_GetRegionForCharacter = EA_GetRegionForCharacter,
        PlayVFX_OnEntity = PlayVFX_OnEntity,
        SafeOsiExec = SafeOsiExec,
        StorePendingAmbush = function(timer, ambushData)
            local fn = GetRuntimeFunction("PersistenceControl", "StorePendingAmbush")
            if type(fn) == "function" then
                return fn(timer, ambushData)
            end
            return nil
        end,
        EffectsDBRuntime = runtimes.EffectsDB,
    }, {
        EnemyAmbush = "tablelike",
        EnemyData = "tablelike",
        SystemsDataTables = "tablelike",
        DebugPrint = "callable",
        UpdateMetric = "callable",
        EA_RandIntCompat = "callable",
        EA_NowMs = "callable",
        EA_NormalizeUUID = "callable",
        EA_GetRegionForCharacter = "callable",
        PlayVFX_OnEntity = "callable",
        SafeOsiExec = "callable",
        StorePendingAmbush = "callable",
    })

    runtimes.ChampionControl = BuildRuntime("Systems_ChampionControl", "EnemyAmbush_Systems_ChampionControl.lua", {
        EnemyAmbush = EnemyAmbush,
        EA = EA,
        EA_Vars = EA_Vars,
        EA_IsModVarsContainer = EA_IsModVarsContainer,
        EA_Dirty = EA_Dirty,
        EA_IsDebugMode = EA_IsDebugMode,
        DebugPrint = DebugPrint,
        CreatureReputation = CreatureReputation,
        EA_NowMs = EA_NowMs,
        EA_LogChampionDiagnostics = supportBag.EA_LogChampionDiagnostics,
        EA_GetGuaranteedChampionArmed = EA_GetGuaranteedChampionArmed,
        EA_SetGuaranteedChampionArmed = (EA and EA["EA_SetGuaranteedChampionArmed"]) or EA_SetGuaranteedChampionArmed,
        GetLocationAppropriateEnemies = supportBag.EA_GetLocationAppropriateEnemies,
        GetSpawnChampionNow = function()
            return GetRuntimeFunction("ChampionSpawn", "SpawnChampionNow")
        end,
        GetResolveChampionSpawnData = function()
            return GetRuntimeFunction("ChampionSpawn", "EA_ResolveChampionSpawnData") or (EA and EA["EA_ResolveChampionSpawnData"]) or nil
        end,
        EA_CHAMPION_TYPE_COOLDOWN_REST_CYCLES = tonumber(supportBag.EA_CHAMPION_TYPE_COOLDOWN_REST_CYCLES) or 1,
    }, {
        EnemyAmbush = "tablelike",
        EA = "tablelike",
        EA_Dirty = "callable",
        DebugPrint = "callable",
        CreatureReputation = "tablelike",
        EA_NowMs = "callable",
        GetLocationAppropriateEnemies = "callable",
    })

    runtimes.ChampionSpawn = BuildRuntime("Systems_ChampionSpawn", "EnemyAmbush_Systems_ChampionSpawn.lua", {
        EnemyAmbush = EnemyAmbush,
        EnemyData = EnemyData,
        SystemsDataTables = SystemsDataTables,
        EA_GetPoolActiveSummonList = function(...)
            local fn = GetRuntimeFunction("PoolSelection", "EA_GetPoolActiveSummonList")
            if type(fn) == "function" then
                return fn(...)
            end
            return {}
        end,
        GetSafeLevel = supportBag.GetSafeLevel,
        EA_GetSettingBool = EA["EA_ReadSettingBool"],
        EA_IsDebugMode = EA_IsDebugMode,
        DebugPrint = DebugPrint,
        SafeGetPosition = SafeGetPosition,
        UpdateMetric = UpdateMetric,
        EA_RandFloatCompat = EA_RandFloatCompat,
        EA_RecordSpawnSuccess = EA_RecordSpawnSuccess,
        SafeOsiExec = SafeOsiExec,
        EA_IsRobust = EA_IsRobust,
        EA_LogEvent = EA_LogEvent,
        HasLineOfSight = HasLineOfSight,
        EA_FindValidPositionCompat = EA_FindValidPositionCompat,
        EA_GetSpawnRetryCount = EA_GetSpawnRetryCount,
        EA_SetLastError = EA_SetLastError,
        EA_RecordSpawnFailure = EA_RecordSpawnFailure,
        EA_StampChampionSpawn = function(...)
            local fn = GetRuntimeFunction("ChampionControl", "EA_StampChampionSpawn")
            if type(fn) == "function" then
                return fn(...)
            end
            return nil
        end,
        GetPartyMaxLevel = supportBag.GetPartyMaxLevel,
        SafeOsiCall = SafeOsiCall,
        EA_GetScaledAmbushLevel = supportBag.EA_GetScaledAmbushLevel,
        ApplyChampionBuffs = (type(EA._TierPackageRuntime) == "table" and EA._TierPackageRuntime.ApplyChampionBuffs) or function() end,
        EA_ApplyShadowCurseProtection = supportBag.EA_ApplyShadowCurseProtection,
        EA_ApplyChampionTelegraph = (type(EA._TierPackageRuntime) == "table" and EA._TierPackageRuntime.EA_ApplyChampionTelegraph) or function() end,
        EA_SelectEffectProfile = function(...)
            local fn = GetRuntimeFunction("Immersion", "EA_SelectEffectProfile")
            if type(fn) == "function" then
                return fn(...)
            end
            return nil
        end,
        EA_ShouldApplyArrivalCue = function(...)
            local fn = GetRuntimeFunction("Immersion", "EA_ShouldApplyArrivalCue")
            if type(fn) == "function" then
                return fn(...)
            end
            return false
        end,
        EA_SelectArrivalCue = function(...)
            local fn = GetRuntimeFunction("Immersion", "EA_SelectArrivalCue")
            if type(fn) == "function" then
                return fn(...)
            end
            return nil
        end,
        EA_MakeAmbushHostile = EA_MakeAmbushHostile,
        SafeApplyStatus = SafeApplyStatus,
        EA_RandIntCompat = EA_RandIntCompat,
        PlayVFX_OnEntity = PlayVFX_OnEntity,
        EA_GetXPRewardCategoryForTier = EA_GetXPRewardCategoryForTier,
        EA_GetXPRewardCategoryForEntry = EA_GetXPRewardCategoryForEntry,
        EA_CalcKillXP = EA_CalcKillXP,
        EA_GetEffectiveAmbushXPPercent = EA_GetEffectiveAmbushXPPercent,
        SafeAddBoosts = SafeAddBoosts,
        EA_NormalizeUUID = EA_NormalizeUUID,
        EA_Spawned = EA_Spawned,
        EA_NowMs = EA_NowMs,
        EA_EvictOldSpawned = EA_EvictOldSpawned,
        EA_GetEffectiveAllowChampionLoot = EA_GetEffectiveAllowChampionLoot,
        EA_ApplyNoLootFlags = supportBag.EA_ApplyNoLootFlags,
        EA_Dirty = EA_Dirty,
        EA_LogChampionDiagnostics = supportBag.EA_LogChampionDiagnostics,
        CreatureReputation = CreatureReputation,
        REPUTATION_THRESHOLDS = REPUTATION_THRESHOLDS,
        EA_CanSpawnChampionForType = function(...)
            local fn = GetRuntimeFunction("ChampionControl", "EA_CanSpawnChampionForType")
            if type(fn) == "function" then
                return fn(...)
            end
            return true
        end,
        EA_GetVengefulChampionChance = EA_GetVengefulChampionChance,
        EA_BAD_CHAMPION_TEMPLATES = EA_BAD_CHAMPION_TEMPLATES,
    }, {
        EnemyAmbush = "tablelike",
        EnemyData = "tablelike",
        SystemsDataTables = "tablelike",
        EA_GetPoolActiveSummonList = "callable",
        GetSafeLevel = "callable",
        DebugPrint = "callable",
        SafeGetPosition = "callable",
        SafeOsiExec = "callable",
        SafeOsiCall = "callable",
        EA_NowMs = "callable",
        EA_Dirty = "callable",
        EA_Spawned = "callable",
    })

    return runtimes
end

local function BuildStartupControlPlane(runtimes, startupDeps)
    startupDeps = type(startupDeps) == "table" and startupDeps or {}

    local persistenceRuntime = type(runtimes.PersistenceControl) == "table" and runtimes.PersistenceControl or {}
    local poolRuntime = type(runtimes.PoolSelection) == "table" and runtimes.PoolSelection or {}
    local loadReputation = persistenceRuntime.LoadReputation
    local markPoolNeedsRebuild = poolRuntime.EA_MarkPoolNeedsRebuild
    local notifyPoolProviderChanged = poolRuntime.EA_NotifyPoolProviderChanged

    local function EA_SessionLoadedInit(tries)
        tries = tonumber(tries) or 0
        EA_WarnLegacyGlobalSurface(startupDeps.IsDebug)

        if Osi and Osi.IsGameStateRunning then
            local ok, running = pcall(Osi.IsGameStateRunning)
            if ok and running ~= 1 then
                local debugPrint = startupDeps.DebugPrint
                local isDebug = startupDeps.IsDebug
                if type(debugPrint) == "function" and type(isDebug) == "function" and isDebug() then
                    debugPrint(string.format(
                        "[Startup] SessionLoaded init deferred: IsGameStateRunning=%s try=%d/15",
                        tostring(running),
                        tries
                    ))
                end
                if tries < 15 and Ext and Ext.Timer and Ext.Timer.WaitFor then
                    Ext.Timer.WaitFor(1000, function()
                        EA_SessionLoadedInit(tries + 1)
                    end)
                end
                return
            end
        end

        if type(loadReputation) == "function" then
            loadReputation()
        end
        if type(startupDeps.CheckVersion) == "function" then
            startupDeps.CheckVersion()
        end
        if type(markPoolNeedsRebuild) == "function" then
            markPoolNeedsRebuild()
        end
        if type(startupDeps.EA_SanitizePersistedTimes) == "function" then
            startupDeps.EA_SanitizePersistedTimes()
        end

        local getSpawned = startupDeps.EA_Spawned
        local dirtySpawned = startupDeps.EA_Dirty
        local evictOldSpawned = startupDeps.EA_EvictOldSpawned
        local normalizeUUID = startupDeps.EA_NormalizeUUID
        local nowMs = startupDeps.EA_NowMs
        local spawned = type(getSpawned) == "function" and getSpawned() or nil
        if type(spawned) ~= "table" and type(spawned) ~= "userdata" then
            spawned = nil
        end

        local dirty = false
        local count = 0
        local keys = {}
        if spawned then
            for uuid, _ in pairs(spawned) do
                keys[#keys + 1] = uuid
            end
        end

        for _, uuid in ipairs(keys) do
            local data = spawned and spawned[uuid] or nil
            if data then
                local norm = type(normalizeUUID) == "function" and normalizeUUID(uuid) or uuid

                if not norm then
                    spawned[uuid] = nil
                    dirty = true
                    count = count + 1
                else
                    if norm ~= uuid then
                        if spawned[norm] == nil then
                            spawned[norm] = data
                        end
                        spawned[uuid] = nil
                        dirty = true
                        uuid = norm
                        data = spawned[uuid] or data
                    end

                    if Osi.ObjectExists and Osi.ObjectExists(uuid) == 1 then
                        data.lastSeen = (type(nowMs) == "function" and nowMs()) or 0
                        if Osi.IsDead and Osi.IsDead(uuid) == 1 then
                            spawned[uuid] = nil
                            dirty = true
                            count = count + 1
                        end
                    end
                end
            end
        end

        if spawned and type(evictOldSpawned) == "function" then
            evictOldSpawned(spawned)
        end
        if type(startupDeps.EA_MarkSessionLoadedForCleanup) == "function" then
            startupDeps.EA_MarkSessionLoadedForCleanup()
        end
        if type(startupDeps.EA_AggressiveSpawnedCleanup) == "function" then
            startupDeps.EA_AggressiveSpawnedCleanup()
        end

        if dirty and spawned and type(dirtySpawned) == "function" then
            dirtySpawned()
            if count > 0 then
                print(string.format("[EnemyAmbush] Garbage Collector: Cleaned up %d orphaned entities from tracker.", count))
            end
        end

        print("[EnemyAmbush] Randomization initialized")

        if type(startupDeps.EA_InitPressureDecayState) == "function" then
            startupDeps.EA_InitPressureDecayState()
        end
        if type(startupDeps.EA_StartPressureDecayLoop) == "function" then
            startupDeps.EA_StartPressureDecayLoop()
        end

        local resetStatusExistenceCache = startupDeps.EA_ResetStatusExistenceCache
        if type(resetStatusExistenceCache) ~= "function" then
            resetStatusExistenceCache = EA and EA["EA_ResetStatusExistenceCache"] or nil
        end
        if type(resetStatusExistenceCache) == "function" then
            pcall(resetStatusExistenceCache)
        end

        local applyMCMSettings = startupDeps.ApplyMCMSettings
        if type(applyMCMSettings) == "function" then
            if Ext and Ext.Timer and Ext.Timer.WaitFor then
                Ext.Timer.WaitFor(250, function()
                    applyMCMSettings()
                end)
            else
                applyMCMSettings()
            end
        end

        local startupState = EnemyAmbush and EnemyAmbush._eaSessionStartupState or nil
        if type(startupState) == "table" then
            startupState.completed = true
            startupState.queued = false
            startupState.completedAtMs = type(startupDeps.EA_NowMs) == "function" and (tonumber(startupDeps.EA_NowMs()) or 0) or 0
        end
    end

    local function EnsureProviderHooksInstalled()
        if not (EnemyAmbush and EnemyAmbush.On) or EnemyAmbush._eaProviderHooksInstalled then
            return false
        end

        EnemyAmbush._eaProviderHooksInstalled = true
        EnemyAmbush.On("EnemyProvidersChanged", function(providerId)
            if type(notifyPoolProviderChanged) == "function" then
                notifyPoolProviderChanged("EnemyProvidersChanged (" .. tostring(providerId) .. ")", true, false)
            end
        end)
        EnemyAmbush.On("XPCloneMappingsChanged", function(providerId)
            if type(notifyPoolProviderChanged) == "function" then
                notifyPoolProviderChanged("XPCloneMappingsChanged (" .. tostring(providerId) .. ")", true, false)
            end
        end)
        EnemyAmbush.On("ChampionProvidersChanged", function(providerId)
            local debugPrint = startupDeps.DebugPrint
            if type(debugPrint) == "function" then
                debugPrint(string.format("[EnemyAmbush][API] ChampionProvidersChanged (%s)", tostring(providerId)))
            end
        end)
        return true
    end

    return {
        EA_SessionLoadedInit = EA_SessionLoadedInit,
        EnsureProviderHooksInstalled = EnsureProviderHooksInstalled,
    }
end

if type(spawnPipelineInputs) ~= "table" then
    print("[EnemyAmbush][Seam] CompositionRoot missing SpawnPipeline composition inputs.")
    return EA
end

local exportMap = spawnPipelineInputs.exportMap
local supportBag = spawnPipelineInputs.supportBag
local runtimeBag = spawnPipelineInputs.runtimeBag
local startupDeps = spawnPipelineInputs.startupDeps
if type(SystemsExports) ~= "table" or type(SystemsExports.BindExports) ~= "function" then
    print("[EnemyAmbush][Seam] CompositionRoot missing SystemsExports.BindExports.")
    return EA
end
if type(exportMap) ~= "table" then
    print("[EnemyAmbush][Seam] CompositionRoot missing SpawnPipeline export map.")
    return EA
end
if type(runtimeBag) ~= "table" then
    print("[EnemyAmbush][Seam] CompositionRoot missing SpawnPipeline runtime bag.")
    return EA
end
if type(supportBag) ~= "table" then
    print("[EnemyAmbush][Seam] CompositionRoot missing SpawnPipeline support bag.")
    return EA
end

runtimeBag = BuildOwnerRuntimeBag(runtimeBag, supportBag)

local function ApplyOwnerExportBindings(map, runtimes)
    local publicationOwners = {}
    local reboundKeys = {}
    local missingBindings = {}

    for _, ownerSpec in ipairs(OWNER_EXPORT_BINDINGS) do
        local runtime = runtimes[ownerSpec.owner]
        if type(runtime) ~= "table" then
            missingBindings[#missingBindings + 1] = string.format("%s.*", tostring(ownerSpec.owner))
        else
            for publicName, runtimeName in pairs(ownerSpec.exports) do
                local value = runtime[runtimeName]
                if value ~= nil then
                    map[publicName] = value
                    publicationOwners[publicName] = ownerSpec.owner
                    reboundKeys[#reboundKeys + 1] = publicName
                else
                    missingBindings[#missingBindings + 1] = string.format(
                        "%s.%s -> %s",
                        tostring(ownerSpec.owner),
                        tostring(runtimeName),
                        tostring(publicName)
                    )
                end
            end
        end
    end

    table.sort(reboundKeys)
    table.sort(missingBindings)
    return publicationOwners, reboundKeys, missingBindings
end

local function ApplySupportBindings(map, support)
    local publicationOwners = {}
    local reboundKeys = {}
    local missingBindings = {}

    for publicName, supportName in pairs(SUPPORT_EXPORT_BINDINGS) do
        local value = support[supportName]
        if value ~= nil then
            map[publicName] = value
            publicationOwners[publicName] = "CompositionRoot"
            reboundKeys[#reboundKeys + 1] = publicName
        else
            missingBindings[#missingBindings + 1] = string.format("support.%s -> %s", tostring(supportName), tostring(publicName))
        end
    end

    table.sort(reboundKeys)
    table.sort(missingBindings)
    return publicationOwners, reboundKeys, missingBindings
end

local composedExportMap = CopyMap(exportMap)
local publicationOwners, reboundKeys, missingBindings = ApplyOwnerExportBindings(composedExportMap, runtimeBag)
local supportPublicationOwners, supportReboundKeys, supportMissingBindings = ApplySupportBindings(composedExportMap, supportBag)
for key, value in pairs(supportPublicationOwners) do
    publicationOwners[key] = value
end
for _, key in ipairs(supportReboundKeys) do
    reboundKeys[#reboundKeys + 1] = key
end
for _, missing in ipairs(supportMissingBindings) do
    missingBindings[#missingBindings + 1] = missing
end
local startupControlPlane = BuildStartupControlPlane(runtimeBag, startupDeps)
if type(startupControlPlane.EA_SessionLoadedInit) == "function" then
    composedExportMap.EA_SessionLoadedInit = startupControlPlane.EA_SessionLoadedInit
    publicationOwners.EA_SessionLoadedInit = "CompositionRoot"
    reboundKeys[#reboundKeys + 1] = "EA_SessionLoadedInit"
end
if #missingBindings > 0 then
    print(string.format(
        "[EnemyAmbush][Seam] CompositionRoot owner export bindings missing: %s",
        table.concat(missingBindings, ", ")
    ))
end
table.sort(reboundKeys)

SystemsExports.BindExports(composedExportMap)
EA._TriggerAmbush = nil
local compatSeams = {}
local providerHooksInstalled = false
if type(startupControlPlane.EnsureProviderHooksInstalled) == "function" then
    providerHooksInstalled = startupControlPlane.EnsureProviderHooksInstalled() == true
end

local exportKeys = {}
for key, _ in pairs(composedExportMap) do
    exportKeys[#exportKeys + 1] = tostring(key)
end
table.sort(exportKeys)

EA.SystemsModules.CompositionRoot = {
    source = "EnemyAmbush_Systems_CompositionRoot.lua",
    composedFrom = tostring(spawnPipelineInputs.source or "unknown"),
    runtimeBag = runtimeBag,
    exportMap = composedExportMap,
    exportKeys = exportKeys,
    publicationOwners = publicationOwners,
    reboundKeys = reboundKeys,
    missingBindings = missingBindings,
    compatSeams = compatSeams,
    startupControlPlane = {
        owner = "CompositionRoot",
        sessionLoadedExport = "EA_SessionLoadedInit",
        providerHooksInstalled = providerHooksInstalled,
    },
}
EA.SystemsModules.OwnerRuntimes = runtimeBag

return EA
