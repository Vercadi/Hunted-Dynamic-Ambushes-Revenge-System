EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local EA_P0Inc = EA["EA_P0Inc"] or function() return 0 end
local EA_ReadSettingBool = EA["EA_ReadSettingBool"]
local M = {}

local function EA_DebugEnabled()
    if type(EA_ReadSettingBool) == "function" then
        return EA_ReadSettingBool("MCM_DebugMode", false) == true
    end
    return false
end

local function EA_IsRestAmbushEnabled()
    local fn = EA and EA["EA_IsRestAmbushEnabled"]
    if type(fn) == "function" then
        return fn() == true
    end
    return true
end

local function EA_RandomSeconds(minS, maxS)
    local fn = EA and EA["RandomSeconds"]
    if type(fn) == "function" then
        local ok, out = pcall(fn, minS, maxS)
        if ok and tonumber(out) then
            return math.floor(tonumber(out))
        end
    end
    local lo = math.floor(tonumber(minS) or 0)
    local hi = math.floor(tonumber(maxS) or lo)
    if hi < lo then lo, hi = hi, lo end
    if hi <= lo then return lo end
    local safeRandInt = EA and EA["EA_RandIntSafe"]
    if type(safeRandInt) == "function" then
        local ok, out = pcall(safeRandInt, lo, hi)
        if ok and tonumber(out) then
            return math.floor(tonumber(out))
        end
    end
    return lo + math.floor((hi - lo) * 0.5)
end

local function EA_RecordRestStat(kind, key, delta)
    local fn = EA and EA["EA_RecordRestStat"]
    if type(fn) == "function" then
        pcall(fn, kind, key, delta)
    end
end

local function EA_LogRestFlow(fmt, ...)
    local msg = fmt
    if select("#", ...) > 0 then
        msg = string.format(fmt, ...)
    end
    print(string.format("[EnemyAmbush][RestFlow] %s", tostring(msg or "")))
end

local function EA_GetCfgNumber(key, fallback)
    local cfg = EA and EA.CFG or {}
    local value = tonumber(cfg and cfg[key])
    if value == nil then
        return tonumber(fallback) or 0
    end
    return value
end

local SHORT_TRIGGER_MIN = EA_GetCfgNumber("SHORT_TRIGGER_MIN", 0)
local SHORT_TRIGGER_MAX = EA_GetCfgNumber("SHORT_TRIGGER_MAX", 10 * 60)
local LONG_TRIGGER_MIN = EA_GetCfgNumber("LONG_TRIGGER_MIN", 2 * 60)
local LONG_TRIGGER_MAX = EA_GetCfgNumber("LONG_TRIGGER_MAX", 20 * 60)
local QUICK_TEST_REST_DELAY_SECONDS = 10

local function EA_IsQuickTestMode()
    local fn = EA and EA["EA_IsQuickTestMode"]
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok then
            return out == true
        end
    end
    if type(EA_ReadSettingBool) == "function" then
        return EA_ReadSettingBool("MCM_QuickTestMode", false) == true
    end
    return false
end

local function EA_GetRestDelayWindowSeconds(isLongRest)
    if EA_IsQuickTestMode() then
        return QUICK_TEST_REST_DELAY_SECONDS, QUICK_TEST_REST_DELAY_SECONDS
    end

    local fallbackMin = isLongRest and LONG_TRIGGER_MIN or SHORT_TRIGGER_MIN
    local fallbackMax = isLongRest and LONG_TRIGGER_MAX or SHORT_TRIGGER_MAX

    local fn = EA and EA["EA_GetRestDelayWindowMinutes"]
    if type(fn) == "function" then
        local ok, minMinutes, maxMinutes = pcall(fn, isLongRest == true)
        if ok and tonumber(minMinutes) and tonumber(maxMinutes) then
            local minSeconds = math.floor(math.max(0, tonumber(minMinutes)) * 60)
            local maxSeconds = math.floor(math.max(0, tonumber(maxMinutes)) * 60)
            if maxSeconds < minSeconds then
                minSeconds, maxSeconds = maxSeconds, minSeconds
            end
            return minSeconds, maxSeconds
        end
    end

    if fallbackMax < fallbackMin then
        fallbackMin, fallbackMax = fallbackMax, fallbackMin
    end
    return fallbackMin, fallbackMax
end

local function EA_GetActiveRestTimer()
    local state = EA and EA.EA_ActiveRestTimer
    if type(state) == "table" and type(state.timer) == "string" and state.timer ~= "" then
        return state
    end
    return nil
end

local function EA_ClearPendingRestPayload(timer)
    if type(timer) ~= "string" or timer == "" then
        return
    end
    local pendingFn = EA and EA["EA_Pending"]
    local dirtyFn = EA and EA["EA_Dirty"]
    local varsFn = EA and EA["EA_Vars"]
    if type(pendingFn) ~= "function" then
        pendingFn = nil
    end
    local pending = nil
    if type(pendingFn) == "function" then
        local okPending, pendingOut = pcall(pendingFn)
        if okPending and (type(pendingOut) == "table" or type(pendingOut) == "userdata") then
            pending = pendingOut
        end
    end
    local touched = false
    if pending and pending[timer] ~= nil then
        pending[timer] = nil
        touched = true
    end
    if type(varsFn) == "function" then
        local okVars, vars = pcall(varsFn)
        if okVars and (type(vars) == "table" or type(vars) == "userdata") then
            local mirror = vars.EA_RestDeferredState
            if (type(mirror) == "table" or type(mirror) == "userdata")
                and tostring(mirror.timer or "") == timer then
                vars.EA_RestDeferredState = nil
                touched = true
            end
        end
    end
    if touched and type(dirtyFn) == "function" then
        pcall(dirtyFn, true)
    end
end

local function EA_ReplaceActiveRestTimer(timer, kind, character, stage)
    if type(timer) ~= "string" or timer == "" then
        return
    end

    local current = EA_GetActiveRestTimer()
    if current and current.timer ~= timer then
        if Osi and Osi.TimerCancel then
            pcall(Osi.TimerCancel, current.timer)
        end
        EA_ClearPendingRestPayload(current.timer)
        EA_RecordRestStat((kind == "long") and "long" or "short", "replacedPending", 1)
        EA_LogRestFlow(
            "replaced pending %s timer=%s with %s timer=%s",
            tostring(current.kind or "rest"),
            tostring(current.timer),
            tostring(kind or "rest"),
            tostring(timer)
        )
    end

    EA.EA_ActiveRestTimer = {
        timer = timer,
        kind = tostring(kind or "rest"),
        character = tostring(character or ""),
        stage = tostring(stage or ""),
        setAt = (Ext and Ext.Utils and Ext.Utils.MonotonicTime and Ext.Utils.MonotonicTime()) or 0,
    }
end

EA.EA_ShortRestAmbushScheduled = EA.EA_ShortRestAmbushScheduled or false
EA.EA_ShortRestStarter = EA.EA_ShortRestStarter or nil
EA.EA_LongRestAmbushScheduled = EA.EA_LongRestAmbushScheduled or false
EA.EA_LongRestCandidates = EA.EA_LongRestCandidates or {}
EA.EA_ActiveRestTimer = EA.EA_ActiveRestTimer or nil

function M.Build(_deps)
    local Runtime = {}
    local restTriggerListenersRegistered = false

    function Runtime.RegisterRestTriggerListeners()
        if restTriggerListenersRegistered then
            EA_P0Inc("listenerRegGuard.RegisterRestTriggerListeners")
            return false
        end
        EA_P0Inc("listenerReg.RegisterRestTriggerListeners")
        if not (Ext and Ext.Osiris and Ext.Osiris.RegisterListener) then
            return
        end
        restTriggerListenersRegistered = true
        EA_P0Inc("listenerReg.MessageBoxClosed.after")
        Ext.Osiris.RegisterListener("MessageBoxClosed", 2, "after", function(player, id)
            if not Ext.IsServer() then return end
            local sid = tostring(id or "")
            if not EA_DebugEnabled() and sid:sub(1, 3) ~= "EA_" then
                return
            end
            print(string.format(
                "[EnemyAmbush][MsgBox] MessageBoxClosed: player=%s id=%s",
                tostring(player),
                sid
            ))
        end)

        EA_P0Inc("listenerReg.MessageBoxYesNoClosed.after")
        Ext.Osiris.RegisterListener("MessageBoxYesNoClosed", 3, "after", function(player, id, answer)
            if not Ext.IsServer() then return end
            local sid = tostring(id or "")
            if not EA_DebugEnabled() and sid:sub(1, 3) ~= "EA_" then
                return
            end
            print(string.format(
                "[EnemyAmbush][MsgBox] MessageBoxYesNoClosed: player=%s id=%s answer=%s",
                tostring(player),
                sid,
                tostring(answer)
            ))
        end)

        EA_P0Inc("listenerReg.ShortRestProcessing.after")
        Ext.Osiris.RegisterListener("ShortRestProcessing", 1, "after", function(character)
            if not Ext.IsServer() then return end
            if Osi.IsPlayer(character) ~= 1 then return end
            if not EA_IsRestAmbushEnabled() then return end
            EA_RecordRestStat("short", "processing", 1)
            EA.EA_ShortRestAmbushScheduled = false
            EA.EA_ShortRestStarter = character
        end)

        EA_P0Inc("listenerReg.ShortRested.after")
        Ext.Osiris.RegisterListener("ShortRested", 1, "after", function(character)
            if not Ext.IsServer() then return end
            if Osi.IsPlayer(character) ~= 1 then return end
            if not EA_IsRestAmbushEnabled() then return end

            EA_RecordRestStat("short", "shortRestedEvent", 1)
            if EA.EA_ShortRestAmbushScheduled then
                EA_RecordRestStat("short", "debounced", 1)
                return
            end

            if EA.EA_ShortRestStarter and character ~= EA.EA_ShortRestStarter then
                EA_RecordRestStat("short", "starterMismatchIgnored", 1)
                return
            end

            EA.EA_ShortRestAmbushScheduled = true

            local shortMinSeconds, shortMaxSeconds = EA_GetRestDelayWindowSeconds(false)
            local delay = EA_RandomSeconds(shortMinSeconds, shortMaxSeconds)
            local timer = string.format("EA_SR_%s_%d", tostring(character), Ext.Utils.MonotonicTime())
            EA_ReplaceActiveRestTimer(timer, "short", character, "initial")
            EA_RecordRestStat("short", "scheduled", 1)
            EA_LogRestFlow("scheduled ShortRest for %s in %ds (%s)", tostring(character), delay, tostring(timer))
            Osi.TimerLaunch(timer, delay * 1000)
        end)

        EA_P0Inc("listenerReg.LongRestStarted.after")
        Ext.Osiris.RegisterListener("LongRestStarted", 0, "after", function()
            if not Ext.IsServer() then return end
            EA_RecordRestStat("long", "started", 1)
            EA.EA_LongRestAmbushScheduled = false
            EA.EA_LongRestCandidates = {}
        end)

        EA_P0Inc("listenerReg.LongRestCancelled.after")
        Ext.Osiris.RegisterListener("LongRestCancelled", 0, "after", function()
            if not Ext.IsServer() then return end
            EA_RecordRestStat("long", "cancelled", 1)
            EA.EA_LongRestAmbushScheduled = false
            EA.EA_LongRestCandidates = {}
        end)

        EA_P0Inc("listenerReg.LongRestFinished.after")
        Ext.Osiris.RegisterListener("LongRestFinished", 0, "after", function()
            if not Ext.IsServer() then return end
            EA_RecordRestStat("long", "finished", 1)

            local incRestCycle = EA and EA["EA_IncrementRestCycleCounter"]
            if type(incRestCycle) == "function" then
                local cycle = incRestCycle("long_rest_finished")
                if EA_DebugEnabled() then
                    print(string.format("[EnemyAmbush][RestFlow] long-rest cycle incremented: cycle=%s", tostring(cycle)))
                end
            end

            local resetWorldRep = EA and EA["EA_ResetWorldRepWindow"]
            if type(resetWorldRep) == "function" then
                local cycle = resetWorldRep("long_rest_finished")
                if EA_DebugEnabled() then
                    print(string.format("[EnemyAmbush][WorldRep] long-rest window reset: cycle=%s", tostring(cycle)))
                end
            end

            if not EA_IsRestAmbushEnabled() then return end

            EA.EA_LongRestAmbushScheduled = false
            EA.EA_LongRestCandidates = {}

            if Osi and Osi.DB_Players and Osi.DB_Players.Get then
                local ok, rows = pcall(Osi.DB_Players.Get, Osi.DB_Players, nil)
                if ok and rows then
                    for _, row in ipairs(rows) do
                        local character = row[1]
                        if character and character ~= "" and Osi.IsPlayer(character) == 1 then
                            table.insert(EA.EA_LongRestCandidates, character)
                        end
                    end
                end
            end
            EA_RecordRestStat("long", "candidateCount", tonumber(EA.EA_LongRestCandidates and #EA.EA_LongRestCandidates) or 0)

            if EA.EA_LongRestAmbushScheduled then
                EA_RecordRestStat("long", "debounced", 1)
                print("[EnemyAmbush] Long rest: already scheduled (debounced).")
                return
            end

            if not EA.EA_LongRestCandidates or #EA.EA_LongRestCandidates == 0 then
                EA_RecordRestStat("long", "noCandidates", 1)
                print("[EnemyAmbush] Long rest: no valid player characters found to schedule ambush.")
                return
            end

            local mono = (Ext and Ext.Utils and Ext.Utils.MonotonicTime and Ext.Utils.MonotonicTime()) or 0
            local idx = (math.floor(tonumber(mono) or 0) % #EA.EA_LongRestCandidates) + 1
            local character = EA.EA_LongRestCandidates[idx]

            EA.EA_LongRestAmbushScheduled = true

            local longMinSeconds, longMaxSeconds = EA_GetRestDelayWindowSeconds(true)
            local delay = EA_RandomSeconds(longMinSeconds, longMaxSeconds)
            local timer = string.format("EA_LR_%s_%d", tostring(character), Ext.Utils.MonotonicTime())
            EA_ReplaceActiveRestTimer(timer, "long", character, "initial")
            EA_RecordRestStat("long", "scheduled", 1)
            EA_LogRestFlow("scheduled LongRest for %s in %ds (%s)", tostring(character), delay, tostring(timer))
            Osi.TimerLaunch(timer, delay * 1000)
        end)
    end

    return Runtime
end

return M
