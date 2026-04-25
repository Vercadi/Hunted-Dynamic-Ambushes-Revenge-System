-- EnemyAmbush_RNG.lua
-- Mod-local RNG for deterministic, mod-scoped randomness across systems.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local MODULE_UUID = EA.ModuleUUID or "96f24297-6ed9-455c-aaa1-ac9c358a8d35"
EA.ModuleUUID = MODULE_UUID

local RNG_MOD = 2147483647
local RNG_A = 48271
local RNG_DEFAULT_SEED = 1357911

local function EA_HashSeedSource(src)
    local hash = 216613
    for i = 1, #src do
        hash = (hash * 33 + src:byte(i)) % RNG_MOD
    end
    return hash
end

local function EA_EnsureSeeded()
    if tonumber(EA._rngState) and tonumber(EA._rngState) > 0 then
        return
    end

    local mono = 0
    if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
        mono = tonumber(Ext.Utils.MonotonicTime()) or 0
    end

    local wallMs = 0
    if os and os.time then
        local okWall, wall = pcall(os.time)
        if okWall and tonumber(wall) then
            wallMs = (tonumber(wall) * 1000) + (mono % 1000)
        end
    end

    local cpuMs = 0
    if os and os.clock then
        local okCpu, c = pcall(os.clock)
        if okCpu and tonumber(c) then
            cpuMs = math.floor(tonumber(c) * 1000)
        end
    end

    local host = (Osi and Osi.GetHostCharacter and Osi.GetHostCharacter()) or ""
    local region = ""
    if host ~= "" and Osi and Osi.GetRegion then
        local okRegion, value = pcall(Osi.GetRegion, host)
        if okRegion and value then
            region = tostring(value)
        end
    end

    local src = string.format(
        "%s|%s|%s|%s|%s|%s|%s",
        tostring(mono),
        tostring(wallMs),
        tostring(cpuMs),
        tostring(host),
        tostring(region),
        tostring(MODULE_UUID),
        tostring(Ext and Ext.Utils and Ext.Utils.GameVersion and Ext.Utils.GameVersion() or "")
    )
    local seed = EA_HashSeedSource(src) % RNG_MOD
    if seed <= 0 then
        seed = RNG_DEFAULT_SEED
    end
    EA._rngState = seed
end

local function EA_NextRaw()
    EA_EnsureSeeded()
    local state = tonumber(EA._rngState) or RNG_DEFAULT_SEED
    state = (state * RNG_A) % RNG_MOD
    if state <= 0 then
        state = RNG_DEFAULT_SEED
    end
    EA._rngState = state
    return state
end

local function EA_RandFloat()
    return EA_NextRaw() / RNG_MOD
end

local function EA_RandInt(minVal, maxVal)
    local lo = tonumber(minVal)
    local hi = tonumber(maxVal)

    if lo == nil and hi == nil then
        return EA_NextRaw()
    end
    if hi == nil then
        hi = math.floor(lo)
        lo = 1
    else
        lo = math.floor(lo)
        hi = math.floor(hi)
    end

    if hi < lo then
        lo, hi = hi, lo
    end

    local span = (hi - lo) + 1
    if span <= 1 then
        return lo
    end

    return lo + (EA_NextRaw() % span)
end

EA.SeedRng = EA_EnsureSeeded
EA.RNG = EA.RNG or {}
EA.RNG.NextFloat = EA_RandFloat
EA.RNG.NextInt = EA_RandInt

EA["EA_RandFloat"] = EA_RandFloat
EA["EA_RandInt"] = EA_RandInt
