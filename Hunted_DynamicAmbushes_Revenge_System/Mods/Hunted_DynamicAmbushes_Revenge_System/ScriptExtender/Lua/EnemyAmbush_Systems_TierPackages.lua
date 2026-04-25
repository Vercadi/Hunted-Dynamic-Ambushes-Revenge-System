EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local M = {}

function M.Build(deps)
    deps = deps or {}

    local SystemsDataTables = deps.SystemsDataTables or {}
    local SafeApplyStatus = deps.SafeApplyStatus or function() return false end
    local SafeRemoveStatus = deps.SafeRemoveStatus or function() end
    local SafeAddBoosts = deps.SafeAddBoosts or function() return false end
    local EA_RandFloatSafe = deps.EA_RandFloatSafe or (EA and EA["EA_RandFloatSafe"])
    local EA_RandFloatCompat = deps.EA_RandFloatCompat or function()
        if type(EA_RandFloatSafe) == "function" then
            local ok, out = pcall(EA_RandFloatSafe)
            if ok and tonumber(out) then
                return tonumber(out)
            end
        end
        return 0.5
    end
    local EA_GetBalanceProfileKeyForSystems = deps.EA_GetBalanceProfileKeyForSystems or function() return "BG3_12" end
    local EA_IsCXMode = deps.EA_IsCXMode or function() return false end
    local EA_UseRandomTraits = deps.EA_UseRandomTraits or function() return true end
    local EA_IsDebugMode = deps.EA_IsDebugMode or function() return false end
    local EA_IsDebugHasteAllAmbushers = deps.EA_IsDebugHasteAllAmbushers or function() return false end
    local DebugPrint = deps.DebugPrint or function() end
    local GetPartyMaxLevel = deps.GetPartyMaxLevel
    local GetCurrentAmbushTheme = deps.GetCurrentAmbushTheme or function() return nil end
    local CurrentAmbushTheme = deps.CurrentAmbushTheme
    local EA_GetPresetHiddenBalanceKnobs = deps.EA_GetPresetHiddenBalanceKnobs or (EA and EA["EA_GetPresetHiddenBalanceKnobs"]) or function() return nil end

    local CHAMPION_TYPE_STATUS_BY_TYPE = (SystemsDataTables and SystemsDataTables.CHAMPION_TYPE_STATUS_BY_TYPE) or {
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

    local EA_TIER_PACK = {
        COMMON = { { 15, "EA_TIER_COMMON_L15" }, { 11, "EA_TIER_COMMON_L11" }, { 7, "EA_TIER_COMMON_L7" }, { 5, "EA_TIER_COMMON_L5" }, { 1, "EA_TIER_COMMON_L1" } },
        VETERAN = { { 15, "EA_TIER_VETERAN_L15" }, { 11, "EA_TIER_VETERAN_L11" }, { 7, "EA_TIER_VETERAN_L7" }, { 5, "EA_TIER_VETERAN_L5" }, { 1, "EA_TIER_VETERAN_L1" } },
        ELITE = { { 15, "EA_TIER_ELITE_L15" }, { 12, "EA_TIER_ELITE_L12" }, { 9, "EA_TIER_ELITE_L9" }, { 5, "EA_TIER_ELITE_L5" }, { 1, "EA_TIER_ELITE_L1" } },
        LEGENDARY = { { 15, "EA_TIER_LEGENDARY_L15" }, { 11, "EA_TIER_LEGENDARY_L11" }, { 5, "EA_TIER_LEGENDARY_L5" }, { 1, "EA_TIER_LEGENDARY_L1" } },
    }

    local EA_TIER_PACK_CX = {
        COMMON = { { 11, "EA_TIER_COMMON_CX_L11" }, { 7, "EA_TIER_COMMON_CX_L7" }, { 1, "EA_TIER_COMMON_CX_L1" } },
        VETERAN = { { 11, "EA_TIER_VETERAN_CX_L11" }, { 7, "EA_TIER_VETERAN_CX_L7" }, { 1, "EA_TIER_VETERAN_CX_L1" } },
        ELITE = { { 12, "EA_TIER_ELITE_CX_L12" }, { 9, "EA_TIER_ELITE_CX_L9" }, { 1, "EA_TIER_ELITE_CX_L1" } },
        LEGENDARY = { { 11, "EA_TIER_LEGENDARY_CX_L11" }, { 1, "EA_TIER_LEGENDARY_CX_L1" } },
    }

    local EA_CHAMPION_BASE_PACK = { { 15, "EA_CHAMPION_BASE_L15" }, { 11, "EA_CHAMPION_BASE_L11" }, { 7, "EA_CHAMPION_BASE_L7" }, { 1, "EA_CHAMPION_BASE_L1" } }
    local EA_CHAMPION_BASE_PACK_CX = { { 15, "EA_CHAMPION_BASE_CX_L15" }, { 11, "EA_CHAMPION_BASE_CX_L11" }, { 7, "EA_CHAMPION_BASE_CX_L7" }, { 1, "EA_CHAMPION_BASE_CX_L1" } }

    local EA_TRAIT_POOL = {
        { id = "EA_TRAIT_ARMORED", w = 30 },
        { id = "EA_TRAIT_BRUTAL", w = 25 },
        { id = "EA_TRAIT_MYSTIC", w = 20 },
        { id = "EA_TRAIT_SKIRMISHER", w = 20 },
        { id = "EA_TRAIT_TITANIC", w = 5 },
    }

    local EA_TRAIT_POOL_CX = {
        { id = "EA_TRAIT_ARMORED", w = 35 },
        { id = "EA_TRAIT_BRUTAL", w = 25 },
        { id = "EA_TRAIT_MYSTIC", w = 20 },
        { id = "EA_TRAIT_SKIRMISHER", w = 20 },
    }

    -- High-threat packages can roll a short Haste burst as a rare trait instead of receiving Haste unconditionally.
    local EA_TRAIT_POOL_HIGH_THREAT = {
        { id = "EA_TRAIT_ARMORED", w = 30 },
        { id = "EA_TRAIT_BRUTAL", w = 25 },
        { id = "EA_TRAIT_MYSTIC", w = 20 },
        { id = "EA_TRAIT_SKIRMISHER", w = 20 },
        { id = "EA_TRAIT_TITANIC", w = 5 },
        { id = "EA_TRAIT_HASTE_BURST", w = 5 },
    }

    local EA_TRAIT_POOL_HIGH_THREAT_CX = {
        { id = "EA_TRAIT_ARMORED", w = 35 },
        { id = "EA_TRAIT_BRUTAL", w = 25 },
        { id = "EA_TRAIT_MYSTIC", w = 20 },
        { id = "EA_TRAIT_SKIRMISHER", w = 20 },
        { id = "EA_TRAIT_HASTE_BURST", w = 5 },
    }

    -- Champions should lean on passive combat pressure rather than gaining
    -- extra spell buttons. Keep the high-threat variant haste-free and bias it
    -- toward heavier durability/damage traits at higher brackets.
    local EA_CHAMPION_TRAIT_POOL_HIGH_THREAT = {
        { id = "EA_TRAIT_ARMORED", w = 28 },
        { id = "EA_TRAIT_BRUTAL", w = 28 },
        { id = "EA_TRAIT_MYSTIC", w = 24 },
        { id = "EA_TRAIT_SKIRMISHER", w = 10 },
        { id = "EA_TRAIT_TITANIC", w = 10 },
    }

    local EA_CHAMPION_TRAIT_POOL_HIGH_THREAT_CX = {
        { id = "EA_TRAIT_ARMORED", w = 34 },
        { id = "EA_TRAIT_BRUTAL", w = 24 },
        { id = "EA_TRAIT_MYSTIC", w = 20 },
        { id = "EA_TRAIT_SKIRMISHER", w = 12 },
        { id = "EA_TRAIT_TITANIC", w = 10 },
    }

    local EA_CLEAR_TIER_STATUS_IDS = {
        "EA_TIER_COMMON_L1", "EA_TIER_COMMON_L5", "EA_TIER_COMMON_L7", "EA_TIER_COMMON_L11", "EA_TIER_COMMON_L15",
        "EA_TIER_VETERAN_L1", "EA_TIER_VETERAN_L5", "EA_TIER_VETERAN_L7", "EA_TIER_VETERAN_L11", "EA_TIER_VETERAN_L15",
        "EA_TIER_ELITE_L1", "EA_TIER_ELITE_L5", "EA_TIER_ELITE_L9", "EA_TIER_ELITE_L12", "EA_TIER_ELITE_L15",
        "EA_TIER_LEGENDARY_L1", "EA_TIER_LEGENDARY_L5", "EA_TIER_LEGENDARY_L11", "EA_TIER_LEGENDARY_L15",
        "EA_TIER_COMMON_CX_L1", "EA_TIER_COMMON_CX_L7", "EA_TIER_COMMON_CX_L11",
        "EA_TIER_VETERAN_CX_L1", "EA_TIER_VETERAN_CX_L7", "EA_TIER_VETERAN_CX_L11",
        "EA_TIER_ELITE_CX_L1", "EA_TIER_ELITE_CX_L9", "EA_TIER_ELITE_CX_L12",
        "EA_TIER_LEGENDARY_CX_L1", "EA_TIER_LEGENDARY_CX_L11",
    }

    local function EA_HasAnyEnlargeStatus(target)
        if not (Osi and Osi.HasActiveStatus) then return false end
        return (Osi.HasActiveStatus(target, "ENLARGE") == 1) or (Osi.HasActiveStatus(target, "ENLARGED") == 1)
    end

    local function EA_ApplyEnlargeStatus(target, durationSeconds, forceRefresh)
        if not target or target == "" then return false end

        durationSeconds = tonumber(durationSeconds) or 12
        forceRefresh = (forceRefresh == true)

        if (not forceRefresh) and EA_HasAnyEnlargeStatus(target) then return true end

        if forceRefresh then
            SafeRemoveStatus(target, "ENLARGE")
            SafeRemoveStatus(target, "ENLARGED")
        end

        if SafeApplyStatus(target, "ENLARGE", durationSeconds, 1) then
            return true
        end

        if SafeApplyStatus(target, "ENLARGED", durationSeconds, 1) then
            return true
        end

        return false
    end

    local function EA_SelectBracket(pack, level)
        level = tonumber(level) or 1
        for _, entry in ipairs(pack) do
            if level >= entry[1] then return entry[2] end
        end
        return nil
    end

    local function EA_SelectTierStatus(category, cx, referenceLevel)
        local pack = cx and EA_TIER_PACK_CX or EA_TIER_PACK
        local entries = pack and pack[category]
        if not entries then return nil end

        local level = tonumber(referenceLevel) or 1
        return EA_SelectBracket(entries, level)
    end

    local function EA_RoundInt(value)
        local n = tonumber(value) or 0
        if n >= 0 then
            return math.floor(n + 0.5)
        end
        return math.ceil(n - 0.5)
    end

    local function EA_ClampTierStatusThreatLevel(level)
        local n = EA_RoundInt(level)
        if n < 1 then return 1 end
        if n > 20 then return 20 end
        return n
    end

    local function EA_GetTierStatusLevelOffset(cx, baseThreatLevel)
        local hidden = nil
        if type(EA_GetPresetHiddenBalanceKnobs) == "function" then
            local ok, data = pcall(EA_GetPresetHiddenBalanceKnobs)
            if ok and type(data) == "table" then
                hidden = data
            end
        end

        local offset = math.max(-4, math.min(4, EA_RoundInt(hidden and hidden.tierStatusLevelOffset or 0)))
        local baseLevel = tonumber(baseThreatLevel) or 1
        if cx == true or baseLevel < 5 then
            offset = 0
        end

        return offset,
            tostring(hidden and hidden.presetKey or "unknown"),
            tostring(hidden and hidden.tierBias or "unknown")
    end

    local function EA_SelectChampionBaseStatus(level, cx)
        local pack = cx and EA_CHAMPION_BASE_PACK_CX or EA_CHAMPION_BASE_PACK
        level = tonumber(level) or 1
        return EA_SelectBracket(pack, level)
    end

    local function EA_SelectChampionTypeStatus(creatureType)
        if not creatureType then return nil end
        return CHAMPION_TYPE_STATUS_BY_TYPE and CHAMPION_TYPE_STATUS_BY_TYPE[creatureType] or nil
    end

    local function EA_Hash32(text)
        text = tostring(text or "")
        local h = 0
        for i = 1, #text do
            h = (h * 31 + text:byte(i)) % 4294967296
        end
        return h
    end

    local function EA_Rand01(seed, salt)
        local h = EA_Hash32(tostring(seed) .. "|" .. tostring(salt or "0"))
        return (h % 1000000) / 1000000
    end

    local function EA_WeightedPick(pool, r01)
        local total = 0
        for _, trait in ipairs(pool) do
            total = total + (trait.w or 0)
        end
        if total <= 0 then return nil end
        local roll = r01 * total
        local acc = 0
        for _, trait in ipairs(pool) do
            acc = acc + (trait.w or 0)
            if roll <= acc then return trait.id end
        end
        return pool[#pool].id
    end

    local function EA_PickDistinctTraits(seed, count, pool)
        local out = {}
        local used = {}
        local tries = 0
        while #out < count and tries < 20 do
            tries = tries + 1
            local pick = EA_WeightedPick(pool, EA_Rand01(seed, "trait_" .. tostring(tries)))
            if pick and not used[pick] then
                used[pick] = true
                table.insert(out, pick)
            end
        end
        return out
    end

    local function EA_ApplyTrait(enemy, traitId, durationSeconds)
        if traitId == "EA_TRAIT_HASTE_BURST" then
            local hasteDuration = 12
            if type(EA_RandFloatSafe) == "function" or type(EA_RandFloatCompat) == "function" then
                local roll = tonumber(EA_RandFloatCompat()) or 0.5
                hasteDuration = 12 + math.floor(math.max(0, math.min(1, roll)) * 12)
            end
            return SafeApplyStatus(enemy, "HASTE", hasteDuration, 1)
        end

        local applied = SafeApplyStatus(enemy, traitId, durationSeconds, 1)
        if traitId == "EA_TRAIT_TITANIC" and applied == true then
            EA_ApplyEnlargeStatus(enemy, 12)
        end
        return applied
    end

    local function EA_ApplyTierAndTraits(enemy, player, category, enemyLevel, durationSeconds, ambushRoll)
        if not enemy or enemy == "" then return end

        SafeApplyStatus(enemy, "EA_AMBUSHER", durationSeconds or 600, 1)

        SafeRemoveStatus(enemy, "EA_VETERAN_BUFF")
        SafeRemoveStatus(enemy, "EA_ELITE_BUFF")
        SafeRemoveStatus(enemy, "EA_LEGENDARY_BUFF")

        for _, statusId in ipairs(EA_CLEAR_TIER_STATUS_IDS) do
            SafeRemoveStatus(enemy, statusId)
        end

        local cx = EA_IsCXMode()
        local threatLevel = tonumber(ambushRoll and (ambushRoll.playerLevel or ambushRoll.targetLevel))
            or tonumber(enemyLevel)
            or (player and GetPartyMaxLevel and tonumber(GetPartyMaxLevel(player)))
            or 1
        local tierStatusOffset, presetKey, tierBias = EA_GetTierStatusLevelOffset(cx, threatLevel)
        local statusThreatLevel = EA_ClampTierStatusThreatLevel((tonumber(threatLevel) or 1) + tierStatusOffset)
        local chosenStatus = EA_SelectTierStatus(category, cx, statusThreatLevel)
        if chosenStatus then
            SafeApplyStatus(enemy, chosenStatus, durationSeconds or 600, 1)
            if EA_IsDebugMode() then
                DebugPrint(string.format(
                    "[TierDurability] enemy=%s category=%s threat=%d statusThreat=%d offset=%d preset=%s tierBias=%s cx=%s status=%s",
                    tostring(enemy),
                    tostring(category),
                    tonumber(threatLevel) or -1,
                    tonumber(statusThreatLevel) or -1,
                    tonumber(tierStatusOffset) or 0,
                    tostring(presetKey),
                    tostring(tierBias),
                    tostring(cx),
                    tostring(chosenStatus)
                ))
            end
        end

        if EA_IsDebugHasteAllAmbushers() then
            SafeApplyStatus(enemy, "HASTE", 6, 1)
        end

        if string.upper(tostring(category or "")) == "COMMON" and not chosenStatus then
            local okBoost = false
            local commonBoosts
            if cx then
                if statusThreatLevel >= 11 then
                    commonBoosts = "IncreaseMaxHP(42%);TemporaryHP(10)"
                elseif statusThreatLevel >= 7 then
                    commonBoosts = "IncreaseMaxHP(30%);TemporaryHP(8)"
                else
                    commonBoosts = "IncreaseMaxHP(18%);TemporaryHP(5)"
                end
            else
                if statusThreatLevel >= 15 then
                    commonBoosts = "IncreaseMaxHP(150%);TemporaryHP(34);ArmorClass(1);WeaponDamage(1)"
                elseif statusThreatLevel >= 11 then
                    commonBoosts = "IncreaseMaxHP(118%);TemporaryHP(26);WeaponDamage(1)"
                elseif statusThreatLevel >= 7 then
                    commonBoosts = "IncreaseMaxHP(82%);TemporaryHP(18)"
                elseif statusThreatLevel >= 5 then
                    commonBoosts = "IncreaseMaxHP(70%);TemporaryHP(16);WeaponDamage(1)"
                else
                    commonBoosts = "IncreaseMaxHP(30%);TemporaryHP(8)"
                end
            end
            if SafeAddBoosts then
                okBoost = SafeAddBoosts(enemy, commonBoosts or "IncreaseMaxHP(30%);TemporaryHP(8)")
            end
            if EA_IsDebugMode() then
                DebugPrint(string.format(
                    "[TierDurability] enemy=%s category=COMMON threat=%d statusThreat=%d offset=%d preset=%s tierBias=%s cx=%s inline=%s applied=%s",
                    tostring(enemy),
                    tonumber(threatLevel) or -1,
                    tonumber(statusThreatLevel) or -1,
                    tonumber(tierStatusOffset) or 0,
                    tostring(presetKey),
                    tostring(tierBias),
                    tostring(cx),
                    tostring(commonBoosts),
                    tostring(okBoost)
                ))
            end
            if EA_IsDebugMode() and not okBoost then
                DebugPrint(string.format("[Tier] COMMON boost apply failed (status intentionally hidden): enemy=%s boosts=%s", tostring(enemy), tostring(commonBoosts)))
            end
        end

        if EA_UseRandomTraits() then
            local traitCount = 0
            if category == "VETERAN" then
                traitCount = (EA_RandFloatCompat() < 0.25) and 1 or 0
            elseif category == "ELITE" then
                traitCount = 1
            elseif category == "LEGENDARY" then
                traitCount = 2
            end

            local profile = EA_GetBalanceProfileKeyForSystems()
            if profile == "MODDED_20" then
                if threatLevel >= 16 then
                    if category == "VETERAN" and traitCount == 0 then
                        traitCount = (EA_RandFloatCompat() < 0.40) and 1 or 0
                    elseif category == "ELITE" then
                        traitCount = math.max(traitCount, 2)
                    end
                end
                if threatLevel >= 18 and category == "LEGENDARY" then
                    traitCount = math.max(traitCount, 3)
                end
            end

            if traitCount > 0 then
                local pool = cx and EA_TRAIT_POOL_CX or EA_TRAIT_POOL
                if category == "LEGENDARY" then
                    pool = cx and EA_TRAIT_POOL_HIGH_THREAT_CX or EA_TRAIT_POOL_HIGH_THREAT
                end
                local rollTheme = (type(ambushRoll) == "table" and ambushRoll.ambushTheme) or nil
                local theme = rollTheme or GetCurrentAmbushTheme() or CurrentAmbushTheme or ""
                local seed = tostring(enemy) .. "|tier|" .. tostring(category) .. "|" .. tostring(theme)
                local traits = EA_PickDistinctTraits(seed, traitCount, pool)

                for _, traitId in ipairs(traits) do
                    EA_ApplyTrait(enemy, traitId, durationSeconds or 600)
                end
            end
        end

        return chosenStatus
    end

    local function EA_ApplyChampionPackages(enemy, creatureType, level, durationSeconds, ambushSeed)
        if not enemy or enemy == "" then return end

        durationSeconds = durationSeconds or 600

        SafeRemoveStatus(enemy, "EA_VETERAN_BUFF")
        SafeRemoveStatus(enemy, "EA_ELITE_BUFF")
        SafeRemoveStatus(enemy, "EA_LEGENDARY_BUFF")
        SafeRemoveStatus(enemy, "EA_AMBUSHER")

        for _, statusId in ipairs(EA_CLEAR_TIER_STATUS_IDS) do
            SafeRemoveStatus(enemy, statusId)
        end

        local cx = EA_IsCXMode()

        local baseStatus = EA_SelectChampionBaseStatus(level, cx)
        if baseStatus then
            SafeApplyStatus(enemy, baseStatus, durationSeconds, 1)
        end

        local typeStatus = EA_SelectChampionTypeStatus(creatureType)
        if typeStatus then
            SafeApplyStatus(enemy, typeStatus, durationSeconds, 1)
        end

        if EA_UseRandomTraits() then
            -- Champions use passive trait pressure, not free extra spells.
            local pool = cx and EA_TRAIT_POOL_CX or EA_TRAIT_POOL
            local traitCount = 2
            local profile = EA_GetBalanceProfileKeyForSystems()
            local championLevel = tonumber(level) or 1

            if championLevel >= 15 then
                pool = cx and EA_CHAMPION_TRAIT_POOL_HIGH_THREAT_CX or EA_CHAMPION_TRAIT_POOL_HIGH_THREAT
                traitCount = 3
            elseif championLevel >= 11 then
                pool = cx and EA_CHAMPION_TRAIT_POOL_HIGH_THREAT_CX or EA_CHAMPION_TRAIT_POOL_HIGH_THREAT
            end

            if profile == "MODDED_20" and championLevel >= 18 then
                traitCount = math.max(traitCount, 4)
            end
            local seed = tostring(enemy) .. "|champ|" .. tostring(creatureType) .. "|" .. tostring(ambushSeed or "")
            local traits = EA_PickDistinctTraits(seed, traitCount, pool)

            for _, traitId in ipairs(traits) do
                EA_ApplyTrait(enemy, traitId, durationSeconds)
            end
        end
    end

    local function EA_ApplyChampionTelegraph(enemy, creatureType)
        if not enemy or enemy == "" then return end
        if creatureType == "Humanoid" or creatureType == "Giant" then
            EA_ApplyEnlargeStatus(enemy, 600, true)
            if Ext and Ext.Timer and Ext.Timer.WaitFor then
                Ext.Timer.WaitFor(250, function()
                    EA_ApplyEnlargeStatus(enemy, 600, true)
                end)
            end
        end
    end

    local function BoostChampionStats(_, _)
        -- intentionally empty
    end

    local function ApplyChampionBuffs(enemy, creatureType, level)
        if not enemy or enemy == "" then return end
        level = tonumber(level) or 1
        EA_ApplyChampionPackages(enemy, creatureType, level, 600, creatureType)
    end

    return {
        CHAMPION_TYPE_STATUS_BY_TYPE = CHAMPION_TYPE_STATUS_BY_TYPE,
        EA_TIER_PACK = EA_TIER_PACK,
        EA_TIER_PACK_CX = EA_TIER_PACK_CX,
        EA_CHAMPION_BASE_PACK = EA_CHAMPION_BASE_PACK,
        EA_CHAMPION_BASE_PACK_CX = EA_CHAMPION_BASE_PACK_CX,
        EA_TRAIT_POOL = EA_TRAIT_POOL,
        EA_TRAIT_POOL_CX = EA_TRAIT_POOL_CX,
        EA_SelectTierStatus = EA_SelectTierStatus,
        EA_SelectChampionBaseStatus = EA_SelectChampionBaseStatus,
        EA_SelectChampionTypeStatus = EA_SelectChampionTypeStatus,
        EA_ApplyTierAndTraits = EA_ApplyTierAndTraits,
        EA_ApplyChampionPackages = EA_ApplyChampionPackages,
        EA_ApplyChampionTelegraph = EA_ApplyChampionTelegraph,
        ApplyChampionBuffs = ApplyChampionBuffs,
        BoostChampionStats = BoostChampionStats,
    }
end

return M
