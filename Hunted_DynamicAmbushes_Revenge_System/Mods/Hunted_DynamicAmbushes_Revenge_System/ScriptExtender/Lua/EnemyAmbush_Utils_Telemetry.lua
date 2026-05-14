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
    local raw = tostring(EA_TelemetrySetting("MCM_SpawnPlacementMode", "CREATE_OOS_ONLY"))
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
    runtimePostLoadGraceBlocks = 0,
    runtimeDialogCutsceneBlocks = 0,
    encountersBegun = 0,
    encountersFinalized = 0,
    encounterSpawnRecords = 0,
    encounterFailureRecords = 0,
    ambusherCleanupTotal = 0,
    combatSoftlockCleanup = 0,
    unreachableJoinCleanup = 0,
    placementWatchdogDistanceStalled = 0,
    hostileRetryExhaustedCleanup = 0,

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

local EA_ENCOUNTER_SUMMARY_MAX = 12
local EA_ENCOUNTER_SPAWN_MAX = 24
local EA_ENCOUNTER_CLEANUP_MAX = 16

EnemyAmbush._eaEncounterSummaries = EnemyAmbush._eaEncounterSummaries or {}
EnemyAmbush._eaEncounterActiveById = EnemyAmbush._eaEncounterActiveById or {}
EnemyAmbush._eaEncounterActiveByAmbushId = EnemyAmbush._eaEncounterActiveByAmbushId or {}
EnemyAmbush._eaEncounterSummarySeq = tonumber(EnemyAmbush._eaEncounterSummarySeq) or 0

local function EA_DiagScalar(value)
    local valueType = type(value)
    if value == nil or valueType == "number" or valueType == "boolean" or valueType == "string" then
        return value
    end
    return tostring(value)
end

local function EA_DiagCopyFlat(source)
    local out = {}
    if type(source) ~= "table" then
        return out
    end
    for key, value in pairs(source) do
        local keyText = tostring(key or "")
        if keyText ~= "" then
            out[keyText] = EA_DiagScalar(value)
        end
    end
    return out
end

local function EA_DiagBump(bucket, key, amount)
    if type(bucket) ~= "table" then
        return
    end
    key = tostring(key or "")
    if key == "" then
        key = "(unknown)"
    end
    bucket[key] = (tonumber(bucket[key]) or 0) + (tonumber(amount) or 1)
end

local function EA_DiagGetRecord(recordId, ambushId)
    local byId = EnemyAmbush._eaEncounterActiveById
    if type(byId) == "table" and recordId and byId[tostring(recordId)] then
        return byId[tostring(recordId)]
    end

    local byAmbush = EnemyAmbush._eaEncounterActiveByAmbushId
    if type(byAmbush) == "table" and ambushId and ambushId ~= "" and byAmbush[tostring(ambushId)] then
        return byAmbush[tostring(ambushId)]
    end

    local active = EnemyAmbush._eaActiveEncounterSummary
    if type(active) == "table" and not recordId and not ambushId then
        return active
    end

    local summaries = EnemyAmbush._eaEncounterSummaries
    if type(summaries) == "table" then
        for i = #summaries, 1, -1 do
            local record = summaries[i]
            if type(record) == "table" then
                if recordId and tostring(record.id or "") == tostring(recordId) then
                    return record
                end
                if ambushId and ambushId ~= "" and tostring(record.ambushId or "") == tostring(ambushId) then
                    return record
                end
            end
        end
    end

    if type(active) == "table" then
        return active
    end

    return nil
end

local function EA_DiagPushFinalized(record)
    if type(record) ~= "table" then
        return
    end

    local summaries = EnemyAmbush._eaEncounterSummaries
    if type(summaries) ~= "table" then
        summaries = {}
        EnemyAmbush._eaEncounterSummaries = summaries
    end

    summaries[#summaries + 1] = record
    while #summaries > EA_ENCOUNTER_SUMMARY_MAX do
        table.remove(summaries, 1)
    end
end

local function EA_DiagNormalizeCleanupReason(reason)
    local token = tostring(reason or "unknown")
    if token == "SoftlockDelete" or token == "softlock" or token == "combat_softlock" then
        return "combat_softlock_cleanup"
    end
    if token == "DeferredJoinTimeout" or token == "NeverEnteredCombat" or token == "MissingEA_AMBUSHER" then
        return "unreachable_join_cleanup"
    end
    if token == "HostileRetriesExhausted" or token == "hostile_retries_exhausted" then
        return "hostile_retry_exhausted"
    end
    if token == "OOSJoinFailed" or token == "oos_join_failed" then
        return "oos_join_failed"
    end
    return token
end

local function EA_DiagMetricForCleanup(reason)
    if reason == "combat_softlock_cleanup" then
        return "combatSoftlockCleanup"
    end
    if reason == "unreachable_join_cleanup" then
        return "unreachableJoinCleanup"
    end
    if reason == "placement_watchdog_distance_stalled" then
        return "placementWatchdogDistanceStalled"
    end
    if reason == "hostile_retry_exhausted" or reason == "oos_join_failed" then
        return "hostileRetryExhaustedCleanup"
    end
    return nil
end

function EA_DiagBeginEncounter(context)
    context = (type(context) == "table") and context or {}
    EnemyAmbush._eaEncounterSummarySeq = (tonumber(EnemyAmbush._eaEncounterSummarySeq) or 0) + 1
    local seq = tonumber(EnemyAmbush._eaEncounterSummarySeq) or 1
    local recordId = tostring(context.recordId or context.id or string.format("encounter_%d", seq))
    local ambushId = tostring(context.ambushId or "")

    local lastRuntimeBlock = nil
    if type(EnemyAmbush._eaLastRuntimeBlock) == "table" then
        local ageMs = EA_EventTime() - (tonumber(EnemyAmbush._eaLastRuntimeBlock.atMs) or 0)
        if ageMs >= 0 and ageMs <= 30000 then
            lastRuntimeBlock = EA_DiagCopyFlat(EnemyAmbush._eaLastRuntimeBlock)
        end
    end

    local record = {
        id = recordId,
        seq = seq,
        state = "active",
        beginMs = EA_EventTime(),
        finalizedMs = nil,
        durationMs = nil,
        ambushId = (ambushId ~= "" and ambushId or nil),
        sourceFlow = tostring(context.sourceFlow or context.flowLabel or "unknown"),
        flowLabel = tostring(context.flowLabel or context.sourceFlow or "unknown"),
        character = EA_DiagScalar(context.character),
        isLongRest = context.isLongRest == true,
        region = tostring(context.region or ""),
        rawRegion = tostring(context.rawRegion or ""),
        partyLevel = tonumber(context.partyLevel) or nil,
        partySize = tonumber(context.partySize) or nil,
        rawPartySize = tonumber(context.rawPartySize) or nil,
        effectivePartySize = tonumber(context.effectivePartySize or context.partySize) or nil,
        realPartyMembers = tonumber(context.realPartyMembers) or nil,
        nonPlayerPartyMembers = tonumber(context.nonPlayerPartyMembers) or nil,
        summonFollowerBonus = tonumber(context.summonFollowerBonus) or nil,
        requestedTier = tostring(context.requestedTier or ""),
        requestedTheme = tostring(context.requestedTheme or ""),
        placementMode = tostring(context.placementMode or ""),
        baseBudget = tonumber(context.baseBudget) or nil,
        adjustedBudget = tonumber(context.adjustedBudget) or nil,
        intensity = tonumber(context.intensity) or nil,
        balanceProfile = tostring(context.balanceProfile or ""),
        preset = tostring(context.preset or ""),
        minEnemiesTarget = tonumber(context.minEnemiesTarget) or nil,
        entityCap = tonumber(context.entityCap) or nil,
        queueStep = context.queueStep == true,
        lastRuntimeReadyReason = tostring(context.lastRuntimeReadyReason or ""),
        lastRuntimeBlock = lastRuntimeBlock,
        spawned = {},
        spawnedCount = 0,
        spawnFailures = 0,
        cleanup = {},
        cleanupCounts = {},
        countsByTier = {},
        countsByCreatureType = {},
        countsByPowerClass = {},
        championCount = 0,
        retinueCount = 0,
        outcome = {},
    }

    EnemyAmbush._eaEncounterActiveById[recordId] = record
    if ambushId ~= "" then
        EnemyAmbush._eaEncounterActiveByAmbushId[ambushId] = record
    end
    EnemyAmbush._eaActiveEncounterSummary = record
    UpdateMetric("encountersBegun")
    EA_LogEvent("ENCOUNTER_BEGIN", "id=" .. recordId .. " ambushId=" .. tostring(ambushId) .. " flow=" .. tostring(record.flowLabel))
    return recordId
end

function EA_DiagRecordEncounterSpawn(recordId, info)
    info = (type(info) == "table") and info or {}
    local record = EA_DiagGetRecord(recordId or info.recordId, info.ambushId)
    if type(record) ~= "table" then
        return false
    end

    local entry = {
        ts = EA_EventTime(),
        enemy = EA_DiagScalar(info.enemy),
        name = tostring(info.name or "Unknown"),
        creatureType = tostring(info.creatureType or ""),
        tier = tostring(info.tier or ""),
        powerClass = tostring(info.powerClass or ""),
        spawnRole = tostring(info.spawnRole or ""),
        template = tostring(info.template or ""),
        spawnTemplate = tostring(info.spawnTemplate or ""),
        scaledLevel = tonumber(info.scaledLevel) or nil,
        templateLevel = tonumber(info.templateLevel) or nil,
        xpPct = tonumber(info.xpPct) or nil,
        noLoot = info.noLoot == true,
        isChampion = info.isChampion == true,
        isRetinue = info.isRetinue == true,
        placementSource = tostring(info.placementSource or ""),
        placementMode = tostring(info.placementMode or ""),
        spawnDistance2D = tonumber(info.spawnDistance2D) or nil,
        spawnHeightDelta = tonumber(info.spawnHeightDelta) or nil,
    }

    record.spawnedCount = (tonumber(record.spawnedCount) or 0) + 1
    if record.state == "finalized" then
        record.totalSpawned = tonumber(record.spawnedCount) or tonumber(record.totalSpawned) or 0
    end
    EA_DiagBump(record.countsByTier, entry.tier)
    EA_DiagBump(record.countsByCreatureType, entry.creatureType)
    EA_DiagBump(record.countsByPowerClass, entry.powerClass)
    if entry.isChampion then
        record.championCount = (tonumber(record.championCount) or 0) + 1
    end
    if entry.isRetinue then
        record.retinueCount = (tonumber(record.retinueCount) or 0) + 1
    end

    record.spawned[#record.spawned + 1] = entry
    while #record.spawned > EA_ENCOUNTER_SPAWN_MAX do
        table.remove(record.spawned, 1)
    end
    UpdateMetric("encounterSpawnRecords")
    return true
end

function EA_DiagRecordEncounterFailure(recordId, reason, info)
    info = (type(info) == "table") and info or {}
    local record = EA_DiagGetRecord(recordId or info.recordId, info.ambushId)
    if type(record) ~= "table" then
        return false
    end
    record.spawnFailures = (tonumber(record.spawnFailures) or 0) + 1
    record.lastFailureReason = tostring(reason or "unknown")
    record.lastFailure = EA_DiagCopyFlat(info)
    UpdateMetric("encounterFailureRecords")
    return true
end

function EA_DiagRecordOutcome(recordId, fields)
    local record = EA_DiagGetRecord(recordId, type(fields) == "table" and fields.ambushId or nil)
    if type(record) ~= "table" or type(fields) ~= "table" then
        return false
    end
    record.outcome = type(record.outcome) == "table" and record.outcome or {}
    local defeatedDelta = tonumber(fields.defeatedCountDelta)
    if defeatedDelta and defeatedDelta ~= 0 then
        record.outcome.defeatedCount = (tonumber(record.outcome.defeatedCount) or 0) + defeatedDelta
    end
    local escapedDelta = tonumber(fields.escapedCountDelta)
    if escapedDelta and escapedDelta ~= 0 then
        record.outcome.escapedCount = (tonumber(record.outcome.escapedCount) or 0) + escapedDelta
    end
    for key, value in pairs(fields) do
        if key ~= "defeatedCountDelta" and key ~= "escapedCountDelta" then
            record.outcome[tostring(key)] = EA_DiagScalar(value)
        end
    end
    return true
end

function EA_DiagRecordRuntimeBlock(reason, info)
    local token = tostring(reason or "unknown")
    info = (type(info) == "table") and info or {}
    local entry = EA_DiagCopyFlat(info)
    entry.reason = token
    entry.atMs = EA_EventTime()
    EnemyAmbush._eaLastRuntimeBlock = entry
    if token == "post_load_grace" then
        UpdateMetric("runtimePostLoadGraceBlocks")
    elseif token == "post_combat_grace" then
        UpdateMetric("runtimePostCombatGraceBlocks")
    elseif token == "dialog_or_cutscene" then
        UpdateMetric("runtimeDialogCutsceneBlocks")
    elseif token == "safe_zone_block" then
        UpdateMetric("runtimeSafeZoneBlocks")
    elseif token == "raw_safe_zone_block" then
        UpdateMetric("runtimeRawSafeZoneBlocks")
    end
    EA_LogEvent("RUNTIME_BLOCK", "reason=" .. token .. " stage=" .. tostring(info.stage or "unknown"))
    return true
end

function EA_DiagRecordCleanup(enemy, reason, info)
    local normalizedReason = EA_DiagNormalizeCleanupReason(reason)
    info = (type(info) == "table") and info or {}
    local record = EA_DiagGetRecord(info.recordId or info.diagRecordId, info.ambushId)
    local entry = {
        ts = EA_EventTime(),
        reason = normalizedReason,
        rawReason = tostring(reason or "unknown"),
        enemy = EA_DiagScalar(enemy or info.enemy),
        name = tostring(info.name or "Unknown"),
        creatureType = tostring(info.creatureType or ""),
        combatKey = tostring(info.combatKey or info._eaSoftlockCombatKey or ""),
        idleTurns = tonumber(info.idleTurns or info._eaSoftlockIdleTurns) or nil,
        distance2D = tonumber(info.distance2D) or nil,
    }

    UpdateMetric("ambusherCleanupTotal")
    local metric = EA_DiagMetricForCleanup(normalizedReason)
    if metric then
        UpdateMetric(metric)
    end

    EnemyAmbush._eaLastAmbusherCleanup = entry
    if type(record) == "table" then
        record.cleanup[#record.cleanup + 1] = entry
        while #record.cleanup > EA_ENCOUNTER_CLEANUP_MAX do
            table.remove(record.cleanup, 1)
        end
        EA_DiagBump(record.cleanupCounts, normalizedReason)
    end

    EA_LogEvent("AMBUSHER_CLEANUP", "reason=" .. normalizedReason .. " enemy=" .. tostring(enemy or info.enemy or ""))
    return true
end

function EA_DiagFinalizeEncounter(recordId, outcome)
    outcome = (type(outcome) == "table") and outcome or {}
    local record = EA_DiagGetRecord(recordId or outcome.recordId, outcome.ambushId)
    if type(record) ~= "table" then
        return false
    end

    if record.state == "finalized" then
        return true
    end

    for key, value in pairs(outcome) do
        record.outcome[tostring(key)] = EA_DiagScalar(value)
    end

    record.state = "finalized"
    record.finalizedMs = EA_EventTime()
    record.durationMs = math.max(0, record.finalizedMs - (tonumber(record.beginMs) or record.finalizedMs))
    record.totalSpawned = tonumber(outcome.totalSpawned) or tonumber(record.spawnedCount) or 0
    record.stopReason = tostring(outcome.stopReason or record.stopReason or "")

    if record.id and type(EnemyAmbush._eaEncounterActiveById) == "table" then
        EnemyAmbush._eaEncounterActiveById[tostring(record.id)] = nil
    end
    if record.ambushId and type(EnemyAmbush._eaEncounterActiveByAmbushId) == "table" then
        EnemyAmbush._eaEncounterActiveByAmbushId[tostring(record.ambushId)] = nil
    end
    if EnemyAmbush._eaActiveEncounterSummary == record then
        EnemyAmbush._eaActiveEncounterSummary = nil
    end

    EA_DiagPushFinalized(record)
    UpdateMetric("encountersFinalized")
    EA_LogEvent("ENCOUNTER_FINALIZE", "id=" .. tostring(record.id) .. " spawned=" .. tostring(record.totalSpawned) .. " reason=" .. tostring(record.stopReason))
    return true
end

function EA_GetLastEncounterSummary(includeActive)
    local summaries = EnemyAmbush._eaEncounterSummaries
    if type(summaries) == "table" and #summaries > 0 then
        return EA_P0Copy(summaries[#summaries])
    end
    if includeActive == true and type(EnemyAmbush._eaActiveEncounterSummary) == "table" then
        return EA_P0Copy(EnemyAmbush._eaActiveEncounterSummary)
    end
    return nil
end

local function EA_DiagFormatCounts(counts)
    if type(counts) ~= "table" then
        return "(none)"
    end
    local keys = {}
    for key, value in pairs(counts) do
        if tonumber(value) and tonumber(value) > 0 then
            keys[#keys + 1] = tostring(key)
        end
    end
    table.sort(keys)
    if #keys == 0 then
        return "(none)"
    end
    local parts = {}
    for _, key in ipairs(keys) do
        parts[#parts + 1] = string.format("%s=%s", key, tostring(counts[key]))
    end
    return table.concat(parts, ", ")
end

function EA_PrintLastEncounterSummary()
    local summary = EA_GetLastEncounterSummary(true)
    if type(summary) ~= "table" then
        print("[EnemyAmbush] Encounter summary: none recorded yet.")
        return false
    end

    print(string.format(
        "[EnemyAmbush] Encounter summary: id=%s state=%s ambushId=%s flow=%s region=%s raw=%s",
        tostring(summary.id or ""),
        tostring(summary.state or ""),
        tostring(summary.ambushId or ""),
        tostring(summary.flowLabel or summary.sourceFlow or ""),
        tostring(summary.region or ""),
        tostring(summary.rawRegion or "")
    ))
    print(string.format(
        "  partyLevel=%s partySize=%s tier=%s theme=%s budget=%s/%s target=%s cap=%s placement=%s",
        tostring(summary.partyLevel or ""),
        tostring(summary.partySize or ""),
        tostring(summary.requestedTier or ""),
        tostring(summary.requestedTheme or ""),
        tostring(summary.outcome and summary.outcome.totalCost or ""),
        tostring(summary.adjustedBudget or ""),
        tostring(summary.minEnemiesTarget or ""),
        tostring(summary.entityCap or ""),
        tostring(summary.placementMode or "")
    ))
    if summary.rawPartySize or summary.effectivePartySize or summary.nonPlayerPartyMembers then
        print(string.format(
            "  partyProfile: raw=%s effective=%s real=%s nonPlayer=%s summonBonus=%s",
            tostring(summary.rawPartySize or ""),
            tostring(summary.effectivePartySize or summary.partySize or ""),
            tostring(summary.realPartyMembers or ""),
            tostring(summary.nonPlayerPartyMembers or ""),
            tostring(summary.summonFollowerBonus or "")
        ))
    end
    print(string.format(
        "  spawned=%s failures=%s stopReason=%s runtimeBlock=%s",
        tostring(summary.totalSpawned or summary.spawnedCount or 0),
        tostring(summary.spawnFailures or 0),
        tostring(summary.stopReason or ""),
        tostring(summary.lastRuntimeReadyReason or "")
    ))
    if type(summary.outcome) == "table" then
        print(string.format(
            "  outcome: defeated=%s escaped=%s lastDefeat=%s lastEscaped=%s",
            tostring(summary.outcome.defeatedCount or 0),
            tostring(summary.outcome.escapedCount or 0),
            tostring(summary.outcome.lastDefeatKind or ""),
            tostring(summary.outcome.lastEscapedName or "")
        ))
    end
    print("  tiers: " .. EA_DiagFormatCounts(summary.countsByTier))
    print("  types: " .. EA_DiagFormatCounts(summary.countsByCreatureType))
    print("  power: " .. EA_DiagFormatCounts(summary.countsByPowerClass))

    if type(summary.lastRuntimeBlock) == "table" and summary.lastRuntimeBlock.reason then
        print(string.format(
            "  last runtime blocker: reason=%s stage=%s actor=%s source=%s remainingMs=%s",
            tostring(summary.lastRuntimeBlock.reason or ""),
            tostring(summary.lastRuntimeBlock.stage or ""),
            tostring(summary.lastRuntimeBlock.actor or ""),
            tostring(summary.lastRuntimeBlock.source or ""),
            tostring(summary.lastRuntimeBlock.remainingMs or "")
        ))
    end

    local spawned = type(summary.spawned) == "table" and summary.spawned or {}
    if #spawned == 0 then
        print("  spawned templates: (none)")
    else
        print("  spawned templates:")
        for i = 1, #spawned do
            local row = spawned[i]
            print(string.format(
                "    %d. %s type=%s tier=%s power=%s level=%s role=%s placement=%s dist=%s template=%s spawnTemplate=%s",
                i,
                tostring(row.name or "Unknown"),
                tostring(row.creatureType or ""),
                tostring(row.tier or ""),
                tostring(row.powerClass or ""),
                tostring(row.scaledLevel or ""),
                tostring(row.spawnRole or ""),
                tostring(row.placementSource or ""),
                tostring(row.spawnDistance2D or ""),
                tostring(row.template or ""),
                tostring(row.spawnTemplate or "")
            ))
        end
    end

    local cleanup = type(summary.cleanup) == "table" and summary.cleanup or {}
    if #cleanup > 0 then
        print("  cleanup: " .. EA_DiagFormatCounts(summary.cleanupCounts))
        for i = 1, #cleanup do
            local row = cleanup[i]
            print(string.format(
                "    %d. reason=%s enemy=%s name=%s type=%s distance=%s",
                i,
                tostring(row.reason or ""),
                tostring(row.enemy or ""),
                tostring(row.name or ""),
                tostring(row.creatureType or ""),
                tostring(row.distance2D or "")
            ))
        end
    end

    return true
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
    EnemyAmbush._eaEncounterSummaries = {}
    EnemyAmbush._eaEncounterActiveById = {}
    EnemyAmbush._eaEncounterActiveByAmbushId = {}
    EnemyAmbush._eaActiveEncounterSummary = nil
    EnemyAmbush._eaLastRuntimeBlock = nil
    EnemyAmbush._eaLastAmbusherCleanup = nil
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
