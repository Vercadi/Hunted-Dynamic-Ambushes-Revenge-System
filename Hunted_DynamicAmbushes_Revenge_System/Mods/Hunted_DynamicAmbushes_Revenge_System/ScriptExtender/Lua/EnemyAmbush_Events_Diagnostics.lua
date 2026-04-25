EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

function M.Build(deps)
    deps = deps or {}

    local EnemyAmbush = deps.EnemyAmbush or EA
    local EA = deps.EA or EnemyAmbush or {}
    local DebugPrint = deps.DebugPrint or function() end
    local UpdateMetric = deps.UpdateMetric or function() end
    local EA_P0Inc = deps.EA_P0Inc or (EA and EA["EA_P0Inc"]) or function() return 0 end
    local EA_NormalizeUUID = deps.EA_NormalizeUUID or function(v) return v end
    local EA_Spawned = deps.EA_Spawned or function() return {} end
    local EA_GetPartyXPRecipients = deps.EA_GetPartyXPRecipients or function() return {} end
    local EA_GetEffectiveAmbushXPPercent = deps.EA_GetEffectiveAmbushXPPercent or function() return 100 end
    local EA_DebugEnabled = deps.EA_DebugEnabled or function() return false end
    local SafeOsiExec = deps.SafeOsiExec or function() return false end
    local EA_GetEffectiveDisableAmbushLoot = deps.EA_GetEffectiveDisableAmbushLoot or function() return true end
    local EA_ClearLootButKeepCorpseClickable = deps.EA_ClearLootButKeepCorpseClickable or function() end
    local EA_GetSettingBoolEvent = deps.EA_GetSettingBoolEvent or function(_, fallback) return fallback == true end
    local EA_ReputationTable = deps.EA_ReputationTable or function() return {} end
    local EA_ReputationThresholdTable = deps.EA_ReputationThresholdTable or function() return { WARY = -5, HOSTILE = -10, VENGEFUL = -20 } end
    local EA_IsAnyPartyInCombat = deps.EA_IsAnyPartyInCombat or function() return false end
    local EA_GetEncounterRepState = deps.EA_GetEncounterRepState or function() return { perType = {}, active = false, updatedAt = 0 } end
    local EA_GetOutOfCombatRepLedger = deps.EA_GetOutOfCombatRepLedger or function() return {} end
    local EA_PruneOutOfCombatRepLedger = deps.EA_PruneOutOfCombatRepLedger or function() end
    local EA_Dirty = deps.EA_Dirty or function() end
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local EA_GetEncounterRepMaxLoss = deps.EA_GetEncounterRepMaxLoss or function() return 3 end
    local EA_MarkRuntimeStateDirty = deps.EA_MarkRuntimeStateDirty or function() end
    local EA_LaunchEncounterRepWatchTimer = deps.EA_LaunchEncounterRepWatchTimer or function(_delayMs)
        return false
    end
    local EA_AddTypePressure = deps.EA_AddTypePressure or function() end
    local EA_FormatRepWarning = deps.EA_FormatRepWarning or function(_, fallbackFmt, creatureType)
        local ct = tostring(creatureType or "Unknown")
        local okFmt, outFmt = pcall(string.format, tostring(fallbackFmt or ""), ct)
        if okFmt and type(outFmt) == "string" and outFmt ~= "" then
            return outFmt
        end
        return tostring(fallbackFmt or "")
    end
    local EA_LOCA_REP_WARNING_WARY = deps.EA_LOCA_REP_WARNING_WARY or ""
    local EA_LOCA_REP_WARNING_HOSTILE = deps.EA_LOCA_REP_WARNING_HOSTILE or ""
    local EA_LOCA_REP_WARNING_VENGEFUL = deps.EA_LOCA_REP_WARNING_VENGEFUL or ""
    local PlayVFX_OnEntity = deps.PlayVFX_OnEntity or function() end
    local EA_CanSpawnChampionForType = deps.EA_CanSpawnChampionForType or function() return true end
    local EA_GetGuaranteedChampionQueueSafeFn = deps.EA_GetGuaranteedChampionQueueSafeFn or (EA and EA["EA_GetGuaranteedChampionQueueSafe"])
    local EA_RememberDefeatedSpawned = deps.EA_RememberDefeatedSpawned or (EA and EA["EA_RememberDefeatedSpawned"]) or function() end
    local SaveReputation = deps.SaveReputation
    local EA_ClearHostileState = deps.EA_ClearHostileState or function() end
    local EA_OUT_OF_COMBAT_REP_WINDOW_MS = tonumber(deps.EA_OUT_OF_COMBAT_REP_WINDOW_MS) or 120000

    local Runtime = {}

    local function EA_GetSpawnedRegistry()
        local spawned = EA_Spawned()
        if type(spawned) ~= "table" and type(spawned) ~= "userdata" then
            return nil
        end
        return spawned
    end

    local function EA_IsValidXPRecipient(character)
        return character
            and character ~= ""
            and Osi
            and Osi.IsPlayer
            and Osi.IsPlayer(character) == 1
    end

    local function EA_IsSamePartyXPRecipient(anchorPlayer, recipient)
        if not EA_IsValidXPRecipient(recipient) then
            return false
        end
        if anchorPlayer and anchorPlayer ~= "" and Osi and Osi.IsInPartyWith then
            local okSameParty, sameParty = pcall(Osi.IsInPartyWith, anchorPlayer, recipient)
            if okSameParty then
                return sameParty == 1
            end
        end
        return true
    end

    local function EA_FormatXPRecipients(recipients)
        if type(recipients) ~= "table" or #recipients == 0 then
            return "(none)"
        end
        local out = {}
        for _, recipient in ipairs(recipients) do
            out[#out + 1] = tostring(recipient)
        end
        return table.concat(out, ",")
    end

    local function EA_ResolveManualXPRecipients(anchorPlayer, fallbackCharacter)
        local recipients = {}
        local seen = {}

        local function Add(recipient)
            if not EA_IsSamePartyXPRecipient(anchorPlayer, recipient) then
                return
            end
            if seen[recipient] then
                return
            end
            seen[recipient] = true
            recipients[#recipients + 1] = recipient
        end

        if Osi and Osi.DB_Players and Osi.DB_Players.Get then
            local okRows, rows = pcall(function()
                return Osi.DB_Players:Get(nil)
            end)
            if okRows and type(rows) == "table" then
                for _, row in ipairs(rows) do
                    Add(row[1])
                end
                if #recipients > 0 then
                    return recipients, "db_players_party_filtered"
                end
            end
        end

        for _, recipient in ipairs(EA_GetPartyXPRecipients(anchorPlayer, fallbackCharacter) or {}) do
            Add(recipient)
        end
        if #recipients > 0 then
            return recipients, "event_helper_fallback"
        end

        return recipients, "none"
    end

    local function EA_ProcessSpawnedDefeat(character, spawnedData, defeatKind)
        if not character or character == "" then return false end
        if type(spawnedData) ~= "table" then return false end
        local spawned = EA_GetSpawnedRegistry()
        if not spawned then
            return false
        end
        if spawnedData._eaDefeatHandled == true then
            UpdateMetric("defeatDuplicateSuppressed")
            return false
        end
        spawnedData._eaDefeatHandled = true
    
        local id = EA_NormalizeUUID(character)
        local defeatTag = tostring(defeatKind or "died")
        if defeatTag == "knockout" then
            UpdateMetric("defeatHandledKnockout")
        elseif defeatTag == "died" then
            UpdateMetric("defeatHandledDied")
        else
            UpdateMetric("defeatHandledDying")
        end
        DebugPrint("Defeat event fired for (spawned):", tostring(character), "kind=", defeatTag)
        EA_RememberDefeatedSpawned(character, spawnedData, defeatTag)
    
        local player = Osi.GetClosestAlivePlayer(character)

        local xpPct = tonumber(spawnedData.xpPct) or EA_GetEffectiveAmbushXPPercent()
        if xpPct ~= 100 then
            local baseRaw = tonumber(spawnedData.xpBase)
            local base = baseRaw or 0
            local xpToGive = math.floor(base * (xpPct / 100) + 0.5)
            local xpSuppressMethod = tostring(spawnedData.xpSuppressMethod or "unknown")
            local xpSuppressVerified = (spawnedData.xpSuppressVerified == true)
            local xpBaseSource = tostring(spawnedData.xpBaseSource or "fallback_table")
            local xpRecipients, xpRecipientSource = EA_ResolveManualXPRecipients(player, character)
            local hasVerifiedCloneSuppression =
                (spawnedData.xpZeroed == true)
                and (xpSuppressVerified == true)
                and (xpSuppressMethod == "clone_template_zero_xp")
            local hasNumericBase = (baseRaw ~= nil)

            if hasVerifiedCloneSuppression and hasNumericBase then
                if EA_DebugEnabled() then
                    DebugPrint("XP payout plan:",
                        "enemy=", tostring(character),
                        "xpPct=", tostring(xpPct),
                        "xpBase=", tostring(base),
                        "xpBaseSource=", tostring(xpBaseSource),
                        "manualAward=", tostring(xpToGive),
                        "partyMembers=", tostring(#xpRecipients),
                        "xpRecipientSource=", tostring(xpRecipientSource),
                        "xpRecipients=", EA_FormatXPRecipients(xpRecipients),
                        "xpSuppressMethod=", tostring(xpSuppressMethod),
                        "xpSuppressVerified=", tostring(xpSuppressVerified))
                end
                if xpToGive > 0 and Ext and Ext.Timer and Ext.Timer.WaitFor then
                    if xpRecipientSource == "db_players_party_filtered" then
                        UpdateMetric("xpManualPayoutRecipientsDBPlayers")
                    elseif xpRecipientSource == "event_helper_fallback" then
                        UpdateMetric("xpManualPayoutRecipientsFallback")
                    else
                        UpdateMetric("xpManualPayoutNoValidRecipients")
                    end
                    if #xpRecipients > 0 then
                        UpdateMetric("xpManualPayoutApplied")
                        UpdateMetric("xpManualPayoutRecipientCount", #xpRecipients)
                        Ext.Timer.WaitFor(150, function()
                            for _, recipient in ipairs(xpRecipients) do
                                SafeOsiExec(Osi.AddExplorationExperience, recipient, xpToGive)
                            end
                        end)
                    elseif EA_DebugEnabled() then
                        DebugPrint(
                            "XP payout blocked: no valid recipients; fail-closed for",
                            tostring(character),
                            "xpPct=", tostring(xpPct),
                            "xpBase=", tostring(base),
                            "xpBaseSource=", tostring(xpBaseSource),
                            "xpRecipientSource=", tostring(xpRecipientSource)
                        )
                    end
                elseif xpToGive > 0 and xpRecipientSource == "none" then
                    UpdateMetric("xpManualPayoutNoValidRecipients")
                    if EA_DebugEnabled() then
                        DebugPrint("XP payout skipped: no valid recipients for", tostring(character))
                    end
                end
            elseif spawnedData.xpZeroed and (not hasNumericBase) then
                DebugPrint(
                    "XP payout blocked: missing numeric base; fail-closed for",
                    tostring(character),
                    "xpPct=", tostring(xpPct),
                    "xpBaseRaw=", tostring(spawnedData.xpBase),
                    "xpBaseSource=", tostring(xpBaseSource)
                )
            elseif spawnedData.xpZeroed then
                UpdateMetric("xpManualPayoutBlockedUnverified")
                DebugPrint(
                    "XP payout blocked: suppression unverified; fail-closed for",
                    tostring(character),
                    "xpPct=", tostring(xpPct),
                    "xpBase=", tostring(base),
                    "xpBaseSource=", tostring(xpBaseSource),
                    "method=", tostring(xpSuppressMethod),
                    "xpSuppressVerified=", tostring(xpSuppressVerified)
                )
            else
                DebugPrint("XP suppression missing (xpZeroed=false); cannot reliably enforce xpPct=", tostring(xpPct), "for", tostring(character), "method=", tostring(xpSuppressMethod))
            end
        end
    
        if EA_GetEffectiveDisableAmbushLoot() then
            -- Policy: keep corpses interactable, but remove loot content.
            if Osi.SetCharacterLootable then
                SafeOsiExec(Osi.SetCharacterLootable, character, 1)
            end
            if Osi.SetIsDroppedOnDeath then
                SafeOsiExec(Osi.SetIsDroppedOnDeath, character, 0)
            end
            EA_ClearLootButKeepCorpseClickable(character)
        end
    
        if EA_GetSettingBoolEvent("MCM_EnableReputation", true) and spawnedData.creatureType and spawnedData.noReputation ~= true then
            local repTable = EA_ReputationTable()
            local thresholds = EA_ReputationThresholdTable()
            local oldRep = repTable[spawnedData.creatureType] or 0
            local newRep
            local repChangeApplied = 0
            local repCapBlocked = false
            local repInCombat = (EA_IsAnyPartyInCombat() == true)
    
            if spawnedData.isChampion then
                newRep = 0
                repChangeApplied = (tonumber(newRep) or 0) - (tonumber(oldRep) or 0)
            else
                local ct = spawnedData.creatureType
                local inCombat = repInCombat
                local encounter = EA_GetEncounterRepState()
                local outOfCombatLedger = EA_GetOutOfCombatRepLedger()
                encounter.perType = encounter.perType or {}
    
                if inCombat then
                    if encounter.active ~= true then
                        encounter.perType = {}
                        encounter.active = true
                        EA_LaunchEncounterRepWatchTimer(5000)
                        EA_MarkRuntimeStateDirty(true)
                    end
                else
                    if encounter.active == true then
                        if EA_DebugEnabled() then
                            DebugPrint("Encounter rep: preserving cap state until watch reset (combat just ended)")
                        end
                    else
                        local now = EA_NowMs and EA_NowMs() or 0
                        EA_PruneOutOfCombatRepLedger(now)
                        local row = outOfCombatLedger[ct]
                        if type(row) ~= "table" or (tonumber(now) > 0 and (now - (tonumber(row.lastAt) or 0)) > EA_OUT_OF_COMBAT_REP_WINDOW_MS) then
                            encounter.perType = {}
                            outOfCombatLedger[ct] = { lastAt = now, delta = 0, kills = 0 }
                            if type(EA_Dirty) == "function" then
                                EA_Dirty()
                            end
                        else
                            encounter.perType[ct] = tonumber(row.delta) or 0
                        end
                    end
                end
    
                local currentDelta = tonumber(encounter.perType[ct]) or 0
                local maxLoss = EA_GetEncounterRepMaxLoss()
                local repChange = 0
                if math.abs(currentDelta) < maxLoss then
                    repChange = -1
                    currentDelta = currentDelta - 1
                    encounter.perType[ct] = currentDelta
                else
                    repCapBlocked = true
                end
                repChangeApplied = repChange
    
                if not inCombat and encounter.active ~= true then
                    local now = EA_NowMs and EA_NowMs() or 0
                    local row = outOfCombatLedger[ct] or { lastAt = now, delta = 0, kills = 0 }
                    row.lastAt = now
                    row.delta = tonumber(encounter.perType[ct]) or 0
                    row.kills = (tonumber(row.kills) or 0) + 1
                    outOfCombatLedger[ct] = row
                    if type(EA_Dirty) == "function" then
                        EA_Dirty()
                    end
                end
                encounter.updatedAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
                EA_MarkRuntimeStateDirty()
                newRep = oldRep + repChange
            end
    
            repTable[spawnedData.creatureType] = newRep
            local repStatsFn = EA and EA["EA_RecordRepChange"]
            if type(repStatsFn) == "function" then
                repStatsFn(
                    spawnedData.creatureType,
                    oldRep,
                    newRep,
                    repChangeApplied,
                    spawnedData.isChampion == true,
                    repCapBlocked,
                    repInCombat
                )
            end
    
            if (not spawnedData.isChampion) and player and player ~= "" and type(EA_AddTypePressure) == "function" then
                EA_AddTypePressure(player, spawnedData.creatureType, 12)
            end
    
            print(string.format("[EnemyAmbush] Reputation changed: %s %s -> %s%s",
                tostring(spawnedData.creatureType),
                tostring(oldRep),
                tostring(newRep),
                spawnedData.isChampion and " (champion reset)" or ""))
    
            local crossedWary = (oldRep > thresholds.WARY and newRep <= thresholds.WARY)
            local crossedHostile = (oldRep > thresholds.HOSTILE and newRep <= thresholds.HOSTILE)
            local crossedVengeful = (oldRep > thresholds.VENGEFUL and newRep <= thresholds.VENGEFUL)

            if crossedVengeful then
                if EA_CanSpawnChampionForType(spawnedData.creatureType) then
                    if type(EA_GetGuaranteedChampionQueueSafeFn) ~= "function" and EA and type(EA["EA_GetGuaranteedChampionQueueSafe"]) == "function" then
                        EA_GetGuaranteedChampionQueueSafeFn = EA["EA_GetGuaranteedChampionQueueSafe"]
                    end
                    local q = {}
                    if type(EA_GetGuaranteedChampionQueueSafeFn) == "function" then
                        local okQ, outQ = pcall(EA_GetGuaranteedChampionQueueSafeFn)
                        if okQ and type(outQ) == "table" then
                            q = outQ
                        end
                    end
                    if q[spawnedData.creatureType] == nil then
                        q[spawnedData.creatureType] = {
                            ts = EA_NowMs(),
                            repAtSet = newRep
                        }
                        EA_Dirty()
                    end
                else
                    DebugPrint("Champion cooldown active; not queueing:", tostring(spawnedData.creatureType))
                end
            end

            local repUiEnabled = EA_GetSettingBoolEvent("MCM_ShowUINotifications", true)
                and EA_GetSettingBoolEvent("MCM_ShowReputationWarnings", true)
            if player and player ~= "" and repUiEnabled then
                if crossedWary then
                    local text = EA_FormatRepWarning(
                        EA_LOCA_REP_WARNING_WARY,
                        "The %s are growing wary of your presence...",
                        spawnedData.creatureType
                    )
                    SafeOsiExec(Osi.OpenMessageBox, player, text)
                elseif crossedHostile then
                    local text = EA_FormatRepWarning(
                        EA_LOCA_REP_WARNING_HOSTILE,
                        "The %s are hunting you now. Their champions will not forgive.",
                        spawnedData.creatureType
                    )
                    SafeOsiExec(Osi.OpenMessageBox, player, text)
                    SafeOsiExec(Osi.PlaySound, player, "UI_Notification_QuestUpdate")
                elseif crossedVengeful then
                    local text = EA_FormatRepWarning(
                        EA_LOCA_REP_WARNING_VENGEFUL,
                        "You have gone too far. A %s champion rises to end you.",
                        spawnedData.creatureType
                    )
                    SafeOsiExec(Osi.OpenMessageBox, player, text)
                    SafeOsiExec(Osi.PlaySound, player, "UI_Notification_CombatStarted")
                    PlayVFX_OnEntity(player, "VFX_Spells_Cast_Intent_Utility_TargetJump_MistyStep_BodyFX_01")
                end
            end

            if SaveReputation then SaveReputation() end
        end
    
        EA_ClearHostileState(character)
        if id then EA_ClearHostileState(id) end
        if id then spawned[id] = nil end
        spawned[character] = nil
        if type(EnemyAmbush._CombatKeyByAmbusher) == "table" then
            EnemyAmbush._CombatKeyByAmbusher[character] = nil
            if id then EnemyAmbush._CombatKeyByAmbusher[id] = nil end
        end
        if type(EnemyAmbush._CombatKeyByMember) == "table" then
            EnemyAmbush._CombatKeyByMember[character] = nil
            if id then EnemyAmbush._CombatKeyByMember[id] = nil end
        end
        EA_Dirty()
        return true
    end

    -- Non-lethal knockouts do not always trigger Dying/Died. Treat them as defeat for
    -- pacifist parity and cleanup/registry parity, then suppress any later world-kill credit.
    -- We intentionally key off explicit KO status IDs here instead of HasAppliedStatusOfType:
    -- status-type scans are broader and can misclassify unrelated states across mods.
    local EA_KNOCKOUT_STATUS_IDS = {
        KNOCKED_OUT = true,
        KNOCKED_OUT_TEMPORARILY = true,
        KNOCKED_OUT_PERMANENTLY = true,
        BONK_ENHANCED_DOWNED = true,
        BONK_ENHANCED_DOWNED_AND_OUT = true,
    }

    local defeatListenersRegistered = false
    function Runtime.RegisterDefeatListeners()
        if defeatListenersRegistered then
            EA_P0Inc("listenerRegGuard.RegisterDefeatListeners")
            return false
        end
        EA_P0Inc("listenerReg.RegisterDefeatListeners")
        if not (Ext and Ext.Osiris and Ext.Osiris.RegisterListener) then
            return
        end
        defeatListenersRegistered = true

        EA_P0Inc("listenerReg.StatusApplied.after")
        Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(character, status, causee, storyActionID)
            local sid = status
            if type(sid) ~= "string" or sid == "" then
                return
            end
            if EA_KNOCKOUT_STATUS_IDS[sid] ~= true then
                sid = string.upper(sid)
                if EA_KNOCKOUT_STATUS_IDS[sid] ~= true then
                    return
                end
            end
            if not character or character == "" then
                return
            end
            local id = EA_NormalizeUUID(character)
            local spawned = EA_GetSpawnedRegistry()
            local spawnedData = spawned and ((id and spawned[id]) or spawned[character]) or nil
            if not spawnedData then
                return
            end
            EA_ProcessSpawnedDefeat(character, spawnedData, "knockout")
        end)

        -- Authoritative lethal defeat hook. Died fires only after death is finalized.
        EA_P0Inc("listenerReg.Died.after")
        Ext.Osiris.RegisterListener("Died", 1, "after", function(character)
            if not character or character == "" then return end
        
            local id = EA_NormalizeUUID(character)
            local spawned = EA_GetSpawnedRegistry()
            local spawnedData = spawned and ((id and spawned[id]) or spawned[character]) or nil
            if not spawnedData then
                return
            end
        
            EA_ProcessSpawnedDefeat(character, spawnedData, "died")
        end)
    end

    Runtime.ProcessSpawnedDefeat = EA_ProcessSpawnedDefeat
    return Runtime
end

return M
