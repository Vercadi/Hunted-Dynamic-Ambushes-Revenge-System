EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

function M.Build(deps)
    deps = deps or {}

    local EnemyAmbush = deps.EnemyAmbush or EA
    local EA = deps.EA or EnemyAmbush or {}
    local ModuleUUID = tostring(deps.ModuleUUID or EA.ModuleUUID or "")
    local SystemsDataTables = deps.SystemsDataTables or {}
    local RestDefaults = (SystemsDataTables and SystemsDataTables.REST_DEFAULTS) or {}
    local TriggerDefaults = (SystemsDataTables and SystemsDataTables.TRIGGER_REST_DEFAULTS) or {}

    local EA_ArmGuaranteedChampion = deps.EA_ArmGuaranteedChampion or function() end
    local IsSafeToSpawnAmbush = deps.IsSafeToSpawnAmbush or function() return true end
    local EA_ShowFirstAmbushTutorial = deps.EA_ShowFirstAmbushTutorial or function() end
    local EA_GetCooldownEnabled = deps.EA_GetCooldownEnabled or function() return false end
    local EA_GetCooldownMinutes = deps.EA_GetCooldownMinutes or function() return 0 end
    local EA_GetTimeInDangerPressureEnabled = deps.EA_GetTimeInDangerPressureEnabled or (EA and EA["EA_GetTimeInDangerPressureEnabled"]) or function()
        return true
    end
    local EA_NormalizeUUID = deps.EA_NormalizeUUID or function(v) return v end
    local EA_LastAmbushTime = deps.EA_LastAmbushTime or function()
        EnemyAmbush.LastAmbushTime = EnemyAmbush.LastAmbushTime or {}
        return EnemyAmbush.LastAmbushTime
    end
    local EA_PersistedNowMs = deps.EA_PersistedNowMs or (EA and EA["EA_PersistedNowMs"]) or function()
        return nil
    end
    local EA_Dirty = deps.EA_Dirty or function() end
    local EA_ModVarsReadyFn = deps.EA_ModVarsReady or (EA and EA["EA_ModVarsReady"])
    local EA_GetPartyMembers = deps.EA_GetPartyMembers or (EA and EA["EA_GetPartyMembers"]) or function(player)
        return { player }
    end
    local EA_IsRobust = deps.EA_IsRobust or function() return false end
    local EA_IsModVarsContainer = deps.EA_IsModVarsContainer or (EA and EA["EA_IsModVarsContainer"])
    local EA_AmbushPressure = deps.EA_AmbushPressure or function()
        EnemyAmbush.AmbushPressure = EnemyAmbush.AmbushPressure or {}
        return EnemyAmbush.AmbushPressure
    end
    local EA_StampAmbushCooldownForCharacter = deps.EA_StampAmbushCooldownForCharacter or function() end
    local EA_StampAmbushCooldownForParty = deps.EA_StampAmbushCooldownForParty or function(character)
        return EA_StampAmbushCooldownForCharacter(character)
    end
    local EA_TrySpawnArmedChampion = deps.EA_TrySpawnArmedChampion or function() return false, "none_armed" end
    local EA_IsChampionDiagnosticsEnabled = deps.EA_IsChampionDiagnosticsEnabled or function() return false end
    local EA_LogChampionDiagnostics = deps.EA_LogChampionDiagnostics or function() end
    local GetLocationAppropriateEnemies = deps.GetLocationAppropriateEnemies or function() return {} end
    local CreatureReputation = deps.CreatureReputation or {}
    local REPUTATION_THRESHOLDS = deps.REPUTATION_THRESHOLDS or {}
    local EA_FormatTypeList = deps.EA_FormatTypeList or function(list)
        if type(list) ~= "table" or #list == 0 then
            return "(none)"
        end
        local out = {}
        for i = 1, #list do
            out[#out + 1] = tostring(list[i])
        end
        return table.concat(out, ", ")
    end
    local SpawnChampionIfNeeded = deps.SpawnChampionIfNeeded or function() return false, {} end
    local EA_ConsumeChampionDiagnosticsOnce = deps.EA_ConsumeChampionDiagnosticsOnce or function() end
    local EA_GetRestAmbushChance = deps.EA_GetRestAmbushChance or (EA and EA["EA_GetRestAmbushChance"]) or function()
        return 0
    end
    local EA_GetTimeInDangerAccumulatedMs = deps.EA_GetTimeInDangerAccumulatedMs or function()
        return 0
    end
    local EA_GetTimeInDangerRiskUnit = deps.EA_GetTimeInDangerRiskUnit or function()
        return 0
    end
    local EA_ResetTimeInDangerState = deps.EA_ResetTimeInDangerState or function()
        return false
    end
    local EA_GetTimeInDangerTravelCheckAtMs = deps.EA_GetTimeInDangerTravelCheckAtMs or function()
        return 0
    end
    local EA_SetTimeInDangerTravelCheckAtMs = deps.EA_SetTimeInDangerTravelCheckAtMs or function()
        return false
    end
    local EA_RandFloatSafe = deps.EA_RandFloatSafe or (EA and EA["EA_RandFloatSafe"])
    local EA_RandFloatCompat = deps.EA_RandFloatCompat or function()
        if type(EA_RandFloatSafe) == "function" then
            local ok, out = pcall(EA_RandFloatSafe)
            if ok and tonumber(out) then
                return tonumber(out)
            end
        end
        return 0.5
    end
    local GetSafeLevel = deps.GetSafeLevel or function() return 1 end
    local GetPointBudget = deps.GetPointBudget or function() return 1 end
    local defaultRandomSeconds = tonumber(TriggerDefaults.DEFAULT_RANDOM_SECONDS) or 60
    local RandomSeconds = deps.RandomSeconds or function() return defaultRandomSeconds end
    local ENEMY_DURATION_MIN = tonumber(deps.ENEMY_DURATION_MIN)
        or tonumber(TriggerDefaults.ENEMY_DURATION_MIN_SECONDS)
        or 300
    local ENEMY_DURATION_MAX = tonumber(deps.ENEMY_DURATION_MAX)
        or tonumber(TriggerDefaults.ENEMY_DURATION_MAX_SECONDS)
        or 600
    local EA_TRAVEL_DANGER_THRESHOLD_MS = tonumber(TriggerDefaults.TIME_IN_DANGER_TRAVEL_THRESHOLD_MS)
        or (8 * 60 * 1000)
    local EA_TRAVEL_DANGER_CHECK_INTERVAL_MS = tonumber(TriggerDefaults.TIME_IN_DANGER_TRAVEL_CHECK_INTERVAL_MS)
        or (180 * 1000)
    local EA_TRAVEL_DANGER_FULL_RISK_MS = tonumber(TriggerDefaults.TIME_IN_DANGER_FULL_RISK_MS)
        or (25 * 60 * 1000)
    local EA_TRAVEL_DANGER_BASE_CHANCE = tonumber(TriggerDefaults.TIME_IN_DANGER_TRAVEL_BASE_CHANCE)
        or 0.03
    local EA_TRAVEL_DANGER_MAX_BONUS = tonumber(TriggerDefaults.TIME_IN_DANGER_TRAVEL_MAX_BONUS)
        or 0.12
    local GetPartyMaxLevel = deps.GetPartyMaxLevel or function() return 1 end
    local GetPartySize = deps.GetPartySize or function() return 1 end
    local EA_RollOverlevelDelta = deps.EA_RollOverlevelDelta or function() return 0 end
    local EA_GetTierFromDelta = deps.EA_GetTierFromDelta or function() return "COMMON" end
    local EA_GetDynamicCategory = deps.EA_GetDynamicCategory or function() return "COMMON" end
    local EA_IsDebugMode = deps.EA_IsDebugMode or function() return false end
    local DebugPrint = deps.DebugPrint or function() end
    local PickEnemyTemplate = deps.PickEnemyTemplate or function() return nil end
    local GetAmbushThemeForEnemy = deps.GetAmbushThemeForEnemy or function() return "Ambush" end
    local defaultTierSpawnDistance = tonumber(TriggerDefaults.TIER_SPAWN_DISTANCE_DEFAULT) or 12
    local EA_GetTierSpawnDistance = deps.EA_GetTierSpawnDistance or function() return defaultTierSpawnDistance end
    local EA_GetWarningDelayMs = deps.EA_GetWarningDelayMs or function() return 1 end
    local ShowAmbushWarning = deps.ShowAmbushWarning or function() end
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local StorePendingAmbush = deps.StorePendingAmbush or function() end
    local EA_Pending = deps.EA_Pending or function()
        EnemyAmbush._Pending = EnemyAmbush._Pending or {}
        return EnemyAmbush._Pending
    end
    local EA_ScheduleApproachBeat = deps.EA_ScheduleApproachBeat or function() end

    local function EA_MakePersistableSeedEnemy(enemy)
        if type(enemy) ~= "table" then
            return nil
        end
        local template = tostring(enemy.template or "")
        if template == "" then
            return nil
        end
        return {
            template = template,
            name = tostring(enemy.name or "Unknown"),
            creatureType = tostring(enemy.creatureType or ""),
            level = tonumber(enemy.level) or 1,
            spawnBand = tostring(enemy.spawnBand or ""),
            powerClass = tostring(enemy.powerClass or ""),
        }
    end

    local function EA_SetDelayedAmbushMirrorPayload(payload)
        local varsFn = EA and EA["EA_Vars"]
        if type(varsFn) ~= "function" then
            return false
        end
        local okVars, vars = pcall(varsFn)
        if not okVars then
            return false
        end
        local isContainer = (type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(vars))
            or type(vars) == "table"
            or type(vars) == "userdata"
        if not isContainer then
            return false
        end
        vars.EA_DelayedAmbushState = payload
        return true
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

        local seedEnemy = EA_MakePersistableSeedEnemy(payload.firstEnemy)
        if seedEnemy then
            out.firstEnemy = seedEnemy
        end

        if type(payload.roll) == "table" or type(payload.roll) == "userdata" then
            out.roll = {
                delta = tonumber(payload.roll.delta) or 0,
                targetLevel = tonumber(payload.roll.targetLevel) or 0,
                tier = tostring(payload.roll.tier or ""),
                spawnDist = tonumber(payload.roll.spawnDist) or 0,
                playerLevel = tonumber(payload.roll.playerLevel) or 0,
                ambushId = tostring(payload.roll.ambushId or ""),
            }
        end

        return out
    end

    local function EA_GetCooldownPartyMembers(character)
        local out = {}
        local seen = {}
        local function addMember(member)
            local key = tostring(member or "")
            if key == "" or seen[key] then
                return
            end
            seen[key] = true
            out[#out + 1] = key
        end

        if type(EA_GetPartyMembers) == "function" and character and character ~= "" then
            local okParty, party = pcall(EA_GetPartyMembers, character)
            if okParty and type(party) == "table" then
                for i = 1, #party do
                    addMember(party[i])
                end
            end
        end

        addMember(character)
        return out
    end

    local function EA_GetPressureRegistry()
        local pressure = EA_AmbushPressure()
        if type(pressure) ~= "table" and type(pressure) ~= "userdata" then
            return nil
        end
        return pressure
    end

    local function EA_ClearTimeInDangerRisk(character, reason)
        if type(EA_ResetTimeInDangerState) ~= "function" then
            return false
        end
        local ok, cleared = pcall(EA_ResetTimeInDangerState, character, reason)
        return ok and cleared == true
    end

    local function EA_GetAuthoredAmbushRuntime()
        local systemsModules = EA and EA.SystemsModules
        local runtime = type(systemsModules) == "table" and systemsModules.AuthoredAmbushRuntime or nil
        if type(runtime) == "table" then
            return runtime
        end
        return nil
    end

    local function EA_GetTryRunScriptedScenarioFn()
        local runtime = EA_GetAuthoredAmbushRuntime()
        local fn = type(runtime) == "table" and runtime.TryRunScriptedScenario or nil
        if type(fn) ~= "function" then
            fn = EA and EA["EA_TryRunScriptedScenario"]
        end
        return type(fn) == "function" and fn or nil
    end

    local function EA_IsRestFlowKind(flowKind)
        return flowKind == "long" or flowKind == "short"
    end

    local function EA_GetAmbushFlowKind(isLongRest, opts)
        local kind = tostring(opts and opts.flowKind or "")
        if kind ~= "" then
            return kind
        end
        return isLongRest == true and "long" or "short"
    end

    local function EA_GetAmbushFlowLabel(isLongRest, opts, flowKind)
        if type(opts) == "table" and type(opts.flowLabel) == "string" and opts.flowLabel ~= "" then
            return opts.flowLabel
        end
        if flowKind == "travel" then
            return "TravelDanger"
        end
        return isLongRest == true and "LongRest" or "ShortRest"
    end

    local function EA_ResolveTravelDangerCharacter(character)
        if Osi and Osi.GetHostCharacter then
            local host = Osi.GetHostCharacter()
            if host and host ~= "" then
                return tostring(host)
            end
        end
        if character and character ~= "" then
            return tostring(character)
        end
        return nil
    end

    local function EA_HasPendingAmbushForCharacter(character)
        local pending = EA_Pending()
        if type(pending) ~= "table" and type(pending) ~= "userdata" then
            return false
        end
        for _, data in pairs(pending) do
            if (type(data) == "table" or type(data) == "userdata") and tostring(data.character or "") == tostring(character or "") then
                return true
            end
        end
        return false
    end

    local function EA_GetPartyCooldownState(character, cooldownMs)
        if not character or character == "" or not cooldownMs or cooldownMs <= 0 then
            return false, nil, nil
        end

        local lastTbl = EA_LastAmbushTime()
        local now = (type(EA_PersistedNowMs) == "function") and EA_PersistedNowMs() or nil
        if (type(lastTbl) ~= "table" and type(lastTbl) ~= "userdata") or now == nil then
            return false, nil, nil
        end

        local blockedMember = nil
        local maxRemainingMs = nil
        local members = EA_GetCooldownPartyMembers(character)
        for i = 1, #members do
            local member = members[i]
            local key = EA_NormalizeUUID(member) or member
            local last = lastTbl[key]
            if last ~= nil then
                local age = now - tonumber(last)
                if age < 0 then
                    lastTbl[key] = now
                    EA_Dirty()
                    age = 0
                end
                if age < cooldownMs then
                    local remaining = cooldownMs - age
                    if maxRemainingMs == nil or remaining > maxRemainingMs then
                        maxRemainingMs = remaining
                        blockedMember = member
                    end
                end
            end
        end

        return maxRemainingMs ~= nil, maxRemainingMs, blockedMember
    end

    local function TriggerAmbush(character, isLongRest, forceAmbush, opts)
        if not character or character == "" then
            return false, "invalid_character"
        end
        opts = (type(opts) == "table") and opts or {}
        local skipTutorial = (opts.skipTutorial == true)
        local skipCooldown = (opts.skipCooldown == true)
        local skipScripted = (opts.skipScripted == true)
        local skipChanceRoll = (opts.skipChanceRoll == true)
        forceAmbush = (forceAmbush == true)
        local flowKind = EA_GetAmbushFlowKind(isLongRest, opts)
        local isRestFlow = EA_IsRestFlowKind(flowKind)
        local restLabel = EA_GetAmbushFlowLabel(isLongRest, opts, flowKind)

        -- LONG REST GATE: arm ONE guaranteed champion (even if we're in camp and won't spawn yet)
        if isLongRest then
            EA_ArmGuaranteedChampion(character)
        end

        -- Safety check before actually spawning anything
        if not IsSafeToSpawnAmbush(character) then
            local rec = EA and EA["EA_RecordRestStat"]
            if isRestFlow and type(rec) == "function" then
                rec(isLongRest and "long" or "short", "blockedSafety", 1)
            end
            print(string.format("[EnemyAmbush][RestFlow] %s blocked: failed safety check for %s", restLabel, tostring(character)))
            return false, "blocked_safety"
        end

        if (not skipTutorial) and EA_ShowFirstAmbushTutorial then
            EA_ShowFirstAmbushTutorial(character)
        end

        -- Party-wide cooldown (optional)
        if (not skipCooldown) and EA_GetCooldownEnabled() then
            local cdMin = EA_GetCooldownMinutes()
            cdMin = math.max(0, math.min(120, cdMin))
            local cdMs = math.floor(cdMin * 60000)

            if cdMs > 0 then
                local activeCooldown, remainingMs, blockedMember = EA_GetPartyCooldownState(character, cdMs)
                if activeCooldown then
                    if EA_IsRobust() then
                        print(string.format(
                            "[EnemyAmbush][ROBUST] Cooldown active for party member %s (%ds remaining), skipping ambush for %s.",
                            tostring(blockedMember or character), math.floor((tonumber(remainingMs) or 0) / 1000), tostring(character)
                        ))
                    end
                    return false, "cooldown_active"
                end
            end
        end

        -- One-shot scripted scenarios (onboarding/set-piece hooks).
        if not skipScripted then
            local scriptedVarsReady = false
            if type(EA_ModVarsReadyFn) == "function" then
                local okReady, ready = pcall(EA_ModVarsReadyFn)
                scriptedVarsReady = (okReady and ready == true)
            end
            if (not scriptedVarsReady) and Ext and Ext.Mod and type(Ext.Mod.IsModLoaded) == "function" and ModuleUUID and ModuleUUID ~= "" then
                local okLoaded, loaded = pcall(Ext.Mod.IsModLoaded, ModuleUUID)
                scriptedVarsReady = (okLoaded and loaded == true)
            end
            if scriptedVarsReady and Ext and Ext.Vars and Ext.Vars.GetModVariables and ModuleUUID and ModuleUUID ~= "" then
                local okVars, vars = pcall(Ext.Vars.GetModVariables, ModuleUUID)
                scriptedVarsReady = (okVars and (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(vars)) or type(vars) == "table")))
            end

            if scriptedVarsReady then
                do
                    local tryScripted = EA_GetTryRunScriptedScenarioFn()
                    if type(tryScripted) == "function" then
                        local ok, ran = pcall(tryScripted, character, isLongRest, forceAmbush)
                        if ok and ran == true then
                            local key = EA_NormalizeUUID(character) or character
                            local pressure = EA_GetPressureRegistry()
                            if pressure then
                                pressure[key] = 0
                            end
                            EA_ClearTimeInDangerRisk(character, "scripted_scenario_consumed")
                            if EA_GetCooldownEnabled() then
                                EA_StampAmbushCooldownForParty(character)
                            end
                            EA_Dirty()
                            local rec = EA and EA["EA_RecordRestStat"]
                            if isRestFlow and type(rec) == "function" then
                                rec(isLongRest and "long" or "short", "scriptedConsumed", 1)
                            end
                            print(string.format("[EnemyAmbush][RestFlow] %s consumed by scripted scenario for %s", restLabel, tostring(character)))
                            return true, "scripted_consumed"
                        elseif not ok then
                            print("[EnemyAmbush][Scenario] Error in scripted scenario pipeline:", tostring(ran))
                        end
                    end
                end
            elseif EA_IsDebugMode() then
                DebugPrint("[Scenario] Skipping scripted scenario check: persistent vars unavailable")
            end
        end

        -- Guaranteed champion attempt (spawns only after long rest arming + when safe)
        local armedSpawned, armedInfo = EA_TrySpawnArmedChampion(character)
        local armedOutcome = (type(armedInfo) == "table") and armedInfo or { reason = armedInfo }
        local armedReason = armedOutcome.reason
        if armedSpawned then
            -- Stamp cooldown for the full party only after a successful champion spawn
            local key = EA_NormalizeUUID(character) or character
            EA_StampAmbushCooldownForParty(character)
            local pressure = EA_GetPressureRegistry()
            if pressure then
                pressure[key] = 0
            end
            EA_ClearTimeInDangerRisk(character, "armed_champion_spawned")
            EA_Dirty()
            local rec = EA and EA["EA_RecordRestStat"]
            if isRestFlow and type(rec) == "function" then
                rec("long", "championSpawned", 1)
            end
            EA_ConsumeChampionDiagnosticsOnce()
            return true, "armed_champion_spawned"
        elseif isLongRest and EA_IsChampionDiagnosticsEnabled() and armedReason and armedReason ~= "none_armed" then
            if armedOutcome.source or armedOutcome.resolveReason or armedOutcome.policy or armedOutcome.providerId then
                EA_LogChampionDiagnostics(
                    "Armed champion path did not spawn: reason=%s source=%s resolveReason=%s policy=%s provider=%s",
                    tostring(armedReason),
                    tostring(armedOutcome.source or "n/a"),
                    tostring(armedOutcome.resolveReason or "n/a"),
                    tostring(armedOutcome.policy or "n/a"),
                    tostring(armedOutcome.providerId or "n/a")
                )
            else
                EA_LogChampionDiagnostics("Armed champion path did not spawn: reason=%s", tostring(armedReason))
            end
        end

        -- Check for champion spawn first (recommended: long-rest only)
        if isLongRest then
            local appropriateTypes = GetLocationAppropriateEnemies(character) or {}
            if EA_IsChampionDiagnosticsEnabled() then
                EA_LogChampionDiagnostics(
                    "LongRest champion scan: region-appropriate types=[%s]",
                    EA_FormatTypeList(appropriateTypes)
                )
            end

            local appropriateSet = {}
            for _, ct in ipairs(appropriateTypes) do
                appropriateSet[tostring(ct)] = true
            end

            local vengefulAppropriate = {}
            local vengefulNotAppropriate = {}
            if type(CreatureReputation) == "table" then
                for ct, rep in pairs(CreatureReputation) do
                    local nrep = tonumber(rep) or 0
                    if nrep <= REPUTATION_THRESHOLDS.VENGEFUL then
                        if appropriateSet[tostring(ct)] then
                            vengefulAppropriate[#vengefulAppropriate + 1] = tostring(ct)
                        else
                            vengefulNotAppropriate[#vengefulNotAppropriate + 1] = tostring(ct)
                        end
                    end
                end
            end
            table.sort(vengefulAppropriate)
            table.sort(vengefulNotAppropriate)

            if EA_IsChampionDiagnosticsEnabled() then
                EA_LogChampionDiagnostics(
                    "Vengeful candidates: appropriate=[%s] | not_appropriate=[%s]",
                    EA_FormatTypeList(vengefulAppropriate),
                    EA_FormatTypeList(vengefulNotAppropriate)
                )
            end

            if #vengefulAppropriate == 0 and EA_IsChampionDiagnosticsEnabled() then
                EA_LogChampionDiagnostics("Champion chance path skipped: no vengeful candidates in current region.")
            end

            for _, creatureType in ipairs(appropriateTypes) do
                local spawned, info = SpawnChampionIfNeeded(character, creatureType)
                info = (type(info) == "table") and info or {}

                if EA_IsChampionDiagnosticsEnabled() and info.reason and info.reason ~= "rep_not_vengeful" then
                    EA_LogChampionDiagnostics(
                        "Chance eval type=%s rep=%s reason=%s roll=%s chance=%s",
                        tostring(creatureType),
                        tostring(info.reputation),
                        tostring(info.reason),
                        (info.roll ~= nil) and string.format("%.3f", tonumber(info.roll) or 0) or "n/a",
                        (info.chance ~= nil) and string.format("%.3f", tonumber(info.chance) or 0) or "n/a"
                    )
                end

                if spawned then
                    -- Stamp cooldown for the full party only after a successful champion spawn
                    local key = EA_NormalizeUUID(character) or character
                    EA_StampAmbushCooldownForParty(character)
                    local pressure = EA_GetPressureRegistry()
                    if pressure then
                        pressure[key] = 0
                    end
                    EA_ClearTimeInDangerRisk(character, "chance_champion_spawned")
                    EA_Dirty()
                    local rec = EA and EA["EA_RecordRestStat"]
                    if isRestFlow and type(rec) == "function" then
                        rec("long", "championSpawned", 1)
                    end

                    print("[EnemyAmbush] Champion spawned for vengeful reputation")
                    EA_ConsumeChampionDiagnosticsOnce()
                    return true, "chance_champion_spawned" -- Champion spawn replaces normal ambush
                end
            end

            if EA_IsChampionDiagnosticsEnabled() then
                EA_LogChampionDiagnostics("Chance path finished without spawn; normal ambush roll continues.")
                EA_ConsumeChampionDiagnosticsOnce()
            end
        end

        if not skipChanceRoll then
            local baseChance = EA_GetRestAmbushChance(isLongRest)
            local dangerAccumulatedMs = 0
            local dangerRiskUnit = 0
            do
                local okAccum, accum = pcall(EA_GetTimeInDangerAccumulatedMs, character)
                if okAccum and tonumber(accum) ~= nil then
                    dangerAccumulatedMs = math.max(0, tonumber(accum) or 0)
                end
                local okRisk, risk = pcall(EA_GetTimeInDangerRiskUnit, character)
                if okRisk and tonumber(risk) ~= nil then
                    dangerRiskUnit = math.max(0, math.min(1, tonumber(risk) or 0))
                end
            end
            local dangerBonus = baseChance * dangerRiskUnit
            local chance = math.max(0, math.min(1, baseChance + dangerBonus))
            if EA_IsDebugMode() and (dangerAccumulatedMs > 0 or dangerRiskUnit > 0) then
                DebugPrint(string.format(
                    "[Rest] %s danger-risk: accumMs=%d riskUnit=%.3f baseChance=%.3f bonus=%.3f finalChance=%.3f",
                    tostring(restLabel),
                    math.floor(dangerAccumulatedMs),
                    dangerRiskUnit,
                    baseChance,
                    dangerBonus,
                    chance
                ))
            end
            local roll = EA_RandFloatCompat()
            if forceAmbush then
                local recRoll = EA and EA["EA_RecordRestRoll"]
                if isRestFlow and type(recRoll) == "function" then
                    recRoll(isLongRest == true, roll, chance, true, true, character)
                end
                print(string.format(
                    "[EnemyAmbush][RestFlow] %s forced: roll=%.3f chance=%.3f char=%s",
                    restLabel, roll, chance, tostring(character)
                ))
            end
            if not forceAmbush and roll >= chance then
                local recRoll = EA and EA["EA_RecordRestRoll"]
                if isRestFlow and type(recRoll) == "function" then
                    recRoll(isLongRest == true, roll, chance, false, false, character)
                end
                print(string.format(
                    "[EnemyAmbush][RestFlow] %s roll failed: roll=%.3f chance=%.3f char=%s",
                    restLabel, roll, chance, tostring(character)
                ))
                if EA_IsDebugMode() then
                    DebugPrint(string.format(
                        "[Rest] %s ambush roll failed: roll=%.3f chance=%.3f",
                        tostring(restLabel), roll, chance
                    ))
                end
                return false, "chance_roll_failed"
            end

            if not forceAmbush then
                local recRoll = EA and EA["EA_RecordRestRoll"]
                if isRestFlow and type(recRoll) == "function" then
                    recRoll(isLongRest == true, roll, chance, false, true, character)
                end
                print(string.format(
                    "[EnemyAmbush][RestFlow] %s roll passed: roll=%.3f chance=%.3f char=%s",
                    restLabel, roll, chance, tostring(character)
                ))
            end
        end

        local playerLevel = GetSafeLevel(character)
        local pointBudget = GetPointBudget(playerLevel, character)
        local duration = RandomSeconds(ENEMY_DURATION_MIN, ENEMY_DURATION_MAX)

        -- Roll ONCE per ambush so tier/dist vibe is consistent
        local pl = GetPartyMaxLevel(character) or playerLevel or 1
        local partySizeForTier = GetPartySize(character)
        local delta = EA_RollOverlevelDelta(pl, partySizeForTier)
        local targetLevel = math.max(1, math.min(pl + delta, 20))
        -- Tier is derived from delta so level-cap clamping does not erase late-game elite/legendary rolls.
        local tier = EA_GetTierFromDelta(delta) or EA_GetDynamicCategory(targetLevel, pl)
        if pl <= 2 and tier ~= "COMMON" then
            if EA_IsDebugMode() then
                DebugPrint(string.format(
                    "[TierSafety] forcing COMMON for low-level party (level=%d size=%d rolled=%s)",
                    pl, partySizeForTier, tostring(tier)
                ))
            end
            delta = 0
            targetLevel = pl
            tier = "COMMON"
        end

        -- Pick first enemy from the rolled tier pool so warning/theme match real spawn pool.
        local firstEnemy = PickEnemyTemplate(character, nil, tier)
        if not firstEnemy then
            print("[EnemyAmbush] No enemy template available")
            return false, "no_enemy_template"
        end

        local ambushTheme = GetAmbushThemeForEnemy(firstEnemy)

        -- Match SpawnHostileNearPlayer distance logic
        local spawnDist = EA_GetTierSpawnDistance(tier)

        -- If we have a creatureType, show warning + use normal delay.
        -- If missing creatureType, still schedule a delayed spawn with a minimal delay (so cooldown/pressure stamping stays consistent).
        local warningMs = 1
        if firstEnemy.creatureType then
            warningMs = EA_GetWarningDelayMs(tier, spawnDist)
            ShowAmbushWarning(character, firstEnemy.creatureType, tier, spawnDist, warningMs)
        end

        -- Build timer + payload
        local ambushId = tostring(Ext.Utils.MonotonicTime())
        local warningTimer = string.format("EA_AMBUSH_DELAYED_%s_%s", character, ambushId)

        local spawnRoll = {
            delta = delta,
            targetLevel = targetLevel,
            tier = tier,
            spawnDist = spawnDist,
            playerLevel = pl,
            ambushId = ambushId
        }
        local seedEnemyForPending = EA_MakePersistableSeedEnemy(firstEnemy)
        local ambushData = {
            kind = "SPAWN",
            timer = warningTimer,
            character = character,
            ambushId = ambushId,
            tier = tier,

            isLongRest = isLongRest,
            triggerKind = flowKind,
            flowLabel = restLabel,
            playerLevel = playerLevel,
            pointBudget = pointBudget,
            duration = duration,
            ambushTheme = ambushTheme,
            firstEnemy = seedEnemyForPending,

            -- carry roll forward so spawns reuse the same tier/dist vibe
            roll = spawnRoll,

            creatureType = firstEnemy.creatureType,
            warningMs = warningMs,
            timestamp = EA_NowMs()
        }

        local storedPayload = StorePendingAmbush(warningTimer, ambushData)
        if not storedPayload then
            local pendingNow = EA_Pending()
            storedPayload = pendingNow and pendingNow[warningTimer] or nil
        end
        local warningDelayMinMs = tonumber(TriggerDefaults.WARNING_DELAY_MIN_MS)
            or tonumber(RestDefaults.STAGGER_QUEUE_INITIAL_DELAY_MIN_MS)
            or 50
        local launchDelayMs = math.max(warningDelayMinMs, tonumber(warningMs) or 0)
        if not storedPayload or storedPayload.kind ~= "SPAWN" then
            print(string.format("[EnemyAmbush] Delayed ambush payload missing for timer=%s; skipping launch.", tostring(warningTimer)))
            return false, "pending_payload_missing"
        end

        local delayedMirrorPayload = EA_MakeDelayedAmbushMirrorPayload(warningTimer, storedPayload)
        if delayedMirrorPayload and EA_SetDelayedAmbushMirrorPayload(delayedMirrorPayload) then
            EA_Dirty(true)
            print(string.format(
                "[EnemyAmbush] Delayed ambush mirror armed for timer '%s'.",
                tostring(warningTimer)
            ))
        end

        Osi.TimerLaunch(warningTimer, launchDelayMs)
        EA_ClearTimeInDangerRisk(character, "normal_ambush_queued")
        if EA_IsDebugMode() then
            DebugPrint(string.format("[Rest] queued delayed ambush: timer=%s warningMs=%d type=%s tier=%s",
                tostring(warningTimer), tonumber(launchDelayMs) or -1, tostring(ambushData.creatureType or "?"), tostring(tier)))
        end

        -- Approach beat only makes sense when we have a creatureType + a real warning delay
        if firstEnemy.creatureType then
            EA_ScheduleApproachBeat(character, ambushId, ambushData.creatureType, tier, warningMs)
        end
        return true, "queued"
    end

    local function EA_TryTriggerTravelDangerAmbush(opts)
        opts = (type(opts) == "table") and opts or {}

        local character = EA_ResolveTravelDangerCharacter(opts.character)
        if not character or character == "" then
            return false, "invalid_character"
        end
        if not EA_GetTimeInDangerPressureEnabled() then
            return false, "disabled"
        end

        local nowMs = tonumber(opts.nowMs) or tonumber(EA_NowMs and EA_NowMs() or 0) or 0
        if nowMs <= 0 then
            return false, "now_unavailable"
        end

        local accumulatedMs = math.max(0, tonumber(EA_GetTimeInDangerAccumulatedMs(character)) or 0)
        if accumulatedMs < EA_TRAVEL_DANGER_THRESHOLD_MS then
            return false, "below_threshold"
        end

        local lastTravelCheckAtMs = math.max(0, tonumber(EA_GetTimeInDangerTravelCheckAtMs(character)) or 0)
        if lastTravelCheckAtMs > 0 and (nowMs - lastTravelCheckAtMs) < EA_TRAVEL_DANGER_CHECK_INTERVAL_MS then
            return false, "cadence_active"
        end

        if EA_HasPendingAmbushForCharacter(character) then
            return false, "pending_ambush"
        end

        if not IsSafeToSpawnAmbush(character) then
            return false, "blocked_safety"
        end

        if EA_GetCooldownEnabled() then
            local cooldownMinutes = math.max(0, math.min(120, tonumber(EA_GetCooldownMinutes()) or 0))
            local cooldownMs = math.floor(cooldownMinutes * 60000)
            if cooldownMs > 0 then
                local activeCooldown = EA_GetPartyCooldownState(character, cooldownMs)
                if activeCooldown then
                    return false, "cooldown_active"
                end
            end
        end

        local denominator = math.max(1, EA_TRAVEL_DANGER_FULL_RISK_MS - EA_TRAVEL_DANGER_THRESHOLD_MS)
        local effectiveRisk = (accumulatedMs - EA_TRAVEL_DANGER_THRESHOLD_MS) / denominator
        if effectiveRisk < 0 then
            effectiveRisk = 0
        elseif effectiveRisk > 1 then
            effectiveRisk = 1
        end

        local chance = math.max(0, math.min(1, EA_TRAVEL_DANGER_BASE_CHANCE + (EA_TRAVEL_DANGER_MAX_BONUS * effectiveRisk)))
        local roll = EA_RandFloatCompat()
        EA_SetTimeInDangerTravelCheckAtMs(character, nowMs)

        if roll >= chance then
            if EA_IsDebugMode() then
                DebugPrint(string.format(
                    "[Risk] travel_check source=%s char=%s accumMs=%d effectiveRisk=%.3f chance=%.3f roll=%.3f trigger=false reason=rolled_fail",
                    tostring(opts.source or "unknown"),
                    tostring(character),
                    math.floor(accumulatedMs),
                    effectiveRisk,
                    chance,
                    roll
                ))
            end
            return false, "roll_failed"
        end

        local queued, reason = TriggerAmbush(character, false, true, {
            skipScripted = true,
            skipChanceRoll = true,
            flowKind = "travel",
            flowLabel = "TravelDanger",
        })
        if EA_IsDebugMode() then
            DebugPrint(string.format(
                "[Risk] travel_check source=%s char=%s accumMs=%d effectiveRisk=%.3f chance=%.3f roll=%.3f trigger=%s reason=%s",
                tostring(opts.source or "unknown"),
                tostring(character),
                math.floor(accumulatedMs),
                effectiveRisk,
                chance,
                roll,
                tostring(queued == true),
                tostring(reason or (queued == true and "queued" or "trigger_failed"))
            ))
        end
        if queued == true then
            return true, "queued"
        end
        return false, tostring(reason or "trigger_failed")
    end

    return {
        TriggerAmbush = TriggerAmbush,
        EA_TryTriggerTravelDangerAmbush = EA_TryTriggerTravelDangerAmbush,
        EA_MakePersistableSeedEnemy = EA_MakePersistableSeedEnemy,
    }
end

return M
