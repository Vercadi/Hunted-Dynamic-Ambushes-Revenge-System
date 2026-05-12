EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

-- TODO(post-1.0): split DebugCommands into smaller modules.
-- Deferred intentionally for this cycle; command-case scope keeps local-budget risk low.

local BuildActiveSummonList = EA["BuildActiveSummonList"]
local EA_GetPoolActiveSummonList = EA["EA_GetPoolActiveSummonList"]
local EA_GetPoolTemplateEntryById = EA["EA_GetPoolTemplateEntryById"]
local ExecuteAmbushSpawn = EA["ExecuteAmbushSpawn"]
local GetPointBudget = EA["GetPointBudget"]
local GetSafeLevel = EA["GetSafeLevel"]
local SpawnChampionNow = EA["SpawnChampionNow"]
local EA_ResolveChampionSpawnData = EA["EA_ResolveChampionSpawnData"]
local SpawnHostileNearPlayer = EA["SpawnHostileNearPlayer"]
local ThemeAllowsEnemy = EA["ThemeAllowsEnemy"]
local TriggerAmbush = EA["TriggerAmbush"]
local ValidateEnemyData = EA["ValidateEnemyData"]
local SaveReputation = EA["SaveReputation"]
local EA_CanSpawnChampionForType = EA["EA_CanSpawnChampionForType"]
local EA_ResetChampionCooldowns = EA["EA_ResetChampionCooldowns"]
local EA_SetChampionDiagnosticsMode = EA["EA_SetChampionDiagnosticsMode"]
local EA_GetChampionDiagnosticsMode = EA["EA_GetChampionDiagnosticsMode"]
local EA_SetChampionFallbackPolicyMode = EA["EA_SetChampionFallbackPolicyMode"]
local EA_GetChampionFallbackPolicyMode = EA["EA_GetChampionFallbackPolicyMode"]
local EA_GetChampionResolveTelemetrySnapshot = EA["EA_GetChampionResolveTelemetrySnapshot"]
local EA_SetDebugHasteAllAmbushers = EA["EA_SetDebugHasteAllAmbushers"]
local EA_IsDebugHasteAllAmbushers = EA["EA_IsDebugHasteAllAmbushers"]
local EA_DebugDescribePersistentHostileRetries = EA["EA_DebugDescribePersistentHostileRetries"]
local EA_DebugSchedulePersistentHostileRetry = EA["EA_DebugSchedulePersistentHostileRetry"]
local EA_DebugClearPersistentHostileRetries = EA["EA_DebugClearPersistentHostileRetries"]
local EA_ApplySettingsToLocals = EA["EA_ApplySettingsToLocals"]
local EA_MakeAmbushHostile = EA["EA_MakeAmbushHostile"]
local EA_RegisterTestSpawn = EA["EA_RegisterTestSpawn"]
local EA_NormalizeUUID = EA["EA_NormalizeUUID"]
local EA_Spawned = EA["EA_Spawned"]
local EA_Dirty = EA["EA_Dirty"]
local EA_RunScriptedScenarioById = EA["EA_RunScriptedScenarioById"]
local EA_ListScriptedScenarios = EA["EA_ListScriptedScenarios"]
local SafeGetPosition = EA["SafeGetPosition"]
local SafeOsiCall = EA["SafeOsiCall"]
local EA_GetGuaranteedChampionQueueSafeFn = EA["EA_GetGuaranteedChampionQueueSafe"]
local EA_GuaranteedChampionQueue = EA["EA_GuaranteedChampionQueue"]
local EA_GetGuaranteedChampionArmed = EA["EA_GetGuaranteedChampionArmed"]
local EA_GetLocationAppropriateEnemies = EA["EA_GetLocationAppropriateEnemies"]
local EA_WorldRepWindow = EA["EA_WorldRepWindow"]
local EA_NowMs = EA["EA_NowMs"]
local EA_PlaySoundEvent = EA["EA_PlaySoundEvent"]
local PlayVFX_OnEntity = EA["PlayVFX_OnEntity"]
local EA_GetCreatureReputationTable = EA["EA_GetCreatureReputationTable"]
local EA_GetReputationThresholds = EA["EA_GetReputationThresholds"]
local EA_PrintLastEncounterSummary = EA["EA_PrintLastEncounterSummary"]

local function _EA_ResolveFn(name, fallbackFn)
    local fn = EA and EA[name]
    if type(fn) == "function" then return fn end
    if type(fallbackFn) == "function" then return fallbackFn end
    return nil
end

local function EA_DebugGetAuthoredAmbushRuntime()
    local systemsModules = EA and EA.SystemsModules
    local runtime = type(systemsModules) == "table" and systemsModules.AuthoredAmbushRuntime or nil
    if type(runtime) == "table" then
        return runtime
    end
    return nil
end

local function EA_DebugResolveRunScriptedScenarioById()
    local runtime = EA_DebugGetAuthoredAmbushRuntime()
    local fn = type(runtime) == "table" and runtime.RunScriptedScenarioById or nil
    if type(fn) ~= "function" then
        fn = _EA_ResolveFn("EA_RunScriptedScenarioById", EA_RunScriptedScenarioById)
    end
    return type(fn) == "function" and fn or nil
end

local function EA_DebugResolveListScriptedScenarios()
    local runtime = EA_DebugGetAuthoredAmbushRuntime()
    local fn = type(runtime) == "table" and runtime.ListScriptedScenarios or nil
    if type(fn) ~= "function" then
        fn = _EA_ResolveFn("EA_ListScriptedScenarios", EA_ListScriptedScenarios)
    end
    return type(fn) == "function" and fn or nil
end

local function EA_DebugGetSettingRaw(settingId, fallback)
    local getOwnedSetting = EA and EA["EA_GetOwnedRuntimeSetting"]
    if type(getOwnedSetting) == "function" then
        local ok, out = pcall(getOwnedSetting, settingId)
        if ok and out ~= nil then
            return out
        end
    end

    local getSnapshotSetting = EA and EA["EA_GetSettingFromSnapshot"]
    if type(getSnapshotSetting) == "function" then
        local ok, out = pcall(getSnapshotSetting, settingId, fallback)
        if ok and out ~= nil then
            return out
        end
    end

    return fallback
end

local function EA_DebugGetSettingBool(settingId, fallback)
    return EA_DebugGetSettingRaw(settingId, fallback) == true
end

local function EA_DebugGetReputationTable()
    local getRepTable = _EA_ResolveFn("EA_GetCreatureReputationTable", EA_GetCreatureReputationTable)
    if type(getRepTable) == "function" then
        local ok, out = pcall(getRepTable)
        if ok and type(out) == "table" then
            return out
        end
    end
    EA.CreatureReputation = EA.CreatureReputation or {}
    return EA.CreatureReputation
end

local function EA_DebugGetReputationThresholds()
    local getThresholds = _EA_ResolveFn("EA_GetReputationThresholds", EA_GetReputationThresholds)
    if type(getThresholds) == "function" then
        local ok, out = pcall(getThresholds)
        if ok and type(out) == "table" then
            return out
        end
    end
    EA.ReputationThresholds = EA.ReputationThresholds or { WARY = -5, HOSTILE = -10, VENGEFUL = -20 }
    return EA.ReputationThresholds
end

local function EA_DebugGetChampionQueue()
    if type(EA_GetGuaranteedChampionQueueSafeFn) ~= "function" and EA and type(EA["EA_GetGuaranteedChampionQueueSafe"]) == "function" then
        EA_GetGuaranteedChampionQueueSafeFn = EA["EA_GetGuaranteedChampionQueueSafe"]
    end
    if type(EA_GetGuaranteedChampionQueueSafeFn) == "function" then
        local ok, out = pcall(EA_GetGuaranteedChampionQueueSafeFn)
        if ok and type(out) == "table" then
            return out
        end
    end
    if type(EA_GuaranteedChampionQueue) == "function" then
        local ok, out = pcall(EA_GuaranteedChampionQueue)
        if ok and type(out) == "table" then
            return out
        end
    end
    return {}
end

local CreatureReputation = EA_DebugGetReputationTable()
local REPUTATION_THRESHOLDS = EA_DebugGetReputationThresholds()
local EA_PROVIDER_PROBE_ID = "ea_debug_provider_probe"
local EA_PROVIDER_PROBE_TEMPLATE = "2db928f2-f1c5-4b5a-8751-168f9f292249"
local EA_PROVIDER_PROBE_STATUS_A = "EA_DEBUG_PROVIDER_PROBE_A"
local EA_PROVIDER_PROBE_STATUS_B = "EA_DEBUG_PROVIDER_PROBE_B"
local EA_PROVIDER_PROBE_NAME_A = "EA Provider Probe A"
local EA_PROVIDER_PROBE_NAME_B = "EA Provider Probe B"
local EA_AUTHORED_API_PROBE_ID = "ea_debug_authored_probe"
local EA_AUTHORED_API_INVALID_PROBE_ID = "ea_debug_authored_probe_invalid"
local EA_AUTHORED_API_TRIGGER_PROBE_ID = "ea_debug_authored_trigger_probe"
local EA_AUTHORED_API_TRIGGER_UNKNOWN_ID = "ea_debug_authored_trigger_probe_missing"

local EA_TEST_VFX_DIMENSION_DOOR_DISAPPEAR = "b214ce9c-33c2-4dfc-bfc2-3af8e4124714"
local EA_TEST_VFX_MISTY_STEP_CAST = "71859b27-bdda-44c3-8c65-7f142a1a2f60"
local EA_TEST_SFX_STINGER = "Set_06_Fight_Stinger_04"
local EA_TEST_SFX_SILENT = "VFX_Sound_Spell_Impact_Silent"

local EA_TEST_VFX_ALIASES = {
    dimdoor = EA_TEST_VFX_DIMENSION_DOOR_DISAPPEAR,
    dimensiondoor = EA_TEST_VFX_DIMENSION_DOOR_DISAPPEAR,
    teleport = EA_TEST_VFX_DIMENSION_DOOR_DISAPPEAR,
    disappear = EA_TEST_VFX_DIMENSION_DOOR_DISAPPEAR,
    misty = EA_TEST_VFX_MISTY_STEP_CAST,
    mistystep = EA_TEST_VFX_MISTY_STEP_CAST,
    mistycast = EA_TEST_VFX_MISTY_STEP_CAST,
    cast = EA_TEST_VFX_MISTY_STEP_CAST,
}

local EA_TEST_SFX_ALIASES = {
    stinger = EA_TEST_SFX_STINGER,
    dark = "Set_07_Explo_Glob_dark_Stinger_01",
    psy = "Set_01_Explo_Stinger_psy_06",
    silent = EA_TEST_SFX_SILENT,
}

local EA_RegionWatchEnabled = false
local EA_RegionWatchIntervalMs = 30000
local EA_RegionWatchLastRaw = nil
local EA_RegionWatchLastCanonical = nil
local EA_RegionWatchLastSafeZones = nil
local EA_RegionWatchLastTriggerBlocked = nil

local function EA_DebugRobustEnabled()
    local fn = EA and EA["EA_IsRobust"]
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok then return out == true end
    end
    return EA_DebugGetSettingBool("MCM_RobustMode", false)
end

local function EA_SetDebugTelemetryEnabled(enabled)
    EnemyAmbush._eaDebugTelemetry = (enabled == true)
    if EnemyAmbush._eaDebugTelemetry then
        print("[EnemyAmbush] Debug telemetry enabled (event printing + auto-dump).")
    else
        print("[EnemyAmbush] Debug telemetry disabled.")
    end
end

local function EA_PrintTelemetrySummary()
    local robustMode = EA_DebugRobustEnabled()
    local enabled = false
    if type(EA_DebugTelemetryEnabled) == "function" then
        local ok, out = pcall(EA_DebugTelemetryEnabled)
        enabled = ok and out == true
    else
        enabled = EnemyAmbush._eaDebugTelemetry == true or robustMode
    end

    print(string.format("[EnemyAmbush] Telemetry: enabled=%s robustMode=%s", tostring(enabled), tostring(robustMode)))
    if type(GetMetricsSummary) == "function" then
        local ok, summary = pcall(GetMetricsSummary)
        if ok and summary then
            print(tostring(summary))
        end
    end
end

local function EA_TryReadObjectField(obj, fieldNames)
    if obj == nil or type(fieldNames) ~= "table" then
        return nil, nil
    end
    for _, fieldName in ipairs(fieldNames) do
        if type(fieldName) == "string" and fieldName ~= "" then
            local ok, value = pcall(function()
                return obj[fieldName]
            end)
            if ok and value ~= nil then
                local valueText = tostring(value)
                if valueText ~= "" and valueText ~= "nil" then
                    return valueText, fieldName
                end
            end
        end
    end
    return nil, nil
end

local function EA_CollectXPCloneSourceRows()
    local EnemyData = (EA and EA.EnemyData) or {}
    local templates = {}

    local function addRow(entry, sourceKind)
        if type(entry) ~= "table" or not entry.template or entry.template == "" then
            return
        end
        local templateId = EA_NormalizeUUID(entry.template)
        if not templateId or templateId == "" then
            return
        end

        local row = templates[templateId]
        if type(row) ~= "table" then
            row = {
                originalTemplate = templateId,
                sourceName = tostring(entry.name or ""),
                creatureType = tostring(entry.creatureType or ""),
                levelHint = tonumber(entry.resolvedTemplateLevel or entry.level) or nil,
                championSource = false,
                summonSource = false,
            }
            templates[templateId] = row
        end

        if row.sourceName == "" and entry.name then
            row.sourceName = tostring(entry.name)
        end
        if row.creatureType == "" and entry.creatureType then
            row.creatureType = tostring(entry.creatureType)
        end
        if row.levelHint == nil then
            row.levelHint = tonumber(entry.resolvedTemplateLevel or entry.level) or nil
        end
        if sourceKind == "champion" then
            row.championSource = true
        else
            row.summonSource = true
        end
    end

    for _, entry in ipairs(EnemyData.SummonList_Vanilla or {}) do
        addRow(entry, "summon")
    end
    for _, entry in ipairs(EnemyData.ChampionList_Vanilla or {}) do
        addRow(entry, "champion")
    end

    return templates
end

local function EA_ExportXPCloneSourceData()
    if not (Ext and Ext.Template and type(Ext.Template.GetRootTemplate) == "function") then
        return false, "template_api_unavailable"
    end
    if not (Ext and Ext.IO and type(Ext.IO.SaveFile) == "function" and Ext.Json and type(Ext.Json.Stringify) == "function") then
        return false, "io_unavailable"
    end

    local rows = EA_CollectXPCloneSourceRows()
    local orderedTemplates = {}
    for templateId, _ in pairs(rows or {}) do
        orderedTemplates[#orderedTemplates + 1] = templateId
    end
    table.sort(orderedTemplates)

    local snapshot = {
        exportedAtMs = EA_NowMs(),
        source = "ea_test xpclones export",
        templateCount = #orderedTemplates,
        resolvedCount = 0,
        missingTemplateCount = 0,
        missingStatsCount = 0,
        templates = {},
        missingTemplates = {},
        missingStats = {},
    }

    for _, templateId in ipairs(orderedTemplates) do
        local row = rows[templateId]
        local okTemplate, tmpl = pcall(Ext.Template.GetRootTemplate, templateId)
        if not okTemplate or tmpl == nil then
            snapshot.missingTemplateCount = snapshot.missingTemplateCount + 1
            snapshot.missingTemplates[#snapshot.missingTemplates + 1] = templateId
            snapshot.templates[templateId] = {
                originalTemplate = templateId,
                sourceName = tostring(row.sourceName or ""),
                creatureType = tostring(row.creatureType or ""),
                levelHint = tonumber(row.levelHint) or nil,
                championSource = (row.championSource == true),
                summonSource = (row.summonSource == true),
                templateResolved = false,
                originalStat = nil,
            }
        else
            local originalStat, statField = EA_TryReadObjectField(tmpl, { "Stats", "StatsId", "StatsEntry", "StatsName" })
            local templateName, nameField = EA_TryReadObjectField(tmpl, { "Name", "DisplayName" })
            local parentTemplateId, parentField = EA_TryReadObjectField(tmpl, { "ParentTemplateId", "ParentTemplate" })
            local rootType, typeField = EA_TryReadObjectField(tmpl, { "Type" })

            if not originalStat or originalStat == "" then
                snapshot.missingStatsCount = snapshot.missingStatsCount + 1
                snapshot.missingStats[#snapshot.missingStats + 1] = templateId
            else
                snapshot.resolvedCount = snapshot.resolvedCount + 1
            end

            snapshot.templates[templateId] = {
                originalTemplate = templateId,
                sourceName = tostring(row.sourceName or ""),
                creatureType = tostring(row.creatureType or ""),
                levelHint = tonumber(row.levelHint) or nil,
                championSource = (row.championSource == true),
                summonSource = (row.summonSource == true),
                templateResolved = true,
                originalStat = originalStat,
                statField = statField,
                templateName = templateName,
                templateNameField = nameField,
                parentTemplateId = parentTemplateId,
                parentTemplateField = parentField,
                rootType = rootType,
                rootTypeField = typeField,
            }
        end
    end

    local ts = tostring(math.floor(tonumber(snapshot.exportedAtMs) or 0))
    local relPath = "Hunted_DynamicAmbushes_Revenge_System/xpclone_source_" .. ts .. ".json"
    local okJson, json = pcall(Ext.Json.Stringify, snapshot, { Beautify = true })
    if not okJson or type(json) ~= "string" then
        return false, "json_failed"
    end
    local okSave, saved = pcall(Ext.IO.SaveFile, relPath, json)
    if not okSave or saved ~= true then
        return false, "save_failed"
    end

    EnemyAmbush._XPCloneSourceExportLastPath = relPath
    EnemyAmbush._XPCloneSourceExportLastSnapshot = snapshot
    return true, relPath, snapshot
end

local function EA_PrintReadinessDiagnostics()
    local modVarsReadyFn = EA_ModVarsReady or (EA and EA["EA_ModVarsReady"])
    local modVarsDiagFn = EA_GetModVarsReadyDiagnostics or (EA and EA["EA_GetModVarsReadyDiagnostics"])
    local gameTimeFn = EA_GameTimeMs or (EA and EA["EA_GameTimeMs"])
    local gameTimeDiagFn = EA_GetGameTimeDiagnostics or (EA and EA["EA_GetGameTimeDiagnostics"])
    local persistedFn = EA_PersistedNowMs or (EA and EA["EA_PersistedNowMs"])
    local persistedPolicyFn = EA_GetPersistedTimePolicy or (EA and EA["EA_GetPersistedTimePolicy"])

    local modReady = false
    if type(modVarsReadyFn) == "function" then
        local ok, out = pcall(modVarsReadyFn)
        modReady = ok and out == true
    end

    local gameNow = nil
    if type(gameTimeFn) == "function" then
        local ok, out = pcall(gameTimeFn)
        if ok then
            gameNow = tonumber(out)
        end
    end

    local persistedNow = nil
    if type(persistedFn) == "function" then
        local ok, out = pcall(persistedFn)
        if ok then
            persistedNow = tonumber(out)
        end
    end

    print(string.format(
        "[EnemyAmbush] Readiness: EA_ModVarsReady=%s ready=%s EA_GameTimeMs=%s gameNow=%s EA_PersistedNowMs=%s persistedNow=%s",
        tostring(type(modVarsReadyFn) == "function"),
        tostring(modReady),
        tostring(type(gameTimeFn) == "function"),
        tostring(gameNow),
        tostring(type(persistedFn) == "function"),
        tostring(persistedNow)
    ))

    if type(modVarsDiagFn) == "function" then
        local ok, diag = pcall(modVarsDiagFn)
        if ok and type(diag) == "table" then
            print(string.format(
                "[EnemyAmbush] ModVarsDiag: reason=%s detail=%s running=%s failures=%s updatedAt=%s",
                tostring(diag.reason or ""),
                tostring(diag.detail or ""),
                tostring(diag.running),
                tostring(diag.failures or 0),
                tostring(diag.updatedAt or 0)
            ))
        end
    end

    if type(gameTimeDiagFn) == "function" then
        local ok, diag = pcall(gameTimeDiagFn)
        if ok and type(diag) == "table" then
            print(string.format(
                "[EnemyAmbush] GameTimeDiag: reason=%s detail=%s rawType=%s failures=%s updatedAt=%s",
                tostring(diag.reason or ""),
                tostring(diag.detail or ""),
                tostring(diag.rawType or ""),
                tostring(diag.failures or 0),
                tostring(diag.updatedAt or 0)
            ))
        end
    end

    if type(persistedPolicyFn) == "function" then
        local ok, policy = pcall(persistedPolicyFn)
        if ok and type(policy) == "table" then
            print(string.format(
                "[EnemyAmbush] PersistedTimePolicy: mode=%s policy=%s source=%s gameTimeProbeOnly=%s",
                tostring(policy.mode or ""),
                tostring(policy.policy or ""),
                tostring(policy.persistedSource or ""),
                tostring(policy.gameTimeProbeOnly == true)
            ))
        end
    end

end

local function EA_CollectNumberLeaves(prefix, bucket, out)
    if type(bucket) ~= "table" then
        return
    end
    for k, v in pairs(bucket) do
        local key = tostring(k)
        if type(v) == "number" then
            out[#out + 1] = {
                key = tostring(prefix) .. key,
                value = v,
            }
        elseif type(v) == "table" then
            EA_CollectNumberLeaves(tostring(prefix) .. key .. ".", v, out)
        end
    end
end

local function EA_PrintNumberBucket(prefix, bucket)
    local rows = {}
    EA_CollectNumberLeaves(prefix, bucket, rows)
    if #rows == 0 then
        print(string.format("%s (none)", tostring(prefix)))
        return
    end
    table.sort(rows, function(a, b)
        return tostring(a.key or "") < tostring(b.key or "")
    end)
    for _, row in ipairs(rows) do
        print(string.format("%s=%s", tostring(row.key), tostring(row.value)))
    end
end

local function EA_PrintPhase0Summary()
    local getSummaryFn = EA and EA["EA_GetPhase0Summary"]
    local getStatsFn = EA and EA["EA_GetPhase0Stats"]
    if type(getSummaryFn) ~= "function" then
        print("[EnemyAmbush] phase0 unavailable (EA_GetPhase0Summary missing).")
        return
    end

    local okSummary, summary = pcall(getSummaryFn)
    if not okSummary or type(summary) ~= "table" then
        print(string.format("[EnemyAmbush] phase0 read failed: %s", tostring(summary)))
        return
    end

    print(string.format(
        "[EnemyAmbush] Phase0: enabled=%s mode=%s verbose=%s noteCount=%s",
        tostring(summary.enabled == true),
        tostring(summary.mode or "count_only"),
        tostring(summary.verbose == true),
        tostring(summary.noteCount or 0)
    ))

    local session = summary.session or {}
    print(string.format(
        "[EnemyAmbush] Phase0 session: bootCount=%s sessionLoadedCount=%s lastSessionLoadedAtMs=%s markerCount=%s",
        tostring(session.bootCount or 0),
        tostring(session.sessionLoadedCount or 0),
        tostring(session.lastSessionLoadedAtMs or 0),
        tostring(session.markerCount or 0)
    ))

    EA_PrintNumberBucket("[EnemyAmbush][P0] listenerReg.", summary.listenerReg)
    EA_PrintNumberBucket("[EnemyAmbush][P0] listenerRegGuard.", summary.listenerRegGuard)

    local duplicates = summary.duplicateRegistrationCallsites or {}
    if type(duplicates) == "table" and #duplicates > 0 then
        print("[EnemyAmbush] Phase0 duplicate registration callsites: " .. table.concat(duplicates, ", "))
    else
        print("[EnemyAmbush] Phase0 duplicate registration callsites: (none)")
    end

    if type(getStatsFn) ~= "function" then
        return
    end
    local okStats, stats = pcall(getStatsFn)
    if not okStats or type(stats) ~= "table" or type(stats.session) ~= "table" or type(stats.session.markers) ~= "table" then
        return
    end

    EA_PrintNumberBucket("[EnemyAmbush][P0] listenerExec.", stats.listenerExec)
    EA_PrintNumberBucket("[EnemyAmbush][P0] timerExec.", stats.timerExec)
    EA_PrintNumberBucket("[EnemyAmbush][P0] killedBy.", stats.killedBy)
    EA_PrintNumberBucket("[EnemyAmbush][P0] enterCombat.", stats.enterCombat)
    EA_PrintNumberBucket("[EnemyAmbush][P0] readiness.", stats.readiness)

    local markers = stats.session.markers
    if #markers == 0 then
        print("[EnemyAmbush] Phase0 session markers: (none)")
        return
    end

    print("[EnemyAmbush] Phase0 session markers (newest last):")
    for i = math.max(1, #markers - 5), #markers do
        local marker = markers[i]
        if type(marker) == "table" then
            print(string.format(
                "[EnemyAmbush][P0] marker[%d]: kind=%s atMs=%s",
                i,
                tostring(marker.kind or ""),
                tostring(marker.atMs or 0)
            ))
        else
            print(string.format("[EnemyAmbush][P0] marker[%d]: %s", i, tostring(marker)))
        end
    end
end

local function EA_PrintPersistentHostileRetrySnapshot(snapshot, label)
    if type(snapshot) ~= "table" then
        print(string.format("[EnemyAmbush] %s unavailable (invalid payload).", tostring(label or "hostileretry")))
        return
    end
    local entries = snapshot.entries
    if type(entries) ~= "table" then
        entries = {}
    end
    print(string.format(
        "[EnemyAmbush] %s: count=%s",
        tostring(label or "hostileretry"),
        tostring(snapshot.count or #entries)
    ))
    if #entries <= 0 then
        print("  (none)")
        return
    end
    for _, row in ipairs(entries) do
        print(string.format(
            "  timer=%s enemy=%s player=%s tries=%s reason=%s delayMs=%s enqueuedAt=%s",
            tostring(row.timerId or ""),
            tostring(row.enemy or ""),
            tostring(row.player or ""),
            tostring(row.tries or 0),
            tostring(row.reason or ""),
            tostring(row.delayMs or 0),
            tostring(row.enqueuedAt or 0)
        ))
    end
end

local function EA_PrintRestStats(stats)
    if type(stats) ~= "table" then
        print("[EnemyAmbush] reststats unavailable.")
        return
    end
    print(string.format(
        "[EnemyAmbush] RestStats: sessionStart=%s updated=%s",
        tostring(stats.sessionStartedAtMs or 0),
        tostring(stats.updatedAtMs or 0)
    ))
    EA_PrintNumberBucket("  short.", stats.short)
    EA_PrintNumberBucket("  long.", stats.long)
    if type(stats.lastRoll) == "table" then
        print(string.format(
            "  lastRoll: kind=%s roll=%s chance=%s forced=%s passed=%s char=%s at=%s",
            tostring(stats.lastRoll.kind or ""),
            tostring(stats.lastRoll.roll or ""),
            tostring(stats.lastRoll.chance or ""),
            tostring(stats.lastRoll.forced == true),
            tostring(stats.lastRoll.passed == true),
            tostring(stats.lastRoll.character or ""),
            tostring(stats.lastRoll.atMs or 0)
        ))
    end
    if type(stats.lastSpawn) == "table" then
        print(string.format(
            "  lastSpawn: kind=%s spawned=%s char=%s at=%s",
            tostring(stats.lastSpawn.kind or ""),
            tostring(stats.lastSpawn.spawnedCount or 0),
            tostring(stats.lastSpawn.character or ""),
            tostring(stats.lastSpawn.atMs or 0)
        ))
    end
    if stats.lastExportPath then
        print(string.format("  lastExportPath=%s", tostring(stats.lastExportPath)))
    end
end

local function EA_PrintRepStats(stats)
    if type(stats) ~= "table" then
        print("[EnemyAmbush] repstats unavailable.")
        return
    end
    print(string.format(
        "[EnemyAmbush] RepStats: sessionStart=%s updated=%s kills=%s championResets=%s capBlocked=%s delta(total=%s neg=%s pos=%s) combat(in=%s out=%s)",
        tostring(stats.sessionStartedAtMs or 0),
        tostring(stats.updatedAtMs or 0),
        tostring(stats.totalKillsTracked or 0),
        tostring(stats.championResets or 0),
        tostring(stats.capBlocked or 0),
        tostring(stats.totalRepDelta or 0),
        tostring(stats.negativeDelta or 0),
        tostring(stats.positiveDelta or 0),
        tostring(stats.inCombatKills or 0),
        tostring(stats.outOfCombatKills or 0)
    ))
    local byType = stats.byType
    if type(byType) == "table" then
        local keys = {}
        for ct, _ in pairs(byType) do
            keys[#keys + 1] = tostring(ct)
        end
        table.sort(keys)
        for _, ct in ipairs(keys) do
            local row = byType[ct]
            if type(row) == "table" then
                print(string.format(
                    "  byType.%s kills=%s champResets=%s capBlocked=%s delta=%s neg=%s pos=%s",
                    tostring(ct),
                    tostring(row.kills or 0),
                    tostring(row.championResets or 0),
                    tostring(row.capBlocked or 0),
                    tostring(row.repDelta or 0),
                    tostring(row.negativeDelta or 0),
                    tostring(row.positiveDelta or 0)
                ))
            end
        end
    end
    if type(stats.last) == "table" then
        print(string.format(
            "  last: type=%s old=%s new=%s change=%s champion=%s capBlocked=%s inCombat=%s at=%s",
            tostring(stats.last.creatureType or ""),
            tostring(stats.last.oldRep or ""),
            tostring(stats.last.newRep or ""),
            tostring(stats.last.repChange or ""),
            tostring(stats.last.championReset == true),
            tostring(stats.last.capBlocked == true),
            tostring(stats.last.inCombat == true),
            tostring(stats.last.atMs or 0)
        ))
    end
    if stats.lastExportPath then
        print(string.format("  lastExportPath=%s", tostring(stats.lastExportPath)))
    end
end

local function EA_PrintRegionDebug(character, forcePrint)
    if not character or character == "" then
        print("[EnemyAmbush][RegionDebug] No character provided")
        return
    end

    local getRegionFn = EA and EA["EA_GetRegionForCharacter"]
    local getSafeZoneFn = EA and EA["EA_GetSafeZoneState"]
    local isRawBlockedFn = EA and EA["EA_IsRawRegionBlocked"]
    local isRegionBlockedFn = EA and EA["EA_IsRegionBlocked"]
    local safeFn = EA and EA["IsSafeToSpawnAmbush"]

    local canonical = nil
    local raw = nil
    if type(getRegionFn) == "function" then
        local ok, a, b = pcall(getRegionFn, character)
        if ok then
            canonical = a
            raw = b
        end
    end

    if (not raw or raw == "") and Osi and Osi.GetRegion then
        local ok, out = pcall(Osi.GetRegion, character)
        if ok then raw = out end
    end

    local safeZoneState = nil
    if type(getSafeZoneFn) == "function" then
        local ok, out = pcall(getSafeZoneFn, character)
        if ok and type(out) == "table" then
            safeZoneState = out
        end
    end
    safeZoneState = safeZoneState or { activeZones = {}, triggerBlocked = false }

    raw = tostring(raw or "")
    canonical = tostring(canonical or raw or "")
    if canonical == "" then canonical = "UNKNOWN" end
    if raw == "" then raw = "UNKNOWN" end

    local rawBlocked = false
    if type(isRawBlockedFn) == "function" then
        local ok, out = pcall(isRawBlockedFn, raw)
        rawBlocked = (ok and out == true) or false
    end

    local canonicalBlocked = false
    if type(isRegionBlockedFn) == "function" then
        local ok, out = pcall(isRegionBlockedFn, canonical)
        canonicalBlocked = (ok and out == true) or false
    end

    local safe = nil
    if type(safeFn) == "function" then
        local ok, out = pcall(safeFn, character)
        if ok then safe = (out == true) end
    end

    local activeSafeZones = table.concat(safeZoneState.activeZones or {}, ", ")
    if activeSafeZones == "" then
        activeSafeZones = "(none)"
    end
    local triggerBlocked = (safeZoneState.triggerBlocked == true)

    local changed =
        (EA_RegionWatchLastRaw ~= raw)
        or (EA_RegionWatchLastCanonical ~= canonical)
        or (EA_RegionWatchLastSafeZones ~= activeSafeZones)
        or (EA_RegionWatchLastTriggerBlocked ~= triggerBlocked)
    if forcePrint == true or changed then
        print(string.format(
            "[EnemyAmbush][RegionDebug] char=%s rawRegion=%s canonical=%s activeSafeZones=%s triggerBlocked=%s rawBlocked=%s canonicalBlocked=%s ambushAllowed=%s",
            tostring(character),
            tostring(raw),
            tostring(canonical),
            tostring(activeSafeZones),
            tostring(triggerBlocked),
            tostring(rawBlocked),
            tostring(canonicalBlocked),
            tostring(safe)
        ))
    end

    EA_RegionWatchLastRaw = raw
    EA_RegionWatchLastCanonical = canonical
    EA_RegionWatchLastSafeZones = activeSafeZones
    EA_RegionWatchLastTriggerBlocked = triggerBlocked
end

local function EA_RegionWatchTick()
    if not EA_RegionWatchEnabled then
        return
    end

    local host = (Osi and Osi.GetHostCharacter) and Osi.GetHostCharacter() or nil
    if host and host ~= "" then
        EA_PrintRegionDebug(host, false)
    end

    if Ext and Ext.Timer and Ext.Timer.WaitFor then
        Ext.Timer.WaitFor(EA_RegionWatchIntervalMs, EA_RegionWatchTick)
    end
end

local function EA_GuidLooksValid(g)
    if type(g) ~= "string" then return false end
    local a, b, c, d, e = g:match("^([%x]+)%-([%x]+)%-([%x]+)%-([%x]+)%-([%x]+)$")
    if not a then return false end
    return (#a == 8 and #b == 4 and #c == 4 and #d == 4 and #e == 12)
end

local function EA_GetSpawnedDataCompat(uuid)
    if not uuid or uuid == "" then return nil end
    local spawned = (type(EA_Spawned) == "function") and EA_Spawned() or nil
    if type(spawned) ~= "table" and type(spawned) ~= "userdata" then return nil end
    local norm = (EA_NormalizeUUID and EA_NormalizeUUID(uuid)) or uuid
    return spawned[norm] or spawned[uuid]
end

local function EA_ResolveVFXInput(raw)
    local src = tostring(raw or "")
    if src == "" then return nil end
    local alias = EA_TEST_VFX_ALIASES[string.lower(src)]
    return alias or src
end

local function EA_ResolveSFXInput(raw)
    local src = tostring(raw or "")
    if src == "" then return nil end
    local alias = EA_TEST_SFX_ALIASES[string.lower(src)]
    return alias or src
end

local function EA_FindAnyTrackedAmbusher()
    local spawned = (type(EA_Spawned) == "function") and EA_Spawned() or nil
    if type(spawned) ~= "table" and type(spawned) ~= "userdata" then
        return nil
    end
    for guid, data in pairs(spawned) do
        if guid and guid ~= "" and (type(data) == "table" or type(data) == "userdata") then
            local exists = true
            if Osi and Osi.ObjectExists then
                local okExists, outExists = pcall(Osi.ObjectExists, guid)
                exists = okExists and tonumber(outExists) == 1
            end
            local isPlayer = false
            if Osi and Osi.IsPlayer then
                local okPlayer, outPlayer = pcall(Osi.IsPlayer, guid)
                isPlayer = okPlayer and tonumber(outPlayer) == 1
            end
            if exists and not isPlayer then
                return guid
            end
        end
    end
    return nil
end

local function EA_CreateNeutralTestSpawnByGuid(player, guid)
    if not player or player == "" then
        return nil, "no_host_character"
    end

    local x, y, z = SafeGetPosition(player)
    if not x or not y or not z then
        return nil, "no_player_position"
    end

    local angle = math.random() * 2 * math.pi
    local spawnX = x + math.cos(angle) * 3
    local spawnZ = z + math.sin(angle) * 3

    local ok, enemy = pcall(Osi.CreateAt, guid, spawnX, y, spawnZ, 1, 1, "")
    if not ok or not enemy or enemy == "" then
        return nil, "createat_failed"
    end

    if Osi.ClearOwnership then
        pcall(Osi.ClearOwnership, enemy)
    elseif EA_DebugGetSettingBool("MCM_DebugMode", false) and not EnemyAmbush._eaClearOwnershipMissingLogged then
        EnemyAmbush._eaClearOwnershipMissingLogged = true
        print("[EnemyAmbush][Debug] ClearOwnership unavailable; using MakeNPC fallback only.")
    end

    if Osi.MakeNPC then
        pcall(Osi.MakeNPC, enemy)
    end
    if Osi.SetCanFight then
        pcall(Osi.SetCanFight, enemy, 1)
    end
    if Osi.SetCanJoinCombat then
        pcall(Osi.SetCanJoinCombat, enemy, 1)
    end

    if EA_RegisterTestSpawn then
        EA_RegisterTestSpawn(enemy)
    end

    return enemy, nil
end

local function EA_ResolveFXTarget(rawTarget, hostPlayer)
    local src = tostring(rawTarget or "")
    local key = string.lower(src)
    if key == "" or key == "player" or key == "host" or key == "me" then
        return hostPlayer
    end
    if key == "last" or key == "ambusher" or key == "spawned" then
        local tracked = EA_FindAnyTrackedAmbusher()
        if tracked and tracked ~= "" then
            return tracked
        end
        return hostPlayer
    end

    local norm = (type(EA_NormalizeUUID) == "function") and EA_NormalizeUUID(src) or src
    if Osi and Osi.ObjectExists then
        local okNorm, outNorm = pcall(Osi.ObjectExists, norm)
        if okNorm and tonumber(outNorm) == 1 then
            return norm
        end
        local okRaw, outRaw = pcall(Osi.ObjectExists, src)
        if okRaw and tonumber(outRaw) == 1 then
            return src
        end
        return nil
    end
    return norm
end

local function EA_TestPlayVFX(target, effect)
    if not target or target == "" or not effect or effect == "" then
        return false
    end
    if type(PlayVFX_OnEntity) == "function" then
        local ok = pcall(PlayVFX_OnEntity, target, effect)
        if ok then return true end
    end
    if Osi and Osi.PlayEffect then
        local ok = pcall(Osi.PlayEffect, target, effect, "", 1.0)
        if ok then return true end
    end
    return false
end

local function EA_TestPlaySFX(target, soundId)
    if not target or target == "" or not soundId or soundId == "" then
        return false
    end
    if type(EA_PlaySoundEvent) == "function" then
        local ok = pcall(EA_PlaySoundEvent, soundId, target)
        if ok then return true end
    end
    if Osi and Osi.PlaySound then
        local ok = pcall(Osi.PlaySound, target, soundId)
        if ok then return true end
    end
    return false
end

local function EA_TestDebugText(target, text)
    if not target or target == "" or not text or text == "" then
        return false
    end
    if not (Osi and Osi.DebugText) then
        return false
    end
    local ok = pcall(Osi.DebugText, target, text)
    return ok == true
end

local EA_FleeFromDebugWatch = EA_FleeFromDebugWatch or {}

local function EA_WatchFleeTarget(target)
    if not target or target == "" then
        return
    end
    local norm = (type(EA_NormalizeUUID) == "function") and EA_NormalizeUUID(target) or target
    EA_FleeFromDebugWatch[norm] = true
    EA_FleeFromDebugWatch[target] = true
end

local function EA_ClearFleeWatch(target)
    if not target or target == "" then
        return
    end
    local norm = (type(EA_NormalizeUUID) == "function") and EA_NormalizeUUID(target) or target
    EA_FleeFromDebugWatch[norm] = nil
    EA_FleeFromDebugWatch[target] = nil
end

local function EA_IsWatchedFleeTarget(target)
    if not target or target == "" then
        return false
    end
    local norm = (type(EA_NormalizeUUID) == "function") and EA_NormalizeUUID(target) or target
    return EA_FleeFromDebugWatch[norm] == true or EA_FleeFromDebugWatch[target] == true
end

local function EA_TestApplyStatus(target, statusId, durationSeconds)
    if not target or target == "" or not statusId or statusId == "" then
        return false
    end
    local duration = tonumber(durationSeconds) or 6
    if duration <= 0 then
        duration = 6
    end
    if type(SafeApplyStatus) == "function" then
        return SafeApplyStatus(target, statusId, duration, 1) == true
    end
    if not (Osi and Osi.ApplyStatus) then
        return false
    end
    local ok = pcall(Osi.ApplyStatus, target, statusId, duration, 1)
    return ok == true
end

local function EA_TestFleeFromObject(target, fleeFrom, fleeRange)
    if not target or target == "" or not fleeFrom or fleeFrom == "" then
        return false
    end
    if not (Osi and Osi.FleeFromObject) then
        return false
    end
    local range = tonumber(fleeRange) or 10.0
    if range <= 0 then
        range = 10.0
    end
    EA_WatchFleeTarget(target)
    local ok = pcall(Osi.FleeFromObject, target, fleeFrom, range)
    if not ok then
        EA_ClearFleeWatch(target)
    end
    return ok == true
end

local function EA_PrintEscapeTuneSnapshot()
    local s = EnemyAmbush and EnemyAmbush.Settings or {}
    print(string.format(
        "[EnemyAmbush] Escape tune: enabled=%s startTurn=%s dc=%s hpThreshold=%s maxPerCombat=%s",
        tostring(s["MCM_EnableAmbusherEscape"]),
        tostring(s["MCM_EscapeStartTurn"]),
        tostring(s["MCM_EscapeDC"]),
        tostring(s["MCM_EscapeHPThreshold"]),
        tostring(s["MCM_EscapeMaxPerCombat"])
    ))
end

local function EA_ApplyEscapeTune(values)
    local setFn = EnemyAmbush and EnemyAmbush["EA_SetOwnedRuntimeSetting"]
    local getTableFn = EnemyAmbush and EnemyAmbush["EA_GetOwnedSettingsTable"]
    local s = type(getTableFn) == "function" and getTableFn() or EnemyAmbush.Settings
    if type(s) ~= "table" then
        return
    end
    for id, value in pairs(values or {}) do
        if type(setFn) == "function" then
            setFn(id, value)
        else
            s[id] = value
        end
    end
    if type(EA_ApplySettingsToLocals) == "function" then
        pcall(EA_ApplySettingsToLocals)
    end
    if type(EA_Dirty) == "function" then
        pcall(EA_Dirty)
    end
end

local function EA_TestDump(uuid)
    if not uuid or uuid == "" then
        print("[EnemyAmbush][TEST] dump: missing uuid")
        return
    end

    local level = SafeOsiCall(Osi.GetLevel, uuid)
    local faction = SafeOsiCall(Osi.GetFaction, uuid)
    local hp = SafeOsiCall(Osi.GetHitpoints, uuid)
    local maxhp = SafeOsiCall(Osi.GetMaxHitpoints, uuid)

    local templateId = nil
    if Osi and Osi.GetTemplate then
        templateId = SafeOsiCall(Osi.GetTemplate, uuid)
    end
    if (not templateId or templateId == "") and Ext and Ext.Entity and Ext.Entity.Get then
        local okEnt, ent = pcall(Ext.Entity.Get, uuid)
        if okEnt and ent then
            local okRT, rt = pcall(function()
                return ent.ServerCharacter and ent.ServerCharacter.Template and ent.ServerCharacter.Template.RootTemplate
            end)
            if okRT and rt then
                templateId = tostring(rt)
            end
        end
    end

    print("[EnemyAmbush][TEST] ---- DUMP ----")
    print("[EnemyAmbush][TEST] UUID:", uuid)
    print("[EnemyAmbush][TEST] Template:", templateId or "(unknown)")
    print("[EnemyAmbush][TEST] Level:", tostring(level), "Faction:", tostring(faction))
    print("[EnemyAmbush][TEST] HP:", tostring(hp), "/", tostring(maxhp))

    -- Show tracked spawn metadata (if it's one of ours)
    local spawnedData = EA_GetSpawnedDataCompat(uuid)
    if spawnedData then
        print("[EnemyAmbush][TEST] TrackedSpawn:", "YES",
            "type:", tostring(spawnedData.creatureType),
            "tier:", tostring(spawnedData.tier),
            "template:", tostring(spawnedData.template))
    else
        print("[EnemyAmbush][TEST] TrackedSpawn: NO")
    end

    -- Important statuses we care about (cheap + reliable)
    local watchStatuses = {
    "EA_AMBUSHER",
    "EA_CHAMPION",
    "SCL_MOONSHIELD",

    -- Tier packs (vanilla)
    "EA_TIER_COMMON_L1", "EA_TIER_COMMON_L5", "EA_TIER_COMMON_L7", "EA_TIER_COMMON_L11", "EA_TIER_COMMON_L15",
    "EA_TIER_VETERAN_L1", "EA_TIER_VETERAN_L5", "EA_TIER_VETERAN_L7", "EA_TIER_VETERAN_L11", "EA_TIER_VETERAN_L15",
    "EA_TIER_ELITE_L1", "EA_TIER_ELITE_L5", "EA_TIER_ELITE_L9", "EA_TIER_ELITE_L12", "EA_TIER_ELITE_L15",
    "EA_TIER_LEGENDARY_L1", "EA_TIER_LEGENDARY_L5", "EA_TIER_LEGENDARY_L11", "EA_TIER_LEGENDARY_L15",

    -- Tier packs (CX)
    "EA_TIER_COMMON_CX_L1", "EA_TIER_COMMON_CX_L7", "EA_TIER_COMMON_CX_L11",
    "EA_TIER_VETERAN_CX_L1", "EA_TIER_VETERAN_CX_L7", "EA_TIER_VETERAN_CX_L11",
    "EA_TIER_ELITE_CX_L1", "EA_TIER_ELITE_CX_L9", "EA_TIER_ELITE_CX_L12",
    "EA_TIER_LEGENDARY_CX_L1", "EA_TIER_LEGENDARY_CX_L11",

    -- Champion base packs
    "EA_CHAMPION_BASE_L1", "EA_CHAMPION_BASE_L7", "EA_CHAMPION_BASE_L11",
    "EA_CHAMPION_BASE_CX_L1", "EA_CHAMPION_BASE_CX_L7", "EA_CHAMPION_BASE_CX_L11",

    -- Champion type packs
    "EA_CHAMPION_ABERRATION", "EA_CHAMPION_BEAST", "EA_CHAMPION_CELESTIAL",
    "EA_CHAMPION_CONSTRUCT", "EA_CHAMPION_DRAGON", "EA_CHAMPION_ELEMENTAL",
    "EA_CHAMPION_FEY", "EA_CHAMPION_FIEND", "EA_CHAMPION_GIANT",
    "EA_CHAMPION_HUMANOID", "EA_CHAMPION_MONSTROSITY", "EA_CHAMPION_OOZE",
    "EA_CHAMPION_PLANT", "EA_CHAMPION_UNDEAD"
}

    local found = {}
    if Osi and Osi.HasActiveStatus then
        for _, st in ipairs(watchStatuses) do
            local ok, res = pcall(Osi.HasActiveStatus, uuid, st)
            if ok and res == 1 then table.insert(found, st) end
        end
    end
    print("[EnemyAmbush][TEST] Statuses:", (#found > 0) and table.concat(found, ", ") or "(none of watched)")
end



-- Console commands
if Ext and Ext.RegisterConsoleCommand then
Ext.RegisterConsoleCommand("ea_test", function(cmd, ...)
local args = {...}
local player = Osi.GetHostCharacter()
if not player then
print("[EnemyAmbush] No host character found!")
return
end

-- Resolve cross-chunk locals used by console commands (Systems/Utils keep many values local)
local function _EA_ResolveTable(getterName, fallbackField)
    local getter = EA and EA[getterName]
    if type(getter) == "function" then
        local ok, t = pcall(getter)
        if ok and type(t) == "table" then return t end
    end
    local t = EA and EA[fallbackField]
    if type(t) == "table" then return t end
    return {}
end

local function EA_BuildActiveListSafe()
    local fn = _EA_ResolveFn("EA_GetPoolActiveSummonList", EA_GetPoolActiveSummonList)
    if type(fn) ~= "function" then
        print("[EnemyAmbush] EA_GetPoolActiveSummonList unavailable (Pool owner not loaded).")
        return {}
    end

    local ok, list = pcall(fn)
    if not ok then
        print(string.format("[EnemyAmbush] EA_GetPoolActiveSummonList failed: %s", tostring(list)))
        return {}
    end
    if type(list) ~= "table" then
        print("[EnemyAmbush] EA_GetPoolActiveSummonList returned non-table result.")
        return {}
    end
    return list
end

local function EA_MakeProviderProbeEntry(kind)
    local suffix = (kind == "b") and "b" or "a"
    return {
        template = EA_PROVIDER_PROBE_TEMPLATE,
        name = (suffix == "b") and EA_PROVIDER_PROBE_NAME_B or EA_PROVIDER_PROBE_NAME_A,
        creatureType = "Humanoid",
        level = 3,
        weight = 1.0,
        spawnBand = "COMMON",
        status = (suffix == "b") and EA_PROVIDER_PROBE_STATUS_B or EA_PROVIDER_PROBE_STATUS_A,
    }
end

local function EA_GetProviderProbeApi()
    return {
        register = EA and EA.RegisterEnemyProvider,
        registerTemplate = EA and EA.RegisterEnemyTemplate,
        unregister = EA and EA.UnregisterEnemyProvider,
        has = EA and EA.HasEnemyProvider,
        isActive = EA and EA.IsEnemyProviderActive,
        get = EA and EA.GetEnemyProvider,
    }
end

local function EA_MakeAuthoredApiProbeDefinition()
    return {
        enabled = true,
        once = false,
        priority = 10,
        triggerKinds = { "external" },
        gates = {
            minPartyLevel = 1,
            maxPartyLevel = 20,
        },
        trigger = {},
        spawn = {
            mode = "pool_roll",
            themeKey = "Humanoid",
            tier = "VETERAN",
        },
        policies = {
            hostilityMode = "default",
            reputationMode = "default",
            rewardMode = "default",
        },
        presentation = {
            flowLabel = "DebugAuthoredApiSmoke",
        },
    }
end

local function EA_MakeAuthoredApiTriggerProbeDefinition()
    return {
        enabled = true,
        once = false,
        priority = 20,
        triggerKinds = { "external" },
        gates = {
            minPartyLevel = 1,
            maxPartyLevel = 20,
        },
        trigger = {},
        spawn = {
            mode = "custom_entries",
            themeKey = "Humanoid",
            entries = {
                {
                    template = "844e3c99-ea7e-4a49-8dcd-691c8c050b41",
                    displayName = "API Smoke Goblin",
                    level = 1,
                    creatureType = "Humanoid",
                },
            },
        },
        policies = {
            hostilityMode = "default",
            reputationMode = "default",
            rewardMode = "default",
        },
        presentation = {
            flowLabel = "DebugAuthoredApiTriggerSmoke",
        },
    }
end

local function EA_MakeAuthoredApiCustomProbePayload(character)
    return {
        character = character,
        source = "debug",
        flowLabel = "DebugAuthoredApiCustomSmoke",
        spawn = {
            mode = "custom_entries",
            themeKey = "Humanoid",
            entries = {
                {
                    template = "844e3c99-ea7e-4a49-8dcd-691c8c050b41",
                    displayName = "API Custom Smoke Goblin",
                    level = 1,
                    creatureType = "Humanoid",
                },
            },
        },
        policies = {
            hostilityMode = "default",
            reputationMode = "default",
            rewardMode = "default",
        },
        presentation = {
            flowLabel = "DebugAuthoredApiCustomSmoke",
        },
    }
end

local function EA_GetAuthoredApiProbeApi()
    local mirror = (type(EA) == "table" and type(EA.API) == "table") and EA.API or nil
    return {
        rootRegister = EA and EA.RegisterAmbushDefinition,
        rootGet = EA and EA.GetAmbushDefinition,
        rootUnregister = EA and EA.UnregisterAmbushDefinition,
        rootState = EA and EA.GetAmbushState,
        rootTrigger = EA and EA.TriggerAmbushDefinition,
        rootCustom = EA and EA.TriggerCustomAmbush,
        apiRegister = mirror and mirror.RegisterAmbushDefinition,
        apiGet = mirror and mirror.GetAmbushDefinition,
        apiUnregister = mirror and mirror.UnregisterAmbushDefinition,
        apiState = mirror and mirror.GetAmbushState,
        apiTrigger = mirror and mirror.TriggerAmbushDefinition,
        apiCustom = mirror and mirror.TriggerCustomAmbush,
    }
end

local function EA_PrintAuthoredApiProbeSurface(api)
    print("[EnemyAmbush] Authored API surface:")
    print(string.format(
        "  EnemyAmbush: register=%s get=%s unregister=%s state=%s trigger=%s custom=%s",
        tostring(type(api.rootRegister)),
        tostring(type(api.rootGet)),
        tostring(type(api.rootUnregister)),
        tostring(type(api.rootState)),
        tostring(type(api.rootTrigger)),
        tostring(type(api.rootCustom))
    ))
    print(string.format(
        "  EnemyAmbush.API: register=%s get=%s unregister=%s state=%s trigger=%s custom=%s",
        tostring(type(api.apiRegister)),
        tostring(type(api.apiGet)),
        tostring(type(api.apiUnregister)),
        tostring(type(api.apiState)),
        tostring(type(api.apiTrigger)),
        tostring(type(api.apiCustom))
    ))
end

local function EA_PrintAuthoredApiStateSummary(label, state)
    if type(state) ~= "table" then
        print(string.format("[EnemyAmbush] %s state unavailable (%s)", tostring(label or "api"), tostring(type(state))))
        return
    end
    print(string.format(
        "[EnemyAmbush] %s state: activeRegion=%s blockedSafeZone=%s inCamp=%s inCombat=%s cooldownActive=%s cooldownRemainingMs=%s pendingAmbushCount=%s registeredDefinitionCount=%s timeInDangerMinutes=%s timeInDangerRiskPct=%s",
        tostring(label or "api"),
        tostring(state.activeRegion),
        tostring(state.blockedSafeZone),
        tostring(state.inCamp),
        tostring(state.inCombat),
        tostring(state.cooldownActive),
        tostring(state.cooldownRemainingMs),
        tostring(state.pendingAmbushCount),
        tostring(state.registeredDefinitionCount),
        tostring(state.timeInDangerMinutes),
        tostring(state.timeInDangerRiskPct)
    ))
end

local function EA_PrintAuthoredApiTriggerSummary(label, ok, payload)
    if ok ~= true or type(payload) ~= "table" then
        print(string.format(
            "[EnemyAmbush] %s => ok=%s err=%s",
            tostring(label or "api trigger"),
            tostring(ok == true),
            tostring(payload)
        ))
        return
    end

    local triggerKindsLabel = ""
    if type(payload.triggerKinds) == "table" then
        triggerKindsLabel = table.concat(payload.triggerKinds, ",")
    end
    local noLeak = type(payload.definition) ~= "table"
        and type(payload.service) ~= "table"
        and type(payload.state) ~= "table"
        and type(payload.queue) ~= "table"
    local definitionIdOk = payload.definitionId == nil
        or (type(payload.definitionId) == "string" and payload.definitionId ~= "")

    local shapeOk = payload.accepted == true
        and type(payload.requestId) == "string" and payload.requestId ~= ""
        and definitionIdOk
        and type(payload.source) == "string" and payload.source ~= ""
        and type(payload.queued) == "boolean"
        and type(payload.triggerKinds) == "table"

    print(string.format(
        "[EnemyAmbush] %s => ok=%s accepted=%s requestId=%s definitionId=%s flowLabel=%s source=%s queued=%s triggerKinds=%s character=%s shape_ok=%s no_leak=%s",
        tostring(label or "api trigger"),
        tostring(ok == true),
        tostring(payload.accepted == true),
        tostring(payload.requestId),
        tostring(payload.definitionId),
        tostring(payload.flowLabel),
        tostring(payload.source),
        tostring(payload.queued),
        tostring(triggerKindsLabel),
        tostring(payload.character),
        tostring(shapeOk),
        tostring(noLeak)
    ))
end

local function EA_RunAuthoredApiSmoke()
    local api = EA_GetAuthoredApiProbeApi()
    EA_PrintAuthoredApiProbeSurface(api)

    if type(api.rootRegister) ~= "function"
        or type(api.rootGet) ~= "function"
        or type(api.rootUnregister) ~= "function"
        or type(api.rootState) ~= "function"
        or type(api.apiRegister) ~= "function"
        or type(api.apiGet) ~= "function"
        or type(api.apiUnregister) ~= "function"
        or type(api.apiState) ~= "function"
    then
        print("[EnemyAmbush] api authored_smoke unavailable (D2-1 authored API exports missing).")
        return
    end

    pcall(api.rootUnregister, EA_AUTHORED_API_PROBE_ID)
    pcall(api.rootUnregister, EA_AUTHORED_API_INVALID_PROBE_ID)

    local okInvalid, errInvalid = api.rootRegister(EA_AUTHORED_API_INVALID_PROBE_ID, {
        enabled = true,
        triggerKinds = { "bogus_kind" },
        spawn = { mode = "pool_roll" },
        policies = {
            hostilityMode = "default",
            reputationMode = "default",
            rewardMode = "default",
        },
    })
    print(string.format(
        "[EnemyAmbush] api authored_smoke invalid register => ok=%s err=%s",
        tostring(okInvalid == true),
        tostring(errInvalid)
    ))

    local stateBefore = api.rootState()
    EA_PrintAuthoredApiStateSummary("api authored_smoke before", stateBefore)

    local okRegister, errRegister = api.rootRegister(EA_AUTHORED_API_PROBE_ID, EA_MakeAuthoredApiProbeDefinition())
    print(string.format(
        "[EnemyAmbush] api authored_smoke register => ok=%s err=%s",
        tostring(okRegister == true),
        tostring(errRegister)
    ))
    if okRegister ~= true then
        pcall(api.rootUnregister, EA_AUTHORED_API_PROBE_ID)
        pcall(api.rootUnregister, EA_AUTHORED_API_INVALID_PROBE_ID)
        return
    end

    local firstSnapshot = api.apiGet(EA_AUTHORED_API_PROBE_ID)
    local secondSnapshot = nil
    local defensiveCopyOk = false
    if type(firstSnapshot) == "table" and type(firstSnapshot.definition) == "table" then
        if type(firstSnapshot.definition.spawn) == "table" then
            firstSnapshot.definition.spawn.mode = "tampered_mode"
        end
        if type(firstSnapshot.definition.triggerKinds) == "table" and firstSnapshot.definition.triggerKinds[1] ~= nil then
            firstSnapshot.definition.triggerKinds[1] = "tampered_kind"
        end
        secondSnapshot = api.rootGet(EA_AUTHORED_API_PROBE_ID)
        defensiveCopyOk = type(secondSnapshot) == "table"
            and type(secondSnapshot.definition) == "table"
            and type(secondSnapshot.definition.spawn) == "table"
            and tostring(secondSnapshot.definition.spawn.mode or "") == "pool_roll"
            and type(secondSnapshot.definition.triggerKinds) == "table"
            and tostring(secondSnapshot.definition.triggerKinds[1] or "") == "external"
    end
    print(string.format(
        "[EnemyAmbush] api authored_smoke defensive_copy => ok=%s",
        tostring(defensiveCopyOk)
    ))

    local stateAfterRegister = api.apiState()
    EA_PrintAuthoredApiStateSummary("api authored_smoke after_register", stateAfterRegister)

    local okUnregister, errUnregister = api.apiUnregister(EA_AUTHORED_API_PROBE_ID)
    print(string.format(
        "[EnemyAmbush] api authored_smoke unregister => ok=%s err=%s",
        tostring(okUnregister == true),
        tostring(errUnregister)
    ))

    local okMissing, errMissing = api.rootUnregister(EA_AUTHORED_API_PROBE_ID)
    print(string.format(
        "[EnemyAmbush] api authored_smoke missing_unregister => ok=%s err=%s",
        tostring(okMissing == true),
        tostring(errMissing)
    ))

    local stateAfterUnregister = api.rootState()
    EA_PrintAuthoredApiStateSummary("api authored_smoke after_unregister", stateAfterUnregister)

    pcall(api.rootUnregister, EA_AUTHORED_API_PROBE_ID)
    pcall(api.rootUnregister, EA_AUTHORED_API_INVALID_PROBE_ID)
end

local function EA_RunAuthoredApiTriggerSmoke()
    local api = EA_GetAuthoredApiProbeApi()
    EA_PrintAuthoredApiProbeSurface(api)

    if type(api.rootRegister) ~= "function"
        or type(api.rootGet) ~= "function"
        or type(api.rootUnregister) ~= "function"
        or type(api.rootTrigger) ~= "function"
        or type(api.apiTrigger) ~= "function"
    then
        print("[EnemyAmbush] api trigger_smoke unavailable (D2-2 trigger exports missing).")
        return
    end

    local player = (Osi and Osi.GetHostCharacter) and Osi.GetHostCharacter() or nil
    if not player or player == "" then
        print("[EnemyAmbush] api trigger_smoke unavailable (host character missing).")
        return
    end

    pcall(api.rootUnregister, EA_AUTHORED_API_TRIGGER_PROBE_ID)

    local okMissingId, errMissingId = api.rootTrigger("", {
        character = player,
        source = "debug",
    })
    print(string.format(
        "[EnemyAmbush] api trigger_smoke missing_id => ok=%s err=%s",
        tostring(okMissingId == true),
        tostring(errMissingId)
    ))

    local okUnknown, errUnknown = api.apiTrigger(EA_AUTHORED_API_TRIGGER_UNKNOWN_ID, {
        character = player,
        source = "debug",
    })
    print(string.format(
        "[EnemyAmbush] api trigger_smoke unknown_id => ok=%s err=%s",
        tostring(okUnknown == true),
        tostring(errUnknown)
    ))

    local okMissingCharacter, errMissingCharacter = api.rootTrigger(EA_AUTHORED_API_TRIGGER_PROBE_ID, {})
    print(string.format(
        "[EnemyAmbush] api trigger_smoke missing_character => ok=%s err=%s",
        tostring(okMissingCharacter == true),
        tostring(errMissingCharacter)
    ))

    local okRegister, errRegister = api.rootRegister(EA_AUTHORED_API_TRIGGER_PROBE_ID, EA_MakeAuthoredApiTriggerProbeDefinition())
    print(string.format(
        "[EnemyAmbush] api trigger_smoke register => ok=%s err=%s",
        tostring(okRegister == true),
        tostring(errRegister)
    ))
    if okRegister ~= true then
        pcall(api.rootUnregister, EA_AUTHORED_API_TRIGGER_PROBE_ID)
        return
    end

    local okTrigger, result = api.apiTrigger(EA_AUTHORED_API_TRIGGER_PROBE_ID, {
        character = player,
        source = "debug",
        flowLabel = "DebugAuthoredApiTriggerSmoke",
    })
    EA_PrintAuthoredApiTriggerSummary("api trigger_smoke trigger", okTrigger, result)

    local snapshot = api.rootGet(EA_AUTHORED_API_TRIGGER_PROBE_ID)
    local triggerCount = type(snapshot) == "table" and tonumber(snapshot.triggerCount) or 0
    local lastTriggeredAtMs = type(snapshot) == "table" and tonumber(snapshot.lastTriggeredAtMs) or 0
    print(string.format(
        "[EnemyAmbush] api trigger_smoke post_trigger_meta => triggerCount=%s lastTriggeredAtMs=%s completed=%s",
        tostring(triggerCount),
        tostring(lastTriggeredAtMs),
        tostring(type(snapshot) == "table" and snapshot.completed == true or false)
    ))

    local okUnregister, errUnregister = api.rootUnregister(EA_AUTHORED_API_TRIGGER_PROBE_ID)
    print(string.format(
        "[EnemyAmbush] api trigger_smoke unregister => ok=%s err=%s",
        tostring(okUnregister == true),
        tostring(errUnregister)
    ))

    pcall(api.rootUnregister, EA_AUTHORED_API_TRIGGER_PROBE_ID)
end

local function EA_RunAuthoredApiCustomSmoke()
    local api = EA_GetAuthoredApiProbeApi()
    EA_PrintAuthoredApiProbeSurface(api)

    if type(api.rootCustom) ~= "function" or type(api.apiCustom) ~= "function" or type(api.rootState) ~= "function" then
        print("[EnemyAmbush] api custom_smoke unavailable (D2-3 custom trigger exports missing).")
        return
    end

    local player = (Osi and Osi.GetHostCharacter) and Osi.GetHostCharacter() or nil
    if not player or player == "" then
        print("[EnemyAmbush] api custom_smoke unavailable (host character missing).")
        return
    end

    local okMissingPayload, errMissingPayload = api.rootCustom(nil)
    print(string.format(
        "[EnemyAmbush] api custom_smoke missing_payload => ok=%s err=%s",
        tostring(okMissingPayload == true),
        tostring(errMissingPayload)
    ))

    local okMissingCharacter, errMissingCharacter = api.apiCustom({
        spawn = {
            mode = "custom_entries",
            entries = {
                { template = "844e3c99-ea7e-4a49-8dcd-691c8c050b41" },
            },
        },
        policies = {
            hostilityMode = "default",
            reputationMode = "default",
            rewardMode = "default",
        },
    })
    print(string.format(
        "[EnemyAmbush] api custom_smoke missing_character => ok=%s err=%s",
        tostring(okMissingCharacter == true),
        tostring(errMissingCharacter)
    ))

    local okInvalidEntryField, errInvalidEntryField = api.rootCustom({
        character = player,
        source = "debug",
        spawn = {
            mode = "custom_entries",
            entries = {
                {
                    template = "844e3c99-ea7e-4a49-8dcd-691c8c050b41",
                    powerClass = "Pack",
                },
            },
        },
        policies = {
            hostilityMode = "default",
            reputationMode = "default",
            rewardMode = "default",
        },
    })
    print(string.format(
        "[EnemyAmbush] api custom_smoke invalid_entry_field => ok=%s err=%s",
        tostring(okInvalidEntryField == true),
        tostring(errInvalidEntryField)
    ))

    local stateBefore = api.rootState()
    EA_PrintAuthoredApiStateSummary("api custom_smoke before", stateBefore)
    local beforeRegisteredCount = type(stateBefore) == "table" and tonumber(stateBefore.registeredDefinitionCount) or 0

    local okCustom, result = api.apiCustom(EA_MakeAuthoredApiCustomProbePayload(player))
    EA_PrintAuthoredApiTriggerSummary("api custom_smoke trigger", okCustom, result)

    local stateAfter = api.rootState()
    EA_PrintAuthoredApiStateSummary("api custom_smoke after", stateAfter)
    local afterRegisteredCount = type(stateAfter) == "table" and tonumber(stateAfter.registeredDefinitionCount) or 0
    print(string.format(
        "[EnemyAmbush] api custom_smoke non_persistent => beforeRegistered=%s afterRegistered=%s ok=%s",
        tostring(beforeRegisteredCount),
        tostring(afterRegisteredCount),
        tostring(beforeRegisteredCount == afterRegisteredCount)
    ))
end

local function EA_GetProviderProbeActiveMatches()
    local matches = {}
    local list = EA_BuildActiveListSafe()
    for _, enemy in ipairs(list) do
        local row = type(enemy) == "table" and enemy or nil
        local status = tostring(row and row.status or "")
        local name = tostring(row and row.name or "")
        if status == EA_PROVIDER_PROBE_STATUS_A
            or status == EA_PROVIDER_PROBE_STATUS_B
            or name == EA_PROVIDER_PROBE_NAME_A
            or name == EA_PROVIDER_PROBE_NAME_B then
            matches[#matches + 1] = {
                name = name,
                template = tostring(row and row.template or ""),
                status = status,
                level = tonumber(row and row.level) or 0,
            }
        end
    end
    table.sort(matches, function(a, b)
        local ka = tostring(a.status or "") .. "|" .. tostring(a.name or "")
        local kb = tostring(b.status or "") .. "|" .. tostring(b.name or "")
        return ka < kb
    end)
    return matches, list
end

local function EA_PrintProviderProbeState()
    local api = EA_GetProviderProbeApi()
    local exists = false
    local active = false
    local storedEntries = 0

    if type(api.has) == "function" then
        local ok, out = pcall(api.has, EA_PROVIDER_PROBE_ID)
        exists = ok and out == true
    elseif type(api.get) == "function" then
        local ok, out = pcall(api.get, EA_PROVIDER_PROBE_ID)
        exists = ok and type(out) == "table"
    end

    if type(api.get) == "function" then
        local ok, provider = pcall(api.get, EA_PROVIDER_PROBE_ID)
        if ok and type(provider) == "table" then
            storedEntries = type(provider.entries) == "table" and #provider.entries or 0
        end
    end

    if type(api.isActive) == "function" then
        local ok, out = pcall(api.isActive, EA_PROVIDER_PROBE_ID)
        active = ok and out == true
    end

    local matches, list = EA_GetProviderProbeActiveMatches()
    print("[EnemyAmbush] Provider probe state:")
    print(string.format(
        "  id=%s exists=%s active=%s storedEntries=%d activeMatches=%d activeListCount=%d template=%s",
        tostring(EA_PROVIDER_PROBE_ID),
        tostring(exists),
        tostring(active),
        tonumber(storedEntries) or 0,
        #matches,
        #list,
        tostring(EA_PROVIDER_PROBE_TEMPLATE)
    ))
    for _, row in ipairs(matches) do
        print(string.format(
            "  match: name=%s status=%s level=%d template=%s",
            tostring(row.name or ""),
            tostring(row.status or ""),
            tonumber(row.level) or 0,
            tostring(row.template or "")
        ))
    end
end

local function EA_NormalizeCreatureTypeInput(rawType)
    local wanted = string.lower(tostring(rawType or ""))
    if wanted == "" then return nil end
    if type(CreatureReputation) == "table" then
        for ct, _ in pairs(CreatureReputation) do
            if string.lower(tostring(ct)) == wanted then
                return tostring(ct)
            end
        end
    end
    return wanted:sub(1, 1):upper() .. wanted:sub(2):lower()
end

local function EA_GetChampionDiagModeSafe()
    if type(EA_GetChampionDiagnosticsMode) == "function" then
        local ok, mode = pcall(EA_GetChampionDiagnosticsMode)
        if ok and mode then
            return string.lower(tostring(mode))
        end
    end
    local dbg = EnemyAmbush and EnemyAmbush.Debug
    local mode = (type(dbg) == "table" and dbg.ChampionDiagnosticsMode) or "off"
    mode = string.lower(tostring(mode))
    if mode ~= "on" and mode ~= "once" then
        mode = "off"
    end
    return mode
end

local function EA_SetChampionDiagModeSafe(mode)
    local normalized = string.lower(tostring(mode or "off"))
    if normalized ~= "on" and normalized ~= "once" then
        normalized = "off"
    end
    if type(EA_SetChampionDiagnosticsMode) == "function" then
        local ok, out = pcall(EA_SetChampionDiagnosticsMode, normalized)
        if ok and out then
            return string.lower(tostring(out))
        end
    end
    EnemyAmbush.Debug = EnemyAmbush.Debug or {}
    EnemyAmbush.Debug.ChampionDiagnosticsMode = normalized
    return normalized
end

local function EA_GetChampionFallbackPolicyModeSafe()
    if type(EA_GetChampionFallbackPolicyMode) == "function" then
        local ok, mode = pcall(EA_GetChampionFallbackPolicyMode)
        if ok and mode then
            return string.lower(tostring(mode))
        end
    end
    return "compat"
end

local function EA_SetChampionFallbackPolicyModeSafe(mode)
    local normalized = string.lower(tostring(mode or "default"))
    if normalized == "debug-only" then
        normalized = "debug_only"
    end
    if normalized == "show" or normalized == "" then
        return EA_GetChampionFallbackPolicyModeSafe()
    end
    if normalized ~= "compat"
        and normalized ~= "strict"
        and normalized ~= "debug_only"
        and normalized ~= "default"
        and normalized ~= "reset"
        and normalized ~= "clear"
    then
        return EA_GetChampionFallbackPolicyModeSafe(), false
    end
    if type(EA_SetChampionFallbackPolicyMode) == "function" then
        local ok, out = pcall(EA_SetChampionFallbackPolicyMode, normalized)
        if ok and out then
            return string.lower(tostring(out)), true
        end
    end
    return EA_GetChampionFallbackPolicyModeSafe(), false
end

local function EA_FormatSimpleList(items)
    if type(items) ~= "table" or #items == 0 then
        return "(none)"
    end
    local out = {}
    for i = 1, #items do
        out[#out + 1] = tostring(items[i])
    end
    return table.concat(out, ", ")
end

local function EA_PrintChampionDiagSnapshot(hostPlayer)
    local player = hostPlayer
    if (not player or player == "") and Osi and Osi.GetHostCharacter then
        player = Osi.GetHostCharacter()
    end

    print(string.format("[EnemyAmbush] ChampionDiag mode=%s", tostring(EA_GetChampionDiagModeSafe())))

    local queue = EA_DebugGetChampionQueue()
    local queued = {}
    for ct, entry in pairs(queue) do
        if type(entry) == "table" then
            queued[#queued + 1] = tostring(ct)
        end
    end
    table.sort(queued)
    print(string.format("[EnemyAmbush] ChampionDiag queued types: %s", EA_FormatSimpleList(queued)))

    local armed = nil
    if type(EA_GetGuaranteedChampionArmed) == "function" then
        local ok, out = pcall(EA_GetGuaranteedChampionArmed)
        if ok and type(out) == "table" then
            armed = out
        end
    end
    if type(armed) == "table" and armed.creatureType then
        print(string.format(
            "[EnemyAmbush] ChampionDiag armed: type=%s tries=%s repAtSet=%s",
            tostring(armed.creatureType),
            tostring(armed.tries),
            tostring(armed.repAtSet)
        ))
    else
        print("[EnemyAmbush] ChampionDiag armed: none")
    end

    local vengeful = {}
    if type(CreatureReputation) == "table" then
        for ct, rep in pairs(CreatureReputation) do
            local n = tonumber(rep) or 0
            if n <= (REPUTATION_THRESHOLDS and REPUTATION_THRESHOLDS.VENGEFUL or -20) then
                vengeful[#vengeful + 1] = string.format("%s=%s", tostring(ct), tostring(n))
            end
        end
    end
    table.sort(vengeful)
    print(string.format("[EnemyAmbush] ChampionDiag vengeful reps: %s", EA_FormatSimpleList(vengeful)))

    local regionTypes = {}
    if type(EA_GetLocationAppropriateEnemies) == "function" and player and player ~= "" then
        local ok, out = pcall(EA_GetLocationAppropriateEnemies, player)
        if ok and type(out) == "table" then
            regionTypes = out
        end
    end
    print(string.format("[EnemyAmbush] ChampionDiag region-appropriate types: %s", EA_FormatSimpleList(regionTypes)))
    print(string.format("[EnemyAmbush] ChampionDiag fallback policy: %s", tostring(EA_GetChampionFallbackPolicyModeSafe())))

    local resolveTelemetry = nil
    if type(EA_GetChampionResolveTelemetrySnapshot) == "function" then
        local ok, out = pcall(EA_GetChampionResolveTelemetrySnapshot)
        if ok and type(out) == "table" then
            resolveTelemetry = out
        end
    end

    if type(resolveTelemetry) ~= "table" then
        print("[EnemyAmbush] ChampionDiag resolve telemetry: unavailable")
        return
    end

    local bySource = type(resolveTelemetry.bySource) == "table" and resolveTelemetry.bySource or {}
    local byPathKind = type(resolveTelemetry.byPathKind) == "table" and resolveTelemetry.byPathKind or {}
    print(string.format(
        "[EnemyAmbush] ChampionDiag resolve summary: total=%s provider=%s summon_fallback=%s none=%s ordinary=%s forced_or_queued=%s",
        tostring(resolveTelemetry.total or 0),
        tostring(bySource.provider or 0),
        tostring(bySource.summon_fallback or 0),
        tostring(bySource.none or 0),
        tostring(byPathKind.ordinary or 0),
        tostring(byPathKind.forced_or_queued or 0)
    ))

    local recent = type(resolveTelemetry.recent) == "table" and resolveTelemetry.recent or {}
    if #recent == 0 then
        print("[EnemyAmbush] ChampionDiag resolve recent: (none)")
        return
    end

    local startIndex = math.max(1, #recent - 2)
    for i = startIndex, #recent do
        local event = recent[i]
        if type(event) == "table" then
            print(string.format(
                "[EnemyAmbush] ChampionDiag resolve[%s]: ctx=%s kind=%s policy=%s type=%s source=%s reason=%s provider=%s template=%s",
                tostring(event.index or i),
                tostring(event.context or "direct_call"),
                tostring(event.pathKind or "forced_or_queued"),
                tostring(event.policy or "compat"),
                tostring(event.creatureType or ""),
                tostring(event.source or "none"),
                tostring(event.reason or "unknown"),
                tostring(event.providerId or "n/a"),
                tostring(event.template or "n/a")
            ))
        end
    end
end

-- Debug category resolver: prefer explicit spawnBand contract, then metadata fallback.
local function EA_GetDebugCategory(enemyData)
    local getBandFn = EA and EA["EA_GetEntrySpawnBand"]
    if type(getBandFn) == "function" then
        local okBand, band = pcall(getBandFn, enemyData)
        if okBand and band then
            return string.upper(tostring(band))
        end
    end

    local getMetaFn = EA and (EA["EA_GetStaticMetadataCategory"] or EA["GetEnemyCategory"])
    if type(getMetaFn) == "function" then
        local okMeta, meta = pcall(getMetaFn, enemyData)
        if okMeta and meta then
            return string.upper(tostring(meta))
        end
    end

    return "COMMON"
end

local function EA_GetUniqueTemplatesForType(creatureType)
    local list = EA_BuildActiveListSafe()
    local seen = {}
    local out = {}
    for _, enemy in ipairs(list) do
        if tostring(enemy.creatureType or "") == tostring(creatureType or "") then
            local template = string.lower(tostring(enemy.template or ""))
            if template ~= "" and not seen[template] then
                seen[template] = true
                out[#out + 1] = {
                    name = tostring(enemy.name or "Unknown"),
                    template = template,
                    tier = tostring(EA_GetDebugCategory(enemy) or "COMMON"),
                    level = tonumber(enemy.level) or 1,
                }
            end
        end
    end
    table.sort(out, function(a, b)
        if a.name == b.name then
            return a.template < b.template
        end
        return a.name < b.name
    end)
    return out
end

-- These are local in Systems, so resolve through exported getters/tables when available.
local CHAMPION_TEMPLATES = _EA_ResolveTable("EA_GetChampionTemplates", "CHAMPION_TEMPLATES")

-- Metrics helpers: GetMetricsSummary is exported; PerformanceMetrics is local in Utils (use getter)
local GetMetricsSummary = (EA and EA["GetMetricsSummary"])
if type(GetMetricsSummary) ~= "function" then
    GetMetricsSummary = function() return "[EnemyAmbush] Metrics unavailable (GetMetricsSummary not exported)" end
end

local function _EA_ResolveMetrics()
    local getter = EA and EA["EA_GetPerformanceMetrics"]
    if type(getter) == "function" then
        local ok, t = pcall(getter)
        if ok and type(t) == "table" then return t end
    end
    local t = EA and EA["PerformanceMetrics"]
    if type(t) == "table" then return t end
    return {}
end
local PerformanceMetrics = _EA_ResolveMetrics()

local function StatExists(name, emptyAsTrue)
    if not name or name == "" then
        return emptyAsTrue == true
    end
    local ok, stat = pcall(Ext.Stats.Get, name)
    return ok and stat ~= nil
end

local function EA_JoinArgs(startIndex, fallback)
    local parts = {}
    for i = startIndex, #args do
        local v = tostring(args[i] or "")
        if v ~= "" then
            parts[#parts + 1] = v
        end
    end
    if #parts > 0 then
        return table.concat(parts, " ")
    end
    return fallback or ""
end

local function EA_OpenMessageBoxYesNoCompat(target, text, id)
    if not (Osi and Osi.OpenMessageBoxYesNo) then
        return false
    end
    if pcall(Osi.OpenMessageBoxYesNo, target, text, id) then
        return true
    end
    if pcall(Osi.OpenMessageBoxYesNo, target, text) then
        return true
    end
    return false
end

if args[1] == "spawnuuid" then
  -- Usage: !ea_test spawnuuid <RootTemplateGUID> [keep|despawn <seconds>]
  local guid = args[2]
  local mode = string.lower(tostring(args[3] or "keep"))
  local seconds = tonumber(args[4]) or 0

  if not guid or guid == "" then
    print("Usage: !ea_test spawnuuid <RootTemplateGUID> [keep|despawn <seconds>]")
    return
  end

  -- Validate GUID format (avoid invalid input)
  if not EA_GuidLooksValid(guid) then
    print("[EnemyAmbush] Invalid UUID format: " .. tostring(guid))
    return
  end

  -- Normalize to lowercase (matches pool-owner lookup keys)
  guid = guid:lower()

  -- Validate template exists (if API available)
  if Ext and Ext.Template and Ext.Template.GetRootTemplate then
    local okT, tmpl = pcall(Ext.Template.GetRootTemplate, guid)
    if okT and not tmpl then
      print("[EnemyAmbush] Template not found in game data: " .. tostring(guid))
      return
    end
  end

  -- Normalize mode
  if mode ~= "keep" and mode ~= "despawn" then
    mode = "keep"
  end

  local player = Osi.GetHostCharacter()
  if not player or player == "" then
    print("[EnemyAmbush] No host character found!")
    return
  end

  -- Try the pool owner first (respects MCM toggles and current active pool state)
  local entry = nil
  local getEntryFn = _EA_ResolveFn("EA_GetPoolTemplateEntryById", EA_GetPoolTemplateEntryById)
  if type(getEntryFn) == "function" then
    local okEntry, out = pcall(getEntryFn, guid)
    if okEntry and type(out) == "table" then
      entry = out
    end
  end

  if entry then
    -- keep = pass nil so your spawn pipeline won't schedule a despawn timer
    local durationArg = (mode == "despawn" and seconds and seconds > 0) and seconds or nil
    local spawnedEnemy = SpawnHostileNearPlayer(player, durationArg, entry)

    if spawnedEnemy and (not durationArg) and EA_RegisterTestSpawn then
      EA_RegisterTestSpawn(spawnedEnemy)
      print(string.format("[EnemyAmbush] Test spawn tracked: %s", tostring(spawnedEnemy)))
    else
      print(string.format("[EnemyAmbush] Test spawn created: %s", tostring(spawnedEnemy)))
    end

  else
    -- Fallback: raw CreateAt by template (works even if GUID isn't in the active list)
    local x,y,z = SafeGetPosition(player)
    if not x then
      print("[EnemyAmbush] Could not get player position")
      return
    end

    local angle = math.random() * 2 * math.pi
    local spawnX = x + math.cos(angle) * 3
    local spawnZ = z + math.sin(angle) * 3

    local ok, enemy = pcall(Osi.CreateAt, guid, spawnX, y, spawnZ, 1, 1, "")
    if not ok or not enemy or enemy == "" then
      print("[EnemyAmbush] CreateAt failed for "..tostring(guid))
      return
    end

    -- Match your existing hostility pipeline
    EA_MakeAmbushHostile(enemy, player)

    if mode == "despawn" and seconds > 0 then
      Osi.TimerLaunch(string.format("EA_Despawn_%s", enemy), math.floor(seconds * 1000))
      -- if you adopted the single global TimerFinished listener, it will delete on expiry
    else
      if EA_RegisterTestSpawn then EA_RegisterTestSpawn(enemy) end
    end

    print("[EnemyAmbush] Spawned enemy by GUID: "..enemy.." ("..mode..")")
  end
end

if args[1] == "neutraluuid" then
  -- Usage: !ea_test neutraluuid <RootTemplateGUID>
  local guid = args[2]
  if not guid or guid == "" then
    print("Usage: !ea_test neutraluuid <RootTemplateGUID>")
    return
  end

  if not EA_GuidLooksValid(guid) then
    print("[EnemyAmbush] Invalid UUID format: " .. tostring(guid))
    return
  end

  guid = guid:lower()

  if Ext and Ext.Template and Ext.Template.GetRootTemplate then
    local okT, tmpl = pcall(Ext.Template.GetRootTemplate, guid)
    if okT and not tmpl then
      print("[EnemyAmbush] Template not found in game data: " .. tostring(guid))
      return
    end
  end

  local player = Osi.GetHostCharacter()
  local enemy, err = EA_CreateNeutralTestSpawnByGuid(player, guid)
  if not enemy or enemy == "" then
    print("[EnemyAmbush] Neutral test spawn failed: " .. tostring(err or "unknown"))
    return
  end

  print(string.format("[EnemyAmbush] Neutral test spawn created: %s", tostring(enemy)))
  print(string.format("[EnemyAmbush] Next step: !ea_test hostile %s", tostring(enemy)))
  return
end

if args[1] == "spawn" then
local mode = (args[2] and string.lower(args[2])) or "preset"
local host = Osi.GetHostCharacter()
if not host then
    print("[EnemyAmbush] No host character found!")
    return
end

local getLevelFn = _EA_ResolveFn("GetSafeLevel", GetSafeLevel)
local getBudgetFn = _EA_ResolveFn("GetPointBudget", GetPointBudget)
local triggerAmbushFn = _EA_ResolveFn("TriggerAmbush", TriggerAmbush)
local executeAmbushFn = _EA_ResolveFn("ExecuteAmbushSpawn", ExecuteAmbushSpawn)
local spawnNearFn = _EA_ResolveFn("SpawnHostileNearPlayer", SpawnHostileNearPlayer)

local playerLevel = 1
if type(getLevelFn) == "function" then
    local okLevel, outLevel = pcall(getLevelFn, host)
    if okLevel and tonumber(outLevel) then
        playerLevel = tonumber(outLevel)
    end
elseif Osi and Osi.GetLevel then
    local okLevel, outLevel = pcall(Osi.GetLevel, host)
    if okLevel and tonumber(outLevel) then
        playerLevel = tonumber(outLevel)
    end
end

local pointBudget = 0
if type(getBudgetFn) == "function" then
    local okBudget, outBudget = pcall(getBudgetFn, playerLevel, host)
    if okBudget and tonumber(outBudget) then
        pointBudget = tonumber(outBudget)
    end
end

if mode == "random" then
    if type(triggerAmbushFn) ~= "function" then
        print("[EnemyAmbush] TriggerAmbush unavailable (Systems not loaded).")
        return
    end
    print("[EnemyAmbush] Spawning random ambush via TriggerAmbush (shared theme+tier roll, scripted/tutorial/cooldown bypassed)")
    triggerAmbushFn(host, false, true, {
        skipScripted = true,
        skipTutorial = true,
        skipCooldown = true,
        flowLabel = "TestRandom"
    })
elseif mode == "type" then
    if type(executeAmbushFn) ~= "function" then
        print("[EnemyAmbush] ExecuteAmbushSpawn unavailable (Systems not loaded).")
        return
    end

    local rawType = tostring(args[3] or "")
    local wantedType = string.lower(rawType)
    local creatureType = nil
    if wantedType ~= "" and type(CreatureReputation) == "table" then
        for ct, _ in pairs(CreatureReputation) do
            if string.lower(tostring(ct)) == wantedType then
                creatureType = tostring(ct)
                break
            end
        end
    end
    if (not creatureType or creatureType == "") and wantedType ~= "" then
        creatureType = wantedType:sub(1, 1):upper() .. wantedType:sub(2):lower()
    end

    if not creatureType or creatureType == "" then
        print("[EnemyAmbush] Usage: !ea_test spawn type <CreatureType> [tier|auto]")
        if type(CreatureReputation) == "table" then
            print("[EnemyAmbush] Valid creature types:")
            for ct, _ in pairs(CreatureReputation) do
                print("  " .. tostring(ct))
            end
        end
        return
    end

    local tierInput = string.upper(tostring(args[4] or "AUTO"))
    local forcedTier = nil
    if tierInput ~= "" and tierInput ~= "AUTO" then
        if tierInput == "COMMON" or tierInput == "VETERAN" or tierInput == "ELITE" or tierInput == "LEGENDARY" or tierInput == "CHAMPION" then
            forcedTier = tierInput
        else
            print("[EnemyAmbush] Invalid tier. Use one of: COMMON, VETERAN, ELITE, LEGENDARY, CHAMPION, AUTO")
            return
        end
    end

    local tier = forcedTier
    local delta = nil
    if not tier then
        local getTierFromDeltaFn = _EA_ResolveFn("EA_GetTierFromDelta", EA and EA["EA_GetTierFromDelta"])
        local rollDeltaFn = _EA_ResolveFn("EA_RollOverlevelDelta", EA and EA["EA_RollOverlevelDelta"])
        local getPartySizeFn = _EA_ResolveFn("GetPartySize", EA and EA["GetPartySize"])

        if type(getTierFromDeltaFn) == "function" and type(rollDeltaFn) == "function" then
            local partySize = 4
            if type(getPartySizeFn) == "function" then
                local okPs, outPs = pcall(getPartySizeFn, host)
                if okPs and tonumber(outPs) then
                    partySize = math.max(1, tonumber(outPs))
                end
            end
            local okDelta, outDelta = pcall(rollDeltaFn, playerLevel, partySize)
            if okDelta and tonumber(outDelta) then
                delta = tonumber(outDelta)
                local okTier, outTier = pcall(getTierFromDeltaFn, delta)
                if okTier and outTier then
                    tier = string.upper(tostring(outTier))
                end
            end
        end
    end
    if not tier or tier == "" then
        tier = "COMMON"
    end

    local candidatesByTier = {
        COMMON = 0,
        VETERAN = 0,
        ELITE = 0,
        LEGENDARY = 0,
        CHAMPION = 0,
    }
    local list = EA_BuildActiveListSafe()
    for _, enemy in ipairs(list) do
        local enemyType = tostring(enemy.creatureType or "")
        local cat = string.upper(tostring(EA_GetDebugCategory(enemy) or "COMMON"))
        if enemyType == creatureType and candidatesByTier[cat] ~= nil then
            candidatesByTier[cat] = candidatesByTier[cat] + 1
        end
    end

    local tierCandidates = tonumber(candidatesByTier[tier] or 0) or 0
    if tierCandidates <= 0 then
        print(string.format(
            "[EnemyAmbush] No active templates for type=%s tier=%s (counts: C=%d V=%d E=%d L=%d Ch=%d)",
            tostring(creatureType),
            tostring(tier),
            tonumber(candidatesByTier.COMMON) or 0,
            tonumber(candidatesByTier.VETERAN) or 0,
            tonumber(candidatesByTier.ELITE) or 0,
            tonumber(candidatesByTier.LEGENDARY) or 0,
            tonumber(candidatesByTier.CHAMPION) or 0
        ))
        return
    end

    local roll = {
        tier = tier,
        category = tier,
        spawnRole = "leader",
    }
    if delta ~= nil then
        local target = math.max(1, math.min((tonumber(playerLevel) or 1) + delta, 20))
        roll.delta = delta
        roll.targetLevel = target
        roll.playerLevel = tonumber(playerLevel) or 1
    end

    print(string.format(
        "[EnemyAmbush] Spawning type-filtered ambush: type=%s tier=%s candidates=%d budget=%d",
        tostring(creatureType), tostring(tier), tierCandidates, tonumber(pointBudget) or 0
    ))
    executeAmbushFn(host, false, playerLevel, pointBudget, 60, creatureType, nil, roll)
elseif mode == "direct" then
    if type(spawnNearFn) ~= "function" then
        print("[EnemyAmbush] SpawnHostileNearPlayer unavailable (Systems not loaded).")
        return
    end
    local count = tonumber(args[3]) or 1
    count = math.floor(count)
    count = math.min(math.max(count, 1), 30)
    local pattern = tostring(args[4] or ""):lower()
    local staggerMs = tonumber(args[5]) or 0
    staggerMs = math.floor(staggerMs)
    staggerMs = math.min(math.max(staggerMs, 0), 5000)
    local useSpread = (pattern == "spread")
    local spawnPath = useSpread and "FindValidPosition+CreateAt" or "CreateOutOfSightAtDirection"

    print(string.format(
        "[EnemyAmbush] Direct spawning %d enemies (ignores budget, spread=%s, staggerMs=%d, path=%s)",
        count, tostring(useSpread), staggerMs, spawnPath
    ))

    for i = 1, count do
        local idx = i
        local function SpawnOne()
            local roll = nil
            if useSpread then
                roll = {
                    spawnDist = 7 + ((idx - 1) % 10),
                    forceFindValidPosition = true
                }
            end
            spawnNearFn(host, 60, nil, roll)
        end

        if staggerMs > 0 and Ext and Ext.Timer and Ext.Timer.WaitFor then
            Ext.Timer.WaitFor((idx - 1) * staggerMs, SpawnOne)
        else
            SpawnOne()
        end
    end
else
    if type(executeAmbushFn) ~= "function" then
        print("[EnemyAmbush] ExecuteAmbushSpawn unavailable (Systems not loaded).")
        return
    end
    local presetName
    if mode == "preset" then
        presetName = args[3]
    else
        presetName = mode
    end
    if not presetName or presetName == "" then
        print("[EnemyAmbush] No preset provided; using location-weighted selection")
        executeAmbushFn(host, false, playerLevel, pointBudget, 60, nil)
    else
        presetName = string.upper(presetName:gsub('-', '_'))
        print(string.format("[EnemyAmbush] Spawning themed ambush: %s", presetName))
        executeAmbushFn(host, false, playerLevel, pointBudget, 60, presetName)
    end
end

elseif args[1] == "spawnrank" then
local rank = (args[2] and string.upper(args[2])) or "VETERAN"
local themeArg = args[3] and string.upper(args[3]:gsub('-', '_')) or nil
local list = EA_BuildActiveListSafe()
local pick = nil
for _, enemy in ipairs(list) do
    if ThemeAllowsEnemy(themeArg, enemy) and EA_GetDebugCategory(enemy) == rank then
        pick = enemy
        break
    end
end

if pick then
    print(string.format("[EnemyAmbush] Spawning %s tier enemy: %s", rank, pick.name))
    SpawnHostileNearPlayer(player, 60, pick, nil, themeArg)
else
    print(string.format("[EnemyAmbush] No enemy found for rank %s (theme: %s)", rank, themeArg or 'ANY'))
end


elseif args[1] == "champion" then
  local raw = args[2]
  local creatureType = raw and (raw:sub(1,1):upper() .. raw:sub(2):lower()) or nil
  local force = (string.lower(tostring(args[3] or "")) == "force")

  if not creatureType then
    print("[EnemyAmbush] Usage: !ea_test champion <CreatureType> [force]")
    print("Valid creature types:")
    for ct, _ in pairs(CreatureReputation or {}) do
      print("  " .. tostring(ct))
    end
    return
  end

  -- Respect your per-type cooldown gate if available
  if (not force) and EA_CanSpawnChampionForType and not EA_CanSpawnChampionForType(creatureType) then
    print(string.format("[EnemyAmbush] Champion spawn on cooldown for type %s (try later)", creatureType))
    return
  end

  if force then
    print(string.format("[EnemyAmbush] Forcing champion spawn (ignoring cooldown): %s", creatureType))
  end
  print(string.format("[EnemyAmbush] Summoning champion: %s", creatureType))
  local resolutionContext = {
    context = force and "debug_force" or "debug_direct",
    pathKind = "forced_or_queued",
  }
  local resolution = nil
  if type(EA_ResolveChampionSpawnData) == "function" then
    resolution = EA_ResolveChampionSpawnData(player, creatureType, resolutionContext)
  end
  if not SpawnChampionNow(player, creatureType, resolution, resolutionContext) then
    if type(resolution) == "table" then
      print(string.format(
        "[EnemyAmbush] Champion spawn failed: source=%s resolveReason=%s policy=%s provider=%s",
        tostring(resolution.source or "n/a"),
        tostring(resolution.reason or "n/a"),
        tostring(resolution.policy or "n/a"),
        tostring(resolution.providerId or "n/a")
      ))
    else
      print("[EnemyAmbush] Champion spawn failed")
    end
  end


elseif args[1] == "spawntype" then
local creatureType = args[2]
if not creatureType or not CreatureReputation[creatureType] then
    print("[EnemyAmbush] Invalid creature type. Valid types:")
    for ct, _ in pairs(CreatureReputation) do
        print("  " .. ct)
    end
    return
end

-- Find an enemy of this type
local list = EA_BuildActiveListSafe()
local found = nil
for _, enemy in ipairs(list) do
    if enemy.creatureType == creatureType then
        found = enemy
        break
    end
end

if found then
    print(string.format("[EnemyAmbush] Force spawning %s: %s", creatureType, found.name))
    SpawnHostileNearPlayer(player, 60, found)
else
    print(string.format("[EnemyAmbush] No %s enemies found in active list", creatureType))
end

elseif args[1] == "typelist" then
local creatureType = EA_NormalizeCreatureTypeInput(args[2])
if not creatureType then
    print("[EnemyAmbush] Usage: !ea_test typelist <CreatureType> [limit]")
    return
end

local rows = EA_GetUniqueTemplatesForType(creatureType)
if #rows == 0 then
    print(string.format("[EnemyAmbush] typelist: no active templates for type=%s", tostring(creatureType)))
    return
end

local limit = tonumber(args[3]) or #rows
limit = math.max(1, math.min(math.floor(limit), #rows))
print(string.format("[EnemyAmbush] typelist %s: showing %d/%d unique templates", tostring(creatureType), limit, #rows))
for i = 1, limit do
    local r = rows[i]
    print(string.format("  %d. %s | template=%s | tier=%s | lvl=%d",
        i, tostring(r.name), tostring(r.template), tostring(r.tier), tonumber(r.level) or 1))
end

elseif args[1] == "typetest" then
local creatureType = EA_NormalizeCreatureTypeInput(args[2])
if not creatureType then
    print("[EnemyAmbush] Usage: !ea_test typetest <CreatureType> [count|all]")
    return
end

local rows = EA_GetUniqueTemplatesForType(creatureType)
if #rows == 0 then
    print(string.format("[EnemyAmbush] typetest: no active templates for type=%s", tostring(creatureType)))
    return
end

local countArg = string.lower(tostring(args[3] or "all"))
local target = #rows
if countArg ~= "all" and countArg ~= "" then
    local n = tonumber(countArg) or #rows
    target = math.max(1, math.min(math.floor(n), #rows))
end

local x, y, z = SafeGetPosition(player)
if not x then
    print("[EnemyAmbush] typetest: could not get host position")
    return
end

local okCount = 0
local failCount = 0
local failRows = {}
for i = 1, target do
    local r = rows[i]
    local ring = math.floor((i - 1) / 8)
    local slot = (i - 1) % 8
    local angle = (slot / 8) * (math.pi * 2)
    local dist = 2.0 + (ring * 1.5)
    local sx = x + math.cos(angle) * dist
    local sz = z + math.sin(angle) * dist
    local created = nil
    local ok, guid = pcall(Osi.CreateAt, r.template, sx, y, sz, 1, 1, "")
    if ok and guid and guid ~= "" then
        created = guid
        okCount = okCount + 1
        if Osi and Osi.RequestDelete then
            pcall(Osi.RequestDelete, created)
        end
    else
        failCount = failCount + 1
        if #failRows < 25 then
            failRows[#failRows + 1] = {
                index = i,
                name = r.name,
                template = r.template
            }
        end
    end
end

print(string.format(
    "[EnemyAmbush] typetest %s: tested=%d ok=%d fail=%d (CreateAt->RequestDelete smoke test)",
    tostring(creatureType), target, okCount, failCount
))
if failCount > 0 then
    print("[EnemyAmbush] typetest failures (first 25):")
    for _, f in ipairs(failRows) do
        print(string.format("  - #%d %s | template=%s", tonumber(f.index) or 0, tostring(f.name), tostring(f.template)))
    end
end

elseif args[1] == "list" then
local list = EA_BuildActiveListSafe()
print(string.format("[EnemyAmbush] %d enemies available:", #list))
for i, enemy in ipairs(list) do
    print(string.format("  %d. %s (Level %d, Type: %s)", 
        i, enemy.name, enemy.level or 0, enemy.creatureType or "Unknown"))
end

elseif args[1] == "spawnhostile" then
    -- Spawn a vanilla goblin and force it into our isolated hostile pipeline
    local x, y, z = SafeGetPosition(player)
    if not x or not y or not z then
        print("[EnemyAmbush] Could not get player position")
        return
    end
    local enemy = Osi.CreateAt("2db928f2-f1c5-4b5a-8751-168f9f292249", x + 3, y, z, 1, 1, "") -- Goblin Brawler

    if not enemy or enemy == "" then
        print("[EnemyAmbush] Failed to create test enemy")
        return
    end

    if Osi.MakeNPC then Osi.MakeNPC(enemy) end
    print(string.format("[EnemyAmbush] Spawned test enemy: %s", enemy))
    print("[EnemyAmbush] spawnhostile is hostility-only debug (it does not apply ambush rewards/status packages).")

    -- Primary path
    EA_MakeAmbushHostile(enemy, player)

    -- Extra fallback for edge cases where hostility doesn't immediately flip.
    if Osi.SetCanFight then
        pcall(Osi.SetCanFight, enemy, 1)
    end
    if Osi.SetCanJoinCombat then
        pcall(Osi.SetCanJoinCombat, enemy, 1)
    end
    if Osi.SetRelationTemporaryHostile then
        pcall(Osi.SetRelationTemporaryHostile, enemy, player)
    end
    if Ext and Ext.Timer and Ext.Timer.WaitFor and Osi.IsInCombat then
        Ext.Timer.WaitFor(300, function()
            if Osi.ObjectExists and Osi.ObjectExists(enemy) == 1 and Osi.IsInCombat(enemy) ~= 1 then
                EA_MakeAmbushHostile(enemy, player)
                if Osi.Attack then
                    pcall(Osi.Attack, enemy, player)
                end
            end
        end)
        Ext.Timer.WaitFor(800, function()
            print(string.format("[EnemyAmbush] Enemy in combat after 0.8s? %s", tostring(Osi.IsInCombat(enemy))))
        end)
    elseif Osi.IsInCombat then
        print(string.format("[EnemyAmbush] Enemy in combat? %s", tostring(Osi.IsInCombat(enemy))))
    end
    return

elseif args[1] == "hostile" then
    local enemy = args[2]
    if not enemy or enemy == "" then
        print("[EnemyAmbush] Usage: !ea_test hostile [enemy_uuid]")
        return
    end
    if Osi.ObjectExists and Osi.ObjectExists(enemy) ~= 1 then
        print(string.format("[EnemyAmbush] hostile: object does not exist: %s", tostring(enemy)))
        return
    end

    print(string.format("[EnemyAmbush] Forcing hostile via EA pipeline: %s", enemy))
    EA_MakeAmbushHostile(enemy, player)

    if Ext and Ext.Timer and Ext.Timer.WaitFor and Osi.IsInCombat then
        Ext.Timer.WaitFor(800, function()
            if Osi.ObjectExists and Osi.ObjectExists(enemy) ~= 1 then
                print(string.format("[EnemyAmbush] hostile target no longer exists after 0.8s: %s", tostring(enemy)))
                return
            end
            print(string.format("[EnemyAmbush] Enemy in combat after 0.8s? %s", tostring(Osi.IsInCombat(enemy))))
        end)
    elseif Osi.IsInCombat then
        print(string.format("[EnemyAmbush] Enemy in combat? %s", tostring(Osi.IsInCombat(enemy))))
    end
    return

elseif args[1] == "attack" then
-- Simple attack test
local x, y, z = SafeGetPosition(player)
if not x or not y or not z then
    print("[EnemyAmbush] Could not get player position")
    return
end
local enemy = Osi.CreateAt("2db928f2-f1c5-4b5a-8751-168f9f292249", x + 3, y, z, 1, 1, "") -- Goblin

if enemy and enemy ~= "" then
    print(string.format("[EnemyAmbush] Created enemy: %s", enemy))
    
    -- Clear ownership and make NPC (capability-guarded for API compatibility).
    if Osi.ClearOwnership then
        Osi.ClearOwnership(enemy)
    elseif EA_DebugGetSettingBool("MCM_DebugMode", false) and not EnemyAmbush._eaClearOwnershipMissingLogged then
        EnemyAmbush._eaClearOwnershipMissingLogged = true
        print("[EnemyAmbush][Debug] ClearOwnership unavailable; using MakeNPC fallback only.")
    end
    if Osi.MakeNPC then
        Osi.MakeNPC(enemy)
    end
    EA_MakeAmbushHostile(enemy, player)
    
    -- Simple attack
    print("[EnemyAmbush] Issuing Attack command")
    Osi.Attack(enemy, player)
    
    -- Check result
    Ext.Timer.WaitFor(1000, function()
        local inCombat = Osi.IsInCombat(enemy)
        print(string.format("[EnemyAmbush] Enemy in combat after 1 second: %s", tostring(inCombat)))
    end)
end


elseif args[1] == "testrep" then
local creatureType = args[2] or "Humanoid"
local oldRep = CreatureReputation[creatureType] or 0
CreatureReputation[creatureType] = oldRep - 1
SaveReputation()
print(string.format("[EnemyAmbush] TEST: %s reputation: %d -> %d", 
    creatureType, oldRep, CreatureReputation[creatureType]))

elseif args[1] == "clearcache" then
    local flushPoolCache = _EA_ResolveFn("EA_FlushPoolCacheState", nil)
    if type(flushPoolCache) == "function" then
        pcall(flushPoolCache, true)
    end
    local resetStatusCache = EA and EA["EA_ResetStatusExistenceCache"]
    if type(resetStatusCache) == "function" then
        pcall(resetStatusCache)
    end
    print("[EnemyAmbush] All caches cleared (summon pool + weighted cache + template cache)")
    return

elseif args[1] == "providerprobe" then
    local action = string.lower(tostring(args[2] or "show"))
    local api = EA_GetProviderProbeApi()
    if action == "show" or action == "status" then
        EA_PrintProviderProbeState()
        return
    elseif action == "register" then
        local fn = api.register
        if type(fn) ~= "function" then
            print("[EnemyAmbush] providerprobe register unavailable (RegisterEnemyProvider missing).")
            return
        end
        local ok, err = fn(EA_PROVIDER_PROBE_ID, { EA_MakeProviderProbeEntry("a") }, {})
        if ok == true then
            print(string.format("[EnemyAmbush] providerprobe register OK: %s", tostring(EA_PROVIDER_PROBE_ID)))
        else
            print(string.format("[EnemyAmbush] providerprobe register failed: %s", tostring(err or "unknown")))
        end
        EA_PrintProviderProbeState()
        return
    elseif action == "edit" or action == "add" then
        local fn = api.registerTemplate
        if type(fn) ~= "function" then
            print("[EnemyAmbush] providerprobe edit unavailable (RegisterEnemyTemplate missing).")
            return
        end
        local ok, err = fn(EA_PROVIDER_PROBE_ID, EA_MakeProviderProbeEntry("b"))
        if ok == true then
            print(string.format("[EnemyAmbush] providerprobe edit OK: %s", tostring(EA_PROVIDER_PROBE_ID)))
        else
            print(string.format("[EnemyAmbush] providerprobe edit failed: %s", tostring(err or "unknown")))
        end
        EA_PrintProviderProbeState()
        return
    elseif action == "unregister" or action == "remove" or action == "clear" or action == "reset" then
        local fn = api.unregister
        if type(fn) ~= "function" then
            print("[EnemyAmbush] providerprobe unregister unavailable (UnregisterEnemyProvider missing).")
            return
        end
        local ok, err = fn(EA_PROVIDER_PROBE_ID)
        if ok == true then
            print(string.format("[EnemyAmbush] providerprobe unregister OK: %s", tostring(EA_PROVIDER_PROBE_ID)))
        elseif tostring(err or "") == "provider not found" then
            print(string.format("[EnemyAmbush] providerprobe already absent: %s", tostring(EA_PROVIDER_PROBE_ID)))
        else
            print(string.format("[EnemyAmbush] providerprobe unregister failed: %s", tostring(err or "unknown")))
        end
        EA_PrintProviderProbeState()
        return
    elseif action == "cycle" then
        local registerFn = api.register
        local editFn = api.registerTemplate
        local unregisterFn = api.unregister
        if type(registerFn) ~= "function" or type(editFn) ~= "function" or type(unregisterFn) ~= "function" then
            print("[EnemyAmbush] providerprobe cycle unavailable (provider API missing).")
            return
        end
        unregisterFn(EA_PROVIDER_PROBE_ID)
        local okRegister, errRegister = registerFn(EA_PROVIDER_PROBE_ID, { EA_MakeProviderProbeEntry("a") }, {})
        print(string.format("[EnemyAmbush] providerprobe cycle register => ok=%s err=%s", tostring(okRegister == true), tostring(errRegister)))
        EA_PrintProviderProbeState()
        local okEdit, errEdit = editFn(EA_PROVIDER_PROBE_ID, EA_MakeProviderProbeEntry("b"))
        print(string.format("[EnemyAmbush] providerprobe cycle edit => ok=%s err=%s", tostring(okEdit == true), tostring(errEdit)))
        EA_PrintProviderProbeState()
        local okUnregister, errUnregister = unregisterFn(EA_PROVIDER_PROBE_ID)
        print(string.format("[EnemyAmbush] providerprobe cycle unregister => ok=%s err=%s", tostring(okUnregister == true), tostring(errUnregister)))
        EA_PrintProviderProbeState()
        return
    else
        print("[EnemyAmbush] providerprobe commands:")
        print("  !ea_test providerprobe show - Print temporary provider state and active-list matches")
        print("  !ea_test providerprobe register - Register probe provider entry A and trigger EnemyProvidersChanged")
        print("  !ea_test providerprobe edit - Add probe provider entry B and trigger EnemyProvidersChanged")
        print("  !ea_test providerprobe unregister - Remove probe provider and trigger EnemyProvidersChanged")
        print("  !ea_test providerprobe cycle - Run register/edit/unregister sequence with state dumps")
        EA_PrintProviderProbeState()
        return
    end

elseif args[1] == "api" then
    local action = string.lower(tostring(args[2] or "show"))
    local target = string.lower(tostring(args[3] or ""))
    local api = EA_GetAuthoredApiProbeApi()
    if action == "show" or action == "status" then
        EA_PrintAuthoredApiProbeSurface(api)
        return
    elseif (action == "authored_smoke")
        or ((action == "authored" or action == "ambush" or action == "ambushes") and (target == "smoke" or target == "authored_smoke" or target == "cycle" or target == "test" or target == "verify"))
    then
        EA_RunAuthoredApiSmoke()
        return
    elseif (action == "trigger_smoke")
        or ((action == "trigger") and (target == "smoke" or target == "trigger_smoke" or target == "test" or target == "verify"))
    then
        EA_RunAuthoredApiTriggerSmoke()
        return
    elseif (action == "custom_smoke")
        or ((action == "custom") and (target == "smoke" or target == "custom_smoke" or target == "test" or target == "verify"))
    then
        EA_RunAuthoredApiCustomSmoke()
        return
    else
        print("[EnemyAmbush] API debug commands:")
        print("  !ea_test api show - Print D2 authored API export presence on EnemyAmbush.* and EnemyAmbush.API.*")
        print("  !ea_test api authored_smoke - Run internal D2-1 authored API register/get/state/unregister smoke cycle")
        print("  !ea_test api trigger_smoke - Run internal D2-2 TriggerAmbushDefinition smoke cycle")
        print("  !ea_test api custom_smoke - Run internal D2-3 TriggerCustomAmbush smoke cycle")
        return
    end

elseif args[1] == "debug" then
    local settings = EnemyAmbush and EnemyAmbush.SettingsSnapshot
    if args[2] == "on" then
        if type(settings) == "table" then
            settings["MCM_DebugMode"] = true
        end
        if type(EA_ApplySettingsToLocals) == "function" then
            pcall(EA_ApplySettingsToLocals)
        end
        print("[EnemyAmbush] Debug mode ENABLED (MCM_DebugMode=true)")
    elseif args[2] == "off" then
        if type(settings) == "table" then
            settings["MCM_DebugMode"] = false
        end
        if type(EA_ApplySettingsToLocals) == "function" then
            pcall(EA_ApplySettingsToLocals)
        end
        print("[EnemyAmbush] Debug mode DISABLED (MCM_DebugMode=false)")
    else
        print("[EnemyAmbush] Usage: !ea_test debug on|off")
    end
    return

elseif args[1] == "region" or args[1] == "getregion" then
    EA_PrintRegionDebug(player, true)
    return

elseif args[1] == "regionwatch" then
    local mode = string.lower(tostring(args[2] or "on"))
    if mode == "off" then
        EA_RegionWatchEnabled = false
        print("[EnemyAmbush] Region watch DISABLED")
        return
    end

    if mode == "now" or mode == "once" then
        EA_PrintRegionDebug(player, true)
        return
    end

    local interval = tonumber(args[3])
    if interval and interval > 0 then
        EA_RegionWatchIntervalMs = math.max(250, math.floor(interval * 1000))
    else
        EA_RegionWatchIntervalMs = 30000
    end

    EA_RegionWatchEnabled = true
    EA_RegionWatchLastRaw = nil
    EA_RegionWatchLastCanonical = nil
    EA_RegionWatchLastSafeZones = nil
    EA_RegionWatchLastTriggerBlocked = nil
    EA_PrintRegionDebug(player, true)
    if Ext and Ext.Timer and Ext.Timer.WaitFor then
        Ext.Timer.WaitFor(EA_RegionWatchIntervalMs, EA_RegionWatchTick)
    end
    print(string.format("[EnemyAmbush] Region watch ENABLED (interval=%.2fs). Walk around; logs print on region/safe-zone change.", EA_RegionWatchIntervalMs / 1000))
    return

elseif args[1] == "vfx" then
    local effect = EA_ResolveVFXInput(args[2])
    if not effect then
        print("[EnemyAmbush] Usage: !ea_test vfx <effectId|alias> [targetUuid|player|last]")
        print("[EnemyAmbush] Aliases: dimdoor, mistycast")
        return
    end
    local target = EA_ResolveFXTarget(args[3], player)
    if not target then
        print(string.format("[EnemyAmbush] Invalid target for VFX: %s", tostring(args[3])))
        return
    end
    local ok = EA_TestPlayVFX(target, effect)
    print(string.format("[EnemyAmbush] VFX test: target=%s effect=%s ok=%s", tostring(target), tostring(effect), tostring(ok)))
    return

elseif args[1] == "sfx" then
    local soundId = EA_ResolveSFXInput(args[2])
    if not soundId then
        print("[EnemyAmbush] Usage: !ea_test sfx <soundEvent|alias> [targetUuid|player|last]")
        print("[EnemyAmbush] Aliases: stinger, dark, psy, silent")
        return
    end
    local target = EA_ResolveFXTarget(args[3], player)
    if not target then
        print(string.format("[EnemyAmbush] Invalid target for SFX: %s", tostring(args[3])))
        return
    end
    local ok = EA_TestPlaySFX(target, soundId)
    print(string.format("[EnemyAmbush] SFX test: target=%s sound=%s ok=%s", tostring(target), tostring(soundId), tostring(ok)))
    return

elseif args[1] == "debugtext" then
    local target = EA_ResolveFXTarget(args[2], player)
    if not target then
        print("[EnemyAmbush] Usage: !ea_test debugtext [targetUuid|player|host|me|last] [text]")
        return
    end
    local text = EA_JoinArgs(3, "EA DebugText Test")
    if text == "" then
        text = "EA DebugText Test"
    end
    local ok = EA_TestDebugText(target, text)
    print(string.format("[EnemyAmbush] DebugText test: target=%s text=%s ok=%s", tostring(target), tostring(text), tostring(ok)))
    return

elseif args[1] == "escapestatus" then
    local target = EA_ResolveFXTarget(args[2], player)
    if not target then
        print("[EnemyAmbush] Usage: !ea_test escapestatus [targetUuid|player|host|me|last] [seconds]")
        return
    end
    local duration = tonumber(args[3]) or 6
    duration = math.max(1, math.floor(duration))
    local ok = EA_TestApplyStatus(target, "EA_ESCAPE_IMMINENT", duration)
    print(string.format(
        "[EnemyAmbush] Escape status test: target=%s status=%s duration=%ss ok=%s",
        tostring(target),
        "EA_ESCAPE_IMMINENT",
        tostring(duration),
        tostring(ok)
    ))
    return

elseif args[1] == "fleefrom" then
    local target = EA_ResolveFXTarget(args[2], player)
    if not target then
        print("[EnemyAmbush] Usage: !ea_test fleefrom [targetUuid|player|host|me|last] [fromUuid|player|host|me|last] [range]")
        return
    end
    local fleeFrom = EA_ResolveFXTarget(args[3], player)
    if not fleeFrom then
        print("[EnemyAmbush] Usage: !ea_test fleefrom [targetUuid|player|host|me|last] [fromUuid|player|host|me|last] [range]")
        return
    end
    if target == fleeFrom then
        print("[EnemyAmbush] fleefrom: target and source must be different")
        return
    end
    local range = tonumber(args[4]) or 10.0
    local ok = EA_TestFleeFromObject(target, fleeFrom, range)
    print(string.format(
        "[EnemyAmbush] FleeFromObject test: target=%s from=%s range=%.1f ok=%s",
        tostring(target),
        tostring(fleeFrom),
        tonumber(range) or 10.0,
        tostring(ok)
    ))
    return

elseif args[1] == "arrivalpreview" then
    local target = EA_ResolveFXTarget(args[2], player)
    if not target then
        print("[EnemyAmbush] Usage: !ea_test arrivalpreview [targetUuid|player|last] [vfxAliasOrId] [sfxAliasOrId]")
        return
    end

    local vfx = EA_ResolveVFXInput(args[3] or EA_TEST_VFX_MISTY_STEP_CAST)
    local sfx = EA_ResolveSFXInput(args[4] or EA_TEST_SFX_STINGER)
    local okVFX = EA_TestPlayVFX(target, vfx)
    local okSFX = EA_TestPlaySFX(target, sfx)
    print(string.format(
        "[EnemyAmbush] Arrival preview: target=%s vfx=%s(%s) sfx=%s(%s)",
        tostring(target), tostring(vfx), tostring(okVFX), tostring(sfx), tostring(okSFX)
    ))
    return

elseif args[1] == "escapepreview" then
    local target = EA_ResolveFXTarget(args[2], player)
    if not target then
        print("[EnemyAmbush] Usage: !ea_test escapepreview [targetUuid|last|player] [vfxAliasOrId] [sfxAliasOrId] [deleteMs]")
        return
    end

    local vfx = EA_ResolveVFXInput(args[3] or EA_TEST_VFX_DIMENSION_DOOR_DISAPPEAR)
    local sfx = EA_ResolveSFXInput(args[4] or EA_TEST_SFX_STINGER)
    local deleteMs = tonumber(args[5]) or 0
    deleteMs = math.max(0, math.floor(deleteMs))

    local okVFX = EA_TestPlayVFX(target, vfx)
    local okSFX = EA_TestPlaySFX(target, sfx)

    if deleteMs > 0 and target ~= player and Ext and Ext.Timer and Ext.Timer.WaitFor and Osi and Osi.RequestDelete then
        local doomed = target
        Ext.Timer.WaitFor(deleteMs, function()
            if Osi.ObjectExists and Osi.ObjectExists(doomed) == 1 then
                pcall(Osi.RequestDelete, doomed)
            end
        end)
    end

    print(string.format(
        "[EnemyAmbush] Escape preview: target=%s vfx=%s(%s) sfx=%s(%s) deleteMs=%d",
        tostring(target), tostring(vfx), tostring(okVFX), tostring(sfx), tostring(okSFX), deleteMs
    ))
    return

elseif args[1] == "escapetune" then
    local mode = string.lower(tostring(args[2] or "show"))
    if mode == "quick" then
        EA_ApplyEscapeTune({
            ["MCM_EnableAmbusherEscape"] = true,
            ["MCM_EscapeStartTurn"] = 1,
            ["MCM_EscapeDC"] = 8,
            ["MCM_EscapeHPThreshold"] = 100,
            ["MCM_EscapeMaxPerCombat"] = 4,
        })
        print("[EnemyAmbush] Escape tune set to QUICK (turn=1, dc=8, hp<=100, max=4)")
        EA_PrintEscapeTuneSnapshot()
        return
    elseif mode == "default" or mode == "rc" then
        EA_ApplyEscapeTune({
            ["MCM_EnableAmbusherEscape"] = true,
            ["MCM_EscapeStartTurn"] = 6,
            ["MCM_EscapeDC"] = 14,
            ["MCM_EscapeHPThreshold"] = 50,
            ["MCM_EscapeMaxPerCombat"] = 1,
        })
        print("[EnemyAmbush] Escape tune restored to default preset values (turn=6, dc=14, hp<=50, max=1)")
        EA_PrintEscapeTuneSnapshot()
        return
    end
    print("[EnemyAmbush] Usage: !ea_test escapetune quick|default|show")
    EA_PrintEscapeTuneSnapshot()
    return

elseif args[1] == "hasteall" then
    local mode = string.lower(tostring(args[2] or "show"))
    if mode == "on" then
        if type(EA_SetDebugHasteAllAmbushers) == "function" then
            EA_SetDebugHasteAllAmbushers(true)
            print("[EnemyAmbush] Debug haste-all-ambushers ENABLED")
        else
            print("[EnemyAmbush] hasteall unavailable (missing export)")
        end
    elseif mode == "off" then
        if type(EA_SetDebugHasteAllAmbushers) == "function" then
            EA_SetDebugHasteAllAmbushers(false)
            print("[EnemyAmbush] Debug haste-all-ambushers DISABLED")
        else
            print("[EnemyAmbush] hasteall unavailable (missing export)")
        end
    else
        local enabled = false
        if type(EA_IsDebugHasteAllAmbushers) == "function" then
            enabled = (EA_IsDebugHasteAllAmbushers() == true)
        end
        print(string.format("[EnemyAmbush] Debug haste-all-ambushers: %s", tostring(enabled)))
        print("[EnemyAmbush] Usage: !ea_test hasteall on|off|show")
    end
    return

elseif args[1] == "championreset" then
    if type(EA_ResetChampionCooldowns) == "function" then
        EA_ResetChampionCooldowns()
        print("[EnemyAmbush] Champion per-type cooldowns cleared")
    else
        print("[EnemyAmbush] championreset unavailable (missing export)")
    end
    return

elseif args[1] == "championdiag" then
    local mode = string.lower(tostring(args[2] or "show"))
    if mode == "on" then
        local current = EA_SetChampionDiagModeSafe("on")
        print(string.format("[EnemyAmbush] Champion diagnostics ENABLED (mode=%s)", tostring(current)))
        EA_PrintChampionDiagSnapshot(player)
    elseif mode == "off" then
        local current = EA_SetChampionDiagModeSafe("off")
        print(string.format("[EnemyAmbush] Champion diagnostics DISABLED (mode=%s)", tostring(current)))
    elseif mode == "once" then
        local current = EA_SetChampionDiagModeSafe("once")
        print(string.format("[EnemyAmbush] Champion diagnostics armed for one long-rest pass (mode=%s)", tostring(current)))
        EA_PrintChampionDiagSnapshot(player)
    elseif mode == "show" then
        print(string.format("[EnemyAmbush] Champion diagnostics mode: %s", tostring(EA_GetChampionDiagModeSafe())))
        EA_PrintChampionDiagSnapshot(player)
    else
        print(string.format("[EnemyAmbush] Champion diagnostics mode: %s", tostring(EA_GetChampionDiagModeSafe())))
        print("[EnemyAmbush] Usage: !ea_test championdiag on|off|once|show")
    end
    return

elseif args[1] == "championpolicy" then
    local mode = string.lower(tostring(args[2] or "show"))
    if mode == "show" or mode == "" then
        print(string.format("[EnemyAmbush] Champion fallback policy: %s", tostring(EA_GetChampionFallbackPolicyModeSafe())))
        EA_PrintChampionDiagSnapshot(player)
    else
        local current, changed = EA_SetChampionFallbackPolicyModeSafe(mode)
        if changed then
            print(string.format("[EnemyAmbush] Champion fallback policy set to %s", tostring(current)))
            EA_PrintChampionDiagSnapshot(player)
        else
            print(string.format("[EnemyAmbush] Champion fallback policy: %s", tostring(current)))
            print("[EnemyAmbush] Usage: !ea_test championpolicy show|compat|strict|debug_only|default")
        end
    end
    return

elseif args[1] == "championqueue" then
    local ct = EA_NormalizeCreatureTypeInput(args[2])
    if not ct then
        print("[EnemyAmbush] Usage: !ea_test championqueue <CreatureType>")
        return
    end
    if type(CreatureReputation) ~= "table" or CreatureReputation[ct] == nil then
        print(string.format("[EnemyAmbush] Unknown creature type for championqueue: %s", tostring(ct)))
        return
    end
    local queue = EA_DebugGetChampionQueue()
    if type(queue) ~= "table" then
        print("[EnemyAmbush] championqueue failed: queue table unavailable")
        return
    end

    local now = 0
    if type(EA_NowMs) == "function" then
        local okNow, outNow = pcall(EA_NowMs)
        if okNow and tonumber(outNow) then
            now = tonumber(outNow)
        end
    end

    queue[ct] = {
        ts = now,
        repAtSet = math.min(-20, tonumber(CreatureReputation and CreatureReputation[ct]) or -20),
        reason = "debug_seed"
    }

    if type(EA_Dirty) == "function" then
        EA_Dirty()
    elseif Ext and Ext.Vars and Ext.Vars.DirtyModVariables then
        pcall(Ext.Vars.DirtyModVariables, tostring((EnemyAmbush and EnemyAmbush.ModuleUUID) or "96f24297-6ed9-455c-aaa1-ac9c358a8d35"))
    end

    print(string.format("[EnemyAmbush] Queued guaranteed champion for %s", tostring(ct)))
    EA_PrintChampionDiagSnapshot(player)
    return

elseif args[1] == "championarm" then
    local ct = EA_NormalizeCreatureTypeInput(args[2])
    if not ct then
        print("[EnemyAmbush] Usage: !ea_test championarm <CreatureType> [run]")
        print("  run: immediately execute long-rest TriggerAmbush path with cooldown/scripted/tutorial bypass")
        return
    end
    if type(CreatureReputation) ~= "table" or CreatureReputation[ct] == nil then
        print(string.format("[EnemyAmbush] Unknown creature type for championarm: %s", tostring(ct)))
        return
    end
    local queue = EA_DebugGetChampionQueue()
    if type(queue) ~= "table" then
        print("[EnemyAmbush] championarm failed: queue table unavailable")
        return
    end

    local now = 0
    if type(EA_NowMs) == "function" then
        local okNow, outNow = pcall(EA_NowMs)
        if okNow and tonumber(outNow) then
            now = tonumber(outNow)
        end
    end

    local rep = tonumber(CreatureReputation[ct]) or 0
    if rep > -20 then
        rep = -20
        CreatureReputation[ct] = rep
        if type(SaveReputation) == "function" then
            SaveReputation()
        end
    end

    queue[ct] = {
        ts = now,
        repAtSet = rep,
        reason = "debug_championarm",
    }
    if type(EA_Dirty) == "function" then
        EA_Dirty()
    end

    print(string.format("[EnemyAmbush] Armed guaranteed champion for %s (rep=%d)", tostring(ct), math.floor(rep)))

    local runNow = (string.lower(tostring(args[3] or "")) == "run")
    if runNow then
        local opts = {
            skipTutorial = true,
            skipCooldown = true,
            skipScripted = true,
            flowLabel = "DebugChampionArm",
        }
        TriggerAmbush(player, true, true, opts)
        print("[EnemyAmbush] championarm run: executed long-rest TriggerAmbush path.")
    else
        print("[EnemyAmbush] championarm queued. Run '!ea_test championarm <CreatureType> run' to execute immediately.")
    end
    EA_PrintChampionDiagSnapshot(player)
    return

elseif args[1] == "verify" then
-- Rebuild active list with current toggles
local list = EA_BuildActiveListSafe()

  local badGuids, total = {}, 0
  for _, e in ipairs(list) do
    total = total + 1
    if not EA_GuidLooksValid(e.template) then
      badGuids[#badGuids+1] = string.format("%s  (%s)", e.name or "Unnamed", e.template or "nil")
    end
  end

-- Check ambusher + champion statuses that we apply
local statusNames = {
  "EA_AMBUSHER"
}

local authoredChampionStatusByType =
  (SystemsDataTables and SystemsDataTables.CHAMPION_TYPE_STATUS_BY_TYPE)
  or {
    Aberration = "EA_CHAMPION_ABERRATION",
    Beast = "EA_CHAMPION_BEAST",
    Celestial = "EA_CHAMPION_CELESTIAL",
    Construct = "EA_CHAMPION_CONSTRUCT",
    Dragon = "EA_CHAMPION_DRAGON",
    Elemental = "EA_CHAMPION_ELEMENTAL",
    Fey = "EA_CHAMPION_FEY",
    Fiend = "EA_CHAMPION_FIEND",
    Giant = "EA_CHAMPION_GIANT",
    Humanoid = "EA_CHAMPION_HUMANOID",
    Monstrosity = "EA_CHAMPION_MONSTROSITY",
    Ooze = "EA_CHAMPION_OOZE",
    Plant = "EA_CHAMPION_PLANT",
    Undead = "EA_CHAMPION_UNDEAD",
  }

-- Only validate authored champion type packages; provider/custom reputation keys do not imply EA_CHAMPION_* stats.
if type(CreatureReputation) == "table" then
  for creatureType, _ in pairs(CreatureReputation) do
    local statusName = authoredChampionStatusByType[tostring(creatureType)]
    if statusName then
      statusNames[#statusNames+1] = statusName
    end
  end
end

-- Optional: include legacy champion.template statuses only while debugging.
if EA_DebugGetSettingBool("MCM_DebugMode", false) then
  local championTemplates =
      (EnemyAmbush and EnemyAmbush._DEBUG_CHAMPION_TEMPLATES)
      or (EnemyAmbush and EnemyAmbush.CHAMPION_TEMPLATES)
      or CHAMPION_TEMPLATES
      or {}

  for _, t in pairs(championTemplates) do
    if type(t) == "table" and t.status then
      statusNames[#statusNames+1] = t.status
    end
  end
end

  local missingRequired = {}
  local missingExternal = {}
  for _, s in ipairs(statusNames) do
    if not StatExists(s, false) then
      if type(s) == "string" and s:match("^EA_") then
        missingRequired[#missingRequired + 1] = s
      else
        missingExternal[#missingExternal + 1] = s
      end
    end
  end

  print(string.format("[EnemyAmbush][verify] Active enemies: %d", total))
  if #badGuids > 0 then
    print("[EnemyAmbush][verify] Invalid GUID format (these won't spawn):")
    for _, line in ipairs(badGuids) do print("  - "..line) end
  else
    print("[EnemyAmbush][verify] All enemy templates have valid GUID formatting.")
  end

  if #missingRequired > 0 then
    print("[EnemyAmbush][verify] Missing required EA status stats:")
    for _, s in ipairs(missingRequired) do print("  - "..s) end
  else
    print("[EnemyAmbush][verify] Required EA statuses: OK")
  end

  if #missingExternal > 0 then
    print("[EnemyAmbush][verify] Missing external/non-EA status refs (informational):")
    for _, s in ipairs(missingExternal) do print("  - "..s) end
  else
    print("[EnemyAmbush][verify] External/non-EA status refs: OK")
  end
  
  elseif args[1] == "dump" then
    local target = args[2]
    EA_TestDump(target)
    return
	
elseif args[1] == "verifytemplates" then
  local list = EA_BuildActiveListSafe()

  if not Ext or not Ext.Template or not Ext.Template.GetRootTemplate then
    print("[EnemyAmbush] Ext.Template.GetRootTemplate not available; cannot verify templates in this environment.")
    return
  end

  local badGuids, missingTemplates, total = {}, {}, 0

  for _, e in ipairs(list) do
    total = total + 1
    if not EA_GuidLooksValid(e.template) then
      badGuids[#badGuids+1] = string.format("%s  (%s)", e.name or "Unnamed", e.template or "nil")
    else
      local ok, tmpl = pcall(Ext.Template.GetRootTemplate, e.template)
      if (not ok) or tmpl == nil then
        missingTemplates[#missingTemplates+1] = string.format("%s  (%s)", e.name or "Unnamed", e.template or "nil")
      end
    end
  end

  print(string.format("[EnemyAmbush] verifytemplates: checked %d entries", total))

  if #badGuids > 0 then
    print(string.format("[EnemyAmbush] Invalid GUID format (%d):", #badGuids))
    for _, s in ipairs(badGuids) do print("  " .. s) end
  else
    print("[EnemyAmbush] GUID format: OK")
  end

  if #missingTemplates > 0 then
    print(string.format("[EnemyAmbush] Missing root templates (%d):", #missingTemplates))
    for _, s in ipairs(missingTemplates) do print("  " .. s) end
  else
    print("[EnemyAmbush] Root template existence: OK")
  end

  return


elseif args[1] == "verifystatuses" then
  local list = EA_BuildActiveListSafe()

  local statusSet = {}

  local function AddStatus(name, src)
    if not name or name == "" then return end
    if statusSet[name] then return end
    statusSet[name] = src or true
  end

  -- Core statuses we apply
  AddStatus("EA_AMBUSHER", "core")
  AddStatus("EA_TIER_COMMON_L1", "core")
  AddStatus("EA_TIER_COMMON_L5", "core")
  AddStatus("EA_TIER_COMMON_L7", "core")
  AddStatus("EA_TIER_COMMON_L11", "core")
  AddStatus("EA_TIER_COMMON_L15", "core")
  AddStatus("EA_TIER_COMMON_CX_L1", "core")
  AddStatus("EA_TIER_COMMON_CX_L7", "core")
  AddStatus("EA_TIER_COMMON_CX_L11", "core")
  AddStatus("EA_TIER_VETERAN_L1", "core")
  AddStatus("EA_TIER_VETERAN_L5", "core")
  AddStatus("EA_TIER_VETERAN_L7", "core")
  AddStatus("EA_TIER_VETERAN_L11", "core")
  AddStatus("EA_TIER_VETERAN_L15", "core")
  AddStatus("EA_TIER_VETERAN_CX_L1", "core")
  AddStatus("EA_TIER_VETERAN_CX_L7", "core")
  AddStatus("EA_TIER_VETERAN_CX_L11", "core")
  AddStatus("EA_TIER_ELITE_L1", "core")
  AddStatus("EA_TIER_ELITE_L5", "core")
  AddStatus("EA_TIER_ELITE_L9", "core")
  AddStatus("EA_TIER_ELITE_L12", "core")
  AddStatus("EA_TIER_ELITE_L15", "core")
  AddStatus("EA_TIER_ELITE_CX_L1", "core")
  AddStatus("EA_TIER_ELITE_CX_L9", "core")
  AddStatus("EA_TIER_ELITE_CX_L12", "core")
  AddStatus("EA_TIER_LEGENDARY_L1", "core")
  AddStatus("EA_TIER_LEGENDARY_L5", "core")
  AddStatus("EA_TIER_LEGENDARY_L11", "core")
  AddStatus("EA_TIER_LEGENDARY_L15", "core")
  AddStatus("EA_TIER_LEGENDARY_CX_L1", "core")
  AddStatus("EA_TIER_LEGENDARY_CX_L11", "core")

  -- Per-entry status (enemy pools)
  for _, e in ipairs(list) do
    if e and e.status then
      AddStatus(e.status, "entry:" .. (e.name or "Unnamed"))
    end
  end

  -- Champion template statuses we apply (debug-only legacy fallback visibility).
  if EA_DebugGetSettingBool("MCM_DebugMode", false) then
    local championTemplates =
      (EnemyAmbush and EnemyAmbush._DEBUG_CHAMPION_TEMPLATES)
      or (EnemyAmbush and EnemyAmbush.CHAMPION_TEMPLATES)
      or CHAMPION_TEMPLATES
      or {}
    for _, t in pairs(championTemplates) do
      if t and t.status then
        AddStatus(t.status, "champion:" .. (t.name or "Unnamed"))
      end
    end
  end

  local missingRequired = {}
  local missingExternal = {}
  local total = 0
  for statusName, _ in pairs(statusSet) do
    total = total + 1
    if not StatExists(statusName, true) then
      if type(statusName) == "string" and statusName:match("^EA_") then
        missingRequired[#missingRequired + 1] = statusName
      else
        missingExternal[#missingExternal + 1] = statusName
      end
    end
  end

  table.sort(missingRequired)
  table.sort(missingExternal)

  print(string.format("[EnemyAmbush] verifystatuses: checked %d unique statuses", total))
  if #missingRequired > 0 then
    print(string.format("[EnemyAmbush] Missing required EA statuses (%d):", #missingRequired))
    for _, s in ipairs(missingRequired) do
      print("  " .. s)
    end
  else
    print("[EnemyAmbush] Required EA statuses: OK")
  end

  if #missingExternal > 0 then
    print(string.format("[EnemyAmbush] Missing external/non-EA status refs (%d):", #missingExternal))
    for _, s in ipairs(missingExternal) do
      print("  " .. s)
    end
  else
    print("[EnemyAmbush] External/non-EA status refs: OK")
  end

  return	

elseif args[1] == "metrics" then
print(GetMetricsSummary())
print("Detailed metrics:")
for k, v in pairs(PerformanceMetrics) do
    print(string.format("  %s: %s", k, tostring(v)))
end

elseif args[1] == "encountersummary" then
local printSummaryFn = _EA_ResolveFn("EA_PrintLastEncounterSummary", EA_PrintLastEncounterSummary)
if type(printSummaryFn) ~= "function" then
    print("[EnemyAmbush] Encounter summary unavailable (EA_PrintLastEncounterSummary missing).")
    return
end
local ok, err = pcall(printSummaryFn)
if not ok then
    print(string.format("[EnemyAmbush] Encounter summary failed: %s", tostring(err)))
end

elseif args[1] == "cleanupabandoned" then
local cleanupFn = _EA_ResolveFn("EA_DebugCleanupAbandonedCombatAmbushers", nil)
if type(cleanupFn) ~= "function" then
    print("[EnemyAmbush] abandoned cleanup unavailable (EA_DebugCleanupAbandonedCombatAmbushers missing).")
    return
end
local rawCombat = tostring(args[2] or "current")
local rawMode = tostring(args[3] or "")
local force = (string.lower(rawCombat) == "force" or string.lower(rawMode) == "force")
local combatGuid = rawCombat
local function EA_DebugAddCombatCandidate(out, seen, value)
    if value == nil then
        return
    end
    local v = tostring(value)
    if v == "" or seen[v] then
        return
    end
    seen[v] = true
    out[#out + 1] = v
end
local function EA_DebugFindTrackedCombat()
    local candidates = {}
    local seen = {}
    local function Add(value)
        EA_DebugAddCombatCandidate(candidates, seen, value)
    end
    if Osi and Osi.GetCombatGroupID then
        local okCombat, outCombat = pcall(Osi.GetCombatGroupID, player)
        if okCombat then
            Add(outCombat)
        end
    end
    local playerId = (EA_NormalizeUUID and EA_NormalizeUUID(player)) or player
    local byMember = EnemyAmbush and EnemyAmbush._CombatKeyByMember
    if type(byMember) == "table" then
        Add(byMember[playerId])
        Add(byMember[player])
        for _, value in pairs(byMember) do
            Add(value)
        end
    end
    local byAmbusher = EnemyAmbush and EnemyAmbush._CombatKeyByAmbusher
    if type(byAmbusher) == "table" then
        for _, value in pairs(byAmbusher) do
            Add(value)
        end
    end
    local spawned = (type(EA_Spawned) == "function") and EA_Spawned() or nil
    if type(spawned) == "table" or type(spawned) == "userdata" then
        for enemy, spawnedData in pairs(spawned) do
            if type(spawnedData) == "table" or type(spawnedData) == "userdata" then
                Add(spawnedData._eaSoftlockCombatKey)
                Add(spawnedData.escapePendingCombatKey)
                Add(spawnedData._eaLastCombatKey)
                local id = (EA_NormalizeUUID and EA_NormalizeUUID(enemy)) or enemy
                if Osi and Osi.IsInCombat and Osi.IsInCombat(id) == 1 and Osi.GetCombatGroupID then
                    local okEnemyCombat, enemyCombat = pcall(Osi.GetCombatGroupID, id)
                    if okEnemyCombat then
                        Add(enemyCombat)
                    end
                end
            end
        end
    end
    return candidates[1]
end
if rawCombat == "" or string.lower(rawCombat) == "current" or string.lower(rawCombat) == "force" then
    combatGuid = EA_DebugFindTrackedCombat()
elseif string.lower(rawCombat) == "all" then
    local cleanupAllFn = _EA_ResolveFn("EA_DebugCleanupAllTrackedAmbushers", nil)
    if type(cleanupAllFn) ~= "function" then
        print("[EnemyAmbush] cleanupabandoned all unavailable (EA_DebugCleanupAllTrackedAmbushers missing).")
        return
    end
    local okAll, removedAll = pcall(cleanupAllFn)
    if not okAll then
        print(string.format("[EnemyAmbush] cleanupabandoned all failed: %s", tostring(removedAll)))
        return
    end
    print(string.format("[EnemyAmbush] cleanupabandoned: combat=all force=true removed=%d", tonumber(removedAll) or 0))
    return
end
if not combatGuid or combatGuid == "" then
    if force then
        local cleanupAllFn = _EA_ResolveFn("EA_DebugCleanupAllTrackedAmbushers", nil)
        if type(cleanupAllFn) == "function" then
            local okAll, removedAll = pcall(cleanupAllFn)
            if not okAll then
                print(string.format("[EnemyAmbush] cleanupabandoned force fallback failed: %s", tostring(removedAll)))
                return
            end
            print(string.format("[EnemyAmbush] cleanupabandoned: combat=all-fallback force=true removed=%d", tonumber(removedAll) or 0))
            return
        end
    end
    print("[EnemyAmbush] cleanupabandoned: no combat id found. Usage: !ea_test cleanupabandoned [current|combatGuid|all] [force]")
    return
end
local okCleanup, removed = pcall(cleanupFn, combatGuid, force)
if not okCleanup then
    print(string.format("[EnemyAmbush] cleanupabandoned failed: %s", tostring(removed)))
    return
end
print(string.format(
    "[EnemyAmbush] cleanupabandoned: combat=%s force=%s removed=%d",
    tostring(combatGuid),
    tostring(force),
    tonumber(removed) or 0
))

elseif args[1] == "telemetry" then
local action = string.lower(tostring(args[2] or "show"))
if action == "on" then
    EA_SetDebugTelemetryEnabled(true)
elseif action == "off" then
    EA_SetDebugTelemetryEnabled(false)
elseif action == "dump" then
    EA_PrintTelemetrySummary()
    if type(EA_DumpState) == "function" then
        local ok, err = pcall(EA_DumpState)
        if not ok then
            print(string.format("[EnemyAmbush] telemetry dump failed: %s", tostring(err)))
        end
    else
        print("[EnemyAmbush] telemetry dump unavailable (EA_DumpState missing).")
    end
elseif action == "reset" then
    if type(EA_ResetMetrics) == "function" then
        local ok, err = pcall(EA_ResetMetrics)
        if not ok then
            print(string.format("[EnemyAmbush] telemetry reset failed: %s", tostring(err)))
        end
    else
        print("[EnemyAmbush] telemetry reset unavailable (EA_ResetMetrics missing).")
    end
else
    EA_PrintTelemetrySummary()
end

elseif args[1] == "xpclones" then
  local action = string.lower(tostring(args[2] or "show"))
  if action == "export" or action == "dump" then
      local ok, a, b = EA_ExportXPCloneSourceData()
      if ok == true then
          local snapshot = b
          print(string.format("[EnemyAmbush] xpclones exported: %s", tostring(a)))
          if type(snapshot) == "table" then
              print(string.format(
                  "[EnemyAmbush] xpclones source: templates=%s resolved=%s missingTemplate=%s missingStats=%s",
                  tostring(snapshot.templateCount or 0),
                  tostring(snapshot.resolvedCount or 0),
                  tostring(snapshot.missingTemplateCount or 0),
                  tostring(snapshot.missingStatsCount or 0)
              ))
          end
      else
          print(string.format("[EnemyAmbush] xpclones export failed: %s", tostring(a)))
      end
  else
      local lastPath = EnemyAmbush and EnemyAmbush._XPCloneSourceExportLastPath
      print("[EnemyAmbush] xpclones commands:")
      print("  !ea_test xpclones export - Export live template->stat source data for the XP-zero clone generator")
      print(string.format("  lastExportPath=%s", tostring(lastPath or "(none)")))
  end
  return

  elseif args[1] == "reststats" then
local action = string.lower(tostring(args[2] or "show"))
local getFn = EA and EA["EA_GetRestStats"]
local resetFn = EA and EA["EA_ResetRestStats"]
local exportFn = EA and EA["EA_ExportRestStats"]
if action == "reset" then
    if type(resetFn) == "function" then
        local ok, err = pcall(resetFn)
        if not ok then
            print(string.format("[EnemyAmbush] reststats reset failed: %s", tostring(err)))
        else
            print("[EnemyAmbush] reststats reset.")
        end
    else
        print("[EnemyAmbush] reststats reset unavailable.")
    end
elseif action == "export" or action == "dump" then
    if type(exportFn) == "function" then
        local ok, a, b = pcall(exportFn)
        if not ok then
            print(string.format("[EnemyAmbush] reststats export failed: %s", tostring(a)))
        elseif a == true then
            print(string.format("[EnemyAmbush] reststats exported: %s", tostring(b)))
        else
            print(string.format("[EnemyAmbush] reststats export failed: %s", tostring(b or "unknown")))
        end
    else
        print("[EnemyAmbush] reststats export unavailable.")
    end
end
if type(getFn) == "function" then
    local ok, stats = pcall(getFn)
    if ok then
        EA_PrintRestStats(stats)
    else
        print(string.format("[EnemyAmbush] reststats read failed: %s", tostring(stats)))
    end
else
    print("[EnemyAmbush] reststats unavailable.")
end

elseif args[1] == "repstats" then
local action = string.lower(tostring(args[2] or "show"))
local getFn = EA and EA["EA_GetRepStats"]
local resetFn = EA and EA["EA_ResetRepStats"]
local exportFn = EA and EA["EA_ExportRepStats"]
if action == "reset" then
    if type(resetFn) == "function" then
        local ok, err = pcall(resetFn)
        if not ok then
            print(string.format("[EnemyAmbush] repstats reset failed: %s", tostring(err)))
        else
            print("[EnemyAmbush] repstats reset.")
        end
    else
        print("[EnemyAmbush] repstats reset unavailable.")
    end
elseif action == "export" or action == "dump" then
    if type(exportFn) == "function" then
        local ok, a, b = pcall(exportFn)
        if not ok then
            print(string.format("[EnemyAmbush] repstats export failed: %s", tostring(a)))
        elseif a == true then
            print(string.format("[EnemyAmbush] repstats exported: %s", tostring(b)))
        else
            print(string.format("[EnemyAmbush] repstats export failed: %s", tostring(b or "unknown")))
        end
    else
        print("[EnemyAmbush] repstats export unavailable.")
    end
end
if type(getFn) == "function" then
    local ok, stats = pcall(getFn)
    if ok then
        EA_PrintRepStats(stats)
    else
        print(string.format("[EnemyAmbush] repstats read failed: %s", tostring(stats)))
    end
else
    print("[EnemyAmbush] repstats unavailable.")
end

elseif args[1] == "readiness" then
EA_PrintReadinessDiagnostics()

elseif args[1] == "hostileretry" then
local action = string.lower(tostring(args[2] or "show"))
local describeFn = _EA_ResolveFn("EA_DebugDescribePersistentHostileRetries", EA_DebugDescribePersistentHostileRetries)
local armFn = _EA_ResolveFn("EA_DebugSchedulePersistentHostileRetry", EA_DebugSchedulePersistentHostileRetry)
local clearFn = _EA_ResolveFn("EA_DebugClearPersistentHostileRetries", EA_DebugClearPersistentHostileRetries)
if action == "arm" then
    local enemy = tostring(args[3] or "")
    if enemy == "" then
        print("[EnemyAmbush] Usage: !ea_test hostileretry arm [enemy_uuid] [delayMs] [tries]")
        return
    end
    local player = (Osi and Osi.GetHostCharacter) and Osi.GetHostCharacter() or ""
    if player == "" then
        print("[EnemyAmbush] hostileretry arm unavailable (host character missing).")
        return
    end
    local delayMs = math.max(1000, math.floor(tonumber(args[4]) or 15000))
    local tries = math.max(0, math.floor(tonumber(args[5]) or 3))
    if type(armFn) ~= "function" then
        print("[EnemyAmbush] hostileretry arm unavailable (missing owner export).")
        return
    end
    local okCall, okArm, detail = pcall(
        armFn,
        enemy,
        player,
        tries,
        "debug_phase6_load_rearm_probe",
        delayMs
    )
    if not okCall then
        print(string.format("[EnemyAmbush] hostileretry arm failed: %s", tostring(okArm)))
        return
    end
    if okArm ~= true then
        print(string.format("[EnemyAmbush] hostileretry arm failed: %s", tostring(detail)))
        return
    end
    print(string.format(
        "[EnemyAmbush] hostileretry arm => ok=true timer=%s enemy=%s player=%s delayMs=%s tries=%s",
        tostring(detail),
        tostring(enemy),
        tostring(player),
        tostring(delayMs),
        tostring(tries)
    ))
    print("[EnemyAmbush] Next step: save before the timer fires, reload, then look for the rearm/firing logs.")
elseif action == "clear" then
    if type(clearFn) ~= "function" then
        print("[EnemyAmbush] hostileretry clear unavailable (missing owner export).")
        return
    end
    local okClear, removed = pcall(clearFn)
    if not okClear then
        print(string.format("[EnemyAmbush] hostileretry clear failed: %s", tostring(removed)))
        return
    end
    print(string.format("[EnemyAmbush] hostileretry clear => removed=%s", tostring(removed or 0)))
end
if type(describeFn) ~= "function" then
    print("[EnemyAmbush] hostileretry show unavailable (missing owner export).")
    return
end
local okSnapshot, snapshot = pcall(describeFn)
if not okSnapshot then
    print(string.format("[EnemyAmbush] hostileretry show failed: %s", tostring(snapshot)))
    return
end
EA_PrintPersistentHostileRetrySnapshot(snapshot, "persistent hostile retries")

elseif args[1] == "poolowner" then
local getOwnerFn = _EA_ResolveFn("EA_GetPoolOwnerId", nil)
local getListFn = _EA_ResolveFn("EA_GetPoolActiveSummonList", nil)
local getEntryFn = _EA_ResolveFn("EA_GetPoolTemplateEntryById", nil)
local getVariantsFn = _EA_ResolveFn("EA_GetPoolTemplateVariantsById", nil)
local getVariantEntryFn = _EA_ResolveFn("EA_GetPoolTemplateVariantEntry", nil)
local resetActiveListFn = _EA_ResolveFn("EA_ResetPoolActiveListState", nil)
local flushPoolCacheFn = _EA_ResolveFn("EA_FlushPoolCacheState", nil)
local markNeedsRebuildFn = _EA_ResolveFn("EA_MarkPoolNeedsRebuild", nil)
local requestPoolRebuildFn = _EA_ResolveFn("EA_RequestPoolRebuild", nil)
local notifyPoolProviderChangedFn = _EA_ResolveFn("EA_NotifyPoolProviderChanged", nil)
local resetLookupsFn = _EA_ResolveFn("EA_ResetPoolTemplateLookups", nil)
local legacyBuildFn = _EA_ResolveFn("BuildActiveSummonList", BuildActiveSummonList)

local ownerId = "(unavailable)"
if type(getOwnerFn) == "function" then
    local ok, out = pcall(getOwnerFn)
    if ok and out ~= nil then
        ownerId = tostring(out)
    else
        ownerId = "error:" .. tostring(out)
    end
end

local listType = "nil"
local listCount = "n/a"
local sampleTemplate = ""
if type(getListFn) == "function" then
    local ok, out = pcall(getListFn)
    if ok then
        listType = type(out)
        if type(out) == "table" then
            listCount = tostring(#out)
            local first = out[1]
            if type(first) == "table" and first.template then
                sampleTemplate = tostring(first.template)
            end
        end
    else
        listType = "error:" .. tostring(out)
    end
end

local legacyListType = "nil"
local legacyListCount = "n/a"
if type(legacyBuildFn) == "function" then
    local ok, out = pcall(legacyBuildFn)
    if ok then
        legacyListType = type(out)
        if type(out) == "table" then
            legacyListCount = tostring(#out)
        end
    else
        legacyListType = "error:" .. tostring(out)
    end
end

print("[EnemyAmbush] Pool owner diagnostics:")
print(string.format("  owner=%s", tostring(ownerId)))
print(string.format(
    "  surfaces: legacyBuild=%s activeList=%s templateEntry=%s templateVariants=%s variantEntry=%s resetActiveList=%s flushPoolCache=%s markNeedsRebuild=%s requestRebuild=%s notifyProviderChange=%s resetLookups=%s",
    tostring(type(legacyBuildFn) == "function"),
    tostring(type(getListFn) == "function"),
    tostring(type(getEntryFn) == "function"),
    tostring(type(getVariantsFn) == "function"),
    tostring(type(getVariantEntryFn) == "function"),
    tostring(type(resetActiveListFn) == "function"),
    tostring(type(flushPoolCacheFn) == "function"),
    tostring(type(markNeedsRebuildFn) == "function"),
    tostring(type(requestPoolRebuildFn) == "function"),
    tostring(type(notifyPoolProviderChangedFn) == "function"),
    tostring(type(resetLookupsFn) == "function")
))
print(string.format(
    "  activeList: ownerType=%s ownerCount=%s legacyType=%s legacyCount=%s sampleTemplate=%s",
    tostring(listType),
    tostring(listCount),
    tostring(legacyListType),
    tostring(legacyListCount),
    tostring(sampleTemplate)
))

elseif args[1] == "phase0" then
local action = string.lower(tostring(args[2] or "show"))
local resetFn = EA and EA["EA_ResetPhase0Stats"]
if action == "reset" then
    if type(resetFn) == "function" then
        local ok, err = pcall(resetFn)
        if not ok then
            print(string.format("[EnemyAmbush] phase0 reset failed: %s", tostring(err)))
            return
        end
        print("[EnemyAmbush] phase0 stats reset.")
    else
        print("[EnemyAmbush] phase0 reset unavailable.")
        return
    end
end
EA_PrintPhase0Summary()

elseif args[1] == "spawnstagger" then
local action = string.lower(tostring(args[2] or "show"))
EA.CFG = EA.CFG or {}
if action == "on" then
    EA.CFG.SPAWN_STAGGER_ENABLED = true
elseif action == "off" then
    EA.CFG.SPAWN_STAGGER_ENABLED = false
elseif tonumber(args[2]) then
    EA.CFG.SPAWN_STAGGER_MS = math.floor(math.max(20, math.min(500, tonumber(args[2]) or 100)))
elseif tonumber(args[3]) then
    EA.CFG.SPAWN_STAGGER_MS = math.floor(math.max(20, math.min(500, tonumber(args[3]) or 100)))
end
if tonumber(EA.CFG.SPAWN_STAGGER_MS) == nil then
    EA.CFG.SPAWN_STAGGER_MS = 100
end
print(string.format(
    "[EnemyAmbush] Spawn stagger: enabled=%s stepMs=%d",
    tostring(EA.CFG.SPAWN_STAGGER_ENABLED ~= false),
    math.floor(math.max(20, math.min(500, tonumber(EA.CFG.SPAWN_STAGGER_MS) or 100)))
))

elseif args[1] == "settings" then
local effectiveXP = tonumber(EA_GetEffectiveAmbushXPPercent and EA_GetEffectiveAmbushXPPercent()) or -1
local disableLoot = (EA_GetEffectiveDisableAmbushLoot and EA_GetEffectiveDisableAmbushLoot()) == true
local allowChampionLoot = (EA_GetEffectiveAllowChampionLoot and EA_GetEffectiveAllowChampionLoot()) == true
local function getSetting(id, fallback)
    return EA_DebugGetSettingRaw(id, fallback)
end
local getRestChanceFn = EA["EA_GetRestAmbushChance"] or EA_GetRestAmbushChance
local getRestDelayFn = EA["EA_GetRestDelayWindowMinutes"] or EA_GetRestDelayWindowMinutes
local getCooldownEnabledFn = EA["EA_GetCooldownEnabled"] or EA_GetCooldownEnabled
local getCooldownMinutesFn = EA["EA_GetCooldownMinutes"] or EA_GetCooldownMinutes
local isQuickTestFn = EA["EA_IsQuickTestMode"] or EA_IsQuickTestMode
local isRestEnabledFn = EA["EA_IsRestAmbushEnabled"] or EA_IsRestAmbushEnabled
local getBalanceProfileFn = EA["EA_GetBalanceProfile"] or EA_GetBalanceProfile
local getBalanceProfileLabelFn = EA["EA_GetBalanceProfileLabel"] or EA_GetBalanceProfileLabel
local getArrivalCuePolicyFn = EA["EA_GetArrivalCuePolicy"] or EA_GetArrivalCuePolicy
local getArrivalCuePolicyLabelFn = EA["EA_GetArrivalCuePolicyLabel"] or EA_GetArrivalCuePolicyLabel
local getSpawnPlacementModeFn = EA["EA_GetSpawnPlacementMode"] or EA_GetSpawnPlacementMode
local getSpawnPlacementModeLabelFn = EA["EA_GetSpawnPlacementModeLabel"] or EA_GetSpawnPlacementModeLabel
local function callBool(fn, fallback)
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok then
            return out == true
        end
    end
    return fallback == true
end
local function callInt(fn, fallback)
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok and tonumber(out) ~= nil then
            return math.floor(tonumber(out))
        end
    end
    return math.floor(tonumber(fallback) or 0)
end
local function callString(fn, fallback)
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok and out ~= nil then
            return tostring(out)
        end
    end
    return tostring(fallback)
end
local function callLabel(fn, value, fallback)
    if type(fn) == "function" then
        local ok, out = pcall(fn, value)
        if ok and type(out) == "string" and out ~= "" then
            return out
        end
    end
    return tostring(fallback)
end

local quickTestRaw = EA_DebugGetSettingBool("MCM_QuickTestMode", false)
local quickTestEffective = callBool(isQuickTestFn, quickTestRaw)
local restEnabledRaw = EA_DebugGetSettingBool("MCM_EnableOnRest", true)
local restEnabledEffective = callBool(isRestEnabledFn, restEnabledRaw)

local cooldownRawEnabled = EA_DebugGetSettingBool("MCM_EnableAmbushCooldown", true)
local cooldownRawMinutes = tonumber(getSetting("MCM_AmbushCooldownMinutes", 45)) or 45
local cooldownEffectiveEnabled = callBool(getCooldownEnabledFn, cooldownRawEnabled)
local cooldownEffectiveMinutes = callInt(getCooldownMinutesFn, cooldownRawMinutes)

local shortChanceRawPct = tonumber(getSetting("MCM_AmbushChanceShortPct", 5)) or 5
local longChanceRawPct = tonumber(getSetting("MCM_AmbushChanceLongPct", 15)) or 15
local shortChanceEffectivePct = shortChanceRawPct
local longChanceEffectivePct = longChanceRawPct
if type(getRestChanceFn) == "function" then
    shortChanceEffectivePct = math.floor((((tonumber(getRestChanceFn(false)) or 0) * 100.0) + 0.5))
    longChanceEffectivePct = math.floor((((tonumber(getRestChanceFn(true)) or 0) * 100.0) + 0.5))
end

local shortDelayRawMin = tonumber(getSetting("MCM_ShortRestDelayMinMinutes", 0)) or 0
local shortDelayRawMax = tonumber(getSetting("MCM_ShortRestDelayMaxMinutes", 10)) or 10
local longDelayRawMin = tonumber(getSetting("MCM_LongRestDelayMinMinutes", 2)) or 2
local longDelayRawMax = tonumber(getSetting("MCM_LongRestDelayMaxMinutes", 20)) or 20
local shortDelayEffectiveMin = shortDelayRawMin
local shortDelayEffectiveMax = shortDelayRawMax
local longDelayEffectiveMin = longDelayRawMin
local longDelayEffectiveMax = longDelayRawMax
if type(getRestDelayFn) == "function" then
    shortDelayEffectiveMin, shortDelayEffectiveMax = getRestDelayFn(false)
    longDelayEffectiveMin, longDelayEffectiveMax = getRestDelayFn(true)
    shortDelayEffectiveMin = tonumber(shortDelayEffectiveMin) or shortDelayRawMin
    shortDelayEffectiveMax = tonumber(shortDelayEffectiveMax) or shortDelayRawMax
    longDelayEffectiveMin = tonumber(longDelayEffectiveMin) or longDelayRawMin
    longDelayEffectiveMax = tonumber(longDelayEffectiveMax) or longDelayRawMax
end

    local balanceProfileRaw = tostring(getSetting("MCM_BalanceProfile", "BG3_12"))
local balanceProfileEffective = callString(getBalanceProfileFn, balanceProfileRaw)
local balanceProfileRawLabel = callLabel(getBalanceProfileLabelFn, balanceProfileRaw, balanceProfileRaw)
local balanceProfileEffectiveLabel = callLabel(getBalanceProfileLabelFn, balanceProfileEffective, balanceProfileEffective)

local arrivalCuePolicyRaw = tostring(getSetting("MCM_ArrivalCuePolicy", "BALANCED"))
local arrivalCuePolicyEffective = callString(getArrivalCuePolicyFn, arrivalCuePolicyRaw)
local arrivalCuePolicyRawLabel = callLabel(getArrivalCuePolicyLabelFn, arrivalCuePolicyRaw, arrivalCuePolicyRaw)
local arrivalCuePolicyEffectiveLabel = callLabel(getArrivalCuePolicyLabelFn, arrivalCuePolicyEffective, arrivalCuePolicyEffective)
local arrivalCueChanceScaleRaw = math.floor(math.max(0, math.min(200, tonumber(getSetting("MCM_ArrivalCueChanceScale", 100)) or 100)))
local spawnPlacementModeRaw = tostring(getSetting("MCM_SpawnPlacementMode", "CREATE_OOS_ONLY"))
local spawnPlacementModeEffective = callString(getSpawnPlacementModeFn, spawnPlacementModeRaw)
local spawnPlacementModeRawLabel = callLabel(getSpawnPlacementModeLabelFn, spawnPlacementModeRaw, spawnPlacementModeRaw)
local spawnPlacementModeEffectiveLabel = callLabel(getSpawnPlacementModeLabelFn, spawnPlacementModeEffective, spawnPlacementModeEffective)

print("[EnemyAmbush] Effective settings:")
print(string.format("  AdvancedMode=%s  Preset=%s  CXMode=%s",
    tostring(EA_DebugGetSettingBool("MCM_AdvancedMode", false)),
    tostring(EA_DebugGetSettingRaw("MCM_DifficultyPreset", "Marked")),
    tostring(EA_DebugGetSettingBool("MCM_CombatExtenderMode", true))))
print(string.format("  Balance=%s (%s)",
    balanceProfileEffectiveLabel,
    balanceProfileEffective))
print("  FodderCurve=Fixed 7+:50% 10+:30% 12+:10%")
print(string.format("  ArrivalCue=%s (%s)",
    arrivalCuePolicyEffectiveLabel,
    arrivalCuePolicyEffective))
print(string.format("  PlacementMode=%s (%s)",
    spawnPlacementModeEffectiveLabel,
    spawnPlacementModeEffective))
print(string.format("  RestEnabled=%s  QuickTest=%s",
    tostring(restEnabledEffective),
    tostring(quickTestEffective)))
print(string.format("  Effective: XP%%=%s  DisableLoot=%s  AllowChampionLoot=%s",
    tostring(effectiveXP),
    tostring(disableLoot),
    tostring(allowChampionLoot)))
print(string.format("  Effective Rest: ShortChance=%d%%  LongChance=%d%%  ShortDelay=%dm-%dm  LongDelay=%dm-%dm",
    shortChanceEffectivePct,
    longChanceEffectivePct,
    shortDelayEffectiveMin,
    shortDelayEffectiveMax,
    longDelayEffectiveMin,
    longDelayEffectiveMax))
print(string.format("  Effective Cooldown: enabled=%s  minutes=%d",
    tostring(cooldownEffectiveEnabled),
    cooldownEffectiveMinutes))
print(string.format("  Raw MCM:   XP%%=%s  DisableLoot=%s  AllowChampionLoot=%s",
    tostring(EA_DebugGetSettingRaw("MCM_AmbushXPPercent", 10)),
    tostring(EA_DebugGetSettingBool("MCM_DisableAmbushLoot", false)),
    tostring(EA_DebugGetSettingBool("MCM_AllowChampionLoot", true))))
print(string.format("  Raw MCM Balance: Profile=%s (%s)",
    balanceProfileRawLabel,
    balanceProfileRaw))
print(string.format("  Raw MCM Arrival: Policy=%s (%s)  ChanceScale=%d%%",
    arrivalCuePolicyRawLabel,
    arrivalCuePolicyRaw,
    arrivalCueChanceScaleRaw))
print(string.format("  Raw MCM Placement: Mode=%s (%s)",
    spawnPlacementModeRawLabel,
    spawnPlacementModeRaw))
print(string.format("  Raw MCM Rest: enabled=%s  QuickTest=%s  ShortChance=%d%%  LongChance=%d%%  ShortDelay=%dm-%dm  LongDelay=%dm-%dm",
    tostring(restEnabledRaw),
    tostring(quickTestRaw),
    shortChanceRawPct,
    longChanceRawPct,
    shortDelayRawMin,
    shortDelayRawMax,
    longDelayRawMin,
    longDelayRawMax))
print(string.format("  Raw MCM Cooldown: enabled=%s  minutes=%d",
    tostring(cooldownRawEnabled),
    cooldownRawMinutes))

elseif args[1] == "validate" then
local list = EA_BuildActiveListSafe()
local valid = 0
local invalid = 0
for _, enemy in ipairs(list) do
    if ValidateEnemyData(enemy) then
        valid = valid + 1
    else
        invalid = invalid + 1
        print(string.format("[EnemyAmbush] Invalid: %s (template: %s)", 
            enemy.name or "Unknown", enemy.template or "nil"))
    end
end
print(string.format("[EnemyAmbush] Validation complete: %d valid, %d invalid", valid, invalid))

elseif args[1] == "dataaudit" then
local mode = string.lower(tostring(args[2] or ""))
local verbose = (mode == "verbose" or mode == "v")
local auditFn = EA and EA["EA_RunDataAudit"]
if type(auditFn) ~= "function" then
    print("[EnemyAmbush] dataaudit unavailable (EA_RunDataAudit missing).")
    return
end
local ok, err = pcall(auditFn, verbose)
if not ok then
    print(string.format("[EnemyAmbush] dataaudit failed: %s", tostring(err)))
else
    print(string.format("[EnemyAmbush] dataaudit complete (verbose=%s).", tostring(verbose)))
end

elseif args[1] == "startupaudit" then
    local auditFn = _EA_ResolveFn("EA_RunStartupTemplateAudit", nil)
    local limit = math.max(0, math.floor(tonumber(args[2]) or 8))
    if type(auditFn) ~= "function" then
        print("[EnemyAmbush] startupaudit unavailable (EA_RunStartupTemplateAudit missing).")
        return
    end
    local ok, result = pcall(auditFn, limit)
    if not ok then
        print(string.format("[EnemyAmbush] startupaudit failed: %s", tostring(result)))
    elseif type(result) == "table" then
        if result.skipped == true then
            print(string.format(
                "[EnemyAmbush] startupaudit skipped: reason=%s",
                tostring(result.reason or "unknown")
            ))
        else
            print(string.format(
                "[EnemyAmbush] startupaudit complete: total=%s invalidGuid=%s missingRoot=%s",
                tostring(result.total or 0),
                tostring(result.invalidGuid or 0),
                tostring(result.missingRoot or 0)
            ))
        end
    else
        print("[EnemyAmbush] startupaudit completed.")
    end

elseif args[1] == "scenario" then
if args[2] == "list" or not args[2] then
    local listFn = EA_DebugResolveListScriptedScenarios()
    if type(listFn) == "function" then
        local items = listFn() or {}
        print(string.format("[EnemyAmbush] Scripted scenarios (%d):", #items))
        for _, sc in ipairs(items) do
            print(string.format("  %s | priority=%d | once=%s | completed=%s",
                tostring(sc.id), tonumber(sc.priority) or 0, tostring(sc.once == true), tostring(sc.completed == true)))
        end
    else
        print("[EnemyAmbush] scenario list unavailable (missing export)")
    end
elseif args[2] == "run" and args[3] then
    local runFn = EA_DebugResolveRunScriptedScenarioById()
    if type(runFn) == "function" then
        local ok = runFn(player, tostring(args[3]), true)
        print(string.format("[EnemyAmbush] Scenario run %s => %s", tostring(args[3]), tostring(ok == true)))
    else
        print("[EnemyAmbush] scenario run unavailable (missing export)")
    end
else
    print("[EnemyAmbush] Scenario commands:")
    print("  !ea_test scenario list - List scripted scenarios")
    print("  !ea_test scenario run [id] - Force-run scripted scenario by id")
end

elseif args[1] == "beachstate" then
local describeFn = EA and EA["EA_DebugDescribeBeachBootstrap"]
if type(describeFn) ~= "function" then
    print("[EnemyAmbush] beachstate unavailable (missing export)")
else
    local ok, info = pcall(describeFn)
    if not ok then
        print(string.format("[EnemyAmbush] beachstate failed: %s", tostring(info)))
    elseif type(info) ~= "table" then
        print("[EnemyAmbush] beachstate unavailable (invalid payload)")
    else
        local function show(value)
            if value == nil then
                return "nil"
            end
            return tostring(value)
        end
        print("[EnemyAmbush] Beach bootstrap:")
        print(string.format(
            "  host=%s exists=%s isPlayer=%s inCombat=%s level=%s region=%s",
            show(info.host),
            show(info.hostExists),
            show(info.hostIsPlayer),
            show(info.hostInCombat),
            show(info.hostLevel),
            show(info.hostRegion)
        ))
        print(string.format(
            "  varsReady=%s safeToSpawn=%s skipTutorial=%s tutorialShown=%s",
            show(info.varsReady),
            show(info.safeToSpawn),
            show(info.skipTutorial),
            show(info.tutorialShown)
        ))
        print(string.format(
            "  storyWakeup=%s source=%s ready=%s reason=%s",
            show(info.storyWakeupDone),
            show(info.storyWakeupSource),
            show(info.ready),
            show(info.readyReason)
        ))
        print(string.format(
            "  done=%s source=%s scenarioCompleted=%s completedAt=%s",
            show(info.done),
            show(info.doneSource),
            show(info.scenarioCompleted),
            show(info.scenarioCompletedAt)
        ))
        print(string.format(
            "  hostVars: done=%s reason=%s doneAt=%s",
            show(info.hostDoneVar),
            show(info.hostDoneReason),
            show(info.hostDoneAt)
        ))
        print(string.format(
            "  partyDone: done=%s member=%s reason=%s doneAt=%s checked=%s scan=%s",
            show(info.partyDone),
            show(info.partyDoneMember),
            show(info.partyDoneReason),
            show(info.partyDoneAt),
            show(info.partyDoneCheckedCount),
            show(info.partyDoneScanAvailable)
        ))
        print(string.format(
            "  persistent: doneAt=%s reason=%s host=%s wakeupDoneSeenAt=%s",
            show(info.stateDoneAt),
            show(info.stateReason),
            show(info.stateHost),
            show(info.stateWakeupDoneSeenAt)
        ))
        print(string.format(
            "  runtime: timerLaunched=%s armed=%s host=%s retries=%s waitTicks=%s execRetries=%s",
            show(info.runtimeTimerLaunched),
            show(info.runtimeArmed),
            show(info.runtimeHost),
            show(info.runtimeRetries),
            show(info.runtimeWaitTicks),
            show(info.runtimeExecRetries)
        ))
    end
end

elseif args[1] == "msgbox" then
local mode = string.lower(tostring(args[2] or "demo"))
if mode == "open" then
    local text = EA_JoinArgs(3, "[EA TEST] OpenMessageBox test.")
    if Osi and Osi.OpenMessageBox then
        local ok = pcall(Osi.OpenMessageBox, player, text)
        print(string.format("[EnemyAmbush] msgbox open => %s", tostring(ok == true)))
    else
        print("[EnemyAmbush] OpenMessageBox unavailable in this context.")
    end
elseif mode == "yesno" then
    local text = EA_JoinArgs(3, "[EA TEST] OpenMessageBoxYesNo test. Choose an option.")
    local id = string.format("EA_TEST_YN_%s", tostring((Ext and Ext.Utils and Ext.Utils.MonotonicTime and Ext.Utils.MonotonicTime()) or os.time()))
    local ok = EA_OpenMessageBoxYesNoCompat(player, text, id)
    print(string.format("[EnemyAmbush] msgbox yesno => %s (id=%s)", tostring(ok == true), tostring(id)))
elseif mode == "demo" then
    local infoText = EA_JoinArgs(3, "[EA TEST] Message box demo.")
    local yesNoId = string.format("EA_TEST_YN_%s", tostring((Ext and Ext.Utils and Ext.Utils.MonotonicTime and Ext.Utils.MonotonicTime()) or os.time()))
    local okOpen = false
    local okYesNo = false
    if Osi and Osi.OpenMessageBox then
        okOpen = pcall(Osi.OpenMessageBox, player, infoText)
    end
    okYesNo = EA_OpenMessageBoxYesNoCompat(player, "[EA TEST] Yes/No dialog demo.", yesNoId)
    print(string.format(
        "[EnemyAmbush] msgbox demo => open=%s yesno=%s (yesnoId=%s)",
        tostring(okOpen == true),
        tostring(okYesNo == true),
        tostring(yesNoId)
    ))
else
    print("[EnemyAmbush] MsgBox commands:")
    print("  !ea_test msgbox open [text] - OpenMessageBox test")
    print("  !ea_test msgbox yesno [text] - OpenMessageBoxYesNo test")
    print("  !ea_test msgbox demo [text] - Run both message box tests")
end

elseif args[1] == "reputation" then
if args[2] == "show" then
    print("[EnemyAmbush] Current Reputation:")
    local hasRep = false
    for creatureType, rep in pairs(CreatureReputation) do
        if rep ~= 0 then
            hasRep = true
            local status = ""
            if rep <= REPUTATION_THRESHOLDS.VENGEFUL then
                status = " (VENGEFUL)"
            elseif rep <= REPUTATION_THRESHOLDS.HOSTILE then
                status = " (HOSTILE)"
            elseif rep <= REPUTATION_THRESHOLDS.WARY then
                status = " (WARY)"
            end
            -- Round the reputation to nearest integer for display
local displayRep = math.floor(rep + 0.5)  -- Round to nearest integer
print(string.format("  %s: %d%s", creatureType, displayRep, status))
        end
    end
    if not hasRep then
        print("  All reputations are neutral (0)")
    end
elseif args[2] == "set" and args[3] and args[4] then
    local creatureType = args[3]
    local value = tonumber(args[4])
    if CreatureReputation[creatureType] and value then
        CreatureReputation[creatureType] = value
        SaveReputation()
        print(string.format("[EnemyAmbush] Set %s reputation to %d", creatureType, value))
    else
        print("[EnemyAmbush] Invalid creature type or value")
        print("Valid types: Aberration, Beast, Celestial, Construct, Dragon, Elemental, Fey, Fiend, Giant, Humanoid, Monstrosity, Ooze, Plant, Undead")
    end
elseif args[2] == "setcustom" and args[3] and args[4] then
    local creatureType = tostring(args[3] or "")
    local value = tonumber(args[4])
    if creatureType ~= "" and string.find(creatureType, "%S") and value then
        if value > 0 then
            value = 0
        end
        CreatureReputation[creatureType] = value
        SaveReputation()
        print(string.format("[EnemyAmbush] Set custom reputation %s to %d", creatureType, value))
    else
        print("[EnemyAmbush] Usage: !ea_test reputation setcustom <CreatureType> <value>")
        print("[EnemyAmbush] CreatureType must be a non-empty string and value must be numeric.")
    end
elseif args[2] == "reset" then
    for k, _ in pairs(CreatureReputation) do
        CreatureReputation[k] = 0
    end
    SaveReputation()
    print("[EnemyAmbush] All reputations reset to 0")
else
    print("[EnemyAmbush] Reputation commands:")
    print("  !ea_test reputation show - Display all non-zero reputations")
    print("  !ea_test reputation set [type] [value] - Set reputation for a creature type")
    print("  !ea_test reputation setcustom <type> <value> - Set/create a custom creature type reputation for verification")
    print("  !ea_test reputation reset - Reset all reputations to 0")
end

else
print("[EnemyAmbush] Commands:")
print("  !ea_test spawn [preset|random|direct|type] - Spawn themed/random ambush; direct supports count<=30, optional spread/stagger")
print("  !ea_test spawn type <CreatureType> [tier|auto] - Normal ambush pipeline filtered to one creature type")
print("  !ea_test spawnrank [Veteran|Elite|Legendary] [theme] - Spawn a single leader-tier enemy")
print("  !ea_test spawntype [type] - Force spawn specific creature type")
print("  !ea_test typelist <type> [limit] - List unique active template UUIDs for a creature type")
print("  !ea_test typetest <type> [count|all] - Fast CreateAt/RequestDelete smoke test of templates by type")
print("  !ea_test spawnuuid <templateUUID> [keep|despawn <seconds>] - Spawn specific RootTemplate UUID")
print("  !ea_test neutraluuid <templateUUID> - Spawn a neutral NPC test target for hostile-path proofs")
print("  !ea_test champion [type] [force] - Spawn champion (force ignores cooldown)")
print("  !ea_test championreset - Clear champion per-type cooldowns")
print("  !ea_test championdiag on|off|once|show - Champion long-rest diagnostics mode")
print("  !ea_test championqueue <CreatureType> - Seed guaranteed champion queue entry")
print("  !ea_test championarm <CreatureType> [run] - Arm guaranteed champion; optional immediate long-rest path run")
print("  !ea_test vfx <effectId|alias> [target] - Play a one-shot VFX on target")
print("  !ea_test sfx <soundEvent|alias> [target] - Play a one-shot SFX/SoundEvent on target")
print("  !ea_test debugtext [target] [text] - Show Osiris DebugText above target")
print("  !ea_test escapestatus [target] [seconds] - Apply temporary EA_ESCAPE_IMMINENT overhead status")
print("  !ea_test fleefrom [target] [from] [range] - Call FleeFromObject on target away from source")
print("  !ea_test arrivalpreview [target] [vfx] [sfx] - Quick arrival cue preview")
print("  !ea_test escapepreview [target] [vfx] [sfx] [deleteMs] - Quick escape cue preview")
print("  !ea_test escapetune quick|default|show - Toggle fast escape test tuning")
print("  !ea_test hasteall on|off|show - Debug: apply 1-turn HASTE to all ambushers")
print("  !ea_test spawnhostile - Hostility-only debug spawn (no ambush status/reward pipeline)")
print("  !ea_test cleanupabandoned [current|combatGuid|all] [force] - Debug: cleanup tracked Hunted ambushers")
print("  !ea_test hostile <uuid> - Make specific enemy hostile")
print("  !ea_test attack <uuid> - Force enemy to attack a nearby player (debug)")
print("  !ea_test list - List ACTIVE enemies (after providers + toggles)")
print("  !ea_test dump <uuid> - Dump info about an entity")
print("  !ea_test verify - Quick GUID + core-status sanity check")
print("  !ea_test verifytemplates - Check GUID format + RootTemplate existence")
print("  !ea_test verifystatuses - Check all statuses we may apply exist")
print("  !ea_test validate - Validate entries (level/weight/etc)")
print("  !ea_test dataaudit [verbose] - Run summon/champion integrity + weight concentration audit")
print("  !ea_test startupaudit [limit] - Run the startup template audit now (debug mode gate still applies)")
print("  !ea_test clearcache - Clear summon pool + weighted cache")
print("  !ea_test providerprobe [show|register|edit|unregister|cycle] - Exercise EnemyProvidersChanged via a temporary provider")
print("  !ea_test api [show|authored_smoke|trigger_smoke] - D2 authored API export/status smoke commands")
print("  !ea_test metrics - Show performance metrics")
print("  !ea_test encountersummary - Print the last finalized encounter summary, or the active one if no finalized summary exists")
print("  !ea_test telemetry on|off|show|dump - Control and inspect debug telemetry")
print("  !ea_test xpclones export - Export live template->stat source data for the XP-zero clone generator")
print("  !ea_test phase0 [show|reset] - Inspect or reset Phase 0 session/load + listener registration counters")
print("  !ea_test reststats [show|reset|export] - Session rest-flow counters and JSON export")
print("  !ea_test repstats [show|reset|export] - Session reputation-change counters and JSON export")
print("  !ea_test readiness - Print ModVars, persisted-time policy, and game-time probe diagnostics")
print("  !ea_test hostileretry [show|arm <enemy> [delayMs] [tries]|clear] - Inspect or seed the persistent hostile-retry queue for load-rearm proof")
print("  !ea_test poolowner - Print pool-owner identity, exported surface status, and active-list diagnostics")
print("  !ea_test spawnstagger [show|on|off|<ms>] - Inspect or tune staggered runtime spawn pacing")
print("  !ea_test settings - Print effective/raw XP, loot, rest chance/delay, quick-test, and cooldown settings")
print("  !ea_test debug on|off - Toggle debug mode")
print("  !ea_test championpolicy [show|compat|strict|debug_only|default] - Inspect or override champion summon-fallback policy")
print("  !ea_test region|getregion - Print raw region, canonical region, trigger safe zones, and ambush allow/block state")
print("  !ea_test regionwatch on [seconds]|off|once - Live region/safe-zone change logger (default 30s)")
print("  !ea_test beachstate - Dump beach bootstrap flags, readiness, and runtime state")
print("  !ea_test msgbox [open|yesno|demo] [text] - Test message box APIs")
print("  !ea_test scenario [list|run <id>] - Scripted scenario debug commands")
print("  !ea_test reputation - Reputation system commands")
print("  !ea_test testrep [type] - Test reputation change")
end
end)
end

if Ext and Ext.Osiris and Ext.Osiris.RegisterListener and not EnemyAmbush._eaStartedFleeingDebugListenerRegistered then
EnemyAmbush._eaStartedFleeingDebugListenerRegistered = true
Ext.Osiris.RegisterListener("StartedFleeing", 1, "after", function(character)
    if not EA_IsWatchedFleeTarget(character) then
        return
    end
    EA_ClearFleeWatch(character)
    print(string.format("[EnemyAmbush][Debug]    StartedFleeing: %s", tostring(character)))
end)
end

-- Legacy command aliases kept for backwards compatibility with prior QA scripts.
if Ext and Ext.RegisterConsoleCommand and not EnemyAmbush._eaDebugTelemetryAliasRegistered then
EnemyAmbush._eaDebugTelemetryAliasRegistered = true
Ext.RegisterConsoleCommand("ea_debugtelemetry_on", function(cmd, ...)
EA_SetDebugTelemetryEnabled(true)
end)
Ext.RegisterConsoleCommand("ea_debugtelemetry_off", function(cmd, ...)
EA_SetDebugTelemetryEnabled(false)
end)
end

