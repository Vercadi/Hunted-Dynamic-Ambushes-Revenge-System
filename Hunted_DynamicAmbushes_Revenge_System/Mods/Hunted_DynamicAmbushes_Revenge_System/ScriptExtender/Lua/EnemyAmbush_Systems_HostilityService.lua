-- EnemyAmbush_Systems_HostilityService.lua
-- Phase 6 Task 6.4: canonical owner for hostility conversion, faction cohesion,
-- and persistent hostile retry behavior.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local ModuleUUID = EA.ModuleUUID or "96f24297-6ed9-455c-aaa1-ac9c358a8d35"
EA.ModuleUUID = ModuleUUID

local EA_USE_ISOLATED_HOSTILE_FACTION = true
local EA_HOSTILE_FACTION = "2b1660d2-9742-4217-91cc-24d1421c9772"
local EA_ENFORCE_AMBUSH_FACTION_RELATION = true
local EA_ALLOW_GLOBAL_RELATION_WRITES = false
local EA_RELATION_WRITE_CACHE = {}
local EA_RELATION_FORM_PROBE = {
    logged = false,
    ambusher = "",
    player = "",
}

local function EA_HostilityDebugEnabled()
    if EA and type(EA["EA_GetSettingFromSnapshot"]) == "function" then
        local okLogging, logging = pcall(EA["EA_GetSettingFromSnapshot"], "MCM_EnableDebugLogging", false)
        if okLogging and logging == true then
            return true
        end
        local ok, out = pcall(EA["EA_GetSettingFromSnapshot"], "MCM_DebugMode", false)
        if ok then
            return out == true
        end
    end
    return false
end

local function EA_HostilityRobustEnabled()
    local fn = EA and EA["EA_IsRobust"]
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok then
            return out == true
        end
    end
    return false
end

local function EA_CountPersistentHostileRetryRows(field)
    if type(field) ~= "table" then
        return 0, ""
    end
    local count = 0
    local sampleTimer = ""
    for timerId, row in pairs(field) do
        if type(timerId) == "string" and type(row) == "table" then
            count = count + 1
            if sampleTimer == "" then
                sampleTimer = timerId
            end
        end
    end
    return count, sampleTimer
end

local function EA_BuildPersistentHostileRetrySnapshot(mode)
    local snapshot = {
        source = tostring(mode or "raw"),
        availability = "unknown",
        field = "missing",
        count = 0,
        sampleTimer = "",
        modVarsReady = false,
        modVarsReason = "",
        modVarsDetail = "",
    }

    local diagFn = EA and EA["EA_GetModVarsReadyDiagnostics"]
    if type(diagFn) == "function" then
        local okDiag, diag = pcall(diagFn)
        if okDiag and type(diag) == "table" then
            snapshot.modVarsReady = (diag.ready == true)
            snapshot.modVarsReason = tostring(diag.reason or "")
            snapshot.modVarsDetail = tostring(diag.detail or "")
        end
    end

    local vars = nil
    if mode == "strict" then
        local strictFn = EA and EA["EA_GetPersistentVarsStrict"]
        if type(strictFn) ~= "function" then
            snapshot.availability = "strict_missing_export"
            return snapshot
        end
        local okVars, out = pcall(strictFn)
        if not okVars then
            snapshot.availability = "strict_failed"
            snapshot.modVarsDetail = tostring(out or "unknown_error")
            return snapshot
        end
        if not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(out)) or type(out) == "table")) then
            snapshot.availability = "strict_unavailable"
            return snapshot
        end
        vars = out
    else
        if not (Ext and Ext.Vars and Ext.Vars.GetModVariables) then
            snapshot.availability = "ext_vars_unavailable"
            return snapshot
        end
        local okVars, out = pcall(Ext.Vars.GetModVariables, ModuleUUID)
        if not okVars then
            snapshot.availability = "raw_get_failed"
            snapshot.modVarsDetail = tostring(out or "unknown_error")
            return snapshot
        end
        if not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(out)) or type(out) == "table")) then
            snapshot.availability = "raw_invalid_container"
            snapshot.modVarsDetail = string.format("returned=%s", type(out))
            return snapshot
        end
        vars = out
    end

    snapshot.availability = "ok"
    local field = vars.EA_PersistentHostileRetries
    if field == nil then
        snapshot.field = "missing"
        return snapshot
    end
    if not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(field)) or type(field) == "table")) then
        snapshot.field = "invalid_type"
        snapshot.modVarsDetail = string.format("field=%s", type(field))
        return snapshot
    end

    local count, sampleTimer = EA_CountPersistentHostileRetryRows(field)
    snapshot.count = count
    snapshot.sampleTimer = tostring(sampleTimer or "")
    if count > 0 then
        snapshot.field = "present_rows"
    else
        snapshot.field = "present_empty"
    end
    return snapshot
end

local function EA_LogPersistentHostileRetrySnapshot(label, snapshot)
    if EA_HostilityDebugEnabled() ~= true or type(snapshot) ~= "table" then
        return
    end
    print(string.format(
        "[EnemyAmbush][Debug] Persistent hostile retry snapshot[%s]: source=%s availability=%s field=%s count=%s sampleTimer=%s modVarsReady=%s reason=%s detail=%s",
        tostring(label or "unknown"),
        tostring(snapshot.source or ""),
        tostring(snapshot.availability or ""),
        tostring(snapshot.field or ""),
        tostring(snapshot.count or 0),
        tostring(snapshot.sampleTimer or ""),
        tostring(snapshot.modVarsReady == true),
        tostring(snapshot.modVarsReason or ""),
        tostring(snapshot.modVarsDetail or "")
    ))
end

local function EA_GetAmbushHostileFaction()
    if EA_USE_ISOLATED_HOSTILE_FACTION and EA_HOSTILE_FACTION and EA_HOSTILE_FACTION ~= "" then
        return EA_HOSTILE_FACTION
    end
    return nil
end

function EA_ClearHostileState(enemy)
    if not enemy or enemy == "" then return end
    if not EnemyAmbush or not EnemyAmbush._eaHostile then return end
    local st = EnemyAmbush._eaHostile
    if st.tries then st.tries[enemy] = nil end
    if st.lastAttack then st.lastAttack[enemy] = nil end
    if st.lastEnter then st.lastEnter[enemy] = nil end
    if st.factionSet then st.factionSet[enemy] = nil end
    if st.lastAdvance then st.lastAdvance[enemy] = nil end
end

local function EA_TrySetFaction(enemy, faction)
    if not (Osi and Osi.SetFaction) then return false end

    local target = tostring(faction or "")
    if target == "" then return false end

    local ok = pcall(Osi.SetFaction, enemy, faction)
    if not ok then return false end

    if Osi.GetFaction then
        local ok2, current = pcall(Osi.GetFaction, enemy)
        if ok2 and current and current ~= "" then
            local cur = tostring(current)
            local curNorm = EA_NormalizeUUID and EA_NormalizeUUID(cur) or nil
            local tgtNorm = EA_NormalizeUUID and EA_NormalizeUUID(target) or nil
            if curNorm and tgtNorm then
                return curNorm == tgtNorm
            end

            local curLower = string.lower(cur)
            local tgtLower = string.lower(target)
            if curLower == tgtLower then
                return true
            end
            if string.find(curLower, tgtLower, 1, true) then
                return true
            end
            return false
        end
    end

    return true
end

local function EA_FactionsEqual(a, b)
    if not a or not b then return false end
    local sa = tostring(a)
    local sb = tostring(b)
    if sa == "" or sb == "" then return false end

    if EA_NormalizeUUID then
        local na = EA_NormalizeUUID(sa)
        local nb = EA_NormalizeUUID(sb)
        if na and nb then
            return na == nb
        end
    end

    sa = string.lower(sa)
    sb = string.lower(sb)
    if sa == sb then return true end
    if string.find(sa, sb, 1, true) then return true end
    if string.find(sb, sa, 1, true) then return true end
    return false
end

local function EA_ForceAmbusherFaction(enemy)
    if not enemy or enemy == "" then
        return false, nil, nil
    end

    local desiredFaction = EA_GetAmbushHostileFaction()
    if not desiredFaction or desiredFaction == "" then
        return false, nil, nil
    end

    local applied = EA_TrySetFaction(enemy, desiredFaction)
    local currentFaction = nil
    if Osi and Osi.GetFaction then
        local okCurrent, out = pcall(Osi.GetFaction, enemy)
        if okCurrent and out and tostring(out) ~= "" then
            currentFaction = tostring(out)
        end
    end

    local ready = (applied == true)
    if (not ready) and currentFaction and EA_FactionsEqual(currentFaction, desiredFaction) then
        ready = true
    end
    return ready, desiredFaction, currentFaction
end

local function EA_AddUniqueFactionValue(out, seen, factionValue)
    if factionValue == nil then
        return
    end
    local raw = tostring(factionValue or "")
    if raw == "" then
        return
    end
    local key = string.lower(raw)
    if seen[key] then
        return
    end
    seen[key] = true
    out[#out + 1] = factionValue
end

local function EA_ExtractEntityGuid(candidate)
    if type(candidate) == "string" then
        return candidate
    end
    if type(candidate) ~= "table" then
        return nil
    end

    local direct = candidate.EntityUuid or candidate.UUID or candidate.Guid or candidate.Handle
    if type(direct) == "string" and direct ~= "" then
        return direct
    end

    if type(candidate.Uuid) == "string" and candidate.Uuid ~= "" then
        return candidate.Uuid
    end
    if type(candidate.Uuid) == "table" then
        local nested = candidate.Uuid.EntityUuid or candidate.Uuid.UUID or candidate.Uuid.Guid
        if type(nested) == "string" and nested ~= "" then
            return nested
        end
    end

    if type(candidate[1]) == "string" and candidate[1] ~= "" then
        return candidate[1]
    end
    return nil
end

local function EA_AddUniqueCharacter(out, seen, character)
    local raw = EA_ExtractEntityGuid(character)
    if not raw or raw == "" then
        return
    end
    local norm = EA_NormalizeUUID and EA_NormalizeUUID(raw) or raw
    local key = string.lower(tostring(norm or raw))
    if seen[key] then
        return
    end
    if Osi and Osi.ObjectExists and Osi.ObjectExists(raw) ~= 1 then
        return
    end
    seen[key] = true
    out[#out + 1] = raw
end

local function EA_TryGetField(obj, field)
    if obj == nil then
        return nil, false
    end
    local ok, value = pcall(function()
        return obj[field]
    end)
    if not ok then
        return nil, false
    end
    return value, true
end

local function EA_AppendCharacterCollection(out, seen, collection)
    if collection == nil then
        return 0
    end
    local addedBefore = #out

    if type(collection) == "table" then
        for _, member in ipairs(collection) do
            EA_AddUniqueCharacter(out, seen, member)
        end
        return #out - addedBefore
    end

    if type(collection) == "userdata" then
        local idx = 1
        while idx <= 256 do
            local okItem, member = pcall(function()
                return collection[idx]
            end)
            if not okItem or member == nil then
                break
            end
            EA_AddUniqueCharacter(out, seen, member)
            idx = idx + 1
        end
    end

    return #out - addedBefore
end

local function EA_TryAppendSEPartyTreeTargets(out, seen, anchorPlayer)
    if not (Ext and Ext.Entity and type(Ext.Entity.Get) == "function") then
        return false
    end
    if not anchorPlayer or anchorPlayer == "" then
        return false
    end

    local okEnt, ent = pcall(Ext.Entity.Get, anchorPlayer)
    if not okEnt or not ent then
        return false
    end

    local partyMember = select(1, EA_TryGetField(ent, "PartyMember"))
    if not partyMember then
        return false
    end
    local party = select(1, EA_TryGetField(partyMember, "Party"))
    if not party then
        return false
    end

    local candidateRoots = { party }
    local partyView = select(1, EA_TryGetField(party, "PartyView"))
    if partyView then
        candidateRoots[#candidateRoots + 1] = partyView
    end

    local memberFields = {
        "Characters",
        "Members",
        "PartyMembers",
        "CharacterGuids",
        "Entities",
        "Participants",
    }

    for _, root in ipairs(candidateRoots) do
        for _, field in ipairs(memberFields) do
            local collection, okField = EA_TryGetField(root, field)
            if okField and collection ~= nil then
                local added = EA_AppendCharacterCollection(out, seen, collection)
                if added > 0 then
                    return true
                end
            end
        end
    end

    return false
end

local function EA_GetHostilityTargets(anchorPlayer)
    local out = {}
    local seen = {}
    EA_AddUniqueCharacter(out, seen, anchorPlayer)

    local usedSEPartyTree = EA_TryAppendSEPartyTreeTargets(out, seen, anchorPlayer)

    if (not usedSEPartyTree or #out <= 1) and Osi then
        if Osi.DB_PartyMembers and Osi.DB_PartyMembers.Get then
            local okParty, rows = pcall(function() return Osi.DB_PartyMembers:Get(nil) end)
            if okParty and type(rows) == "table" then
                for _, row in ipairs(rows) do
                    EA_AddUniqueCharacter(out, seen, row and row[1])
                end
            end
        end
        if Osi.DB_PlayerSummons and Osi.DB_PlayerSummons.Get then
            local okSummons, rows = pcall(function() return Osi.DB_PlayerSummons:Get(nil, nil) end)
            if okSummons and type(rows) == "table" then
                for _, row in ipairs(rows) do
                    local summon = row and row[1]
                    local owner = row and row[2]
                    if owner and Osi.IsPlayer and Osi.IsPlayer(owner) == 1 then
                        EA_AddUniqueCharacter(out, seen, summon)
                    end
                end
            end
        end
        if Osi.DB_IsFollower and Osi.DB_IsFollower.Get then
            local okFollowers, rows = pcall(function() return Osi.DB_IsFollower:Get(nil, nil) end)
            if okFollowers and type(rows) == "table" then
                for _, row in ipairs(rows) do
                    local follower = row and row[1]
                    local owner = row and row[2]
                    if owner and Osi.IsPlayer and Osi.IsPlayer(owner) == 1 then
                        EA_AddUniqueCharacter(out, seen, follower)
                    end
                end
            end
        end
    end

    if #out == 0 and Osi and Osi.GetHostCharacter then
        EA_AddUniqueCharacter(out, seen, Osi.GetHostCharacter())
    end
    return out
end

local function EA_GetPartyFactionValues(anchorPlayer)
    local out = {}
    local seen = {}
    if not (Osi and Osi.GetFaction) then
        return out
    end

    local function AddFactionFromCharacter(character)
        if not character or character == "" then
            return
        end
        if Osi.ObjectExists and Osi.ObjectExists(character) ~= 1 then
            return
        end
        local okF, factionValue = pcall(Osi.GetFaction, character)
        if okF and factionValue and tostring(factionValue) ~= "" then
            EA_AddUniqueFactionValue(out, seen, factionValue)
        end
    end

    AddFactionFromCharacter(anchorPlayer)

    local targets = EA_GetHostilityTargets(anchorPlayer)
    for _, member in ipairs(targets) do
        AddFactionFromCharacter(member)
    end

    if #out == 0 and Osi.GetHostCharacter then
        AddFactionFromCharacter(Osi.GetHostCharacter())
    end
    return out
end

local function EA_TryApplyGlobalFactionRelationBidirectional(ambusherFactionCandidates, playerFactionValue)
    if not (Osi and Osi.SetRelation) then
        return false
    end
    if type(ambusherFactionCandidates) ~= "table" or #ambusherFactionCandidates == 0 then
        return false
    end
    if playerFactionValue == nil or tostring(playerFactionValue) == "" then
        return false
    end

    local playerKey = string.lower(tostring(playerFactionValue))
    do
        local n = 0
        for _ in pairs(EA_RELATION_WRITE_CACHE) do
            n = n + 1
            if n > 2048 then
                EA_RELATION_WRITE_CACHE = {}
                break
            end
        end
    end
    for _, ambusherFaction in ipairs(ambusherFactionCandidates) do
        local ambusherKey = string.lower(tostring(ambusherFaction or ""))
        if ambusherKey ~= "" then
            local relKeyEfPf = ambusherKey .. "|" .. playerKey
            local relKeyPfEf = playerKey .. "|" .. ambusherKey
            if not EA_RELATION_WRITE_CACHE[relKeyEfPf] or not EA_RELATION_WRITE_CACHE[relKeyPfEf] then
                local okAB = pcall(Osi.SetRelation, ambusherFaction, playerFactionValue, 0)
                local okBA = pcall(Osi.SetRelation, playerFactionValue, ambusherFaction, 0)
                if okAB and okBA then
                    EA_RELATION_WRITE_CACHE[relKeyEfPf] = true
                    EA_RELATION_WRITE_CACHE[relKeyPfEf] = true
                    if EA_HostilityDebugEnabled() and EA_RELATION_FORM_PROBE.logged ~= true then
                        EA_RELATION_FORM_PROBE.logged = true
                        EA_RELATION_FORM_PROBE.ambusher = tostring(ambusherFaction)
                        EA_RELATION_FORM_PROBE.player = tostring(playerFactionValue)
                        DebugPrint(
                            "SetRelation form probe success:",
                            "ambusher=",
                            tostring(ambusherFaction),
                            "player=",
                            tostring(playerFactionValue)
                        )
                    end
                    return true
                end
            end
        end
    end
    return false
end

local function EA_EnsureEnemyHostileToPlayerFaction(enemy, player)
    if not EA_ENFORCE_AMBUSH_FACTION_RELATION then return end
    if not EA_USE_ISOLATED_HOSTILE_FACTION then return end
    if not enemy or enemy == "" or not player or player == "" then return end
    if not Osi or not Osi.GetFaction then return end

    local okEf, ef = pcall(Osi.GetFaction, enemy)
    local okPf, pf = pcall(Osi.GetFaction, player)
    ef = (okEf and ef and tostring(ef) ~= "") and tostring(ef) or nil
    pf = (okPf and pf and tostring(pf) ~= "") and tostring(pf) or nil
    if not ef or not pf then return end

    local isolatedFaction = EA_GetAmbushHostileFaction()
    local enemyOnIsolatedFaction = isolatedFaction and EA_FactionsEqual(ef, isolatedFaction)

    if not enemyOnIsolatedFaction then
        if EA_HostilityDebugEnabled() then
            DebugPrint("Skipped faction-relation enforcement (enemy not on ambush faction):", tostring(enemy), "faction=", tostring(ef))
        end
        return
    end

    if EA_ALLOW_GLOBAL_RELATION_WRITES == true and Osi.SetRelation then
        local ambusherFactionCandidates = {}
        local seenAmbusher = {}
        EA_AddUniqueFactionValue(ambusherFactionCandidates, seenAmbusher, ef)
        EA_AddUniqueFactionValue(ambusherFactionCandidates, seenAmbusher, EA_HOSTILE_FACTION)

        local partyFactions = EA_GetPartyFactionValues(player)
        if #partyFactions == 0 then
            EA_AddUniqueFactionValue(partyFactions, {}, pf)
        end

        for _, partyFaction in ipairs(partyFactions) do
            EA_TryApplyGlobalFactionRelationBidirectional(ambusherFactionCandidates, partyFaction)
        end
    end

    if Osi.SetIndividualRelation then
        local targets = EA_GetHostilityTargets(player)
        if #targets > 0 then
            for _, target in ipairs(targets) do
                if target and target ~= "" and (not Osi.ObjectExists or Osi.ObjectExists(target) == 1) then
                    pcall(Osi.SetIndividualRelation, enemy, target, 0)
                    pcall(Osi.SetIndividualRelation, target, enemy, 0)
                end
            end
        else
            pcall(Osi.SetIndividualRelation, enemy, pf, 0)
            pcall(Osi.SetIndividualRelation, player, ef, 0)
        end
    end
end

local EA_DEFER_HOSTILE_MAX_TRIES = 20
local EA_DEFER_HOSTILE_DELAY_MS = 250
local EA_DEFER_HOSTILE_TRIES = {}
local EA_DEFER_HOSTILE_PERSIST_AFTER_TRY = 3
local EA_DEFER_HOSTILE_PERSIST_DELAY_MS = 1000
local EA_PERSIST_HOSTILE_TIMER_PREFIX = "EA_HOSTILE_RETRY_"
local EA_HOSTILE_APPROACH_INTERVAL_MS = 700
local EA_HOSTILE_IN_COMBAT_APPROACH_MAX_DISTANCE = 12
local EA_HOSTILE_IN_COMBAT_APPROACH_TOLERANCE = 1.5
local EA_HOSTILE_IN_COMBAT_RETRY_DELAY_MS = 500

EA_MakeAmbushHostile = EA_MakeAmbushHostile

local function EA_GetDeferredSupportJoinWindowCompat(...)
    local fn = EA and EA["EA_GetDeferredSupportJoinWindow"]
    if type(fn) == "function" then
        return fn(...)
    end
    return nil
end

local function EA_ShouldLogDeferredJoinCompat(...)
    local fn = EA and EA["EA_ShouldLogDeferredJoin"]
    if type(fn) == "function" then
        return fn(...)
    end
    return true
end

local function EA_EvaluateDeferredSupportJoinRulesCompat(joinWindow, playerInCombat, ...)
    local fn = EA and EA["EA_EvaluateDeferredSupportJoinRules"]
    if type(fn) == "function" then
        return fn(joinWindow, playerInCombat, ...)
    end
    return {
        allowForcedJoin = (playerInCombat ~= true),
        joinGraceActive = false,
        joinGraceAgeMs = 0,
        forceJoinMaxDistance = 35,
        forceJoinWhilePlayerInCombat = true,
    }
end

local function EA_CommandApproachAndStrike(enemy, player, tries, hostileState, allowPositionFallback)
    if not enemy or enemy == "" or not player or player == "" then return end
    if not hostileState then return end
    if Osi.ObjectExists and (Osi.ObjectExists(enemy) ~= 1 or Osi.ObjectExists(player) ~= 1) then return end
    if allowPositionFallback == nil then
        allowPositionFallback = true
    end

    local now = 0
    if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
        now = Ext.Utils.MonotonicTime()
    elseif EA_NowMs then
        now = EA_NowMs()
    end

    local lastAdvance = hostileState.lastAdvance[enemy] or 0
    if (now - lastAdvance) >= EA_HOSTILE_APPROACH_INTERVAL_MS then
        hostileState.lastAdvance[enemy] = now

        local moved = false
        if Osi.CharacterMoveTo then
            moved = pcall(Osi.CharacterMoveTo, enemy, player, "Sprint", 0)
        end

        if (not moved) and allowPositionFallback and Osi.CharacterMoveToPosition and Osi.GetPosition then
            local okPos, px, py, pz = pcall(Osi.GetPosition, player)
            if okPos and px and pz then
                pcall(Osi.CharacterMoveToPosition, enemy, px, py or 0, pz, "Sprint", "", 0)
            end
        end
    end
end

local function EA_PersistentHostileRetryQueue()
    local vars = EA_Vars and EA_Vars() or nil
    if not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(vars)) or type(vars) == "table")) then
        return nil, nil
    end
    local queue = vars.EA_PersistentHostileRetries
    if not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(queue)) or type(queue) == "table")) then
        return nil, vars
    end
    return queue, vars
end

local function EA_CopyPersistentHostileRetryQueue(source)
    local snapshot = {}
    if not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(source)) or type(source) == "table")) then
        return snapshot
    end
    for timerId, row in pairs(source) do
        if type(timerId) == "string" and (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(row)) or type(row) == "table")) then
            snapshot[timerId] = {
                enemy = tostring(row.enemy or ""),
                player = tostring(row.player or ""),
                tries = tonumber(row.tries) or 0,
                reason = tostring(row.reason or ""),
                delayMs = tonumber(row.delayMs) or 0,
                enqueuedAt = tonumber(row.enqueuedAt) or 0,
            }
        end
    end
    return snapshot
end

local function EA_WritePersistentHostileRetryQueue(queueSnapshot, immediateDirty)
    local vars = EA_Vars and EA_Vars() or nil
    if not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(vars)) or type(vars) == "table")) then
        return false
    end
    local okWrite = pcall(function()
        vars.EA_PersistentHostileRetries = EA_CopyPersistentHostileRetryQueue(queueSnapshot)
    end)
    if not okWrite then
        return false
    end
    if EA_Dirty then
        EA_Dirty(immediateDirty == true)
    end
    return true
end

local function EA_MakePersistentHostileRetryTimer(enemy)
    local id = EA_NormalizeUUID and EA_NormalizeUUID(enemy) or tostring(enemy or "enemy")
    local stamp = (Ext and Ext.Utils and Ext.Utils.MonotonicTime and tonumber(Ext.Utils.MonotonicTime())) or (os.time() * 1000)
    return string.format("%s%s_%d", EA_PERSIST_HOSTILE_TIMER_PREFIX, tostring(id), math.floor(tonumber(stamp) or 0))
end

local function EA_SchedulePersistentHostileRetry(enemy, player, tries, reason, delayMs)
    if not (Osi and Osi.TimerLaunch) then
        return false
    end

    local timerId = EA_MakePersistentHostileRetryTimer(enemy)
    local launchMs = math.max(250, tonumber(delayMs) or EA_DEFER_HOSTILE_PERSIST_DELAY_MS)
    local currentQueue = EA_PersistentHostileRetryQueue()
    local nextQueue = EA_CopyPersistentHostileRetryQueue(currentQueue)
    nextQueue[timerId] = {
        enemy = enemy,
        player = player,
        tries = tonumber(tries) or 0,
        reason = tostring(reason or ""),
        delayMs = launchMs,
        enqueuedAt = EA_NowMs and tonumber(EA_NowMs()) or 0,
    }
    if not EA_WritePersistentHostileRetryQueue(nextQueue, true) then
        return false
    end
    pcall(Osi.TimerLaunch, timerId, launchMs)
    if EA_HostilityDebugEnabled() then
        print(string.format(
            "[EnemyAmbush][Debug] Persistent hostile retry scheduled: timer=%s enemy=%s player=%s tries=%s reason=%s delayMs=%s",
            tostring(timerId),
            tostring(enemy),
            tostring(player),
            tostring(tries or 0),
            tostring(reason or ""),
            tostring(launchMs)
        ))
    end
    return true, timerId
end

function EA_HandlePersistentHostileRetryTimer(timer)
    if type(timer) ~= "string" or timer:match("^" .. EA_PERSIST_HOSTILE_TIMER_PREFIX) == nil then
        return false
    end
    local currentQueue = EA_PersistentHostileRetryQueue()
    local row = (type(currentQueue) == "table") and currentQueue[timer] or nil
    if type(currentQueue) == "table" and row ~= nil then
        local nextQueue = EA_CopyPersistentHostileRetryQueue(currentQueue)
        nextQueue[timer] = nil
        EA_WritePersistentHostileRetryQueue(nextQueue, true)
    end
    if not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(row)) or type(row) == "table")) then
        if EA_HostilityDebugEnabled() then
            print(string.format(
                "[EnemyAmbush][Debug] Persistent hostile retry timer fired without queue row: timer=%s",
                tostring(timer)
            ))
        end
        return true
    end

    local enemy = tostring(row.enemy or "")
    local player = tostring(row.player or "")
    if enemy == "" or player == "" then
        return true
    end
    if Osi and Osi.ObjectExists then
        if Osi.ObjectExists(enemy) ~= 1 or Osi.ObjectExists(player) ~= 1 then
            EA_ClearHostileState(enemy)
            return true
        end
    end

    local previous = tonumber(EA_DEFER_HOSTILE_TRIES[enemy]) or 0
    local replayTry = tonumber(row.tries) or 0
    EA_DEFER_HOSTILE_TRIES[enemy] = math.max(previous, replayTry)
    if EA_HostilityDebugEnabled() then
        print(string.format(
            "[EnemyAmbush][Debug] Persistent hostile retry timer firing: timer=%s enemy=%s player=%s tries=%s reason=%s",
            tostring(timer),
            tostring(enemy),
            tostring(player),
            tostring(replayTry),
            tostring(row.reason or "")
        ))
    end
    EA_MakeAmbushHostile(enemy, player)
    return true
end

function EA_RearmPersistentHostileRetries()
    if not (Osi and Osi.TimerLaunch) then
        return 0
    end
    local decisionSnapshot = EA_BuildPersistentHostileRetrySnapshot("strict")
    local queue = EA_PersistentHostileRetryQueue()
    if type(queue) ~= "table" then
        if EA_HostilityDebugEnabled() then
            print(string.format(
                "[EnemyAmbush][Debug] Persistent hostile retry rearm decision: field=%s availability=%s count=%s rearmed=0 queueType=%s",
                tostring(type(decisionSnapshot) == "table" and decisionSnapshot.field or ""),
                tostring(type(decisionSnapshot) == "table" and decisionSnapshot.availability or ""),
                tostring(type(decisionSnapshot) == "table" and decisionSnapshot.count or 0),
                tostring(type(queue))
            ))
        end
        return 0
    end
    local rearmed = 0
    local sanitizedQueue = EA_CopyPersistentHostileRetryQueue(queue)
    local pruned = false
    for timerId, row in pairs(sanitizedQueue) do
        if type(timerId) == "string"
            and timerId:match("^" .. EA_PERSIST_HOSTILE_TIMER_PREFIX)
            and type(row) == "table"
            and type(row.enemy) == "string"
            and row.enemy ~= ""
            and type(row.player) == "string"
            and row.player ~= "" then
            local ms = math.max(250, tonumber(row.delayMs) or EA_DEFER_HOSTILE_PERSIST_DELAY_MS)
            pcall(Osi.TimerLaunch, timerId, ms)
            rearmed = rearmed + 1
        else
            sanitizedQueue[timerId] = nil
            pruned = true
        end
    end
    if pruned then
        EA_WritePersistentHostileRetryQueue(sanitizedQueue, true)
    end
    if EA_HostilityDebugEnabled() then
        print(string.format(
            "[EnemyAmbush][Debug] Persistent hostile retry rearm decision: field=%s availability=%s count=%s rearmed=%s sampleTimer=%s",
            tostring(type(decisionSnapshot) == "table" and decisionSnapshot.field or ""),
            tostring(type(decisionSnapshot) == "table" and decisionSnapshot.availability or ""),
            tostring(type(decisionSnapshot) == "table" and decisionSnapshot.count or 0),
            tostring(rearmed),
            tostring(type(decisionSnapshot) == "table" and decisionSnapshot.sampleTimer or "")
        ))
    end
    return rearmed
end

local function EA_DebugDescribePersistentHostileRetries()
    local snapshot = {
        count = 0,
        entries = {},
    }
    local queue = EA_PersistentHostileRetryQueue()
    if type(queue) ~= "table" then
        return snapshot
    end
    for timerId, row in pairs(queue) do
        if type(timerId) == "string" and (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(row)) or type(row) == "table")) then
            snapshot.entries[#snapshot.entries + 1] = {
                timerId = timerId,
                enemy = tostring(row.enemy or ""),
                player = tostring(row.player or ""),
                tries = tonumber(row.tries) or 0,
                reason = tostring(row.reason or ""),
                delayMs = tonumber(row.delayMs) or 0,
                enqueuedAt = tonumber(row.enqueuedAt) or 0,
            }
        end
    end
    table.sort(snapshot.entries, function(a, b)
        return tostring(a.timerId or "") < tostring(b.timerId or "")
    end)
    snapshot.count = #snapshot.entries
    return snapshot
end

local function EA_DebugSchedulePersistentHostileRetry(enemy, player, tries, reason, delayMs)
    enemy = tostring(enemy or "")
    player = tostring(player or "")
    if enemy == "" or player == "" then
        return false, "invalid enemy or player"
    end
    if Osi and Osi.ObjectExists then
        if Osi.ObjectExists(enemy) ~= 1 then
            return false, "enemy missing"
        end
        if Osi.ObjectExists(player) ~= 1 then
            return false, "player missing"
        end
    end
    local ok, timerId = EA_SchedulePersistentHostileRetry(
        enemy,
        player,
        tonumber(tries) or 0,
        tostring(reason or "debug_phase6_load_rearm_probe"),
        tonumber(delayMs) or EA_DEFER_HOSTILE_PERSIST_DELAY_MS
    )
    if ok == true then
        return true, timerId
    end
    return false, "schedule failed"
end

local function EA_DebugClearPersistentHostileRetries()
    local queue = EA_PersistentHostileRetryQueue()
    if type(queue) ~= "table" then
        return 0
    end
    local removed = 0
    for timerId, _ in pairs(queue) do
        removed = removed + 1
    end
    if removed > 0 then
        EA_WritePersistentHostileRetryQueue({}, true)
    end
    return removed
end

local function EA_DeferHostility(enemy, player, reason)
    if not (Ext and Ext.Timer and Ext.Timer.WaitFor) then
        if EA_SchedulePersistentHostileRetry(enemy, player, EA_DEFER_HOSTILE_TRIES[enemy] or 0, reason, EA_DEFER_HOSTILE_PERSIST_DELAY_MS) then
            return
        end
        if Osi and Osi.RequestDelete then Osi.RequestDelete(enemy) end
        return
    end

    EA_DEFER_HOSTILE_TRIES[enemy] = (EA_DEFER_HOSTILE_TRIES[enemy] or 0) + 1
    local tries = EA_DEFER_HOSTILE_TRIES[enemy]

    if tries > EA_DEFER_HOSTILE_MAX_TRIES then
        if EA_HostilityRobustEnabled() then
            print(string.format("[EnemyAmbush][ROBUST] Deferred hostile timed out (%s). Deleting enemy=%s",
                tostring(reason), tostring(enemy)))
        end
        EA_DEFER_HOSTILE_TRIES[enemy] = nil
        if Osi and Osi.RequestDelete then Osi.RequestDelete(enemy) end
        return
    end

    if EA_HostilityRobustEnabled() then
        print(string.format("[EnemyAmbush][ROBUST] Deferring hostile (%s) try=%d/%d enemy=%s",
            tostring(reason), tries, EA_DEFER_HOSTILE_MAX_TRIES, tostring(enemy)))
    end

    if tries >= EA_DEFER_HOSTILE_PERSIST_AFTER_TRY then
        if EA_SchedulePersistentHostileRetry(enemy, player, tries, reason, EA_DEFER_HOSTILE_PERSIST_DELAY_MS) then
            return
        end
    end

    Ext.Timer.WaitFor(EA_DEFER_HOSTILE_DELAY_MS, function()
        EA_MakeAmbushHostile(enemy, player)
    end)
end

EA_MakeAmbushHostile = function(enemy, player)
    if not enemy or enemy == "" then return end
    if not player or player == "" then return end
    if not Osi then return end

    EnemyAmbush._eaHostile = EnemyAmbush._eaHostile or {
        tries = {},
        lastAttack = {},
        lastEnter = {},
        factionSet = {},
        lastAdvance = {},
        ambushFactionById = {},
    }
    local st = EnemyAmbush._eaHostile
    st.tries = st.tries or {}
    st.lastAttack = st.lastAttack or {}
    st.lastEnter = st.lastEnter or {}
    st.factionSet = st.factionSet or {}
    st.lastAdvance = st.lastAdvance or {}
    st.ambushFactionById = st.ambushFactionById or {}

    if Osi.ObjectExists and Osi.ObjectExists(enemy) ~= 1 then
        EA_ClearHostileState(enemy)
        return
    end
    if Osi.IsDead and Osi.IsDead(enemy) == 1 then
        EA_ClearHostileState(enemy)
        return
    end

    local enemyInCombat = (Osi.IsInCombat and Osi.IsInCombat(enemy) == 1)
    local playerInCombat = (Osi.IsInCombat and Osi.IsInCombat(player) == 1) or false

    local tries = (st.tries[enemy] or 0) + 1
    st.tries[enemy] = tries

    if Osi.SetOnStage then
        pcall(Osi.SetOnStage, enemy, 1)
    end
    if Osi.SetCanFight then
        pcall(Osi.SetCanFight, enemy, 1)
    end
    if Osi.SetCanJoinCombat then
        pcall(Osi.SetCanJoinCombat, enemy, 1)
    end

    local enemyKey = EA_NormalizeUUID(enemy) or enemy
    local ambushId = nil
    local disableAggressiveAdvance = false
    local forceCombatJoin = false
    do
        local spawned = EA_Spawned and EA_Spawned() or nil
        if type(spawned) == "table" then
            local sd = spawned[enemyKey] or spawned[enemy]
            if type(sd) == "table" then
                local aid = tostring(sd.ambushId or "")
                if aid ~= "" then ambushId = aid end
                disableAggressiveAdvance = (sd.disableAggressiveAdvance == true) or (sd.isChampion == true)
                forceCombatJoin = (sd.forceCombatJoin == true) or (tostring(sd.spawnRole or "") == "champion_retinue")
            end
        end
    end
    local joinWindow = nil
    local joinCombatKey = ""
    if ambushId then
        joinWindow = EA_GetDeferredSupportJoinWindowCompat(ambushId)
        if type(joinWindow) == "table" then
            joinCombatKey = tostring(joinWindow.combatKey or "")
        end
    end

    if Osi.SetFaction and not st.factionSet[enemy] then
        local function EA_CurrentEnemyFaction()
            if not Osi.GetFaction then return nil end
            local okF, current = pcall(Osi.GetFaction, enemy)
            if okF and current and current ~= "" then
                return current
            end
            return nil
        end

        local desired = nil
        if ambushId and st.ambushFactionById[ambushId] then
            desired = st.ambushFactionById[ambushId]
        end
        if not desired or desired == "" then
            desired = EA_GetAmbushHostileFaction()
        end

        local ok = false
        if desired and desired ~= "" then
            ok = EA_TrySetFaction(enemy, desired)
        end
        local appliedFaction = ok and (EA_CurrentEnemyFaction() or desired) or nil

        if (not ok) and EA_HostilityDebugEnabled() then
            DebugPrint("Ambush faction not ready yet; will retry:", tostring(enemy), "try=", tostring(tries))
        end

        if ok then
            st.factionSet[enemy] = true

            if ambushId and appliedFaction and appliedFaction ~= "" then
                st.ambushFactionById[ambushId] = appliedFaction
            end

            EA_EnsureEnemyHostileToPlayerFaction(enemy, player)
        end
    end

    local MAX_TRIES = 8
    local requiredFaction = nil
    if ambushId then
        requiredFaction = st.ambushFactionById[ambushId]
    end
    if not requiredFaction or requiredFaction == "" then
        requiredFaction = EA_GetAmbushHostileFaction()
    end

    if requiredFaction and Osi.GetFaction then
        local okF, currentFaction = pcall(Osi.GetFaction, enemy)
        local current = (okF and currentFaction and tostring(currentFaction) ~= "") and tostring(currentFaction) or nil
        if (not current) or (not EA_FactionsEqual(current, requiredFaction)) then
            st.factionSet[enemy] = nil

            if EA_HostilityDebugEnabled() then
                DebugPrint("Faction cohesion retry:", tostring(enemy), "expected=", tostring(requiredFaction), "current=", tostring(current))
            end

            if tries >= MAX_TRIES then
                UpdateMetric("hostileRetriesExhausted")
                EA_SetLastError("HostileFactionMismatch", "enemy=" .. tostring(enemy))
                EA_LogEvent("HOSTILE_FAIL", "Faction mismatch enemy=" .. tostring(enemy) .. " expected=" .. tostring(requiredFaction) .. " current=" .. tostring(current))
                local norm = EA_NormalizeUUID(enemy) or enemy
                local spawned = EA_Spawned()
                if type(spawned) == "table" or type(spawned) == "userdata" then
                    spawned[norm] = nil
                    spawned[enemy] = nil
                    EA_Dirty()
                end
                if Osi and Osi.ObjectExists and Osi.ObjectExists(enemy) == 1 and Osi.RequestDelete then
                    pcall(Osi.RequestDelete, enemy)
                end
                EA_ClearHostileState(enemy)
                return
            end

            if Ext and Ext.Timer and Ext.Timer.WaitFor then
                Ext.Timer.WaitFor(150, function()
                    if Osi.ObjectExists and Osi.ObjectExists(player) ~= 1 then
                        EA_ClearHostileState(enemy)
                        return
                    end
                    EA_MakeAmbushHostile(enemy, player)
                end)
            end
            return
        end
    end

    if Osi.SetOnStage then
        pcall(Osi.SetOnStage, enemy, 1)
    end

    if Osi.SetCanFight then
        pcall(Osi.SetCanFight, enemy, 1)
    end
    if Osi.SetCanJoinCombat then
        pcall(Osi.SetCanJoinCombat, enemy, 1)
    end

    EA_EnsureEnemyHostileToPlayerFaction(enemy, player)

    if Osi.SetRelationTemporaryHostile then
        pcall(Osi.SetRelationTemporaryHostile, enemy, player)
        pcall(Osi.SetRelationTemporaryHostile, player, enemy)
    end

    local distToPlayer = nil
    if Osi.GetDistanceTo then
        local okDist, d = pcall(Osi.GetDistanceTo, enemy, player)
        if okDist and tonumber(d) then
            distToPlayer = tonumber(d)
        end
    end

    local now = 0
    if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
        now = tonumber(Ext.Utils.MonotonicTime()) or 0
    elseif type(EA_NowMs) == "function" then
        now = tonumber(EA_NowMs()) or 0
    end
    local catchupSoftMaxDistance = EA_HOSTILE_IN_COMBAT_APPROACH_MAX_DISTANCE + EA_HOSTILE_IN_COMBAT_APPROACH_TOLERANCE
    local joinDecision = EA_EvaluateDeferredSupportJoinRulesCompat(joinWindow, playerInCombat, distToPlayer, catchupSoftMaxDistance)
    local allowForcedJoin = (type(joinDecision) == "table" and joinDecision.allowForcedJoin == true) or (not playerInCombat)
    if forceCombatJoin then
        allowForcedJoin = true
    end
    local joinGraceActive = (type(joinDecision) == "table" and joinDecision.joinGraceActive == true) or false
    local joinGraceAgeMs = (type(joinDecision) == "table" and tonumber(joinDecision.joinGraceAgeMs)) or 0
    local forceJoinMaxDistance = (type(joinDecision) == "table" and tonumber(joinDecision.forceJoinMaxDistance)) or 35
    if allowForcedJoin and playerInCombat and distToPlayer then
        if EA_HostilityDebugEnabled()
            and ambushId
                and EA_ShouldLogDeferredJoinCompat(ambushId, joinCombatKey, "force_join_window") then
            DebugPrint(
                "Deferred support forced catch-up enabled:",
                tostring(enemy),
                "dist=",
                tostring(distToPlayer),
                "softMax=",
                tostring(catchupSoftMaxDistance),
                "forceMax=",
                tostring(forceJoinMaxDistance),
                "graceActive=",
                tostring(joinGraceActive),
                "graceAgeMs=",
                tostring(joinGraceAgeMs),
                "combat=",
                tostring(joinCombatKey)
            )
        end
    end

    local tooFarInCombatCatchup = false
    if playerInCombat and (not allowForcedJoin) and distToPlayer then
        tooFarInCombatCatchup = (distToPlayer > catchupSoftMaxDistance)
    end
    if tooFarInCombatCatchup then
        if EA_HostilityDebugEnabled()
                and EA_ShouldLogDeferredJoinCompat(ambushId, joinCombatKey, "too_far_retry") then
            DebugPrint(
                "Deferred support catch-up skipped (player already in combat, too far):",
                tostring(enemy),
                "dist=",
                tostring(distToPlayer),
                "softMax=",
                tostring(catchupSoftMaxDistance),
                "forceMax=",
                tostring(forceJoinMaxDistance),
                "graceActive=",
                tostring(joinGraceActive),
                "graceAgeMs=",
                tostring(joinGraceAgeMs),
                "combat=",
                tostring(joinCombatKey)
            )
        end
        st.tries[enemy] = math.min(2, st.tries[enemy] or 2)
        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(EA_HOSTILE_IN_COMBAT_RETRY_DELAY_MS, function()
                if Osi.ObjectExists and Osi.ObjectExists(player) ~= 1 then
                    EA_ClearHostileState(enemy)
                    return
                end
                EA_MakeAmbushHostile(enemy, player)
            end)
        end
        return
    end

    if Osi.SetHostileAndEnterCombat and Osi.GetFaction then
        local ef = Osi.GetFaction(enemy)
        local pf = Osi.GetFaction(player)
        local factionReady = (ef and ef ~= "" and requiredFaction and requiredFaction ~= "" and EA_FactionsEqual(ef, requiredFaction))
        if factionReady and pf and pf ~= "" and allowForcedJoin then
            pcall(Osi.SetHostileAndEnterCombat, ef, pf, enemy, player)
        elseif EA_HostilityDebugEnabled() and tries <= 2 then
            if not factionReady then
                DebugPrint("Skipped SetHostileAndEnterCombat (faction not ready):", tostring(enemy), "current=", tostring(ef), "required=", tostring(requiredFaction))
            elseif playerInCombat and not allowForcedJoin and EA_ShouldLogDeferredJoinCompat(ambushId, joinCombatKey, "skip_sethostile") then
                DebugPrint("Skipped SetHostileAndEnterCombat (player already in combat):", tostring(enemy), "dist=", tostring(distToPlayer))
            end
        end
    end

    if (not enemyInCombat) and Osi.EnterCombat and allowForcedJoin then
        local lastEnter = st.lastEnter[enemy] or 0
        if (now - lastEnter) >= 250 then
            st.lastEnter[enemy] = now
            pcall(Osi.EnterCombat, enemy, player)
        end
    end

    if tries >= 2 and not enemyInCombat and not disableAggressiveAdvance then
        if playerInCombat and tries >= 3 and Osi.ApplyStatus then
            pcall(Osi.ApplyStatus, enemy, "MAG_MOMENTUM", 6, 1, enemy)
        end
        EA_CommandApproachAndStrike(enemy, player, tries, st, not playerInCombat)
    end

    if Osi.IsInCombat and Osi.IsInCombat(enemy) == 1 then
        EA_ClearHostileState(enemy)
        return
    end

    if tries >= MAX_TRIES then
        UpdateMetric("hostileRetriesExhausted")
        EA_SetLastError("HostileRetriesExhausted", "enemy=" .. tostring(enemy))
        EA_LogEvent("HOSTILE_FAIL", "Exhausted retries enemy=" .. tostring(enemy) .. " player=" .. tostring(player))
        local norm = EA_NormalizeUUID(enemy) or enemy
        local spawned = EA_Spawned()
        if type(spawned) == "table" or type(spawned) == "userdata" then
            spawned[norm] = nil
            spawned[enemy] = nil
            EA_Dirty()
        end
        if Osi and Osi.ObjectExists and Osi.ObjectExists(enemy) == 1 and Osi.RequestDelete then
            pcall(Osi.RequestDelete, enemy)
            if EA_HostilityDebugEnabled() then
                print(string.format("[EnemyAmbush][Debug] Deleted stuck ambusher after hostile retry exhaustion: %s", tostring(enemy)))
            end
        end
        EA_ClearHostileState(enemy)
        return
    end

    if Ext and Ext.Timer and Ext.Timer.WaitFor then
        Ext.Timer.WaitFor(150, function()
            if Osi.ObjectExists and Osi.ObjectExists(player) ~= 1 then
                EA_ClearHostileState(enemy)
                return
            end
            EA_MakeAmbushHostile(enemy, player)
        end)
    end
end

EA["EA_ForceAmbusherFaction"] = EA_ForceAmbusherFaction
EA["EA_ClearHostileState"] = EA_ClearHostileState
EA["EA_HandlePersistentHostileRetryTimer"] = EA_HandlePersistentHostileRetryTimer
EA["EA_RearmPersistentHostileRetries"] = EA_RearmPersistentHostileRetries
EA["EA_MakeAmbushHostile"] = EA_MakeAmbushHostile
EA["EA_DebugBuildPersistentHostileRetrySnapshot"] = EA_BuildPersistentHostileRetrySnapshot
EA["EA_DebugLogPersistentHostileRetrySnapshot"] = EA_LogPersistentHostileRetrySnapshot
EA["EA_DebugDescribePersistentHostileRetries"] = EA_DebugDescribePersistentHostileRetries
EA["EA_DebugSchedulePersistentHostileRetry"] = EA_DebugSchedulePersistentHostileRetry
EA["EA_DebugClearPersistentHostileRetries"] = EA_DebugClearPersistentHostileRetries
