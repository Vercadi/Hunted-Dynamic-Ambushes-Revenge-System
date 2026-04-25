EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

function M.Build(deps)
    deps = deps or {}

    local EnemyAmbush = deps.EnemyAmbush or EA
    local EA = deps.EA or EnemyAmbush or {}
    local ModuleUUID = tostring(deps.ModuleUUID or (EA and EA.ModuleUUID) or "")
    local DebugPrint = deps.DebugPrint or function() end
    local EA_DebugEnabled = deps.EA_DebugEnabled or function() return false end
    local EA_Dirty = deps.EA_Dirty or function() end
    local EA_NowMs = deps.EA_NowMs or function()
        if Ext and Ext.Utils and type(Ext.Utils.MonotonicTime) == "function" then
            local okNow, now = pcall(Ext.Utils.MonotonicTime)
            if okNow and tonumber(now) then
                return tonumber(now)
            end
        end
        return 0
    end
    local EA_LogRestFlow = deps.EA_LogRestFlow or function(stage, fmt, ...)
        local msg = tostring(fmt or "")
        if select("#", ...) > 0 then
            local okFmt, out = pcall(string.format, msg, ...)
            if okFmt and type(out) == "string" then
                msg = out
            end
        end
        print(string.format("[EnemyAmbush][RestFlow] %s %s", tostring(stage or "bootstrap"), msg))
    end
    local EA_ShouldSkipBeachTutorialAmbush = deps.EA_ShouldSkipBeachTutorialAmbush or function() return false end
    local EA_GetScriptedScenarioState = deps.EA_GetScriptedScenarioState or function() return nil end
    local EA_RunScriptedScenarioById = deps.EA_RunScriptedScenarioById or function() return false end
    local EA_GetRegionForCharacter = deps.EA_GetRegionForCharacter
    local GetSafeLevel = deps.GetSafeLevel
    local IsSafeToSpawnAmbush = deps.IsSafeToSpawnAmbush
    local EA_ResolveLocaText = deps.EA_ResolveLocaText or function(rawText)
        return tostring(rawText or "")
    end
    local EA_IsModVarsContainer = deps.EA_IsModVarsContainer
    local EA_ModVarsReadyFn = deps.EA_ModVarsReady or (EA and EA["EA_ModVarsReady"])

    local function GetAuthoredAmbushRuntime()
        local systemsModules = EA and EA.SystemsModules
        local runtime = type(systemsModules) == "table" and systemsModules.AuthoredAmbushRuntime or nil
        if type(runtime) == "table" then
            return runtime
        end
        return nil
    end

    local function GetScriptedScenarioState()
        local runtime = GetAuthoredAmbushRuntime()
        local fn = type(runtime) == "table" and runtime.GetScriptedScenarioState or nil
        if type(fn) ~= "function" then
            fn = EA_GetScriptedScenarioState
        end
        if type(fn) == "function" then
            return fn()
        end
        return nil
    end

    local function RunScriptedScenarioById(character, scenarioId, forceRun, opts)
        local runtime = GetAuthoredAmbushRuntime()
        local fn = type(runtime) == "table" and runtime.RunScriptedScenarioById or nil
        if type(fn) ~= "function" then
            fn = EA_RunScriptedScenarioById
        end
        if type(fn) == "function" then
            return fn(character, scenarioId, forceRun, opts)
        end
        return false
    end

    local BEACH_BOOTSTRAP_TIMER = "EA_BOOTSTRAP_BEACH"
    local BEACH_BOOTSTRAP_EXEC_TIMER = "EA_BOOTSTRAP_BEACH_EXEC"
    local EA_LOCA_BEACH_WAKEUP_MESSAGE = "h4c9e9b13g2f74g4f87ga1f6g8fd97c4e4a10;1"
    local EA_BEACH_BOOTSTRAP_DONE_VAR = "HuntedMod_96f24297_BeachBootstrapDone"
    local EA_BEACH_BOOTSTRAP_DONE_REASON_VAR = "HuntedMod_96f24297_BeachBootstrapDoneReason"
    local EA_BEACH_BOOTSTRAP_DONE_AT_VAR = "HuntedMod_96f24297_BeachBootstrapDoneAt"
    local EA_FLAG_CRA_WAKEUP_DONE = "c72b29a9-dcbc-487a-8ddd-707d8de73494"
    local EA_SHADOWHEART_ORIGIN_UUID = "3ed74f06-3c60-42dc-83f6-f034cb47c679"
    local BEACH_BOOTSTRAP_INITIAL_DELAY_MS = 3000
    local BEACH_BOOTSTRAP_POST_WAKEUP_DELAY_MS = 10000
    local BEACH_BOOTSTRAP_INTERVAL_MS = 2000
    local BEACH_BOOTSTRAP_SPAWN_DELAY_MS = 30000
    local BEACH_BOOTSTRAP_MAX_RETRIES = 180
    local BeachBootstrapRetries = 0
    local BeachBootstrapWaitTicks = 0
    local BeachBootstrapArmed = false
    local BeachBootstrapHost = nil
    local BeachBootstrapExecRetries = 0
    local BeachBootstrapTimerLaunched = false
    local BeachBootstrapDoneGateLogKey = nil

    local function TryRunBeachWakeupThroughAuthoredRuntime(hostCharacter, opts)
        opts = type(opts) == "table" and opts or {}
        local authoredRuntime = GetAuthoredAmbushRuntime()
        if type(authoredRuntime) == "table" and type(authoredRuntime.TryInternalScenario) == "function" then
            return authoredRuntime.TryInternalScenario(hostCharacter, opts)
        end
        if EA_DebugEnabled() then
            EA_LogRestFlow("bootstrap", "Beach wake-up internal runtime unavailable; using temporary direct scenario fallback.")
        end
        return RunScriptedScenarioById(
            hostCharacter,
            tostring(opts.scenarioId or "EA_SCN_BEACH_WAKEUP"),
            true,
            opts
        )
    end

    local function IsVarsContainer(vars)
        if type(EA_IsModVarsContainer) == "function" then
            local ok, out = pcall(EA_IsModVarsContainer, vars)
            if ok and out == true then
                return true
            end
        end
        return type(vars) == "table"
    end

    local function PeekPersistentVars()
        local varsFn = EA and EA["EA_Vars"]
        if type(varsFn) ~= "function" then
            return nil
        end
        local okVars, vars = pcall(varsFn)
        if not okVars or not IsVarsContainer(vars) then
            return nil
        end
        return vars
    end

    local function PeekBeachBootstrapState()
        local vars = PeekPersistentVars()
        if not IsVarsContainer(vars) then
            return nil
        end
        if type(vars.EA_BeachBootstrapState) == "table" then
            return vars.EA_BeachBootstrapState
        end
        return nil
    end

    local function FlagResultToBool(v)
        if v == true then return true end
        if v == false then return false end
        local n = tonumber(v)
        if n ~= nil then
            return n == 1
        end
        return false
    end

    local function ReadStoryFlag(flagUuid, hostCharacter)
        if not flagUuid or flagUuid == "" then
            return nil, "invalid_flag"
        end
        if not (Osi and Osi.GetFlag) then
            return nil, "getflag_unavailable"
        end

        local ok, value = pcall(Osi.GetFlag, flagUuid)
        if ok then
            return FlagResultToBool(value), "global"
        end

        if hostCharacter and hostCharacter ~= "" then
            local okHost, valueHost = pcall(Osi.GetFlag, flagUuid, hostCharacter)
            if okHost then
                return FlagResultToBool(valueHost), "host_scoped"
            end
        end

        return nil, "query_failed"
    end

    local function IsTruthyVar(raw)
        local doneStr = tostring(raw or "")
        local doneInt = tonumber(doneStr)
        return (doneStr == "1" or doneStr == "true" or doneStr == "TRUE" or (doneInt ~= nil and doneInt > 0))
    end

    local function ReadHostVarString(hostCharacter, varName)
        if not hostCharacter or hostCharacter == "" or not varName or varName == "" then
            return nil
        end
        if not (Osi and Osi.GetVarString) then
            return nil
        end
        local ok, raw = pcall(Osi.GetVarString, hostCharacter, varName)
        if not ok then
            return nil
        end
        return raw
    end

    local function LogBeachBootstrapGateOnce(key, fmt, ...)
        key = tostring(key or "")
        if key == "" then
            return
        end
        if BeachBootstrapDoneGateLogKey == key then
            return
        end
        BeachBootstrapDoneGateLogKey = key
        EA_LogRestFlow("bootstrap", tostring(fmt or ""), ...)
    end

    local function GetBeachWakeupSpawnCap(hostCharacter)
        local host = hostCharacter
        if (not host or host == "") and Osi and Osi.GetHostCharacter then
            host = Osi.GetHostCharacter()
        end
        if not host or host == "" then
            return 1, "shadowheart_party_check:no_host"
        end

        local shadowheartCandidates = {
            "S_Player_ShadowHeart_" .. tostring(EA_SHADOWHEART_ORIGIN_UUID),
            tostring(EA_SHADOWHEART_ORIGIN_UUID)
        }

        if Osi and Osi.IsInPartyWith then
            for _, candidate in ipairs(shadowheartCandidates) do
                local okParty, sameParty = pcall(Osi.IsInPartyWith, host, candidate)
                if okParty and tonumber(sameParty) == 1 then
                    return 2, "shadowheart_in_party:is_in_party_with"
                end
            end
        end

        if Osi and Osi.DB_PartyMembers and Osi.DB_PartyMembers.Get then
            local okRows, rows = pcall(Osi.DB_PartyMembers.Get, Osi.DB_PartyMembers, host, nil)
            if okRows and type(rows) == "table" then
                for _, row in ipairs(rows) do
                    local member = string.lower(tostring(row and row[1] or ""))
                    if member ~= "" and (
                        string.find(member, string.lower(tostring(EA_SHADOWHEART_ORIGIN_UUID)), 1, true)
                        or string.find(member, "shadowheart", 1, true)
                    ) then
                        return 2, "shadowheart_in_party:db_party_members"
                    end
                end
            end
        end

        return 1, "shadowheart_not_in_party"
    end

    local function ArePersistentVarsReady()
        if type(EA_ModVarsReadyFn) == "function" then
            local okReady, ready = pcall(EA_ModVarsReadyFn)
            if okReady then
                return ready == true
            end
        end
        if Ext and Ext.Mod and type(Ext.Mod.IsModLoaded) == "function" and ModuleUUID ~= "" then
            local okLoaded, loaded = pcall(Ext.Mod.IsModLoaded, ModuleUUID)
            if okLoaded and loaded ~= true then
                return false
            end
        end
        if Ext and Ext.Vars and Ext.Vars.GetModVariables and ModuleUUID ~= "" then
            local okVars, vars = pcall(Ext.Vars.GetModVariables, ModuleUUID)
            if okVars and IsVarsContainer(vars) then
                return true
            end
        end
        return false
    end

    local function GetBeachBootstrapState()
        local varsFn = EA and EA["EA_Vars"]
        if type(varsFn) ~= "function" then
            return nil
        end
        local okVars, vars = pcall(varsFn)
        if not okVars or not IsVarsContainer(vars) then
            return nil
        end
        if type(vars.EA_BeachBootstrapState) ~= "table" then
            vars.EA_BeachBootstrapState = {}
        end
        return vars.EA_BeachBootstrapState
    end

    local function GetBeachBootstrapDoneStatus()
        local bootstrapState = PeekBeachBootstrapState()
        if type(bootstrapState) == "table" and tonumber(bootstrapState.doneAt) and tonumber(bootstrapState.doneAt) > 0 then
            return true, "bootstrap_state_done", {
                host = tostring(bootstrapState.host or ""),
                reason = tostring(bootstrapState.reason or ""),
                doneAt = tostring(bootstrapState.doneAt or "")
            }
        end

        local host = (Osi and Osi.GetHostCharacter) and Osi.GetHostCharacter() or nil
        if EA_ShouldSkipBeachTutorialAmbush and EA_ShouldSkipBeachTutorialAmbush() then
            return true, "skip_tutorial_toggle", {
                host = tostring(host or "")
            }
        end

        local doneRaw = ReadHostVarString(host, EA_BEACH_BOOTSTRAP_DONE_VAR)
        if IsTruthyVar(doneRaw) then
            return true, "host_var_done", {
                host = tostring(host or ""),
                doneRaw = tostring(doneRaw or ""),
                reason = tostring(ReadHostVarString(host, EA_BEACH_BOOTSTRAP_DONE_REASON_VAR) or ""),
                doneAt = tostring(ReadHostVarString(host, EA_BEACH_BOOTSTRAP_DONE_AT_VAR) or "")
            }
        end

        local st = GetScriptedScenarioState()
        local completedAt = type(st) == "table" and type(st.completed) == "table" and st.completed["EA_SCN_BEACH_WAKEUP"] or nil
        if completedAt ~= nil then
            return true, "scenario_state_done", {
                host = tostring(host or ""),
                doneAt = tostring(completedAt or "")
            }
        end

        return false, "not_done", {
            host = tostring(host or "")
        }
    end

    local function MarkBeachBootstrapDone(host, reason)
        local hostCharacter = host
        if (not hostCharacter or hostCharacter == "") and Osi and Osi.GetHostCharacter then
            hostCharacter = Osi.GetHostCharacter()
        end

        if hostCharacter and hostCharacter ~= "" and Osi and Osi.SetVarString then
            pcall(Osi.SetVarString, hostCharacter, EA_BEACH_BOOTSTRAP_DONE_VAR, "1")
            pcall(Osi.SetVarString, hostCharacter, EA_BEACH_BOOTSTRAP_DONE_REASON_VAR, tostring(reason or "scenario_completed"))
            pcall(Osi.SetVarString, hostCharacter, EA_BEACH_BOOTSTRAP_DONE_AT_VAR, tostring(tonumber(EA_NowMs and EA_NowMs() or 0) or 0))
        end

        do
            local varsFn = EA and EA["EA_Vars"]
            if type(varsFn) == "function" then
                local okVars, vars = pcall(varsFn)
                if okVars and IsVarsContainer(vars) and vars.EA_TutorialShown ~= 1 then
                    vars.EA_TutorialShown = 1
                    EA_Dirty(true)
                end
            end
        end

        local state = GetBeachBootstrapState()
        if type(state) ~= "table" then
            return
        end
        if state.doneAt == nil then
            state.doneAt = EA_NowMs()
            state.host = tostring(hostCharacter or "")
            state.reason = tostring(reason or "scenario_completed")
            EA_Dirty(true)
        end
    end

    local function ShowBeachWakeupMessage(player)
        if not player or player == "" then
            return
        end
        local text = EA_ResolveLocaText(EA_LOCA_BEACH_WAKEUP_MESSAGE)
        if text == "" then
            return
        end
        if Osi and Osi.OpenMessageBox then
            pcall(Osi.OpenMessageBox, player, text)
        elseif EA_DebugEnabled() then
            DebugPrint("Beach wake-up message skipped: OpenMessageBox unavailable.")
        end
    end

    local function LaunchBeachBootstrapTimerWhenRunning(tries)
        tries = tonumber(tries) or 0
        if BeachBootstrapTimerLaunched == true then
            return
        end

        if Osi and Osi.IsGameStateRunning then
            local okRunning, running = pcall(Osi.IsGameStateRunning)
            if (not okRunning) or running ~= 1 then
                if tries < 30 and Ext and Ext.Timer and Ext.Timer.WaitFor then
                    if EA_DebugEnabled() and (tries == 0 or tries == 9 or tries == 19) then
                        EA_LogRestFlow(
                            "bootstrap",
                            "Beach bootstrap launch waiting for running-state (retry=%d/%d)",
                            tries + 1,
                            30
                        )
                    end
                    Ext.Timer.WaitFor(500, function()
                        LaunchBeachBootstrapTimerWhenRunning(tries + 1)
                    end)
                else
                    EA_LogRestFlow(
                        "bootstrap",
                        "Beach bootstrap timer launch aborted: game state never reached running (tries=%d/%d)",
                        tries,
                        30
                    )
                end
                return
            end
        end

        if Osi and Osi.TimerLaunch then
            local okLaunch = pcall(Osi.TimerLaunch, BEACH_BOOTSTRAP_TIMER, BEACH_BOOTSTRAP_INITIAL_DELAY_MS)
            if okLaunch then
                BeachBootstrapTimerLaunched = true
                if EA_DebugEnabled() then
                    EA_LogRestFlow(
                        "bootstrap",
                        "Beach bootstrap timer launched after running-state guard (tries=%d delayMs=%d)",
                        tries,
                        BEACH_BOOTSTRAP_INITIAL_DELAY_MS
                    )
                end
            elseif EA_DebugEnabled() then
                DebugPrint("Failed to launch beach bootstrap timer after running-state guard.")
            end
        end
    end

    local function IsBeachBootstrapDone()
        local done, source, info = GetBeachBootstrapDoneStatus()
        if done ~= true then
            return false
        end

        info = type(info) == "table" and info or {}
        local host = tostring(info.host or "")

        if source == "bootstrap_state_done" then
            LogBeachBootstrapGateOnce(
                "bootstrap_state_done",
                "Beach wake-up bootstrap skipped: persistent bootstrap state already done (reason=%s doneAt=%s)",
                tostring(info.reason or ""),
                tostring(info.doneAt or "")
            )
            return true
        end

        if source == "skip_tutorial_toggle" then
            LogBeachBootstrapGateOnce("skip_tutorial_toggle", "Beach wake-up bootstrap skipped: tutorial skip toggle enabled.")
            MarkBeachBootstrapDone(host, "mcm_skip_tutorial")
            return true
        end

        if source == "host_var_done" then
            LogBeachBootstrapGateOnce(
                "host_var_done",
                "Beach wake-up bootstrap skipped: host bootstrap done var already set (reason=%s doneAt=%s)",
                tostring(info.reason or ""),
                tostring(info.doneAt or "")
            )
            MarkBeachBootstrapDone(host, "host_var_sync")
        local stSync = GetScriptedScenarioState()
            if type(stSync) == "table" and type(stSync.completed) == "table" and stSync.completed["EA_SCN_BEACH_WAKEUP"] == nil then
                stSync.completed["EA_SCN_BEACH_WAKEUP"] = EA_NowMs()
                EA_Dirty(true)
            end
            return true
        end

        if source == "scenario_state_done" then
            LogBeachBootstrapGateOnce(
                "scenario_state_done",
                "Beach wake-up bootstrap skipped: scenario already marked complete (doneAt=%s)",
                tostring(info.doneAt or "")
            )
            MarkBeachBootstrapDone(host, "scenario_state_sync")
            return true
        end

        LogBeachBootstrapGateOnce("unknown_done_state", "Beach wake-up bootstrap skipped: done source=%s", tostring(source or "unknown"))
        return true
    end

    local function EvaluateBeachBootstrapReadiness(character, allowDelayStateWrite)
        if not character or character == "" then
            return false, "no_host"
        end
        if Osi.IsPlayer and Osi.IsPlayer(character) ~= 1 then
            return false, "host_not_player"
        end
        if Osi.ObjectExists and Osi.ObjectExists(character) ~= 1 then
            return false, "host_missing"
        end
        local level = tonumber(GetSafeLevel and GetSafeLevel(character) or 1) or 1
        if level > 3 then
            return false, "level>3"
        end

        local region = nil
        if type(EA_GetRegionForCharacter) == "function" then
            region = EA_GetRegionForCharacter(character)
        end
        if tostring(region or "") ~= "WLD_Main_A" then
            return false, "region=" .. tostring(region or "unknown")
        end

        if type(IsSafeToSpawnAmbush) == "function" and not IsSafeToSpawnAmbush(character) then
            return false, "unsafe_state"
        end

        local wakeupDone, wakeupSource = ReadStoryFlag(EA_FLAG_CRA_WAKEUP_DONE, character)
        if wakeupDone ~= true then
            if wakeupDone == nil then
                return false, "wake_up_flag_unavailable:" .. tostring(wakeupSource or "unknown")
            end
            return false, "wake_up_not_done"
        end

        if Osi.IsInCombat and Osi.IsInCombat(character) == 1 then
            return false, "in_combat"
        end

        if type(IsSafeToSpawnAmbush) == "function" and not IsSafeToSpawnAmbush(character) then
            return false, "unsafe_state"
        end

        do
            local bootstrapState = allowDelayStateWrite == false and PeekBeachBootstrapState() or GetBeachBootstrapState()
            if type(bootstrapState) == "table" then
                local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
                local seenAt = tonumber(bootstrapState.wakeupDoneSeenAt or 0) or 0
                if seenAt <= 0 then
                    if allowDelayStateWrite == false then
                        return false, "post_wakeup_delay_not_started"
                    end
                    bootstrapState.wakeupDoneSeenAt = now
                    EA_Dirty()
                    return false, "post_wakeup_delay_started"
                end
                local age = now - seenAt
                if age < BEACH_BOOTSTRAP_POST_WAKEUP_DELAY_MS then
                    local remain = math.max(0, math.ceil((BEACH_BOOTSTRAP_POST_WAKEUP_DELAY_MS - age) / 1000))
                    return false, "post_wakeup_delay:" .. tostring(remain) .. "s"
                end
            elseif allowDelayStateWrite == false and ArePersistentVarsReady() then
                return false, "post_wakeup_delay_not_started"
            end
        end

        if not ArePersistentVarsReady() then
            return false, "vars_unavailable"
        end

        return true, "ok"
    end

    local function CheckBeachBootstrapReady(character)
        return EvaluateBeachBootstrapReadiness(character, true)
    end

    local function IsBeachBootstrapStartContextPossible(character)
        if not character or character == "" then
            return false, "no_host"
        end
        local wakeupDone = nil
        local region = nil
        local wakeupSource = nil
        if type(EA_GetRegionForCharacter) == "function" then
            region = EA_GetRegionForCharacter(character)
        end
        wakeupDone, wakeupSource = ReadStoryFlag(EA_FLAG_CRA_WAKEUP_DONE, character)
        if tostring(region or "") == "WLD_Main_A" then
            return true, "region_main_a"
        end
        if wakeupDone == true then
            return true, "wake_up_done"
        end
        if wakeupDone == nil then
            return false, "wake_up_flag_unavailable:" .. tostring(wakeupSource or "unknown")
        end
        return false, "region=" .. tostring(region or "unknown")
    end

    local function ShouldConsumeBeachBootstrapRetry(reason)
        reason = tostring(reason or "")
        if reason == "" then
            return true
        end
        if reason == "no_host"
            or reason == "host_not_player"
            or reason == "host_missing"
            or reason == "in_combat"
            or reason == "unsafe_state"
            or reason == "wake_up_not_done"
            or reason == "post_wakeup_delay_not_started"
            or reason == "post_wakeup_delay_started"
            or reason == "vars_unavailable" then
            return false
        end
        if string.sub(reason, 1, 7) == "region=" and reason ~= "region=WLD_Main_A" then
            return false
        end
        if string.sub(reason, 1, 25) == "wake_up_flag_unavailable:" then
            return false
        end
        if string.sub(reason, 1, 18) == "post_wakeup_delay:" then
            return false
        end
        return true
    end

    local function DescribeBeachBootstrapState()
        local host = (Osi and Osi.GetHostCharacter) and Osi.GetHostCharacter() or nil
        local vars = PeekPersistentVars()
        local bootstrapState = PeekBeachBootstrapState()
        local wakeupDone, wakeupSource = ReadStoryFlag(EA_FLAG_CRA_WAKEUP_DONE, host)
        local done, doneSource, doneInfo = GetBeachBootstrapDoneStatus()
        local tutorialShown = nil
        local scenarioCompletedAt = nil
        local safeToSpawn = nil
        local level = nil
        local region = nil
        local objectExists = nil
        local isPlayer = nil
        local inCombat = nil
        local ready = false
        local readyReason = "no_host"

        if IsVarsContainer(vars) then
            tutorialShown = vars.EA_TutorialShown
        end

        if type(EA_GetRegionForCharacter) == "function" and host and host ~= "" then
            region = EA_GetRegionForCharacter(host)
        end

        if type(GetSafeLevel) == "function" and host and host ~= "" then
            level = tonumber(GetSafeLevel(host) or 0) or 0
        end

        if type(IsSafeToSpawnAmbush) == "function" and host and host ~= "" then
            local okSafe, outSafe = pcall(IsSafeToSpawnAmbush, host)
            if okSafe then
                safeToSpawn = outSafe == true
            end
        end

        if Osi and Osi.ObjectExists and host and host ~= "" then
            local okExists, outExists = pcall(Osi.ObjectExists, host)
            if okExists then
                objectExists = tonumber(outExists) == 1
            end
        end

        if Osi and Osi.IsPlayer and host and host ~= "" then
            local okPlayer, outPlayer = pcall(Osi.IsPlayer, host)
            if okPlayer then
                isPlayer = tonumber(outPlayer) == 1
            end
        end

        if Osi and Osi.IsInCombat and host and host ~= "" then
            local okCombat, outCombat = pcall(Osi.IsInCombat, host)
            if okCombat then
                inCombat = tonumber(outCombat) == 1
            end
        end

        if host and host ~= "" then
            ready, readyReason = EvaluateBeachBootstrapReadiness(host, false)
        end

        local st = GetScriptedScenarioState()
        if type(st) == "table" and type(st.completed) == "table" then
            scenarioCompletedAt = st.completed["EA_SCN_BEACH_WAKEUP"]
        end

        return {
            host = tostring(host or ""),
            varsReady = ArePersistentVarsReady() == true,
            skipTutorial = EA_ShouldSkipBeachTutorialAmbush and EA_ShouldSkipBeachTutorialAmbush() == true or false,
            storyWakeupDone = wakeupDone,
            storyWakeupSource = tostring(wakeupSource or ""),
            ready = ready == true,
            readyReason = tostring(readyReason or ""),
            tutorialShown = tutorialShown,
            scenarioCompleted = scenarioCompletedAt ~= nil,
            scenarioCompletedAt = scenarioCompletedAt,
            hostDoneVar = ReadHostVarString(host, EA_BEACH_BOOTSTRAP_DONE_VAR),
            hostDoneReason = ReadHostVarString(host, EA_BEACH_BOOTSTRAP_DONE_REASON_VAR),
            hostDoneAt = ReadHostVarString(host, EA_BEACH_BOOTSTRAP_DONE_AT_VAR),
            done = done == true,
            doneSource = tostring(doneSource or ""),
            doneInfo = type(doneInfo) == "table" and doneInfo or {},
            stateDoneAt = type(bootstrapState) == "table" and bootstrapState.doneAt or nil,
            stateReason = type(bootstrapState) == "table" and bootstrapState.reason or nil,
            stateHost = type(bootstrapState) == "table" and bootstrapState.host or nil,
            stateWakeupDoneSeenAt = type(bootstrapState) == "table" and bootstrapState.wakeupDoneSeenAt or nil,
            runtimeTimerLaunched = BeachBootstrapTimerLaunched == true,
            runtimeArmed = BeachBootstrapArmed == true,
            runtimeHost = tostring(BeachBootstrapHost or ""),
            runtimeRetries = tonumber(BeachBootstrapRetries or 0) or 0,
            runtimeWaitTicks = tonumber(BeachBootstrapWaitTicks or 0) or 0,
            runtimeExecRetries = tonumber(BeachBootstrapExecRetries or 0) or 0,
            hostExists = objectExists,
            hostIsPlayer = isPlayer,
            hostInCombat = inCombat,
            hostLevel = level,
            hostRegion = region,
            safeToSpawn = safeToSpawn
        }
    end

    local function EnsureBeachBootstrapStarted(source)
        local host = (Osi and Osi.GetHostCharacter) and Osi.GetHostCharacter() or nil
        if IsBeachBootstrapDone() then
            return false
        end
        if BeachBootstrapTimerLaunched == true then
            return true
        end
        local startPossible, startReason = IsBeachBootstrapStartContextPossible(host)
        if startPossible ~= true then
            return false
        end
        if EA_DebugEnabled() then
            EA_LogRestFlow(
                "bootstrap",
                "Beach bootstrap ensure-start (%s reason=%s)",
                tostring(source or "unknown"),
                tostring(startReason or "unknown")
            )
        end
        LaunchBeachBootstrapTimerWhenRunning(0)
        return BeachBootstrapTimerLaunched == true
    end

    local Runtime = {}

    function Runtime.OnSessionLoaded()
        BeachBootstrapRetries = 0
        BeachBootstrapWaitTicks = 0
        BeachBootstrapArmed = false
        BeachBootstrapHost = nil
        BeachBootstrapExecRetries = 0
        BeachBootstrapTimerLaunched = false
        BeachBootstrapDoneGateLogKey = nil

        if EA_DebugEnabled() then
            EA_LogRestFlow(
                "bootstrap",
                "Beach bootstrap session init queued (skipTutorial=%s)",
                tostring(EA_ShouldSkipBeachTutorialAmbush and EA_ShouldSkipBeachTutorialAmbush() == true or false)
            )
        end

        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(100, function()
                EnsureBeachBootstrapStarted("session_loaded_runtime")
            end)
        else
            EnsureBeachBootstrapStarted("session_loaded_runtime")
        end
    end

    function Runtime.TryHandleTimer(timer)
        timer = tostring(timer or "")

        if timer == BEACH_BOOTSTRAP_TIMER then
            if IsBeachBootstrapDone() then
                return true
            end
            if BeachBootstrapArmed == true then
                return true
            end

            local host = (Osi and Osi.GetHostCharacter) and Osi.GetHostCharacter() or nil
            local ready, reason = CheckBeachBootstrapReady(host)

            if ready then
                BeachBootstrapWaitTicks = 0
                BeachBootstrapArmed = true
                BeachBootstrapHost = host
                BeachBootstrapExecRetries = 0
                EA_LogRestFlow(
                    "bootstrap",
                    "Beach wake-up armed for %s (spawn in %ds)",
                    tostring(host),
                    math.floor(BEACH_BOOTSTRAP_SPAWN_DELAY_MS / 1000)
                )
                ShowBeachWakeupMessage(host)
                Osi.TimerLaunch(BEACH_BOOTSTRAP_EXEC_TIMER, BEACH_BOOTSTRAP_SPAWN_DELAY_MS)
                return true
            end

            local consumeRetry = ShouldConsumeBeachBootstrapRetry(reason)
            if consumeRetry then
                BeachBootstrapRetries = (BeachBootstrapRetries or 0) + 1
            else
                BeachBootstrapWaitTicks = (BeachBootstrapWaitTicks or 0) + 1
            end

            if BeachBootstrapRetries <= BEACH_BOOTSTRAP_MAX_RETRIES then
                local logTick = consumeRetry and (BeachBootstrapRetries or 0) or (BeachBootstrapWaitTicks or 0)
                if logTick == 1 or (logTick % 15) == 0 then
                    if consumeRetry then
                        EA_LogRestFlow(
                            "bootstrap",
                            "Beach wake-up pending (%s) retry=%d/%d",
                            tostring(reason or "blocked"),
                            BeachBootstrapRetries or 0,
                            BEACH_BOOTSTRAP_MAX_RETRIES
                        )
                    else
                        EA_LogRestFlow(
                            "bootstrap",
                            "Beach wake-up pending (%s) parked (retry budget preserved: %d/%d wait=%d)",
                            tostring(reason or "blocked"),
                            BeachBootstrapRetries or 0,
                            BEACH_BOOTSTRAP_MAX_RETRIES,
                            BeachBootstrapWaitTicks or 0
                        )
                    end
                end
                Osi.TimerLaunch(BEACH_BOOTSTRAP_TIMER, BEACH_BOOTSTRAP_INTERVAL_MS)
            else
                EA_LogRestFlow("bootstrap", "Beach wake-up bootstrap expired after %d retries", BEACH_BOOTSTRAP_MAX_RETRIES)
            end
            return true
        end

        if timer == BEACH_BOOTSTRAP_EXEC_TIMER then
            if IsBeachBootstrapDone() then
                BeachBootstrapArmed = false
                BeachBootstrapHost = nil
                BeachBootstrapExecRetries = 0
                return true
            end

            local host = BeachBootstrapHost
            if not host or host == "" then
                host = (Osi and Osi.GetHostCharacter) and Osi.GetHostCharacter() or nil
            end

            local ready, reason = CheckBeachBootstrapReady(host)
            if not ready then
                BeachBootstrapExecRetries = (BeachBootstrapExecRetries or 0) + 1
                if BeachBootstrapExecRetries == 1 or (BeachBootstrapExecRetries % 6) == 0 then
                    EA_LogRestFlow(
                        "bootstrap",
                        "Beach wake-up armed but waiting (%s) retry=%d",
                        tostring(reason or "blocked"),
                        BeachBootstrapExecRetries
                    )
                end
                Osi.TimerLaunch(BEACH_BOOTSTRAP_EXEC_TIMER, BEACH_BOOTSTRAP_INTERVAL_MS)
                return true
            end

            local spawnCap, capReason = GetBeachWakeupSpawnCap(host)
            EA_LogRestFlow("bootstrap", "Beach wake-up spawn cap=%d (%s)", tonumber(spawnCap) or 1, tostring(capReason or "unknown"))

            local okRun, ran, _spawned, scenarioReason = pcall(
                TryRunBeachWakeupThroughAuthoredRuntime,
                host,
                {
                    scenarioId = "EA_SCN_BEACH_WAKEUP",
                    forceRun = true,
                    source = "beach_bootstrap",
                    flowLabel = "BeachWakeupBootstrap",
                    spawnCap = tonumber(spawnCap) or 1,
                }
            )
            if okRun and ran == true then
                MarkBeachBootstrapDone(host, "scenario_spawned")
                EA_LogRestFlow("bootstrap", "Beach wake-up scenario triggered for %s", tostring(host))
                BeachBootstrapArmed = false
                BeachBootstrapHost = nil
                BeachBootstrapExecRetries = 0
            else
                reason = okRun and ("scenario_not_ran:" .. tostring(scenarioReason or "unknown")) or ("scenario_error:" .. tostring(ran))
                BeachBootstrapExecRetries = (BeachBootstrapExecRetries or 0) + 1
                if BeachBootstrapExecRetries == 1 or (BeachBootstrapExecRetries % 6) == 0 then
                    EA_LogRestFlow("bootstrap", "Beach wake-up run deferred (%s) retry=%d", tostring(reason), BeachBootstrapExecRetries)
                end
                Osi.TimerLaunch(BEACH_BOOTSTRAP_EXEC_TIMER, BEACH_BOOTSTRAP_INTERVAL_MS)
            end
            return true
        end

        return false
    end

    EA["EA_DebugDescribeBeachBootstrap"] = DescribeBeachBootstrapState
    EA["EA_EnsureBeachBootstrapStarted"] = EnsureBeachBootstrapStarted

    return Runtime
end

return M
