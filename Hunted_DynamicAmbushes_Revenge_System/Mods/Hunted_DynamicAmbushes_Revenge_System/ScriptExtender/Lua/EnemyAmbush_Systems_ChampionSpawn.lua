EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

function M.Build(deps)
    deps = deps or {}

    local EnemyAmbush = deps.EnemyAmbush or EA
    local EnemyData = deps.EnemyData or {}
    local SystemsDataTables = deps.SystemsDataTables or {}

    local EA_GetPoolActiveSummonList = deps.EA_GetPoolActiveSummonList or function() return {} end
    local GetSafeLevel = deps.GetSafeLevel or function() return 1 end
    local EA_GetSettingBool = deps.EA_GetSettingBool or function(_, fallback) return fallback == true end
    local EA_IsDebugMode = deps.EA_IsDebugMode or function() return false end
    local DebugPrint = deps.DebugPrint or function() end
    local SafeGetPosition = deps.SafeGetPosition or function() return nil, nil, nil end
    local UpdateMetric = deps.UpdateMetric or function() end
    local EA_RandFloatSafe = deps.EA_RandFloatSafe or (EA and EA["EA_RandFloatSafe"])
    local EA_RandIntSafe = deps.EA_RandIntSafe or (EA and EA["EA_RandIntSafe"])
    local EA_RandFloatCompat = deps.EA_RandFloatCompat or function()
        if type(EA_RandFloatSafe) == "function" then
            local ok, out = pcall(EA_RandFloatSafe)
            if ok and tonumber(out) then
                return tonumber(out)
            end
        end
        return 0.5
    end
    local EA_RecordSpawnSuccess = deps.EA_RecordSpawnSuccess or function() end
    local SafeOsiExec = deps.SafeOsiExec or function() return false end
    local EA_IsRobust = deps.EA_IsRobust or function() return false end
    local EA_LogEvent = deps.EA_LogEvent or function() end
    local HasLineOfSight = deps.HasLineOfSight
    local EA_FindValidPositionCompat = deps.EA_FindValidPositionCompat or function() return 0, 0, 0, false end
    local EA_GetSpawnRetryCount = deps.EA_GetSpawnRetryCount or function() return 2 end
    local EA_SetLastError = deps.EA_SetLastError or function() end
    local EA_RecordSpawnFailure = deps.EA_RecordSpawnFailure or function() end
    local EA_StampChampionSpawn = deps.EA_StampChampionSpawn or function() end
    local GetPartyMaxLevel = deps.GetPartyMaxLevel or function() return 1 end
    local SafeOsiCall = deps.SafeOsiCall or function(fn, ...)
        if type(fn) ~= "function" then return nil end
        local ok, out = pcall(fn, ...)
        if ok then return out end
        return nil
    end
    local EA_GetScaledAmbushLevel = deps.EA_GetScaledAmbushLevel or function(_, targetLevel)
        return tonumber(targetLevel) or 1
    end
    local ApplyChampionBuffs = deps.ApplyChampionBuffs or function() end
    local EA_ApplyShadowCurseProtection = deps.EA_ApplyShadowCurseProtection or function() end
    local EA_ApplyChampionTelegraph = deps.EA_ApplyChampionTelegraph or function() end
    local EA_SelectEffectProfile = deps.EA_SelectEffectProfile or function() return nil end
    local EA_ShouldApplyArrivalCue = deps.EA_ShouldApplyArrivalCue or function() return false end
    local EA_SelectArrivalCue = deps.EA_SelectArrivalCue or function() return nil end
    local EA_MakeAmbushHostile = deps.EA_MakeAmbushHostile or function() end
    local SafeApplyStatus = deps.SafeApplyStatus or function() return false end
    local EA_RandIntCompat = deps.EA_RandIntCompat or function(minVal, maxVal)
        if type(EA_RandIntSafe) == "function" then
            local ok, out = pcall(EA_RandIntSafe, minVal, maxVal)
            if ok and tonumber(out) then
                return tonumber(out)
            end
        end
        local lo = math.floor(tonumber(minVal) or 0)
        local hi = math.floor(tonumber(maxVal) or lo)
        if hi < lo then lo, hi = hi, lo end
        if hi <= lo then return lo end
        return lo + math.floor((hi - lo) * 0.5)
    end
    local PlayVFX_OnEntity = deps.PlayVFX_OnEntity or function() end
    local EA_GetXPRewardCategoryForTier = deps.EA_GetXPRewardCategoryForTier or function() return "FODDER" end
    local EA_CalcKillXP = deps.EA_CalcKillXP or function() return 0 end
    local EA_GetEffectiveAmbushXPPercent = deps.EA_GetEffectiveAmbushXPPercent or function() return 100 end
    local EA_GetXPCloneRecord = deps.EA_GetXPCloneRecord
        or (EnemyData and EnemyData.GetXPCloneRecord)
        or (EA and EA["EA_GetXPCloneRecord"])
        or function() return nil end
    local SafeAddBoosts = deps.SafeAddBoosts or function() return false end
    local EA_NormalizeUUID = deps.EA_NormalizeUUID or function(v) return v end
    local EA_Spawned = deps.EA_Spawned or function() return {} end
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local EA_EvictOldSpawned = deps.EA_EvictOldSpawned or function() end
    local EA_GetEffectiveAllowChampionLoot = deps.EA_GetEffectiveAllowChampionLoot or function() return false end
    local EA_ApplyNoLootFlags = deps.EA_ApplyNoLootFlags or function() end
    local EA_Dirty = deps.EA_Dirty or function() end
    local EA_LogChampionDiagnostics = deps.EA_LogChampionDiagnostics or function() end
    local CreatureReputation = deps.CreatureReputation or {}
    local REPUTATION_THRESHOLDS = deps.REPUTATION_THRESHOLDS or {}
    local EA_CanSpawnChampionForType = deps.EA_CanSpawnChampionForType or function() return true end
    local EA_GetVengefulChampionChance = deps.EA_GetVengefulChampionChance
        or EA_GetVengefulChampionChance
        or function() return 0 end
    local EA_BAD_CHAMPION_TEMPLATES = deps.EA_BAD_CHAMPION_TEMPLATES
        or (SystemsDataTables and SystemsDataTables.BAD_CHAMPION_TEMPLATES)
        or {}

    local runtime = {}
    local CHAMPION_FALLBACK_POLICY_DEFAULT = "compat"

    local function EA_NormalizeChampionFallbackPolicy(policy)
        local token = string.lower(tostring(policy or ""))
        if token == "debug-only" then
            token = "debug_only"
        end
        if token ~= "compat" and token ~= "strict" and token ~= "debug_only" then
            token = CHAMPION_FALLBACK_POLICY_DEFAULT
        end
        return token
    end

    local function EA_GetChampionFallbackPolicyOverride()
        local override = EnemyAmbush and EnemyAmbush._eaChampionFallbackPolicyOverride
        if override == nil or override == "" then
            return nil
        end
        return EA_NormalizeChampionFallbackPolicy(override)
    end

    local function EA_SetChampionFallbackPolicyMode(policy)
        local token = string.lower(tostring(policy or ""))
        if token == "" or token == "default" or token == "reset" or token == "clear" then
            EnemyAmbush._eaChampionFallbackPolicyOverride = nil
            return CHAMPION_FALLBACK_POLICY_DEFAULT
        end

        local normalized = EA_NormalizeChampionFallbackPolicy(token)
        EnemyAmbush._eaChampionFallbackPolicyOverride = normalized
        return normalized
    end

    local function EA_GetChampionFallbackPolicyMode()
        return EA_GetChampionFallbackPolicyOverride() or CHAMPION_FALLBACK_POLICY_DEFAULT
    end

    local function EA_IsBadChampionTemplate(template)
        if not template or template == "" then return true end
        return EA_BAD_CHAMPION_TEMPLATES[string.lower(tostring(template))] == true
    end

    local function EA_MakeChampionResolveResult(source, reason, providerId, champion, policy)
        return {
            source = tostring(source or "none"),
            reason = tostring(reason or "unknown"),
            providerId = (providerId ~= nil and providerId ~= "") and tostring(providerId) or nil,
            policy = EA_NormalizeChampionFallbackPolicy(policy or EA_GetChampionFallbackPolicyMode()),
            champion = (type(champion) == "table") and champion or nil,
        }
    end

    local function EA_BumpBoundedCount(bucket, key, maxKeys)
        if type(bucket) ~= "table" then
            return
        end

        key = tostring(key or "")
        if key == "" then
            key = "(none)"
        end

        if type(bucket[key]) == "number" then
            bucket[key] = bucket[key] + 1
            return
        end

        local limit = math.max(1, math.floor(tonumber(maxKeys) or 12))
        local keyCount = 0
        for _ in pairs(bucket) do
            keyCount = keyCount + 1
        end

        if keyCount >= limit then
            bucket["(other)"] = (tonumber(bucket["(other)"]) or 0) + 1
            return
        end

        bucket[key] = 1
    end

    local function EA_CopyFlatCounts(source)
        local out = {}
        if type(source) ~= "table" then
            return out
        end
        for key, value in pairs(source) do
            out[tostring(key)] = tonumber(value) or 0
        end
        return out
    end

    local function EA_CopyRecentResolveEvents(source)
        local out = {}
        if type(source) ~= "table" then
            return out
        end
        for i = 1, #source do
            local event = source[i]
            if type(event) == "table" then
                out[#out + 1] = {
                    index = tonumber(event.index) or 0,
                    ts = tonumber(event.ts) or 0,
                    creatureType = tostring(event.creatureType or ""),
                    source = tostring(event.source or "none"),
                    reason = tostring(event.reason or "unknown"),
                    providerId = event.providerId and tostring(event.providerId) or nil,
                    policy = EA_NormalizeChampionFallbackPolicy(event.policy or CHAMPION_FALLBACK_POLICY_DEFAULT),
                    template = event.template and tostring(event.template) or nil,
                    context = tostring(event.context or "direct_call"),
                    pathKind = tostring(event.pathKind or "forced_or_queued"),
                }
            end
        end
        return out
    end

    local function EA_GetChampionResolveTelemetryStore()
        EnemyAmbush._eaChampionResolveTelemetry = EnemyAmbush._eaChampionResolveTelemetry or {}
        local store = EnemyAmbush._eaChampionResolveTelemetry
        store.total = tonumber(store.total) or 0
        store.bySource = (type(store.bySource) == "table") and store.bySource or {}
        store.byReason = (type(store.byReason) == "table") and store.byReason or {}
        store.byCreatureType = (type(store.byCreatureType) == "table") and store.byCreatureType or {}
        store.byProviderId = (type(store.byProviderId) == "table") and store.byProviderId or {}
        store.byContext = (type(store.byContext) == "table") and store.byContext or {}
        store.byPathKind = (type(store.byPathKind) == "table") and store.byPathKind or {}
        store.byPolicy = (type(store.byPolicy) == "table") and store.byPolicy or {}
        store.recent = (type(store.recent) == "table") and store.recent or {}
        return store
    end

    local function EA_NormalizeChampionResolveContext(context)
        local token = nil
        local pathKind = nil
        if type(context) == "table" then
            token = context.context or context.token or context.label
            pathKind = context.pathKind or context.path or context.kind
        else
            token = context
        end

        token = tostring(token or "direct_call")
        if token == "" then
            token = "direct_call"
        end

        pathKind = tostring(pathKind or "")
        if pathKind == "" then
            if token == "chance_path" then
                pathKind = "ordinary"
            else
                pathKind = "forced_or_queued"
            end
        end

        if pathKind ~= "ordinary" and pathKind ~= "forced_or_queued" then
            pathKind = "forced_or_queued"
        end

        return token, pathKind
    end

    local function EA_IsDebugChampionFallbackContext(contextToken)
        contextToken = string.lower(tostring(contextToken or ""))
        return contextToken:find("^debug_", 1) == 1
    end

    local function EA_EvaluateChampionFallbackPolicy(context)
        local contextToken, pathKind = EA_NormalizeChampionResolveContext(context)
        local policy = EA_GetChampionFallbackPolicyMode()
        local allowFallback = false

        if policy == "compat" then
            allowFallback = true
        elseif policy == "debug_only" then
            allowFallback = EA_IsDebugChampionFallbackContext(contextToken)
        end

        return {
            policy = policy,
            context = contextToken,
            pathKind = pathKind,
            allowFallback = allowFallback,
        }
    end

    local function EA_RecordChampionResolveTelemetry(creatureType, resolution, context)
        local normalized = resolution
        if type(normalized) ~= "table" then
            normalized = EA_MakeChampionResolveResult("none", "invalid_resolution", nil, nil)
        end

        local source = tostring(normalized.source or "none")
        if source ~= "provider" and source ~= "summon_fallback" and source ~= "none" then
            source = "none"
        end

        local reason = tostring(normalized.reason or "unknown")
        local providerId = (normalized.providerId ~= nil and normalized.providerId ~= "")
            and tostring(normalized.providerId)
            or nil
        local policy = EA_NormalizeChampionFallbackPolicy(normalized.policy or CHAMPION_FALLBACK_POLICY_DEFAULT)
        local champion = (type(normalized.champion) == "table") and normalized.champion or nil
        local template = (champion and champion.template and champion.template ~= "")
            and tostring(champion.template)
            or nil
        local contextToken, pathKind = EA_NormalizeChampionResolveContext(context)
        local typeToken = tostring(creatureType or "")
        normalized.policy = policy

        UpdateMetric("championResolveTotal")
        if source == "provider" then
            UpdateMetric("championResolveProvider")
        elseif source == "summon_fallback" then
            UpdateMetric("championResolveSummonFallback")
        else
            UpdateMetric("championResolveNone")
        end

        if pathKind == "ordinary" then
            UpdateMetric("championResolveOrdinary")
        else
            UpdateMetric("championResolveForcedOrQueued")
        end

        local store = EA_GetChampionResolveTelemetryStore()
        store.total = (tonumber(store.total) or 0) + 1
        EA_BumpBoundedCount(store.bySource, source, 8)
        EA_BumpBoundedCount(store.byReason, reason, 16)
        EA_BumpBoundedCount(store.byCreatureType, typeToken, 16)
        EA_BumpBoundedCount(store.byContext, contextToken, 8)
        EA_BumpBoundedCount(store.byPathKind, pathKind, 4)
        EA_BumpBoundedCount(store.byPolicy, policy, 6)
        if providerId then
            EA_BumpBoundedCount(store.byProviderId, providerId, 16)
        end

        store.recent[#store.recent + 1] = {
            index = store.total,
            ts = tonumber(EA_NowMs()) or 0,
            creatureType = typeToken,
            source = source,
            reason = reason,
            providerId = providerId,
            policy = policy,
            template = template,
            context = contextToken,
            pathKind = pathKind,
        }
        while #store.recent > 8 do
            table.remove(store.recent, 1)
        end

        EA_LogChampionDiagnostics(
            "Resolve #%d ctx=%s kind=%s policy=%s type=%s source=%s reason=%s provider=%s template=%s",
            tonumber(store.total) or 0,
            tostring(contextToken),
            tostring(pathKind),
            tostring(policy),
            tostring(typeToken),
            tostring(source),
            tostring(reason),
            tostring(providerId or "n/a"),
            tostring(template or "n/a")
        )

        return normalized
    end

    local function EA_GetChampionResolveTelemetrySnapshot()
        local store = EA_GetChampionResolveTelemetryStore()
        return {
            total = tonumber(store.total) or 0,
            bySource = EA_CopyFlatCounts(store.bySource),
            byReason = EA_CopyFlatCounts(store.byReason),
            byCreatureType = EA_CopyFlatCounts(store.byCreatureType),
            byProviderId = EA_CopyFlatCounts(store.byProviderId),
            byContext = EA_CopyFlatCounts(store.byContext),
            byPathKind = EA_CopyFlatCounts(store.byPathKind),
            byPolicy = EA_CopyFlatCounts(store.byPolicy),
            recent = EA_CopyRecentResolveEvents(store.recent),
        }
    end

    local function EA_WaitForMaxHP(entity, triesLeft, delayMs, onReady)
        triesLeft = triesLeft or 4
        delayMs = delayMs or 80

        local maxhp = SafeOsiCall(Osi.GetMaxHitpoints, entity) or 0
        if maxhp > 0 then
            onReady(maxhp)
            return
        end

        if triesLeft <= 0 then
            DebugPrint("EA_WaitForMaxHP: maxhp never became ready for:", tostring(entity))
            onReady(0)
            return
        end

        Ext.Timer.WaitFor(delayMs, function()
            EA_WaitForMaxHP(entity, triesLeft - 1, delayMs, onReady)
        end)
    end

    local function EA_CopyChampionCandidate(entry, providerId)
        local out = {}
        if type(entry) ~= "table" then
            return out
        end

        for key, value in pairs(entry) do
            out[key] = value
        end

        if providerId and providerId ~= "" then
            out.providerId = tostring(providerId)
        end

        return out
    end

    local function EA_GetChampionPartyLevel(player)
        local partyLevel = tonumber(GetPartyMaxLevel and GetPartyMaxLevel(player) or nil) or 0
        local fallbackLevel = tonumber(GetSafeLevel and GetSafeLevel(player) or nil) or 0
        if fallbackLevel > partyLevel then
            partyLevel = fallbackLevel
        end
        if partyLevel < 1 then
            partyLevel = 1
        end
        return partyLevel
    end

    local function EA_NormalizeChampionLevelGate(value)
        value = tonumber(value)
        if not value then
            return nil
        end
        value = math.floor(value)
        if value < 1 then
            return nil
        end
        return value
    end

    local function EA_IsChampionEntryEligibleForPartyLevel(entry, partyLevel)
        local minPartyLevel = EA_NormalizeChampionLevelGate(entry and entry.minPartyLevel)
        local maxPartyLevel = EA_NormalizeChampionLevelGate(entry and entry.maxPartyLevel)

        if minPartyLevel and maxPartyLevel and maxPartyLevel < minPartyLevel then
            maxPartyLevel = minPartyLevel
        end

        if minPartyLevel and partyLevel < minPartyLevel then
            return false, "below_min_party_level", minPartyLevel, maxPartyLevel
        end
        if maxPartyLevel and partyLevel > maxPartyLevel then
            return false, "above_max_party_level", minPartyLevel, maxPartyLevel
        end

        return true, nil, minPartyLevel, maxPartyLevel
    end

    local function EA_SelectEligibleProviderChampion(creatureType, partyLevel)
        local providerOrder = (EnemyAmbush and EnemyAmbush._championProviderOrder) or {}
        local providers = (EnemyAmbush and EnemyAmbush._championProviders) or {}
        local providerIsActive = EnemyAmbush and EnemyAmbush.IsChampionProviderActive
        local priorities = {}
        local candidatesByPriority = {}
        local sawCandidates = false
        local sawBelowMin = false
        local sawAboveMax = false

        for _, providerId in ipairs(providerOrder) do
            local provider = providers[providerId]
            local isActive = true

            if type(providerIsActive) == "function" then
                isActive = (providerIsActive(providerId) == true)
            end

            if provider and isActive then
                local entrySet = provider.championsByType and provider.championsByType[creatureType]
                local entries = {}

                if type(entrySet) == "table" and entrySet.template then
                    entries = { entrySet }
                elseif type(entrySet) == "table" then
                    entries = entrySet
                end

                if #entries > 0 then
                    sawCandidates = true
                    local priority = tonumber(provider.priority) or 0
                    local bucket = candidatesByPriority[priority]
                    if not bucket then
                        bucket = {}
                        candidatesByPriority[priority] = bucket
                        priorities[#priorities + 1] = priority
                    end

                    for _, entry in ipairs(entries) do
                        if type(entry) == "table" and entry.template and entry.template ~= "" then
                            local eligible, gateReason, minPartyLevel, maxPartyLevel = EA_IsChampionEntryEligibleForPartyLevel(entry, partyLevel)
                            if eligible then
                                bucket[#bucket + 1] = EA_CopyChampionCandidate(entry, providerId)
                            else
                                if gateReason == "below_min_party_level" then
                                    sawBelowMin = true
                                elseif gateReason == "above_max_party_level" then
                                    sawAboveMax = true
                                end

                                if EA_IsDebugMode() then
                                    DebugPrint(
                                        "[Champion] Provider candidate gated:",
                                        tostring(providerId),
                                        tostring(creatureType),
                                        tostring(entry.name or entry.template),
                                        "partyLevel=" .. tostring(partyLevel),
                                        "min=" .. tostring(minPartyLevel or "-"),
                                        "max=" .. tostring(maxPartyLevel or "-"),
                                        "reason=" .. tostring(gateReason)
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end

        if not sawCandidates then
            return nil, nil
        end

        table.sort(priorities, function(a, b)
            return a > b
        end)

        for _, priority in ipairs(priorities) do
            local bucket = candidatesByPriority[priority]
            if type(bucket) == "table" and #bucket > 0 then
                local totalWeight = 0
                for _, candidate in ipairs(bucket) do
                    totalWeight = totalWeight + math.max(tonumber(candidate.weight) or 1, 0)
                end

                if totalWeight <= 0 then
                    return EA_CopyChampionCandidate(bucket[1], bucket[1].providerId), nil
                end

                local roll = EA_RandFloatCompat() * totalWeight
                local acc = 0
                for _, candidate in ipairs(bucket) do
                    acc = acc + math.max(tonumber(candidate.weight) or 1, 0)
                    if roll <= acc then
                        return EA_CopyChampionCandidate(candidate, candidate.providerId), nil
                    end
                end

                return EA_CopyChampionCandidate(bucket[1], bucket[1].providerId), nil
            end
        end

        if sawBelowMin and not sawAboveMax then
            return nil, "provider_below_min_party_level"
        end
        if sawAboveMax and not sawBelowMin then
            return nil, "provider_above_max_party_level"
        end

        return nil, "provider_level_gated"
    end

    local function EA_ResolveChampionSpawnData(player, creatureType, resolveContext)
        local fallbackPolicy = EA_EvaluateChampionFallbackPolicy(resolveContext)
        local effectivePolicy = fallbackPolicy.policy
        local partyLevel = EA_GetChampionPartyLevel(player)
        local champion, providerRejectedReason = EA_SelectEligibleProviderChampion(creatureType, partyLevel)
        local providerId = (type(champion) == "table" and champion.providerId) or nil
        local providerRejected = (providerRejectedReason ~= nil)
        local fallbackCandidateRejected = false
        local usedActiveSummonFallback = false

        if champion and champion.template and champion.template ~= "" then
            champion.vfx = champion.vfx or champion.spawnVFX or EnemyData.DEFAULT_SPAWN_VFX
            champion.level = tonumber(champion.level) or 10
        end

        if champion and EA_IsBadChampionTemplate(champion.template) then
            if EA_IsDebugMode() then
                print(string.format(
                    "[EnemyAmbush][DataAudit] Blacklisted champion template rejected: source=provider type=%s template=%s",
                    tostring(creatureType),
                    tostring(champion.template)
                ))
            end
            champion = nil
            providerRejected = true
            providerRejectedReason = "provider_rejected_bad_template"
        end

        if (not champion) and fallbackPolicy.allowFallback and EA_GetPoolActiveSummonList then
            local desiredLevel = tonumber(GetSafeLevel and GetSafeLevel(player) or nil) or 1
            local best = nil
            local bestScore = -99999
            local targetType = tostring(creatureType or "")
            for _, entry in ipairs(EA_GetPoolActiveSummonList() or {}) do
                if type(entry) == "table"
                    and tostring(entry.creatureType or "") == targetType
                    and entry.template and entry.template ~= ""
                    and entry.championOnly ~= true
                then
                    local entryLevel = tonumber(entry.resolvedTemplateLevel or entry.level) or 1
                    local score = entryLevel - (math.abs(entryLevel - desiredLevel) * 0.2)
                    if score > bestScore then
                        bestScore = score
                        best = entry
                    end
                end
            end

            if best and not EA_IsBadChampionTemplate(best.template) then
                champion = {
                    template = tostring(best.template),
                    name = tostring(best.name or (targetType .. " Champion")),
                    level = tonumber(best.resolvedTemplateLevel or best.level) or desiredLevel,
                    status = "",
                    vfx = best.spawnVFX or EnemyData.DEFAULT_SPAWN_VFX,
                }
                usedActiveSummonFallback = true
            elseif best and EA_IsDebugMode() then
                print(string.format(
                    "[EnemyAmbush][DataAudit] Blacklisted champion template rejected: source=active_summon type=%s template=%s",
                    tostring(creatureType),
                    tostring(best.template)
                ))
                fallbackCandidateRejected = true
            end
        end

        if champion and champion.template and champion.template ~= "" then
            if usedActiveSummonFallback then
                local fallbackReason = providerRejectedReason and (providerRejectedReason .. "_active_summon_fallback") or "active_summon_fallback"
                return EA_MakeChampionResolveResult("summon_fallback", fallbackReason, providerId, champion, effectivePolicy)
            end
            if providerId then
                return EA_MakeChampionResolveResult("provider", "provider_selected", providerId, champion, effectivePolicy)
            end
            return EA_MakeChampionResolveResult("summon_fallback", "active_summon_fallback", nil, champion, effectivePolicy)
        end

        if not fallbackPolicy.allowFallback then
            if providerRejected then
                local reason = providerRejectedReason
                    or ((effectivePolicy == "debug_only")
                        and "provider_rejected_policy_debug_only"
                        or "provider_rejected_policy_strict")
                return EA_MakeChampionResolveResult("none", reason, providerId, nil, effectivePolicy)
            end

            local reason = (effectivePolicy == "debug_only")
                and "policy_debug_only_no_fallback"
                or "policy_strict_no_fallback"
            return EA_MakeChampionResolveResult("none", reason, nil, nil, effectivePolicy)
        end

        if providerRejected then
            return EA_MakeChampionResolveResult("none", providerRejectedReason or "provider_rejected_no_fallback", providerId, nil, effectivePolicy)
        end

        if fallbackCandidateRejected then
            return EA_MakeChampionResolveResult("none", "fallback_candidate_rejected", nil, nil, effectivePolicy)
        end

        return EA_MakeChampionResolveResult("none", "no_champion_match", nil, nil, effectivePolicy)
    end

    local function SpawnChampionNow(player, creatureType, resolved, telemetryContext)
        local resolution = (type(resolved) == "table") and resolved or EA_ResolveChampionSpawnData(player, creatureType, telemetryContext)
        if type(resolution) ~= "table" then
            resolution = EA_MakeChampionResolveResult("none", "invalid_resolution", nil, nil)
        end
        resolution = EA_RecordChampionResolveTelemetry(creatureType, resolution, telemetryContext)
        local champion = resolution.champion
        local fallbackReason = (resolution.source == "summon_fallback") and resolution.reason or nil

        if champion and champion.template and champion.template ~= "" then
            champion.vfx = champion.vfx or champion.spawnVFX or EnemyData.DEFAULT_SPAWN_VFX
            champion.level = tonumber(champion.level) or 10
            if fallbackReason then
                print(string.format(
                    "[EnemyAmbush] Champion fallback engaged (%s): type=%s template=%s",
                    tostring(fallbackReason),
                    tostring(creatureType),
                    tostring(champion.template)
                ))
            end
        end

        if not champion then
            print(string.format(
                "[EnemyAmbush] No champion configuration for type %s (vanillaSummons=%s debugMode=%s)",
                tostring(creatureType),
                tostring(EA_GetSettingBool("MCM_EnableVanillaSummons", true)),
                tostring(EA_GetSettingBool("MCM_DebugMode", false))
            ))
            return false
        end

        local x, y, z = SafeGetPosition(player)
        if not x then
            print("[EnemyAmbush] ERROR: Could not get player position for champion spawn")
            return false
        end

        UpdateMetric("championsAttempted")

        local championXpPct = tonumber(EA_GetEffectiveAmbushXPPercent()) or 100
        local championOriginalTemplate = champion.template
        local championCloneRecord = nil
        local championSpawnTemplate = champion.template
        if championXpPct ~= 100 then
            championCloneRecord = EA_GetXPCloneRecord(champion.template)
            if type(championCloneRecord) ~= "table"
                or type(championCloneRecord.cloneTemplate) ~= "string"
                or championCloneRecord.cloneTemplate == ""
            then
                UpdateMetric("xpCloneChampionSkippedNoCoverage")
                EA_SetLastError("ChampionXPCloneCoverageMissing", "template=" .. tostring(champion.template) .. " type=" .. tostring(creatureType))
                if EA_RecordSpawnFailure then
                    EA_RecordSpawnFailure("ChampionXPCloneCoverageMissing template=" .. tostring(champion.template) .. " type=" .. tostring(creatureType))
                end
                DebugPrint("Champion XP clone coverage missing:", tostring(champion.name or creatureType), tostring(champion.template))
                return false
            end
            championSpawnTemplate = championCloneRecord.cloneTemplate
        end

        local enemy = nil
        local spawnX, spawnY, spawnZ = nil, nil, nil

        if Osi.CreateOutOfSightAtDirection then
            if EA_IsDebugMode() then
                DebugPrint("[Champion] Trying CreateOutOfSightAtDirection (4 attempts)")
            end
            for attempt = 1, 4 do
                local angleDeg = math.floor(EA_RandFloatCompat() * 360)
                local ok, guid = pcall(Osi.CreateOutOfSightAtDirection, championSpawnTemplate, x, y, z, angleDeg, 1, 0, "")
                if ok and guid and guid ~= "" then
                    local sx, sy, sz = SafeGetPosition(guid)
                    if sx then
                        enemy = guid
                        spawnX, spawnY, spawnZ = sx, sy, sz
                        if EA_IsDebugMode() then
                            DebugPrint(string.format("[Champion] CreateOutOfSightAtDirection succeeded (attempt %d): %s", attempt, tostring(guid)))
                        end
                        if EA_RecordSpawnSuccess then EA_RecordSpawnSuccess("ChampionSpawn") end
                        break
                    end
                    SafeOsiExec(Osi.RequestDelete, guid)
                elseif EA_IsDebugMode() and attempt == 1 then
                    DebugPrint(string.format("[Champion] CreateOutOfSightAtDirection failed (attempt %d): ok=%s guid=%s", attempt, tostring(ok), tostring(guid)))
                end
            end
            if not enemy and EA_IsDebugMode() then
                DebugPrint("[Champion] CreateOutOfSightAtDirection all attempts failed, falling back to FindValidPosition")
            end
        end

        local attempts = (EA_IsRobust() and 12) or 8
        local baseDist = 11

        if not enemy then
            for i = 1, attempts do
                local angle = EA_RandFloatCompat() * math.pi * 2
                local dist = baseDist + (EA_RandFloatCompat() * 3.5)

                local rawX = x + math.cos(angle) * dist
                local rawZ = z + math.sin(angle) * dist

                local validX, validY, validZ, posOk = EA_FindValidPositionCompat(rawX, y, rawZ, 2, player)

                if (not posOk) or (not validX) or validX == 0 then
                    UpdateMetric("championFindValidPosFailed")
                end

                if validX and validX ~= 0 then
                    local created = nil
                    local createTries = math.max(1, tonumber(EA_GetSpawnRetryCount and EA_GetSpawnRetryCount() or 2) or 2)

                    for attempt = 1, createTries do
                        UpdateMetric("championCreateAtAttempts")
                        local ok, guid = pcall(Osi.CreateAt, championSpawnTemplate, validX, validY, validZ, 1, 1, "")
                        if ok and guid and guid ~= "" then
                            created = guid
                            if Osi.ObjectExists and Osi.ObjectExists(guid) ~= 1 and EA_IsRobust() then
                                EA_LogEvent("CHAMPION", "CreateAt returned id before ObjectExists==1 (continuing) id=" .. tostring(guid))
                            end
                            break
                        else
                            UpdateMetric("championCreateAtFailed")
                        end
                    end

                    if created and created ~= "" then
                        if HasLineOfSight and (i <= (attempts - 2)) and HasLineOfSight(player, created) then
                            UpdateMetric("championLosRejected")
                            if EA_IsRobust() then
                                EA_LogEvent("CHAMPION", "Rejected LoS spawn id=" .. tostring(created))
                            end
                            SafeOsiExec(Osi.RequestDelete, created)
                        else
                            enemy = created
                            spawnX, spawnY, spawnZ = validX, validY, validZ
                            if EA_RecordSpawnSuccess then EA_RecordSpawnSuccess("ChampionSpawn") end
                            break
                        end
                    end
                end
            end
        end

        if not enemy then
            local fallbackDist = 10
            local fallbackAngle = EA_RandFloatCompat() * math.pi * 2
            local rawFx = x + math.cos(fallbackAngle) * fallbackDist
            local rawFz = z + math.sin(fallbackAngle) * fallbackDist
            local fx, fy, fz, posOk = EA_FindValidPositionCompat(rawFx, y, rawFz, 3, player)
            if posOk and fx and fx ~= 0 then
                UpdateMetric("championCreateAtAttempts")
                local ok, created = pcall(Osi.CreateAt, championSpawnTemplate, fx, fy, fz, 1, 1, "")
                if ok and created and created ~= "" then
                    enemy = created
                    spawnX, spawnY, spawnZ = fx, fy, fz
                    if EA_RecordSpawnSuccess then EA_RecordSpawnSuccess("ChampionSpawnFallback") end
                else
                    UpdateMetric("championCreateAtFailed")
                end
            elseif posOk then
                UpdateMetric("championFindValidPosFailed")
            else
                UpdateMetric("championCreateAtAttempts")
                local ok, created = pcall(Osi.CreateAt, championSpawnTemplate, rawFx, y, rawFz, 1, 1, "")
                if ok and created and created ~= "" then
                    enemy = created
                    spawnX, spawnY, spawnZ = rawFx, y, rawFz
                    if EA_RecordSpawnSuccess then EA_RecordSpawnSuccess("ChampionSpawnRawFallback") end
                else
                    UpdateMetric("championCreateAtFailed")
                end
            end
        end

        if not enemy then
            UpdateMetric("championsFailed")
            EA_SetLastError("ChampionSpawnFailed", "template=" .. tostring(championSpawnTemplate) .. " type=" .. tostring(creatureType))
            EA_LogEvent("CHAMPION_FAIL", "Failed after robust placement template=" .. tostring(championSpawnTemplate))
            if EA_RecordSpawnFailure then
                EA_RecordSpawnFailure("ChampionSpawn template=" .. tostring(championSpawnTemplate) .. " type=" .. tostring(creatureType))
            end
            print(string.format("[EnemyAmbush] Failed to create champion for template %s (after robust placement attempts)", tostring(championSpawnTemplate)))
            return false
        end

        UpdateMetric("championsCreated")
        EA_StampChampionSpawn(creatureType)
        EA_LogEvent("CHAMPION", "Spawned id=" .. tostring(enemy) .. " template=" .. tostring(championSpawnTemplate))

        local playerLevel = GetPartyMaxLevel(player)
        local championTemplateLevel = tonumber(SafeOsiCall(Osi.GetLevel, enemy))
            or tonumber(champion and champion.level)
            or 1
        local championTargetLevel = math.max(
            (tonumber(playerLevel) or 1) + 2,
            tonumber(champion and champion.level) or championTemplateLevel
        )
        local championLevel = EA_GetScaledAmbushLevel(
            tonumber(champion and champion.level) or championTemplateLevel,
            championTargetLevel,
            championTemplateLevel,
            "CHAMPION"
        )
        Osi.SetLevel(enemy, championLevel)

        ApplyChampionBuffs(enemy, creatureType, championLevel)
        EA_ApplyShadowCurseProtection(enemy, player, -1)
        EA_ApplyChampionTelegraph(enemy, creatureType)

        local championHostilityStarted = false
        local function EA_StartChampionHostility()
            if championHostilityStarted then
                return
            end
            championHostilityStarted = true

            EA_MakeAmbushHostile(enemy, player)

            if Ext and Ext.Timer and Ext.Timer.WaitFor then
                Ext.Timer.WaitFor(300, function()
                    if Osi.ObjectExists and Osi.ObjectExists(enemy) == 1 and Osi.ObjectExists(player) == 1 then
                        if Osi.IsInCombat and Osi.IsInCombat(enemy) ~= 1 then
                            EA_MakeAmbushHostile(enemy, player)
                        end
                    end
                end)
                Ext.Timer.WaitFor(900, function()
                    if Osi.ObjectExists and Osi.ObjectExists(enemy) == 1 and Osi.ObjectExists(player) == 1 then
                        if Osi.IsInCombat and Osi.IsInCombat(enemy) ~= 1 then
                            EA_MakeAmbushHostile(enemy, player)
                        end
                    end
                end)
            end
        end

        EA_WaitForMaxHP(enemy, 4, 140, function(maxhp)
            if tonumber(maxhp) and tonumber(maxhp) > 1 then
                SafeOsiExec(Osi.SetHitpoints, enemy, tonumber(maxhp))
                DebugPrint("Champion HP normalized to max:", tostring(maxhp))
            else
                DebugPrint("Champion has low/invalid max HP after scaling:", tostring(champion.template), tostring(maxhp))
            end
            EA_StartChampionHostility()
        end)
        if Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor(750, EA_StartChampionHostility)
        end

        local championCueContext = {
            player = player,
            enemy = enemy,
            isChampion = true,
            creatureType = creatureType,
        }
        local applyChampionCue, championCueDecision = EA_ShouldApplyArrivalCue("CHAMPION", championCueContext)
        local championCue = nil
        local championPayload = {}
        local championCueVfx = nil
        local championCueVisualApplied = false
        if applyChampionCue then
            championCue = EA_SelectArrivalCue(creatureType, "CHAMPION", championCueContext)
            championPayload = (type(championCue) == "table") and championCue or {}
            championCueVfx = championPayload.castEffect or championPayload.vfx or championPayload.prepareEffect
            if championCue.fallbackUsed == true then
                UpdateMetric("arrivalCueProfileFallbackUsed")
            end
            if championPayload.statusId and championPayload.statusId ~= "" then
                local cueStatusDuration = tonumber(championPayload.statusDuration) or 2
                if SafeApplyStatus(enemy, championPayload.statusId, cueStatusDuration, 1) then
                    championCueVisualApplied = true
                    UpdateMetric("arrivalCueStatusApplied")
                else
                    UpdateMetric("arrivalCueStatusFailed")
                end
            end
            if (not championCueVisualApplied) and championCueVfx and championCueVfx ~= "" then
                PlayVFX_OnEntity(enemy, championCueVfx)
                championCueVisualApplied = true
            end
            if championPayload.sfx and championPayload.sfx ~= "" and Osi and Osi.PlaySound then
                SafeOsiExec(Osi.PlaySound, enemy, championPayload.sfx)
            end
        end
        if EA_IsDebugMode() and type(championCueDecision) == "table" then
            local rollText = "n/a"
            if tonumber(championCueDecision.roll) ~= nil then
                rollText = string.format("%.4f", tonumber(championCueDecision.roll))
            end
            local profileId = (type(championCue) == "table" and championCue.id) or "nil"
            local fallbackUsed = (type(championCue) == "table" and championCue.fallbackUsed == true)
            DebugPrint(string.format(
                "[ArrivalCue][Champion] tier=%s policy=%s stored=%s base=%.2f scaled=%.2f scale=%d%% roll=%s apply=%s profile=%s fallback=%s reason=%s",
                tostring(championCueDecision.tier or "CHAMPION"),
                tostring(championCueDecision.policy or "BALANCED"),
                tostring(championCueDecision.storedPolicy or championCueDecision.policy or "BALANCED"),
                tonumber(championCueDecision.baseChance) or 0,
                tonumber(championCueDecision.scaledChance) or 0,
                tonumber(championCueDecision.chanceScale) or 100,
                rollText,
                tostring(championCueDecision.apply == true),
                tostring(profileId),
                tostring(fallbackUsed),
                tostring(championCueDecision.reason or "unknown")
            ))
        end
        if not championCueVisualApplied then
            PlayVFX_OnEntity(enemy, champion.vfx)
        end

        if champion.status and champion.status ~= "" then
            local sid = tostring(champion.status)
            local isKnownBadUiStatus = (sid == "WILD_MAGIC")

            if not isKnownBadUiStatus then
                SafeApplyStatus(enemy, sid, -1, 1)
            else
                DebugPrint("Skipping known UI-broken champion status:", tostring(champion.name or champion.template), sid)
            end
        end

        local championRewardCat = "Boss"
        local championXpBase = EA_CalcKillXP(championLevel, championRewardCat)
        local championXpBaseSource = "fallback_table"
        local championXpZeroed = false
        local championXpSuppressMethod = "none"
        local championXpSuppressVerified = false
        local championXpOriginalStat = nil
        local championXpOriginalRewardGuid = nil

        if championXpPct ~= 100 then
            if type(championCloneRecord) == "table"
                and type(championCloneRecord.cloneTemplate) == "string"
                and championCloneRecord.cloneTemplate ~= ""
                and string.lower(tostring(championCloneRecord.cloneTemplate)) == string.lower(tostring(championSpawnTemplate))
            then
                championXpZeroed = true
                championXpSuppressMethod = "clone_template_zero_xp"
                championXpSuppressVerified = true
                championXpOriginalStat = championCloneRecord.originalStat
                championXpOriginalRewardGuid = championCloneRecord.originalRewardGuid
                UpdateMetric("xpSuppressVerifiedApplied")
                UpdateMetric("xpSuppressCloneApplied")
            else
                UpdateMetric("xpSuppressFailed")
                UpdateMetric("xpCloneSpawnUnverified")
                DebugPrint("Champion XP clone suppression could not be verified:", tostring(enemy), "originalTemplate=", tostring(championOriginalTemplate), "spawnTemplate=", tostring(championSpawnTemplate))
            end
        end

        do
            local normalizedID = EA_NormalizeUUID(enemy) or enemy
            local spawned = EA_Spawned()
            if type(spawned) == "table" or type(spawned) == "userdata" then
                spawned[normalizedID] = {
                    template = championOriginalTemplate,
                    creatureType = creatureType,
                    name = champion.name or "Champion",
                    isChampion = true,
                    isTieredEnemy = false,
                    scaledLevel = championLevel,
                    xpBase = championXpBase,
                    xpBaseSource = championXpBaseSource,
                    xpZeroed = championXpZeroed,
                    xpPct = championXpPct,
                    xpSuppressMethod = championXpSuppressMethod,
                    xpSuppressVerified = (championXpSuppressVerified == true),
                    xpOriginalTemplate = championOriginalTemplate,
                    xpOriginalStat = championXpOriginalStat,
                    xpOriginalRewardGuid = championXpOriginalRewardGuid,
                    tier = "CHAMPION",
                    xpRewardCategory = championRewardCat,
                    spawnTemplate = championSpawnTemplate,
                    tsCreated = EA_NowMs(),
                    lastSeen = EA_NowMs(),
                }

                EA_EvictOldSpawned(spawned)
            elseif EA_DebugEnabled() then
                DebugPrint("Champion spawned without persistent registry:", tostring(normalizedID), tostring(creatureType))
            end

            if not EA_GetEffectiveAllowChampionLoot() then
                EA_ApplyNoLootFlags(enemy)
            end

            if type(spawned) == "table" or type(spawned) == "userdata" then
                EA_Dirty()
                DebugPrint("Registered spawned CHAMPION:", tostring(normalizedID), tostring(creatureType), tostring(championLevel))
            end
        end

        local showChampionPopup = EA_GetSettingBool("MCM_ShowUINotifications", true)
            and EA_GetSettingBool("MCM_ShowChampionArrivalPopup", false)
        if showChampionPopup then
            SafeOsiExec(Osi.OpenMessageBox, player, string.format("%s has come for you.", champion.name))
            SafeOsiExec(Osi.PlaySound, player, "UI_Notification_CombatStarted")
        end

        print(string.format("[EnemyAmbush] Champion arrived: %s (%s reputation, Level %d)", champion.name, creatureType, championLevel))
        return true
    end

    local function SpawnChampionIfNeeded(player, creatureType)
        local reputation = CreatureReputation[creatureType] or 0
        if reputation > REPUTATION_THRESHOLDS.VENGEFUL then
            return false, {
                reason = "rep_not_vengeful",
                reputation = reputation
            }
        end

        if not EA_CanSpawnChampionForType(creatureType) then
            return false, {
                reason = "cooldown",
                reputation = reputation
            }
        end

        local chance = tonumber(EA_GetVengefulChampionChance and EA_GetVengefulChampionChance()) or 0
        chance = math.max(0, math.min(1, chance))
        local roll = EA_RandFloatCompat()

        if roll >= chance then
            return false, {
                reason = "chance_failed",
                reputation = reputation,
                chance = chance,
                roll = roll
            }
        end

        local resolutionContext = {
            context = "chance_path",
            pathKind = "ordinary",
        }
        local resolution = EA_ResolveChampionSpawnData(player, creatureType, resolutionContext)
        local spawned = SpawnChampionNow(player, creatureType, resolution, resolutionContext)
        if spawned then
            return true, {
                reason = "spawned",
                reputation = reputation,
                chance = chance,
                roll = roll,
                source = resolution.source,
                resolveReason = resolution.reason,
                providerId = resolution.providerId,
                policy = resolution.policy,
                champion = resolution.champion,
            }
        end

        return false, {
            reason = "spawn_failed",
            reputation = reputation,
            chance = chance,
            roll = roll,
            source = resolution.source,
            resolveReason = resolution.reason,
            providerId = resolution.providerId,
            policy = resolution.policy,
            champion = resolution.champion,
        }
    end

    runtime.EA_GetChampionFallbackPolicyMode = EA_GetChampionFallbackPolicyMode
    runtime.EA_SetChampionFallbackPolicyMode = EA_SetChampionFallbackPolicyMode
    runtime.EA_ResolveChampionSpawnData = EA_ResolveChampionSpawnData
    runtime.EA_GetChampionResolveTelemetrySnapshot = EA_GetChampionResolveTelemetrySnapshot
    runtime.EA_IsBadChampionTemplate = EA_IsBadChampionTemplate
    runtime.SpawnChampionNow = SpawnChampionNow
    runtime.SpawnChampionIfNeeded = SpawnChampionIfNeeded
    return runtime
end

return M
