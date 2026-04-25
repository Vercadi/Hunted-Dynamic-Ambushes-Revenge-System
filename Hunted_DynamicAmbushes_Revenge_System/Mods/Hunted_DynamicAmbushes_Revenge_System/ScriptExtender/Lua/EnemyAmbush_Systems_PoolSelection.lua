EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local M = {}
function M.Build(deps)
    deps = deps or {}
    local EnemyAmbush = deps.EnemyAmbush or EA
    local EA = deps.EA or EnemyAmbush or {}
    local MCMContract = deps.MCMContract or (Ext.Require("EnemyAmbush_MCMContract.lua") or (EA and EA.MCMContract) or {})
    local Cache = deps.Cache or (EnemyAmbush and EnemyAmbush.Cache) or {}
    local EnemyData = deps.EnemyData or {}
    local SystemsDataTables = deps.SystemsDataTables or {}
    local CreatureReputation = deps.CreatureReputation or {}
    local REPUTATION_THRESHOLDS = deps.REPUTATION_THRESHOLDS or {}
    local DebugPrint = deps.DebugPrint or function() end
    local EA_IsDebugMode = deps.EA_IsDebugMode or function() return false end
    local EA_GetSettingBool = deps.EA_GetSettingBool or function(_, defaultValue) return defaultValue end
    local EA_GetSettingRaw = deps.EA_GetSettingRaw or function(_, defaultValue) return defaultValue end
    local EA_GetEffectiveAmbushXPPercent = deps.EA_GetEffectiveAmbushXPPercent or function() return 100 end
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local GetTableSize = deps.GetTableSize or function(t)
        local n = 0
        for _ in pairs(t or {}) do n = n + 1 end
        return n
    end
    local GetPartyMaxLevel = deps.GetPartyMaxLevel or function() return 1 end
    local GetPartySize = deps.GetPartySize or function() return 1 end
    local GetPointBudget = deps.GetPointBudget or function() return 1 end
    local GetLocationAppropriateEnemies = deps.GetLocationAppropriateEnemies or function() return { "Humanoid", "Beast", "Monstrosity" } end
    local GetRegionalStrengthModifier = deps.GetRegionalStrengthModifier or function() return 1.0 end
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
    local UpdateMetric = deps.UpdateMetric or function() end

    local POOL_OWNER_ID = "Systems_PoolSelection"

    local function EA_NormalizeContractValue(id, value, fallback)
        if MCMContract and type(MCMContract.NormalizeValue) == "function" then
            return MCMContract.NormalizeValue(id, value, fallback)
        end
        return fallback
    end
    local RequestCacheRebuild = deps.RequestCacheRebuild or function() end
    local EA_GetTypePressureSignature = deps.EA_GetTypePressureSignature or (EA and EA["EA_GetTypePressureSignature"])
    local EA_GetTypePressure = deps.EA_GetTypePressure or (EA and EA["EA_GetTypePressure"])
    local EA_GetRecentAmbushTypePenalty = deps.EA_GetRecentAmbushTypePenalty or (EA and EA["EA_GetRecentAmbushTypePenalty"])
    local EA_GetStrictProgressionGates = deps.EA_GetStrictProgressionGates or (EA and EA["EA_GetStrictProgressionGates"])
    local EA_GetBalanceProfile = deps.EA_GetBalanceProfile or (EA and EA["EA_GetBalanceProfile"])
    local EA_GetPresetHiddenBalanceKnobs = deps.EA_GetPresetHiddenBalanceKnobs or (EA and EA["EA_GetPresetHiddenBalanceKnobs"]) or function() return nil end
    local EA_GetRegionForCharacter = deps.EA_GetRegionForCharacter or (EA and EA["EA_GetRegionForCharacter"]) or function() return "unknown" end
    local EA_NormalizeUUID = deps.EA_NormalizeUUID or (EA and EA["EA_NormalizeUUID"]) or function(v) return v end
    local EA_HasXPCloneCoverage = deps.EA_HasXPCloneCoverage
        or (EnemyData and EnemyData.HasXPCloneCoverage)
        or (EA and EA["EA_HasXPCloneCoverage"])
        or function() return false end
local function EA_TemplateVariantKey(templateId, level, status)
    return tostring(templateId or ""):lower()
        .. "|" .. tostring(level or "")
        .. "|" .. string.upper(tostring(status or ""))
end
-- Legacy template lookup mirrors are retired from normal runtime use here.
-- The pool owner keeps them private and exposes owner-backed query helpers.
local TemplateIndex = {}
local TemplateVariants = {}
local TemplateVariantIndex = {}
local function EA_RebuildTemplateLookupsFromList(list)
    TemplateIndex = {}
    TemplateVariants = {}
    TemplateVariantIndex = {}
    for _, entry in ipairs(list or {}) do
        if entry and entry.template and entry.template ~= "" then
            local templateId = tostring(entry.template):lower()
            entry.template = templateId
            if not TemplateIndex[templateId] then
                TemplateIndex[templateId] = entry
            end
            local variants = TemplateVariants[templateId]
            if not variants then
                variants = {}
                TemplateVariants[templateId] = variants
            end
            variants[#variants + 1] = entry
            TemplateVariantIndex[EA_TemplateVariantKey(templateId, entry.level, entry.status)] = entry
        end
    end
end
local function EA_CopyProviderEntry(entry)
    local copy = {}
    for k, v in pairs(entry or {}) do
        copy[k] = v
    end
    return copy
end
local function EA_GetEntryBandPreview(entry)
    if not entry then
        return "COMMON"
    end
    if entry.championOnly == true then
        return "CHAMPION_ONLY"
    end
    local rawBand = entry.spawnBand
    if rawBand ~= nil then
        local band = string.upper(tostring(rawBand))
        if band == "CHAMPION" then
            band = "CHAMPION_ONLY"
        end
        if band == "COMMON" or band == "VETERAN" or band == "ELITE" or band == "LEGENDARY" or band == "CHAMPION_ONLY" then
            return band
        end
    end
    local level = tonumber(entry.level) or 1
    if level >= 11 then return "LEGENDARY" end
    if level >= 8 then return "ELITE" end
    if level >= 5 then return "VETERAN" end
    return "COMMON"
end

-- Retained through 1.0 as the owner-backed internal/debug compatibility query surface.
-- Normal runtime should keep using pool-owner exports and injected Cache deps.
local function BuildActiveSummonList()
    local providerSignalRevision = tonumber(Cache.providerSignalRevision) or 0
    local xpCloneRequired = ((tonumber(EA_GetEffectiveAmbushXPPercent()) or 100) ~= 100)
    if Cache.providerRevision ~= -1 and Cache.providerRevision ~= providerSignalRevision then
        Cache.needsRebuild = true
        Cache.summonList = nil
        Cache.xpCloneRequired = nil
        EA_RebuildTemplateLookupsFromList({})
    elseif Cache.xpCloneRequired ~= nil and Cache.xpCloneRequired ~= xpCloneRequired then
        Cache.needsRebuild = true
        Cache.summonList = nil
        EA_RebuildTemplateLookupsFromList({})
    end
    if Cache.summonList
        and not Cache.needsRebuild
        and Cache.providerRevision == providerSignalRevision
        and Cache.xpCloneRequired == xpCloneRequired
    then
        local hasTemplateIndex = next(TemplateIndex)
        local hasVariantIndex = next(TemplateVariantIndex)
        if not hasTemplateIndex or not hasVariantIndex then
            EA_RebuildTemplateLookupsFromList(Cache.summonList)
        end
        return Cache.summonList
    end
if not EA_GetSettingBool("MCM_EnableSummons", true) then 
    EA_RebuildTemplateLookupsFromList({})
    Cache.summonList = {}
    Cache.providerRevision = providerSignalRevision
    Cache.xpCloneRequired = xpCloneRequired
    Cache.needsRebuild = false
    return Cache.summonList 
end
local active = {}
local skippedNoCloneCoverage = 0
EA_RebuildTemplateLookupsFromList({})
local entries = {}
if EnemyAmbush and EnemyAmbush.GetActiveEnemyEntries then
    entries = EnemyAmbush.GetActiveEnemyEntries()
else
    entries = EnemyData.SummonList_Vanilla or {}
end
local seen = {}
for _, s in ipairs(entries or {}) do
    if s and s.template and s.template ~= "" then
        local copy = EA_CopyProviderEntry(s)
        local t = tostring(copy.template):lower()
        copy.template = t
        if not copy.level then copy.level = 1 end
        if not copy.creatureType then copy.creatureType = "Humanoid" end
        if not copy.spawnVFX then copy.spawnVFX = EnemyData.DEFAULT_SPAWN_VFX end
        if not copy.despawnVFX then copy.despawnVFX = EnemyData.DEFAULT_DESPAWN_VFX end
        local key = EA_TemplateVariantKey(t, copy.level, copy.status)
        if not seen[key] then
            seen[key] = true
            local templateOk = Cache.templateExists[t]
            if templateOk == nil then
                templateOk = true
                if Ext and Ext.Template and Ext.Template.GetRootTemplate then
                    local okT, tmpl = pcall(Ext.Template.GetRootTemplate, t)
                    templateOk = (okT and tmpl ~= nil)
                end
                Cache.templateExists[t] = templateOk
            end
            if not templateOk then
                DebugPrint("Skipping missing template in active pool:", copy.name or "(unnamed)", t)
            end
            if templateOk and xpCloneRequired and not EA_HasXPCloneCoverage(t) then
                skippedNoCloneCoverage = skippedNoCloneCoverage + 1
                UpdateMetric("xpClonePoolSkippedNoCoverage")
                DebugPrint("Skipping XP-clone-unmapped entry in active pool:", copy.name or "(unnamed)", t)
                templateOk = false
            end
            if templateOk then
                if not TemplateIndex[t] then
                    TemplateIndex[t] = copy
                end
                TemplateVariants[t] = TemplateVariants[t] or {}
                table.insert(TemplateVariants[t], copy)
                TemplateVariantIndex[key] = copy
                table.insert(active, copy)
            end
        else
            DebugPrint("Skipping duplicate entry in pool:", key, copy.name or "(unnamed)")
        end
    end
end

Cache.providerRevision = providerSignalRevision
Cache.xpCloneRequired = xpCloneRequired
DebugPrint(string.format(
    "Active summon list built: %d enemies available (xpCloneRequired=%s skippedNoCoverage=%d)",
    #active,
    tostring(xpCloneRequired),
    skippedNoCloneCoverage
))
if EA_IsDebugMode() then
    local counts = {
        COMMON = 0,
        VETERAN = 0,
        ELITE = 0,
        LEGENDARY = 0,
        CHAMPION_ONLY = 0,
    }
    for _, entry in ipairs(active) do
        local band = EA_GetEntryBandPreview(entry)
        counts[band] = (counts[band] or 0) + 1
    end
    DebugPrint(string.format(
        "[Bands] Active pool: COMMON=%d VETERAN=%d ELITE=%d LEGENDARY=%d CHAMPION_ONLY=%d",
        counts.COMMON or 0,
        counts.VETERAN or 0,
        counts.ELITE or 0,
        counts.LEGENDARY or 0,
        counts.CHAMPION_ONLY or 0
    ))
end
Cache.summonList = active
Cache.needsRebuild = false
Cache.generation = (Cache.generation or 0) + 1
return active
end

local function EA_GetPoolOwnerId()
    return POOL_OWNER_ID
end

local function EA_EnsureTemplateLookupsBuilt()
    local hasTemplateIndex = next(TemplateIndex)
    local hasVariantIndex = next(TemplateVariantIndex)
    if not hasTemplateIndex or not hasVariantIndex then
        BuildActiveSummonList()
    end
end

local function EA_GetPoolTemplateEntryById(templateId)
    if not templateId or templateId == "" then
        return nil
    end
    local key = tostring(templateId):lower()
    EA_EnsureTemplateLookupsBuilt()
    local byTemplate = TemplateIndex[key]
    if type(byTemplate) == "table" then
        return byTemplate
    end
    local variants = TemplateVariants[key]
    if type(variants) == "table" then
        return variants[1]
    end
    return nil
end

local function EA_GetPoolTemplateVariantsById(templateId)
    if not templateId or templateId == "" then
        return {}
    end
    local key = tostring(templateId):lower()
    EA_EnsureTemplateLookupsBuilt()
    local variants = TemplateVariants[key]
    if type(variants) == "table" then
        return variants
    end
    return {}
end

local function EA_GetPoolTemplateVariantEntry(templateId, level, status)
    if not templateId or templateId == "" then
        return nil
    end
    local key = tostring(templateId):lower()
    EA_EnsureTemplateLookupsBuilt()
    local entry = TemplateVariantIndex[EA_TemplateVariantKey(key, level, status)]
    if type(entry) == "table" then
        return entry
    end
    return EA_GetPoolTemplateEntryById(key)
end

local function EA_ResetPoolActiveListState()
    Cache.summonList = nil
    EA_RebuildTemplateLookupsFromList({})
end

local function EA_ResetPoolTemplateLookups()
    EA_RebuildTemplateLookupsFromList({})
end

local function EA_MarkPoolNeedsRebuild()
    Cache.needsRebuild = true
end

local function EA_FlushPoolCacheState(hard)
    EA_ResetPoolActiveListState()
    Cache.weighted = {}
    Cache.templateExists = {}
    Cache.order = {}
    Cache.orderHead = 1
    Cache.needsRebuild = true
    if hard then
        Cache.providerRevision = -1
    end
end

local function EA_RequestPoolRebuild(reason, hard, immediate)
    Cache.needsRebuild = true
    if type(RequestCacheRebuild) == "function" then
        return RequestCacheRebuild(reason, hard, immediate)
    end
    if hard then
        EA_FlushPoolCacheState(true)
    else
        EA_ResetPoolActiveListState()
        Cache.needsRebuild = true
    end
    return nil
end

local function EA_NotifyPoolProviderChanged(reason, hard, immediate)
    Cache.providerSignalRevision = (tonumber(Cache.providerSignalRevision) or 0) + 1
    return EA_RequestPoolRebuild(reason or "Provider changed", hard, immediate)
end

local function EA_EvictWeightedCacheToMax(maxSize)
    local size = GetTableSize(Cache.weighted)

    while size > maxSize do
        local item = Cache.order[Cache.orderHead]
        Cache.order[Cache.orderHead] = nil
        Cache.orderHead = Cache.orderHead + 1

        if item then
            local key = item.key
            local ts = item.ts
            local entry = Cache.weighted[key]
            if entry and entry.timestamp == ts then
                Cache.weighted[key] = nil
                size = size - 1
            end
        end

        if Cache.orderHead > 512 and Cache.orderHead > (#Cache.order / 2) then
            local newQ = {}
            for i = Cache.orderHead, #Cache.order do
                newQ[#newQ + 1] = Cache.order[i]
            end
            Cache.order = newQ
            Cache.orderHead = 1
        end
    end
end

EnemyAmbush.HasEnemyProvider = EnemyAmbush.HasEnemyProvider or function(id)
    return EnemyAmbush._providers and EnemyAmbush._providers[id] ~= nil
end
EnemyAmbush.HasChampionProvider = EnemyAmbush.HasChampionProvider or function(id)
    return EnemyAmbush._championProviders and EnemyAmbush._championProviders[id] ~= nil
end
local function EA_P0IncLocal(key)
    local fn = EA and EA["EA_P0Inc"]
    if type(fn) ~= "function" or type(key) ~= "string" or key == "" then
        return 0
    end
    local ok, out = pcall(fn, key)
    if ok and tonumber(out) then
        return tonumber(out)
    end
    return 0
end
local function EA_P0PrimeKeyForSource(source)
    local key = tostring(source or "")
    if key == "entered_level" then
        return "killedBy.templatePrime.enteredLevel"
    elseif key == "entered_combat" then
        return "killedBy.templatePrime.enteredCombat"
    elseif key == "attacked_by" then
        return "killedBy.templatePrime.attackedBy"
    end
    return nil
end
local function EA_NormalizeTemplateId(templateId)
    if templateId == nil then
        return nil
    end
    local s = tostring(templateId)
    if s == "" then
        return nil
    end
    s = string.lower(s)
    local guid = s:match("(%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x)$")
    if guid and guid ~= "" then
        return guid
    end
    return s
end
local function EA_GetLocalCharacterTemplateCache()
    EnemyAmbush._LocalCharacterTemplateCache = EnemyAmbush._LocalCharacterTemplateCache or {}
    return EnemyAmbush._LocalCharacterTemplateCache
end
local function EA_ResetLocalCharacterTemplateCache()
    EnemyAmbush._LocalCharacterTemplateCache = {}
    return EnemyAmbush._LocalCharacterTemplateCache
end
local function EA_GetCharacterEntity(character)
    if not character or character == "" then
        return nil, nil
    end
    if not (Ext and Ext.Entity and Ext.Entity.Get) then
        return nil, EA_NormalizeUUID(character)
    end
    local normalized = EA_NormalizeUUID(character)
    local entityRef = normalized or character
    local okEnt, ent = pcall(Ext.Entity.Get, entityRef)
    if (not okEnt or not ent) and normalized and normalized ~= character then
        okEnt, ent = pcall(Ext.Entity.Get, character)
    end
    if okEnt then
        return ent, normalized
    end
    return nil, normalized
end
local function EA_ReadEntityTemplateInfo(ent)
    if not ent then
        return nil, nil, nil
    end
    local serverCharacter = ent.ServerCharacter
    local template = serverCharacter and serverCharacter.Template
    if not template then
        return nil, nil, nil
    end
    local rootTemplateId = nil
    local localTemplateId = nil
    do
        local okRoot, root = pcall(function()
            return template.RootTemplate
        end)
        if okRoot then
            rootTemplateId = EA_NormalizeTemplateId(root)
        end
    end
    do
        local okLocal, localTemplate = pcall(function()
            return template.Id
        end)
        if okLocal then
            localTemplateId = EA_NormalizeTemplateId(localTemplate)
        end
    end
    if (not rootTemplateId or rootTemplateId == "") and localTemplateId
        and Ext and Ext.Template and Ext.Template.GetRootTemplate then
        local okRoot, root = pcall(Ext.Template.GetRootTemplate, localTemplateId)
        if okRoot and root then
            rootTemplateId = EA_NormalizeTemplateId(root)
        end
        if rootTemplateId and rootTemplateId ~= "" then
            return rootTemplateId, localTemplateId, "liveLocalToRoot"
        end
    end
    if rootTemplateId and rootTemplateId ~= "" then
        return rootTemplateId, localTemplateId, "liveRoot"
    end
    return nil, localTemplateId, nil
end
local function EA_TryResolveTemplateViaOsi(character, normalized)
    if not (Osi and Osi.GetTemplate) then
        return nil
    end
    local templateId = nil
    local entityRef = normalized or character
    local okTemplate, out = pcall(Osi.GetTemplate, entityRef)
    if okTemplate and out and tostring(out) ~= "" then
        templateId = tostring(out)
    end
    if (not templateId or templateId == "") and normalized and normalized ~= character then
        okTemplate, out = pcall(Osi.GetTemplate, character)
        if okTemplate and out and tostring(out) ~= "" then
            templateId = tostring(out)
        end
    end
    return EA_NormalizeTemplateId(templateId)
end
local function EA_RecordLocalCharacterTemplate(character, rootTemplate, localTemplate, source)
    local normalized = EA_NormalizeUUID(character)
    if not normalized or normalized == "" then
        return nil
    end
    local rootTemplateId = EA_NormalizeTemplateId(rootTemplate)
    local localTemplateId = EA_NormalizeTemplateId(localTemplate)
    if (not rootTemplateId or rootTemplateId == "") and (not localTemplateId or localTemplateId == "") then
        return nil
    end
    local cache = EA_GetLocalCharacterTemplateCache()
    local entry = cache[normalized]
    if type(entry) ~= "table" then
        entry = {}
        cache[normalized] = entry
    end
    if rootTemplateId and rootTemplateId ~= "" then
        entry.rootTemplate = rootTemplateId
    end
    if localTemplateId and localTemplateId ~= "" then
        entry.localTemplate = localTemplateId
    end
    if source and source ~= "" then
        entry.source = tostring(source)
    end
    entry.seenAtMs = tonumber(EA_NowMs()) or 0
    return entry
end
local function EA_GetCachedLocalCharacterTemplate(character)
    local normalized = EA_NormalizeUUID(character)
    if not normalized or normalized == "" then
        return nil
    end
    local cache = EA_GetLocalCharacterTemplateCache()
    local entry = cache[normalized]
    if type(entry) ~= "table" then
        return nil
    end
    return entry
end
local function EA_LiveResolveCharacterTemplate(character, allowOsi)
    if not character or character == "" then
        return nil, nil, nil
    end
    local ent, normalized = EA_GetCharacterEntity(character)
    if ent and not ent.ServerCharacter then
        return nil, nil, nil
    end
    local rootTemplateId, localTemplateId, resolveSource = EA_ReadEntityTemplateInfo(ent)
    if rootTemplateId and rootTemplateId ~= "" then
        return rootTemplateId, localTemplateId, resolveSource
    end
    if allowOsi ~= false then
        local osiTemplate = EA_TryResolveTemplateViaOsi(character, normalized)
        if osiTemplate and osiTemplate ~= "" then
            return osiTemplate, localTemplateId, "osi"
        end
    end
    return nil, localTemplateId, nil
end
local function EA_PrimeCharacterTemplateCache(character, source, rootTemplateHint)
    local existing = EA_GetCachedLocalCharacterTemplate(character)
    if type(existing) == "table" and existing.rootTemplate and existing.rootTemplate ~= "" then
        return existing.rootTemplate, existing.localTemplate, existing.source or "cache"
    end

    local ent = nil
    local normalized = EA_NormalizeUUID(character)
    if rootTemplateHint and rootTemplateHint ~= "" then
        ent = select(1, EA_GetCharacterEntity(character))
        local _, localTemplateId = EA_ReadEntityTemplateInfo(ent)
        if ent and ent.ServerCharacter then
            local entry = EA_RecordLocalCharacterTemplate(character, rootTemplateHint, localTemplateId, source or "entered_level")
            if entry and entry.rootTemplate and entry.rootTemplate ~= "" then
                local phase0Key = EA_P0PrimeKeyForSource(source)
                if phase0Key then
                    EA_P0IncLocal(phase0Key)
                end
                return entry.rootTemplate, entry.localTemplate, entry.source
            end
        end
    end

    local rootTemplateId, localTemplateId = EA_LiveResolveCharacterTemplate(character, true)
    if rootTemplateId and rootTemplateId ~= "" then
        local entry = EA_RecordLocalCharacterTemplate(character, rootTemplateId, localTemplateId, source or "live_resolve")
        if entry and entry.rootTemplate and entry.rootTemplate ~= "" then
            local phase0Key = EA_P0PrimeKeyForSource(source)
            if phase0Key then
                EA_P0IncLocal(phase0Key)
            end
            return entry.rootTemplate, entry.localTemplate, entry.source
        end
    elseif normalized and normalized ~= "" and localTemplateId and localTemplateId ~= "" then
        EA_RecordLocalCharacterTemplate(character, nil, localTemplateId, source or "live_resolve")
    end

    return nil, localTemplateId, nil
end
local function EA_GetCharacterTemplate(character, opts)
    if not character or character == "" then
        return nil
    end
    opts = type(opts) == "table" and opts or {}

    local cached = nil
    if opts.preferCache ~= false then
        cached = EA_GetCachedLocalCharacterTemplate(character)
        if type(cached) == "table" and cached.rootTemplate and cached.rootTemplate ~= "" then
            if opts.phase0Track == true then
                EA_P0IncLocal("killedBy.templateCacheHit")
            end
            return cached.rootTemplate, cached.localTemplate, "cache"
        end
    end

    local templateId, localTemplateId, resolveSource = EA_LiveResolveCharacterTemplate(character, opts.allowOsi ~= false)
    if templateId and templateId ~= "" then
        EA_RecordLocalCharacterTemplate(character, templateId, localTemplateId, opts.cacheSource or "live_resolve")
        if opts.phase0Track == true then
            if resolveSource == "liveRoot" then
                EA_P0IncLocal("killedBy.templateResolve.liveRoot")
            elseif resolveSource == "liveLocalToRoot" then
                EA_P0IncLocal("killedBy.templateResolve.liveLocalToRoot")
            elseif resolveSource == "osi" then
                EA_P0IncLocal("killedBy.templateResolve.osi")
            end
        end
        return templateId, localTemplateId, resolveSource
    end

    return nil, localTemplateId, resolveSource
end
local function EA_ResolveCreatureTypeByTemplate(templateId)
    if not templateId or templateId == "" then
        return nil
    end
    local key = tostring(templateId):lower()
    local byTemplate = EA_GetPoolTemplateEntryById(key)
    if type(byTemplate) == "table" and byTemplate.creatureType and byTemplate.creatureType ~= "" then
        return byTemplate.creatureType
    end
    local variants = EA_GetPoolTemplateVariantsById(key)
    if type(variants) == "table" and type(variants[1]) == "table" and variants[1].creatureType and variants[1].creatureType ~= "" then
        return variants[1].creatureType
    end
    return nil
end
local function EA_ResolveCreatureTypeForCharacter(character, opts)
    local templateId = EA_GetCharacterTemplate(character, opts)
    if templateId then
        local creatureType = EA_ResolveCreatureTypeByTemplate(templateId)
        if creatureType and creatureType ~= "" then
            return creatureType, templateId
        end
    end
    return nil, templateId
end
Cache.weighted = Cache.weighted or {}
local CACHE_DURATION = 300000 -- 5 minutes in milliseconds
Cache.templateExists = Cache.templateExists or {}
local function EA_GetReputationSignatureForTypes(appropriateTypes)
    if not EA_GetSettingBool("MCM_EnableReputation", true) then
        return "rep:off"
    end
    if type(appropriateTypes) ~= "table" or #appropriateTypes == 0 then
        return "rep:empty"
    end
    local parts = {}
    for _, ct in ipairs(appropriateTypes) do
        local rep = tonumber((CreatureReputation and CreatureReputation[ct]) or 0) or 0
        local bucket
        if rep >= 0 then
            bucket = math.floor((rep * 10) + 0.5)
        else
            bucket = math.ceil((rep * 10) - 0.5)
        end
        parts[#parts + 1] = string.format("%s:%d", tostring(ct), bucket)
    end
    return table.concat(parts, ",")
end
local function GetCacheKey(player, playerLevel, location, appropriateTypes, themeKey, poolKey)
    local typeStr = table.concat(appropriateTypes or {}, ",")
    local themeStr = themeKey or "all"
    local poolStr = poolKey or "any"
    local repFlag = EA_GetSettingBool("MCM_EnableReputation", true) and 1 or 0
    local repSig = EA_GetReputationSignatureForTypes(appropriateTypes)
    local tpSig = "tp:na"
    if type(EA_GetTypePressureSignature) == "function" then
        tpSig = EA_GetTypePressureSignature(player, appropriateTypes)
    end
    local presetSig = "preset:na"
    do
        local raw = nil
        if type(EA_GetPresetHiddenBalanceKnobs) == "function" then
            local ok, data = pcall(EA_GetPresetHiddenBalanceKnobs)
            if ok and type(data) == "table" then
                raw = data
            end
        end
        local tierBias = string.upper(tostring(raw and raw.tierBias or "COMMON_VETERAN_BASELINE"))
        local fodderEliteBias = string.upper(tostring(raw and raw.fodderEliteBias or "BALANCED"))
        presetSig = string.format("preset:%s/%s", tostring(tierBias), tostring(fodderEliteBias))
    end
    local gen = Cache.generation or 0
    return string.format("%d_%s_%s_%s_t%s_r%d_rs[%s]_ts[%s]_%s_g%d",
        playerLevel, location or "unknown", typeStr, themeStr, poolStr, repFlag, repSig, tpSig, presetSig, gen)
end
local function GetCachedWeightedList(player, themeKey, poolKey)
    local providerSignalRevision = tonumber(Cache.providerSignalRevision) or 0
    if Cache.needsRebuild == true then
        return nil, nil
    end
    if Cache.providerRevision ~= -1 and Cache.providerRevision ~= providerSignalRevision then
        return nil, nil
    end
    local playerLevel = GetPartyMaxLevel(player)
local location = EA_GetRegionForCharacter(player)
local appropriateTypes = GetLocationAppropriateEnemies(player)
local cacheKey = GetCacheKey(player, playerLevel, location, appropriateTypes, themeKey, poolKey)
local cached = Cache.weighted[cacheKey]
if cached and cached.timestamp and CACHE_DURATION then
    local now = EA_NowMs()
    if (now - cached.timestamp) < CACHE_DURATION then
        DebugPrint("Using cached weighted list for key:", cacheKey)
        return cached.list, cached.total
    end
end
return nil, nil
end
local function CacheWeightedList(player, weightedList, total, themeKey, poolKey)
    local playerLevel = GetPartyMaxLevel(player)
    local location = EA_GetRegionForCharacter(player)
    local appropriateTypes = GetLocationAppropriateEnemies(player)
    local cacheKey = GetCacheKey(player, playerLevel, location, appropriateTypes, themeKey, poolKey)
    local now = EA_NowMs()
    local isNewKey = (Cache.weighted[cacheKey] == nil)
    if isNewKey then
        local size = GetTableSize(Cache.weighted)
        if size >= Cache.maxSize then
            EA_EvictWeightedCacheToMax(Cache.maxSize - 1)
        end
    end
    Cache.weighted[cacheKey] = { list = weightedList, total = total, timestamp = now }
    Cache.order[#Cache.order + 1] = { key = cacheKey, ts = now }
    for key, entry in pairs(Cache.weighted) do
        if now - entry.timestamp > CACHE_DURATION then
            Cache.weighted[key] = nil
        end
    end
    EA_EvictWeightedCacheToMax(Cache.maxSize)
    if Cache.orderHead > 512 and Cache.orderHead > (#Cache.order / 2) then
        local newQ = {}
        for i = Cache.orderHead, #Cache.order do
            newQ[#newQ + 1] = Cache.order[i]
        end
        Cache.order = newQ
        Cache.orderHead = 1
    end
end
local CurrentAmbushTheme = nil
local function GetAmbushThemeForEnemy(enemyData)
    if not enemyData then return nil end
    return enemyData.creatureType
end
local EA_THEME_SPILLOVER_RULES = {
    FEY = {
        supportOnly = true,
        minNativeCandidates = 6,
        themes = { "BEAST" },
    },
    PLANT = {
        supportOnly = true,
        minNativeCandidates = 6,
        themes = { "BEAST" },
    },
}
local function EA_NormalizeThemeKey(themeKey)
    if themeKey == nil then
        return nil
    end
    local key = tostring(themeKey)
    if key == "" then
        return nil
    end
    return string.upper(key)
end
local function ThemeAllowsEnemy(themeKey, enemyData)
    if not themeKey or themeKey == "" then return true end
    local creatureType = enemyData.creatureType
    if not creatureType then return false end
    if creatureType == themeKey or string.upper(creatureType) == themeKey then
        return true
    end
    return false
end
local function EA_MakeCandidateVariantKey(enemyData)
    return EA_TemplateVariantKey(
        tostring(enemyData and enemyData.template or ""),
        enemyData and enemyData.level,
        enemyData and enemyData.status
    )
end
local function EA_AddUniqueThemeCandidate(target, seen, enemyData)
    if not enemyData or enemyData.championOnly == true then
        return false
    end
    local key = EA_MakeCandidateVariantKey(enemyData)
    if seen[key] then
        return false
    end
    seen[key] = true
    target[#target + 1] = enemyData
    return true
end
local function EA_GetThemeSpilloverPlan(themeKey, opts)
    local normalizedTheme = EA_NormalizeThemeKey(themeKey)
    if not normalizedTheme then
        return nil
    end
    local rule = EA_THEME_SPILLOVER_RULES[normalizedTheme]
    if type(rule) ~= "table" then
        return nil
    end

    opts = opts or {}
    local roleTag = string.lower(tostring(opts.roleTag or "any"))
    if rule.supportOnly and roleTag ~= "support" then
        return nil
    end

    local nativeCount = tonumber(opts.nativeCount) or 0
    local threshold = math.max(0, math.floor(tonumber(rule.minNativeCandidates) or 0))
    if threshold > 0 and nativeCount >= threshold then
        return nil
    end

    local stages = {}
    local poolStageParts = {}
    for _, rawTheme in ipairs(rule.themes or {}) do
        local spillTheme = EA_NormalizeThemeKey(rawTheme)
        if spillTheme and spillTheme ~= normalizedTheme then
            stages[#stages + 1] = spillTheme
            poolStageParts[#poolStageParts + 1] = string.lower(spillTheme)
        end
    end
    if #stages == 0 then
        return nil
    end

    return {
        sourceTheme = normalizedTheme,
        roleTag = roleTag,
        supportOnly = rule.supportOnly == true,
        nativeCount = nativeCount,
        minNativeCandidates = threshold,
        stages = stages,
        poolKey = string.format(
            "spill_%s_%s_%s",
            string.lower(normalizedTheme),
            roleTag,
            table.concat(poolStageParts, "_")
        ),
    }
end
local function EA_CollectThemeCandidates(fullList, themeKey, opts)
    local candidates = {}
    local seen = {}
    local nativeCount = 0

    for _, enemy in ipairs(fullList or {}) do
        if not enemy.championOnly and ThemeAllowsEnemy(themeKey, enemy) then
            nativeCount = nativeCount + 1
            EA_AddUniqueThemeCandidate(candidates, seen, enemy)
        end
    end

    local spillover = EA_GetThemeSpilloverPlan(themeKey, {
        roleTag = opts and opts.roleTag,
        nativeCount = nativeCount,
    })
    if not spillover then
        return candidates, nil
    end

    local addedTotal = 0
    local stageAdds = {}
    for _, spillTheme in ipairs(spillover.stages or {}) do
        local added = 0
        for _, enemy in ipairs(fullList or {}) do
            if not enemy.championOnly and ThemeAllowsEnemy(spillTheme, enemy) then
                if EA_AddUniqueThemeCandidate(candidates, seen, enemy) then
                    added = added + 1
                    addedTotal = addedTotal + 1
                end
            end
        end
        stageAdds[#stageAdds + 1] = {
            theme = spillTheme,
            added = added,
        }
    end
    if addedTotal <= 0 then
        return candidates, nil
    end

    spillover.stageAdds = stageAdds
    spillover.addedTotal = addedTotal
    spillover.finalCount = #candidates
    return candidates, spillover
end
local function ValidateEnemyData(enemyData)
if not enemyData then 
    DebugPrint("ValidateEnemyData: enemyData is nil")
    return false 
end
if not enemyData.template or enemyData.template == "" then 
    DebugPrint("ValidateEnemyData: Invalid template:", tostring(enemyData.template))
    return false 
end
if not enemyData.name then 
    DebugPrint("ValidateEnemyData: Missing name for template:", enemyData.template)
    return false 
end
if not enemyData.level or enemyData.level <= 0 or enemyData.level > 20 then 
    DebugPrint("ValidateEnemyData: Invalid level:", tostring(enemyData.level))
    return false 
end
if enemyData.spawnBand ~= nil then
    local rawBand = tostring(enemyData.spawnBand or "")
    if rawBand ~= "" then
        local band = string.upper(rawBand)
        if band == "CHAMPION" then
            band = "CHAMPION_ONLY"
        end
        if band ~= "COMMON" and band ~= "VETERAN" and band ~= "ELITE" and band ~= "LEGENDARY" and band ~= "CHAMPION_ONLY" then
            DebugPrint("ValidateEnemyData: Invalid spawnBand:", tostring(enemyData.spawnBand), "template=", tostring(enemyData.template))
            return false
        end
    end
end
if string.find(enemyData.template, "SOME_") then
    DebugPrint("ValidateEnemyData: Placeholder UUID found:", enemyData.template)
    return false
end
if Ext and Ext.Template and Ext.Template.GetRootTemplate then
    local t = enemyData.template
    local exists = Cache.templateExists[t]
    if exists == nil then
        local okT, rootTemplate = pcall(Ext.Template.GetRootTemplate, t)
        exists = (okT and rootTemplate ~= nil)
        Cache.templateExists[t] = exists
    end
    if not exists then
        DebugPrint("ValidateEnemyData: Template not found in game:", t)
        return false
    end
end
return true
end
local EA_HIGH_LEVEL_CHAFF_START = 14
local EA_HIGH_LEVEL_CHAFF_MIN_TEMPLATE_LEVEL = 2
local EA_HIGH_LEVEL_BIAS = 0.65
local EA_WEIGHT_MULTIPLIER_CAP = 12.0
local function EA_IsHighLevelChaffEntry(entry, pl)
    if not entry or entry.championOnly == true then return false end
    local playerLevel = tonumber(pl) or 1
    if playerLevel < EA_HIGH_LEVEL_CHAFF_START then return false end
    local enemyLevel = tonumber(entry.level) or 1
    if enemyLevel > EA_HIGH_LEVEL_CHAFF_MIN_TEMPLATE_LEVEL then return false end
    if playerLevel >= 18 and enemyLevel <= 1 then
        return true
    end
    if playerLevel >= 20 and enemyLevel <= 2 then
        return true
    end
    return false
end
local function EA_GetHighLevelLowTierSuppression(playerLevel, enemyLevel)
    local pl = tonumber(playerLevel) or 1
    local el = tonumber(enemyLevel) or 1
    if pl < 8 then
        return 1.0
    end
    local levelGap = pl - el
    if levelGap <= 4 then
        return 1.0
    end
    local mul
    if levelGap <= 6 then
        mul = 0.72
    elseif levelGap <= 8 then
        mul = 0.45
    elseif levelGap <= 10 then
        mul = 0.24
    else
        mul = 0.12
    end
    if pl >= 16 and el <= 2 then
        mul = math.min(mul, 0.09)
    end
    if pl >= 18 and el <= 1 then
        mul = math.min(mul, 0.05)
    end
    return mul
end
local EA_ENTRY_BAND_ORDER = (SystemsDataTables and SystemsDataTables.ENTRY_BAND_ORDER) or {
    COMMON = 1,
    VETERAN = 2,
    ELITE = 3,
    LEGENDARY = 4,
    CHAMPION = 5,
    CHAMPION_ONLY = 5,
}
local function EA_NormalizeEntryBand(band)
    local key = string.upper(tostring(band or ""))
    if not EA_ENTRY_BAND_ORDER[key] then
        return nil
    end
    if key == "CHAMPION" then
        return "CHAMPION_ONLY"
    end
    return key
end
local function EA_GetEntrySpawnBand(entry)
    if not entry then return "COMMON" end
    if entry.championOnly == true then return "CHAMPION_ONLY" end
    local explicit = EA_NormalizeEntryBand(entry.spawnBand)
    if explicit then
        return explicit
    end
    local levelOverride =
        tonumber(entry.levelOverride)
        or tonumber(entry.templateLevelOverride)
        or tonumber(entry.LevelOverride)
    local enemyLevel = tonumber(entry.level) or 1
    local bandLevel = (levelOverride and levelOverride >= 1) and levelOverride or enemyLevel
    if bandLevel >= 11 then return "LEGENDARY" end
    if bandLevel >= 8 then return "ELITE" end
    if bandLevel >= 5 then return "VETERAN" end
    return "COMMON"
end
local function EA_GetTierPoolStages(spawnTier)
    local tier = EA_NormalizeEntryBand(spawnTier) or "COMMON"
    if tier == "COMMON" then
        return {
            { COMMON = true }
        }, "common"
    end
    if tier == "VETERAN" or tier == "ELITE" then
        return {
            { COMMON = true, VETERAN = true, ELITE = true }
        }, "shared_cve"
    end
    if tier == "LEGENDARY" then
        return {
            { LEGENDARY = true },
            { VETERAN = true, ELITE = true },
        }, "legendary"
    end
    return {
        { COMMON = true }
    }, "common"
end
local function EA_IsAllowedBandForRequestedTier(band, requestedTier)
    local req = EA_NormalizeEntryBand(requestedTier) or "COMMON"
    local b = EA_NormalizeEntryBand(band) or "COMMON"
    if req == "COMMON" then
        return b == "COMMON"
    end
    if req == "VETERAN" or req == "ELITE" then
        return b == "COMMON" or b == "VETERAN" or b == "ELITE"
    end
    return true
end
local function EA_GetRequestedTierBandLabel(requestedTier)
    local req = EA_NormalizeEntryBand(requestedTier) or "COMMON"
    if req == "COMMON" then
        return "COMMON"
    end
    if req == "VETERAN" or req == "ELITE" then
        return "COMMON+VETERAN+ELITE"
    end
    if req == "LEGENDARY" then
        return "LEGENDARY+VETERAN+ELITE"
    end
    return "ANY"
end
local function EA_GetEntryPowerClass(entry)
    local raw = entry and entry.powerClass
    if raw ~= nil then
        local key = string.upper(tostring(raw))
        if key == "FODDER" or key == "STANDARD" or key == "BRUISER" or key == "DREAD" or key == "APEX" then
            return key
        end
    end
    local lvl = tonumber(entry and (
        entry.resolvedTemplateLevel
        or entry.levelOverride
        or entry.templateLevelOverride
        or entry.level
    )) or 1
    if lvl >= 12 then return "APEX" end
    if lvl >= 9 then return "DREAD" end
    if lvl >= 6 then return "BRUISER" end
    if lvl >= 3 then return "STANDARD" end
    return "FODDER"
end
local function EA_GetPowerClassPreferenceStages(requestedTier)
    local req = EA_NormalizeEntryBand(requestedTier)
    local allClasses = { FODDER = true, STANDARD = true, BRUISER = true, DREAD = true, APEX = true }
    if req == "COMMON" then
        return {
            { FODDER = true, STANDARD = true },
            allClasses,
        }, "fs"
    end
    if req == "VETERAN" then
        return {
            { STANDARD = true, BRUISER = true },
            allClasses,
        }, "sb"
    end
    if req == "ELITE" then
        return {
            { BRUISER = true, DREAD = true },
            allClasses,
        }, "bd"
    end
    if req == "LEGENDARY" then
        return {
            { DREAD = true, APEX = true },
            allClasses,
        }, "da"
    end
    return nil, nil
end
local function PickEnemyTemplate(player, themeKey, spawnTier, opts)
opts = opts or {}
local fullList = BuildActiveSummonList()
if #fullList == 0 then return nil end
local candidates, spilloverInfo = EA_CollectThemeCandidates(fullList, themeKey, opts)
if #candidates == 0 then
    candidates = fullList
    spilloverInfo = nil
end
local poolKey = (spilloverInfo and spilloverInfo.poolKey) or "any"
local requestedTier = EA_NormalizeEntryBand(spawnTier)
if spawnTier ~= nil then
    local stages, profile = EA_GetTierPoolStages(spawnTier)
    local chosen = nil
    local stageIndex = nil
    for idx, stageBands in ipairs(stages) do
        local stageCandidates = {}
        for _, enemy in ipairs(candidates) do
            local band = EA_GetEntrySpawnBand(enemy)
            if stageBands[band] then
                table.insert(stageCandidates, enemy)
            end
        end
        if #stageCandidates > 0 then
            chosen = stageCandidates
            stageIndex = idx
            break
        end
    end
    if chosen and #chosen > 0 then
        candidates = chosen
        poolKey = string.format("%s_s%d", profile or "any", stageIndex or 1)
        if stageIndex and stageIndex > 1 then
            DebugPrint(string.format("Tier pool fallback applied: tier=%s stage=%d candidates=%d",
                tostring(spawnTier), stageIndex, #candidates))
        end
    else
        poolKey = "any"
        DebugPrint(string.format("Tier pool had no matches: tier=%s (using themed candidates)", tostring(spawnTier)))
    end
end
local tierLockRejected = 0
if requestedTier == "COMMON" or requestedTier == "VETERAN" or requestedTier == "ELITE" then
    local strictBand = {}
    for _, enemy in ipairs(candidates) do
        local band = EA_GetEntrySpawnBand(enemy)
        if EA_IsAllowedBandForRequestedTier(band, requestedTier) then
            table.insert(strictBand, enemy)
        else
            tierLockRejected = tierLockRejected + 1
        end
    end
    if #strictBand == 0 then
        for _, enemy in ipairs(fullList) do
            if not enemy.championOnly then
                local band = EA_GetEntrySpawnBand(enemy)
                if EA_IsAllowedBandForRequestedTier(band, requestedTier) then
                    table.insert(strictBand, enemy)
                end
            end
        end
        if #strictBand > 0 then
            local lockLabel = EA_GetRequestedTierBandLabel(requestedTier)
            DebugPrint(string.format(
                "Tier band fallback applied: no themed %s candidates in allowed bands; using global %s pool (%d)",
                tostring(requestedTier), lockLabel, #strictBand))
            poolKey = (requestedTier == "COMMON") and "band_common" or "band_cve"
        end
    end
    if #strictBand == 0 then
        local lockLabel = EA_GetRequestedTierBandLabel(requestedTier)
        DebugPrint(string.format("Tier band gate: no %s candidates available for tier=%s", lockLabel, tostring(requestedTier)))
        return nil
    end
    candidates = strictBand
end
local playerLevel = GetPartyMaxLevel(player)
local partySizeForWeight = GetPartySize(player)
local veteranOnlyLockActive = false
local function EA_GetEarlyTemplateLevelCap(pl, ps)
    local level = tonumber(pl) or 1
    if level <= 1 then
        return 2
    end
    if level == 2 then
        return 3
    end
    if level == 3 then
        return 4
    end
    if level == 4 then
        return 5
    end
    return nil
end
local earlyTemplateLevelCap = EA_GetEarlyTemplateLevelCap(playerLevel, partySizeForWeight)
if earlyTemplateLevelCap then
    local cappedCandidates = {}
    local rejectedByTemplateLevel = 0
    for _, enemy in ipairs(candidates) do
        local templateLevel = tonumber(enemy and (
            enemy.resolvedTemplateLevel
            or enemy.levelOverride
            or enemy.templateLevelOverride
            or enemy.level
        )) or 1
        if templateLevel <= earlyTemplateLevelCap then
            table.insert(cappedCandidates, enemy)
        else
            rejectedByTemplateLevel = rejectedByTemplateLevel + 1
        end
    end
    if #cappedCandidates == 0 then
        if EA_IsDebugMode() then
            DebugPrint(string.format(
                "[LowLevelGate] template ceiling exhausted pool: level=%d party=%d cap=%d rejected=%d",
                tonumber(playerLevel) or 1,
                tonumber(partySizeForWeight) or 1,
                tonumber(earlyTemplateLevelCap) or 2,
                rejectedByTemplateLevel
            ))
        end
        return nil
    end
    candidates = cappedCandidates
    poolKey = string.format("%s_lcap%d", tostring(poolKey or "any"), earlyTemplateLevelCap)
    if EA_IsDebugMode() then
        DebugPrint(string.format(
            "[LowLevelGate] template ceiling active: level=%d party=%d cap=%d selected=%d rejected=%d",
            tonumber(playerLevel) or 1,
            tonumber(partySizeForWeight) or 1,
            tonumber(earlyTemplateLevelCap) or 2,
            #candidates,
            rejectedByTemplateLevel
        ))
    end
end
if requestedTier == "VETERAN" and partySizeForWeight <= 2 and playerLevel <= 4 then
    local veteranOnly = {}
    for _, enemy in ipairs(candidates) do
        if EA_GetEntrySpawnBand(enemy) == "VETERAN" then
            table.insert(veteranOnly, enemy)
        end
    end
    if #veteranOnly > 0 then
        candidates = veteranOnly
        poolKey = "strict_veteran_early"
        veteranOnlyLockActive = true
        if EA_IsDebugMode() then
            DebugPrint(string.format(
                "Early small-party safeguard: VETERAN tier restricted to VETERAN band only (%d candidates)",
                #candidates
            ))
        end
    end
end
local strictProgressionGates = true
if type(EA_GetStrictProgressionGates) == "function" then
    strictProgressionGates = (EA_GetStrictProgressionGates() == true)
else
    strictProgressionGates = EA_GetSettingBool("MCM_StrictProgressionGates", true)
end
if strictProgressionGates then
do
    local preGateCandidates = candidates
    local gateRejectedTotal = 0
    local gateRejectedBelow = 0
    local gateRejectedAbove = 0
    local function FilterByPartyLevelGate(source, widen)
        local accepted = {}
        local rejected = 0
        local rejectedBelow = 0
        local rejectedAbove = 0
        local widenBy = tonumber(widen) or 0
        for _, enemy in ipairs(source or {}) do
            local minPartyLevel = tonumber(enemy and enemy.minPartyLevel) or 1
            local maxPartyLevel = tonumber(enemy and enemy.maxPartyLevel) or 99
            if minPartyLevel < 1 then minPartyLevel = 1 end
            if maxPartyLevel < 1 then maxPartyLevel = 1 end
            if maxPartyLevel < minPartyLevel then
                minPartyLevel, maxPartyLevel = maxPartyLevel, minPartyLevel
            end
            minPartyLevel = math.max(1, minPartyLevel - widenBy)
            maxPartyLevel = maxPartyLevel + widenBy
            if playerLevel >= minPartyLevel and playerLevel <= maxPartyLevel then
                table.insert(accepted, enemy)
            else
                rejected = rejected + 1
                if playerLevel < minPartyLevel then
                    rejectedBelow = rejectedBelow + 1
                elseif playerLevel > maxPartyLevel then
                    rejectedAbove = rejectedAbove + 1
                end
            end
        end
        return accepted, rejected, rejectedBelow, rejectedAbove
    end
    local allowedBands = {}
    for _, enemy in ipairs(preGateCandidates) do
        local band = EA_GetEntrySpawnBand(enemy)
        if band then
            allowedBands[band] = true
        end
    end
    local hasAllowedBands = next(allowedBands) ~= nil
    local preserveCurrentBandShape = not (requestedTier == "VETERAN" or requestedTier == "ELITE")
    local relaxedTierPool = {}
    for _, enemy in ipairs(fullList) do
        if enemy and not enemy.championOnly then
            local band = EA_GetEntrySpawnBand(enemy)
            local allowedByRequestedTier = true
            if requestedTier == "COMMON" or requestedTier == "VETERAN" or requestedTier == "ELITE" then
                allowedByRequestedTier = EA_IsAllowedBandForRequestedTier(band, requestedTier)
            end
            local allowedByCurrentBands = true
            if preserveCurrentBandShape and hasAllowedBands and not allowedBands[band] then
                allowedByCurrentBands = false
            end
            local allowedByVeteranLock = true
            if veteranOnlyLockActive and band ~= "VETERAN" then
                allowedByVeteranLock = false
            end
            if allowedByRequestedTier and allowedByCurrentBands and allowedByVeteranLock then
                table.insert(relaxedTierPool, enemy)
            end
        end
    end
    if #relaxedTierPool == 0 then
        relaxedTierPool = preGateCandidates
    end
    local gateStage = "primary"
    local relaxGateStage = preserveCurrentBandShape and "relax_bandshape" or "relax_allowed_bands"
    local gatedCandidates, rejected, rejectedBelow, rejectedAbove = FilterByPartyLevelGate(preGateCandidates, 0)
    gateRejectedTotal = gateRejectedTotal + rejected
    gateRejectedBelow = gateRejectedBelow + rejectedBelow
    gateRejectedAbove = gateRejectedAbove + rejectedAbove
    if #gatedCandidates == 0 then
        if relaxedTierPool ~= preGateCandidates then
            local relaxedCandidates
            relaxedCandidates, rejected, rejectedBelow, rejectedAbove = FilterByPartyLevelGate(relaxedTierPool, 0)
            gateRejectedTotal = gateRejectedTotal + rejected
            gateRejectedBelow = gateRejectedBelow + rejectedBelow
            gateRejectedAbove = gateRejectedAbove + rejectedAbove
            if #relaxedCandidates > 0 then
                gatedCandidates = relaxedCandidates
                gateStage = relaxGateStage
            end
        end
        if #gatedCandidates == 0 then
            local widenedOne
            widenedOne, rejected, rejectedBelow, rejectedAbove = FilterByPartyLevelGate(relaxedTierPool, 1)
            gateRejectedTotal = gateRejectedTotal + rejected
            gateRejectedBelow = gateRejectedBelow + rejectedBelow
            gateRejectedAbove = gateRejectedAbove + rejectedAbove
            if #widenedOne > 0 then
                gatedCandidates = widenedOne
                gateStage = "widen_1"
            end
        end
        if #gatedCandidates == 0 then
            local widenedTwo
            widenedTwo, rejected, rejectedBelow, rejectedAbove = FilterByPartyLevelGate(relaxedTierPool, 2)
            gateRejectedTotal = gateRejectedTotal + rejected
            gateRejectedBelow = gateRejectedBelow + rejectedBelow
            gateRejectedAbove = gateRejectedAbove + rejectedAbove
            if #widenedTwo > 0 then
                gatedCandidates = widenedTwo
                gateStage = "widen_2"
            end
        end
    end
    if #gatedCandidates > 0 then
        candidates = gatedCandidates
        poolKey = string.format("%s_pg_%s", tostring(poolKey or "any"), gateStage)
        if gateStage ~= "primary" then
            DebugPrint(string.format(
                "[ProgressionGate] fallback=%s tier=%s level=%d selected=%d rejected=%d (below=%d, above=%d) tierRejected=%d",
                gateStage,
                tostring(spawnTier),
                playerLevel,
                #candidates,
                gateRejectedTotal,
                gateRejectedBelow,
                gateRejectedAbove,
                tierLockRejected
            ))
        elseif EA_IsDebugMode() and gateRejectedTotal > 0 then
            DebugPrint(string.format(
                "[ProgressionGate] tier=%s level=%d selected=%d rejected=%d (below=%d, above=%d) tierRejected=%d",
                tostring(spawnTier),
                playerLevel,
                #candidates,
                gateRejectedTotal,
                gateRejectedBelow,
                gateRejectedAbove,
                tierLockRejected
            ))
        end
    else
        candidates = preGateCandidates
        poolKey = string.format("%s_pg_final_fallback", tostring(poolKey or "any"))
        DebugPrint(string.format(
            "[ProgressionGate] final fallback (gate exhausted) tier=%s level=%d candidates=%d rejected=%d (below=%d, above=%d) tierRejected=%d",
            tostring(spawnTier),
            playerLevel,
            #candidates,
            gateRejectedTotal,
            gateRejectedBelow,
            gateRejectedAbove,
            tierLockRejected
        ))
    end
end
elseif EA_IsDebugMode() then
    DebugPrint("[ProgressionGate] disabled (MCM_StrictProgressionGates=false)")
end
local filteredCandidates = {}
local skippedChaff = 0
for _, enemy in ipairs(candidates) do
    if EA_IsHighLevelChaffEntry(enemy, playerLevel) then
        skippedChaff = skippedChaff + 1
    else
        table.insert(filteredCandidates, enemy)
    end
end
if #filteredCandidates > 0 then
    candidates = filteredCandidates
    if skippedChaff > 0 then
        DebugPrint(string.format("High-level anti-chaff filtered %d candidate(s) for level %d party.", skippedChaff, playerLevel))
    end
elseif skippedChaff > 0 then
    DebugPrint("High-level anti-chaff fallback: no filtered candidates, keeping original themed list.")
end
if requestedTier ~= nil then
    local powerClassStages, powerClassProfile = EA_GetPowerClassPreferenceStages(requestedTier)
    if type(powerClassStages) == "table" and #powerClassStages > 0 then
        local chosen = nil
        local stageIndex = nil
        for idx, stageClasses in ipairs(powerClassStages) do
            local stageCandidates = {}
            for _, enemy in ipairs(candidates) do
                local powerClass = EA_GetEntryPowerClass(enemy)
                if stageClasses[powerClass] then
                    table.insert(stageCandidates, enemy)
                end
            end
            if #stageCandidates > 0 then
                chosen = stageCandidates
                stageIndex = idx
                break
            end
        end
        if chosen and #chosen > 0 then
            candidates = chosen
            poolKey = string.format("%s_pc_%s_s%d", tostring(poolKey or "any"), tostring(powerClassProfile or "all"), tonumber(stageIndex) or 1)
            if EA_IsDebugMode() then
                DebugPrint(string.format(
                    "[PowerClassPref] tier=%s profile=%s stage=%d selected=%d fallback=%s",
                    tostring(requestedTier),
                    tostring(powerClassProfile or "all"),
                    tonumber(stageIndex) or 1,
                    #candidates,
                    tostring((tonumber(stageIndex) or 1) > 1)
                ))
            end
        end
    end
end
local weightedList, total = GetCachedWeightedList(player, themeKey, poolKey)
if not weightedList then
    if spilloverInfo and EA_IsDebugMode() then
        local stageParts = {}
        for _, item in ipairs(spilloverInfo.stageAdds or {}) do
            if (tonumber(item.added) or 0) > 0 then
                stageParts[#stageParts + 1] = string.format("%s=%d", tostring(item.theme), tonumber(item.added) or 0)
            end
        end
        DebugPrint(string.format(
            "[Spillover] theme=%s role=%s native=%d threshold=%d added={%s} final=%d",
            tostring(spilloverInfo.sourceTheme),
            tostring(spilloverInfo.roleTag or "any"),
            tonumber(spilloverInfo.nativeCount) or 0,
            tonumber(spilloverInfo.minNativeCandidates) or 0,
            table.concat(stageParts, " "),
            tonumber(spilloverInfo.finalCount) or #candidates
        ))
    end
    local pointBudget = GetPointBudget(playerLevel, player)
    local appropriateTypes = GetLocationAppropriateEnemies(player)
    weightedList = {}
    total = 0
    local phase4Suppressed = 0
    local phase4FallbackUsed = false
    local balanceProfile = "BG3_12"
    if type(EA_GetBalanceProfile) == "function" then
        local profile = EA_NormalizeContractValue("MCM_BalanceProfile", EA_GetBalanceProfile() or "BG3_12", "BG3_12")
        if profile == "BG3_12" or profile == "MODDED_20" then
            balanceProfile = profile
        end
    else
        local profile = EA_NormalizeContractValue("MCM_BalanceProfile", EA_GetSettingRaw("MCM_BalanceProfile", "BG3_12") or "BG3_12", "BG3_12")
        if profile == "BG3_12" or profile == "MODDED_20" then
            balanceProfile = profile
        end
    end
    local function EA_GetNormalizedPhase4PresetKnobs()
        local raw = nil
        if type(EA_GetPresetHiddenBalanceKnobs) == "function" then
            local ok, data = pcall(EA_GetPresetHiddenBalanceKnobs)
            if ok and type(data) == "table" then
                raw = data
            end
        end

        local tierBias = string.upper(tostring(raw and raw.tierBias or "COMMON_VETERAN_BASELINE"))
        if tierBias ~= "COMMON_HEAVY"
            and tierBias ~= "COMMON_VETERAN_BASELINE"
            and tierBias ~= "VETERAN_ELITE_LEANING"
            and tierBias ~= "ELITE_LEGENDARY_LEANING" then
            tierBias = "COMMON_VETERAN_BASELINE"
        end

        local fodderEliteBias = string.upper(tostring(raw and raw.fodderEliteBias or "BALANCED"))
        if fodderEliteBias ~= "FODDER_HEAVY"
            and fodderEliteBias ~= "BALANCED"
            and fodderEliteBias ~= "STRONGER_ENEMY_LEANING"
            and fodderEliteBias ~= "STRONGEST_ENEMY_LEANING" then
            fodderEliteBias = "BALANCED"
        end

        return {
            tierBias = tierBias,
            fodderEliteBias = fodderEliteBias,
        }
    end
    local function EA_GetPhase4ClassWeightMultiplier(powerClass, level)
        local pl = tonumber(level) or 1
        if balanceProfile == "BG3_12" and pl > 12 then
            pl = 12
        end
        local modded20 = (balanceProfile == "MODDED_20")
        local key = powerClass or "STANDARD"
        if key == "FODDER" then
            if pl >= 12 then return 0.10 end
            if pl >= 10 then return 0.30 end
            if pl >= 7 then return 0.50 end
            return 1.0
        end
        if key == "STANDARD" then
            if modded20 and pl >= 18 then return 1.28 end
            if pl >= 12 then return 1.20 end
            if pl >= 9 then return 1.10 end
            return 1.0
        end
        if key == "BRUISER" then
            if modded20 and pl >= 18 then return 1.34 end
            if pl >= 15 then return 1.26 end
            if pl >= 9 then return 1.20 end
            if pl >= 6 then return 1.12 end
            return 1.0
        end
        if key == "DREAD" then
            if modded20 and pl >= 18 then return 1.30 end
            if pl >= 15 then return 1.20 end
            if pl >= 12 then return 1.12 end
            if pl >= 9 then return 1.05 end
            return 1.0
        end
        if key == "APEX" then
            if modded20 and pl >= 18 then return 1.24 end
            if pl >= 15 then return 1.12 end
            if pl >= 12 then return 1.05 end
            return 1.0
        end
        return 1.0
    end
    local function EA_GetPhase4PresetClassWeightMultiplier(powerClass, requestedTier, hidden)
        local bias = string.upper(tostring(hidden and hidden.fodderEliteBias or "BALANCED"))
        local key = powerClass or "STANDARD"
        local req = EA_NormalizeEntryBand(requestedTier) or "COMMON"
        if key == "FODDER" or key == "STANDARD" then
            return 1.0
        end
        if bias == "STRONGER_ENEMY_LEANING" then
            if key == "BRUISER" then return 1.08 end
            if key == "DREAD" then return (req == "ELITE" or req == "LEGENDARY") and 1.15 or 1.12 end
            if key == "APEX" then return (req == "LEGENDARY") and 1.10 or 1.06 end
        elseif bias == "STRONGEST_ENEMY_LEANING" then
            if key == "BRUISER" then return 1.12 end
            if key == "DREAD" then return (req == "ELITE" or req == "LEGENDARY") and 1.20 or 1.15 end
            if key == "APEX" then return (req == "LEGENDARY") and 1.12 or 1.08 end
        end
        return 1.0
    end
    local function EA_GetPhase4ExpensiveSuppressionMultiplier(requestedTier, hidden)
        local req = EA_NormalizeEntryBand(requestedTier) or "COMMON"
        local bias = string.upper(tostring(hidden and hidden.fodderEliteBias or "BALANCED"))
        if req == "LEGENDARY" or req == "ELITE" then
            if bias == "STRONGEST_ENEMY_LEANING" then
                return 0.85
            elseif bias == "STRONGER_ENEMY_LEANING" then
                return 0.75
            end
        elseif req == "VETERAN" and bias == "STRONGEST_ENEMY_LEANING" then
            return 0.70
        end
        return 0.60
    end
    local presetHidden = EA_GetNormalizedPhase4PresetKnobs()
    local expensiveTemplateMult = EA_GetPhase4ExpensiveSuppressionMultiplier(requestedTier, presetHidden)
    if EA_IsDebugMode() then
        DebugPrint(string.format(
            "[Phase4Preset] tier=%s bias=%s expensiveMult=%.2f",
            tostring(requestedTier or "ANY"),
            tostring(presetHidden.fodderEliteBias),
            tonumber(expensiveTemplateMult) or 0
        ))
    end
    for _, e in ipairs(candidates) do
        if e and e.championOnly == true then
        elseif ValidateEnemyData(e) then
            local w = e.weight or 1
            local enemyLevel = e.level or 1
            local creatureType = e.creatureType or "Monstrosity"
            local isAppropriate = false
            for _, appType in ipairs(appropriateTypes) do
                if creatureType == appType then
                    isAppropriate = true
                    w = w * 2.0
                    break
                end
            end
            local reputation = CreatureReputation[creatureType] or 0
            if reputation <= REPUTATION_THRESHOLDS.VENGEFUL then
                w = w * 3.0
            elseif reputation <= REPUTATION_THRESHOLDS.HOSTILE then
                w = w * 2.0
            elseif reputation <= REPUTATION_THRESHOLDS.WARY then
                w = w * 1.5
            end
            if type(EA_GetTypePressure) == "function" then
                local typePressure = tonumber(EA_GetTypePressure(player, creatureType)) or 0
                if typePressure > 0 then
                    local pressureMult = 1.0 + (math.min(typePressure, 100) * 0.008)
                    w = w * pressureMult
                end
            end
            if type(EA_GetRecentAmbushTypePenalty) == "function" then
                w = w * (tonumber(EA_GetRecentAmbushTypePenalty(player, creatureType)) or 1.0)
            end
            local regionalMod = GetRegionalStrengthModifier(player, creatureType)
            w = w * regionalMod
            local playerTier = "expert"
            if playerLevel <= 2 then
                playerTier = "novice"
            elseif playerLevel <= 4 then
                playerTier = "apprentice"
            elseif playerLevel <= 6 then
                playerTier = "journeyman"
            end
            if playerTier == "expert" and enemyLevel >= 7 then
                w = w * 2.0
            elseif playerTier == "journeyman" and enemyLevel >= 5 and enemyLevel <= 6 then
                w = w * 1.5
            elseif playerTier == "apprentice" and enemyLevel >= 3 and enemyLevel <= 4 then
                w = w * 1.5
            elseif playerTier == "novice" and enemyLevel <= 2 then
                w = w * 1.5
            end
            local levelGap = enemyLevel - playerLevel
            if partySizeForWeight <= 2 and playerLevel <= 3 then
                if enemyLevel >= 5 then
                    w = w * 0.06
                elseif enemyLevel >= 4 then
                    w = w * 0.16
                end
            end
            if playerLevel <= 2 then
                if levelGap >= 3 then
                    w = w * 0.15
                elseif levelGap >= 2 then
                    w = w * 0.35
                elseif levelGap <= -2 then
                    w = w * 1.25
                end
            elseif playerLevel <= 4 then
                if levelGap >= 4 then
                    w = w * 0.2
                elseif levelGap >= 2 then
                    w = w * 0.5
                elseif levelGap <= -2 then
                    w = w * 1.15
                end
            else
                if levelGap >= 5 then
                    w = w * 0.2
                elseif levelGap >= 3 then
                    w = w * 0.45
                elseif levelGap >= 2 then
                    w = w * EA_HIGH_LEVEL_BIAS
                elseif levelGap <= -3 then
                    w = w * 1.1
                end
            end
            if enemyLevel >= pointBudget * 0.75 then
                w = w * expensiveTemplateMult
            end
            local highLevelSuppression = EA_GetHighLevelLowTierSuppression(playerLevel, enemyLevel)
            if highLevelSuppression < 1.0 then
                w = w * highLevelSuppression
            end
            local powerClass = EA_GetEntryPowerClass(e)
            local classMult = EA_GetPhase4ClassWeightMultiplier(powerClass, playerLevel)
            local presetClassMult = EA_GetPhase4PresetClassWeightMultiplier(powerClass, requestedTier, presetHidden)
            if classMult <= 0 then
                phase4Suppressed = phase4Suppressed + 1
            else
                w = w * classMult * presetClassMult
                if w > EA_WEIGHT_MULTIPLIER_CAP then
                    w = EA_WEIGHT_MULTIPLIER_CAP
                    if UpdateMetric then
                        UpdateMetric("weightCapHits")
                    end
                end
                if w > 0 then
                    table.insert(weightedList, { enemy = e, adjustedWeight = w })
                    total = total + w
                else
                    phase4Suppressed = phase4Suppressed + 1
                end
            end
        else
            DebugPrint("Skipping invalid enemy template:", e.name or "Unknown")
        end
    end
    if #weightedList == 0 or total <= 0 then
        phase4FallbackUsed = true
        weightedList = {}
        total = 0
        for _, e in ipairs(candidates) do
            if e and e.championOnly ~= true and ValidateEnemyData(e) then
                local fallbackW = tonumber(e.weight) or 1
                if fallbackW <= 0 then fallbackW = 0.01 end
                table.insert(weightedList, { enemy = e, adjustedWeight = fallbackW })
                total = total + fallbackW
            end
        end
    end
    if EA_IsDebugMode() and (phase4Suppressed > 0 or phase4FallbackUsed) then
        DebugPrint(string.format(
            "[Phase4] profile=%s policy=%s class-weighting suppressed=%d fallbackUsed=%s level=%d pool=%d",
            tostring(balanceProfile),
            tostring(fodderPolicy),
            phase4Suppressed,
            tostring(phase4FallbackUsed),
            playerLevel,
            #weightedList
        ))
    end
    CacheWeightedList(player, weightedList, total, themeKey, poolKey)
    UpdateMetric("cacheMisses")
else
    UpdateMetric("cacheHits")
end
local r = EA_RandFloatCompat() * total
local c = 0
for _, entry in ipairs(weightedList) do
    c = c + entry.adjustedWeight
    if r <= c then
        return entry.enemy
    end
end
if #candidates > 0 then
    return candidates[#candidates]
end
return nil
end

local function EA_RunStartupTemplateAudit(maxDetails)
    if not EA_IsDebugMode() then
        return { skipped = true, reason = "debug_off" }
    end
    if not (Ext and Ext.Template and type(Ext.Template.GetRootTemplate) == "function") then
        print("[EnemyAmbush][StartupAudit] Skipped: Ext.Template.GetRootTemplate unavailable.")
        return { skipped = true, reason = "template_api_unavailable" }
    end

    local list = BuildActiveSummonList() or {}
    local limit = math.max(0, math.floor(tonumber(maxDetails) or 8))
    local badGuids = {}
    local missingTemplates = {}
    local badCount = 0
    local missingCount = 0

    for _, enemy in ipairs(list) do
        local name = tostring(enemy and enemy.name or "Unnamed")
        local template = tostring(enemy and enemy.template or "")
        if template == "" or not template:match("^[0-9a-fA-F%-]+$") then
            badCount = badCount + 1
            if #badGuids < limit then
                badGuids[#badGuids + 1] = string.format("%s (%s)", name, template)
            end
        else
            local ok, root = pcall(Ext.Template.GetRootTemplate, template)
            if (not ok) or root == nil then
                missingCount = missingCount + 1
                if #missingTemplates < limit then
                    missingTemplates[#missingTemplates + 1] = string.format("%s (%s)", name, template)
                end
            end
        end
    end

    print(string.format(
        "[EnemyAmbush][StartupAudit] template check: total=%d invalidGuid=%d missingRoot=%d",
        #list,
        badCount,
        missingCount
    ))

    if badCount > 0 then
        print(string.format("[EnemyAmbush][StartupAudit] Invalid GUID samples (%d shown):", #badGuids))
        for _, row in ipairs(badGuids) do
            print("  - " .. tostring(row))
        end
    end
    if missingCount > 0 then
        print(string.format("[EnemyAmbush][StartupAudit] Missing root template samples (%d shown):", #missingTemplates))
        for _, row in ipairs(missingTemplates) do
            print("  - " .. tostring(row))
        end
    end

    return {
        skipped = false,
        total = #list,
        invalidGuid = badCount,
        missingRoot = missingCount,
    }
end

    local runtime = {}
    runtime.POOL_OWNER_ID = POOL_OWNER_ID
    runtime.BuildActiveSummonList = BuildActiveSummonList
    runtime.GetAmbushThemeForEnemy = GetAmbushThemeForEnemy
    runtime.ThemeAllowsEnemy = ThemeAllowsEnemy
    runtime.ValidateEnemyData = ValidateEnemyData
    runtime.PickEnemyTemplate = PickEnemyTemplate
    runtime.EA_GetPoolOwnerId = EA_GetPoolOwnerId
    runtime.EA_GetPoolActiveSummonList = BuildActiveSummonList
    runtime.EA_GetPoolTemplateEntryById = EA_GetPoolTemplateEntryById
    runtime.EA_GetPoolTemplateVariantsById = EA_GetPoolTemplateVariantsById
    runtime.EA_GetPoolTemplateVariantEntry = EA_GetPoolTemplateVariantEntry
    runtime.EA_ResetPoolActiveListState = EA_ResetPoolActiveListState
    runtime.EA_FlushPoolCacheState = EA_FlushPoolCacheState
    runtime.EA_MarkPoolNeedsRebuild = EA_MarkPoolNeedsRebuild
    runtime.EA_RequestPoolRebuild = EA_RequestPoolRebuild
    runtime.EA_NotifyPoolProviderChanged = EA_NotifyPoolProviderChanged
    runtime.EA_ResetPoolTemplateLookups = EA_ResetPoolTemplateLookups
    runtime.EA_GetEntrySpawnBand = EA_GetEntrySpawnBand
    runtime.EA_GetCharacterTemplate = EA_GetCharacterTemplate
    runtime.EA_PrimeCharacterTemplateCache = EA_PrimeCharacterTemplateCache
    runtime.EA_ResetLocalCharacterTemplateCache = EA_ResetLocalCharacterTemplateCache
runtime.EA_ResolveCreatureTypeByTemplate = EA_ResolveCreatureTypeByTemplate
runtime.EA_ResolveCreatureTypeForCharacter = EA_ResolveCreatureTypeForCharacter
runtime.EA_GetThemeSpilloverPlan = EA_GetThemeSpilloverPlan
runtime.EA_WEIGHT_MULTIPLIER_CAP = EA_WEIGHT_MULTIPLIER_CAP
runtime.EA_RunStartupTemplateAudit = EA_RunStartupTemplateAudit
runtime.CurrentAmbushTheme = CurrentAmbushTheme
    return runtime
end
return M
