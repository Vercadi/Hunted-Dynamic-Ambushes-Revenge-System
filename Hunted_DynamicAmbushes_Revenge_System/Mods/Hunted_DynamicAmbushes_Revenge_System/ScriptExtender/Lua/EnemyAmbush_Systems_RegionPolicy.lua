-- EnemyAmbush_Systems_RegionPolicy.lua
-- Canonical owner for region normalization/policy, blocked-region helpers,
-- and trigger safe-zone occupancy state.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local function SafeOsiCall(...)
    local fn = EA and EA["SafeOsiCall"]
    if type(fn) == "function" then
        return fn(...)
    end
    return nil
end

-- ========= REGION NORMALIZATION + POLICY TABLE =========

-- Alias map: variant/sub-region IDs -> canonical region key.
-- Keeps all consumers consistent without scattering string comparisons.
local EA_REGION_ALIASES = {
    -- City aliases (CTY_* is used by some flags / sub-region tags)
    ["CTY_Main_A"] = "BGO_Main_A",
    ["BG_Main_A"] = "BGO_Main_A",
    ["BG_Under_A"] = "BGO_Under_A",
    ["BG_Upper_A"] = "BGO_Upper_A",

    -- Interior aliases that map to a parent act-region
    ["INT_Main_A"] = "BGO_Main_A",

    -- Epilogue / endgame scenes map to themselves, so no alias is needed.
}

-- Central region policy table.
-- Fields:
--   act       (number)  Game act (1/2/3, 0 = special)
--   label     (string)  Human-readable name for debug
--   blocked   (bool)    Hard-blocked from ambushes (safety override)
--   camp      (bool)    Is a camp region
--   setpiece  (bool)    Narrative setpiece / boss arena
--   shadowCurse (bool)  Needs shadow curse immunity for spawns
--   pressureMult (number|nil) Override for pressure multiplier
local EA_REGION_POLICY = {
    -- ===== ACT 1 =====
    ["WLD_Main_A"] = { act = 1, label = "Wilderness", pressureMult = 0.8 },
    ["CRE_Main_A"] = { act = 1, label = "Mountain Pass", pressureMult = 1.2 },
    ["UND_Main_A"] = { act = 1, label = "Underdark", pressureMult = 1.3 },
    ["GOB_Main_A"] = { act = 1, label = "Goblin Camp" },

    -- ===== ACT 2 =====
    ["SCL_Main_A"] = { act = 2, label = "Shadow-Cursed Lands", shadowCurse = true, pressureMult = 1.6 },
    ["MOO_Main_A"] = { act = 2, label = "Moonrise Towers", shadowCurse = true, pressureMult = 1.5 },

    -- ===== ACT 3 =====
    ["RIV_Main_A"] = { act = 3, label = "Rivington", pressureMult = 0.7 },
    ["WYM_Main_A"] = { act = 3, label = "Wyrm's Crossing", pressureMult = 1.0 },
    ["BGO_Main_A"] = { act = 3, label = "Lower City", pressureMult = 1.0 },
    ["BGO_Upper_A"] = { act = 3, label = "Upper City" },
    ["BGO_Under_A"] = { act = 3, label = "Sewers", pressureMult = 1.4 },

    -- ===== SPECIAL / OTHER PLANES =====
    ["CRE_Astral_A"] = { act = 0, label = "Astral Plane", blocked = true },
    ["AVE_Main_A"] = { act = 0, label = "House of Hope", pressureMult = 2.0 },
    ["SHA_Main_A"] = { act = 0, label = "Shadowfell" },

    -- ===== CAMP =====
    ["CMP_Main_A"] = { act = 0, label = "Camp", camp = true },

    -- ===== TUTORIAL =====
    ["TUT_Avernus_C"] = { act = 0, label = "Tutorial (Nautiloid)", blocked = true },

    -- ===== SETPIECE / BOSS ARENAS =====
    ["IRN_Main_A"] = { act = 3, label = "Iron Throne", setpiece = true, blocked = true },
    ["EPI_Main_A"] = { act = 3, label = "Epilogue", setpiece = true, blocked = true },
    ["END_Main"] = { act = 3, label = "Endgame", setpiece = true, blocked = true },
}

EA.REGION_POLICY = EA_REGION_POLICY
EA.REGION_ALIASES = EA_REGION_ALIASES

-- Trigger-based safe settlement hubs. Trigger occupancy is the authoritative signal
-- where available; raw sublevel patterns remain as fallback for hubs that still surface
-- reliable raw region IDs.
local EA_TRIGGER_SAFE_ZONE_DEFS = {
    EMERALD_GROVE = {
        label = "Emerald Grove",
        blocked = true,
        reason = "settlement_hub",
        sourceNote = "Norbyte DEN_* marker-target triggers",
        rawPatterns = { "WLD_DruidSubs_", "WLD_DenSubs_" },
        triggers = {
            "8a64c311-e43a-4e2f-81d5-401728fd07bb",
            "50062397-bf9c-4765-9cbc-e40b5148f211",
            "ea27b551-614e-4a2b-be30-eec246744860",
            "05334587-5b2e-4b09-8fc0-220329fe9687",
            "673dbc57-a754-4e37-9bd8-10a7ffeea93d",
            "25d3b069-a9a6-4895-81c7-7405e1a70c01",
            "687f429f-91f5-4e8f-9ab2-04cf6cfa23ba",
            "1eaef46b-2ba4-487c-893b-95b178f3bf0f",
        },
    },
    LAST_LIGHT_INN = {
        label = "Last Light Inn",
        blocked = true,
        reason = "settlement_hub",
        sourceNote = "Norbyte HAV_* marker-target triggers",
        rawPatterns = { "SCL_Haven_" },
        triggers = {
            "bceea38d-fe28-4a17-9581-48e1c9f23f4a",
            "389d2e4f-01ac-4f55-8e1c-507303540b5d",
            "e5073cbc-25df-4f03-83f0-bede4669762d",
            "fec9a316-3db9-4918-a3c2-6d00b8f29ce9",
            "335c7cf0-c83d-4a67-8c04-acef5a3fa5b0",
        },
    },
    FRIENDLY_ARM_INN = {
        label = "Friendly Arm Inn",
        blocked = true,
        reason = "settlement_hub",
        sourceNote = "Raw-region fallback only; trigger UUID pending local content/source data",
        rawPatterns = { "BGO_FriendlyArmInn_" },
        triggers = {},
    },
}

EA.TRIGGER_SAFE_ZONE_DEFS = EA_TRIGGER_SAFE_ZONE_DEFS

local function EA_NormalizeSafeZoneKey(value)
    local normalized = EA_NormalizeUUID and EA_NormalizeUUID(value) or nil
    if type(normalized) == "string" and normalized ~= "" then
        return normalized
    end
    if type(value) == "string" then
        return string.lower(value)
    end
    return tostring(value or "")
end

local function EA_GetTriggerSafeZoneIndex()
    if type(EA._TriggerSafeZoneIndex) == "table" then
        return EA._TriggerSafeZoneIndex
    end

    local index = {}
    for zoneId, def in pairs(EA_TRIGGER_SAFE_ZONE_DEFS) do
        if type(def) == "table" and type(def.triggers) == "table" then
            for _, trigger in ipairs(def.triggers) do
                local triggerKey = EA_NormalizeSafeZoneKey(trigger)
                if triggerKey ~= "" then
                    index[triggerKey] = index[triggerKey] or {}
                    index[triggerKey][#index[triggerKey] + 1] = zoneId
                end
            end
        end
    end

    EA._TriggerSafeZoneIndex = index
    return index
end

local function EA_EnsureTriggerSafeZoneState()
    EA._TriggerSafeZoneState = EA._TriggerSafeZoneState or {}
    local state = EA._TriggerSafeZoneState
    if type(state.activeByCharacter) ~= "table" then state.activeByCharacter = {} end
    if type(state.registeredTriggers) ~= "table" then state.registeredTriggers = {} end
    if type(state.lastEntered) ~= "table" then state.lastEntered = {} end
    if type(state.lastLeft) ~= "table" then state.lastLeft = {} end
    if type(state.lastRegistrationAtMs) ~= "number" then state.lastRegistrationAtMs = 0 end
    return state
end

local function EA_GetCharacterSafeZoneBucket(character)
    local key = EA_NormalizeSafeZoneKey(character)
    if key == "" then return nil, "" end
    local state = EA_EnsureTriggerSafeZoneState()
    local bucket = state.activeByCharacter[key]
    if type(bucket) ~= "table" then
        bucket = {}
        state.activeByCharacter[key] = bucket
    end
    return bucket, key
end

local function EA_PruneCharacterSafeZones(characterKey)
    local state = EA_EnsureTriggerSafeZoneState()
    local bucket = state.activeByCharacter[characterKey]
    if type(bucket) ~= "table" then
        state.activeByCharacter[characterKey] = nil
        return
    end

    local hasAny = false
    for zoneId, count in pairs(bucket) do
        local numeric = tonumber(count) or 0
        if numeric > 0 then
            bucket[zoneId] = numeric
            hasAny = true
        else
            bucket[zoneId] = nil
        end
    end

    if not hasAny then
        state.activeByCharacter[characterKey] = nil
    end
end

local function EA_GetRawSafeZoneIds(rawRegion)
    local raw = tostring(rawRegion or "")
    local ids = {}
    if raw == "" then
        return ids
    end

    for zoneId, def in pairs(EA_TRIGGER_SAFE_ZONE_DEFS) do
        local patterns = type(def) == "table" and def.rawPatterns or nil
        if type(patterns) == "table" then
            for _, pattern in ipairs(patterns) do
                if raw:find(tostring(pattern), 1, true) then
                    ids[zoneId] = true
                    break
                end
            end
        end
    end

    return ids
end

local function EA_GetActiveTriggerSafeZoneIdsForCharacter(character)
    local state = EA_EnsureTriggerSafeZoneState()
    local key = EA_NormalizeSafeZoneKey(character)
    if key == "" then
        return {}
    end

    local bucket = state.activeByCharacter[key]
    local ids = {}
    if type(bucket) ~= "table" then
        return ids
    end

    for zoneId, count in pairs(bucket) do
        if (tonumber(count) or 0) > 0 then
            ids[zoneId] = true
        end
    end

    return ids
end

local function EA_BuildSafeZoneLabels(zoneIds)
    local labels = {}
    for zoneId in pairs(zoneIds or {}) do
        local def = EA_TRIGGER_SAFE_ZONE_DEFS[zoneId]
        labels[#labels + 1] = tostring((def and def.label) or zoneId)
    end
    table.sort(labels)
    return labels
end

function EA_GetSafeZoneState(character)
    local canonical, raw = EA_GetRegionForCharacter(character)
    local triggerIds = EA_GetActiveTriggerSafeZoneIdsForCharacter(character)
    local rawIds = EA_GetRawSafeZoneIds(raw)
    local combined = {}
    local triggerBlocked = false

    for zoneId in pairs(triggerIds) do
        combined[zoneId] = true
        local def = EA_TRIGGER_SAFE_ZONE_DEFS[zoneId]
        if def == nil or def.blocked ~= false then
            triggerBlocked = true
        end
    end
    for zoneId in pairs(rawIds) do
        combined[zoneId] = true
    end

    local labels = EA_BuildSafeZoneLabels(combined)
    local activeZoneIds = {}
    for zoneId in pairs(combined) do
        activeZoneIds[#activeZoneIds + 1] = zoneId
    end
    table.sort(activeZoneIds)

    return {
        character = EA_NormalizeSafeZoneKey(character),
        canonical = tostring(canonical or ""),
        raw = tostring(raw or ""),
        triggerBlocked = triggerBlocked == true,
        triggerZoneIds = triggerIds,
        rawZoneIds = rawIds,
        activeZoneIds = activeZoneIds,
        activeZones = labels,
    }
end

function EA_IsCharacterInBlockedSafeZone(character)
    local state = EA_GetSafeZoneState(character)
    return state.triggerBlocked == true
end

function EA_RebuildSafeZoneRegistration()
    local state = EA_EnsureTriggerSafeZoneState()
    state.activeByCharacter = {}
    state.registeredTriggers = {}

    if not (Osi and Osi.TriggerRegisterForPlayers) then
        return 0
    end

    local registered = 0
    local seen = {}
    local triggerIndex = EA_GetTriggerSafeZoneIndex()
    for triggerKey in pairs(triggerIndex) do
        if triggerKey ~= "" and not seen[triggerKey] then
            seen[triggerKey] = true
            local ok, err = pcall(Osi.TriggerRegisterForPlayers, triggerKey)
            if ok then
                state.registeredTriggers[triggerKey] = true
                registered = registered + 1
            else
                print(string.format(
                    "[EnemyAmbush][SafeZone] Trigger registration failed: trigger=%s err=%s",
                    tostring(triggerKey),
                    tostring(err)
                ))
            end
        end
    end

    state.lastRegistrationAtMs = (EA_NowMs and tonumber(EA_NowMs())) or 0
    return registered
end

function EA_OnEnteredSafeZoneTrigger(character, trigger)
    local triggerKey = EA_NormalizeSafeZoneKey(trigger)
    local triggerIndex = EA_GetTriggerSafeZoneIndex()
    local zoneIds = triggerIndex[triggerKey]
    if type(zoneIds) ~= "table" or #zoneIds == 0 then
        return false
    end

    local bucket, characterKey = EA_GetCharacterSafeZoneBucket(character)
    if type(bucket) ~= "table" or characterKey == "" then
        return false
    end

    local state = EA_EnsureTriggerSafeZoneState()
    for _, zoneId in ipairs(zoneIds) do
        bucket[zoneId] = (tonumber(bucket[zoneId]) or 0) + 1
    end
    state.lastEntered[characterKey] = triggerKey
    return true
end

function EA_OnLeftSafeZoneTrigger(character, trigger)
    local triggerKey = EA_NormalizeSafeZoneKey(trigger)
    local triggerIndex = EA_GetTriggerSafeZoneIndex()
    local zoneIds = triggerIndex[triggerKey]
    if type(zoneIds) ~= "table" or #zoneIds == 0 then
        return false
    end

    local bucket, characterKey = EA_GetCharacterSafeZoneBucket(character)
    if type(bucket) ~= "table" or characterKey == "" then
        return false
    end

    local state = EA_EnsureTriggerSafeZoneState()
    for _, zoneId in ipairs(zoneIds) do
        local nextCount = (tonumber(bucket[zoneId]) or 0) - 1
        if nextCount > 0 then
            bucket[zoneId] = nextCount
        else
            bucket[zoneId] = nil
        end
    end
    EA_PruneCharacterSafeZones(characterKey)
    state.lastLeft[characterKey] = triggerKey
    return true
end

-- Sublevel denylist: if the raw region string from GetRegion contains any of these
-- substrings, ambushes are blocked (setpiece, boss lair, tutorial, cinematic, rest camp).
-- Checked before collapsing to canonical main region.
local EA_SUBLEVEL_BLOCK_PATTERNS = {
    -- Tutorial / Nautiloid
    "Nautiloid",
    "Avernus",
    "GLO_TUT_",
    "TUT_",
    -- Rest camp (player camp for long rest): CMP_* and camp prefabs only
    "CMP_",
    "CAMP_",
    "PLT_Camp",
    -- Cinematic levels
    "CIN_",
    -- Boss / setpiece
    "HagLair",
    "Hag_C",
    "SharTemple",
    "Chapel_Push",
    -- Dev / test
    "Testlevel",
}

for _, def in pairs(EA_TRIGGER_SAFE_ZONE_DEFS) do
    if type(def) == "table" and type(def.rawPatterns) == "table" then
        for _, pattern in ipairs(def.rawPatterns) do
            EA_SUBLEVEL_BLOCK_PATTERNS[#EA_SUBLEVEL_BLOCK_PATTERNS + 1] = tostring(pattern)
        end
    end
end

function EA_IsRawRegionBlocked(rawRegion)
    local raw = tostring(rawRegion or "")
    if raw == "" then return false end
    for _, pattern in ipairs(EA_SUBLEVEL_BLOCK_PATTERNS) do
        if raw:find(pattern, 1, true) then
            return true
        end
    end
    return false
end

_EA_HeuristicRegionLog = _EA_HeuristicRegionLog or {}
_EA_HEURISTIC_REGION_LOG_INTERVAL_MS = 60000

local function EA_LogHeuristicRegionMapping(rawRegion, canonical, context)
    if not rawRegion or rawRegion == "" then return end
    if not canonical or canonical == "" then return end
    if rawRegion == canonical then return end
    local now = (EA_NowMs and tonumber(EA_NowMs())) or 0
    local key = tostring(rawRegion)
    local lastLog = _EA_HeuristicRegionLog[key]
    if lastLog and (now - lastLog) < _EA_HEURISTIC_REGION_LOG_INTERVAL_MS then
        return
    end
    _EA_HeuristicRegionLog[key] = now
    print(string.format(
        "[EnemyAmbush][RegionTelemetry] Heuristic region map raw='%s' -> canonical='%s' context=%s",
        tostring(rawRegion),
        tostring(canonical),
        tostring(context or "?")
    ))
end

function EA_ResolveRegion(rawRegion)
    local raw = tostring(rawRegion or "")
    if raw == "" then return "" end

    if EA_REGION_ALIASES[raw] then
        return EA_REGION_ALIASES[raw]
    end

    if EA_REGION_POLICY[raw] then
        return raw
    end

    local prefix = raw:match("^(%u+)_")
    if prefix then
        local prefixMap = {
            WLD = "WLD_Main_A",
            CRE = raw:find("Astral") and "CRE_Astral_A" or "CRE_Main_A",
            UND = "UND_Main_A",
            GOB = "GOB_Main_A",
            SCL = "SCL_Main_A",
            MOO = "MOO_Main_A",
            RIV = "RIV_Main_A",
            WYM = "WYM_Main_A",
            BGO = "BGO_Main_A",
            CTY = "BGO_Main_A",
            BG = "BGO_Main_A",
            AVE = "AVE_Main_A",
            SHA = "SHA_Main_A",
            CMP = "CMP_Main_A",
            TUT = "TUT_Avernus_C",
            INT = "BGO_Main_A",
            IRN = "IRN_Main_A",
            EPI = "EPI_Main_A",
            END = "END_Main",
        }
        if prefixMap[prefix] then
            local canonical = prefixMap[prefix]
            EA_LogHeuristicRegionMapping(raw, canonical, "prefix")
            return canonical
        end
    end

    return raw
end

function EA_GetRegionForCharacter(character)
    if not character or character == "" then return "", "" end
    local raw = ""
    if Osi and Osi.GetRegion then
        raw = SafeOsiCall(Osi.GetRegion, character) or ""
    end
    return EA_ResolveRegion(raw), raw
end

function EA_GetRegionPolicy(regionOrChar, isCharacter)
    local canonical
    if isCharacter then
        canonical = EA_GetRegionForCharacter(regionOrChar)
    else
        canonical = EA_ResolveRegion(regionOrChar)
    end
    return EA_REGION_POLICY[canonical], canonical
end

function EA_IsRegionBlocked(region)
    local ok, policy = pcall(EA_GetRegionPolicy, region, false)
    if not ok or type(policy) ~= "table" then
        return false
    end
    return (policy.blocked == true) or (policy.setpiece == true)
end

function EA_IsRegionCamp(region)
    local canonical = EA_ResolveRegion(region)
    local policy = EA_REGION_POLICY[canonical]
    if policy and policy.camp then return true end
    if canonical:find("Camp") or canonical:find("CAMP") or canonical == "CMP_Main_A" then
        return true
    end
    return false
end

_EA_UnknownRegionLog = _EA_UnknownRegionLog or {}
_EA_UNKNOWN_REGION_LOG_INTERVAL_MS = 60000

function EA_LogUnknownRegion(rawRegion, context)
    if not rawRegion or rawRegion == "" then return end
    local canonical = EA_ResolveRegion(rawRegion)
    if EA_REGION_POLICY[canonical] then return end

    local now = (EA_NowMs and tonumber(EA_NowMs())) or 0
    local lastLog = _EA_UnknownRegionLog[rawRegion]
    if lastLog and (now - lastLog) < _EA_UNKNOWN_REGION_LOG_INTERVAL_MS then
        return
    end
    _EA_UnknownRegionLog[rawRegion] = now
    print(string.format(
        "[EnemyAmbush][RegionTelemetry] Unknown region '%s' (resolved='%s') context=%s",
        tostring(rawRegion),
        tostring(canonical),
        tostring(context or "?")
    ))
end

EA["EA_ResolveRegion"] = EA_ResolveRegion
EA["EA_GetRegionForCharacter"] = EA_GetRegionForCharacter
EA["EA_GetRegionPolicy"] = EA_GetRegionPolicy
EA["EA_IsRegionBlocked"] = EA_IsRegionBlocked
EA["EA_IsRawRegionBlocked"] = EA_IsRawRegionBlocked
EA["EA_IsRegionCamp"] = EA_IsRegionCamp
EA["EA_LogUnknownRegion"] = EA_LogUnknownRegion
EA["EA_GetSafeZoneState"] = EA_GetSafeZoneState
EA["EA_IsCharacterInBlockedSafeZone"] = EA_IsCharacterInBlockedSafeZone
EA["EA_RebuildSafeZoneRegistration"] = EA_RebuildSafeZoneRegistration
EA["EA_OnEnteredSafeZoneTrigger"] = EA_OnEnteredSafeZoneTrigger
EA["EA_OnLeftSafeZoneTrigger"] = EA_OnLeftSafeZoneTrigger
EA["EA_TRIGGER_SAFE_ZONE_DEFS"] = EA_TRIGGER_SAFE_ZONE_DEFS
