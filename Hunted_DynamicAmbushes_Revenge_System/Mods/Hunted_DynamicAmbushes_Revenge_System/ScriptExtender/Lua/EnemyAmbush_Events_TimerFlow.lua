EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

function M.Build(deps)
    deps = deps or {}
    local EnemyAmbush = deps.EnemyAmbush or EA
    local EA = deps.EA or EnemyAmbush or {}
    local DebugPrint = deps.DebugPrint or function() end
    local EA_Spawned = deps.EA_Spawned or function() return {} end
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local EA_Dirty = deps.EA_Dirty or function() end
    local EA_EvictOldSpawned = deps.EA_EvictOldSpawned or function() end
    local EA_AggressiveSpawnedCleanup = deps.EA_AggressiveSpawnedCleanup
    local EA_PruneRuntimeCombatState = deps.EA_PruneRuntimeCombatState or function() end
    local EA_GetEncounterRepState = deps.EA_GetEncounterRepState or function() return {} end
    local EA_IsAnyPartyInCombat = deps.EA_IsAnyPartyInCombat or function() return false end
    local EA_MarkRuntimeStateDirty = deps.EA_MarkRuntimeStateDirty or function() end
    local EA_GetSettingBoolEvent = deps.EA_GetSettingBoolEvent or function(_, fallback) return fallback == true end
    local EA_GetSettingNumberEvent = deps.EA_GetSettingNumberEvent or function(_, fallback) return tonumber(fallback) or 0 end
    local EA_ReputationTable = deps.EA_ReputationTable or function() return {} end
    local SaveReputation = deps.SaveReputation
    local CleanupPendingAmbushes = deps.CleanupPendingAmbushes or function() end
    local EA_NormalizeUUID = deps.EA_NormalizeUUID or function(v) return v end
    local EA_AmbushPressure = deps.EA_AmbushPressure or function() return {} end
    local EA_GetCooldownEnabled = deps.EA_GetCooldownEnabled or function() return false end
    local EA_PersistedNowMs = deps.EA_PersistedNowMs
    local EA_LastAmbushTime = deps.EA_LastAmbushTime or function() return {} end
    local EA_DebugEnabled = deps.EA_DebugEnabled or function() return false end
    local EA_LogRestFlow = deps.EA_LogRestFlow or function() end
    local EA_TickTimeInDangerRisk = deps.EA_TickTimeInDangerRisk
    local EA_TryTriggerTravelDangerAmbush = deps.EA_TryTriggerTravelDangerAmbush
    local EA_GetPostLoadAmbushGraceState = deps.EA_GetPostLoadAmbushGraceState or (EA and EA["EA_GetPostLoadAmbushGraceState"]) or function()
        return { active = false }
    end
    local EA_GetPostCombatAmbushGraceState = deps.EA_GetPostCombatAmbushGraceState or (EA and EA["EA_GetPostCombatAmbushGraceState"]) or function()
        return { active = false }
    end
    local EA_GetCampExitAmbushGraceState = deps.EA_GetCampExitAmbushGraceState or (EA and EA["EA_GetCampExitAmbushGraceState"]) or function()
        return { active = false }
    end
    local EA_UpdateCampExitAmbushGraceForCharacter = deps.EA_UpdateCampExitAmbushGraceForCharacter or (EA and EA["EA_UpdateCampExitAmbushGraceForCharacter"]) or nil
    local EA_GetDialogueSafetyState = deps.EA_GetDialogueSafetyState or (EA and EA["EA_GetDialogueSafetyState"]) or function()
        return { blocked = false }
    end
    local EA_DiagRecordRuntimeBlock = deps.EA_DiagRecordRuntimeBlock or (EA and EA["EA_DiagRecordRuntimeBlock"]) or function() return false end
    local LONG_REST_SAFETY_DELAY = tonumber(deps.LONG_REST_SAFETY_DELAY) or 30
    local EA_REHYDRATE_READY_RETRY_MAX = tonumber(deps.EA_REHYDRATE_READY_RETRY_MAX) or 30
    local EA_REHYDRATE_READY_RETRY_MS = tonumber(deps.EA_REHYDRATE_READY_RETRY_MS) or 1000
    local EA_STAGGER_STEP_MS_MIN = tonumber(deps.EA_STAGGER_STEP_MS_MIN) or 20
    local EA_STAGGER_STEP_MS_DEFAULT = tonumber(deps.EA_STAGGER_STEP_MS_DEFAULT) or 100
    local EA_STAGGER_STEP_MS_MAX = tonumber(deps.EA_STAGGER_STEP_MS_MAX) or 500

    local Runtime = {}

    local function EA_GetSpawnedRegistry()
        local spawned = EA_Spawned()
        if type(spawned) ~= "table" and type(spawned) ~= "userdata" then
            return nil
        end
        return spawned
    end

    local function EA_GetAmbushPressureRegistry()
        local pressure = EA_AmbushPressure()
        if type(pressure) ~= "table" and type(pressure) ~= "userdata" then
            return nil
        end
        return pressure
    end

    local function EA_GetLastAmbushTimeRegistry()
        local last = EA_LastAmbushTime()
        if type(last) ~= "table" and type(last) ~= "userdata" then
            return nil
        end
        return last
    end

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

    function Runtime.HandleTimerValidateSpawned()
        local spawned = EA_GetSpawnedRegistry()
        if not spawned then
            if Osi.TimerLaunch then
                Osi.TimerLaunch("EA_VALIDATE_SPAWNED", 300000)
            end
            return
        end
        local cleanedDead = 0

        local keys = {}
        for uuid, _ in pairs(spawned) do
            keys[#keys + 1] = uuid
        end

        for _, uuid in ipairs(keys) do
            local data = spawned[uuid]
            if data and Osi.ObjectExists and Osi.ObjectExists(uuid) == 1 then
                data.lastSeen = EA_NowMs()
                if Osi.IsDead and Osi.IsDead(uuid) == 1 then
                    spawned[uuid] = nil
                    cleanedDead = cleanedDead + 1
                end
            end
        end

        if cleanedDead > 0 then
            EA_Dirty()
            DebugPrint("Validated spawned enemies, removed dead:", cleanedDead)
        end

        EA_EvictOldSpawned(spawned)
        if EA_AggressiveSpawnedCleanup then
            EA_AggressiveSpawnedCleanup()
        end
        if Osi.TimerLaunch then
            Osi.TimerLaunch("EA_VALIDATE_SPAWNED", 300000)
        end
    end

    function Runtime.HandleTimerRuntimeCombatPrune()
        EA_PruneRuntimeCombatState("periodic_timer")
        if type(EA_TickTimeInDangerRisk) == "function" then
            local okTick, tickErr = pcall(EA_TickTimeInDangerRisk, {
                source = "EA_RUNTIME_COMBAT_PRUNE",
                nowMs = EA_NowMs(),
            })
            if not okTick and EA_DebugEnabled() then
                DebugPrint(string.format("[Risk] time_in_danger tick failed: %s", tostring(tickErr)))
            end
        end
        if type(EA_TryTriggerTravelDangerAmbush) == "function" then
            local okTravel, travelReason = pcall(EA_TryTriggerTravelDangerAmbush, {
                source = "EA_RUNTIME_COMBAT_PRUNE",
                nowMs = EA_NowMs(),
            })
            if not okTravel and EA_DebugEnabled() then
                DebugPrint(string.format("[Risk] travel_check failed: %s", tostring(travelReason)))
            end
        end
        if Osi.TimerLaunch then
            Osi.TimerLaunch("EA_RUNTIME_COMBAT_PRUNE", 30000)
        end
    end

    function Runtime.HandleTimerEncounterRepWatch()
        local encounter = EA_GetEncounterRepState()

        if encounter.active ~= true then
            return
        end

        if not EA_IsAnyPartyInCombat() then
            encounter.perType = {}
            encounter.active = false
            encounter.updatedAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
            EA_MarkRuntimeStateDirty(true)
            DebugPrint("Encounter rep reset (combat ended)")
            return
        end

        encounter.updatedAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
        EA_MarkRuntimeStateDirty()
        Osi.TimerLaunch("EA_ENCOUNTER_REP_WATCH", 5000)
    end

    function Runtime.HandleTimerReputationDecay()
        local inCombat = (type(EA_IsAnyPartyInCombat) == "function") and (EA_IsAnyPartyInCombat() == true) or false
        if inCombat then
            Osi.TimerLaunch("EA_REPUTATION_DECAY", 60000)
            return
        end

        local reputationEnabled = EA_GetSettingBoolEvent("MCM_EnableReputation", true)
        local decayRate = EA_GetSettingNumberEvent("MCM_ReputationDecayRate", 0.5)
        if reputationEnabled and decayRate > 0 then
            local repTable = EA_ReputationTable()
            local changed = false
            for creatureType, rep in pairs(repTable) do
                local repValue = tonumber(rep)
                if repValue and repValue < 0 then
                    local newRep = repValue + decayRate
                    local clamped = math.floor(math.min(0, newRep) * 10 + 0.5) / 10
                    if clamped ~= repValue then
                        repTable[creatureType] = clamped
                        changed = true
                    end
                end
            end
            if changed and type(SaveReputation) == "function" then
                SaveReputation()
                DebugPrint("Reputation decay applied")
            end
        end
        Osi.TimerLaunch("EA_REPUTATION_DECAY", 300000)
    end

    function Runtime.HandleTimerCleanupPending()
        CleanupPendingAmbushes()
        Osi.TimerLaunch("EA_CLEANUP_PENDING", 60000)
    end

    function Runtime.GetStaggerStepMs(raw)
        return math.floor(math.max(EA_STAGGER_STEP_MS_MIN, math.min(EA_STAGGER_STEP_MS_MAX, tonumber(raw) or EA_STAGGER_STEP_MS_DEFAULT)))
    end

    function Runtime.OnDelayedAmbushComplete(char, ambushData, spawnedCount)
        local resolvedCount = tonumber(spawnedCount) or 0
        local flowKind = EA_GetPendingFlowKind(ambushData)
        local flowLabel = EA_GetPendingFlowLabel(ambushData)
        local recSpawn = EA and EA["EA_RecordRestSpawn"]
        if (flowKind == "long" or flowKind == "short") and type(recSpawn) == "function" then
            recSpawn(ambushData and ambushData.isLongRest == true, resolvedCount, char)
        end
        if resolvedCount > 0 then
            local key = EA_NormalizeUUID(char) or char
            local pressure = EA_GetAmbushPressureRegistry()
            if pressure then
                pressure[key] = 0
            end

            if EA_GetCooldownEnabled() then
                local now = (type(EA_PersistedNowMs) == "function") and EA_PersistedNowMs() or nil
                local last = EA_GetLastAmbushTimeRegistry()
                if now then
                    if last then
                        last[key] = now
                    end
                else
                    EnemyAmbush._eaDelayedCooldownStampRetry = EnemyAmbush._eaDelayedCooldownStampRetry or {}
                    local slot = EnemyAmbush._eaDelayedCooldownStampRetry[key]
                    if type(slot) ~= "table" then
                        slot = { tries = 0, active = false, character = char }
                        EnemyAmbush._eaDelayedCooldownStampRetry[key] = slot
                    end
                    if not slot.active and Ext and Ext.Timer and Ext.Timer.WaitFor then
                        slot.active = true
                        local function RetryDelayedCooldownStamp()
                            slot.tries = (tonumber(slot.tries) or 0) + 1
                            local nowRetry = (type(EA_PersistedNowMs) == "function") and EA_PersistedNowMs() or nil
                            local lastRetry = EA_GetLastAmbushTimeRegistry()
                            if nowRetry then
                                if lastRetry then
                                    lastRetry[key] = nowRetry
                                    EA_Dirty()
                                    EnemyAmbush._eaDelayedCooldownStampRetry[key] = nil
                                    if EA_DebugEnabled() then
                                        DebugPrint("Delayed ambush cooldown stamp retry succeeded for", tostring(slot.character or key), "attempt=", tostring(slot.tries))
                                    end
                                    return
                                end
                            end
                            if (tonumber(slot.tries) or 0) >= 120 then
                                slot.active = false
                                if EA_DebugEnabled() then
                                    DebugPrint("Delayed ambush cooldown stamp retry exhausted for", tostring(slot.character or key))
                                end
                                return
                            end
                            Ext.Timer.WaitFor(500, RetryDelayedCooldownStamp)
                        end
                        Ext.Timer.WaitFor(500, RetryDelayedCooldownStamp)
                    end
                    if EA_DebugEnabled() then
                        DebugPrint("Delayed ambush cooldown stamp skipped: persisted game-time unavailable for", tostring(char))
                    end
                end
            end

            EA_Dirty()
            EA_LogRestFlow(
                "spawned",
                "Delayed ambush spawned %d entities for %s (%s)",
                resolvedCount,
                tostring(char),
                flowLabel
            )
        else
            EA_LogRestFlow("spawned", "Delayed ambush executed but spawned 0 entities for %s", tostring(char))
        end
    end

    function Runtime.IsRuntimeReadyForAmbush(character)
        if not character or character == "" then
            return false, "missing_character"
        end
        if Osi and Osi.IsGameStateRunning then
            local okRunning, running = pcall(Osi.IsGameStateRunning)
            if (not okRunning) or running ~= 1 then
                return false, "game_state_not_running"
            end
        end
        local graceState = EA_GetPostLoadAmbushGraceState()
        if type(graceState) == "table" and graceState.active == true then
            pcall(EA_DiagRecordRuntimeBlock, "post_load_grace", {
                stage = "runtime_ready",
                character = tostring(character),
                remainingMs = tonumber(graceState.remainingMs) or 0,
                graceMs = tonumber(graceState.graceMs) or 0,
                source = tostring(graceState.reason or ""),
            })
            return false, "post_load_grace"
        end
        local postCombatGraceState = EA_GetPostCombatAmbushGraceState(character)
        if type(postCombatGraceState) == "table" and postCombatGraceState.active == true then
            pcall(EA_DiagRecordRuntimeBlock, "post_combat_grace", {
                stage = "runtime_ready",
                character = tostring(character),
                remainingMs = tonumber(postCombatGraceState.remainingMs) or 0,
                graceMs = tonumber(postCombatGraceState.graceMs) or 0,
                source = tostring(postCombatGraceState.reason or ""),
            })
            return false, "post_combat_grace"
        end
        local campExitGraceState = nil
        if type(EA_UpdateCampExitAmbushGraceForCharacter) == "function" then
            local okCampExit, _, state = pcall(EA_UpdateCampExitAmbushGraceForCharacter, character, EA_NowMs(), "camp_exit")
            if okCampExit and type(state) == "table" then
                campExitGraceState = state
            end
        end
        if type(campExitGraceState) ~= "table" then
            campExitGraceState = EA_GetCampExitAmbushGraceState(character)
        end
        if type(campExitGraceState) == "table" and campExitGraceState.active == true then
            pcall(EA_DiagRecordRuntimeBlock, "camp_exit_grace", {
                stage = "runtime_ready",
                character = tostring(character),
                remainingMs = tonumber(campExitGraceState.remainingMs) or 0,
                graceMs = tonumber(campExitGraceState.graceMs) or 0,
                source = tostring(campExitGraceState.reason or ""),
            })
            return false, "camp_exit_grace"
        end
        if Osi and Osi.ObjectExists and Osi.ObjectExists(character) ~= 1 then
            return false, "character_not_ready"
        end
        local dialogueState = EA_GetDialogueSafetyState(character)
        if type(dialogueState) == "table" and dialogueState.blocked == true then
            pcall(EA_DiagRecordRuntimeBlock, "dialog_or_cutscene", {
                stage = "runtime_ready",
                character = tostring(character),
                actor = tostring(dialogueState.actor or ""),
                source = tostring(dialogueState.source or ""),
                checkedActors = tonumber(dialogueState.checkedActors) or 0,
            })
            return false, "dialog_or_cutscene"
        end
        return true, "ok"
    end

    local function EA_GetRuntimeReadyRetryPolicy(data, reason)
        local token = tostring(reason or "runtime_not_ready")
        local retryDelayMs = EA_REHYDRATE_READY_RETRY_MS
        local retryLimit = EA_REHYDRATE_READY_RETRY_MAX

        if token == "post_combat_grace" then
            local state = EA_GetPostCombatAmbushGraceState(type(data) == "table" and data.character or nil)
            local remainingMs = tonumber(type(state) == "table" and state.remainingMs or nil) or 0
            retryDelayMs = math.max(1000, math.min(5000, remainingMs + 250))
            retryLimit = math.max(retryLimit, math.ceil((remainingMs + 120000) / retryDelayMs))
        elseif token == "dialog_or_cutscene" then
            retryDelayMs = 2000
            retryLimit = math.max(retryLimit, 180)
        elseif token == "post_load_grace" then
            local state = EA_GetPostLoadAmbushGraceState()
            local remainingMs = tonumber(type(state) == "table" and state.remainingMs or nil) or 0
            retryDelayMs = math.max(1000, math.min(5000, remainingMs + 250))
            retryLimit = math.max(retryLimit, math.ceil((remainingMs + 60000) / retryDelayMs))
        elseif token == "camp_exit_grace" then
            local state = EA_GetCampExitAmbushGraceState(type(data) == "table" and data.character or nil)
            local remainingMs = tonumber(type(state) == "table" and state.remainingMs or nil) or 0
            retryDelayMs = math.max(1000, math.min(5000, remainingMs + 250))
            retryLimit = math.max(retryLimit, math.ceil((remainingMs + 60000) / retryDelayMs))
        elseif token == "safe_zone_block" or token == "raw_safe_zone_block" then
            retryDelayMs = 5000
            retryLimit = math.max(retryLimit, 240)
        elseif token == "character_not_ready" or token == "game_state_not_running" then
            retryDelayMs = 1000
            retryLimit = math.max(retryLimit, 60)
        end

        local storedLimit = tonumber(type(data) == "table" and data.runtimeReadyRetryLimit or nil) or 0
        if storedLimit > retryLimit then
            retryLimit = storedLimit
        end
        return math.max(1, math.floor(retryDelayMs)), math.max(1, math.floor(retryLimit))
    end

    function Runtime.RequeueRuntimeReadyRetry(pending, timer, data, stage, reason)
        if type(pending) ~= "table" and type(pending) ~= "userdata" then
            return false
        end
        if type(data) ~= "table" and type(data) ~= "userdata" then
            return false
        end
        data.lastRuntimeReadyReason = tostring(reason or data.lastRuntimeReadyReason or "runtime_not_ready")
        data.lastRuntimeReadyAtMs = EA_NowMs()
        local retryDelayMs, retryLimit = EA_GetRuntimeReadyRetryPolicy(data, data.lastRuntimeReadyReason)
        data.runtimeReadyRetryLimit = retryLimit
        data.runtimeReadyRetries = (tonumber(data.runtimeReadyRetries) or 0) + 1
        if data.runtimeReadyRetries > retryLimit then
            pending[timer] = nil
            if EA_Dirty then EA_Dirty(true) end
            EA_LogRestFlow(
                "deferred",
                "%s dropped after runtime-ready retries exhausted timer=%s reason=%s retries=%d/%d",
                tostring(stage or "rehydrate"),
                tostring(timer),
                tostring(data.lastRuntimeReadyReason),
                tonumber(data.runtimeReadyRetries) or 0,
                tonumber(retryLimit) or 0
            )
            return true
        end
        data.timestamp = EA_NowMs()
        pending[timer] = data
        if EA_Dirty then EA_Dirty(true) end
        Osi.TimerLaunch(timer, retryDelayMs)
        if data.runtimeReadyRetries == 1 or (data.runtimeReadyRetries % 5) == 0 then
            EA_LogRestFlow(
                "deferred",
                "%s waiting for runtime-ready timer=%s reason=%s retry=%d/%d delayMs=%d",
                tostring(stage or "rehydrate"),
                tostring(timer),
                tostring(data.lastRuntimeReadyReason),
                tonumber(data.runtimeReadyRetries) or 0,
                tonumber(retryLimit) or 0,
                tonumber(retryDelayMs) or 0
            )
        end
        return true
    end

    return Runtime
end

return M
