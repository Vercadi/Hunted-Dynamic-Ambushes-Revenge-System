EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local M = {}
function M.Build(deps)
    deps = deps or {}
    local EnemyAmbush = deps.EnemyAmbush or EA
    local EA = deps.EA or EnemyAmbush or {}
    local ModuleUUID = deps.ModuleUUID or (EA and EA.ModuleUUID)
    local DebugPrint = deps.DebugPrint or function() end
    local EA_P0Inc = deps.EA_P0Inc or (EA and EA["EA_P0Inc"]) or function() return 0 end
    local EventsTimerRouter = deps.EventsTimerRouter or {}
    local EventsTimerFlow = deps.EventsTimerFlow or {}
    local EventsScenarioBootstrap = deps.EventsScenarioBootstrap or {}
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local EA_Dirty = deps.EA_Dirty or function() end
    local EA_Pending = deps.EA_Pending or function() return {} end
    local EA_IsRestAmbushEnabled = deps.EA_IsRestAmbushEnabled or function() return true end
    local EA_IsQuickTestMode = deps.EA_IsQuickTestMode or function() return false end
    local EA_AddAmbushPressure = deps.EA_AddAmbushPressure or function() return 0 end
    local EA_GetAmbushPressure = deps.EA_GetAmbushPressure or function() return 0 end
    local EA_ArmGuaranteedChampion = deps.EA_ArmGuaranteedChampion or function() end
    local IsSafeToSpawnAmbush = deps.IsSafeToSpawnAmbush or function() return false end
    local TriggerAmbush = deps.TriggerAmbush or function() end
    local EA_RandIntSafe = deps.EA_RandIntSafe or (EA and EA["EA_RandIntSafe"])
    local EA_RandomInt = deps.EA_RandomInt or function(a, b)
        if type(EA_RandIntSafe) == "function" then
            local ok, out = pcall(EA_RandIntSafe, a, b)
            if ok and tonumber(out) then
                return tonumber(out)
            end
        end
        local lo = math.floor(tonumber(a) or 1)
        local hi = math.floor(tonumber(b) or lo)
        if hi < lo then lo, hi = hi, lo end
        if hi <= lo then
            return lo
        end
        return lo + math.floor((hi - lo) * 0.5)
    end
    local ExecuteAmbushSpawn = deps.ExecuteAmbushSpawn or function() return 0 end
    local EA_PlayApproachBeatFromData = deps.EA_PlayApproachBeatFromData or function() end
    local EA_HandlePersistentHostileRetryTimer = deps.EA_HandlePersistentHostileRetryTimer
    local EA_HandleKilledByEvent = deps.EA_HandleKilledByEvent or function() end
    local EA_IsDebugMode = deps.EA_IsDebugMode or function() return false end
    local EA_DebugEnabled = deps.EA_DebugEnabled or function() return false end
    local EA_Spawned = deps.EA_Spawned or function() return {} end
    local EA_NormalizeUUID = deps.EA_NormalizeUUID or function(v) return v end
    local EA_ClearHostileState = deps.EA_ClearHostileState or function() end
    local EA_DESPAWN_FADE_SOUND = deps.EA_DESPAWN_FADE_SOUND or "VFX_Sound_Spell_Impact_Silent"
    local PlayVFX_OnEntity = deps.PlayVFX_OnEntity or function() end
    local EA_PlaySoundEvent = deps.EA_PlaySoundEvent or function() end
    local EnemyData = deps.EnemyData or {}
    local SafeOsiExec = deps.SafeOsiExec or function() return false end
    local EA_EvictOldSpawned = deps.EA_EvictOldSpawned or function() end
    local EA_AggressiveSpawnedCleanup = deps.EA_AggressiveSpawnedCleanup
    local EA_PruneRuntimeCombatState = deps.EA_PruneRuntimeCombatState or function() return 0 end
    local EA_GetEncounterRepState = deps.EA_GetEncounterRepState or function() return {} end
    local EA_IsAnyPartyInCombat = deps.EA_IsAnyPartyInCombat or function() return false end
    local EA_MarkRuntimeStateDirty = deps.EA_MarkRuntimeStateDirty or function() end
    local EA_ShouldLogDespawn = deps.EA_ShouldLogDespawn or function() return false end
    local EA_GetSettingBoolEvent = deps.EA_GetSettingBoolEvent or function(_,fallback) return fallback == true end
    local EA_GetSettingNumberEvent = deps.EA_GetSettingNumberEvent or function(_,fallback) return tonumber(fallback) or 0 end
    local EA_ReputationTable = deps.EA_ReputationTable or function() return {} end
    local SaveReputation = deps.SaveReputation
    local CleanupPendingAmbushes = deps.CleanupPendingAmbushes or function() end
    local EA_AmbushPressure = deps.EA_AmbushPressure or function() return {} end
    local EA_GetCooldownEnabled = deps.EA_GetCooldownEnabled or function() return false end
    local EA_PersistedNowMs = deps.EA_PersistedNowMs
    local EA_GetNowMsSafe = deps.EA_GetNowMsSafe or (EA and EA["EA_GetNowMsSafe"])
    local EA_DebugBuildPersistentHostileRetrySnapshot = deps.EA_DebugBuildPersistentHostileRetrySnapshot or (EA and EA["EA_DebugBuildPersistentHostileRetrySnapshot"])
    local EA_DebugLogPersistentHostileRetrySnapshot = deps.EA_DebugLogPersistentHostileRetrySnapshot or (EA and EA["EA_DebugLogPersistentHostileRetrySnapshot"])
    local EA_BuildRuntimeWithDepsShared = deps.EA_BuildRuntimeWithDeps or (EA and EA["EA_BuildRuntimeWithDeps"])
    local EA_ValidateBuildDeps = deps.EA_ValidateBuildDeps or (EA and EA["EA_ValidateBuildDeps"])
    local RelaunchPendingTimersOnLoad = deps.RelaunchPendingTimersOnLoad
    local EA_RearmPersistentHostileRetries = deps.EA_RearmPersistentHostileRetries
    local EA_LastAmbushTime = deps.EA_LastAmbushTime or function() return {} end
    local EA_ShouldSkipBeachTutorialAmbush = deps.EA_ShouldSkipBeachTutorialAmbush or function() return false end
    local EA_GetScriptedScenarioState = deps.EA_GetScriptedScenarioState or function() return nil end
    local EA_RunScriptedScenarioById = deps.EA_RunScriptedScenarioById or function() return false end
    local EA_TickTimeInDangerRisk = deps.EA_TickTimeInDangerRisk
    local EA_TryTriggerTravelDangerAmbush = deps.EA_TryTriggerTravelDangerAmbush
    local EA_GetRegionForCharacter = deps.EA_GetRegionForCharacter
    local GetSafeLevel = deps.GetSafeLevel
    local EA_ResolveLocaText = deps.EA_ResolveLocaText or function(v) return tostring(v or "") end
    local EA_IsModVarsContainer = deps.EA_IsModVarsContainer
    local AMBUSH_PRESSURE_MAX = tonumber(deps.AMBUSH_PRESSURE_MAX) or 100
    local LONG_REST_SAFETY_DELAY = tonumber(deps.LONG_REST_SAFETY_DELAY) or 30
    local LONG_REST_RETRY_MAX = tonumber(deps.LONG_REST_RETRY_MAX) or 6
    local SHORT_REST_RETRY_MAX = tonumber(deps.SHORT_REST_RETRY_MAX) or 6
    local DELAYED_AMBUSH_RETRY_MAX = tonumber(deps.DELAYED_AMBUSH_RETRY_MAX) or 8
    local EA_REHYDRATE_READY_RETRY_MAX = tonumber(deps.EA_REHYDRATE_READY_RETRY_MAX) or 30
    local EA_REHYDRATE_READY_RETRY_MS = tonumber(deps.EA_REHYDRATE_READY_RETRY_MS) or 1000
    local EA_STAGGER_STEP_MS_MIN = tonumber(deps.EA_STAGGER_STEP_MS_MIN) or 20
    local EA_STAGGER_STEP_MS_DEFAULT = tonumber(deps.EA_STAGGER_STEP_MS_DEFAULT) or 100
    local EA_STAGGER_STEP_MS_MAX = tonumber(deps.EA_STAGGER_STEP_MS_MAX) or 500
    local EA_STAGGER_QUEUE_INITIAL_DELAY_MIN_MS = tonumber(deps.EA_STAGGER_QUEUE_INITIAL_DELAY_MIN_MS) or 50
    local EA_RETRY_LOG_EVERY = tonumber(deps.EA_RETRY_LOG_EVERY) or 5
    local EA_TIMER_PREFIXES = deps.EA_TIMER_PREFIXES or {}
    local TIMER_PREFIX_OWNED = tostring(EA_TIMER_PREFIXES.OWNED or "EA_")
    local TIMER_PREFIX_SHORT_REST = tostring(EA_TIMER_PREFIXES.SHORT_REST or "EA_SR_")
    local TIMER_PREFIX_LONG_REST = tostring(EA_TIMER_PREFIXES.LONG_REST or "EA_LR_")
    local TIMER_PREFIX_SHORT_RETRY = tostring(EA_TIMER_PREFIXES.SHORT_REST_RETRY or "EA_SR_RETRY_")
    local TIMER_PREFIX_LONG_RETRY = tostring(EA_TIMER_PREFIXES.LONG_REST_RETRY or "EA_LR_RETRY_")
    local TIMER_PREFIX_REST_DEFER = tostring(EA_TIMER_PREFIXES.REST_DEFER or "EA_REST_DEFER_")
    local TIMER_PREFIX_SPAWNQ = tostring(EA_TIMER_PREFIXES.SPAWN_QUEUE or "EA_SPAWNQ_")
    local TIMER_PREFIX_AMBUSH_DELAYED = tostring(EA_TIMER_PREFIXES.AMBUSH_DELAYED or "EA_AMBUSH_DELAYED_")
    local TIMER_PREFIX_DESPAWN = tostring(EA_TIMER_PREFIXES.DESPAWN or "EA_Despawn_")
    local TIMER_PREFIX_DELETE = tostring(EA_TIMER_PREFIXES.DELETE or "EA_Delete_")
    local RECURRING_STARTUP_TIMER_SPECS = {
        { timer = "EA_REPUTATION_DECAY", delayMs = 300000 },
        { timer = "EA_CLEANUP_PENDING", delayMs = 60000 },
        { timer = "EA_VALIDATE_SPAWNED", delayMs = 300000 },
        { timer = "EA_RUNTIME_COMBAT_PRUNE", delayMs = 15000 },
    }

    local function EA_HasPrefix(value, prefix)
        if type(value) ~= "string" or type(prefix) ~= "string" then
            return false
        end
        return string.sub(value, 1, #prefix) == prefix
    end

    local function EA_IsRuntimeGameStateReady()
        if Osi and Osi.IsGameStateRunning then
            local okRunning, running = pcall(Osi.IsGameStateRunning)
            if (not okRunning) or running ~= 1 then
                return false
            end
        end
        return true
    end

    local EA_DEFERRED_PAYLOAD_RETRY_COUNTS = {}
    local EA_DELAYED_MIRROR_LOAD_LOGGED = {}
    local EA_DELAYED_PAYLOAD_RETRY_COUNTS = {}
    local EA_DELAYED_PENDING_UNAVAILABLE_RETRY_COUNTS = {}
    local EA_LogRestFlow

    local function EA_GetPendingFlowKind(data)
        local isMap = (type(data) == "table" or type(data) == "userdata")
        local kind = tostring(isMap and data.triggerKind or "")
        if kind ~= "" then
            return kind
        end
        return ((isMap and data.isLongRest == true) and "long" or "short")
    end

    local function EA_GetPendingFlowLabel(data)
        local isMap = (type(data) == "table" or type(data) == "userdata")
        if isMap and type(data.flowLabel) == "string" and data.flowLabel ~= "" then
            return data.flowLabel
        end
        return EA_GetPendingFlowKind(data) == "long" and "LongRest" or "ShortRest"
    end

    local function EA_GetPendingIfPresent()
        local varsFn = EA and EA["EA_Vars"]
        if type(varsFn) ~= "function" then
            return nil
        end
        local ok, vars = pcall(varsFn)
        if not ok or (type(vars) ~= "table" and type(vars) ~= "userdata") then
            return nil
        end
        local pending = vars.PersistentPendingAmbushes
        if type(pending) ~= "table" and type(pending) ~= "userdata" then
            return nil
        end
        return pending
    end

    local function EA_RequeueDeferredPayloadRetry(timer, deferredChar, reason)
        if type(timer) ~= "string" or timer == "" or not (Osi and Osi.TimerLaunch) then
            return false
        end
        local tries = (tonumber(EA_DEFERRED_PAYLOAD_RETRY_COUNTS[timer]) or 0) + 1
        if tries > EA_REHYDRATE_READY_RETRY_MAX then
            EA_DEFERRED_PAYLOAD_RETRY_COUNTS[timer] = nil
            EA_LogRestFlow(
                "deferred",
                "payload rehydrate retries exhausted timer=%s char=%s reason=%s retries=%d",
                tostring(timer),
                tostring(deferredChar or ""),
                tostring(reason or "unknown"),
                tonumber(tries - 1) or 0
            )
            return false
        end
        EA_DEFERRED_PAYLOAD_RETRY_COUNTS[timer] = tries
        Osi.TimerLaunch(timer, EA_REHYDRATE_READY_RETRY_MS)
        if tries == 1 or (tries % 5) == 0 then
            EA_LogRestFlow(
                "deferred",
                "payload rehydrate waiting timer=%s char=%s reason=%s retry=%d/%d",
                tostring(timer),
                tostring(deferredChar or ""),
                tostring(reason or "unknown"),
                tonumber(tries) or 0,
                EA_REHYDRATE_READY_RETRY_MAX
            )
        end
        return true
    end

    local function EA_GetDelayedAmbushMirrorIfPresent()
        local varsFn = EA and EA["EA_Vars"]
        if type(varsFn) ~= "function" then
            return nil, nil
        end
        local ok, vars = pcall(varsFn)
        if not ok or (type(vars) ~= "table" and type(vars) ~= "userdata") then
            return nil, nil
        end
        local payload = vars.EA_DelayedAmbushState
        if type(payload) ~= "table" and type(payload) ~= "userdata" then
            return nil, vars
        end
        return payload, vars
    end

    local function EA_CopyDelayedAmbushFirstEnemy(source)
        if type(source) ~= "table" and type(source) ~= "userdata" then
            return nil
        end
        local template = tostring(source.template or "")
        if template == "" then
            return nil
        end
        return {
            template = template,
            name = tostring(source.name or "Unknown"),
            creatureType = tostring(source.creatureType or ""),
            level = tonumber(source.level) or 1,
            spawnBand = tostring(source.spawnBand or ""),
            powerClass = tostring(source.powerClass or ""),
        }
    end

    local function EA_CopyDelayedAmbushRoll(source)
        if type(source) ~= "table" and type(source) ~= "userdata" then
            return nil
        end
        return {
            delta = tonumber(source.delta) or 0,
            targetLevel = tonumber(source.targetLevel) or 0,
            tier = tostring(source.tier or ""),
            spawnDist = tonumber(source.spawnDist) or 0,
            playerLevel = tonumber(source.playerLevel) or 0,
            ambushId = tostring(source.ambushId or ""),
        }
    end

    local function EA_MakeDelayedAmbushMirrorPayload(timer, payload)
        if type(timer) ~= "string" or timer == "" then
            return nil
        end
        if type(payload) ~= "table" and type(payload) ~= "userdata" then
            return nil
        end

        local out = {
            kind = "SPAWN",
            timer = tostring(timer),
            character = tostring(payload.character or ""),
            ambushId = tostring(payload.ambushId or ""),
            tier = tostring(payload.tier or ""),
            isLongRest = (payload.isLongRest == true),
            triggerKind = tostring(payload.triggerKind or ""),
            flowLabel = tostring(payload.flowLabel or ""),
            playerLevel = tonumber(payload.playerLevel) or 0,
            pointBudget = tonumber(payload.pointBudget) or 0,
            duration = tonumber(payload.duration) or 0,
            ambushTheme = tostring(payload.ambushTheme or ""),
            creatureType = tostring(payload.creatureType or ""),
            warningMs = tonumber(payload.warningMs) or 0,
            timestamp = tonumber(payload.timestamp) or 0,
            retryCount = tonumber(payload.retryCount) or 0,
            runtimeReadyRetries = tonumber(payload.runtimeReadyRetries) or 0,
        }

        local firstEnemy = EA_CopyDelayedAmbushFirstEnemy(payload.firstEnemy)
        if firstEnemy then
            out.firstEnemy = firstEnemy
        end

        local roll = EA_CopyDelayedAmbushRoll(payload.roll)
        if roll then
            out.roll = roll
        end

        return out
    end

    local function EA_SetDelayedAmbushMirror(payload)
        local varsFn = EA and EA["EA_Vars"]
        if type(varsFn) ~= "function" then
            return false
        end
        local ok, vars = pcall(varsFn)
        if not ok or (type(vars) ~= "table" and type(vars) ~= "userdata") then
            return false
        end
        vars.EA_DelayedAmbushState = payload
        return true
    end

    local function EA_ClearDelayedPayloadRetry(timer)
        if type(timer) ~= "string" or timer == "" then
            return
        end
        EA_DELAYED_MIRROR_LOAD_LOGGED[timer] = nil
        EA_DELAYED_PAYLOAD_RETRY_COUNTS[timer] = nil
    end

    local function EA_ClearDelayedAmbushMirrorForTimer(timer)
        if type(timer) ~= "string" or timer == "" then
            return false
        end
        EA_DELAYED_MIRROR_LOAD_LOGGED[timer] = nil
        local mirror = ({ EA_GetDelayedAmbushMirrorIfPresent() })[1]
        if type(mirror) ~= "table" and type(mirror) ~= "userdata" then
            return false
        end
        if tostring(mirror.timer or "") ~= tostring(timer) then
            return false
        end
        local cleared = EA_SetDelayedAmbushMirror(nil)
        if cleared and EA_Dirty then
            EA_Dirty(true)
        end
        return cleared
    end

    local function EA_TrackDelayedAmbushMirror(timer, payload)
        if type(timer) ~= "string" or timer == "" then
            return false
        end
        local mirrorPayload = EA_MakeDelayedAmbushMirrorPayload(timer, payload)
        if type(mirrorPayload) ~= "table" then
            return false
        end
        local stored = EA_SetDelayedAmbushMirror(mirrorPayload)
        if stored and EA_Dirty then
            EA_Dirty(true)
        end
        return stored
    end

    local function EA_RecoverDelayedAmbushPayloadFromMirror(timer, pending)
        if type(timer) ~= "string" or timer == "" then
            return nil
        end
        if type(pending) ~= "table" and type(pending) ~= "userdata" then
            return nil
        end
        local mirror = ({ EA_GetDelayedAmbushMirrorIfPresent() })[1]
        if not EA_DELAYED_MIRROR_LOAD_LOGGED[timer] then
            print(string.format(
                "[EnemyAmbush] Delayed ambush mirror lookup for timer '%s': %s.",
                tostring(timer),
                ((type(mirror) == "table" or type(mirror) == "userdata") and tostring(mirror.timer or "") == tostring(timer)) and "hit" or "miss"
            ))
            EA_DELAYED_MIRROR_LOAD_LOGGED[timer] = true
        end
        if type(mirror) ~= "table" and type(mirror) ~= "userdata" then
            return nil
        end
        if tostring(mirror.kind or "") ~= "SPAWN" then
            return nil
        end
        if tostring(mirror.timer or "") ~= tostring(timer) then
            return nil
        end
        local recovered = EA_MakeDelayedAmbushMirrorPayload(timer, mirror)
        if type(recovered) ~= "table" then
            return nil
        end
        pending[timer] = recovered
        if EA_Dirty then
            EA_Dirty(true)
        end
        print(string.format(
            "[EnemyAmbush] Recovered delayed ambush payload for timer '%s' using delayed mirror.",
            tostring(timer)
        ))
        return recovered
    end

    local function EA_RequeueDelayedPayloadRetry(timer, reason)
        if type(timer) ~= "string" or timer == "" or not (Osi and Osi.TimerLaunch) then
            EA_ClearDelayedPayloadRetry(timer)
            return false
        end

        local tries = (tonumber(EA_DELAYED_PAYLOAD_RETRY_COUNTS[timer]) or 0) + 1
        if tries > EA_REHYDRATE_READY_RETRY_MAX then
            EA_ClearDelayedPayloadRetry(timer)
            print(string.format(
                "[EnemyAmbush] Delayed ambush payload missing for timer '%s' after retries exhausted (%d/%d). Dropping.",
                tostring(timer),
                tonumber(tries - 1) or 0,
                tonumber(EA_REHYDRATE_READY_RETRY_MAX) or 0
            ))
            EA_ClearDelayedAmbushMirrorForTimer(timer)
            return false
        end

        EA_DELAYED_PAYLOAD_RETRY_COUNTS[timer] = tries
        Osi.TimerLaunch(timer, EA_REHYDRATE_READY_RETRY_MS)

        if tries == 1 then
            print(string.format(
                "[EnemyAmbush] Delayed ambush payload missing for timer '%s'; retrying (%d/%d).",
                tostring(timer),
                tonumber(tries) or 0,
                tonumber(EA_REHYDRATE_READY_RETRY_MAX) or 0
            ))
        else
            print(string.format(
                "[EnemyAmbush] Delayed ambush payload still missing for timer '%s'; retrying (%d/%d).",
                tostring(timer),
                tonumber(tries) or 0,
                tonumber(EA_REHYDRATE_READY_RETRY_MAX) or 0
            ))
        end

        return true
    end

    local function EA_ClearDelayedPendingUnavailableRetry(timer)
        if type(timer) ~= "string" or timer == "" then
            return
        end
        EA_DELAYED_PENDING_UNAVAILABLE_RETRY_COUNTS[timer] = nil
    end

    local function EA_RequeueDelayedPendingUnavailableRetry(timer)
        if type(timer) ~= "string" or timer == "" or not (Osi and Osi.TimerLaunch) then
            EA_ClearDelayedPendingUnavailableRetry(timer)
            return false
        end

        local tries = (tonumber(EA_DELAYED_PENDING_UNAVAILABLE_RETRY_COUNTS[timer]) or 0) + 1
        if tries > EA_REHYDRATE_READY_RETRY_MAX then
            EA_ClearDelayedPendingUnavailableRetry(timer)
            print(string.format(
                "[EnemyAmbush] Delayed ambush pending store unavailable for timer '%s' after retries exhausted (%d/%d). Dropping.",
                tostring(timer),
                tonumber(tries - 1) or 0,
                tonumber(EA_REHYDRATE_READY_RETRY_MAX) or 0
            ))
            return false
        end

        EA_DELAYED_PENDING_UNAVAILABLE_RETRY_COUNTS[timer] = tries
        Osi.TimerLaunch(timer, EA_REHYDRATE_READY_RETRY_MS)

        if tries == 1 then
            print(string.format(
                "[EnemyAmbush] Delayed ambush pending store unavailable for timer '%s'; retrying (%d/%d).",
                tostring(timer),
                tonumber(tries) or 0,
                tonumber(EA_REHYDRATE_READY_RETRY_MAX) or 0
            ))
        else
            print(string.format(
                "[EnemyAmbush] Delayed ambush pending store still unavailable for timer '%s'; retrying (%d/%d).",
                tostring(timer),
                tonumber(tries) or 0,
                tonumber(EA_REHYDRATE_READY_RETRY_MAX) or 0
            ))
        end

        return true
    end

    local function EA_SanitizeDeferredRestOpts(sourceOpts)
        if type(sourceOpts) ~= "table" then
            return nil
        end
        local sanitized = {}
        if sourceOpts.skipTutorial == true then
            sanitized.skipTutorial = true
        end
        if sourceOpts.skipCooldown == true then
            sanitized.skipCooldown = true
        end
        if sourceOpts.skipScripted == true then
            sanitized.skipScripted = true
        end
        if type(sourceOpts.flowLabel) == "string" and sourceOpts.flowLabel ~= "" then
            sanitized.flowLabel = sourceOpts.flowLabel
        end
        if next(sanitized) == nil then
            return nil
        end
        return sanitized
    end

    local function EA_MakeDeferredRestPayload(timerName, charId, longRest, forced, why, retryCount, retryDelayMs, sourceOpts, tsMs, runtimeReadyRetries)
        local payload = {
            kind = "REST_DEFERRED",
            timer = tostring(timerName or ""),
            character = tostring(charId or ""),
            isLongRest = (longRest == true),
            force = (forced == true),
            reason = tostring(why or "unsafe"),
            retryCount = tonumber(retryCount) or 0,
            retryDelayMs = tonumber(retryDelayMs) or 0,
            timestamp = tonumber(tsMs) or 0,
        }
        local sanitizedOpts = EA_SanitizeDeferredRestOpts(sourceOpts)
        if sanitizedOpts then
            payload.opts = sanitizedOpts
        end
        local readyRetries = tonumber(runtimeReadyRetries)
        if readyRetries and readyRetries > 0 then
            payload.runtimeReadyRetries = readyRetries
        end
        return payload
    end

    local function EA_GetDeferredRestMirrorIfPresent()
        local varsFn = EA and EA["EA_Vars"]
        if type(varsFn) ~= "function" then
            return nil, nil
        end
        local ok, vars = pcall(varsFn)
        if not ok or (type(vars) ~= "table" and type(vars) ~= "userdata") then
            return nil, nil
        end
        local payload = vars.EA_RestDeferredState
        if type(payload) ~= "table" and type(payload) ~= "userdata" then
            return nil, vars
        end
        return payload, vars
    end

    local function EA_SetDeferredRestMirror(payload)
        local varsFn = EA and EA["EA_Vars"]
        if type(varsFn) ~= "function" then
            return false
        end
        local ok, vars = pcall(varsFn)
        if not ok or (type(vars) ~= "table" and type(vars) ~= "userdata") then
            return false
        end
        vars.EA_RestDeferredState = payload
        return true
    end

    local Runtime = {}
    local sessionLoadedTimerStartupCompleted = false
    local sessionLoadedTimerStartupRetryQueued = false
    local EA_OnScenarioBootstrapSessionLoaded = deps.EA_OnScenarioBootstrapSessionLoaded or function() end
    local EA_HandleScenarioBootstrapTimer = deps.EA_HandleScenarioBootstrapTimer or function(_timer) return false end
    local function EA_BuildRuntimeWithDeps(moduleName, moduleTable, moduleDeps, schema)
        if type(EA_BuildRuntimeWithDepsShared) == "function" then
            return EA_BuildRuntimeWithDepsShared(moduleName, moduleTable, moduleDeps, schema)
        end
        if type(moduleTable) ~= "table" or type(moduleTable.Build) ~= "function" then
            return nil
        end
        if type(EA_ValidateBuildDeps) == "function" then
            local ok = EA_ValidateBuildDeps(moduleName, moduleDeps, schema)
            if ok ~= true then
                return nil
            end
        end
        local buildOk, runtimeOrErr = pcall(moduleTable.Build, moduleDeps)
        if not buildOk then
            print(string.format("[EnemyAmbush][Seam] %s Build() failed: %s", tostring(moduleName), tostring(runtimeOrErr)))
            return nil
        end
        return runtimeOrErr
    end
    local timerListenersRegistered = false
    function Runtime.RegisterTimerListeners()
    if timerListenersRegistered then
        EA_P0Inc("listenerRegGuard.RegisterTimerListeners")
        return false
    end
    EA_P0Inc("listenerReg.RegisterTimerListeners")
    if not (Ext and Ext.Osiris and Ext.Osiris.RegisterListener) then
        return
    end
    timerListenersRegistered = true
    -- ========= TIMER HANDLER =========
    -- Tracks retries per character for the current long-rest chain
    local EA_LR_RetryCount = {}
    local EA_SR_RetryCount = {}
    local EA_LR_RetryOpts = {}
    local EA_SR_RetryOpts = {}
    local RETRY_LOG_EVERY = math.max(1, EA_RETRY_LOG_EVERY)
    EA_LogRestFlow = function(stage, fmt, ...)
        local msg = fmt
        if select("#", ...) > 0 then
            msg = string.format(fmt, ...)
        end
        print(string.format("[EnemyAmbush][RestFlow] %s %s", tostring(stage or "event"), tostring(msg or "")))
    end
    local function EA_IsPlayableCharacter(character)
        if not character or character == "" then
            return false
        end
        if Osi and Osi.IsPlayer then
            return Osi.IsPlayer(character) == 1
        end
        return true
    end
    local function EA_ResolveRestCharacter(rawChar, timerName, stageLabel)
        if EA_IsPlayableCharacter(rawChar) then
            return rawChar
        end
        local host = (Osi and Osi.GetHostCharacter and Osi.GetHostCharacter()) or nil
        if EA_IsPlayableCharacter(host) then
            EA_LogRestFlow(
                "check",
                "%s timer fallback to host=%s (raw=%s timer=%s)",
                tostring(stageLabel or "Rest"),
                tostring(host),
                tostring(rawChar or ""),
                tostring(timerName or "")
            )
            return host
        end
        EA_LogRestFlow(
            "check",
            "%s timer dropped: no valid player (raw=%s timer=%s)",
            tostring(stageLabel or "Rest"),
            tostring(rawChar or ""),
            tostring(timerName or "")
        )
        return nil
    end
    local function EA_GetRestRetryDelaySeconds()
        if type(EA_IsQuickTestMode) == "function" then
            local ok, quick = pcall(EA_IsQuickTestMode)
            if ok and quick == true then
                return 3
            end
        end
        return LONG_REST_SAFETY_DELAY
    end
    local function EA_ParseRestTimerCharacter(timerName, prefix, stageLabel)
        if type(timerName) ~= "string" or timerName == "" then
            return nil
        end
        if type(prefix) ~= "string" or prefix == "" then
            return nil
        end

        -- Character ids can contain underscores, so parse greedily up to the final "_<monotonic>" suffix.
        local char = timerName:match("^" .. prefix .. "(.+)_%d+$")
        if char and char ~= "" then
            return char
        end

        EA_LogRestFlow(
            "check",
            "%s timer parse failed timer=%s prefix=%s",
            tostring(stageLabel or "Rest"),
            tostring(timerName),
            tostring(prefix)
        )
        return nil
    end
    local function EA_IsTrackedRestTimer(timerName)
        return EA_HasPrefix(timerName, TIMER_PREFIX_SHORT_REST)
            or EA_HasPrefix(timerName, TIMER_PREFIX_LONG_REST)
            or EA_HasPrefix(timerName, TIMER_PREFIX_SHORT_RETRY)
            or EA_HasPrefix(timerName, TIMER_PREFIX_LONG_RETRY)
            or EA_HasPrefix(timerName, TIMER_PREFIX_REST_DEFER)
    end
    local function EA_GetActiveRestTimer()
        local state = EA and EA.EA_ActiveRestTimer
        if type(state) == "table" and type(state.timer) == "string" and state.timer ~= "" then
            return state
        end
        return nil
    end
    local function EA_ClearPendingRestPayload(timerName)
        if type(timerName) ~= "string" or timerName == "" then
            return
        end
        local pending = EA_Pending()
        local mirrorCleared = false
        if type(pending) ~= "table" and type(pending) ~= "userdata" then
            pending = nil
        end
        if pending and pending[timerName] ~= nil then
            pending[timerName] = nil
            mirrorCleared = true
        end
        local mirror = ({ EA_GetDeferredRestMirrorIfPresent() })[1]
        if (type(mirror) == "table" or type(mirror) == "userdata")
            and tostring(mirror.timer or "") == timerName then
            if EA_SetDeferredRestMirror(nil) then
                mirrorCleared = true
            end
        end
        if mirrorCleared then
            EA_Dirty(true)
        end
    end
    local function EA_ClearActiveRestTimer(timerName)
        local current = EA_GetActiveRestTimer()
        if not current then
            return
        end
        if timerName == nil or current.timer == timerName then
            EA.EA_ActiveRestTimer = nil
        end
    end
    local function EA_ReplaceActiveRestTimer(timerName, kind, character, stage)
        if type(timerName) ~= "string" or timerName == "" then
            return
        end
        local current = EA_GetActiveRestTimer()
        if current and current.timer ~= timerName then
            if Osi and Osi.TimerCancel then
                pcall(Osi.TimerCancel, current.timer)
            end
            EA_ClearPendingRestPayload(current.timer)
            local rec = EA and EA["EA_RecordRestStat"]
            if type(rec) == "function" then
                rec((kind == "long") and "long" or "short", "replacedPending", 1)
            end
            EA_LogRestFlow(
                "replace",
                "pending %s timer=%s replaced by %s timer=%s",
                tostring(current.kind or "rest"),
                tostring(current.timer),
                tostring(kind or "rest"),
                tostring(timerName)
            )
        end
        EA.EA_ActiveRestTimer = {
            timer = timerName,
            kind = tostring(kind or "rest"),
            character = tostring(character or ""),
            stage = tostring(stage or ""),
            setAt = EA_NowMs(),
        }
    end
    local function EA_ShouldIgnoreStaleRestTimer(timerName, kind)
        if not EA_IsTrackedRestTimer(timerName) then
            return false
        end
        local current = EA_GetActiveRestTimer()
        if current and current.timer ~= timerName then
            local rec = EA and EA["EA_RecordRestStat"]
            if type(rec) == "function" then
                rec((kind == "long") and "long" or "short", "staleTimerIgnored", 1)
            end
            EA_LogRestFlow(
                "check",
                "stale %s timer ignored current=%s stale=%s",
                tostring(kind or "rest"),
                tostring(current.timer),
                tostring(timerName)
            )
            return true
        end
        return false
    end
    local function EA_GetPendingAmbushId(data)
        if type(data) ~= "table" and type(data) ~= "userdata" then
            return ""
        end
        local roll = data.roll
        if type(roll) ~= "table" and type(roll) ~= "userdata" then
            return ""
        end
        local ambushId = tostring(roll.ambushId or "")
        if ambushId == "" then
            return ""
        end
        return ambushId
    end
    local function EA_GetSpawnQueueSpawnedCount(data)
        if type(data) ~= "table" and type(data) ~= "userdata" then
            return 0
        end
        local queueState = data.queueState
        if type(queueState) ~= "table" and type(queueState) ~= "userdata" then
            return 0
        end
        local spawnedEnemies = queueState.spawnedEnemies
        if type(spawnedEnemies) ~= "table" then
            return 0
        end
        return #spawnedEnemies
    end
    local function EA_GetSpawnQueueTargetCount(data)
        if type(data) ~= "table" and type(data) ~= "userdata" then
            return 0
        end
        local queueState = data.queueState
        if type(queueState) ~= "table" and type(queueState) ~= "userdata" then
            return 0
        end
        return math.max(0, math.floor(tonumber(queueState.minEnemiesTarget) or 0))
    end
    local function EA_GetSpawnQueueCombatContinuationLimit(spawnedSoFar, targetCount)
        local gap = math.max(0, (tonumber(targetCount) or 0) - (tonumber(spawnedSoFar) or 0))
        return math.max(2, math.min(10, gap + 1))
    end
    local function EA_GetStoredSpawnQueueCombatContinuationLimit(data, spawnedSoFar, targetCount)
        local dataType = type(data)
        if dataType == "table" or dataType == "userdata" then
            local stored = math.max(0, math.floor(tonumber(data.combatContinueLimit) or 0))
            if stored > 0 then
                return stored
            end
        end
        local limit = EA_GetSpawnQueueCombatContinuationLimit(spawnedSoFar, targetCount)
        if (dataType == "table" or dataType == "userdata") and limit > 0 then
            data.combatContinueLimit = limit
        end
        return limit
    end
    local function EA_GetSpawnQueueContinuationProgress(beforeCount, data)
        local before = math.max(0, math.floor(tonumber(beforeCount) or 0))
        local after = EA_GetSpawnQueueSpawnedCount(data)
        return after > before, after
    end
    local function EA_FindEngagedSpawnForAmbush(ambushId)
        local aid = tostring(ambushId or "")
        if aid == "" then
            return nil
        end
        local spawned = EA_Spawned()
        if type(spawned) ~= "table" and type(spawned) ~= "userdata" then
            return nil
        end
        for id, spawnData in pairs(spawned) do
            if (type(spawnData) == "table" or type(spawnData) == "userdata")
                and tostring(spawnData.ambushId or "") == aid then
                local enemy = EA_NormalizeUUID(id) or id
                local exists = (not Osi.ObjectExists) or (Osi.ObjectExists(enemy) == 1)
                local alive = exists and ((not Osi.IsDead) or (Osi.IsDead(enemy) ~= 1))
                if alive and Osi.IsInCombat and Osi.IsInCombat(enemy) == 1 then
                    return enemy
                end
            end
        end
        return nil
    end
    local function EA_StatsNowMs()
        if type(EA_GetNowMsSafe) == "function" then
            return tonumber(EA_GetNowMsSafe()) or 0
        end
        local nowFn = EA_NowMs or (EA and EA["EA_NowMs"])
        if type(nowFn) == "function" then
            local ok, out = pcall(nowFn)
            if ok and tonumber(out) then
                return tonumber(out)
            end
        end
        local persistedFn = EA_PersistedNowMs or (EA and EA["EA_PersistedNowMs"])
        if type(persistedFn) == "function" then
            local ok, out = pcall(persistedFn)
            if ok and tonumber(out) then
                return tonumber(out)
            end
        end
        return 0
    end
    local function EA_StatsCopy(value)
        if type(value) ~= "table" then
            return value
        end
        local out = {}
        for k, v in pairs(value) do
            out[k] = EA_StatsCopy(v)
        end
        return out
    end
    local function EA_EnsureRestStats()
        local s = EnemyAmbush._RestStats
        if type(s) ~= "table" then
            s = {
                sessionStartedAtMs = EA_StatsNowMs(),
                updatedAtMs = 0,
                short = {},
                long = {},
                lastRoll = nil,
                lastExportPath = nil,
            }
            EnemyAmbush._RestStats = s
        end
        s.short = s.short or {}
        s.long = s.long or {}
        return s
    end
    local function EA_EnsureRepStats()
        local s = EnemyAmbush._RepStats
        if type(s) ~= "table" then
            s = {
                sessionStartedAtMs = EA_StatsNowMs(),
                updatedAtMs = 0,
                totalKillsTracked = 0,
                championResets = 0,
                capBlocked = 0,
                outOfCombatKills = 0,
                inCombatKills = 0,
                totalRepDelta = 0,
                negativeDelta = 0,
                positiveDelta = 0,
                byType = {},
                last = nil,
                lastExportPath = nil,
            }
            EnemyAmbush._RepStats = s
        end
        s.byType = s.byType or {}
        return s
    end
    EA["EA_RecordRestStat"] = function(kind, key, delta)
        if kind ~= "short" and kind ~= "long" then
            return
        end
        if type(key) ~= "string" or key == "" then
            return
        end
        local s = EA_EnsureRestStats()
        local bucket = s[kind]
        local add = tonumber(delta) or 1
        bucket[key] = (tonumber(bucket[key]) or 0) + add
        s.updatedAtMs = EA_StatsNowMs()
    end
    EA["EA_RecordRestRoll"] = function(isLongRest, roll, chance, forced, passed, character)
        local kind = (isLongRest == true) and "long" or "short"
        local rec = EA and EA["EA_RecordRestStat"]
        if type(rec) == "function" then
            rec(kind, "rolls", 1)
            if forced == true then
                rec(kind, "forcedRolls", 1)
            end
            if passed == true then
                rec(kind, "rollPassed", 1)
            else
                rec(kind, "rollFailed", 1)
            end
        end
        local s = EA_EnsureRestStats()
        s.lastRoll = {
            kind = kind,
            roll = tonumber(roll),
            chance = tonumber(chance),
            forced = (forced == true),
            passed = (passed == true),
            character = tostring(character or ""),
            atMs = EA_StatsNowMs(),
        }
        s.updatedAtMs = s.lastRoll.atMs
    end
    EA["EA_RecordRestSpawn"] = function(isLongRest, spawnedCount, character)
        local count = tonumber(spawnedCount) or 0
        local kind = (isLongRest == true) and "long" or "short"
        local rec = EA and EA["EA_RecordRestStat"]
        if type(rec) == "function" then
            if count > 0 then
                rec(kind, "spawnedAmbushes", 1)
                rec(kind, "spawnedEntities", count)
            else
                rec(kind, "zeroSpawnAmbushes", 1)
            end
        end
        local s = EA_EnsureRestStats()
        s.lastSpawn = {
            kind = kind,
            spawnedCount = count,
            character = tostring(character or ""),
            atMs = EA_StatsNowMs(),
        }
        s.updatedAtMs = s.lastSpawn.atMs
    end
    EA["EA_GetRestStats"] = function()
        return EA_StatsCopy(EA_EnsureRestStats())
    end
    
    EA["EA_ResetRestStats"] = function()
        EnemyAmbush._RestStats = nil
        return EA["EA_GetRestStats"]()
    end
    
    EA["EA_ExportRestStats"] = function()
        if not (Ext and Ext.IO and type(Ext.IO.SaveFile) == "function" and Ext.Json and type(Ext.Json.Stringify) == "function") then
            return false, "io_unavailable"
        end
        local snapshot = EA_StatsCopy(EA_EnsureRestStats())
        snapshot.exportedAtMs = EA_StatsNowMs()
        snapshot.source = "ea_test reststats export"
        local ts = tostring(math.floor(tonumber(snapshot.exportedAtMs) or 0))
        local relPath = "Hunted_DynamicAmbushes_Revenge_System/reststats_" .. ts .. ".json"
        local okJson, json = pcall(Ext.Json.Stringify, snapshot, { Beautify = true })
        if not okJson or type(json) ~= "string" then
            return false, "json_failed"
        end
        local okSave, saved = pcall(Ext.IO.SaveFile, relPath, json)
        if not okSave or saved ~= true then
            return false, "save_failed"
        end
        local stats = EA_EnsureRestStats()
        stats.lastExportPath = relPath
        stats.updatedAtMs = EA_StatsNowMs()
        return true, relPath
    end
    
    EA["EA_RecordRepChange"] = function(creatureType, oldRep, newRep, repChange, isChampion, capBlocked, inCombat)
        local ct = tostring(creatureType or "Unknown")
        local before = tonumber(oldRep) or 0
        local after = tonumber(newRep) or before
        local delta = tonumber(repChange)
        if delta == nil then
            delta = after - before
        end
    
        local s = EA_EnsureRepStats()
        s.totalKillsTracked = (tonumber(s.totalKillsTracked) or 0) + 1
        s.totalRepDelta = (tonumber(s.totalRepDelta) or 0) + delta
        if delta < 0 then
            s.negativeDelta = (tonumber(s.negativeDelta) or 0) + math.abs(delta)
        elseif delta > 0 then
            s.positiveDelta = (tonumber(s.positiveDelta) or 0) + delta
        end
        if isChampion == true then
            s.championResets = (tonumber(s.championResets) or 0) + 1
        end
        if capBlocked == true then
            s.capBlocked = (tonumber(s.capBlocked) or 0) + 1
        end
        if inCombat == true then
            s.inCombatKills = (tonumber(s.inCombatKills) or 0) + 1
        else
            s.outOfCombatKills = (tonumber(s.outOfCombatKills) or 0) + 1
        end
    
        local byType = s.byType[ct]
        if type(byType) ~= "table" then
            byType = {
                kills = 0,
                championResets = 0,
                capBlocked = 0,
                repDelta = 0,
                negativeDelta = 0,
                positiveDelta = 0,
            }
            s.byType[ct] = byType
        end
        byType.kills = (tonumber(byType.kills) or 0) + 1
        byType.repDelta = (tonumber(byType.repDelta) or 0) + delta
        if delta < 0 then
            byType.negativeDelta = (tonumber(byType.negativeDelta) or 0) + math.abs(delta)
        elseif delta > 0 then
            byType.positiveDelta = (tonumber(byType.positiveDelta) or 0) + delta
        end
        if isChampion == true then
            byType.championResets = (tonumber(byType.championResets) or 0) + 1
        end
        if capBlocked == true then
            byType.capBlocked = (tonumber(byType.capBlocked) or 0) + 1
        end
    
        s.last = {
            creatureType = ct,
            oldRep = before,
            newRep = after,
            repChange = delta,
            championReset = (isChampion == true),
            capBlocked = (capBlocked == true),
            inCombat = (inCombat == true),
            atMs = EA_StatsNowMs(),
        }
        s.updatedAtMs = s.last.atMs
    end
    
    EA["EA_GetRepStats"] = function()
        return EA_StatsCopy(EA_EnsureRepStats())
    end
    
    EA["EA_ResetRepStats"] = function()
        EnemyAmbush._RepStats = nil
        return EA["EA_GetRepStats"]()
    end
    
    EA["EA_ExportRepStats"] = function()
        if not (Ext and Ext.IO and type(Ext.IO.SaveFile) == "function" and Ext.Json and type(Ext.Json.Stringify) == "function") then
            return false, "io_unavailable"
        end
        local snapshot = EA_StatsCopy(EA_EnsureRepStats())
        snapshot.exportedAtMs = EA_StatsNowMs()
        snapshot.source = "ea_test repstats export"
        local ts = tostring(math.floor(tonumber(snapshot.exportedAtMs) or 0))
        local relPath = "Hunted_DynamicAmbushes_Revenge_System/repstats_" .. ts .. ".json"
        local okJson, json = pcall(Ext.Json.Stringify, snapshot, { Beautify = true })
        if not okJson or type(json) ~= "string" then
            return false, "json_failed"
        end
        local okSave, saved = pcall(Ext.IO.SaveFile, relPath, json)
        if not okSave or saved ~= true then
            return false, "save_failed"
        end
        local stats = EA_EnsureRepStats()
        stats.lastExportPath = relPath
        stats.updatedAtMs = EA_StatsNowMs()
        return true, relPath
    end
    
    local function EA_QueueRestDeferred(char, isLongRest, force, reason, retries, opts)
        if not char or char == "" then return end
        local pending = EA_Pending()
        if type(pending) ~= "table" and type(pending) ~= "userdata" then return end
        local rec = EA and EA["EA_RecordRestStat"]
        local kind = (isLongRest == true) and "long" or "short"
        local retryDelaySec = EA_GetRestRetryDelaySeconds()
        if type(rec) == "function" then
            rec(kind, "deferredQueued", 1)
        end

        local timer = string.format("%s%s_%d", TIMER_PREFIX_REST_DEFER, tostring(char), Ext.Utils.MonotonicTime())
        local payload = EA_MakeDeferredRestPayload(
            timer,
            char,
            isLongRest == true,
            force == true,
            reason,
            retries,
            retryDelaySec * 1000,
            opts,
            EA_NowMs(),
            0
        )
        pending[timer] = payload
        EA_SetDeferredRestMirror(payload)
        EA_Dirty(true)
        EA_ReplaceActiveRestTimer(timer, kind, char, "deferred")
        Osi.TimerLaunch(timer, retryDelaySec * 1000)
        EA_LogRestFlow(
            "queued",
            "%s queued until safe (%s) retries=%d in %ds timer=%s",
            (isLongRest and "LongRest" or "ShortRest"),
            tostring(reason or "unsafe"),
            tonumber(retries) or 0,
            retryDelaySec,
            tostring(timer)
        )
    end
    
    -- Helper: schedule a retry with a cap
    local function LaunchLongRestRetry(char, reason, force, opts)
        EA_LR_RetryCount[char] = (EA_LR_RetryCount[char] or 0) + 1
        EA_LR_RetryOpts[char] = (type(opts) == "table") and opts or EA_LR_RetryOpts[char]
        local rec = EA and EA["EA_RecordRestStat"]
        if type(rec) == "function" then
            rec("long", "retryScheduled", 1)
        end
    
        if EA_LR_RetryCount[char] > LONG_REST_RETRY_MAX then
            EA_QueueRestDeferred(char, true, force, reason, EA_LR_RetryCount[char], EA_LR_RetryOpts[char])
            return
        end
    
        local retryTimer = string.format("%s%s_%d", TIMER_PREFIX_LONG_RETRY, tostring(char), Ext.Utils.MonotonicTime())
        local retryDelaySec = EA_GetRestRetryDelaySeconds()
        EA_ReplaceActiveRestTimer(retryTimer, "long", char, "retry")
        EA_LogRestFlow(
            "delayed",
            "LongRest delayed (%s) retry %d/%d in %ds (%s)",
            tostring(reason or "unsafe"),
            EA_LR_RetryCount[char],
            LONG_REST_RETRY_MAX,
            retryDelaySec,
            tostring(retryTimer)
        )
        Osi.TimerLaunch(retryTimer, retryDelaySec * 1000)
    end
    
    local function LaunchShortRestRetry(char, reason, force, opts)
        EA_SR_RetryCount[char] = (EA_SR_RetryCount[char] or 0) + 1
        EA_SR_RetryOpts[char] = (type(opts) == "table") and opts or EA_SR_RetryOpts[char]
        local rec = EA and EA["EA_RecordRestStat"]
        if type(rec) == "function" then
            rec("short", "retryScheduled", 1)
        end
    
        if EA_SR_RetryCount[char] > SHORT_REST_RETRY_MAX then
            EA_QueueRestDeferred(char, false, force, reason, EA_SR_RetryCount[char], EA_SR_RetryOpts[char])
            return
        end
    
        local retryTimer = string.format("%s%s_%d", TIMER_PREFIX_SHORT_RETRY, tostring(char), Ext.Utils.MonotonicTime())
        local retryDelaySec = EA_GetRestRetryDelaySeconds()
        EA_ReplaceActiveRestTimer(retryTimer, "short", char, "retry")
        EA_LogRestFlow(
            "delayed",
            "ShortRest delayed (%s) retry %d/%d in %ds (%s)",
            tostring(reason or "unsafe"),
            EA_SR_RetryCount[char],
            SHORT_REST_RETRY_MAX,
            retryDelaySec,
            tostring(retryTimer)
        )
        Osi.TimerLaunch(retryTimer, retryDelaySec * 1000)
    end
    
    local EventsTimerFlowRuntime = nil
    if EventsTimerFlow and type(EventsTimerFlow.Build) == "function" then
        local timerFlowDeps = {
            EnemyAmbush = EnemyAmbush,
            EA = EA,
            DebugPrint = DebugPrint,
            EA_Spawned = EA_Spawned,
            EA_NowMs = EA_NowMs,
            EA_Dirty = EA_Dirty,
            EA_Pending = EA_Pending,
            EA_EvictOldSpawned = EA_EvictOldSpawned,
            EA_AggressiveSpawnedCleanup = EA_AggressiveSpawnedCleanup,
            EA_PruneRuntimeCombatState = EA_PruneRuntimeCombatState,
            EA_GetEncounterRepState = EA_GetEncounterRepState,
            EA_IsAnyPartyInCombat = EA_IsAnyPartyInCombat,
            EA_MarkRuntimeStateDirty = EA_MarkRuntimeStateDirty,
            EA_GetSettingBoolEvent = EA_GetSettingBoolEvent,
            EA_GetSettingNumberEvent = EA_GetSettingNumberEvent,
            EA_ReputationTable = EA_ReputationTable,
            SaveReputation = SaveReputation,
            CleanupPendingAmbushes = CleanupPendingAmbushes,
            EA_NormalizeUUID = EA_NormalizeUUID,
            EA_AmbushPressure = EA_AmbushPressure,
            EA_GetCooldownEnabled = EA_GetCooldownEnabled,
            EA_PersistedNowMs = EA_PersistedNowMs,
            EA_LastAmbushTime = EA_LastAmbushTime,
            EA_DebugEnabled = EA_DebugEnabled,
            EA_LogRestFlow = EA_LogRestFlow,
            EA_TickTimeInDangerRisk = EA_TickTimeInDangerRisk,
            EA_TryTriggerTravelDangerAmbush = EA_TryTriggerTravelDangerAmbush,
            LONG_REST_SAFETY_DELAY = LONG_REST_SAFETY_DELAY,
            EA_REHYDRATE_READY_RETRY_MAX = EA_REHYDRATE_READY_RETRY_MAX,
            EA_REHYDRATE_READY_RETRY_MS = EA_REHYDRATE_READY_RETRY_MS,
            EA_STAGGER_STEP_MS_MIN = EA_STAGGER_STEP_MS_MIN,
            EA_STAGGER_STEP_MS_DEFAULT = EA_STAGGER_STEP_MS_DEFAULT,
            EA_STAGGER_STEP_MS_MAX = EA_STAGGER_STEP_MS_MAX,
        }
        EventsTimerFlowRuntime = EA_BuildRuntimeWithDeps("EventsTimerFlow", EventsTimerFlow, timerFlowDeps, {
            EnemyAmbush = "tablelike",
            EA = "tablelike",
            DebugPrint = "callable",
            EA_Spawned = "callable",
            EA_NowMs = "callable",
            EA_Dirty = "callable",
            EA_Pending = "callable",
            EA_PersistedNowMs = { "callable", "nil" },
            EA_TickTimeInDangerRisk = { "callable", "nil" },
            EA_TryTriggerTravelDangerAmbush = { "callable", "nil" },
        })
    end
    
    local EventsScenarioBootstrapRuntime = nil
    if EventsScenarioBootstrap and type(EventsScenarioBootstrap.Build) == "function" then
        local scenarioDeps = {
            EnemyAmbush = EnemyAmbush,
            EA = EA,
            ModuleUUID = ModuleUUID,
            DebugPrint = DebugPrint,
            EA_DebugEnabled = EA_DebugEnabled,
            EA_Dirty = EA_Dirty,
            EA_NowMs = EA_NowMs,
            EA_LogRestFlow = EA_LogRestFlow,
            EA_ShouldSkipBeachTutorialAmbush = EA_ShouldSkipBeachTutorialAmbush,
            EA_GetScriptedScenarioState = EA_GetScriptedScenarioState,
            EA_RunScriptedScenarioById = EA_RunScriptedScenarioById,
            EA_GetRegionForCharacter = EA_GetRegionForCharacter,
            GetSafeLevel = GetSafeLevel,
            IsSafeToSpawnAmbush = IsSafeToSpawnAmbush,
            EA_ResolveLocaText = EA_ResolveLocaText,
            EA_IsModVarsContainer = EA_IsModVarsContainer,
        }
        EventsScenarioBootstrapRuntime = EA_BuildRuntimeWithDeps("EventsScenarioBootstrap", EventsScenarioBootstrap, scenarioDeps, {
            EnemyAmbush = "tablelike",
            EA = "tablelike",
            ModuleUUID = "string",
            DebugPrint = "callable",
            EA_NowMs = "callable",
            EA_Dirty = "callable",
            IsSafeToSpawnAmbush = "callable",
            EA_ShouldSkipBeachTutorialAmbush = "callable",
            EA_GetScriptedScenarioState = "callable",
            EA_RunScriptedScenarioById = "callable",
        })
    end
    if EventsScenarioBootstrapRuntime and type(EventsScenarioBootstrapRuntime.OnSessionLoaded) == "function" then
        EA_OnScenarioBootstrapSessionLoaded = EventsScenarioBootstrapRuntime.OnSessionLoaded
    end
    if EventsScenarioBootstrapRuntime and type(EventsScenarioBootstrapRuntime.TryHandleTimer) == "function" then
        EA_HandleScenarioBootstrapTimer = EventsScenarioBootstrapRuntime.TryHandleTimer
    end
    
    local function EA_HandleTimerValidateSpawned()
        if EventsTimerFlowRuntime and type(EventsTimerFlowRuntime.HandleTimerValidateSpawned) == "function" then
            return EventsTimerFlowRuntime.HandleTimerValidateSpawned()
        end
    end
    
    local function EA_HandleTimerRuntimeCombatPrune()
        if EventsTimerFlowRuntime and type(EventsTimerFlowRuntime.HandleTimerRuntimeCombatPrune) == "function" then
            return EventsTimerFlowRuntime.HandleTimerRuntimeCombatPrune()
        end
    end
    
    local function EA_HandleTimerEncounterRepWatch()
        if EventsTimerFlowRuntime and type(EventsTimerFlowRuntime.HandleTimerEncounterRepWatch) == "function" then
            return EventsTimerFlowRuntime.HandleTimerEncounterRepWatch()
        end
    end
    
    local function EA_HandleTimerReputationDecay()
        if EventsTimerFlowRuntime and type(EventsTimerFlowRuntime.HandleTimerReputationDecay) == "function" then
            return EventsTimerFlowRuntime.HandleTimerReputationDecay()
        end
    end
    
    local function EA_HandleTimerCleanupPending()
        if EventsTimerFlowRuntime and type(EventsTimerFlowRuntime.HandleTimerCleanupPending) == "function" then
            return EventsTimerFlowRuntime.HandleTimerCleanupPending()
        end
    end
    
    local EA_TIMER_EXACT_HANDLERS = {}
    if EventsTimerRouter and type(EventsTimerRouter.BuildExactHandlers) == "function" then
        EA_TIMER_EXACT_HANDLERS = EventsTimerRouter.BuildExactHandlers({
            onValidateSpawned = EA_HandleTimerValidateSpawned,
            onRuntimeCombatPrune = EA_HandleTimerRuntimeCombatPrune,
            onEncounterRepWatch = EA_HandleTimerEncounterRepWatch,
            onReputationDecay = EA_HandleTimerReputationDecay,
            onCleanupPending = EA_HandleTimerCleanupPending,
        })
    else
        EA_TIMER_EXACT_HANDLERS = {
            EA_VALIDATE_SPAWNED = EA_HandleTimerValidateSpawned,
            EA_RUNTIME_COMBAT_PRUNE = EA_HandleTimerRuntimeCombatPrune,
            EA_ENCOUNTER_REP_WATCH = EA_HandleTimerEncounterRepWatch,
            EA_REPUTATION_DECAY = EA_HandleTimerReputationDecay,
            EA_CLEANUP_PENDING = EA_HandleTimerCleanupPending,
        }
    end

    local function EA_LaunchExactRecurringTimer(timer, delayMs)
        if type(timer) ~= "string" or timer == "" then
            return false
        end
        if type(EA_TIMER_EXACT_HANDLERS[timer]) ~= "function" then
            return false
        end
        if not (Osi and Osi.TimerLaunch) then
            return false
        end
        local launchMs = math.max(250, tonumber(delayMs) or 0)
        local okLaunch, launchErr = pcall(Osi.TimerLaunch, timer, launchMs)
        if not okLaunch then
            print(string.format(
                "[EnemyAmbush][Timer] Failed to launch exact timer %s (%dms): %s",
                tostring(timer),
                launchMs,
                tostring(launchErr)
            ))
            return false
        end
        return true
    end

    function Runtime.LaunchEncounterRepWatchTimer(delayMs)
        return EA_LaunchExactRecurringTimer("EA_ENCOUNTER_REP_WATCH", tonumber(delayMs) or 5000)
    end

    function Runtime.LaunchStartupRecurringTimers()
        for i = 1, #RECURRING_STARTUP_TIMER_SPECS do
            local spec = RECURRING_STARTUP_TIMER_SPECS[i]
            EA_LaunchExactRecurringTimer(spec.timer, spec.delayMs)
        end
        return true
    end

    -- TimerMain is the explicit control plane for startup timer launch and session-load timer relaunch.
    function Runtime.HandleSessionLoadedTimerStartup(tries)
        tries = tonumber(tries) or 0
        if sessionLoadedTimerStartupCompleted then
            return true
        end
        if not EA_IsRuntimeGameStateReady() then
            if EA_DebugEnabled() then
                DebugPrint(string.format(
                    "[Startup] Timer startup deferred: runtime game state not ready try=%d/15",
                    tries
                ))
            end
            if tries < 15 and not sessionLoadedTimerStartupRetryQueued and Ext and Ext.Timer and Ext.Timer.WaitFor then
                sessionLoadedTimerStartupRetryQueued = true
                Ext.Timer.WaitFor(1000, function()
                    sessionLoadedTimerStartupRetryQueued = false
                    Runtime.HandleSessionLoadedTimerStartup(tries + 1)
                end)
            end
            return false
        end

        sessionLoadedTimerStartupRetryQueued = false

        if type(RelaunchPendingTimersOnLoad) == "function" then
            RelaunchPendingTimersOnLoad()
        end

        Runtime.LaunchStartupRecurringTimers()

        if type(EA_OnScenarioBootstrapSessionLoaded) == "function" then
            local okScenario, scenarioErr = pcall(EA_OnScenarioBootstrapSessionLoaded)
            if not okScenario then
                print(string.format(
                    "[EnemyAmbush][Bootstrap] Scenario bootstrap session init failed (timer_owner): %s",
                    tostring(scenarioErr)
                ))
            end
        end

        local function LogPersistentHostileRetrySnapshot(label, mode)
            if EA_DebugEnabled() ~= true then
                return
            end
            if type(EA_DebugBuildPersistentHostileRetrySnapshot) ~= "function"
                or type(EA_DebugLogPersistentHostileRetrySnapshot) ~= "function" then
                return
            end
            local okSnapshot, snapshot = pcall(EA_DebugBuildPersistentHostileRetrySnapshot, mode)
            if not okSnapshot then
                DebugPrint(string.format(
                    "Persistent hostile retry snapshot build failed (%s/%s): %s",
                    tostring(label),
                    tostring(mode),
                    tostring(snapshot)
                ))
                return
            end
            pcall(EA_DebugLogPersistentHostileRetrySnapshot, label, snapshot)
        end

        LogPersistentHostileRetrySnapshot("session_loaded_pre_rearm_raw", "raw")

        local function RearmPersistentHostileRetriesNow()
            if type(EA_RearmPersistentHostileRetries) ~= "function" then
                return
            end
            LogPersistentHostileRetrySnapshot("session_loaded_pre_rearm_strict", "strict")
            local okRearm, count = pcall(EA_RearmPersistentHostileRetries)
            if okRearm and tonumber(count) and tonumber(count) > 0 and EA_DebugEnabled() then
                DebugPrint(string.format("Rearmed persistent hostile retries: %d", tonumber(count)))
            end
        end

        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(1000, RearmPersistentHostileRetriesNow)
        else
            RearmPersistentHostileRetriesNow()
        end

        sessionLoadedTimerStartupCompleted = true
        return true
    end
    
    local function EA_GetStaggerStepMs(raw)
        if EventsTimerFlowRuntime and type(EventsTimerFlowRuntime.GetStaggerStepMs) == "function" then
            return EventsTimerFlowRuntime.GetStaggerStepMs(raw)
        end
        return math.floor(math.max(EA_STAGGER_STEP_MS_MIN, math.min(EA_STAGGER_STEP_MS_MAX, tonumber(raw) or EA_STAGGER_STEP_MS_DEFAULT)))
    end
    
    local function EA_OnDelayedAmbushComplete(char, ambushData, spawnedCount)
        if EventsTimerFlowRuntime and type(EventsTimerFlowRuntime.OnDelayedAmbushComplete) == "function" then
            return EventsTimerFlowRuntime.OnDelayedAmbushComplete(char, ambushData, spawnedCount)
        end
    end
    
    local function EA_IsRuntimeReadyForAmbush(character)
        if EventsTimerFlowRuntime and type(EventsTimerFlowRuntime.IsRuntimeReadyForAmbush) == "function" then
            return EventsTimerFlowRuntime.IsRuntimeReadyForAmbush(character)
        end
        return false, "timer_flow_unavailable"
    end
    
    local function EA_RequeueRuntimeReadyRetry(pending, timer, data, stage)
        if EventsTimerFlowRuntime and type(EventsTimerFlowRuntime.RequeueRuntimeReadyRetry) == "function" then
            return EventsTimerFlowRuntime.RequeueRuntimeReadyRetry(pending, timer, data, stage)
        end
        return false
    end

    local function EA_TryHandlePersistentHostileRetry(timer)
        if type(EA_HandlePersistentHostileRetryTimer) ~= "function" then
            return false
        end
        local okRetry, handled = pcall(EA_HandlePersistentHostileRetryTimer, timer)
        return okRetry and handled == true
    end

    local function EA_DispatchExactTimer(timer)
        local exactHandler = EA_TIMER_EXACT_HANDLERS[timer]
        if type(exactHandler) == "function" then
            exactHandler()
            return true
        end
        return false
    end

    local function EA_TryHandleApproachBeatTimer(timer)
        if EventsTimerRouter and type(EventsTimerRouter.TryHandleApproachBeatTimer) == "function" then
            local handledBeat = EventsTimerRouter.TryHandleApproachBeatTimer(timer, {
                pendingFn = EA_Pending,
                dirtyFn = EA_Dirty,
                playBeatFn = EA_PlayApproachBeatFromData,
            })
            if handledBeat == true then
                return true
            end
        end
        return false
    end

    local function EA_TryHandleScenarioBootstrapTimer(timer)
        return EA_HandleScenarioBootstrapTimer(timer) == true
    end

    local function EA_HandleShortRestTimer(timer)
        if EA_ShouldIgnoreStaleRestTimer(timer, "short") then
            return true
        end
        EA_ClearActiveRestTimer(timer)
        local char = EA_ParseRestTimerCharacter(timer, TIMER_PREFIX_SHORT_REST, "ShortRest")
        if char then
            local rec = EA and EA["EA_RecordRestStat"]
            local rawChar = char
            char = EA_ResolveRestCharacter(rawChar, timer, "ShortRest")
            if not char then
                if type(rec) == "function" then
                    rec("short", "timerInvalidCharacter", 1)
                end
                return true
            end
            local chainOpts = EA_SR_RetryOpts[rawChar] or EA_SR_RetryOpts[char]
            if type(rec) == "function" then
                rec("short", "timerFired", 1)
            end
            if not EA_IsRestAmbushEnabled() then
                return true
            end

            EA_SR_RetryCount[char] = 0
            EA_SR_RetryOpts[char] = chainOpts

            local pressure = EA_AddAmbushPressure(char, false)
            local force = (pressure >= AMBUSH_PRESSURE_MAX)
            EA_LogRestFlow("check", "ShortRest timer fired char=%s pressure=%.2f force=%s", tostring(char), tonumber(pressure) or 0, tostring(force))

            if IsSafeToSpawnAmbush(char) then
                if type(rec) == "function" then
                    rec("short", "safeTriggers", 1)
                end
                if EA_DebugEnabled() then
                    DebugPrint("Short rest ambush check: safe, triggering now for", tostring(char))
                end
                TriggerAmbush(char, false, force, chainOpts)
            else
                if type(rec) == "function" then
                    rec("short", "unsafeDelayed", 1)
                end
                LaunchShortRestRetry(char, "not safe yet", force, chainOpts)
            end
        end
        return true
    end

    local function EA_HandleLongRestTimer(timer)
        if EA_ShouldIgnoreStaleRestTimer(timer, "long") then
            return true
        end
        EA_ClearActiveRestTimer(timer)
        local char = EA_ParseRestTimerCharacter(timer, TIMER_PREFIX_LONG_REST, "LongRest")
        if char then
            local rec = EA and EA["EA_RecordRestStat"]
            local rawChar = char
            char = EA_ResolveRestCharacter(rawChar, timer, "LongRest")
            if not char then
                if type(rec) == "function" then
                    rec("long", "timerInvalidCharacter", 1)
                end
                return true
            end
            local chainOpts = EA_LR_RetryOpts[rawChar] or EA_LR_RetryOpts[char]
            if type(rec) == "function" then
                rec("long", "timerFired", 1)
            end
            EA_LR_RetryCount[char] = 0
            EA_LR_RetryOpts[char] = chainOpts

            if not EA_IsRestAmbushEnabled() then
                return true
            end

            EA_ArmGuaranteedChampion(char)

            local pressure = EA_AddAmbushPressure(char, true)
            local force = (pressure >= AMBUSH_PRESSURE_MAX)
            EA_LogRestFlow("check", "LongRest timer fired char=%s pressure=%.2f force=%s", tostring(char), tonumber(pressure) or 0, tostring(force))

            if IsSafeToSpawnAmbush(char) then
                if type(rec) == "function" then
                    rec("long", "safeTriggers", 1)
                end
                TriggerAmbush(char, true, force, chainOpts)
            else
                if type(rec) == "function" then
                    rec("long", "unsafeDelayed", 1)
                end
                LaunchLongRestRetry(char, "not safe yet", force, chainOpts)
            end
        end
        return true
    end

    local function EA_HandleShortRestRetryTimer(timer)
        if EA_ShouldIgnoreStaleRestTimer(timer, "short") then
            return true
        end
        EA_ClearActiveRestTimer(timer)
        local char = EA_ParseRestTimerCharacter(timer, TIMER_PREFIX_SHORT_RETRY, "ShortRestRetry")
        if char then
            local rec = EA and EA["EA_RecordRestStat"]
            local rawChar = char
            char = EA_ResolveRestCharacter(rawChar, timer, "ShortRestRetry")
            if not char then
                if type(rec) == "function" then
                    rec("short", "retryInvalidCharacter", 1)
                end
                return true
            end
            if type(rec) == "function" then
                rec("short", "retryTimerFired", 1)
            end
            if not EA_IsRestAmbushEnabled() then
                return true
            end

            if IsSafeToSpawnAmbush(char) then
                local pressure = EA_GetAmbushPressure(char)
                local force = (pressure >= AMBUSH_PRESSURE_MAX)
                EA_LogRestFlow("retry", "ShortRest retry safe char=%s pressure=%.2f force=%s", tostring(char), tonumber(pressure) or 0, tostring(force))
                if type(rec) == "function" then
                    rec("short", "retrySafeTriggers", 1)
                end
                TriggerAmbush(char, false, force, EA_SR_RetryOpts[rawChar] or EA_SR_RetryOpts[char])
            else
                local pressure = EA_GetAmbushPressure(char)
                local force = (pressure >= AMBUSH_PRESSURE_MAX)
                if type(rec) == "function" then
                    rec("short", "retryStillUnsafe", 1)
                end
                LaunchShortRestRetry(char, "still not safe", force, EA_SR_RetryOpts[rawChar] or EA_SR_RetryOpts[char])
            end
        end
        return true
    end

    local function EA_HandleLongRestRetryTimer(timer)
        if EA_ShouldIgnoreStaleRestTimer(timer, "long") then
            return true
        end
        EA_ClearActiveRestTimer(timer)
        local char = EA_ParseRestTimerCharacter(timer, TIMER_PREFIX_LONG_RETRY, "LongRestRetry")
        if char then
            local rec = EA and EA["EA_RecordRestStat"]
            local rawChar = char
            char = EA_ResolveRestCharacter(rawChar, timer, "LongRestRetry")
            if not char then
                if type(rec) == "function" then
                    rec("long", "retryInvalidCharacter", 1)
                end
                return true
            end
            if type(rec) == "function" then
                rec("long", "retryTimerFired", 1)
            end
            if not EA_IsRestAmbushEnabled() then
                return true
            end

            if IsSafeToSpawnAmbush(char) then
                local pressure = EA_GetAmbushPressure(char)
                local force = (pressure >= AMBUSH_PRESSURE_MAX)
                EA_LogRestFlow("retry", "LongRest retry safe char=%s pressure=%.2f force=%s", tostring(char), tonumber(pressure) or 0, tostring(force))
                if type(rec) == "function" then
                    rec("long", "retrySafeTriggers", 1)
                end
                TriggerAmbush(char, true, force, EA_LR_RetryOpts[rawChar] or EA_LR_RetryOpts[char])
            else
                local pressure = EA_GetAmbushPressure(char)
                local force = (pressure >= AMBUSH_PRESSURE_MAX)
                if type(rec) == "function" then
                    rec("long", "retryStillUnsafe", 1)
                end
                LaunchLongRestRetry(char, "still not safe", force, EA_LR_RetryOpts[rawChar] or EA_LR_RetryOpts[char])
            end
        end
        return true
    end

    local function EA_HandleRestDeferredTimer(timer)
        if EA_ShouldIgnoreStaleRestTimer(timer, "rest") then
            return true
        end
        EA_ClearActiveRestTimer(timer)
        local deferredChar = EA_ParseRestTimerCharacter(timer, TIMER_PREFIX_REST_DEFER, "RestDeferred")
        if deferredChar then
            local rec = EA and EA["EA_RecordRestStat"]
            local pending = EA_GetPendingIfPresent()
            if type(pending) ~= "table" and type(pending) ~= "userdata" then
                EA_RequeueDeferredPayloadRetry(timer, deferredChar, "pending_not_hydrated")
                return true
            end
            local data = pending[timer]
            if not data then
                local replacementTimer = nil
                local replacementData = nil
                for pendingTimer, pendingData in pairs(pending) do
                    if pendingTimer ~= timer
                        and (type(pendingData) == "table" or type(pendingData) == "userdata")
                        and pendingData.kind == "REST_DEFERRED"
                        and tostring(pendingData.character or "") == tostring(deferredChar or "") then
                        local candidateTs = tonumber(pendingData.timestamp) or 0
                        local chosenTs = tonumber(replacementData and replacementData.timestamp) or 0
                        if replacementData == nil or candidateTs >= chosenTs then
                            replacementTimer = pendingTimer
                            replacementData = pendingData
                        end
                    end
                end
                if replacementTimer and replacementData then
                    if Osi and Osi.TimerCancel then
                        pcall(Osi.TimerCancel, replacementTimer)
                    end
                    pending[replacementTimer] = nil
                    data = replacementData
                    EA_LogRestFlow(
                        "deferred",
                        "recovered payload for stale timer=%s using pending=%s",
                        tostring(timer),
                        tostring(replacementTimer)
                    )
                else
                    local mirror = ({ EA_GetDeferredRestMirrorIfPresent() })[1]
                    if (type(mirror) == "table" or type(mirror) == "userdata")
                        and tostring(mirror.character or "") == tostring(deferredChar or "") then
                        data = EA_MakeDeferredRestPayload(
                            timer,
                            mirror.character,
                            mirror.isLongRest == true,
                            mirror.force == true,
                            mirror.reason,
                            mirror.retryCount,
                            mirror.retryDelayMs,
                            mirror.opts,
                            mirror.timestamp,
                            mirror.runtimeReadyRetries
                        )
                        pending[timer] = data
                        EA_LogRestFlow(
                            "deferred",
                            "recovered payload for timer=%s using deferred mirror",
                            tostring(timer)
                        )
                    end
                end
                if not data then
                    if EA_RequeueDeferredPayloadRetry(timer, deferredChar, "payload_missing") then
                        return true
                    end
                    EA_LogRestFlow("deferred", "missing payload for timer=%s", tostring(timer))
                    return true
                end
            end
            EA_DEFERRED_PAYLOAD_RETRY_COUNTS[timer] = nil

            pending[timer] = nil

            local char = data.character
            if not char or char == "" then
                EA_SetDeferredRestMirror(nil)
                EA_Dirty(true)
                EA_LogRestFlow("deferred", "invalid payload character timer=%s", tostring(timer))
                return true
            end
            if Osi.IsPlayer and Osi.IsPlayer(char) ~= 1 then
                EA_SR_RetryOpts[char] = nil
                EA_LR_RetryOpts[char] = nil
                EA_SetDeferredRestMirror(nil)
                EA_Dirty(true)
                EA_LogRestFlow("deferred", "character no longer player=%s", tostring(char))
                return true
            end

            if not EA_IsRestAmbushEnabled() then
                if type(rec) == "function" then
                    rec((data.isLongRest == true) and "long" or "short", "deferredDroppedDisabled", 1)
                end
                EA_SR_RetryOpts[char] = nil
                EA_LR_RetryOpts[char] = nil
                EA_SetDeferredRestMirror(nil)
                EA_Dirty(true)
                EA_LogRestFlow("deferred", "rest ambush disabled; dropping deferred payload for %s", tostring(char))
                return true
            end

            if IsSafeToSpawnAmbush(char) then
                if type(rec) == "function" then
                    rec((data.isLongRest == true) and "long" or "short", "deferredResumed", 1)
                end
                EA_LogRestFlow(
                    "resume",
                    "%s resumed after defer retries=%d char=%s",
                    data.isLongRest and "LongRest" or "ShortRest",
                    tonumber(data.retryCount) or 0,
                    tostring(char)
                )
                TriggerAmbush(char, data.isLongRest == true, data.force == true, data.opts)
                EA_SR_RetryOpts[char] = nil
                EA_LR_RetryOpts[char] = nil
                EA_SetDeferredRestMirror(nil)
                EA_Dirty(true)
            else
                data.retryCount = (tonumber(data.retryCount) or 0) + 1
                local retryDelaySec = EA_GetRestRetryDelaySeconds()
                local retryTimer = string.format("%s%s_%d", TIMER_PREFIX_REST_DEFER, tostring(char), Ext.Utils.MonotonicTime())
                local retryPayload = EA_MakeDeferredRestPayload(
                    retryTimer,
                    char,
                    data.isLongRest == true,
                    data.force == true,
                    data.reason,
                    data.retryCount,
                    retryDelaySec * 1000,
                    data.opts,
                    EA_NowMs(),
                    data.runtimeReadyRetries
                )
                pending[retryTimer] = retryPayload
                EA_SetDeferredRestMirror(retryPayload)
                EA_ReplaceActiveRestTimer(retryTimer, (data.isLongRest == true) and "long" or "short", char, "deferred")
                EA_Dirty(true)
                Osi.TimerLaunch(retryTimer, retryDelaySec * 1000)
                if type(rec) == "function" then
                    rec((data.isLongRest == true) and "long" or "short", "deferredRequeued", 1)
                end

                if data.retryCount == 1 or (data.retryCount % RETRY_LOG_EVERY) == 0 then
                    EA_LogRestFlow(
                        "deferred",
                        "%s still unsafe for %s; keeping queued (retry=%d, timer=%s)",
                        data.isLongRest and "LongRest" or "ShortRest",
                        tostring(char),
                        tonumber(data.retryCount) or 0,
                        tostring(retryTimer)
                    )
                end
            end
        end
        return true
    end

    local function EA_HandleSpawnQueueTimer(timer)
        local spawnQueueKey = timer:match("^" .. TIMER_PREFIX_SPAWNQ .. "(.+)$")
        if spawnQueueKey then
            local pending = EA_Pending()
            if type(pending) ~= "table" and type(pending) ~= "userdata" then
                return true
            end
            local data = pending[timer]
            if type(data) ~= "table" and type(data) ~= "userdata" then
                pending[timer] = nil
                EA_Dirty(true)
                return true
            end
            if data.kind ~= "SPAWN_QUEUE" then
                pending[timer] = nil
                EA_Dirty(true)
                return true
            end

            local char = data.character
            if not char or char == "" then
                pending[timer] = nil
                EA_Dirty(true)
                return true
            end
            if Osi.IsPlayer and Osi.IsPlayer(char) ~= 1 then
                pending[timer] = nil
                EA_Dirty(true)
                return true
            end

            local runtimeReady, _ = EA_IsRuntimeReadyForAmbush(char)
            if not runtimeReady then
                EA_RequeueRuntimeReadyRetry(pending, timer, data, "Spawn queue")
                return true
            end

            local queueAmbushId = EA_GetPendingAmbushId(data)
            local engagedEnemy = EA_FindEngagedSpawnForAmbush(queueAmbushId)
            local allowCombatContinuation = false
            local combatContinuation = nil
            if engagedEnemy then
                local spawnedSoFar = EA_GetSpawnQueueSpawnedCount(data)
                local targetCount = EA_GetSpawnQueueTargetCount(data)
                local nextCombatContinue = (tonumber(data.combatContinueCount) or 0) + 1
                local combatContinueLimit = EA_GetStoredSpawnQueueCombatContinuationLimit(data, spawnedSoFar, targetCount)
                if targetCount > 0 and spawnedSoFar < targetCount and nextCombatContinue <= combatContinueLimit then
                    allowCombatContinuation = true
                    combatContinuation = {
                        ambushId = tostring(queueAmbushId),
                        enemy = tostring(engagedEnemy),
                        spawnedBefore = tonumber(spawnedSoFar) or 0,
                        targetCount = tonumber(targetCount) or 0,
                        nextCount = tonumber(nextCombatContinue) or 0,
                        limit = tonumber(combatContinueLimit) or 0,
                    }
                else
                    local finalizeReason = "target_met"
                    if tonumber(targetCount) and tonumber(targetCount) > 0 and tonumber(spawnedSoFar) < tonumber(targetCount) then
                        finalizeReason = "combat_continue_limit"
                    elseif not tonumber(targetCount) or tonumber(targetCount) <= 0 then
                        finalizeReason = "missing_target"
                    end
                    pending[timer] = nil
                    EA_Dirty(true)
                    EA_LogRestFlow(
                        "spawned",
                        "Spawn queue finalized by combat engagement for %s (ambushId=%s, spawned=%d/%d, enemy=%s, timer=%s, reason=%s)",
                        tostring(char),
                        tostring(queueAmbushId),
                        tonumber(spawnedSoFar) or 0,
                        tonumber(targetCount) or 0,
                        tostring(engagedEnemy),
                        tostring(timer),
                        tostring(finalizeReason)
                    )
                    EA_OnDelayedAmbushComplete(char, data, spawnedSoFar)
                    return true
                end
            end

            if (not allowCombatContinuation) and not IsSafeToSpawnAmbush(char) then
                data.retryCount = (tonumber(data.retryCount) or 0) + 1
                data.timestamp = EA_NowMs()
                pending[timer] = data
                EA_Dirty(true)
                Osi.TimerLaunch(timer, EA_GetRestRetryDelaySeconds() * 1000)
                if data.retryCount == 1 or (data.retryCount % RETRY_LOG_EVERY) == 0 then
                    EA_LogRestFlow(
                        "deferred",
                        "Spawn queue still unsafe for %s (retry=%d, timer=%s)",
                        tostring(char),
                        tonumber(data.retryCount) or 0,
                        tostring(timer)
                    )
                end
                return true
            end

            data.queueState = data.queueState or {}
            local result = ExecuteAmbushSpawn(
                char,
                data.isLongRest == true,
                data.playerLevel,
                data.pointBudget,
                data.duration,
                data.ambushTheme,
                data.firstEnemy,
                data.roll,
                {
                    queueStep = true,
                    queueState = data.queueState,
                    staggerMs = EA_GetStaggerStepMs(data.staggerMs),
                }
            )

            if tonumber(result) == -2 then
                if type(combatContinuation) == "table" then
                    local progressed, spawnedNow = EA_GetSpawnQueueContinuationProgress(combatContinuation.spawnedBefore, data)
                    if progressed then
                        data.combatContinueCount = combatContinuation.nextCount
                        EA_LogRestFlow(
                            "spawned",
                            "Spawn queue continuing during combat for %s (ambushId=%s, spawned=%d/%d, continuation=%d/%d, enemy=%s, timer=%s)",
                            tostring(char),
                            tostring(combatContinuation.ambushId),
                            tonumber(spawnedNow) or 0,
                            tonumber(combatContinuation.targetCount) or 0,
                            tonumber(combatContinuation.nextCount) or 0,
                            tonumber(combatContinuation.limit) or 0,
                            tostring(combatContinuation.enemy),
                            tostring(timer)
                        )
                    elseif EA_IsDebugMode() then
                        DebugPrint(string.format(
                            "[RestFlow] Spawn queue combat continuation made no spawn progress: char=%s ambushId=%s spawned=%d/%d continuation=%d/%d enemy=%s timer=%s",
                            tostring(char),
                            tostring(combatContinuation.ambushId),
                            tonumber(spawnedNow) or 0,
                            tonumber(combatContinuation.targetCount) or 0,
                            tonumber(data.combatContinueCount) or 0,
                            tonumber(combatContinuation.limit) or 0,
                            tostring(combatContinuation.enemy),
                            tostring(timer)
                        ))
                    end
                end
                data.step = (tonumber(data.step) or 0) + 1
                data.retryCount = 0
                data.timestamp = EA_NowMs()
                pending[timer] = data
                EA_Dirty(true)

                local stepMs = EA_GetStaggerStepMs(data.staggerMs)
                local jitter = EA_RandomInt(0, math.max(0, math.floor(stepMs * 0.20)))
                Osi.TimerLaunch(timer, stepMs + jitter)
                return true
            end

            pending[timer] = nil
            EA_Dirty(true)
            EA_OnDelayedAmbushComplete(char, data, result)
        end
        return true
    end

    local function EA_HandleDelayedAmbushTimer(timer)
        local pending = EA_Pending()
        if type(pending) ~= "table" and type(pending) ~= "userdata" then
            EA_RequeueDelayedPendingUnavailableRetry(timer)
            return true
        end
        EA_ClearDelayedPendingUnavailableRetry(timer)
        local ambushData = pending[timer]

        if not ambushData then
            ambushData = EA_RecoverDelayedAmbushPayloadFromMirror(timer, pending)
            if not ambushData then
                if EA_RequeueDelayedPayloadRetry(timer, "payload_missing") then
                    return true
                end
                return true
            end
        end
        EA_ClearDelayedPayloadRetry(timer)

        if (type(ambushData) ~= "table" and type(ambushData) ~= "userdata") or ambushData.kind ~= "SPAWN" then
            EA_ClearDelayedAmbushMirrorForTimer(timer)
            if EA_IsDebugMode() then
                DebugPrint("Delayed ambush timer ignored for non-SPAWN payload:", tostring(timer))
            end
            return true
        end

        local char = ambushData.character
        if not char or char == "" then
            EA_ClearDelayedAmbushMirrorForTimer(timer)
            print(string.format("[EnemyAmbush] Delayed ambush payload had invalid character for timer '%s'.", tostring(timer)))
            return true
        end

        local runtimeReady, _ = EA_IsRuntimeReadyForAmbush(char)
        if not runtimeReady then
            local nextRuntimeReadyRetry = (tonumber(ambushData.runtimeReadyRetries) or 0) + 1
            if nextRuntimeReadyRetry > EA_REHYDRATE_READY_RETRY_MAX then
                EA_ClearDelayedAmbushMirrorForTimer(timer)
            else
                EA_TrackDelayedAmbushMirror(timer, ambushData)
            end
            EA_RequeueRuntimeReadyRetry(pending, timer, ambushData, "Delayed ambush")
            return true
        end

        pending[timer] = nil
        if EA_Dirty then EA_Dirty(true) end

        if Osi.IsPlayer(char) == 1 and IsSafeToSpawnAmbush(char) then
            local staggerConfigured = ((EA and EA.CFG and EA.CFG.SPAWN_STAGGER_ENABLED) ~= false)
            local staggerMs = EA_GetStaggerStepMs((EA and EA.CFG and EA.CFG.SPAWN_STAGGER_MS) or EA_STAGGER_STEP_MS_DEFAULT)

            if staggerConfigured then
                local queueTimer = string.format("%s%s_%d", TIMER_PREFIX_SPAWNQ, tostring(char), Ext.Utils.MonotonicTime())
                pending[queueTimer] = {
                    kind = "SPAWN_QUEUE",
                    character = char,
                    isLongRest = (ambushData.isLongRest == true),
                    triggerKind = EA_GetPendingFlowKind(ambushData),
                    flowLabel = EA_GetPendingFlowLabel(ambushData),
                    playerLevel = ambushData.playerLevel,
                    pointBudget = ambushData.pointBudget,
                    duration = ambushData.duration,
                    ambushTheme = ambushData.ambushTheme,
                    firstEnemy = ambushData.firstEnemy,
                    roll = ambushData.roll,
                    queueState = {},
                    staggerMs = staggerMs,
                    step = 0,
                    retryCount = 0,
                    combatContinueCount = 0,
                    timestamp = EA_NowMs(),
                }
                EA_Dirty()
                EA_ClearDelayedAmbushMirrorForTimer(timer)
                Osi.TimerLaunch(queueTimer, math.max(EA_STAGGER_QUEUE_INITIAL_DELAY_MIN_MS, staggerMs))
                EA_LogRestFlow(
                    "spawned",
                    "Delayed ambush queued for persistent stagger: %s (%s, %dms step, timer=%s)",
                    tostring(char),
                    EA_GetPendingFlowLabel(ambushData),
                    staggerMs,
                    tostring(queueTimer)
                )
                return true
            end

            local spawnedCount = ExecuteAmbushSpawn(
                char,
                ambushData.isLongRest,
                ambushData.playerLevel,
                ambushData.pointBudget,
                ambushData.duration,
                ambushData.ambushTheme,
                ambushData.firstEnemy,
                ambushData.roll,
                {
                    staggerEnabled = false,
                }
            )
            EA_OnDelayedAmbushComplete(char, ambushData, spawnedCount)
            EA_ClearDelayedAmbushMirrorForTimer(timer)
        else
            ambushData.retryCount = (tonumber(ambushData.retryCount) or 0) + 1
            local retryTimer = string.format("%s%s_%d", TIMER_PREFIX_AMBUSH_DELAYED, tostring(char), Ext.Utils.MonotonicTime())
            ambushData.timestamp = EA_NowMs()
            ambushData.timer = retryTimer
            pending[retryTimer] = ambushData
            EA_Dirty()
            EA_TrackDelayedAmbushMirror(retryTimer, ambushData)
            local retryDelaySec = EA_GetRestRetryDelaySeconds()
            Osi.TimerLaunch(retryTimer, retryDelaySec * 1000)

            if ambushData.retryCount <= DELAYED_AMBUSH_RETRY_MAX then
                EA_LogRestFlow(
                    "deferred",
                    "Delayed ambush deferred for %s retry %d/%d in %ds (%s)",
                    tostring(char),
                    ambushData.retryCount,
                    DELAYED_AMBUSH_RETRY_MAX,
                    retryDelaySec,
                    tostring(retryTimer)
                )
            elseif (ambushData.retryCount % RETRY_LOG_EVERY) == 0 then
                EA_LogRestFlow(
                    "deferred",
                    "Delayed ambush still queued for %s (retry=%d, timer=%s)",
                    tostring(char),
                    ambushData.retryCount,
                    tostring(retryTimer)
                )
            end
        end

        return true
    end

    local function EA_HandleDespawnTimer(timer)
        local ent = timer:match("^" .. TIMER_PREFIX_DESPAWN .. "(.+)$")
        if ent then
            local alive = (not Osi.IsDead) or (Osi.IsDead(ent) ~= 1)

            local function HasAnyStatus(statuses)
                if not Osi.HasActiveStatus then return false, nil end
                for i = 1, #statuses do
                    local s = statuses[i]
                    if s and s ~= "" and Osi.HasActiveStatus(ent, s) == 1 then
                        return true, s
                    end
                end
                return false, nil
            end

            local norm = EA_NormalizeUUID(ent) or ent
            local spawned = EA_Spawned()
            if type(spawned) ~= "table" and type(spawned) ~= "userdata" then
                return true
            end
            local data = spawned[norm] or spawned[ent]

            local tier = data and data.tier or nil
            local isChamp = data and data.isChampion == true

            if not isChamp then
                local championStatuses = {
                    "EA_CHAMPION_BASE_L1", "EA_CHAMPION_BASE_L7", "EA_CHAMPION_BASE_L11",
                    "EA_CHAMPION_BASE_CX_L1", "EA_CHAMPION_BASE_CX_L7", "EA_CHAMPION_BASE_CX_L11",
                    "EA_CHAMPION_ABERRATION", "EA_CHAMPION_BEAST", "EA_CHAMPION_CELESTIAL",
                    "EA_CHAMPION_CONSTRUCT", "EA_CHAMPION_DRAGON", "EA_CHAMPION_ELEMENTAL",
                    "EA_CHAMPION_FEY", "EA_CHAMPION_FIEND", "EA_CHAMPION_GIANT",
                    "EA_CHAMPION_HUMANOID", "EA_CHAMPION_MONSTROSITY", "EA_CHAMPION_OOZE",
                    "EA_CHAMPION_PLANT", "EA_CHAMPION_UNDEAD",
                }
                local hasChamp = HasAnyStatus(championStatuses)
                isChamp = (hasChamp == true)
            end

            if not tier then
                local legendaryTierStatuses = {
                    "EA_TIER_LEGENDARY_L1", "EA_TIER_LEGENDARY_L5", "EA_TIER_LEGENDARY_L11", "EA_TIER_LEGENDARY_L15",
                    "EA_TIER_LEGENDARY_CX_L1", "EA_TIER_LEGENDARY_CX_L11",
                }
                local eliteTierStatuses = {
                    "EA_TIER_ELITE_L1", "EA_TIER_ELITE_L5", "EA_TIER_ELITE_L9", "EA_TIER_ELITE_L12", "EA_TIER_ELITE_L15",
                    "EA_TIER_ELITE_CX_L1", "EA_TIER_ELITE_CX_L9", "EA_TIER_ELITE_CX_L12",
                }
                local veteranTierStatuses = {
                    "EA_TIER_VETERAN_L1", "EA_TIER_VETERAN_L5", "EA_TIER_VETERAN_L7", "EA_TIER_VETERAN_L11", "EA_TIER_VETERAN_L15",
                    "EA_TIER_VETERAN_CX_L1", "EA_TIER_VETERAN_CX_L7", "EA_TIER_VETERAN_CX_L11",
                }
                local commonTierStatuses = {
                    "EA_TIER_COMMON_L1", "EA_TIER_COMMON_L5", "EA_TIER_COMMON_L7", "EA_TIER_COMMON_L11", "EA_TIER_COMMON_L15",
                    "EA_TIER_COMMON_CX_L1", "EA_TIER_COMMON_CX_L7", "EA_TIER_COMMON_CX_L11",
                }

                if HasAnyStatus(legendaryTierStatuses) then
                    tier = "LEGENDARY"
                elseif HasAnyStatus(eliteTierStatuses) then
                    tier = "ELITE"
                elseif HasAnyStatus(veteranTierStatuses) then
                    tier = "VETERAN"
                elseif HasAnyStatus(commonTierStatuses) then
                    tier = "COMMON"
                end
            end

            if EA_ShouldLogDespawn(ent, "fired", 120000) then
                DebugPrint("Despawn timer fired:", tostring(ent), "alive=", tostring(alive), "tier=", tostring(tier), "champ=", tostring(isChamp))
            end

            local inCombat = (Osi.IsInCombat and Osi.IsInCombat(ent) == 1)
            if alive and inCombat then
                if Osi.TimerLaunch then
                    Osi.TimerLaunch(timer, 15000)
                end
                if EA_ShouldLogDespawn(ent, "deferred", 120000) then
                    DebugPrint("Despawn deferred (in combat):", tostring(ent))
                end
                return true
            end

            if alive then
                local despawnVFX = (data and data.despawnVFX) or EnemyData.DEFAULT_DESPAWN_VFX
                PlayVFX_OnEntity(ent, despawnVFX)
                EA_PlaySoundEvent(EA_DESPAWN_FADE_SOUND, ent)
            end

            EA_ClearHostileState(ent)
            if norm then EA_ClearHostileState(norm) end

            if norm then spawned[norm] = nil end
            spawned[ent] = nil
            if type(EnemyAmbush._CombatKeyByAmbusher) == "table" then
                EnemyAmbush._CombatKeyByAmbusher[ent] = nil
                if norm then
                    EnemyAmbush._CombatKeyByAmbusher[norm] = nil
                end
            end
            if type(EnemyAmbush._CombatKeyByMember) == "table" then
                EnemyAmbush._CombatKeyByMember[ent] = nil
                if norm then
                    EnemyAmbush._CombatKeyByMember[norm] = nil
                end
            end
            EA_Dirty()

            if Osi.TimerLaunch then
                Osi.TimerLaunch(string.format("%s%s", TIMER_PREFIX_DELETE, ent), alive and 1000 or 100)
            end
        end
        return true
    end

    local function EA_HandleDeleteTimer(timer)
        local ent = timer:match("^" .. TIMER_PREFIX_DELETE .. "(.+)$")
        if ent then
            local exists = true
            if Osi.ObjectExists then
                exists = (Osi.ObjectExists(ent) == 1)
            end
            if exists then
                SafeOsiExec(Osi.RequestDelete, ent)
            end
        end
        return true
    end

    local EA_TIMER_PREFIX_HANDLERS = {
        { name = "short_rest_retry", prefix = TIMER_PREFIX_SHORT_RETRY, handle = EA_HandleShortRestRetryTimer },
        { name = "short_rest", prefix = TIMER_PREFIX_SHORT_REST, handle = EA_HandleShortRestTimer },
        { name = "long_rest_retry", prefix = TIMER_PREFIX_LONG_RETRY, handle = EA_HandleLongRestRetryTimer },
        { name = "long_rest", prefix = TIMER_PREFIX_LONG_REST, handle = EA_HandleLongRestTimer },
        { name = "rest_defer", prefix = TIMER_PREFIX_REST_DEFER, handle = EA_HandleRestDeferredTimer },
        { name = "spawn_queue", prefix = TIMER_PREFIX_SPAWNQ, handle = EA_HandleSpawnQueueTimer },
        { name = "delayed_ambush", prefix = TIMER_PREFIX_AMBUSH_DELAYED, handle = EA_HandleDelayedAmbushTimer },
        { name = "despawn", prefix = TIMER_PREFIX_DESPAWN, handle = EA_HandleDespawnTimer },
        { name = "delete", prefix = TIMER_PREFIX_DELETE, handle = EA_HandleDeleteTimer },
    }

    local function EA_DispatchPrefixTimer(timer)
        for i = 1, #EA_TIMER_PREFIX_HANDLERS do
            local entry = EA_TIMER_PREFIX_HANDLERS[i]
            if EA_HasPrefix(timer, entry.prefix) then
                return entry.handle(timer) == true
            end
        end
        return false
    end
    
    EA_P0Inc("listenerReg.TimerFinished.after")
    Ext.Osiris.RegisterListener("TimerFinished", 1, "after", function(timer)
        if not Ext.IsServer() then return end
        if not timer then return end
        timer = tostring(timer)
        local ownedTimer = (EventsTimerRouter and type(EventsTimerRouter.IsOwnedTimer) == "function")
            and EventsTimerRouter.IsOwnedTimer(timer)
            or EA_HasPrefix(timer, TIMER_PREFIX_OWNED)
        if not ownedTimer then
            return
        end
        if EA_TryHandlePersistentHostileRetry(timer) then
            return
        end

        if EA_DispatchExactTimer(timer) then
            return
        end

        if EA_TryHandleApproachBeatTimer(timer) then
            return
        end

        if EA_TryHandleScenarioBootstrapTimer(timer) then
            return
        end

        if EA_DispatchPrefixTimer(timer) then
            return
        end
    end)
    end

    function Runtime.GetScenarioSessionLoadedHandler()
        return EA_OnScenarioBootstrapSessionLoaded
    end

    function Runtime.GetScenarioTimerHandler()
        return EA_HandleScenarioBootstrapTimer
    end

    return Runtime
end

return M
