EnemyAmbush = EnemyAmbush or {}

local M = {}
local TIMER_PREFIX_OWNED = "EA_"
local TIMER_PREFIX_APPROACH_BEAT = "EA_AMBUSH_BEAT_"

local function HasPrefix(value, prefix)
    if type(value) ~= "string" or type(prefix) ~= "string" then
        return false
    end
    return string.sub(value, 1, #prefix) == prefix
end

function M.IsOwnedTimer(timer)
    if type(timer) ~= "string" or timer == "" then
        return false
    end
    return HasPrefix(timer, TIMER_PREFIX_OWNED)
end

function M.BuildExactHandlers(ctx)
    ctx = ctx or {}
    return {
        EA_VALIDATE_SPAWNED = ctx.onValidateSpawned,
        EA_RUNTIME_COMBAT_PRUNE = ctx.onRuntimeCombatPrune,
        EA_ENCOUNTER_REP_WATCH = ctx.onEncounterRepWatch,
        EA_REPUTATION_DECAY = ctx.onReputationDecay,
        EA_CLEANUP_PENDING = ctx.onCleanupPending,
    }
end

function M.TryHandleApproachBeatTimer(timer, ctx)
    if type(timer) ~= "string" then
        return false
    end
    if not HasPrefix(timer, TIMER_PREFIX_APPROACH_BEAT) then
        return false
    end

    ctx = ctx or {}
    local pendingFn = ctx.pendingFn
    local dirtyFn = ctx.dirtyFn
    local beatFn = ctx.playBeatFn
    if type(pendingFn) ~= "function" then
        return true
    end

    local pending = pendingFn()
    if type(pending) ~= "table" and type(pending) ~= "userdata" then
        return true
    end

    local beatData = pending[timer]
    if beatData then
        pending[timer] = nil
        if type(dirtyFn) == "function" then
            dirtyFn()
        end
        if type(beatFn) == "function" then
            beatFn(beatData)
        end
    end
    return true
end

return M
