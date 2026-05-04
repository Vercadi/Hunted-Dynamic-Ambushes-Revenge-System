-- EnemyAmbush_MCMContract.lua
-- Shared client/server MCM setting contract to prevent drift.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local contract = EA.MCMContract or {}

contract.DEFAULT_PRESET = "Marked"
contract.DEFAULT_CUSTOM_BASE_PRESET = "Marked"
contract.CUSTOM_PRESET_KEY = "CUSTOM"

contract.LEGACY_PRESET_MIGRATION = {
    ["EASY"] = "Wayfarer",
    ["NORMAL"] = "Marked",
    ["HARD"] = "Relentless",
}

contract.CONTROL_SETTING_IDS = {
    ["MCM_DifficultyPreset"] = true,
    ["MCM_AdvancedMode"] = true,
}

contract.PRESET_SETTING_IDS = {
    ["MCM_AmbushIntensity"] = true,
    ["MCM_ApplyPartySurprised"] = true,
    ["MCM_EnableTimeInDangerPressure"] = true,
    ["MCM_AmbushXPPercent"] = true,
    ["MCM_DisableAmbushLoot"] = true,
    ["MCM_AllowChampionLoot"] = true,
    ["MCM_EnableAmbushCooldown"] = true,
    ["MCM_AmbushCooldownMinutes"] = true,
    ["MCM_AmbushChanceShortPct"] = true,
    ["MCM_AmbushChanceLongPct"] = true,
    ["MCM_ShortRestDelayMinMinutes"] = true,
    ["MCM_ShortRestDelayMaxMinutes"] = true,
    ["MCM_LongRestDelayMinMinutes"] = true,
    ["MCM_LongRestDelayMaxMinutes"] = true,
    ["MCM_EnableAmbusherEscape"] = true,
    ["MCM_EscapeStartTurn"] = true,
    ["MCM_EscapeDC"] = true,
    ["MCM_EscapeHPThreshold"] = true,
    ["MCM_EscapeMaxPerCombat"] = true,
}

contract.GLOBAL_SETTING_IDS = {
    ["MCM_EnableSummons"] = true,
    ["MCM_EnableOnRest"] = true,
    ["MCM_EnableReputation"] = true,
    ["MCM_ShowUINotifications"] = true,
    ["MCM_ShowAmbushWarningNotifications"] = true,
    ["MCM_ShowChampionArrivalPopup"] = true,
    ["MCM_ShowReputationWarnings"] = true,
    ["MCM_ReputationDecayRate"] = true,
    ["MCM_EnableVanillaSummons"] = true,
    ["MCM_CombatExtenderMode"] = true,
    ["MCM_BalanceProfile"] = true,
    ["MCM_CampAmbushes"] = true,
    ["MCM_ScaleWithPartySize"] = true,
    ["MCM_StrictProgressionGates"] = true,
    ["MCM_UseCompositionGuards"] = true,
    ["MCM_ArrivalCuePolicy"] = true,
}

contract.SUPPORT_SETTING_IDS = {
    ["MCM_CustomBasePreset"] = true,
    ["MCM_SafetyChecks"] = true,
    ["MCM_PointBudget"] = true,
    ["MCM_EnableDebugLogging"] = true,
    ["MCM_DebugMode"] = true,
    ["MCM_RobustMode"] = true,
    ["MCM_QuickTestMode"] = true,
    ["MCM_SkipBeachTutorialAmbush"] = true,
    ["MCM_SpawnPlacementMode"] = true,
}

contract.PRESET_SETTING_BINDINGS = {
    { id = "MCM_ApplyPartySurprised", field = "applyPartySurprised", default = false, kind = "bool" },
    { id = "MCM_EnableTimeInDangerPressure", field = "enableTimeInDangerPressure", default = true, kind = "bool" },
    { id = "MCM_EnableAmbushCooldown", field = "cooldownEnabled", default = true, kind = "bool" },
    { id = "MCM_AmbushCooldownMinutes", field = "cooldownMin", default = 45, kind = "number" },
    { id = "MCM_AmbushChanceShortPct", field = "shortChancePct", default = 5, kind = "number" },
    { id = "MCM_AmbushChanceLongPct", field = "longChancePct", default = 15, kind = "number" },
    { id = "MCM_ShortRestDelayMinMinutes", field = "shortDelayMinMinutes", default = 0, kind = "number" },
    { id = "MCM_ShortRestDelayMaxMinutes", field = "shortDelayMaxMinutes", default = 10, kind = "number" },
    { id = "MCM_LongRestDelayMinMinutes", field = "longDelayMinMinutes", default = 2, kind = "number" },
    { id = "MCM_LongRestDelayMaxMinutes", field = "longDelayMaxMinutes", default = 20, kind = "number" },
    { id = "MCM_AmbushIntensity", field = "intensity", default = 0.90, kind = "number" },
    { id = "MCM_EnableAmbusherEscape", field = "enableAmbusherEscape", default = true, kind = "bool" },
    { id = "MCM_EscapeStartTurn", field = "escapeStartTurn", default = 6, kind = "number" },
    { id = "MCM_EscapeDC", field = "escapeDC", default = 14, kind = "number" },
    { id = "MCM_EscapeHPThreshold", field = "escapeHPThreshold", default = 50, kind = "number" },
    { id = "MCM_EscapeMaxPerCombat", field = "escapeMaxPerCombat", default = 1, kind = "number" },
    { id = "MCM_AmbushXPPercent", field = "xpPct", default = 0, kind = "number" },
    { id = "MCM_DisableAmbushLoot", field = "disableLoot", default = false, kind = "bool" },
    { id = "MCM_AllowChampionLoot", field = "allowChampionLoot", default = true, kind = "bool" },
}

contract.HIDDEN_PRESET_KNOBS = {
    Wayfarer = {
        tierBias = "COMMON_HEAVY",
        championWeightMultiplier = 0.50,
        fodderEliteBias = "FODDER_HEAVY",
        maxVeteran = 1,
        maxElite = 0,
        maxLegendary = 0,
        tierStatusLevelOffset = 0,
    },
    Marked = {
        tierBias = "COMMON_VETERAN_BASELINE",
        championWeightMultiplier = 0.90,
        fodderEliteBias = "BALANCED",
        maxVeteran = 2,
        maxElite = 1,
        maxLegendary = 1,
        tierStatusLevelOffset = 0,
    },
    Relentless = {
        tierBias = "VETERAN_ELITE_LEANING",
        championWeightMultiplier = 1.15,
        fodderEliteBias = "STRONGER_ENEMY_LEANING",
        maxVeteran = 3,
        maxElite = 2,
        maxLegendary = 1,
        tierStatusLevelOffset = 1,
    },
    Hunted = {
        tierBias = "ELITE_LEGENDARY_LEANING",
        championWeightMultiplier = 1.40,
        fodderEliteBias = "STRONGEST_ENEMY_LEANING",
        maxVeteran = 4,
        maxElite = 3,
        maxLegendary = 2,
        tierStatusLevelOffset = 2,
    },
}

contract.LEGACY_PRESET_RESIDUE = {
    -- Preserved temporarily for backward-compatible pressure/chance behavior.
    -- This is intentionally outside the canonical Workstream E preset owner map.
    chanceMult = {
        classification = "temporary_hidden_preset_owned_residue",
        values = {
            Wayfarer = 0.50,
            Marked = 0.75,
            Relentless = 0.85,
        },
    },
}

function contract.ToBool(v)
    if v == true then return true end
    if v == false then return false end
    if type(v) == "number" then return v ~= 0 end
    if type(v) == "string" then
        v = v:lower()
        return (v == "true" or v == "1" or v == "yes" or v == "on")
    end
    return false
end

contract.IDS = {
    "MCM_EnableSummons",
    "MCM_EnableVanillaSummons",
    "MCM_SafetyChecks",
    "MCM_CampAmbushes",
    "MCM_ApplyPartySurprised",
    "MCM_EnableTimeInDangerPressure",
    "MCM_ShowUINotifications",
    "MCM_ShowAmbushWarningNotifications",
    "MCM_ShowChampionArrivalPopup",
    "MCM_ArrivalCuePolicy",
    "MCM_SpawnPlacementMode",
    "MCM_EnableReputation",
    "MCM_EnableOnRest",
    "MCM_DifficultyPreset",
    "MCM_AdvancedMode",
    "MCM_ShowReputationWarnings",
    "MCM_ReputationDecayRate",
    "MCM_PointBudget",
    "MCM_AmbushIntensity",
    "MCM_ScaleWithPartySize",
    "MCM_EnableDebugLogging",
    "MCM_DebugMode",
    "MCM_RobustMode",
    "MCM_AmbushXPPercent",
    "MCM_DisableAmbushLoot",
    "MCM_AllowChampionLoot",
    "MCM_EnableAmbushCooldown",
    "MCM_AmbushCooldownMinutes",
    "MCM_AmbushChanceShortPct",
    "MCM_AmbushChanceLongPct",
    "MCM_ShortRestDelayMinMinutes",
    "MCM_ShortRestDelayMaxMinutes",
    "MCM_LongRestDelayMinMinutes",
    "MCM_LongRestDelayMaxMinutes",
    "MCM_QuickTestMode",
    "MCM_StrictProgressionGates",
    "MCM_UseCompositionGuards",
    "MCM_BalanceProfile",
    "MCM_SkipBeachTutorialAmbush",
    "MCM_CombatExtenderMode",
    "MCM_EnableAmbusherEscape",
    "MCM_EscapeStartTurn",
    "MCM_EscapeDC",
    "MCM_EscapeHPThreshold",
    "MCM_EscapeMaxPerCombat",
}

-- Settings that are actually present in MCM_blueprint.json for the release UI.
-- Runtime-only preset knobs remain in IDS so the mod can apply preset-owned
-- values internally without asking BG3MCM to load/save settings it cannot see.
contract.BLUEPRINT_IDS = {
    "MCM_DifficultyPreset",
    "MCM_AdvancedMode",
    "MCM_CustomBasePreset",
    "MCM_CombatExtenderMode",
    "MCM_AmbushIntensity",
    "MCM_ScaleWithPartySize",
    "MCM_StrictProgressionGates",
    "MCM_UseCompositionGuards",
    "MCM_BalanceProfile",
    "MCM_EnableReputation",
    "MCM_ReputationDecayRate",
    "MCM_EnableOnRest",
    "MCM_EnableTimeInDangerPressure",
    "MCM_SafetyChecks",
    "MCM_CampAmbushes",
    "MCM_EnableAmbushCooldown",
    "MCM_AmbushCooldownMinutes",
    "MCM_EnableSummons",
    "MCM_EnableVanillaSummons",
    "MCM_ApplyPartySurprised",
    "MCM_ArrivalCuePolicy",
    "MCM_SpawnPlacementMode",
    "MCM_EnableAmbusherEscape",
    "MCM_EnableDebugLogging",
    "MCM_AmbushXPPercent",
    "MCM_DisableAmbushLoot",
    "MCM_AllowChampionLoot",
}

contract.BOOL_IDS = {
    ["MCM_EnableSummons"] = true,
    ["MCM_EnableVanillaSummons"] = true,
    ["MCM_SafetyChecks"] = true,
    ["MCM_CampAmbushes"] = true,
    ["MCM_ApplyPartySurprised"] = true,
    ["MCM_EnableTimeInDangerPressure"] = true,
    ["MCM_ShowUINotifications"] = true,
    ["MCM_ShowAmbushWarningNotifications"] = true,
    ["MCM_ShowChampionArrivalPopup"] = true,
    ["MCM_EnableReputation"] = true,
    ["MCM_EnableOnRest"] = true,
    ["MCM_AdvancedMode"] = true,
    ["MCM_ShowReputationWarnings"] = true,
    ["MCM_ScaleWithPartySize"] = true,
    ["MCM_EnableDebugLogging"] = true,
    ["MCM_DebugMode"] = true,
    ["MCM_RobustMode"] = true,
    ["MCM_DisableAmbushLoot"] = true,
    ["MCM_AllowChampionLoot"] = true,
    ["MCM_EnableAmbushCooldown"] = true,
    ["MCM_QuickTestMode"] = true,
    ["MCM_StrictProgressionGates"] = true,
    ["MCM_UseCompositionGuards"] = true,
    ["MCM_SkipBeachTutorialAmbush"] = true,
    ["MCM_CombatExtenderMode"] = true,
    ["MCM_EnableAmbusherEscape"] = true,
}

contract.NUMERIC_RULES = {
    -- Integer-like controls are modeled as slider_int in blueprint and enforced
    -- here again for server-side safety.
    ["MCM_ReputationDecayRate"] = { min = 0, max = 1, integer = false },
    ["MCM_PointBudget"] = { min = 0, max = 30, integer = true },
    ["MCM_AmbushIntensity"] = { min = 0.5, max = 2, integer = false },
    ["MCM_AmbushXPPercent"] = { min = 0, max = 100, integer = true },
    ["MCM_AmbushCooldownMinutes"] = { min = 0, max = 120, integer = true },
    ["MCM_AmbushChanceShortPct"] = { min = 0, max = 100, integer = true },
    ["MCM_AmbushChanceLongPct"] = { min = 0, max = 100, integer = true },
    ["MCM_ShortRestDelayMinMinutes"] = { min = 0, max = 60, integer = true },
    ["MCM_ShortRestDelayMaxMinutes"] = { min = 0, max = 60, integer = true },
    ["MCM_LongRestDelayMinMinutes"] = { min = 0, max = 60, integer = true },
    ["MCM_LongRestDelayMaxMinutes"] = { min = 0, max = 60, integer = true },
    ["MCM_EscapeStartTurn"] = { min = 1, max = 30, integer = true },
    ["MCM_EscapeDC"] = { min = 5, max = 25, integer = true },
    ["MCM_EscapeHPThreshold"] = { min = 1, max = 100, integer = true },
    ["MCM_EscapeMaxPerCombat"] = { min = 0, max = 6, integer = true },
}

contract.ENUM_RULES = {
    ["MCM_DifficultyPreset"] = {
        WAYFARER = true,
        MARKED = true,
        RELENTLESS = true,
        HUNTED = true,
        CUSTOM = true,
    },
    ["MCM_CustomBasePreset"] = {
        WAYFARER = true,
        MARKED = true,
        RELENTLESS = true,
        HUNTED = true,
    },
    -- Keep legacy, previous readable aliases, and current friendly MCM values
    -- accepted for backward compatibility.
    ["MCM_BalanceProfile"] = {
        BG3_12 = true,
        MODDED_20 = true,
        VANILLA_1_12 = true,
        EXTENDED_13_20 = true,
    },
    ["MCM_ArrivalCuePolicy"] = {
        BALANCED = true,
        ALWAYS_ON = true,
        OFF = true,
    },
    ["MCM_SpawnPlacementMode"] = {
        AUTO = true,
        FIND_VALID_ONLY = true,
        CREATE_OOS_ONLY = true,
    },
}

contract.ENUM_CANONICAL = {
    ["MCM_DifficultyPreset"] = {
        ["WAYFARER"] = "Wayfarer",
        ["MARKED"] = "Marked",
        ["RELENTLESS"] = "Relentless",
        ["HUNTED"] = "Hunted",
        ["CUSTOM"] = "CUSTOM",
        ["EASY"] = "Wayfarer",
        ["NORMAL"] = "Marked",
        ["HARD"] = "Relentless",
    },
    ["MCM_CustomBasePreset"] = {
        ["WAYFARER"] = "Wayfarer",
        ["MARKED"] = "Marked",
        ["RELENTLESS"] = "Relentless",
        ["HUNTED"] = "Hunted",
        ["EASY"] = "Wayfarer",
        ["NORMAL"] = "Marked",
        ["HARD"] = "Relentless",
    },
    ["MCM_BalanceProfile"] = {
        ["BG3_12"] = "BG3_12",
        ["MODDED_20"] = "MODDED_20",
        ["VANILLA_1_12"] = "BG3_12",
        ["EXTENDED_13_20"] = "MODDED_20",
        ["VANILLA 1-12"] = "BG3_12",
        ["EXTENDED 13-20"] = "MODDED_20",
    },
    ["MCM_ArrivalCuePolicy"] = {
        ["BALANCED"] = "BALANCED",
        ["ALWAYS_ON"] = "ALWAYS_ON",
        ["OFF"] = "OFF",
        ["ALWAYS ON"] = "ALWAYS_ON",
    },
    ["MCM_SpawnPlacementMode"] = {
        ["AUTO"] = "AUTO",
        ["FIND_VALID_ONLY"] = "FIND_VALID_ONLY",
        ["CREATE_OOS_ONLY"] = "CREATE_OOS_ONLY",
        ["FIND VALID ONLY"] = "FIND_VALID_ONLY",
        ["CREATE OOS ONLY"] = "CREATE_OOS_ONLY",
    },
}

contract.ENUM_LABELS = {
    ["MCM_BalanceProfile"] = {
        ["BG3_12"] = "Vanilla 1-12",
        ["MODDED_20"] = "Extended 13-20",
    },
    ["MCM_ArrivalCuePolicy"] = {
        ["BALANCED"] = "Balanced",
        ["ALWAYS_ON"] = "Always On",
        ["OFF"] = "Off",
    },
    ["MCM_SpawnPlacementMode"] = {
        ["AUTO"] = "Auto",
        ["FIND_VALID_ONLY"] = "Find Valid Only",
        ["CREATE_OOS_ONLY"] = "Create OOS Only",
    },
    ["MCM_DifficultyPreset"] = {
        ["Wayfarer"] = "Wayfarer",
        ["Marked"] = "Marked",
        ["Relentless"] = "Relentless",
        ["Hunted"] = "Hunted",
        ["CUSTOM"] = "CUSTOM",
    },
    ["MCM_CustomBasePreset"] = {
        ["Wayfarer"] = "Wayfarer",
        ["Marked"] = "Marked",
        ["Relentless"] = "Relentless",
        ["Hunted"] = "Hunted",
    },
}

contract.PRESETS = {
    Wayfarer = {
        shortChancePct = 3,
        longChancePct = 10,
        shortDelayMinMinutes = 1,
        shortDelayMaxMinutes = 12,
        longDelayMinMinutes = 3,
        longDelayMaxMinutes = 25,
        intensity = 0.75,
        cooldownEnabled = true,
        cooldownMin = 60,
        applyPartySurprised = false,
        enableTimeInDangerPressure = false,
        enableAmbusherEscape = true,
        escapeStartTurn = 6,
        escapeDC = 12,
        escapeHPThreshold = 55,
        escapeMaxPerCombat = 2,
        vengefulMult = 0.55,
        xpPct = 100,
        disableLoot = false,
        allowChampionLoot = true,
    },
    Marked = {
        shortChancePct = 5,
        longChancePct = 15,
        shortDelayMinMinutes = 0,
        shortDelayMaxMinutes = 10,
        longDelayMinMinutes = 2,
        longDelayMaxMinutes = 20,
        intensity = 0.90,
        cooldownEnabled = true,
        cooldownMin = 45,
        applyPartySurprised = true,
        enableTimeInDangerPressure = true,
        enableAmbusherEscape = true,
        escapeStartTurn = 6,
        escapeDC = 14,
        escapeHPThreshold = 50,
        escapeMaxPerCombat = 1,
        vengefulMult = 0.70,
        xpPct = 30,
        disableLoot = false,
        allowChampionLoot = true,
    },
    Relentless = {
        shortChancePct = 7,
        longChancePct = 20,
        shortDelayMinMinutes = 0,
        shortDelayMaxMinutes = 8,
        longDelayMinMinutes = 2,
        longDelayMaxMinutes = 16,
        intensity = 1.05,
        cooldownEnabled = true,
        cooldownMin = 35,
        applyPartySurprised = true,
        enableTimeInDangerPressure = true,
        enableAmbusherEscape = true,
        escapeStartTurn = 7,
        escapeDC = 16,
        escapeHPThreshold = 45,
        escapeMaxPerCombat = 1,
        vengefulMult = 0.90,
        xpPct = 20,
        disableLoot = false,
        allowChampionLoot = true,
    },
    Hunted = {
        shortChancePct = 9,
        longChancePct = 25,
        shortDelayMinMinutes = 0,
        shortDelayMaxMinutes = 6,
        longDelayMinMinutes = 1,
        longDelayMaxMinutes = 12,
        intensity = 1.20,
        cooldownEnabled = true,
        cooldownMin = 30,
        applyPartySurprised = true,
        enableTimeInDangerPressure = true,
        enableAmbusherEscape = true,
        escapeStartTurn = 7,
        escapeDC = 17,
        escapeHPThreshold = 40,
        escapeMaxPerCombat = 1,
        vengefulMult = 1.10,
        xpPct = 10,
        disableLoot = false,
        allowChampionLoot = true,
    },
}

contract.BASE_PRESET_KEYS = {
    WAYFARER = true,
    MARKED = true,
    RELENTLESS = true,
    HUNTED = true,
}

contract.ID_SET = {}
for _, id in ipairs(contract.IDS or {}) do
    contract.ID_SET[tostring(id)] = true
end

contract.BLUEPRINT_ID_SET = {}
for _, id in ipairs(contract.BLUEPRINT_IDS or {}) do
    contract.BLUEPRINT_ID_SET[tostring(id)] = true
end

function contract.IsKnownId(id)
    return type(id) == "string" and contract.ID_SET[id] == true
end

function contract.IsBlueprintSetting(id)
    return type(id) == "string" and contract.BLUEPRINT_ID_SET[id] == true
end

function contract.GetSettingOwnerKind(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end
    if contract.CONTROL_SETTING_IDS[id] == true then
        return "control"
    end
    if contract.PRESET_SETTING_IDS[id] == true then
        return "preset"
    end
    if contract.GLOBAL_SETTING_IDS[id] == true then
        return "global"
    end
    if contract.SUPPORT_SETTING_IDS[id] == true then
        return "support"
    end
    return nil
end

function contract.IsPresetOwnedSetting(id)
    return contract.GetSettingOwnerKind(id) == "preset"
end

function contract.IsGlobalSetting(id)
    return contract.GetSettingOwnerKind(id) == "global"
end

function contract.IsSupportSetting(id)
    return contract.GetSettingOwnerKind(id) == "support"
end

function contract.IsControlSetting(id)
    return contract.GetSettingOwnerKind(id) == "control"
end

function contract.BuildPresetOwnedSettingValues(presetValues)
    if type(presetValues) ~= "table" then
        return {}
    end
    local updates = {}
    for _, binding in ipairs(contract.PRESET_SETTING_BINDINGS or {}) do
        local value = presetValues[binding.field]
        if binding.kind == "bool" then
            if value == nil then
                value = binding.default == true
            else
                value = contract.ToBool(value)
            end
        elseif binding.kind == "number" then
            value = tonumber(value)
            if value == nil then
                value = binding.default
            end
        else
            if value == nil then
                value = binding.default
            end
        end
        updates[binding.id] = value
    end
    return updates
end

function contract.BuildHiddenPresetKnobValues(presetKey, fallbackPresetKey)
    local resolvedPreset = tostring(presetKey or "")
    if not contract.IsBasePreset(resolvedPreset) then
        resolvedPreset = tostring(fallbackPresetKey or contract.DEFAULT_PRESET)
    end
    if not contract.IsBasePreset(resolvedPreset) then
        resolvedPreset = contract.DEFAULT_PRESET
    end

    local source = type(contract.HIDDEN_PRESET_KNOBS) == "table" and contract.HIDDEN_PRESET_KNOBS[resolvedPreset] or nil
    if type(source) ~= "table" then
        source = contract.HIDDEN_PRESET_KNOBS and contract.HIDDEN_PRESET_KNOBS[contract.DEFAULT_PRESET] or {}
    end

    return {
        presetKey = resolvedPreset,
        tierBias = tostring(source.tierBias or "COMMON_VETERAN_BASELINE"),
        championWeightMultiplier = tonumber(source.championWeightMultiplier) or 0.90,
        fodderEliteBias = tostring(source.fodderEliteBias or "BALANCED"),
        maxVeteran = math.max(0, math.floor((tonumber(source.maxVeteran) or 2) + 0.5)),
        maxElite = math.max(0, math.floor((tonumber(source.maxElite) or 1) + 0.5)),
        maxLegendary = math.max(0, math.floor((tonumber(source.maxLegendary) or 1) + 0.5)),
        tierStatusLevelOffset = math.max(-4, math.min(4, math.floor((tonumber(source.tierStatusLevelOffset) or 0) + 0.5))),
    }
end

function contract.GetLegacyPresetResidueValue(name, presetKey, fallback)
    local bucket = type(contract.LEGACY_PRESET_RESIDUE) == "table" and contract.LEGACY_PRESET_RESIDUE[name] or nil
    if type(bucket) ~= "table" then
        return fallback
    end
    local values = type(bucket.values) == "table" and bucket.values or nil
    if type(values) ~= "table" then
        return fallback
    end
    local value = values[presetKey]
    if value == nil then
        return fallback
    end
    return value
end

function contract.IsBasePreset(key)
    local raw = tostring(key or ""):upper():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    local canonical = contract.ENUM_CANONICAL and contract.ENUM_CANONICAL["MCM_CustomBasePreset"]
    if canonical and canonical[raw] then
        raw = tostring(canonical[raw] or ""):upper()
    end
    return contract.BASE_PRESET_KEYS[raw] == true
end

local function _normalizeNumeric(id, value, fallback)
    local rule = contract.NUMERIC_RULES and contract.NUMERIC_RULES[id]
    if not rule then
        return value, true
    end
    local n = tonumber(value)
    if n == nil then
        n = tonumber(fallback)
    end
    if n == nil then
        return nil, false, "not_numeric"
    end
    local min = tonumber(rule.min)
    local max = tonumber(rule.max)
    if min ~= nil and n < min then
        n = min
    end
    if max ~= nil and n > max then
        n = max
    end
    if rule.integer == true then
        n = math.floor(n + 0.5)
    end
    return n, true
end

local function _normalizeEnum(id, value, fallback)
    local enum = contract.ENUM_RULES and contract.ENUM_RULES[id]
    local canonical = contract.ENUM_CANONICAL and contract.ENUM_CANONICAL[id]
    if not enum then
        return value, true
    end

    local raw = tostring(value or ""):upper():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if canonical and canonical[raw] then
        return canonical[raw], true
    end
    if enum[raw] then
        return raw, true
    end

    local fb = tostring(fallback or ""):upper():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if canonical and canonical[fb] then
        return canonical[fb], true
    end
    if fb ~= "" and enum[fb] then
        return fb, true
    end

    return nil, false, "bad_enum"
end

local function _sanitizeOrFallback(id, value, fallback)
    local out, ok = contract.SanitizeValue(id, value, fallback)
    if ok then
        return out, true
    end

    local fbOut, fbOk = contract.SanitizeValue(id, fallback, fallback)
    if fbOk then
        return fbOut, true
    end

    return fallback, false
end

function contract.SanitizeValue(id, value, fallback)
    if type(id) ~= "string" or id == "" then
        return nil, false, "bad_id"
    end

    if contract.BOOL_IDS and contract.BOOL_IDS[id] then
        return contract.ToBool(value), true
    end

    local numericOut, numericOk, numericReason = _normalizeNumeric(id, value, fallback)
    if contract.NUMERIC_RULES and contract.NUMERIC_RULES[id] then
        return numericOut, numericOk, numericReason
    end

    local enumOut, enumOk, enumReason = _normalizeEnum(id, value, fallback)
    if contract.ENUM_RULES and contract.ENUM_RULES[id] then
        return enumOut, enumOk, enumReason
    end

    return value, true
end

function contract.NormalizeValue(id, value, fallback)
    local out = _sanitizeOrFallback(id, value, fallback)
    return out
end

local function _normalizePresetEnumValue(id, value)
    local canonical = contract.ENUM_CANONICAL and contract.ENUM_CANONICAL[id]
    local enum = contract.ENUM_RULES and contract.ENUM_RULES[id]
    local raw = tostring(value or ""):upper():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if raw == "" then
        return nil
    end
    if canonical and canonical[raw] then
        return canonical[raw]
    end
    if enum and enum[raw] then
        return raw
    end
    return nil
end

function contract.NormalizePresetSelection(presetValue, customBaseValue, advancedModeValue, presetFallback, customBaseFallback)
    local defaultPreset = _normalizePresetEnumValue("MCM_DifficultyPreset", presetFallback) or contract.DEFAULT_PRESET
    if defaultPreset == contract.CUSTOM_PRESET_KEY then
        defaultPreset = contract.DEFAULT_PRESET
    end

    local defaultCustomBase = _normalizePresetEnumValue("MCM_CustomBasePreset", customBaseFallback) or contract.DEFAULT_CUSTOM_BASE_PRESET
    if not contract.IsBasePreset(defaultCustomBase) then
        defaultCustomBase = contract.DEFAULT_CUSTOM_BASE_PRESET
    end

    local preset = _normalizePresetEnumValue("MCM_DifficultyPreset", presetValue)
    local customBase = _normalizePresetEnumValue("MCM_CustomBasePreset", customBaseValue)
    local advancedMode = contract.ToBool(advancedModeValue)
    local hasPersistedCustomBase = (type(customBaseValue) == "string" and customBaseValue:match("%S") ~= nil)

    if preset == contract.CUSTOM_PRESET_KEY then
        if not contract.IsBasePreset(customBase) then
            customBase = defaultCustomBase
        end
        return contract.CUSTOM_PRESET_KEY, customBase
    end

    if contract.IsBasePreset(preset) then
        return preset, preset
    end

    if advancedMode or hasPersistedCustomBase then
        if not contract.IsBasePreset(customBase) then
            customBase = defaultCustomBase
        end
        return contract.CUSTOM_PRESET_KEY, customBase
    end

    return defaultPreset, defaultPreset
end

function contract.GetValueLabel(id, value, fallback)
    local labels = contract.ENUM_LABELS and contract.ENUM_LABELS[id]
    local normalized = contract.NormalizeValue(id, value, fallback)
    if type(labels) == "table" then
        return labels[normalized] or labels[contract.NormalizeValue(id, fallback, fallback)] or tostring(normalized or fallback or "")
    end
    return tostring(normalized or fallback or "")
end

EA.MCMContract = contract
return contract
