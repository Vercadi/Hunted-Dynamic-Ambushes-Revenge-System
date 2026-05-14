EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

function M.Build(deps)
    deps = deps or {}
    local EARef = deps.EA or EA or {}
    local systemsData = deps.SystemsDataTables or {}

    local EA_NowMs = deps.EA_NowMs or function()
        if Osi and Osi.GetTime then
            local ok, gameTime = pcall(Osi.GetTime)
            if ok and tonumber(gameTime) then
                return math.floor(tonumber(gameTime) * 1000)
            end
        end
        if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
            local okMono, mono = pcall(Ext.Utils.MonotonicTime)
            if okMono and tonumber(mono) then
                return math.floor(tonumber(mono) * 1000)
            end
        end
        return 0
    end
    local EA_NormalizeUUID = deps.EA_NormalizeUUID or function(uuid)
        if type(uuid) == "string" then
            return string.lower(uuid)
        end
        return uuid
    end
    local EA_GetPartyMembers = deps.EA_GetPartyMembers or function()
        return {}
    end
    local EA_GetSettingBool = deps.EA_GetSettingBool or function(_, fallback)
        return fallback == true
    end
    local SafeOsiCall = deps.SafeOsiCall or function(fn, ...)
        if type(fn) ~= "function" then
            return nil
        end
        local ok, out = pcall(fn, ...)
        if ok then
            return out
        end
        return nil
    end
    local SafeApplyStatus = deps.SafeApplyStatus or function()
        return false
    end
    local UpdateMetric = deps.UpdateMetric or (EARef and EARef["UpdateMetric"]) or function()
    end
    local DebugPrint = deps.DebugPrint or (EARef and EARef["DebugPrint"]) or function()
    end
    local EA_IsDebugMode = deps.EA_IsDebugMode or function()
        return false
    end

    local EA_SURPRISE_STATE = {
        applied = {},
        pendingRolls = {},
        rollCounter = 0,
    }
    local EA_SURPRISE_CFG = systemsData.SURPRISE_CFG or {
        ttlMs = 120000,
        durationSeconds = 6,
        ambushedStatus = "EA_AMBUSHED",
        rollTimeoutMs = 12000,
        rollPrefix = "EA_SURPRISE_PERC_",
        rollType = "RawAbility",
        rollerSkill = "Perception",
        subjectSkill = "Stealth",
        defaultAdvantage = 0,
        defaultSubjectAdvantage = 0,
        fallbackDifficultyClass = "DC_Legacy_10",
    }

    local function EA_BuildAmbushToken(player, ambushRoll)
        if type(ambushRoll) == "table" and ambushRoll.ambushId then
            return tostring(ambushRoll.ambushId)
        end

        local now = tonumber(EA_NowMs()) or 0
        return tostring(player) .. "|" .. tostring(math.floor(now / 2000))
    end

    local function EA_IsMemberSurpriseImmune(member)
        local immune = false
        if Osi and Osi.HasPassive then
            local hasAlert = SafeOsiCall(Osi.HasPassive, member, "Alert")
            local hasSurpriseImmune = SafeOsiCall(Osi.HasPassive, member, "Surprise_Immunity")
            immune = (hasAlert == 1) or (hasSurpriseImmune == 1)
        end
        if (not immune) and Osi and Osi.HasActiveStatus then
            local hasStatusImmune = SafeOsiCall(Osi.HasActiveStatus, member, "SURPRISE_IMMUNITY")
            local hasStatusAlert = SafeOsiCall(Osi.HasActiveStatus, member, "ALERT")
            local hasAmbushImmune = SafeOsiCall(Osi.HasActiveStatus, member, "AMBUSH_IMMUNITY")
            immune = (hasStatusImmune == 1) or (hasStatusAlert == 1)
            immune = immune or (hasAmbushImmune == 1)
        end
        return immune
    end

    local function EA_ApplySurprisedToMember(member, source)
        UpdateMetric("surpriseApplyAttempts")
        local appliedNow = false
        if source and source ~= "" and Osi and Osi.ObjectExists and Osi.ObjectExists(source) == 1 then
            local ok = pcall(Osi.ApplyStatus, member, "SURPRISED", EA_SURPRISE_CFG.durationSeconds, 1, source)
            appliedNow = (ok == true)
        end
        if (not appliedNow) and SafeApplyStatus(member, "SURPRISED", EA_SURPRISE_CFG.durationSeconds, 1) then
            appliedNow = true
        end
        if appliedNow then
            UpdateMetric("surpriseApplied")
        else
            UpdateMetric("surpriseApplyFailed")
        end
        return appliedNow
    end

    local function EA_ApplyAmbushedToMember(member, source)
        local statusId = tostring(EA_SURPRISE_CFG.ambushedStatus or "")
        if statusId == "" then
            return false
        end

        local appliedNow = false
        if source and source ~= "" and Osi and Osi.ObjectExists and Osi.ObjectExists(source) == 1 then
            local ok = pcall(Osi.ApplyStatus, member, statusId, EA_SURPRISE_CFG.durationSeconds, 1, source)
            appliedNow = (ok == true)
        end
        if (not appliedNow) and SafeApplyStatus(member, statusId, EA_SURPRISE_CFG.durationSeconds, 1) then
            appliedNow = true
        end
        if appliedNow then
            UpdateMetric("surpriseAmbushedApplied")
        else
            UpdateMetric("surpriseAmbushedApplyFailed")
        end
        return appliedNow
    end

    local function EA_ScheduleSurpriseRollTimeout(rollId)
        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(EA_SURPRISE_CFG.rollTimeoutMs, function()
                local pending = EA_SURPRISE_STATE.pendingRolls[rollId]
                if pending then
                    EA_SURPRISE_STATE.pendingRolls[rollId] = nil
                    UpdateMetric("surpriseRollTimeouts")
                    if EA_IsDebugMode() then
                        local ageMs = (tonumber(EA_NowMs()) or 0) - (tonumber(pending.timestamp) or 0)
                        DebugPrint(
                            string.format(
                                "[Surprise] Roll timeout (no RollResult): rollId=%s member=%s ageMs=%s -> no surprise (safe default)",
                                rollId,
                                tostring(pending.member),
                                tostring(ageMs)
                            )
                        )
                    end
                end
            end)
        end
    end

    local function EA_RequestSurprisePerceptionRoll(member, source, token)
        local now = tonumber(EA_NowMs()) or 0
        EA_SURPRISE_STATE.rollCounter = (tonumber(EA_SURPRISE_STATE.rollCounter) or 0) + 1
        local rollId = EA_SURPRISE_CFG.rollPrefix .. tostring(EA_SURPRISE_STATE.rollCounter) .. "_" .. tostring(math.floor(now))
        local sourceRaw = (source ~= nil) and tostring(source) or ""
        local sourceGuid = EA_NormalizeUUID(sourceRaw) or ""

        local function EA_ObjectExistsSafe(id)
            if not id or id == "" then
                return false
            end
            if not (Osi and Osi.ObjectExists) then
                return true
            end
            local ok, exists = pcall(Osi.ObjectExists, id)
            return ok and exists == 1
        end

        local sourceRef = ""
        if sourceRaw ~= "" and EA_ObjectExistsSafe(sourceRaw) then
            sourceRef = sourceRaw
        elseif sourceGuid ~= "" and EA_ObjectExistsSafe(sourceGuid) then
            sourceRef = sourceGuid
        elseif sourceRaw ~= "" then
            sourceRef = sourceRaw
        elseif sourceGuid ~= "" then
            sourceRef = sourceGuid
        end

        EA_SURPRISE_STATE.pendingRolls[rollId] = {
            member = member,
            source = (sourceRef ~= "" and sourceRef) or sourceGuid,
            token = token,
            timestamp = now,
        }

        local rollRequested = false
        local failureReasons = {}

        if sourceRef ~= "" then
            if Osi and Osi.RequestPassiveRollVersusSkill then
                local ok, err = pcall(
                    Osi.RequestPassiveRollVersusSkill,
                    member,
                    sourceRef,
                    EA_SURPRISE_CFG.rollType,
                    EA_SURPRISE_CFG.rollerSkill,
                    EA_SURPRISE_CFG.subjectSkill,
                    EA_SURPRISE_CFG.defaultAdvantage,
                    EA_SURPRISE_CFG.defaultSubjectAdvantage,
                    rollId
                )

                local legacyErr = nil
                if not ok then
                    local fullAltOk
                    fullAltOk, legacyErr = pcall(
                        Osi.RequestPassiveRollVersusSkill,
                        member,
                        sourceRef,
                        EA_SURPRISE_CFG.rollType,
                        EA_SURPRISE_CFG.rollerSkill,
                        EA_SURPRISE_CFG.subjectSkill,
                        -1,
                        -1,
                        rollId
                    )
                    ok = fullAltOk
                end
                if not ok then
                    local legacyOk
                    legacyOk, legacyErr = pcall(
                        Osi.RequestPassiveRollVersusSkill,
                        member,
                        sourceRef,
                        EA_SURPRISE_CFG.rollerSkill,
                        EA_SURPRISE_CFG.subjectSkill,
                        EA_SURPRISE_CFG.defaultAdvantage,
                        rollId
                    )
                    ok = legacyOk
                end

                rollRequested = (ok == true)
                if EA_IsDebugMode() then
                    if ok then
                        DebugPrint(
                            string.format(
                                "[Surprise] RequestPassiveRollVersusSkill: member=%s vs source=%s rollId=%s ok=true",
                                tostring(member),
                                tostring(sourceRef),
                                rollId
                            )
                        )
                    else
                        failureReasons[#failureReasons + 1] =
                            string.format("versus_failed(current=%s legacy=%s)", tostring(err), tostring(legacyErr))
                        DebugPrint(
                            string.format(
                                "[Surprise] RequestPassiveRollVersusSkill failed: member=%s vs source=%s rollId=%s currentErr=%s legacyErr=%s",
                                tostring(member),
                                tostring(sourceRef),
                                rollId,
                                tostring(err),
                                tostring(legacyErr)
                            )
                        )
                    end
                end
            elseif EA_IsDebugMode() then
                DebugPrint("[Surprise] RequestPassiveRollVersusSkill unavailable in this runtime; trying RequestPassiveRoll fallback.")
            end
            if not (Osi and Osi.RequestPassiveRollVersusSkill) then
                failureReasons[#failureReasons + 1] = "versus_api_missing"
            end
        elseif EA_IsDebugMode() then
            DebugPrint(
                string.format(
                    "[Surprise] Versus roll skipped; invalid source for member=%s source=%s normalized=%s resolved=%s",
                    tostring(member),
                    tostring(sourceRaw),
                    tostring(sourceGuid),
                    tostring(sourceRef)
                )
            )
            failureReasons[#failureReasons + 1] = "source_invalid"
        end

        if not rollRequested and Osi and Osi.RequestPassiveRoll then
            local rollSubject = sourceRef
            if rollSubject == "" then
                rollSubject = member
            end

            local ok, err = pcall(
                Osi.RequestPassiveRoll,
                member,
                rollSubject,
                EA_SURPRISE_CFG.rollType,
                EA_SURPRISE_CFG.rollerSkill,
                EA_SURPRISE_CFG.fallbackDifficultyClass,
                EA_SURPRISE_CFG.defaultAdvantage,
                rollId
            )

            local legacyErr = nil
            if not ok then
                local legacyOk
                legacyOk, legacyErr = pcall(
                    Osi.RequestPassiveRoll,
                    member,
                    rollSubject,
                    EA_SURPRISE_CFG.rollerSkill,
                    EA_SURPRISE_CFG.fallbackDifficultyClass,
                    rollId
                )
                ok = legacyOk
            end

            rollRequested = (ok == true)
            if EA_IsDebugMode() then
                if ok then
                    DebugPrint(
                        string.format(
                            "[Surprise] RequestPassiveRoll fallback: member=%s subject=%s dc=%s rollId=%s ok=true",
                            tostring(member),
                            tostring(rollSubject),
                            tostring(EA_SURPRISE_CFG.fallbackDifficultyClass),
                            tostring(rollId)
                        )
                    )
                else
                    failureReasons[#failureReasons + 1] =
                        string.format("passive_failed(current=%s legacy=%s)", tostring(err), tostring(legacyErr))
                    DebugPrint(
                        string.format(
                            "[Surprise] RequestPassiveRoll fallback failed: member=%s subject=%s dc=%s rollId=%s currentErr=%s legacyErr=%s",
                            tostring(member),
                            tostring(rollSubject),
                            tostring(EA_SURPRISE_CFG.fallbackDifficultyClass),
                            tostring(rollId),
                            tostring(err),
                            tostring(legacyErr)
                        )
                    )
                end
            end
        elseif not rollRequested and EA_IsDebugMode() then
            DebugPrint("[Surprise] RequestPassiveRoll unavailable in this runtime.")
            failureReasons[#failureReasons + 1] = "passive_api_missing"
        end

        if not rollRequested then
            EA_SURPRISE_STATE.pendingRolls[rollId] = nil
            if EA_IsDebugMode() then
                local reason = (#failureReasons > 0) and table.concat(failureReasons, " | ") or "unknown"
                DebugPrint(
                    string.format(
                        "[Surprise] Roll API unavailable/failed, applying directly: member=%s rollId=%s reason=%s",
                        tostring(member),
                        tostring(rollId),
                        tostring(reason)
                    )
                )
            end
            return EA_ApplySurprisedToMember(member, source)
        end

        EA_ScheduleSurpriseRollTimeout(rollId)
        return false
    end

    local function EA_HandleSurpriseRollResult(character, result, resultCritical, eventName)
        if type(eventName) ~= "string" then
            return false
        end
        if eventName:sub(1, #EA_SURPRISE_CFG.rollPrefix) ~= EA_SURPRISE_CFG.rollPrefix then
            return false
        end

        local pending = EA_SURPRISE_STATE.pendingRolls[eventName]
        if not pending then
            return false
        end
        EA_SURPRISE_STATE.pendingRolls[eventName] = nil

        local member = pending.member
        local source = pending.source
        local resultNum = tonumber(result)
        local rollFailed = (resultNum == 0)
        local rollPassed = not rollFailed

        if EA_IsDebugMode() then
            DebugPrint(
                string.format(
                    "[Surprise] RollResult: member=%s result=%s crit=%s passed=%s rollId=%s",
                    tostring(member),
                    tostring(result),
                    tostring(resultCritical),
                    tostring(rollPassed),
                    tostring(eventName)
                )
            )
        end

        if rollPassed then
            UpdateMetric("surpriseRollPassed")
            if EA_IsDebugMode() then
                DebugPrint(string.format("[Surprise] %s passed Perception check - not surprised", tostring(member)))
            end
            return true
        end

        UpdateMetric("surpriseRollFailed")
        local applied = EA_ApplySurprisedToMember(member, source)
        local ambushedApplied = false
        if applied then
            ambushedApplied = EA_ApplyAmbushedToMember(member, source)
        end
        if EA_IsDebugMode() then
            DebugPrint(string.format(
                "[Surprise] %s failed Perception check - SURPRISED applied=%s AMBUSHED applied=%s",
                tostring(member),
                tostring(applied),
                tostring(ambushedApplied)
            ))
        end
        return true
    end

    local function EA_TryApplyPartySurprise(player, ambushRoll, requireInCombat)
        if not EA_GetSettingBool("MCM_ApplyPartySurprised", true) then
            return
        end

        requireInCombat = (requireInCombat == true)

        local members = EA_GetPartyMembers(player)
        if requireInCombat then
            local anyInCombat = false
            for _, member in ipairs(members) do
                if Osi and Osi.IsInCombat and Osi.IsInCombat(member) == 1 then
                    anyInCombat = true
                    break
                end
            end
            if not anyInCombat then
                return
            end
        end

        local token = EA_BuildAmbushToken(player, ambushRoll)
        local now = tonumber(EA_NowMs()) or 0

        for key, ts in pairs(EA_SURPRISE_STATE.applied) do
            if (now - (tonumber(ts) or 0)) > EA_SURPRISE_CFG.ttlMs then
                EA_SURPRISE_STATE.applied[key] = nil
            end
        end

        if EA_SURPRISE_STATE.applied[token] then
            return
        end

        local rollsRequested = 0
        local skippedImmune = 0
        local eligible = 0
        local source = (type(ambushRoll) == "table" and ambushRoll.source) or nil
        for _, member in ipairs(members) do
            local exists = (not Osi or not Osi.ObjectExists) or (Osi.ObjectExists(member) == 1)
            local dead = (Osi and Osi.IsDead and Osi.IsDead(member) == 1) or false
            if exists and not dead then
                local inCombatOk = true
                if requireInCombat and Osi and Osi.IsInCombat and Osi.IsInCombat(member) ~= 1 then
                    inCombatOk = false
                end

                if inCombatOk then
                    eligible = eligible + 1
                    if EA_IsMemberSurpriseImmune(member) then
                        skippedImmune = skippedImmune + 1
                        if EA_IsDebugMode() then
                            DebugPrint(string.format("[Surprise] %s is immune (Alert/passive) - skipping", tostring(member)))
                        end
                    else
                        EA_RequestSurprisePerceptionRoll(member, source, token)
                        rollsRequested = rollsRequested + 1
                    end
                end
            end
        end

        if eligible > 0 then
            EA_SURPRISE_STATE.applied[token] = now
            if rollsRequested == 0 then
                UpdateMetric("surpriseNoRollsRequested")
            end
        elseif EA_IsDebugMode() then
            DebugPrint("Surprise deferred: no eligible in-combat party members yet for token", token)
            UpdateMetric("surpriseDeferredNoEligible")
        end

        if EA_IsDebugMode() then
            DebugPrint(
                string.format(
                    "[Surprise] Perception rolls requested: %d, immune skipped: %d, eligible: %d, token: %s",
                    rollsRequested,
                    skippedImmune,
                    eligible,
                    tostring(token)
                )
            )
        end
    end

    return {
        EA_BuildAmbushToken = EA_BuildAmbushToken,
        EA_IsMemberSurpriseImmune = EA_IsMemberSurpriseImmune,
        EA_ApplySurprisedToMember = EA_ApplySurprisedToMember,
        EA_ApplyAmbushedToMember = EA_ApplyAmbushedToMember,
        EA_RequestSurprisePerceptionRoll = EA_RequestSurprisePerceptionRoll,
        EA_HandleSurpriseRollResult = EA_HandleSurpriseRollResult,
        EA_TryApplyPartySurprise = EA_TryApplyPartySurprise,
    }
end

EA.SystemsSurprise = M
return M
