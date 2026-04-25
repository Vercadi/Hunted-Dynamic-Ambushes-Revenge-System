-- EnemyAmbush_Systems_SupportJoinService.lua
-- Canonical owner for deferred support-join windows, grace rules, expiry, and join-log throttling.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local EA_HOSTILE_FORCE_JOIN_WHILE_PLAYER_IN_COMBAT = true
local EA_HOSTILE_FORCE_JOIN_MAX_DISTANCE = 35
local EA_HOSTILE_COHESION_JOIN_GRACE_MS = 6000
-- Debug retries happen frequently while a support unit cannot legally catch up.
-- Keep the first message, then suppress repeats long enough to avoid combat-log spam.
local EA_HOSTILE_JOIN_LOG_TTL_MS = 30000

local function EA_SupportJoinNowMs()
    if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
        return tonumber(Ext.Utils.MonotonicTime()) or 0
    end
    if type(EA_NowMs) == "function" then
        return tonumber(EA_NowMs()) or 0
    end
    return 0
end

local function EA_EnsureSupportJoinState()
    EA._eaSupportJoin = EA._eaSupportJoin or {}
    local st = EA._eaSupportJoin
    if type(st.deferredJoinWindows) ~= "table" then st.deferredJoinWindows = {} end
    if type(st.deferredJoinLogSeen) ~= "table" then st.deferredJoinLogSeen = {} end

    local legacy = EA._eaHostile
    if type(legacy) == "table" then
        if next(st.deferredJoinWindows) == nil and type(legacy.deferredJoinWindows) == "table" then
            st.deferredJoinWindows = legacy.deferredJoinWindows
        end
        if next(st.deferredJoinLogSeen) == nil and type(legacy.deferredJoinLogSeen) == "table" then
            st.deferredJoinLogSeen = legacy.deferredJoinLogSeen
        end
        legacy.deferredJoinWindows = nil
        legacy.deferredJoinLogSeen = nil
    end

    return st
end

function EA_PruneDeferredSupportJoinState(st, now)
    local state = st
    if type(state) ~= "table" then
        state = EA_EnsureSupportJoinState()
    end

    local ts = tonumber(now) or 0
    if ts <= 0 then
        ts = EA_SupportJoinNowMs()
    end
    if ts <= 0 then
        return
    end

    local stateTtlMs = math.max(EA_HOSTILE_COHESION_JOIN_GRACE_MS, EA_HOSTILE_JOIN_LOG_TTL_MS) + 15000
    if type(state.deferredJoinWindows) == "table" then
        for aid, window in pairs(state.deferredJoinWindows) do
            local updatedAt = tonumber(type(window) == "table" and window.updatedAt) or 0
            if updatedAt > 0 and (ts - updatedAt) > stateTtlMs then
                state.deferredJoinWindows[aid] = nil
            end
        end
    end
    if type(state.deferredJoinLogSeen) == "table" then
        for key, seenAt in pairs(state.deferredJoinLogSeen) do
            local loggedAt = tonumber(seenAt) or 0
            if loggedAt > 0 and (ts - loggedAt) > EA_HOSTILE_JOIN_LOG_TTL_MS then
                state.deferredJoinLogSeen[key] = nil
            end
        end
    end
end

function EA_RegisterDeferredSupportJoinWindow(ambushId, combatGuid, player, sourceEnemy)
    local aid = tostring(ambushId or "")
    if aid == "" then
        return nil
    end

    local st = EA_EnsureSupportJoinState()
    local now = EA_SupportJoinNowMs()
    EA_PruneDeferredSupportJoinState(st, now)

    local combatKey = tostring(combatGuid or "")
    local current = st.deferredJoinWindows[aid]
    if type(current) ~= "table"
        or (combatKey ~= "" and tostring(current.combatKey or "") ~= "" and tostring(current.combatKey or "") ~= combatKey) then
        current = {
            ambushId = aid,
            combatKey = combatKey,
            startedAt = now,
            updatedAt = now,
            player = player,
            sourceEnemy = sourceEnemy,
        }
        st.deferredJoinWindows[aid] = current
        return current
    end

    if combatKey ~= "" and tostring(current.combatKey or "") == "" then
        current.combatKey = combatKey
    end
    current.updatedAt = now
    if player and player ~= "" then
        current.player = player
    end
    if sourceEnemy and sourceEnemy ~= "" then
        current.sourceEnemy = sourceEnemy
    end
    return current
end

function EA_GetDeferredSupportJoinWindow(ambushId, combatGuid)
    local aid = tostring(ambushId or "")
    if aid == "" then
        return nil
    end

    local st = EA_EnsureSupportJoinState()
    local now = EA_SupportJoinNowMs()
    EA_PruneDeferredSupportJoinState(st, now)

    local current = st.deferredJoinWindows[aid]
    if type(current) ~= "table" then
        return nil
    end

    local combatKey = tostring(combatGuid or "")
    local currentCombatKey = tostring(current.combatKey or "")
    if combatKey ~= "" and currentCombatKey ~= "" and currentCombatKey ~= combatKey then
        return nil
    end
    return current
end

function EA_ShouldLogDeferredJoin(stOrAmbushId, ambushIdOrCombatKey, combatKeyOrReason, reasonMaybe)
    local ambushId = stOrAmbushId
    local combatKey = ambushIdOrCombatKey
    local reason = combatKeyOrReason
    if type(stOrAmbushId) == "table" then
        ambushId = ambushIdOrCombatKey
        combatKey = combatKeyOrReason
        reason = reasonMaybe
    end

    local st = EA_EnsureSupportJoinState()
    local now = EA_SupportJoinNowMs()
    EA_PruneDeferredSupportJoinState(st, now)

    local key = table.concat({
        tostring(reason or "join"),
        tostring(ambushId or ""),
        tostring(combatKey or ""),
    }, "|")
    local lastSeen = tonumber(st.deferredJoinLogSeen[key]) or 0
    if lastSeen > 0 and now > 0 and (now - lastSeen) <= EA_HOSTILE_JOIN_LOG_TTL_MS then
        return false
    end
    st.deferredJoinLogSeen[key] = (now > 0) and now or 1
    return true
end

function EA_EvaluateDeferredSupportJoinRules(joinWindow, playerInCombat, distToPlayer, catchupSoftMaxDistance)
    local now = EA_SupportJoinNowMs()
    local joinGraceActive = false
    local joinGraceAgeMs = 0
    if type(joinWindow) == "table" then
        local startedAt = tonumber(joinWindow.startedAt) or 0
        if startedAt > 0 and now > 0 then
            joinGraceAgeMs = math.max(0, now - startedAt)
            joinGraceActive = (joinGraceAgeMs <= EA_HOSTILE_COHESION_JOIN_GRACE_MS)
        elseif startedAt <= 0 then
            joinGraceActive = true
        end
    end

    local allowForcedJoin = (playerInCombat ~= true)
    if (not allowForcedJoin)
        and EA_HOSTILE_FORCE_JOIN_WHILE_PLAYER_IN_COMBAT
        and tonumber(distToPlayer)
        and (
            tonumber(distToPlayer) <= tonumber(catchupSoftMaxDistance or 0)
            or (joinGraceActive and tonumber(distToPlayer) <= EA_HOSTILE_FORCE_JOIN_MAX_DISTANCE)
        ) then
        allowForcedJoin = true
    end

    return {
        allowForcedJoin = allowForcedJoin,
        joinGraceActive = joinGraceActive,
        joinGraceAgeMs = joinGraceAgeMs,
        forceJoinMaxDistance = EA_HOSTILE_FORCE_JOIN_MAX_DISTANCE,
        forceJoinWhilePlayerInCombat = EA_HOSTILE_FORCE_JOIN_WHILE_PLAYER_IN_COMBAT,
    }
end

EA["EA_PruneDeferredSupportJoinState"] = EA_PruneDeferredSupportJoinState
EA["EA_RegisterDeferredSupportJoinWindow"] = EA_RegisterDeferredSupportJoinWindow
EA["EA_GetDeferredSupportJoinWindow"] = EA_GetDeferredSupportJoinWindow
EA["EA_ShouldLogDeferredJoin"] = EA_ShouldLogDeferredJoin
EA["EA_EvaluateDeferredSupportJoinRules"] = EA_EvaluateDeferredSupportJoinRules
