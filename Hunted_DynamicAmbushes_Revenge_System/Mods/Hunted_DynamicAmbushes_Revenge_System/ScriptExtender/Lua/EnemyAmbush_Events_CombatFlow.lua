EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local M = {}
function M.Build(deps)
    deps = deps or {}
    local EnemyAmbush = deps.EnemyAmbush or EA
    local EA = deps.EA or EnemyAmbush or {}
    local DebugPrint = deps.DebugPrint or function() end
    local EA_BindRuntimeCombatMaps = deps.EA_BindRuntimeCombatMaps or function() end
    local EA_GetRuntimeCombatMemberMap = deps.EA_GetRuntimeCombatMemberMap or function() return {} end
    local EA_GetRuntimeTurnChatterMap = deps.EA_GetRuntimeTurnChatterMap or function() return {} end
    local EA_GetRuntimeEscapeStateMap = deps.EA_GetRuntimeEscapeStateMap or function() return {} end
    local EA_MarkRuntimeStateDirty = deps.EA_MarkRuntimeStateDirty or function() end
    local EA_RUNTIME_COMBAT_TTL_MS = tonumber(deps.EA_RUNTIME_COMBAT_TTL_MS) or (45 * 60 * 1000)
    local EA_NormalizeUUID = deps.EA_NormalizeUUID or function(v) return v end
    local EA_FastNormalizeUUID = deps.EA_FastNormalizeUUID or function() return nil end
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local EA_Spawned = deps.EA_Spawned or function() return {} end
    local EA_GetPartyMembers = deps.EA_GetPartyMembers
    local EA_ClearHostileState = deps.EA_ClearHostileState or function() end
    local EA_Dirty = deps.EA_Dirty or function() end
    local EA_DESPAWN_FADE_SOUND = deps.EA_DESPAWN_FADE_SOUND or "VFX_Sound_Spell_Impact_Silent"
    local EA_DebugEnabled = deps.EA_DebugEnabled or function() return false end
    local UpdateMetric = deps.UpdateMetric or function() end
    local EA_P0Inc = deps.EA_P0Inc or (EA and EA["EA_P0Inc"]) or function() return 0 end
    local EA_P0BumpKeyedCount = deps.EA_P0BumpKeyedCount or (EA and EA["EA_P0BumpKeyedCount"]) or function() return 0 end
    local EA_P0PushNote = deps.EA_P0PushNote or (EA and EA["EA_P0PushNote"]) or function() return 0 end
    local PlayVFX_OnEntity = deps.PlayVFX_OnEntity or function() end
    local SafeApplyStatus = deps.SafeApplyStatus or function() return false end
    local EnemyData = deps.EnemyData or {}
    local EA_PlaySoundEvent = deps.EA_PlaySoundEvent or function() end
    local SafeOsiExec = deps.SafeOsiExec or function() return false end
    local EA_GetEscapeProfileByCreatureType = deps.EA_GetEscapeProfileByCreatureType or function() return { bonus = 0 } end
    local EA_RandIntSafe = deps.EA_RandIntSafe or (EA and EA["EA_RandIntSafe"])
    local EA_RandomInt = deps.EA_RandomInt or function(minVal, maxVal)
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
    local EA_DeleteStuckAmbusher = deps.EA_DeleteStuckAmbusher or function() end
    local EA_MakeAmbushHostile = deps.EA_MakeAmbushHostile or function() end
    local EA_RegisterDeferredSupportJoinWindow = deps.EA_RegisterDeferredSupportJoinWindow or (EA and EA["EA_RegisterDeferredSupportJoinWindow"]) or function() return nil end
    local EA_ShouldLogDeferredJoin = deps.EA_ShouldLogDeferredJoin or (EA and EA["EA_ShouldLogDeferredJoin"]) or function() return true end
    local EA_IsAnyPartyInCombat = deps.EA_IsAnyPartyInCombat or function() return false end
    local EA_TryApplyPartySurprise = deps.EA_TryApplyPartySurprise or function() end
    local EA_PlayCombatStartVoiceOrSfx = deps.EA_PlayCombatStartVoiceOrSfx or function() return false end
    local EA_HandleSurpriseRollResult = deps.EA_HandleSurpriseRollResult
    local EA_PrimeCharacterTemplateCache = deps.EA_PrimeCharacterTemplateCache or function() return nil end
    local EA_ReadSettingBool = deps.EA_ReadSettingBool or (EA and EA["EA_ReadSettingBool"])
    local EA_ReadSettingNumber = deps.EA_ReadSettingNumber or (EA and EA["EA_ReadSettingNumber"])
    local EA_GetPreset = deps.EA_GetPreset or (EA and EA["EA_GetPreset"]) or function() return nil end
    local EA_NULL_GUID = "NULL_00000000-0000-0000-0000-000000000000"
    local EA_ARRIVAL_INVISIBILITY_STATUS = "EA_ARRIVAL_INVISIBLE"
    local EA_ESCAPE_INVISIBILITY_STATUS = "EA_ESCAPE_INVISIBLE"
    local EA_ESCAPE_IMMINENT_STATUS = "EA_ESCAPE_IMMINENT"
    local EA_ESCAPE_FAIL_STAGGERED_STATUS = "EA_ESCAPE_STAGGERED"
    local EA_ESCAPE_INVISIBILITY_DURATION = 3
    local EA_ESCAPE_DEPART_PRE_DELAY_MS = 400
    local EA_ESCAPE_STAGE_ENDTURN_DELAY_MS = 500
    local EA_ESCAPE_IMMINENT_DURATION = 30
    local EA_ESCAPE_FAIL_STAGGERED_DURATION = 6
    local EA_ESCAPE_PENDING_RESOLVE_TURNS = 1
    local EA_ESCAPE_FLEE_RANGE_DEFAULT = 12.0
    if type(EnemyData) ~= "table" then
        EnemyData = {}
    end
    EnemyData.DEFAULT_DESPAWN_VFX = EnemyData.DEFAULT_DESPAWN_VFX
        or "VFX_Spells_Cast_Intent_Utility_TargetJump_MistyStep_BodyFX_01"
    local Runtime = {}
    local EA_PruneRuntimeCombatStateRef = nil
    local EA_EnsureCombatEscapeStateRef = function() return nil, nil end
    local EA_CleanupCombatEscapeStateIfIdleRef = function() return nil end
    local EA_ResetSoftlockIdleCounterRef = function() return false end
    local EA_GetCombatKeyForTurnCharacterRef = function() return "" end
    local EA_FindCombatEscapeStateRef = function() return nil, nil end
    local EA_FindTurnChatterStateRef = function() return nil, nil end
    local EA_TryAmbusherEscapeRef = function() return false end
    local EA_TrySoftlockDeleteOnTurnRef = function() return false end
    local EA_CancelPendingEscapeRef = function() return false end
    local EA_FindCombatKeyForCharacter = nil
    local combatEventListenersRegistered = false
    function Runtime.RegisterCombatEventListeners()
    if combatEventListenersRegistered then
        EA_P0Inc("listenerRegGuard.RegisterCombatEventListeners")
        return false
    end
    EA_P0Inc("listenerReg.RegisterCombatEventListeners")
    if not (Ext and Ext.Osiris and Ext.Osiris.RegisterListener) then
        return
    end
    combatEventListenersRegistered = true
    local EA_EnterCombatRetryByPair = {}
    local EA_EnterCombatTeleportUsedByPair = {}
    local EA_EnterCombatFirstFailAtByPair = {}
    local EA_SurpriseAppliedByCombat = {}
    EA_BindRuntimeCombatMaps()
    EnemyAmbush._CombatKeyByAmbusher = EnemyAmbush._CombatKeyByAmbusher or {}
    EnemyAmbush._CombatKeyByMember = EnemyAmbush._CombatKeyByMember or EA_GetRuntimeCombatMemberMap()
    local EA_ENTER_COMBAT_ENABLE_TELEPORT_FALLBACK = true
    local EA_ENTER_COMBAT_MOMENTUM_RETRY_FROM = 4
    local EA_ENTER_COMBAT_MOMENTUM_DURATION = 12
    local EA_ENTER_COMBAT_TELEPORT_MIN_DELAY_MS = 9000
    local EA_ENTER_COMBAT_TELEPORT_MIN_DISTANCE = 16
    local EA_ESCAPE_RETRY_COOLDOWN_TURNS = 1
    local EA_SOFTLOCK_IDLE_TURN_LIMIT = 3
    local EA_SOFTLOCK_DELETE_DELAY_MS = 120
    local function EA_NowMonotonicMs()
        if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
            return tonumber(Ext.Utils.MonotonicTime()) or 0
        end
        return 0
    end
    local function EA_NormalizeCombatKey(combatKey)
        if combatKey == nil then
            return ""
        end
        local s = tostring(combatKey)
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        if s == "" then
            return ""
        end
        return string.lower(s)
    end
    local function EA_CombatGuidOnly(combatKey)
        local s = EA_NormalizeCombatKey(combatKey)
        if s == "" then
            return ""
        end
        local guid = s:match("(%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x)")
        return guid or ""
    end
    local function EA_FindTurnChatterState(combatKey)
        local all = EA_GetRuntimeTurnChatterMap()
        if type(all) ~= "table" then
            return nil, nil
        end
        local normalized = EA_NormalizeCombatKey(combatKey)
        if normalized ~= "" and type(all[normalized]) == "table" then
            return normalized, all[normalized]
        end
        local guid = EA_CombatGuidOnly(normalized)
        if guid ~= "" then
            for k, v in pairs(all) do
                if type(v) == "table" and EA_CombatGuidOnly(k) == guid then
                    return k, v
                end
            end
        end
        return nil, nil
    end
    local function EA_FindCombatEscapeState(combatKey)
        local all = EA_GetRuntimeEscapeStateMap()
        if type(all) ~= "table" then
            return nil, nil
        end
        local normalized = EA_NormalizeCombatKey(combatKey)
        if normalized ~= "" and type(all[normalized]) == "table" then
            return normalized, all[normalized]
        end
        local guid = EA_CombatGuidOnly(normalized)
        if guid ~= "" then
            for k, v in pairs(all) do
                if type(v) == "table" and EA_CombatGuidOnly(k) == guid then
                    return k, v
                end
            end
        end
        return nil, nil
    end
    local function EA_ClampEscapeSettingNumber(value, fallback, minValue, maxValue, integer)
        local n = tonumber(value)
        if n == nil then
            n = tonumber(fallback) or 0
        end
        if minValue ~= nil then
            n = math.max(tonumber(minValue) or n, n)
        end
        if maxValue ~= nil then
            n = math.min(tonumber(maxValue) or n, n)
        end
        if integer == true then
            n = math.floor(n + 0.5)
        end
        return n
    end
    local function EA_GetPresetEscapeNumber(field, fallback, minValue, maxValue, integer)
        local value = nil
        local preset = type(EA_GetPreset) == "function" and EA_GetPreset() or nil
        if type(preset) == "table" then
            value = preset[field]
        end
        if EA_DebugEnabled() and type(EA_ReadSettingNumber) == "function" then
            local settingIdByField = {
                escapeStartTurn = "MCM_EscapeStartTurn",
                escapeDC = "MCM_EscapeDC",
                escapeHPThreshold = "MCM_EscapeHPThreshold",
                escapeMaxPerCombat = "MCM_EscapeMaxPerCombat",
            }
            local settingId = settingIdByField[field]
            if settingId then
                value = EA_ReadSettingNumber(settingId, value or fallback)
            end
        end
        return EA_ClampEscapeSettingNumber(value, fallback, minValue, maxValue, integer)
    end
    local function EA_EnsureCombatEscapeState(combatKey)
        local normalized = EA_NormalizeCombatKey(combatKey)
        if normalized == "" then
            return nil, nil
        end
        local all = EA_GetRuntimeEscapeStateMap()
        local state = all[normalized]
        local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
        if type(state) ~= "table" then
            state = {
                turnCount = 0,
                escapedCount = 0,
                nextAttemptTurnByEnemy = {},
                pendingByEnemy = {},
                createdAt = now,
                updatedAt = now
            }
            all[normalized] = state
            EA_MarkRuntimeStateDirty(true)
        else
            if type(state.nextAttemptTurnByEnemy) ~= "table" then
                state.nextAttemptTurnByEnemy = {}
            end
            if type(state.pendingByEnemy) ~= "table" then
                state.pendingByEnemy = {}
            end
            state.turnCount = tonumber(state.turnCount) or 0
            state.escapedCount = tonumber(state.escapedCount) or 0
            state.updatedAt = now
        end
        return normalized, state
    end
    local function EA_GetCombatKeyForTurnCharacter(turnCharacter)
        local id = EA_FastNormalizeUUID(turnCharacter) or EA_NormalizeUUID(turnCharacter) or turnCharacter
        local byMember = EnemyAmbush._CombatKeyByMember
        if type(byMember) == "table" then
            local knownMember = byMember[id] or byMember[turnCharacter]
            if type(knownMember) == "string" and knownMember ~= "" then
                UpdateMetric("turnStartedCacheHit")
                return knownMember
            end
        end
        local byAmbusher = EnemyAmbush._CombatKeyByAmbusher
        if type(byAmbusher) == "table" then
            local known = byAmbusher[id] or byAmbusher[turnCharacter]
            if type(known) == "string" and known ~= "" then
                if type(byMember) == "table" then
                    byMember[id] = known
                    byMember[turnCharacter] = known
                end
                UpdateMetric("turnStartedCacheHit")
                return known
            end
        end
        local combatKey = ""
        if Osi.DB_Is_InCombat and Osi.DB_Is_InCombat.Get then
            local okRows, rows = pcall(function()
                return Osi.DB_Is_InCombat:Get(turnCharacter, nil)
            end)
            if okRows and type(rows) == "table" and rows[1] and rows[1][2] then
                combatKey = tostring(rows[1][2] or "")
            end
        end
        if combatKey ~= "" then
            UpdateMetric("turnStartedDbFallback")
            if type(byMember) == "table" then
                byMember[id] = combatKey
                byMember[turnCharacter] = combatKey
            end
        end
        if combatKey == "" and Osi.GetCombatGroupID then
            local okGroup, groupId = pcall(Osi.GetCombatGroupID, turnCharacter)
            if okGroup and groupId then
                combatKey = tostring(groupId)
                if type(byMember) == "table" then
                    byMember[id] = combatKey
                    byMember[turnCharacter] = combatKey
                end
            end
        end
        return combatKey
    end
    local function EA_GetSpawnedRegistry()
        local spawned = EA_Spawned()
        if type(spawned) ~= "table" and type(spawned) ~= "userdata" then
            return nil
        end
        return spawned
    end
    local function EA_CountTrackedAmbushersInCombat(combatGuid)
        if not (Osi.DB_Is_InCombat and Osi.DB_Is_InCombat.Get) then
            return 0
        end
        local spawned = EA_GetSpawnedRegistry()
        if not spawned then
            return 0
        end
        local okRows, rows = pcall(function()
            return Osi.DB_Is_InCombat:Get(nil, combatGuid)
        end)
        if not okRows or type(rows) ~= "table" then
            return 0
        end
        local count = 0
        for _, row in ipairs(rows) do
            local member = row[1]
            if member and member ~= "" then
                local id = EA_FastNormalizeUUID(member) or EA_NormalizeUUID(member) or member
                local data = spawned[id] or spawned[member]
                if data and Osi.IsPlayer and Osi.IsPlayer(member) ~= 1 then
                    if (not Osi.IsDead) or Osi.IsDead(member) ~= 1 then
                        count = count + 1
                    end
                end
            end
        end
        return count
    end
    local function EA_GetAlivePartyMembersForEnemy(enemy, anchorPlayer)
        local members = {}
        local seen = {}
        local function Add(member)
            if type(member) ~= "string" or member == "" or seen[member] then
                return
            end
            if Osi.ObjectExists and Osi.ObjectExists(member) ~= 1 then
                return
            end
            if Osi.IsDead and Osi.IsDead(member) == 1 then
                return
            end
            if Osi.IsPlayer and Osi.IsPlayer(member) ~= 1 then
                return
            end
            seen[member] = true
            members[#members + 1] = member
        end
        if type(EA_GetPartyMembers) == "function" and anchorPlayer and anchorPlayer ~= "" then
            local okParty, party = pcall(EA_GetPartyMembers, anchorPlayer)
            if okParty and type(party) == "table" then
                for _, member in ipairs(party) do
                    Add(member)
                end
            end
        end
        Add(anchorPlayer)
        if #members == 0 and enemy and enemy ~= "" and Osi.GetClosestAlivePlayer then
            Add(Osi.GetClosestAlivePlayer(enemy))
        end
        if #members == 0 and Osi.GetHostCharacter then
            Add(Osi.GetHostCharacter())
        end
        return members
    end
    local function EA_GetDepartureTargetObject(character, anchorPlayer)
        local target = nil
        if type(anchorPlayer) == "string" and anchorPlayer ~= "" then
            target = anchorPlayer
        end
        if (not target or target == "") and character and character ~= "" and Osi.GetClosestAlivePlayer then
            local okPlayer, player = pcall(Osi.GetClosestAlivePlayer, character)
            if okPlayer and type(player) == "string" and player ~= "" then
                target = player
            end
        end
        if type(target) ~= "string" or target == "" then
            target = EA_NULL_GUID
        end
        return target
    end
    local function EA_RequestDeleteTemporaryCharacter(character)
        if type(character) ~= "string" or character == "" then
            return false
        end
        if Osi.ObjectExists and Osi.ObjectExists(character) ~= 1 then
            return true
        end
        if Osi.RequestDeleteTemporary then
            local okDelete = pcall(Osi.RequestDeleteTemporary, character)
            if okDelete then
                return true
            end
        end
        return false
    end
    local function EA_HasActiveStatusCompat(entity, status)
        if not (entity and entity ~= "" and status and status ~= "") then
            return false
        end
        if not (Osi and Osi.HasActiveStatus) then
            return false
        end
        local ok, result = pcall(Osi.HasActiveStatus, entity, status)
        return ok and tonumber(result) == 1
    end
    local function EA_RemoveArrivalInvisibility(character, reason)
        if not (character and character ~= "") then
            return false
        end
        if Osi.ObjectExists and Osi.ObjectExists(character) ~= 1 then
            return false
        end
        if not EA_HasActiveStatusCompat(character, EA_ARRIVAL_INVISIBILITY_STATUS) then
            return false
        end
        local ok = (Osi and Osi.RemoveStatus) and pcall(Osi.RemoveStatus, character, EA_ARRIVAL_INVISIBILITY_STATUS) or false
        if not ok then
            return false
        end
        local id = EA_NormalizeUUID(character) or character
        local spawned = EA_GetSpawnedRegistry()
        local spawnedData = spawned and (spawned[id] or spawned[character]) or nil
        if type(spawnedData) == "table" or type(spawnedData) == "userdata" then
            spawnedData.arrivalInvisible = nil
        end
        UpdateMetric("arrivalInvisibilityRemoved")
        if EA_DebugEnabled() then
            DebugPrint("[ArrivalInvisibility] removed:", tostring(character), "reason=", tostring(reason or "unknown"))
        end
        return true
    end
    local function EA_ApplyEscapeInvisibility(character, durationSeconds)
        local duration = tonumber(durationSeconds) or EA_ESCAPE_INVISIBILITY_DURATION
        if duration <= 0 then
            return false
        end
        local applied = (SafeApplyStatus(character, EA_ESCAPE_INVISIBILITY_STATUS, duration, 1) == true)
        if applied then
            UpdateMetric("escapeInvisibilityApplied")
        else
            UpdateMetric("escapeInvisibilityFailed")
        end
        return applied
    end
    local function EA_ApplyEscapeImminentStatus(character, durationSeconds)
        local duration = tonumber(durationSeconds) or EA_ESCAPE_IMMINENT_DURATION
        if duration <= 0 then
            duration = EA_ESCAPE_IMMINENT_DURATION
        end
        local applied = (SafeApplyStatus(character, EA_ESCAPE_IMMINENT_STATUS, duration, 1) == true)
        if applied then
            UpdateMetric("escapeImminentStatusApplied")
        else
            UpdateMetric("escapeImminentStatusFailed")
        end
        return applied
    end
    local function EA_ApplyEscapeFailStaggeredStatus(character, durationSeconds)
        local duration = tonumber(durationSeconds) or EA_ESCAPE_FAIL_STAGGERED_DURATION
        if duration <= 0 then
            duration = EA_ESCAPE_FAIL_STAGGERED_DURATION
        end
        local applied = (SafeApplyStatus(character, EA_ESCAPE_FAIL_STAGGERED_STATUS, duration, 1) == true)
        if applied then
            UpdateMetric("escapeFailStaggeredApplied")
        else
            UpdateMetric("escapeFailStaggeredFailed")
        end
        return applied
    end
    local function EA_RemoveEscapeImminentStatus(character, reason)
        if type(character) ~= "string" or character == "" then
            return false
        end
        if Osi.ObjectExists and Osi.ObjectExists(character) ~= 1 then
            return false
        end
        if not EA_HasActiveStatusCompat(character, EA_ESCAPE_IMMINENT_STATUS) then
            return false
        end
        local ok = (Osi and Osi.RemoveStatus) and pcall(Osi.RemoveStatus, character, EA_ESCAPE_IMMINENT_STATUS) or false
        if ok then
            UpdateMetric("escapeImminentStatusRemoved")
            if EA_DebugEnabled() then
                DebugPrint("[EscapeImminent] removed:", tostring(character), "reason=", tostring(reason or "unknown"))
            end
            return true
        end
        return false
    end
    local function EA_ShowEscapeDebugText(character, text)
        if type(character) ~= "string" or character == "" then
            return false
        end
        if type(text) ~= "string" or text == "" then
            return false
        end
        if not (Osi and Osi.DebugText) then
            return false
        end
        local ok = pcall(Osi.DebugText, character, text)
        if ok then
            UpdateMetric("escapeDebugTextShown")
            return true
        end
        return false
    end
    local function EA_DisengageEscapingCharacter(character)
        if type(character) ~= "string" or character == "" then
            return false
        end
        if Osi.ObjectExists and Osi.ObjectExists(character) ~= 1 then
            return false
        end

        if Osi.SetCanJoinCombat then
            pcall(Osi.SetCanJoinCombat, character, 0)
        elseif Osi.LeaveCombat then
            pcall(Osi.LeaveCombat, character)
        end
        if Osi.SetCanFight then
            pcall(Osi.SetCanFight, character, 0)
        end
        if Osi.EndTurn then
            pcall(Osi.EndTurn, character)
        end
        return true
    end
    local function EA_GetEscapeAnchorObject(character, spawnedData)
        local anchor = nil
        if type(spawnedData) == "table" and type(spawnedData.anchorPlayer) == "string" and spawnedData.anchorPlayer ~= "" then
            anchor = spawnedData.anchorPlayer
        end
        if (not anchor or anchor == "") and character and character ~= "" and Osi.GetClosestAlivePlayer then
            local okPlayer, player = pcall(Osi.GetClosestAlivePlayer, character)
            if okPlayer and type(player) == "string" and player ~= "" then
                anchor = player
            end
        end
        if (not anchor or anchor == "") and Osi.GetHostCharacter then
            local okHost, host = pcall(Osi.GetHostCharacter)
            if okHost and type(host) == "string" and host ~= "" then
                anchor = host
            end
        end
        return anchor
    end
    local function EA_IssueFleeFromObject(character, fleeFrom, fleeRange)
        if type(character) ~= "string" or character == "" or type(fleeFrom) ~= "string" or fleeFrom == "" then
            return false
        end
        if Osi.ObjectExists and (Osi.ObjectExists(character) ~= 1 or Osi.ObjectExists(fleeFrom) ~= 1) then
            return false
        end
        if not (Osi and Osi.FleeFromObject) then
            return false
        end
        local range = tonumber(fleeRange) or EA_ESCAPE_FLEE_RANGE_DEFAULT
        if range <= 0 then
            range = EA_ESCAPE_FLEE_RANGE_DEFAULT
        end
        local ok = pcall(Osi.FleeFromObject, character, fleeFrom, range)
        if ok then
            UpdateMetric("escapeFleeIssued")
        else
            UpdateMetric("escapeFleeIssueFailed")
        end
        return ok == true
    end
    local function EA_ScheduleEscapeStageEndTurn(character, delayMs)
        if type(character) ~= "string" or character == "" then
            return false
        end
        local function EndTurnNow()
            if Osi.ObjectExists and Osi.ObjectExists(character) ~= 1 then
                return
            end
            if Osi.IsInCombat and Osi.IsInCombat(character) ~= 1 then
                return
            end
            if Osi.EndTurn then
                pcall(Osi.EndTurn, character)
            end
        end

        local delay = tonumber(delayMs) or EA_ESCAPE_STAGE_ENDTURN_DELAY_MS
        if delay <= 0 then
            EndTurnNow()
            return true
        end
        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(delay, EndTurnNow)
            return true
        end
        EndTurnNow()
        return true
    end
    local function EA_DepartCharacterOutOfCombat(character, anchorPlayer, deleteDelayMs)
        if type(character) ~= "string" or character == "" then
            return false, "missing_character"
        end
        if Osi.ObjectExists and Osi.ObjectExists(character) ~= 1 then
            return false, "missing_object"
        end

        EA_DisengageEscapingCharacter(character)

        local usedDisappear = false
        if Osi.DisappearOutOfSightTo then
            local targetObject = EA_GetDepartureTargetObject(character, anchorPlayer)
            usedDisappear = (pcall(Osi.DisappearOutOfSightTo, character, targetObject, "Sprint", 1, "") == true)
        end

        local function FinalizeDelete()
            if Osi.ObjectExists and Osi.ObjectExists(character) ~= 1 then
                return
            end
            EA_RequestDeleteTemporaryCharacter(character)
            if Osi.ObjectExists and Osi.ObjectExists(character) == 1 and Osi.SetOnStage then
                pcall(Osi.SetOnStage, character, 0)
            end
        end

        local delay = tonumber(deleteDelayMs) or (usedDisappear and 1200 or 200)
        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(delay, FinalizeDelete)
        else
            FinalizeDelete()
        end

        return true, (usedDisappear and "disappear_out_of_sight" or "delete_temporary")
    end
    local function EA_HasLineOfSightToAnyPartyMember(enemy, anchorPlayer)
        if not (enemy and enemy ~= "" and Osi.HasLineOfSight) then
            return false
        end
        local members = EA_GetAlivePartyMembersForEnemy(enemy, anchorPlayer)
        for _, member in ipairs(members) do
            local okLos, hasLos = pcall(Osi.HasLineOfSight, enemy, member)
            if okLos and tonumber(hasLos) == 1 then
                return true
            end
        end
        return false
    end
    local function EA_ResetSoftlockIdleCounter(character, reason, damageAmount)
        if type(character) ~= "string" or character == "" then
            return false
        end
        local id = EA_FastNormalizeUUID(character) or EA_NormalizeUUID(character) or character
        local spawned = EA_GetSpawnedRegistry()
        if not spawned then
            return false
        end
        local spawnedData = spawned[id] or spawned[character]
        if type(spawnedData) ~= "table" then
            return false
        end
        spawnedData._eaSoftlockIdleTurns = 0
        spawnedData._eaSoftlockLastDamageAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
        spawnedData._eaSoftlockLastDamageAmount = tonumber(damageAmount) or 0
        if reason then
            spawnedData._eaSoftlockLastResetReason = tostring(reason)
        end
        return true
    end
    local function EA_FinalizeSoftlockDelete(doomed, norm)
        local spawned = EA_GetSpawnedRegistry()
        if spawned then
            spawned[doomed] = nil
            if norm then
                spawned[norm] = nil
            end
        end
        if type(EnemyAmbush._CombatKeyByAmbusher) == "table" then
            EnemyAmbush._CombatKeyByAmbusher[doomed] = nil
            if norm then
                EnemyAmbush._CombatKeyByAmbusher[norm] = nil
            end
        end
        if type(EnemyAmbush._CombatKeyByMember) == "table" then
            EnemyAmbush._CombatKeyByMember[doomed] = nil
            if norm then
                EnemyAmbush._CombatKeyByMember[norm] = nil
            end
        end
        EA_ClearHostileState(doomed)
        if norm then
            EA_ClearHostileState(norm)
        end
        if spawned then
            EA_Dirty()
        end
    end
    local function EA_ScheduleSoftlockDelete(turnCharacter, combatKey, spawnedData)
        if not turnCharacter or turnCharacter == "" then
            return false
        end
        if Osi.ObjectExists and Osi.ObjectExists(turnCharacter) ~= 1 then
            return false
        end
        local norm = EA_FastNormalizeUUID(turnCharacter) or EA_NormalizeUUID(turnCharacter) or turnCharacter
        local trackedCount = EA_CountTrackedAmbushersInCombat(combatKey)
        local isLastTracked = trackedCount <= 1
        spawnedData._eaSoftlockDeletePending = true
        spawnedData._eaSoftlockDeleteQueuedAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0

        PlayVFX_OnEntity(turnCharacter, EnemyData.DEFAULT_DESPAWN_VFX)
        EA_PlaySoundEvent(EA_DESPAWN_FADE_SOUND, turnCharacter)

        if EA_DebugEnabled() then
            DebugPrint(
                "Softlock guard deleting stuck ambusher:",
                tostring(turnCharacter),
                "combat=",
                tostring(combatKey),
                "lastTracked=",
                tostring(isLastTracked),
                "idleTurns=",
                tostring(tonumber(spawnedData._eaSoftlockIdleTurns) or 0)
            )
        end

        local function DeleteNow()
            if Osi.ObjectExists and Osi.ObjectExists(turnCharacter) == 1 then
                EA_FinalizeSoftlockDelete(turnCharacter, norm)
                EA_DepartCharacterOutOfCombat(turnCharacter, spawnedData.anchorPlayer, EA_SOFTLOCK_DELETE_DELAY_MS)
            else
                EA_FinalizeSoftlockDelete(turnCharacter, norm)
            end
        end

        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(80, DeleteNow)
        else
            EA_FinalizeSoftlockDelete(turnCharacter, norm)
            EA_DepartCharacterOutOfCombat(turnCharacter, spawnedData.anchorPlayer, EA_SOFTLOCK_DELETE_DELAY_MS)
        end
        UpdateMetric("softlockDeleted")
        return true
    end

    local function EA_TrySoftlockDeleteOnTurn(turnCharacter, combatKey, spawnedData)
        if type(spawnedData) ~= "table" then
            return false
        end
        if spawnedData._eaDefeatHandled == true or spawnedData.escapeScheduled == true or spawnedData._eaSoftlockDeletePending == true then
            return false
        end
        if Osi.IsInCombat and Osi.IsInCombat(turnCharacter) ~= 1 then
            return false
        end

        local idleTurns = (tonumber(spawnedData._eaSoftlockIdleTurns) or 0) + 1
        spawnedData._eaSoftlockIdleTurns = idleTurns
        spawnedData._eaSoftlockCombatKey = combatKey

        if idleTurns < EA_SOFTLOCK_IDLE_TURN_LIMIT then
            return false
        end

        if EA_HasLineOfSightToAnyPartyMember(turnCharacter, spawnedData.anchorPlayer) then
            return false
        end

        return EA_ScheduleSoftlockDelete(turnCharacter, combatKey, spawnedData)
    end

    local function EA_CleanupCombatEscapeStateIfIdle(combatGuid)
        local stateKey, _ = EA_FindCombatEscapeState(combatGuid)
        if not stateKey then
            return
        end

        if EA_CountTrackedAmbushersInCombat(combatGuid) <= 0 then
            local escapeMap = EA_GetRuntimeEscapeStateMap()
            local chatterMap = EA_GetRuntimeTurnChatterMap()
            escapeMap[stateKey] = nil
            chatterMap[stateKey] = nil
            EA_MarkRuntimeStateDirty(true)
        end
    end

    local function EA_PruneRuntimeCombatState(reason)
        local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
        local escapeMap = EA_GetRuntimeEscapeStateMap()
        local chatterMap = EA_GetRuntimeTurnChatterMap()
        local removed = 0

        for combatKey, state in pairs(escapeMap) do
            if type(state) == "table" and type(state.pendingByEnemy) == "table" then
                for enemyId, pending in pairs(state.pendingByEnemy) do
                    local alive = (type(enemyId) == "string" and enemyId ~= "" and Osi.ObjectExists and Osi.ObjectExists(enemyId) == 1)
                    if not alive or type(pending) ~= "table" then
                        state.pendingByEnemy[enemyId] = nil
                        removed = removed + 1
                    end
                end
            end
            local updatedAt = tonumber(type(state) == "table" and state.updatedAt) or 0
            local stale = (now > 0 and updatedAt > 0 and (now - updatedAt) > EA_RUNTIME_COMBAT_TTL_MS)
            if stale or EA_CountTrackedAmbushersInCombat(combatKey) <= 0 then
                escapeMap[combatKey] = nil
                chatterMap[combatKey] = nil
                removed = removed + 1
            end
        end

        for combatKey, state in pairs(chatterMap) do
            local updatedAt = tonumber(type(state) == "table" and state.updatedAt) or 0
            local stale = (now > 0 and updatedAt > 0 and (now - updatedAt) > EA_RUNTIME_COMBAT_TTL_MS)
            if stale or EA_CountTrackedAmbushersInCombat(combatKey) <= 0 then
                chatterMap[combatKey] = nil
                escapeMap[combatKey] = nil
                removed = removed + 1
            end
        end

        if type(EnemyAmbush._CombatKeyByAmbusher) == "table" then
            for k, combatKey in pairs(EnemyAmbush._CombatKeyByAmbusher) do
                local okExists = (type(k) == "string" and k ~= "" and Osi.ObjectExists and Osi.ObjectExists(k) == 1)
                if not okExists or type(combatKey) ~= "string" or combatKey == "" then
                    EnemyAmbush._CombatKeyByAmbusher[k] = nil
                    removed = removed + 1
                end
            end
        end
        if type(EnemyAmbush._CombatKeyByMember) == "table" then
            for k, combatKey in pairs(EnemyAmbush._CombatKeyByMember) do
                local okExists = (type(k) == "string" and k ~= "" and Osi.ObjectExists and Osi.ObjectExists(k) == 1)
                if not okExists or type(combatKey) ~= "string" or combatKey == "" then
                    EnemyAmbush._CombatKeyByMember[k] = nil
                    removed = removed + 1
                end
            end
        end

        if removed > 0 then
            if EA_DebugEnabled() then
                DebugPrint(string.format("[RuntimeState] pruned=%d reason=%s", removed, tostring(reason or "unknown")))
            end
            EA_MarkRuntimeStateDirty(true)
        end
        return removed
    end
    EA_PruneRuntimeCombatStateRef = EA_PruneRuntimeCombatState

    local function EA_CancelPendingEscape(turnCharacter, combatKey, reason, damageAmount, applyRetryCooldown)
        if type(turnCharacter) ~= "string" or turnCharacter == "" then
            return false
        end
        local resolvedCombatKey = EA_NormalizeCombatKey(combatKey)
        if resolvedCombatKey == "" then
            local findCombatKeyForCharacter = EA_FindCombatKeyForCharacter
            if type(findCombatKeyForCharacter) == "function" then
                resolvedCombatKey = findCombatKeyForCharacter(turnCharacter)
            end
        end
        if resolvedCombatKey == "" then
            return false
        end
        local stateKey, state = EA_FindCombatEscapeState(resolvedCombatKey)
        if not (stateKey and type(state) == "table") then
            return false
        end
        state.pendingByEnemy = state.pendingByEnemy or {}
        local id = EA_FastNormalizeUUID(turnCharacter) or EA_NormalizeUUID(turnCharacter) or turnCharacter
        local pending = state.pendingByEnemy[id]
        if type(pending) ~= "table" then
            return false
        end
        state.pendingByEnemy[id] = nil
        if applyRetryCooldown ~= false then
            state.nextAttemptTurnByEnemy = state.nextAttemptTurnByEnemy or {}
            state.nextAttemptTurnByEnemy[id] = (tonumber(state.turnCount) or 0) + EA_ESCAPE_RETRY_COOLDOWN_TURNS
        end
        state.updatedAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
        local spawned = EA_GetSpawnedRegistry()
        local spawnedData = spawned and (spawned[id] or spawned[turnCharacter]) or nil
        if type(spawnedData) == "table" then
            spawnedData.escapePending = nil
            spawnedData.escapePendingAt = nil
            spawnedData.escapePendingCombatKey = nil
        end
        EA_RemoveEscapeImminentStatus(turnCharacter, reason or "canceled")
        EA_Dirty()
        EA_MarkRuntimeStateDirty()
        if EA_DebugEnabled() then
            DebugPrint(
                "[Escape] canceled:",
                tostring(turnCharacter),
                "reason=",
                tostring(reason or "unknown"),
                "damage=",
                tostring(tonumber(damageAmount) or 0)
            )
        end
        return true
    end
    local function EA_ResolveAmbusherEscape(turnCharacter, combatKey, state, spawnedData, profile, meta)
        local id = EA_FastNormalizeUUID(turnCharacter) or EA_NormalizeUUID(turnCharacter) or turnCharacter
        state.pendingByEnemy = state.pendingByEnemy or {}
        state.pendingByEnemy[id] = nil
        EA_RemoveEscapeImminentStatus(turnCharacter, "escape_resolved")

        local escapeVisualApplied = false
        EA_RemoveArrivalInvisibility(turnCharacter, "escape_success")
        if profile and profile.statusId and profile.statusId ~= "" then
            local statusDuration = tonumber(profile.statusDuration) or 2
            if SafeApplyStatus(turnCharacter, tostring(profile.statusId), statusDuration, 1) then
                escapeVisualApplied = true
                UpdateMetric("escapeCueStatusApplied")
            else
                UpdateMetric("escapeCueStatusFailed")
            end
        end
        if not escapeVisualApplied then
            if profile and profile.vfx then
                PlayVFX_OnEntity(turnCharacter, tostring(profile.vfx))
            else
                PlayVFX_OnEntity(turnCharacter, EnemyData.DEFAULT_DESPAWN_VFX)
            end
        end
        if profile and profile.sfx then
            EA_PlaySoundEvent(tostring(profile.sfx), turnCharacter)
        else
            EA_PlaySoundEvent(EA_DESPAWN_FADE_SOUND, turnCharacter)
        end

        EA_ClearHostileState(turnCharacter)
        if id then
            EA_ClearHostileState(id)
        end

        if type(spawnedData) == "table" then
            spawnedData.escapePending = nil
            spawnedData.escapePendingAt = nil
            spawnedData.escapePendingCombatKey = nil
            spawnedData.escapeScheduled = true
            spawnedData.escapeScheduledAt = EA_NowMs and EA_NowMs() or 0
        end

        state.escapedCount = (tonumber(state.escapedCount) or 0) + 1
        state.nextAttemptTurnByEnemy = state.nextAttemptTurnByEnemy or {}
        state.nextAttemptTurnByEnemy[id] = nil
        state.updatedAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
        EA_Dirty()

        if EA_CountTrackedAmbushersInCombat(combatKey) <= 0 then
            EA_GetRuntimeEscapeStateMap()[combatKey] = nil
            EA_GetRuntimeTurnChatterMap()[combatKey] = nil
            EA_MarkRuntimeStateDirty(true)
        end

        EA_IssueFleeFromObject(turnCharacter, type(meta) == "table" and meta.fleeFrom or nil, type(meta) == "table" and meta.fleeRange or nil)
        EA_FinalizeEscapedEntity(turnCharacter)
        EA_DisengageEscapingCharacter(turnCharacter)

        local departureMode = "delayed_disappear_out_of_sight"
        local function EA_BeginEscapeDeparture()
            if Osi.ObjectExists and Osi.ObjectExists(turnCharacter) ~= 1 then
                return
            end
            EA_ApplyEscapeInvisibility(turnCharacter, EA_ESCAPE_INVISIBILITY_DURATION)
            local _, actualDepartureMode = EA_DepartCharacterOutOfCombat(turnCharacter, spawnedData.anchorPlayer, 1200)
            if actualDepartureMode then
                departureMode = actualDepartureMode
            end
        end

        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(EA_ESCAPE_DEPART_PRE_DELAY_MS, EA_BeginEscapeDeparture)
        else
            EA_BeginEscapeDeparture()
        end

        if EA_DebugEnabled() then
            DebugPrint(
                "[Escape] success:",
                tostring(turnCharacter),
                "roll=",
                tostring(type(meta) == "table" and meta.totalRoll or "n/a"),
                "dc=",
                tostring(type(meta) == "table" and meta.dc or "n/a"),
                "d20=",
                tostring(type(meta) == "table" and meta.d20 or "n/a"),
                "bonus=",
                tostring(type(meta) == "table" and meta.totalBonus or "n/a"),
                "tier=",
                tostring(type(meta) == "table" and meta.tier or "?"),
                "type=",
                tostring((type(meta) == "table" and meta.creatureType) or (spawnedData and spawnedData.creatureType) or "?"),
                "hp%=",
                tostring(type(meta) == "table" and meta.hpPctRounded or "n/a"),
                "escapedCount=",
                tostring(state.escapedCount),
                "mode=",
                tostring(type(meta) == "table" and meta.profileMode or "default"),
                "departure=",
                tostring(departureMode or "unknown")
            )
        end
        return true
    end
    local function EA_ResolvePendingEscapeAfterLeftCombat(turnCharacter, combatKey, reason)
        if type(turnCharacter) ~= "string" or turnCharacter == "" then
            return false
        end
        local resolvedCombatKey = EA_NormalizeCombatKey(combatKey)
        if resolvedCombatKey == "" then
            local findCombatKeyForCharacter = EA_FindCombatKeyForCharacter
            if type(findCombatKeyForCharacter) == "function" then
                resolvedCombatKey = findCombatKeyForCharacter(turnCharacter)
            end
        end
        if resolvedCombatKey == "" then
            return false
        end
        local stateKey, state = EA_FindCombatEscapeState(resolvedCombatKey)
        if not (stateKey and type(state) == "table") then
            return false
        end
        state.pendingByEnemy = state.pendingByEnemy or {}
        local id = EA_FastNormalizeUUID(turnCharacter) or EA_NormalizeUUID(turnCharacter) or turnCharacter
        local pending = state.pendingByEnemy[id]
        if type(pending) ~= "table" then
            return false
        end

        local spawned = EA_GetSpawnedRegistry()
        local spawnedData = spawned and (spawned[id] or spawned[turnCharacter]) or nil
        if type(spawnedData) ~= "table" then
            return false
        end

        local pendingTier = string.upper(tostring(pending.tier or spawnedData.tier or "COMMON"))
        local profile = EA_GetEscapeProfileByCreatureType(spawnedData.creatureType, pendingTier, {
            combatKey = resolvedCombatKey,
            turnCharacter = turnCharacter,
        })

        if EA_DebugEnabled() then
            DebugPrint(
                "[Escape] completing staged escape after LeftCombat:",
                tostring(turnCharacter),
                "combat=",
                tostring(resolvedCombatKey),
                "reason=",
                tostring(reason or "left_combat")
            )
        end

        return EA_ResolveAmbusherEscape(turnCharacter, resolvedCombatKey, state, spawnedData, profile, pending)
    end

    local function EA_TryAmbusherEscape(turnCharacter, combatKey, state)
        local escapeEnabled = true
        if type(EA_ReadSettingBool) == "function" then
            escapeEnabled = EA_ReadSettingBool("MCM_EnableAmbusherEscape", true) == true
        end
        local escapeDebug = EA_DebugEnabled()
        local function EA_LogEscapeBlocked(reason, ...)
            if not escapeDebug then
                return
            end
            DebugPrint("[Escape] blocked:", tostring(turnCharacter), "reason=", tostring(reason), ...)
        end
        if not escapeEnabled then
            EA_LogEscapeBlocked("disabled")
            return false
        end
        if not turnCharacter or turnCharacter == "" then
            EA_LogEscapeBlocked("missing_character")
            return false
        end
        if Osi.IsInCombat and Osi.IsInCombat(turnCharacter) ~= 1 then
            EA_LogEscapeBlocked("not_in_combat")
            return false
        end

        local spawned = EA_GetSpawnedRegistry()
        if not spawned then
            EA_LogEscapeBlocked("missing_registry")
            return false
        end
        local id = EA_FastNormalizeUUID(turnCharacter) or EA_NormalizeUUID(turnCharacter) or turnCharacter
        local spawnedData = spawned[id] or spawned[turnCharacter]
        if type(spawnedData) ~= "table" then
            EA_LogEscapeBlocked("not_spawned")
            return false
        end
        state.pendingByEnemy = state.pendingByEnemy or {}
        local pending = state.pendingByEnemy[id]
        if type(pending) == "table" then
            if EA_CountTrackedAmbushersInCombat(combatKey) <= 1 then
                EA_CancelPendingEscape(turnCharacter, combatKey, "last_tracked", 0, true)
                EA_LogEscapeBlocked("last_tracked", "combat=", tostring(combatKey), "pending=", "true")
                return false
            end
            local pendingProfile = EA_GetEscapeProfileByCreatureType(spawnedData.creatureType, string.upper(tostring(pending.tier or spawnedData.tier or "COMMON")), {
                combatKey = combatKey,
                turnCharacter = turnCharacter,
            })
            return EA_ResolveAmbusherEscape(turnCharacter, combatKey, state, spawnedData, pendingProfile, pending)
        end
        if spawnedData.isChampion == true then
            EA_LogEscapeBlocked("champion")
            return false
        end
        if spawnedData.noEscape == true then
            EA_LogEscapeBlocked("no_escape")
            return false
        end

        local turnCount = tonumber(state and state.turnCount) or 0
        local startTurn = EA_GetPresetEscapeNumber(
            "escapeStartTurn",
            10,
            1,
            30,
            true
        )
        if turnCount < startTurn then
            EA_LogEscapeBlocked("turn", "current=", tostring(turnCount), "start=", tostring(startTurn))
            return false
        end

        local maxEscapes = EA_GetPresetEscapeNumber(
            "escapeMaxPerCombat",
            2,
            0,
            6,
            true
        )
        state.escapedCount = tonumber(state.escapedCount) or 0
        if state.escapedCount >= maxEscapes then
            EA_LogEscapeBlocked("max_escapes", "escapedCount=", tostring(state.escapedCount), "max=", tostring(maxEscapes))
            return false
        end

        state.nextAttemptTurnByEnemy = state.nextAttemptTurnByEnemy or {}
        local nextTurn = tonumber(state.nextAttemptTurnByEnemy[id]) or 0
        if nextTurn > turnCount then
            EA_LogEscapeBlocked("retry_cooldown", "currentTurn=", tostring(turnCount), "nextTurn=", tostring(nextTurn))
            return false
        end

        local hpThreshold = EA_GetPresetEscapeNumber(
            "escapeHPThreshold",
            50,
            1,
            100,
            true
        )
        local hp = Osi.GetHitpoints and tonumber(Osi.GetHitpoints(turnCharacter)) or nil
        local maxHp = Osi.GetMaxHitpoints and tonumber(Osi.GetMaxHitpoints(turnCharacter)) or nil
        local hpPct = nil
        if hp and maxHp and maxHp > 0 then
            hpPct = (hp / maxHp) * 100.0
        end
        if hpPct and hpPct > hpThreshold then
            EA_LogEscapeBlocked("hp", "hp%=", tostring(math.floor(hpPct + 0.5)), "threshold=", tostring(hpThreshold), "hp=", tostring(hp), "maxHp=", tostring(maxHp))
            return false
        end

        -- Never let the final tracked ambusher disappear from the fight.
        if EA_CountTrackedAmbushersInCombat(combatKey) <= 1 then
            EA_LogEscapeBlocked("last_tracked", "combat=", tostring(combatKey))
            return false
        end

        local tier = string.upper(tostring(spawnedData.tier or "COMMON"))
        local profile = EA_GetEscapeProfileByCreatureType(spawnedData.creatureType, tier, {
            combatKey = combatKey,
            turnCharacter = turnCharacter,
        })
        local tierBonusByBand = {
            COMMON = 0,
            VETERAN = 1,
            ELITE = 2,
            LEGENDARY = 3
        }
        local tierBonus = tonumber(tierBonusByBand[tier]) or 0
        local profileBonus = tonumber(profile and profile.bonus) or 0
        local totalBonus = tierBonus + profileBonus
        local dc = EA_GetPresetEscapeNumber(
            "escapeDC",
            14,
            5,
            25,
            true
        )
        local d20 = EA_RandomInt(1, 20)
        local totalRoll = d20 + totalBonus
        local success = totalRoll >= dc

        if not success then
            state.nextAttemptTurnByEnemy[id] = turnCount + EA_ESCAPE_RETRY_COOLDOWN_TURNS
            EA_ApplyEscapeFailStaggeredStatus(turnCharacter, EA_ESCAPE_FAIL_STAGGERED_DURATION)
            if EA_DebugEnabled() then
                DebugPrint(
                    "[Escape] failed:",
                    tostring(turnCharacter),
                    "roll=",
                    tostring(totalRoll),
                    "dc=",
                    tostring(dc),
                    "d20=",
                    tostring(d20),
                    "bonus=",
                    tostring(totalBonus),
                    "hp%=",
                    tostring(hpPct and math.floor(hpPct + 0.5) or "n/a")
                )
            end
            return false
        end

        local fleeFrom = EA_GetEscapeAnchorObject(turnCharacter, spawnedData)
        local fleeRange = tonumber(profile and profile.fleeRange) or EA_ESCAPE_FLEE_RANGE_DEFAULT
        local pendingMeta = {
            totalRoll = totalRoll,
            dc = dc,
            d20 = d20,
            totalBonus = totalBonus,
            hpPctRounded = hpPct and math.floor(hpPct + 0.5) or "n/a",
            tier = tier,
            creatureType = spawnedData.creatureType or "?",
            profileMode = tostring(profile and profile.fallbackMode or "default"),
            fleeFrom = fleeFrom,
            fleeRange = fleeRange,
            resolveTurn = turnCount + EA_ESCAPE_PENDING_RESOLVE_TURNS,
            armedTurn = turnCount,
        }

        local staged = false
        if EA_ApplyEscapeImminentStatus(turnCharacter, EA_ESCAPE_IMMINENT_DURATION) then
            state.pendingByEnemy[id] = pendingMeta
            state.updatedAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
            if type(spawnedData) == "table" then
                spawnedData.escapePending = true
                spawnedData.escapePendingAt = state.updatedAt
                spawnedData.escapePendingCombatKey = combatKey
            end
            EA_Dirty()
            EA_MarkRuntimeStateDirty()
            staged = true
            EA_IssueFleeFromObject(turnCharacter, fleeFrom, fleeRange)
            EA_ScheduleEscapeStageEndTurn(turnCharacter, EA_ESCAPE_STAGE_ENDTURN_DELAY_MS)
            if EA_DebugEnabled() then
                DebugPrint(
                    "[Escape] staged:",
                    tostring(turnCharacter),
                    "roll=",
                    tostring(totalRoll),
                    "dc=",
                    tostring(dc),
                    "d20=",
                    tostring(d20),
                    "bonus=",
                    tostring(totalBonus),
                    "tier=",
                    tostring(tier),
                    "type=",
                    tostring(spawnedData.creatureType or "?"),
                    "hp%=",
                    tostring(hpPct and math.floor(hpPct + 0.5) or "n/a"),
                    "resolveTurn=",
                    tostring(pendingMeta.resolveTurn),
                    "mode=",
                    tostring(pendingMeta.profileMode),
                    "fleeRange=",
                    tostring(fleeRange)
                )
            end
        end
        if staged then
            return true
        end

        return EA_ResolveAmbusherEscape(turnCharacter, combatKey, state, spawnedData, profile, pendingMeta)
    end
    EA_FindCombatKeyForCharacter = function(character)
        local id = EA_FastNormalizeUUID(character) or EA_NormalizeUUID(character) or character
        local byMember = EnemyAmbush._CombatKeyByMember
        if type(byMember) == "table" then
            local knownMember = byMember[id] or byMember[character]
            if type(knownMember) == "string" and knownMember ~= "" then
                return knownMember
            end
        end
        local byAmbusher = EnemyAmbush._CombatKeyByAmbusher
        if type(byAmbusher) == "table" then
            local known = byAmbusher[id] or byAmbusher[character]
            if type(known) == "string" and known ~= "" then
                return known
            end
        end
        return ""
    end
    local function EA_FinalizeEscapedEntity(doomed)
        local norm = EA_FastNormalizeUUID(doomed) or EA_NormalizeUUID(doomed) or doomed
        local spawnedNow = EA_GetSpawnedRegistry()
        if spawnedNow then
            local doomedData = spawnedNow[norm] or spawnedNow[doomed]
            if type(doomedData) == "table" then
                doomedData.escapePending = nil
                doomedData.escapePendingAt = nil
                doomedData.escapeScheduled = nil
                doomedData.escapeScheduledAt = nil
            end
            spawnedNow[doomed] = nil
            if norm then
                spawnedNow[norm] = nil
            end
        end
        if type(EnemyAmbush._CombatKeyByAmbusher) == "table" then
            EnemyAmbush._CombatKeyByAmbusher[doomed] = nil
            if norm then
                EnemyAmbush._CombatKeyByAmbusher[norm] = nil
            end
        end
        if type(EnemyAmbush._CombatKeyByMember) == "table" then
            EnemyAmbush._CombatKeyByMember[doomed] = nil
            if norm then
                EnemyAmbush._CombatKeyByMember[norm] = nil
            end
        end
        if spawnedNow then
            EA_Dirty()
        end
    end

    EA_EnsureCombatEscapeStateRef = EA_EnsureCombatEscapeState
    EA_CleanupCombatEscapeStateIfIdleRef = EA_CleanupCombatEscapeStateIfIdle
    EA_ResetSoftlockIdleCounterRef = EA_ResetSoftlockIdleCounter
    EA_GetCombatKeyForTurnCharacterRef = EA_GetCombatKeyForTurnCharacter
    EA_FindCombatEscapeStateRef = EA_FindCombatEscapeState
    EA_FindTurnChatterStateRef = EA_FindTurnChatterState
    EA_TryAmbusherEscapeRef = EA_TryAmbusherEscape
    EA_TrySoftlockDeleteOnTurnRef = EA_TrySoftlockDeleteOnTurn
    EA_CancelPendingEscapeRef = EA_CancelPendingEscape
    local EA_ResolvePendingEscapeAfterLeftCombatRef = EA_ResolvePendingEscapeAfterLeftCombat

    local function EA_TryAnyTurnBark(barkList, speaker, maxAttempts)
        if type(barkList) ~= "table" or #barkList == 0 then
            return false, nil
        end
        local attempts = math.max(1, math.min(#barkList, math.floor(tonumber(maxAttempts) or #barkList)))
        local used = {}
        local lastTried = nil
        for _ = 1, attempts do
            local barkId = nil
            local guard = 0
            while guard < 32 do
                guard = guard + 1
                local candidate = barkList[EA_RandomInt(1, #barkList)]
                if type(candidate) == "string" and candidate ~= "" and not used[candidate] then
                    barkId = candidate
                    break
                end
            end
            if not barkId then
                break
            end
            used[barkId] = true
            lastTried = barkId
            if Osi.StartVoiceBark and SafeOsiExec(Osi.StartVoiceBark, barkId, speaker) then
                return true, barkId
            end
        end
        return false, lastTried
    end

    local EA_LimitedSeenOrderByCache = setmetatable({}, { __mode = "k" })
    local function EA_MarkLimitedSeen(cache, key, cap, ttlMs)
        if type(cache) ~= "table" or not key or key == "" then return end

        local limit = tonumber(cap) or 256
        if limit < 16 then
            limit = 16
        end
        local ttl = tonumber(ttlMs) or (10 * 60 * 1000)
        if ttl < 1000 then
            ttl = 1000
        end

        local now = tonumber(EA_NowMonotonicMs and EA_NowMonotonicMs() or 0) or 0
        local existing = tonumber(cache[key]) or 0
        if existing > 0 and now > 0 and (now - existing) <= ttl then
            return
        end

        local order = EA_LimitedSeenOrderByCache[cache]
        if type(order) ~= "table" then
            order = {}
            EA_LimitedSeenOrderByCache[cache] = order
        end

        cache[key] = (now > 0) and now or 1
        order[#order + 1] = key

        if now > 0 then
            local idx = 1
            while idx <= #order do
                local k = order[idx]
                local seenAt = tonumber(cache[k]) or 0
                if seenAt <= 0 or (now - seenAt) > ttl then
                    cache[k] = nil
                    table.remove(order, idx)
                else
                    idx = idx + 1
                end
            end
        end

        while #order > limit do
            local oldest = table.remove(order, 1)
            if oldest then
                cache[oldest] = nil
            end
        end
    end

    local function EA_GetPlayerFromCombat(combatGuid, fallbackSource)
        if Osi.DB_Is_InCombat and Osi.DB_Is_InCombat.Get then
            local okRows, rows = pcall(function()
                return Osi.DB_Is_InCombat:Get(nil, combatGuid)
            end)
            if okRows and rows then
                for _, row in ipairs(rows) do
                    local member = row[1]
                    if member and member ~= "" and Osi.IsPlayer and Osi.IsPlayer(member) == 1 then
                        return member
                    end
                end
            end
        end

        if fallbackSource and fallbackSource ~= "" and Osi.GetClosestAlivePlayer then
            local p = Osi.GetClosestAlivePlayer(fallbackSource)
            if p and p ~= "" then
                return p
            end
        end
        if Osi.GetHostCharacter then
            return Osi.GetHostCharacter()
        end
        return nil
    end

    local function EA_FindSpawnedSourceInCombat(combatGuid)
        local spawned = EA_GetSpawnedRegistry()
        if not spawned then
            return nil, nil
        end
        if Osi.DB_Is_InCombat and Osi.DB_Is_InCombat.Get then
            local okRows, rows = pcall(function()
                return Osi.DB_Is_InCombat:Get(nil, combatGuid)
            end)
            if okRows and rows then
                for _, row in ipairs(rows) do
                    local member = row[1]
                    local id = EA_NormalizeUUID(member) or member
                    local data = spawned[id] or spawned[member]
                    if data and ((not Osi.IsPlayer) or Osi.IsPlayer(member) ~= 1) then
                        return member, data
                    end
                end
            end
        end
        return nil, nil
    end

    local function EA_JoinDeferredSupportsForAmbush(ambushId, player, sourceEnemy, combatGuid)
        local aid = tostring(ambushId or "")
        if aid == "" then return 0 end
        local combatKey = EA_NormalizeCombatKey(combatGuid)
        EA_RegisterDeferredSupportJoinWindow(aid, combatKey, player, sourceEnemy)

        local spawned = EA_GetSpawnedRegistry()
        if not spawned then
            return 0
        end
        local joined = 0
        for id, data in pairs(spawned) do
            if (type(data) == "table" or type(data) == "userdata") and data.joinDeferred and tostring(data.ambushId or "") == aid then
                local enemy = EA_NormalizeUUID(id) or id
                local alive = (not Osi.ObjectExists) or (Osi.ObjectExists(enemy) == 1)
                alive = alive and ((not Osi.IsDead) or (Osi.IsDead(enemy) ~= 1))
                if alive then
                    local joinPlayer = player
                    if (not joinPlayer or joinPlayer == "") and data.anchorPlayer and Osi.ObjectExists and Osi.ObjectExists(data.anchorPlayer) == 1 then
                        joinPlayer = data.anchorPlayer
                    end
                    if (not joinPlayer or joinPlayer == "") and sourceEnemy and sourceEnemy ~= "" and Osi.GetClosestAlivePlayer then
                        joinPlayer = Osi.GetClosestAlivePlayer(sourceEnemy)
                    end
                    if joinPlayer and joinPlayer ~= "" then
                        data.joinDeferred = nil
                        EA_RemoveArrivalInvisibility(enemy, "deferred_join")
                        EA_MakeAmbushHostile(enemy, joinPlayer)
                        if Ext and Ext.Timer and Ext.Timer.WaitFor then
                            local enemyRef = enemy
                            local joinRef = joinPlayer
                            Ext.Timer.WaitFor(220, function()
                                if Osi.ObjectExists and Osi.ObjectExists(enemyRef) == 1 and Osi.ObjectExists(joinRef) == 1 then
                                    if Osi.IsInCombat and Osi.IsInCombat(enemyRef) ~= 1 then
                                        EA_RemoveArrivalInvisibility(enemyRef, "deferred_join_retry")
                                        EA_MakeAmbushHostile(enemyRef, joinRef)
                                        if Osi.Attack then
                                            pcall(Osi.Attack, enemyRef, joinRef)
                                        end
                                    end
                                end
                            end)
                            Ext.Timer.WaitFor(650, function()
                                if Osi.ObjectExists and Osi.ObjectExists(enemyRef) == 1 and Osi.ObjectExists(joinRef) == 1 then
                                    if Osi.IsInCombat and Osi.IsInCombat(enemyRef) ~= 1 then
                                        EA_RemoveArrivalInvisibility(enemyRef, "deferred_join_retry")
                                        EA_MakeAmbushHostile(enemyRef, joinRef)
                                    end
                                end
                            end)
                        end
                        joined = joined + 1
                    end
                else
                    data.joinDeferred = nil
                end
            end
        end

        if joined > 0 and EA_DebugEnabled() then
            local joinLogCombatKey = (combatKey ~= "" and combatKey or "unknown")
            if EA_ShouldLogDeferredJoin(aid, joinLogCombatKey, "joined") then
                DebugPrint("Joined deferred supports:", tostring(joined), "ambushId=", tostring(aid), "combat=", tostring(combatKey))
            end
        end
        return joined
    end

    -- Phase 8 / LP-03 measured follow-through:
    -- keep the retry/rescue ladder intact unless direct ambush-owned telemetry
    -- shows an active runtime defect. Current evidence classifies this path as
    -- contained, so Task 8.5 records an explicit no-change decision here.
    EA_P0Inc("listenerReg.EnterCombatFailed.after")
    Ext.Osiris.RegisterListener("EnterCombatFailed", 2, "after", function(a, b)
        local player, enemy = nil, nil
        if Osi.IsPlayer and Osi.IsPlayer(a) == 1 then
            player, enemy = a, b
        elseif Osi.IsPlayer and Osi.IsPlayer(b) == 1 then
            player, enemy = b, a
        end
        if not player or not enemy then
            EA_P0Inc("enterCombat.ignoredNonPlayerPair")
            return
        end

        local spawned = EA_GetSpawnedRegistry()
        if not spawned then
            EA_P0Inc("enterCombat.ignoredNonAmbush")
            return
        end
        local enemyId = EA_NormalizeUUID(enemy) or enemy
        local spawnData = spawned[enemyId] or spawned[enemy]
        if not spawnData then
            EA_P0Inc("enterCombat.ignoredNonAmbush")
            return
        end
        local isChampionAmbusher = (type(spawnData) == "table" and spawnData.isChampion == true)
        if type(spawnData) == "table" and spawnData.joinDeferred then
            EA_P0Inc("enterCombat.ignoredDeferredJoin")
            return
        end

        EA_P0Inc("listenerExec.EnterCombatFailed")
        if EA_DebugEnabled() then
            print(string.format("[EnemyAmbush][Debug] EnterCombatFailed: %s vs %s", tostring(a), tostring(b)))
        end

        local key = tostring(enemyId) .. "|" .. tostring(EA_NormalizeUUID(player) or player)
        local tries = (EA_EnterCombatRetryByPair[key] or 0) + 1
        local pairSeen = EA_P0BumpKeyedCount("enterCombat.byPair", key, 64)
        if pairSeen > 1 then
            EA_P0PushNote("enterCombat.samples", {
                kind = "repeat_pair",
                key = key,
                count = pairSeen,
                tries = tries,
            }, 24)
        end
        EA_P0Inc("enterCombat.failedSeen")
        if tries == 1 then
            EA_P0Inc("enterCombat.retryStage.1")
        elseif tries == 2 then
            EA_P0Inc("enterCombat.retryStage.2")
        elseif tries == 3 then
            EA_P0Inc("enterCombat.retryStage.3")
        else
            EA_P0Inc("enterCombat.retryStage.4plus")
            if tries >= 4 then
                EA_P0PushNote("enterCombat.samples", {
                    kind = "deep_retry",
                    key = key,
                    tries = tries,
                    enemy = tostring(enemyId),
                }, 24)
            end
        end
        if tries >= 8 then
            EA_P0Inc("enterCombat.retryStage.8plus")
        end
        if tries >= 12 then
            EA_P0Inc("enterCombat.retryStage.12")
        end
        EA_EnterCombatRetryByPair[key] = tries
        if not EA_EnterCombatFirstFailAtByPair[key] then
            EA_EnterCombatFirstFailAtByPair[key] = EA_NowMonotonicMs()
        end
        if tries > 12 then
            EA_P0Inc("enterCombat.retryExhausted")
            if EA_EnterCombatTeleportUsedByPair[key] then
                EA_P0Inc("enterCombat.teleportRescueFailed")
            end
            EA_EnterCombatRetryByPair[key] = nil
            EA_EnterCombatTeleportUsedByPair[key] = nil
            EA_EnterCombatFirstFailAtByPair[key] = nil
            EA_DeleteStuckAmbusher(enemy, "EnterCombatFailedRetries")
            return
        end

        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(120 * tries, function()
                if Osi.ObjectExists and (Osi.ObjectExists(enemy) ~= 1 or Osi.ObjectExists(player) ~= 1) then
                    return
                end
                if Osi.IsDead and Osi.IsDead(enemy) == 1 then
                    return
                end
                local enemyInCombat = (Osi.IsInCombat and Osi.IsInCombat(enemy) == 1) or false
                if enemyInCombat then
                    EA_P0Inc("enterCombat.successAfterRetry")
                    if tries == 1 then
                        EA_P0Inc("enterCombat.successStage.1")
                    elseif tries == 2 then
                        EA_P0Inc("enterCombat.successStage.2")
                    elseif tries == 3 then
                        EA_P0Inc("enterCombat.successStage.3")
                    else
                        EA_P0Inc("enterCombat.successStage.4plus")
                    end
                    if tries >= 8 then
                        EA_P0Inc("enterCombat.successStage.8plus")
                    end
                    if tries >= 12 then
                        EA_P0Inc("enterCombat.successStage.12")
                    end
                    if EA_EnterCombatTeleportUsedByPair[key] then
                        EA_P0Inc("enterCombat.teleportRescueSucceeded")
                    end
                    EA_EnterCombatRetryByPair[key] = nil
                    EA_EnterCombatTeleportUsedByPair[key] = nil
                    EA_EnterCombatFirstFailAtByPair[key] = nil
                    return
                end
                local playerInCombat = (Osi.IsInCombat and Osi.IsInCombat(player) == 1) or false
                local partyInCombat = playerInCombat
                if type(EA_IsAnyPartyInCombat) == "function" then
                    local okParty, anyParty = pcall(EA_IsAnyPartyInCombat)
                    if okParty then
                        partyInCombat = (anyParty == true) or (tonumber(anyParty) == 1)
                    end
                end

                EA_RemoveArrivalInvisibility(enemy, "enter_combat_retry")
                EA_MakeAmbushHostile(enemy, player)
                if tries >= EA_ENTER_COMBAT_MOMENTUM_RETRY_FROM and Osi.ApplyStatus then
                    pcall(Osi.ApplyStatus, enemy, "MAG_MOMENTUM", EA_ENTER_COMBAT_MOMENTUM_DURATION, 1, enemy)
                end
                -- True last-resort teleport rescue:
                -- only at final retry tier, only once per pair, and never if party is already in combat.
                local stillOutOfCombat = (Osi.IsInCombat and Osi.IsInCombat(enemy) ~= 1) or false
                if EA_ENTER_COMBAT_ENABLE_TELEPORT_FALLBACK and tries >= 12 and stillOutOfCombat then
                    EA_P0Inc("enterCombat.teleportRescueConsidered")
                    local nowMs = EA_NowMonotonicMs()
                    local firstFailAt = tonumber(EA_EnterCombatFirstFailAtByPair[key]) or 0
                    local failAgeMs = (firstFailAt > 0 and nowMs > firstFailAt) and (nowMs - firstFailAt) or 0
                    local farEnough = false
                    local distToPlayer = nil
                    if Osi.GetDistanceTo then
                        local okDist, d = pcall(Osi.GetDistanceTo, enemy, player)
                        if okDist and tonumber(d) then
                            distToPlayer = tonumber(d)
                            farEnough = (distToPlayer >= EA_ENTER_COMBAT_TELEPORT_MIN_DISTANCE)
                        end
                    end
                    local teleportEligible = (failAgeMs >= EA_ENTER_COMBAT_TELEPORT_MIN_DELAY_MS) and farEnough

                    if (not isChampionAmbusher) and (not EA_EnterCombatTeleportUsedByPair[key]) and Osi.TeleportTo and (not partyInCombat) and teleportEligible then
                        EA_EnterCombatTeleportUsedByPair[key] = true
                        EA_P0Inc("enterCombat.teleportRescueAttempted")
                        UpdateMetric("enterCombatTeleportFallbackUsed")
                        if EA_DebugEnabled() then
                            DebugPrint(
                                "EnterCombat final teleport fallback:",
                                tostring(enemy),
                                "tries=",
                                tostring(tries),
                                "ageMs=",
                                tostring(failAgeMs),
                                "dist=",
                                tostring(distToPlayer)
                            )
                        end
                        local okTeleport = pcall(Osi.TeleportTo, enemy, player, "", 0, 0, 0, 0, 1)
                        if okTeleport then
                            EA_P0Inc("enterCombat.teleportRescueApplied")
                        else
                            EA_P0Inc("enterCombat.teleportRescueFailed")
                        end
                        EA_RemoveArrivalInvisibility(enemy, "enter_combat_teleport_retry")
                        EA_MakeAmbushHostile(enemy, player)
                    else
                        local skipReason = "unknown"
                        if EA_EnterCombatTeleportUsedByPair[key] then
                            skipReason = "already_used"
                        elseif not Osi.TeleportTo then
                            skipReason = "no_teleport_api"
                        elseif isChampionAmbusher then
                            skipReason = "champion"
                        elseif partyInCombat then
                            skipReason = "party_in_combat"
                        elseif not teleportEligible then
                            skipReason = "not_eligible"
                        end
                        EA_P0BumpKeyedCount("enterCombat.teleportSkipReason", skipReason, 32)
                    if EA_DebugEnabled() then
                        DebugPrint(
                            "EnterCombat final teleport skipped:",
                            tostring(enemy),
                            "tries=",
                            tostring(tries),
                            "ageMs=",
                            tostring(failAgeMs),
                            "dist=",
                            tostring(distToPlayer),
                            "partyInCombat=",
                            tostring(partyInCombat),
                            "teleportEnabled=",
                            tostring(EA_ENTER_COMBAT_ENABLE_TELEPORT_FALLBACK),
                            "eligible=",
                            tostring(teleportEligible),
                            "used=",
                            tostring(EA_EnterCombatTeleportUsedByPair[key] == true)
                        )
                    end
                    end
                end
            end)
        end
    end)

    -- Surprise is now applied once per combat from CombatStarted, not EnteredCombat retry ladders.
    EA_P0Inc("listenerReg.CombatStarted.before")
    Ext.Osiris.RegisterListener("CombatStarted", 1, "before", function(combatGuid)
        local combatKey = EA_NormalizeCombatKey(combatGuid)
        if combatKey == "" or EA_SurpriseAppliedByCombat[combatKey] then
            return
        end

        local sourceEnemy, sourceData = EA_FindSpawnedSourceInCombat(combatGuid)
        if not sourceEnemy then
            return
        end

        local escapeKey = EA_NormalizeCombatKey(combatGuid)
        if escapeKey ~= "" then
            EA_EnsureCombatEscapeState(escapeKey)
            local sourceId = EA_NormalizeUUID(sourceEnemy) or sourceEnemy
            EnemyAmbush._CombatKeyByAmbusher[sourceId] = escapeKey
            EnemyAmbush._CombatKeyByAmbusher[sourceEnemy] = escapeKey
            if type(EnemyAmbush._CombatKeyByMember) == "table" then
                EnemyAmbush._CombatKeyByMember[sourceId] = escapeKey
                EnemyAmbush._CombatKeyByMember[sourceEnemy] = escapeKey
            end
        end

        EA_MarkLimitedSeen(EA_SurpriseAppliedByCombat, combatKey, 256)

        local player = EA_GetPlayerFromCombat(combatGuid, sourceEnemy)
        if not player or player == "" then
            return
        end

        if EA_DebugEnabled() then
            DebugPrint("CombatStarted surprise hook:", tostring(sourceEnemy), "combat=", tostring(combatKey))
        end

        local suppressCombatStartPresentation = (type(sourceData) == "table" and sourceData.suppressCombatStartPresentation == true)
        local chatterMap = EA_GetRuntimeTurnChatterMap()
        if not suppressCombatStartPresentation then
            EA_PlayCombatStartVoiceOrSfx(sourceEnemy, player, sourceData, combatGuid)
            do
                local hasTurnBarks = (type(sourceData) == "table" and type(sourceData.combatTurnBarks) == "table" and #sourceData.combatTurnBarks > 0)
                local hasTurnSounds = (type(sourceData) == "table" and type(sourceData.combatTurnSounds) == "table" and #sourceData.combatTurnSounds > 0)
                local turnLimit = math.max(0, math.min(8, math.floor(tonumber(type(sourceData) == "table" and sourceData.combatTurnLimit or 0) or 0)))
                if (hasTurnBarks or hasTurnSounds) and turnLimit > 0 then
                    chatterMap[combatKey] = {
                        sourceEnemy = sourceEnemy,
                        player = player,
                        remaining = turnLimit,
                        barks = sourceData.combatTurnBarks,
                        sounds = sourceData.combatTurnSounds,
                        soundAlways = (sourceData.combatTurnSoundAlways == true),
                        enemyOnly = (sourceData.combatTurnEnemyOnly == true),
                        updatedAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0,
                    }
                    EA_MarkRuntimeStateDirty()
                    if EA_DebugEnabled() then
                        DebugPrint("Combat turn chatter armed:", tostring(combatKey), "turns=", tostring(turnLimit), "enemyOnly=", tostring(sourceData.combatTurnEnemyOnly == true))
                    end
                else
                    chatterMap[combatKey] = nil
                    EA_MarkRuntimeStateDirty()
                end
            end
        else
            chatterMap[combatKey] = nil
            EA_MarkRuntimeStateDirty()
        end

        local payload = { ambushId = "combat|" .. combatKey, source = sourceEnemy }
        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(90, function()
                EA_TryApplyPartySurprise(player, payload, true)
            end)
        else
            EA_TryApplyPartySurprise(player, payload, true)
        end

        if type(sourceData) == "table" and sourceData.ambushId then
            EA_JoinDeferredSupportsForAmbush(sourceData.ambushId, player, sourceEnemy, combatGuid)
        end
    end)
    end

    function Runtime.PruneRuntimeCombatState(reason)
        if type(EA_PruneRuntimeCombatStateRef) == "function" then
            return EA_PruneRuntimeCombatStateRef(reason)
        end
        return 0
    end
    function Runtime.EnsureCombatEscapeState(combatKey)
        return EA_EnsureCombatEscapeStateRef(combatKey)
    end
    function Runtime.CleanupCombatEscapeStateIfIdle(combatGuid)
        return EA_CleanupCombatEscapeStateIfIdleRef(combatGuid)
    end
    function Runtime.ResetSoftlockIdleCounter(character, reason, damageAmount)
        return EA_ResetSoftlockIdleCounterRef(character, reason, damageAmount)
    end
    function Runtime.GetCombatKeyForTurnCharacter(turnCharacter)
        return EA_GetCombatKeyForTurnCharacterRef(turnCharacter)
    end
    function Runtime.FindCombatEscapeState(combatKey)
        return EA_FindCombatEscapeStateRef(combatKey)
    end
    function Runtime.FindTurnChatterState(combatKey)
        return EA_FindTurnChatterStateRef(combatKey)
    end
    function Runtime.TryAmbusherEscape(turnCharacter, combatKey, state)
        return EA_TryAmbusherEscapeRef(turnCharacter, combatKey, state)
    end
    function Runtime.TrySoftlockDeleteOnTurn(turnCharacter, combatKey, spawnedData)
        return EA_TrySoftlockDeleteOnTurnRef(turnCharacter, combatKey, spawnedData)
    end
    function Runtime.CancelPendingEscape(turnCharacter, combatKey, reason, damageAmount, applyRetryCooldown)
        return EA_CancelPendingEscapeRef(turnCharacter, combatKey, reason, damageAmount, applyRetryCooldown)
    end
    function Runtime.ResolvePendingEscapeAfterLeftCombat(turnCharacter, combatKey, reason)
        if type(EA_ResolvePendingEscapeAfterLeftCombatRef) == "function" then
            return EA_ResolvePendingEscapeAfterLeftCombatRef(turnCharacter, combatKey, reason)
        end
        return false
    end

    return Runtime
end

return M
