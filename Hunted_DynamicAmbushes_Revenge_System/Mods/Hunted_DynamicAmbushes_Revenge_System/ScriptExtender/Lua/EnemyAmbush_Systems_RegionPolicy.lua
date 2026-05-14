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
    ["AVE_Main_A"] = { act = 0, label = "House of Hope", setpiece = true, blocked = true },
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
        sourceNote = "Norbyte DEN_* lair/hub/trader/hideout triggers",
        rawPatterns = { "WLD_DruidSubs_", "WLD_DenSubs_" },
        triggers = {
            "3484a4b1-4c3a-41ef-9290-54b5e7cce86f",
            "c403fcf2-b101-4eda-a7a1-1a53477d7b9d",
            "1a1624d9-cde7-4edb-9395-2109909a7077",
            "85dbdbd1-0a70-da4b-7bc8-8991e7371b57",
            "8a9b2f1d-6490-db64-718e-bcd64e38ea66",
            "8a64c311-e43a-4e2f-81d5-401728fd07bb",
            "50062397-bf9c-4765-9cbc-e40b5148f211",
            "ea27b551-614e-4a2b-be30-eec246744860",
            "05334587-5b2e-4b09-8fc0-220329fe9687",
            "673dbc57-a754-4e37-9bd8-10a7ffeea93d",
            "25d3b069-a9a6-4895-81c7-7405e1a70c01",
            "687f429f-91f5-4e8f-9ab2-04cf6cfa23ba",
            "1eaef46b-2ba4-487c-893b-95b178f3bf0f",
            "9eea20f5-4832-4e71-a310-c825237a00a7",
            "8182d25e-d90f-4e75-9615-34bc5929ad0a",
            "a678b3dd-aa86-41a2-9138-5d8f328bb77d",
            "5e96478b-d5df-41d3-a20e-4ae522f75144",
            "bc0ea3d8-aac1-49a8-b284-30d2029186f6",
            "66dedc4c-25c0-457f-8b07-a87d7b1d0688",
        },
    },
    AUNTIE_ETHEL_LAIR = {
        label = "Auntie Ethel's lair",
        blocked = true,
        reason = "narrative_setpiece",
        sourceNote = "Verified Gustav trigger S_HAG_HagLair_f84e3319-4a1d-483c-a718-dee3bff70d07",
        rawPatterns = { "HagLair", "Hag_C" },
        triggers = {
            "f84e3319-4a1d-483c-a718-dee3bff70d07",
            "db8a7138-ba47-45d9-8456-0a77a9901966",
        },
    },
    LAST_LIGHT_INN = {
        label = "Last Light Inn",
        blocked = true,
        reason = "settlement_hub",
        sourceNote = "Norbyte HAV_* hub/cellar/interior triggers",
        rawPatterns = { "SCL_Haven_" },
        triggers = {
            "bceea38d-fe28-4a17-9581-48e1c9f23f4a",
            "389d2e4f-01ac-4f55-8e1c-507303540b5d",
            "e5073cbc-25df-4f03-83f0-bede4669762d",
            "fec9a316-3db9-4918-a3c2-6d00b8f29ce9",
            "335c7cf0-c83d-4a67-8c04-acef5a3fa5b0",
            "1df96345-f975-40fd-a185-5716619f8d7e",
            "c65180c5-2ac2-4620-902c-0b92c33c324d",
            "6ac001f4-9c56-4a1b-963d-a509e158ffab",
            "eee18cb6-443a-4b8f-ad19-58dff3d731d8",
            "69a889f7-2dad-43cf-86e4-e4f2331e54cc",
            "01b3e82a-6e82-4c6d-9213-ddd67439826b",
        },
    },
    MOONRISE_TOWERS = {
        label = "Moonrise Towers",
        blocked = true,
        reason = "settlement_hub",
        sourceNote = "Norbyte MOO_* tower/interior triggers",
        rawPatterns = { "MOO_" },
        triggers = {
            "f088177f-ceba-4019-8d1d-1c505d046a35",
            "0e3f7ebc-9932-488b-aef0-f55660b03cda",
            "14187ad9-cf83-44f9-81bf-bb46cb4cd8e6",
            "429a55cc-58d2-4469-9577-852131e1fff3",
            "93c522d3-04c4-4f71-a1dc-043478c51301",
            "77c94e75-2924-4ca3-b7bd-d631b18d6c73",
            "b262cbea-f40c-47da-9f34-ba8ce5bf782b",
            "b50b8553-0064-41d0-8595-266f69e35c33",
            "c6f54de0-1c8f-4cf8-bcf9-b13c8f53b05b",
            "d066ff4c-bc01-4e46-97ad-f641ccd61929",
        },
    },
    ACT2_SETPIECE_INTERIORS = {
        label = "Act 2 setpiece interior",
        blocked = true,
        reason = "narrative_setpiece",
        sourceNote = "Norbyte SHA/SCL setpiece triggers and raw sublevel names",
        rawPatterns = {
            "SCL_MindflayerColony",
            "SCL_Mausoleum",
            "SCL_KethericEntrance",
            "SCL_MoonriseDungeon",
            "SCL_VillageSubs",
            "SHA_",
        },
        triggers = {
            "982d32f0-cdee-4797-873d-94e6402ddc7b",
            "7fe381d9-9467-46ed-abd2-73dda3bd691d",
            "aad74606-6ae5-4d23-9ca7-daadad08c020",
            "0a302268-dd92-4462-99e5-ca7491815ec0",
            "348b76ee-33d8-471b-a95d-7ded0d6cdfd5",
            "961f86d2-b05c-40c5-b2e4-bf40c089f481",
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
    SORCEROUS_SUNDRIES = {
        label = "Sorcerous Sundries / Ramazith Tower",
        blocked = true,
        reason = "story_interior",
        sourceNote = "Verified Act 3 raw sublevels and Sorcerous Sundries trigger",
        rawPatterns = { "BGH_SorcerersSundries_A_ART", "BGO_RamazithTower_A_ART", "CTY_SorcerousSundriesBasement_A" },
        triggers = { "59e9313f-29cd-48b4-9241-4e5db28f6bbf" },
    },
    ELFSONG_TAVERN = {
        label = "Elfsong Tavern",
        blocked = true,
        reason = "settlement_hub",
        sourceNote = "Verified Act 3 raw sublevels and Elfsong triggers",
        rawPatterns = { "BGH_ElfSongTavern_A_Art", "BGO_ElfsongBasement_A", "CMP_BGO_Elfsong_", "CTY_CIN_PrivateCampRoom_Elfsong_A" },
        triggers = { "b905146f-d47c-469f-b96a-6d3b42dd35f5", "ce0fea85-47ad-4e27-8aa1-ad1699d4f320" },
    },
    JAHEIRA_HOME = {
        label = "Jaheira's home",
        blocked = true,
        reason = "story_interior",
        sourceNote = "Verified Act 3 raw sublevels and Jaheira basement trigger",
        rawPatterns = { "BGO_JaheiraBasement_B", "PLT_CTY_JaheiraTreasure_" },
        triggers = { "3be5ee75-b8a5-473f-9b82-b60f90b742ca" },
    },
    STORMSHORE_TABERNACLE = {
        label = "Stormshore Tabernacle",
        blocked = true,
        reason = "story_interior",
        sourceNote = "Verified Act 3 raw sublevels and tabernacle trigger",
        rawPatterns = { "BGH_StormshoreTabernacle_A", "CTY_Tabernacle_Basement_A" },
        triggers = { "d9fcb0ed-4fb0-4439-9644-2209cf93ee42" },
    },
    COUNTING_HOUSE = {
        label = "Counting House",
        blocked = true,
        reason = "story_interior",
        sourceNote = "Verified Act 3 raw sublevels; trigger UUID UNVERIFIED/not added",
        rawPatterns = { "BGH_Countinghouse_C", "BGH_CountingHouseVault_C", "BGH_CountingHouseVaultConnection_A" },
        triggers = {},
    },
    FIGARO_SHOP = {
        label = "Figaro's shop",
        blocked = true,
        reason = "story_interior",
        sourceNote = "Verified Act 3 raw sublevels and Figaro trigger",
        rawPatterns = { "BGH_FigaroCosmeticShop_A", "CTY_Figaro_Basement_A" },
        triggers = { "24bc4789-18c9-4ec5-8188-5c2e837e9496" },
    },
    DEVILS_FEE = {
        label = "Devil's Fee",
        blocked = true,
        reason = "story_interior",
        sourceNote = "Verified Act 3 raw sublevels and Devil's Fee trigger",
        rawPatterns = { "BGH_DiabolistHouse_A_ART", "BGO_DiabolistCellar_A_ART" },
        triggers = { "54727477-6f56-4e87-a63d-3cc8f67616a4" },
    },
    HOUSE_OF_GRIEF = {
        label = "House of Grief",
        blocked = true,
        reason = "story_interior",
        sourceNote = "Verified Act 3 raw sublevels and House of Grief trigger",
        rawPatterns = { "BGH_House_of_Grief", "BGO_Sharran_Grotto" },
        triggers = { "8bffed4d-fe97-4cd8-b8a3-ad65833b2485" },
    },
    CAZADOR_PALACE = {
        label = "Cazador's palace",
        blocked = true,
        reason = "story_interior",
        sourceNote = "Verified Act 3 raw sublevels and Cazador palace triggers",
        rawPatterns = { "CTY_CazadorPalace_A", "CTY_CazSideRooms_A", "BGO_UC_CazadorChapel_A", "PLT_Cazador" },
        triggers = { "3be855c5-58aa-49ed-a74e-b094c41c5d77", "a6f08f08-56e2-4af6-951c-15e46ea8c75c" },
    },
    STEEL_WATCH_FOUNDRY = {
        label = "Steel Watch Foundry",
        blocked = true,
        reason = "story_interior",
        sourceNote = "Verified Act 3 raw sublevels and foundry triggers",
        rawPatterns = { "BGH_SteelWatchFoundry_B", "BGO_SteelWatchLabControlCenter_B", "PLT_SteelWatchFoundry_" },
        triggers = { "2a286caf-5b3f-4470-9c9c-10b3e70356fe", "6aef5972-edd8-4e19-a211-064d5e5b254e" },
    },
    IRON_THRONE_SUPPORT = {
        label = "Submersible / Iron Throne support",
        blocked = true,
        reason = "narrative_setpiece",
        sourceNote = "Verified raw sublevels; trigger UUID UNVERIFIED/not added",
        rawPatterns = { "CTY_Submersible_A", "PLT_CTY_Submersible" },
        triggers = {},
    },
    WYRMWAY = {
        label = "Wyrmway",
        blocked = true,
        reason = "narrative_setpiece",
        sourceNote = "Verified raw sublevels; trigger UUID UNVERIFIED/not added",
        rawPatterns = { "BGO_Wyrmsway", "BGO_CIN_WyrmswayArena", "PLT_WYR_Wyrmway" },
        triggers = {},
    },
    MURDER_TRIBUNAL = {
        label = "Murder Tribunal",
        blocked = true,
        reason = "narrative_setpiece",
        sourceNote = "Verified raw sublevel; trigger UUID UNVERIFIED/not added",
        rawPatterns = { "CTY_MurderTribunal_A" },
        triggers = {},
    },
    BHAAL_ANCIENT_LAIR = {
        label = "Ancient Lair / Bhaal catacombs",
        blocked = true,
        reason = "narrative_setpiece",
        sourceNote = "Verified Act 3 raw sublevels and Ancient Lair trigger",
        rawPatterns = { "CTY_AncientLair_A", "CTY_Catacombs_A" },
        triggers = { "4bd5906b-d5e3-4a7e-89a9-88c50360d7a2" },
    },
    HOUSE_OF_HOPE = {
        label = "House of Hope",
        blocked = true,
        reason = "narrative_setpiece",
        sourceNote = "Verified raw region AVE_Main_A and House of Hope trigger",
        rawPatterns = { "BGO_HouseOfHope" },
        triggers = { "9f7aa5e7-80f5-42ca-a939-c680c552fbfc" },
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
    local rawBlocked = false

    for zoneId in pairs(triggerIds) do
        combined[zoneId] = true
        local def = EA_TRIGGER_SAFE_ZONE_DEFS[zoneId]
        if def == nil or def.blocked ~= false then
            triggerBlocked = true
        end
    end
    for zoneId in pairs(rawIds) do
        combined[zoneId] = true
        local def = EA_TRIGGER_SAFE_ZONE_DEFS[zoneId]
        if def == nil or def.blocked ~= false then
            rawBlocked = true
        end
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
        blocked = triggerBlocked == true or rawBlocked == true,
        blockReason = (rawBlocked == true and "raw_safe_zone_block") or (triggerBlocked == true and "safe_zone_block") or "",
        triggerBlocked = triggerBlocked == true,
        rawBlocked = rawBlocked == true,
        triggerZoneIds = triggerIds,
        rawZoneIds = rawIds,
        activeZoneIds = activeZoneIds,
        activeZones = labels,
    }
end

function EA_GetObjectSafeZoneBlockState(object)
    local state = EA_GetSafeZoneState(object)
    if type(state) == "table" and state.blocked == true then
        return state
    end

    local triggerFn = Osi and Osi.IsInTrigger
    if type(triggerFn) ~= "function" or not object or object == "" then
        return state
    end

    local triggerIndex = EA_GetTriggerSafeZoneIndex()
    for triggerKey, zoneIds in pairs(triggerIndex) do
        local okInside, inside = pcall(triggerFn, object, triggerKey)
        if okInside and tonumber(inside) == 1 then
            local combined = {}
            local blocked = false
            for _, zoneId in ipairs(zoneIds or {}) do
                combined[zoneId] = true
                local def = EA_TRIGGER_SAFE_ZONE_DEFS[zoneId]
                if def == nil or def.blocked ~= false then
                    blocked = true
                end
            end
            local labels = EA_BuildSafeZoneLabels(combined)
            local activeZoneIds = {}
            for zoneId in pairs(combined) do
                activeZoneIds[#activeZoneIds + 1] = zoneId
            end
            table.sort(activeZoneIds)
            return {
                character = EA_NormalizeSafeZoneKey(object),
                canonical = tostring(type(state) == "table" and state.canonical or ""),
                raw = tostring(type(state) == "table" and state.raw or ""),
                blocked = blocked == true,
                blockReason = blocked and "safe_zone_block" or "",
                triggerBlocked = blocked == true,
                rawBlocked = false,
                trigger = triggerKey,
                triggerZoneIds = combined,
                rawZoneIds = {},
                activeZoneIds = activeZoneIds,
                activeZones = labels,
            }
        end
    end

    return state
end

function EA_IsCharacterInBlockedSafeZone(character)
    local state = EA_GetSafeZoneState(character)
    return state.blocked == true
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
EA["EA_GetObjectSafeZoneBlockState"] = EA_GetObjectSafeZoneBlockState
EA["EA_IsCharacterInBlockedSafeZone"] = EA_IsCharacterInBlockedSafeZone
EA["EA_RebuildSafeZoneRegistration"] = EA_RebuildSafeZoneRegistration
EA["EA_OnEnteredSafeZoneTrigger"] = EA_OnEnteredSafeZoneTrigger
EA["EA_OnLeftSafeZoneTrigger"] = EA_OnLeftSafeZoneTrigger
EA["EA_TRIGGER_SAFE_ZONE_DEFS"] = EA_TRIGGER_SAFE_ZONE_DEFS
