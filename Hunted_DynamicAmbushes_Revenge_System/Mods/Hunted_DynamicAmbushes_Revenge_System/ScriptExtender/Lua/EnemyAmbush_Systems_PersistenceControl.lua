EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

function M.Build(deps)
    deps = deps or {}
    local EnemyAmbush = deps.EnemyAmbush or EA
    local EA = deps.EA or EnemyAmbush or {}
    local GetTableSize = deps.GetTableSize or function(t)
        local count = 0
        for _ in pairs(t or {}) do
            count = count + 1
        end
        return count
    end
    local EA_Pending = deps.EA_Pending or function()
        return nil
    end
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local EA_Dirty = deps.EA_Dirty or function() end
    local EA_IsRobust = deps.EA_IsRobust or function() return false end
    local ModuleUUID = deps.ModuleUUID
    local EA_Vars = deps.EA_Vars
    local EA_IsModVarsContainer = deps.EA_IsModVarsContainer
    local EA_IsDebugMode = deps.EA_IsDebugMode or function() return false end
    local DebugPrint = deps.DebugPrint or function() end
    local CreatureReputation = deps.CreatureReputation or {}
    local REPUTATION_THRESHOLDS = deps.REPUTATION_THRESHOLDS or {}
    local EA_ModVarsReady = deps.EA_ModVarsReady or (EA and EA["EA_ModVarsReady"])
    local EA_GetModVarsReadyDiagnostics = deps.EA_GetModVarsReadyDiagnostics or (EA and EA["EA_GetModVarsReadyDiagnostics"])
    local EA_P0Inc = deps.EA_P0Inc or (EA and EA["EA_P0Inc"]) or function() return 0 end
    local EA_FlushPoolCacheState = deps.EA_FlushPoolCacheState or (EA and EA["EA_FlushPoolCacheState"]) or function() end

    local runtime = {}

    local EA_PENDING_CAP = tonumber(deps.EA_PENDING_CAP) or 80
    local EA_PENDING_TTL_MS = tonumber(deps.EA_PENDING_TTL_MS) or 120000
    local EA_REST_RETRY_DELAY_MS = tonumber(deps.EA_REST_RETRY_DELAY_MS) or 30000
    local TIMER_PREFIX_REST_DEFER = tostring(deps.TIMER_PREFIX_REST_DEFER or "EA_REST_DEFER_")
    local EA_PENDING_RELAUNCH_RETRY_MAX = tonumber(deps.EA_PENDING_RELAUNCH_RETRY_MAX) or 20
    local EA_PENDING_RELAUNCH_RETRY_MS = tonumber(deps.EA_PENDING_RELAUNCH_RETRY_MS) or 500
    local _eaPendingStoreUnavailableReason = nil
    local _eaPendingStoreUnavailableAt = 0
    local _eaPendingRelaunchCompleted = false
    local _eaPendingRelaunchQueued = false
    local _eaPendingRelaunchAttempts = 0

    local function EA_GetRestRetryDelayMs()
        local quickTestFn = deps.EA_IsQuickTestMode or (EA and EA["EA_IsQuickTestMode"])
        if type(quickTestFn) == "function" then
            local ok, quick = pcall(quickTestFn)
            if ok and quick == true then
                return 3000
            end
        end
        return EA_REST_RETRY_DELAY_MS
    end

    local function EA_HasPersistentContainer(value)
        if type(EA_IsModVarsContainer) == "function" then
            return EA_IsModVarsContainer(value)
        end
        local t = type(value)
        return t == "table" or t == "userdata"
    end

    local function EA_ReportPendingStoreUnavailable(context)
        EA_P0Inc("readiness.pendingStoreUnavailable")
        if not EA_IsDebugMode() then
            return
        end
        local diagFn = EA_GetModVarsReadyDiagnostics or (EA and EA["EA_GetModVarsReadyDiagnostics"])
        local diag = (type(diagFn) == "function") and diagFn() or nil
        local reason = tostring(diag and diag.reason or "unknown")
        local detail = tostring(diag and diag.detail or "")
        local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
        if reason == _eaPendingStoreUnavailableReason and now > 0 and (now - (_eaPendingStoreUnavailableAt or 0)) < 10000 then
            return
        end
        _eaPendingStoreUnavailableReason = reason
        _eaPendingStoreUnavailableAt = now
        DebugPrint(
            string.format("%s skipped: PersistentPendingAmbushes unavailable", tostring(context or "Pending persistence")),
            "reason=", reason,
            "detail=", detail
        )
    end

    local function EA_GetPersistentPendingStore(context)
        local pending = EA_Pending()
        if not EA_HasPersistentContainer(pending) then
            EA_ReportPendingStoreUnavailable(context)
            return nil
        end
        return pending
    end

    local function EA_GetPersistentPendingStoreIfPresent()
        local vars = (type(EA_Vars) == "function") and EA_Vars() or nil
        if not EA_HasPersistentContainer(vars) then
            return nil
        end
        local pending = vars.PersistentPendingAmbushes
        if not EA_HasPersistentContainer(pending) then
            return nil
        end
        return pending
    end

    local function EA_GetDeferredRestMirrorIfPresent()
        local vars = (type(EA_Vars) == "function") and EA_Vars() or nil
        if not EA_HasPersistentContainer(vars) then
            return nil
        end
        local mirror = vars.EA_RestDeferredState
        if not EA_HasPersistentContainer(mirror) then
            return nil
        end
        if type(mirror.timer) ~= "string" or mirror.timer == "" then
            return nil
        end
        return mirror
    end

    local _eaCacheRebuildQueued = false
    local _eaCacheRebuildAgain = false
    local _eaCacheRebuildReasons = {}
    local _eaCacheRebuildHard = false

    local function CleanupPendingAmbushes(forceCap)
        local pending = EA_GetPersistentPendingStoreIfPresent()
        if not pending then
            return
        end
        local now = EA_NowMs()
        local nowMono = 0
        if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
            nowMono = tonumber(Ext.Utils.MonotonicTime()) or 0
        end
        local removed = 0
        local touched = false

        local function EA_IsFreshDelayedSpawnTimer(timerKey, kind)
            if kind ~= "SPAWN" or type(timerKey) ~= "string" then
                return false
            end
            if string.sub(timerKey, 1, 18) ~= "EA_AMBUSH_DELAYED_" then
                return false
            end
            if nowMono <= 0 then
                return false
            end
            local rawMono = timerKey:match("_(%d+)$")
            local timerMono = tonumber(rawMono) or 0
            if timerMono <= 0 then
                return false
            end
            local delta = nowMono - timerMono
            return delta >= -5000 and delta <= (10 * 60 * 1000)
        end

        for timer, data in pairs(pending) do
            if type(data) ~= "table" and type(data) ~= "userdata" then
                pending[timer] = nil
                removed = removed + 1
                touched = true
            else
                if data.kind == "BEAT" then
                    pending[timer] = nil
                    removed = removed + 1
                    touched = true
                else
                    local ts = tonumber(data.timestamp) or 0
                    if ts <= 0 then
                        data.timestamp = now
                        touched = true
                        ts = now
                    end

                    local age = now - ts
                    if age < 0 then
                        data.timestamp = now
                        touched = true
                        age = 0
                    end

                    local ttlMs = EA_PENDING_TTL_MS
                    if data.kind == "SPAWN_QUEUE" then
                        ttlMs = math.max(ttlMs, 15 * 60 * 1000)
                    elseif data.kind == "REST_DEFERRED" then
                        ttlMs = nil
                    end
                    if ttlMs and age > ttlMs then
                        if EA_IsFreshDelayedSpawnTimer(timer, data.kind) then
                            data.timestamp = now
                            touched = true
                        else
                            pending[timer] = nil
                            removed = removed + 1
                            touched = true
                        end
                    end
                end
            end
        end

        local cap = forceCap or EA_PENDING_CAP
        local size = GetTableSize(pending)
        if size > cap then
            local entries = {}
            for timer, data in pairs(pending) do
                local ts = 0
                local protected = false
                if type(data) == "table" or type(data) == "userdata" then
                    ts = tonumber(data.timestamp) or 0
                    protected = (data.kind == "REST_DEFERRED")
                end
                entries[#entries + 1] = { timer = timer, ts = ts, protected = protected }
            end

            table.sort(entries, function(a, b)
                if a.protected ~= b.protected then
                    return (not a.protected) and b.protected
                end
                return a.ts < b.ts
            end)

            local toEvict = size - cap
            local evicted = 0
            for i = 1, #entries do
                if evicted >= toEvict then
                    break
                end
                local entry = entries[i]
                if entry and not entry.protected then
                    local t = entry.timer
                    if t then
                        pending[t] = nil
                        removed = removed + 1
                        evicted = evicted + 1
                        touched = true
                    end
                end
            end
        end

        if touched then
            EA_Dirty()
            if EA_IsRobust() and removed > 0 then
                print(string.format("[EnemyAmbush][ROBUST] Pending cleanup removed=%d nowSize=%d", removed, GetTableSize(pending)))
            end
        end
    end

    local function StorePendingAmbush(timer, ambushData)
        if not timer or timer == "" then
            print("[EnemyAmbush] StorePendingAmbush called with invalid timer key")
            return
        end

        local pending = EA_GetPersistentPendingStore("StorePendingAmbush")
        if not pending then
            EA_P0Inc("readiness.pendingStoreDropped")
            return
        end

        if type(ambushData) == "table" and ambushData.timestamp == nil then
            ambushData.timestamp = EA_NowMs()
        end

        pending[timer] = ambushData
        EA_Dirty(true)

        if GetTableSize(pending) > EA_PENDING_CAP then
            CleanupPendingAmbushes(EA_PENDING_CAP)
        elseif GetTableSize(pending) > 24 then
            CleanupPendingAmbushes()
        else
            EA_Dirty(true)
        end

        return pending[timer], pending
    end

    local function RelaunchPendingTimersOnLoad()
        if not Ext.IsServer() then return end
        if not (Osi and Osi.TimerLaunch) then return end
        if _eaPendingRelaunchCompleted then
            return true
        end

        local pending = EA_GetPersistentPendingStoreIfPresent()
        if not pending then
            EA_P0Inc("readiness.pendingTimersSkippedNoPendingFieldYet")
            if not _eaPendingRelaunchQueued
                and _eaPendingRelaunchAttempts < EA_PENDING_RELAUNCH_RETRY_MAX
                and Ext and Ext.Timer and Ext.Timer.WaitFor then
                _eaPendingRelaunchQueued = true
                _eaPendingRelaunchAttempts = _eaPendingRelaunchAttempts + 1
                Ext.Timer.WaitFor(EA_PENDING_RELAUNCH_RETRY_MS, function()
                    _eaPendingRelaunchQueued = false
                    RelaunchPendingTimersOnLoad()
                end)
            end
            local deferredMirror = EA_GetDeferredRestMirrorIfPresent()
            if not deferredMirror then
                return false
            end
            pending = EA_GetPersistentPendingStore("RelaunchPendingTimersOnLoad")
            if not pending then
                return false
            end
        end
        local now = EA_NowMs()

        local relaunched = 0
        local dropped = 0
        local discovered = 0
        local touched = false
        local activeRestCandidate = nil

        local deferredMirror = EA_GetDeferredRestMirrorIfPresent()
        if deferredMirror and pending[tostring(deferredMirror.timer or "")] == nil then
            pending[tostring(deferredMirror.timer)] = {
                kind = "REST_DEFERRED",
                timer = tostring(deferredMirror.timer or ""),
                character = tostring(deferredMirror.character or ""),
                isLongRest = (deferredMirror.isLongRest == true),
                force = (deferredMirror.force == true),
                reason = tostring(deferredMirror.reason or "unsafe"),
                retryCount = tonumber(deferredMirror.retryCount) or 0,
                retryDelayMs = tonumber(deferredMirror.retryDelayMs) or EA_GetRestRetryDelayMs(),
                timestamp = tonumber(deferredMirror.timestamp) or now,
                runtimeReadyRetries = tonumber(deferredMirror.runtimeReadyRetries) or nil,
                opts = (type(deferredMirror.opts) == "table" or type(deferredMirror.opts) == "userdata") and deferredMirror.opts or nil,
            }
            touched = true
        end

        for timer, data in pairs(pending) do
            discovered = discovered + 1
            if type(data) ~= "table" and type(data) ~= "userdata" then
                pending[timer] = nil
                dropped = dropped + 1
                touched = true
            elseif data.kind == "SPAWN" and type(timer) == "string" and string.sub(timer, 1, 18) == "EA_AMBUSH_DELAYED_" then
                local ts = tonumber(data.timestamp) or 0
                local warn = tonumber(data.warningMs) or 0
                if ts > 0 and warn > 0 then
                    local elapsed = now - ts
                    local remaining = warn - elapsed
                    if remaining < 250 then remaining = 250 end
                    if remaining > 120000 then remaining = 250 end
                    if Osi.TimerCancel then
                        pcall(Osi.TimerCancel, timer)
                    end
                    Osi.TimerLaunch(timer, remaining)
                    relaunched = relaunched + 1
                end
            elseif data.kind == "SPAWN_QUEUE" and type(timer) == "string" and string.sub(timer, 1, 10) == "EA_SPAWNQ_" then
                local stepMs = tonumber(data.staggerMs) or 100
                stepMs = math.floor(math.max(20, math.min(500, stepMs)))
                if Osi.TimerCancel then
                    pcall(Osi.TimerCancel, timer)
                end
                Osi.TimerLaunch(timer, math.max(50, stepMs))
                relaunched = relaunched + 1
            elseif data.kind == "REST_DEFERRED" and type(timer) == "string" and string.sub(timer, 1, string.len(TIMER_PREFIX_REST_DEFER)) == TIMER_PREFIX_REST_DEFER then
                local retryDelayMs = tonumber(data.retryDelayMs)
                if not retryDelayMs or retryDelayMs <= 0 then
                    retryDelayMs = EA_GetRestRetryDelayMs()
                    data.retryDelayMs = retryDelayMs
                    touched = true
                end
                retryDelayMs = math.floor(math.max(250, math.min(120000, retryDelayMs)))
                local ts = tonumber(data.timestamp) or 0
                local remaining = retryDelayMs
                if ts > 0 then
                    remaining = retryDelayMs - (now - ts)
                end
                if remaining < 250 then remaining = 250 end
                if remaining > retryDelayMs then remaining = retryDelayMs end
                if Osi.TimerCancel then
                    pcall(Osi.TimerCancel, timer)
                end
                Osi.TimerLaunch(timer, math.floor(remaining))
                relaunched = relaunched + 1
                local candidateTs = tonumber(data.timestamp) or 0
                if not activeRestCandidate or candidateTs >= (tonumber(activeRestCandidate.ts) or 0) then
                    activeRestCandidate = {
                        timer = timer,
                        ts = candidateTs,
                        kind = (data.isLongRest == true) and "long" or "short",
                        character = tostring(data.character or ""),
                        stage = "deferred",
                    }
                end
            elseif data.kind == "BEAT" and type(timer) == "string" and string.sub(timer, 1, 15) == "EA_AMBUSH_BEAT_" then
                pending[timer] = nil
                dropped = dropped + 1
                touched = true
            end
        end

        if activeRestCandidate then
            EnemyAmbush.EA_ActiveRestTimer = {
                timer = tostring(activeRestCandidate.timer or ""),
                kind = tostring(activeRestCandidate.kind or "rest"),
                character = tostring(activeRestCandidate.character or ""),
                stage = tostring(activeRestCandidate.stage or ""),
                setAt = now,
            }
        end

        if discovered > 0 then
            EA_P0Inc("readiness.pendingTimersDiscovered", discovered)
        end
        if relaunched > 0 then
            EA_P0Inc("readiness.pendingTimersRelaunched", relaunched)
        end
        if dropped > 0 then
            EA_P0Inc("readiness.pendingTimersDropped", dropped)
        end

        if touched then
            EA_Dirty()
        end

        if relaunched > 0 or dropped > 0 then
            print(string.format("[EnemyAmbush] Pending timers on load: relaunched=%d dropped=%d", relaunched, dropped))
        end
        _eaPendingRelaunchCompleted = true
        return true
    end

    local function FlushCachesNow(hard)
        EA_FlushPoolCacheState(hard)
    end

    local function CollectReasonsString()
        local reasons = {}
        for r, _ in pairs(_eaCacheRebuildReasons) do
            reasons[#reasons + 1] = r
        end
        table.sort(reasons)
        _eaCacheRebuildReasons = {}
        return (#reasons > 0) and table.concat(reasons, ", ") or "unknown"
    end

    local function RequestCacheRebuild(reason, hard, immediate)
        reason = tostring(reason or "unknown")
        _eaCacheRebuildReasons[reason] = true
        if hard then _eaCacheRebuildHard = true end

        if immediate == true or not (Ext and Ext.Timer and Ext.Timer.WaitFor) then
            local why = CollectReasonsString()
            local doHard = _eaCacheRebuildHard
            _eaCacheRebuildHard = false
            FlushCachesNow(doHard)
            if EA_IsRobust() then
                print(string.format("[EnemyAmbush][ROBUST] Cache flush (immediate, hard=%s): %s", tostring(doHard), why))
            end
            return
        end

        if _eaCacheRebuildQueued then
            _eaCacheRebuildAgain = true
            return
        end

        _eaCacheRebuildQueued = true
        local DEBOUNCE_MS = 250
        Ext.Timer.WaitFor(DEBOUNCE_MS, function()
            _eaCacheRebuildQueued = false

            local why = CollectReasonsString()
            local doHard = _eaCacheRebuildHard
            _eaCacheRebuildHard = false

            FlushCachesNow(doHard)
            if EA_IsRobust() then
                print(string.format("[EnemyAmbush][ROBUST] Cache flush (hard=%s): %s", tostring(doHard), why))
            end

            if _eaCacheRebuildAgain then
                _eaCacheRebuildAgain = false
                RequestCacheRebuild("coalesced", doHard, false)
            end
        end)
    end

    local SAVE_REPUTATION_RETRY_DELAY_MS = 500
    local SAVE_REPUTATION_RETRY_MAX = 30

    local function SaveReputation(immediateDirty)
        immediateDirty = immediateDirty ~= false
        EA_P0Inc("killedBy.repSave.calls")
        EA_P0Inc("readiness.repSave.calls")
        local readyFn = EA_ModVarsReady or (EA and EA["EA_ModVarsReady"])
        local ready = (type(readyFn) == "function" and readyFn() == true)
        if not ready then
            EA_P0Inc("killedBy.repSave.notReady")
            EA_P0Inc("readiness.repSave.notReady")
            EnemyAmbush._eaPendingSaveReputation = true
            if immediateDirty then
                EnemyAmbush._eaPendingSaveReputationImmediate = true
            elseif EnemyAmbush._eaPendingSaveReputationImmediate == nil then
                EnemyAmbush._eaPendingSaveReputationImmediate = false
            end
            if not EnemyAmbush._eaPendingSaveReputationRetry then
                EnemyAmbush._eaPendingSaveReputationRetry = true
                EnemyAmbush._eaPendingSaveReputationAttempts = 0
                EA_P0Inc("killedBy.repSave.retryScheduled")
                EA_P0Inc("readiness.repSave.retryScheduled")
                if Ext and Ext.Timer and Ext.Timer.WaitFor then
                    local function RetrySaveReputation()
                        EnemyAmbush._eaPendingSaveReputationAttempts = (tonumber(EnemyAmbush._eaPendingSaveReputationAttempts) or 0) + 1
                        EA_P0Inc("killedBy.repSave.retryAttempts")
                        EA_P0Inc("readiness.repSave.retryAttempts")
                        local retryReadyFn = EA_ModVarsReady or (EA and EA["EA_ModVarsReady"])
                        if type(retryReadyFn) == "function" and retryReadyFn() == true then
                            EnemyAmbush._eaPendingSaveReputationRetry = false
                            EnemyAmbush._eaPendingSaveReputationAttempts = 0
                            EA_P0Inc("killedBy.repSave.retryReady")
                            EA_P0Inc("readiness.repSave.retryReady")
                            if EnemyAmbush._eaPendingSaveReputation then
                                local pendingImmediate = (EnemyAmbush._eaPendingSaveReputationImmediate ~= false)
                                EnemyAmbush._eaPendingSaveReputation = false
                                EnemyAmbush._eaPendingSaveReputationImmediate = nil
                                SaveReputation(pendingImmediate)
                            end
                            return
                        end
                        if (tonumber(EnemyAmbush._eaPendingSaveReputationAttempts) or 0) >= SAVE_REPUTATION_RETRY_MAX then
                            EnemyAmbush._eaPendingSaveReputationRetry = false
                            EA_P0Inc("killedBy.repSave.retryExhausted")
                            EA_P0Inc("readiness.repSave.retryExhausted")
                            if EA_IsDebugMode() then
                                local diagFn = EA_GetModVarsReadyDiagnostics or (EA and EA["EA_GetModVarsReadyDiagnostics"])
                                local diag = (type(diagFn) == "function") and diagFn() or nil
                                local reason = tostring(diag and diag.reason or "unknown")
                                local detail = tostring(diag and diag.detail or "")
                                local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
                                local lastAt = tonumber(EnemyAmbush._eaSaveRepRetryExhaustLoggedAt) or 0
                                local lastReason = tostring(EnemyAmbush._eaSaveRepRetryExhaustReason or "")
                                if reason ~= lastReason or now <= 0 or (now - lastAt) >= 60000 then
                                    EnemyAmbush._eaSaveRepRetryExhaustReason = reason
                                    EnemyAmbush._eaSaveRepRetryExhaustLoggedAt = now
                                    DebugPrint("SaveReputation retry exhausted:",
                                        "reason=", reason,
                                        "detail=", detail)
                                end
                            end
                            return
                        end
                        Ext.Timer.WaitFor(SAVE_REPUTATION_RETRY_DELAY_MS, RetrySaveReputation)
                    end
                    Ext.Timer.WaitFor(SAVE_REPUTATION_RETRY_DELAY_MS, RetrySaveReputation)
                else
                    EnemyAmbush._eaPendingSaveReputationRetry = false
                    EA_P0Inc("killedBy.repSave.retryNoTimer")
                    EA_P0Inc("readiness.repSave.retryNoTimer")
                end
            end
            if EA_IsDebugMode() then
                local diagFn = EA_GetModVarsReadyDiagnostics or (EA and EA["EA_GetModVarsReadyDiagnostics"])
                local diag = (type(diagFn) == "function") and diagFn() or nil
                local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
                local lastAt = tonumber(EnemyAmbush._eaSaveRepNotReadyLoggedAt) or 0
                if now <= 0 or (now - lastAt) >= 10000 then
                    EnemyAmbush._eaSaveRepNotReadyLoggedAt = now
                    DebugPrint("SaveReputation skipped: ModVariables backend not ready",
                        "reason=", tostring(diag and diag.reason or "unknown"),
                        "detail=", tostring(diag and diag.detail or ""))
                end
            end
            return
        end

        EnemyAmbush._eaPendingSaveReputation = false
        EnemyAmbush._eaPendingSaveReputationImmediate = nil

        local vars = (type(EA_Vars) == "function") and EA_Vars() or nil
        if not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(vars)) or type(vars) == "table")) then
            EA_P0Inc("killedBy.repSave.varsUnavailable")
            EA_P0Inc("readiness.repSave.varsUnavailable")
            if EA_IsDebugMode() then
                DebugPrint("SaveReputation skipped: EA_Vars unavailable")
            end
            return
        end

        -- Persist a fresh snapshot back onto the registered root field instead of
        -- mutating nested keys in place. The strict Phase 3 contract keeps the
        -- persistent root authoritative, and whole-table assignment is the most
        -- reliable way to commit nested reputation changes across save/load.
        local repSnapshot = {}
        for ct, value in pairs(CreatureReputation) do
            repSnapshot[ct] = tonumber(value) or 0
        end

        local okRepWrite = pcall(function()
            vars.Reputation = repSnapshot
        end)
        if not okRepWrite then
            EA_P0Inc("killedBy.repSave.repTableWriteFailed")
            EA_P0Inc("readiness.repSave.repTableWriteFailed")
            if EA_IsDebugMode() then
                DebugPrint("SaveReputation skipped: failed to write Reputation snapshot")
            end
            return
        end

        if immediateDirty then
            EA_P0Inc("killedBy.repSave.immediate")
            EA_P0Inc("readiness.repSave.immediate")
            if EA_Dirty then
                EA_Dirty(true)
            elseif Ext and Ext.Vars and Ext.Vars.DirtyModVariables and ModuleUUID then
                pcall(Ext.Vars.DirtyModVariables, ModuleUUID)
            end
        else
            EA_P0Inc("killedBy.repSave.deferredDirty")
            EA_P0Inc("readiness.repSave.deferredDirty")
            if EA_Dirty then
                EA_Dirty(false)
            elseif Ext and Ext.Vars and Ext.Vars.DirtyModVariables and ModuleUUID then
                pcall(Ext.Vars.DirtyModVariables, ModuleUUID)
            end
        end
    end

    local function LoadReputation()
        EA_P0Inc("readiness.repLoad.calls")

        local readyFn = EA_ModVarsReady or (EA and EA["EA_ModVarsReady"])
        local ready = (type(readyFn) == "function" and readyFn() == true)
        if not ready then
            EA_P0Inc("readiness.repLoad.notReady")
            EnemyAmbush._eaPendingLoadReputation = true
            if not EnemyAmbush._eaPendingLoadReputationRetry then
                EnemyAmbush._eaPendingLoadReputationRetry = true
                EnemyAmbush._eaPendingLoadReputationAttempts = 0
                EA_P0Inc("readiness.repLoad.retryScheduled")
                if Ext and Ext.Timer and Ext.Timer.WaitFor then
                    local function RetryLoadReputation()
                        EnemyAmbush._eaPendingLoadReputationAttempts = (tonumber(EnemyAmbush._eaPendingLoadReputationAttempts) or 0) + 1
                        EA_P0Inc("readiness.repLoad.retryAttempts")
                        local retryReadyFn = EA_ModVarsReady or (EA and EA["EA_ModVarsReady"])
                        if type(retryReadyFn) == "function" and retryReadyFn() == true then
                            EnemyAmbush._eaPendingLoadReputationRetry = false
                            EnemyAmbush._eaPendingLoadReputationAttempts = 0
                            EA_P0Inc("readiness.repLoad.retryReady")
                            if EnemyAmbush._eaPendingLoadReputation then
                                EnemyAmbush._eaPendingLoadReputation = false
                                LoadReputation()
                            end
                            return
                        end
                        if (tonumber(EnemyAmbush._eaPendingLoadReputationAttempts) or 0) >= 120 then
                            EnemyAmbush._eaPendingLoadReputationRetry = false
                            EA_P0Inc("readiness.repLoad.retryExhausted")
                            if EA_IsDebugMode() then
                                local diagFn = EA_GetModVarsReadyDiagnostics or (EA and EA["EA_GetModVarsReadyDiagnostics"])
                                local diag = (type(diagFn) == "function") and diagFn() or nil
                                local reason = tostring(diag and diag.reason or "unknown")
                                local detail = tostring(diag and diag.detail or "")
                                local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
                                local lastAt = tonumber(EnemyAmbush._eaLoadRepRetryExhaustLoggedAt) or 0
                                local lastReason = tostring(EnemyAmbush._eaLoadRepRetryExhaustReason or "")
                                if reason ~= lastReason or now <= 0 or (now - lastAt) >= 60000 then
                                    EnemyAmbush._eaLoadRepRetryExhaustReason = reason
                                    EnemyAmbush._eaLoadRepRetryExhaustLoggedAt = now
                                    DebugPrint("LoadReputation retry exhausted:",
                                        "reason=", reason,
                                        "detail=", detail)
                                end
                            end
                            return
                        end
                        Ext.Timer.WaitFor(500, RetryLoadReputation)
                    end
                    Ext.Timer.WaitFor(500, RetryLoadReputation)
                else
                    EnemyAmbush._eaPendingLoadReputationRetry = false
                    EA_P0Inc("readiness.repLoad.retryNoTimer")
                end
            end
            if EA_IsDebugMode() then
                local diagFn = EA_GetModVarsReadyDiagnostics or (EA and EA["EA_GetModVarsReadyDiagnostics"])
                local diag = (type(diagFn) == "function") and diagFn() or nil
                local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
                local lastAt = tonumber(EnemyAmbush._eaLoadRepNotReadyLoggedAt) or 0
                if now <= 0 or (now - lastAt) >= 10000 then
                    EnemyAmbush._eaLoadRepNotReadyLoggedAt = now
                    DebugPrint("LoadReputation delayed: ModVariables backend not ready",
                        "reason=", tostring(diag and diag.reason or "unknown"),
                        "detail=", tostring(diag and diag.detail or ""))
                end
            end
            return
        end

        EnemyAmbush._eaPendingLoadReputation = false

        local vars = (type(EA_Vars) == "function") and EA_Vars() or nil
        if not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(vars)) or type(vars) == "table")) then
            EA_P0Inc("readiness.repLoad.varsUnavailable")
            if EA_IsDebugMode() then
                DebugPrint("LoadReputation skipped: EA_Vars unavailable")
            end
            return
        end

        local okRepRead, rep = pcall(function() return vars.Reputation end)
        local repIsContainer = ((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(rep)) or type(rep) == "table")
        if not okRepRead or not repIsContainer then
            local okRepInit = pcall(function() vars.Reputation = {} end)
            if not okRepInit then
                EA_P0Inc("readiness.repLoad.repTableInitFailed")
                if EA_IsDebugMode() then
                    DebugPrint("LoadReputation skipped: Reputation mod-var class unavailable")
                end
                return
            end
            EA_P0Inc("readiness.repLoad.repTableInitialized")
            rep = vars.Reputation
        end

        -- Reputation keys are provider/API-owned non-empty creatureType strings, not
        -- only the seeded vanilla set from SpawnPipeline.
        local function EA_IsSupportedPersistedReputationKey(creatureType)
            if type(creatureType) ~= "string" then
                return false
            end
            if creatureType == "" then
                return false
            end
            if not string.find(creatureType, "%S") then
                return false
            end
            return true
        end

        local loaded = 0
        local skippedInvalid = 0
        local okIter, iterErr = pcall(function()
            for ct, value in pairs(rep) do
                if EA_IsSupportedPersistedReputationKey(ct) then
                    local normalized = tonumber(value) or 0
                    if normalized > 0 then
                        normalized = 0
                    end
                    CreatureReputation[ct] = normalized
                    loaded = loaded + 1
                else
                    skippedInvalid = skippedInvalid + 1
                end
            end
        end)
        if not okIter then
            loaded = 0
            skippedInvalid = 0
            for ct, _ in pairs(CreatureReputation) do
                local v = rep[ct]
                if v ~= nil then
                    local normalized = tonumber(v) or 0
                    if normalized > 0 then
                        normalized = 0
                    end
                    CreatureReputation[ct] = normalized
                    loaded = loaded + 1
                end
            end
            if EA_IsDebugMode() then
                DebugPrint("LoadReputation fell back to seeded-key restore:",
                    "reason=", tostring(iterErr))
            end
        end

        EnemyAmbush._eaLastLoadedReputationValues = loaded

        EA_P0Inc("readiness.repLoad.immediate")
        if loaded > 0 then
            EnemyAmbush._eaPendingLoadReputationVerifyRetry = false
            EnemyAmbush._eaPendingLoadReputationVerifyAttempts = 0
            EA_P0Inc("readiness.repLoad.valuesLoaded", loaded)
        elseif not EnemyAmbush._eaPendingLoadReputationVerifyRetry then
            EnemyAmbush._eaPendingLoadReputationVerifyRetry = true
            EnemyAmbush._eaPendingLoadReputationVerifyAttempts = 0
            EA_P0Inc("readiness.repLoad.verifyScheduled")
            if Ext and Ext.Timer and Ext.Timer.WaitFor then
                local function RetryVerifyLoadReputation()
                    EnemyAmbush._eaPendingLoadReputationVerifyAttempts = (tonumber(EnemyAmbush._eaPendingLoadReputationVerifyAttempts) or 0) + 1
                    EA_P0Inc("readiness.repLoad.verifyAttempts")
                    LoadReputation()
                    if (tonumber(EnemyAmbush._eaLastLoadedReputationValues) or 0) > 0 then
                        EnemyAmbush._eaPendingLoadReputationVerifyRetry = false
                        EnemyAmbush._eaPendingLoadReputationVerifyAttempts = 0
                        EA_P0Inc("readiness.repLoad.verifyRecovered")
                        if EA_IsDebugMode() then
                            DebugPrint("LoadReputation verify recovered:",
                                "loaded=", tostring(EnemyAmbush._eaLastLoadedReputationValues))
                        end
                        return
                    end
                    if (tonumber(EnemyAmbush._eaPendingLoadReputationVerifyAttempts) or 0) >= 12 then
                        EnemyAmbush._eaPendingLoadReputationVerifyRetry = false
                        EA_P0Inc("readiness.repLoad.verifyExhausted")
                        if EA_IsDebugMode() then
                            DebugPrint("LoadReputation verify exhausted:",
                                "loaded=", tostring(EnemyAmbush._eaLastLoadedReputationValues or 0))
                        end
                        return
                    end
                    Ext.Timer.WaitFor(500, RetryVerifyLoadReputation)
                end
                Ext.Timer.WaitFor(500, RetryVerifyLoadReputation)
            else
                EnemyAmbush._eaPendingLoadReputationVerifyRetry = false
                EA_P0Inc("readiness.repLoad.verifyNoTimer")
            end
        end

        if skippedInvalid > 0 then
            EA_P0Inc("readiness.repLoad.invalidKeysSkipped", skippedInvalid)
            if EA_IsDebugMode() then
                DebugPrint("LoadReputation skipped invalid keys:",
                    "count=", tostring(skippedInvalid))
            end
        end
    end

    local function EA_ResetReputationForMigration()
        local repType = type(CreatureReputation)
        if repType ~= "table" and repType ~= "userdata" then
            return false
        end
        for creatureType, _ in pairs(CreatureReputation) do
            CreatureReputation[creatureType] = 0
        end
        SaveReputation()
        return true
    end

    local function EA_GetCreatureReputationTable()
        return CreatureReputation
    end

    local function EA_GetReputationThresholds()
        return REPUTATION_THRESHOLDS
    end

    runtime.CleanupPendingAmbushes = CleanupPendingAmbushes
    runtime.StorePendingAmbush = StorePendingAmbush
    runtime.RelaunchPendingTimersOnLoad = RelaunchPendingTimersOnLoad
    runtime.FlushCachesNow = FlushCachesNow
    runtime.RequestCacheRebuild = RequestCacheRebuild
    runtime.SaveReputation = SaveReputation
    runtime.LoadReputation = LoadReputation
    runtime.EA_ResetReputationForMigration = EA_ResetReputationForMigration
    runtime.EA_GetCreatureReputationTable = EA_GetCreatureReputationTable
    runtime.EA_GetReputationThresholds = EA_GetReputationThresholds

    return runtime
end

return M
