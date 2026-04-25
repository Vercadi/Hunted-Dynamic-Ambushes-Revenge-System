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
    local EA_Spawned = deps.EA_Spawned or function() return {} end
    local EA_NormalizeUUID = deps.EA_NormalizeUUID or function(v) return v end
    local EA_FastNormalizeUUID = deps.EA_FastNormalizeUUID or function(v) return v end
    local EA_NormalizeCombatKey = deps.EA_NormalizeCombatKey or function(v) return v or "" end
    local EA_EnsureCombatEscapeState = deps.EA_EnsureCombatEscapeState or function() end
    local EA_GetPlayerFromCombat = deps.EA_GetPlayerFromCombat or function() return nil end
    local EA_JoinDeferredSupportsForAmbush = deps.EA_JoinDeferredSupportsForAmbush or function() end
    local EA_CleanupCombatEscapeStateIfIdle = deps.EA_CleanupCombatEscapeStateIfIdle or function() end
    local EA_ResetSoftlockIdleCounter = deps.EA_ResetSoftlockIdleCounter or function() return false end
    local EA_GetRuntimeTurnChatterMap = deps.EA_GetRuntimeTurnChatterMap or function() return {} end
    local EA_GetRuntimeEscapeStateMap = deps.EA_GetRuntimeEscapeStateMap or function() return {} end
    local EA_GetCombatKeyForTurnCharacter = deps.EA_GetCombatKeyForTurnCharacter or function() return "" end
    local EA_FindCombatEscapeState = deps.EA_FindCombatEscapeState or function() return nil, nil end
    local EA_FindTurnChatterState = deps.EA_FindTurnChatterState or function() return nil, nil end
    local EA_CancelPendingEscape = deps.EA_CancelPendingEscape or function() return false end
    local EA_ResolvePendingEscapeAfterLeftCombat = deps.EA_ResolvePendingEscapeAfterLeftCombat or function() return false end
    local EA_TryAmbusherEscape = deps.EA_TryAmbusherEscape or function() return false end
    local EA_TrySoftlockDeleteOnTurn = deps.EA_TrySoftlockDeleteOnTurn or function() return false end
    local EA_MarkRuntimeStateDirty = deps.EA_MarkRuntimeStateDirty or function() end
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local EA_TryAnyTurnBark = deps.EA_TryAnyTurnBark or function() return false, nil end
    local EA_RandIntSafe = deps.EA_RandIntSafe or (EA and EA["EA_RandIntSafe"])
    local EA_RandomInt = deps.EA_RandomInt or function(minVal, maxVal)
        if type(EA_RandIntSafe) == "function" then
            local ok, out = pcall(EA_RandIntSafe, minVal, maxVal)
            if ok and tonumber(out) then
                return tonumber(out)
            end
        end
        if maxVal == nil then
            local hi = math.floor(tonumber(minVal) or 1)
            return (hi <= 1) and 1 or math.floor((1 + hi) * 0.5)
        end
        local lo = math.floor(tonumber(minVal) or 1)
        local hi = math.floor(tonumber(maxVal) or lo)
        if hi < lo then lo, hi = hi, lo end
        return (hi <= lo) and lo or (lo + math.floor((hi - lo) * 0.5))
    end
    local EA_PlaySoundEvent = deps.EA_PlaySoundEvent or function() end
    local EA_DebugEnabled = deps.EA_DebugEnabled or function() return false end
    local EA_HandleSurpriseRollResult = deps.EA_HandleSurpriseRollResult
    local EA_PrimeCharacterTemplateCache = deps.EA_PrimeCharacterTemplateCache or function() return nil end

    local Runtime = {}

    local function EA_GetSpawnedRegistry()
        local spawned = EA_Spawned()
        if type(spawned) ~= "table" and type(spawned) ~= "userdata" then
            return nil
        end
        return spawned
    end

    local EA_ARRIVAL_INVISIBILITY_STATUS = "EA_ARRIVAL_INVISIBLE"
    local function EA_ClearArrivalInvisibility(character, spawnedData, reason)
        if not (character and character ~= "" and type(spawnedData) == "table") then
            return false
        end
        if not (Osi and Osi.HasActiveStatus and Osi.RemoveStatus) then
            return false
        end
        local okHas, hasStatus = pcall(Osi.HasActiveStatus, character, EA_ARRIVAL_INVISIBILITY_STATUS)
        if not okHas or tonumber(hasStatus) ~= 1 then
            if spawnedData.arrivalInvisible then
                spawnedData.arrivalInvisible = nil
            end
            return false
        end
        local okRemove = pcall(Osi.RemoveStatus, character, EA_ARRIVAL_INVISIBILITY_STATUS)
        if okRemove then
            spawnedData.arrivalInvisible = nil
            UpdateMetric("arrivalInvisibilityRemoved")
            if EA_DebugEnabled() then
                DebugPrint("[ArrivalInvisibility] removed:", tostring(character), "reason=", tostring(reason or "entered_combat"))
            end
            return true
        end
        return false
    end

    local combatTurnListenersRegistered = false
    function Runtime.RegisterCombatTurnListeners()
        if combatTurnListenersRegistered then
            EA_P0Inc("listenerRegGuard.RegisterCombatTurnListeners")
            return false
        end
        EA_P0Inc("listenerReg.RegisterCombatTurnListeners")
        if not (Ext and Ext.Osiris and Ext.Osiris.RegisterListener) then
            return
        end
        combatTurnListenersRegistered = true

        -- If an ambush member enters combat later (eg retries), join deferred supports behind that anchor.
        EA_P0Inc("listenerReg.EnteredCombat.after")
        Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(character, combatGuid)
            if character and character ~= "" then
                pcall(EA_PrimeCharacterTemplateCache, character, "entered_combat")
            end
            local spawned = EA_GetSpawnedRegistry()
            if not spawned then
                return
            end
            local id = EA_NormalizeUUID(character) or character
            local normalizedCombat = EA_NormalizeCombatKey(combatGuid)
            local byMember = EnemyAmbush._CombatKeyByMember
            if type(byMember) == "table" and normalizedCombat ~= "" then
                byMember[id] = normalizedCombat
                byMember[character] = normalizedCombat
            end
            local spawnedData = spawned[id] or spawned[character]
            if not (type(spawnedData) == "table" and spawnedData.ambushId) then
                return
            end
            EA_ClearArrivalInvisibility(character, spawnedData, "entered_combat")
            spawnedData._eaSoftlockIdleTurns = 0
            spawnedData._eaSoftlockDeletePending = nil
            spawnedData._eaSoftlockCombatKey = normalizedCombat
            local escapeKey = normalizedCombat
            if escapeKey ~= "" then
                EA_EnsureCombatEscapeState(escapeKey)
                EnemyAmbush._CombatKeyByAmbusher[id] = escapeKey
                EnemyAmbush._CombatKeyByAmbusher[character] = escapeKey
            end
            local player = EA_GetPlayerFromCombat(combatGuid, character)
            EA_JoinDeferredSupportsForAmbush(spawnedData.ambushId, player, character, combatGuid)
        end)

        EA_P0Inc("listenerReg.LeftCombat.after")
        Ext.Osiris.RegisterListener("LeftCombat", 2, "after", function(character, combatGuid)
            local id = EA_NormalizeUUID(character) or character
            local spawned = EA_GetSpawnedRegistry()
            local spawnedData = spawned and (spawned[id] or spawned[character]) or nil
            if type(spawnedData) == "table" then
                local resolvedStagedEscape = false
                if spawnedData.escapePending == true then
                    resolvedStagedEscape = (EA_ResolvePendingEscapeAfterLeftCombat(character, combatGuid, "left_combat") == true)
                end
                if not resolvedStagedEscape then
                    EA_CancelPendingEscape(character, combatGuid, "left_combat", 0, false)
                end
                spawnedData._eaSoftlockIdleTurns = 0
                spawnedData._eaSoftlockDeletePending = nil
                spawnedData._eaSoftlockCombatKey = nil
            end
            if type(EnemyAmbush._CombatKeyByAmbusher) == "table" then
                EnemyAmbush._CombatKeyByAmbusher[id] = nil
                EnemyAmbush._CombatKeyByAmbusher[character] = nil
            end
            if type(EnemyAmbush._CombatKeyByMember) == "table" then
                EnemyAmbush._CombatKeyByMember[id] = nil
                EnemyAmbush._CombatKeyByMember[character] = nil
            end
            EA_CleanupCombatEscapeStateIfIdle(combatGuid)
        end)

        -- Reset per-ambusher idle softlock counters whenever real damage is exchanged.
        EA_P0Inc("listenerReg.AttackedBy.after")
        Ext.Osiris.RegisterListener("AttackedBy", 7, "after", function(defender, attackerOwner, attacker, damageType, damageAmount, damageCause, storyActionID)
            local amount = tonumber(damageAmount) or 0
            if amount <= 0 then
                return
            end
            if defender and defender ~= "" then
                pcall(EA_PrimeCharacterTemplateCache, defender, "attacked_by")
            end
            if attacker and attacker ~= "" then
                pcall(EA_PrimeCharacterTemplateCache, attacker, "attacked_by")
            end
            if attackerOwner and attackerOwner ~= "" and attackerOwner ~= attacker then
                pcall(EA_PrimeCharacterTemplateCache, attackerOwner, "attacked_by")
            end
            local resetAny = false
            if EA_CancelPendingEscape(defender, nil, "damage_received", amount, true) then
                resetAny = true
            end
            if EA_ResetSoftlockIdleCounter(defender, "damage_received", amount) then
                resetAny = true
            end
            if EA_ResetSoftlockIdleCounter(attacker, "damage_dealt", amount) then
                resetAny = true
            end
            if attackerOwner and attackerOwner ~= attacker then
                if EA_ResetSoftlockIdleCounter(attackerOwner, "damage_dealt_owner", amount) then
                    resetAny = true
                end
            end
            if resetAny then
                UpdateMetric("softlockDamageReset")
            end
        end)

        EA_P0Inc("listenerReg.TurnStarted.after")
        Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(turnCharacter)
            if not turnCharacter or turnCharacter == "" then
                return
            end
            if Osi.IsInCombat and Osi.IsInCombat(turnCharacter) ~= 1 then
                return
            end

            local chatterByCombat = EA_GetRuntimeTurnChatterMap()
            local escapeByCombat = EA_GetRuntimeEscapeStateMap()
            local hasChatter = (type(chatterByCombat) == "table" and next(chatterByCombat) ~= nil)
            local hasEscape = (type(escapeByCombat) == "table" and next(escapeByCombat) ~= nil)
            if not hasChatter and not hasEscape then
                UpdateMetric("turnStartedFastExitNoActiveWork")
                UpdateMetric("turnStartedFastExitNoActiveChatter")
                return
            end

            local combatKey = EA_GetCombatKeyForTurnCharacter(turnCharacter)
            if combatKey == "" then
                return
            end

            local escapeKey, escapeState = EA_FindCombatEscapeState(combatKey)
            local spawned = EA_GetSpawnedRegistry()
            local turnId = EA_FastNormalizeUUID(turnCharacter) or EA_NormalizeUUID(turnCharacter) or turnCharacter
            local spawnedData = spawned and (spawned[turnId] or spawned[turnCharacter]) or nil
            local escapedThisTurn = false
            if hasEscape and type(escapeState) == "table" then
                escapeState.turnCount = (tonumber(escapeState.turnCount) or 0) + 1
                escapeState.updatedAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
                EA_MarkRuntimeStateDirty()
                if type(spawnedData) == "table" then
                    escapedThisTurn = (EA_TryAmbusherEscape(turnCharacter, escapeKey or combatKey, escapeState) == true)
                end
            end

            -- Softlock guard is intentionally one-candidate-per-turn: we only evaluate current turn actor.
            if type(spawnedData) == "table" and not escapedThisTurn then
                if EA_TrySoftlockDeleteOnTurn(turnCharacter, escapeKey or combatKey, spawnedData) then
                    return
                end
            end

            if not hasChatter then
                return
            end

            local stateKey, state = EA_FindTurnChatterState(combatKey)
            if type(state) ~= "table" then
                if EA_DebugEnabled() and type(chatterByCombat) == "table" then
                    local armedCount = 0
                    for _ in pairs(chatterByCombat) do
                        armedCount = armedCount + 1
                    end
                    if armedCount > 0 then
                        DebugPrint("Turn chatter state miss:", tostring(turnCharacter), "combat=", tostring(combatKey), "armed=", tostring(armedCount))
                    end
                end
                return
            end
            local remaining = tonumber(state.remaining) or 0
            if remaining <= 0 then
                if stateKey then
                    chatterByCombat[stateKey] = nil
                    EA_MarkRuntimeStateDirty()
                end
                return
            end

            if state.enemyOnly == true and state.player and state.player ~= "" and Osi.IsEnemy then
                local okEnemy, isEnemy = pcall(Osi.IsEnemy, turnCharacter, state.player)
                if not okEnemy or isEnemy ~= 1 then
                    return
                end
            end

            local speaker = turnCharacter
            if Osi.ObjectExists and Osi.ObjectExists(speaker) ~= 1 then
                speaker = state.sourceEnemy or ""
            end
            if not speaker or speaker == "" then
                state.remaining = remaining - 1
                state.updatedAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
                EA_MarkRuntimeStateDirty()
                if state.remaining <= 0 then
                    if stateKey then
                        chatterByCombat[stateKey] = nil
                        EA_MarkRuntimeStateDirty()
                    end
                end
                return
            end

            local barkPlayed = false
            if type(state.barks) == "table" and #state.barks > 0 and Osi.StartVoiceBark then
                local barkId = nil
                barkPlayed, barkId = EA_TryAnyTurnBark(state.barks, speaker, 4)
                if EA_DebugEnabled() then
                    DebugPrint("Turn chatter bark:", tostring(speaker), "combat=", tostring(combatKey), "bark=", tostring(barkId), "played=", tostring(barkPlayed))
                end
            end

            if type(state.sounds) == "table" and #state.sounds > 0 and (state.soundAlways == true or not barkPlayed) then
                local soundId = state.sounds[EA_RandomInt(1, #state.sounds)]
                if type(soundId) == "string" and soundId ~= "" then
                    EA_PlaySoundEvent(soundId, speaker)
                    if EA_DebugEnabled() then
                        DebugPrint("Turn chatter sound:", tostring(speaker), "combat=", tostring(combatKey), "sound=", tostring(soundId))
                    end
                end
            end
            state.remaining = remaining - 1
            state.updatedAt = tonumber(EA_NowMs and EA_NowMs() or 0) or 0
            EA_MarkRuntimeStateDirty()
            if state.remaining <= 0 then
                if stateKey then
                    chatterByCombat[stateKey] = nil
                    EA_MarkRuntimeStateDirty()
                end
            end
        end)

        -- Handles async RollResult callbacks for the perception-gated surprise system.
        EA_P0Inc("listenerReg.RollResult.after")
        Ext.Osiris.RegisterListener("RollResult", 6, "after", function(eventName, roller, rollSubject, resultType, isActiveRoll, criticality)
            local handler = EA_HandleSurpriseRollResult or (EA and EA["EA_HandleSurpriseRollResult"])
            if type(handler) == "function" then
                handler(roller, resultType, criticality, eventName)
            end
        end)
    end

    return Runtime
end

return M
