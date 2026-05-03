EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

-- Keep local fallback to module UUID for standalone safety.
local ModuleUUID = EA.ModuleUUID or "96f24297-6ed9-455c-aaa1-ac9c358a8d35"
EA.ModuleUUID = ModuleUUID

-- Config/MCM sync paths can run before Systems touches Cache fallback branches.
-- SpawnPipeline remains the owner of the shared cache bag shape; this file only
-- seeds the retained internal mirror early for bootstrap safety.
EnemyAmbush.Cache = EnemyAmbush.Cache or {}
local Cache = EnemyAmbush.Cache

local MCMContract = Ext.Require("EnemyAmbush_MCMContract.lua") or (EA and EA.MCMContract) or {}
local EA_ToBoolSafe = EA["EA_ToBoolSafe"]
local EA_ReadSettingBool = EA["EA_ReadSettingBool"]
local EA_ConfigDebugEnabled
local function EA_P0Inc(...)
    local fn = EA and EA["EA_P0Inc"]
    if type(fn) == "function" then
        return fn(...)
    end
    return 0
end

local function EA_ConfigIsModVarsContainer(value)
    local fn = EA and EA["EA_IsModVarsContainer"]
    if type(fn) == "function" then
        return fn(value)
    end
    local t = type(value)
    return t == "table" or t == "userdata"
end

local function EA_GetPersistedSettingsRoot()
    local v = (EA_Vars and EA_Vars()) or nil
    if not EA_ConfigIsModVarsContainer(v) then
        return nil
    end
    return v
end

local function EA_RestorePersistedCustomBasePresetFromRoot()
    local fn = EA and EA["EA_RestorePersistedCustomBasePresetKey"]
    if type(fn) == "function" then
        pcall(fn)
    end
end

local function EA_NormalizePresetSettingForConfig(id, value, fallback)
    if MCMContract and type(MCMContract.NormalizeValue) == "function" then
        return MCMContract.NormalizeValue(id, value, fallback)
    end
    return value ~= nil and value or fallback
end

local function EA_GetCurrentPresetSelection()
    local getSetting = EA and EA["EA_GetOwnedRuntimeSetting"]
    if type(getSetting) == "function" then
        return getSetting("MCM_DifficultyPreset")
    end
    local settings = EnemyAmbush and EnemyAmbush.Settings
    if type(settings) == "table" then
        return settings["MCM_DifficultyPreset"]
    end
    return nil
end

local function EA_PersistNormalizedPresetToMCMIfNeeded(rawPresetValue)
    local normalizedPreset = EA_GetCurrentPresetSelection()
    normalizedPreset = EA_NormalizePresetSettingForConfig("MCM_DifficultyPreset", normalizedPreset, "Marked")
    local normalizedRaw = EA_NormalizePresetSettingForConfig("MCM_DifficultyPreset", rawPresetValue, "Marked")
    if normalizedPreset == nil or normalizedPreset == normalizedRaw then
        return false
    end

    local registerPresetSyncWrite = EA and EA["EA_RegisterPresetSyncWrite"]
    if type(registerPresetSyncWrite) == "function" then
        pcall(registerPresetSyncWrite, "MCM_DifficultyPreset", normalizedPreset)
    end

    if MCM then
        if type(MCM.Set) == "function" then
            pcall(MCM.Set, "MCM_DifficultyPreset", normalizedPreset, ModuleUUID, true)
        end
        if type(MCM.SetSetting) == "function" then
            pcall(MCM.SetSetting, "MCM_DifficultyPreset", normalizedPreset, ModuleUUID, true)
        end
    end
    return true
end

local EA_REQUIRED_MCM_DEFAULTS_APPLIED = false
local EA_REQUIRED_MCM_MISSING_LOGGED = false

local function EA_ReportMissingRequiredMCM(reason)
    EA_P0Inc("readiness.mcmRequiredMissing")
    if EA_REQUIRED_MCM_MISSING_LOGGED and not EA_ConfigDebugEnabled() then
        return
    end
    EA_REQUIRED_MCM_MISSING_LOGGED = true
    print(string.format(
        "[EnemyAmbush][MCM] BG3MCM is required (%s). Install Mod Configuration Menu and reload this save.",
        tostring(reason or "missing_mcm")
    ))
end

local function EA_ApplyRequiredMCMMissingDefaults()
    if EA_REQUIRED_MCM_DEFAULTS_APPLIED then
        return
    end
    EA_REQUIRED_MCM_DEFAULTS_APPLIED = true
    EA_ApplyRuntimeSettingsBatch({}, { forceRefresh = true })
end

-- ========= MCM loader =========
EA_MCM_IDS = MCMContract.IDS or EA_MCM_IDS or {}
EA_MCM_BLUEPRINT_IDS = MCMContract.BLUEPRINT_IDS or EA_MCM_IDS

EA_MCM_WATCHED = {}
for _, id in ipairs(EA_MCM_IDS) do
    EA_MCM_WATCHED[id] = true
end

local EA_MCM_REBUILD_IDS = {
    ["MCM_EnableSummons"] = true,
    ["MCM_EnableVanillaSummons"] = true,
    ["MCM_ScaleWithPartySize"] = true,
    ["MCM_CombatExtenderMode"] = true,
    ["MCM_PointBudget"] = true,
    ["MCM_AmbushIntensity"] = true,
    ["MCM_StrictProgressionGates"] = true,
    ["MCM_BalanceProfile"] = true,
}

local EA_MCM_BOOTSTRAP_RETRY_SCHEDULED = false
local EA_MCM_SAVE_EVENT_WINDOW_MS = 120
local EA_MCM_LAST_SAVE_EVENT = {}

local function EA_StringifyMCMValue(value)
    local t = type(value)
    if t == "string" or t == "number" or t == "boolean" then
        return tostring(value)
    end
    if value == nil then
        return "<nil>"
    end
    if Ext and Ext.Json and type(Ext.Json.Stringify) == "function" then
        local ok, out = pcall(Ext.Json.Stringify, value)
        if ok and type(out) == "string" and out ~= "" then
            return out
        end
    end
    return "<" .. t .. ">"
end

local function EA_ShouldSkipRapidDuplicateSave(id, value)
    local now = 0
    if type(EA_ConfigNowMs) == "function" then
        local ok, out = pcall(EA_ConfigNowMs)
        if ok and tonumber(out) then
            now = tonumber(out)
        end
    end
    local key = tostring(id or "")
    local currentValue = EA_StringifyMCMValue(value)
    local last = EA_MCM_LAST_SAVE_EVENT[key]
    if last and now > 0 then
        local age = now - (tonumber(last.atMs) or 0)
        if age >= 0 and age <= EA_MCM_SAVE_EVENT_WINDOW_MS and tostring(last.value or "") == currentValue then
            if EA_ConfigDebugEnabled() then
                print(string.format("[EnemyAmbush][MCM] Suppressed duplicate save event for %s (age=%dms)", key, age))
            end
            return true
        end
    end
    EA_MCM_LAST_SAVE_EVENT[key] = {
        atMs = now,
        value = currentValue
    }
    return false
end

local function EA_BumpProviderRevision(reason)
    if EA and type(EA.InvalidateEnemyProviderCache) == "function" then
        pcall(EA.InvalidateEnemyProviderCache, tostring(reason or "setting_change"))
    end
    if EA and type(EA["EA_ResetStatusExistenceCache"]) == "function" then
        pcall(EA["EA_ResetStatusExistenceCache"])
    end
end

local function EA_ToBoolCompat(v)
    local fn = EA_ToBoolSafe or (EA and EA["EA_ToBoolSafe"])
    if type(fn) == "function" then
        local ok, out = pcall(fn, v)
        if ok then
            return out == true
        end
    end
    if MCMContract and type(MCMContract.ToBool) == "function" then
        return MCMContract.ToBool(v)
    end
    return v == true
end

EA_ConfigDebugEnabled = function()
    if type(EA_ReadSettingBool) == "function" then
        return EA_ReadSettingBool("MCM_EnableDebugLogging", false) == true
            or EA_ReadSettingBool("MCM_DebugMode", false) == true
    end
    return false
end

local function EA_SetRuntimeSetting(id, value)
    local setFn = EA and EA["EA_SetOwnedRuntimeSetting"]
    if type(setFn) == "function" then
        return setFn(id, value)
    end
    local settings = type(EnemyAmbush.Settings) == "table" and EnemyAmbush.Settings or nil
    if type(settings) ~= "table" then
        return value
    end
    settings[id] = value
    EnemyAmbush.SettingsSnapshot = settings
    return value
end

local function EA_GetRuntimeSetting(id)
    local getFn = EA and EA["EA_GetOwnedRuntimeSetting"]
    if type(getFn) == "function" then
        return getFn(id)
    end
    local settings = type(EnemyAmbush.Settings) == "table" and EnemyAmbush.Settings or nil
    if type(settings) ~= "table" then
        return nil
    end
    EnemyAmbush.SettingsSnapshot = settings
    return settings[id]
end

local function EA_ShouldMarkPresetCustom(settingId)
    local fn = EA_ShouldMarkPresetCustomForSetting or (EA and EA["EA_ShouldMarkPresetCustomForSetting"])
    if type(fn) == "function" then
        local ok, out = pcall(fn, settingId)
        return ok and out == true
    end
    return false
end

local function EA_TryMarkPresetCustom(settingId, source)
    local fn = EA_MarkPresetCustomFromAdvancedEdit or (EA and EA["EA_MarkPresetCustomFromAdvancedEdit"])
    if type(fn) == "function" then
        local ok, out = pcall(fn, settingId, source)
        return ok and out == true
    end
    return false
end

function EA_ConfigValuesEqual(a, b)
    if type(a) == "number" and type(b) == "number" then
        return math.abs(a - b) < 1e-6
    end
    return a == b
end

local function EA_ApplyRuntimeSetting(id, value, opts)
    local applyFn = EA_ApplyOwnedRuntimeSetting or (EA and EA["EA_ApplyOwnedRuntimeSetting"])
    if type(applyFn) == "function" then
        return applyFn(id, value, opts)
    end

    local current = EA_GetRuntimeSetting(id)
    EA_SetRuntimeSetting(id, value)

    opts = type(opts) == "table" and opts or {}
    local refreshed = false
    if opts.refresh ~= false then
        if EA_ApplySettingsToLocals then EA_ApplySettingsToLocals() end
        if EA_NormalizeMCM then EA_NormalizeMCM() end
        refreshed = true
    end

    local changed = not EA_ConfigValuesEqual(current, EA_GetRuntimeSetting(id))
    return {
        touchedIds = { id },
        changedIds = changed and { id } or {},
        touchedCount = 1,
        changedCount = changed and 1 or 0,
        anyChanged = changed,
        refreshed = refreshed,
    }
end

local function EA_ApplyRuntimeSettingsBatch(entries, opts)
    local applyFn = EA_ApplyOwnedRuntimeSettingsBatch or (EA and EA["EA_ApplyOwnedRuntimeSettingsBatch"])
    if type(applyFn) == "function" then
        return applyFn(entries, opts)
    end

    opts = type(opts) == "table" and opts or {}
    local touchedIds = {}
    local changedIds = {}
    local beforeValues = {}
    local seen = {}

    if type(entries) == "table" then
        local count = #entries
        if count > 0 then
            for _, item in ipairs(entries) do
                local id = type(item) == "table" and item.id or nil
                local value = type(item) == "table" and item.value or nil
                if type(id) == "string" and id ~= "" then
                    if not seen[id] then
                        seen[id] = true
                        touchedIds[#touchedIds + 1] = id
                        beforeValues[id] = EA_GetRuntimeSetting(id)
                    end
                    EA_SetRuntimeSetting(id, value)
                end
            end
        else
            for id, value in pairs(entries) do
                if type(id) == "string" and id ~= "" then
                    if not seen[id] then
                        seen[id] = true
                        touchedIds[#touchedIds + 1] = id
                        beforeValues[id] = EA_GetRuntimeSetting(id)
                    end
                    EA_SetRuntimeSetting(id, value)
                end
            end
        end
    end

    local refreshed = false
    if opts.refresh ~= false and (#touchedIds > 0 or opts.forceRefresh == true) then
        if EA_ApplySettingsToLocals then EA_ApplySettingsToLocals() end
        if EA_NormalizeMCM then EA_NormalizeMCM() end
        refreshed = true
    end

    for _, id in ipairs(touchedIds) do
        if not EA_ConfigValuesEqual(beforeValues[id], EA_GetRuntimeSetting(id)) then
            changedIds[#changedIds + 1] = id
        end
    end

    return {
        touchedIds = touchedIds,
        changedIds = changedIds,
        touchedCount = #touchedIds,
        changedCount = #changedIds,
        anyChanged = (#changedIds > 0),
        refreshed = refreshed,
    }
end

function EA_ConfigNowMs()
    if type(EA_NowMs) == "function" then
        local ok, ts = pcall(EA_NowMs)
        if ok and type(ts) == "number" then
            return ts
        end
    end
    if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
        local ok, ts = pcall(Ext.Utils.MonotonicTime)
        if ok and type(ts) == "number" then
            return ts
        end
    end
    return 0
end

function EA_SettingAffectsProviderActivation(settingId)
    if type(settingId) ~= "string" or settingId == "" then
        return false
    end

    local providers = EnemyAmbush and EnemyAmbush._providers
    if type(providers) == "table" then
        for _, provider in pairs(providers) do
            if type(provider) == "table" then
                local opts = provider.opts
                if type(opts) == "table" and opts.enabledVar == settingId then
                    return true
                end
            end
        end
    end

    local championProviders = EnemyAmbush and EnemyAmbush._championProviders
    if type(championProviders) == "table" then
        for _, provider in pairs(championProviders) do
            if type(provider) == "table" then
                local opts = provider.opts
                if type(opts) == "table" and opts.enabledVar == settingId then
                    return true
                end
            end
        end
    end

    return false
end

EA_COMBAT_EXTENDER_UUID = "0c692104-c83f-48b8-9fcd-ca7e33be5098"

function EA_IsModLoadedByUUID(uuid)
    if not uuid or uuid == "" then return false end
    if not Ext or not Ext.Mod or type(Ext.Mod.IsModLoaded) ~= "function" then return false end
    local ok, loaded = pcall(Ext.Mod.IsModLoaded, uuid)
    return ok and loaded == true
end

function EA_DetectCombatExtenderByStatProbe()
    if not Ext or not Ext.Stats or type(Ext.Stats.Get) ~= "function" then
        return false
    end

    -- Fallback for edge cases where UUID lookup is unavailable but CX stats are loaded.
    local probes = { "CX_APPLIED", "CX_ATTACK_1", "CX_SAVINGTHROW_1", "CX_Fighter_Boost" }
    for _, sid in ipairs(probes) do
        local ok, stat = pcall(Ext.Stats.Get, sid)
        if ok and stat ~= nil then
            return true
        end
    end
    return false
end

function EA_DetectCombatExtender()
    -- Primary: explicit UUID detection.
    if EA_IsModLoadedByUUID(EA_COMBAT_EXTENDER_UUID) then
        return true, "uuid"
    end

    -- Secondary: stats probe for unusual load-order / packaging edge cases.
    if EA_DetectCombatExtenderByStatProbe() then
        return true, "stat-probe"
    end

    return false, "none"
end

function EA_ResolveCXMode()
    local v = EA_Vars and EA_Vars() or nil
    local override = v and v.CXOverride or nil -- nil/0/1

    local detected, detectedBy = EA_DetectCombatExtender()
    local cx

    -- Detection gate: enable only when CX is detected (UUID or stat probe).
    if not detected then
        cx = false

        -- If settings were previously true (eg stale from old auto-detect), report once per resolve.
        if (override == 1 or (type(EA_ReadSettingBool) == "function" and EA_ReadSettingBool("MCM_CombatExtenderMode", false) == true)) and EA_ConfigDebugEnabled() then
            print("[EnemyAmbush][CX] Combat Extender not detected; forcing CX mode OFF.")
        end
    else
        if override == 0 then
            cx = false
        elseif override == 1 then
            cx = true
        else
            cx = true
        end

        if override == nil and not (type(EA_ReadSettingBool) == "function" and EA_ReadSettingBool("MCM_CombatExtenderMode", false) == true) and EA_ConfigDebugEnabled() then
            print(string.format("[EnemyAmbush][CX] Combat Extender detected (%s); enabling CX mode automatically. (Toggle CX mode in MCM to override.)", tostring(detectedBy)))
        end
    end

    local cxEnabled = (cx == true)
    EA_SetRuntimeSetting("MCM_CombatExtenderMode", cxEnabled)
end

function ApplyMCMSettings()
    -- NOTE: EnemyAmbush.SettingsDefaults + EnemyAmbush.Settings already exist from the namespaced defaults block.
    -- Pull from MCM if present, else keep defaults.
if not MCM or not MCM.Get then
    EA_ReportMissingRequiredMCM("missing_mcm_get")
    EA_ApplyRequiredMCMMissingDefaults()
    EA_ResolveCXMode()
    return
end

    EA_REQUIRED_MCM_DEFAULTS_APPLIED = false

    -- Only load settings relevant to Enemy Ambush
    local ids = EA_MCM_BLUEPRINT_IDS or EA_MCM_IDS or {}

    local loadedCount = 0
    local loadedEntries = {}
    local loadedValues = {}
    for _, id in ipairs(ids) do
        local ok, val = pcall(MCM.Get, id)
        if ok and val ~= nil then
            loadedEntries[#loadedEntries + 1] = { id = id, value = val }
            loadedValues[id] = val
            loadedCount = loadedCount + 1
        end
    end

    local controlsLoaded = loadedValues["MCM_DifficultyPreset"] ~= nil and loadedValues["MCM_AdvancedMode"] ~= nil

    -- SessionLoaded ordering quirk: BG3MCM may still be populating values on early ticks.
    -- If the control settings are missing, avoid pushing preset defaults back into MCM
    -- until a later retry confirms the real saved values.
    if (not controlsLoaded) and (not EA_MCM_BOOTSTRAP_RETRY_SCHEDULED) and Ext and Ext.Timer and Ext.Timer.WaitFor then
        EA_MCM_BOOTSTRAP_RETRY_SCHEDULED = true
        EA_P0Inc("readiness.mcmBootstrapRetryScheduled")
        print("[EnemyAmbush][MCM] Initial MCM pull incomplete; retrying once in 1500ms before preset sync.")
        Ext.Timer.WaitFor(1500, function()
            EA_P0Inc("readiness.mcmBootstrapRetryFired")
            ApplyMCMSettings()
        end)
    end

    EA_ApplyRuntimeSettingsBatch(loadedEntries, { forceRefresh = true })

    if not controlsLoaded then
        EA_ResolveCXMode()
        print(string.format("[EnemyAmbush][MCM] Settings pull incomplete (%d values loaded); deferring preset sync until controls are available.", tonumber(loadedCount) or 0))
        return
    end

    EA_PersistNormalizedPresetToMCMIfNeeded(loadedValues["MCM_DifficultyPreset"])

    local startupPreset = EA_NormalizePresetSettingForConfig("MCM_DifficultyPreset", EA_GetCurrentPresetSelection(), "Marked")
    if startupPreset ~= "CUSTOM" then
        if EA_SyncAdvancedFromPresetPersisted then
            EA_SyncAdvancedFromPresetPersisted()
        elseif EA_SyncAdvancedFromPreset then
            EA_SyncAdvancedFromPreset()
        end
    end

    -- Finally resolve CX mode (auto-detect unless user override exists)
    EA_ResolveCXMode()

    print("[EnemyAmbush][MCM] Settings loaded from MCM (namespaced).")
end

if Ext and Ext.ModEvents and Ext.ModEvents.BG3MCM then
    local mcmSavedEvent = Ext.ModEvents.BG3MCM["MCM_Setting_Saved"]
    if mcmSavedEvent and mcmSavedEvent.Subscribe then
        mcmSavedEvent:Subscribe(function(payload)
        if not payload or (payload.modUUID and payload.modUUID ~= ModuleUUID) or not payload.settingId then return end
        local id = payload.settingId
        if EA_ShouldSkipRapidDuplicateSave(id, payload.value) then
            return
        end

        local applyMeta = EA_ApplyRuntimeSetting(id, payload.value, { forceRefresh = true })
        local effectiveChanged = applyMeta and applyMeta.anyChanged == true
        local persistedSettingsDirty = (EA_PersistSyncedSetting(id, payload.value) == true)

        -- If user touched CX mode, persist an override so auto-detect won't fight them
        if id == "MCM_CombatExtenderMode" then
            local v = EA_GetPersistedSettingsRoot()
            if EA_ConfigIsModVarsContainer(v) then
                v.CXOverride = (EA_ToBoolCompat(payload.value) and 1 or 0)
                persistedSettingsDirty = true
            end
            if EA_ResolveCXMode then EA_ResolveCXMode() end
        end

        -- Preset writes are authoritative for baseline values whenever preset is not CUSTOM.
    if id == "MCM_DifficultyPreset" then
        local normalizedPreset = EA_NormalizePresetSettingForConfig("MCM_DifficultyPreset", payload.value, "Marked")
        if normalizedPreset ~= "CUSTOM" then
            if EA_SyncAdvancedFromPresetPersisted then
                EA_SyncAdvancedFromPresetPersisted()
            elseif EA_SyncAdvancedFromPreset then
                EA_SyncAdvancedFromPreset()
            end
        end
        effectiveChanged = true
    end

        -- CUSTOM keeps its stored advanced values across Advanced toggles; non-CUSTOM keeps preset baseline authority.
    if id == "MCM_AdvancedMode" then
        local advancedOn = EA_ToBoolCompat(payload.value)
        local preset = EA_NormalizePresetSettingForConfig(
            "MCM_DifficultyPreset",
            (EnemyAmbush.Settings and EnemyAmbush.Settings["MCM_DifficultyPreset"]) or "Marked",
            "Marked"
        )
        local shouldReapply = preset ~= "CUSTOM"
        if shouldReapply then
            if EA_SyncAdvancedFromPresetPersisted then
                EA_SyncAdvancedFromPresetPersisted()
            elseif EA_SyncAdvancedFromPreset then
                EA_SyncAdvancedFromPreset()
            end
            effectiveChanged = true
            if (not advancedOn) and EA_ConfigDebugEnabled() then
                print(string.format("[EnemyAmbush][MCM] Advanced OFF -> preset baseline reapplied (%s)", tostring(preset)))
            end
        end
    end

        local suppressPresetCustom = false
        if EA_ShouldMarkPresetCustom(id) then
            local consumePresetSyncWrite = EA_ConsumePresetSyncWrite or (EA and EA["EA_ConsumePresetSyncWrite"])
            if type(consumePresetSyncWrite) == "function" then
                suppressPresetCustom = consumePresetSyncWrite(id, payload.value) == true
            end
        end

        if (not suppressPresetCustom) and EA_ShouldMarkPresetCustom(id) and EA_TryMarkPresetCustom(id, "mcm_saved") then
            effectiveChanged = true
        end

        local providerAffects = EA_SettingAffectsProviderActivation(id)
        if EA_MCM_REBUILD_IDS[id] or providerAffects then
            local requestPoolRebuild = EA and EA["EA_RequestPoolRebuild"]
            local notifyPoolProviderChanged = EA and EA["EA_NotifyPoolProviderChanged"]
            local markPoolNeedsRebuild = EA and EA["EA_MarkPoolNeedsRebuild"]
            if providerAffects then
                EA_BumpProviderRevision("mcm_saved_" .. tostring(id))
                if type(notifyPoolProviderChanged) == "function" then
                    notifyPoolProviderChanged("MCM saved (" .. tostring(id) .. ")", true, false)
                elseif type(requestPoolRebuild) == "function" then
                    requestPoolRebuild("MCM saved (" .. tostring(id) .. ")", true, false)
                elseif type(markPoolNeedsRebuild) == "function" then
                    markPoolNeedsRebuild()
                end
            elseif type(requestPoolRebuild) == "function" then
                requestPoolRebuild("MCM saved (" .. tostring(id) .. ")", true, false)
            else
                if type(markPoolNeedsRebuild) == "function" then
                    markPoolNeedsRebuild()
                end
            end
        end

        if persistedSettingsDirty then
            if EA_Dirty then
                EA_Dirty(true)
            elseif Ext and Ext.Vars and Ext.Vars.DirtyModVariables then
                Ext.Vars.DirtyModVariables(ModuleUUID)
            end
        end

        print(string.format("[EnemyAmbush][MCM] Saved %s = %s", tostring(id), tostring(payload.value)))
    end)
    else
        EA_ReportMissingRequiredMCM("missing_mcm_saved_event")
        print("[EnemyAmbush][MCM] BG3MCM.MCM_Setting_Saved not found; supported live settings sync is unavailable.")
    end
end

-- ========= Shared persisted-setting helpers (server-side) =========

function EA_PersistSyncedSetting(id, value)
    local v = EA_GetPersistedSettingsRoot()
    if not EA_ConfigIsModVarsContainer(v) then
        return false
    end
    -- Retained internal persisted mirror for the supported BG3MCM-driven path.
    -- This supports save continuity/debug inspection, not standalone settings authority.
    if not EA_ConfigIsModVarsContainer(v.MCMSettings) then v.MCMSettings = {} end
    v.MCMSettings[id] = value
    return true
end

-- Custom EA_MCM_SYNC net listener intentionally removed.
-- Server-side MCM authority uses BG3MCM.MCM_Setting_Saved + startup MCM.Get pull.

EA["ApplyMCMSettings"] = ApplyMCMSettings
