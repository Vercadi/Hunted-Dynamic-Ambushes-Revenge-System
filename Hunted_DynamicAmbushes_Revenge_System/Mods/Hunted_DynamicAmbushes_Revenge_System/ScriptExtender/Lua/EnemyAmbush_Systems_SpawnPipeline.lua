EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

-- Module UUID must never be nil (Ext.Vars.GetModVariables requires a string).
-- Hard-fallback to the mod UUID from your blueprint/meta.
local ModuleUUID = EA.ModuleUUID or "96f24297-6ed9-455c-aaa1-ac9c358a8d35"
EA.ModuleUUID = ModuleUUID
local EA_ValidateBuildDeps = EA["EA_ValidateBuildDeps"]
local EA_BuildRuntimeWithDepsShared = EA["EA_BuildRuntimeWithDeps"]
local EA_GetNowMsSafe = EA["EA_GetNowMsSafe"]
local EA_NormalizeUUIDSafe = EA["EA_NormalizeUUIDSafe"]
local EA_ReadSettingRaw = EA["EA_ReadSettingRaw"]
local EA_ReadSettingBool = EA["EA_ReadSettingBool"]
local EA_ReadSettingNumber = EA["EA_ReadSettingNumber"]
local function EA_IsRobustSetting(...)
    local fn = EA and EA["EA_IsRobust"]
    if type(fn) == "function" then
        return fn(...)
    end
    return false
end

local function EA_GetSpawnRetryCount(...)
    local fn = EA and EA["EA_GetSpawnRetryCount"]
    if type(fn) == "function" then
        return fn(...)
    end
    return 1
end

local function PlayVFX_OnEntity(...)
    local fn = EA and EA["PlayVFX_OnEntity"]
    if type(fn) == "function" then
        return fn(...)
    end
end

local function EA_MakeAmbushHostile(...)
    local fn = EA and EA["EA_MakeAmbushHostile"]
    if type(fn) == "function" then
        return fn(...)
    end
end

local function IsDebug(...)
    local fn = EA and EA["IsDebug"]
    if type(fn) == "function" then
        return fn(...)
    end
    return false
end

local function SafeOsiCall(...)
    local fn = EA and EA["SafeOsiCall"]
    if type(fn) == "function" then
        return fn(...)
    end
    return nil
end

local function SafeOsiExec(...)
    local fn = EA and EA["SafeOsiExec"]
    if type(fn) == "function" then
        return fn(...)
    end
    return false
end

local function SafeAddBoosts(...)
    local fn = EA and EA["SafeAddBoosts"]
    if type(fn) == "function" then
        return fn(...)
    end
    return false
end

local function SafeGetPosition(...)
    local fn = EA and EA["SafeGetPosition"]
    if type(fn) == "function" then
        return fn(...)
    end
    return nil, nil, nil
end

local function EA_GetPresetHiddenBalanceKnobs()
    local fn = EA and EA["EA_GetPresetHiddenBalanceKnobs"]
    if type(fn) == "function" then
        local ok, data = pcall(fn)
        if ok and type(data) == "table" then
            return data
        end
    end
    return nil
end

local function EA_NormalizePresetTierBiasKey(value)
    local key = string.upper(tostring(value or "COMMON_VETERAN_BASELINE"))
    if key ~= "COMMON_HEAVY"
        and key ~= "COMMON_VETERAN_BASELINE"
        and key ~= "VETERAN_ELITE_LEANING"
        and key ~= "ELITE_LEGENDARY_LEANING" then
        key = "COMMON_VETERAN_BASELINE"
    end
    return key
end

-- Data dependency lives here (Systems depends on Data)
local EnemyData = Ext.Require("EnemyAmbush_Data.lua")
local SystemsDataTables = Ext.Require("EnemyAmbush_Systems_DataTables.lua")
local RestDefaults = (SystemsDataTables and SystemsDataTables.REST_DEFAULTS) or {}
local TriggerDefaults = (SystemsDataTables and SystemsDataTables.TRIGGER_REST_DEFAULTS) or {}

local CFG = EA.CFG or {}
local ENEMY_DURATION_MIN = tonumber(CFG.ENEMY_DURATION_MIN)
    or tonumber(TriggerDefaults.ENEMY_DURATION_MIN_SECONDS)
    or (5 * 60)
local ENEMY_DURATION_MAX = tonumber(CFG.ENEMY_DURATION_MAX)
    or tonumber(TriggerDefaults.ENEMY_DURATION_MAX_SECONDS)
    or (10 * 60)
local EA_STAGGER_STEP_MS_DEFAULT = tonumber(RestDefaults.STAGGER_STEP_MS_DEFAULT) or 100
local EA_STAGGER_STEP_MS_MIN = tonumber(RestDefaults.STAGGER_STEP_MS_MIN) or 20
local EA_STAGGER_STEP_MS_MAX = tonumber(RestDefaults.STAGGER_STEP_MS_MAX) or 500
EA.CFG = EA.CFG or {}
EA.CFG.SPAWN_STAGGER_ENABLED = (EA.CFG.SPAWN_STAGGER_ENABLED ~= false)
EA.CFG.SPAWN_STAGGER_MS = tonumber(EA.CFG.SPAWN_STAGGER_MS) or EA_STAGGER_STEP_MS_DEFAULT
if EA.CFG.SPAWN_STAGGER_MS < EA_STAGGER_STEP_MS_MIN then EA.CFG.SPAWN_STAGGER_MS = EA_STAGGER_STEP_MS_MIN end
if EA.CFG.SPAWN_STAGGER_MS > EA_STAGGER_STEP_MS_MAX then EA.CFG.SPAWN_STAGGER_MS = EA_STAGGER_STEP_MS_MAX end


EA_ShowFirstAmbushTutorial = (EA and (EA["EA_ShowFirstAmbushTutorial"] or EA.EA_ShowFirstAmbushTutorial)) or function() end

-- Dynamic nil-safe wrappers for bootstrap/load-order resilience.
EA_Pending = function()
    local fn = EA and EA["EA_Pending"]
    if type(fn) == "function" then
        local ok, data = pcall(fn)
        if ok and (type(data) == "table" or type(data) == "userdata") then
            return data
        end
    end
    return nil
end

EA_Spawned = function()
    local fn = EA and EA["EA_Spawned"]
    if type(fn) == "function" then
        local ok, data = pcall(fn)
        if ok and (type(data) == "table" or type(data) == "userdata") then
            return data
        end
    end
    EA._Spawned = EA._Spawned or {}
    return EA._Spawned
end

EA_NormalizeUUID = function(uuid)
    if type(EA_NormalizeUUIDSafe) == "function" then
        return EA_NormalizeUUIDSafe(uuid)
    end
    local fn = EA and EA["EA_NormalizeUUID"]
    if type(fn) == "function" then
        return fn(uuid)
    end
    if type(uuid) == "string" then
        return string.lower(uuid)
    end
    return uuid
end

EA_GetRegionForCharacter = function(character)
    local fn = EA and EA["EA_GetRegionForCharacter"]
    if type(fn) == "function" then
        return fn(character)
    end
    return "", ""
end

EA_IsRegionBlocked = function(region)
    local fn = EA and EA["EA_IsRegionBlocked"]
    if type(fn) == "function" then
        local ok, blocked = pcall(fn, region)
        if ok then
            return blocked == true
        end
    end
    return false
end

EA_IsRawRegionBlocked = function(rawRegion)
    local fn = EA and EA["EA_IsRawRegionBlocked"]
    if type(fn) == "function" then
        local ok, blocked = pcall(fn, rawRegion)
        if ok then
            return blocked == true
        end
    end
    return false
end

EA_GetSafeZoneState = function(character)
    local fn = EA and EA["EA_GetSafeZoneState"]
    if type(fn) == "function" then
        local ok, out = pcall(fn, character)
        if ok and type(out) == "table" then
            return out
        end
    end
    return {
        character = tostring(character or ""),
        activeZones = {},
        activeZoneIds = {},
        triggerBlocked = false,
    }
end

EA_IsCharacterInBlockedSafeZone = function(character)
    local fn = EA and EA["EA_IsCharacterInBlockedSafeZone"]
    if type(fn) == "function" then
        local ok, blocked = pcall(fn, character)
        if ok then
            return blocked == true
        end
    end
    return false
end

EA_LogUnknownRegion = function(rawRegion, context)
    local fn = EA and EA["EA_LogUnknownRegion"]
    if type(fn) == "function" then
        pcall(fn, rawRegion, context)
    end
end

EA_IsRegionCamp = function(region)
    local fn = EA and EA["EA_IsRegionCamp"]
    if type(fn) == "function" then
        local ok, isCamp = pcall(fn, region)
        if ok then
            return isCamp == true
        end
    end
    local key = tostring(region or "")
    return key == "CMP_Main_A" or key:find("Camp", 1, true) ~= nil or key:find("CAMP", 1, true) ~= nil
end

EA_NowMs = function()
    if type(EA_GetNowMsSafe) == "function" then
        return EA_GetNowMsSafe()
    end
    local fn = EA and EA["EA_NowMs"]
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    local persisted = EA and EA["EA_PersistedNowMs"]
    if type(persisted) == "function" then
        local ok, out = pcall(persisted)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    return 0
end

function EA_IsDebugHasteAllAmbushers()
    local dbg = EnemyAmbush and EnemyAmbush.Debug
    return type(dbg) == "table" and dbg.HasteAllAmbushers == true
end

function EA_SetDebugHasteAllAmbushers(enabled)
    EnemyAmbush.Debug = EnemyAmbush.Debug or {}
    EnemyAmbush.Debug.HasteAllAmbushers = (enabled == true)
    return EnemyAmbush.Debug.HasteAllAmbushers
end

function EA_GetChampionDiagnosticsMode()
    EnemyAmbush.Debug = EnemyAmbush.Debug or {}
    local mode = string.lower(tostring(EnemyAmbush.Debug.ChampionDiagnosticsMode or "off"))
    if mode ~= "on" and mode ~= "once" then
        mode = "off"
    end
    return mode
end

function EA_SetChampionDiagnosticsMode(mode)
    EnemyAmbush.Debug = EnemyAmbush.Debug or {}
    local normalized = string.lower(tostring(mode or "off"))
    if normalized ~= "on" and normalized ~= "once" then
        normalized = "off"
    end
    EnemyAmbush.Debug.ChampionDiagnosticsMode = normalized
    return normalized
end

function EA_IsChampionDiagnosticsEnabled()
    local mode = EA_GetChampionDiagnosticsMode()
    return mode == "on" or mode == "once"
end

function EA_ConsumeChampionDiagnosticsOnce()
    if EA_GetChampionDiagnosticsMode() == "once" then
        EA_SetChampionDiagnosticsMode("off")
        return true
    end
    return false
end

function EA_LogChampionDiagnostics(fmt, ...)
    if not EA_IsChampionDiagnosticsEnabled() then
        return
    end
    local ok, msg = pcall(string.format, tostring(fmt or ""), ...)
    if not ok then
        msg = tostring(fmt or "")
    end
    print(string.format("[EnemyAmbush][ChampionDiag] %s", tostring(msg)))
end

function EA_FormatTypeList(types)
    if type(types) ~= "table" or #types == 0 then
        return "(none)"
    end
    local out = {}
    for i = 1, #types do
        out[#out + 1] = tostring(types[i])
    end
    return table.concat(out, ", ")
end

local function GetTableSize(t)
    local fn = EA and EA["GetTableSize"]
    if type(fn) == "function" then
        return fn(t)
    end
    local c = 0
    if type(t) == "table" then
        for _ in pairs(t) do c = c + 1 end
    end
    return c
end

local function EA_BuildRuntimeWithDeps(moduleName, moduleTable, deps, schema)
    if type(EA_BuildRuntimeWithDepsShared) == "function" then
        return EA_BuildRuntimeWithDepsShared(moduleName, moduleTable, deps, schema)
    end
    if type(moduleTable) ~= "table" or type(moduleTable.Build) ~= "function" then
        return nil
    end
    if type(EA_ValidateBuildDeps) == "function" then
        local ok = EA_ValidateBuildDeps(moduleName, deps, schema)
        if ok ~= true then
            return nil
        end
    end
    local buildOk, runtimeOrErr = pcall(moduleTable.Build, deps)
    if not buildOk then
        print(string.format("[EnemyAmbush][Seam] %s Build() failed: %s", tostring(moduleName), tostring(runtimeOrErr)))
        return nil
    end
    return runtimeOrErr
end

local function EA_GetCompositionRootRuntime(runtimeName)
    local modules = EA and EA.SystemsModules or nil
    local composition = modules and modules.CompositionRoot or nil
    local runtimes = composition and composition.runtimeBag or nil
    local runtime = runtimes and runtimes[runtimeName]
    if type(runtime) == "table" then
        return runtime
    end
    return nil
end

local function EA_GetCompositionRootFunction(runtimeName, fnName)
    local runtime = EA_GetCompositionRootRuntime(runtimeName)
    local fn = runtime and runtime[fnName]
    if type(fn) == "function" then
        return fn
    end
    return nil
end

local function EA_CallCompositionRootFunction(runtimeName, fnName, ...)
    local fn = EA_GetCompositionRootFunction(runtimeName, fnName)
    if type(fn) == "function" then
        return fn(...)
    end
    return nil
end

local SystemsPartyPressure = Ext.Require("EnemyAmbush_Systems_PartyPressure.lua")
local PartyPressureFallbackRuntime = nil
if SystemsPartyPressure and type(SystemsPartyPressure.Build) == "function" then
    local ok, runtimeOrErr = pcall(SystemsPartyPressure.Build, {
        EA_PARTY_PRESSURE_MIN_POINTS = 3,
    })
    if ok and type(runtimeOrErr) == "table" then
        PartyPressureFallbackRuntime = runtimeOrErr
    else
        print(string.format("[EnemyAmbush] PartyPressure module unavailable: %s", tostring(runtimeOrErr)))
    end
end

-- ========= POINT SYSTEM TUNABLES =========
EA_BUDGET_MIN = 3
EA_BUDGET_MAX_BASE = 32
EA_BUDGET_LINEAR = 1.30
EA_BUDGET_LATE_START = 9
EA_BUDGET_LATE_MULT = 0.45
EA_BUDGET_PARTY_BASE = 4
EA_BUDGET_PARTY_WEIGHT = 0.35
EA_BUDGET_MAX_FINAL = 40

local BudgetFallbackMCMContract = Ext.Require("EnemyAmbush_MCMContract.lua") or (EA and EA.MCMContract) or {}

EA_GetBalanceProfileKeyForSystems = function()
    local fn = EA_CallCompositionRootFunction("Budget", "EA_GetBalanceProfileKeyForSystems")
    if type(fn) == "string" and fn ~= "" then
        return fn
    end

    local profile = "BG3_12"
    if BudgetFallbackMCMContract and type(BudgetFallbackMCMContract.NormalizeValue) == "function" then
        profile = BudgetFallbackMCMContract.NormalizeValue(
            "MCM_BalanceProfile",
            EA_ReadSettingRaw("MCM_BalanceProfile", "BG3_12") or "BG3_12",
            "BG3_12"
        )
    else
        profile = string.upper(tostring(EA_ReadSettingRaw("MCM_BalanceProfile", "BG3_12") or "BG3_12"))
    end
    if profile == "BG3_12" or profile == "MODDED_20" then
        return profile
    end
    return "BG3_12"
end

EA_GetBudgetFinalCapForProfile = function()
    local fn = EA_GetCompositionRootFunction("Budget", "EA_GetBudgetFinalCapForProfile")
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    if EA_GetBalanceProfileKeyForSystems() == "MODDED_20" then
        return math.max(EA_BUDGET_MAX_FINAL, 48)
    end
    return EA_BUDGET_MAX_FINAL
end

EA_PointBudgetCurve = function(playerLevel)
    local fn = EA_GetCompositionRootFunction("Budget", "EA_PointBudgetCurve")
    if type(fn) == "function" then
        local ok, out = pcall(fn, playerLevel)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    local level = math.max(1, math.min(20, math.floor(tonumber(playerLevel) or 1)))
    local points = EA_BUDGET_MIN + math.floor((level - 1) * EA_BUDGET_LINEAR + 0.5)
    if level >= EA_BUDGET_LATE_START then
        local t = level - (EA_BUDGET_LATE_START - 1)
        points = points + math.floor(t * t * EA_BUDGET_LATE_MULT + 0.5)
    end
    if EA_GetBalanceProfileKeyForSystems() == "MODDED_20" and level > 12 then
        points = points + math.min(8, level - 12)
    end
    local curveCap = EA_BUDGET_MAX_BASE
    if EA_GetBalanceProfileKeyForSystems() == "MODDED_20" then
        curveCap = math.max(curveCap, 40)
    end
    return math.max(EA_BUDGET_MIN, math.min(curveCap, points))
end

EA_ApplyPartyScaling = function(points, partySize)
    local fn = EA_GetCompositionRootFunction("Budget", "EA_ApplyPartyScaling")
    if type(fn) == "function" then
        local ok, out = pcall(fn, points, partySize)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    if PartyPressureFallbackRuntime and type(PartyPressureFallbackRuntime.GetScaledBudgetPoints) == "function" then
        local scaled = PartyPressureFallbackRuntime.GetScaledBudgetPoints(points, partySize)
        return math.max(EA_BUDGET_MIN, math.min(EA_GetBudgetFinalCapForProfile(), tonumber(scaled) or EA_BUDGET_MIN))
    end
    local size = math.max(1, math.min(12, math.floor(tonumber(partySize) or EA_BUDGET_PARTY_BASE)))
    local fallbackDelta = math.max(0, size - EA_BUDGET_PARTY_BASE) * 2
    local scaled = math.floor((tonumber(points) or EA_BUDGET_MIN) + fallbackDelta + 0.5)
    return math.max(EA_BUDGET_MIN, math.min(EA_GetBudgetFinalCapForProfile(), scaled))
end

GetPointBudget = function(playerLevel, player)
    local fn = EA_GetCompositionRootFunction("Budget", "GetPointBudget")
    if type(fn) == "function" then
        local ok, out = pcall(fn, playerLevel, player)
        if ok and tonumber(out) then
            return math.max(1, math.floor(tonumber(out) + 0.5))
        end
    end

    local pointBudget = EA_ReadSettingNumber("MCM_PointBudget", 0) or 0
    if EA_IsAdvancedMode() and type(IsDebug) == "function" and IsDebug() and pointBudget > 0 then
        return math.max(1, math.floor(pointBudget + 0.5))
    end
    local base = EA_PointBudgetCurve(playerLevel)
    local ps = (player and EA_GetEffectiveScaleWithPartySize()) and GetPartySize(player) or 4
    local scaled = EA_ApplyPartyScaling(base, ps)
    if PartyPressureFallbackRuntime and type(PartyPressureFallbackRuntime.GetBudgetPartyBonus) == "function" then
        local hidden = EA_GetPresetHiddenBalanceKnobs() or {}
        local bonus = PartyPressureFallbackRuntime.GetBudgetPartyBonus(playerLevel, ps, hidden)
        scaled = math.max(EA_BUDGET_MIN, math.min(EA_GetBudgetFinalCapForProfile(), (tonumber(scaled) or EA_BUDGET_MIN) + (tonumber(bonus) or 0)))
    end
    return scaled
end

-- Compatibility helper for Osiris FindValidPosition signatures.
-- BG3 commonly expects: FindValidPosition(x, y, z, radius, anchorGuid, checkLine?)
function EA_FindValidPositionCompat(rawX, y, rawZ, radius, anchorGuid)
    local r = tonumber(radius) or 2.0
    if Osi and Osi.FindValidPosition then
        local ok, found, vx, vy, vz = pcall(Osi.FindValidPosition, rawX, y, rawZ, r, anchorGuid, 1)
        if ok and tonumber(found) == 1 and vx ~= nil and vy ~= nil and vz ~= nil then
            return vx, vy, vz, true
        end
    end

    -- Graceful fallback for environments where query is unavailable.
    return rawX, y, rawZ, false
end


-- Random helpers
function EA_RandIntCompat(minVal, maxVal)
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
        local state = tonumber(EA and EA._fallbackRandState) or 1357911
        state = (state * 48271) % 2147483647
        if state <= 0 then state = 1357911 end
        EA._fallbackRandState = state
        return 1 + (state % hi)
    end
    local lo = math.floor(tonumber(minVal) or 1)
    local hi = math.floor(tonumber(maxVal) or lo)
    if hi < lo then lo, hi = hi, lo end
    local span = (hi - lo) + 1
    if span <= 1 then return lo end
    local state = tonumber(EA and EA._fallbackRandState) or 1357911
    state = (state * 48271) % 2147483647
    if state <= 0 then state = 1357911 end
    EA._fallbackRandState = state
    return lo + (state % span)
end

function EA_RandFloatCompat()
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
    local state = tonumber(EA and EA._fallbackRandState) or 1357911
    state = (state * 48271) % 2147483647
    if state <= 0 then state = 1357911 end
    EA._fallbackRandState = state
    return state / 2147483647
end

function RandomSeconds(minS, maxS)
    local lo = tonumber(minS) or 60
    local hi = tonumber(maxS) or lo
    if hi < lo then hi = lo end
    return lo + EA_RandIntCompat(0, math.max(0, hi - lo))
end

-- Level scaling helper:
-- keep ambushers tied to encounter threat while preserving uniquely high-level templates.
function EA_ClampSpawnLevel(level)
    local n = tonumber(level) or 1
    n = math.floor(n + 0.5)
    if n < 1 then n = 1 end
    if n > 20 then n = 20 end
    return n
end

-- Early-game small-party protection:
-- cap spawn level by tier so hidden high-native templates don't one-shot progression.
local function EA_GetEarlySmallPartyLevelCap(partyLevel, partySize, category)
    local pl = EA_ClampSpawnLevel(partyLevel or 1)
    local ps = tonumber(partySize) or 4
    local tier = string.upper(tostring(category or "COMMON"))

    if ps > 2 then return nil end

    -- Level 1-2 safety profile: keep encounters in the level 1-2 band.
    -- This avoids spike templates while preventing impossible downlevel loops
    -- on entries that cannot be pushed below level 2 by engine internals.
    if pl <= 2 then
        if tier == "COMMON" then return 2 end
        if tier == "VETERAN" then return 3 end
        if tier == "ELITE" then return 4 end
        if tier == "LEGENDARY" then return 4 end
        return 3
    end

    if pl <= 3 then
        if tier == "COMMON" then return pl end
        if tier == "VETERAN" then return pl + 1 end
        if tier == "ELITE" then return pl + 2 end
        if tier == "LEGENDARY" then return pl + 2 end
        return pl + 1
    end

    if pl <= 5 then
        if tier == "COMMON" then return pl + 1 end
        if tier == "VETERAN" then return pl + 2 end
        if tier == "ELITE" then return pl + 3 end
        if tier == "LEGENDARY" then return pl + 3 end
        return pl + 2
    end

    return nil
end

local function EA_GetScaledAmbushLevel(enemyMetaLevel, targetLevel, templateLevel, category, partyLevel, partySize)
    local meta = EA_ClampSpawnLevel(enemyMetaLevel or templateLevel or 1)
    local target = EA_ClampSpawnLevel(targetLevel or meta)
    local nativeLevel = EA_ClampSpawnLevel(templateLevel or meta)

    -- Keep some spread so not all templates collapse to the exact same level.
    local spread = 0
    if meta >= 8 then
        spread = 2
    elseif meta >= 6 then
        spread = 1
    elseif meta <= 2 then
        spread = -1
    end

    local desired = target + spread
    if string.upper(tostring(category or "")) == "CHAMPION" then
        desired = desired + 1
    end

    local earlyCap = EA_GetEarlySmallPartyLevelCap(partyLevel or target, partySize, category)
    if earlyCap then
        earlyCap = EA_ClampSpawnLevel(earlyCap)
    end

    -- Normally we do not downlevel unique/native high templates.
    -- Exception: early small-party protection allows controlled downleveling up to cap.
    local preserveNative = true
    if earlyCap and nativeLevel > earlyCap then
        preserveNative = false
        if type(IsDebug) == "function" and IsDebug() then
            DebugPrint(string.format(
                "Early small-party level cap active: native=%d cap=%d tier=%s",
                nativeLevel, earlyCap, tostring(category)
            ))
        end
    end
    if preserveNative then
        desired = math.max(desired, nativeLevel)
    end
    if earlyCap then
        desired = math.min(desired, earlyCap)
    end
    return EA_ClampSpawnLevel(desired)
end

function EA_GetXPRewardCategoryForTier(tier)
    local key = string.upper(tostring(tier or "COMMON"))
    if key == "COMMON" then return "Pack" end
    if key == "VETERAN" then return "Combatant" end
    if key == "ELITE" then return "Elite" end
    if key == "LEGENDARY" then return "Miniboss" end
    if key == "CHAMPION" then return "Boss" end
    return "Combatant"
end

function EA_GetXPRewardCategoryForEntry(entry, tier)
    local tierKey = string.upper(tostring(tier or "COMMON"))
    if tierKey == "CHAMPION" then
        return "Boss", "champion"
    end

    local powerClass = nil
    if type(entry) == "table" then
        powerClass = entry.powerClass
    end

    local powerKey = string.upper(tostring(powerClass or ""))
    if powerKey == "FODDER" then return "Pack", "powerClass" end
    if powerKey == "STANDARD" then return "Combatant", "powerClass" end
    if powerKey == "BRUISER" then return "Combatant", "powerClass" end
    if powerKey == "DREAD" then return "Elite", "powerClass" end
    if powerKey == "APEX" then return "Miniboss", "powerClass" end

    return EA_GetXPRewardCategoryForTier(tierKey), "tier_fallback"
end

-- Native XP suppression for sub-100% ambush XP now uses zero-XP clone templates.
-- The old boost-based suppressor is legacy-only and no longer part of the live spawn path.

local function EA_ApplyNoLootFlags(entity)
    if not entity or entity == "" then return end
    if Osi and Osi.SetCharacterLootable then
        -- Policy: keep corpses interactable, but strip dropped/generated loot.
        SafeOsiExec(Osi.SetCharacterLootable, entity, 1)
    end
    if Osi and Osi.SetIsDroppedOnDeath then
        SafeOsiExec(Osi.SetIsDroppedOnDeath, entity, 0)
    end
    if Osi and Osi.ClearTradeGeneratedItems then
        SafeOsiExec(Osi.ClearTradeGeneratedItems, entity)
    end
end

-- Registry of entities spawned by test commands
EnemyAmbush.TestSpawns = EnemyAmbush.TestSpawns or {}

local function EA_RegisterTestSpawn(entity)
  if entity and entity ~= "" then
    EnemyAmbush.TestSpawns[#EnemyAmbush.TestSpawns + 1] = entity
  end
end

local function EA_CleanupTestSpawns()
  if #EnemyAmbush.TestSpawns == 0 then
    print("[EnemyAmbush] No test spawns to clean up.")
    return
  end
  for _, id in ipairs(EnemyAmbush.TestSpawns) do
    -- Best-effort delete; SafeOsiCall wraps errors if you use it
    if SafeOsiCall then
      SafeOsiCall(Osi.RequestDelete, id)
    else
      Osi.RequestDelete(id)
    end
  end
  EnemyAmbush.TestSpawns = {}
  print("[EnemyAmbush] Cleaned up all test spawns.")
end

-- Safe level getter
function GetSafeLevel(entity)
if not entity or entity == "" then return 1 end
local level = 1
if Osi.GetLevel then
    level = tonumber(Osi.GetLevel(entity)) or 1
end
return math.max(1, math.min(level, 20))
end

local EA_SUMMON_PARTY_WEIGHT = 0.25
local EA_PARTY_CACHE = { key = "", fetchedAt = 0, members = nil, ttlMs = 250 }

local function EA_GetNowForPartyCache()
    return tonumber(EA_NowMs and EA_NowMs()) or 0
end

local function EA_UpdatePartyCache(key, now, members)
    EA_PARTY_CACHE.key = key
    EA_PARTY_CACHE.fetchedAt = now
    EA_PARTY_CACHE.members = members
    return members
end

local function EA_ProbePartyMembers(player)
    local out = {}
    local seen = {}
    local function addMember(member)
        if not member or member == "" then return end
        if seen[member] then return end
        seen[member] = true
        out[#out + 1] = member
    end

    if Osi.DB_PartyMembers then
        local ok, tuples = pcall(function()
            return Osi.DB_PartyMembers:Get(nil)
        end)
        if ok and tuples then
            for _, entry in ipairs(tuples) do
                local member = entry[1]
                if member then
                    local inSameParty = true
                    if Osi.IsInPartyWith then
                        inSameParty = (Osi.IsInPartyWith(player, member) == 1)
                    end
                    if inSameParty then
                        addMember(member)
                    end
                end
            end
        end
    end

    if #out == 0 then
        addMember(player)
    end

    return out
end

local function EA_GetPartyMembersCached(player)
    local key = tostring(player or "")
    local now = EA_GetNowForPartyCache()
    if EA_PARTY_CACHE.key == key and type(EA_PARTY_CACHE.members) == "table" then
        local age = now - (tonumber(EA_PARTY_CACHE.fetchedAt) or 0)
        if now <= 0 or age <= (tonumber(EA_PARTY_CACHE.ttlMs) or 250) then
            -- Avoid carrying an early-load single-member cache too long;
            -- force a fresh probe so budget pre-roll matches runtime party size.
            if #EA_PARTY_CACHE.members > 1 then
                return EA_PARTY_CACHE.members
            end
            if not (Osi and Osi.DB_PartyMembers) then
                return EA_PARTY_CACHE.members
            end
        end
    end

    return EA_UpdatePartyCache(key, now, EA_ProbePartyMembers(player))
end

local function EA_GetPartyMembersForSizing(player)
    local members = EA_GetPartyMembersCached(player)
    local count = #members
    if count <= 1 then
        local bestMembers = members
        local bestCount = count
        for _ = 1, 2 do
            local sample = EA_ProbePartyMembers(player)
            local sampleCount = #sample
            if sampleCount > bestCount then
                bestMembers = sample
                bestCount = sampleCount
            end
        end
        if bestCount > count then
            EA_UpdatePartyCache(tostring(player or ""), EA_GetNowForPartyCache(), bestMembers)
            if type(IsDebug) == "function" and IsDebug() then
                DebugPrint(string.format(
                    "[PartyProbe] upgraded party size sample: player=%s initial=%d final=%d",
                    tostring(player), count, bestCount
                ))
            end
            members = bestMembers
        end
    end
    return members
end

local function EA_IsRealPartyMember(member, anchorPlayer)
    if member and anchorPlayer and member == anchorPlayer then
        return true
    end
    if member and member ~= "" and Osi and Osi.IsPlayer then
        local ok, isPlayer = pcall(Osi.IsPlayer, member)
        if ok and tonumber(isPlayer) == 1 then
            return true
        end
    end
    return false
end

function EA_GetPartyProfile(player)
    local members = EA_GetPartyMembersForSizing(player)
    local rawCount = #members
    local realCount = 0
    local nonPlayerCount = 0

    for i = 1, #members do
        local member = members[i]
        if EA_IsRealPartyMember(member, player) then
            realCount = realCount + 1
        else
            nonPlayerCount = nonPlayerCount + 1
        end
    end

    if realCount <= 0 then
        realCount = 1
    end

    local summonBonus = math.floor((nonPlayerCount * EA_SUMMON_PARTY_WEIGHT) + 0.0001)
    local effectiveSize = math.max(1, math.min(12, realCount + summonBonus))

    return {
        rawPartySize = rawCount,
        effectivePartySize = effectiveSize,
        realPartyMembers = realCount,
        nonPlayerPartyMembers = nonPlayerCount,
        summonFollowerBonus = summonBonus,
        summonFollowerWeight = EA_SUMMON_PARTY_WEIGHT,
    }
end
EA["EA_GetPartyProfile"] = EA_GetPartyProfile

-- Helper: get maximum level among members in the same party as 'player'
local function GetPartyMaxLevel(player)
    local maxLevel = GetSafeLevel(player)
    local members = EA_GetPartyMembersCached(player)
    for i = 1, #members do
        local lvl = GetSafeLevel(members[i])
        if lvl > maxLevel then
            maxLevel = lvl
        end
    end
    return maxLevel
end

-- Get effective party size. Real party members count fully; non-player party
-- entries such as summons/followers contribute one effective member per four.
GetPartySize = function(player)
    local profile = EA_GetPartyProfile(player)
    return tonumber(profile and profile.effectivePartySize) or 1
end

local function EA_GetPartyMembers(player)
    local cached = EA_GetPartyMembersCached(player)
    local out = {}
    for i = 1, #cached do
        out[i] = cached[i]
    end
    return out
end

-- Surprise runtime construction now lives in CompositionRoot.

-- ========= CREATURE REPUTATION SYSTEM =========
EnemyAmbush.CreatureReputation = EnemyAmbush.CreatureReputation or {
 Aberration = 0,
 Beast = 0,
 Celestial = 0,
 Construct = 0,
 Dragon = 0,
 Elemental = 0,
 Fey = 0,
 Fiend = 0,
 Giant = 0,
 Humanoid = 0,
 Monstrosity = 0,
 Ooze = 0,
 Plant = 0,
 Undead = 0
}
local CreatureReputation = EnemyAmbush.CreatureReputation

-- Reputation thresholds
EnemyAmbush.ReputationThresholds = EnemyAmbush.ReputationThresholds or {
 WARY = -5,
 HOSTILE = -10,
 VENGEFUL = -20
}
local REPUTATION_THRESHOLDS = EnemyAmbush.ReputationThresholds

-- ========= REPUTATION: PER-ENCOUNTER CAP =========
local EA_ENCOUNTER_REP_MAX_LOSS = 3 -- canonical max reputation loss per creatureType per combat encounter

local function EA_IsAnyPartyInCombat()
    if not (Osi and Osi.IsInCombat) then return false end

    if Osi.DB_PartyMembers then
        local ok, tuples = pcall(function() return Osi.DB_PartyMembers:Get(nil) end)
        if ok and tuples then
            for _, entry in ipairs(tuples) do
                local member = entry[1]
                if member and Osi.IsPlayer(member) == 1 then
                    if Osi.IsInCombat(member) == 1 then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- ========= CHAMPION SYSTEM =========
-- Legacy static fallback champion table removed by RC policy.
-- Champion providers are authoritative; fallback uses active summon pool only.

-- ========= LOCATION-BASED THEMES =========
local function GetLocationAppropriateEnemies(character)
 local region = EA_GetRegionForCharacter(character)

 -- Define which creature types are appropriate for each region
local regionCreatures = {
    -- Act 1
    ["WLD_Main_A"] = {"Beast", "Plant", "Fey", "Humanoid"},
    ["CRE_Main_A"] = {"Giant", "Dragon", "Elemental", "Construct"},
    ["UND_Main_A"] = {"Aberration", "Ooze", "Monstrosity", "Fey"},
    ["GOB_Main_A"] = {"Humanoid", "Beast", "Monstrosity"},

    -- Act 2
    ["SCL_Main_A"] = {"Undead", "Aberration", "Monstrosity"},
    ["MOO_Main_A"] = {"Humanoid", "Undead", "Fiend", "Aberration"},

    -- Act 3
    ["RIV_Main_A"] = {"Humanoid", "Beast", "Construct"},
    ["WYM_Main_A"] = {"Humanoid", "Construct", "Dragon"},
    ["BGO_Main_A"] = {"Humanoid", "Construct", "Fiend", "Undead"},
    ["BGO_Upper_A"] = {"Humanoid", "Construct", "Celestial", "Fiend"},
    ["BGO_Under_A"] = {"Ooze", "Aberration", "Undead", "Monstrosity"},

    -- Other Planes
    ["CRE_Astral_A"] = {"Aberration", "Dragon", "Construct"},
    ["AVE_Main_A"] = {"Fiend", "Construct"},
    ["SHA_Main_A"] = {"Undead", "Aberration", "Fiend"},

    -- Camp
    ["CMP_Main_A"] = {"Beast", "Humanoid"}
}

return regionCreatures[region] or {"Humanoid", "Beast", "Monstrosity"} -- Default
end

-- Shadow curse detection now reads from the central EA_REGION_POLICY table.
local function EA_IsShadowCursedRegion(region)
    region = tostring(region or "")
    if region == "" then return false end

    -- Resolve through the canonical region system
    local canonical = EA_ResolveRegion(region)
    local policy = EnemyAmbush.REGION_POLICY[canonical]
    if policy and policy.shadowCurse then return true end

    -- Legacy prefix fallback for any sub-regions not yet in the policy table
    if region:find("SCL_", 1, true) == 1 then return true end
    if region:find("MOO_", 1, true) == 1 then return true end

    return false
end

local function EA_ApplyShadowCurseProtection(enemy, player, durationSeconds)
    if not enemy or enemy == "" then return false end

    local region = nil
    if player and player ~= "" then
        region = EA_GetRegionForCharacter(player)
    end
    if (not region or region == "") and enemy and enemy ~= "" then
        region = EA_GetRegionForCharacter(enemy)
    end

    if not EA_IsShadowCursedRegion(region) then
        return false
    end

    if Osi and Osi.HasActiveStatus and Osi.HasActiveStatus(enemy, "SCL_MOONSHIELD") == 1 then
        return true
    end

    local dur = tonumber(durationSeconds) or 600
    if dur <= 0 then
        dur = -1
    end

    local ok = SafeApplyStatus(enemy, "SCL_MOONSHIELD", dur, 1)
    if type(IsDebug) == "function" and IsDebug() then
        DebugPrint("Shadow curse protection:", tostring(enemy), "region=", tostring(region), "applied=", tostring(ok))
    end
    return ok
end

-- Champion breathing room: per creatureType cooldown in long-rest cycles.
-- Set to 0 to disable same-type champion cooldown.
local EA_CHAMPION_TYPE_COOLDOWN_REST_CYCLES = 1
local function EA_ArmGuaranteedChampion(character)
    local fn = EA_GetCompositionRootFunction("ChampionControl", "EA_ArmGuaranteedChampion")
    if type(fn) == "function" then
        return fn(character)
    end
end

-- Called on any ambush tick AFTER safety checks pass: tries to spawn the armed champion
local function EA_TrySpawnArmedChampion(player)
    local fn = EA_GetCompositionRootFunction("ChampionControl", "EA_TrySpawnArmedChampion")
    if type(fn) == "function" then
        return fn(player)
    end
    return false, {
        reason = "module_unavailable",
        context = "armed_queue",
        pathKind = "forced_or_queued",
    }
end

-- ========= ENHANCED LOCATION SYSTEM =========
local REGION_CREATURE_STRENGTH = {
-- ===== ACT 1 =====
-- Wilderness (Beach, Grove, etc)
["WLD_Main_A"] = {
    Beast = 2.0,      -- Lots of wildlife
    Plant = 1.5,      -- Natural area
    Fey = 1.5,        -- Druids and nature magic
    Humanoid = 1.2    -- Goblins, bandits
},

-- Rosymorn Monastery Trail (Mountain Pass)
["CRE_Main_A"] = {
    Giant = 2.5,      -- Githyanki are tall/strong
    Dragon = 2.0,     -- Dragon riders
    Elemental = 1.5,  -- Mountain elements
    Construct = 1.5   -- Ancient defenses
},

-- Underdark
["UND_Main_A"] = {
    Aberration = 2.5,  -- Mind flayers, etc
    Ooze = 2.0,        -- Cave slimes
    Monstrosity = 1.5, -- Hook horrors, etc
    Fey = 1.5,         -- Dark fey/Duergar
    Elemental = 1.2    -- Earth elementals
},

-- Goblin Camp interior
["GOB_Main_A"] = {
    Humanoid = 3.0,    -- Goblins everywhere!
    Beast = 1.5,       -- Worgs, spiders
    Monstrosity = 1.2  -- Their pets
},

-- ===== ACT 2 =====
-- Shadow-Cursed Lands
["SCL_Main_A"] = {
    Undead = 3.5,      -- Shadow curse victims
    Aberration = 2.0,  -- Twisted by curse
    Monstrosity = 1.5, -- Corrupted creatures
    Plant = 0.5        -- Plants struggle here
},

-- Moonrise Towers
["MOO_Main_A"] = {
    Humanoid = 2.0,    -- Cultists
    Undead = 1.5,      -- Necromancy
    Fiend = 1.5,       -- Dark magic
    Aberration = 1.5   -- Tadpole experiments
},

-- ===== ACT 3 =====
-- Rivington
["RIV_Main_A"] = {
    Humanoid = 2.5,    -- Refugees, guards
    Beast = 1.5,       -- Farm animals
    Construct = 1.2    -- City defenses
},

-- Wyrm's Crossing
["WYM_Main_A"] = {
    Humanoid = 2.5,    -- Guards, travelers
    Construct = 2.0,   -- Steel Watch
    Dragon = 1.5       -- Dragon theme
},

-- Lower City
["BGO_Main_A"] = {
    Humanoid = 3.0,    -- Dense population
    Construct = 2.0,   -- Steel Watch
    Fiend = 1.5,       -- Criminal underworld
    Undead = 1.3       -- Murders, graveyards
},

-- Upper City
["BGO_Upper_A"] = {
    Humanoid = 2.5,    -- Nobles, guards
    Construct = 2.5,   -- Heavy security
    Celestial = 1.5,   -- Temple district
    Fiend = 1.5        -- Political corruption
},

-- Sewers/Underground
["BGO_Under_A"] = {
    Ooze = 3.0,        -- Sewer slimes
    Aberration = 2.0,  -- Things in the dark
    Undead = 2.0,      -- Buried secrets
    Monstrosity = 1.5, -- Sewer monsters
    Humanoid = 1.5     -- Thieves guild
},

-- ===== OTHER PLANES =====
-- Astral Plane
["CRE_Astral_A"] = {
    Aberration = 2.5,  -- Githyanki
    Dragon = 2.0,      -- Red dragons
    Construct = 1.5    -- Astral constructs
},

-- House of Hope (Avernus)
["AVE_Main_A"] = {
    Fiend = 4.0,       -- It's literally Hell
    Construct = 1.5,   -- Infernal machines
    Humanoid = 0.5     -- Few mortals here
},

-- Shadowfell/Shar's Domain
["SHA_Main_A"] = {
    Undead = 3.0,      -- Death plane
    Aberration = 2.0,  -- Twisted by shadow
    Fiend = 1.5        -- Dark entities
},

-- Camp (if camp ambushes enabled)
["CMP_Main_A"] = {
    Beast = 0.5,       -- Reduced in camp
    Humanoid = 0.5,    -- Reduced in camp
    -- Most creatures avoid camps
}
}

-- Regional Strength Modifier
local function GetRegionalStrengthModifier(character, creatureType)
-- Validate inputs
if not character or character == "" then
    DebugPrint("GetRegionalStrengthModifier: Invalid character")
    return 1.0
end

if not creatureType or creatureType == "" then
    DebugPrint("GetRegionalStrengthModifier: Invalid creature type")
    return 1.0
end

local region = EA_GetRegionForCharacter(character)
local regionMods = REGION_CREATURE_STRENGTH[region]

if regionMods and regionMods[creatureType] then
    return regionMods[creatureType]
end
return 1.0
end

-- ========= CACHE VARIABLES =========
-- Retained as an internal/debug compatibility mirror. SpawnPipeline owns the
-- top-level shared cache bag shape, while other systems consume injected Cache deps.
EnemyAmbush.Cache = EnemyAmbush.Cache or {
    summonList = nil,
    needsRebuild = true,
    generation = 0,
    providerRevision = -1,
    providerSignalRevision = 0,
    maxSize = 100,
    order = {},
    orderHead = 1,
    weighted = {},
    templateExists = {},
}
local Cache = EnemyAmbush.Cache
local function StorePendingAmbush(timer, ambushData)
    local fn = EA_GetCompositionRootFunction("PersistenceControl", "StorePendingAmbush")
    if type(fn) == "function" then
        return fn(timer, ambushData)
    end
end
-- ========= MCM + JSON config/sync =========
-- Extracted to EnemyAmbush_Config.lua to reduce chunk-local pressure in Systems.
Ext.Require("EnemyAmbush_Config.lua")

-- Metadata category helper for debug tooling.
-- This does not represent runtime dynamic overlevel scaling.
local function EA_GetStaticMetadataCategory(enemyData)
    if type(enemyData) ~= "table" then
        return "COMMON"
    end

    local explicit = string.upper(tostring(enemyData.spawnBand or ""))
    if explicit == "CHAMPION" then
        explicit = "CHAMPION_ONLY"
    end
    if explicit == "COMMON" or explicit == "VETERAN" or explicit == "ELITE" or explicit == "LEGENDARY" or explicit == "CHAMPION_ONLY" then
        return explicit
    end

    local level = tonumber(enemyData.level) or 1
    if level >= 11 then
        return "LEGENDARY"
    elseif level >= 8 then
        return "ELITE"
    elseif level >= 5 then
        return "VETERAN"
    elseif level >= 1 then
        return "COMMON"
    else
        return "MINION"
    end
end

-- Dynamic tiering: tiers are based on overlevel delta vs party, not absolute level
local function EA_GetDynamicCategory(enemyLevel, partyLevel)
    enemyLevel = tonumber(enemyLevel) or 1
    partyLevel = tonumber(partyLevel) or enemyLevel

    if enemyLevel <= 0 then return "MINION" end

    local delta = enemyLevel - partyLevel
    if delta >= 4 then
        return "LEGENDARY"
    elseif delta >= 2 then
        return "ELITE"
    elseif delta >= 1 then
        return "VETERAN"
    else
        return "COMMON"
    end
end

-- Chance-based overleveling curve (tweak these numbers to taste)
-- partySize-aware so very small parties at low levels do not over-roll Veteran spikes.
local function EA_RollOverlevelDelta(partyLevel, partySize)
    local r = EA_RandFloatCompat()
    partyLevel = tonumber(partyLevel) or 1
    partySize = tonumber(partySize) or 4
    local hidden = EA_GetPresetHiddenBalanceKnobs() or {}
    local tierBias = EA_NormalizePresetTierBiasKey(hidden.tierBias)
    local maxVeteran = math.max(0, math.floor((tonumber(hidden.maxVeteran) or 2) + 0.5))
    local maxElite = math.max(0, math.floor((tonumber(hidden.maxElite) or 1) + 0.5))
    local maxLegendary = math.max(0, math.floor((tonumber(hidden.maxLegendary) or 1) + 0.5))
    local delta = 0

    local function rollFromThresholds(t0, t1, t2, t3)
        if r < t0 then return 0 end
        if r < t1 then return 1 end
        if r < t2 then return 2 end
        if t3 ~= nil and r < t3 then return 3 end
        if t3 ~= nil then
            return 4
        end
        return 3
    end

    -- Very low levels: no overlevel spikes.
    if partyLevel <= 3 then
        delta = 0
    elseif partyLevel == 4 then
        if partySize <= 2 then
            delta = 0
        elseif tierBias == "ELITE_LEGENDARY_LEANING" then
            delta = (r < 0.18) and 1 or 0
        elseif tierBias == "VETERAN_ELITE_LEANING" then
            delta = (r < 0.14) and 1 or 0
        elseif tierBias == "COMMON_HEAVY" then
            delta = (r < 0.06) and 1 or 0
        else
            delta = (r < 0.10) and 1 or 0
        end
    elseif partyLevel <= 7 then
        -- Mid game: occasional spikes
        if partySize <= 2 then
            delta = rollFromThresholds(0.72, 0.93, 0.99, nil)
        elseif tierBias == "COMMON_HEAVY" then
            delta = rollFromThresholds(0.72, 0.92, 0.98, nil)
        elseif tierBias == "VETERAN_ELITE_LEANING" then
            delta = rollFromThresholds(0.50, 0.80, 0.95, nil)
        elseif tierBias == "ELITE_LEGENDARY_LEANING" then
            delta = rollFromThresholds(0.42, 0.74, 0.92, nil)
        else
            delta = rollFromThresholds(0.60, 0.86, 0.97, nil)
        end
    elseif partyLevel <= 12 then
        -- Late game: preset bias becomes the main top-tier feel shaper.
        if tierBias == "COMMON_HEAVY" then
            delta = rollFromThresholds(0.66, 0.88, 0.97, 0.995)
        elseif tierBias == "VETERAN_ELITE_LEANING" then
            delta = rollFromThresholds(0.46, 0.76, 0.92, 0.98)
        elseif tierBias == "ELITE_LEGENDARY_LEANING" then
            delta = rollFromThresholds(0.38, 0.68, 0.88, 0.96)
        else
            delta = rollFromThresholds(0.55, 0.82, 0.95, 0.99)
        end
    else
        -- Modded 13-20: preserve late spikes, but still honor preset bias.
        if tierBias == "COMMON_HEAVY" then
            delta = rollFromThresholds(0.48, 0.75, 0.93, 0.99)
        elseif tierBias == "VETERAN_ELITE_LEANING" then
            delta = rollFromThresholds(0.28, 0.56, 0.82, 0.94)
        elseif tierBias == "ELITE_LEGENDARY_LEANING" then
            delta = rollFromThresholds(0.20, 0.48, 0.76, 0.91)
        else
            delta = rollFromThresholds(0.35, 0.65, 0.88, 0.96)
        end
    end

    if delta >= 4 and maxLegendary <= 0 then
        delta = 3
    end
    if delta >= 2 and maxElite <= 0 then
        delta = 1
    end
    if delta >= 1 and maxVeteran <= 0 then
        delta = 0
    end

    if IsDebug() and type(DebugPrint) == "function" then
        DebugPrint(string.format(
            "[TierBias] level=%d party=%d bias=%s hidden[V=%d E=%d L=%d] roll=%.4f delta=%d",
            tonumber(partyLevel) or 1,
            tonumber(partySize) or 1,
            tostring(tierBias),
            maxVeteran,
            maxElite,
            maxLegendary,
            tonumber(r) or 0,
            tonumber(delta) or 0
        ))
    end

    return delta
end

EA_TIER_SPAWN_DISTANCE = (SystemsDataTables and SystemsDataTables.TIER_SPAWN_DISTANCE) or {
    COMMON = 12,
    VETERAN = 12,
    ELITE = 16,
    LEGENDARY = 19,
}

EA_MAX_SPAWN_HEIGHT_DELTA = tonumber(SystemsDataTables and SystemsDataTables.MAX_SPAWN_HEIGHT_DELTA) or 4.0

-- Some story/shell templates are unsafe in generic champion runtime flow.
-- This deny-list is a runtime safety net (not a replacement for data curation):
-- champion rolls must never pick these entries even if data includes them.
EA_BAD_CHAMPION_TEMPLATES = (SystemsDataTables and SystemsDataTables.BAD_CHAMPION_TEMPLATES) or {
    ["44b9e114-b5ab-4d64-bb91-eb9114d2fd3a"] = true, -- Dark Justiciar Giant shell template
    ["80db81be-27d4-42a8-a2b0-4b7fbfd74f01"] = true, -- Skeletal Dragon (Undead variant) broken body rig at runtime
    ["2751f474-424e-4693-85dc-cb5bebbba259"] = true, -- Beholder Tyrant visual/name failure in generic champion flow
}

local function EA_GetTierSpawnDistance(tier)
    local key = string.upper(tostring(tier or "COMMON"))
    return tonumber(EA_TIER_SPAWN_DISTANCE[key]) or EA_TIER_SPAWN_DISTANCE.COMMON
end

local function ApplyDifficultyVisuals(enemy, enemyData, playerLevel)
    -- Legacy danger-aura path removed.
    -- Cosmetic selection now routes through EffectsDB in Immersion/SpawnPlacement.
    return
end

local CurrentAmbushTheme = nil

local function BuildActiveSummonList()
    local fn = EA_GetCompositionRootFunction("PoolSelection", "EA_GetPoolActiveSummonList")
    if type(fn) == "function" then
        return fn()
    end
    return Cache.summonList or {}
end

local function EA_GetPoolActiveSummonList()
    return BuildActiveSummonList()
end

local function GetAmbushThemeForEnemy(enemyData)
    local fn = EA_GetCompositionRootFunction("PoolSelection", "GetAmbushThemeForEnemy")
    if type(fn) == "function" then
        return fn(enemyData)
    end
    if not enemyData then return nil end
    return enemyData.creatureType
end

local function ThemeAllowsEnemy(themeKey, enemyData)
    local fn = EA_GetCompositionRootFunction("PoolSelection", "ThemeAllowsEnemy")
    if type(fn) == "function" then
        return fn(themeKey, enemyData)
    end
    if not themeKey or themeKey == "" then return true end
    local creatureType = enemyData and enemyData.creatureType
    if not creatureType then return false end
    return (creatureType == themeKey) or (string.upper(tostring(creatureType)) == tostring(themeKey))
end

local function ValidateEnemyData(enemyData)
    local fn = EA_GetCompositionRootFunction("PoolSelection", "ValidateEnemyData")
    if type(fn) == "function" then
        return fn(enemyData)
    end
    if not enemyData then return false end
    if not enemyData.template or enemyData.template == "" then return false end
    if not enemyData.name then return false end
    if not enemyData.level or enemyData.level <= 0 or enemyData.level > 20 then return false end
    return true
end

local function PickEnemyTemplate(player, themeKey, spawnTier)
    local fn = EA_GetCompositionRootFunction("PoolSelection", "PickEnemyTemplate")
    if type(fn) == "function" then
        return fn(player, themeKey, spawnTier)
    end

    local list = BuildActiveSummonList() or {}
    if #list == 0 then return nil end

    local filtered = {}
    for _, enemy in ipairs(list) do
        if enemy and enemy.championOnly ~= true and ThemeAllowsEnemy(themeKey, enemy) and ValidateEnemyData(enemy) then
            filtered[#filtered + 1] = enemy
        end
    end
    if #filtered == 0 then
        for _, enemy in ipairs(list) do
            if enemy and enemy.championOnly ~= true and ValidateEnemyData(enemy) then
                filtered[#filtered + 1] = enemy
            end
        end
    end
    if #filtered == 0 then return nil end

    local idx = math.floor((EA_RandFloatCompat() or 0) * #filtered) + 1
    if idx < 1 then idx = 1 end
    if idx > #filtered then idx = #filtered end
    return filtered[idx]
end

local function EA_GetTierFromDelta(delta)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_GetTierFromDelta")
    if type(fn) == "function" then
        return fn(delta)
    end
    delta = tonumber(delta) or 0
    if delta >= 4 then return "LEGENDARY" end
    if delta >= 2 then return "ELITE" end
    if delta >= 1 then return "VETERAN" end
    return "COMMON"
end

local function EA_GetWarningDelayMs(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_GetWarningDelayMs")
    if type(fn) == "function" then
        return fn(...)
    end
    return 1600
end

local function ShowAmbushWarning(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "ShowAmbushWarning")
    if type(fn) == "function" then
        return fn(...)
    end
end

local function EA_ScheduleApproachBeat(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_ScheduleApproachBeat")
    if type(fn) == "function" then
        return fn(...)
    end
end

local function EA_PlayRegionAmbience(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_PlayRegionAmbience")
    if type(fn) == "function" then
        return fn(...)
    end
end

local function EA_PlayPostSpawnBark(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_PlayPostSpawnBark")
    if type(fn) == "function" then
        return fn(...)
    end
end

local function EA_PlayCombatStartVoiceOrSfx(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_PlayCombatStartVoiceOrSfx")
    if type(fn) == "function" then
        return fn(...)
    end
    return false
end

local function EA_GetEscapeProfileByCreatureType(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_GetEscapeProfileByCreatureType")
    if type(fn) == "function" then
        return fn(...)
    end
    return {
        bonus = 0,
        vfx = EnemyData.DEFAULT_DESPAWN_VFX,
        sfx = "VFX_Sound_Spell_Impact_Silent",
        fallbackMode = "misty_step",
    }
end

local function EA_PlaySoundEvent(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_PlaySoundEvent")
    if type(fn) == "function" then
        return fn(...)
    end
end

local function EA_TryVoiceBark(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_TryVoiceBark")
    if type(fn) == "function" then
        return fn(...)
    end
    return false
end

local function EA_SelectEffectProfile(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_SelectEffectProfile")
    if type(fn) == "function" then
        return fn(...)
    end
    return nil
end

local function EA_SelectArrivalCue(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_SelectArrivalCue")
    if type(fn) == "function" then
        return fn(...)
    end
    return nil
end

local function EA_EvaluateArrivalCue(tier, context)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_EvaluateArrivalCue")
    if type(fn) == "function" then
        return fn(tier, context)
    end
    return {
        tier = tostring(tier or ""),
        policy = "BALANCED",
        storedPolicy = "BALANCED",
        chanceScale = 100,
        baseChance = 0,
        scaledChance = 0,
        roll = nil,
        apply = false,
        context = context,
        reason = "no_runtime",
    }
end

local function EA_ShouldApplyArrivalCue(...)
    local fn = EA_GetCompositionRootFunction("Immersion", "EA_ShouldApplyArrivalCue")
    if type(fn) == "function" then
        return fn(...)
    end
    return false
end

-- Spawn placement/runtime implementation moved to EnemyAmbush_Systems_SpawnPlacement.lua
-- TODO-P4: remove legacy globals after compatibility cycle.
local EA_RemoveSpawnedEnemyImmediate
local EA_ScheduleSpawnIntegrityWatch
local EA_SpawnHostileNearPlayer_Prepare
local EA_SpawnHostileNearPlayer_DoCreate
local EA_SpawnHostileNearPlayer_PostConfigure
local SpawnHostileNearPlayer

local function EA_IsCXMode()
    return (EA_ReadSettingBool("MCM_CombatExtenderMode", false))
end

-- Random traits are ALWAYS ON by design (no MCM toggle)
local function EA_UseRandomTraits()
    return true
end

CHAMPION_TYPE_STATUS_BY_TYPE = nil
EA_ApplyTierAndTraits = nil
EA_ApplyChampionPackages = nil
EA_ApplyChampionTelegraph = nil
ApplyChampionBuffs = nil
BoostChampionStats = nil

EA._SystemsTierPackagesModule = Ext.Require("EnemyAmbush_Systems_TierPackages.lua")
EA._TierPackageRuntime = nil
if EA._SystemsTierPackagesModule and type(EA._SystemsTierPackagesModule.Build) == "function" then
    local tierPackageDeps = {
        SystemsDataTables = SystemsDataTables,
        SafeApplyStatus = SafeApplyStatus,
        SafeRemoveStatus = SafeRemoveStatus,
        SafeAddBoosts = SafeAddBoosts,
        EA_RandFloatCompat = EA_RandFloatCompat,
        EA_GetBalanceProfileKeyForSystems = EA_GetBalanceProfileKeyForSystems,
        EA_IsCXMode = EA_IsCXMode,
        EA_UseRandomTraits = EA_UseRandomTraits,
        EA_IsDebugMode = IsDebug,
        EA_IsDebugHasteAllAmbushers = EA_IsDebugHasteAllAmbushers,
        DebugPrint = DebugPrint,
        GetPartyMaxLevel = GetPartyMaxLevel,
        CurrentAmbushTheme = CurrentAmbushTheme,
        GetCurrentAmbushTheme = function() return CurrentAmbushTheme end,
        EA_GetPresetHiddenBalanceKnobs = EA_GetPresetHiddenBalanceKnobs,
    }
    EA._TierPackageRuntime = EA_BuildRuntimeWithDeps("Systems_TierPackages", EA._SystemsTierPackagesModule, tierPackageDeps, {
        SystemsDataTables = "tablelike",
        SafeApplyStatus = "callable",
        SafeRemoveStatus = "callable",
        SafeAddBoosts = "callable",
        DebugPrint = "callable",
        GetPartyMaxLevel = "callable",
    })
end

if type(EA._TierPackageRuntime) == "table" then
    CHAMPION_TYPE_STATUS_BY_TYPE = EA._TierPackageRuntime.CHAMPION_TYPE_STATUS_BY_TYPE or {}
    EA_ApplyTierAndTraits = EA._TierPackageRuntime.EA_ApplyTierAndTraits
    EA_ApplyChampionPackages = EA._TierPackageRuntime.EA_ApplyChampionPackages
    EA_ApplyChampionTelegraph = EA._TierPackageRuntime.EA_ApplyChampionTelegraph
    ApplyChampionBuffs = EA._TierPackageRuntime.ApplyChampionBuffs
    BoostChampionStats = EA._TierPackageRuntime.BoostChampionStats
else
    print("[EnemyAmbush] TierPackages module unavailable; champion/tier package helpers disabled.")
    CHAMPION_TYPE_STATUS_BY_TYPE = CHAMPION_TYPE_STATUS_BY_TYPE or {}
    EA_ApplyTierAndTraits = EA_ApplyTierAndTraits or function() end
    EA_ApplyChampionPackages = EA_ApplyChampionPackages or function() end
    EA_ApplyChampionTelegraph = EA_ApplyChampionTelegraph or function() end
    ApplyChampionBuffs = ApplyChampionBuffs or function() end
    BoostChampionStats = BoostChampionStats or function() end
end

local function SpawnChampionIfNeeded(player, creatureType)
    local fn = EA_GetCompositionRootFunction("ChampionSpawn", "SpawnChampionIfNeeded")
    if type(fn) == "function" then
        return fn(player, creatureType)
    end

    return false, {
        reason = "runtime_missing",
        reputation = CreatureReputation[creatureType] or 0,
        source = "none",
        resolveReason = "runtime_missing",
        providerId = nil,
        policy = "compat",
        champion = nil,
    }
end

local SystemsSpawnPlacement = Ext.Require("EnemyAmbush_Systems_SpawnPlacement.lua")
local SpawnPlacementRuntime = nil
if SystemsSpawnPlacement and type(SystemsSpawnPlacement.Build) == "function" then
    local spawnPlacementDeps = {
        EnemyData = EnemyData,
        UpdateMetric = UpdateMetric,
        EA_GetSettingBool = EA_ReadSettingBool,
        PickEnemyTemplate = PickEnemyTemplate,
        ValidateEnemyData = ValidateEnemyData,
        DebugPrint = DebugPrint,
        SafeGetPosition = SafeGetPosition,
        GetPartyMaxLevel = GetPartyMaxLevel,
        EA_RollOverlevelDelta = EA_RollOverlevelDelta,
        GetPartySize = GetPartySize,
        EA_GetTierFromDelta = EA_GetTierFromDelta,
        EA_GetDynamicCategory = EA_GetDynamicCategory,
        EA_GetTierSpawnDistance = EA_GetTierSpawnDistance,
        EA_IsRobust = EA_IsRobustSetting,
        EA_RecordSpawnSuccess = EA_RecordSpawnSuccess,
        EA_FindValidPositionCompat = EA_FindValidPositionCompat,
        SafeOsiExec = SafeOsiExec,
        HasLineOfSight = HasLineOfSight,
        EA_SetLastError = EA_SetLastError,
        EA_LogEvent = EA_LogEvent,
        EA_RecordSpawnFailure = EA_RecordSpawnFailure,
        SafeOsiCall = SafeOsiCall,
        EA_GetScaledAmbushLevel = EA_GetScaledAmbushLevel,
        ApplyDifficultyVisuals = ApplyDifficultyVisuals,
        EA_EvaluateArrivalCue = EA_EvaluateArrivalCue,
        EA_ShouldApplyArrivalCue = EA_ShouldApplyArrivalCue,
        EA_SelectArrivalCue = EA_SelectArrivalCue,
        EA_PlaySoundEvent = EA_PlaySoundEvent,
        EA_TryVoiceBark = EA_TryVoiceBark,
        EA_GetXPRewardCategoryForTier = EA_GetXPRewardCategoryForTier,
        EA_GetXPRewardCategoryForEntry = EA_GetXPRewardCategoryForEntry,
        EA_CalcKillXP = EA_CalcKillXP,
        EA_GetEffectiveAmbushXPPercent = EA_GetEffectiveAmbushXPPercent,
        SafeAddBoosts = SafeAddBoosts,
        PlayVFX_OnEntity = PlayVFX_OnEntity,
        SafeApplyStatus = SafeApplyStatus,
        EA_ApplyTierAndTraits = EA_ApplyTierAndTraits,
        EA_ApplyShadowCurseProtection = EA_ApplyShadowCurseProtection,
        EA_NormalizeUUID = EA_NormalizeUUID,
        EA_Spawned = EA_Spawned,
        EA_Dirty = EA_Dirty,
        EA_MakeAmbushHostile = EA_MakeAmbushHostile,
        EA_ForceAmbusherFaction = EA["EA_ForceAmbusherFaction"],
        EA_NowMs = EA_NowMs,
        EA_EvictOldSpawned = EA_EvictOldSpawned,
        EA_GetEffectiveDisableAmbushLoot = EA_GetEffectiveDisableAmbushLoot,
        EA_ApplyNoLootFlags = EA_ApplyNoLootFlags,
        EA_DiagRecordEncounterSpawn = EA["EA_DiagRecordEncounterSpawn"],
        EA_DiagRecordCleanup = EA["EA_DiagRecordCleanup"],
        EA_GetPartyMembers = EA_GetPartyMembers,
        GetSafeLevel = GetSafeLevel,
        PerformanceMetrics = PerformanceMetrics,
        CurrentAmbushTheme = CurrentAmbushTheme,
        GetCurrentAmbushTheme = function() return CurrentAmbushTheme end,
        EA_MAX_SPAWN_HEIGHT_DELTA = EA_MAX_SPAWN_HEIGHT_DELTA,
    }
    SpawnPlacementRuntime = EA_BuildRuntimeWithDeps("Systems_SpawnPlacement", SystemsSpawnPlacement, spawnPlacementDeps, {
        EnemyData = "tablelike",
        UpdateMetric = "callable",
        EA_GetSettingBool = "callable",
        ValidateEnemyData = "callable",
        DebugPrint = "callable",
        SafeGetPosition = "callable",
        SafeOsiExec = "callable",
        SafeOsiCall = "callable",
        EA_NowMs = "callable",
        EA_Spawned = "callable",
        EA_Dirty = "callable",
    })
end
if type(SpawnPlacementRuntime) == "table" then
    EA_RemoveSpawnedEnemyImmediate = SpawnPlacementRuntime.EA_RemoveSpawnedEnemyImmediate
    EA_ScheduleSpawnIntegrityWatch = SpawnPlacementRuntime.EA_ScheduleSpawnIntegrityWatch
    EA_SpawnHostileNearPlayer_Prepare = SpawnPlacementRuntime.EA_SpawnHostileNearPlayer_Prepare
    EA_SpawnHostileNearPlayer_DoCreate = SpawnPlacementRuntime.EA_SpawnHostileNearPlayer_DoCreate
    EA_SpawnHostileNearPlayer_PostConfigure = SpawnPlacementRuntime.EA_SpawnHostileNearPlayer_PostConfigure
    SpawnHostileNearPlayer = SpawnPlacementRuntime.SpawnHostileNearPlayer
else
    print("[EnemyAmbush] SpawnPlacement module unavailable; spawn helpers are disabled.")
    EA_RemoveSpawnedEnemyImmediate = EA_RemoveSpawnedEnemyImmediate or function() end
    EA_ScheduleSpawnIntegrityWatch = EA_ScheduleSpawnIntegrityWatch or function() end
    EA_SpawnHostileNearPlayer_Prepare = EA_SpawnHostileNearPlayer_Prepare or function() return nil end
    EA_SpawnHostileNearPlayer_DoCreate = EA_SpawnHostileNearPlayer_DoCreate or function() return nil end
    EA_SpawnHostileNearPlayer_PostConfigure = EA_SpawnHostileNearPlayer_PostConfigure or function() return nil end
    SpawnHostileNearPlayer = SpawnHostileNearPlayer or function() return nil end
end-- ========= SAFETY CHECKS =========
EA_DialogSkipLastLogMs = 0
EA_DialogSkipLogIntervalMs = 10000

function IsSafeToSpawnAmbush(character)
-- Check if character is valid
if not character or character == "" then return false end

local function EA_UpdateCampExitGraceFromSafety(isInCamp)
    local fn = EA_UpdateCampExitAmbushGrace or (EA and EA["EA_UpdateCampExitAmbushGrace"])
    if type(fn) == "function" then
        pcall(fn, character, isInCamp == true, nil, "spawn_safety")
    end
end

local function EA_IsCampExitGraceBlocking()
    local fn = EA_GetCampExitAmbushGraceState or (EA and EA["EA_GetCampExitAmbushGraceState"])
    if type(fn) ~= "function" then
        return false
    end
    local ok, state = pcall(fn, character)
    return ok and type(state) == "table" and state.active == true
end

-- Don't spawn during load / transition: only when the game is in "Running" state
if Osi.IsGameStateRunning then
    local running = Osi.IsGameStateRunning()
    if running ~= 1 then
        print("[EnemyAmbush] Skipping ambush - game state not running (loading/transition)")
        return false
    end
end

-- Skip all checks if safety checks are disabled
if not EA_ReadSettingBool("MCM_SafetyChecks", true) then return true end

-- Check if in combat
if Osi.IsInCombat and Osi.IsInCombat(character) == 1 then
    print("[EnemyAmbush] Skipping ambush - player in combat")
    return false
end

-- Check if trigger/party actors are reserved as speakers (dialog/cutscene)
local dialogueState = { blocked = false }
local dialogueSafetyFn = EA_GetDialogueSafetyState or (EA and EA["EA_GetDialogueSafetyState"])
if type(dialogueSafetyFn) == "function" then
    local okDialogue, state = pcall(dialogueSafetyFn, character)
    if okDialogue and type(state) == "table" then
        dialogueState = state
    end
elseif Osi.IsSpeakerReserved then
    local okReserved, reserved = pcall(Osi.IsSpeakerReserved, character)
    if okReserved and tonumber(reserved) == 1 then
        dialogueState = {
            blocked = true,
            reason = "dialog_or_cutscene",
            actor = tostring(character or ""),
            source = "speaker_reserved",
        }
    end
end
if dialogueState.blocked == true then
    local now = (EA_NowMs and tonumber(EA_NowMs())) or 0
    if (EA_DialogSkipLastLogMs == 0) or (now - EA_DialogSkipLastLogMs >= EA_DialogSkipLogIntervalMs) then
        EA_DialogSkipLastLogMs = now
        print("[EnemyAmbush] Skipping ambush - character in dialog")
    end
    local diagRuntimeBlock = EA_DiagRecordRuntimeBlock or (EA and EA["EA_DiagRecordRuntimeBlock"])
    if type(diagRuntimeBlock) == "function" then
        pcall(diagRuntimeBlock, "dialog_or_cutscene", {
            stage = "spawn_safety",
            character = tostring(character or ""),
            actor = tostring(dialogueState.actor or ""),
            source = tostring(dialogueState.source or ""),
            checkedActors = tonumber(dialogueState.checkedActors) or 0,
        })
    end
    return false
end

-- Check if in camp/safe zone (respect MCM setting)
if not EA_ReadSettingBool("MCM_CampAmbushes", false) then
    -- 1) Primary: DB_InCamp (most accurate Osiris signal for "character is in camp right now")
    if Osi.DB_InCamp then
        local ok, tuples = pcall(function()
            return Osi.DB_InCamp:Get(character)
        end)
        if ok and tuples and #tuples > 0 then
            EA_UpdateCampExitGraceFromSafety(true)
            print("[EnemyAmbush] Skipping ambush - in camp (DB_InCamp)")
            return false
        end
    end

    -- 2) Fallback: DB_PlayerInCamp (secondary signal, some setups expose this)
    if Osi.DB_PlayerInCamp then
        local ok, tuples = pcall(function()
            return Osi.DB_PlayerInCamp:Get(character)
        end)
        if ok and tuples and #tuples > 0 then
            EA_UpdateCampExitGraceFromSafety(true)
            print("[EnemyAmbush] Skipping ambush - in camp (DB_PlayerInCamp)")
            return false
        end
    end

    -- 3) Region-based camp heuristic (uses the canonical resolver)
    local campRegion = EA_GetRegionForCharacter(character)
    local isCampRegion = false
    if type(EA_IsRegionCamp) == "function" then
        isCampRegion = (EA_IsRegionCamp(campRegion) == true)
    end
    if isCampRegion then
        EA_UpdateCampExitGraceFromSafety(true)
        print("[EnemyAmbush] Skipping ambush - in camp (region policy)")
        return false
    end

    EA_UpdateCampExitGraceFromSafety(false)
    if EA_IsCampExitGraceBlocking() then
        return false
    end
end

-- Check if character is dead
if Osi.IsDead and Osi.IsDead(character) == 1 then
    print("[EnemyAmbush] Skipping ambush - player is dead")
    return false
end


-- Check movement capabilities (simplified - removed IsMovementBlocked)
if Osi.CanMove and Osi.CanMove(character) ~= 1 then
    print("[EnemyAmbush] Skipping ambush - character cannot move")
    return false
end

-- Don't spawn during forced turn-based mode (stealth "TB", traps, etc.)
if Osi.IsInForceTurnBasedMode then
    local ftb = Osi.IsInForceTurnBasedMode(character)
    if ftb == 1 then
        print("[EnemyAmbush] Skipping ambush - forced turn-based mode")
        return false
    end
end

-- Region policy checks (blocked regions + setpiece/boss arenas + telemetry)
local canonical, rawRegion = EA_GetRegionForCharacter(character)
local safeZoneState = EA_GetSafeZoneState(character)

if EA_IsCharacterInBlockedSafeZone(character) then
    local active = table.concat(safeZoneState.activeZones or {}, ", ")
    if active == "" then
        active = "trigger_safe_zone"
    end
    local blockReason = tostring(safeZoneState.blockReason or "")
    if blockReason == "" then
        blockReason = "safe_zone_block"
    end
    local diagRuntimeBlock = EA_DiagRecordRuntimeBlock or (EA and EA["EA_DiagRecordRuntimeBlock"])
    if type(diagRuntimeBlock) == "function" then
        pcall(diagRuntimeBlock, blockReason, {
            stage = "spawn_safety",
            character = tostring(character or ""),
            canonical = tostring(canonical or ""),
            raw = tostring(rawRegion or ""),
            active = tostring(active),
        })
    end
    print(string.format("[EnemyAmbush] Skipping ambush - blocked safe zone: %s", tostring(active)))
    return false
end

-- Sublevel denylist: block setpiece/boss/camp/tutorial sublevels by raw region ID
if rawRegion and rawRegion ~= "" and EA_IsRawRegionBlocked(rawRegion) then
    local diagRuntimeBlock = EA_DiagRecordRuntimeBlock or (EA and EA["EA_DiagRecordRuntimeBlock"])
    if type(diagRuntimeBlock) == "function" then
        pcall(diagRuntimeBlock, "raw_safe_zone_block", {
            stage = "spawn_safety",
            character = tostring(character or ""),
            canonical = tostring(canonical or ""),
            raw = tostring(rawRegion or ""),
        })
    end
    print(string.format("[EnemyAmbush] Skipping ambush - blocked sublevel: %s", tostring(rawRegion)))
    return false
end

if canonical ~= "" then
    -- Hard-blocked regions (Astral, Tutorial, Epilogue, Iron Throne, Endgame, etc.)
    if EA_IsRegionBlocked(canonical) then
        local policy = EnemyAmbush.REGION_POLICY[canonical]
        local label = (policy and policy.label) or canonical
        print(string.format("[EnemyAmbush] Skipping ambush - blocked region: %s (%s)", canonical, label))
        return false
    end

    -- Unknown region telemetry (throttled logging for unmapped regions)
    EA_LogUnknownRegion(rawRegion, "safety_check")
end

return true
end

local EA_AMBUSH_COOLDOWN_STAMP_RETRY_DELAY_MS = 500
local EA_AMBUSH_COOLDOWN_STAMP_RETRY_MAX = 30

local function EA_ScheduleAmbushCooldownStampRetry(character, key, reasonLabel)
    EnemyAmbush._eaAmbushCooldownStampRetry = EnemyAmbush._eaAmbushCooldownStampRetry or {}
    local slot = EnemyAmbush._eaAmbushCooldownStampRetry[key]
    if type(slot) ~= "table" then
        slot = {
            tries = 0,
            active = false,
            character = character,
            reason = tostring(reasonLabel or "unknown")
        }
        EnemyAmbush._eaAmbushCooldownStampRetry[key] = slot
    else
        slot.reason = tostring(reasonLabel or slot.reason or "unknown")
    end
    if slot.active or not (Ext and Ext.Timer and Ext.Timer.WaitFor) then
        return false
    end

    slot.active = true
    local function RetryAmbushCooldownStamp()
        slot.tries = (tonumber(slot.tries) or 0) + 1
        local retryReadyFn = EA_ModVarsReady or (EA and EA["EA_ModVarsReady"])
        local retryReady = (type(retryReadyFn) == "function" and retryReadyFn() == true)
        local nowRetry = (type(EA_PersistedNowMs) == "function") and EA_PersistedNowMs() or nil
        local lastByChar = retryReady and EA_LastAmbushTime() or nil
        if retryReady and nowRetry and (type(lastByChar) == "table" or type(lastByChar) == "userdata") then
            lastByChar[key] = nowRetry
            EA_Dirty(true)
            EnemyAmbush._eaAmbushCooldownStampRetry[key] = nil
            return true
        end
        if (tonumber(slot.tries) or 0) >= EA_AMBUSH_COOLDOWN_STAMP_RETRY_MAX then
            slot.active = false
            if type(IsDebug) == "function" and IsDebug() then
                DebugPrint(
                    "Ambush cooldown stamp retry exhausted for",
                    tostring(slot.character or key),
                    "reason=",
                    tostring(slot.reason or "unknown")
                )
            end
            return false
        end
        Ext.Timer.WaitFor(EA_AMBUSH_COOLDOWN_STAMP_RETRY_DELAY_MS, RetryAmbushCooldownStamp)
        return false
    end

    Ext.Timer.WaitFor(EA_AMBUSH_COOLDOWN_STAMP_RETRY_DELAY_MS, RetryAmbushCooldownStamp)
    return true
end

local function EA_StampAmbushCooldownForCharacter(character)
    local key = EA_NormalizeUUID(character) or character
    if not key or key == "" then
        return false
    end

    local readyFn = EA_ModVarsReady or (EA and EA["EA_ModVarsReady"])
    local ready = (type(readyFn) == "function" and readyFn() == true)
    if not ready then
        EA_ScheduleAmbushCooldownStampRetry(character, key, "modvars_not_ready")
        if type(IsDebug) == "function" and IsDebug() then
            DebugPrint("Ambush cooldown stamp skipped: ModVariables not ready for", tostring(character))
        end
        return false
    end

    local now = (type(EA_PersistedNowMs) == "function") and EA_PersistedNowMs() or nil
    if not now then
        EA_ScheduleAmbushCooldownStampRetry(character, key, "persisted_time_unavailable")
        if type(IsDebug) == "function" and IsDebug() then
            DebugPrint("Ambush cooldown stamp skipped: persisted game-time unavailable for", tostring(character))
        end
        return false
    end
    local lastByChar = EA_LastAmbushTime()
    if type(lastByChar) ~= "table" and type(lastByChar) ~= "userdata" then
        if type(IsDebug) == "function" and IsDebug() then
            DebugPrint("Ambush cooldown stamp skipped: LastAmbushTime unavailable for", tostring(character))
        end
        return false
    end
    lastByChar[key] = now
    return true
end

local function EA_StampAmbushCooldownForParty(character)
    local stampedAny = false
    local members = {}
    if type(EA_GetPartyMembers) == "function" and character and character ~= "" then
        local okParty, party = pcall(EA_GetPartyMembers, character)
        if okParty and type(party) == "table" then
            members = party
        end
    end
    if #members == 0 then
        members[1] = character
    end
    for i = 1, #members do
        if EA_StampAmbushCooldownForCharacter(members[i]) then
            stampedAny = true
        end
    end
    return stampedAny
end

local function EA_CompleteAmbushExecution(char, ambushData, spawnedCount)
    local resolvedCount = tonumber(spawnedCount) or 0
    local recSpawn = EA and EA["EA_RecordRestSpawn"]
    if type(recSpawn) == "function" then
        pcall(recSpawn, ambushData and ambushData.isLongRest == true, resolvedCount, char)
    end

    if resolvedCount > 0 then
        local key = EA_NormalizeUUID(char) or char
        local pressureByChar = (type(EA_AmbushPressure) == "function") and EA_AmbushPressure() or nil
        if type(pressureByChar) == "table" or type(pressureByChar) == "userdata" then
            pressureByChar[key] = 0
        end

        if EA_GetCooldownEnabled() then
            EA_StampAmbushCooldownForParty(char)
        end

        EA_Dirty()
        if type(EA_LogRestFlow) == "function" then
            EA_LogRestFlow(
                "spawned",
                "Immediate ambush spawned %d entities for %s (%s)",
                resolvedCount,
                tostring(char),
                ambushData and ambushData.isLongRest and "LongRest" or "ShortRest"
            )
        end
    elseif type(EA_LogRestFlow) == "function" then
        EA_LogRestFlow("spawned", "Immediate ambush executed but spawned 0 entities for %s", tostring(char))
    end
end

-- ========= AMBUSH LOGIC (Trigger/Rest execution split) =========
local SystemsTriggerRestFlow = Ext.Require("EnemyAmbush_Systems_TriggerRestFlow.lua")
local TriggerRestFlowRuntime = nil
if SystemsTriggerRestFlow and type(SystemsTriggerRestFlow.Build) == "function" then
    local triggerRestFlowDeps = {
        EnemyAmbush = EnemyAmbush,
        EA = EA,
        SystemsDataTables = SystemsDataTables,
        ModuleUUID = ModuleUUID,
        EA_ArmGuaranteedChampion = EA_ArmGuaranteedChampion,
        IsSafeToSpawnAmbush = IsSafeToSpawnAmbush,
        EA_ShowFirstAmbushTutorial = EA_ShowFirstAmbushTutorial,
        EA_GetCooldownEnabled = EA_GetCooldownEnabled,
        EA_GetCooldownMinutes = EA_GetCooldownMinutes,
        EA_GetTimeInDangerPressureEnabled = EA_GetTimeInDangerPressureEnabled,
        EA_NormalizeUUID = EA_NormalizeUUID,
        EA_LastAmbushTime = EA_LastAmbushTime,
        EA_PersistedNowMs = EA_PersistedNowMs,
        EA_Dirty = EA_Dirty,
        EA_IsRobust = EA_IsRobustSetting,
        EA_IsModVarsContainer = EA_IsModVarsContainer,
        EA_AmbushPressure = EA_AmbushPressure,
        EA_StampAmbushCooldownForCharacter = EA_StampAmbushCooldownForCharacter,
        EA_StampAmbushCooldownForParty = EA_StampAmbushCooldownForParty,
        EA_GetPartyMembers = EA_GetPartyMembers,
        EA_TrySpawnArmedChampion = EA_TrySpawnArmedChampion,
        EA_IsChampionDiagnosticsEnabled = EA_IsChampionDiagnosticsEnabled,
        EA_LogChampionDiagnostics = EA_LogChampionDiagnostics,
        GetLocationAppropriateEnemies = GetLocationAppropriateEnemies,
        CreatureReputation = CreatureReputation,
        REPUTATION_THRESHOLDS = REPUTATION_THRESHOLDS,
        EA_FormatTypeList = EA_FormatTypeList,
        SpawnChampionIfNeeded = SpawnChampionIfNeeded,
        EA_ConsumeChampionDiagnosticsOnce = EA_ConsumeChampionDiagnosticsOnce,
        EA_GetRestAmbushChance = EA_GetRestAmbushChance,
        EA_GetTimeInDangerAccumulatedMs = EA_GetTimeInDangerAccumulatedMs,
        EA_GetTimeInDangerRiskUnit = EA_GetTimeInDangerRiskUnit,
        EA_ResetTimeInDangerState = EA_ResetTimeInDangerState,
        EA_GetTimeInDangerTravelCheckAtMs = EA_GetTimeInDangerTravelCheckAtMs,
        EA_SetTimeInDangerTravelCheckAtMs = EA_SetTimeInDangerTravelCheckAtMs,
        EA_RandFloatCompat = EA_RandFloatCompat,
        GetSafeLevel = GetSafeLevel,
        GetPointBudget = GetPointBudget,
        RandomSeconds = RandomSeconds,
        ENEMY_DURATION_MIN = ENEMY_DURATION_MIN,
        ENEMY_DURATION_MAX = ENEMY_DURATION_MAX,
        GetPartyMaxLevel = GetPartyMaxLevel,
        GetPartySize = GetPartySize,
        EA_RollOverlevelDelta = EA_RollOverlevelDelta,
        EA_GetTierFromDelta = EA_GetTierFromDelta,
        EA_GetDynamicCategory = EA_GetDynamicCategory,
        EA_IsDebugMode = IsDebug,
        DebugPrint = DebugPrint,
        PickEnemyTemplate = PickEnemyTemplate,
        GetAmbushThemeForEnemy = GetAmbushThemeForEnemy,
        EA_GetTierSpawnDistance = EA_GetTierSpawnDistance,
        EA_GetWarningDelayMs = EA_GetWarningDelayMs,
        ShowAmbushWarning = ShowAmbushWarning,
        EA_NowMs = EA_NowMs,
        StorePendingAmbush = StorePendingAmbush,
        EA_Pending = EA_Pending,
        EA_ScheduleApproachBeat = EA_ScheduleApproachBeat,
    }
    TriggerRestFlowRuntime = EA_BuildRuntimeWithDeps("Systems_TriggerRestFlow", SystemsTriggerRestFlow, triggerRestFlowDeps, {
        EnemyAmbush = "tablelike",
        EA = "tablelike",
        SystemsDataTables = "tablelike",
        ModuleUUID = "string",
        IsSafeToSpawnAmbush = "callable",
        EA_ShowFirstAmbushTutorial = "callable",
        EA_GetCooldownEnabled = "callable",
        EA_PersistedNowMs = { "callable", "nil" },
        EA_Dirty = "callable",
        GetLocationAppropriateEnemies = "callable",
        GetSafeLevel = "callable",
        GetPointBudget = "callable",
        EA_NowMs = "callable",
        StorePendingAmbush = "callable",
        EA_Pending = "callable",
    })
end

local TriggerAmbush = nil
if type(TriggerRestFlowRuntime) == "table" and type(TriggerRestFlowRuntime.TriggerAmbush) == "function" then
    TriggerAmbush = TriggerRestFlowRuntime.TriggerAmbush
else
    print("[EnemyAmbush] TriggerRestFlow module unavailable; TriggerAmbush disabled.")
    TriggerAmbush = function(character)
        if type(IsDebug) == "function" and IsDebug() then
            DebugPrint("[Seam] Trigger/rest runtime unavailable; TriggerAmbush skipped for", tostring(character))
        end
    end
end

EA_TIER_ORDER = { COMMON = 1, VETERAN = 2, ELITE = 3, LEGENDARY = 4, CHAMPION = 5 }
EA_TIER_FROM_INDEX = { "COMMON", "VETERAN", "ELITE", "LEGENDARY", "CHAMPION" }
local SystemsSpawnExecution = Ext.Require("EnemyAmbush_Systems_SpawnExecution.lua")
local SpawnExecutionRuntime = nil
if SystemsSpawnExecution and type(SystemsSpawnExecution.Build) == "function" then
    local spawnExecutionDeps = {
        EnemyAmbush = EnemyAmbush,
        EA = EA,
        EA_GetRegionForCharacter = EA_GetRegionForCharacter,
        EA_GetSafeZoneState = EA_GetSafeZoneState,
        EA_IsCharacterInBlockedSafeZone = EA_IsCharacterInBlockedSafeZone,
        EA_LogUnknownRegion = EA_LogUnknownRegion,
        EA_IsRawRegionBlocked = EA_IsRawRegionBlocked,
        EA_IsRegionBlocked = EA_IsRegionBlocked,
        EA_GetEffectiveAmbushIntensity = EA_GetEffectiveAmbushIntensity,
        EA_IsCXMode = EA_IsCXMode,
        DebugPrint = DebugPrint,
        EA_GetUseCompositionGuards = EA_GetUseCompositionGuards,
        EA_GetSettingBool = EA_ReadSettingBool,
        EA_GetSpawnPlacementMode = EA_GetSpawnPlacementMode,
        EA_GetBalanceProfile = EA_GetBalanceProfile,
        EA_GetBalanceProfileKeyForSystems = EA_GetBalanceProfileKeyForSystems,
        EA_GetPresetHiddenBalanceKnobs = EA_GetPresetHiddenBalanceKnobs,
        EA_GetTargetCountPartyBonus = function(...)
            if PartyPressureFallbackRuntime and type(PartyPressureFallbackRuntime.GetTargetCountPartyBonus) == "function" then
                return PartyPressureFallbackRuntime.GetTargetCountPartyBonus(...)
            end
            return 0, 0
        end,
        EA_GetEntityCapForParty = function(...)
            if PartyPressureFallbackRuntime and type(PartyPressureFallbackRuntime.GetEntityCapForParty) == "function" then
                return PartyPressureFallbackRuntime.GetEntityCapForParty(...)
            end
            local baseCap = tonumber((select(1, ...))) or 6
            return baseCap, baseCap, 0
        end,
        EA_GetSettingRaw = EA_ReadSettingRaw,
        GetPartySize = GetPartySize,
        EA_GetPartyProfile = EA_GetPartyProfile,
        EA_GetPoolActiveSummonList = EA_GetPoolActiveSummonList,
        GetAmbushThemeForEnemy = GetAmbushThemeForEnemy,
        ValidateEnemyData = ValidateEnemyData,
        PickEnemyTemplate = PickEnemyTemplate,
        SpawnHostileNearPlayer = SpawnHostileNearPlayer,
        EA_RecordRecentAmbushType = EA_RecordRecentAmbushType,
        EA_ConsumeTypePressure = EA_ConsumeTypePressure,
        EA_NowMs = EA_NowMs,
        EA_RandIntCompat = EA_RandIntCompat,
        EA_PlayRegionAmbience = EA_PlayRegionAmbience,
        EA_PlayPostSpawnBark = EA_PlayPostSpawnBark,
        EA_DiagBeginEncounter = EA["EA_DiagBeginEncounter"],
        EA_DiagRecordEncounterFailure = EA["EA_DiagRecordEncounterFailure"],
        EA_DiagFinalizeEncounter = EA["EA_DiagFinalizeEncounter"],
        EA_SPAWN_STAGGER_MS = tonumber(EA.CFG and EA.CFG.SPAWN_STAGGER_MS) or EA_STAGGER_STEP_MS_DEFAULT,
    }
    SpawnExecutionRuntime = EA_BuildRuntimeWithDeps("Systems_SpawnExecution", SystemsSpawnExecution, spawnExecutionDeps, {
        EnemyAmbush = "tablelike",
        EA = "tablelike",
        EA_GetRegionForCharacter = "callable",
        EA_GetSafeZoneState = "callable",
        EA_IsCharacterInBlockedSafeZone = "callable",
        EA_GetEffectiveAmbushIntensity = "callable",
        DebugPrint = "callable",
        EA_GetSpawnPlacementMode = "callable",
        EA_GetPresetHiddenBalanceKnobs = "callable",
        EA_GetTargetCountPartyBonus = "callable",
        EA_GetEntityCapForParty = "callable",
        GetPartySize = "callable",
        EA_GetPartyProfile = "callable",
        EA_GetPoolActiveSummonList = "callable",
        ValidateEnemyData = "callable",
        PickEnemyTemplate = "callable",
        SpawnHostileNearPlayer = "callable",
        EA_NowMs = "callable",
        EA_RandIntCompat = "callable",
    })
end
if type(SpawnExecutionRuntime) == "table" then
    EA_TIER_ORDER = SpawnExecutionRuntime.EA_TIER_ORDER or EA_TIER_ORDER
    EA_TIER_FROM_INDEX = SpawnExecutionRuntime.EA_TIER_FROM_INDEX or EA_TIER_FROM_INDEX
    EA_NormalizeTierLabel = SpawnExecutionRuntime.EA_NormalizeTierLabel
    EA_DowngradeTier = SpawnExecutionRuntime.EA_DowngradeTier
    EA_CopyRollWithTier = SpawnExecutionRuntime.EA_CopyRollWithTier
    EA_GetMinAmbushTemplateCostForPartyLevel = SpawnExecutionRuntime.EA_GetMinAmbushTemplateCostForPartyLevel
    EA_GetEffectiveAmbushTemplateCost = SpawnExecutionRuntime.EA_GetEffectiveAmbushTemplateCost
    ExecuteAmbushSpawn = SpawnExecutionRuntime.ExecuteAmbushSpawn
else
    print("[EnemyAmbush] SpawnExecution module unavailable; ExecuteAmbushSpawn disabled.")
    EA_NormalizeTierLabel = EA_NormalizeTierLabel or function(tier)
        local key = string.upper(tostring(tier or "COMMON"))
        if not EA_TIER_ORDER[key] then return "COMMON" end
        return key
    end
    EA_DowngradeTier = EA_DowngradeTier or function(tier, steps)
        local idx = EA_TIER_ORDER[EA_NormalizeTierLabel(tier)] or 1
        local target = math.max(1, idx - (tonumber(steps) or 1))
        return EA_TIER_FROM_INDEX[target] or "COMMON"
    end
    EA_CopyRollWithTier = EA_CopyRollWithTier or function(baseRoll, tier, roleTag)
        local out = {}
        if type(baseRoll) == "table" then
            for k, v in pairs(baseRoll) do out[k] = v end
        end
        out.tier = EA_NormalizeTierLabel(tier)
        out.category = out.tier
        if roleTag then out.spawnRole = roleTag end
        return out
    end
    EA_GetMinAmbushTemplateCostForPartyLevel = EA_GetMinAmbushTemplateCostForPartyLevel or function() return 1 end
    EA_GetEffectiveAmbushTemplateCost = EA_GetEffectiveAmbushTemplateCost or function(enemyData)
        local raw = tonumber(enemyData and enemyData.level) or 1
        raw = math.max(1, math.floor(raw + 0.5))
        return raw, raw, 1
    end
    ExecuteAmbushSpawn = ExecuteAmbushSpawn or function() return 0 end
end
-- ========= COMPOSITION INPUTS (SpawnPipeline -> CompositionRoot) =========
local spawnPipelineExportMap = {}

local spawnPipelineSupportBag = {
    EnemyData = EnemyData,
    SystemsDataTables = SystemsDataTables,
    Cache = Cache,
    CreatureReputation = CreatureReputation,
    REPUTATION_THRESHOLDS = REPUTATION_THRESHOLDS,
    ModuleUUID = ModuleUUID,
    GetSafeLevel = GetSafeLevel,
    GetPartySize = GetPartySize,
    EA_GetPartyProfile = EA_GetPartyProfile,
    EA_GetPartyMembers = EA_GetPartyMembers,
    GetPartyMaxLevel = GetPartyMaxLevel,
    EA_IsAnyPartyInCombat = EA_IsAnyPartyInCombat,
    EA_GetLocationAppropriateEnemies = GetLocationAppropriateEnemies,
    EA_GetStaticMetadataCategory = EA_GetStaticMetadataCategory,
    GetEnemyCategory = EA_GetStaticMetadataCategory,
    RandomSeconds = RandomSeconds,
    EA_RollOverlevelDelta = EA_RollOverlevelDelta,
    IsSafeToSpawnAmbush = IsSafeToSpawnAmbush,
    EA_RegisterTestSpawn = EA_RegisterTestSpawn,
    EA_ENCOUNTER_REP_MAX_LOSS = EA_ENCOUNTER_REP_MAX_LOSS,
    EA_GetDynamicCategory = EA_GetDynamicCategory,
    EA_GetTierSpawnDistance = EA_GetTierSpawnDistance,
    EA_GetScaledAmbushLevel = EA_GetScaledAmbushLevel,
    EA_ApplyShadowCurseProtection = EA_ApplyShadowCurseProtection,
    EA_ApplyNoLootFlags = EA_ApplyNoLootFlags,
    GetRegionalStrengthModifier = GetRegionalStrengthModifier,
    EA_GetChampionDiagnosticsMode = EA_GetChampionDiagnosticsMode,
    EA_SetChampionDiagnosticsMode = EA_SetChampionDiagnosticsMode,
    EA_IsChampionDiagnosticsEnabled = EA_IsChampionDiagnosticsEnabled,
    EA_ConsumeChampionDiagnosticsOnce = EA_ConsumeChampionDiagnosticsOnce,
    EA_LogChampionDiagnostics = EA_LogChampionDiagnostics,
    EA_FormatTypeList = EA_FormatTypeList,
    EA_SetDebugHasteAllAmbushers = EA_SetDebugHasteAllAmbushers,
    EA_IsDebugHasteAllAmbushers = EA_IsDebugHasteAllAmbushers,
    EA_CHAMPION_TYPE_COOLDOWN_REST_CYCLES = EA_CHAMPION_TYPE_COOLDOWN_REST_CYCLES,
}

EA.SystemsModules = EA.SystemsModules or {}
EA.SystemsModules.CompositionInputs = EA.SystemsModules.CompositionInputs or {}
EA.SystemsModules.CompositionInputs.SpawnPipeline = {
    source = "EnemyAmbush_Systems_SpawnPipeline.lua",
    exportMap = spawnPipelineExportMap,
    supportBag = spawnPipelineSupportBag,
    startupDeps = {
        CheckVersion = CheckVersion,
        EA_SanitizePersistedTimes = EA_SanitizePersistedTimes,
        EA_Spawned = EA_Spawned,
        EA_Dirty = EA_Dirty,
        EA_EvictOldSpawned = EA_EvictOldSpawned,
        EA_MarkSessionLoadedForCleanup = EA_MarkSessionLoadedForCleanup,
        EA_AggressiveSpawnedCleanup = EA_AggressiveSpawnedCleanup,
        EA_InitPressureDecayState = EA_InitPressureDecayState,
        EA_StartPressureDecayLoop = EA_StartPressureDecayLoop,
        EA_ResetStatusExistenceCache = EA and EA["EA_ResetStatusExistenceCache"] or nil,
        ApplyMCMSettings = ApplyMCMSettings,
        IsDebug = IsDebug,
        DebugPrint = DebugPrint,
        EA_NowMs = EA_NowMs,
        EA_NormalizeUUID = EA_NormalizeUUID,
    },
    runtimeBag = {
        SpawnPlacement = SpawnPlacementRuntime,
        TriggerRestFlow = TriggerRestFlowRuntime,
        SpawnExecution = SpawnExecutionRuntime,
    },
}


