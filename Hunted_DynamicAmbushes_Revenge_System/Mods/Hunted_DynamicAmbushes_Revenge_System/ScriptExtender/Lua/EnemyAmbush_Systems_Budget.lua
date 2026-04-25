EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local M = {}

function M.Build(deps)
    deps = deps or {}

    local MCMContract = deps.MCMContract or (Ext.Require("EnemyAmbush_MCMContract.lua") or (EA and EA.MCMContract) or {})
    local EA_GetSettingRaw = deps.EA_GetSettingRaw or function(_, fallback) return fallback end
    local EA_GetSettingNumber = deps.EA_GetSettingNumber or function(_, fallback) return tonumber(fallback) or 0 end
    local EA_IsAdvancedMode = deps.EA_IsAdvancedMode or function() return false end
    local EA_GetEffectiveScaleWithPartySize = deps.EA_GetEffectiveScaleWithPartySize or function() return true end
    local EA_GetPresetHiddenBalanceKnobs = deps.EA_GetPresetHiddenBalanceKnobs or (EA and EA["EA_GetPresetHiddenBalanceKnobs"]) or function() return nil end
    local EA_GetScaledBudgetPoints = deps.EA_GetScaledBudgetPoints or function(points)
        return tonumber(points) or 0
    end
    local EA_GetBudgetPartyBonus = deps.EA_GetBudgetPartyBonus or function()
        return 0, 0
    end
    local EA_IsDebugMode = deps.EA_IsDebugMode or function() return false end
    local GetPartySize = deps.GetPartySize or function() return 4 end
    local DebugPrint = deps.DebugPrint or function() end

    local EA_BUDGET_MIN = 3
    local EA_BUDGET_MAX_BASE = 32
    local EA_BUDGET_LINEAR = 1.30
    local EA_BUDGET_LATE_START = 9
    local EA_BUDGET_LATE_MULT = 0.45

    local EA_BUDGET_MAX_FINAL = 40

    local function EA_NormalizeContractValue(id, value, fallback)
        if MCMContract and type(MCMContract.NormalizeValue) == "function" then
            return MCMContract.NormalizeValue(id, value, fallback)
        end
        return fallback
    end

    local function EA_GetBalanceProfileKeyForSystems()
        if type(EA_GetSettingRaw) == "function" then
            local profile = EA_NormalizeContractValue("MCM_BalanceProfile", EA_GetSettingRaw("MCM_BalanceProfile", "BG3_12"), "BG3_12")
            if profile == "BG3_12" or profile == "MODDED_20" then
                return profile
            end
        end
        return "BG3_12"
    end

    local function EA_GetBudgetFinalCapForProfile()
        local profile = EA_GetBalanceProfileKeyForSystems()
        if profile == "MODDED_20" then
            return math.max(EA_BUDGET_MAX_FINAL, 48)
        end
        return EA_BUDGET_MAX_FINAL
    end

    local function EA_GetNormalizedPresetHiddenKnobs()
        local raw = nil
        if type(EA_GetPresetHiddenBalanceKnobs) == "function" then
            local ok, data = pcall(EA_GetPresetHiddenBalanceKnobs)
            if ok and type(data) == "table" then
                raw = data
            end
        end

        local tierBias = string.upper(tostring(raw and raw.tierBias or "COMMON_VETERAN_BASELINE"))
        if tierBias ~= "COMMON_HEAVY"
            and tierBias ~= "COMMON_VETERAN_BASELINE"
            and tierBias ~= "VETERAN_ELITE_LEANING"
            and tierBias ~= "ELITE_LEGENDARY_LEANING" then
            tierBias = "COMMON_VETERAN_BASELINE"
        end

        return {
            tierBias = tierBias,
            maxVeteran = math.max(0, math.floor((tonumber(raw and raw.maxVeteran) or 2) + 0.5)),
            maxElite = math.max(0, math.floor((tonumber(raw and raw.maxElite) or 1) + 0.5)),
            maxLegendary = math.max(0, math.floor((tonumber(raw and raw.maxLegendary) or 1) + 0.5)),
        }
    end

    local function EA_PointBudgetCurve(playerLevel)
        local level = tonumber(playerLevel) or 1
        level = math.max(1, math.min(20, math.floor(level)))
        local profile = EA_GetBalanceProfileKeyForSystems()

        local base = EA_BUDGET_MIN + math.floor((level - 1) * EA_BUDGET_LINEAR + 0.5)

        local late = 0
        if level >= EA_BUDGET_LATE_START then
            local t = level - (EA_BUDGET_LATE_START - 1)
            late = math.floor(t * t * EA_BUDGET_LATE_MULT + 0.5)
        end

        local points = base + late
        points = math.max(EA_BUDGET_MIN, math.min(EA_BUDGET_MAX_BASE, points))

        if profile == "MODDED_20" and level > 12 then
            points = points + math.min(8, level - 12)
        end

        local curveCap = EA_BUDGET_MAX_BASE
        if profile == "MODDED_20" then
            curveCap = math.max(curveCap, 40)
        end
        points = math.max(EA_BUDGET_MIN, math.min(curveCap, points))
        return points
    end

    local function EA_ApplyPartyScaling(points, partySize)
        local scaled = EA_GetScaledBudgetPoints(points, partySize)
        local finalCap = EA_GetBudgetFinalCapForProfile()
        scaled = math.max(EA_BUDGET_MIN, math.min(finalCap, scaled))
        return scaled
    end

    local function GetPointBudget(playerLevel, player)
        local pointBudget = EA_GetSettingNumber("MCM_PointBudget", 0) or 0
        local debugMode = EA_IsDebugMode()
        if EA_IsAdvancedMode() and debugMode and pointBudget > 0 then
            if debugMode then
                DebugPrint(string.format("[Budget] Fixed override: %d (Advanced Mode, MCM_PointBudget>0)", math.floor(pointBudget + 0.5)))
            end
            return math.max(1, math.floor(pointBudget + 0.5))
        end

        local base = EA_PointBudgetCurve(playerLevel)
        local scaleEnabled = EA_GetEffectiveScaleWithPartySize() == true
        local partySize = 4
        if player and scaleEnabled then
            partySize = GetPartySize(player)
        end

        local scaled = EA_ApplyPartyScaling(base, partySize)
        local bonus = 0
        local presetBonus = 0
        local scaleDelta = scaled - base
        if scaleEnabled then
            local level = tonumber(playerLevel) or 1
            level = math.max(1, math.min(20, math.floor(level)))

            local size = tonumber(partySize) or 4
            size = math.max(1, math.min(12, math.floor(size)))
            local hidden = EA_GetNormalizedPresetHiddenKnobs()
            bonus, presetBonus = EA_GetBudgetPartyBonus(level, size, hidden)

            if debugMode then
                DebugPrint(string.format(
                    "[BudgetPreset] level=%d partySize=%d tierBias=%s hidden[V=%d E=%d L=%d] presetBonus=%d",
                    level, size, tostring(hidden.tierBias),
                    tonumber(hidden.maxVeteran) or 0,
                    tonumber(hidden.maxElite) or 0,
                    tonumber(hidden.maxLegendary) or 0,
                    presetBonus
                ))
                DebugPrint(string.format(
                    "[PartyPressure] level=%d party=%d budgetScaleDelta=%d budgetBonus=%d",
                    level,
                    size,
                    tonumber(scaleDelta) or 0,
                    tonumber(bonus) or 0
                ))
            end
        end

        local finalCap = EA_GetBudgetFinalCapForProfile()
        local final = math.max(EA_BUDGET_MIN, math.min(finalCap, scaled + bonus))

        if debugMode then
            local advanced = EA_IsAdvancedMode()
            DebugPrint(string.format(
                "[Budget] level=%d base=%d partySize=%d scaleEnabled=%s(adv=%s) => scaled=%d bonus=%d final=%d",
                tonumber(playerLevel) or -1, base, partySize,
                tostring(scaleEnabled), tostring(advanced), scaled, bonus, final
            ))
        end

        return final
    end

    return {
        EA_BUDGET_MIN = EA_BUDGET_MIN,
        EA_BUDGET_MAX_BASE = EA_BUDGET_MAX_BASE,
        EA_BUDGET_LINEAR = EA_BUDGET_LINEAR,
        EA_BUDGET_LATE_START = EA_BUDGET_LATE_START,
        EA_BUDGET_LATE_MULT = EA_BUDGET_LATE_MULT,
        EA_BUDGET_MAX_FINAL = EA_BUDGET_MAX_FINAL,
        EA_GetBalanceProfileKeyForSystems = EA_GetBalanceProfileKeyForSystems,
        EA_GetBudgetFinalCapForProfile = EA_GetBudgetFinalCapForProfile,
        EA_PointBudgetCurve = EA_PointBudgetCurve,
        EA_ApplyPartyScaling = EA_ApplyPartyScaling,
        GetPointBudget = GetPointBudget,
    }
end

return M
