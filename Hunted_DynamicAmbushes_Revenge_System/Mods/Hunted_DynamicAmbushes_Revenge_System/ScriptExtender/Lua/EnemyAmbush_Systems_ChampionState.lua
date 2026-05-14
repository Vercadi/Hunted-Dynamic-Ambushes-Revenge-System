-- EnemyAmbush_Systems_ChampionState.lua
-- Dedicated owner for guaranteed champion queue / armed-state ModVar storage.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local function EA_ChampionStateIsContainer(value)
    local fn = (EA and EA["EA_IsModVarsContainer"]) or EA_IsModVarsContainer
    if type(fn) == "function" then
        local ok, out = pcall(fn, value)
        if ok then
            return out == true
        end
    end
    return type(value) == "table"
end

local function EA_ChampionStateVars()
    local fn = (EA and EA["EA_Vars"]) or EA_Vars
    if type(fn) ~= "function" then
        return nil
    end
    local ok, vars = pcall(fn)
    if not ok or not EA_ChampionStateIsContainer(vars) then
        return nil
    end
    return vars
end

local function EA_ChampionStateDirty()
    local fn = (EA and EA["EA_Dirty"]) or EA_Dirty
    if type(fn) == "function" then
        pcall(fn)
    end
end

EA_GuaranteedChampionQueue = function()
    local vars = EA_ChampionStateVars()
    if not vars then
        return nil
    end
    if not EA_ChampionStateIsContainer(vars.GuaranteedChampionQueue) then
        vars.GuaranteedChampionQueue = {}
    end
    return vars.GuaranteedChampionQueue
end

local function EA_GetGuaranteedChampionQueueSafe()
    local fn = EA and EA["EA_GuaranteedChampionQueue"]
    if type(fn) ~= "function" then
        fn = EA_GuaranteedChampionQueue
    end
    if type(fn) == "function" then
        local ok, out = pcall(fn)
        if ok and EA_ChampionStateIsContainer(out) then
            return out
        end
    end
    return {}
end

function EA_GetGuaranteedChampionArmed()
    local vars = EA_ChampionStateVars()
    if not vars then
        return nil
    end
    return vars.GuaranteedChampionArmed
end

local function EA_SetGuaranteedChampionArmed(armed)
    local vars = EA_ChampionStateVars()
    if not vars then
        return false
    end
    vars.GuaranteedChampionArmed = armed
    EA_ChampionStateDirty()
    return true
end

local function EA_ClearGuaranteedChampionForType(creatureType)
    local vars = EA_ChampionStateVars()
    if not vars then
        return false
    end
    local queue = EA_GuaranteedChampionQueue()
    if not EA_ChampionStateIsContainer(queue) then
        return false
    end
    queue[creatureType] = nil

    if vars.GuaranteedChampionArmed
        and vars.GuaranteedChampionArmed.creatureType == creatureType then
        vars.GuaranteedChampionArmed = nil
    end

    EA_ChampionStateDirty()
    return true
end

EA["EA_GuaranteedChampionQueue"] = EA_GuaranteedChampionQueue
EA["EA_GetGuaranteedChampionQueueSafe"] = EA_GetGuaranteedChampionQueueSafe
EA["EA_GetGuaranteedChampionArmed"] = EA_GetGuaranteedChampionArmed
EA["EA_SetGuaranteedChampionArmed"] = EA_SetGuaranteedChampionArmed
EA["EA_ClearGuaranteedChampionForType"] = EA_ClearGuaranteedChampionForType
