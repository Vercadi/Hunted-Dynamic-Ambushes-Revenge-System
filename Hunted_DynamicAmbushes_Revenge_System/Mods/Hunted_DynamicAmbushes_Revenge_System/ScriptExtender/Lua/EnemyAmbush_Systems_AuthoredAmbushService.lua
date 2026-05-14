EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

local INTERNAL_TRIGGER_KINDS = {
    rest = true,
    region_entry = true,
    internal_call = true,
}

local PUBLIC_TRIGGER_KINDS = {
    external = true,
    rest = true,
    region_entry = true,
}

local PUBLIC_SPAWN_MODES = {
    pool_roll = true,
    custom_entries = true,
}

local PUBLIC_HOSTILITY_MODES = {
    default = true,
    immediate = true,
    deferred = true,
}

local PUBLIC_REPUTATION_MODES = {
    default = true,
    none = true,
}

local PUBLIC_REWARD_MODES = {
    default = true,
    no_loot = true,
    no_xp = true,
    scripted = true,
}

local PUBLIC_CUSTOM_PAYLOAD_KEYS = {
    enabled = true,
    once = true,
    priority = true,
    triggerKinds = true,
    gates = true,
    trigger = true,
    spawn = true,
    policies = true,
    presentation = true,
    character = true,
    flowLabel = true,
    source = true,
}

local PUBLIC_CUSTOM_GATES_KEYS = {
    minPartyLevel = true,
    maxPartyLevel = true,
    allowedRegions = true,
    blockedRegions = true,
    allowInCamp = true,
    allowInBlockedSafeZone = true,
}

local PUBLIC_CUSTOM_TRIGGER_KEYS = {
    external = true,
}

local PUBLIC_CUSTOM_SPAWN_KEYS = {
    mode = true,
    themeKey = true,
    tier = true,
    entries = true,
}

local PUBLIC_CUSTOM_ENTRY_KEYS = {
    template = true,
    count = true,
    displayName = true,
    level = true,
    creatureType = true,
}

local PUBLIC_CUSTOM_POLICIES_KEYS = {
    hostilityMode = true,
    reputationMode = true,
    rewardMode = true,
}

local PUBLIC_CUSTOM_PRESENTATION_KEYS = {
    introLoca = true,
    postCombatLoca = true,
    flowLabel = true,
}

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for key, inner in pairs(value) do
        out[key] = DeepCopy(inner)
    end
    return out
end

local function NormalizeTriggerKinds(value)
    local list = {}
    local seen = {}

    local function addKind(kind)
        kind = tostring(kind or "")
        if kind == "" or seen[kind] or INTERNAL_TRIGGER_KINDS[kind] ~= true then
            return
        end
        seen[kind] = true
        list[#list + 1] = kind
    end

    if type(value) == "table" then
        if #value > 0 then
            for _, kind in ipairs(value) do
                addKind(kind)
            end
        else
            for kind, enabled in pairs(value) do
                if enabled == true then
                    addKind(kind)
                end
            end
        end
    end

    if #list == 0 then
        addKind("rest")
    end

    return list, seen
end

local function NormalizePublicTriggerKinds(value)
    if type(value) ~= "table" then
        return nil, "invalid triggerKinds"
    end

    local list = {}
    local seen = {}
    local invalidKind = false

    local function addKind(kind)
        kind = tostring(kind or "")
        if kind == "" or seen[kind] then
            return
        end
        if PUBLIC_TRIGGER_KINDS[kind] ~= true then
            invalidKind = true
            return
        end
        seen[kind] = true
        list[#list + 1] = kind
    end

    if #value > 0 then
        for _, kind in ipairs(value) do
            addKind(kind)
        end
    else
        for kind, enabled in pairs(value) do
            if enabled == true then
                addKind(kind)
            end
        end
    end

    if invalidKind or #list == 0 then
        return nil, "invalid triggerKinds"
    end

    return list, seen
end

local function NormalizeRegionSet(value)
    if type(value) ~= "table" then
        return nil
    end

    local out = {}
    if #value > 0 then
        for _, region in ipairs(value) do
            region = tostring(region or "")
            if region ~= "" then
                out[region] = true
            end
        end
    else
        for region, allowed in pairs(value) do
            region = tostring(region or "")
            if region ~= "" and allowed == true then
                out[region] = true
            end
        end
    end

    if next(out) == nil then
        return nil
    end
    return out
end

local function NormalizePublicOptionalString(value, fieldName)
    if value == nil then
        return nil
    end
    if type(value) ~= "string" then
        return nil, "invalid " .. tostring(fieldName or "string")
    end
    if value == "" then
        return nil
    end
    return value
end

local function HasUnsupportedKeys(value, allowedKeys)
    if type(value) ~= "table" or type(allowedKeys) ~= "table" then
        return false
    end
    for key in pairs(value) do
        if type(key) ~= "string" or allowedKeys[key] ~= true then
            return true
        end
    end
    return false
end

local function NormalizePublicRegionList(value, fieldName)
    if value == nil then
        return nil
    end
    if type(value) ~= "table" then
        return nil, "invalid " .. tostring(fieldName or "regions")
    end

    local list = {}
    local seen = {}

    local function addRegion(region)
        region = tostring(region or "")
        if region == "" or not region:match("^[A-Za-z0-9_]+$") then
            return false
        end
        if not seen[region] then
            seen[region] = true
            list[#list + 1] = region
        end
        return true
    end

    if #value > 0 then
        for _, region in ipairs(value) do
            if not addRegion(region) then
                return nil, "invalid " .. tostring(fieldName or "regions")
            end
        end
    else
        for region, enabled in pairs(value) do
            if enabled == true then
                if not addRegion(region) then
                    return nil, "invalid " .. tostring(fieldName or "regions")
                end
            elseif enabled ~= false and enabled ~= nil then
                return nil, "invalid " .. tostring(fieldName or "regions")
            end
        end
    end

    if #list == 0 then
        return nil
    end
    return list
end

local function NormalizePublicRestTypes(value)
    if value == nil then
        return nil
    end
    if type(value) ~= "table" then
        return nil, "invalid restTypes"
    end

    local list = {}
    local seen = {}
    for _, restType in ipairs(value) do
        restType = tostring(restType or "")
        if restType ~= "short" and restType ~= "long" then
            return nil, "invalid restTypes"
        end
        if not seen[restType] then
            seen[restType] = true
            list[#list + 1] = restType
        end
    end

    if #list == 0 then
        return nil, "invalid restTypes"
    end
    return list
end

local function NormalizePublicChancePct(value, fieldName)
    if value == nil then
        return nil
    end
    local numeric = tonumber(value)
    if numeric == nil or numeric < 0 or numeric > 100 then
        return nil, "invalid " .. tostring(fieldName or "chancePct")
    end
    return numeric
end

local function NormalizePublicCooldownMinutes(value)
    if value == nil then
        return nil
    end
    local numeric = tonumber(value)
    if numeric == nil or numeric < 0 then
        return nil, "invalid cooldownMinutes"
    end
    return numeric
end

local function NormalizePublicLevelBound(value, fieldName)
    if value == nil then
        return nil
    end
    local numeric = tonumber(value)
    if numeric == nil then
        return nil, "invalid " .. tostring(fieldName or "level")
    end
    return numeric
end

local function NormalizePublicPolicies(value)
    local policies = type(value) == "table" and value or {}
    local hostilityMode = tostring(policies.hostilityMode or "default")
    local reputationMode = tostring(policies.reputationMode or "default")
    local rewardMode = tostring(policies.rewardMode or "default")

    if PUBLIC_HOSTILITY_MODES[hostilityMode] ~= true then
        return nil, "invalid hostilityMode"
    end
    if PUBLIC_REPUTATION_MODES[reputationMode] ~= true then
        return nil, "invalid reputationMode"
    end
    if PUBLIC_REWARD_MODES[rewardMode] ~= true then
        return nil, "invalid rewardMode"
    end

    return {
        hostilityMode = hostilityMode,
        reputationMode = reputationMode,
        rewardMode = rewardMode,
    }
end

local function NormalizePublicPresentation(value)
    local presentation = type(value) == "table" and value or {}
    local introLoca, introErr = NormalizePublicOptionalString(presentation.introLoca, "presentation.introLoca")
    if introErr then
        return nil, introErr
    end
    local postCombatLoca, postErr = NormalizePublicOptionalString(presentation.postCombatLoca, "presentation.postCombatLoca")
    if postErr then
        return nil, postErr
    end
    local flowLabel, flowErr = NormalizePublicOptionalString(presentation.flowLabel, "presentation.flowLabel")
    if flowErr then
        return nil, flowErr
    end

    return {
        introLoca = introLoca,
        postCombatLoca = postCombatLoca,
        flowLabel = flowLabel,
    }
end

local function NormalizePublicSpawnEntries(entries)
    if type(entries) ~= "table" then
        return nil, "invalid entries"
    end

    local out = {}
    for _, entry in ipairs(entries) do
        if type(entry) ~= "table" then
            return nil, "invalid entries"
        end

        local template = tostring(entry.template or "")
        if template == "" then
            return nil, "invalid entries"
        end

        local normalizedEntry = {
            template = template,
        }

        if entry.count ~= nil then
            local count = tonumber(entry.count)
            if count == nil or count < 1 then
                return nil, "invalid entries"
            end
            normalizedEntry.count = math.floor(count)
        end

        if entry.displayName ~= nil then
            local displayName, displayErr = NormalizePublicOptionalString(entry.displayName, "entries.displayName")
            if displayErr then
                return nil, "invalid entries"
            end
            normalizedEntry.displayName = displayName
        end

        if entry.level ~= nil then
            local level = tonumber(entry.level)
            if level == nil or level < 1 then
                return nil, "invalid entries"
            end
            normalizedEntry.level = math.floor(level)
        end

        if entry.creatureType ~= nil then
            local creatureType, creatureErr = NormalizePublicOptionalString(entry.creatureType, "entries.creatureType")
            if creatureErr then
                return nil, "invalid entries"
            end
            normalizedEntry.creatureType = creatureType
        end

        out[#out + 1] = normalizedEntry
    end

    if #out == 0 then
        return nil, "invalid entries"
    end

    return out
end

local function NormalizePublicSpawn(value)
    if type(value) ~= "table" then
        return nil, "invalid spawn"
    end

    local mode = tostring(value.mode or "")
    if PUBLIC_SPAWN_MODES[mode] ~= true then
        return nil, "invalid spawn.mode"
    end

    local themeKey, themeErr = NormalizePublicOptionalString(value.themeKey, "spawn.themeKey")
    if themeErr then
        return nil, themeErr
    end
    local tier, tierErr = NormalizePublicOptionalString(value.tier, "spawn.tier")
    if tierErr then
        return nil, tierErr
    end

    local out = {
        mode = mode,
        themeKey = themeKey,
        tier = tier,
    }

    if value.allowChampion == true then
        out.allowChampion = true
    end
    if value.forceChampion == true then
        out.forceChampion = true
    end

    if mode == "custom_entries" then
        local entries, entriesErr = NormalizePublicSpawnEntries(value.entries)
        if entriesErr then
            return nil, entriesErr
        end
        out.entries = entries
    end

    return out
end

local function NormalizePublicTrigger(value, triggerKindsSet)
    local trigger = type(value) == "table" and value or {}
    local out = {}

    if triggerKindsSet.external == true then
        out.external = {}
    end

    if triggerKindsSet.rest == true then
        local restSource = type(trigger.rest) == "table" and trigger.rest or trigger
        local rest = {}
        local restTypes, restTypesErr = NormalizePublicRestTypes(restSource.restTypes)
        if restTypesErr then
            return nil, restTypesErr
        end
        local chancePct, chanceErr = NormalizePublicChancePct(restSource.chancePct, "rest.chancePct")
        if chanceErr then
            return nil, chanceErr
        end
        if restTypes then
            rest.restTypes = restTypes
        end
        if chancePct ~= nil then
            rest.chancePct = chancePct
        end
        out.rest = rest
    end

    if triggerKindsSet.region_entry == true then
        local regionSource = trigger
        if type(trigger.region_entry) == "table" then
            regionSource = trigger.region_entry
        elseif type(trigger.regionEntry) == "table" then
            regionSource = trigger.regionEntry
        end

        local regionEntry = {}
        local regions, regionsErr = NormalizePublicRegionList(regionSource.regions, "trigger.regions")
        if regionsErr then
            return nil, regionsErr
        end
        local chancePct, chanceErr = NormalizePublicChancePct(regionSource.chancePct, "region_entry.chancePct")
        if chanceErr then
            return nil, chanceErr
        end
        local cooldownMinutes, cooldownErr = NormalizePublicCooldownMinutes(regionSource.cooldownMinutes)
        if cooldownErr then
            return nil, cooldownErr
        end
        if regions then
            regionEntry.regions = regions
        end
        if chancePct ~= nil then
            regionEntry.chancePct = chancePct
        end
        if cooldownMinutes ~= nil then
            regionEntry.cooldownMinutes = cooldownMinutes
        end
        out.region_entry = regionEntry
    end

    return out
end

local function NormalizePublicGates(value)
    local gates = type(value) == "table" and value or {}
    local minPartyLevel, minErr = NormalizePublicLevelBound(gates.minPartyLevel, "gates.minPartyLevel")
    if minErr then
        return nil, minErr
    end
    local maxPartyLevel, maxErr = NormalizePublicLevelBound(gates.maxPartyLevel, "gates.maxPartyLevel")
    if maxErr then
        return nil, maxErr
    end
    if minPartyLevel and maxPartyLevel and minPartyLevel > maxPartyLevel then
        return nil, "invalid level range"
    end

    local allowedRegions, allowedErr = NormalizePublicRegionList(gates.allowedRegions, "gates.allowedRegions")
    if allowedErr then
        return nil, allowedErr
    end
    local blockedRegions, blockedErr = NormalizePublicRegionList(gates.blockedRegions, "gates.blockedRegions")
    if blockedErr then
        return nil, blockedErr
    end

    return {
        minPartyLevel = minPartyLevel,
        maxPartyLevel = maxPartyLevel,
        allowedRegions = allowedRegions,
        blockedRegions = blockedRegions,
        allowInCamp = (gates.allowInCamp == true),
        allowInBlockedSafeZone = (gates.allowInBlockedSafeZone == true),
    }
end

local function NormalizePublicDefinition(definitionId, raw)
    if type(raw) ~= "table" then
        return nil, "definition must be a table"
    end

    local id = tostring(definitionId or "")
    if id == "" then
        return nil, "invalid id"
    end

    if raw.id ~= nil then
        local embeddedId = tostring(raw.id or "")
        if embeddedId ~= "" and embeddedId ~= id then
            return nil, "id mismatch"
        end
    end

    local triggerKinds, triggerKindsSetOrReason = NormalizePublicTriggerKinds(raw.triggerKinds)
    if not triggerKinds then
        return nil, triggerKindsSetOrReason
    end
    local triggerKindsSet = triggerKindsSetOrReason

    local gates, gatesErr = NormalizePublicGates(raw.gates)
    if gatesErr then
        return nil, gatesErr
    end

    local trigger, triggerErr = NormalizePublicTrigger(raw.trigger, triggerKindsSet)
    if triggerErr then
        return nil, triggerErr
    end

    local spawn, spawnErr = NormalizePublicSpawn(raw.spawn)
    if spawnErr then
        return nil, spawnErr
    end

    local policies, policiesErr = NormalizePublicPolicies(raw.policies)
    if policiesErr then
        return nil, policiesErr
    end

    local presentation, presentationErr = NormalizePublicPresentation(raw.presentation)
    if presentationErr then
        return nil, presentationErr
    end

    return {
        enabled = (raw.enabled ~= false),
        once = (raw.once == true),
        priority = tonumber(raw.priority) or 0,
        triggerKinds = triggerKinds,
        gates = gates,
        trigger = trigger,
        spawn = spawn,
        policies = policies,
        presentation = presentation,
    }
end

local function NormalizePublicCustomPayload(raw)
    if type(raw) ~= "table" then
        return nil, "invalid payload"
    end

    if HasUnsupportedKeys(raw, PUBLIC_CUSTOM_PAYLOAD_KEYS) then
        return nil, "unsupported payload fields"
    end
    if type(raw.gates) == "table" and HasUnsupportedKeys(raw.gates, PUBLIC_CUSTOM_GATES_KEYS) then
        return nil, "unsupported gates fields"
    end
    if type(raw.policies) == "table" and HasUnsupportedKeys(raw.policies, PUBLIC_CUSTOM_POLICIES_KEYS) then
        return nil, "unsupported policies fields"
    end
    if type(raw.presentation) == "table" and HasUnsupportedKeys(raw.presentation, PUBLIC_CUSTOM_PRESENTATION_KEYS) then
        return nil, "unsupported presentation fields"
    end
    if raw.trigger ~= nil then
        if type(raw.trigger) ~= "table" then
            return nil, "invalid trigger"
        end
        if HasUnsupportedKeys(raw.trigger, PUBLIC_CUSTOM_TRIGGER_KEYS) then
            return nil, "unsupported trigger fields"
        end
        if raw.trigger.external ~= nil then
            if type(raw.trigger.external) ~= "table" or next(raw.trigger.external) ~= nil then
                return nil, "invalid trigger"
            end
        end
    end

    local providedTriggerKinds = raw.triggerKinds
    if providedTriggerKinds == nil then
        providedTriggerKinds = { "external" }
    else
        local triggerKinds, triggerKindsSetOrReason = NormalizePublicTriggerKinds(providedTriggerKinds)
        if not triggerKinds then
            return nil, triggerKindsSetOrReason
        end
        if #triggerKinds ~= 1 or triggerKindsSetOrReason.external ~= true then
            return nil, "invalid triggerKinds"
        end
        providedTriggerKinds = triggerKinds
    end

    local spawn = type(raw.spawn) == "table" and raw.spawn or nil
    if type(spawn) == "table" and tostring(spawn.mode or "") == "custom_entries" then
        if HasUnsupportedKeys(spawn, PUBLIC_CUSTOM_SPAWN_KEYS) then
            return nil, "unsupported spawn fields"
        end
        local entries = spawn.entries
        if type(entries) ~= "table" then
            return nil, "invalid entries"
        end
        for _, entry in ipairs(entries) do
            if type(entry) ~= "table" then
                return nil, "invalid entries"
            end
            if HasUnsupportedKeys(entry, PUBLIC_CUSTOM_ENTRY_KEYS) then
                return nil, "unsupported entries fields"
            end
        end
    end

    local normalized, normalizeErr = NormalizePublicDefinition("__public_custom__", {
        enabled = raw.enabled,
        once = raw.once,
        priority = raw.priority,
        triggerKinds = providedTriggerKinds,
        gates = raw.gates,
        trigger = raw.trigger,
        spawn = raw.spawn,
        policies = raw.policies,
        presentation = raw.presentation,
    })
    if not normalized then
        return nil, normalizeErr
    end
    if tostring(normalized.spawn and normalized.spawn.mode or "") ~= "custom_entries" then
        return nil, "unsupported spawn.mode"
    end
    return normalized
end

local function NormalizeSpawnEntries(entries)
    local out = {}
    if type(entries) ~= "table" then
        return out
    end

    for _, entry in ipairs(entries) do
        if type(entry) == "table" then
            out[#out + 1] = DeepCopy(entry)
        end
    end
    return out
end

local function NormalizeRegionEntryTriggerConfig(value)
    local cfg = type(value) == "table" and value or {}
    return {
        regions = NormalizeRegionSet(cfg.regions),
        requireRegionChange = (cfg.requireRegionChange ~= false),
        allowBlockedRegion = (cfg.allowBlockedRegion == true),
        allowCamp = (cfg.allowCamp == true),
        allowBlockedSafeZone = (cfg.allowBlockedSafeZone == true),
    }
end

local function NormalizeDefinition(raw)
    if type(raw) ~= "table" then
        return nil
    end

    local id = tostring(raw.id or "")
    if id == "" then
        return nil
    end

    local triggerKinds, triggerKindSet = NormalizeTriggerKinds(raw.triggerKinds)
    local gates = type(raw.gates) == "table" and raw.gates or {}
    local trigger = type(raw.trigger) == "table" and raw.trigger or {}
    local spawn = type(raw.spawn) == "table" and raw.spawn or {}
    local presentation = type(raw.presentation) == "table" and raw.presentation or {}
    local internal = type(raw.internal) == "table" and raw.internal or {}

    local normalized = {
        id = id,
        label = tostring(raw.label or id),
        enabled = (raw.enabled ~= false),
        once = (raw.once == true),
        priority = tonumber(raw.priority) or 0,
        triggerKinds = triggerKinds,
        _triggerKindSet = triggerKindSet,
        gates = {
            minPartyLevel = tonumber(gates.minPartyLevel),
            maxPartyLevel = tonumber(gates.maxPartyLevel),
            allowedRegions = NormalizeRegionSet(gates.allowedRegions),
            blockedRegions = NormalizeRegionSet(gates.blockedRegions),
            internalMatcherId = tostring(gates.internalMatcherId or ""),
        },
        trigger = {
            rest = DeepCopy(type(trigger.rest) == "table" and trigger.rest or {}),
            regionEntry = NormalizeRegionEntryTriggerConfig(trigger.regionEntry),
            internal = DeepCopy(type(trigger.internal) == "table" and trigger.internal or {}),
        },
        spawn = {
            mode = tostring(spawn.mode or "fixed_spawn_specs"),
            theme = tostring(spawn.theme or ""),
            entries = NormalizeSpawnEntries(spawn.entries),
        },
        presentation = {
            introText = tostring(presentation.introText or ""),
            completionText = tostring(presentation.completionText or ""),
            postCombatMessage = tostring(presentation.postCombatMessage or ""),
            onboardingAfterCombat = (presentation.onboardingAfterCombat == true),
        },
        internal = DeepCopy(internal),
    }

    if normalized.gates.internalMatcherId == "" then
        normalized.gates.internalMatcherId = nil
    end

    return normalized
end

function M.Build(_deps)
    local deps = type(_deps) == "table" and _deps or {}
    local depsEA = type(deps.EA) == "table" and deps.EA or EA
    local EA_NowMs = type(depsEA) == "table" and type(depsEA["EA_NowMs"]) == "function"
        and depsEA["EA_NowMs"]
        or function()
            return 0
        end
    local definitionsById = {}
    local orderedDefinitions = {}
    local publicDefinitionsById = {}
    local publicOrderedIds = {}

    local function PublicTriggerKindsContain(definition, kind)
        if type(definition) ~= "table" or type(definition.triggerKinds) ~= "table" then
            return false
        end
        for _, triggerKind in ipairs(definition.triggerKinds) do
            if tostring(triggerKind or "") == tostring(kind or "") then
                return true
            end
        end
        return false
    end

    local function PublicRegionListContains(list, region)
        region = tostring(region or "")
        if region == "" or type(list) ~= "table" then
            return false
        end
        for _, candidate in ipairs(list) do
            if tostring(candidate or "") == region then
                return true
            end
        end
        return false
    end

    local function SortPublicDefinitionIds()
        table.sort(publicOrderedIds, function(a, b)
            local aDefinition = publicDefinitionsById[a]
            local bDefinition = publicDefinitionsById[b]
            local aPriority = tonumber(aDefinition and aDefinition.definition and aDefinition.definition.priority) or 0
            local bPriority = tonumber(bDefinition and bDefinition.definition and bDefinition.definition.priority) or 0
            if aPriority == bPriority then
                return tostring(a or "") < tostring(b or "")
            end
            return aPriority > bPriority
        end)
    end

    local function ReplaceDefinitions(definitions)
        definitionsById = {}
        orderedDefinitions = {}

        if type(definitions) ~= "table" then
            return 0
        end

        for _, raw in ipairs(definitions) do
            local definition = NormalizeDefinition(raw)
            if definition then
                definitionsById[definition.id] = definition
                orderedDefinitions[#orderedDefinitions + 1] = definition
            end
        end

        table.sort(orderedDefinitions, function(a, b)
            local aPriority = tonumber(a and a.priority) or 0
            local bPriority = tonumber(b and b.priority) or 0
            if aPriority == bPriority then
                return tostring(a and a.id or "") < tostring(b and b.id or "")
            end
            return aPriority > bPriority
        end)

        return #orderedDefinitions
    end

    local function GetDefinition(definitionId)
        local definition = definitionsById[tostring(definitionId or "")]
        if type(definition) ~= "table" then
            return nil
        end
        return DeepCopy(definition)
    end

    local function RegisterPublicDefinition(definitionId, rawDefinition)
        definitionId = tostring(definitionId or "")
        if definitionId == "" then
            return false, "invalid id"
        end
        if definitionsById[definitionId] ~= nil then
            return false, "id reserved"
        end

        local normalized, reason = NormalizePublicDefinition(definitionId, rawDefinition)
        if type(normalized) ~= "table" then
            return false, tostring(reason or "invalid definition")
        end

        local entry = publicDefinitionsById[definitionId]
        local meta = type(entry) == "table" and type(entry.meta) == "table" and DeepCopy(entry.meta) or {}
        if meta.triggerCount == nil then
            meta.triggerCount = 0
        end
        if meta.completed == nil then
            meta.completed = false
        end

        publicDefinitionsById[definitionId] = {
            definition = normalized,
            meta = meta,
        }

        if not entry then
            publicOrderedIds[#publicOrderedIds + 1] = definitionId
        end
        SortPublicDefinitionIds()

        return true
    end

    local function UnregisterPublicDefinition(definitionId)
        definitionId = tostring(definitionId or "")
        if definitionId == "" then
            return false, "invalid id"
        end
        if publicDefinitionsById[definitionId] == nil then
            return false, "definition not found"
        end

        publicDefinitionsById[definitionId] = nil
        for index, value in ipairs(publicOrderedIds) do
            if value == definitionId then
                table.remove(publicOrderedIds, index)
                break
            end
        end

        return true
    end

    local function GetPublicDefinition(definitionId)
        local entry = publicDefinitionsById[tostring(definitionId or "")]
        if type(entry) ~= "table" or type(entry.definition) ~= "table" then
            return nil
        end

        local meta = type(entry.meta) == "table" and entry.meta or {}
        return {
            id = tostring(definitionId or ""),
            definition = DeepCopy(entry.definition),
            registered = true,
            enabled = (entry.definition.enabled == true),
            once = (entry.definition.once == true),
            triggerCount = tonumber(meta.triggerCount) or 0,
            lastTriggeredAtMs = tonumber(meta.lastTriggeredAtMs),
            completed = (meta.completed == true),
        }
    end

    local function GetPublicDefinitionCount()
        return #publicOrderedIds
    end

    local function ValidatePublicDefinitionTrigger(definitionId, ctx)
        definitionId = tostring(definitionId or "")
        if definitionId == "" then
            return false, "invalid id"
        end
        if type(ctx) ~= "table" then
            return false, "invalid ctx"
        end

        local character = tostring(ctx.character or "")
        if character == "" then
            return false, "invalid character"
        end

        local entry = publicDefinitionsById[definitionId]
        if type(entry) ~= "table" or type(entry.definition) ~= "table" then
            return false, "definition not found"
        end

        local definition = entry.definition
        local meta = type(entry.meta) == "table" and entry.meta or {}
        if definition.enabled ~= true then
            return false, "disabled"
        end
        if PublicTriggerKindsContain(definition, "external") ~= true then
            return false, "definition not externally triggerable"
        end
        if definition.once == true and meta.completed == true then
            return false, "completed"
        end

        local level = tonumber(ctx.level)
        local gates = type(definition.gates) == "table" and definition.gates or {}
        if gates.minPartyLevel ~= nil and level ~= nil and level < tonumber(gates.minPartyLevel) then
            return false, "below_min_level"
        end
        if gates.maxPartyLevel ~= nil and level ~= nil and level > tonumber(gates.maxPartyLevel) then
            return false, "above_max_level"
        end

        local region = tostring(ctx.region or "")
        if type(gates.allowedRegions) == "table" and #gates.allowedRegions > 0 and not PublicRegionListContains(gates.allowedRegions, region) then
            return false, "region_not_allowed"
        end
        if type(gates.blockedRegions) == "table" and #gates.blockedRegions > 0 and PublicRegionListContains(gates.blockedRegions, region) then
            return false, "region_blocked"
        end
        if ctx.inCamp == true and gates.allowInCamp ~= true then
            return false, "camp_blocked"
        end
        if ctx.inBlockedSafeZone == true and gates.allowInBlockedSafeZone ~= true then
            return false, "safe_zone_blocked"
        end
        if ctx.inCombat == true then
            return false, "in_combat"
        end

        return true, DeepCopy(definition)
    end

    local function MarkPublicDefinitionTriggered(definitionId, opts)
        definitionId = tostring(definitionId or "")
        if definitionId == "" then
            return false, "invalid id"
        end

        local entry = publicDefinitionsById[definitionId]
        if type(entry) ~= "table" or type(entry.definition) ~= "table" then
            return false, "definition not found"
        end

        entry.meta = type(entry.meta) == "table" and entry.meta or {}
        entry.meta.triggerCount = math.max(0, math.floor(tonumber(entry.meta.triggerCount) or 0)) + 1
        entry.meta.lastTriggeredAtMs = tonumber(type(opts) == "table" and opts.atMs or nil) or tonumber(EA_NowMs()) or 0
        if entry.definition.once == true or (type(opts) == "table" and opts.completed == true) then
            entry.meta.completed = true
        end
        return true
    end

    local function ListDefinitions()
        local out = {}
        for _, definition in ipairs(orderedDefinitions) do
            out[#out + 1] = DeepCopy(definition)
        end
        return out
    end

    local function MatchesGeneric(definition, ctx, state)
        if type(definition) ~= "table" or type(ctx) ~= "table" then
            return false, "invalid_definition_or_context"
        end
        if definition.enabled ~= true then
            return false, "disabled"
        end
        if definition.once == true and type(state) == "table" and type(state.completed) == "table" and state.completed[definition.id] ~= nil then
            return false, "completed"
        end

        local triggerKind = tostring(ctx.triggerKind or "rest")
        if definition._triggerKindSet[triggerKind] ~= true then
            return false, "trigger_kind_mismatch"
        end

        local level = tonumber(ctx.level)
        if definition.gates.minPartyLevel and level and level < definition.gates.minPartyLevel then
            return false, "below_min_level"
        end
        if definition.gates.maxPartyLevel and level and level > definition.gates.maxPartyLevel then
            return false, "above_max_level"
        end

        local region = tostring(ctx.region or "")
        if type(definition.gates.allowedRegions) == "table" and next(definition.gates.allowedRegions) ~= nil then
            if region == "" or definition.gates.allowedRegions[region] ~= true then
                return false, "region_not_allowed"
            end
        end
        if type(definition.gates.blockedRegions) == "table" and next(definition.gates.blockedRegions) ~= nil then
            if region ~= "" and definition.gates.blockedRegions[region] == true then
                return false, "region_blocked"
            end
        end

        if triggerKind == "rest" then
            local restCfg = definition.trigger.rest or {}
            if restCfg.allowLongRest == false and ctx.isLongRest == true then
                return false, "long_rest_blocked"
            end
            if type(restCfg.restTypes) == "table" and #restCfg.restTypes > 0 then
                local currentRestType = ctx.isLongRest == true and "long" or "short"
                local matchedRestType = false
                for _, restType in ipairs(restCfg.restTypes) do
                    if tostring(restType or "") == currentRestType then
                        matchedRestType = true
                        break
                    end
                end
                if not matchedRestType then
                    return false, "rest_type_mismatch"
                end
            end
        elseif triggerKind == "region_entry" then
            local regionEntryCfg = definition.trigger.regionEntry or {}
            local previousRegion = tostring(ctx.previousRegion or "")
            if regionEntryCfg.requireRegionChange ~= false then
                if region == "" then
                    return false, "region_unavailable"
                end
                if previousRegion == "" then
                    return false, "region_first_observation"
                end
                if previousRegion == region then
                    return false, "region_unchanged"
                end
            end
            if type(regionEntryCfg.regions) == "table" and next(regionEntryCfg.regions) ~= nil then
                if region == "" or regionEntryCfg.regions[region] ~= true then
                    return false, "region_entry_region_mismatch"
                end
            end
            if ctx.regionBlocked == true and regionEntryCfg.allowBlockedRegion ~= true then
                return false, "region_policy_blocked"
            end
            if ctx.regionIsCamp == true and regionEntryCfg.allowCamp ~= true then
                return false, "camp_blocked"
            end
            if ctx.inBlockedSafeZone == true and regionEntryCfg.allowBlockedSafeZone ~= true then
                return false, "safe_zone_blocked"
            end
        end

        return true, "generic_match"
    end

    local function FindFirstMatchingDefinition(ctx, state, opts)
        opts = type(opts) == "table" and opts or {}
        local internalMatchers = type(opts.internalMatchers) == "table" and opts.internalMatchers or {}

        for _, definition in ipairs(orderedDefinitions) do
            local matched = MatchesGeneric(definition, ctx, state)
            if matched then
                local matcherId = definition.gates.internalMatcherId
                if matcherId then
                    local matcher = internalMatchers[matcherId]
                    if type(matcher) == "function" then
                        local okMatcher, result = pcall(matcher, definition, ctx, state)
                        if okMatcher and result == true then
                            return DeepCopy(definition), "matched"
                        end
                    end
                else
                    return DeepCopy(definition), "matched"
                end
            end
        end

        return nil, "no_match"
    end

    return {
        ReplaceDefinitions = ReplaceDefinitions,
        GetDefinition = GetDefinition,
        ListDefinitions = ListDefinitions,
        FindFirstMatchingDefinition = FindFirstMatchingDefinition,
        MatchesGeneric = MatchesGeneric,
        RegisterPublicDefinition = RegisterPublicDefinition,
        UnregisterPublicDefinition = UnregisterPublicDefinition,
        GetPublicDefinition = GetPublicDefinition,
        GetPublicDefinitionCount = GetPublicDefinitionCount,
        NormalizePublicCustomPayload = NormalizePublicCustomPayload,
        ValidatePublicDefinitionTrigger = ValidatePublicDefinitionTrigger,
        MarkPublicDefinitionTriggered = MarkPublicDefinitionTriggered,
        SchemaVersion = 5,
    }
end

return M
