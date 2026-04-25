EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local ModuleUUID = EA.ModuleUUID

-- Pull required functions into locals so your pasted listener code stays unchanged
local DebugPrint = EA["DebugPrint"]
local EA_AggressiveSpawnedCleanup = EA["EA_AggressiveSpawnedCleanup"]
local EA_Dirty = EA["EA_Dirty"]
local EA_EvictOldSpawned = EA["EA_EvictOldSpawned"]
local EA_NormalizeUUID = EA["EA_NormalizeUUID"]
local EA_NormalizeUUIDFast = EA["EA_NormalizeUUIDFast"]
local EA_Spawned = EA["EA_Spawned"]
local EA_SessionLoadedInit = EA["EA_SessionLoadedInit"]
local CleanupPendingAmbushes = EA["CleanupPendingAmbushes"]
local EA_AddAmbushPressure = EA["EA_AddAmbushPressure"]
local EA_AmbushPressure = EA["EA_AmbushPressure"]
local EA_ArmGuaranteedChampion = EA["EA_ArmGuaranteedChampion"]
local EA_CanSpawnChampionForType = EA["EA_CanSpawnChampionForType"]
local EA_IncrementRestCycleCounter = EA["EA_IncrementRestCycleCounter"]
local EA_GetAmbushPressure = EA["EA_GetAmbushPressure"]
local EA_GetCooldownEnabled = EA["EA_GetCooldownEnabled"]
local EA_IsQuickTestMode = EA["EA_IsQuickTestMode"]
local EA_GetEffectiveAmbushXPPercent = EA["EA_GetEffectiveAmbushXPPercent"]
local EA_GetEffectiveAllowChampionLoot = EA["EA_GetEffectiveAllowChampionLoot"]
local EA_GetEffectiveDisableAmbushLoot = EA["EA_GetEffectiveDisableAmbushLoot"]
local EA_IsAnyPartyInCombat = EA["EA_IsAnyPartyInCombat"]
local EA_IsRestAmbushEnabled = EA["EA_IsRestAmbushEnabled"]
local EA_PlayApproachBeatFromData = EA["EA_PlayApproachBeatFromData"]
local EA_PlayCombatStartVoiceOrSfx = EA["EA_PlayCombatStartVoiceOrSfx"]
local EA_Pending = EA["EA_Pending"]
local EA_NowMs = EA["EA_NowMs"]
local EA_PersistedNowMs = EA["EA_PersistedNowMs"]
local EA_RegisterTestSpawn = EA["EA_RegisterTestSpawn"]
local ExecuteAmbushSpawn = EA["ExecuteAmbushSpawn"]
local GetPointBudget = EA["GetPointBudget"]
local EA_GetPartyMembers = EA["EA_GetPartyMembers"]
local GetSafeLevel = EA["GetSafeLevel"]
local IsSafeToSpawnAmbush = EA["IsSafeToSpawnAmbush"]
local LaunchLongRestRetry = EA["LaunchLongRestRetry"] -- if this one is local, export it from Systems too
local SafeGetPosition = EA["SafeGetPosition"]
local SafeOsiCall = EA["SafeOsiCall"]
local SafeOsiExec = EA["SafeOsiExec"]
local SafeApplyStatus = EA["SafeApplyStatus"]
local SaveReputation = EA["SaveReputation"]
local SpawnChampionNow = EA["SpawnChampionNow"]
local SpawnHostileNearPlayer = EA["SpawnHostileNearPlayer"]
local ThemeAllowsEnemy = EA["ThemeAllowsEnemy"]
local TriggerAmbush = EA["TriggerAmbush"]
local ValidateEnemyData = EA["ValidateEnemyData"]
local PlayVFX_OnEntity = EA["PlayVFX_OnEntity"]
local EA_RunScriptedScenarioById = EA["EA_RunScriptedScenarioById"]
local EA_GetScriptedScenarioState = EA["EA_GetScriptedScenarioState"]
local EA_PlaySoundEvent = EA["EA_PlaySoundEvent"]
local EA_GetEscapeProfileByCreatureType = EA["EA_GetEscapeProfileByCreatureType"]
local EA_DESPAWN_FADE_SOUND = EA["EA_DESPAWN_FADE_SOUND"] or "VFX_Sound_Spell_Impact_Silent"
local EA_ClearHostileState = EA["EA_ClearHostileState"]
local EA_HandlePersistentHostileRetryTimer = EA["EA_HandlePersistentHostileRetryTimer"]
local EA_RearmPersistentHostileRetries = EA["EA_RearmPersistentHostileRetries"]
local EA_ClearLootButKeepCorpseClickable = EA["EA_ClearLootButKeepCorpseClickable"]
local EA_MakeAmbushHostile = EA["EA_MakeAmbushHostile"]
local EA_TryApplyPartySurprise = EA["EA_TryApplyPartySurprise"]
local EA_HandleSurpriseRollResult = EA["EA_HandleSurpriseRollResult"]
local EA_GetRegionForCharacter = EA["EA_GetRegionForCharacter"]
local EA_GetSafeZoneState = EA["EA_GetSafeZoneState"] or function(character)
    return {
        character = tostring(character or ""),
        activeZones = {},
        activeZoneIds = {},
        triggerBlocked = false,
    }
end
local EA_IsCharacterInBlockedSafeZone = EA["EA_IsCharacterInBlockedSafeZone"] or function()
    return false
end
local EA_RebuildSafeZoneRegistration = EA["EA_RebuildSafeZoneRegistration"] or function()
    return 0
end
local EA_OnEnteredSafeZoneTrigger = EA["EA_OnEnteredSafeZoneTrigger"] or function()
    return false
end
local EA_OnLeftSafeZoneTrigger = EA["EA_OnLeftSafeZoneTrigger"] or function()
    return false
end
local EA_LogUnknownRegion = EA["EA_LogUnknownRegion"]
local EA_AddTypePressure = EA["EA_AddTypePressure"]
local EA_WorldRepWindow = EA["EA_WorldRepWindow"]
local EA_ResetWorldRepWindow = EA["EA_ResetWorldRepWindow"]
local EA_IsDefeatedSpawned = EA["EA_IsDefeatedSpawned"]
local EA_ResolveCreatureTypeForCharacter = EA["EA_ResolveCreatureTypeForCharacter"]
local EA_ShouldSkipBeachTutorialAmbush = EA["EA_ShouldSkipBeachTutorialAmbush"]
local EA_Vars = EA["EA_Vars"]
local UpdateMetric = EA["UpdateMetric"] or function() end
local EA_P0Inc = EA["EA_P0Inc"] or function() return 0 end
local EA_P0Set = EA["EA_P0Set"] or function() return nil end
local EA_P0PushNote = EA["EA_P0PushNote"] or function() return 0 end
local EA_P0BumpKeyedCount = EA["EA_P0BumpKeyedCount"] or function() return 0 end
local EA_RandInt = EA["EA_RandInt"]
local EA_RandFloat = EA["EA_RandFloat"]
local EA_RandIntSafe = EA["EA_RandIntSafe"]
local EA_RandFloatSafe = EA["EA_RandFloatSafe"]
local EA_GetGuaranteedChampionQueueSafeFn = EA["EA_GetGuaranteedChampionQueueSafe"]
local EA_ValidateBuildDeps = EA["EA_ValidateBuildDeps"]
local EA_BuildRuntimeWithDepsShared = EA["EA_BuildRuntimeWithDeps"]
local EA_ReadSettingBool = EA["EA_ReadSettingBool"]
local EA_ReadSettingNumber = EA["EA_ReadSettingNumber"]

local function EA_ResolveExportFn(name, fallbackFn)
    local fn = EA and EA[name]
    if type(fn) == "function" then
        return fn
    end
    if type(fallbackFn) == "function" then
        return fallbackFn
    end
    return nil
end

local function EA_GetAuthoredAmbushRuntime()
    local systemsModules = EA and EA.SystemsModules
    local runtime = type(systemsModules) == "table" and systemsModules.AuthoredAmbushRuntime or nil
    if type(runtime) == "table" then
        return runtime
    end
    return nil
end

local function EA_RandomInt(minVal, maxVal)
    if type(EA_RandInt) == "function" then
        local ok, out = pcall(EA_RandInt, minVal, maxVal)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    if type(EA_RandIntSafe) == "function" then
        local ok, out = pcall(EA_RandIntSafe, minVal, maxVal)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    if maxVal == nil then
        local hi = math.floor(tonumber(minVal) or 1)
        if hi <= 1 then return 1 end
        return math.floor((1 + hi) * 0.5)
    end
    local lo = math.floor(tonumber(minVal) or 1)
    local hi = math.floor(tonumber(maxVal) or lo)
    if hi < lo then lo, hi = hi, lo end
    if hi <= lo then return lo end
    return lo + math.floor((hi - lo) * 0.5)
end

local function EA_RandomFloat()
    if type(EA_RandFloat) == "function" then
        local ok, out = pcall(EA_RandFloat)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    if type(EA_RandFloatSafe) == "function" then
        local ok, out = pcall(EA_RandFloatSafe)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    return 0.5
end

local function EA_DebugEnabled()
    if type(EA_ReadSettingBool) == "function" then
        return EA_ReadSettingBool("MCM_DebugMode", false) == true
    end
    return false
end

local function EA_P0NowMs()
    if type(EA_NowMs) == "function" then
        local ok, out = pcall(EA_NowMs)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
        return tonumber(Ext.Utils.MonotonicTime()) or 0
    end
    return 0
end

local function EA_P0RecordSessionMarker(kind, extra)
    EA_P0PushNote("session.markers", {
        kind = tostring(kind or "marker"),
        atMs = EA_P0NowMs(),
        extra = extra,
    }, 32)
end

local EnemyData = Ext.Require("EnemyAmbush_Data.lua") or {}
local SystemsDataTables = Ext.Require("EnemyAmbush_Systems_DataTables.lua") or {}
local EventsTimerRouter = Ext.Require("EnemyAmbush_Events_TimerRouter.lua") or {}
local EventsTimerFlow = Ext.Require("EnemyAmbush_Events_TimerFlow.lua") or {}
local EventsScenarioBootstrap = Ext.Require("EnemyAmbush_Events_ScenarioBootstrap.lua") or {}
local EventsCombatFlow = Ext.Require("EnemyAmbush_Events_CombatFlow.lua") or {}
local EventsCombatTurnFlow = Ext.Require("EnemyAmbush_Events_CombatTurnFlow.lua") or {}
local EventsDiagnostics = Ext.Require("EnemyAmbush_Events_Diagnostics.lua") or {}
local EventsTimerMain = Ext.Require("EnemyAmbush_Events_TimerMain.lua") or {}
local EventsRestTriggers = Ext.Require("EnemyAmbush_Events_RestTriggers.lua") or {}
if type(EnemyData) ~= "table" then
    EnemyData = {}
end

EA_P0Inc("session.bootCount")
EA_P0RecordSessionMarker("boot", { source = "EnemyAmbush_Events.lua" })

local function EA_BuildRuntimeWithDeps(moduleName, moduleTable, deps, schema)
    if type(EA_BuildRuntimeWithDepsShared) == "function" then
        return EA_BuildRuntimeWithDepsShared(moduleName, moduleTable, deps, schema)
    end
    if type(moduleTable) ~= "table" or type(moduleTable.Build) ~= "function" then
        return nil
    end
    if type(EA_ValidateBuildDeps) == "function" then
        local ok = EA_ValidateBuildDeps(moduleName, deps, schema)
        if ok ~= true then
            return nil
        end
    end
    local builtOk, runtimeOrErr = pcall(moduleTable.Build, deps)
    if not builtOk then
        print(string.format("[EnemyAmbush][Seam] %s Build() failed: %s", tostring(moduleName), tostring(runtimeOrErr)))
        return nil
    end
    return runtimeOrErr
end

if type(EventsTimerRouter) ~= "table"
    or type(EventsTimerRouter.IsOwnedTimer) ~= "function"
    or type(EventsTimerRouter.BuildExactHandlers) ~= "function"
    or type(EventsTimerRouter.TryHandleApproachBeatTimer) ~= "function" then
    print("[EnemyAmbush][Seam] Events timer-router contract missing required functions.")
else
    print("[EnemyAmbush][Seam] Events timer-router contract: OK")
end
if type(EventsTimerFlow) ~= "table" or type(EventsTimerFlow.Build) ~= "function" then
    print("[EnemyAmbush][Seam] Events timer-flow contract missing Build().")
else
    print("[EnemyAmbush][Seam] Events timer-flow contract: OK")
end
if type(EventsScenarioBootstrap) ~= "table" or type(EventsScenarioBootstrap.Build) ~= "function" then
    print("[EnemyAmbush][Seam] Events scenario-bootstrap contract missing Build().")
else
    print("[EnemyAmbush][Seam] Events scenario-bootstrap contract: OK")
end
if type(EventsCombatFlow) ~= "table" or type(EventsCombatFlow.Build) ~= "function" then
    print("[EnemyAmbush][Seam] Events combat-flow contract missing Build().")
else
    print("[EnemyAmbush][Seam] Events combat-flow contract: OK")
end
if type(EventsDiagnostics) ~= "table" or type(EventsDiagnostics.Build) ~= "function" then
    print("[EnemyAmbush][Seam] Events diagnostics contract missing Build().")
else
    print("[EnemyAmbush][Seam] Events diagnostics contract: OK")
end
if type(EventsTimerMain) ~= "table" or type(EventsTimerMain.Build) ~= "function" then
    print("[EnemyAmbush][Seam] Events timer-main contract missing Build().")
else
    print("[EnemyAmbush][Seam] Events timer-main contract: OK")
end
EnemyData.DEFAULT_DESPAWN_VFX = EnemyData.DEFAULT_DESPAWN_VFX
    or "VFX_Spells_Cast_Intent_Utility_TargetJump_MistyStep_BodyFX_01"

-- Dynamic wrappers (avoid caching EA[...] at file load; bootstrap/load order can make EA[...] nil)
EA_IsRestAmbushEnabled = function()
    local fn = EA and EA["EA_IsRestAmbushEnabled"]
    if type(fn) == "function" then
        return fn()
    end
    -- Fallback: if the function isn't available yet, don't crash rests.
    return true
end
EA_IsQuickTestMode = function()
    local fn = EA and EA["EA_IsQuickTestMode"]
    if type(fn) == "function" then
        return fn() == true
    end
    return false
end

EA_ArmGuaranteedChampion = EA_ArmGuaranteedChampion or function(character)
    local fn = EA and EA["EA_ArmGuaranteedChampion"]
    if type(fn) == "function" then
        return fn(character)
    end
end

EA_CanSpawnChampionForType = EA_CanSpawnChampionForType or function(creatureType)
    local fn = EA and EA["EA_CanSpawnChampionForType"]
    if type(fn) == "function" then
        return fn(creatureType)
    end
    return true
end

EA_PlaySoundEvent = EA_PlaySoundEvent or function() end
EA_GetEscapeProfileByCreatureType = EA_GetEscapeProfileByCreatureType or function(creatureType, ...)
    local fn = EA and EA["EA_GetEscapeProfileByCreatureType"]
    if type(fn) == "function" then
        return fn(creatureType, ...)
    end
    return {
        bonus = 0,
        vfx = "VFX_Spells_Cast_Intent_Utility_TargetJump_MistyStep_BodyFX_01",
        sfx = "VFX_Sound_Spell_Impact_Silent",
        fallbackMode = "misty_step"
    }
end
EA_ClearHostileState = EA_ClearHostileState or function() end
PlayVFX_OnEntity = PlayVFX_OnEntity or function() end
EA_ClearLootButKeepCorpseClickable = EA_ClearLootButKeepCorpseClickable or function() end
EA_GetEffectiveDisableAmbushLoot = EA_GetEffectiveDisableAmbushLoot or function()
    local fn = EA and EA["EA_GetEffectiveDisableAmbushLoot"]
    if type(fn) == "function" then
        return fn()
    end
    return true
end
EA_GetEffectiveAllowChampionLoot = EA_GetEffectiveAllowChampionLoot or function()
    local fn = EA and EA["EA_GetEffectiveAllowChampionLoot"]
    if type(fn) == "function" then
        return fn()
    end
    return true
end
EA_MakeAmbushHostile = EA_MakeAmbushHostile or function(enemy, player)
    local fn = EA and EA["EA_MakeAmbushHostile"]
    if type(fn) == "function" then
        return fn(enemy, player)
    end
end
EA_TryApplyPartySurprise = EA_TryApplyPartySurprise or function(player, ambushRoll, requireInCombat)
    local fn = EA and EA["EA_TryApplyPartySurprise"]
    if type(fn) == "function" then
        return fn(player, ambushRoll, requireInCombat)
    end
end
EA_PlayCombatStartVoiceOrSfx = EA_PlayCombatStartVoiceOrSfx or function(sourceEnemy, player, sourceData, combatGuid)
    local fn = EA and EA["EA_PlayCombatStartVoiceOrSfx"]
    if type(fn) == "function" then
        return fn(sourceEnemy, player, sourceData, combatGuid)
    end
    return false
end

EA_Pending = EA_Pending or function()
    local fn = EA and EA["EA_Pending"]
    if type(fn) == "function" then
        local ok, data = pcall(fn)
        if ok and (type(data) == "table" or type(data) == "userdata") then
            return data
        end
    end
    return nil
end

EA_NowMs = EA_NowMs or function()
    local fn = EA and EA["EA_NowMs"]
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    local persisted = EA and EA["EA_PersistedNowMs"]
    if type(persisted) == "function" then
        local ok, out = pcall(persisted)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    return 0
end

EA_AddTypePressure = EA_AddTypePressure or function(character, creatureType, amount)
    local fn = EA and EA["EA_AddTypePressure"]
    if type(fn) == "function" then
        return fn(character, creatureType, amount)
    end
    return 0
end

EA_WorldRepWindow = EA_WorldRepWindow or function()
    local fn = EA and EA["EA_WorldRepWindow"]
    if type(fn) == "function" then
        return fn()
    end
    return nil
end

EA_IsDefeatedSpawned = EA_IsDefeatedSpawned or function(character)
    local fn = EA and EA["EA_IsDefeatedSpawned"]
    if type(fn) == "function" then
        local ok, out = pcall(fn, character)
        if ok then
            return out == true
        end
    end
    return false
end

EA_ResetWorldRepWindow = EA_ResetWorldRepWindow or function(reason)
    local fn = EA and EA["EA_ResetWorldRepWindow"]
    if type(fn) == "function" then
        return fn(reason)
    end
    return 0
end

EA_ShouldSkipBeachTutorialAmbush = EA_ShouldSkipBeachTutorialAmbush or function()
    local fn = EA and EA["EA_ShouldSkipBeachTutorialAmbush"]
    if type(fn) == "function" then
        return fn() == true
    end
    if type(EA_ReadSettingBool) == "function" then
        return EA_ReadSettingBool("MCM_SkipBeachTutorialAmbush", false) == true
    end
    return false
end

EA_Spawned = EA_Spawned or function()
    local fn = EA and EA["EA_Spawned"]
    if type(fn) == "function" then
        local ok, data = pcall(fn)
        if ok and (type(data) == "table" or type(data) == "userdata") then
            return data
        end
    end
    EA._Spawned = EA._Spawned or {}
    return EA._Spawned
end

EA_NormalizeUUID = EA_NormalizeUUID or function(uuid)
    local fn = EA and EA["EA_NormalizeUUID"]
    if type(fn) == "function" then
        local ok, value = pcall(fn, uuid)
        if ok then
            return value
        end
    end
    if type(uuid) == "string" then
        return string.lower(uuid)
    end
    return uuid
end

local function EA_FastNormalizeUUID(uuid)
    local fnFast = EA_NormalizeUUIDFast or (EA and EA["EA_NormalizeUUIDFast"])
    if type(fnFast) == "function" then
        local ok, out = pcall(fnFast, uuid)
        if ok and out and out ~= "" then
            return out
        end
    end
    return nil
end

EA_ResolveCreatureTypeForCharacter = EA_ResolveCreatureTypeForCharacter or function(character, opts)
    local fn = EA and EA["EA_ResolveCreatureTypeForCharacter"]
    if type(fn) == "function" then
        return fn(character, opts)
    end
    return nil, nil
end

CleanupPendingAmbushes = CleanupPendingAmbushes or function(forceCap)
    local fn = EA and EA["CleanupPendingAmbushes"]
    if type(fn) == "function" then
        return fn(forceCap)
    end
end

EA_RunScriptedScenarioById = function(character, scenarioId, forceRun, opts)
    local runtime = EA_GetAuthoredAmbushRuntime()
    local fn = type(runtime) == "table" and runtime.RunScriptedScenarioById or nil
    if type(fn) ~= "function" then
        fn = EA and EA["EA_RunScriptedScenarioById"]
    end
    if type(fn) == "function" then
        return fn(character, scenarioId, forceRun, opts)
    end
    return false
end

EA_GetScriptedScenarioState = function()
    local runtime = EA_GetAuthoredAmbushRuntime()
    local fn = type(runtime) == "table" and runtime.GetScriptedScenarioState or nil
    if type(fn) ~= "function" then
        fn = EA and EA["EA_GetScriptedScenarioState"]
    end
    if type(fn) == "function" then
        return fn()
    end
    return nil
end

local function EA_TryRunInternalRegionEntryScenario(character, opts)
    local systemsModules = EA and EA.SystemsModules
    local authoredRuntime = type(systemsModules) == "table" and systemsModules.AuthoredAmbushRuntime or nil
    if type(authoredRuntime) == "table" and type(authoredRuntime.TryRegionEntryScenario) == "function" then
        return authoredRuntime.TryRegionEntryScenario(character, opts)
    end
    return false, 0, "authored_region_entry_runtime_unavailable"
end

local function EA_TickInternalTimeInDangerRisk(opts)
    local tickRisk = EA and EA["EA_TickTimeInDangerRisk"]
    if type(tickRisk) == "function" then
        return tickRisk(opts)
    end
    return false, 0, "time_in_danger_risk_runtime_unavailable"
end

local function EA_TryTriggerInternalTravelDangerAmbush(opts)
    local triggerTravel = EA and EA["EA_TryTriggerTravelDangerAmbush"]
    if type(triggerTravel) == "function" then
        return triggerTravel(opts)
    end
    return false, "travel_danger_runtime_unavailable"
end

local EA_WORLD_REP_DELTA_PER_KILL = -0.5
local EA_WORLD_REP_CAP_PER_TYPE_PER_LR = 3.0
local EA_WORLD_REP_CAP_GLOBAL_PER_LR = 6.0
local EA_WORLD_TYPE_PRESSURE_GAIN = 8
local EA_OUT_OF_COMBAT_REP_WINDOW_MS = 120000 -- 120s anti-chaining window for non-combat kill streaks
local EA_RUNTIME_COMBAT_TTL_MS = 45 * 60 * 1000
local EA_RUNTIME_STATE_DIRTY_DEBOUNCE_MS = 1500
local EA_RuntimeCombatStateDirtyAt = 0

local EA_LOCA_REP_WARNING_WARY = "h7f6f9f46g0d90g4a9egb7d9g8a7f57c96d30;1"
local EA_LOCA_REP_WARNING_HOSTILE = "h9a8ed1a4g77bcg4f2fg9f79g1b7da6608efc;1"
local EA_LOCA_REP_WARNING_VENGEFUL = "h6d42cc0bg2576g49bfg8bc6g2efafac71f7d;1"
local EA_GetCreatureReputationTable = EA["EA_GetCreatureReputationTable"]
local EA_GetReputationThresholds = EA["EA_GetReputationThresholds"]

local function EA_ReputationTable()
    if type(EA_GetCreatureReputationTable) ~= "function" and EA and type(EA["EA_GetCreatureReputationTable"]) == "function" then
        EA_GetCreatureReputationTable = EA["EA_GetCreatureReputationTable"]
    end
    if type(EA_GetCreatureReputationTable) == "function" then
        local ok, rep = pcall(EA_GetCreatureReputationTable)
        if ok and type(rep) == "table" then
            return rep
        end
    end
    EA.CreatureReputation = EA.CreatureReputation or {}
    return EA.CreatureReputation
end

local function EA_ReputationThresholdTable()
    if type(EA_GetReputationThresholds) ~= "function" and EA and type(EA["EA_GetReputationThresholds"]) == "function" then
        EA_GetReputationThresholds = EA["EA_GetReputationThresholds"]
    end
    if type(EA_GetReputationThresholds) == "function" then
        local ok, thresholds = pcall(EA_GetReputationThresholds)
        if ok and type(thresholds) == "table" then
            return thresholds
        end
    end
    EA.ReputationThresholds = EA.ReputationThresholds or { WARY = -5, HOSTILE = -10, VENGEFUL = -20 }
    return EA.ReputationThresholds
end

local function EA_MarkRuntimeStateDirty(force)
    if type(EA_Dirty) ~= "function" then
        return
    end
    local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
    if force == true or now <= 0 or (now - EA_RuntimeCombatStateDirtyAt) >= EA_RUNTIME_STATE_DIRTY_DEBOUNCE_MS then
        EA_RuntimeCombatStateDirtyAt = now
        EA_Dirty()
    end
end

local function EA_GetOutOfCombatRepLedger()
    local ledgerFn = EA and EA["EA_OutOfCombatRepLedger"]
    if type(ledgerFn) == "function" then
        local ok, ledger = pcall(ledgerFn)
        if ok and type(ledger) == "table" then
            return ledger
        end
    end
    EA._OutOfCombatRepLedger = EA._OutOfCombatRepLedger or {}
    return EA._OutOfCombatRepLedger
end

local function EA_FormatRepWarning(locaHandle, fallbackFmt, creatureType)
    local ct = tostring(creatureType or "Unknown")
    local template = EA_ResolveLocaText(locaHandle)
    if type(template) ~= "string" or template == "" or template == tostring(locaHandle or "") then
        template = tostring(fallbackFmt or "")
    end
    local ok, out = pcall(string.format, template, ct)
    if ok and type(out) == "string" and out ~= "" then
        return out
    end
    return template
end

local function EA_GetRuntimeCombatState()
    -- Runtime combat maps are session-only state. Persisting this in Ext.Vars
    -- caused class-registration errors on load for EA_RuntimeCombatState.
    -- Keep combat maps in-memory under EnemyAmbush only.
    EA._RuntimeCombatState = EA._RuntimeCombatState or {}
    local st = EA._RuntimeCombatState
    if type(st.escapeByCombat) ~= "table" then st.escapeByCombat = {} end
    if type(st.turnChatterByCombat) ~= "table" then st.turnChatterByCombat = {} end
    if type(st.combatByMember) ~= "table" then st.combatByMember = {} end
    if type(st.encounterRep) ~= "table" then st.encounterRep = {} end
    local er = st.encounterRep
    if type(er.perType) ~= "table" then er.perType = {} end
    if type(er.active) ~= "boolean" then er.active = false end
    if type(er.updatedAt) ~= "number" then er.updatedAt = 0 end
    return st
end

local function EA_GetRuntimeEscapeStateMap()
    local st = EA_GetRuntimeCombatState()
    return st.escapeByCombat
end

local function EA_GetRuntimeTurnChatterMap()
    local st = EA_GetRuntimeCombatState()
    return st.turnChatterByCombat
end

local function EA_GetRuntimeCombatMemberMap()
    local st = EA_GetRuntimeCombatState()
    return st.combatByMember
end

local function EA_GetEncounterRepState()
    local st = EA_GetRuntimeCombatState()
    local er = st.encounterRep
    er.perType = er.perType or {}
    return er
end

local function EA_BindRuntimeCombatMaps()
    EnemyAmbush._TurnChatterByCombat = EA_GetRuntimeTurnChatterMap()
    EnemyAmbush._CombatEscapeState = EA_GetRuntimeEscapeStateMap()
    EnemyAmbush._CombatKeyByMember = EA_GetRuntimeCombatMemberMap()
end

local function EA_GetEncounterRepMaxLoss()
    local modern = tonumber(EA and EA["EA_ENCOUNTER_REP_MAX_LOSS"])
    if modern and modern > 0 then
        return math.max(1, math.floor(modern))
    end
    return 3
end

local function EA_PruneOutOfCombatRepLedger(nowMs)
    local ledger = EA_GetOutOfCombatRepLedger()
    local now = tonumber(nowMs) or 0
    if now <= 0 then return end
    local changed = false
    for key, row in pairs(ledger) do
        local lastAt = tonumber(type(row) == "table" and row.lastAt) or 0
        if lastAt <= 0 or (now - lastAt) > EA_OUT_OF_COMBAT_REP_WINDOW_MS then
            ledger[key] = nil
            changed = true
        end
    end
    if changed and type(EA_Dirty) == "function" then
        EA_Dirty()
    end
end

local function EA_IsPartyAlignedCharacter(character, host)
    if type(character) ~= "string" or character == "" then return false end
    if Osi.ObjectExists and Osi.ObjectExists(character) ~= 1 then return false end
    if Osi.IsPlayer and Osi.IsPlayer(character) == 1 then
        return true
    end
    if host and host ~= "" and Osi.IsInPartyWith then
        local ok, same = pcall(Osi.IsInPartyWith, host, character)
        if ok and same == 1 then
            return true
        end
    end
    return false
end

local function EA_SelectWorldKillPlayer(victim, attackerA, attackerB)
    local host = (Osi and Osi.GetHostCharacter) and Osi.GetHostCharacter() or nil

    if EA_IsPartyAlignedCharacter(attackerA, host) then
        return attackerA, host
    end
    if EA_IsPartyAlignedCharacter(attackerB, host) then
        return attackerB, host
    end

    if Osi and Osi.GetClosestAlivePlayer then
        local p = Osi.GetClosestAlivePlayer(victim)
        if EA_IsPartyAlignedCharacter(p, host) then
            return p, host
        end
    end

    if type(host) == "string" and host ~= "" then
        return host, host
    end
    return nil, host
end

local function EA_ProcessWorldKillReputation(victim, attackerA, attackerB, storyActionId)
    EA_P0Inc("killedBy.seen")
    if type(EA_ReadSettingBool) == "function" and not EA_ReadSettingBool("MCM_EnableReputation", true) then
        EA_P0Inc("killedBy.skipReputationDisabled")
        return
    end
    if type(victim) ~= "string" or victim == "" then
        EA_P0Inc("killedBy.invalidVictim")
        return
    end
    if Osi.IsPlayer and Osi.IsPlayer(victim) == 1 then
        EA_P0Inc("killedBy.playerVictim")
        return
    end

    local id = EA_NormalizeUUID(victim)
    local spawned = EA_Spawned()
    if type(spawned) == "table" or type(spawned) == "userdata" then
        local spawnedData = (id and spawned[id]) or spawned[victim]
        if spawnedData then
            -- Ambush-spawned kills already run through the dedicated Dying path.
            EA_P0Inc("killedBy.spawnedSuppressed")
            return
        end
    end
    if EA_IsDefeatedSpawned(victim) then
        EA_P0Inc("killedBy.defeatedSpawnedSuppressed")
        UpdateMetric("worldRepSuppressedDefeatedSpawned")
        if EA_DebugEnabled() then
            DebugPrint(string.format(
                "[WorldRep] suppressed for previously defeated spawned ambusher: victim=%s action=%s",
                tostring(victim), tostring(storyActionId)))
        end
        return
    end

    local player, host = EA_SelectWorldKillPlayer(victim, attackerA, attackerB)
    local aParty = EA_IsPartyAlignedCharacter(attackerA, host)
    local bParty = EA_IsPartyAlignedCharacter(attackerB, host)
    if not aParty and not bParty then
        EA_P0Inc("killedBy.noPartyAlignedAttacker")
        return
    end

    local creatureType, templateId = EA_ResolveCreatureTypeForCharacter(victim, {
        preferCache = true,
        allowOsi = true,
        phase0Track = true,
    })
    if not creatureType or creatureType == "" then
        EA_P0Inc("killedBy.creatureTypeUnresolved")
        if templateId and templateId ~= "" then
            EA_P0Inc("killedBy.templateResolvedButUntracked")
        else
            EA_P0Inc("killedBy.templateStillUnresolved")
        end
        if EA_DebugEnabled() then
            DebugPrint(string.format(
                "[WorldRep] ignored kill (template not tracked): victim=%s template=%s action=%s",
                tostring(victim), tostring(templateId), tostring(storyActionId)))
        end
        return
    end

    local worldRep = EA_WorldRepWindow()
    if type(worldRep) ~= "table" then
        EA_P0Inc("killedBy.worldRepWindowUnavailable")
        return
    end
    worldRep.perType = worldRep.perType or {}

    local usedType = tonumber(worldRep.perType[creatureType]) or 0
    local usedGlobal = tonumber(worldRep.total) or 0
    local stepAbs = math.abs(EA_WORLD_REP_DELTA_PER_KILL)
    local remainType = math.max(0, EA_WORLD_REP_CAP_PER_TYPE_PER_LR - usedType)
    local remainGlobal = math.max(0, EA_WORLD_REP_CAP_GLOBAL_PER_LR - usedGlobal)
    local allowAbs = math.min(stepAbs, remainType, remainGlobal)

    if allowAbs <= 0 then
        EA_P0Inc("killedBy.capReached")
        if EA_DebugEnabled() then
            DebugPrint(string.format(
                "[WorldRep] cap reached (type/global): ct=%s usedType=%.2f usedGlobal=%.2f",
                tostring(creatureType), usedType, usedGlobal))
        end
        return
    end

    local repTable = EA_ReputationTable()
    local repChange = -allowAbs
    local oldRep = repTable[creatureType] or 0
    local newRep = oldRep + repChange
    repTable[creatureType] = newRep
    worldRep.perType[creatureType] = usedType + allowAbs
    worldRep.total = usedGlobal + allowAbs
    worldRep.lastUpdateAt = EA_NowMs()
    EA_P0Inc("killedBy.worldRepApplied")

    if type(EA_AddTypePressure) == "function" and player and player ~= "" then
        EA_AddTypePressure(player, creatureType, EA_WORLD_TYPE_PRESSURE_GAIN)
    end

    print(string.format(
        "[EnemyAmbush][WorldRep] %s %.1f -> %.1f (delta=%.1f capType=%.1f/%.1f capGlobal=%.1f/%.1f template=%s)",
        tostring(creatureType),
        tonumber(oldRep) or 0,
        tonumber(newRep) or 0,
        repChange,
        tonumber(worldRep.perType[creatureType]) or 0, EA_WORLD_REP_CAP_PER_TYPE_PER_LR,
        tonumber(worldRep.total) or 0, EA_WORLD_REP_CAP_GLOBAL_PER_LR,
        tostring(templateId)
    ))

    -- Phase 8 / LP-02 measured follow-through:
    -- world-reputation updates are driven by the broad KilledBy hook, so we keep
    -- snapshot ownership in PersistenceControl but avoid forcing an immediate
    -- DirtyModVariables flush for every accepted world kill.
    if SaveReputation then
        SaveReputation(false)
    elseif EA_Dirty then
        EA_Dirty()
    end
end

local function EA_HandleKilledByEvent(victim, attackerOwner, attacker, storyActionId)
    EA_P0Inc("listenerExec.KilledBy.total")
    if type(victim) ~= "string" or victim == "" then
        EA_P0Inc("killedBy.invalidVictim")
        return
    end

    local victimKey = EA_NormalizeUUID(victim) or victim
    local pairKey = string.format("%s|%s", tostring(victimKey), tostring(storyActionId or ""))
    local seen = EA_P0BumpKeyedCount("killedBy.byVictimAction", pairKey, 64)
    if seen > 1 then
        EA_P0PushNote("killedBy.samples", {
            kind = "duplicate_victim_action",
            key = pairKey,
            count = seen,
        }, 24)
    end

    local aOwner = (type(attackerOwner) == "string" and attackerOwner ~= "") and attackerOwner or nil
    local aDirect = (type(attacker) == "string" and attacker ~= "") and attacker or nil
    EA_ProcessWorldKillReputation(victim, aOwner, aDirect, storyActionId)
end

local function EA_DeleteStuckAmbusher(enemy, reason)
    if not enemy or enemy == "" then return end
    if Osi and Osi.IsInCombat and Osi.IsInCombat(enemy) == 1 then return end

    local norm = (EA_NormalizeUUID and (EA_NormalizeUUID(enemy) or enemy)) or enemy
    local spawned = (type(EA_Spawned) == "function") and EA_Spawned() or nil
    if type(spawned) == "table" then
        if norm then spawned[norm] = nil end
        spawned[enemy] = nil
        if EA_Dirty then EA_Dirty() end
    end
    if type(EnemyAmbush._CombatKeyByAmbusher) == "table" then
        EnemyAmbush._CombatKeyByAmbusher[enemy] = nil
        if norm then
            EnemyAmbush._CombatKeyByAmbusher[norm] = nil
        end
    end
    if type(EnemyAmbush._CombatKeyByMember) == "table" then
        EnemyAmbush._CombatKeyByMember[enemy] = nil
        if norm then
            EnemyAmbush._CombatKeyByMember[norm] = nil
        end
    end

    if EA_ClearHostileState then
        pcall(EA_ClearHostileState, enemy)
        if norm then pcall(EA_ClearHostileState, norm) end
    end

    if Osi and Osi.ObjectExists and Osi.ObjectExists(enemy) == 1 and Osi.RequestDelete then
        pcall(Osi.RequestDelete, enemy)
        if EA_DebugEnabled() then
            print(string.format("[EnemyAmbush][Debug] Deleted stuck ambusher: %s reason=%s", tostring(enemy), tostring(reason or "unknown")))
        end
    end
end

local EA_DespawnLogAt = {}
local EA_DESPAWN_LOG_MAX_ENTRIES = 800
local EA_DESPAWN_LOG_STALE_MS = 3600000
local function EA_PruneDespawnLog(now)
    local count = 0
    local staleKeys = {}
    for key, ts in pairs(EA_DespawnLogAt) do
        count = count + 1
        local last = tonumber(ts) or 0
        if last <= 0 or (now - last) >= EA_DESPAWN_LOG_STALE_MS then
            staleKeys[#staleKeys + 1] = key
        end
    end

    for _, key in ipairs(staleKeys) do
        if EA_DespawnLogAt[key] ~= nil then
            EA_DespawnLogAt[key] = nil
            count = count - 1
        end
    end

    if count <= EA_DESPAWN_LOG_MAX_ENTRIES then
        return
    end

    local trim = count - EA_DESPAWN_LOG_MAX_ENTRIES
    for key in pairs(EA_DespawnLogAt) do
        EA_DespawnLogAt[key] = nil
        trim = trim - 1
        if trim <= 0 then
            break
        end
    end
end

local function EA_ShouldLogDespawn(ent, kind, intervalMs)
    if not EA_DebugEnabled() then
        return false
    end
    if not ent or ent == "" then
        return false
    end
    local now = tonumber((EA_NowMs and EA_NowMs()) or 0) or 0
    EA_PruneDespawnLog(now)
    local key = string.format("%s|%s", tostring(kind or "generic"), tostring(ent))
    local minInterval = tonumber(intervalMs) or 30000
    local last = tonumber(EA_DespawnLogAt[key]) or 0
    if (now - last) >= minInterval then
        EA_DespawnLogAt[key] = now
        return true
    end
    return false
end

local function EA_GetPartyXPRecipients(anchorPlayer, fallbackCharacter)
    local recipients = {}
    local seen = {}

    local function Add(player)
        if not player or player == "" then return end
        if Osi.IsPlayer and Osi.IsPlayer(player) ~= 1 then return end
        if seen[player] then return end
        seen[player] = true
        recipients[#recipients + 1] = player
    end

    Add(anchorPlayer)

    if anchorPlayer and anchorPlayer ~= "" then
        local helper = EA_GetPartyMembers or (EA and EA["EA_GetPartyMembers"])
        if type(helper) == "function" then
            local okMembers, members = pcall(helper, anchorPlayer)
            if okMembers and type(members) == "table" then
                for _, member in ipairs(members) do
                    Add(member)
                end
            end
        elseif Osi.DB_PartyMembers and Osi.DB_PartyMembers.Get then
            local okRows, rows = pcall(function()
                return Osi.DB_PartyMembers:Get(nil)
            end)
            if okRows and rows then
                for _, row in ipairs(rows) do
                    local member = row[1]
                    if member and member ~= "" and Osi.IsPlayer and Osi.IsPlayer(member) == 1 then
                        local sameParty = true
                        if Osi.IsInPartyWith then
                            sameParty = (Osi.IsInPartyWith(anchorPlayer, member) == 1)
                        end
                        if sameParty then
                            Add(member)
                        end
                    end
                end
            end
        end
    end

    if #recipients == 0 and fallbackCharacter and fallbackCharacter ~= "" and Osi.GetClosestAlivePlayer then
        Add(Osi.GetClosestAlivePlayer(fallbackCharacter))
    end
    if #recipients == 0 and Osi.GetHostCharacter then
        Add(Osi.GetHostCharacter())
    end

    return recipients
end

local EA_HandleScenarioBootstrapTimer = function(_timer)
    return false
end
local EA_OnScenarioBootstrapSessionLoaded = function()
end
local EA_ScenarioBootstrapSessionLoadedIsStub = true
local EA_ScenarioBootstrapSessionInitDispatched = false
local EA_ScenarioBootstrapSessionLoadedSeen = false

local function EA_TryEnsureBeachBootstrapStartedDelayed(source, retries)
    retries = tonumber(retries) or 0
    local ensureBeachBootstrapStarted = EA and EA["EA_EnsureBeachBootstrapStarted"]
    if type(ensureBeachBootstrapStarted) == "function" then
        local okEnsure, ensureErr = pcall(ensureBeachBootstrapStarted, source)
        if okEnsure then
            return
        end
        if retries < 20 and Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(250, function()
                EA_TryEnsureBeachBootstrapStartedDelayed(source, retries + 1)
            end)
            return
        end
        print(string.format(
            "[EnemyAmbush][Bootstrap] Direct bootstrap start failed (%s): %s",
            tostring(source or "unknown"),
            tostring(ensureErr)
        ))
        return
    end
    if retries < 20 and Ext and Ext.Timer and Ext.Timer.WaitFor then
        Ext.Timer.WaitFor(250, function()
            EA_TryEnsureBeachBootstrapStartedDelayed(source, retries + 1)
        end)
        return
    end
    if retries > 0 then
        print(string.format(
            "[EnemyAmbush][Bootstrap] Direct bootstrap start unavailable (%s): missing export after %d retries",
            tostring(source or "unknown"),
            retries
        ))
    end
end

local function EA_DispatchScenarioBootstrapSessionLoaded(source)
    if EA_ScenarioBootstrapSessionLoadedIsStub == true then
        return
    end
    if EA_ScenarioBootstrapSessionInitDispatched == true then
        return
    end
    EA_ScenarioBootstrapSessionInitDispatched = true
    local ok, err = pcall(EA_OnScenarioBootstrapSessionLoaded)
    if not ok then
        EA_ScenarioBootstrapSessionInitDispatched = false
        print(string.format(
            "[EnemyAmbush][Bootstrap] Scenario bootstrap session init failed (%s): %s",
            tostring(source or "unknown"),
            tostring(err)
        ))
    end
end

local function EA_LocaHandleNoVersion(rawText)
    if type(rawText) ~= "string" then return nil end
    local s = rawText:match("^%s*(.-)%s*$")
    if not s or s == "" then return nil end
    local bare = s:match("^(h[%w]+);%d+$")
    if bare then return bare end
    bare = s:match("^(h[%w]+)$")
    if bare then return bare end
    return nil
end

local function EA_ResolveLocaText(rawText)
    local shared = EA and EA["EA_ResolveLocaText"]
    if type(shared) == "function" then
        local ok, out = pcall(shared, rawText)
        if ok and type(out) == "string" then
            return out
        end
    end
    local text = tostring(rawText or "")
    if text == "" then
        return ""
    end
    local bare = EA_LocaHandleNoVersion(text)
    if bare and Osi and Osi.ResolveTranslatedString then
        local okBare, translatedBare = pcall(Osi.ResolveTranslatedString, bare)
        if okBare and type(translatedBare) == "string" and translatedBare ~= "" and translatedBare ~= bare then
            return translatedBare
        end
    end
    return text
end

local EventsTimerMainRuntime = nil
local function EA_GetSessionStartupState()
    local state = EnemyAmbush._eaSessionStartupState
    if type(state) ~= "table" then
        state = {
            queued = false,
            completed = false,
            queuedAtMs = 0,
            completedAtMs = 0,
            retryCount = 0,
            lastSource = "",
        }
        EnemyAmbush._eaSessionStartupState = state
    end
    return state
end

local function EA_QueueSessionStartup(source)
    if not (Ext and Ext.IsServer and Ext.IsServer()) then
        return false
    end
    local state = EA_GetSessionStartupState()
    if state.completed == true then
        return false
    end

    local nowMs = EA_P0NowMs()
    local queuedAtMs = tonumber(state.queuedAtMs) or 0
    local isTimedOut = queuedAtMs > 0 and nowMs > 0 and (nowMs - queuedAtMs) >= 20000
    if state.queued == true and not isTimedOut then
        return false
    end
    if state.queued == true and isTimedOut then
        if tonumber(state.retryCount) >= 3 then
            print(string.format(
                "[EnemyAmbush][Startup] Session startup timed out after %dms and hit retry cap (%d); waiting for manual fallback source=%s",
                tonumber(nowMs - queuedAtMs) or 0,
                tonumber(state.retryCount) or 0,
                tostring(source or "unknown")
            ))
            return false
        end
        state.retryCount = (tonumber(state.retryCount) or 0) + 1
        print(string.format(
            "[EnemyAmbush][Startup] Session startup timed out after %dms; re-queueing attempt=%d source=%s",
            tonumber(nowMs - queuedAtMs) or 0,
            tonumber(state.retryCount) or 0,
            tostring(source or "unknown")
        ))
    end

    local sessionLoadedInit = EA_ResolveExportFn("EA_SessionLoadedInit", EA_SessionLoadedInit)
    if type(sessionLoadedInit) ~= "function" then
        print("[EnemyAmbush][Seam] SessionLoaded export unavailable: EA_SessionLoadedInit")
        return false
    end

    state.queued = true
    state.completed = false
    state.queuedAtMs = nowMs
    state.lastSource = tostring(source or "unknown")
    EA_ScenarioBootstrapSessionLoadedSeen = true
    local loadedAtMs = nowMs
    EA_P0Inc("session.sessionLoadedCount")
    EA_P0Set("session.lastSessionLoadedAtMs", loadedAtMs)
    EA_P0RecordSessionMarker("session_loaded", {
        atMs = loadedAtMs,
        source = tostring(source or "unknown"),
    })

    if tostring(source or "") ~= "session_loaded_event" then
        print(string.format(
            "[EnemyAmbush][Startup] Session startup queued via fallback source=%s",
            tostring(source or "unknown")
        ))
    end

    local resetLocalTemplateCache = EA and EA["EA_ResetLocalCharacterTemplateCache"]
    if type(resetLocalTemplateCache) == "function" then
        local okReset, resetErr = pcall(resetLocalTemplateCache)
        if not okReset then
            print(string.format("[EnemyAmbush][WorldRep] Local template cache reset failed: %s", tostring(resetErr)))
        end
    end

    -- Small delay; EA_SessionLoadedInit also retries until IsGameStateRunning.
    Ext.Timer.WaitFor(500, function()
        sessionLoadedInit(0)
        if EventsTimerMainRuntime and type(EventsTimerMainRuntime.HandleSessionLoadedTimerStartup) == "function" then
            EventsTimerMainRuntime.HandleSessionLoadedTimerStartup(0)
        else
            print("[EnemyAmbush][Seam] Events timer-main runtime missing HandleSessionLoadedTimerStartup().")
        end
    end)
    EA_BindRuntimeCombatMaps()

    -- Startup guardrails for RC namespace/export cleanup.
    if Ext and Ext.Timer and Ext.Timer.WaitFor then
        Ext.Timer.WaitFor(1200, function()
            local bannedGlobals = {
                "SUMMON_CHANCE_SHORT",
                "SUMMON_CHANCE_LONG",
                "CreatureReputation",
                "REPUTATION_THRESHOLDS",
                "SaveReputation",
                "LoadReputation",
            }
            local found = {}
            for _, key in ipairs(bannedGlobals) do
                if rawget(_G, key) ~= nil then
                    found[#found + 1] = key
                end
            end
            if #found > 0 then
                print(string.format(
                    "[EnemyAmbush][StartupGuard] Deprecated globals detected in _G: %s",
                    table.concat(found, ", ")
                ))
            end

            local requiredExports = {
                "EA_GetPoolActiveSummonList",
                "TriggerAmbush",
                "SpawnHostileNearPlayer",
                "ExecuteAmbushSpawn",
                "EA_NormalizeUUID",
                "EA_PersistedNowMs",
                "EA_GetGuaranteedChampionQueueSafe",
                "EA_GetSafeZoneState",
                "EA_IsCharacterInBlockedSafeZone",
                "EA_RebuildSafeZoneRegistration",
                "EA_ResetLocalCharacterTemplateCache",
                "EA_PrimeCharacterTemplateCache",
            }
            local missing = {}
            for _, key in ipairs(requiredExports) do
                if type(EA[key]) ~= "function" then
                    missing[#missing + 1] = key
                end
            end
            if #missing > 0 then
                print(string.format(
                    "[EnemyAmbush][StartupGuard] Missing required EA exports: %s",
                    table.concat(missing, ", ")
                ))
            end

            local startupAudit = EA_ResolveExportFn("EA_RunStartupTemplateAudit", nil)
            if EA_DebugEnabled() and type(startupAudit) == "function" then
                pcall(startupAudit, 8)
            end
        end)
    end

    if type(EA_RebuildSafeZoneRegistration) == "function" then
        local function RegisterSafeZoneTriggers()
            local ok, countOrErr = pcall(EA_RebuildSafeZoneRegistration)
            if not ok then
                print(string.format("[EnemyAmbush][SafeZone] Session trigger registration failed: %s", tostring(countOrErr)))
                return
            end
            if EA_DebugEnabled() then
                DebugPrint(string.format("Registered safe-zone triggers: %s", tostring(countOrErr or 0)))
            end
        end
        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(750, RegisterSafeZoneTriggers)
        else
            RegisterSafeZoneTriggers()
        end
    end

    if Ext and Ext.Timer and Ext.Timer.WaitFor then
        local queuedStamp = tonumber(state.queuedAtMs) or 0
        Ext.Timer.WaitFor(20000, function()
            local latest = EA_GetSessionStartupState()
            if latest.completed == true then
                return
            end
            if latest.queued == true and tonumber(latest.queuedAtMs) == queuedStamp then
                latest.queued = false
                EA_QueueSessionStartup("startup_watchdog")
            end
        end)
    end

    return true
end

-- Run init only once the session is loaded (server only).
if Ext and Ext.Events and Ext.Events.SessionLoaded then
    EA_P0Inc("listenerReg.SessionLoaded.subscribe")
    Ext.Events.SessionLoaded:Subscribe(function()
        EA_QueueSessionStartup("session_loaded_event")
    end)
end

if Ext and Ext.Osiris and Ext.Osiris.RegisterListener then
    EA_P0Inc("listenerReg.SavegameLoaded.subscribe")
    Ext.Osiris.RegisterListener("SavegameLoaded", 0, "after", function()
        EA_QueueSessionStartup("savegame_loaded_fallback")
    end)
    EA_P0Inc("listenerReg.LevelGameplayStarted.subscribe")
    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(_levelName, _isEditorMode)
        EA_QueueSessionStartup("level_gameplay_started_fallback")
    end)
end

if Ext and Ext.Timer and Ext.Timer.WaitFor then
    -- Last-resort bootstrap only: let SessionLoaded/SavegameLoaded/LevelGameplayStarted
    -- settle first so normal loads do not get an unnecessary early fallback queue.
    Ext.Timer.WaitFor(12000, function()
        local state = EA_GetSessionStartupState()
        if state.completed == true or state.queued == true then
            return
        end
        if tostring(state.lastSource or "") ~= "" then
            return
        end
        if (tonumber(state.retryCount) or 0) > 0 then
            return
        end
        EA_QueueSessionStartup("bootstrap_watchdog_late")
    end)
end

-- Shared config (defined in Utils, stored on EnemyAmbush.CFG)
local CFG = EA.CFG or {}
local RestDefaults = (SystemsDataTables and SystemsDataTables.REST_DEFAULTS) or {}
local TIMER_PREFIXES = (SystemsDataTables and SystemsDataTables.TIMER_PREFIXES) or {}
local LONG_REST_SAFETY_DELAY = tonumber(CFG.LONG_REST_SAFETY_DELAY)
    or tonumber(RestDefaults.LONG_REST_SAFETY_DELAY_S)
    or 30
local AMBUSH_PRESSURE_MAX = tonumber(CFG.AMBUSH_PRESSURE_MAX)
    or tonumber(RestDefaults.AMBUSH_PRESSURE_MAX)
    or 100
local LONG_REST_RETRY_MAX = tonumber(RestDefaults.LONG_REST_RETRY_MAX) or 6
local SHORT_REST_RETRY_MAX = tonumber(RestDefaults.SHORT_REST_RETRY_MAX) or 6
local DELAYED_AMBUSH_RETRY_MAX = tonumber(RestDefaults.DELAYED_AMBUSH_RETRY_MAX) or 8
local EA_REHYDRATE_READY_RETRY_MAX = tonumber(RestDefaults.REHYDRATE_READY_RETRY_MAX) or 30
local EA_REHYDRATE_READY_RETRY_MS = tonumber(RestDefaults.REHYDRATE_READY_RETRY_MS) or 1000
local EA_STAGGER_STEP_MS_MIN = tonumber(RestDefaults.STAGGER_STEP_MS_MIN) or 20
local EA_STAGGER_STEP_MS_DEFAULT = tonumber(RestDefaults.STAGGER_STEP_MS_DEFAULT) or 100
local EA_STAGGER_STEP_MS_MAX = tonumber(RestDefaults.STAGGER_STEP_MS_MAX) or 500
local EA_STAGGER_QUEUE_INITIAL_DELAY_MIN_MS = tonumber(RestDefaults.STAGGER_QUEUE_INITIAL_DELAY_MIN_MS) or 50
local EA_RETRY_LOG_EVERY = tonumber(RestDefaults.RETRY_LOG_EVERY) or 5

-- Rest/message-box listener registration is coordinated explicitly from this file.

-- Helpful diagnostic when forced hostility doesn't actually produce combat.
-- Keep this in a dedicated function so listener-scoped helper locals do not
-- consume main-chunk local slots (Lua hard cap: 200 per function/chunk).
local EventsCombatFlowRuntime = nil
if EventsCombatFlow and type(EventsCombatFlow.Build) == "function" then
    local deps = {
        EnemyAmbush = EnemyAmbush,
        EA = EA,
        DebugPrint = DebugPrint,
        EA_BindRuntimeCombatMaps = EA_BindRuntimeCombatMaps,
        EA_GetRuntimeCombatMemberMap = EA_GetRuntimeCombatMemberMap,
        EA_GetRuntimeTurnChatterMap = EA_GetRuntimeTurnChatterMap,
        EA_GetRuntimeEscapeStateMap = EA_GetRuntimeEscapeStateMap,
        EA_MarkRuntimeStateDirty = EA_MarkRuntimeStateDirty,
        EA_RUNTIME_COMBAT_TTL_MS = EA_RUNTIME_COMBAT_TTL_MS,
        EA_NormalizeUUID = EA_NormalizeUUID,
        EA_FastNormalizeUUID = EA_FastNormalizeUUID,
        EA_NowMs = EA_NowMs,
        EA_Spawned = EA_Spawned,
        EA_GetPartyMembers = EA_GetPartyMembers,
        EA_ClearHostileState = EA_ClearHostileState,
        EA_Dirty = EA_Dirty,
        EA_DESPAWN_FADE_SOUND = EA_DESPAWN_FADE_SOUND,
        EA_DebugEnabled = EA_DebugEnabled,
        UpdateMetric = UpdateMetric,
        EA_P0Inc = EA_P0Inc,
        PlayVFX_OnEntity = PlayVFX_OnEntity,
        SafeApplyStatus = SafeApplyStatus,
        EnemyData = EnemyData,
        EA_PlaySoundEvent = EA_PlaySoundEvent,
        SafeOsiExec = SafeOsiExec,
        EA_GetEscapeProfileByCreatureType = EA_GetEscapeProfileByCreatureType,
        EA_RandomInt = EA_RandomInt,
        EA_DeleteStuckAmbusher = EA_DeleteStuckAmbusher,
        EA_MakeAmbushHostile = EA_MakeAmbushHostile,
        EA_RegisterDeferredSupportJoinWindow = EA["EA_RegisterDeferredSupportJoinWindow"],
        EA_IsAnyPartyInCombat = EA_IsAnyPartyInCombat,
        EA_TryApplyPartySurprise = EA_TryApplyPartySurprise,
        EA_PlayCombatStartVoiceOrSfx = EA_PlayCombatStartVoiceOrSfx,
        EA_HandleSurpriseRollResult = EA_HandleSurpriseRollResult,
        EA_ReadSettingBool = EA_ReadSettingBool,
        EA_ReadSettingNumber = EA_ReadSettingNumber,
        EA_PrimeCharacterTemplateCache = EA["EA_PrimeCharacterTemplateCache"],
    }
    EventsCombatFlowRuntime = EA_BuildRuntimeWithDeps("EventsCombatFlow", EventsCombatFlow, deps, {
        EnemyAmbush = "tablelike",
        EA = "tablelike",
        DebugPrint = "callable",
        EA_NowMs = "callable",
        EA_Spawned = "callable",
        EA_GetPartyMembers = "callable",
        EA_P0Inc = "callable",
        SafeOsiExec = "callable",
    })
end

local EventsCombatTurnFlowRuntime = nil
if EventsCombatTurnFlow and type(EventsCombatTurnFlow.Build) == "function" then
    local combatFlowFns = EventsCombatFlowRuntime or {}
    local deps = {
        EnemyAmbush = EnemyAmbush,
        EA = EA,
        DebugPrint = DebugPrint,
        UpdateMetric = UpdateMetric,
        EA_P0Inc = EA_P0Inc,
        EA_Spawned = EA_Spawned,
        EA_NormalizeUUID = EA_NormalizeUUID,
        EA_FastNormalizeUUID = EA_FastNormalizeUUID,
        EA_NormalizeCombatKey = EA_NormalizeCombatKey,
        EA_EnsureCombatEscapeState = combatFlowFns.EnsureCombatEscapeState,
        EA_GetPlayerFromCombat = EA_GetPlayerFromCombat,
        EA_JoinDeferredSupportsForAmbush = EA_JoinDeferredSupportsForAmbush,
        EA_CleanupCombatEscapeStateIfIdle = combatFlowFns.CleanupCombatEscapeStateIfIdle,
        EA_ResetSoftlockIdleCounter = combatFlowFns.ResetSoftlockIdleCounter,
        EA_GetRuntimeTurnChatterMap = EA_GetRuntimeTurnChatterMap,
        EA_GetRuntimeEscapeStateMap = EA_GetRuntimeEscapeStateMap,
        EA_GetCombatKeyForTurnCharacter = combatFlowFns.GetCombatKeyForTurnCharacter,
        EA_FindCombatEscapeState = combatFlowFns.FindCombatEscapeState,
        EA_FindTurnChatterState = combatFlowFns.FindTurnChatterState,
        EA_CancelPendingEscape = combatFlowFns.CancelPendingEscape,
        EA_ResolvePendingEscapeAfterLeftCombat = combatFlowFns.ResolvePendingEscapeAfterLeftCombat,
        EA_TryAmbusherEscape = combatFlowFns.TryAmbusherEscape,
        EA_TrySoftlockDeleteOnTurn = combatFlowFns.TrySoftlockDeleteOnTurn,
        EA_MarkRuntimeStateDirty = EA_MarkRuntimeStateDirty,
        EA_NowMs = EA_NowMs,
        EA_TryAnyTurnBark = EA_TryAnyTurnBark,
        EA_RandomInt = EA_RandomInt,
        EA_PlaySoundEvent = EA_PlaySoundEvent,
        EA_DebugEnabled = EA_DebugEnabled,
        EA_HandleSurpriseRollResult = EA_HandleSurpriseRollResult,
        EA_PrimeCharacterTemplateCache = EA["EA_PrimeCharacterTemplateCache"],
    }
    EventsCombatTurnFlowRuntime = EA_BuildRuntimeWithDeps("EventsCombatTurnFlow", EventsCombatTurnFlow, deps, {
        EnemyAmbush = "tablelike",
        EA = "tablelike",
        DebugPrint = "callable",
        UpdateMetric = "callable",
        EA_P0Inc = "callable",
        EA_Spawned = "callable",
        EA_NowMs = "callable",
    })
end

local function EA_PruneRuntimeCombatState(reason)
    if EventsCombatFlowRuntime and type(EventsCombatFlowRuntime.PruneRuntimeCombatState) == "function" then
        return EventsCombatFlowRuntime.PruneRuntimeCombatState(reason)
    end
    return 0
end

local EventsDiagnosticsRuntime = nil
local encounterRepWatchTimerLaunchWarningEmitted = false
local function EA_LaunchEncounterRepWatchTimer(delayMs)
    if EventsTimerMainRuntime and type(EventsTimerMainRuntime.LaunchEncounterRepWatchTimer) == "function" then
        return EventsTimerMainRuntime.LaunchEncounterRepWatchTimer(delayMs)
    end
    if not encounterRepWatchTimerLaunchWarningEmitted then
        encounterRepWatchTimerLaunchWarningEmitted = true
        print("[EnemyAmbush][Seam] Events timer-main runtime missing LaunchEncounterRepWatchTimer().")
    end
    return false
end
if EventsDiagnostics and type(EventsDiagnostics.Build) == "function" then
    local deps = {
        EnemyAmbush = EnemyAmbush,
        EA = EA,
        DebugPrint = DebugPrint,
        UpdateMetric = UpdateMetric,
        EA_P0Inc = EA_P0Inc,
        EA_NormalizeUUID = EA_NormalizeUUID,
        EA_Spawned = EA_Spawned,
        EA_GetPartyXPRecipients = EA_GetPartyXPRecipients,
        EA_GetEffectiveAmbushXPPercent = EA_GetEffectiveAmbushXPPercent,
        EA_DebugEnabled = EA_DebugEnabled,
        SafeOsiExec = SafeOsiExec,
        EA_GetEffectiveDisableAmbushLoot = EA_GetEffectiveDisableAmbushLoot,
        EA_ClearLootButKeepCorpseClickable = EA_ClearLootButKeepCorpseClickable,
        EA_GetSettingBoolEvent = EA_ReadSettingBool,
        EA_ReputationTable = EA_ReputationTable,
        EA_ReputationThresholdTable = EA_ReputationThresholdTable,
        EA_IsAnyPartyInCombat = EA_IsAnyPartyInCombat,
        EA_GetEncounterRepState = EA_GetEncounterRepState,
        EA_GetOutOfCombatRepLedger = EA_GetOutOfCombatRepLedger,
        EA_PruneOutOfCombatRepLedger = EA_PruneOutOfCombatRepLedger,
        EA_Dirty = EA_Dirty,
        EA_NowMs = EA_NowMs,
        EA_GetEncounterRepMaxLoss = EA_GetEncounterRepMaxLoss,
        EA_MarkRuntimeStateDirty = EA_MarkRuntimeStateDirty,
        EA_LaunchEncounterRepWatchTimer = EA_LaunchEncounterRepWatchTimer,
        EA_AddTypePressure = EA_AddTypePressure,
        EA_FormatRepWarning = EA_FormatRepWarning,
        EA_LOCA_REP_WARNING_WARY = EA_LOCA_REP_WARNING_WARY,
        EA_LOCA_REP_WARNING_HOSTILE = EA_LOCA_REP_WARNING_HOSTILE,
        EA_LOCA_REP_WARNING_VENGEFUL = EA_LOCA_REP_WARNING_VENGEFUL,
        PlayVFX_OnEntity = PlayVFX_OnEntity,
        EA_CanSpawnChampionForType = EA_CanSpawnChampionForType,
        EA_GetGuaranteedChampionQueueSafeFn = EA_GetGuaranteedChampionQueueSafeFn,
        SaveReputation = SaveReputation,
        EA_ClearHostileState = EA_ClearHostileState,
        EA_OUT_OF_COMBAT_REP_WINDOW_MS = EA_OUT_OF_COMBAT_REP_WINDOW_MS,
    }
    EventsDiagnosticsRuntime = EA_BuildRuntimeWithDeps("EventsDiagnostics", EventsDiagnostics, deps, {
        EnemyAmbush = "tablelike",
        EA = "tablelike",
        DebugPrint = "callable",
        UpdateMetric = "callable",
        EA_P0Inc = "callable",
        EA_LaunchEncounterRepWatchTimer = "callable",
        EA_Spawned = "callable",
        EA_GetPartyXPRecipients = "callable",
        SafeOsiExec = "callable",
        EA_NowMs = "callable",
    })
end

local EventsRestTriggersRuntime = nil
if EventsRestTriggers and type(EventsRestTriggers.Build) == "function" then
    EventsRestTriggersRuntime = EventsRestTriggers.Build({
        EnemyAmbush = EnemyAmbush,
        EA = EA,
    })
end

if EventsTimerMain and type(EventsTimerMain.Build) == "function" then
    local compositionRoot = type(EA.SystemsModules) == "table" and EA.SystemsModules.CompositionRoot or nil
    local runtimeBag = type(compositionRoot) == "table" and compositionRoot.runtimeBag or nil
    local persistenceRuntime = type(runtimeBag) == "table" and runtimeBag.PersistenceControl or nil
    local deps = {
        EnemyAmbush = EnemyAmbush,
        EA = EA,
        ModuleUUID = ModuleUUID,
        DebugPrint = DebugPrint,
        EA_P0Inc = EA_P0Inc,
        EventsTimerRouter = EventsTimerRouter,
        EventsTimerFlow = EventsTimerFlow,
        EventsScenarioBootstrap = EventsScenarioBootstrap,
        EA_NowMs = EA_NowMs,
        EA_Dirty = EA_Dirty,
        EA_Pending = EA_Pending,
        EA_IsRestAmbushEnabled = EA_IsRestAmbushEnabled,
        EA_AddAmbushPressure = EA_AddAmbushPressure,
        EA_GetAmbushPressure = EA_GetAmbushPressure,
        EA_ArmGuaranteedChampion = EA_ArmGuaranteedChampion,
        IsSafeToSpawnAmbush = IsSafeToSpawnAmbush,
        TriggerAmbush = TriggerAmbush,
        EA_RandomInt = EA_RandomInt,
        ExecuteAmbushSpawn = ExecuteAmbushSpawn,
        EA_PlayApproachBeatFromData = EA_PlayApproachBeatFromData,
        EA_HandlePersistentHostileRetryTimer = EA_HandlePersistentHostileRetryTimer,
        EA_HandleKilledByEvent = EA_HandleKilledByEvent,
        EA_IsDebugMode = EA_IsDebugMode,
        EA_DebugEnabled = EA_DebugEnabled,
        EA_Spawned = EA_Spawned,
        EA_NormalizeUUID = EA_NormalizeUUID,
        EA_ClearHostileState = EA_ClearHostileState,
        EA_DESPAWN_FADE_SOUND = EA_DESPAWN_FADE_SOUND,
        PlayVFX_OnEntity = PlayVFX_OnEntity,
        EA_PlaySoundEvent = EA_PlaySoundEvent,
        EnemyData = EnemyData,
        SafeOsiExec = SafeOsiExec,
        EA_EvictOldSpawned = EA_EvictOldSpawned,
        EA_AggressiveSpawnedCleanup = EA_AggressiveSpawnedCleanup,
        EA_PruneRuntimeCombatState = EA_PruneRuntimeCombatState,
        EA_GetEncounterRepState = EA_GetEncounterRepState,
        EA_IsAnyPartyInCombat = EA_IsAnyPartyInCombat,
        EA_MarkRuntimeStateDirty = EA_MarkRuntimeStateDirty,
        EA_ShouldLogDespawn = EA_ShouldLogDespawn,
        EA_GetSettingBoolEvent = EA_ReadSettingBool,
        EA_GetSettingNumberEvent = EA_ReadSettingNumber,
        EA_ReputationTable = EA_ReputationTable,
        SaveReputation = SaveReputation,
        CleanupPendingAmbushes = CleanupPendingAmbushes,
        EA_AmbushPressure = EA_AmbushPressure,
        EA_GetCooldownEnabled = EA_GetCooldownEnabled,
        EA_IsQuickTestMode = EA_IsQuickTestMode,
        EA_PersistedNowMs = EA_PersistedNowMs,
        EA_GetNowMsSafe = EA["EA_GetNowMsSafe"],
        EA_BuildRuntimeWithDeps = EA["EA_BuildRuntimeWithDeps"],
        RelaunchPendingTimersOnLoad = type(persistenceRuntime) == "table" and persistenceRuntime.RelaunchPendingTimersOnLoad or nil,
        EA_RearmPersistentHostileRetries = EA_RearmPersistentHostileRetries,
        EA_LastAmbushTime = EA_LastAmbushTime,
        EA_ShouldSkipBeachTutorialAmbush = EA_ShouldSkipBeachTutorialAmbush,
        EA_GetScriptedScenarioState = EA_GetScriptedScenarioState,
        EA_RunScriptedScenarioById = EA_RunScriptedScenarioById,
        EA_TickTimeInDangerRisk = EA_TickInternalTimeInDangerRisk,
        EA_TryTriggerTravelDangerAmbush = EA_TryTriggerInternalTravelDangerAmbush,
        EA_GetRegionForCharacter = EA_GetRegionForCharacter,
        GetSafeLevel = GetSafeLevel,
        EA_ResolveLocaText = EA_ResolveLocaText,
        EA_IsModVarsContainer = EA_IsModVarsContainer,
        AMBUSH_PRESSURE_MAX = AMBUSH_PRESSURE_MAX,
        LONG_REST_SAFETY_DELAY = LONG_REST_SAFETY_DELAY,
        LONG_REST_RETRY_MAX = LONG_REST_RETRY_MAX,
        SHORT_REST_RETRY_MAX = SHORT_REST_RETRY_MAX,
        DELAYED_AMBUSH_RETRY_MAX = DELAYED_AMBUSH_RETRY_MAX,
        EA_REHYDRATE_READY_RETRY_MAX = EA_REHYDRATE_READY_RETRY_MAX,
        EA_REHYDRATE_READY_RETRY_MS = EA_REHYDRATE_READY_RETRY_MS,
        EA_STAGGER_STEP_MS_MIN = EA_STAGGER_STEP_MS_MIN,
        EA_STAGGER_STEP_MS_DEFAULT = EA_STAGGER_STEP_MS_DEFAULT,
        EA_STAGGER_STEP_MS_MAX = EA_STAGGER_STEP_MS_MAX,
        EA_STAGGER_QUEUE_INITIAL_DELAY_MIN_MS = EA_STAGGER_QUEUE_INITIAL_DELAY_MIN_MS,
        EA_RETRY_LOG_EVERY = EA_RETRY_LOG_EVERY,
        EA_TIMER_PREFIXES = TIMER_PREFIXES,
        EA_OnScenarioBootstrapSessionLoaded = EA_OnScenarioBootstrapSessionLoaded,
        EA_HandleScenarioBootstrapTimer = EA_HandleScenarioBootstrapTimer,
    }
    EventsTimerMainRuntime = EA_BuildRuntimeWithDeps("EventsTimerMain", EventsTimerMain, deps, {
        EnemyAmbush = "tablelike",
        EA = "tablelike",
        ModuleUUID = "string",
        DebugPrint = "callable",
        EA_P0Inc = "callable",
        EventsTimerRouter = "tablelike",
        EventsTimerFlow = "tablelike",
        EventsScenarioBootstrap = "tablelike",
        EA_NowMs = "callable",
        EA_Dirty = "callable",
        EA_Pending = "callable",
        RelaunchPendingTimersOnLoad = { "callable", "nil" },
        EA_RearmPersistentHostileRetries = { "callable", "nil" },
        EA_BuildRuntimeWithDeps = { "callable", "nil" },
        IsSafeToSpawnAmbush = "callable",
        TriggerAmbush = "callable",
    })
end
if EventsTimerMainRuntime and type(EventsTimerMainRuntime.GetScenarioSessionLoadedHandler) == "function" then
    local cb = EventsTimerMainRuntime.GetScenarioSessionLoadedHandler()
    if type(cb) == "function" then
        EA_OnScenarioBootstrapSessionLoaded = cb
        EA_ScenarioBootstrapSessionLoadedIsStub = false
        if EA_ScenarioBootstrapSessionLoadedSeen == true and Ext and Ext.IsServer and Ext.IsServer() then
            EA_TryEnsureBeachBootstrapStartedDelayed("late_bind_recovery_direct", 0)
            if Ext.Timer and Ext.Timer.WaitFor then
                Ext.Timer.WaitFor(50, function()
                    EA_DispatchScenarioBootstrapSessionLoaded("late_bind_recovery")
                end)
            else
                EA_DispatchScenarioBootstrapSessionLoaded("late_bind_recovery")
            end
        end
    end
end
if EventsTimerMainRuntime and type(EventsTimerMainRuntime.GetScenarioTimerHandler) == "function" then
    local th = EventsTimerMainRuntime.GetScenarioTimerHandler()
    if type(th) == "function" then
        EA_HandleScenarioBootstrapTimer = th
    end
end

local worldRepAndTimerListenersRegistered = false
local function EA_RegisterWorldRepAndTimerListeners()
    if worldRepAndTimerListenersRegistered then
        EA_P0Inc("listenerRegGuard.RegisterWorldRepAndTimerListeners")
        return false
    end
    EA_P0Inc("listenerReg.RegisterWorldRepAndTimerListeners")
    if not (Ext and Ext.Osiris and Ext.Osiris.RegisterListener) then
        return
    end
    worldRepAndTimerListenersRegistered = true

    do
        local ok, err = pcall(function()
            EA_P0Inc("listenerReg.EnteredLevel.after")
            Ext.Osiris.RegisterListener("EnteredLevel", 3, "after", function(objectGuid, objectRootTemplate, levelName)
                EA_P0Inc("listenerExec.EnteredLevel.after")
                local primeTemplateCache = EA and EA["EA_PrimeCharacterTemplateCache"]
                if type(primeTemplateCache) ~= "function" then
                    primeTemplateCache = nil
                end
                if type(primeTemplateCache) == "function" then
                    local primeOk, primeErr = pcall(primeTemplateCache, objectGuid, "entered_level", objectRootTemplate)
                    if not primeOk and EA_DebugEnabled() then
                        DebugPrint(string.format(
                            "[WorldRep] EnteredLevel cache prime failed: object=%s level=%s err=%s",
                            tostring(objectGuid),
                            tostring(levelName),
                            tostring(primeErr)
                        ))
                    end
                end

                if tostring(levelName or "") == "WLD_Main_A" then
                    local isPlayer = false
                    if Osi and Osi.IsPlayer then
                        local okPlayer, outPlayer = pcall(Osi.IsPlayer, objectGuid)
                        if okPlayer and tonumber(outPlayer) == 1 then
                            isPlayer = true
                        end
                    end
                    if isPlayer then
                        EA_TryEnsureBeachBootstrapStartedDelayed("entered_level_wld_main_a", 0)
                        local canonicalRegion = ""
                        local rawRegion = tostring(levelName or "")
                        if type(EA_GetRegionForCharacter) == "function" then
                            local okRegion, resolvedCanonical, resolvedRaw = pcall(EA_GetRegionForCharacter, objectGuid)
                            if okRegion then
                                canonicalRegion = tostring(resolvedCanonical or "")
                                if tostring(resolvedRaw or "") ~= "" then
                                    rawRegion = tostring(resolvedRaw or "")
                                end
                            end
                        end
                        local okScenarioDispatch, dispatchErr = pcall(EA_TryRunInternalRegionEntryScenario, objectGuid, {
                            source = "EnteredLevel",
                            enteredLevelName = tostring(levelName or ""),
                            canonicalRegion = canonicalRegion,
                            rawRegion = rawRegion,
                        })
                        if not okScenarioDispatch and EA_DebugEnabled() then
                            DebugPrint(string.format(
                                "[Scenario] region_entry EnteredLevel dispatch failed: object=%s level=%s err=%s",
                                tostring(objectGuid),
                                tostring(levelName),
                                tostring(dispatchErr)
                            ))
                        end
                    end
                end
            end)
        end)
        if not ok then
            print(string.format("[EnemyAmbush][WorldRep] EnteredLevel listener unavailable: %s", tostring(err)))
        end
    end

    do
        local ok, err = pcall(function()
            EA_P0Inc("listenerReg.KilledBy.after")
            Ext.Osiris.RegisterListener("KilledBy", 4, "after", function(a, b, c, d)
                EA_P0Inc("listenerExec.KilledByListener.after")
                EA_HandleKilledByEvent(a, b, c, d)
            end)
        end)
        if not ok then
            print(string.format("[EnemyAmbush][WorldRep] KilledBy listener unavailable: %s", tostring(err)))
        end
    end

    if EventsTimerMainRuntime and type(EventsTimerMainRuntime.RegisterTimerListeners) == "function" then
        EventsTimerMainRuntime.RegisterTimerListeners()
    else
        print("[EnemyAmbush][Seam] Events timer-main runtime missing RegisterTimerListeners().")
    end
end
local safeZoneListenersRegistered = false
local function EA_RegisterSafeZoneListeners()
    if safeZoneListenersRegistered then
        EA_P0Inc("listenerRegGuard.RegisterSafeZoneListeners")
        return false
    end
    EA_P0Inc("listenerReg.RegisterSafeZoneListeners")
    if not (Ext and Ext.Osiris and Ext.Osiris.RegisterListener) then
        return
    end
    safeZoneListenersRegistered = true

    do
        local ok, err = pcall(function()
            EA_P0Inc("listenerReg.EnteredTrigger.after")
            Ext.Osiris.RegisterListener("EnteredTrigger", 2, "after", function(character, trigger)
                EA_P0Inc("listenerExec.EnteredTrigger.after")
                local handledOk, handled = pcall(EA_OnEnteredSafeZoneTrigger, character, trigger)
                if not handledOk then
                    print(string.format("[EnemyAmbush][SafeZone] EnteredTrigger handler failed: %s", tostring(handled)))
                elseif handled == true and EA_DebugEnabled() then
                    local state = EA_GetSafeZoneState(character)
                    DebugPrint(string.format(
                        "[SafeZone] EnteredTrigger char=%s trigger=%s active=%s",
                        tostring(character),
                        tostring(trigger),
                        table.concat(state.activeZones or {}, ", ")
                    ))
                end
            end)
        end)
        if not ok then
            print(string.format("[EnemyAmbush][SafeZone] EnteredTrigger listener unavailable: %s", tostring(err)))
        end
    end

    do
        local ok, err = pcall(function()
            EA_P0Inc("listenerReg.LeftTrigger.after")
            Ext.Osiris.RegisterListener("LeftTrigger", 2, "after", function(character, trigger)
                EA_P0Inc("listenerExec.LeftTrigger.after")
                local handledOk, handled = pcall(EA_OnLeftSafeZoneTrigger, character, trigger)
                if not handledOk then
                    print(string.format("[EnemyAmbush][SafeZone] LeftTrigger handler failed: %s", tostring(handled)))
                elseif handled == true and EA_DebugEnabled() then
                    local state = EA_GetSafeZoneState(character)
                    DebugPrint(string.format(
                        "[SafeZone] LeftTrigger char=%s trigger=%s active=%s",
                        tostring(character),
                        tostring(trigger),
                        table.concat(state.activeZones or {}, ", ")
                    ))
                end
            end)
        end)
        if not ok then
            print(string.format("[EnemyAmbush][SafeZone] LeftTrigger listener unavailable: %s", tostring(err)))
        end
    end
end

local function EA_RegisterAllEventListeners()
    EA_P0Inc("listenerReg.RegisterAllEventListeners")

    if EventsCombatFlowRuntime and type(EventsCombatFlowRuntime.RegisterCombatEventListeners) == "function" then
        EventsCombatFlowRuntime.RegisterCombatEventListeners()
    else
        print("[EnemyAmbush][Seam] Events combat-flow runtime missing RegisterCombatEventListeners().")
    end

    if EventsCombatTurnFlowRuntime and type(EventsCombatTurnFlowRuntime.RegisterCombatTurnListeners) == "function" then
        EventsCombatTurnFlowRuntime.RegisterCombatTurnListeners()
    else
        print("[EnemyAmbush][Seam] Events combat-turn-flow runtime missing RegisterCombatTurnListeners().")
    end

    if EventsDiagnosticsRuntime and type(EventsDiagnosticsRuntime.RegisterDefeatListeners) == "function" then
        EventsDiagnosticsRuntime.RegisterDefeatListeners()
    else
        print("[EnemyAmbush][Seam] Events diagnostics runtime missing RegisterDefeatListeners().")
    end

    if EventsRestTriggersRuntime and type(EventsRestTriggersRuntime.RegisterRestTriggerListeners) == "function" then
        EventsRestTriggersRuntime.RegisterRestTriggerListeners()
    else
        print("[EnemyAmbush][Seam] Events rest-triggers runtime missing RegisterRestTriggerListeners().")
    end

    EA_RegisterWorldRepAndTimerListeners()
    EA_RegisterSafeZoneListeners()
end

EA_RegisterAllEventListeners()

