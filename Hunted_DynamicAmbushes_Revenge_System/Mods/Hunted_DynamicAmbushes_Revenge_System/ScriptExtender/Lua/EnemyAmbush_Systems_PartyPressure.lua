EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local M = {}

function M.Build(deps)
    deps = deps or {}

    local EA_PARTY_PRESSURE_MIN_POINTS = tonumber(deps.EA_PARTY_PRESSURE_MIN_POINTS) or 3

    local BUDGET_POINT_DELTA_BY_PARTY_SIZE = {
        [1] = -3,
        [2] = -2,
        [3] = -1,
        [4] = 0,
        [5] = 2,
        [6] = 4,
        [7] = 6,
        [8] = 8,
        [9] = 10,
        [10] = 12,
        [11] = 14,
        [12] = 16,
    }

    local TARGET_COUNT_BONUS_BY_PARTY_SIZE = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 1,
        [6] = 1,
        [7] = 2,
        [8] = 2,
        [9] = 3,
        [10] = 3,
        [11] = 4,
        [12] = 4,
    }

    local ENTITY_CAP_BY_PARTY_SIZE = {
        [1] = 4,
        [2] = 4,
        [3] = 5,
        [4] = 6,
        [5] = 7,
        [6] = 8,
        [7] = 9,
        [8] = 10,
        [9] = 11,
        [10] = 12,
        [11] = 13,
        [12] = 14,
    }

    local function ClampPartySize(partySize)
        local size = tonumber(partySize) or 4
        return math.max(1, math.min(12, math.floor(size + 0.5)))
    end

    local function ClampLevel(playerLevel)
        local level = tonumber(playerLevel) or 1
        return math.max(1, math.min(20, math.floor(level + 0.5)))
    end

    local function NormalizeTier(tier)
        local key = string.upper(tostring(tier or "COMMON"))
        if key ~= "COMMON"
            and key ~= "VETERAN"
            and key ~= "ELITE"
            and key ~= "LEGENDARY"
            and key ~= "CHAMPION" then
            key = "COMMON"
        end
        return key
    end

    local function NormalizeTierBias(presetHidden)
        local bias = string.upper(tostring(type(presetHidden) == "table" and presetHidden.tierBias or "COMMON_VETERAN_BASELINE"))
        if bias ~= "COMMON_HEAVY"
            and bias ~= "COMMON_VETERAN_BASELINE"
            and bias ~= "VETERAN_ELITE_LEANING"
            and bias ~= "ELITE_LEGENDARY_LEANING" then
            bias = "COMMON_VETERAN_BASELINE"
        end
        return bias
    end

    local function GetScaledBudgetPoints(points, partySize)
        local basePoints = tonumber(points) or EA_PARTY_PRESSURE_MIN_POINTS
        local size = ClampPartySize(partySize)
        local delta = tonumber(BUDGET_POINT_DELTA_BY_PARTY_SIZE[size]) or 0
        local scaled = math.max(EA_PARTY_PRESSURE_MIN_POINTS, math.floor(basePoints + delta + 0.5))
        return scaled, delta
    end

    local function GetBudgetPartyBonus(playerLevel, partySize, presetHidden)
        local level = ClampLevel(playerLevel)
        local size = ClampPartySize(partySize)
        local bias = NormalizeTierBias(presetHidden)
        local presetBonus = 0

        if size >= 5 and level >= 6 then
            if bias == "VETERAN_ELITE_LEANING" then
                presetBonus = 1
            elseif bias == "ELITE_LEGENDARY_LEANING" then
                presetBonus = 2
            end

            if size >= 7 and level >= 8 and presetBonus > 0 then
                presetBonus = presetBonus + 1
            end
        end

        return presetBonus, presetBonus
    end

    local function GetTargetCountPartyBonus(playerLevel, partySize, tier, presetHidden)
        local level = ClampLevel(playerLevel)
        local size = ClampPartySize(partySize)
        local _ = NormalizeTier(tier)
        local __ = NormalizeTierBias(presetHidden)
        local bonus = tonumber(TARGET_COUNT_BONUS_BY_PARTY_SIZE[size]) or 0

        if level <= 2 then
            bonus = 0
        elseif level <= 4 then
            bonus = math.min(bonus, 1)
        end

        return bonus, bonus
    end

    local function GetEntityCapForParty(baseCap, playerLevel, partySize, tier)
        local configuredBase = math.max(2, math.floor((tonumber(baseCap) or 6) + 0.5))
        local level = ClampLevel(playerLevel)
        local size = ClampPartySize(partySize)
        local tierKey = NormalizeTier(tier)
        local capByParty = tonumber(ENTITY_CAP_BY_PARTY_SIZE[size]) or configuredBase
        local tierShift = 0

        if tierKey == "LEGENDARY" then
            tierShift = -1
        elseif tierKey == "CHAMPION" then
            tierShift = -2
        end

        local dynamicCap = capByParty + tierShift
        if level <= 2 and size <= 2 then
            dynamicCap = math.min(dynamicCap, configuredBase)
        end

        local finalCap = math.max(configuredBase, math.floor(dynamicCap + 0.5))
        return finalCap, capByParty, tierShift
    end

    return {
        ClampPartySize = ClampPartySize,
        ClampLevel = ClampLevel,
        GetScaledBudgetPoints = GetScaledBudgetPoints,
        GetBudgetPartyBonus = GetBudgetPartyBonus,
        GetTargetCountPartyBonus = GetTargetCountPartyBonus,
        GetEntityCapForParty = GetEntityCapForParty,
    }
end

return M
