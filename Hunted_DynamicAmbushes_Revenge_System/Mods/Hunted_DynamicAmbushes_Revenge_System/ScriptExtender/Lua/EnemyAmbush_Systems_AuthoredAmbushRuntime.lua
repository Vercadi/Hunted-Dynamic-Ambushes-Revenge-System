EnemyAmbush = EnemyAmbush or {}
local RootEA = EnemyAmbush

local M = {}

function M.Build(deps)
deps = (type(deps) == "table") and deps or {}

local EA = type(deps.EA) == "table" and deps.EA or RootEA
EA.SystemsModules = EA.SystemsModules or {}

local AuthoredAmbushService = type(deps.AuthoredAmbushService) == "table" and deps.AuthoredAmbushService or nil
local AuthoredAmbushRuntime = {}

local DebugPrint = EA["DebugPrint"] or function(...) end
local EA_Dirty = EA["EA_Dirty"] or function() end
local EA_GetRegionForCharacter = EA["EA_GetRegionForCharacter"]
local EA_GetSafeZoneState = EA["EA_GetSafeZoneState"]
local EA_IsCharacterInBlockedSafeZone = EA["EA_IsCharacterInBlockedSafeZone"]
local EA_IsRegionBlocked = EA["EA_IsRegionBlocked"]
local EA_IsRegionCamp = EA["EA_IsRegionCamp"]
local EA_IsAnyPartyInCombat = EA["EA_IsAnyPartyInCombat"]
local EA_NowMs = EA["EA_NowMs"] or function() return 0 end
local EA_Vars = EA["EA_Vars"]
local EA_NormalizeUUID = EA["EA_NormalizeUUID"]
local GetSafeLevel = EA["GetSafeLevel"]
local SpawnHostileNearPlayer = EA["SpawnHostileNearPlayer"]
local EA_GetSettingFromSnapshot = EA["EA_GetSettingFromSnapshot"]
local EA_ShouldSkipBeachTutorialAmbush = EA["EA_ShouldSkipBeachTutorialAmbush"]
local EA_PublicTriggerRequestSeq = 0

local function EA_IsVarsContainer(value)
    local fn = deps.EA_IsModVarsContainer
    if type(fn) ~= "function" then
        fn = EA and EA["EA_IsModVarsContainer"]
    end
    if type(fn) == "function" then
        local ok, out = pcall(fn, value)
        return ok and out == true
    end
    return false
end

local function EA_GetFn(name, fallback)
    local fn = EA and EA[name]
    if type(fn) == "function" then
        return fn
    end
    if type(fallback) == "function" then
        return fallback
    end
    return nil
end

local function EA_SafeGetHostPlayer()
    if Osi and Osi.GetHostCharacter then
        local host = Osi.GetHostCharacter()
        if host and host ~= "" then return host end
    end
    return nil
end

local function EA_GetScenarioCharacterKey(character)
    local normalizeFn = EA_GetFn("EA_NormalizeUUID", EA_NormalizeUUID)
    if type(normalizeFn) == "function" then
        local ok, normalized = pcall(normalizeFn, character)
        if ok and type(normalized) == "string" and normalized ~= "" then
            return normalized
        end
    end
    return tostring(character or "")
end

local function EA_Notify(player, text)
    local debugEnabled = false
    if type(EA_GetSettingFromSnapshot) == "function" then
        local okLogging, logging = pcall(EA_GetSettingFromSnapshot, "MCM_EnableDebugLogging", false)
        if okLogging and logging == true then
            debugEnabled = true
        end
        local ok, out = pcall(EA_GetSettingFromSnapshot, "MCM_DebugMode", false)
        debugEnabled = debugEnabled or (ok and out == true)
    end
    if debugEnabled and text and text ~= "" then
        DebugPrint("Scenario notify suppressed:", tostring(text))
    end
end

local function EA_GetScenarioState()
    local varsFn = EA_GetFn("EA_Vars", EA_Vars)
    if type(varsFn) ~= "function" then
        return nil
    end
    local okVars, vars = pcall(varsFn)
    if not okVars then
        return nil
    end
    if not ((EA_IsVarsContainer(vars)) or type(vars) == "table") then return nil end
    if type(vars.EA_ScriptedScenarioState) ~= "table" then
        vars.EA_ScriptedScenarioState = {}
    end
    local state = vars.EA_ScriptedScenarioState
    if type(state.completed) ~= "table" then state.completed = {} end
    if type(state.lastRun) ~= "table" then state.lastRun = {} end
    if type(state.regionEntry) ~= "table" then state.regionEntry = {} end
    if type(state.regionEntry.lastCanonicalByCharacter) ~= "table" then
        state.regionEntry.lastCanonicalByCharacter = {}
    end
    state.version = 2
    return state
end

local function EA_IsBeachWakeupAlreadyHandled(state)
    if type(EA_ShouldSkipBeachTutorialAmbush) == "function" and EA_ShouldSkipBeachTutorialAmbush() then
        if type(state) == "table" and type(state.completed) == "table" and state.completed["EA_SCN_BEACH_WAKEUP"] == nil then
            state.completed["EA_SCN_BEACH_WAKEUP"] = EA_NowMs()
            EA_Dirty(true)
        end
        return true
    end

    local varsFn = EA_GetFn("EA_Vars", EA_Vars)
    if type(varsFn) == "function" then
        local okVars, vars = pcall(varsFn)
        if okVars and ((EA_IsVarsContainer(vars)) or type(vars) == "table") then
            local beachState = vars.EA_BeachBootstrapState
            if type(beachState) == "table" and tonumber(beachState.doneAt) and tonumber(beachState.doneAt) > 0 then
                if type(state) == "table" and type(state.completed) == "table" and state.completed["EA_SCN_BEACH_WAKEUP"] == nil then
                    state.completed["EA_SCN_BEACH_WAKEUP"] = tonumber(beachState.doneAt) or EA_NowMs()
                    EA_Dirty(true)
                end
                return true
            end
        end
    end

    return false
end

local function EA_BeachWakeupEligibleFromBootstrapState()
    local varsFn = EA_GetFn("EA_Vars", EA_Vars)
    if type(varsFn) ~= "function" then
        return false
    end
    local okVars, vars = pcall(varsFn)
    if not okVars or not ((EA_IsVarsContainer(vars)) or type(vars) == "table") then
        return false
    end
    local beachState = vars.EA_BeachBootstrapState
    if type(beachState) ~= "table" then
        return false
    end
    return (tonumber(beachState.wakeupDoneSeenAt) or 0) > 0
end

local function EA_CopyTable(t)
    local out = {}
    for k, v in pairs(t or {}) do
        out[k] = v
    end
    return out
end

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

local function EA_ResolveLocaText(rawText)
    local shared = EA and EA["EA_ResolveLocaText"]
    if type(shared) == "function" then
        local ok, out = pcall(shared, rawText)
        if ok and type(out) == "string" then
            return out
        end
    end
    local text = tostring(rawText or "")
    if text == "" then
        return ""
    end
    local bare = EA_LocaHandleNoVersion(text)
    if bare and Osi and Osi.ResolveTranslatedString then
        local okBare, translatedBare = pcall(Osi.ResolveTranslatedString, bare)
        if okBare and type(translatedBare) == "string" and translatedBare ~= "" and translatedBare ~= bare then
            return translatedBare
        end
    end
    return text
end

local function EA_FindEnemyDataByTemplate(templateId, fallback)
    if not templateId or templateId == "" then
        return nil
    end
    local key = tostring(templateId):lower()

    local getEntryFn = EA_GetFn("EA_GetPoolTemplateEntryById", nil)
    if type(getEntryFn) == "function" then
        local okEntry, entry = pcall(getEntryFn, key)
        if okEntry and type(entry) == "table" then
            return EA_CopyTable(entry)
        end
    end

    local getVariantsFn = EA_GetFn("EA_GetPoolTemplateVariantsById", nil)
    if type(getVariantsFn) == "function" then
        local okVariants, variants = pcall(getVariantsFn, key)
        if okVariants and type(variants) == "table" and type(variants[1]) == "table" then
            return EA_CopyTable(variants[1])
        end
    end

    if type(fallback) == "table" then
        local out = EA_CopyTable(fallback)
        out.template = key
        if not out.name then out.name = "Scripted Ambusher" end
        if not out.level then out.level = 1 end
        if not out.creatureType then out.creatureType = "Beast" end
        if out.status == nil then out.status = "" end
        if out.weight == nil then out.weight = 1 end
        return out
    end

    return nil
end

local EA_INTERNAL_AUTHORED_MATCHERS = {
    beach_wakeup = function(_definition, _ctx, matchState)
        if EA_IsBeachWakeupAlreadyHandled(matchState) then
            return false
        end
        return EA_BeachWakeupEligibleFromBootstrapState()
    end,
}

local function EA_ListAuthoredAmbushDefinitions()
    if type(AuthoredAmbushService) == "table" and type(AuthoredAmbushService.ListDefinitions) == "function" then
        return AuthoredAmbushService.ListDefinitions()
    end
    return {}
end

local function EA_GetAuthoredAmbushDefinitionById(definitionId)
    if type(AuthoredAmbushService) == "table" and type(AuthoredAmbushService.GetDefinition) == "function" then
        return AuthoredAmbushService.GetDefinition(definitionId)
    end
    return nil
end

local function EA_FindMatchingAuthoredAmbush(ctx, state)
    if type(AuthoredAmbushService) ~= "table" or type(AuthoredAmbushService.FindFirstMatchingDefinition) ~= "function" then
        return nil, "service_unavailable"
    end
    return AuthoredAmbushService.FindFirstMatchingDefinition(ctx, state, {
        internalMatchers = EA_INTERNAL_AUTHORED_MATCHERS,
    })
end

local function EA_MatchesInternalAuthoredDefinition(definition, ctx, state)
    if type(AuthoredAmbushService) ~= "table" or type(AuthoredAmbushService.MatchesGeneric) ~= "function" then
        return false, "service_unavailable"
    end

    local matched, reason = AuthoredAmbushService.MatchesGeneric(definition, ctx, state)
    if matched ~= true then
        return false, reason or "generic_mismatch"
    end

    local matcherId = type(definition.gates) == "table" and definition.gates.internalMatcherId or nil
    if matcherId ~= nil then
        local matcher = EA_INTERNAL_AUTHORED_MATCHERS[matcherId]
        if type(matcher) ~= "function" then
            return false, "internal_matcher_missing"
        end
        local okMatch, out = pcall(matcher, definition, ctx, state)
        if not okMatch or out ~= true then
            return false, "internal_matcher_blocked"
        end
    end

    return true, "matched"
end

local function EA_DefinitionPostCombatMessage(definition)
    local presentation = type(definition) == "table" and definition.presentation or nil
    return type(presentation) == "table" and tostring(presentation.postCombatMessage or "") or ""
end

local function EA_DefinitionOnboardingAfterCombat(definition)
    local presentation = type(definition) == "table" and definition.presentation or nil
    return type(presentation) == "table" and presentation.onboardingAfterCombat == true
end

local function EA_DefinitionIntroText(definition)
    local presentation = type(definition) == "table" and definition.presentation or nil
    return type(presentation) == "table" and tostring(presentation.introText or "") or ""
end

local function EA_DefinitionCompletionText(definition)
    local presentation = type(definition) == "table" and definition.presentation or nil
    return type(presentation) == "table" and tostring(presentation.completionText or "") or ""
end

local function EA_DefinitionTheme(definition)
    local spawn = type(definition) == "table" and definition.spawn or nil
    return type(spawn) == "table" and tostring(spawn.theme or "") or ""
end

local function EA_DefinitionSpawnEntries(definition)
    local spawn = type(definition) == "table" and definition.spawn or nil
    if type(spawn) == "table" and type(spawn.entries) == "table" then
        return spawn.entries
    end
    return {}
end

local function EA_LogRegionEntryEvaluation(ctx, outcome, scenarioId)
    DebugPrint(string.format(
        "[Scenario] region_entry source=%s prev=%s current=%s raw=%s blockedSafe=%s blockedRegion=%s camp=%s outcome=%s scenario=%s",
        tostring(ctx and ctx.source or "?"),
        tostring(ctx and ctx.previousRegion or ""),
        tostring(ctx and ctx.region or ""),
        tostring(ctx and ctx.rawRegion or ""),
        tostring((ctx and ctx.inBlockedSafeZone) == true),
        tostring((ctx and ctx.regionBlocked) == true),
        tostring((ctx and ctx.regionIsCamp) == true),
        tostring(outcome or "unknown"),
        tostring(scenarioId or "")
    ))
end

local function EA_IsScenarioPromptShown(state, scenarioId)
    if type(state) ~= "table" then return false end
    state.flags = state.flags or {}
    return state.flags["post_prompt_" .. tostring(scenarioId)] == true
end

local function EA_SetScenarioPromptShown(state, scenarioId)
    if type(state) ~= "table" then return end
    state.flags = state.flags or {}
    state.flags["post_prompt_" .. tostring(scenarioId)] = true
    state.flags["post_prompt_" .. tostring(scenarioId) .. "_at"] = EA_NowMs()
    EA_Dirty(true)
end

local function EA_ScheduleScenarioPostCombatPrompt(character, scenario, spawnedEntities)
    if type(scenario) ~= "table" then return end
    local text = EA_ResolveLocaText(EA_DefinitionPostCombatMessage(scenario))
    if text == "" then return end
    if not (Ext and Ext.Timer and Ext.Timer.WaitFor) then return end

    local state = EA_GetScenarioState()
    if not state then return end
    if EA_IsScenarioPromptShown(state, scenario.id) then return end

    local maxChecks = 90
    local intervalMs = 2000
    local checks = 0
    local requiresCombat = EA_DefinitionOnboardingAfterCombat(scenario)
    local sawCombat = false

    local function IsAnySpawnStillAlive()
        for _, enemy in ipairs(spawnedEntities or {}) do
            if enemy and enemy ~= "" then
                local exists = (not Osi.ObjectExists) or (Osi.ObjectExists(enemy) == 1)
                local alive = exists and ((not Osi.IsDead) or (Osi.IsDead(enemy) ~= 1))
                if alive then
                    return true
                end
            end
        end
        return false
    end

    local function IsPartyInCombat()
        local fn = EA and EA["EA_IsAnyPartyInCombat"]
        if type(fn) == "function" then
            local ok, inCombat = pcall(fn)
            if ok and inCombat == true then
                return true
            end
        end
        if character and character ~= "" and Osi.ObjectExists and Osi.ObjectExists(character) == 1 and Osi.IsInCombat then
            return Osi.IsInCombat(character) == 1
        end
        return false
    end

    local function Tick()
        checks = checks + 1

        local inCombat = IsPartyInCombat()
        if inCombat then
            sawCombat = true
        end
        local alive = IsAnySpawnStillAlive()
        local combatGatePassed = (not requiresCombat) or sawCombat

        -- Show after first fight settles. For onboarding flows that explicitly
        -- require combat, do not show if no combat engagement was observed.
        if combatGatePassed and (not inCombat) and ((not alive) or checks >= 30) then
            local target = character
            if not target or target == "" then
                target = EA_SafeGetHostPlayer()
            end
            if target and target ~= "" and Osi and Osi.OpenMessageBox then
                pcall(Osi.OpenMessageBox, target, text)
                if Osi.PlaySound then
                    pcall(Osi.PlaySound, target, "UI_Notification_QuestUpdate")
                end
            end
            local st = EA_GetScenarioState()
            if st then
                EA_SetScenarioPromptShown(st, scenario.id)
            end
            return
        end

        if checks >= maxChecks then
            local debugEnabled = false
            if type(EA_GetSettingFromSnapshot) == "function" then
                local okLogging, logging = pcall(EA_GetSettingFromSnapshot, "MCM_EnableDebugLogging", false)
                if okLogging and logging == true then
                    debugEnabled = true
                end
                local ok, out = pcall(EA_GetSettingFromSnapshot, "MCM_DebugMode", false)
                debugEnabled = debugEnabled or (ok and out == true)
            end
            if debugEnabled and requiresCombat and (not sawCombat) then
                DebugPrint("Scenario post-combat prompt skipped (no combat observed):", tostring(scenario.id or "unknown"))
            end
            return
        end

        Ext.Timer.WaitFor(intervalMs, Tick)
    end

    Ext.Timer.WaitFor(intervalMs, Tick)
end

local function EA_RunScenario(character, scenario, forceRun, opts)
    if not character or character == "" then return false, 0, "invalid_character" end
    opts = (type(opts) == "table") and opts or {}
    local persistScenarioState = (opts.persistState ~= false)

    local spawnFn = EA_GetFn("SpawnHostileNearPlayer", SpawnHostileNearPlayer)
    if type(spawnFn) ~= "function" then
        DebugPrint("Scripted scenario spawn function unavailable:", tostring(scenario and scenario.id or "unknown"))
        return false, 0, "spawn_function_unavailable"
    end

    local state = nil
    if persistScenarioState or not forceRun then
        state = EA_GetScenarioState()
    end
    if (persistScenarioState or not forceRun) and not state then
        DebugPrint("Scripted scenario state unavailable:", tostring(scenario and scenario.id or "unknown"))
        return false, 0, "state_unavailable"
    end

    if not forceRun then
        local getLevelFn = EA_GetFn("GetSafeLevel", GetSafeLevel)
        local level = (type(getLevelFn) == "function") and (tonumber(getLevelFn(character)) or 1) or 1
        local region = "UNKNOWN"
        local getRegionFn = EA_GetFn("EA_GetRegionForCharacter", EA_GetRegionForCharacter)
        if type(getRegionFn) == "function" then
            local canonical = getRegionFn(character)
            region = tostring(canonical or "UNKNOWN")
        end
        local ctx = {
            triggerKind = "rest",
            isLongRest = false,
            level = level,
            region = region
        }
        local matchedDefinition = EA_FindMatchingAuthoredAmbush(ctx, state)
        if type(matchedDefinition) ~= "table" or tostring(matchedDefinition.id or "") ~= tostring(scenario.id or "") then
            return false, 0, "context_mismatch"
        end
    end

    local introText = EA_DefinitionIntroText(scenario)
    if introText ~= "" then
        EA_Notify(character, introText)
    end

    local spawned = 0
    local spawnedEntities = {}
    local spawnCap = tonumber(opts.spawnCap)
    if spawnCap ~= nil then
        spawnCap = math.max(1, math.floor(spawnCap))
    end

    for index, spawnSpec in ipairs(EA_DefinitionSpawnEntries(scenario)) do
        if spawnCap and spawned >= spawnCap then
            break
        end

        local enemyData = EA_FindEnemyDataByTemplate(spawnSpec.template, spawnSpec.fallback)
        if enemyData then
            local roll = {
                tier = "COMMON",
                category = "COMMON",
                spawnRole = (index == 1) and "leader" or "support",
                spawnDist = tonumber(spawnSpec.spawnDist) or 8,
                forceFindValidPosition = (spawnSpec.forceFindValidPosition == true),
                preCombatGraceMs = tonumber(spawnSpec.preCombatGraceMs) or nil,
                disableAggressiveAdvance = (spawnSpec.disableAggressiveAdvance == true),
                noReputation = (spawnSpec.noReputation == true),
                scriptedScenario = scenario.id
            }
            if type(spawnSpec.combatStartBarks) == "table" and #spawnSpec.combatStartBarks > 0 then
                local copiedBarks = {}
                for _, barkId in ipairs(spawnSpec.combatStartBarks) do
                    if type(barkId) == "string" and barkId ~= "" then
                        copiedBarks[#copiedBarks + 1] = barkId
                    end
                end
                if #copiedBarks > 0 then
                    roll.combatStartBarks = copiedBarks
                end
            end
            if spawnSpec.combatStartNoFallback == true then
                roll.combatStartNoFallback = true
            end
            if spawnSpec.noEscape == true then
                roll.noEscape = true
            end
            if spawnSpec.suppressCombatStartPresentation == true then
                roll.suppressCombatStartPresentation = true
            end
            if type(spawnSpec.combatStartSounds) == "table" and #spawnSpec.combatStartSounds > 0 then
                local copiedSounds = {}
                for _, soundId in ipairs(spawnSpec.combatStartSounds) do
                    if type(soundId) == "string" and soundId ~= "" then
                        copiedSounds[#copiedSounds + 1] = soundId
                    end
                end
                if #copiedSounds > 0 then
                    roll.combatStartSounds = copiedSounds
                end
            end
            if spawnSpec.combatStartSoundAlways == true then
                roll.combatStartSoundAlways = true
            end
            if type(spawnSpec.combatTurnBarks) == "table" and #spawnSpec.combatTurnBarks > 0 then
                local copiedTurnBarks = {}
                for _, barkId in ipairs(spawnSpec.combatTurnBarks) do
                    if type(barkId) == "string" and barkId ~= "" then
                        copiedTurnBarks[#copiedTurnBarks + 1] = barkId
                    end
                end
                if #copiedTurnBarks > 0 then
                    roll.combatTurnBarks = copiedTurnBarks
                end
            end
            if type(spawnSpec.combatTurnSounds) == "table" and #spawnSpec.combatTurnSounds > 0 then
                local copiedTurnSounds = {}
                for _, soundId in ipairs(spawnSpec.combatTurnSounds) do
                    if type(soundId) == "string" and soundId ~= "" then
                        copiedTurnSounds[#copiedTurnSounds + 1] = soundId
                    end
                end
                if #copiedTurnSounds > 0 then
                    roll.combatTurnSounds = copiedTurnSounds
                end
            end
            if spawnSpec.combatTurnSoundAlways == true then
                roll.combatTurnSoundAlways = true
            end
            if spawnSpec.combatTurnEnemyOnly == true then
                roll.combatTurnEnemyOnly = true
            end
            if spawnSpec.combatTurnLimit ~= nil then
                local turnLimit = math.max(0, math.min(8, math.floor(tonumber(spawnSpec.combatTurnLimit) or 0)))
                if turnLimit > 0 then
                    roll.combatTurnLimit = turnLimit
                end
            end
            local enemy = spawnFn(
                character,
                tonumber(spawnSpec.duration) or 60,
                enemyData,
                roll,
                EA_DefinitionTheme(scenario)
            )
            if enemy and enemy ~= "" then
                spawned = spawned + 1
                spawnedEntities[#spawnedEntities + 1] = enemy
            else
                DebugPrint(
                    string.format(
                        "Scripted scenario spawn failed (%s idx=%d template=%s)",
                        tostring(scenario.id),
                        tonumber(index) or -1,
                        tostring(spawnSpec.template or "")
                    )
                )
            end
        else
            DebugPrint("Scripted scenario missing template:", tostring(spawnSpec.template))
        end
    end

    if spawned > 0 then
        if persistScenarioState and state then
            state.lastRun[scenario.id] = {
                ts = EA_NowMs(),
                count = spawned
            }
            if scenario.once then
                state.completed[scenario.id] = EA_NowMs()
            end
            EA_Dirty(true)
        end
        print(string.format("[EnemyAmbush][Scenario] %s spawned %d enemies.", tostring(scenario.id), spawned))
        local completionText = EA_DefinitionCompletionText(scenario)
        if completionText ~= "" then
            EA_Notify(character, completionText)
        end
        if persistScenarioState then
            EA_ScheduleScenarioPostCombatPrompt(character, scenario, spawnedEntities)
        end
        return true, spawned, "ok"
    end

    return false, 0, "no_spawned_entities"
end

local function EA_NextPublicTriggerRequestId(definitionId)
    EA_PublicTriggerRequestSeq = EA_PublicTriggerRequestSeq + 1
    return string.format(
        "EA_API_TRIGGER_%s_%d_%d",
        tostring(definitionId or "unknown"),
        tonumber(EA_NowMs()) or 0,
        EA_PublicTriggerRequestSeq
    )
end

local function EA_CopyList(list)
    local out = {}
    if type(list) ~= "table" then
        return out
    end
    for _, value in ipairs(list) do
        out[#out + 1] = value
    end
    return out
end

local function EA_GetPublicTriggerFlowLabel(definition, ctx)
    local flowLabel = tostring(type(ctx) == "table" and ctx.flowLabel or "")
    if flowLabel ~= "" then
        return flowLabel
    end
    local presentation = type(definition) == "table" and definition.presentation or nil
    flowLabel = tostring(type(presentation) == "table" and presentation.flowLabel or "")
    if flowLabel ~= "" then
        return flowLabel
    end
    return nil
end

local function EA_BuildPublicScenario(definitionId, definition, ctx)
    if type(definition) ~= "table" then
        return nil, "definition not found"
    end
    local spawn = type(definition.spawn) == "table" and definition.spawn or {}
    local policies = type(definition.policies) == "table" and definition.policies or {}
    local presentation = type(definition.presentation) == "table" and definition.presentation or {}

    if tostring(spawn.mode or "") ~= "custom_entries" then
        return nil, "unsupported spawn.mode"
    end
    if tostring(policies.hostilityMode or "default") ~= "default" then
        return nil, "unsupported hostilityMode"
    end
    if tostring(policies.rewardMode or "default") ~= "default" then
        return nil, "unsupported rewardMode"
    end

    local theme = tostring(spawn.themeKey or "")
    if theme == "" then
        theme = "PUBLIC_CUSTOM"
    end

    local entries = {}
    for _, entry in ipairs(type(spawn.entries) == "table" and spawn.entries or {}) do
        if type(entry) == "table" then
            local count = math.max(1, math.floor(tonumber(entry.count) or 1))
            for _ = 1, count do
                entries[#entries + 1] = {
                    template = tostring(entry.template or ""),
                    fallback = {
                        name = tostring(entry.displayName or "Custom Ambusher"),
                        level = math.max(1, math.floor(tonumber(entry.level) or 1)),
                        creatureType = tostring(entry.creatureType or spawn.themeKey or "Humanoid"),
                        status = "",
                    },
                    noReputation = (tostring(policies.reputationMode or "default") == "none"),
                }
            end
        end
    end

    if #entries == 0 then
        return nil, "invalid entries"
    end

    return {
        id = tostring(definitionId or ""),
        label = tostring(definitionId or ""),
        enabled = true,
        once = (definition.once == true),
        priority = tonumber(definition.priority) or 0,
        triggerKinds = { "internal_call" },
        spawn = {
            mode = "fixed_spawn_specs",
            theme = theme,
            entries = entries,
        },
        presentation = {
            introText = tostring(presentation.introLoca or ""),
            completionText = "",
            postCombatMessage = "",
            onboardingAfterCombat = false,
        },
        internal = {
            publicDefinition = true,
            source = tostring(type(ctx) == "table" and ctx.source or "external"),
        },
    }, nil
end

local function EA_RunPublicScenarioBridge(requestKey, definitionId, definition, ctx, onAccepted)
    local scenario, scenarioReason = EA_BuildPublicScenario(requestKey, definition, ctx)
    if type(scenario) ~= "table" then
        return false, tostring(scenarioReason or "runtime_unsupported")
    end

    local character = tostring(ctx.character or "")
    local okRun, spawned, runReason = EA_RunScenario(character, scenario, true, {
        persistState = false,
    })
    if okRun ~= true then
        return false, tostring(runReason or "trigger_failed")
    end

    if type(onAccepted) == "function" then
        pcall(onAccepted)
    end

    return true, {
        accepted = true,
        requestId = EA_NextPublicTriggerRequestId(requestKey),
        definitionId = definitionId,
        flowLabel = EA_GetPublicTriggerFlowLabel(definition, ctx),
        source = tostring(ctx.source or "external"),
        queued = false,
        triggerKinds = EA_CopyList(definition.triggerKinds),
        character = character,
    }
end

local function EA_TryTriggerPublicAmbushDefinition(definitionId, ctx)
    definitionId = tostring(definitionId or "")
    if definitionId == "" then
        return false, "invalid id"
    end
    if type(ctx) ~= "table" then
        return false, "invalid ctx"
    end
    if type(AuthoredAmbushService) ~= "table" or type(AuthoredAmbushService.ValidatePublicDefinitionTrigger) ~= "function" then
        return false, "service unavailable"
    end

    local okValidate, definitionOrReason, maybeDefinition = pcall(AuthoredAmbushService.ValidatePublicDefinitionTrigger, definitionId, ctx)
    if not okValidate then
        return false, "validation_failed"
    end

    local definition = nil
    if definitionOrReason ~= true then
        return false, tostring(maybeDefinition or definitionOrReason or "validation_failed")
    end
    definition = maybeDefinition
    if type(definition) ~= "table" then
        return false, "definition not found"
    end

    return EA_RunPublicScenarioBridge(definitionId, definitionId, definition, ctx, function()
        if type(AuthoredAmbushService.MarkPublicDefinitionTriggered) == "function" then
            pcall(AuthoredAmbushService.MarkPublicDefinitionTriggered, definitionId, {
                atMs = EA_NowMs(),
            })
        end
    end)
end

local function EA_TryTriggerPublicCustomAmbush(payload, ctx)
    if type(payload) ~= "table" then
        return false, "invalid payload"
    end
    if type(ctx) ~= "table" then
        return false, "invalid ctx"
    end
    if type(AuthoredAmbushService) ~= "table" or type(AuthoredAmbushService.NormalizePublicCustomPayload) ~= "function" then
        return false, "service unavailable"
    end

    local okNormalize, normalizedOrReason, maybeReason = pcall(AuthoredAmbushService.NormalizePublicCustomPayload, payload)
    if not okNormalize then
        return false, "validation_failed"
    end

    local definition = nil
    if type(normalizedOrReason) ~= "table" then
        return false, tostring(maybeReason or normalizedOrReason or "invalid payload")
    end
    definition = normalizedOrReason

    return EA_RunPublicScenarioBridge("custom", nil, definition, ctx, nil)
end

local function EA_TryRunRegionEntryAuthoredScenario(character, opts)
    if not character or character == "" then
        return false, 0, "invalid_character"
    end
    opts = (type(opts) == "table") and opts or {}

    local state = EA_GetScenarioState()
    if not state then
        return false, 0, "state_unavailable"
    end

    local regionState = type(state.regionEntry) == "table" and state.regionEntry or nil
    local lastCanonicalByCharacter = regionState and regionState.lastCanonicalByCharacter or nil
    if type(lastCanonicalByCharacter) ~= "table" then
        return false, 0, "region_entry_state_unavailable"
    end

    local getLevelFn = EA_GetFn("GetSafeLevel", GetSafeLevel)
    local level = (type(getLevelFn) == "function") and (tonumber(getLevelFn(character)) or 1) or 1

    local currentRegion = tostring(opts.canonicalRegion or "")
    local rawRegion = tostring(opts.rawRegion or "")
    local getRegionFn = EA_GetFn("EA_GetRegionForCharacter", EA_GetRegionForCharacter)
    if type(getRegionFn) == "function" and currentRegion == "" then
        local canonical, raw = getRegionFn(character)
        currentRegion = tostring(canonical or "")
        if rawRegion == "" then
            rawRegion = tostring(raw or "")
        end
    end
    if currentRegion == "" then
        return false, 0, "region_unavailable"
    end

    local characterKey = EA_GetScenarioCharacterKey(character)
    local previousRegion = tostring(lastCanonicalByCharacter[characterKey] or "")
    local regionUpdated = (previousRegion ~= currentRegion)
    if regionUpdated then
        lastCanonicalByCharacter[characterKey] = currentRegion
    end

    local getSafeZoneFn = EA_GetFn("EA_GetSafeZoneState", EA_GetSafeZoneState)
    local safeZoneState = type(getSafeZoneFn) == "function" and getSafeZoneFn(character) or nil
    local blockedSafeZoneFn = EA_GetFn("EA_IsCharacterInBlockedSafeZone", EA_IsCharacterInBlockedSafeZone)
    local inBlockedSafeZone = type(blockedSafeZoneFn) == "function" and blockedSafeZoneFn(character) == true or false
    local isRegionBlockedFn = EA_GetFn("EA_IsRegionBlocked", EA_IsRegionBlocked)
    local regionBlocked = type(isRegionBlockedFn) == "function" and isRegionBlockedFn(currentRegion) == true or false
    local isRegionCampFn = EA_GetFn("EA_IsRegionCamp", EA_IsRegionCamp)
    local regionIsCamp = type(isRegionCampFn) == "function" and isRegionCampFn(currentRegion) == true or false

    local ctx = {
        triggerKind = "region_entry",
        source = tostring(opts.source or "EnteredLevel"),
        level = level,
        region = currentRegion,
        rawRegion = rawRegion,
        previousRegion = previousRegion,
        inBlockedSafeZone = inBlockedSafeZone,
        safeZoneState = safeZoneState,
        regionBlocked = regionBlocked,
        regionIsCamp = regionIsCamp,
    }

    if previousRegion == "" then
        if regionUpdated then
            EA_Dirty(true)
        end
        EA_LogRegionEntryEvaluation(ctx, "first_observation", nil)
        return false, 0, "first_observation"
    end

    if previousRegion == currentRegion then
        EA_LogRegionEntryEvaluation(ctx, "same_canonical_region", nil)
        return false, 0, "same_canonical_region"
    end

    local scenario = EA_FindMatchingAuthoredAmbush(ctx, state)
    if type(scenario) ~= "table" then
        if regionUpdated then
            EA_Dirty(true)
        end
        EA_LogRegionEntryEvaluation(ctx, "no_match", nil)
        return false, 0, "no_match"
    end

    local ok, spawned, reason = EA_RunScenario(character, scenario, true, opts)
    if regionUpdated then
        EA_Dirty(true)
    end
    EA_LogRegionEntryEvaluation(ctx, reason or (ok and "ok" or "run_failed"), scenario.id)
    return ok, spawned or 0, reason or "run_failed"
end

local function EA_TryRunInternalAuthoredScenario(character, opts)
    if not character or character == "" then
        return false, 0, "invalid_character"
    end
    opts = (type(opts) == "table") and opts or {}

    local state = EA_GetScenarioState()
    if not state then
        return false, 0, "state_unavailable"
    end

    local getLevelFn = EA_GetFn("GetSafeLevel", GetSafeLevel)
    local level = (type(getLevelFn) == "function") and (tonumber(getLevelFn(character)) or 1) or 1
    local region = "UNKNOWN"
    local getRegionFn = EA_GetFn("EA_GetRegionForCharacter", EA_GetRegionForCharacter)
    if type(getRegionFn) == "function" then
        local canonical = getRegionFn(character)
        region = tostring(canonical or "UNKNOWN")
    end

    local ctx = {
        triggerKind = "internal_call",
        force = (opts.force == true or opts.forceRun == true),
        source = tostring(opts.source or "internal_call"),
        level = level,
        region = region,
    }

    local scenarioId = tostring(opts.definitionId or opts.scenarioId or "")
    local scenario = nil
    if scenarioId ~= "" then
        scenario = EA_GetAuthoredAmbushDefinitionById(scenarioId)
        if type(scenario) ~= "table" then
            return false, 0, "scenario_not_found"
        end
        local matched, reason = EA_MatchesInternalAuthoredDefinition(scenario, ctx, state)
        if matched ~= true then
            return false, 0, reason or "internal_context_mismatch"
        end
    else
        scenario = EA_FindMatchingAuthoredAmbush(ctx, state)
        if type(scenario) ~= "table" then
            return false, 0, "no_match"
        end
    end

    return EA_RunScenario(character, scenario, true, opts)
end

local function EA_TryRunScriptedScenario(character, isLongRest, forceAmbush)
    if not character or character == "" then return false end
    local state = EA_GetScenarioState()
    if not state then return false end

    local getLevelFn = EA_GetFn("GetSafeLevel", GetSafeLevel)
    local level = (type(getLevelFn) == "function") and (tonumber(getLevelFn(character)) or 1) or 1
    local region = "UNKNOWN"
    local getRegionFn = EA_GetFn("EA_GetRegionForCharacter", EA_GetRegionForCharacter)
    if type(getRegionFn) == "function" then
        local canonical = getRegionFn(character)
        region = tostring(canonical or "UNKNOWN")
    end

    local ctx = {
        triggerKind = "rest",
        isLongRest = (isLongRest == true),
        force = (forceAmbush == true),
        level = level,
        region = region
    }

    local scenario = EA_FindMatchingAuthoredAmbush(ctx, state)
    if type(scenario) == "table" then
        local ok = EA_RunScenario(character, scenario, true)
        if ok then
            return true
        end
    end

    return false
end

local function EA_RunScriptedScenarioById(character, scenarioId, forceRun, opts)
    if not scenarioId or scenarioId == "" then return false end
    local scenario = EA_GetAuthoredAmbushDefinitionById(scenarioId)
    if type(scenario) == "table" then
        local ok, spawned, reason = EA_RunScenario(character, scenario, forceRun == true, opts)
        return ok, spawned, reason
    end
    return false, 0, "scenario_not_found"
end

local function EA_ListScriptedScenarios()
    local state = EA_GetScenarioState() or { completed = {} }
    local out = {}
    for _, scenario in ipairs(EA_ListAuthoredAmbushDefinitions()) do
        out[#out + 1] = {
            id = scenario.id,
            label = scenario.label,
            once = scenario.once == true,
            priority = tonumber(scenario.priority) or 0,
            completed = (state.completed and state.completed[scenario.id] ~= nil) and true or false
        }
    end
    return out
end

AuthoredAmbushRuntime.TryInternalScenario = EA_TryRunInternalAuthoredScenario
AuthoredAmbushRuntime.TryRegionEntryScenario = EA_TryRunRegionEntryAuthoredScenario
AuthoredAmbushRuntime.TriggerPublicDefinition = EA_TryTriggerPublicAmbushDefinition
AuthoredAmbushRuntime.TriggerPublicCustom = EA_TryTriggerPublicCustomAmbush
AuthoredAmbushRuntime.TryRunScriptedScenario = EA_TryRunScriptedScenario
AuthoredAmbushRuntime.RunScriptedScenarioById = EA_RunScriptedScenarioById
AuthoredAmbushRuntime.ListScriptedScenarios = EA_ListScriptedScenarios
AuthoredAmbushRuntime.GetScriptedScenarioState = EA_GetScenarioState

return AuthoredAmbushRuntime
end

return M
