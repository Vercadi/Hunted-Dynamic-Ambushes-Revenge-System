EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local M = {}
function M.Build(deps)
    deps = deps or {}
    local EnemyData = deps.EnemyData or Ext.Require("EnemyAmbush_Data.lua")
    local UpdateMetric = deps.UpdateMetric or (EA and EA["UpdateMetric"]) or function() end
    local EA_GetSettingBoolRaw = deps.EA_GetSettingBool or (EA and EA["EA_GetSettingBool"]) or function(_, fallback) return fallback == true end
    local function EA_GetSettingBool(settingId, fallback)
        if settingId == "MCM_DebugMode" then
            return EA_GetSettingBoolRaw("MCM_EnableDebugLogging", false) == true
                or EA_GetSettingBoolRaw("MCM_DebugMode", false) == true
        end
        return EA_GetSettingBoolRaw(settingId, fallback)
    end
    local EA_GetSpawnPlacementMode = deps.EA_GetSpawnPlacementMode or (EA and EA["EA_GetSpawnPlacementMode"]) or function() return "AUTO" end
    local PickEnemyTemplate = deps.PickEnemyTemplate
    local ValidateEnemyData = deps.ValidateEnemyData
    local DebugPrint = deps.DebugPrint or (EA and EA["DebugPrint"]) or function() end
    local SafeGetPosition = deps.SafeGetPosition or function() return nil, nil, nil end
    local GetPartyMaxLevel = deps.GetPartyMaxLevel
    local EA_RollOverlevelDelta = deps.EA_RollOverlevelDelta
    local GetPartySize = deps.GetPartySize or function() return 1 end
    local EA_GetTierFromDelta = deps.EA_GetTierFromDelta
    local EA_GetDynamicCategory = deps.EA_GetDynamicCategory
    local EA_GetTierSpawnDistance = deps.EA_GetTierSpawnDistance
    local EA_IsRobust = deps.EA_IsRobust or function() return false end
    local EA_RecordSpawnSuccess = deps.EA_RecordSpawnSuccess
    local EA_FindValidPositionCompat = deps.EA_FindValidPositionCompat
    local SafeOsiExec = deps.SafeOsiExec or function() return false end
    local HasLineOfSight = deps.HasLineOfSight or function() return false end
    local EA_SetLastError = deps.EA_SetLastError or function() end
    local EA_LogEvent = deps.EA_LogEvent or function() end
    local EA_RecordSpawnFailure = deps.EA_RecordSpawnFailure
    local SafeOsiCall = deps.SafeOsiCall or function() return nil end
    local EA_GetScaledAmbushLevel = deps.EA_GetScaledAmbushLevel
    local ApplyDifficultyVisuals = deps.ApplyDifficultyVisuals or function() end
    local EA_EvaluateArrivalCue = deps.EA_EvaluateArrivalCue
    local EA_ShouldApplyArrivalCue = deps.EA_ShouldApplyArrivalCue or function() return false end
    local EA_SelectArrivalCue = deps.EA_SelectArrivalCue or function() return nil end
    local EA_PlaySoundEvent = deps.EA_PlaySoundEvent or function() end
    local EA_TryVoiceBark = deps.EA_TryVoiceBark or function() return false end
    local EA_GetXPRewardCategoryForTier = deps.EA_GetXPRewardCategoryForTier
    local EA_GetXPRewardCategoryForEntry = deps.EA_GetXPRewardCategoryForEntry
        or function(entry, tier)
            return EA_GetXPRewardCategoryForTier(tier), "tier_fallback"
        end
    local EA_CalcKillXP = deps.EA_CalcKillXP or function() return 0 end
    local EA_GetEffectiveAmbushXPPercent = deps.EA_GetEffectiveAmbushXPPercent or function() return 100 end
    local EA_GetXPCloneRecord = deps.EA_GetXPCloneRecord
        or (EnemyData and EnemyData.GetXPCloneRecord)
        or (EA and EA["EA_GetXPCloneRecord"])
        or function() return nil end
    local SafeAddBoosts = deps.SafeAddBoosts or function() return false end
    local PlayVFX_OnEntity = deps.PlayVFX_OnEntity or function() end
    local SafeApplyStatus = deps.SafeApplyStatus or function() return false end
    local EA_ApplyTierAndTraits = deps.EA_ApplyTierAndTraits
    local EA_ApplyShadowCurseProtection = deps.EA_ApplyShadowCurseProtection
    local EA_NormalizeUUID = deps.EA_NormalizeUUID or function(v) return v end
    local EA_Spawned = deps.EA_Spawned or function() return {} end
    local EA_Dirty = deps.EA_Dirty or function() end
    local EA_MakeAmbushHostile = deps.EA_MakeAmbushHostile or function() end
    local EA_ForceAmbusherFaction = deps.EA_ForceAmbusherFaction or function() return false end
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local EA_EvictOldSpawned = deps.EA_EvictOldSpawned or function() end
    local EA_GetEffectiveDisableAmbushLoot = deps.EA_GetEffectiveDisableAmbushLoot or function() return false end
    local EA_ApplyNoLootFlags = deps.EA_ApplyNoLootFlags
    local EA_DiagRecordEncounterSpawn = deps.EA_DiagRecordEncounterSpawn or (EA and EA["EA_DiagRecordEncounterSpawn"]) or function() return false end
    local EA_DiagRecordCleanup = deps.EA_DiagRecordCleanup or (EA and EA["EA_DiagRecordCleanup"]) or function() return false end
    local EA_GetPartyMembers = deps.EA_GetPartyMembers or function(player)
        if player and player ~= "" then
            return { player }
        end
        return {}
    end
    local GetSafeLevel = deps.GetSafeLevel or function() return 1 end
    local PerformanceMetrics = deps.PerformanceMetrics
    local CurrentAmbushTheme = deps.CurrentAmbushTheme
    local GetCurrentAmbushTheme = deps.GetCurrentAmbushTheme
    local EA_MAX_SPAWN_HEIGHT_DELTA = tonumber(deps.EA_MAX_SPAWN_HEIGHT_DELTA) or tonumber((EA.CFG and EA.CFG.MAX_SPAWN_HEIGHT_DELTA)) or 4.0
    local EA_XP_COMPAT_NOTICE_EMITTED = (EA and EA._xpCompatNoticeEmitted) == true
    local fallbackRngMod = 2147483647
    local fallbackRngA = 48271
    local fallbackRngState = (tonumber(Ext and Ext.Utils and Ext.Utils.MonotonicTime and Ext.Utils.MonotonicTime()) or 1357911) % fallbackRngMod
    if fallbackRngState <= 0 then fallbackRngState = 1357911 end
    local function FallbackRandRaw()
        fallbackRngState = (fallbackRngState * fallbackRngA) % fallbackRngMod
        if fallbackRngState <= 0 then fallbackRngState = 1357911 end
        return fallbackRngState
    end
    local function EA_RandIntCompat(minVal, maxVal)
        local fn = EA and EA["EA_RandInt"]
        if type(fn) == "function" then
            local ok, out = pcall(fn, minVal, maxVal)
            if ok and tonumber(out) then
                return math.floor(tonumber(out))
            end
        end
        if maxVal == nil then
            local hi = math.floor(tonumber(minVal) or 1)
            if hi <= 1 then return 1 end
            return 1 + (FallbackRandRaw() % hi)
        end
        local lo = math.floor(tonumber(minVal) or 1)
        local hi = math.floor(tonumber(maxVal) or lo)
        if hi < lo then lo, hi = hi, lo end
        local span = (hi - lo) + 1
        if span <= 1 then return lo end
        return lo + (FallbackRandRaw() % span)
    end

    local function EA_RandFloatCompat()
        local fn = EA and EA["EA_RandFloat"]
        if type(fn) == "function" then
            local ok, out = pcall(fn)
            if ok and tonumber(out) then
                local v = tonumber(out)
                if v < 0 then v = 0 end
                if v >= 1 then v = 0.999999 end
                return v
            end
        end
        return FallbackRandRaw() / fallbackRngMod
    end

    local EA_ARRIVAL_INVISIBILITY_STATUS = "EA_ARRIVAL_INVISIBLE"
    local EA_ARRIVAL_INVISIBILITY_DURATION = 12
    local EA_ARRIVAL_INVISIBILITY_FAILSAFE_MS = 6000

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

    local function EA_RemoveArrivalInvisibility(enemy, reason, suppressDebug)
        if not (enemy and enemy ~= "") then
            return false
        end
        if Osi and Osi.ObjectExists and Osi.ObjectExists(enemy) ~= 1 then
            return false
        end
        if not EA_HasActiveStatusCompat(enemy, EA_ARRIVAL_INVISIBILITY_STATUS) then
            return false
        end
        local ok = (Osi and Osi.RemoveStatus) and pcall(Osi.RemoveStatus, enemy, EA_ARRIVAL_INVISIBILITY_STATUS) or false
        if not ok then
            return false
        end
        local norm = EA_NormalizeUUID(enemy) or enemy
        local spawned = EA_Spawned()
        local data = ((type(spawned) == "table" or type(spawned) == "userdata") and (spawned[norm] or spawned[enemy])) or nil
        if type(data) == "table" or type(data) == "userdata" then
            data.arrivalInvisible = nil
        end
        UpdateMetric("arrivalInvisibilityRemoved")
        if (not suppressDebug) and EA_GetSettingBool("MCM_DebugMode", false) then
            DebugPrint("[ArrivalInvisibility] removed:", tostring(enemy), "reason=", tostring(reason or "unknown"))
        end
        return true
    end

    local function EA_ApplyArrivalInvisibility(enemy, durationSeconds)
        local duration = tonumber(durationSeconds) or EA_ARRIVAL_INVISIBILITY_DURATION
        if duration <= 0 then
            return false
        end
        local applied = (SafeApplyStatus(enemy, EA_ARRIVAL_INVISIBILITY_STATUS, duration, 1) == true)
        if applied then
            UpdateMetric("arrivalInvisibilityApplied")
        else
            UpdateMetric("arrivalInvisibilityFailed")
        end
        return applied
    end

    local function EA_ScheduleArrivalInvisibilityFailsafe(enemy, delayMs)
        local delay = math.max(250, math.floor(tonumber(delayMs) or EA_ARRIVAL_INVISIBILITY_FAILSAFE_MS))
        if not (Ext and Ext.Timer and Ext.Timer.WaitFor) then
            return
        end
        Ext.Timer.WaitFor(delay, function()
            EA_RemoveArrivalInvisibility(enemy, "failsafe_timeout", true)
        end)
    end

local function EA_RemoveSpawnedEnemyImmediate(enemy, reason)
    if not enemy or enemy == "" then return end
    local norm = EA_NormalizeUUID(enemy) or enemy
    local spawned = EA_Spawned()
    local spawnedData = nil
    if type(spawned) == "table" or type(spawned) == "userdata" then
        spawnedData = spawned[norm] or spawned[enemy]
        if type(spawnedData) == "table" then
            pcall(EA_DiagRecordCleanup, enemy, tostring(reason or "unknown"), spawnedData)
        end
        spawned[norm] = nil
        spawned[enemy] = nil
    end
    EA_Dirty()
    if Osi and Osi.ObjectExists and Osi.ObjectExists(enemy) == 1 then
        if Osi.RequestDeleteTemporary then
            pcall(Osi.RequestDeleteTemporary, enemy)
        end
        if Osi.ObjectExists(enemy) == 1 and Osi.SetOnStage then
            pcall(Osi.SetOnStage, enemy, 0)
        end
    end
    if EA_GetSettingBool("MCM_DebugMode", false) then
        DebugPrint("Deleted invalid ambusher:", tostring(enemy), "reason=", tostring(reason or "unknown"))
    end
end

local function EA_RequestDeleteWithRetry(enemy, reason)
    if not enemy or enemy == "" then
        return
    end
    if not (Osi and (Osi.RequestDeleteTemporary or Osi.SetOnStage)) then
        return
    end

    local retryDelays = { 60, 180, 450 }

    local function TryDelete(attempt)
        local exists = 1
        if Osi.ObjectExists then
            local okExists, existsValue = pcall(Osi.ObjectExists, enemy)
            if okExists then
                exists = tonumber(existsValue) or 0
            else
                exists = 0
            end
        end

        if exists == 1 then
            if Osi.ClearOwnership then
                pcall(Osi.ClearOwnership, enemy)
            end
            if Osi.MakeNPC then
                pcall(Osi.MakeNPC, enemy)
            end
            if Osi.RequestDeleteTemporary then
                pcall(Osi.RequestDeleteTemporary, enemy)
            end
            if Osi.ObjectExists and Osi.ObjectExists(enemy) == 1 and Osi.SetOnStage then
                pcall(Osi.SetOnStage, enemy, 0)
            end
            return
        end

        local delay = retryDelays[attempt + 1]
        if delay and Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(delay, function()
                TryDelete(attempt + 1)
            end)
        elseif EA_GetSettingBool("MCM_DebugMode", false) then
            DebugPrint("Delete retry exhausted before ObjectExists:", tostring(enemy), "reason=", tostring(reason or "unknown"))
        end
    end

    TryDelete(0)
end

local function EA_ScheduleSpawnIntegrityWatch(enemy, player)
    if not (Ext and Ext.Timer and Ext.Timer.WaitFor) then return end
    if not enemy or enemy == "" then return end

    local enemyRef = enemy
    local playerRef = player

    local function HasLoSValue(value)
        return value == true or tonumber(value) == 1
    end

    local function GetPartySnapshot()
        local members = {}
        if type(EA_GetPartyMembers) == "function" and playerRef and playerRef ~= "" then
            local okParty, outParty = pcall(EA_GetPartyMembers, playerRef)
            if okParty and type(outParty) == "table" then
                members = outParty
            end
        end
        if #members == 0 and playerRef and playerRef ~= "" then
            members[1] = playerRef
        end
        return members
    end

    local function GetClosestPartyDistance2D(ex, ez, members)
        local closestDist = nil
        for i = 1, #(members or {}) do
            local member = members[i]
            if member and member ~= "" and Osi.ObjectExists and Osi.ObjectExists(member) == 1 then
                local px, _, pz = SafeGetPosition(member)
                if px and pz then
                    local dx = (tonumber(ex) or 0) - (tonumber(px) or 0)
                    local dz = (tonumber(ez) or 0) - (tonumber(pz) or 0)
                    local dist2D = math.sqrt((dx * dx) + (dz * dz))
                    if not closestDist or dist2D < closestDist then
                        closestDist = dist2D
                    end
                end
            end
        end
        return closestDist
    end

    local function HasLineOfSightToParty(members)
        if not HasLineOfSight then
            return false
        end
        for i = 1, #(members or {}) do
            local member = members[i]
            if member and member ~= "" and Osi.ObjectExists and Osi.ObjectExists(member) == 1 then
                local okLosA, losA = pcall(HasLineOfSight, enemyRef, member)
                local okLosB, losB = pcall(HasLineOfSight, member, enemyRef)
                if (okLosA and HasLoSValue(losA)) or (okLosB and HasLoSValue(losB)) then
                    return true
                end
            end
        end
        return false
    end

    local function Check(afterKick)
        if Osi.ObjectExists and Osi.ObjectExists(enemyRef) ~= 1 then
            return
        end
        if Osi.IsDead and Osi.IsDead(enemyRef) == 1 then
            return
        end

        local spawned = EA_Spawned()
        local norm = EA_NormalizeUUID(enemyRef) or enemyRef
        local data = ((type(spawned) == "table" or type(spawned) == "userdata")) and (spawned[norm] or spawned[enemyRef]) or nil
        if type(data) ~= "table" then
            return
        end

        local hasAmbusher = (Osi.HasActiveStatus and Osi.HasActiveStatus(enemyRef, "EA_AMBUSHER") == 1) or false
        if not hasAmbusher then
            EA_RemoveSpawnedEnemyImmediate(enemyRef, "MissingEA_AMBUSHER")
            return
        end

        local inCombat = (Osi.IsInCombat and Osi.IsInCombat(enemyRef) == 1) or false
        local stillDeferred = (data.joinDeferred == true)
        if inCombat and (not stillDeferred) then
            local createdAt = tonumber(data.tsCreated) or 0
            local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
            local ageMs = now - createdAt
            local ex, ey, ez = SafeGetPosition(enemyRef)
            local partyMembers = GetPartySnapshot()

            if ageMs >= 30000 and ex and ez and #partyMembers > 0 then
                local dist2D = GetClosestPartyDistance2D(ex, ez, partyMembers)
                local lastDist = tonumber(data._eaPlacementWatchLastDist)
                local lastAt = tonumber(data._eaPlacementWatchLastAt) or 0
                local stalled = dist2D ~= nil and lastDist ~= nil and math.abs(dist2D - lastDist) < 1.0 and (now - lastAt) >= 4500
                local hasLoS = HasLineOfSightToParty(partyMembers)

                data._eaPlacementWatchLastDist = dist2D
                data._eaPlacementWatchLastAt = now
                if dist2D ~= nil and dist2D >= 45.0 and stalled and not hasLoS then
                    data._eaPlacementWatchStalledCount = (tonumber(data._eaPlacementWatchStalledCount) or 0) + 1
                    if data._eaPlacementWatchStalledCount >= 2 then
                        data.distance2D = dist2D
                        EA_RemoveSpawnedEnemyImmediate(enemyRef, "placement_watchdog_distance_stalled")
                        return
                    end
                else
                    data._eaPlacementWatchStalledCount = 0
                end
            end

            if ageMs < 70000 then
                Ext.Timer.WaitFor(5000, function()
                    Check(afterKick == true)
                end)
            end
            return
        end
        if (not inCombat) and stillDeferred then
            local createdAt = tonumber(data.tsCreated) or 0
            local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
            local ageMs = now - createdAt
            if ageMs >= 12000 then
                EA_RemoveSpawnedEnemyImmediate(enemyRef, "DeferredJoinTimeout")
                return
            end
        end
        if (not inCombat) and (not stillDeferred) then
            local createdAt = tonumber(data.tsCreated) or 0
            local now = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
            local ageMs = now - createdAt
            local minWatchMs = 9500
            local graceMs = tonumber(data.preCombatGraceMs) or 0
            if graceMs > 0 then
                minWatchMs = math.max(minWatchMs, graceMs + 2500)
            end
            if data.disableAggressiveAdvance == true then
                minWatchMs = math.max(minWatchMs, 15000)
            end

            if ageMs < minWatchMs then
                Ext.Timer.WaitFor(2500, function()
                    Check(afterKick == true)
                end)
                return
            end

            if not afterKick then
                if playerRef and playerRef ~= "" and Osi.ObjectExists and Osi.ObjectExists(playerRef) == 1 then
                    EA_MakeAmbushHostile(enemyRef, playerRef)
                end
                Ext.Timer.WaitFor(2500, function()
                    Check(true)
                end)
            else
                EA_RemoveSpawnedEnemyImmediate(enemyRef, "NeverEnteredCombat")
            end
        end
    end

    Ext.Timer.WaitFor(7000, function()
        Check(false)
    end)
end

-- SINGLE spawn hostile function
local function EA_SpawnHostileNearPlayer_Prepare(player, durationSeconds, enemyDataOverride, ambushRoll, ambushTheme)
    -- Track spawn attempt
    UpdateMetric("spawnsAttempted")
    local spawnStartTime = Ext.Utils.MonotonicTime()

    -- Validate inputs
    if not player or player == "" then
        print("[EnemyAmbush] ERROR: Invalid player for spawn")
        UpdateMetric("spawnsFailed")
        return
    end

    if not EA_GetSettingBool("MCM_EnableSummons", true) then
        UpdateMetric("spawnsFailed")
        return
    end

    local theme = ambushTheme
    if (not theme or theme == "") and type(ambushRoll) == "table" then
        theme = ambushRoll.ambushTheme
    end
    if not theme or theme == "" then
        theme = (type(GetCurrentAmbushTheme) == "function" and GetCurrentAmbushTheme()) or CurrentAmbushTheme
    end
    local desiredTier = nil
    if type(ambushRoll) == "table" then
        desiredTier = ambushRoll.tier or ambushRoll.category
    end
    local enemyData = enemyDataOverride or PickEnemyTemplate(player, theme, desiredTier)
    if not enemyData then 
        print("[EnemyAmbush] No enemy template available")
        return 
    end

    if not ValidateEnemyData(enemyData) then
        print("[EnemyAmbush] Invalid enemy data selected")
        DebugPrint("Enemy data details:", enemyData.name, enemyData.template, enemyData.level)
        return
    end

    local xpPct = tonumber(EA_GetEffectiveAmbushXPPercent()) or 100
    local xpCloneRecord = nil
    local spawnTemplate = enemyData.template
    if xpPct ~= 100 then
        xpCloneRecord = EA_GetXPCloneRecord(enemyData.template)
        if type(xpCloneRecord) ~= "table"
            or type(xpCloneRecord.cloneTemplate) ~= "string"
            or xpCloneRecord.cloneTemplate == ""
        then
            UpdateMetric("xpCloneSpawnSkippedNoCoverage")
            EA_SetLastError("XPCloneCoverageMissing", "template=" .. tostring(enemyData.template))
            if EA_RecordSpawnFailure then
                EA_RecordSpawnFailure("XPCloneCoverageMissing template=" .. tostring(enemyData.template))
            end
            DebugPrint("XP clone coverage missing for ambusher template:", tostring(enemyData.name or "(unnamed)"), tostring(enemyData.template))
            return
        end
        spawnTemplate = xpCloneRecord.cloneTemplate
    end

    -- Safe position getting
    local x, y, z = SafeGetPosition(player)
    if not x then
        print("[EnemyAmbush] ERROR: Could not get player position")
        return
    end

    -- Decide target level + tier BEFORE spawning (dynamic tiering)
    local playerLevel = GetPartyMaxLevel(player)

    local delta, targetLevel, category, spawnDist
    if ambushRoll and ambushRoll.delta ~= nil then
        delta = tonumber(ambushRoll.delta) or 0
        targetLevel = tonumber(ambushRoll.targetLevel) or math.max(1, math.min((playerLevel or 1) + delta, 20))
        category = ambushRoll.tier or ambushRoll.category or EA_GetTierFromDelta(delta)
        spawnDist = tonumber(ambushRoll.spawnDist)
    end

    if delta == nil then
        delta = EA_RollOverlevelDelta(playerLevel, GetPartySize(player))
        targetLevel = math.max(1, math.min((playerLevel or 1) + delta, 20))
        -- Tier must follow the rolled overlevel delta, not clamped targetLevel.
        -- Otherwise level 20 parties collapse to COMMON-only rolls.
        category = EA_GetTierFromDelta(delta) or EA_GetDynamicCategory(targetLevel, playerLevel)
    end

    spawnDist = spawnDist or EA_GetTierSpawnDistance(category)

    -- Pick a valid spawn position AND spawn there; reject if in LoS (tier-aware)
    local attempts = (EA_IsRobust() and 12) or 8
    local enemy = nil

    return {
        player = player,
        durationSeconds = durationSeconds,
        ambushRoll = ambushRoll,
        ambushTheme = ambushTheme,
        enemyData = enemyData,
        category = category,
        targetLevel = targetLevel,
        playerLevel = playerLevel,
        delta = delta,
        spawnDist = spawnDist,
        x = x, y = y, z = z,
        attempts = attempts,
        spawnStartTime = spawnStartTime,
        xpPct = xpPct,
        xpCloneRecord = xpCloneRecord,
        spawnTemplate = spawnTemplate,
    }
end

local function EA_SpawnHostileNearPlayer_DoCreate(ctx)
    if not ctx then return nil end
    local enemy = nil
    local player = ctx.player
    local x, y, z = ctx.x, ctx.y, ctx.z
    local spawnDist = ctx.spawnDist
    local attempts = ctx.attempts
    local category = ctx.category
    local enemyData = ctx.enemyData
    local spawnTemplate = ctx.spawnTemplate or (enemyData and enemyData.template)
    local minSpawnDistance = math.max(8.0, (tonumber(spawnDist) or 12.0) * 0.60)

    local spawnX, spawnY, spawnZ = nil, nil, nil
    local placementSource = nil
    local forceFindValidPosition = (type(ctx.ambushRoll) == "table" and ctx.ambushRoll.forceFindValidPosition == true)
    local function EA_TryGetPositionViaOsi(entity)
        if not entity or entity == "" then
            return nil, nil, nil
        end
        if not (Osi and type(Osi.GetPosition) == "function") then
            return nil, nil, nil
        end
        local ok, px, py, pz = pcall(Osi.GetPosition, entity)
        if not ok then
            return nil, nil, nil
        end
        px = tonumber(px)
        py = tonumber(py)
        pz = tonumber(pz)
        if px and py and pz then
            return px, py, pz
        end
        return nil, nil, nil
    end
    local placementMode = tostring(EA_GetSpawnPlacementMode() or "CREATE_OOS_ONLY"):upper()
    if placementMode ~= "AUTO" and placementMode ~= "FIND_VALID_ONLY" and placementMode ~= "CREATE_OOS_ONLY" then
        placementMode = "CREATE_OOS_ONLY"
    end
    if forceFindValidPosition then
        placementMode = "FIND_VALID_ONLY"
    end
    local spawnRole = (type(ctx.ambushRoll) == "table" and tostring(ctx.ambushRoll.spawnRole or "")) or ""
    local autoHybridSupport = (placementMode == "AUTO" and (spawnRole == "support" or spawnRole == "champion_retinue") and not forceFindValidPosition)
    local rawAnchorX, rawAnchorY, rawAnchorZ = EA_TryGetPositionViaOsi(player)
    local createOutOfSightAvailable = (Osi and Osi.CreateOutOfSightAtDirection and x and y and z) and true or false
    local createOutOfSightTooCloseRejects = 0
    local createOutOfSightZeroDistanceRejects = 0
    local createOutOfSightHardFailures = 0
    local function EA_IsTooCloseToPlayer(px, pz)
        if (px == nil) or (pz == nil) then
            return false, 0
        end
        local dx = (tonumber(px) or 0) - (tonumber(x) or 0)
        local dz = (tonumber(pz) or 0) - (tonumber(z) or 0)
        local dist2D = math.sqrt((dx * dx) + (dz * dz))
        return dist2D < minSpawnDistance, dist2D
    end

    if EA_GetSettingBool("MCM_DebugMode", false) then
        DebugPrint(string.format(
            "[Spawn] Placement mode=%s forceFindValid=%s supportHybrid=%s",
            placementMode,
            tostring(forceFindValidPosition),
            tostring(autoHybridSupport)
        ))
        if (placementMode ~= "FIND_VALID_ONLY") and Osi and Osi.CreateOutOfSightAtDirection then
            if createOutOfSightAvailable and (not rawAnchorX or not rawAnchorY or not rawAnchorZ) then
                DebugPrint("[Spawn] CreateOutOfSightAtDirection using SafeGetPosition anchor (raw Osi.GetPosition unavailable).")
            elseif not createOutOfSightAvailable then
                DebugPrint("[Spawn] CreateOutOfSightAtDirection unavailable for this spawn: no usable anchor position.")
            end
        end
    end

    local function EA_TryCreateOutOfSightPlacement(afterFindValid)
        if not createOutOfSightAvailable or placementMode == "FIND_VALID_ONLY" then
            return false
        end
        if EA_GetSettingBool("MCM_DebugMode", false) then
            DebugPrint("[Spawn] Trying CreateOutOfSightAtDirection (6 attempts)")
        end
        for attempt = 1, 6 do
            local angleDeg = math.floor(EA_RandFloatCompat() * 360)
            local createDist = math.max(2, math.floor((tonumber(spawnDist) or 12) + (EA_RandFloatCompat() * 3)))
            local ok, guid = pcall(Osi.CreateOutOfSightAtDirection, spawnTemplate, x, y, z, angleDeg, createDist, 0, "")
            if ok and guid and guid ~= "" then
                local ex, ey, ez = SafeGetPosition(guid)
                if not ex then
                    ex, ey, ez = EA_TryGetPositionViaOsi(guid)
                end
                if ex then
                    local heightDelta = math.abs((tonumber(ey) or 0) - (tonumber(y) or 0))
                    local tooClose, closeDist = EA_IsTooCloseToPlayer(ex, ez)
                    local zeroDistanceProbe = tooClose and ((tonumber(closeDist) or 999) <= 0.05)
                    if heightDelta <= EA_MAX_SPAWN_HEIGHT_DELTA and (not tooClose) then
                        enemy = guid
                        spawnX, spawnY, spawnZ = ex, ey, ez
                        placementSource = "create_oos"
                        if EA_GetSettingBool("MCM_DebugMode", false) then
                            DebugPrint(string.format("[Spawn] CreateOutOfSightAtDirection succeeded (attempt %d, dist=%d): %s", attempt, createDist, tostring(guid)))
                        end
                        if EA_RecordSpawnSuccess then EA_RecordSpawnSuccess("SpawnHostileNearPlayer") end
                        break
                    elseif heightDelta <= EA_MAX_SPAWN_HEIGHT_DELTA and (placementMode == "CREATE_OOS_ONLY" or placementMode == "AUTO") and zeroDistanceProbe then
                        enemy = guid
                        spawnX, spawnY, spawnZ = ex, ey, ez
                        placementSource = "create_oos_zero_distance_probe"
                        UpdateMetric("createOutOfSightZeroDistanceAccepted")
                        if EA_GetSettingBool("MCM_DebugMode", false) then
                            DebugPrint(string.format("[Spawn] CreateOutOfSightAtDirection accepted deferred zero-distance probe (attempt %d, dist=%d): %s", attempt, createDist, tostring(guid)))
                        end
                        if EA_RecordSpawnSuccess then EA_RecordSpawnSuccess("SpawnHostileNearPlayer") end
                        break
                    else
                        if EA_GetSettingBool("MCM_DebugMode", false) then
                            if tooClose then
                                DebugPrint(string.format("[Spawn] CreateOutOfSightAtDirection rejected (too close %.2f < %.2f)", closeDist, minSpawnDistance))
                            else
                                DebugPrint(string.format("[Spawn] CreateOutOfSightAtDirection rejected (height delta %.2f > %.2f)", heightDelta, EA_MAX_SPAWN_HEIGHT_DELTA))
                            end
                        end
                        if tooClose then
                            createOutOfSightTooCloseRejects = createOutOfSightTooCloseRejects + 1
                            UpdateMetric("createOutOfSightTooCloseRejected")
                            if (tonumber(closeDist) or 999) <= 0.05 then
                                createOutOfSightZeroDistanceRejects = createOutOfSightZeroDistanceRejects + 1
                                UpdateMetric("createOutOfSightZeroDistanceRejected")
                            end
                            if placementMode == "AUTO"
                                and (createOutOfSightZeroDistanceRejects >= 2 or createOutOfSightTooCloseRejects >= 3) then
                                UpdateMetric("createOutOfSightAutoShortCircuit")
                                if EA_GetSettingBool("MCM_DebugMode", false) then
                                    DebugPrint("[Spawn] AUTO short-circuit: repeated CreateOutOfSight too-close rejects, switching to FindValidPosition for this spawn.")
                                end
                                EA_RequestDeleteWithRetry(guid, "create_oos_probe_reject_short_circuit")
                                break
                            end
                        end
                    end
                else
                    createOutOfSightHardFailures = createOutOfSightHardFailures + 1
                end
                EA_RequestDeleteWithRetry(guid, "create_oos_probe_reject")
            elseif EA_GetSettingBool("MCM_DebugMode", false) and attempt == 1 then
                DebugPrint(string.format("[Spawn] CreateOutOfSightAtDirection failed (attempt %d): ok=%s guid=%s", attempt, tostring(ok), tostring(guid)))
            end
            if not ok or not guid or guid == "" then
                createOutOfSightHardFailures = createOutOfSightHardFailures + 1
            end
        end
        if not enemy and EA_GetSettingBool("MCM_DebugMode", false) then
            if placementMode == "CREATE_OOS_ONLY" then
                DebugPrint("[Spawn] CreateOutOfSightAtDirection exhausted under CREATE_OOS_ONLY.")
            elseif afterFindValid then
                DebugPrint("[Spawn] CreateOutOfSightAtDirection failed after AUTO support hybrid FindValid path.")
            else
                DebugPrint("[Spawn] CreateOutOfSightAtDirection all attempts failed, falling back to FindValidPosition")
            end
        end
        return enemy ~= nil
    end

    local function EA_TryFindValidPlacement()
        if placementMode == "CREATE_OOS_ONLY" then
            return false
        end
        for i = 1, attempts do
            local angle = EA_RandFloatCompat() * math.pi * 2
            local distJitterMax = forceFindValidPosition and 1.2 or 3
            local dist = spawnDist + EA_RandFloatCompat() * distJitterMax

            local rawX = x + math.cos(angle) * dist
            local rawZ = z + math.sin(angle) * dist

            local validX, validY, validZ, posOk = EA_FindValidPositionCompat(rawX, y, rawZ, 2, player)

            if (not posOk) or (not validX) or validX == 0 then
                UpdateMetric("findValidPosFailed")
            end

            local heightDelta = math.abs((tonumber(validY) or tonumber(y) or 0) - (tonumber(y) or 0))
            local badHeight = heightDelta > EA_MAX_SPAWN_HEIGHT_DELTA
            local tooClose, closeDist = EA_IsTooCloseToPlayer(validX, validZ)
            if badHeight then
                if EA_GetSettingBool("MCM_DebugMode", false) then
                    DebugPrint("Rejected spawn candidate (height delta):", string.format("%.2f", heightDelta))
                end
            end
            if tooClose and EA_GetSettingBool("MCM_DebugMode", false) then
                DebugPrint("Rejected spawn candidate (too close):", string.format("%.2f", closeDist), "<", string.format("%.2f", minSpawnDistance))
            end

            if validX and validX ~= 0 and (not badHeight) and (not tooClose) then
                -- Create enemy (SYNC retries) at this candidate position
                local created = nil
                local tries = math.max(1, tonumber(EA_GetSpawnRetryCount and EA_GetSpawnRetryCount() or 1) or 1)

                for attempt = 1, tries do
                    UpdateMetric("createAtAttempts")
                    local ok, guid = pcall(Osi.CreateAt, spawnTemplate, validX, validY, validZ, 1, 1, "")
                    if ok and guid and guid ~= "" then
                        created = guid
                        if Osi.ObjectExists and Osi.ObjectExists(guid) ~= 1 and EA_IsRobust() then
                            EA_LogEvent("SPAWN", "CreateAt returned id before ObjectExists==1 (continuing) id=" .. tostring(guid))
                        end
                        break
                    else
                        UpdateMetric("createAtFailed")
                        if EA_IsRobust() then
                            EA_LogEvent("SPAWN", "CreateAt failed (retry) template=" .. tostring(spawnTemplate))
                        end
                    end
                end

                if created and created ~= "" then
                    local enforce = (category == "ELITE" or category == "LEGENDARY")
                        or (category == "VETERAN" and EA_RandFloatCompat() < 0.5)

                    if enforce and HasLineOfSight and HasLineOfSight(player, created) then
                        UpdateMetric("losRejected")
                        if EA_IsRobust() then
                            EA_LogEvent("SPAWN", "Rejected LoS spawn tier=" .. tostring(category) .. " id=" .. tostring(created))
                        end
                        SafeOsiExec(Osi.RequestDelete, created)
                    else
                        enemy = created
                        spawnX, spawnY, spawnZ = validX, validY, validZ
                        placementSource = "find_valid"
                        if EA_RecordSpawnSuccess then EA_RecordSpawnSuccess("SpawnHostileNearPlayer") end
                        break
                    end
                end
            end
        end
        return enemy ~= nil
    end

    if autoHybridSupport then
        if EA_GetSettingBool("MCM_DebugMode", false) then
            DebugPrint("[Spawn] AUTO support hybrid: trying FindValidPosition before CreateOutOfSightAtDirection.")
        end
        EA_TryFindValidPlacement()
        if not enemy then
            EA_TryCreateOutOfSightPlacement(true)
        end
    else
        EA_TryCreateOutOfSightPlacement(false)
        if not enemy then
            EA_TryFindValidPlacement()
        end
    end

    local allowFinalFindValidFallback = true
    if placementMode == "CREATE_OOS_ONLY" then
        allowFinalFindValidFallback = false
        if EA_GetSettingBool("MCM_DebugMode", false) then
            DebugPrint("[Spawn] CREATE_OOS_ONLY failing without FindValid fallback.")
        end
    end

    if not enemy and allowFinalFindValidFallback then
        -- Final relaxed fallback: still keep this far enough to preserve ambush feel.
        local baseDist = (spawnDist or EA_GetTierSpawnDistance(category))
        local fallbackDist = forceFindValidPosition
            and math.max(4, baseDist * 0.85)
            or math.max(9, baseDist * 0.68)
        local fallbackAngle = EA_RandFloatCompat() * math.pi * 2
        local rawFx = x + math.cos(fallbackAngle) * fallbackDist
        local rawFz = z + math.sin(fallbackAngle) * fallbackDist

        local fx, fy, fz, posOk = EA_FindValidPositionCompat(rawFx, y, rawFz, 4, player)
        if (not posOk) or (not fx) or fx == 0 then
            UpdateMetric("findValidPosFailed")
            if EA_GetSettingBool("MCM_DebugMode", false) then
                DebugPrint("Skipped fallback spawn (FindValidPosition failed)")
            end
            fx, fy, fz = nil, nil, nil
        end

        local fallbackHeightDelta = math.abs((tonumber(fy) or tonumber(y) or 0) - (tonumber(y) or 0))
        local fallbackTooClose, fallbackDist2D = EA_IsTooCloseToPlayer(fx, fz)
        if fx and fallbackHeightDelta <= EA_MAX_SPAWN_HEIGHT_DELTA and (not fallbackTooClose) then
            UpdateMetric("createAtAttempts")
            local ok, created = pcall(Osi.CreateAt, spawnTemplate, fx, fy, fz, 1, 1, "")
            if ok and created and created ~= "" then
                enemy = created
                spawnX, spawnY, spawnZ = fx, fy, fz
                placementSource = "fallback_find_valid"
                if EA_RecordSpawnSuccess then EA_RecordSpawnSuccess("SpawnHostileNearPlayerFallback") end
                if EA_IsRobust() then
                    EA_LogEvent("SPAWN", "Fallback spawn succeeded (LoS-relaxed) template=" .. tostring(spawnTemplate))
                end
            else
                UpdateMetric("createAtFailed")
            end
        else
            if EA_GetSettingBool("MCM_DebugMode", false) then
                if fallbackTooClose then
                    DebugPrint("Skipped fallback spawn (too close):", string.format("%.2f", fallbackDist2D), "<", string.format("%.2f", minSpawnDistance))
                else
                    DebugPrint("Skipped fallback spawn (height delta):", string.format("%.2f", fallbackHeightDelta))
                end
            end
        end
    end

    if not enemy then
        local failureReason = (placementMode == "CREATE_OOS_ONLY") and "oos_spawn_failed" or "spawn_placement_failed"
        UpdateMetric("spawnsFailed")
        UpdateMetric("spawnPlacementFailed")
        if failureReason == "oos_spawn_failed" then
            UpdateMetric("oosSpawnFailed")
        end
        EA_SetLastError("SpawnPlacementFailed", "reason=" .. failureReason .. " template=" .. tostring(spawnTemplate) .. " tier=" .. tostring(category))
        EA_LogEvent("SPAWN_FAIL", "reason=" .. failureReason .. " attempts=" .. tostring(attempts) .. " template=" .. tostring(spawnTemplate))
        if EA_RecordSpawnFailure then EA_RecordSpawnFailure(failureReason .. " template=" .. tostring(spawnTemplate) .. " tier=" .. tostring(category)) end
        DebugPrint("SpawnHostileNearPlayer: Failed to spawn enemy after", attempts, "attempts")
        return nil
    end


    ctx.enemy = enemy
    ctx.spawnX, ctx.spawnY, ctx.spawnZ = spawnX, spawnY, spawnZ
    ctx.placementSource = placementSource or "unknown"
    ctx.placementMode = placementMode
    ctx.spawnAnchorX, ctx.spawnAnchorY, ctx.spawnAnchorZ = x, y, z
    if spawnX and spawnZ and x and z then
        local dx = (tonumber(spawnX) or 0) - (tonumber(x) or 0)
        local dz = (tonumber(spawnZ) or 0) - (tonumber(z) or 0)
        ctx.spawnDistance2D = math.sqrt((dx * dx) + (dz * dz))
    end
    if spawnY and y then
        ctx.spawnHeightDelta = math.abs((tonumber(spawnY) or 0) - (tonumber(y) or 0))
    end
    return ctx
end

local function EA_SpawnHostileNearPlayer_PostConfigure(ctx)
    if not ctx then return nil end
    local enemy = ctx.enemy
    local player = ctx.player
    local durationSeconds = ctx.durationSeconds
    local ambushRoll = ctx.ambushRoll
    local enemyData = ctx.enemyData
    local category = ctx.category
    local targetLevel = ctx.targetLevel
    local playerLevel = ctx.playerLevel
    local delta = ctx.delta
    local spawnStartTime = ctx.spawnStartTime

    -- Sanity
    if not enemy or enemy == '' then
        UpdateMetric('spawnsFailed')
        return nil
    end

    -- Capability-probed: ClearOwnership is optional across runtimes; MakeNPC fallback still detaches summon ownership.
    if Osi.ClearOwnership then
        Osi.ClearOwnership(enemy)
    elseif EA_GetSettingBool("MCM_DebugMode", false) and not EnemyAmbush._eaClearOwnershipMissingLogged then
        EnemyAmbush._eaClearOwnershipMissingLogged = true
        print("[EnemyAmbush][Debug] ClearOwnership unavailable; using MakeNPC fallback only.")
    end

    -- Make sure it's not a summon
    if Osi.MakeNPC then
        Osi.MakeNPC(enemy)
    end

    -- Initial best-effort faction set. Some templates apply internal faction state during post-spawn setup,
    -- so we enforce again right before combat kick.
    if type(EA_ForceAmbusherFaction) == "function" then
        pcall(EA_ForceAmbusherFaction, enemy)
    end

    -- Level scaling BEFORE setting HP (dynamic tiering)
    local enemyBaseLevel = enemyData.level or 1
    local scaledLevel = enemyBaseLevel
    local appliedDurabilityStatus = nil
    local settledHpFinalizeGeneration = 0

    local function EA_FinalizeSettledHp(reason)
        if Osi.ObjectExists and Osi.ObjectExists(enemy) ~= 1 then
            return
        end

        local maxHP = SafeOsiCall(Osi.GetMaxHitpoints, enemy)
        if maxHP and maxHP > 0 then
            SafeOsiExec(Osi.SetHitpoints, enemy, maxHP)
        end

        if EA_GetSettingBool("MCM_DebugMode", false) then
            local currentHP = SafeOsiCall(Osi.GetHitpoints, enemy) or "?"
            local currentMaxHP = SafeOsiCall(Osi.GetMaxHitpoints, enemy) or "?"
            local currentLevel = SafeOsiCall(Osi.GetLevel, enemy) or GetSafeLevel(enemy)
            local currentFaction = (Osi.GetFaction and Osi.GetFaction(enemy)) or "none"
            DebugPrint(string.format(
                "Settled spawn stats: %s: %s (Level %s, HP: %s/%s, Durability: %s, Faction: %s, reason=%s)",
                tostring(enemyData.name or "Unknown"),
                tostring(enemy),
                tostring(currentLevel),
                tostring(currentHP),
                tostring(currentMaxHP),
                tostring(appliedDurabilityStatus or "none"),
                tostring(currentFaction),
                tostring(reason or "unknown")
            ))
        end
    end

    local function EA_ScheduleSettledHpFinalize(delayMs, reason)
        if not (Osi.GetMaxHitpoints and Osi.SetHitpoints) then
            return
        end

        local waitMs = math.max(0, math.floor(tonumber(delayMs) or 0))
        if not (Ext and Ext.Timer and Ext.Timer.WaitFor) then
            EA_FinalizeSettledHp(reason)
            return
        end

        settledHpFinalizeGeneration = settledHpFinalizeGeneration + 1
        local token = settledHpFinalizeGeneration
        Ext.Timer.WaitFor(waitMs, function()
            if token ~= settledHpFinalizeGeneration then
                return
            end
            EA_FinalizeSettledHp(reason)
        end)
    end

    local newLevel = nil
    if Osi.SetLevel then
        local templateLevel = tonumber(SafeOsiCall(Osi.GetLevel, enemy)) or enemyBaseLevel
        newLevel = EA_GetScaledAmbushLevel(
            enemyBaseLevel,
            targetLevel or playerLevel or enemyBaseLevel,
            templateLevel,
            category,
            playerLevel,
            GetPartySize(player)
        )

        local setLevelOk = SafeOsiExec(Osi.SetLevel, enemy, newLevel)
        if (not setLevelOk) and EA_GetSettingBool("MCM_DebugMode", false) then
            DebugPrint("SetLevel failed:", tostring(enemy), "target=", tostring(newLevel))
        end
        scaledLevel = newLevel

        -- Some templates re-assert native level shortly after spawn. Re-apply scaled
        -- level for a few ticks so early-game caps are actually enforced.
        if Ext and Ext.Timer and Ext.Timer.WaitFor and Osi.GetLevel then
            local levelRetryMax = 4
            local levelRetryCount = 0
            local desiredLevel = tonumber(newLevel)
            local stagnantCount = 0
            local lastObservedLevel = nil

            local function EA_EnforceScaledLevelAfterSpawn()
                if not desiredLevel then
                    return
                end
                if Osi.ObjectExists and Osi.ObjectExists(enemy) ~= 1 then
                    return
                end

                local currentLevel = tonumber(SafeOsiCall(Osi.GetLevel, enemy))
                if currentLevel == desiredLevel then
                    EA_ScheduleSettledHpFinalize(160, "level_aligned")
                    return
                end

                if currentLevel ~= nil and currentLevel == lastObservedLevel then
                    stagnantCount = stagnantCount + 1
                else
                    stagnantCount = 0
                    lastObservedLevel = currentLevel
                end

                -- Some templates appear to enforce a runtime level floor.
                -- Stop retrying if repeated attempts observe no movement.
                if stagnantCount >= 2 then
                    if EA_GetSettingBool("MCM_DebugMode", false) then
                        DebugPrint(
                            "Scaled-level enforcement stopped (stagnant):",
                            tostring(enemy),
                            "current=", tostring(currentLevel),
                            "target=", tostring(desiredLevel),
                            "tries=", tostring(levelRetryCount),
                            "/", tostring(levelRetryMax)
                        )
                    end
                    EA_ScheduleSettledHpFinalize(160, "level_stagnant")
                    return
                end

                levelRetryCount = levelRetryCount + 1
                SafeOsiExec(Osi.SetLevel, enemy, desiredLevel)

                if EA_GetSettingBool("MCM_DebugMode", false) then
                    DebugPrint(
                        "Reapplied scaled level:",
                        tostring(enemy),
                        "current=", tostring(currentLevel),
                        "target=", tostring(desiredLevel),
                        "try=", tostring(levelRetryCount),
                        "/", tostring(levelRetryMax)
                    )
                end

                if levelRetryCount < levelRetryMax then
                    Ext.Timer.WaitFor(120, EA_EnforceScaledLevelAfterSpawn)
                else
                    EA_ScheduleSettledHpFinalize(180, "level_retry_limit")
                end
            end

            Ext.Timer.WaitFor(120, EA_EnforceScaledLevelAfterSpawn)
        end

        -- Keep dynamic category based on party/threat roll, not the fixed spawn level.
        if not ambushRoll then
            category = category or EA_GetDynamicCategory(targetLevel or playerLevel, playerLevel)
        end
    end

    if Osi.GetMaxHitpoints and Osi.SetHitpoints then
        local hpNormalizeRetries = 3
        local function EA_NormalizeHpAfterSetLevel()
            if Osi.ObjectExists and Osi.ObjectExists(enemy) ~= 1 then
                return
            end
            local maxHP = SafeOsiCall(Osi.GetMaxHitpoints, enemy)
            if maxHP and maxHP > 0 then
                SafeOsiExec(Osi.SetHitpoints, enemy, maxHP)
                if EA_GetSettingBool("MCM_DebugMode", false) then
                    DebugPrint("Restored HP to max after SetLevel (pre-settle):", maxHP)
                end
                return
            end
            hpNormalizeRetries = hpNormalizeRetries - 1
            if hpNormalizeRetries > 0 and Ext and Ext.Timer and Ext.Timer.WaitFor then
                Ext.Timer.WaitFor(120, EA_NormalizeHpAfterSetLevel)
            end
        end
        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(80, EA_NormalizeHpAfterSetLevel)
        else
            EA_NormalizeHpAfterSetLevel()
        end
    end

    -- Legacy danger aura visuals retained as no-op compatibility hook.
    ApplyDifficultyVisuals(enemy, enemyData, playerLevel)

    local isTieredEnemy = (category == "LEGENDARY" or category == "ELITE" or category == "VETERAN")

    -- Economy: estimate "base XP" for manual AddExplorationExperience payout.
    local rewardCat, rewardCatSource = EA_GetXPRewardCategoryForEntry(enemyData, category)
    local xpBase = EA_CalcKillXP(scaledLevel, rewardCat)
    local xpBaseSource = "fallback_table"
    if rewardCatSource == "powerClass" then
        UpdateMetric("xpCategoryFromPowerClass")
    else
        UpdateMetric("xpCategoryFromTierFallback")
        if EA_GetSettingBool("MCM_DebugMode", false) then
            DebugPrint(
                "XP fallback category used tier mapping:",
                tostring(enemyData.name or "(unnamed)"),
                "powerClass=", tostring(enemyData.powerClass or "(missing)"),
                "tier=", tostring(category),
                "rewardCategory=", tostring(rewardCat)
            )
        end
    end

    -- Economy: XP tuning (only when XP% != 100)
    local xpZeroed = false
    local xpPct = tonumber(ctx.xpPct) or tonumber(EA_GetEffectiveAmbushXPPercent()) or 100
    local xpSuppressMethod = "none"
    local xpSuppressVerified = false
    local xpOriginalTemplate = enemyData.template
    local xpOriginalStat = nil
    local xpOriginalRewardGuid = nil
    local xpCloneTemplate = ctx.spawnTemplate or enemyData.template

    if xpPct ~= 100 then
        if not EA_XP_COMPAT_NOTICE_EMITTED then
            EA_XP_COMPAT_NOTICE_EMITTED = true
            if EA and type(EA) == "table" then
                EA._xpCompatNoticeEmitted = true
            end
            print("[EnemyAmbush] XP compatibility note: non-100% ambush XP uses manual payout and may not follow third-party kill-XP multiplier mods.")
        end
        local xpCloneRecord = ctx.xpCloneRecord
        if type(xpCloneRecord) == "table"
            and type(xpCloneRecord.cloneTemplate) == "string"
            and xpCloneRecord.cloneTemplate ~= ""
            and string.lower(tostring(xpCloneRecord.cloneTemplate)) == string.lower(tostring(xpCloneTemplate))
        then
            xpZeroed = true
            xpSuppressMethod = "clone_template_zero_xp"
            xpSuppressVerified = true
            xpOriginalStat = xpCloneRecord.originalStat
            xpOriginalRewardGuid = xpCloneRecord.originalRewardGuid
            UpdateMetric("xpSuppressVerifiedApplied")
            UpdateMetric("xpSuppressCloneApplied")
        else
            UpdateMetric("xpSuppressFailed")
            UpdateMetric("xpCloneSpawnUnverified")
            DebugPrint("XP clone suppression could not be verified for", tostring(enemy), "originalTemplate=", tostring(xpOriginalTemplate), "spawnTemplate=", tostring(xpCloneTemplate))
        end
    end

    DebugPrint(
        "XP setup:",
        "Enemy=", tostring(enemy),
        "xpPct=", tostring(xpPct),
        "xpBase=", tostring(xpBase),
        "xpBaseSource=", tostring(xpBaseSource),
        "xpRewardCategory=", tostring(rewardCat),
        "xpRewardCategorySource=", tostring(rewardCatSource),
        "xpZeroed=", tostring(xpZeroed),
        "xpSuppressMethod=", tostring(xpSuppressMethod),
        "xpSuppressVerified=", tostring(xpSuppressVerified),
        "xpOriginalTemplate=", tostring(xpOriginalTemplate),
        "xpCloneTemplate=", tostring(xpCloneTemplate)
    )

    -- Spawn VFX and status first (so buffs exist before combat/initiative roll).
    -- Arrival cues are now EffectsDB-routed and chance-gated by tier.
    local arrivalVisualApplied = false
    local cueContext = {
        player = player,
        enemy = enemy,
        creatureType = enemyData.creatureType,
        partyLevel = playerLevel,
        scaledLevel = scaledLevel,
    }
    local arrivalDecision = nil
    local applyArrivalCue = false
    if type(EA_EvaluateArrivalCue) == "function" then
        applyArrivalCue, arrivalDecision = EA_ShouldApplyArrivalCue(category, cueContext)
    else
        applyArrivalCue = EA_ShouldApplyArrivalCue(category, cueContext)
    end
    local arrivalCue = nil
    if applyArrivalCue then
        arrivalCue = EA_SelectArrivalCue(enemyData.creatureType, category, cueContext)
        if type(arrivalCue) == "table" then
            if arrivalCue.fallbackUsed == true then
                UpdateMetric("arrivalCueProfileFallbackUsed")
            end
            local cueStatusApplied = false
            if arrivalCue.statusId and arrivalCue.statusId ~= "" then
                local cueStatusDuration = tonumber(arrivalCue.statusDuration) or 2
                cueStatusApplied = (SafeApplyStatus(enemy, arrivalCue.statusId, cueStatusDuration, 1) == true)
                if cueStatusApplied then
                    UpdateMetric("arrivalCueStatusApplied")
                    arrivalVisualApplied = true
                else
                    UpdateMetric("arrivalCueStatusFailed")
                end
            end
            if not cueStatusApplied then
                local cueVfx = arrivalCue.castEffect or arrivalCue.vfx or arrivalCue.prepareEffect
                if cueVfx and cueVfx ~= "" then
                    PlayVFX_OnEntity(enemy, cueVfx)
                    arrivalVisualApplied = true
                end
            end
            if arrivalCue.sfx and arrivalCue.sfx ~= "" then
                EA_PlaySoundEvent(arrivalCue.sfx, enemy)
            end
            if arrivalCue.bark and arrivalCue.bark ~= "" then
                EA_TryVoiceBark(arrivalCue.bark, enemy)
            end
        end
    end
    if EA_GetSettingBool("MCM_DebugMode", false) and type(arrivalDecision) == "table" then
        local rollText = "n/a"
        if tonumber(arrivalDecision.roll) ~= nil then
            rollText = string.format("%.4f", tonumber(arrivalDecision.roll))
        end
        local profileId = (type(arrivalCue) == "table" and arrivalCue.id) or "nil"
        local fallbackUsed = (type(arrivalCue) == "table" and arrivalCue.fallbackUsed == true)
        DebugPrint(string.format(
            "[ArrivalCue] tier=%s policy=%s stored=%s base=%.2f scaled=%.2f scale=%d%% roll=%s apply=%s profile=%s fallback=%s reason=%s",
            tostring(arrivalDecision.tier or category),
            tostring(arrivalDecision.policy or "BALANCED"),
            tostring(arrivalDecision.storedPolicy or arrivalDecision.policy or "BALANCED"),
            tonumber(arrivalDecision.baseChance) or 0,
            tonumber(arrivalDecision.scaledChance) or 0,
            tonumber(arrivalDecision.chanceScale) or 100,
            rollText,
            tostring(arrivalDecision.apply == true),
            tostring(profileId),
            tostring(fallbackUsed),
            tostring(arrivalDecision.reason or "unknown")
        ))
    end
    if not arrivalVisualApplied then
        PlayVFX_OnEntity(enemy, (enemyData.spawnVFX or EnemyData.DEFAULT_SPAWN_VFX))
    end

    local arrivalInvisibilityApplied = EA_ApplyArrivalInvisibility(enemy, EA_ARRIVAL_INVISIBILITY_DURATION)
    if arrivalInvisibilityApplied then
        EA_ScheduleArrivalInvisibilityFailsafe(enemy, EA_ARRIVAL_INVISIBILITY_FAILSAFE_MS)
    end

    if enemyData.status and enemyData.status ~= "" then
        local s = tostring(enemyData.status)
        local isKnownBadUiStatus = (s == "WILD_MAGIC")

        if not isKnownBadUiStatus then
            SafeApplyStatus(enemy, s, durationSeconds or 600, 1)
        elseif isKnownBadUiStatus then
            DebugPrint("Skipping known UI-broken status:", enemyData.name, s)
        end
    end

    -- Apply ambusher identity + bracket tier + optional traits (new system)
    appliedDurabilityStatus = EA_ApplyTierAndTraits(enemy, player, category, scaledLevel, durationSeconds, ambushRoll)
    EA_ApplyShadowCurseProtection(enemy, player, durationSeconds)
    -- Baseline movement assist now lives under EA_AMBUSHER via MAG_MOMENTUM.

    -- Tier/status applications can change max HP after SetLevel; settle once the
    -- level retry chain has finished instead of relying on a timer-only "final" pass.
    EA_ScheduleSettledHpFinalize(220, "status_applied")

    local spawnRole = (type(ambushRoll) == "table" and tostring(ambushRoll.spawnRole or "")) or ""
    local ambushId = (type(ambushRoll) == "table" and tostring(ambushRoll.ambushId or "")) or ""
    local deferJoinUntilAnchor = (spawnRole == "support" and ambushId ~= "")
    local preCombatGraceMs = 320
    if type(ambushRoll) == "table" and ambushRoll.preCombatGraceMs ~= nil then
        preCombatGraceMs = math.max(0, math.min(60000, math.floor(tonumber(ambushRoll.preCombatGraceMs) or 320)))
    end
    local disableAggressiveAdvance = (type(ambushRoll) == "table" and ambushRoll.disableAggressiveAdvance == true)
    local combatStartBarks = nil
    if type(ambushRoll) == "table" and type(ambushRoll.combatStartBarks) == "table" and #ambushRoll.combatStartBarks > 0 then
        local copied = {}
        for _, barkId in ipairs(ambushRoll.combatStartBarks) do
            if type(barkId) == "string" and barkId ~= "" then
                copied[#copied + 1] = barkId
            end
        end
        if #copied > 0 then
            combatStartBarks = copied
        end
    end
    local combatStartNoFallback = (type(ambushRoll) == "table" and ambushRoll.combatStartNoFallback == true)
    local combatStartSounds = nil
    if type(ambushRoll) == "table" and type(ambushRoll.combatStartSounds) == "table" and #ambushRoll.combatStartSounds > 0 then
        local copiedSounds = {}
        for _, soundId in ipairs(ambushRoll.combatStartSounds) do
            if type(soundId) == "string" and soundId ~= "" then
                copiedSounds[#copiedSounds + 1] = soundId
            end
        end
        if #copiedSounds > 0 then
            combatStartSounds = copiedSounds
        end
    end
    local combatStartSoundAlways = (type(ambushRoll) == "table" and ambushRoll.combatStartSoundAlways == true)
    local suppressCombatStartPresentation = (type(ambushRoll) == "table" and ambushRoll.suppressCombatStartPresentation == true)
    local combatTurnBarks = nil
    if type(ambushRoll) == "table" and type(ambushRoll.combatTurnBarks) == "table" and #ambushRoll.combatTurnBarks > 0 then
        local copiedTurnBarks = {}
        for _, barkId in ipairs(ambushRoll.combatTurnBarks) do
            if type(barkId) == "string" and barkId ~= "" then
                copiedTurnBarks[#copiedTurnBarks + 1] = barkId
            end
        end
        if #copiedTurnBarks > 0 then
            combatTurnBarks = copiedTurnBarks
        end
    end
    local combatTurnSounds = nil
    if type(ambushRoll) == "table" and type(ambushRoll.combatTurnSounds) == "table" and #ambushRoll.combatTurnSounds > 0 then
        local copiedTurnSounds = {}
        for _, soundId in ipairs(ambushRoll.combatTurnSounds) do
            if type(soundId) == "string" and soundId ~= "" then
                copiedTurnSounds[#copiedTurnSounds + 1] = soundId
            end
        end
        if #copiedTurnSounds > 0 then
            combatTurnSounds = copiedTurnSounds
        end
    end
    local combatTurnSoundAlways = (type(ambushRoll) == "table" and ambushRoll.combatTurnSoundAlways == true)
    local combatTurnEnemyOnly = (type(ambushRoll) == "table" and ambushRoll.combatTurnEnemyOnly == true)
    local noEscape = (type(ambushRoll) == "table" and ambushRoll.noEscape == true)
    local combatTurnLimit = nil
    if type(ambushRoll) == "table" and ambushRoll.combatTurnLimit ~= nil then
        local v = math.max(0, math.min(8, math.floor(tonumber(ambushRoll.combatTurnLimit) or 0)))
        if v > 0 then
            combatTurnLimit = v
        end
    end

    local debugMode = EA_GetSettingBool("MCM_DebugMode", false)
    local function EA_EnsureAmbusherFactionForCombat(reason, logPending)
        if type(EA_ForceAmbusherFaction) ~= "function" then
            return
        end
        local okForce, readyNow, desiredFaction, currentFaction = pcall(EA_ForceAmbusherFaction, enemy)
        if not debugMode then
            return
        end
        if okForce and readyNow == true then
            DebugPrint("Precombat faction set:", tostring(enemy), "reason=", tostring(reason), "faction=", tostring(desiredFaction or currentFaction))
        elseif logPending == true then
            DebugPrint("Precombat faction pending:", tostring(enemy), "reason=", tostring(reason), "desired=", tostring(desiredFaction), "current=", tostring(currentFaction))
        end
    end

    -- Flip hostility / force combat AFTER packages are applied.
    -- Supports can defer joining until the ambush anchor has started combat.
    if deferJoinUntilAnchor then
        EA_EnsureAmbusherFactionForCombat("support_deferred", false)
        if Osi.SetOnStage then pcall(Osi.SetOnStage, enemy, 1) end
        if Osi.SetCanFight then pcall(Osi.SetCanFight, enemy, 1) end
        if Osi.SetCanJoinCombat then pcall(Osi.SetCanJoinCombat, enemy, 1) end

        if debugMode then
            DebugPrint("Deferred support join until anchor engages:", tostring(enemy), "ambushId=", tostring(ambushId))
        end

        -- Safety fallback: if anchor never starts combat (edge cases), do not leave supports idle forever.
        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(2200, function()
                if Osi.ObjectExists and Osi.ObjectExists(enemy) == 1 and Osi.ObjectExists(player) == 1 then
                    if Osi.IsInCombat and Osi.IsInCombat(enemy) ~= 1 then
                        local sid = EA_NormalizeUUID(enemy) or enemy
                        local s = EA_Spawned()
                        local sd = s[sid] or s[enemy]
                        if type(sd) == "table" then
                            sd.joinDeferred = nil
                        end
                        if debugMode then
                            DebugPrint("Support join fallback fired:", tostring(enemy), "ambushId=", tostring(ambushId))
                        end
                        EA_RemoveArrivalInvisibility(enemy, "support_fallback")
                        EA_EnsureAmbusherFactionForCombat("support_fallback", true)
                        EA_MakeAmbushHostile(enemy, player)
                    end
                end
            end)
        end
    else
        local function EA_KickCombat(forceEnter)
            if Osi.ObjectExists and (Osi.ObjectExists(enemy) ~= 1 or Osi.ObjectExists(player) ~= 1) then
                return
            end
            if Osi.IsInCombat and Osi.IsInCombat(enemy) == 1 then
                return
            end
            EA_RemoveArrivalInvisibility(enemy, forceEnter and "kick_force" or "kick_grace")
            EA_EnsureAmbusherFactionForCombat(forceEnter and "kick_force" or "kick_grace", forceEnter == true)
            EA_MakeAmbushHostile(enemy, player)
        end

        -- Brief grace so ambushers can visually advance before combat lock-in.
        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(preCombatGraceMs, function()
                EA_KickCombat(false)
            end)
            Ext.Timer.WaitFor(preCombatGraceMs + 300, function()
                EA_KickCombat(true)
            end)
            Ext.Timer.WaitFor(preCombatGraceMs + 900, function()
                EA_KickCombat(true)
            end)
        else
            EA_KickCombat(false)
        end
    end

    -- Optional: log final combat state
    local finalInCombat = Osi.IsInCombat(enemy)
    DebugPrint("Final combat status:", tostring(finalInCombat))

    if EA_GetSettingBool("MCM_DebugMode", false) and Ext and Ext.Timer and Ext.Timer.WaitFor then
        Ext.Timer.WaitFor(preCombatGraceMs + 450, function()
            if Osi.ObjectExists and Osi.ObjectExists(enemy) ~= 1 then
                return
            end
            local f = (Osi.GetFaction and Osi.GetFaction(enemy)) or "none"
            local ic = (Osi.IsInCombat and Osi.IsInCombat(enemy)) or 0
            DebugPrint("Hostility settled:", tostring(enemy), "faction=", tostring(f), "inCombat=", tostring(ic))
        end)
    end

    -- Schedule despawn
    if durationSeconds and durationSeconds > 0 then
        local despawnTimer = string.format("EA_Despawn_%s", enemy)
        local launchMs = math.max(100, math.floor((tonumber(durationSeconds) or 0) * 1000))
        local launched = false
        if SafeOsiExec and Osi and Osi.TimerLaunch then
            launched = (SafeOsiExec(Osi.TimerLaunch, despawnTimer, launchMs) == true)
        elseif Osi and Osi.TimerLaunch then
            local ok = pcall(Osi.TimerLaunch, despawnTimer, launchMs)
            launched = (ok == true)
        end
        if launched then
            DebugPrint("Scheduled despawn:", tostring(enemy), "after", tostring(durationSeconds), "seconds")
        else
            UpdateMetric("despawnTimerLaunchFailed")
            if EA_GetSettingBool("MCM_DebugMode", false) then
                DebugPrint("Failed to schedule despawn timer:", tostring(despawnTimer), "enemy=", tostring(enemy))
            end
        end
    end

    local finalFaction = Osi.GetFaction(enemy) or "none"

    DebugPrint(string.format("Spawned %s: %s (Level %d, Faction: %s)",
        enemyData.name or "Unknown", enemy, GetSafeLevel(enemy),
        finalFaction))

    -- Store this as a spawned enemy for reputation tracking (normalized key)
    local normalizedID = EA_NormalizeUUID(enemy) or enemy
    local spawned = EA_Spawned()
    if type(spawned) == "table" or type(spawned) == "userdata" then
        spawned[normalizedID] = {
            template = xpOriginalTemplate,
            creatureType = enemyData.creatureType,
            name = enemyData.name,
            scriptedScenario = (type(ambushRoll) == "table" and ambushRoll.scriptedScenario) or nil,
            ambushId = (ambushId ~= "" and ambushId or nil),
            spawnRole = (spawnRole ~= "" and spawnRole or nil),
            joinDeferred = (deferJoinUntilAnchor and true or nil),
            preCombatGraceMs = preCombatGraceMs,
            disableAggressiveAdvance = (disableAggressiveAdvance and true or nil),
            forceCombatJoin = (type(ambushRoll) == "table" and ambushRoll.forceCombatJoin == true) or nil,
            noEscape = (noEscape and true or nil),
            noReputation = (type(ambushRoll) == "table" and ambushRoll.noReputation == true) or nil,
            combatStartBarks = combatStartBarks,
            combatStartNoFallback = (combatStartNoFallback and true or nil),
            suppressCombatStartPresentation = (suppressCombatStartPresentation and true or nil),
            combatStartSounds = combatStartSounds,
            combatStartSoundAlways = (combatStartSoundAlways and true or nil),
            combatTurnBarks = combatTurnBarks,
            combatTurnSounds = combatTurnSounds,
            combatTurnSoundAlways = (combatTurnSoundAlways and true or nil),
            combatTurnEnemyOnly = (combatTurnEnemyOnly and true or nil),
            combatTurnLimit = combatTurnLimit,
            anchorPlayer = player,
            arrivalInvisible = (arrivalInvisibilityApplied and true or nil),
            arrivalInvisibleStatus = (arrivalInvisibilityApplied and EA_ARRIVAL_INVISIBILITY_STATUS or nil),

            -- Tiered ambushers are not champions
            isChampion = false,
            isTieredEnemy = isTieredEnemy,

            scaledLevel = scaledLevel,
            xpBase = xpBase,
            xpBaseSource = xpBaseSource,
            xpZeroed = xpZeroed,
            xpPct = xpPct,
            xpSuppressMethod = xpSuppressMethod,
            xpSuppressVerified = (xpSuppressVerified == true),
            xpOriginalTemplate = xpOriginalTemplate,
            xpOriginalStat = xpOriginalStat,
            xpOriginalRewardGuid = xpOriginalRewardGuid,
            tier = category,
            despawnVFX = enemyData.despawnVFX or EnemyData.DEFAULT_DESPAWN_VFX,
            xpRewardCategory = rewardCat,
            spawnTemplate = xpCloneTemplate,
            placementSource = ctx.placementSource,
            placementMode = ctx.placementMode,
            spawnX = ctx.spawnX,
            spawnY = ctx.spawnY,
            spawnZ = ctx.spawnZ,
            spawnAnchorX = ctx.spawnAnchorX,
            spawnAnchorY = ctx.spawnAnchorY,
            spawnAnchorZ = ctx.spawnAnchorZ,
            spawnDistance2D = ctx.spawnDistance2D,
            spawnHeightDelta = ctx.spawnHeightDelta,
            tsCreated = EA_NowMs(),
            lastSeen = EA_NowMs(),
        }

        -- NEW: enforce cap immediately (prevents long-session bloat between validate sweeps)
        EA_EvictOldSpawned(spawned)
    elseif EA_GetSettingBool("MCM_DebugMode", false) then
        DebugPrint("[Spawn] persistent registry unavailable; enemy not tracked:", tostring(normalizedID))
    end

    -- Economy / UX: apply no-loot flags now, clear corpse inventory on death event.
    local disableAmbushLoot = EA_GetEffectiveDisableAmbushLoot()
    if disableAmbushLoot then
        EA_ApplyNoLootFlags(enemy)
    end

    pcall(EA_DiagRecordEncounterSpawn, type(ambushRoll) == "table" and ambushRoll.diagRecordId or nil, {
        ambushId = ambushId,
        enemy = enemy,
        name = enemyData.name,
        creatureType = enemyData.creatureType,
        tier = category,
        powerClass = enemyData.powerClass,
        spawnRole = spawnRole,
        template = xpOriginalTemplate,
        spawnTemplate = xpCloneTemplate,
        scaledLevel = scaledLevel,
        templateLevel = enemyData.level,
        xpPct = xpPct,
        noLoot = disableAmbushLoot == true,
        isChampion = false,
        isRetinue = spawnRole == "champion_retinue",
        placementSource = ctx.placementSource,
        placementMode = ctx.placementMode,
        spawnDistance2D = ctx.spawnDistance2D,
        spawnHeightDelta = ctx.spawnHeightDelta,
    })

    EA_ScheduleSpawnIntegrityWatch(enemy, player)

    if type(spawned) == "table" or type(spawned) == "userdata" then
        EA_Dirty()
        DebugPrint(string.format("Registered spawned enemy: %s (%s)",
        normalizedID, enemyData.creatureType or "Unknown"))
    end

    -- Update performance metrics
        -- ========= FINAL METRICS / RETURN =========
        UpdateMetric("spawnsSuccessful")
        local spawnTime = Ext.Utils.MonotonicTime() - spawnStartTime
        UpdateMetric("totalSpawnTime", spawnTime)

        -- Update average spawn time (ONLY if these fields exist)
        if PerformanceMetrics and PerformanceMetrics.spawnsSuccessful and PerformanceMetrics.spawnsSuccessful > 0 then
            PerformanceMetrics.averageSpawnTime = PerformanceMetrics.totalSpawnTime / PerformanceMetrics.spawnsSuccessful
        end

        return enemy
end

local function SpawnHostileNearPlayer(player, durationSeconds, enemyDataOverride, ambushRoll, ambushTheme)
    local ctx = EA_SpawnHostileNearPlayer_Prepare(player, durationSeconds, enemyDataOverride, ambushRoll, ambushTheme)
    if not ctx then return nil end
    ctx = EA_SpawnHostileNearPlayer_DoCreate(ctx)
    if not ctx then return nil end
    return EA_SpawnHostileNearPlayer_PostConfigure(ctx)
end


    return {
        EA_RemoveSpawnedEnemyImmediate = EA_RemoveSpawnedEnemyImmediate,
        EA_ScheduleSpawnIntegrityWatch = EA_ScheduleSpawnIntegrityWatch,
        EA_SpawnHostileNearPlayer_Prepare = EA_SpawnHostileNearPlayer_Prepare,
        EA_SpawnHostileNearPlayer_DoCreate = EA_SpawnHostileNearPlayer_DoCreate,
        EA_SpawnHostileNearPlayer_PostConfigure = EA_SpawnHostileNearPlayer_PostConfigure,
        SpawnHostileNearPlayer = SpawnHostileNearPlayer,
    }
end
EA.SystemsSpawnPlacement = M
return M

