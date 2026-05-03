-- EnemyAmbush_Utils_Telemetry.lua
-- Extracted from monolithic EnemyAmbush_Utils.lua for local-budget stability.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local ModuleUUID = EA.ModuleUUID or "96f24297-6ed9-455c-aaa1-ac9c358a8d35"
EA.ModuleUUID = ModuleUUID
local EA_TelemetrySetting

local function EA_TelemetryGetExport(name)
    if EA then
        local fn = EA[name]
        if type(fn) == "function" then
            return fn
        end
    end
    return nil
end

local function EA_TelemetryRobustEnabled()
    local robustFn = EA_TelemetryGetExport("EA_IsRobust")
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

local function EA_TelemetryDebugEnabled()
    return EA_TelemetryRobustEnabled() or (EnemyAmbush and EnemyAmbush._eaDebugTelemetry == true)
end

local function EA_TelemetryFriendlyProfile()
    local raw = tostring(EA_TelemetrySetting("MCM_BalanceProfile", "BG3_12"))
    local label = raw
    local labelFn = EA_TelemetryGetExport("EA_GetBalanceProfileLabel")
    if type(labelFn) == "function" then
        local ok, out = pcall(labelFn, raw)
        if ok and type(out) == "string" and out ~= "" then
            label = out
        end
    end
    return string.format("%s (%s)", label, raw)
end

local function EA_TelemetryFriendlyArrivalCuePolicy()
    local raw = tostring(EA_TelemetrySetting("MCM_ArrivalCuePolicy", "BALANCED"))
    local label = raw
    local labelFn = EA_TelemetryGetExport("EA_GetArrivalCuePolicyLabel")
    if type(labelFn) == "function" then
        local ok, out = pcall(labelFn, raw)
        if ok and type(out) == "string" and out ~= "" then
            label = out
        end
    end
    return string.format("%s (%s)", label, raw)
end

local function EA_TelemetryFriendlyPlacementMode()
    local raw = tostring(EA_TelemetrySetting("MCM_SpawnPlacementMode", "AUTO"))
    local label = raw
    local labelFn = EA_TelemetryGetExport("EA_GetSpawnPlacementModeLabel")
    if type(labelFn) == "function" then
        local ok, out = pcall(labelFn, raw)
        if ok and type(out) == "string" and out ~= "" then
            label = out
        end
    end
    return string.format("%s (%s)", label, raw)
end

-- ========= TELEMETRY (METRICS + LAST EVENTS) =========
PerformanceMetrics = {
    -- Core
    spawnsAttempted = 0,
    spawnsSuccessful = 0,
    spawnsFailed = 0,

    -- Placement + creation
    findValidPosFailed = 0,
    createAtAttempts = 0,
    createAtFailed = 0,
    losRejected = 0,
    spawnPlacementFailed = 0,

    -- Hostility/combat forcing
    hostileRetriesExhausted = 0,
    deferredHostileTimeouts = 0,

    -- Champions
    championsAttempted = 0,
    championsCreated = 0,
    championsFailed = 0,
    championFindValidPosFailed = 0,
    championCreateAtAttempts = 0,
    championCreateAtFailed = 0,
    championLosRejected = 0,

    -- Performance
    averageSpawnTime = 0,
    totalSpawnTime = 0,

    -- Cache
    cacheHits = 0,
    cacheMisses = 0,

    -- Last error
    lastError = nil,
    lastErrorTs = nil,
}

-- Ring buffer of recent events (for bug reports)
EnemyAmbush._eaEventLog = EnemyAmbush._eaEventLog or {}
EnemyAmbush._eaEventLogMax = EnemyAmbush._eaEventLogMax or 60

local function EA_EventTime()
    if EA_NowMs then return EA_NowMs() end
    return os.time() * 1000
end

-- ========= PHASE 0 INSTRUMENTATION =========
local EA_PHASE0_NOTE_MAX = 64
local EA_PHASE0_SESSION_MARKER_MAX = 32
local EA_PHASE0_DUP_KEY_MAX = 64
local EA_PHASE0_CONTEXT_KEY_MAX = 32
local EA_PHASE0_SAMPLE_MAX = 24

EnemyAmbush._eaPhase0Verbose = EnemyAmbush._eaPhase0Verbose == true
EnemyAmbush._eaPhase0GuardDupRegs = EnemyAmbush._eaPhase0GuardDupRegs == true

local function EA_P0Enabled()
    return EnemyAmbush._eaPhase0Enabled ~= false
end

local function EA_P0CurrentMode()
    if EnemyAmbush._eaPhase0GuardDupRegs == true then
        return "count_plus_guard"
    end
    return "count_only"
end

local function EA_P0Copy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = EA_P0Copy(v)
    end
    return out
end

local function EA_P0MakeStats()
    return {
        meta = {
            enabled = EA_P0Enabled(),
            verbose = EnemyAmbush._eaPhase0Verbose == true,
            guardDupRegs = EnemyAmbush._eaPhase0GuardDupRegs == true,
            mode = EA_P0CurrentMode(),
            caps = {
                noteBuffer = EA_PHASE0_NOTE_MAX,
                sessionMarkers = EA_PHASE0_SESSION_MARKER_MAX,
                duplicateKeys = EA_PHASE0_DUP_KEY_MAX,
                contextKeys = EA_PHASE0_CONTEXT_KEY_MAX,
                sampleBuffer = EA_PHASE0_SAMPLE_MAX,
            },
        },
        session = {
            bootCount = 0,
            sessionLoadedCount = 0,
            lastSessionLoadedAtMs = 0,
            markers = {},
        },
        listenerReg = {},
        listenerRegGuard = {},
        listenerExec = {},
        timerExec = {},
        killedBy = {},
        enterCombat = {},
        readiness = {},
        notes = {},
    }
end

local function EA_P0CountKeys(t)
    local count = 0
    if type(t) ~= "table" then
        return count
    end
    for k, _ in pairs(t) do
        if k ~= "_overflow" then
            count = count + 1
        end
    end
    return count
end

local function EA_P0ResolvePath(root, path, create)
    if type(root) ~= "table" or type(path) ~= "string" or path == "" then
        return nil, nil
    end
    local current = root
    local key = nil
    for part in string.gmatch(path, "[^%.]+") do
        if key ~= nil then
            local nextNode = current[key]
            if type(nextNode) ~= "table" then
                if not create then
                    return nil, nil
                end
                nextNode = {}
                current[key] = nextNode
            end
            current = nextNode
        end
        key = part
    end
    return current, key
end

function EA_P0EnsureStats()
    local stats = EnemyAmbush._eaPhase0Stats
    if type(stats) ~= "table" then
        stats = EA_P0MakeStats()
        EnemyAmbush._eaPhase0Stats = stats
    end

    stats.meta = type(stats.meta) == "table" and stats.meta or {}
    stats.meta.enabled = EA_P0Enabled()
    stats.meta.verbose = EnemyAmbush._eaPhase0Verbose == true
    stats.meta.guardDupRegs = EnemyAmbush._eaPhase0GuardDupRegs == true
    stats.meta.mode = EA_P0CurrentMode()
    stats.meta.caps = {
        noteBuffer = EA_PHASE0_NOTE_MAX,
        sessionMarkers = EA_PHASE0_SESSION_MARKER_MAX,
        duplicateKeys = EA_PHASE0_DUP_KEY_MAX,
        contextKeys = EA_PHASE0_CONTEXT_KEY_MAX,
        sampleBuffer = EA_PHASE0_SAMPLE_MAX,
    }

    stats.session = type(stats.session) == "table" and stats.session or {}
    stats.session.markers = type(stats.session.markers) == "table" and stats.session.markers or {}
    stats.listenerReg = type(stats.listenerReg) == "table" and stats.listenerReg or {}
    stats.listenerRegGuard = type(stats.listenerRegGuard) == "table" and stats.listenerRegGuard or {}
    stats.listenerExec = type(stats.listenerExec) == "table" and stats.listenerExec or {}
    stats.timerExec = type(stats.timerExec) == "table" and stats.timerExec or {}
    stats.killedBy = type(stats.killedBy) == "table" and stats.killedBy or {}
    stats.enterCombat = type(stats.enterCombat) == "table" and stats.enterCombat or {}
    stats.readiness = type(stats.readiness) == "table" and stats.readiness or {}
    stats.notes = type(stats.notes) == "table" and stats.notes or {}

    return stats
end

function EA_P0Inc(path, delta)
    if not EA_P0Enabled() then
        return 0
    end
    local parent, key = EA_P0ResolvePath(EA_P0EnsureStats(), path, true)
    if not parent or not key then
        return 0
    end
    local amount = tonumber(delta) or 1
    parent[key] = (tonumber(parent[key]) or 0) + amount
    return tonumber(parent[key]) or 0
end

function EA_P0Set(path, value)
    if not EA_P0Enabled() then
        return nil
    end
    local parent, key = EA_P0ResolvePath(EA_P0EnsureStats(), path, true)
    if not parent or not key then
        return nil
    end
    parent[key] = value
    return parent[key]
end

function EA_P0SetFlag(path, value)
    return EA_P0Set(path, value)
end

function EA_P0PushNote(path, entry, maxEntries)
    if not EA_P0Enabled() then
        return 0
    end
    local parent, key = EA_P0ResolvePath(EA_P0EnsureStats(), path, true)
    if not parent or not key then
        return 0
    end
    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end
    local bucket = parent[key]
    bucket[#bucket + 1] = EA_P0Copy(entry)
    local maxCount = math.max(1, tonumber(maxEntries) or EA_PHASE0_NOTE_MAX)
    while #bucket > maxCount do
        table.remove(bucket, 1)
    end
    return #bucket
end

function EA_P0BumpKeyedCount(path, bucketKey, maxKeys)
    if not EA_P0Enabled() then
        return 0
    end
    bucketKey = tostring(bucketKey or "")
    if bucketKey == "" then
        return 0
    end
    local parent, key = EA_P0ResolvePath(EA_P0EnsureStats(), path, true)
    if not parent or not key then
        return 0
    end
    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end
    local bucket = parent[key]
    if bucket[bucketKey] ~= nil then
        bucket[bucketKey] = (tonumber(bucket[bucketKey]) or 0) + 1
        return tonumber(bucket[bucketKey]) or 0
    end
    local limit = math.max(1, tonumber(maxKeys) or EA_PHASE0_DUP_KEY_MAX)
    if EA_P0CountKeys(bucket) >= limit then
        bucket._overflow = (tonumber(bucket._overflow) or 0) + 1
        return 0
    end
    bucket[bucketKey] = 1
    return 1
end

function EA_GetPhase0Stats()
    return EA_P0Copy(EA_P0EnsureStats())
end

function EA_ResetPhase0Stats()
    EnemyAmbush._eaPhase0Stats = EA_P0MakeStats()
    return EA_GetPhase0Stats()
end

local function EA_P0CollectDuplicatePaths(prefix, bucket, out)
    if type(bucket) ~= "table" then
        return
    end
    for key, value in pairs(bucket) do
        local path = (prefix ~= "" and (prefix .. "." .. tostring(key))) or tostring(key)
        if type(value) == "number" then
            if tonumber(value) and tonumber(value) > 1 then
                out[#out + 1] = path
            end
        elseif type(value) == "table" then
            EA_P0CollectDuplicatePaths(path, value, out)
        end
    end
end

function EA_GetPhase0Summary()
    local stats = EA_P0EnsureStats()
    local duplicateCallsites = {}
    EA_P0CollectDuplicatePaths("", stats.listenerReg, duplicateCallsites)
    table.sort(duplicateCallsites)

    return {
        mode = EA_P0CurrentMode(),
        enabled = EA_P0Enabled(),
        verbose = EnemyAmbush._eaPhase0Verbose == true,
        session = {
            bootCount = tonumber(stats.session.bootCount) or 0,
            sessionLoadedCount = tonumber(stats.session.sessionLoadedCount) or 0,
            lastSessionLoadedAtMs = tonumber(stats.session.lastSessionLoadedAtMs) or 0,
            markerCount = #(stats.session.markers or {}),
        },
        listenerReg = EA_P0Copy(stats.listenerReg),
        listenerRegGuard = EA_P0Copy(stats.listenerRegGuard),
        duplicateRegistrationCallsites = duplicateCallsites,
        noteCount = #(stats.notes or {}),
    }
end

EA_P0EnsureStats()

function EA_LogEvent(kind, msg)
    kind = tostring(kind or "EVT")
    msg = tostring(msg or "")
    local t = EA_EventTime()
    local line = string.format("[%s][%d] %s", kind, t, msg)

    local log = EnemyAmbush._eaEventLog
    log[#log + 1] = line
    if #log > (EnemyAmbush._eaEventLogMax or 60) then
        table.remove(log, 1)
    end

    -- IMPORTANT: only print event spam when debug telemetry is enabled
    if EA_TelemetryDebugEnabled() then
        print("[EnemyAmbush][EVT] " .. line)
    end
end

function EA_SetLastError(code, detail)
    local line = tostring(code or "Error")
    if detail and detail ~= "" then
        line = line .. " | " .. tostring(detail)
    end
    PerformanceMetrics.lastError = line
    PerformanceMetrics.lastErrorTs = EA_EventTime()
    EA_LogEvent("ERR", line)
end

function UpdateMetric(metric, value)
    if not metric or metric == "" then return end
    PerformanceMetrics[metric] = (PerformanceMetrics[metric] or 0) + (value or 1)
end

function GetMetricsSummary()
    local successRate = 0
    if (PerformanceMetrics.spawnsAttempted or 0) > 0 then
        successRate = ((PerformanceMetrics.spawnsSuccessful or 0) / (PerformanceMetrics.spawnsAttempted or 1)) * 100
    end

    local hitRate = (PerformanceMetrics.cacheHits or 0) / ((PerformanceMetrics.cacheHits or 0) + (PerformanceMetrics.cacheMisses or 0) + 0.001) * 100

    return string.format(
        "[EnemyAmbush] Metrics: %d spawns (%d ok, %.1f%%), Avg spawn time: %.2fms, Cache hit rate: %.1f%%, LastErr: %s",
        (PerformanceMetrics.spawnsAttempted or 0),
        (PerformanceMetrics.spawnsSuccessful or 0),
        successRate,
        (PerformanceMetrics.averageSpawnTime or 0),
        hitRate,
        tostring(PerformanceMetrics.lastError or "(none)")
    )
end

function EA_SafeCountTable(t)
    if type(t) ~= "table" then return 0 end
    local getTableSizeFn = EA_TelemetryGetExport("GetTableSize")
    if type(getTableSizeFn) == "function" then
        return getTableSizeFn(t)
    end
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

EA_TelemetrySetting = function(settingId, fallback)
    if EA and type(EA["EA_GetSettingFromSnapshot"]) == "function" then
        local ok, out = pcall(EA["EA_GetSettingFromSnapshot"], settingId, fallback)
        if ok and out ~= nil then
            return out
        end
    end
    return fallback
end

function EA_DumpState()
    print("[EnemyAmbush][DUMP] ===============================")
    print("[EnemyAmbush][DUMP] Version:", tostring(MOD_VERSION or "(unknown)"))
    print("[EnemyAmbush][DUMP] ModuleUUID:", tostring(ModuleUUID or "(unknown)"))
    print("[EnemyAmbush][DUMP] RobustMode:", tostring(EA_TelemetryRobustEnabled()))
    print("[EnemyAmbush][DUMP] TimeMode:", tostring(EA_TIME_MODE or "(not set)"))
    print("[EnemyAmbush][DUMP] " .. GetMetricsSummary())

    -- Quick counts for persisted tables (if they exist in your build)
    local okSpawned = (type(EA_Spawned) == "function") and EA_Spawned() or nil
    local okPending = (type(EA_Pending) == "function") and EA_Pending() or nil
    local okQueue = (type(EA_GuaranteedChampionQueue) == "function") and EA_GuaranteedChampionQueue() or nil
    local okLast = (type(EA_LastAmbushTime) == "function") and EA_LastAmbushTime() or nil

    print("[EnemyAmbush][DUMP] Counts: spawned=" .. EA_SafeCountTable(okSpawned)
        .. " pending=" .. EA_SafeCountTable(okPending)
        .. " champQueue=" .. EA_SafeCountTable(okQueue)
        .. " lastAmbushTime=" .. EA_SafeCountTable(okLast))

    -- Snapshot common settings via canonical settings accessors.
    print("[EnemyAmbush][DUMP] Settings snapshot:",
        "EnableSummons=" .. tostring(EA_TelemetrySetting("MCM_EnableSummons", true)),
        "EnableOnRest=" .. tostring(EA_TelemetrySetting("MCM_EnableOnRest", true)),
        "EnableCooldown=" .. tostring(EA_TelemetrySetting("MCM_EnableAmbushCooldown", true)),
        "CooldownMin=" .. tostring(EA_TelemetrySetting("MCM_AmbushCooldownMinutes", 45)),
        "QuickTest=" .. tostring(EA_TelemetrySetting("MCM_QuickTestMode", false)),
        "ShortChance%=" .. tostring(EA_TelemetrySetting("MCM_AmbushChanceShortPct", 5)),
        "LongChance%=" .. tostring(EA_TelemetrySetting("MCM_AmbushChanceLongPct", 15)),
        "ShortDelayMin=" .. tostring(EA_TelemetrySetting("MCM_ShortRestDelayMinMinutes", 0)),
        "ShortDelayMax=" .. tostring(EA_TelemetrySetting("MCM_ShortRestDelayMaxMinutes", 10)),
        "LongDelayMin=" .. tostring(EA_TelemetrySetting("MCM_LongRestDelayMinMinutes", 2)),
        "LongDelayMax=" .. tostring(EA_TelemetrySetting("MCM_LongRestDelayMaxMinutes", 20)),
        "Intensity=" .. tostring(EA_TelemetrySetting("MCM_AmbushIntensity", 0.90)),
        "StrictGates=" .. tostring(EA_TelemetrySetting("MCM_StrictProgressionGates", true)),
        "CompGuards=" .. tostring(EA_TelemetrySetting("MCM_UseCompositionGuards", true)),
        "Profile=" .. EA_TelemetryFriendlyProfile(),
        "FodderCurve=7+:50%,10+:30%,12+:10%",
        "ArrivalCuePolicy=" .. EA_TelemetryFriendlyArrivalCuePolicy(),
        "ArrivalCueScale%=100(fixed)",
        "PlacementMode=" .. EA_TelemetryFriendlyPlacementMode(),
        "SkipBeachTutorial=" .. tostring(EA_TelemetrySetting("MCM_SkipBeachTutorialAmbush", false)),
        "XP%=" .. tostring(EA_TelemetrySetting("MCM_AmbushXPPercent", 10)),
        "LootOff=" .. tostring(EA_TelemetrySetting("MCM_DisableAmbushLoot", false))
    )

    if PerformanceMetrics.lastError then
        print("[EnemyAmbush][DUMP] LastErrorTs:", tostring(PerformanceMetrics.lastErrorTs))
    end

    print("[EnemyAmbush][DUMP] Recent events (newest last):")
    local log = EnemyAmbush._eaEventLog or {}
    for i = math.max(1, #log - 30), #log do
        print("[EnemyAmbush][DUMP]  " .. tostring(log[i]))
    end
    print("[EnemyAmbush][DUMP] ===============================")
end

function EA_ResetMetrics()
    for k, v in pairs(PerformanceMetrics) do
        if type(v) == "number" then PerformanceMetrics[k] = 0 end
    end
    PerformanceMetrics.lastError = nil
    PerformanceMetrics.lastErrorTs = nil
    EnemyAmbush._eaEventLog = {}
    print("[EnemyAmbush][DUMP] Metrics reset.")
end

-- ========= AUTO-DUMP ON FAILURE STREAK (rate limited, DEBUG ONLY) =========
-- Metrics always collect; auto-dump only triggers in debug telemetry mode.
EnemyAmbush._eaDebugTelemetry = EnemyAmbush._eaDebugTelemetry or false

EnemyAmbush._eaSpawnFailStreak = EnemyAmbush._eaSpawnFailStreak or 0
EnemyAmbush._eaAutoDumpCooldownUntil = EnemyAmbush._eaAutoDumpCooldownUntil or 0

function EA_DebugTelemetryEnabled()
    return EA_TelemetryDebugEnabled()
end

function EA_RecordSpawnSuccess(context)
    EnemyAmbush._eaSpawnFailStreak = 0
end

function EA_RecordSpawnFailure(context)
    EnemyAmbush._eaSpawnFailStreak = (EnemyAmbush._eaSpawnFailStreak or 0) + 1
    EA_LogEvent("SPAWN_FAIL", "streak=" .. tostring(EnemyAmbush._eaSpawnFailStreak) .. " ctx=" .. tostring(context or ""))

    -- Only auto-dump when debug telemetry is enabled (prevents Nexus log spam)
    if not EA_DebugTelemetryEnabled() then
        return
    end

    -- Trigger after 3 consecutive failures, then rate-limit (60s)
    if EnemyAmbush._eaSpawnFailStreak >= 3 then
        local now = EA_EventTime()
        if now >= (EnemyAmbush._eaAutoDumpCooldownUntil or 0) then
            EnemyAmbush._eaAutoDumpCooldownUntil = now + 60000
            EA_LogEvent("AUTO_DUMP", "Triggered ctx=" .. tostring(context or ""))
            EA_DumpState()
        end
    end
end

-- Console command ownership intentionally lives in EnemyAmbush_DebugCommands.lua.
