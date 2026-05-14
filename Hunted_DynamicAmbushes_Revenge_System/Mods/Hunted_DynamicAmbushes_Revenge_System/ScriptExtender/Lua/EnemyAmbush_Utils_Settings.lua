-- EnemyAmbush_Utils_Settings.lua
-- Extracted from monolithic EnemyAmbush_Utils.lua for local-budget stability.

local ModuleUUID = "96f24297-6ed9-455c-aaa1-ac9c358a8d35"
EnemyAmbush = EnemyAmbush or {}
EnemyAmbush.ModuleUUID = ModuleUUID

-- Legacy forward declarations removed: these no-op globals caused load-order ambiguity.

-- Pull exported helpers from Utils into globals used throughout this file
local EA = EnemyAmbush
local MCMContract = Ext.Require("EnemyAmbush_MCMContract.lua") or (EA and EA.MCMContract) or {}
local EA_LOCA_FIRST_AMBUSH_TUTORIAL = "h63b0e40eg6c0ag4d86gb8f5g5d2f58f91c91;1"

local function EA_SettingsIsModVarsContainer(value)
    local fn = EA and EA["EA_IsModVarsContainer"]
    if type(fn) == "function" then
        return fn(value)
    end
    local t = type(value)
    return t == "table" or t == "userdata"
end

EA_ShowFirstAmbushTutorial = EA_ShowFirstAmbushTutorial or function(player)
    local v = EA_Vars and EA_Vars() or nil
    if not v then return end
    if v.EA_TutorialShown and v.EA_TutorialShown ~= 0 then return end

    v.EA_TutorialShown = 1
    if Ext and Ext.Vars and Ext.Vars.DirtyModVariables then
        Ext.Vars.DirtyModVariables(ModuleUUID)
    end

    if Osi and Osi.OpenMessageBox then
        local text = "You are hunted.\n\nStay vigilant."
        if Ext and Ext.Loca and Ext.Loca.GetTranslatedString then
            local okLoca, translated = pcall(Ext.Loca.GetTranslatedString, EA_LOCA_FIRST_AMBUSH_TUTORIAL)
            if okLoca and type(translated) == "string" and translated ~= "" then
                text = translated
            end
        end
        pcall(Osi.OpenMessageBox, player, text)
    end
end

EnemyAmbush.EA_ShowFirstAmbushTutorial = EA_ShowFirstAmbushTutorial

-- ========= EARLY DEFAULTS / HELPERS (MUST STAY NEAR TOP) =========

-- Normalize UUID to ensure consistent lookup
function EA_IsGuidLike(id)
    if type(id) ~= "string" then return false end
    local a, b, c, d, e = id:match("^([%x]+)%-([%x]+)%-([%x]+)%-([%x]+)%-([%x]+)$")
    if not a then return false end
    return (#a == 8 and #b == 4 and #c == 4 and #d == 4 and #e == 12)
end

function EA_NormalizeUUIDFast(id)
    if id == nil then return nil end
    if type(id) ~= "string" then
        id = tostring(id)
    end
    local n = #id
    if n == 36 then
        if EA_IsGuidLike(id) then
            return string.lower(id)
        end
        return nil
    end
    if n > 36 then
        local tail = id:sub(n - 35, n)
        if EA_IsGuidLike(tail) then
            return string.lower(tail)
        end
    end
    return nil
end

function EA_NormalizeUUID(id)
    if id == nil then return nil end
    if type(id) ~= "string" then id = tostring(id) end

    local fast = EA_NormalizeUUIDFast(id)
    if fast then
        return fast
    end

    -- trim
    id = id:match("^%s*(.-)%s*$")
    if id == "" then return nil end

    if EA_IsGuidLike(id) then
        return id:lower()
    end

    -- Extract a GUID-like token anywhere in the string
    for a, b, c, d, e in id:gmatch("([%x]+)%-([%x]+)%-([%x]+)%-([%x]+)%-([%x]+)") do
        if #a == 8 and #b == 4 and #c == 4 and #d == 4 and #e == 12 then
            return (a .. "-" .. b .. "-" .. c .. "-" .. d .. "-" .. e):lower()
        end
    end

    -- Fallback: keep non-UUID handles/ids so tracking still works
    if #id >= 6 and #id <= 128 then
        return id:lower()
    end

    return nil
end

function EA_HasLoS(a, b)
    if not a or not b or a == "" or b == "" then return false end

    if Osi and Osi.HasLineOfSight then
        local ok, res = pcall(Osi.HasLineOfSight, a, b)
        if ok and res ~= nil then return res == 1 end
    end

    if Osi and Osi.CanSee then
        local ok, res = pcall(Osi.CanSee, a, b)
        if ok and res ~= nil then return res == 1 end
    end

    return false
end

-- ---- SETTINGS + MCM DEFAULTS (NAMESPACED; NO GLOBALS) ----
function EA_ToBool(v)
    local toBool = MCMContract and MCMContract.ToBool
    if type(toBool) == "function" then
        return toBool(v)
    end
    return false
end

function EA_ToNumber(v, default)
    local n = tonumber(v)
    if n == nil then return default end
    return n
end

local function EA_ContractSanitizeSetting(settingId, value, fallback)
    if MCMContract and type(MCMContract.SanitizeValue) == "function" then
        local out, ok = MCMContract.SanitizeValue(settingId, value, fallback)
        if ok then
            return out
        end
    end
    return fallback
end

local function EA_ContractNormalizeSetting(settingId, value, fallback)
    if MCMContract and type(MCMContract.NormalizeValue) == "function" then
        return MCMContract.NormalizeValue(settingId, value, fallback)
    end
    return EA_ContractSanitizeSetting(settingId, value, fallback)
end

local function EA_ContractGetValueLabel(settingId, value, fallback)
    if MCMContract and type(MCMContract.GetValueLabel) == "function" then
        return MCMContract.GetValueLabel(settingId, value, fallback)
    end
    return tostring(EA_ContractNormalizeSetting(settingId, value, fallback) or fallback or "")
end

function EA_NormalizeXPToggle(v)
    local n = tonumber(v) or 0
    if n < 0 then n = 0 end
    if n > 100 then n = 100 end
    return math.floor(n + 0.5)
end

-- Namespace for settings (runtime mirror; MCM remains the source of truth when present)
EnemyAmbush.Settings = EnemyAmbush.Settings or {}
-- Canonical gameplay-facing snapshot. Keep pointer stable and mutate in place.
EnemyAmbush.SettingsSnapshot = EnemyAmbush.SettingsSnapshot or EnemyAmbush.Settings

-- Defaults keyed by MCM settingId (stable + easy mapping)
EnemyAmbush.SettingsDefaults = EnemyAmbush.SettingsDefaults or {
    ["MCM_EnableSummons"]            = true,
    ["MCM_EnableVanillaSummons"]     = true,
    ["MCM_EnableOnRest"]             = true,

    ["MCM_DifficultyPreset"]         = "Marked",
    ["MCM_CustomBasePreset"]         = "Marked",
    ["MCM_AdvancedMode"]             = false,

    ["MCM_ScaleWithPartySize"]       = true,
    ["MCM_CombatExtenderMode"]       = false,

    ["MCM_SafetyChecks"]             = true,
    ["MCM_CampAmbushes"]             = false,
    ["MCM_ApplyPartySurprised"]      = true,
    ["MCM_EnableTimeInDangerPressure"] = true,
    ["MCM_ShowUINotifications"]      = false,
    ["MCM_ShowAmbushWarningNotifications"] = false,
    ["MCM_ShowChampionArrivalPopup"] = false,
    ["MCM_ArrivalCuePolicy"]         = "BALANCED",
    ["MCM_SpawnPlacementMode"]       = "CREATE_OOS_ONLY",

    ["MCM_EnableReputation"]         = true,
    ["MCM_ShowReputationWarnings"]   = false,
    ["MCM_ReputationDecayRate"]      = 0.5,

    ["MCM_PointBudget"]              = 0,
    ["MCM_AmbushIntensity"]          = 0.90,
    ["MCM_StrictProgressionGates"]   = true,
    ["MCM_UseCompositionGuards"]     = true,
    ["MCM_BalanceProfile"]           = "BG3_12",

    -- Keep raw reward defaults aligned with the current shipped default preset (Marked).
    ["MCM_DisableAmbushLoot"]        = false,
    ["MCM_AllowChampionLoot"]        = true,
    ["MCM_AmbushXPPercent"]          = 30,

    ["MCM_EnableDebugLogging"]       = false,
    ["MCM_DebugMode"]                = false,
    ["MCM_RobustMode"]               = false,

    ["MCM_EnableAmbushCooldown"]     = true,
    ["MCM_AmbushCooldownMinutes"]    = 45,
    ["MCM_AmbushChanceShortPct"]     = 5,
    ["MCM_AmbushChanceLongPct"]      = 15,
    ["MCM_ShortRestDelayMinMinutes"] = 0,
    ["MCM_ShortRestDelayMaxMinutes"] = 10,
    ["MCM_LongRestDelayMinMinutes"]  = 2,
    ["MCM_LongRestDelayMaxMinutes"]  = 20,
    ["MCM_QuickTestMode"]            = false,
    ["MCM_SkipBeachTutorialAmbush"]  = false,
    ["MCM_EnableAmbusherEscape"]     = true,
    ["MCM_EscapeStartTurn"]          = 6,
    ["MCM_EscapeDC"]                 = 14,
    ["MCM_EscapeHPThreshold"]        = 50,
    ["MCM_EscapeMaxPerCombat"]       = 1,
}

local EA_SETTINGS  = EnemyAmbush.Settings
local EA_DEFAULTS  = EnemyAmbush.SettingsDefaults
EnemyAmbush.SettingsSnapshot = EA_SETTINGS

function EA_GetSettingsSnapshot()
    local snap = EnemyAmbush and EnemyAmbush.SettingsSnapshot
    if type(snap) ~= "table" then
        snap = EnemyAmbush and EnemyAmbush.Settings or {}
        EnemyAmbush.SettingsSnapshot = snap
    end
    return snap
end

function EA_GetOwnedSettingsTable()
    EnemyAmbush.Settings = EA_SETTINGS
    EnemyAmbush.SettingsSnapshot = EA_SETTINGS
    return EA_SETTINGS
end

function EA_SetOwnedRuntimeSetting(settingId, value)
    local settings = EA_GetOwnedSettingsTable()
    settings[settingId] = value
    EnemyAmbush.SettingsSnapshot = settings
    return value
end

function EA_GetOwnedRuntimeSetting(settingId)
    local settings = EA_GetOwnedSettingsTable()
    return settings[settingId]
end

local function EA_SettingsValuesEqual(a, b)
    if type(a) == "number" and type(b) == "number" then
        return math.abs(a - b) < 1e-6
    end
    return a == b
end

local function EA_RefreshOwnedSettingsState()
    if type(EA_ApplySettingsToLocals) == "function" then
        EA_ApplySettingsToLocals()
    end
    if type(EA_NormalizeMCM) == "function" then
        EA_NormalizeMCM()
    end
    EnemyAmbush.SettingsSnapshot = EA_SETTINGS
    return EA_SETTINGS
end

local function EA_IterOwnedApplyEntries(entries)
    if type(entries) ~= "table" then
        return function() return nil end
    end

    local count = #entries
    if count > 0 then
        local index = 0
        return function()
            index = index + 1
            local item = entries[index]
            if type(item) ~= "table" then
                return nil
            end
            if item.id ~= nil then
                return item.id, item.value
            end
            return item[1], item[2]
        end
    end

    local key, value = next(entries, nil)
    return function()
        local outKey, outValue = key, value
        if outKey == nil then
            return nil
        end
        key, value = next(entries, outKey)
        return outKey, outValue
    end
end

function EA_ApplyOwnedRuntimeSettingsBatch(entries, opts)
    opts = type(opts) == "table" and opts or {}

    local settings = EA_GetOwnedSettingsTable()
    local touchedIds = {}
    local touchedSeen = {}
    local beforeValues = {}

    for settingId, value in EA_IterOwnedApplyEntries(entries) do
        if type(settingId) == "string" and settingId ~= "" then
            if not touchedSeen[settingId] then
                touchedSeen[settingId] = true
                touchedIds[#touchedIds + 1] = settingId
                beforeValues[settingId] = settings[settingId]
            end

            local fallback = settings[settingId]
            if fallback == nil then
                fallback = EA_DEFAULTS[settingId]
            end
            settings[settingId] = EA_ContractSanitizeSetting(settingId, value, fallback)
        end
    end

    local shouldRefresh = opts.refresh ~= false and (#touchedIds > 0 or opts.forceRefresh == true)
    if shouldRefresh then
        EA_RefreshOwnedSettingsState()
    end

    local changedIds = {}
    for _, settingId in ipairs(touchedIds) do
        if not EA_SettingsValuesEqual(beforeValues[settingId], settings[settingId]) then
            changedIds[#changedIds + 1] = settingId
        end
    end

    if touchedSeen["MCM_EnableTimeInDangerPressure"]
        and settings["MCM_EnableTimeInDangerPressure"] == false then
        local clearFn = EA and EA["EA_ClearAllTimeInDangerState"]
        if type(clearFn) == "function" then
            pcall(clearFn, "setting_disabled")
        end
    end

    return {
        touchedIds = touchedIds,
        changedIds = changedIds,
        touchedCount = #touchedIds,
        changedCount = #changedIds,
        anyChanged = (#changedIds > 0),
        refreshed = shouldRefresh,
        settings = settings,
    }
end

function EA_ApplyOwnedRuntimeSetting(settingId, value, opts)
    return EA_ApplyOwnedRuntimeSettingsBatch({
        { id = settingId, value = value }
    }, opts)
end

function EA_GetSettingFromSnapshot(settingId, fallback)
    local snap = EA_GetSettingsSnapshot()
    if type(settingId) ~= "string" or settingId == "" then
        return fallback
    end
    local v = snap[settingId]
    if v == nil then
        return fallback
    end
    return v
end

function EA_ReadSettingRaw(settingId, fallback)
    return EA_GetSettingFromSnapshot(settingId, fallback)
end

function EA_ReadSettingBool(settingId, fallback)
    local value = EA_ReadSettingRaw(settingId, fallback)
    local toBool = (EA and EA["EA_ToBoolSafe"]) or (EA and EA["EA_ToBool"])
    if type(toBool) == "function" then
        local ok, out = pcall(toBool, value)
        if ok then
            return out == true
        end
    end
    return value == true
end

function EA_ReadSettingNumber(settingId, fallback)
    local value = tonumber(EA_ReadSettingRaw(settingId, fallback))
    if value ~= nil then
        return value
    end
    return tonumber(fallback)
end

function EA_SettingsInit()
    for k, v in pairs(EA_DEFAULTS) do
        if EA_SETTINGS[k] == nil then
            EA_SETTINGS[k] = v
        end
    end
end

EA_SettingsInit()

EA["EA_GetOwnedSettingsTable"] = EA_GetOwnedSettingsTable
EA["EA_SetOwnedRuntimeSetting"] = EA_SetOwnedRuntimeSetting
EA["EA_GetOwnedRuntimeSetting"] = EA_GetOwnedRuntimeSetting
EA["EA_ApplyOwnedRuntimeSetting"] = EA_ApplyOwnedRuntimeSetting
EA["EA_ApplyOwnedRuntimeSettingsBatch"] = EA_ApplyOwnedRuntimeSettingsBatch
EA["EA_GetSettingsSnapshot"] = EA_GetSettingsSnapshot
EA["EA_GetSettingFromSnapshot"] = EA_GetSettingFromSnapshot
EA["EA_ReadSettingRaw"] = EA_ReadSettingRaw
EA["EA_ReadSettingBool"] = EA_ReadSettingBool
EA["EA_ReadSettingNumber"] = EA_ReadSettingNumber

local function EA_RestorePersistedCustomBasePresetKey()
    local v = EA_Vars and EA_Vars() or nil
    if not EA_SettingsIsModVarsContainer(v) then
        return false
    end
    local base = v.MCMCustomPresetBase or nil
    if type(base) == "string" and base ~= "" then
        local normalized = MCMContract and type(MCMContract.NormalizeValue) == "function"
            and MCMContract.NormalizeValue("MCM_CustomBasePreset", base, "Marked")
            or base
        if MCMContract and type(MCMContract.IsBasePreset) == "function" and MCMContract.IsBasePreset(normalized) then
            EA_SETTINGS["MCM_CustomBasePreset"] = normalized
            if normalized ~= base then
                v.MCMCustomPresetBase = normalized
                if EA_Dirty then
                    EA_Dirty(true)
                elseif Ext and Ext.Vars and Ext.Vars.DirtyModVariables then
                    Ext.Vars.DirtyModVariables(ModuleUUID)
                end
            end
            return true
        end
    end
    return false
end

EA["EA_RestorePersistedCustomBasePresetKey"] = EA_RestorePersistedCustomBasePresetKey

do
    EA_RestorePersistedCustomBasePresetKey()
end

local EA_OWNER_SETTINGS_CACHE = {}

local EA_OWNER_BOOL_IDS = {
    "MCM_EnableSummons",
    "MCM_EnableVanillaSummons",
    "MCM_EnableOnRest",
    "MCM_AdvancedMode",
    "MCM_ScaleWithPartySize",
    "MCM_CombatExtenderMode",
    "MCM_SafetyChecks",
    "MCM_CampAmbushes",
    "MCM_ApplyPartySurprised",
    "MCM_EnableTimeInDangerPressure",
    "MCM_ShowUINotifications",
    "MCM_ShowAmbushWarningNotifications",
    "MCM_ShowChampionArrivalPopup",
    "MCM_EnableReputation",
    "MCM_ShowReputationWarnings",
    "MCM_StrictProgressionGates",
    "MCM_UseCompositionGuards",
    "MCM_DisableAmbushLoot",
    "MCM_AllowChampionLoot",
    "MCM_EnableDebugLogging",
    "MCM_DebugMode",
    "MCM_RobustMode",
    "MCM_EnableAmbushCooldown",
    "MCM_QuickTestMode",
    "MCM_SkipBeachTutorialAmbush",
    "MCM_EnableAmbusherEscape",
}

local EA_OWNER_NUMBER_DEFAULTS = {
    ["MCM_ReputationDecayRate"] = 0.5,
    ["MCM_PointBudget"] = 0,
    ["MCM_AmbushIntensity"] = 0.90,
    ["MCM_AmbushXPPercent"] = 30,
    ["MCM_AmbushCooldownMinutes"] = 45,
    ["MCM_AmbushChanceShortPct"] = 5,
    ["MCM_AmbushChanceLongPct"] = 15,
    ["MCM_ShortRestDelayMinMinutes"] = 0,
    ["MCM_ShortRestDelayMaxMinutes"] = 10,
    ["MCM_LongRestDelayMinMinutes"] = 2,
    ["MCM_LongRestDelayMaxMinutes"] = 20,
    ["MCM_EscapeStartTurn"] = 6,
    ["MCM_EscapeDC"] = 14,
    ["MCM_EscapeHPThreshold"] = 50,
    ["MCM_EscapeMaxPerCombat"] = 1,
}

local EA_OWNER_STRING_DEFAULTS = {
    ["MCM_DifficultyPreset"] = "Marked",
    ["MCM_CustomBasePreset"] = "Marked",
    ["MCM_ArrivalCuePolicy"] = "BALANCED",
    ["MCM_SpawnPlacementMode"] = "CREATE_OOS_ONLY",
    ["MCM_BalanceProfile"] = "BG3_12",
}

local EA_OWNER_ENUM_DEFAULTS = {
    ["MCM_ArrivalCuePolicy"] = "BALANCED",
    ["MCM_SpawnPlacementMode"] = "CREATE_OOS_ONLY",
    ["MCM_BalanceProfile"] = "BG3_12",
}

local function EA_GetOwnerCachedSetting(settingId, fallback)
    local value = EA_OWNER_SETTINGS_CACHE[settingId]
    if value == nil then
        return fallback
    end
    return value
end

local function EA_WriteOwnerCacheBackToSettings()
    local cache = EA_OWNER_SETTINGS_CACHE

    for _, settingId in ipairs(EA_OWNER_BOOL_IDS) do
        EA_SETTINGS[settingId] = cache[settingId]
    end

    for settingId in pairs(EA_OWNER_NUMBER_DEFAULTS) do
        EA_SETTINGS[settingId] = cache[settingId]
    end

    EA_SETTINGS["MCM_DifficultyPreset"] = cache["MCM_DifficultyPreset"]
    EA_SETTINGS["MCM_CustomBasePreset"] = cache["MCM_CustomBasePreset"]

    for settingId in pairs(EA_OWNER_ENUM_DEFAULTS) do
        EA_SETTINGS[settingId] = cache[settingId]
    end

    -- Legacy cleanup: removed setting; ignore stale values from older saves.
    EA_SETTINGS["MCM_AdvancedFollowsPreset"] = nil
    EA_SETTINGS["MCM_ArrivalCueChanceScale"] = nil
    EnemyAmbush.SettingsSnapshot = EA_SETTINGS
end

-- RC policy: settings are not mirrored into free globals.
-- Gameplay reads through settings snapshot/accessor helpers.

function EA_ApplySettingsToLocals()
    local cache = EA_OWNER_SETTINGS_CACHE

    for _, settingId in ipairs(EA_OWNER_BOOL_IDS) do
        cache[settingId] = EA_ToBool(EA_SETTINGS[settingId])
    end

    for settingId, fallback in pairs(EA_OWNER_NUMBER_DEFAULTS) do
        cache[settingId] = EA_ToNumber(EA_SETTINGS[settingId], fallback)
    end

    for settingId, fallback in pairs(EA_OWNER_STRING_DEFAULTS) do
        cache[settingId] = tostring(EA_SETTINGS[settingId] or fallback)
    end

    EnemyAmbush.SettingsSnapshot = EA_SETTINGS
end

EA_ApplySettingsToLocals()

function EA_NormalizeMCM()
    local cache = EA_OWNER_SETTINGS_CACHE

    for _, settingId in ipairs(EA_OWNER_BOOL_IDS) do
        cache[settingId] = EA_ToBool(cache[settingId])
    end

    for settingId, fallback in pairs(EA_OWNER_NUMBER_DEFAULTS) do
        cache[settingId] = EA_ContractSanitizeSetting(settingId, cache[settingId], fallback)
    end

    for settingId, fallback in pairs(EA_OWNER_ENUM_DEFAULTS) do
        cache[settingId] = EA_ContractNormalizeSetting(settingId, cache[settingId], fallback)
    end

    if MCMContract and type(MCMContract.NormalizePresetSelection) == "function" then
        cache["MCM_DifficultyPreset"], cache["MCM_CustomBasePreset"] =
            MCMContract.NormalizePresetSelection(
                cache["MCM_DifficultyPreset"],
                cache["MCM_CustomBasePreset"],
                cache["MCM_AdvancedMode"],
                "Marked",
                "Marked"
            )
    else
        cache["MCM_DifficultyPreset"] = EA_ContractNormalizeSetting("MCM_DifficultyPreset", cache["MCM_DifficultyPreset"], "Marked")
        cache["MCM_CustomBasePreset"] = EA_ContractNormalizeSetting("MCM_CustomBasePreset", cache["MCM_CustomBasePreset"], "Marked")
        if tostring(cache["MCM_DifficultyPreset"] or "Marked") ~= "CUSTOM" then
            cache["MCM_CustomBasePreset"] = tostring(cache["MCM_DifficultyPreset"] or "Marked")
        end
    end

    EA_WriteOwnerCacheBackToSettings()
end

EA_NormalizeMCM()

-- Debug helpers (still use the locals above)
function IsDebug()
    return EA_GetOwnerCachedSetting("MCM_EnableDebugLogging", false) == true
        or EA_GetOwnerCachedSetting("MCM_DebugMode", false) == true
end

DebugPrint = function(...)
    if IsDebug() then
        print("[EnemyAmbush][Debug]", ...)
    end
end

-- ========= PRESET + ADVANCED MODE =========
EA_PRESETS = (MCMContract and MCMContract.PRESETS) or {
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

function EA_IsAdvancedMode()
    return EA_GetOwnerCachedSetting("MCM_AdvancedMode", false) == true
end

local function EA_IsAdvancedDebugMode()
    return EA_IsAdvancedMode() and EA_GetOwnerCachedSetting("MCM_DebugMode", false) == true
end

local function EA_IsBasePresetKey(key)
    if MCMContract and type(MCMContract.IsBasePreset) == "function" then
        return MCMContract.IsBasePreset(key)
    end
    key = tostring(key or "")
    return key == "Wayfarer" or key == "Marked" or key == "Relentless" or key == "Hunted"
end

function EA_GetCustomBasePresetKey()
    local key = EA_GetSettingFromSnapshot("MCM_CustomBasePreset", "Marked")
    if MCMContract and type(MCMContract.NormalizeValue) == "function" then
        key = MCMContract.NormalizeValue("MCM_CustomBasePreset", key, "Marked")
    end
    if not EA_IsBasePresetKey(key) then
        key = "Marked"
    end
    return key
end

local function EA_PersistCustomBasePresetKey(key)
    local v = EA_Vars and EA_Vars() or nil
    if EA_SettingsIsModVarsContainer(v) then
        v.MCMCustomPresetBase = key
        if EA_Dirty then
            EA_Dirty(true)
        elseif Ext and Ext.Vars and Ext.Vars.DirtyModVariables then
            Ext.Vars.DirtyModVariables(ModuleUUID)
        end
    end
end

function EA_SetCustomBasePresetKey(baseKey, persist)
    local key = baseKey
    if MCMContract and type(MCMContract.NormalizeValue) == "function" then
        key = MCMContract.NormalizeValue("MCM_CustomBasePreset", key, "Marked")
    end
    if not EA_IsBasePresetKey(key) then
        key = "Marked"
    end
    EA_ApplyOwnedRuntimeSetting("MCM_CustomBasePreset", key, { forceRefresh = true })

    if persist == true then
        EA_PersistCustomBasePresetKey(key)
    end
    return key
end

local function EA_GetResolvedPresetKey()
    local key = EA_GetOwnerCachedSetting("MCM_DifficultyPreset", EA_GetSettingFromSnapshot("MCM_DifficultyPreset", "Marked"))
    if MCMContract and type(MCMContract.NormalizeValue) == "function" then
        key = MCMContract.NormalizeValue("MCM_DifficultyPreset", key, "Marked")
    end
    if key == "CUSTOM" then
        key = EA_GetCustomBasePresetKey()
    end
    if not EA_IsBasePresetKey(key) then
        key = "Marked"
    end
    return key
end

function EA_GetPreset()
    local key = EA_GetResolvedPresetKey()
    return EA_PRESETS[key] or EA_PRESETS.Marked
end

local EA_PRESET_HIDDEN_RUNTIME = nil

local function EA_RefreshPresetHiddenRuntimeData()
    local resolvedPreset = EA_GetResolvedPresetKey()
    local hidden = nil
    if MCMContract and type(MCMContract.BuildHiddenPresetKnobValues) == "function" then
        hidden = MCMContract.BuildHiddenPresetKnobValues(resolvedPreset, "Marked")
    end
    if type(hidden) ~= "table" then
        hidden = {
            presetKey = resolvedPreset,
            tierBias = "COMMON_VETERAN_BASELINE",
            championWeightMultiplier = 0.90,
            fodderEliteBias = "BALANCED",
            maxVeteran = 2,
            maxElite = 1,
            maxLegendary = 1,
            tierStatusLevelOffset = 0,
        }
    end
    EA_PRESET_HIDDEN_RUNTIME = hidden
    EA.PresetHiddenBalanceRuntime = hidden
    return hidden
end

function EA_GetPresetHiddenBalanceKnobs()
    local resolvedPreset = EA_GetResolvedPresetKey()
    if type(EA_PRESET_HIDDEN_RUNTIME) ~= "table" or EA_PRESET_HIDDEN_RUNTIME.presetKey ~= resolvedPreset then
        return EA_RefreshPresetHiddenRuntimeData()
    end
    return EA_PRESET_HIDDEN_RUNTIME
end

EA["EA_GetPresetHiddenBalanceKnobs"] = EA_GetPresetHiddenBalanceKnobs

local EA_PRESET_SYNC_SUPPRESSED_WRITES = {}

local function EA_PresetSyncValueKey(value)
    local t = type(value)
    if t == "string" or t == "number" or t == "boolean" then
        return t .. ":" .. tostring(value)
    end
    if value == nil then
        return "nil:"
    end
    return t .. ":"
end

function EA_RegisterPresetSyncWrite(settingId, value)
    if type(settingId) ~= "string" or settingId == "" then
        return false
    end
    EA_PRESET_SYNC_SUPPRESSED_WRITES[settingId] = EA_PresetSyncValueKey(value)
    return true
end

function EA_ConsumePresetSyncWrite(settingId, value)
    if type(settingId) ~= "string" or settingId == "" then
        return false
    end
    local expected = EA_PRESET_SYNC_SUPPRESSED_WRITES[settingId]
    if expected == nil then
        return false
    end
    if expected ~= EA_PresetSyncValueKey(value) then
        return false
    end
    EA_PRESET_SYNC_SUPPRESSED_WRITES[settingId] = nil
    return true
end

EA["EA_RegisterPresetSyncWrite"] = EA_RegisterPresetSyncWrite
EA["EA_ConsumePresetSyncWrite"] = EA_ConsumePresetSyncWrite

function EA_ShouldMarkPresetCustomForSetting(settingId)
    if type(settingId) ~= "string" then
        return false
    end
    if MCMContract and type(MCMContract.IsPresetOwnedSetting) == "function" then
        return MCMContract.IsPresetOwnedSetting(settingId)
    end
    return false
end

function EA_MarkPresetCustomFromAdvancedEdit(settingId, source)
    if not EA_ShouldMarkPresetCustomForSetting(settingId) then
        return false
    end
    if not EA_IsAdvancedMode() then
        return false
    end

    local currentPreset = EA_GetOwnerCachedSetting("MCM_DifficultyPreset", EA_GetSettingFromSnapshot("MCM_DifficultyPreset", "Marked"))
    if MCMContract and type(MCMContract.NormalizeValue) == "function" then
        currentPreset = MCMContract.NormalizeValue("MCM_DifficultyPreset", currentPreset, "Marked")
    end
    local updates = {
        ["MCM_DifficultyPreset"] = "CUSTOM",
    }
    if currentPreset ~= "CUSTOM" then
        if not EA_IsBasePresetKey(currentPreset) then
            currentPreset = "Marked"
        end
        updates["MCM_CustomBasePreset"] = currentPreset
        EA_PersistCustomBasePresetKey(currentPreset)
    end

    if currentPreset == "CUSTOM" and tostring(EA_GetSettingFromSnapshot("MCM_DifficultyPreset", "CUSTOM")):upper() == "CUSTOM" then
        return false
    end

    EA_ApplyOwnedRuntimeSettingsBatch(updates, { forceRefresh = true })

    if MCM then
        EA_RegisterPresetSyncWrite("MCM_DifficultyPreset", "CUSTOM")
        if type(MCM.Set) == "function" then
            pcall(MCM.Set, "MCM_DifficultyPreset", "CUSTOM", ModuleUUID, true)
        end
        if type(MCM.SetSetting) == "function" then
            pcall(MCM.SetSetting, "MCM_DifficultyPreset", "CUSTOM", ModuleUUID, true)
        end
        if updates["MCM_CustomBasePreset"] ~= nil then
            EA_RegisterPresetSyncWrite("MCM_CustomBasePreset", updates["MCM_CustomBasePreset"])
            if type(MCM.Set) == "function" then
                pcall(MCM.Set, "MCM_CustomBasePreset", updates["MCM_CustomBasePreset"], ModuleUUID, true)
            end
            if type(MCM.SetSetting) == "function" then
                pcall(MCM.SetSetting, "MCM_CustomBasePreset", updates["MCM_CustomBasePreset"], ModuleUUID, true)
            end
        end
    end

    if IsDebug() then
        DebugPrint(string.format("[Preset] switched to CUSTOM due to %s (%s)", tostring(settingId), tostring(source or "runtime")))
    end
    if EA_Dirty then
        EA_Dirty()
    end
    return true
end

local function EA_BuildPresetOwnedSettingUpdates()
    local presetValues = EA_GetPreset()
    if MCMContract and type(MCMContract.BuildPresetOwnedSettingValues) == "function" then
        return MCMContract.BuildPresetOwnedSettingValues(presetValues)
    end
    return {}
end

-- Sync advanced-mode knobs to the CURRENT preset (so enabling Advanced doesn't change gameplay)
function EA_SyncAdvancedFromPreset()
    EA_RefreshPresetHiddenRuntimeData()
    EA_ApplyOwnedRuntimeSettingsBatch(EA_BuildPresetOwnedSettingUpdates(), { forceRefresh = true })

    EA_Dirty()
end

function EA_SyncAdvancedFromPresetPersisted()
    EA_RefreshPresetHiddenRuntimeData()
    local updates = EA_BuildPresetOwnedSettingUpdates()

    for id, val in pairs(updates) do
        EA_RegisterPresetSyncWrite(id, val)

        -- Only ask BG3MCM to persist settings that are present in the release
        -- blueprint. Hidden preset-owned knobs are runtime-owned here.
        local canWriteMCM = true
        if MCMContract and type(MCMContract.IsBlueprintSetting) == "function" then
            canWriteMCM = MCMContract.IsBlueprintSetting(id) == true
        end
        if canWriteMCM and MCM then
            if type(MCM.Set) == "function" then
                pcall(MCM.Set, id, val, ModuleUUID, true)
            end
            if type(MCM.SetSetting) == "function" then
                pcall(MCM.SetSetting, id, val, ModuleUUID, true)
            end
        end
    end

    EA_ApplyOwnedRuntimeSettingsBatch(updates, { forceRefresh = true })
    EA_Dirty()
end

function EA_IsRestAmbushEnabled()
    return EA_GetOwnerCachedSetting("MCM_EnableOnRest", false) == true
end

function EA_GetTimeInDangerPressureEnabled()
    return EA_GetOwnerCachedSetting("MCM_EnableTimeInDangerPressure", true) == true
end

function EA_GetStrictProgressionGates()
    return EA_GetOwnerCachedSetting("MCM_StrictProgressionGates", false) == true
end

function EA_GetUseCompositionGuards()
    return EA_GetOwnerCachedSetting("MCM_UseCompositionGuards", false) == true
end

function EA_GetBalanceProfile()
    return EA_GetOwnerCachedSetting("MCM_BalanceProfile", "BG3_12")
end

function EA_GetBalanceProfileLabel(value)
    return EA_ContractGetValueLabel("MCM_BalanceProfile", value or EA_GetOwnerCachedSetting("MCM_BalanceProfile", "BG3_12"), "BG3_12")
end

function EA_GetArrivalCuePolicy()
    local key = EA_GetOwnerCachedSetting("MCM_ArrivalCuePolicy", "BALANCED")
    if key ~= "OFF" and EA_GetOwnerCachedSetting("MCM_QuickTestMode", false) == true then
        return "ALWAYS_ON"
    end
    return key
end

function EA_GetArrivalCuePolicyLabel(value)
    return EA_ContractGetValueLabel("MCM_ArrivalCuePolicy", value or EA_GetOwnerCachedSetting("MCM_ArrivalCuePolicy", "BALANCED"), "BALANCED")
end

function EA_GetArrivalCueChanceScale()
    -- Release MCM keeps arrival cue tuning to policy only; ignore stale
    -- hidden values from builds that exposed a chance-scale slider.
    return 100
end

function EA_GetSpawnPlacementMode()
    return EA_GetOwnerCachedSetting("MCM_SpawnPlacementMode", "CREATE_OOS_ONLY")
end

function EA_GetSpawnPlacementModeLabel(value)
    return EA_ContractGetValueLabel("MCM_SpawnPlacementMode", value or EA_GetOwnerCachedSetting("MCM_SpawnPlacementMode", "CREATE_OOS_ONLY"), "Create OOS Only")
end

function EA_ShouldSkipBeachTutorialAmbush()
    return EA_GetOwnerCachedSetting("MCM_SkipBeachTutorialAmbush", false) == true
end

local function EA_GetChanceMultiplier()
    local presetKey = EA_GetResolvedPresetKey()
    if MCMContract and type(MCMContract.GetLegacyPresetResidueValue) == "function" then
        return tonumber(MCMContract.GetLegacyPresetResidueValue("chanceMult", presetKey, 1.0)) or 1.0
    end
    return 1.0
end

local function EA_ClampPercentToUnit(v, fallbackPct)
    local pct = tonumber(v)
    if pct == nil then
        pct = tonumber(fallbackPct) or 0
    end
    pct = math.floor(pct + 0.5)
    if pct < 0 then pct = 0 end
    if pct > 100 then pct = 100 end
    return pct / 100.0
end

local function EA_ClampDelayMinutes(v, fallback)
    local n = tonumber(v)
    if n == nil then
        n = tonumber(fallback) or 0
    end
    n = math.floor(n + 0.5)
    if n < 0 then n = 0 end
    if n > 60 then n = 60 end
    return n
end

function EA_IsQuickTestMode()
    return EA_GetOwnerCachedSetting("MCM_QuickTestMode", false) == true
end

local function EA_GetPresetRestChancePct(isLongRest)
    local p = EA_GetPreset()
    local pct = tonumber(isLongRest and p.longChancePct or p.shortChancePct)
    if pct == nil then
        -- Backward compatibility with legacy chance multiplier residue.
        local cfg = EnemyAmbush and EnemyAmbush.CFG or nil
        local shortBase = tonumber(cfg and cfg.SUMMON_CHANCE_SHORT) or 0.06
        local longBase = tonumber(cfg and cfg.SUMMON_CHANCE_LONG) or 0.20
        local base = isLongRest and longBase or shortBase
        pct = ((tonumber(base) or 0) * EA_GetChanceMultiplier()) * 100.0
    end
    return pct
end

local function EA_GetPresetRestDelayMinutes(isLongRest)
    local p = EA_GetPreset()
    if isLongRest then
        return
            EA_ClampDelayMinutes(p.longDelayMinMinutes, 2),
            EA_ClampDelayMinutes(p.longDelayMaxMinutes, 20)
    end
    return
        EA_ClampDelayMinutes(p.shortDelayMinMinutes, 0),
        EA_ClampDelayMinutes(p.shortDelayMaxMinutes, 10)
end

function EA_GetEffectiveAmbushXPPercent()
    if EA_IsAdvancedMode() then
        return EA_NormalizeXPToggle(EA_GetOwnerCachedSetting("MCM_AmbushXPPercent", 30))
    end
    return EA_NormalizeXPToggle(EA_GetPreset().xpPct)
end

function EA_GetEffectiveDisableAmbushLoot()
    if EA_IsAdvancedMode() then
        return EA_GetOwnerCachedSetting("MCM_DisableAmbushLoot", false) == true
    end
    return EA_GetPreset().disableLoot == true
end

function EA_GetEffectiveScaleWithPartySize()
    -- In Simple mode (Advanced OFF), keep party scaling ON as baseline behavior.
    if EA_IsAdvancedMode() then
        return EA_GetOwnerCachedSetting("MCM_ScaleWithPartySize", true) == true
    end
    return true
end


function EA_GetEffectiveAllowChampionLoot()
    if EA_IsAdvancedMode() then
        return EA_GetOwnerCachedSetting("MCM_AllowChampionLoot", true) == true
    end
    return EA_GetPreset().allowChampionLoot == true
end

EA_RefreshPresetHiddenRuntimeData()

function EA_GetEffectiveAmbushIntensity()
    if EA_IsAdvancedMode() then
        local v = tonumber(EA_GetOwnerCachedSetting("MCM_AmbushIntensity", 1.0)) or 1.0
        return math.max(0.5, math.min(2.0, v))
    end
    return tonumber(EA_GetPreset().intensity) or 1.0
end

function EA_GetCooldownEnabled()
    if EA_IsQuickTestMode() then
        return false
    end
    if EA_IsAdvancedMode() then
        return EA_GetOwnerCachedSetting("MCM_EnableAmbushCooldown", true) == true
    end
    return EA_GetPreset().cooldownEnabled ~= false
end

function EA_GetCooldownMinutes()
    if EA_IsQuickTestMode() then
        return 0
    end
    if EA_IsAdvancedMode() then
        local v = tonumber(EA_GetOwnerCachedSetting("MCM_AmbushCooldownMinutes", 45)) or 45
        return math.max(0, math.min(120, v))
    end
    local v = tonumber(EA_GetPreset().cooldownMin) or 45
    return math.max(0, math.min(120, v))
end

function EA_GetRestAmbushChance(isLongRest)
    if EA_IsQuickTestMode() then
        return 1.0
    end
    if EA_IsAdvancedDebugMode() then
        if isLongRest then
            return EA_ClampPercentToUnit(EA_GetOwnerCachedSetting("MCM_AmbushChanceLongPct", 15), 15)
        end
        return EA_ClampPercentToUnit(EA_GetOwnerCachedSetting("MCM_AmbushChanceShortPct", 5), 5)
    end
    return EA_ClampPercentToUnit(EA_GetPresetRestChancePct(isLongRest), isLongRest and 15 or 5)
end

function EA_GetRestDelayWindowMinutes(isLongRest)
    if EA_IsQuickTestMode() then
        return 0, 0
    end

    local minMinutes = 0
    local maxMinutes = 0
    if EA_IsAdvancedDebugMode() then
        if isLongRest then
            minMinutes = EA_ClampDelayMinutes(EA_GetOwnerCachedSetting("MCM_LongRestDelayMinMinutes", 2), 2)
            maxMinutes = EA_ClampDelayMinutes(EA_GetOwnerCachedSetting("MCM_LongRestDelayMaxMinutes", 20), 20)
        else
            minMinutes = EA_ClampDelayMinutes(EA_GetOwnerCachedSetting("MCM_ShortRestDelayMinMinutes", 0), 0)
            maxMinutes = EA_ClampDelayMinutes(EA_GetOwnerCachedSetting("MCM_ShortRestDelayMaxMinutes", 10), 10)
        end
    else
        minMinutes, maxMinutes = EA_GetPresetRestDelayMinutes(isLongRest)
    end

    if maxMinutes < minMinutes then
        minMinutes, maxMinutes = maxMinutes, minMinutes
    end
    return minMinutes, maxMinutes
end

local VENGEFUL_CHAMPION_BASE_CHANCE = 0.30
function EA_GetVengefulChampionChance()
    local mult = tonumber(EA_GetPreset().vengefulMult) or 1.0
    local chance = VENGEFUL_CHAMPION_BASE_CHANCE * mult
    if chance < 0 then chance = 0 end
    if chance > 1 then chance = 1 end
    return chance
end

local EA_XP_TABLE = {
  [1]  = { Zero=0, Civilian=1, Pack=3,  Combatant=10, Elite=15,  Miniboss=20, Boss=30 },
  [2]  = { Zero=0, Civilian=1, Pack=5,  Combatant=15, Elite=25,  Miniboss=40, Boss=75 },
  [3]  = { Zero=0, Civilian=1, Pack=10, Combatant=20, Elite=40,  Miniboss=50, Boss=100 },
  [4]  = { Zero=0, Civilian=1, Pack=20, Combatant=40, Elite=75,  Miniboss=100,Boss=150 },
  [5]  = { Zero=0, Civilian=1, Pack=40, Combatant=75, Elite=90,  Miniboss=150,Boss=250 },
  [6]  = { Zero=0, Civilian=1, Pack=50, Combatant=90, Elite=150, Miniboss=230,Boss=320 },
  [7]  = { Zero=0, Civilian=1, Pack=60, Combatant=110,Elite=180, Miniboss=280,Boss=400 },
  [8]  = { Zero=0, Civilian=1, Pack=75, Combatant=140,Elite=220, Miniboss=350,Boss=500 },
  [9]  = { Zero=0, Civilian=1, Pack=110,Combatant=200,Elite=315, Miniboss=500,Boss=700 },
  [10] = { Zero=0, Civilian=1, Pack=135,Combatant=250,Elite=400, Miniboss=640,Boss=875 },
  -- BG3 caps creature XP at lvl 12+ (treat 11/12 similarly if you want; keeping 10 is already useful for early-game control)
}

local function EA_ClampInt(v, lo, hi)
  v = math.floor(tonumber(v) or lo)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

function EA_CalcKillXP(level, rewardCategory)
  local rawLevel = EA_ClampInt(level, 1, 20)
  local tableLevel = math.min(rawLevel, 10)
  rewardCategory = rewardCategory or "Combatant"

  local row = EA_XP_TABLE[tableLevel]
  local base = (row and row[rewardCategory]) or (row and row.Combatant) or 0
  if base <= 0 then
      return 0
  end

  if rawLevel <= 10 then
      return base
  end

  -- Extend progression for mods that raise level cap (eg to 20).
  -- +5% per level above 10, capped at level 20 (max +50%).
  local extraLevels = rawLevel - 10
  local mult = 1.0 + (extraLevels * 0.05)
  return math.floor(base * mult + 0.5)
end

-- Robust logging + retry tuning (module-owned; accessed through helpers).
local ROBUST_LOG_ARGS = false

local ROBUST_CREATE_RETRIES = 4
local ROBUST_CREATE_RETRY_DELAY_MS = 150

local ROBUST_HOSTILE_RETRIES = 4
local ROBUST_HOSTILE_RETRY_DELAY_MS = 200

function EA_IsRobust()
    return EA_GetOwnerCachedSetting("MCM_RobustMode", false) == true
end

function EA_GetRobustLogArgs()
    return ROBUST_LOG_ARGS == true
end

function EA_GetRobustCreateRetries()
    return tonumber(ROBUST_CREATE_RETRIES) or 4
end

function EA_GetRobustCreateRetryDelayMs()
    return tonumber(ROBUST_CREATE_RETRY_DELAY_MS) or 150
end

function EA_GetRobustHostileRetries()
    return tonumber(ROBUST_HOSTILE_RETRIES) or 4
end

function EA_GetRobustHostileRetryDelayMs()
    return tonumber(ROBUST_HOSTILE_RETRY_DELAY_MS) or 200
end

-- Local retry helper (only used inside this file)
function RobustRetry(tag, maxAttempts, delayMs, tryFn, doneFn)
    local attempt = 1

    local function step()
        local ok, result = pcall(tryFn, attempt)

        if ok and result then
            if doneFn then doneFn(result) end
            return
        end

        if attempt >= maxAttempts then
            if EA_IsRobust() then
                print(string.format("[EnemyAmbush][ROBUST] %s FAILED after %d attempts", tag, attempt))
            end
            return
        end

        attempt = attempt + 1
        if EA_IsRobust() and delayMs and delayMs > 0 then
            print(string.format("[EnemyAmbush][ROBUST] %s retrying. (attempt %d in %dms)", tag, attempt, delayMs))
        end

        if delayMs and delayMs > 0 then
            Ext.Timer.WaitFor(delayMs, step)
        else
            step()
        end
    end

    step()
end

local EA_StatusExistsCache = {}

function SafeApplyStatus(entity, status, duration, force)
    -- Validate status exists (helps when optional mods are missing)
    if Ext and Ext.Stats and Ext.Stats.Get then
        local cached = EA_StatusExistsCache[status]
        if cached == nil then
            local ok, stat = pcall(Ext.Stats.Get, status)
            cached = (ok and stat ~= nil)
            EA_StatusExistsCache[status] = cached
        end
        if cached ~= true then
            if IsDebug() then
                print("[EnemyAmbush][DEBUG] Skipping missing status:", status)
            end
            return false
        end
    end

    local success, err = pcall(function()
        Osi.ApplyStatus(entity, status, duration, force)
    end)
    if not success then
        print(string.format("[EnemyAmbush][ERROR] Failed to apply status %s: %s", status, err))
        return false
    end
    return true
end

function EA_ResetStatusExistenceCache()
    EA_StatusExistsCache = {}
end

function SafeRemoveStatus(entity, status)
    if not entity or entity == "" then return false end
    if not status or status == "" then return false end
    if not Osi or not Osi.RemoveStatus then return false end

    local ok, err = pcall(function()
        Osi.RemoveStatus(entity, status)
    end)
    if not ok then
        if IsDebug() then
            print(string.format("[EnemyAmbush][DEBUG] Failed to remove status %s: %s", tostring(status), tostring(err)))
        end
        return false
    end
    return true
end
