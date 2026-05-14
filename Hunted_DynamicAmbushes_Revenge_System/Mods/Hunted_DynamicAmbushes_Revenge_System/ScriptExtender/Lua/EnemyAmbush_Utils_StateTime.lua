-- EnemyAmbush_Utils_StateTime.lua
-- Extracted from monolithic EnemyAmbush_Utils.lua for local-budget stability.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local ModuleUUID = EA.ModuleUUID or "96f24297-6ed9-455c-aaa1-ac9c358a8d35"
EA.ModuleUUID = ModuleUUID
local function EA_P0Inc(...)
    local fn = EA and EA["EA_P0Inc"]
    if type(fn) == "function" then
        return fn(...)
    end
    return 0
end

-- ========= Debounced persistence flush =========
-- Many systems call EA_Dirty() in bursts (pressure, rep, spawned tracking, pending ambushes).
-- Debounce to avoid save/sync spam and hitching, especially in long sessions.
local _eaDirtyQueued = false
local _eaDirtyAgain = false
local _eaDirtyNotReadyLastReason = ""
local _eaDirtyNotReadyLastAt = 0
local _eaDirtyNotReadyLogIntervalMs = 60000

local function EA_StateTimeDebugEnabled()
    local getter = EA and EA["EA_GetSettingFromSnapshot"]
    if type(getter) == "function" then
        local ok, out = pcall(getter, "MCM_DebugMode", false)
        if ok then
            return out == true
        end
    end
    return false
end

local function EA_StateTimeTimeInDangerEnabled()
    local enabledFn = EA and EA["EA_GetTimeInDangerPressureEnabled"]
    if type(enabledFn) == "function" then
        local ok, out = pcall(enabledFn)
        if ok then
            return out == true
        end
    end
    local getter = EA and EA["EA_GetSettingFromSnapshot"]
    if type(getter) == "function" then
        local ok, out = pcall(getter, "MCM_EnableTimeInDangerPressure", true)
        if ok then
            return out == true
        end
    end
    return true
end

local function EA_GetChanceMultiplierSafe()
    local fn = EA and EA["EA_GetChanceMultiplier"]
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok and tonumber(out) ~= nil then
            return tonumber(out)
        end
    end
    return 1.0
end

local function EA_StatePersistentReady()
    local readyFn = EA and EA["EA_ModVarsReady"]
    if type(readyFn) ~= "function" then
        return false
    end
    local ok, ready = pcall(readyFn)
    return ok and ready == true
end

local function EA_StatePersistentMap(value)
    return type(value) == "table" or type(value) == "userdata"
end

local function EA_StateTimeGetConfigNumber(key, default)
    local cfg = EA and EA.CFG
    if type(cfg) == "table" then
        local value = tonumber(cfg[key])
        if value ~= nil then
            return value
        end
    end
    return tonumber(default) or 0
end

local function EA_StateTimeGetConfigBool(key, default)
    local cfg = EA and EA.CFG
    if type(cfg) == "table" then
        local value = cfg[key]
        if value ~= nil then
            return value ~= false
        end
    end
    return default ~= false
end

local function EA_StateTimeGetPressureRegionMultEnabled()
    return EA_StateTimeGetConfigBool("AMBUSH_PRESSURE_USE_REGION_MULT", true)
end

local function EA_StateTimeGetPressureMax()
    return EA_StateTimeGetConfigNumber("AMBUSH_PRESSURE_MAX", 100)
end

local function EA_StateTimeGetPressureGainShort()
    return EA_StateTimeGetConfigNumber("AMBUSH_PRESSURE_GAIN_SHORT", 5)
end

local function EA_StateTimeGetPressureGainLong()
    return EA_StateTimeGetConfigNumber("AMBUSH_PRESSURE_GAIN_LONG", 20)
end

local function EA_StateTimeGetPressureDecayEnabled()
    return EA_StateTimeGetConfigBool("AMBUSH_PRESSURE_DECAY_ENABLED", true)
end

local function EA_StateTimeGetPressureDecayIntervalMs()
    return EA_StateTimeGetConfigNumber("AMBUSH_PRESSURE_DECAY_INTERVAL_MS", 120000)
end

local function EA_StateTimeGetPressureDecayMinutesQuantum()
    return EA_StateTimeGetConfigNumber("AMBUSH_PRESSURE_DECAY_MINUTES_QUANTUM", 1)
end

local function EA_StateTimeResolveRegionPressureMult(canonical)
    if type(canonical) ~= "string" or canonical == "" then
        return nil
    end

    local regionPolicy = EA and EA.REGION_POLICY
    if type(regionPolicy) ~= "table" then
        return nil
    end

    local direct = regionPolicy[canonical]
    if type(direct) == "table" and direct.pressureMult ~= nil then
        return tonumber(direct.pressureMult) or 1.0
    end

    for key, policy in pairs(regionPolicy) do
        if type(key) == "string"
            and type(policy) == "table"
            and policy.pressureMult ~= nil
            and canonical:find(key, 1, true) then
            return tonumber(policy.pressureMult) or 1.0
        end
    end

    return nil
end

local function EA_ReportDirtyNotReady()
    EA_P0Inc("readiness.dirtyRetryRemovedNoop")
    if not EA_StateTimeDebugEnabled() then
        return
    end
    local diagFn = EA and EA["EA_GetModVarsReadyDiagnostics"]
    local diag = (type(diagFn) == "function") and diagFn() or nil
    local reason = tostring(diag and diag.reason or "unknown")
    local detail = tostring(diag and diag.detail or "")
    local nowFn = EA and EA["EA_NowMs"]
    local now = tonumber(type(nowFn) == "function" and nowFn() or 0) or 0
    local shouldLog = (reason ~= _eaDirtyNotReadyLastReason)
    if not shouldLog then
        if now <= 0 then
            shouldLog = true
        elseif (now - _eaDirtyNotReadyLastAt) >= _eaDirtyNotReadyLogIntervalMs then
            shouldLog = true
        end
    end
    if not shouldLog then
        return
    end
    _eaDirtyNotReadyLastReason = reason
    _eaDirtyNotReadyLastAt = now
    DebugPrint(
        "EA_Dirty skipped: persistent ModVariables not ready",
        "reason=", reason,
        "detail=", detail
    )
end

local function EA_DirtyImmediate()
    if not EA_StatePersistentReady() then
        EA_P0Inc("readiness.dirtyImmediateNotReady")
        EA_ReportDirtyNotReady()
        return
    end
    EA_P0Inc("readiness.dirtyImmediateReady")

    local invalidateCache = EA and EA["EA_InvalidateModVarsHandleCache"]
    if type(invalidateCache) == "function" then
        pcall(invalidateCache)
    end

    if Ext and Ext.Vars and Ext.Vars.DirtyModVariables then
        Ext.Vars.DirtyModVariables(ModuleUUID)
    end
    -- Do NOT call SyncModVariables here.
    -- If you want client-visible UI later, we'll register client prototypes and sync intentionally.
end

EA_Dirty = function(immediate)
    -- Allow critical paths to force an immediate flush if desired
    -- Critical gameplay-state mutations MUST call EA_Dirty(true):
    -- pending ambush records, spawn registry mutations, reputation saves,
    -- scenario completion/bootstrap flags, and rest-cycle/cooldown stamps.
    if immediate == true then
        _eaDirtyQueued = false
        _eaDirtyAgain = false
        EA_DirtyImmediate()
        return
    end

    -- If we can't schedule timers, fall back to immediate
    if not (Ext and Ext.Timer and Ext.Timer.WaitFor) then
        EA_P0Inc("readiness.dirtyImmediateNoTimerFallback")
        EA_DirtyImmediate()
        return
    end

    -- Coalesce bursts
    if _eaDirtyQueued then
        _eaDirtyAgain = true
        EA_P0Inc("readiness.dirtyCoalesced")
        return
    end

    _eaDirtyQueued = true

    -- Tuned for lower data-loss window while still coalescing bursts.
    local DEBOUNCE_MS = 120

    Ext.Timer.WaitFor(DEBOUNCE_MS, function()
        _eaDirtyQueued = false
        EA_DirtyImmediate()

        -- If more dirty requests arrived while queued, flush once more (still debounced)
        if _eaDirtyAgain then
            _eaDirtyAgain = false
            EA_Dirty(false)
        end
    end)
end

function EA_GetRegionPressureMult(character)
    if not EA_StateTimeGetPressureRegionMultEnabled() then return 1.0 end
    local canonical, raw = EA_GetRegionForCharacter(character)

    -- Log unknown regions for telemetry
    EA_LogUnknownRegion(raw, "pressure_mult")

    local mult = EA_StateTimeResolveRegionPressureMult(canonical)
    if mult ~= nil then
        return mult
    end
    return 1.0
end

function EA_GetAmbushPressure(character)
    local key = EA_NormalizeUUID(character) or character
    local pressure = EA_AmbushPressure()
    if not EA_StatePersistentMap(pressure) then
        return 0
    end
    return tonumber(pressure[key]) or 0
end

local EA_TIME_IN_DANGER_FULL_RISK_MS = 25 * 60 * 1000
local EA_TIME_IN_DANGER_MAX_DELTA_MS = 90000
local EA_TIME_IN_DANGER_POST_AMBUSH_GATE_MS = 30 * 60 * 1000
local EA_TIME_IN_DANGER_POST_COMBAT_GRACE_MS = 5 * 60 * 1000
local EA_TIME_IN_DANGER_CAMP_EXIT_GRACE_MS = 20 * 1000

local function EA_GetTimeInDangerCharacterKey(character)
    local key = EA_NormalizeUUID(character) or tostring(character or "")
    if key == "" then
        return nil
    end
    return key
end

local function EA_GetTimeInDangerPostAmbushGateRemainingMs(characterKey, nowMs)
    if not characterKey or characterKey == "" then
        return 0, 0
    end
    local lastAmbushFn = EA_LastAmbushTime or (EA and EA["EA_LastAmbushTime"])
    local lastByChar = (type(lastAmbushFn) == "function") and lastAmbushFn() or nil
    if not EA_StatePersistentMap(lastByChar) then
        return 0, 0
    end

    local lastAtMs = tonumber(lastByChar[characterKey]) or 0
    if lastAtMs <= 0 then
        return 0, 0
    end

    local resolvedNow = math.max(0, tonumber(nowMs) or 0)
    if resolvedNow <= 0 then
        return 0, lastAtMs
    end
    if lastAtMs > resolvedNow then
        lastAtMs = resolvedNow
    end

    local remainingMs = (lastAtMs + EA_TIME_IN_DANGER_POST_AMBUSH_GATE_MS) - resolvedNow
    if remainingMs <= 0 then
        return 0, lastAtMs
    end
    return math.floor(remainingMs), lastAtMs
end

local function EA_GetTimeInDangerHostCharacter()
    if Osi and Osi.GetHostCharacter then
        local host = Osi.GetHostCharacter()
        if host and host ~= "" then
            return host
        end
    end
    return nil
end

local function EA_ResolveTimeInDangerCharacter(character)
    local host = EA_GetTimeInDangerHostCharacter()
    if host and host ~= "" then
        return tostring(host)
    end
    if character and character ~= "" then
        return tostring(character)
    end
    return nil
end

local function EA_IsCharacterInCampNow(character, canonicalRegion)
    if not character or character == "" then
        return false
    end

    if Osi and Osi.DB_InCamp then
        local ok, tuples = pcall(function()
            return Osi.DB_InCamp:Get(character)
        end)
        if ok and tuples and #tuples > 0 then
            return true
        end
    end

    if Osi and Osi.DB_PlayerInCamp then
        local ok, tuples = pcall(function()
            return Osi.DB_PlayerInCamp:Get(character)
        end)
        if ok and tuples and #tuples > 0 then
            return true
        end
    end

    return EA_IsRegionCamp and EA_IsRegionCamp(canonicalRegion) == true or false
end

local function EA_GetCampExitGraceMap()
    EA._CampExitAmbushGraceByCharacter = EA._CampExitAmbushGraceByCharacter or {}
    if type(EA._CampExitAmbushGraceByCharacter) ~= "table" then
        EA._CampExitAmbushGraceByCharacter = {}
    end
    return EA._CampExitAmbushGraceByCharacter
end

local function EA_GetCampPresenceMap()
    EA._CampPresenceByCharacter = EA._CampPresenceByCharacter or {}
    if type(EA._CampPresenceByCharacter) ~= "table" then
        EA._CampPresenceByCharacter = {}
    end
    return EA._CampPresenceByCharacter
end

function EA_GetCampExitAmbushGraceState(character, nowMs)
    local resolvedCharacter = EA_ResolveTimeInDangerCharacter(character)
    local key = EA_GetTimeInDangerCharacterKey(resolvedCharacter)
    if not key then
        return { active = false }
    end

    local entry = EA_GetCampExitGraceMap()[key]
    if type(entry) ~= "table" then
        return { active = false }
    end

    local resolvedNow = math.max(0, tonumber(nowMs) or tonumber(EA_NowMs and EA_NowMs() or 0) or 0)
    local endAtMs = tonumber(entry.endAtMs) or 0
    if endAtMs <= resolvedNow then
        EA_GetCampExitGraceMap()[key] = nil
        return { active = false }
    end

    return {
        active = true,
        character = tostring(resolvedCharacter or key),
        remainingMs = math.max(0, math.floor(endAtMs - resolvedNow)),
        graceMs = math.max(0, math.floor(tonumber(entry.graceMs) or EA_TIME_IN_DANGER_CAMP_EXIT_GRACE_MS)),
        startAtMs = math.max(0, math.floor(tonumber(entry.startAtMs) or 0)),
        reason = tostring(entry.reason or "camp_exit"),
    }
end

function EA_StampCampExitAmbushGrace(character, reason, durationMs, nowMs)
    local resolvedCharacter = EA_ResolveTimeInDangerCharacter(character)
    local key = EA_GetTimeInDangerCharacterKey(resolvedCharacter)
    if not key then
        return false
    end

    local resolvedNow = math.max(0, tonumber(nowMs) or tonumber(EA_NowMs and EA_NowMs() or 0) or 0)
    local graceMs = math.max(0, math.floor(tonumber(durationMs) or EA_TIME_IN_DANGER_CAMP_EXIT_GRACE_MS))
    if graceMs <= 0 then
        return false
    end

    EA_GetCampExitGraceMap()[key] = {
        startAtMs = resolvedNow,
        endAtMs = resolvedNow + graceMs,
        graceMs = graceMs,
        reason = tostring(reason or "camp_exit"),
    }
    if EA_StateTimeDebugEnabled() then
        DebugPrint(string.format(
            "[Risk] camp-exit grace stamped char=%s reason=%s graceMs=%d",
            tostring(resolvedCharacter or key),
            tostring(reason or "camp_exit"),
            graceMs
        ))
    end
    return true
end

function EA_UpdateCampExitAmbushGrace(character, isInCamp, nowMs, reason)
    local resolvedCharacter = EA_ResolveTimeInDangerCharacter(character)
    local key = EA_GetTimeInDangerCharacterKey(resolvedCharacter)
    if not key then
        return { active = false }
    end

    local presence = EA_GetCampPresenceMap()
    local wasInCamp = presence[key] == true
    local nowInCamp = isInCamp == true
    presence[key] = nowInCamp

    if wasInCamp and not nowInCamp then
        EA_StampCampExitAmbushGrace(resolvedCharacter, reason or "camp_exit", EA_TIME_IN_DANGER_CAMP_EXIT_GRACE_MS, nowMs)
    end
    return EA_GetCampExitAmbushGraceState(resolvedCharacter, nowMs)
end

function EA_UpdateCampExitAmbushGraceForCharacter(character, nowMs, reason)
    local canonicalRegion = nil
    if type(EA_GetRegionForCharacter) == "function" and character and character ~= "" then
        local okRegion, canonical = pcall(EA_GetRegionForCharacter, character)
        if okRegion then
            canonicalRegion = canonical
        end
    end
    local inCamp = EA_IsCharacterInCampNow(character, canonicalRegion)
    local graceState = EA_UpdateCampExitAmbushGrace(character, inCamp, nowMs, reason or "camp_exit")
    return inCamp, graceState
end

local function EA_IsCharacterOrPartyInCombat(character)
    if character and character ~= "" and Osi and Osi.IsInCombat then
        local ok, inCombat = pcall(Osi.IsInCombat, character)
        if ok and inCombat == 1 then
            return true
        end
    end

    return EA_IsAnyPartyInCombat and EA_IsAnyPartyInCombat() == true or false
end

local function EA_GetTimeInDangerStateSafe()
    local state = EA_TimeInDangerState()
    if not EA_StatePersistentMap(state) then
        return nil
    end
    if not EA_StatePersistentMap(state.accumulatedMsByCharacter) then
        state.accumulatedMsByCharacter = {}
    end
    if not EA_StatePersistentMap(state.lastTickAtMsByCharacter) then
        state.lastTickAtMsByCharacter = {}
    end
    if not EA_StatePersistentMap(state.lastTravelCheckAtMsByCharacter) then
        state.lastTravelCheckAtMsByCharacter = {}
    end
    return state
end

local function EA_CopyTimeInDangerNumericMap(source)
    local snapshot = {}
    if not EA_StatePersistentMap(source) then
        return snapshot
    end
    for key, value in pairs(source) do
        local normalizedKey = EA_NormalizeUUID(key) or tostring(key or "")
        if normalizedKey ~= "" then
            local numericValue = tonumber(value)
            if numericValue ~= nil then
                snapshot[normalizedKey] = math.floor(numericValue)
            end
        end
    end
    return snapshot
end

local function EA_CopyTimeInDangerState(source)
    local snapshot = {
        accumulatedMsByCharacter = {},
        lastTickAtMsByCharacter = {},
        lastTravelCheckAtMsByCharacter = {},
    }
    if not EA_StatePersistentMap(source) then
        return snapshot
    end
    snapshot.accumulatedMsByCharacter = EA_CopyTimeInDangerNumericMap(source.accumulatedMsByCharacter)
    snapshot.lastTickAtMsByCharacter = EA_CopyTimeInDangerNumericMap(source.lastTickAtMsByCharacter)
    snapshot.lastTravelCheckAtMsByCharacter = EA_CopyTimeInDangerNumericMap(source.lastTravelCheckAtMsByCharacter)
    return snapshot
end

local EA_WriteTimeInDangerState

function EA_ClearAllTimeInDangerState(reason)
    local state = EA_GetTimeInDangerStateSafe()
    if not state then
        return false
    end

    local hadAccumulated = next(state.accumulatedMsByCharacter) ~= nil
    local hadLastTick = next(state.lastTickAtMsByCharacter) ~= nil
    local hadTravelCheck = next(state.lastTravelCheckAtMsByCharacter) ~= nil
    if not (hadAccumulated or hadLastTick or hadTravelCheck) then
        return false
    end

    state.accumulatedMsByCharacter = {}
    state.lastTickAtMsByCharacter = {}
    state.lastTravelCheckAtMsByCharacter = {}

    local wrote = EA_WriteTimeInDangerState(state, true)
    if wrote and EA_StateTimeDebugEnabled() then
        DebugPrint(string.format(
            "[Risk] time_in_danger state cleared reason=%s",
            tostring(reason or "unspecified")
        ))
    end
    return wrote
end

EA_WriteTimeInDangerState = function(stateSnapshot, immediateDirty)
    local varsFn = EA and EA["EA_Vars"]
    local vars = (type(varsFn) == "function") and varsFn() or nil
    if not EA_StatePersistentMap(vars) then
        return false
    end
    local okWrite = pcall(function()
        vars.EA_TimeInDangerState = EA_CopyTimeInDangerState(stateSnapshot)
    end)
    if not okWrite then
        return false
    end
    if EA_Dirty then
        EA_Dirty(immediateDirty == true)
    end
    return true
end

function EA_GetTimeInDangerAccumulatedMs(character)
    if not EA_StateTimeTimeInDangerEnabled() then
        return 0
    end
    local state = EA_GetTimeInDangerStateSafe()
    if not state then
        return 0
    end
    local key = EA_GetTimeInDangerCharacterKey(EA_ResolveTimeInDangerCharacter(character))
    if not key then
        return 0
    end
    return math.max(0, tonumber(state.accumulatedMsByCharacter[key]) or 0)
end

function EA_GetTimeInDangerRiskUnit(character)
    if not EA_StateTimeTimeInDangerEnabled() then
        return 0
    end
    local accumulatedMs = EA_GetTimeInDangerAccumulatedMs(character)
    if accumulatedMs <= 0 then
        return 0
    end
    local riskUnit = accumulatedMs / EA_TIME_IN_DANGER_FULL_RISK_MS
    if riskUnit < 0 then
        return 0
    end
    if riskUnit > 1 then
        return 1
    end
    return riskUnit
end

function EA_GetTimeInDangerTravelCheckAtMs(character)
    if not EA_StateTimeTimeInDangerEnabled() then
        return 0
    end
    local state = EA_GetTimeInDangerStateSafe()
    if not state then
        return 0
    end
    local key = EA_GetTimeInDangerCharacterKey(EA_ResolveTimeInDangerCharacter(character))
    if not key then
        return 0
    end
    return math.max(0, tonumber(state.lastTravelCheckAtMsByCharacter[key]) or 0)
end

function EA_SetTimeInDangerTravelCheckAtMs(character, atMs)
    if not EA_StateTimeTimeInDangerEnabled() then
        return false
    end
    local state = EA_GetTimeInDangerStateSafe()
    if not state then
        return false
    end
    local key = EA_GetTimeInDangerCharacterKey(EA_ResolveTimeInDangerCharacter(character))
    if not key then
        return false
    end
    local resolvedAtMs = math.max(0, math.floor(tonumber(atMs) or 0))
    local current = math.max(0, tonumber(state.lastTravelCheckAtMsByCharacter[key]) or 0)
    if current == resolvedAtMs then
        return false
    end
    state.lastTravelCheckAtMsByCharacter[key] = resolvedAtMs
    return EA_WriteTimeInDangerState(state, true)
end

function EA_ResetTimeInDangerState(character, reason)
    local state = EA_GetTimeInDangerStateSafe()
    if not state then
        return false
    end
    local resolvedCharacter = EA_ResolveTimeInDangerCharacter(character)
    local key = EA_GetTimeInDangerCharacterKey(resolvedCharacter)
    if not key then
        return false
    end

    local accumulatedMsByCharacter = state.accumulatedMsByCharacter
    local lastTickAtMsByCharacter = state.lastTickAtMsByCharacter
    local lastTravelCheckAtMsByCharacter = state.lastTravelCheckAtMsByCharacter
    local hadAccumulated = (tonumber(accumulatedMsByCharacter[key]) or 0) > 0
    local hadLastTick = tonumber(lastTickAtMsByCharacter[key]) ~= nil
    local hadTravelCheck = tonumber(lastTravelCheckAtMsByCharacter[key]) ~= nil
    accumulatedMsByCharacter[key] = nil
    lastTickAtMsByCharacter[key] = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
    lastTravelCheckAtMsByCharacter[key] = nil

    if hadAccumulated or hadLastTick or hadTravelCheck then
        local wrote = EA_WriteTimeInDangerState(state, true)
        if wrote and EA_StateTimeDebugEnabled() then
            DebugPrint(string.format(
                "[Risk] time_in_danger reset char=%s reason=%s",
                tostring(resolvedCharacter or key),
                tostring(reason or "unspecified")
            ))
        end
        return wrote
    end

    return false
end

local function EA_GetPostCombatGraceMap()
    EA._PostCombatAmbushGraceByCharacter = EA._PostCombatAmbushGraceByCharacter or {}
    if type(EA._PostCombatAmbushGraceByCharacter) ~= "table" then
        EA._PostCombatAmbushGraceByCharacter = {}
    end
    return EA._PostCombatAmbushGraceByCharacter
end

local function EA_GetPostCombatTracker()
    EA._PostCombatGraceTracker = EA._PostCombatGraceTracker or {}
    if type(EA._PostCombatGraceTracker) ~= "table" then
        EA._PostCombatGraceTracker = {}
    end
    if type(EA._PostCombatGraceTracker.combats) ~= "table" then
        EA._PostCombatGraceTracker.combats = {}
    end
    return EA._PostCombatGraceTracker.combats
end

local function EA_PostCombatNormalizeCombatKey(combatGuid)
    local fn = EA and EA["EA_NormalizeCombatKey"]
    if type(fn) == "function" then
        local ok, out = pcall(fn, combatGuid)
        if ok and out and out ~= "" then
            return tostring(out)
        end
    end
    return tostring(combatGuid or "")
end

function EA_GetPostCombatAmbushGraceState(character, nowMs)
    local resolvedCharacter = EA_ResolveTimeInDangerCharacter(character)
    local key = EA_GetTimeInDangerCharacterKey(resolvedCharacter)
    if not key then
        return { active = false }
    end
    local graceMap = EA_GetPostCombatGraceMap()
    local entry = graceMap[key]
    if type(entry) ~= "table" then
        return { active = false }
    end
    local resolvedNow = math.max(0, tonumber(nowMs) or tonumber(EA_NowMs and EA_NowMs() or 0) or 0)
    local endAtMs = tonumber(entry.endAtMs) or 0
    if endAtMs <= resolvedNow then
        graceMap[key] = nil
        return { active = false }
    end
    return {
        active = true,
        character = tostring(resolvedCharacter or key),
        remainingMs = math.max(0, math.floor(endAtMs - resolvedNow)),
        graceMs = math.max(0, math.floor(tonumber(entry.graceMs) or EA_TIME_IN_DANGER_POST_COMBAT_GRACE_MS)),
        startAtMs = math.max(0, math.floor(tonumber(entry.startAtMs) or 0)),
        reason = tostring(entry.reason or "vanilla_combat_ended"),
    }
end

function EA_StampPostCombatAmbushGrace(character, reason, durationMs)
    local resolvedCharacter = EA_ResolveTimeInDangerCharacter(character)
    local key = EA_GetTimeInDangerCharacterKey(resolvedCharacter)
    if not key then
        return false
    end
    local nowMs = math.max(0, tonumber(EA_NowMs and EA_NowMs() or 0) or 0)
    local graceMs = math.max(0, math.floor(tonumber(durationMs) or EA_TIME_IN_DANGER_POST_COMBAT_GRACE_MS))
    if graceMs <= 0 then
        return false
    end
    EA_GetPostCombatGraceMap()[key] = {
        startAtMs = nowMs,
        endAtMs = nowMs + graceMs,
        graceMs = graceMs,
        reason = tostring(reason or "vanilla_combat_ended"),
    }
    if EA_StateTimeDebugEnabled() then
        DebugPrint(string.format(
            "[Risk] post-combat grace stamped char=%s reason=%s graceMs=%d",
            tostring(resolvedCharacter or key),
            tostring(reason or "vanilla_combat_ended"),
            graceMs
        ))
    end
    return true
end

local function EA_PostCombatIsPlayer(character)
    if character and character ~= "" and Osi and Osi.IsPlayer then
        local ok, isPlayer = pcall(Osi.IsPlayer, character)
        return ok and tonumber(isPlayer) == 1
    end
    return false
end

local function EA_PostCombatIsHuntedAmbusher(character)
    if not character or character == "" then
        return false
    end
    local id = EA_NormalizeUUID(character) or character
    local spawnedFn = EA_Spawned or (EA and EA["EA_Spawned"])
    local spawned = (type(spawnedFn) == "function") and spawnedFn() or nil
    if EA_StatePersistentMap(spawned) and (spawned[id] ~= nil or spawned[character] ~= nil) then
        return true
    end
    if Osi and Osi.HasActiveStatus then
        local ok, hasStatus = pcall(Osi.HasActiveStatus, character, "EA_AMBUSHER")
        if ok and tonumber(hasStatus) == 1 then
            return true
        end
    end
    return false
end

local function EA_FinalizePostCombatGraceIfReady(combatKey, character, token)
    local tracker = EA_GetPostCombatTracker()
    local state = tracker[combatKey]
    if type(state) ~= "table" or state.finalizeToken ~= token then
        return false
    end
    for _ in pairs(state.activePlayers or {}) do
        return false
    end
    tracker[combatKey] = nil
    if state.partySeen == true and state.huntedSeen ~= true then
        local target = EA_ResolveTimeInDangerCharacter(character) or character
        EA_ResetTimeInDangerState(target, "vanilla_combat_ended")
        EA_StampPostCombatAmbushGrace(target, "vanilla_combat_ended", EA_TIME_IN_DANGER_POST_COMBAT_GRACE_MS)
        return true
    end
    return false
end

function EA_RecordCombatEnteredForPostCombatGrace(character, combatGuid)
    local combatKey = EA_PostCombatNormalizeCombatKey(combatGuid)
    if combatKey == "" then
        return false
    end
    local tracker = EA_GetPostCombatTracker()
    local state = tracker[combatKey]
    if type(state) ~= "table" then
        state = { partySeen = false, huntedSeen = false, activePlayers = {}, finalizeToken = 0 }
        tracker[combatKey] = state
    end
    local characterKey = EA_GetTimeInDangerCharacterKey(character)
    if EA_PostCombatIsPlayer(character) then
        state.partySeen = true
        if characterKey then
            state.activePlayers[characterKey] = true
        end
    end
    if EA_PostCombatIsHuntedAmbusher(character) then
        state.huntedSeen = true
    end
    return true
end

function EA_RecordCombatLeftForPostCombatGrace(character, combatGuid)
    local combatKey = EA_PostCombatNormalizeCombatKey(combatGuid)
    if combatKey == "" then
        return false
    end
    local tracker = EA_GetPostCombatTracker()
    local state = tracker[combatKey]
    if type(state) ~= "table" then
        state = { partySeen = false, huntedSeen = false, activePlayers = {}, finalizeToken = 0 }
        tracker[combatKey] = state
    end
    if EA_PostCombatIsPlayer(character) then
        state.partySeen = true
        local characterKey = EA_GetTimeInDangerCharacterKey(character)
        if characterKey then
            state.activePlayers[characterKey] = nil
        end
    end
    if EA_PostCombatIsHuntedAmbusher(character) then
        state.huntedSeen = true
    end
    state.finalizeToken = (tonumber(state.finalizeToken) or 0) + 1
    local token = state.finalizeToken
    if Ext and Ext.Timer and Ext.Timer.WaitFor then
        Ext.Timer.WaitFor(2500, function()
            EA_FinalizePostCombatGraceIfReady(combatKey, character, token)
        end)
        return true
    end
    return EA_FinalizePostCombatGraceIfReady(combatKey, character, token)
end

function EA_TickTimeInDangerRisk(opts)
    opts = (type(opts) == "table") and opts or {}

    local state = EA_GetTimeInDangerStateSafe()
    if not state then
        return false, 0, "state_unavailable"
    end

    local character = tostring(EA_ResolveTimeInDangerCharacter(opts.character) or "")
    if character == "" then
        return false, 0, "character_unavailable"
    end

    local key = EA_GetTimeInDangerCharacterKey(character)
    if not key then
        return false, 0, "character_unavailable"
    end

    if not EA_StateTimeTimeInDangerEnabled() then
        EA_ClearAllTimeInDangerState("disabled")
        return false, 0, "disabled"
    end

    local nowMs = tonumber(opts.nowMs) or tonumber(EA_NowMs and EA_NowMs() or 0) or 0
    local accumulatedMsByCharacter = state.accumulatedMsByCharacter
    local lastTickAtMsByCharacter = state.lastTickAtMsByCharacter
    local lastTickAtMs = tonumber(lastTickAtMsByCharacter[key]) or 0
    local deltaMs = 0
    if lastTickAtMs > 0 and nowMs > lastTickAtMs then
        deltaMs = nowMs - lastTickAtMs
        if deltaMs > EA_TIME_IN_DANGER_MAX_DELTA_MS then
            deltaMs = 0
        end
    end
    lastTickAtMsByCharacter[key] = nowMs

    local canonicalRegion, rawRegion = EA_GetRegionForCharacter(character)
    canonicalRegion = tostring(canonicalRegion or "")
    rawRegion = tostring(rawRegion or "")
    if canonicalRegion == "" then
        return false, 0, "region_unavailable"
    end

    local inCombat = EA_IsCharacterOrPartyInCombat(character)
    local safeZoneState = (type(EA_GetSafeZoneState) == "function") and EA_GetSafeZoneState(character) or nil
    local inBlockedSafeZone = false
    local safeZoneBlockReason = ""
    if type(safeZoneState) == "table" then
        inBlockedSafeZone = safeZoneState.blocked == true
        safeZoneBlockReason = tostring(safeZoneState.blockReason or "")
    elseif EA_IsCharacterInBlockedSafeZone then
        inBlockedSafeZone = EA_IsCharacterInBlockedSafeZone(character) == true
    end
    if safeZoneBlockReason == "" and inBlockedSafeZone then
        safeZoneBlockReason = "safe_zone_block"
    end
    local rawRegionBlocked = EA_IsRawRegionBlocked and EA_IsRawRegionBlocked(rawRegion) == true or false
    local regionBlocked = EA_IsRegionBlocked and EA_IsRegionBlocked(canonicalRegion) == true or false
    local regionIsCamp = EA_IsCharacterInCampNow(character, canonicalRegion)
    local campExitGraceState = EA_UpdateCampExitAmbushGrace(character, regionIsCamp, nowMs, "time_in_danger")
    local campExitGraceActive = type(campExitGraceState) == "table" and campExitGraceState.active == true
    local postAmbushGateRemainingMs, postAmbushGateStartAtMs =
        EA_GetTimeInDangerPostAmbushGateRemainingMs(key, nowMs)
    local postAmbushGateActive = postAmbushGateRemainingMs > 0
    local postCombatGraceState = EA_GetPostCombatAmbushGraceState(character, nowMs)
    local postCombatGraceActive = type(postCombatGraceState) == "table" and postCombatGraceState.active == true
    local eligible = (inCombat ~= true)
        and (inBlockedSafeZone ~= true)
        and (rawRegionBlocked ~= true)
        and (regionBlocked ~= true)
        and (regionIsCamp ~= true)
        and (campExitGraceActive ~= true)
        and (postAmbushGateActive ~= true)
        and (postCombatGraceActive ~= true)

    local accumulatedMs = tonumber(accumulatedMsByCharacter[key]) or 0
    local changed = false
    if eligible and deltaMs > 0 then
        accumulatedMs = accumulatedMs + deltaMs
        accumulatedMsByCharacter[key] = accumulatedMs
        changed = true
    elseif accumulatedMsByCharacter[key] == nil then
        accumulatedMsByCharacter[key] = accumulatedMs
        changed = true
    end

    if changed then
        if not EA_WriteTimeInDangerState(state, true) then
            return false, accumulatedMs, "write_failed"
        end
    end

    if EA_StateTimeDebugEnabled() then
        DebugPrint(string.format(
            "[Risk] time_in_danger source=%s char=%s region=%s raw=%s eligible=%s combat=%s blockedSafe=%s rawBlocked=%s blockedRegion=%s camp=%s campExitGraceMs=%d postAmbushGateMs=%d postCombatGraceMs=%d gateStartMs=%d deltaMs=%d accumMs=%d riskUnit=%.3f",
            tostring(opts.source or "unknown"),
            tostring(character),
            tostring(canonicalRegion),
            tostring(rawRegion),
            tostring(eligible),
            tostring(inCombat),
            tostring(inBlockedSafeZone),
            tostring(rawRegionBlocked),
            tostring(regionBlocked),
            tostring(regionIsCamp),
            math.floor(tonumber(campExitGraceState and campExitGraceState.remainingMs) or 0),
            math.floor(tonumber(postAmbushGateRemainingMs) or 0),
            math.floor(tonumber(postCombatGraceState and postCombatGraceState.remainingMs) or 0),
            math.floor(tonumber(postAmbushGateStartAtMs) or 0),
            math.floor(tonumber(deltaMs) or 0),
            math.floor(tonumber(accumulatedMs) or 0),
            tonumber(EA_GetTimeInDangerRiskUnit(character)) or 0
        ))
    end

    local resultReason = eligible and "accumulating" or "blocked"
    if postAmbushGateActive then
        resultReason = "post_ambush_gate"
    elseif campExitGraceActive then
        resultReason = "camp_exit_grace"
    elseif postCombatGraceActive then
        resultReason = "post_combat_grace"
    elseif safeZoneBlockReason ~= "" then
        resultReason = safeZoneBlockReason
    elseif rawRegionBlocked then
        resultReason = "raw_safe_zone_block"
    elseif regionBlocked then
        resultReason = "region_block"
    elseif regionIsCamp then
        resultReason = "camp"
    elseif inCombat then
        resultReason = "combat"
    end
    return true, accumulatedMs, resultReason
end

function EA_RecordRecentAmbushType(character, creatureType)
    if not character or character == "" or not creatureType or creatureType == "" then
        return
    end
    local key = EA_NormalizeUUID(character) or tostring(character)
    local historyFn = EA_AmbushTypeHistory or (EA and EA["EA_AmbushTypeHistory"])
    if type(historyFn) ~= "function" then
        return
    end
    local history = historyFn()
    if not EA_StatePersistentMap(history) then
        return
    end
    local prev = history[key]
    local a, b = nil, nil
    if type(prev) == "table" then
        a = prev[1]
        b = prev[2]
    end

    if a == creatureType then
        history[key] = { creatureType, b }
    else
        history[key] = { creatureType, a }
    end
    EA_Dirty()
end

function EA_GetRecentAmbushTypePenalty(character, creatureType)
    if not character or character == "" or not creatureType or creatureType == "" then
        return 1.0
    end
    local key = EA_NormalizeUUID(character) or tostring(character)
    local historyFn = EA_AmbushTypeHistory or (EA and EA["EA_AmbushTypeHistory"])
    if type(historyFn) ~= "function" then
        return 1.0
    end
    local history = historyFn()
    if not EA_StatePersistentMap(history) then
        return 1.0
    end
    local prev = history[key]
    if type(prev) ~= "table" then
        return 1.0
    end

    local last = prev[1]
    local older = prev[2]
    if last == creatureType then
        return 0.65
    end
    if older == creatureType then
        return 0.82
    end
    return 1.0
end

local EA_DecayTypePressureForKey
function EA_AddTypePressure(character, creatureType, amount)
    local key = EA_TypePressureKey(character, creatureType)
    if not key then return 0 end

    local tbl = EA_TypePressure()
    local lastTbl = EA_TypePressureLastUpdate()
    if not EA_StatePersistentMap(tbl) or not EA_StatePersistentMap(lastTbl) then
        return 0
    end
    local now = EA_NowMs()

    -- Keep type-pressure behavior aligned with global pressure (decay before gain).
    if type(EA_DecayTypePressureForKey) == "function" then
        EA_DecayTypePressureForKey(key, now)
    end

    local old = tonumber(tbl[key]) or 0
    local gain = tonumber(amount) or 0
    local new = old + gain
    if new < 0 then new = 0 end
    if new > 100 then new = 100 end

    if new <= 0 then
        tbl[key] = nil
        lastTbl[key] = nil
    else
        tbl[key] = new
        lastTbl[key] = now
    end

    EA_Dirty()
    return new
end

function EA_ConsumeTypePressure(character, creatureType, amount)
    local spend = tonumber(amount) or 0
    if spend <= 0 then
        return EA_GetTypePressure(character, creatureType)
    end
    return EA_AddTypePressure(character, creatureType, -spend)
end

function EA_GetTypePressureSignature(character, creatureTypes)
    if not character or character == "" then
        return "tp:none"
    end
    if type(creatureTypes) ~= "table" or #creatureTypes == 0 then
        return "tp:empty"
    end

    local parts = {}
    for _, ct in ipairs(creatureTypes) do
        local p = EA_GetTypePressure(character, ct)
        local bucket = math.floor(math.max(0, math.min(100, p)) / 10)
        parts[#parts + 1] = string.format("%s:%d", tostring(ct), bucket)
    end
    return table.concat(parts, ",")
end

function EA_ResetWorldRepWindow(reason)
    local st = EA_WorldRepWindow()
    if not EA_StatePersistentMap(st) then
        return 0
    end
    st.cycle = (tonumber(st.cycle) or 0) + 1
    st.total = 0
    st.perType = {}
    st.lastResetAt = EA_NowMs()
    st.lastResetReason = tostring(reason or "manual")
    EA_Dirty()
    return st.cycle
end

local function EA_DecayAmountForMinutes(p, minutes)
    p = tonumber(p) or 0
    minutes = tonumber(minutes) or 0
    if minutes <= 0 or p <= 0 then return 0 end

    local m = minutes
    local decay = 0

    -- Segment 1: above 80
    if p > 80 and m > 0 then
        local need = p - 80
        local rate = 1.0
        local take = math.min(m, math.ceil(need / rate))
        decay = decay + take * rate
        p = p - take * rate
        m = m - take
    end

    -- Segment 2: 50..80
    if p > 50 and m > 0 then
        local need = p - 50
        local rate = 0.6
        local take = math.min(m, math.ceil(need / rate))
        decay = decay + take * rate
        p = p - take * rate
        m = m - take
    end

    -- Segment 3: below 50
    if m > 0 then
        decay = decay + m * 0.35
    end

    return decay
end

local function EA_DecayPressureForKey(key, now)
    if not EA_StateTimeGetPressureDecayEnabled() then return false end
    if not key or key == "" then return false end

    local tbl = EA_AmbushPressure()
    local lastTbl = EA_AmbushPressureLastUpdate()
    if not EA_StatePersistentMap(tbl) or not EA_StatePersistentMap(lastTbl) then
        return false
    end

    local p = tonumber(tbl[key]) or 0
    if p <= 0 then
        tbl[key] = nil
        lastTbl[key] = nil
        return false
    end

    now = now or EA_NowMs()

    local last = tonumber(lastTbl[key])
    if not last then
        lastTbl[key] = now
        return false
    end

    -- Clamp future timestamps (time source changed / corruption)
    if last > now then
        lastTbl[key] = now
        return false
    end

    local elapsedMs = now - last
    local minutes = math.floor(elapsedMs / 60000)

    if minutes < EA_StateTimeGetPressureDecayMinutesQuantum() then
        return false
    end

    local decay = EA_DecayAmountForMinutes(p, minutes)
    if decay <= 0 then
        -- Still advance last update to prevent huge bursts later
        lastTbl[key] = last + (minutes * 60000)
        return false
    end

    local new = p - decay
    if new < 0 then new = 0 end

    if new <= 0 then
        tbl[key] = nil
        lastTbl[key] = nil
    else
        tbl[key] = new
        -- Preserve remainder: move last forward by whole minutes decayed
        lastTbl[key] = last + (minutes * 60000)
    end

    return true
end

EA_DecayTypePressureForKey = function(key, now)
    if not EA_StateTimeGetPressureDecayEnabled() then return false end
    if not key or key == "" then return false end

    local tbl = EA_TypePressure()
    local lastTbl = EA_TypePressureLastUpdate()
    if not EA_StatePersistentMap(tbl) or not EA_StatePersistentMap(lastTbl) then
        return false
    end

    local p = tonumber(tbl[key]) or 0
    if p <= 0 then
        tbl[key] = nil
        lastTbl[key] = nil
        return false
    end

    now = now or EA_NowMs()
    local last = tonumber(lastTbl[key])
    if not last then
        lastTbl[key] = now
        return false
    end

    if last > now then
        lastTbl[key] = now
        return false
    end

    local elapsedMs = now - last
    local minutes = math.floor(elapsedMs / 60000)
    if minutes < EA_StateTimeGetPressureDecayMinutesQuantum() then
        return false
    end

    local decay = EA_DecayAmountForMinutes(p, minutes)
    if decay <= 0 then
        lastTbl[key] = last + (minutes * 60000)
        return false
    end

    local new = p - decay
    if new < 0 then new = 0 end

    if new <= 0 then
        tbl[key] = nil
        lastTbl[key] = nil
    else
        tbl[key] = new
        lastTbl[key] = last + (minutes * 60000)
    end

    return true
end

local function EA_DecayAllPressures()
    if not EA_StateTimeGetPressureDecayEnabled() then return end
    if not (Osi and Osi.IsGameStateRunning) then return end
    if Osi.IsGameStateRunning() ~= 1 then return end
    if not EA_StatePersistentReady() then return end

    local tbl = EA_AmbushPressure()
    local typeTbl = EA_TypePressure()
    if not EA_StatePersistentMap(tbl) or not EA_StatePersistentMap(typeTbl) then
        return
    end
    local now = EA_NowMs()
    local changed = false

    -- Copy keys (safe mutation)
    local keys = {}
    for k, _ in pairs(tbl) do keys[#keys + 1] = k end

    for i = 1, #keys do
        if EA_DecayPressureForKey(keys[i], now) then
            changed = true
        end
    end

    local typeKeys = {}
    for k, _ in pairs(typeTbl) do typeKeys[#typeKeys + 1] = k end
    for i = 1, #typeKeys do
        if EA_DecayTypePressureForKey(typeKeys[i], now) then
            changed = true
        end
    end

    if changed then
        EA_Dirty() -- debounced now
    end
end

function EA_InitPressureDecayState()
    if not EA_StatePersistentReady() then
        return
    end

    -- One-time sanity pass each load: ensure lastUpdate is sane vs current time base
    local tbl = EA_AmbushPressure()
    local lastTbl = EA_AmbushPressureLastUpdate()
    local typeTbl = EA_TypePressure()
    local typeLastTbl = EA_TypePressureLastUpdate()
    if not EA_StatePersistentMap(tbl) or not EA_StatePersistentMap(lastTbl)
        or not EA_StatePersistentMap(typeTbl) or not EA_StatePersistentMap(typeLastTbl) then
        return
    end
    local now = EA_NowMs()

    local WALL_EPOCH_CUTOFF = 1000000000000
    local nowLooksGame = (now < WALL_EPOCH_CUTOFF)

    local keys = {}
    for k, _ in pairs(tbl) do keys[#keys + 1] = k end

    local touched = false
    for i = 1, #keys do
        local k = keys[i]
        local p = tonumber(tbl[k]) or 0
        if p <= 0 then
            tbl[k] = nil
            lastTbl[k] = nil
            touched = true
        else
            local last = tonumber(lastTbl[k])
            if not last then
                lastTbl[k] = now
                touched = true
            else
                -- If last looks like wallclock but now is game-time, reset to now to avoid massive instant decay
                local lastLooksWall = (last >= WALL_EPOCH_CUTOFF)
                if nowLooksGame and lastLooksWall then
                    lastTbl[k] = now
                    touched = true
                elseif last > now then
                    lastTbl[k] = now
                    touched = true
                end
            end
        end
    end

    local typeKeys = {}
    for k, _ in pairs(typeTbl) do typeKeys[#typeKeys + 1] = k end

    for i = 1, #typeKeys do
        local k = typeKeys[i]
        local p = tonumber(typeTbl[k]) or 0
        if p <= 0 then
            typeTbl[k] = nil
            typeLastTbl[k] = nil
            touched = true
        else
            local last = tonumber(typeLastTbl[k])
            if not last then
                typeLastTbl[k] = now
                touched = true
            else
                local lastLooksWall = (last >= WALL_EPOCH_CUTOFF)
                if nowLooksGame and lastLooksWall then
                    typeLastTbl[k] = now
                    touched = true
                elseif last > now then
                    typeLastTbl[k] = now
                    touched = true
                end
            end
        end
    end

    if touched then
        EA_Dirty() -- debounced
    end
end

function EA_StartPressureDecayLoop()
    if not (Ext and Ext.Timer and Ext.Timer.WaitFor) then return end
    EnemyAmbush._eaPressureDecayLoopRunning = EnemyAmbush._eaPressureDecayLoopRunning or false
    if EnemyAmbush._eaPressureDecayLoopRunning then return end
    EnemyAmbush._eaPressureDecayLoopRunning = true

    local function loop()
        -- If session not running, just reschedule (keeps it safe during loads)
        EA_DecayAllPressures()
        Ext.Timer.WaitFor(EA_StateTimeGetPressureDecayIntervalMs(), loop)
    end

    Ext.Timer.WaitFor(EA_StateTimeGetPressureDecayIntervalMs(), loop)
end

function EA_AddAmbushPressure(character, isLongRest)
    local key = EA_NormalizeUUID(character) or character
    local tbl = EA_AmbushPressure()
    local lastTbl = EA_AmbushPressureLastUpdate()
    if not EA_StatePersistentMap(tbl) or not EA_StatePersistentMap(lastTbl) then
        return 0
    end
    local now = EA_NowMs()

    -- Apply any pending decay before we add more
    EA_DecayPressureForKey(key, now)

    local old = tonumber(tbl[key]) or 0

    local baseGain = isLongRest and EA_StateTimeGetPressureGainLong() or EA_StateTimeGetPressureGainShort()
    local gain = tonumber(baseGain) or 0

    -- Keep balance consistent across presets:
    -- chance mult affects both RNG chance and pressure gain.
    local cm = EA_GetChanceMultiplierSafe()
    local rm = EA_GetRegionPressureMult(character)

    gain = gain * cm * rm
    if gain < 0 then gain = 0 end

    local new = old + gain
    local pressureMax = EA_StateTimeGetPressureMax()
    if new > pressureMax then new = pressureMax end
    if new < 0 then new = 0 end

    if new <= 0 then
        tbl[key] = nil
        lastTbl[key] = nil
    else
        tbl[key] = new
        lastTbl[key] = now
    end

    EA_Dirty()

    -- Minimal UX: only notify once when reaching 100
    if old < pressureMax and new >= pressureMax then
        DebugPrint("Ambush pressure reached 100%:", tostring(character))
    end

    return new
end

function EA_ClearLootButKeepCorpseClickable(corpse)
    if not corpse or corpse == "" then return end
    if not Osi then
        return
    end

    -- Keep corpse interactable; strip generated/trade loot only.
    if Osi.SetCharacterLootable then
        pcall(Osi.SetCharacterLootable, corpse, 1)
    end
    if Osi.SetIsDroppedOnDeath then
        pcall(Osi.SetIsDroppedOnDeath, corpse, 0)
    end
    if Osi.ClearTradeGeneratedItems then
        pcall(Osi.ClearTradeGeneratedItems, corpse)
    end
end

-- ========= TIME SOURCE (PERSISTENT TIMESTAMPS) =========
-- Persisted timestamps are wall-clock authoritative in this cycle.
-- Game-time probing remains diagnostics-only until a documented provider is
-- validated for all target runtimes.
local EA_TIME_MODE = "WALL" -- runtime clock mode for EA_NowMs
local EA_PERSISTED_TIME_POLICY = "WALL_CLOCK_AUTH"

-- Script Extender-safe monotonic clock (works even during early load; does not require Lua 'os')
local function EA_MonotonicMs()
    if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
        local ok, t = pcall(Ext.Utils.MonotonicTime)
        local n = tonumber(t)
        if ok and n then
            -- BG3SE exposes monotonic milliseconds on the supported runtimes for
            -- this mod. Inflating that value by 1000 breaks delta-based systems.
            return math.floor(n)
        end
    end
    return 0
end

local function EA_WallClockStrictMs()
    -- Returns nil when wall clock is unavailable.
    if os and os.time then
        local ok, t = pcall(os.time)
        if ok and t then
            local base = tonumber(t) * 1000
            -- Optional: add sub-second-ish jitter from monotonic (harmless)
            local mono = EA_MonotonicMs()
            if mono > 0 then
                base = base + (mono % 1000)
            end
            return math.floor(base)
        end
    end
    return nil
end

-- Best-effort wall clock.
function EA_WallClockMs()
    local wall = EA_WallClockStrictMs()
    if wall then
        return wall
    end
    -- Safe runtime fallback (session only).
    return EA_MonotonicMs()
end

local EA_GAME_TIME_DIAG = {
    lastReason = "uninitialized",
    lastDetail = "",
    lastType = "",
    lastRaw = nil,
    failures = 0,
    updatedAt = 0,
}

local function EA_SetGameTimeDiag(reason, detail, rawType, rawValue)
    EA_GAME_TIME_DIAG.lastReason = tostring(reason or "unknown")
    EA_GAME_TIME_DIAG.lastDetail = tostring(detail or "")
    EA_GAME_TIME_DIAG.lastType = tostring(rawType or "")
    EA_GAME_TIME_DIAG.lastRaw = rawValue
    EA_GAME_TIME_DIAG.updatedAt = EA_MonotonicMs()
    if reason == "ok" then
        EA_GAME_TIME_DIAG.failures = 0
    else
        EA_GAME_TIME_DIAG.failures = (tonumber(EA_GAME_TIME_DIAG.failures) or 0) + 1
    end
end

function EA_GetGameTimeDiagnostics()
    return {
        reason = tostring(EA_GAME_TIME_DIAG.lastReason or "unknown"),
        detail = tostring(EA_GAME_TIME_DIAG.lastDetail or ""),
        rawType = tostring(EA_GAME_TIME_DIAG.lastType or ""),
        raw = EA_GAME_TIME_DIAG.lastRaw,
        failures = tonumber(EA_GAME_TIME_DIAG.failures) or 0,
        updatedAt = tonumber(EA_GAME_TIME_DIAG.updatedAt) or 0,
    }
end

local function EA_NormalizeGameTimeValue(value)
    local n = tonumber(value)
    if not n or n < 0 then
        return nil
    end
    -- Some runtimes expose seconds; normalize to ms.
    if n <= 315576000 then
        return math.floor(n * 1000)
    end
    return math.floor(n)
end

function EA_ProbeGameTimeMs()
    if not (Osi and Osi.GetTime) then
        EA_SetGameTimeDiag("missing_gettime", "Osi.GetTime unavailable", "", nil)
        return nil, "missing_gettime"
    end

    local ok, a, b, c, d = pcall(Osi.GetTime)
    if not ok then
        EA_SetGameTimeDiag("gettime_error", tostring(a or "unknown_error"), "", nil)
        return nil, "gettime_error"
    end

    local raw = a
    local rawType = type(raw)
    local normalized = nil
    if rawType == "table" then
        normalized = EA_NormalizeGameTimeValue(raw.Global or raw.global or raw["Global"])
        if not normalized then
            for _, key in ipairs({ "GameTime", "gameTime", "Time", "time", "Value", "value" }) do
                normalized = EA_NormalizeGameTimeValue(raw[key])
                if normalized then
                    break
                end
            end
        end
        if not normalized then
            local best = nil
            for _, v in pairs(raw) do
                local candidate = EA_NormalizeGameTimeValue(v)
                if candidate and (not best or candidate > best) then
                    best = candidate
                end
            end
            normalized = best
        end
    else
        normalized = EA_NormalizeGameTimeValue(raw)
    end

    if not normalized then
        normalized = EA_NormalizeGameTimeValue(b) or EA_NormalizeGameTimeValue(c) or EA_NormalizeGameTimeValue(d)
    end
    if not normalized then
        EA_SetGameTimeDiag(
            "provider_returned_nil",
            string.format("a=%s b=%s c=%s d=%s", tostring(a), tostring(b), tostring(c), tostring(d)),
            rawType,
            raw
        )
        return nil, "provider_returned_nil"
    end

    EA_SetGameTimeDiag("ok", "", rawType, raw)
    return normalized, "ok"
end

function EA_GameTimeMs()
    local now = EA_ProbeGameTimeMs()
    return now
end

EA_NowMs = function()
    if EA_TIME_MODE == "WALL" then
        return EA_WallClockMs()
    end

    local gt = EA_GameTimeMs()
    if gt then return gt end

    -- During early SessionLoaded / tutorial ship / not-fully-ready phases,
    -- game-time queries can return nil. Never fall back to 'os' here.
    return EA_MonotonicMs()
end

-- Persisted cooldown timestamps are wall-clock authoritative in this cycle.
local EA_PERSISTED_TIME_LOG_LAST = 0
local EA_PERSISTED_TIME_LOG_INTERVAL_MS = 60000
local EA_PERSISTED_TIME_SKIP_COUNT = 0
local EA_PERSISTED_TIME_SOURCE_COUNT = 0
local EA_PERSISTED_LAST_WALL_MS = nil
local EA_PERSISTED_LAST_MONO_MS = 0

local function EA_LogPersistedTimeUnavailable(reason)
    local nowMono = 0
    if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
        nowMono = tonumber(Ext.Utils.MonotonicTime()) or 0
    end
    if nowMono > 0 and (nowMono - EA_PERSISTED_TIME_LOG_LAST) < EA_PERSISTED_TIME_LOG_INTERVAL_MS then
        EA_PERSISTED_TIME_SKIP_COUNT = EA_PERSISTED_TIME_SKIP_COUNT + 1
        return
    end
    if nowMono <= 0 then
        nowMono = EA_PERSISTED_TIME_LOG_LAST + EA_PERSISTED_TIME_LOG_INTERVAL_MS
    end
    EA_PERSISTED_TIME_LOG_LAST = nowMono
    local skipped = EA_PERSISTED_TIME_SKIP_COUNT
    EA_PERSISTED_TIME_SKIP_COUNT = 0
    local diag = (type(EA_GetGameTimeDiagnostics) == "function") and EA_GetGameTimeDiagnostics() or nil
    local detail = ""
    if type(diag) == "table" then
        detail = string.format(
            " gameTimeProbe=%s detail=%s rawType=%s",
            tostring(diag.reason or "unknown"),
            tostring(diag.detail or ""),
            tostring(diag.rawType or "")
        )
    end
    print(string.format(
        "[EnemyAmbush][Time] Persisted timestamp skipped (%s). wall-clock unavailable. skipped=%d%s",
        tostring(reason or "unknown"),
        tonumber(skipped) or 0,
        tostring(detail)
    ))
end

local function EA_LogPersistedTimeSource(source)
    local nowMono = EA_MonotonicMs()
    EA_PERSISTED_TIME_SOURCE_COUNT = EA_PERSISTED_TIME_SOURCE_COUNT + 1
    if nowMono > 0 and (nowMono - EA_PERSISTED_TIME_LOG_LAST) < EA_PERSISTED_TIME_LOG_INTERVAL_MS then
        return
    end
    EA_PERSISTED_TIME_LOG_LAST = nowMono
    print(string.format(
        "[EnemyAmbush][Time] Persisted timestamp source=%s count=%d",
        tostring(source or "unknown"),
        tonumber(EA_PERSISTED_TIME_SOURCE_COUNT) or 0
    ))
end

function EA_PersistedNowMs()
    local monoNow = EA_MonotonicMs()
    local wall = EA_WallClockStrictMs()
    if wall then
        EA_PERSISTED_LAST_WALL_MS = math.floor(wall)
        EA_PERSISTED_LAST_MONO_MS = monoNow
        EA_LogPersistedTimeSource("wall_clock")
        return math.floor(wall)
    end

    -- Bounded continuity fallback: if strict wall-clock is temporarily unavailable,
    -- continue from the last known wall-clock stamp using monotonic delta.
    if EA_PERSISTED_LAST_WALL_MS and monoNow > 0 and EA_PERSISTED_LAST_MONO_MS > 0 and monoNow >= EA_PERSISTED_LAST_MONO_MS then
        local estimated = EA_PERSISTED_LAST_WALL_MS + (monoNow - EA_PERSISTED_LAST_MONO_MS)
        EA_LogPersistedTimeSource("wall_clock_estimate")
        return math.floor(estimated)
    end

    -- Last-resort fallback when strict wall-clock is unavailable from process start.
    -- This prevents nil persisted timestamps (cooldown stamp skips) in runtimes where
    -- os.time is not exposed, while still keeping monotonic progression in-session.
    if monoNow > 0 then
        EA_PERSISTED_LAST_WALL_MS = monoNow
        EA_PERSISTED_LAST_MONO_MS = monoNow
        EA_LogPersistedTimeSource("monotonic_seed")
        return math.floor(monoNow)
    end

    EA_LogPersistedTimeUnavailable("missing_wall_clock")
    return nil
end

function EA_GetPersistedTimePolicy()
    return {
        mode = tostring(EA_TIME_MODE),
        policy = tostring(EA_PERSISTED_TIME_POLICY),
        persistedSource = "wall_clock_with_monotonic_estimate_or_seed",
        gameTimeProbeOnly = true,
    }
end

-- Export time helpers so other split files can access them reliably
EnemyAmbush.EA_WallClockMs = EA_WallClockMs
EnemyAmbush.EA_GameTimeMs  = EA_GameTimeMs
EnemyAmbush.EA_NowMs       = EA_NowMs
EnemyAmbush.EA_PersistedNowMs = EA_PersistedNowMs
EnemyAmbush.EA_GetGameTimeDiagnostics = EA_GetGameTimeDiagnostics
EnemyAmbush.EA_ProbeGameTimeMs = EA_ProbeGameTimeMs
EnemyAmbush.EA_GetPersistedTimePolicy = EA_GetPersistedTimePolicy

-- Legacy migration helper (retained for backward compatibility with older saves).
-- Current policy is wall-clock persisted time; this path only matters if a future
-- cycle re-enables a game-time persisted source.
local function EA_MigrateTsToCurrentTimeBase(ts, nowGame, nowWall)
    ts = tonumber(ts)
    if not ts then return nil end

    -- If game time isn't available, do nothing special (stay wall).
    if not nowGame then return ts end

    -- Old wall-clock ms since epoch is usually > 1e12 (year ~2001+). Game-time ms is normally far smaller.
    local WALL_EPOCH_CUTOFF = 1000000000000

    local looksWall = (ts >= WALL_EPOCH_CUTOFF) and (nowGame < WALL_EPOCH_CUTOFF)
    if looksWall then
        local age = (nowWall or EA_WallClockMs()) - ts
        if (not age) or age < 0 then
            -- Clock moved backwards / corrupted: clamp to "now"
            return nowGame
        end
        local migrated = nowGame - age
        if migrated < 0 then migrated = 0 end
        return migrated
    end

    -- Same time base: clamp "future" timestamps
    if ts > nowGame then
        return nowGame
    end
    return ts
end

function EA_SanitizePersistedTimes()
    if not EA_StatePersistentReady() then
        return
    end

    local varsFn = EA and EA["EA_Vars"]
    local v = (type(varsFn) == "function") and varsFn() or nil
    if type(v) ~= "table" and type(v) ~= "userdata" then
        return
    end

    -- Migration versioning so we only do the wall->game conversion once per save
    local TARGET_VER = 2
    local nowGame = (type(EA_GameTimeMs) == "function" and EA_GameTimeMs()) or nil
    local nowWall = (type(EA_WallClockMs) == "function" and EA_WallClockMs()) or nil
    local now = (type(EA_PersistedNowMs) == "function") and EA_PersistedNowMs() or nil
    if not now then
        return
    end

    local doMigrate = (v.EA_TimeSourceVersion ~= TARGET_VER)

    -- Clamp / migrate cooldown timestamps
    local lastTbl = EA_LastAmbushTime()
    for k, value in pairs(lastTbl) do
        local ts = tonumber(value)
        if ts then
            if doMigrate then
                ts = EA_MigrateTsToCurrentTimeBase(ts, nowGame or now, nowWall)
            end
            if ts and ts > now then ts = now end
            lastTbl[k] = ts
        end
    end

    -- Clamp / migrate type-pressure timestamps
    local typeLastTbl = EA_TypePressureLastUpdate()
    for k, value in pairs(typeLastTbl) do
        local ts = tonumber(value)
        if ts then
            if doMigrate then
                ts = EA_MigrateTsToCurrentTimeBase(ts, nowGame or now, nowWall)
            end
            if ts and ts > now then ts = now end
            typeLastTbl[k] = ts
        end
    end

    -- Pressure values persist across sessions, but pressure timestamps are session
    -- baseline state to avoid stale/offline decay spikes after reload.
    local ambushLastTbl = EA_AmbushPressureLastUpdate()
    for k, _ in pairs(ambushLastTbl) do
        ambushLastTbl[k] = now
    end
    for k, _ in pairs(typeLastTbl) do
        typeLastTbl[k] = now
    end

    local timeInDanger = EA_TimeInDangerState()
    local timeInDangerTouched = false
    if EA_StatePersistentMap(timeInDanger) then
        local dangerLastTbl = timeInDanger.lastTickAtMsByCharacter
        if EA_StatePersistentMap(dangerLastTbl) then
            for k, _ in pairs(dangerLastTbl) do
                dangerLastTbl[k] = now
                timeInDangerTouched = true
            end
        end
        local dangerTravelLastTbl = timeInDanger.lastTravelCheckAtMsByCharacter
        if EA_StatePersistentMap(dangerTravelLastTbl) then
            for k, _ in pairs(dangerTravelLastTbl) do
                dangerTravelLastTbl[k] = now
                timeInDangerTouched = true
            end
        end
        local dangerAccumTbl = timeInDanger.accumulatedMsByCharacter
        if EA_StatePersistentMap(dangerAccumTbl) then
            for k, value in pairs(dangerAccumTbl) do
                local accum = tonumber(value) or 0
                if accum < 0 then
                    dangerAccumTbl[k] = 0
                    timeInDangerTouched = true
                else
                    local normalizedAccum = math.floor(accum)
                    if dangerAccumTbl[k] ~= normalizedAccum then
                        dangerAccumTbl[k] = normalizedAccum
                        timeInDangerTouched = true
                    end
                end
            end
        end
        if timeInDangerTouched then
            EA_WriteTimeInDangerState(timeInDanger, true)
        end
    end

    -- Clamp / migrate champion per-type cooldown timestamps
    local champLast = v.EA_ChampionLastSpawnByType
    if type(champLast) == "table" then
        for k, value in pairs(champLast) do
            local ts = tonumber(value)
            if ts then
                if doMigrate then
                    ts = EA_MigrateTsToCurrentTimeBase(ts, nowGame or now, nowWall)
                end
                if ts and ts > now then ts = now end
                champLast[k] = ts
            end
        end
    end

    -- Clamp / migrate guaranteed queue timestamps
    local q = EA_GuaranteedChampionQueue()
    for _, entry in pairs(q) do
        if type(entry) == "table" and entry.ts ~= nil then
            local ts = tonumber(entry.ts)
            if ts then
                if doMigrate then
                    ts = EA_MigrateTsToCurrentTimeBase(ts, nowGame or now, nowWall)
                end
                if ts and ts > now then ts = now end
                entry.ts = ts
            end
        end
    end

    -- Clamp / migrate armed timestamp too
    if v.GuaranteedChampionArmed and type(v.GuaranteedChampionArmed) == "table" and v.GuaranteedChampionArmed.ts ~= nil then
        local ts = tonumber(v.GuaranteedChampionArmed.ts)
        if ts then
            if doMigrate then
                ts = EA_MigrateTsToCurrentTimeBase(ts, nowGame or now, nowWall)
            end
            if ts and ts > now then ts = now end
            v.GuaranteedChampionArmed.ts = ts
        end
    end

    -- IMPORTANT: do not call EA_Pending() during SessionLoaded sanitization.
    -- That accessor auto-initializes PersistentPendingAmbushes when the field is
    -- absent, which can overwrite a not-yet-hydrated pending store with an
    -- empty table before deferred timer relaunch runs.
    local pending = v.PersistentPendingAmbushes
    if EA_StatePersistentMap(pending) then
        for _, data in pairs(pending) do
            if type(data) == "table" and data.timestamp ~= nil then
                local ts = tonumber(data.timestamp)
                if ts then
                    if doMigrate then
                        ts = EA_MigrateTsToCurrentTimeBase(ts, nowGame or now, nowWall)
                    end
                    if ts and ts > now then ts = now end
                    data.timestamp = ts
                end
            end
        end
    end

    local deferredRest = v.EA_RestDeferredState
    if EA_StatePersistentMap(deferredRest) and deferredRest.timestamp ~= nil then
        local ts = tonumber(deferredRest.timestamp)
        if ts then
            if doMigrate then
                ts = EA_MigrateTsToCurrentTimeBase(ts, nowGame or now, nowWall)
            end
            if ts and ts > now then ts = now end
            deferredRest.timestamp = ts
        end
    end

    local worldRep = EA_WorldRepWindow()
    if worldRep and worldRep.lastResetAt ~= nil then
        local ts = tonumber(worldRep.lastResetAt)
        if ts then
            if doMigrate then
                ts = EA_MigrateTsToCurrentTimeBase(ts, nowGame or now, nowWall)
            end
            if ts and ts > now then ts = now end
            worldRep.lastResetAt = ts
        end
    end

    -- Clamp / migrate spawned tracking timestamps (IMPORTANT for eviction ordering)
    local spawned = EA_Spawned()
    if EA_StatePersistentMap(spawned) then
        for _, data in pairs(spawned) do
            if type(data) == "table" then
                if data.tsCreated ~= nil then
                    local ts = tonumber(data.tsCreated)
                    if ts then
                        if doMigrate then
                            ts = EA_MigrateTsToCurrentTimeBase(ts, nowGame or now, nowWall)
                        end
                        if ts and ts > now then ts = now end
                        data.tsCreated = ts
                    end
                end
                if data.lastSeen ~= nil then
                    local ts = tonumber(data.lastSeen)
                    if ts then
                        if doMigrate then
                            ts = EA_MigrateTsToCurrentTimeBase(ts, nowGame or now, nowWall)
                        end
                        if ts and ts > now then ts = now end
                        data.lastSeen = ts
                    end
                end
            end
        end
    end

    if doMigrate then
        v.EA_TimeSourceVersion = TARGET_VER
    end

    -- Use immediate flush if your debounced EA_Dirty supports it; extra args are ignored safely if not.
    EA_Dirty(true)
end
