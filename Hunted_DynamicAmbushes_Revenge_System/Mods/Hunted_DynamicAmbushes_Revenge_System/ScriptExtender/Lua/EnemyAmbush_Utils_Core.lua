-- EnemyAmbush_Utils_Core.lua
-- Extracted from monolithic EnemyAmbush_Utils.lua for local-budget stability.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local ModuleUUID = EA.ModuleUUID or "96f24297-6ed9-455c-aaa1-ac9c358a8d35"
EA.ModuleUUID = ModuleUUID
local MCMContract = Ext.Require("EnemyAmbush_MCMContract.lua") or (EA and EA.MCMContract) or {}
local function EA_P0Inc(...)
    local fn = EA and EA["EA_P0Inc"]
    if type(fn) == "function" then
        return fn(...)
    end
    return 0
end
local function EA_P0Set(...)
    local fn = EA and EA["EA_P0Set"]
    if type(fn) == "function" then
        return fn(...)
    end
    return nil
end

-- ========= VERSION CHECKING =========
local MOD_VERSION = "1.0.1"

function EA_ParseVersionTuple(versionString)
    local a, b, c = tostring(versionString or "0.0.0"):match("^(%d+)%.(%d+)%.(%d+)$")
    return tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0
end

function EA_IsVersionLess(lhs, rhs)
    local la, lb, lc = EA_ParseVersionTuple(lhs)
    local ra, rb, rc = EA_ParseVersionTuple(rhs)
    if la ~= ra then return la < ra end
    if lb ~= rb then return lb < rb end
    return lc < rc
end

local function EA_RunReputationMigrationReset()
    if EA and type(EA["EA_ResetReputationForMigration"]) == "function" then
        local ok, didReset = pcall(EA["EA_ResetReputationForMigration"])
        if ok then
            return didReset == true
        end
    end
    return false
end

local function EA_DepMatchesType(value, expected)
    if expected == nil or expected == "any" then
        return value ~= nil
    end
    if expected == "callable" then
        return type(value) == "function"
    end
    if expected == "tablelike" then
        local t = type(value)
        return t == "table" or t == "userdata"
    end
    if type(expected) == "string" then
        return type(value) == expected
    end
    if type(expected) == "table" then
        for _, candidate in ipairs(expected) do
            if EA_DepMatchesType(value, candidate) then
                return true
            end
        end
        return false
    end
    return value ~= nil
end

local function EA_ValidateBuildDeps(moduleName, deps, schema)
    moduleName = tostring(moduleName or "unknown_module")
    if type(deps) ~= "table" then
        print(string.format("[EnemyAmbush][Seam] %s Build deps invalid: expected table, got %s", moduleName, type(deps)))
        return false, { "<deps_table>" }
    end
    if type(schema) ~= "table" then
        return true, {}
    end

    local missing = {}
    for key, expectedType in pairs(schema) do
        local value = deps[key]
        if not EA_DepMatchesType(value, expectedType) then
            local expectedLabel = type(expectedType) == "table" and table.concat(expectedType, "|") or tostring(expectedType or "any")
            missing[#missing + 1] = string.format("%s:%s", tostring(key), expectedLabel)
        end
    end
    table.sort(missing)

    if #missing > 0 then
        print(string.format("[EnemyAmbush][Seam] %s Build deps missing/incompatible: %s", moduleName, table.concat(missing, ", ")))
        return false, missing
    end
    return true, {}
end

EA["EA_ValidateBuildDeps"] = EA_ValidateBuildDeps

-- Centralized runtime builder for split modules.
local function EA_BuildRuntimeWithDeps(moduleName, moduleTable, deps, schema)
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

-- Shared safe accessors to avoid duplicated fallback logic in split files.
local function EA_GetNowMsSafe()
    local nowFn = EA and EA["EA_NowMs"]
    if type(nowFn) == "function" then
        local ok, out = pcall(nowFn)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    local persistedFn = EA and EA["EA_PersistedNowMs"]
    if type(persistedFn) == "function" then
        local ok, out = pcall(persistedFn)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    return 0
end

local function EA_GetPersistedNowMsSafe()
    local persistedFn = EA and EA["EA_PersistedNowMs"]
    if type(persistedFn) == "function" then
        local ok, out = pcall(persistedFn)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    return EA_GetNowMsSafe()
end

local function EA_NormalizeUUIDSafe(uuid)
    local normalizeFn = EA and EA["EA_NormalizeUUID"]
    if type(normalizeFn) == "function" then
        local ok, value = pcall(normalizeFn, uuid)
        if ok then
            return value
        end
    end
    if type(uuid) == "string" then
        return string.lower(uuid)
    end
    return uuid
end

-- Canonical RNG-safe wrappers. Prefer EA RNG module and only fall back to
-- deterministic local LCG if RNG facade is temporarily unavailable.
local RNG_SAFE_MOD = 2147483647
local RNG_SAFE_A = 48271
local RNG_SAFE_DEFAULT_SEED = 24681357

local function EA_EnsureRngFacadeLoaded()
    if type(EA["EA_RandInt"]) == "function" and type(EA["EA_RandFloat"]) == "function" then
        return
    end
    if Ext and type(Ext.Require) == "function" then
        pcall(Ext.Require, "EnemyAmbush_RNG.lua")
    end
end

local function EA_NextFallbackRandomRaw()
    local state = tonumber(EA._rngFallbackState)
    if not state or state <= 0 then
        local seed = 0
        if Ext and Ext.Utils and type(Ext.Utils.MonotonicTime) == "function" then
            local okMono, mono = pcall(Ext.Utils.MonotonicTime)
            if okMono and tonumber(mono) then
                seed = math.floor(tonumber(mono))
            end
        end
        if seed <= 0 and os and type(os.time) == "function" then
            local okWall, wall = pcall(os.time)
            if okWall and tonumber(wall) then
                seed = math.floor(tonumber(wall) * 1000)
            end
        end
        state = seed % RNG_SAFE_MOD
        if state <= 0 then
            state = RNG_SAFE_DEFAULT_SEED
        end
    end
    state = (state * RNG_SAFE_A) % RNG_SAFE_MOD
    if state <= 0 then
        state = RNG_SAFE_DEFAULT_SEED
    end
    EA._rngFallbackState = state
    return state
end

local function EA_RandIntSafe(minVal, maxVal)
    EA_EnsureRngFacadeLoaded()
    local randInt = EA and EA["EA_RandInt"]
    if type(randInt) == "function" then
        local ok, out = pcall(randInt, minVal, maxVal)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end

    local lo = tonumber(minVal)
    local hi = tonumber(maxVal)
    if lo == nil and hi == nil then
        return EA_NextFallbackRandomRaw()
    end
    if hi == nil then
        hi = math.floor(lo or 1)
        lo = 1
    else
        lo = math.floor(lo or 1)
        hi = math.floor(hi or lo)
    end
    if hi < lo then
        lo, hi = hi, lo
    end
    local span = (hi - lo) + 1
    if span <= 1 then
        return lo
    end
    return lo + (EA_NextFallbackRandomRaw() % span)
end

local function EA_RandFloatSafe()
    EA_EnsureRngFacadeLoaded()
    local randFloat = EA and EA["EA_RandFloat"]
    if type(randFloat) == "function" then
        local ok, out = pcall(randFloat)
        if ok and tonumber(out) then
            return tonumber(out)
        end
    end
    return EA_NextFallbackRandomRaw() / RNG_SAFE_MOD
end

-- Canonical bool coercion path used across server modules.
local function EA_ToBoolSafe(v)
    local toBool = EA and EA["EA_ToBool"]
    if type(toBool) == "function" then
        local ok, out = pcall(toBool, v)
        if ok then
            return out == true
        end
    end
    if MCMContract and type(MCMContract.ToBool) == "function" then
        return MCMContract.ToBool(v)
    end
    return v == true
end

EA["EA_BuildRuntimeWithDeps"] = EA_BuildRuntimeWithDeps
EA["EA_GetNowMsSafe"] = EA_GetNowMsSafe
EA["EA_GetPersistedNowMsSafe"] = EA_GetPersistedNowMsSafe
EA["EA_NormalizeUUIDSafe"] = EA_NormalizeUUIDSafe
EA["EA_RandIntSafe"] = EA_RandIntSafe
EA["EA_RandFloatSafe"] = EA_RandFloatSafe
EA["EA_ToBoolSafe"] = EA_ToBoolSafe

function CheckVersion()
 local vars = (type(EA_Vars) == "function") and EA_Vars() or nil
 local savedVersion = nil
 if ((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(vars)) or type(vars) == "table") then
     savedVersion = tostring(vars.EA_ModVersion or "")
     if savedVersion == "" then
         savedVersion = nil
     end
 end

 -- One-time compatibility read from legacy unnamespaced character VarString.
 if not savedVersion and Osi and Osi.GetHostCharacter and Osi.GetVarString then
     local host = Osi.GetHostCharacter()
     if host and host ~= "" then
         local legacy = Osi.GetVarString(host, "EA_Version")
         if legacy and legacy ~= "" then
             savedVersion = tostring(legacy)
         end
     end
 end

 if savedVersion ~= MOD_VERSION then
     print(string.format("[EnemyAmbush] Version update detected: %s -> %s",
         savedVersion or "none", MOD_VERSION))

     -- Example migration: Reset reputation if updating from pre-1.0
     if not savedVersion or EA_IsVersionLess(savedVersion, "1.0.0") then
         local migrated = EA_RunReputationMigrationReset()
         if migrated then
             print("[EnemyAmbush] Migration: Reset all reputations for v1.0.0")
         else
             print("[EnemyAmbush] Migration note: reputation reset callback unavailable; skipping reset.")
         end
     end

     if ((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(vars)) or type(vars) == "table") then
         vars.EA_ModVersion = MOD_VERSION
         if type(EA_Dirty) == "function" then
             EA_Dirty()
         end
     end
 end
end

-- ========= SAFE OSIRIS WRAPPER =========
local function EA_RobustEnabled()
    local robustFn = EA and EA["EA_IsRobust"]
    if type(robustFn) == "function" then
        local ok, out = pcall(robustFn)
        if ok then return out == true end
    end
    if EA and type(EA["EA_GetSettingFromSnapshot"]) == "function" then
        local ok, out = pcall(EA["EA_GetSettingFromSnapshot"], "MCM_RobustMode", false)
        if ok then
            return out == true
        end
    end
    return false
end

local function EA_RobustLogArgsEnabled()
    if type(EA_GetRobustLogArgs) == "function" then
        local ok, out = pcall(EA_GetRobustLogArgs)
        if ok then return out == true end
    end
    if EA and type(EA["EA_GetRobustLogArgs"]) == "function" then
        local ok, out = pcall(EA["EA_GetRobustLogArgs"])
        if ok then return out == true end
    end
    return false
end

local function SafeOsiCall(func, ...)
    if not func then return nil end

    -- best effort name
    local fname = "<unknown>"
    if type(func) == "function" and debug and debug.getinfo then
        local info = debug.getinfo(func, "n")
        if info and info.name and info.name ~= "" then fname = info.name end
    end

    local ok, a, b, c, d, e = pcall(func, ...)
    if not ok then
        if EA_RobustEnabled() then
            if EA_RobustLogArgsEnabled() then
                print(string.format("[EnemyAmbush][ROBUST] Osiris call failed: %s | err=%s | args=%s",
                    tostring(fname), tostring(a), Ext.Json.Stringify({...})
                ))
            else
                print(string.format("[EnemyAmbush][ROBUST] Osiris call failed: %s | err=%s", tostring(fname), tostring(a)))
            end
        else
            print("[EnemyAmbush] Osiris call failed:", a)
        end
        return nil
    end

    -- return first result (and keep compatibility with your current usage)
    return a, b, c, d, e
end

local SafeOsiExec

local function SafeAddPassive(entity, passiveId)
    if not entity or entity == "" or not passiveId or passiveId == "" then
        return false
    end
    if not Osi or not Osi.AddPassive then
        DebugPrint("SafeAddPassive: Osi.AddPassive missing")
        return false
    end
    return SafeOsiExec(Osi.AddPassive, entity, passiveId)
end

-- Use this when you only care if the call succeeded (pcall ok),
-- NOT what Osiris returned.
SafeOsiExec = function(func, ...)
    if not func then return false end
    local ok, err = pcall(func, ...)
    if not ok then
        if EA_RobustEnabled() then
            if EA_RobustLogArgsEnabled() then
                print(string.format("[EnemyAmbush][ROBUST] Osiris exec failed | err=%s | args=%s",
                    tostring(err), Ext.Json.Stringify({...})
                ))
            else
                print(string.format("[EnemyAmbush][ROBUST] Osiris exec failed | err=%s", tostring(err)))
            end
        else
            print("[EnemyAmbush] Osiris exec failed:", err)
        end
        return false
    end
    return true
end

-- ========= SAFE BOOST WRAPPER (SCRIPT EXTENDER / STORY BOOSTS) =========
local function SafeAddBoosts(target, boosts)
    if not (Osi and Osi.AddBoosts) then return false end

    -- Some setups use 4 args, some list 5; try both safely.
    if SafeOsiExec(Osi.AddBoosts, target, boosts, "", "") then return true end
    if SafeOsiExec(Osi.AddBoosts, target, boosts, "", target) then return true end

    return false
end

local function EA_TryIndex(obj, key)
    if obj == nil then
        return nil
    end
    local ok, value = pcall(function()
        return obj[key]
    end)
    if ok then
        return value
    end
    return nil
end

local function EA_CoercePositionTriple(x, y, z)
    local nx = tonumber(x)
    local ny = tonumber(y)
    local nz = tonumber(z)
    if nx and ny and nz then
        return nx, ny, nz
    end
    return nil, nil, nil
end

local function EA_ReadVec3(value)
    if value == nil then
        return nil, nil, nil
    end

    return EA_CoercePositionTriple(
        EA_TryIndex(value, "x") or EA_TryIndex(value, "X") or EA_TryIndex(value, 1),
        EA_TryIndex(value, "y") or EA_TryIndex(value, "Y") or EA_TryIndex(value, 2),
        EA_TryIndex(value, "z") or EA_TryIndex(value, "Z") or EA_TryIndex(value, 3)
    )
end

-- Helper to safely get position
local function SafeGetPosition(entity)
if not entity or entity == "" then return nil, nil, nil end

if Osi and type(Osi.GetPosition) == "function" then
    local success, x, y, z = pcall(Osi.GetPosition, entity)
    if success then
        local nx, ny, nz = EA_CoercePositionTriple(x, y, z)
        if nx and ny and nz then
            return nx, ny, nz
        end
    end
end

if Ext and Ext.Entity and type(Ext.Entity.Get) == "function" then
    local okEnt, ent = pcall(Ext.Entity.Get, entity)
    if okEnt and ent then
        local transformComponent = EA_TryIndex(ent, "Transform")
        local transform = transformComponent and EA_TryIndex(transformComponent, "Transform")
        local tx, ty, tz = EA_ReadVec3(transform and EA_TryIndex(transform, "Translate"))
        if tx and ty and tz then
            return tx, ty, tz
        end

        local boundComponent = EA_TryIndex(ent, "Bound")
        local bound = boundComponent and EA_TryIndex(boundComponent, "Bound")
        local bx, by, bz = EA_ReadVec3(bound and EA_TryIndex(bound, "Translate"))
        if bx and by and bz then
            return bx, by, bz
        end

        local stealth = EA_TryIndex(ent, "Stealth")
        local sx, sy, sz = EA_ReadVec3(stealth and EA_TryIndex(stealth, "Position"))
        if sx and sy and sz then
            return sx, sy, sz
        end
    end
end

return nil, nil, nil
end

-- Table size helper (Lua doesn't have built-in table.size)
local function GetTableSize(t)
local count = 0
for _ in pairs(t) do count = count + 1 end
return count
end

EA["SafeOsiCall"] = SafeOsiCall
EA["SafeOsiExec"] = SafeOsiExec
EA["SafeAddBoosts"] = SafeAddBoosts
EA["SafeGetPosition"] = SafeGetPosition
EA["GetTableSize"] = GetTableSize

local function EA_LocaHandleNoVersion(rawText)
    if type(rawText) ~= "string" then return nil end
    local s = rawText:match("^%s*(.-)%s*$")
    if not s or s == "" then return nil end
    local bare = s:match("^(h[%w]+);%d+$")
    if bare then return bare end
    bare = s:match("^(h[%w]+)$")
    if bare then return bare end
    return nil
end

function EA_ResolveLocaText(rawText)
    local text = tostring(rawText or "")
    if text == "" then
        return ""
    end

    local probes, seen = {}, {}
    local function addProbe(v)
        if not v or v == "" then return end
        if seen[v] then return end
        seen[v] = true
        probes[#probes + 1] = v
    end

    local bare = EA_LocaHandleNoVersion(text)
    if bare then addProbe(bare) end
    addProbe(text)
    if bare then addProbe(bare .. ";1") end

    for _, probe in ipairs(probes) do
        if Osi and Osi.ResolveTranslatedString then
            local ok, translated = pcall(Osi.ResolveTranslatedString, probe)
            if ok and type(translated) == "string" and translated ~= "" and translated ~= probe and translated ~= text then
                return translated
            end
        end
        if Ext and Ext.Loca and Ext.Loca.GetTranslatedString then
            local ok, translated = pcall(Ext.Loca.GetTranslatedString, probe)
            if ok and type(translated) == "string" and translated ~= "" and translated ~= probe and translated ~= text then
                return translated
            end
        end
    end

    return text
end



-- ========= BATCH STATUS HELPER =========
local function ApplyMultipleStatuses(entity, statuses, duration, force)
    if not entity or entity == "" then return 0, 0 end
    if type(statuses) ~= "table" then return 0, 0 end

    duration = duration or -1
    force = force or 1

    local applied, failed = 0, 0

    for _, status in ipairs(statuses) do
        if status and status ~= "" then
            local ok = SafeApplyStatus(entity, status, duration, force)
            if ok then
                applied = applied + 1
            else
                failed = failed + 1
                DebugPrint("Failed to apply status:", status)
            end
        end
    end

    DebugPrint(string.format("Applied %d/%d statuses to %s", applied, #statuses, tostring(entity)))
    return applied, failed
end

-- ========= MOD DEPENDENCIES =========
local MOD_UUIDS = {}
-- Track if we've already warned about missing mods
local WARNINGS_SHOWN = {}

-- Register a mod-scoped, synced, persistent table for reputation
Ext.Vars.RegisterModVariable(ModuleUUID, "Reputation", {
    Server = true,
    Client = false,
    WriteableOnServer = true,
    Persistent = true,
    SyncToClient = false
})

-- Retained internal persisted mirror for the supported BG3MCM-driven settings path.
-- This is save-sensitive, but it is not the supported standalone settings authority.
Ext.Vars.RegisterModVariable(ModuleUUID, "MCMSettings", {
    Server = true,
    Client = false,
    WriteableOnServer = true,
    Persistent = true,
    SyncToClient = false
})

-- Persisted tables (server-side)
Ext.Vars.RegisterModVariable(ModuleUUID, "PersistentSpawnedEnemies", {
    Server = true,
    WriteableOnServer = true,
    Persistent = true,
    SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "PersistentDefeatedSpawnedEnemies", {
    Server = true,
    WriteableOnServer = true,
    Persistent = true,
    SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "PersistentPendingAmbushes", {
    Server = true,
    WriteableOnServer = true,
    Persistent = true,
    SyncToClient = false
})

-- Dedicated mirror for the single active deferred rest chain.
-- This exists because REST_DEFERRED must survive save/load even when the
-- generic pending-timer corridor has not yet been reconstructed.
Ext.Vars.RegisterModVariable(ModuleUUID, "EA_RestDeferredState", {
    Server = true,
    WriteableOnServer = true,
    Persistent = true,
    SyncToClient = false
})

-- Dedicated mirror for the single active delayed ambush warning chain.
-- This exists because the delayed warning timer can survive save/load even
-- when the generic pending row has not yet been persisted or reconstructed.
Ext.Vars.RegisterModVariable(ModuleUUID, "EA_DelayedAmbushState", {
    Server = true,
    WriteableOnServer = true,
    Persistent = true,
    SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "LastAmbushTime", {
    Server = true,
    WriteableOnServer = true,
    Persistent = true,
    SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "AmbushPressure", {
    Server = true,
    WriteableOnServer = true,
    Persistent = true,
    SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "AmbushPressureLastUpdate", {
    Server = true,
    WriteableOnServer = true,
    Persistent = true,
    SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_TimeSourceVersion", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_ModVersion", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_TutorialShown", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "GuaranteedChampionQueue", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "GuaranteedChampionArmed", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "CXOverride", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_ChampionLastSpawnByType", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_RestCycleCounter", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_ChampionCooldownCycleByType", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_ScriptedScenarioState", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_TimeInDangerState", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

-- Beach tutorial bootstrap state bucket (used by Events bootstrap timers).
Ext.Vars.RegisterModVariable(ModuleUUID, "EA_BeachBootstrapState", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

-- Persistent hostility retry queue (save/load resilient hostility retries).
Ext.Vars.RegisterModVariable(ModuleUUID, "EA_PersistentHostileRetries", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

-- Stores CUSTOM preset base (Wayfarer/Marked/Relentless/Hunted) for preset-derived advanced defaults.
Ext.Vars.RegisterModVariable(ModuleUUID, "MCMCustomPresetBase", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_TypePressure", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_TypePressureLastUpdate", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_WorldRepWindow", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_AmbushTypeHistory", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

Ext.Vars.RegisterModVariable(ModuleUUID, "EA_OutOfCombatRepLedger", {
    Server = true, Client = false, WriteableOnServer = true, Persistent = true, SyncToClient = false
})

local EA_PERSISTENT_ROOT_FIELDS = {
    "Reputation",
    "MCMSettings",
    "PersistentSpawnedEnemies",
    "PersistentDefeatedSpawnedEnemies",
    "PersistentPendingAmbushes",
    "EA_RestDeferredState",
    "EA_DelayedAmbushState",
    "LastAmbushTime",
    "AmbushPressure",
    "AmbushPressureLastUpdate",
    "EA_TimeSourceVersion",
    "EA_ModVersion",
    "EA_TutorialShown",
    "GuaranteedChampionQueue",
    "GuaranteedChampionArmed",
    "CXOverride",
    "EA_ChampionLastSpawnByType",
    "EA_RestCycleCounter",
    "EA_ChampionCooldownCycleByType",
    "EA_ScriptedScenarioState",
    "EA_TimeInDangerState",
    "EA_BeachBootstrapState",
    "EA_PersistentHostileRetries",
    "MCMCustomPresetBase",
    "EA_TypePressure",
    "EA_TypePressureLastUpdate",
    "EA_WorldRepWindow",
    "EA_AmbushTypeHistory",
    "EA_OutOfCombatRepLedger",
}

local EA_PERSISTENT_ACCESSOR_FIELD_MAP = {
    EA_LastAmbushTime = "LastAmbushTime",
    EA_AmbushPressure = "AmbushPressure",
    EA_AmbushPressureLastUpdate = "AmbushPressureLastUpdate",
    EA_TypePressure = "EA_TypePressure",
    EA_TypePressureLastUpdate = "EA_TypePressureLastUpdate",
    EA_TimeInDangerState = "EA_TimeInDangerState",
    EA_WorldRepWindow = "EA_WorldRepWindow",
    EA_AmbushTypeHistory = "EA_AmbushTypeHistory",
    EA_OutOfCombatRepLedger = "EA_OutOfCombatRepLedger",
    EA_Spawned = "PersistentSpawnedEnemies",
    EA_DefeatedSpawned = "PersistentDefeatedSpawnedEnemies",
    EA_Pending = "PersistentPendingAmbushes",
    EA_GuaranteedChampionQueue = "GuaranteedChampionQueue",
    EA_GetGuaranteedChampionArmed = "GuaranteedChampionArmed",
    EA_SetGuaranteedChampionArmed = "GuaranteedChampionArmed",
}

local EA_PERSISTENT_ROOT_CONTRACT = {
    moduleUUID = ModuleUUID,
    rootAccessor = "EA_Vars",
    strictAccessor = "EA_GetPersistentVarsStrict",
    fields = EA_PERSISTENT_ROOT_FIELDS,
    accessorFieldMap = EA_PERSISTENT_ACCESSOR_FIELD_MAP,
}

EA["EA_PERSISTENT_ROOT_CONTRACT"] = EA_PERSISTENT_ROOT_CONTRACT

local EA_ModVarsDiag = {
    ready = false,
    reason = "uninitialized",
    detail = "",
    running = nil,
    updatedAt = 0,
    failures = 0,
}

local EA_MODVARS_HANDLE_CACHE_TTL_MS = 180
local EA_ModVarsHandleCache = {
    vars = nil,
    expiresAt = 0,
}

local EA_VARS_STRICT_UNAVAILABLE_LOG = {
    reason = "",
    detail = "",
    updatedAt = 0,
}
local EA_VARS_STRICT_UNAVAILABLE_LOG_INTERVAL_MS = 60000

local function EA_DiagMonotonicMs()
    if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
        local ok, t = pcall(Ext.Utils.MonotonicTime)
        local n = tonumber(t)
        if ok and n then
            return math.floor(n)
        end
    end
    return 0
end

local function EA_InvalidateModVarsHandleCache()
    EA_ModVarsHandleCache.vars = nil
    EA_ModVarsHandleCache.expiresAt = 0
end

local function EA_RefreshModVarsHandleCache(vars)
    if not EA_IsModVarsContainer(vars) then
        EA_InvalidateModVarsHandleCache()
        return
    end
    local now = EA_DiagMonotonicMs()
    EA_ModVarsHandleCache.vars = vars
    EA_ModVarsHandleCache.expiresAt = now + EA_MODVARS_HANDLE_CACHE_TTL_MS
end

local function EA_GetCachedModVarsHandle()
    local now = EA_DiagMonotonicMs()
    if now <= 0 then
        return nil
    end
    if EA_ModVarsHandleCache.vars and now <= (tonumber(EA_ModVarsHandleCache.expiresAt) or 0) then
        if EA_IsModVarsContainer(EA_ModVarsHandleCache.vars) then
            return EA_ModVarsHandleCache.vars
        end
        EA_InvalidateModVarsHandleCache()
    end
    return nil
end

function EA_GetModVarsReadyDiagnostics()
    return {
        ready = (EA_ModVarsDiag.ready == true),
        reason = tostring(EA_ModVarsDiag.reason or "unknown"),
        detail = tostring(EA_ModVarsDiag.detail or ""),
        running = EA_ModVarsDiag.running,
        failures = tonumber(EA_ModVarsDiag.failures) or 0,
        updatedAt = tonumber(EA_ModVarsDiag.updatedAt) or 0,
    }
end

function EA_IsModVarsContainer(vars)
    local t = type(vars)
    return t == "table" or t == "userdata"
end

function EA_ModVarsReady()
    EA_ModVarsDiag.updatedAt = EA_DiagMonotonicMs()
    EA_P0Inc("readiness.modVarsReadyChecks")

    if not (Ext and Ext.Vars and Ext.Vars.GetModVariables) then
        EA_ModVarsDiag.ready = false
        EA_ModVarsDiag.reason = "ext_vars_unavailable"
        EA_ModVarsDiag.detail = "Ext.Vars.GetModVariables missing"
        EA_ModVarsDiag.running = nil
        EA_ModVarsDiag.failures = (tonumber(EA_ModVarsDiag.failures) or 0) + 1
        EA_P0Inc("readiness.modVarsNotReady.ext_vars_unavailable")
        EA_P0Set("readiness.lastModVarsReason", "ext_vars_unavailable")
        return false
    end
    if Osi and Osi.IsGameStateRunning then
        local okRunning, running = pcall(Osi.IsGameStateRunning)
        EA_ModVarsDiag.running = running
        if not okRunning then
            EA_ModVarsDiag.ready = false
            EA_ModVarsDiag.reason = "game_state_query_failed"
            EA_ModVarsDiag.detail = tostring(running or "unknown_error")
            EA_ModVarsDiag.failures = (tonumber(EA_ModVarsDiag.failures) or 0) + 1
            EA_P0Inc("readiness.modVarsNotReady.game_state_query_failed")
            EA_P0Set("readiness.lastModVarsReason", "game_state_query_failed")
            return false
        end
        if okRunning and running ~= 1 then
            EA_ModVarsDiag.ready = false
            EA_ModVarsDiag.reason = "game_state_not_running"
            EA_ModVarsDiag.detail = string.format("IsGameStateRunning=%s", tostring(running))
            EA_ModVarsDiag.failures = (tonumber(EA_ModVarsDiag.failures) or 0) + 1
            EA_P0Inc("readiness.modVarsNotReady.game_state_not_running")
            EA_P0Set("readiness.lastModVarsReason", "game_state_not_running")
            return false
        end
    end
    if Ext and Ext.Mod and type(Ext.Mod.IsModLoaded) == "function" then
        local okLoaded, loaded = pcall(Ext.Mod.IsModLoaded, ModuleUUID)
        if okLoaded and loaded ~= true then
            EA_ModVarsDiag.ready = false
            EA_ModVarsDiag.reason = "module_not_loaded"
            EA_ModVarsDiag.detail = string.format("Module '%s' is not loaded", tostring(ModuleUUID))
            EA_ModVarsDiag.failures = (tonumber(EA_ModVarsDiag.failures) or 0) + 1
            EA_P0Inc("readiness.modVarsNotReady.module_not_loaded")
            EA_P0Set("readiness.lastModVarsReason", "module_not_loaded")
            return false
        end
    end

    local cached = EA_GetCachedModVarsHandle()
    if EA_IsModVarsContainer(cached) then
        EA_ModVarsDiag.ready = true
        EA_ModVarsDiag.reason = "ok_cached"
        EA_ModVarsDiag.detail = ""
        EA_ModVarsDiag.failures = 0
        EA_P0Inc("readiness.modVarsReadyOkCached")
        EA_P0Set("readiness.lastModVarsReason", "ok_cached")
        return true
    end

    local ok, vars = pcall(Ext.Vars.GetModVariables, ModuleUUID)
    if not ok then
        EA_ModVarsDiag.ready = false
        EA_ModVarsDiag.reason = "get_modvars_failed"
        EA_ModVarsDiag.detail = tostring(vars or "unknown_error")
        EA_ModVarsDiag.failures = (tonumber(EA_ModVarsDiag.failures) or 0) + 1
        EA_P0Inc("readiness.modVarsNotReady.get_modvars_failed")
        EA_P0Set("readiness.lastModVarsReason", "get_modvars_failed")
        return false
    end
    if not EA_IsModVarsContainer(vars) then
        EA_ModVarsDiag.ready = false
        EA_ModVarsDiag.reason = "get_modvars_invalid_type"
        EA_ModVarsDiag.detail = string.format("returned=%s", type(vars))
        EA_ModVarsDiag.failures = (tonumber(EA_ModVarsDiag.failures) or 0) + 1
        EA_P0Inc("readiness.modVarsNotReady.get_modvars_invalid_type")
        EA_P0Set("readiness.lastModVarsReason", "get_modvars_invalid_type")
        return false
    end

    EA_ModVarsDiag.ready = true
    EA_ModVarsDiag.reason = "ok"
    EA_ModVarsDiag.detail = ""
    EA_ModVarsDiag.failures = 0
    EA_RefreshModVarsHandleCache(vars)
    EA_P0Inc("readiness.modVarsReadyOk")
    EA_P0Set("readiness.lastModVarsReason", "ok")
    return true
end

local function EA_LogStrictVarsUnavailable(diag)
    EA_P0Inc("readiness.varsStrictAccessNotReady")
    EA_P0Set("readiness.lastVarsAccessReason", tostring(type(diag) == "table" and diag.reason or "unknown"))

    local debugEnabled = false
    if EA and type(EA["EA_GetSettingFromSnapshot"]) == "function" then
        local okLogging, outLogging = pcall(EA["EA_GetSettingFromSnapshot"], "MCM_EnableDebugLogging", false)
        debugEnabled = okLogging and outLogging == true
        local okDebug, outDebug = pcall(EA["EA_GetSettingFromSnapshot"], "MCM_DebugMode", false)
        debugEnabled = debugEnabled or (okDebug and outDebug == true)
    end
    if debugEnabled ~= true then
        return
    end

    local reason = tostring(type(diag) == "table" and diag.reason or "unknown")
    local detail = tostring(type(diag) == "table" and diag.detail or "")
    local running = tostring(type(diag) == "table" and diag.running or "")
    local now = EA_DiagMonotonicMs()
    local sameReason = (EA_VARS_STRICT_UNAVAILABLE_LOG.reason == reason)
        and (EA_VARS_STRICT_UNAVAILABLE_LOG.detail == detail)
    local recentlyLogged = (now > 0)
        and ((now - (tonumber(EA_VARS_STRICT_UNAVAILABLE_LOG.updatedAt) or 0)) < EA_VARS_STRICT_UNAVAILABLE_LOG_INTERVAL_MS)
    if sameReason and recentlyLogged then
        return
    end

    EA_VARS_STRICT_UNAVAILABLE_LOG.reason = reason
    EA_VARS_STRICT_UNAVAILABLE_LOG.detail = detail
    EA_VARS_STRICT_UNAVAILABLE_LOG.updatedAt = now
    DebugPrint(
        "EA_Vars strict access unavailable: persistent ModVariables not ready",
        "reason=", reason,
        "detail=", detail,
        "running=", running
    )
end

local function EA_GetPersistentVarsStrict()
    local cached = EA_GetCachedModVarsHandle()
    if EA_IsModVarsContainer(cached) then
        return cached
    end

    local ready = (type(EA_ModVarsReady) == "function" and EA_ModVarsReady() == true)
    if not ready then
        EA_InvalidateModVarsHandleCache()
        local diag = (type(EA_GetModVarsReadyDiagnostics) == "function") and EA_GetModVarsReadyDiagnostics() or nil
        EA_LogStrictVarsUnavailable(diag)
        return nil
    end

    cached = EA_GetCachedModVarsHandle()
    if EA_IsModVarsContainer(cached) then
        return cached
    end

    if Ext and Ext.Vars and Ext.Vars.GetModVariables then
        local ok, vars = pcall(Ext.Vars.GetModVariables, ModuleUUID)
        if ok and EA_IsModVarsContainer(vars) then
            EA_RefreshModVarsHandleCache(vars)
            return vars
        end
    end

    EA_InvalidateModVarsHandleCache()
    local diag = (type(EA_GetModVarsReadyDiagnostics) == "function") and EA_GetModVarsReadyDiagnostics() or nil
    EA_LogStrictVarsUnavailable(diag)
    return nil
end

EA["EA_GetPersistentVarsStrict"] = EA_GetPersistentVarsStrict

function EA_Vars()
    return EA_GetPersistentVarsStrict()
end

local function EA_GetPersistentFieldStrict(fieldName)
    local v = EA_Vars()
    if not EA_IsModVarsContainer(v) then
        return nil, nil
    end
    return v[fieldName], v
end

local function EA_GetOrInitPersistentTableFieldStrict(fieldName)
    local current, v = EA_GetPersistentFieldStrict(fieldName)
    if not EA_IsModVarsContainer(v) then
        return nil
    end
    if not EA_IsModVarsContainer(current) then
        current = {}
        v[fieldName] = current
    end
    return current
end

function EA_LastAmbushTime()
    return EA_GetOrInitPersistentTableFieldStrict("LastAmbushTime")
end

function EA_AmbushPressure()
    return EA_GetOrInitPersistentTableFieldStrict("AmbushPressure")
end

function EA_AmbushPressureLastUpdate()
    return EA_GetOrInitPersistentTableFieldStrict("AmbushPressureLastUpdate")
end

EA["EA_InvalidateModVarsHandleCache"] = EA_InvalidateModVarsHandleCache

function EA_TypePressure()
    return EA_GetOrInitPersistentTableFieldStrict("EA_TypePressure")
end

function EA_TypePressureLastUpdate()
    return EA_GetOrInitPersistentTableFieldStrict("EA_TypePressureLastUpdate")
end

function EA_TimeInDangerState()
    local st = EA_GetOrInitPersistentTableFieldStrict("EA_TimeInDangerState")
    if not EA_IsModVarsContainer(st) then
        return nil
    end
    if not EA_IsModVarsContainer(st.accumulatedMsByCharacter) then
        st.accumulatedMsByCharacter = {}
    end
    if not EA_IsModVarsContainer(st.lastTickAtMsByCharacter) then
        st.lastTickAtMsByCharacter = {}
    end
    if not EA_IsModVarsContainer(st.lastTravelCheckAtMsByCharacter) then
        st.lastTravelCheckAtMsByCharacter = {}
    end
    return st
end

function EA_WorldRepWindow()
    local st = EA_GetOrInitPersistentTableFieldStrict("EA_WorldRepWindow")
    if not EA_IsModVarsContainer(st) then
        return nil
    end
    if not EA_IsModVarsContainer(st.perType) then st.perType = {} end
    if type(st.total) ~= "number" then st.total = tonumber(st.total) or 0 end
    if type(st.cycle) ~= "number" then st.cycle = tonumber(st.cycle) or 0 end
    return st
end

function EA_AmbushTypeHistory()
    return EA_GetOrInitPersistentTableFieldStrict("EA_AmbushTypeHistory")
end

function EA_OutOfCombatRepLedger()
    return EA_GetOrInitPersistentTableFieldStrict("EA_OutOfCombatRepLedger")
end

EA["EA_OutOfCombatRepLedger"] = EA_OutOfCombatRepLedger

function EA_TypePressureKey(character, creatureType)
    if not character or character == "" or not creatureType or creatureType == "" then
        return nil
    end
    local p = EA_NormalizeUUID(character) or tostring(character)
    return string.format("%s|%s", tostring(p), tostring(creatureType))
end

function EA_GetTypePressure(character, creatureType)
    local key = EA_TypePressureKey(character, creatureType)
    if not key then return 0 end
    local tbl = EA_TypePressure()
    if not EA_IsModVarsContainer(tbl) then
        return 0
    end
    return tonumber(tbl[key]) or 0
end

function EA_Spawned()
    return EA_GetOrInitPersistentTableFieldStrict("PersistentSpawnedEnemies")
end

function EA_DefeatedSpawned()
    return EA_GetOrInitPersistentTableFieldStrict("PersistentDefeatedSpawnedEnemies")
end

local EA_DEFEATED_SPAWNED_TRACK_CAP = 512
local EA_DEFEATED_SPAWNED_TTL_MS = 1000 * 60 * 60 * 24 -- 24 hours

local function EA_PruneDefeatedSpawned(defeated, cap)
    if not EA_IsModVarsContainer(defeated) then
        return
    end

    cap = tonumber(cap) or EA_DEFEATED_SPAWNED_TRACK_CAP
    local now = EA_GetPersistedNowMsSafe()
    local entries = {}

    for key, row in pairs(defeated) do
        local ts = tonumber(type(row) == "table" and row.ts or nil) or 0
        if type(key) ~= "string" or key == "" then
            defeated[key] = nil
        elseif now > 0 and ts > 0 and (now - ts) > EA_DEFEATED_SPAWNED_TTL_MS then
            defeated[key] = nil
        else
            entries[#entries + 1] = {
                key = key,
                ts = ts,
            }
        end
    end

    if #entries <= cap then
        return
    end

    table.sort(entries, function(a, b)
        return (tonumber(a.ts) or 0) < (tonumber(b.ts) or 0)
    end)

    for i = 1, (#entries - cap) do
        defeated[entries[i].key] = nil
    end
end

function EA_IsDefeatedSpawned(character)
    if type(character) ~= "string" or character == "" then
        return false
    end
    local key = EA_NormalizeUUID(character) or character
    local defeated = EA_DefeatedSpawned()
    if not EA_IsModVarsContainer(defeated) then
        return false
    end
    EA_PruneDefeatedSpawned(defeated)
    return type(defeated[key]) == "table"
end

function EA_RememberDefeatedSpawned(character, spawnedData, defeatKind)
    if type(character) ~= "string" or character == "" then
        return nil
    end
    local key = EA_NormalizeUUID(character) or character
    if type(key) ~= "string" or key == "" then
        return nil
    end

    local defeated = EA_DefeatedSpawned()
    if not EA_IsModVarsContainer(defeated) then
        return nil
    end
    defeated[key] = {
        ts = EA_GetPersistedNowMsSafe(),
        kind = tostring(defeatKind or "died"),
        creatureType = type(spawnedData) == "table" and spawnedData.creatureType or nil,
        isChampion = (type(spawnedData) == "table" and spawnedData.isChampion == true) or false,
    }
    EA_PruneDefeatedSpawned(defeated)
    return defeated[key]
end

-- Helper used by test/debug commands
local function EA_GetSpawnedData(uuid)
    if not uuid or uuid == "" then return nil end
    local norm = EA_NormalizeUUID(uuid) or uuid
    local spawned = EA_Spawned()
    if not EA_IsModVarsContainer(spawned) then
        return nil
    end
    return spawned[norm] or spawned[uuid]
end

local EA_SPAWNED_TRACK_CAP = 200
local EA_SPAWNED_STALE_TTL_MS = 1000 * 60 * 60 -- 60 minutes
local EA_SPAWNED_CLEANUP_LOAD_GRACE_MS = 1000 * 60 * 10 -- 10 minutes after session load

local function EA_CountTable(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

function EA_EvictOldSpawned(spawned, cap)
    if not EA_IsModVarsContainer(spawned) then return end
    cap = cap or EA_SPAWNED_TRACK_CAP

    local entries = {}
    local count = 0
    for uuid, data in pairs(spawned) do
        count = count + 1
        local last = 0
        if type(data) == "table" then
            last = tonumber(data.lastSeen) or tonumber(data.tsCreated) or 0
        end
        entries[#entries+1] = { uuid = uuid, last = last }
    end

    if count <= cap then return end

    table.sort(entries, function(a, b) return a.last < b.last end)
    local toEvict = count - cap
    for i = 1, toEvict do
        spawned[entries[i].uuid] = nil
    end
end

function EA_MarkSessionLoadedForCleanup(tsMs)
    EnemyAmbush._SpawnedCleanupSessionLoadedAtMs = tonumber(tsMs) or EA_NowMs() or 0
end

-- Optional aggressive cleanup for old, unloaded tracked spawns (prevents save bloat)
function EA_AggressiveSpawnedCleanup()
    local spawned = EA_Spawned()
    if not EA_IsModVarsContainer(spawned) then return end

    local now = EA_NowMs()
    local removed = 0
    local dirty = false

    local loadedAt = tonumber(EnemyAmbush._SpawnedCleanupSessionLoadedAtMs) or 0
    if loadedAt <= 0 then
        loadedAt = now
        EnemyAmbush._SpawnedCleanupSessionLoadedAtMs = loadedAt
    end
    local inLoadGrace = (tonumber(now) or 0) > 0 and (now - loadedAt) < EA_SPAWNED_CLEANUP_LOAD_GRACE_MS
    local allowStalePurge = not inLoadGrace and (tonumber(now) or 0) > 0

    local keys = {}
    for k, _ in pairs(spawned) do keys[#keys+1] = k end

    for _, id in ipairs(keys) do
        local data = spawned[id]
        if type(data) ~= "table" then
            spawned[id] = nil
            removed = removed + 1
            dirty = true
        else
            if allowStalePurge then
                local lastSeen = tonumber(data.lastSeen) or tonumber(data.tsCreated) or 0
                local age = (lastSeen > 0) and (now - lastSeen) or (EA_SPAWNED_STALE_TTL_MS + 1)
                if Osi.ObjectExists and Osi.ObjectExists(id) ~= 1 then
                    if age > EA_SPAWNED_STALE_TTL_MS then
                        spawned[id] = nil
                        removed = removed + 1
                        dirty = true
                    end
                end
            end
        end
    end

    if dirty then
        EA_Dirty()
        DebugPrint("AggressiveSpawnedCleanup removed:", removed)
    end
end

function EA_Pending()
    return EA_GetOrInitPersistentTableFieldStrict("PersistentPendingAmbushes")
end
