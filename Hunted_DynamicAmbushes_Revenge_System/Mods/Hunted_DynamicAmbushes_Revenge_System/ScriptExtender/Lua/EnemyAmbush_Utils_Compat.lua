-- EnemyAmbush_Utils_Compat.lua
-- Optional legacy/dev shim for old global helper callsites.
-- This file is no longer part of normal bootstrap and should only load when
-- legacy globals are explicitly enabled before bootstrap.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
EA.LegacyCompatGlobalsEnabled = true

if not EA._LegacyCompatGlobalsAnnounced then
    EA._LegacyCompatGlobalsAnnounced = true
    print("[EnemyAmbush][Compat] Optional legacy global shim enabled.")
end

local warned = {}
local function warnOnce(name, exportName)
    if warned[name] then
        return
    end
    warned[name] = true
    print(string.format(
        "[EnemyAmbush][Deprecation] Global %s called; use EnemyAmbush[\"%s\"] instead.",
        tostring(name),
        tostring(exportName or name)
    ))
end

if rawget(_G, "SafeOsiCall") == nil then
    _G.SafeOsiCall = function(func, ...)
        local fn = EA and EA["SafeOsiCall"]
        if type(fn) == "function" then
            warnOnce("SafeOsiCall")
            return fn(func, ...)
        end
        if not func then
            return nil
        end
        local ok, a, b, c, d, e = pcall(func, ...)
        if not ok then
            return nil
        end
        return a, b, c, d, e
    end
end

if rawget(_G, "SafeOsiExec") == nil then
    _G.SafeOsiExec = function(func, ...)
        local fn = EA and EA["SafeOsiExec"]
        if type(fn) == "function" then
            warnOnce("SafeOsiExec")
            return fn(func, ...)
        end
        if not func then
            return false
        end
        local ok = pcall(func, ...)
        return ok == true
    end
end

if rawget(_G, "SafeAddBoosts") == nil then
    _G.SafeAddBoosts = function(target, boosts)
        local fn = EA and EA["SafeAddBoosts"]
        if type(fn) == "function" then
            warnOnce("SafeAddBoosts")
            return fn(target, boosts)
        end
        if not (Osi and Osi.AddBoosts) then
            return false
        end
        if pcall(Osi.AddBoosts, target, boosts, "", "") then
            return true
        end
        if pcall(Osi.AddBoosts, target, boosts, "", target) then
            return true
        end
        return false
    end
end

if rawget(_G, "SafeGetPosition") == nil then
    _G.SafeGetPosition = function(entity)
        local fn = EA and EA["SafeGetPosition"]
        if type(fn) == "function" then
            warnOnce("SafeGetPosition")
            return fn(entity)
        end
        if not entity or entity == "" then
            return nil, nil, nil
        end
        local ok, x, y, z = pcall(Osi.GetPosition, entity)
        if ok and type(x) == "number" and type(y) == "number" and type(z) == "number" then
            return x, y, z
        end
        return nil, nil, nil
    end
end

if rawget(_G, "GetTableSize") == nil then
    _G.GetTableSize = function(t)
        local fn = EA and EA["GetTableSize"]
        if type(fn) == "function" then
            warnOnce("GetTableSize")
            return fn(t)
        end
        local count = 0
        if type(t) == "table" then
            for _ in pairs(t) do
                count = count + 1
            end
        end
        return count
    end
end

if rawget(_G, "IsRobust") == nil then
    _G.IsRobust = function(...)
        local fn = EA and EA["EA_IsRobust"]
        if type(fn) == "function" then
            warnOnce("IsRobust", "EA_IsRobust")
            return fn(...)
        end
        return false
    end
end

if rawget(_G, "PlayVFX_OnEntity") == nil then
    _G.PlayVFX_OnEntity = function(entity, vfx, scale)
        local fn = EA and EA["PlayVFX_OnEntity"]
        if type(fn) == "function" then
            warnOnce("PlayVFX_OnEntity", "PlayVFX_OnEntity")
            return fn(entity, vfx, scale)
        end
    end
end

if rawget(_G, "GetSpawnRetryCount") == nil then
    _G.GetSpawnRetryCount = function(...)
        local fn = EA and EA["EA_GetSpawnRetryCount"]
        if type(fn) == "function" then
            warnOnce("GetSpawnRetryCount", "EA_GetSpawnRetryCount")
            return fn(...)
        end
        return 1
    end
end

if rawget(_G, "GetSpawnRetryBackoffMs") == nil then
    _G.GetSpawnRetryBackoffMs = function(attempt)
        local fn = EA and EA["EA_GetSpawnRetryBackoffMs"]
        if type(fn) == "function" then
            warnOnce("GetSpawnRetryBackoffMs", "EA_GetSpawnRetryBackoffMs")
            return fn(attempt)
        end
        return 0
    end
end

if rawget(_G, "GetSpawnRadiusBonus") == nil then
    _G.GetSpawnRadiusBonus = function(attempt)
        local fn = EA and EA["EA_GetSpawnRadiusBonus"]
        if type(fn) == "function" then
            warnOnce("GetSpawnRadiusBonus", "EA_GetSpawnRadiusBonus")
            return fn(attempt)
        end
        return 0.0
    end
end
