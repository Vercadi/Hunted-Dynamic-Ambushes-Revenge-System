-- EnemyAmbush_API.lua
-- Public API for EnemyAmbush (server-side)

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local EA_ReadSettingBool = EA["EA_ReadSettingBool"]

EA.API_VERSION = "1.5.0"

-- Increments every time providers change (used to auto-rebuild cached pools)
EA.ProviderRevision = EA.ProviderRevision or 0
EA.ChampionProviderRevision = EA.ChampionProviderRevision or 0

-- Provider storage
EA._providers = EA._providers or {}               -- id -> { entries = {}, opts = {} }
EA._providerOrder = EA._providerOrder or {}       -- stable order
EA._championProviders = EA._championProviders or {}          -- id -> provider
EA._championProviderOrder = EA._championProviderOrder or {}  -- stable order

-- Simple event system (recommended)
EA._listeners = EA._listeners or {}               -- event -> { fn, fn... }

local function EA_IsModLoaded(uuid)
    if not uuid or uuid == "" then
        return false
    end
    if not Ext or not Ext.Mod or not Ext.Mod.IsModLoaded then
        return false
    end
    return Ext.Mod.IsModLoaded(uuid)
end

local function EA_ApiLogFailure(action, reason)
    print(string.format(
        "[EnemyAmbush][API] %s failed: %s",
        tostring(action or "API call"),
        tostring(reason or "unknown error")
    ))
end

local function EA_ResolveApiExport(name)
    local fn = EA and EA[name]
    if type(fn) == "function" then
        return fn
    end
    return nil
end

local function EA_CopyValue(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, innerValue in pairs(value) do
        copy[EA_CopyValue(key, seen)] = EA_CopyValue(innerValue, seen)
    end
    return copy
end

local function EA_RemoveOrderedId(order, id)
    for index, value in ipairs(order or {}) do
        if value == id then
            table.remove(order, index)
            return true
        end
    end
    return false
end

local function EA_NormalizeApiTemplateId(value, fieldName)
    local id = string.lower(tostring(value or ""))
    if id == "" then
        return nil, "invalid " .. tostring(fieldName or "template")
    end
    return id
end

local function EA_NormalizeApiOptionalString(value)
    if value == nil then
        return nil
    end
    local text = tostring(value or "")
    if text == "" then
        return nil
    end
    return text
end

local function EA_GetAuthoredAmbushService()
    local systemsModules = EA and EA.SystemsModules
    local service = systemsModules and systemsModules.AuthoredAmbushService
    if type(service) == "table" then
        return service
    end
    return nil
end

local function EA_GetAuthoredAmbushRuntime()
    local systemsModules = EA and EA.SystemsModules
    local runtime = systemsModules and systemsModules.AuthoredAmbushRuntime
    if type(runtime) == "table" then
        return runtime
    end
    return nil
end

local function EA_GetApiHostCharacter()
    if Osi and Osi.GetHostCharacter then
        local host = Osi.GetHostCharacter()
        if host and host ~= "" then
            return host
        end
    end
    return nil
end

local function EA_GetApiPartyMembers(character)
    if not character or character == "" then
        return {}
    end

    local members = {}
    local seen = {}

    local function addMember(member)
        member = tostring(member or "")
        if member == "" or seen[member] then
            return
        end
        seen[member] = true
        members[#members + 1] = member
    end

    local getPartyMembers = EA and EA["EA_GetPartyMembers"]
    if type(getPartyMembers) == "function" then
        local okParty, party = pcall(getPartyMembers, character)
        if okParty and type(party) == "table" then
            for _, member in ipairs(party) do
                addMember(member)
            end
        end
    end

    if #members == 0 then
        addMember(character)
    end

    return members
end

local function EA_IsApiCharacterInCamp(character, canonicalRegion)
    if not character or character == "" then
        return false
    end

    if Osi and Osi.DB_InCamp then
        local okInCamp, tuples = pcall(function()
            return Osi.DB_InCamp:Get(character)
        end)
        if okInCamp and tuples and #tuples > 0 then
            return true
        end
    end

    if Osi and Osi.DB_PlayerInCamp then
        local okPlayerInCamp, tuples = pcall(function()
            return Osi.DB_PlayerInCamp:Get(character)
        end)
        if okPlayerInCamp and tuples and #tuples > 0 then
            return true
        end
    end

    local isRegionCamp = EA and EA["EA_IsRegionCamp"]
    if type(isRegionCamp) == "function" then
        local okCamp, out = pcall(isRegionCamp, canonicalRegion)
        if okCamp and out == true then
            return true
        end
    end

    return false
end

local function EA_GetApiCooldownState(character)
    local getCooldownEnabled = EA and EA["EA_GetCooldownEnabled"]
    if type(getCooldownEnabled) ~= "function" then
        return false, 0
    end
    local okEnabled, cooldownEnabled = pcall(getCooldownEnabled)
    if not okEnabled or cooldownEnabled ~= true then
        return false, 0
    end

    local getCooldownMinutes = EA and EA["EA_GetCooldownMinutes"]
    local lastAmbushTime = EA and EA["EA_LastAmbushTime"]
    local normalizeUUID = EA and EA["EA_NormalizeUUID"]
    local persistedNowMs = EA and EA["EA_PersistedNowMs"]
    if type(getCooldownMinutes) ~= "function" or type(lastAmbushTime) ~= "function" or type(persistedNowMs) ~= "function" then
        return false, 0
    end

    local okMinutes, cooldownMinutes = pcall(getCooldownMinutes)
    cooldownMinutes = okMinutes and tonumber(cooldownMinutes) or 0
    if cooldownMinutes <= 0 then
        return false, 0
    end

    local okLast, lastByCharacter = pcall(lastAmbushTime)
    local okNow, nowMs = pcall(persistedNowMs)
    if not okLast or (type(lastByCharacter) ~= "table" and type(lastByCharacter) ~= "userdata") or not okNow or tonumber(nowMs) == nil then
        return false, 0
    end

    local cooldownMs = math.floor(cooldownMinutes * 60000)
    local remainingMs = 0
    for _, member in ipairs(EA_GetApiPartyMembers(character)) do
        local key = member
        if type(normalizeUUID) == "function" then
            local okKey, normalized = pcall(normalizeUUID, member)
            if okKey and type(normalized) == "string" and normalized ~= "" then
                key = normalized
            end
        end

        local last = tonumber(lastByCharacter[key])
        if last and last > 0 then
            local age = tonumber(nowMs) - last
            if age < 0 then
                age = 0
            end
            if age < cooldownMs then
                local candidateRemaining = cooldownMs - age
                if candidateRemaining > remainingMs then
                    remainingMs = candidateRemaining
                end
            end
        end
    end

    return remainingMs > 0, remainingMs
end

local function EA_BuildPublicTriggerCtx(ctx)
    if type(ctx) ~= "table" then
        return false, "invalid ctx"
    end

    local character = tostring(ctx.character or "")
    if character == "" then
        return false, "invalid character"
    end

    local normalized = {
        character = character,
        force = (ctx.force == true),
    }

    local flowLabel = ctx.flowLabel
    if flowLabel ~= nil then
        if type(flowLabel) ~= "string" or flowLabel == "" then
            return false, "invalid ctx"
        end
        normalized.flowLabel = flowLabel
    end

    local source = ctx.source
    if source ~= nil then
        if type(source) ~= "string" or source == "" then
            return false, "invalid ctx"
        end
        normalized.source = source
    else
        normalized.source = "external"
    end

    local getSafeLevel = EA and EA["GetSafeLevel"]
    if type(getSafeLevel) == "function" then
        local okLevel, level = pcall(getSafeLevel, character)
        if okLevel and tonumber(level) ~= nil then
            normalized.level = tonumber(level)
        end
    end

    local activeRegion = nil
    local getRegionForCharacter = EA and EA["EA_GetRegionForCharacter"]
    if type(getRegionForCharacter) == "function" then
        local okRegion, canonicalRegion = pcall(getRegionForCharacter, character)
        if okRegion and type(canonicalRegion) == "string" and canonicalRegion ~= "" then
            activeRegion = canonicalRegion
            normalized.region = canonicalRegion
        end
    end

    local isBlockedSafeZone = EA and EA["EA_IsCharacterInBlockedSafeZone"]
    if type(isBlockedSafeZone) == "function" then
        local okBlockedSafe, out = pcall(isBlockedSafeZone, character)
        normalized.inBlockedSafeZone = okBlockedSafe and out == true or false
    else
        normalized.inBlockedSafeZone = false
    end

    normalized.inCamp = EA_IsApiCharacterInCamp(character, activeRegion)

    local inCombat = false
    if Osi and Osi.IsInCombat then
        local okCharacterCombat, out = pcall(Osi.IsInCombat, character)
        inCombat = okCharacterCombat and tonumber(out) == 1 or false
    end
    if not inCombat then
        local isAnyPartyInCombat = EA and EA["EA_IsAnyPartyInCombat"]
        if type(isAnyPartyInCombat) == "function" then
            local okPartyCombat, out = pcall(isAnyPartyInCombat)
            inCombat = okPartyCombat and out == true or false
        end
    end
    normalized.inCombat = inCombat

    return true, normalized
end

local function EA_GetPendingAmbushCount()
    local pendingFn = EA and EA["EA_Pending"]
    if type(pendingFn) ~= "function" then
        return 0
    end
    local okPending, pending = pcall(pendingFn)
    if not okPending or (type(pending) ~= "table" and type(pending) ~= "userdata") then
        return 0
    end

    local count = 0
    for _ in pairs(pending) do
        count = count + 1
    end
    return count
end

local function EA_CountChampionEntries(championsByType)
    local total = 0
    local creatureTypes = {}
    for creatureType, entry in pairs(championsByType or {}) do
        creatureTypes[#creatureTypes + 1] = tostring(creatureType)
        if type(entry) == "table" then
            if entry.template then
                total = total + 1
            else
                for _, champion in ipairs(entry) do
                    if type(champion) == "table" and champion.template then
                        total = total + 1
                    end
                end
            end
        end
    end
    table.sort(creatureTypes)
    return total, creatureTypes
end

local function EA_ProviderIsActive(provider)
    local opts = provider.opts or {}

    -- MCM gate (string name)
    if opts.enabledVar then
        local enabledDefault = opts.enabledDefault
        if enabledDefault == nil then
            enabledDefault = true
        end
        local enabled = enabledDefault
        local readSettingBool = EA_ReadSettingBool or (EA and EA["EA_ReadSettingBool"])
        if type(readSettingBool) == "function" then
            enabled = readSettingBool(opts.enabledVar, enabledDefault) == true
        end
        if not enabled then
            return false
        end
    end

    -- Custom enable function gate (optional)
    if type(opts.enabledFn) == "function" then
        local ok, res = pcall(opts.enabledFn)
        if not ok or not res then
            return false
        end
    end

    -- Requires ALL UUIDs (optional)
    if opts.requiresAllUUID and type(opts.requiresAllUUID) == "table" then
        for _, uuid in ipairs(opts.requiresAllUUID) do
            if not EA_IsModLoaded(uuid) then
                return false
            end
        end
    end

    -- Requires ANY UUID (optional)
    if opts.requiresAnyUUID and type(opts.requiresAnyUUID) == "table" then
        local any = false
        for _, uuid in ipairs(opts.requiresAnyUUID) do
            if EA_IsModLoaded(uuid) then
                any = true
                break
            end
        end
        if not any then
            return false
        end
    end

    return true
end

local function EA_CopyEnemyProviderSnapshot(provider)
    if type(provider) ~= "table" then
        return nil
    end
    local entries = provider.entries or {}
    local snapshot = {
        id = tostring(provider.id or ""),
        entries = EA_CopyValue(entries),
        opts = EA_CopyValue(provider.opts or {}),
        priority = tonumber(provider.priority) or 0,
        active = EA_ProviderIsActive(provider),
        entryCount = #entries,
    }
    return snapshot
end

local function EA_CopyChampionProviderSnapshot(provider)
    if type(provider) ~= "table" then
        return nil
    end
    local championsByType = provider.championsByType or {}
    local championCount, creatureTypes = EA_CountChampionEntries(championsByType)
    local snapshot = {
        id = tostring(provider.id or ""),
        championsByType = EA_CopyValue(championsByType),
        opts = EA_CopyValue(provider.opts or {}),
        priority = tonumber(provider.priority) or 0,
        active = EA_ProviderIsActive(provider),
        championCount = championCount,
        creatureTypes = creatureTypes,
    }
    return snapshot
end

-- ========= Public API: Events =========
function EA.On(eventName, fn)
    if type(eventName) ~= "string" or eventName == "" or type(fn) ~= "function" then
        return nil
    end
    EA._listeners[eventName] = EA._listeners[eventName] or {}
    table.insert(EA._listeners[eventName], fn)
    return fn
end

function EA.Off(eventName, fn)
    if type(eventName) ~= "string" or eventName == "" or type(fn) ~= "function" then
        return 0
    end
    local list = EA._listeners[eventName]
    if type(list) ~= "table" then
        return 0
    end
    local removed = 0
    for index = #list, 1, -1 do
        if list[index] == fn then
            table.remove(list, index)
            removed = removed + 1
        end
    end
    if #list == 0 then
        EA._listeners[eventName] = nil
    end
    return removed
end

function EA.Once(eventName, fn)
    if type(eventName) ~= "string" or eventName == "" or type(fn) ~= "function" then
        return nil
    end
    local wrapper = nil
    wrapper = function(...)
        EA.Off(eventName, wrapper)
        return fn(...)
    end
    EA.On(eventName, wrapper)
    return wrapper
end

function EA.Emit(eventName, ...)
    local list = EA._listeners[eventName]
    if type(list) ~= "table" or #list == 0 then
        return 0
    end
    local snapshot = {}
    for index, fn in ipairs(list) do
        snapshot[index] = fn
    end
    local fired = 0
    for _, fn in ipairs(snapshot) do
        fired = fired + 1
        pcall(fn, ...)
    end
    return fired
end

-- ========= Public API: Enemy Providers =========
function EA.HasEnemyProvider(id)
    return type(id) == "string" and id ~= "" and EA._providers[id] ~= nil
end

function EA.GetEnemyProvider(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end
    return EA_CopyEnemyProviderSnapshot(EA._providers[id])
end

function EA.ListEnemyProviders()
    local out = {}
    for orderIndex, id in ipairs(EA._providerOrder or {}) do
        local provider = EA._providers[id]
        if provider then
            local snapshot = EA_CopyEnemyProviderSnapshot(provider)
            snapshot.orderIndex = orderIndex
            out[#out + 1] = snapshot
        end
    end
    return out
end

function EA.IsEnemyProviderActive(id)
    if type(id) ~= "string" or id == "" then
        return false
    end
    local provider = EA._providers[id]
    if not provider then
        return false
    end
    return EA_ProviderIsActive(provider)
end

function EA.RegisterEnemyProvider(id, entries, opts)
    if type(id) ~= "string" or id == "" then
        EA_ApiLogFailure("RegisterEnemyProvider", "invalid id")
        return false, "invalid id"
    end
    if type(entries) ~= "table" then
        entries = {}
    end
    if type(opts) ~= "table" then
        opts = {}
    end

    local storedEntries = EA_CopyValue(entries)
    local storedOpts = EA_CopyValue(opts)
    local isNew = (EA._providers[id] == nil)

    EA._providers[id] = {
        id = id,
        entries = storedEntries,
        opts = storedOpts,
        priority = tonumber(storedOpts.priority) or 0,
    }

    if isNew then
        table.insert(EA._providerOrder, id)
    end

    EA.ProviderRevision = (EA.ProviderRevision or 0) + 1
    EA.Emit("EnemyProvidersChanged", id)
    return true
end

function EA.UnregisterEnemyProvider(id)
    if type(id) ~= "string" or id == "" then
        EA_ApiLogFailure("UnregisterEnemyProvider", "invalid id")
        return false, "invalid id"
    end
    if not EA._providers[id] then
        return false, "provider not found"
    end
    EA._providers[id] = nil
    EA_RemoveOrderedId(EA._providerOrder, id)
    EA.ProviderRevision = (EA.ProviderRevision or 0) + 1
    EA.Emit("EnemyProvidersChanged", id)
    return true
end

-- Convenience: register a single enemy entry into an existing provider
function EA.RegisterEnemyTemplate(providerId, entry)
    if type(providerId) ~= "string" or providerId == "" then
        EA_ApiLogFailure("RegisterEnemyTemplate", "invalid providerId")
        return false, "invalid providerId"
    end
    if type(entry) ~= "table" then
        EA_ApiLogFailure("RegisterEnemyTemplate", "entry must be a table")
        return false, "entry must be a table"
    end

    local p = EA._providers[providerId]
    if not p then
        return EA.RegisterEnemyProvider(providerId, { entry }, {})
    end

    p.entries = p.entries or {}
    table.insert(p.entries, EA_CopyValue(entry))

    EA.ProviderRevision = (EA.ProviderRevision or 0) + 1
    EA.Emit("EnemyProvidersChanged", providerId)
    return true
end

-- Returns merged active entries (what the ambush system should use).
-- The returned list is a defensive copy and must be treated as read-only snapshot data.
local _activeEntriesCache = nil
local _activeEntriesCacheGen = -1

-- Explicit cache invalidation hook for config/runtime setting changes that affect provider activation.
function EA.InvalidateEnemyProviderCache(reason)
    EA.ProviderRevision = (EA.ProviderRevision or 0) + 1
    if EA.DebugPrint and type(EA.DebugPrint) == "function" then
        EA.DebugPrint("[EnemyAmbush][API] Enemy provider cache invalidated:", tostring(reason or "unspecified"))
    end
end

-- Registers an explicit original-template -> zero-XP-clone mapping supplied by
-- an external compatibility patch. The clone template must exist in the loaded
-- mod set; this API only wires Hunted's runtime lookup/selection contract.
function EA.RegisterXPCloneMapping(providerId, mapping)
    if type(providerId) ~= "string" or providerId == "" then
        EA_ApiLogFailure("RegisterXPCloneMapping", "invalid providerId")
        return false, "invalid providerId"
    end
    if type(mapping) ~= "table" then
        EA_ApiLogFailure("RegisterXPCloneMapping", "mapping must be a table")
        return false, "mapping must be a table"
    end

    local originalTemplate, originalErr = EA_NormalizeApiTemplateId(mapping.originalTemplate or mapping.template, "originalTemplate")
    if not originalTemplate then
        EA_ApiLogFailure("RegisterXPCloneMapping", originalErr)
        return false, originalErr
    end
    local cloneTemplate, cloneErr = EA_NormalizeApiTemplateId(mapping.cloneTemplate or mapping.xpCloneTemplate, "cloneTemplate")
    if not cloneTemplate then
        EA_ApiLogFailure("RegisterXPCloneMapping", cloneErr)
        return false, cloneErr
    end

    EA.EnemyData = EA.EnemyData or {}
    EA.EnemyData.XPCloneMap = EA.EnemyData.XPCloneMap or {}
    EA._xpCloneProviderMappings = EA._xpCloneProviderMappings or {}
    EA._xpCloneProviderMappings[providerId] = EA._xpCloneProviderMappings[providerId] or {}

    local existing = EA.EnemyData.XPCloneMap[originalTemplate]
    if type(existing) == "table"
        and not (existing.source == "api" and existing.providerId == providerId)
    then
        EA_ApiLogFailure("RegisterXPCloneMapping", "mapping already exists")
        return false, "mapping already exists"
    end

    local record = {
        originalTemplate = originalTemplate,
        cloneTemplate = cloneTemplate,
        originalStat = EA_NormalizeApiOptionalString(mapping.originalStat),
        cloneStat = EA_NormalizeApiOptionalString(mapping.cloneStat),
        originalRewardGuid = EA_NormalizeApiOptionalString(mapping.originalRewardGuid),
        providerId = providerId,
        source = "api",
        rewardLevels = type(mapping.rewardLevels) == "table" and EA_CopyValue(mapping.rewardLevels) or {},
    }

    EA.EnemyData.XPCloneMap[originalTemplate] = record
    EA._xpCloneProviderMappings[providerId][originalTemplate] = true
    if type(existing) ~= "table" then
        EA.EnemyData.XPCloneCount = (tonumber(EA.EnemyData.XPCloneCount) or 0) + 1
    end
    EA.ProviderRevision = (EA.ProviderRevision or 0) + 1
    EA.ChampionProviderRevision = (EA.ChampionProviderRevision or 0) + 1
    EA.Emit("XPCloneMappingsChanged", providerId, originalTemplate)
    return true
end

function EA.UnregisterXPCloneMappings(providerId)
    if type(providerId) ~= "string" or providerId == "" then
        EA_ApiLogFailure("UnregisterXPCloneMappings", "invalid providerId")
        return false, "invalid providerId"
    end

    local mappings = EA._xpCloneProviderMappings and EA._xpCloneProviderMappings[providerId]
    if type(mappings) ~= "table" then
        return false, "provider mappings not found"
    end

    local removed = 0
    if EA.EnemyData and type(EA.EnemyData.XPCloneMap) == "table" then
        for originalTemplate in pairs(mappings) do
            local row = EA.EnemyData.XPCloneMap[originalTemplate]
            if type(row) == "table" and row.providerId == providerId and row.source == "api" then
                EA.EnemyData.XPCloneMap[originalTemplate] = nil
                removed = removed + 1
            end
        end
        EA.EnemyData.XPCloneCount = math.max(0, (tonumber(EA.EnemyData.XPCloneCount) or 0) - removed)
    end

    EA._xpCloneProviderMappings[providerId] = nil
    EA.ProviderRevision = (EA.ProviderRevision or 0) + 1
    EA.ChampionProviderRevision = (EA.ChampionProviderRevision or 0) + 1
    EA.Emit("XPCloneMappingsChanged", providerId, nil)
    return true, removed
end

local EA_API_FALLBACK_RNG_MOD = 2147483647
local EA_API_FALLBACK_RNG_A = 48271
local EA_API_FALLBACK_RNG_STATE = ((tonumber(Ext and Ext.Utils and Ext.Utils.MonotonicTime and Ext.Utils.MonotonicTime()) or 24681357) % EA_API_FALLBACK_RNG_MOD)
if EA_API_FALLBACK_RNG_STATE <= 0 then
    EA_API_FALLBACK_RNG_STATE = 24681357
end

local function EA_ApiFallbackRandFloat()
    EA_API_FALLBACK_RNG_STATE = (EA_API_FALLBACK_RNG_STATE * EA_API_FALLBACK_RNG_A) % EA_API_FALLBACK_RNG_MOD
    if EA_API_FALLBACK_RNG_STATE <= 0 then
        EA_API_FALLBACK_RNG_STATE = 24681357
    end
    return EA_API_FALLBACK_RNG_STATE / EA_API_FALLBACK_RNG_MOD
end

local function EA_ApiRandFloat()
    local fn = EA and EA["EA_RandFloat"]
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok and tonumber(out) then
            local n = tonumber(out)
            if n >= 0 and n <= 1 then
                return n
            end
        end
    end
    return EA_ApiFallbackRandFloat()
end

function EA.GetActiveEnemyEntries()
    local currentGen = EA.ProviderRevision or 0
    if _activeEntriesCache and _activeEntriesCacheGen == currentGen then
        return EA_CopyValue(_activeEntriesCache)
    end

    local out = {}

    -- Sort providers by priority (higher first)
    local providers = {}
    for _, id in ipairs(EA._providerOrder or {}) do
        local p = EA._providers[id]
        if p and EA_ProviderIsActive(p) then
            providers[#providers + 1] = p
        end
    end

    table.sort(providers, function(a, b)
        local pa = (a.opts and a.opts.priority) or 0
        local pb = (b.opts and b.opts.priority) or 0
        return pa > pb
    end)

    -- Merge entries (light validation)
    for _, p in ipairs(providers) do
        for _, e in ipairs(p.entries or {}) do
            if type(e) == "table" and e.template and e.template ~= "" then
                out[#out + 1] = e
            end
        end
    end

    _activeEntriesCache = out
    _activeEntriesCacheGen = currentGen
    return EA_CopyValue(out)
end

-- ========= Public API: Champions (Providers) =========
local function EA_GetChampionListForType(provider, creatureType)
    local t = provider.championsByType and provider.championsByType[creatureType]
    if not t then
        return {}
    end
    -- allow either a single champion table OR a list of champion tables
    if t.template then
        return { t }
    end
    return t
end

function EA.HasChampionProvider(id)
    return type(id) == "string" and id ~= "" and EA._championProviders[id] ~= nil
end

function EA.GetChampionProvider(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end
    return EA_CopyChampionProviderSnapshot(EA._championProviders[id])
end

function EA.ListChampionProviders()
    local out = {}
    for orderIndex, id in ipairs(EA._championProviderOrder or {}) do
        local provider = EA._championProviders[id]
        if provider then
            local snapshot = EA_CopyChampionProviderSnapshot(provider)
            snapshot.orderIndex = orderIndex
            out[#out + 1] = snapshot
        end
    end
    return out
end

function EA.IsChampionProviderActive(id)
    if type(id) ~= "string" or id == "" then
        return false
    end
    local provider = EA._championProviders[id]
    if not provider then
        return false
    end
    return EA_ProviderIsActive(provider)
end

function EA.RegisterChampionProvider(id, championsByType, opts)
    if type(id) ~= "string" or id == "" then
        EA_ApiLogFailure("RegisterChampionProvider", "invalid id")
        return false, "invalid id"
    end
    if type(championsByType) ~= "table" then
        championsByType = {}
    end
    if type(opts) ~= "table" then
        opts = {}
    end

    local storedChampionsByType = EA_CopyValue(championsByType)
    local storedOpts = EA_CopyValue(opts)
    local isNew = (EA._championProviders[id] == nil)

    EA._championProviders[id] = {
        id = id,
        championsByType = storedChampionsByType,
        opts = storedOpts,
        priority = tonumber(storedOpts.priority) or 0,
    }

    if isNew then
        table.insert(EA._championProviderOrder, id)
    end

    EA.ChampionProviderRevision = (EA.ChampionProviderRevision or 0) + 1
    EA.Emit("ChampionProvidersChanged", id)
    return true
end

function EA.UnregisterChampionProvider(id)
    if type(id) ~= "string" or id == "" then
        EA_ApiLogFailure("UnregisterChampionProvider", "invalid id")
        return false, "invalid id"
    end
    if not EA._championProviders[id] then
        return false, "provider not found"
    end
    EA._championProviders[id] = nil
    EA_RemoveOrderedId(EA._championProviderOrder, id)
    EA.ChampionProviderRevision = (EA.ChampionProviderRevision or 0) + 1
    EA.Emit("ChampionProvidersChanged", id)
    return true
end

-- Convenience: register/override a single champion template under a provider
function EA.RegisterChampionTemplate(providerId, creatureType, championData)
    if type(providerId) ~= "string" or providerId == "" then
        EA_ApiLogFailure("RegisterChampionTemplate", "invalid providerId")
        return false, "invalid providerId"
    end
    if type(creatureType) ~= "string" or creatureType == "" then
        EA_ApiLogFailure("RegisterChampionTemplate", "invalid creatureType")
        return false, "invalid creatureType"
    end
    if type(championData) ~= "table" then
        EA_ApiLogFailure("RegisterChampionTemplate", "championData must be a table")
        return false, "championData must be a table"
    end

    local p = EA._championProviders[providerId]
    if not p then
        return EA.RegisterChampionProvider(providerId, { [creatureType] = championData }, {})
    end

    p.championsByType = p.championsByType or {}
    p.championsByType[creatureType] = EA_CopyValue(championData)

    EA.ChampionProviderRevision = (EA.ChampionProviderRevision or 0) + 1
    EA.Emit("ChampionProvidersChanged", providerId)
    return true
end

function EA.GetChampionTemplate(creatureType)
    local candidates = {}
    local bestPriority = nil

    for _, id in ipairs(EA._championProviderOrder) do
        local p = EA._championProviders[id]
        if p and EA_ProviderIsActive(p) then
            local list = EA_GetChampionListForType(p, creatureType)
            if #list > 0 then
                local pr = tonumber(p.priority) or 0
                if bestPriority == nil or pr > bestPriority then
                    bestPriority = pr
                    candidates = {}
                end
                if pr == bestPriority then
                    for _, c in ipairs(list) do
                        if c and c.template and c.template ~= "" then
                            local candidate = EA_CopyValue(c)
                            candidate.providerId = id
                            table.insert(candidates, candidate)
                        end
                    end
                end
            end
        end
    end

    if #candidates == 0 then
        return nil
    end

    -- Weighted random among top-priority candidates
    local total = 0
    for _, c in ipairs(candidates) do
        total = total + (tonumber(c.weight) or 1)
    end
    local r = EA_ApiRandFloat() * total
    local acc = 0
    for _, c in ipairs(candidates) do
        acc = acc + (tonumber(c.weight) or 1)
        if r <= acc then
            return EA_CopyValue(c)
        end
    end
    return EA_CopyValue(candidates[1])
end

-- ========= Public API: Authored / Custom Ambush Definitions (D2-1 / D2-2) =========
function EA.RegisterAmbushDefinition(id, definition)
    local service = EA_GetAuthoredAmbushService()
    if type(service) ~= "table" or type(service.RegisterPublicDefinition) ~= "function" then
        EA_ApiLogFailure("RegisterAmbushDefinition", "service unavailable")
        return false, "service unavailable"
    end

    local ok, reason = service.RegisterPublicDefinition(id, definition)
    if ok ~= true then
        EA_ApiLogFailure("RegisterAmbushDefinition", reason)
        return false, reason
    end
    return true
end

function EA.UnregisterAmbushDefinition(id)
    local service = EA_GetAuthoredAmbushService()
    if type(service) ~= "table" or type(service.UnregisterPublicDefinition) ~= "function" then
        EA_ApiLogFailure("UnregisterAmbushDefinition", "service unavailable")
        return false, "service unavailable"
    end

    local ok, reason = service.UnregisterPublicDefinition(id)
    if ok ~= true then
        EA_ApiLogFailure("UnregisterAmbushDefinition", reason)
        return false, reason
    end
    return true
end

function EA.GetAmbushDefinition(id)
    local service = EA_GetAuthoredAmbushService()
    if type(service) ~= "table" or type(service.GetPublicDefinition) ~= "function" then
        return nil
    end

    local snapshot = service.GetPublicDefinition(id)
    if type(snapshot) ~= "table" then
        return nil
    end
    return EA_CopyValue(snapshot)
end

function EA.GetAmbushState()
    local hostCharacter = EA_GetApiHostCharacter()
    local getRegionForCharacter = EA and EA["EA_GetRegionForCharacter"]
    local isBlockedSafeZone = EA and EA["EA_IsCharacterInBlockedSafeZone"]
    local isAnyPartyInCombat = EA and EA["EA_IsAnyPartyInCombat"]
    local getDangerMs = EA and EA["EA_GetTimeInDangerAccumulatedMs"]
    local getDangerRiskUnit = EA and EA["EA_GetTimeInDangerRiskUnit"]
    local service = EA_GetAuthoredAmbushService()

    local activeRegion = nil
    local blockedSafeZone = false
    local inCamp = false
    local inCombat = false
    local cooldownActive = false
    local cooldownRemainingMs = 0
    local timeInDangerMinutes = 0
    local timeInDangerRiskPct = 0

    if hostCharacter and hostCharacter ~= "" then
        if type(getRegionForCharacter) == "function" then
            local okRegion, canonicalRegion = pcall(getRegionForCharacter, hostCharacter)
            if okRegion and type(canonicalRegion) == "string" and canonicalRegion ~= "" then
                activeRegion = canonicalRegion
            end
        end

        if type(isBlockedSafeZone) == "function" then
            local okBlockedSafe, out = pcall(isBlockedSafeZone, hostCharacter)
            blockedSafeZone = okBlockedSafe and out == true or false
        end

        inCamp = EA_IsApiCharacterInCamp(hostCharacter, activeRegion)

        if type(isAnyPartyInCombat) == "function" then
            local okCombat, out = pcall(isAnyPartyInCombat)
            inCombat = okCombat and out == true or false
        end

        cooldownActive, cooldownRemainingMs = EA_GetApiCooldownState(hostCharacter)

        if type(getDangerMs) == "function" then
            local okDangerMs, accumulatedMs = pcall(getDangerMs, hostCharacter)
            if okDangerMs and tonumber(accumulatedMs) ~= nil then
                timeInDangerMinutes = math.floor(((tonumber(accumulatedMs) or 0) / 60000) * 100 + 0.5) / 100
            end
        end

        if type(getDangerRiskUnit) == "function" then
            local okRisk, riskUnit = pcall(getDangerRiskUnit, hostCharacter)
            if okRisk and tonumber(riskUnit) ~= nil then
                timeInDangerRiskPct = math.floor((tonumber(riskUnit) * 100) * 10 + 0.5) / 10
            end
        end
    end

    local registeredDefinitionCount = 0
    if type(service) == "table" and type(service.GetPublicDefinitionCount) == "function" then
        local okCount, count = pcall(service.GetPublicDefinitionCount)
        if okCount and tonumber(count) ~= nil then
            registeredDefinitionCount = math.max(0, math.floor(tonumber(count) or 0))
        end
    end

    return {
        activeRegion = activeRegion,
        blockedSafeZone = blockedSafeZone,
        inCamp = inCamp,
        inCombat = inCombat,
        cooldownActive = cooldownActive,
        cooldownRemainingMs = math.max(0, math.floor(tonumber(cooldownRemainingMs) or 0)),
        pendingAmbushCount = EA_GetPendingAmbushCount(),
        registeredDefinitionCount = registeredDefinitionCount,
        timeInDangerMinutes = timeInDangerMinutes,
        timeInDangerRiskPct = timeInDangerRiskPct,
    }
end

function EA.TriggerAmbushDefinition(id, ctx)
    local definitionId = tostring(id or "")
    if definitionId == "" then
        EA_ApiLogFailure("TriggerAmbushDefinition", "invalid id")
        return false, "invalid id"
    end

    local okCtx, normalizedCtxOrReason = EA_BuildPublicTriggerCtx(ctx)
    if okCtx ~= true then
        EA_ApiLogFailure("TriggerAmbushDefinition", normalizedCtxOrReason)
        return false, normalizedCtxOrReason
    end

    local runtime = EA_GetAuthoredAmbushRuntime()
    if type(runtime) ~= "table" or type(runtime.TriggerPublicDefinition) ~= "function" then
        EA_ApiLogFailure("TriggerAmbushDefinition", "runtime unavailable")
        return false, "runtime unavailable"
    end

    local okTrigger, resultOrReason = runtime.TriggerPublicDefinition(definitionId, normalizedCtxOrReason)
    if okTrigger ~= true then
        EA_ApiLogFailure("TriggerAmbushDefinition", resultOrReason)
        return false, resultOrReason
    end
    if type(resultOrReason) ~= "table" then
        EA_ApiLogFailure("TriggerAmbushDefinition", "invalid trigger result")
        return false, "invalid trigger result"
    end
    return true, EA_CopyValue(resultOrReason)
end

function EA.TriggerCustomAmbush(payload)
    if type(payload) ~= "table" then
        EA_ApiLogFailure("TriggerCustomAmbush", "invalid payload")
        return false, "invalid payload"
    end

    local okCtx, normalizedCtxOrReason = EA_BuildPublicTriggerCtx(payload)
    if okCtx ~= true then
        EA_ApiLogFailure("TriggerCustomAmbush", normalizedCtxOrReason)
        return false, normalizedCtxOrReason
    end

    local runtime = EA_GetAuthoredAmbushRuntime()
    if type(runtime) ~= "table" or type(runtime.TriggerPublicCustom) ~= "function" then
        EA_ApiLogFailure("TriggerCustomAmbush", "runtime unavailable")
        return false, "runtime unavailable"
    end

    local okTrigger, resultOrReason = runtime.TriggerPublicCustom(payload, normalizedCtxOrReason)
    if okTrigger ~= true then
        EA_ApiLogFailure("TriggerCustomAmbush", resultOrReason)
        return false, resultOrReason
    end
    if type(resultOrReason) ~= "table" then
        EA_ApiLogFailure("TriggerCustomAmbush", "invalid trigger result")
        return false, "invalid trigger result"
    end
    return true, EA_CopyValue(resultOrReason)
end

-- ========= Public API: Trigger Ambush =========
function EA.TriggerAmbush(character, isLongRest)
    local triggerAmbush = EA_ResolveApiExport("TriggerAmbush")
    if type(triggerAmbush) == "function" then
        return triggerAmbush(character, isLongRest == true)
    end
    print("[EnemyAmbush][API] TriggerAmbush called, but TriggerAmbush export is not wired yet.")
end

-- ========= Public API: Reputation =========
function EA.GetReputation(creatureType)
    if not creatureType or creatureType == "" then
        return 0
    end
    local getRepTable = EA and EA["EA_GetCreatureReputationTable"]
    local repTable = (type(getRepTable) == "function") and getRepTable() or nil
    if type(repTable) ~= "table" then
        return 0
    end
    return tonumber(repTable[creatureType]) or 0
end

function EA.SetReputation(creatureType, value)
    if not creatureType or creatureType == "" then
        return
    end
    local getRepTable = EA and EA["EA_GetCreatureReputationTable"]
    local repTable = (type(getRepTable) == "function") and getRepTable() or nil
    if type(repTable) ~= "table" then
        return
    end
    local v = tonumber(value) or 0
    -- Clamp to <= 0 (the system treats 0 as neutral, negatives as hostility)
    if v > 0 then
        v = 0
    end
    repTable[creatureType] = v
    local saveReputation = EA and EA["SaveReputation"]
    if type(saveReputation) == "function" then
        pcall(saveReputation)
    end
    EA.Emit("ReputationChanged", creatureType, v)
end

function EA.ModifyReputation(creatureType, delta)
    if not creatureType or creatureType == "" then
        return
    end
    local cur = EA.GetReputation(creatureType)
    local d = tonumber(delta) or 0
    EA.SetReputation(creatureType, cur + d)
end

EA.API = EA.API or {}
EA.API.API_VERSION = EA.API_VERSION
EA.API.On = EA.On
EA.API.Off = EA.Off
EA.API.Once = EA.Once
EA.API.Emit = EA.Emit
EA.API.HasEnemyProvider = EA.HasEnemyProvider
EA.API.GetEnemyProvider = EA.GetEnemyProvider
EA.API.ListEnemyProviders = EA.ListEnemyProviders
EA.API.IsEnemyProviderActive = EA.IsEnemyProviderActive
EA.API.RegisterEnemyProvider = EA.RegisterEnemyProvider
EA.API.UnregisterEnemyProvider = EA.UnregisterEnemyProvider
EA.API.RegisterEnemyTemplate = EA.RegisterEnemyTemplate
EA.API.InvalidateEnemyProviderCache = EA.InvalidateEnemyProviderCache
EA.API.RegisterXPCloneMapping = EA.RegisterXPCloneMapping
EA.API.UnregisterXPCloneMappings = EA.UnregisterXPCloneMappings
EA.API.GetActiveEnemyEntries = EA.GetActiveEnemyEntries
EA.API.HasChampionProvider = EA.HasChampionProvider
EA.API.GetChampionProvider = EA.GetChampionProvider
EA.API.ListChampionProviders = EA.ListChampionProviders
EA.API.IsChampionProviderActive = EA.IsChampionProviderActive
EA.API.RegisterChampionProvider = EA.RegisterChampionProvider
EA.API.UnregisterChampionProvider = EA.UnregisterChampionProvider
EA.API.RegisterChampionTemplate = EA.RegisterChampionTemplate
EA.API.GetChampionTemplate = EA.GetChampionTemplate
EA.API.RegisterAmbushDefinition = EA.RegisterAmbushDefinition
EA.API.UnregisterAmbushDefinition = EA.UnregisterAmbushDefinition
EA.API.GetAmbushDefinition = EA.GetAmbushDefinition
EA.API.GetAmbushState = EA.GetAmbushState
EA.API.TriggerAmbushDefinition = EA.TriggerAmbushDefinition
EA.API.TriggerCustomAmbush = EA.TriggerCustomAmbush
EA.API.TriggerAmbush = EA.TriggerAmbush
EA.API.GetReputation = EA.GetReputation
EA.API.SetReputation = EA.SetReputation
EA.API.ModifyReputation = EA.ModifyReputation

-- Queue-based pre-API registration (_G.EA_API_QUEUE) has been removed.
-- Providers must register through EA.RegisterEnemyProvider/EA.RegisterChampionProvider.
