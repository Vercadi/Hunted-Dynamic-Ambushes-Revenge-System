EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
local M = {}
function M.Build(deps)
    deps = deps or {}
    local EnemyAmbush = deps.EnemyAmbush or EA
    local EA = deps.EA or EnemyAmbush or {}
    local MCMContract = deps.MCMContract or (Ext.Require("EnemyAmbush_MCMContract.lua") or (EA and EA.MCMContract) or {})
    local EA_GetRegionForCharacter = deps.EA_GetRegionForCharacter or function() return "", "" end
    local EA_GetSafeZoneState = deps.EA_GetSafeZoneState or function()
        return { activeZones = {}, triggerBlocked = false }
    end
    local EA_IsCharacterInBlockedSafeZone = deps.EA_IsCharacterInBlockedSafeZone or function() return false end
    local EA_LogUnknownRegion = deps.EA_LogUnknownRegion or function() end
    local EA_IsRawRegionBlocked = deps.EA_IsRawRegionBlocked or function() return false end
    local EA_IsRegionBlocked = deps.EA_IsRegionBlocked or function() return false end
    local EA_GetEffectiveAmbushIntensity = deps.EA_GetEffectiveAmbushIntensity or function() return 1.0 end
    local EA_IsCXMode = deps.EA_IsCXMode or function() return false end
    local DebugPrint = deps.DebugPrint or function() end
    local EA_GetUseCompositionGuards = deps.EA_GetUseCompositionGuards
    local EA_GetSettingBoolRaw = deps.EA_GetSettingBool or function(_, fallback) return fallback == true end
    local function EA_GetSettingBool(settingId, fallback)
        if settingId == "MCM_DebugMode" then
            return EA_GetSettingBoolRaw("MCM_EnableDebugLogging", false) == true
                or EA_GetSettingBoolRaw("MCM_DebugMode", false) == true
        end
        return EA_GetSettingBoolRaw(settingId, fallback)
    end
    local EA_GetSpawnPlacementMode = deps.EA_GetSpawnPlacementMode or (EA and EA["EA_GetSpawnPlacementMode"]) or function() return "AUTO" end
    local EA_GetBalanceProfile = deps.EA_GetBalanceProfile
    local EA_GetPresetHiddenBalanceKnobs = deps.EA_GetPresetHiddenBalanceKnobs or (EA and EA["EA_GetPresetHiddenBalanceKnobs"]) or function() return nil end
    local EA_GetTargetCountPartyBonus = deps.EA_GetTargetCountPartyBonus or function() return 0, 0 end
    local EA_GetEntityCapForParty = deps.EA_GetEntityCapForParty or function(baseCap)
        return tonumber(baseCap) or 6, tonumber(baseCap) or 6, 0
    end
    local EA_GetSettingRaw = deps.EA_GetSettingRaw or function(_, fallback) return fallback end
    local GetPartySize = deps.GetPartySize or function() return 1 end
    local EA_GetPartyProfile = deps.EA_GetPartyProfile or (EA and EA["EA_GetPartyProfile"]) or nil
    local EA_GetPoolActiveSummonList = deps.EA_GetPoolActiveSummonList or function() return {} end
    local GetAmbushThemeForEnemy = deps.GetAmbushThemeForEnemy
    local ValidateEnemyData = deps.ValidateEnemyData
    local PickEnemyTemplate = deps.PickEnemyTemplate
    local SpawnHostileNearPlayer = deps.SpawnHostileNearPlayer
    local EA_RecordRecentAmbushType = deps.EA_RecordRecentAmbushType
    local EA_ConsumeTypePressure = deps.EA_ConsumeTypePressure
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local EA_RandIntCompat = deps.EA_RandIntCompat
    local EA_PlayRegionAmbience = deps.EA_PlayRegionAmbience
    local EA_PlayPostSpawnBark = deps.EA_PlayPostSpawnBark
    local EA_DiagBeginEncounter = deps.EA_DiagBeginEncounter or (EA and EA["EA_DiagBeginEncounter"]) or function() return nil end
    local EA_DiagRecordEncounterFailure = deps.EA_DiagRecordEncounterFailure or (EA and EA["EA_DiagRecordEncounterFailure"]) or function() return false end
    local EA_DiagFinalizeEncounter = deps.EA_DiagFinalizeEncounter or (EA and EA["EA_DiagFinalizeEncounter"]) or function() return false end
    local EA_SPAWN_STAGGER_MS_DEFAULT = tonumber(deps.EA_SPAWN_STAGGER_MS) or tonumber((EA and EA.CFG and EA.CFG.SPAWN_STAGGER_MS)) or 100
    local function EA_GetSpawnStaggerMsLive()
        return tonumber((EA and EA.CFG and EA.CFG.SPAWN_STAGGER_MS)) or EA_SPAWN_STAGGER_MS_DEFAULT
    end
    local function EA_NormalizeContractValue(id, value, fallback)
        if MCMContract and type(MCMContract.NormalizeValue) == "function" then
            return MCMContract.NormalizeValue(id, value, fallback)
        end
        return fallback
    end
    local function EA_DefaultBalanceProfileKeyForSystems()
        if type(EA_GetBalanceProfile) == "function" then
            local profile = EA_NormalizeContractValue("MCM_BalanceProfile", EA_GetBalanceProfile() or "BG3_12", "BG3_12")
            if profile == "BG3_12" or profile == "MODDED_20" then
                return profile
            end
        end
        local profile = EA_NormalizeContractValue("MCM_BalanceProfile", EA_GetSettingRaw("MCM_BalanceProfile", "BG3_12") or "BG3_12", "BG3_12")
        if profile == "BG3_12" or profile == "MODDED_20" then
            return profile
        end
        return "BG3_12"
    end
    local function EA_GetSpawnPlacementModeKey()
        local mode = tostring(EA_GetSpawnPlacementMode() or "CREATE_OOS_ONLY"):upper()
        if mode ~= "AUTO" and mode ~= "FIND_VALID_ONLY" and mode ~= "CREATE_OOS_ONLY" then
            mode = "CREATE_OOS_ONLY"
        end
        return mode
    end
    local EA_GetBalanceProfileKeyForSystems = deps.EA_GetBalanceProfileKeyForSystems or EA_DefaultBalanceProfileKeyForSystems
local EA_TIER_ORDER = { COMMON = 1, VETERAN = 2, ELITE = 3, LEGENDARY = 4, CHAMPION = 5 }
local EA_TIER_FROM_INDEX = { "COMMON", "VETERAN", "ELITE", "LEGENDARY", "CHAMPION" }

local function EA_NormalizeTierLabel(tier)
    local key = string.upper(tostring(tier or "COMMON"))
    if not EA_TIER_ORDER[key] then
        return "COMMON"
    end
    return key
end

local function EA_DowngradeTier(tier, steps)
    local key = EA_NormalizeTierLabel(tier)
    local idx = EA_TIER_ORDER[key] or 1
    local down = tonumber(steps) or 1
    local target = math.max(1, idx - down)
    return EA_TIER_FROM_INDEX[target] or "COMMON"
end

local function EA_GetSupportBaseTier(topTier, presetHidden, playerLevel, partySize)
    local top = EA_NormalizeTierLabel(topTier)
    local base = EA_DowngradeTier(top, 1)
    if top == "COMMON" then
        return base, base, nil
    end

    local hidden = presetHidden or {}
    local bias = string.upper(tostring(hidden.tierBias or "COMMON_VETERAN_BASELINE"))
    local level = math.max(1, math.min(20, math.floor(tonumber(playerLevel) or 1)))
    local size = math.max(1, math.min(12, math.floor(tonumber(partySize) or 4)))

    if bias == "ELITE_LEGENDARY_LEANING" and level >= 8 and size >= 4 then
        if top == "VETERAN" then
            return "VETERAN", base, "hunted_veteran_floor"
        end
        return base, base, nil
    end

    if bias == "VETERAN_ELITE_LEANING" and level >= 10 and size >= 5 then
        if top == "VETERAN" then
            return "VETERAN", base, "relentless_veteran_floor"
        end
        return base, base, nil
    end

    return base, base, nil
end

local function EA_GetBaseTierTargetAdjustment(tier)
    local key = EA_NormalizeTierLabel(tier)
    if key == "VETERAN" or key == "ELITE" then
        return -1
    end
    if key == "LEGENDARY" or key == "CHAMPION" then
        return -2
    end
    return 0
end

local function EA_GetTierTargetAdjustment(tier, presetHidden, playerLevel, partySize)
    local key = EA_NormalizeTierLabel(tier)
    local baseAdjustment = EA_GetBaseTierTargetAdjustment(key)

    if key == "CHAMPION" then
        return baseAdjustment, baseAdjustment
    end

    local hidden = presetHidden or {}
    local bias = string.upper(tostring(hidden.tierBias or "COMMON_VETERAN_BASELINE"))
    local level = tonumber(playerLevel) or 1
    local size = tonumber(partySize) or 4
    level = math.max(1, math.min(20, math.floor(level)))
    size = math.max(1, math.min(12, math.floor(size)))

    if level < 8 or size < 5 then
        return baseAdjustment, baseAdjustment
    end

    if bias == "VETERAN_ELITE_LEANING" then
        if key == "VETERAN" then
            return 0, baseAdjustment
        elseif key == "ELITE" and size >= 6 then
            return 0, baseAdjustment
        end
    elseif bias == "ELITE_LEGENDARY_LEANING" then
        if key == "VETERAN" or key == "ELITE" then
            return 0, baseAdjustment
        elseif key == "LEGENDARY" then
            return -1, baseAdjustment
        end
    end

    return baseAdjustment, baseAdjustment
end

local function EA_NormalizePresetHiddenKnobs()
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

    local fodderEliteBias = string.upper(tostring(raw and raw.fodderEliteBias or "BALANCED"))
    if fodderEliteBias ~= "FODDER_HEAVY"
        and fodderEliteBias ~= "BALANCED"
        and fodderEliteBias ~= "STRONGER_ENEMY_LEANING"
        and fodderEliteBias ~= "STRONGEST_ENEMY_LEANING" then
        fodderEliteBias = "BALANCED"
    end

    return {
        tierBias = tierBias,
        fodderEliteBias = fodderEliteBias,
        maxVeteran = math.max(0, math.floor((tonumber(raw and raw.maxVeteran) or 2) + 0.5)),
        maxElite = math.max(0, math.floor((tonumber(raw and raw.maxElite) or 1) + 0.5)),
        maxLegendary = math.max(0, math.floor((tonumber(raw and raw.maxLegendary) or 1) + 0.5)),
    }
end

local function EA_CopyRollWithTier(baseRoll, tier, roleTag)
    local out = {}
    if type(baseRoll) == "table" then
        for k, v in pairs(baseRoll) do
            out[k] = v
        end
    end
    local t = EA_NormalizeTierLabel(tier)
    out.tier = t
    out.category = t
    if roleTag then
        out.spawnRole = roleTag
    end
    return out
end

-- Effective point-cost floor for low-template entries at higher party levels.
-- This keeps "difficulty metadata" levels useful while preventing high-level
-- ambushes from overfilling with many cheap low-tier templates.
local function EA_GetMinAmbushTemplateCostForPartyLevel(partyLevel)
    local pl = tonumber(partyLevel) or 1
    local profile = EA_GetBalanceProfileKeyForSystems()
    if profile == "MODDED_20" and pl >= 20 then return 6 end
    if pl >= 16 then return 5 end
    if pl >= 12 then return 4 end
    if pl >= 8 then return 3 end
    return 1
end

local function EA_GetEffectiveAmbushTemplateCost(enemyData, partyLevel)
    local rawCost = tonumber(enemyData and enemyData.level) or 1
    rawCost = math.max(1, math.floor(rawCost + 0.5))
    local floorCost = EA_GetMinAmbushTemplateCostForPartyLevel(partyLevel)
    local effectiveCost = math.max(rawCost, floorCost)
    return effectiveCost, rawCost, floorCost
end

-- Execute the actual ambush spawn (separated from TriggerAmbush for delay)
local function ExecuteAmbushSpawn(character, isLongRest, playerLevel, pointBudget, duration, ambushTheme, seedEnemy, ambushRoll, spawnOpts)
  -- Re-check region safety at spawn time (player may have moved since queueing)
  local spawnRegion, spawnRaw = EA_GetRegionForCharacter(character)
  if EA_IsCharacterInBlockedSafeZone(character) then
      local safeZoneState = EA_GetSafeZoneState(character)
      local label = table.concat(safeZoneState.activeZones or {}, ", ")
      if label == "" then
          label = "trigger_safe_zone"
      end
      print(string.format("[EnemyAmbush] Spawn cancelled - player in blocked safe zone: %s", tostring(label)))
      return 0
  end
  EA_LogUnknownRegion(spawnRaw, "spawn_execution")
  if spawnRaw and spawnRaw ~= "" and EA_IsRawRegionBlocked(spawnRaw) then
      print(string.format("[EnemyAmbush] Spawn cancelled - player in blocked sublevel: %s", tostring(spawnRaw)))
      return 0
  end
  if EA_IsRegionBlocked(spawnRegion) then
      local policy = EnemyAmbush.REGION_POLICY[spawnRegion]
      local label = (policy and policy.label) or spawnRegion
      print(string.format("[EnemyAmbush] Spawn cancelled - player moved to blocked region: %s (%s)", spawnRegion, label))
      return 0
  end

  local intensity = EA_GetEffectiveAmbushIntensity()
  if EA_IsCXMode and EA_IsCXMode() then
      -- CX already hardens enemies heavily; trim pack size slightly for better pacing.
      intensity = intensity * 0.80
  end
  local baseBudget = pointBudget or 0
  local adjustedBudget = math.floor(baseBudget * intensity + 0.5)

  print(string.format(
      "[EnemyAmbush] Triggering ambush for %s (Level %d) budget=%d (x%.2f => %d) region=%s",
      tostring(character), playerLevel, baseBudget, intensity, adjustedBudget, tostring(spawnRegion)))

  if EA_GetSettingBool("MCM_DebugMode", false) then
      local cxActive = (EA_IsCXMode and EA_IsCXMode()) or false
      DebugPrint(string.format(
          "[Budget-Exec] base=%d intensity=%.2f CX=%s adjusted=%d region=%s",
          baseBudget, intensity, tostring(cxActive), adjustedBudget, tostring(spawnRegion)
      ))
  end

local topTier = EA_NormalizeTierLabel((ambushRoll and (ambushRoll.tier or ambushRoll.category)) or "COMMON")
local leaderSpawned = false
local useCompositionGuards = true
local balanceProfile = "BG3_12"
local presetHidden = EA_NormalizePresetHiddenKnobs()

if type(EA_GetUseCompositionGuards) == "function" then
    useCompositionGuards = (EA_GetUseCompositionGuards() == true)
else
    useCompositionGuards = EA_GetSettingBool("MCM_UseCompositionGuards", true)
end

if type(EA_GetBalanceProfile) == "function" then
    local profile = EA_NormalizeContractValue("MCM_BalanceProfile", EA_GetBalanceProfile() or "BG3_12", "BG3_12")
    if profile == "BG3_12" or profile == "MODDED_20" then
        balanceProfile = profile
    end
else
    local profile = EA_NormalizeContractValue("MCM_BalanceProfile", EA_GetSettingRaw("MCM_BalanceProfile", "BG3_12") or "BG3_12", "BG3_12")
    if profile == "BG3_12" or profile == "MODDED_20" then
        balanceProfile = profile
    end
end

  local function EA_NormalizePowerClass(enemyData)
      local raw = enemyData and enemyData.powerClass
      if raw ~= nil then
          local key = string.upper(tostring(raw))
          if key == "FODDER" or key == "STANDARD" or key == "BRUISER" or key == "DREAD" or key == "APEX" then
              return key
          end
      end

      local lvl = tonumber(enemyData and (
          enemyData.resolvedTemplateLevel
          or enemyData.levelOverride
          or enemyData.templateLevelOverride
          or enemyData.level
      )) or 1
      if lvl >= 12 then return "APEX" end
      if lvl >= 9 then return "DREAD" end
      if lvl >= 6 then return "BRUISER" end
      if lvl >= 3 then return "STANDARD" end
      return "FODDER"
  end

  local function EA_GetPowerClassCapsForLevel(level, tier)
      local pl = tonumber(level) or 1
      if balanceProfile == "BG3_12" and pl > 12 then
          pl = 12
      end
      local t = EA_NormalizeTierLabel(tier)
      local caps = {
          FODDER = 99,
          STANDARD = 99,
          BRUISER = 0,
          DREAD = 0,
          APEX = 0,
      }

      if balanceProfile == "MODDED_20" and pl >= 18 then
          caps.BRUISER = 4
          caps.DREAD = 2
          caps.APEX = 1
      elseif pl >= 15 then
          caps.BRUISER = 3
          caps.DREAD = 2
          caps.APEX = 1
      elseif pl >= 12 then
          caps.BRUISER = 2
          caps.DREAD = 1
          caps.APEX = 0
      elseif pl >= 9 then
          caps.BRUISER = 2
          caps.DREAD = 1
          caps.APEX = 0
      elseif pl >= 5 then
          caps.BRUISER = 1
          caps.DREAD = 0
          caps.APEX = 0
      end

      -- Keep high-tier rolls meaningful in late progression without breaking low-level safety.
      if pl >= 9 then
          if t == "LEGENDARY" then
              caps.DREAD = math.max(caps.DREAD, 1)
          elseif t == "CHAMPION" then
              caps.DREAD = math.max(caps.DREAD, 1)
              caps.APEX = math.max(caps.APEX, 1)
          end
      end

      return caps
  end

  local function EA_ApplyPresetFodderEliteBias(caps, biasKey, tierKey)
      local bias = tostring(biasKey or "BALANCED")
      local tier = EA_NormalizeTierLabel(tierKey)
      if bias == "FODDER_HEAVY" then
          caps.BRUISER = math.max(0, (tonumber(caps.BRUISER) or 0) - 1)
          caps.DREAD = math.max(0, (tonumber(caps.DREAD) or 0) - 1)
          caps.APEX = math.max(0, (tonumber(caps.APEX) or 0) - 1)
      elseif bias == "STRONGER_ENEMY_LEANING" then
          caps.BRUISER = (tonumber(caps.BRUISER) or 0) + 1
          if tier == "ELITE" or tier == "LEGENDARY" then
              caps.DREAD = (tonumber(caps.DREAD) or 0) + 1
          end
      elseif bias == "STRONGEST_ENEMY_LEANING" then
          caps.BRUISER = (tonumber(caps.BRUISER) or 0) + 1
          if tier == "VETERAN" then
              caps.DREAD = math.max(tonumber(caps.DREAD) or 0, 1)
          elseif tier == "ELITE" or tier == "LEGENDARY" then
              caps.DREAD = (tonumber(caps.DREAD) or 0) + 1
          end
      end
      return caps
  end

  local queueStepMode = (type(spawnOpts) == "table" and type(spawnOpts.queueState) == "table")
  local queueState = queueStepMode and spawnOpts.queueState or nil
  local partyProfile = nil
  if type(EA_GetPartyProfile) == "function" then
      local okProfile, outProfile = pcall(EA_GetPartyProfile, character)
      if okProfile and type(outProfile) == "table" then
          partyProfile = outProfile
      end
  end
  local partySizeNow = tonumber((partyProfile and partyProfile.effectivePartySize) or GetPartySize(character)) or 4
  partySizeNow = math.max(1, math.min(12, math.floor(partySizeNow)))
  local rawPartySizeNow = math.max(1, math.min(99, math.floor(tonumber(partyProfile and partyProfile.rawPartySize) or partySizeNow)))
  local realPartyMembersNow = math.max(1, math.min(12, math.floor(tonumber(partyProfile and partyProfile.realPartyMembers) or partySizeNow)))
  local nonPlayerPartyMembersNow = math.max(0, math.min(99, math.floor(tonumber(partyProfile and partyProfile.nonPlayerPartyMembers) or 0)))
  local summonFollowerBonusNow = math.max(0, math.min(12, math.floor(tonumber(partyProfile and partyProfile.summonFollowerBonus) or 0)))
  local levelNow = tonumber(playerLevel) or 1
  levelNow = math.max(1, math.min(20, math.floor(levelNow)))
  local supportTier, supportTierDefault, supportTierFloorReason = EA_GetSupportBaseTier(topTier, presetHidden, levelNow, partySizeNow)
  if supportTierFloorReason and EA_GetSettingBool("MCM_DebugMode", false) then
      DebugPrint(string.format(
          "[TierMix] support floor reason=%s bias=%s top=%s base=%s resolved=%s level=%d party=%d",
          tostring(supportTierFloorReason),
          tostring(presetHidden.tierBias),
          tostring(topTier),
          tostring(supportTierDefault),
          tostring(supportTier),
          levelNow,
          partySizeNow
      ))
  end
  if partySizeNow <= 2 and levelNow <= 2 and topTier ~= "COMMON" then
      DebugPrint(string.format(
          "[TierSafety] ExecuteAmbushSpawn forcing COMMON (level=%d size=%d rolled=%s)",
          levelNow, partySizeNow, tostring(topTier)
      ))
      topTier = "COMMON"
      supportTier = "COMMON"
      if type(ambushRoll) == "table" then
          ambushRoll.tier = "COMMON"
          ambushRoll.category = "COMMON"
      end
  end

  local powerClassCaps = nil
  if queueStepMode and type(queueState.powerClassCaps) == "table" then
      powerClassCaps = queueState.powerClassCaps
  else
      powerClassCaps = EA_GetPowerClassCapsForLevel(playerLevel, topTier)
      powerClassCaps = EA_ApplyPresetFodderEliteBias(powerClassCaps, presetHidden.fodderEliteBias, topTier)
  end
  if not useCompositionGuards then
      powerClassCaps.BRUISER = 99
      powerClassCaps.DREAD = 99
      powerClassCaps.APEX = 99
  end
  local earlyNonFodderMax = nil
  if levelNow <= 2 then
      earlyNonFodderMax = 1
  elseif levelNow <= 4 then
      -- Early game safety:
      -- - levels 3-4 with 1-2 party members: max 1 non-fodder unit
      -- - levels 3-4 with 3+ party members: max 2 non-fodder units
      if partySizeNow >= 3 then
          earlyNonFodderMax = 2
      else
          earlyNonFodderMax = 1
      end
  end
  local powerClassSpawned = {
      FODDER = 0,
      STANDARD = 0,
      BRUISER = 0,
      DREAD = 0,
      APEX = 0,
  }
  if queueStepMode and type(queueState.powerClassSpawned) == "table" then
      local src = queueState.powerClassSpawned
      powerClassSpawned.FODDER = tonumber(src.FODDER) or 0
      powerClassSpawned.STANDARD = tonumber(src.STANDARD) or 0
      powerClassSpawned.BRUISER = tonumber(src.BRUISER) or 0
      powerClassSpawned.DREAD = tonumber(src.DREAD) or 0
      powerClassSpawned.APEX = tonumber(src.APEX) or 0
  end
  local nonFodderSpawned = queueStepMode and (tonumber(queueState.nonFodderSpawned) or 0) or 0
  local powerCapRejects = queueStepMode and (tonumber(queueState.powerCapRejects) or 0) or 0
  local powerCapRelaxSteps = queueStepMode and (tonumber(queueState.powerCapRelaxSteps) or 0) or 0
  local spawnTierCounts = {
      COMMON = 0,
      VETERAN = 0,
      ELITE = 0,
      LEGENDARY = 0,
  }
  if queueStepMode and type(queueState.spawnTierCounts) == "table" then
      local src = queueState.spawnTierCounts
      spawnTierCounts.COMMON = tonumber(src.COMMON) or 0
      spawnTierCounts.VETERAN = tonumber(src.VETERAN) or 0
      spawnTierCounts.ELITE = tonumber(src.ELITE) or 0
      spawnTierCounts.LEGENDARY = tonumber(src.LEGENDARY) or 0
  end

  local function EA_GetSpawnTierCap(tier)
      local key = EA_NormalizeTierLabel(tier)
      if key == "VETERAN" then
          return tonumber(presetHidden.maxVeteran) or 0
      elseif key == "ELITE" then
          return tonumber(presetHidden.maxElite) or 0
      elseif key == "LEGENDARY" then
          return tonumber(presetHidden.maxLegendary) or 0
      end
      return math.huge
  end

  local function EA_RecordSpawnTier(tier)
      local key = EA_NormalizeTierLabel(tier)
      if key == "COMMON" or key == "VETERAN" or key == "ELITE" or key == "LEGENDARY" then
          spawnTierCounts[key] = (tonumber(spawnTierCounts[key]) or 0) + 1
      end
  end

  local function EA_SelectSpawnTierForRole(baseTier, isLeader)
      local normalized = EA_NormalizeTierLabel(baseTier)
      local chain = {}
      if normalized == "COMMON" then
          chain = { "COMMON" }
      elseif isLeader then
          chain = { normalized, EA_DowngradeTier(normalized, 1), EA_DowngradeTier(normalized, 2), "COMMON" }
      elseif normalized == "LEGENDARY" then
          chain = { "ELITE", "VETERAN", "COMMON" }
      elseif normalized == "ELITE" then
          chain = { "ELITE", "VETERAN", "COMMON" }
      elseif normalized == "VETERAN" then
          if presetHidden.fodderEliteBias == "FODDER_HEAVY" then
              chain = { "COMMON" }
          else
              chain = { "VETERAN", "COMMON" }
          end
      else
          chain = { "COMMON" }
      end

      local seen = {}
      for i = 1, #chain do
          local tier = EA_NormalizeTierLabel(chain[i])
          if not seen[tier] then
              seen[tier] = true
              local cap = EA_GetSpawnTierCap(tier)
              local used = tonumber(spawnTierCounts[tier]) or 0
              if cap == math.huge or used < cap then
                  if tier ~= normalized and EA_GetSettingBool("MCM_DebugMode", false) then
                      DebugPrint(string.format(
                          "[TierMix] downgraded role=%s base=%s resolved=%s used[V=%d E=%d L=%d] caps[V=%d E=%d L=%d]",
                          tostring(isLeader and "leader" or "support"),
                          tostring(normalized),
                          tostring(tier),
                          tonumber(spawnTierCounts.VETERAN) or 0,
                          tonumber(spawnTierCounts.ELITE) or 0,
                          tonumber(spawnTierCounts.LEGENDARY) or 0,
                          tonumber(presetHidden.maxVeteran) or 0,
                          tonumber(presetHidden.maxElite) or 0,
                          tonumber(presetHidden.maxLegendary) or 0
                      ))
                  end
                  return tier
              end
          end
      end

      return "COMMON"
  end

  local function EA_PickEnemyTemplateForRole(roleTier, roleTag)
      local tried = {}
      local function tryTier(tier)
          local key = EA_NormalizeTierLabel(tier)
          if tried[key] then
              return nil, nil
          end
          tried[key] = true
          local enemyData = PickEnemyTemplate(character, ambushTheme, key, {
              roleTag = roleTag,
          })
          if enemyData then
              return key, enemyData
          end
          return nil, nil
      end

      local isLeader = (roleTag == "leader")
      local preferred = EA_SelectSpawnTierForRole(roleTier, isLeader)
      local pickedTier, enemyData = tryTier(preferred)
      if enemyData then
          return pickedTier, enemyData
      end

      local fallbackTier = EA_DowngradeTier(preferred, 1)
      pickedTier, enemyData = tryTier(fallbackTier)
      if enemyData then
          return pickedTier, enemyData
      end

      return tryTier("COMMON")
  end

  local function EA_IsPowerClassCapReached(powerClass)
      if not useCompositionGuards then
          return false
      end
      local key = powerClass or "STANDARD"
      local cap = tonumber(powerClassCaps[key])
      local used = tonumber(powerClassSpawned[key]) or 0
      if not cap then
          return false
      end
      return used >= cap
  end

  local function EA_RecordPowerClassSpawn(powerClass)
      local key = powerClass or "STANDARD"
      powerClassSpawned[key] = (tonumber(powerClassSpawned[key]) or 0) + 1
  end

  local function EA_IsEarlyNonFodderCapReached(powerClass)
      if not earlyNonFodderMax then
          return false
      end
      local key = powerClass or "STANDARD"
      if key == "FODDER" then
          return false
      end
      return nonFodderSpawned >= earlyNonFodderMax
  end

  local function EA_RecordEarlyNonFodderSpawn(powerClass)
      if not earlyNonFodderMax then
          return
      end
      local key = powerClass or "STANDARD"
      if key ~= "FODDER" then
          nonFodderSpawned = nonFodderSpawned + 1
      end
  end

  local function EA_TryRelaxPowerClassCaps(reason, currentSpawnedCount, minTargetCount)
      if not useCompositionGuards then
          return false
      end
      if (tonumber(currentSpawnedCount) or 0) >= (tonumber(minTargetCount) or 0) then
          return false
      end

      if powerCapRelaxSteps == 0 then
          powerClassCaps.BRUISER = (tonumber(powerClassCaps.BRUISER) or 0) + 1
      elseif powerCapRelaxSteps == 1 then
          powerClassCaps.DREAD = (tonumber(powerClassCaps.DREAD) or 0) + 1
      elseif powerCapRelaxSteps == 2 then
          powerClassCaps.APEX = (tonumber(powerClassCaps.APEX) or 0) + 1
      else
          return false
      end

      powerCapRelaxSteps = powerCapRelaxSteps + 1
      DebugPrint(string.format(
          "[PowerCaps] relaxed (%s) step=%d caps[B=%d D=%d A=%d]",
          tostring(reason or "retry"),
          powerCapRelaxSteps,
          tonumber(powerClassCaps.BRUISER) or 0,
          tonumber(powerClassCaps.DREAD) or 0,
          tonumber(powerClassCaps.APEX) or 0
      ))
      return true
  end

  
  local configuredCap = tonumber(EA and EA.CFG and EA.CFG.MAX_AMBUSH_ENTITIES) or 6
  configuredCap = math.max(2, math.floor(configuredCap))
  local cap = configuredCap
  local earlySmallPartySpawnCap = nil
  local fodderSwarmCap = queueStepMode and (tonumber(queueState.fodderSwarmCap) or 0) or 0
  local minEnemiesTarget = 2
  local targetAdjustment, baseTargetAdjustment = EA_GetTierTargetAdjustment(topTier, presetHidden, playerLevel, partySizeNow)
  local targetCountPartyBonus = 0
  local configuredCapForDebug = configuredCap
  local capByPartyForDebug = cap
  local capTierShiftForDebug = 0
  do
      local size = tonumber(partySizeNow) or 4
      size = math.max(1, math.min(12, math.floor(size)))

      local level = tonumber(playerLevel) or 1
      level = math.max(1, math.min(20, math.floor(level)))

      cap, capByPartyForDebug, capTierShiftForDebug = EA_GetEntityCapForParty(configuredCap, level, size, topTier)
      targetCountPartyBonus = EA_GetTargetCountPartyBonus(level, size, topTier, presetHidden)

      if level <= 2 then
          if size <= 2 then
              earlySmallPartySpawnCap = 2
          elseif size <= 4 then
              earlySmallPartySpawnCap = 3
          else
              earlySmallPartySpawnCap = 4
          end
      elseif level <= 4 then
          if size <= 2 then
              earlySmallPartySpawnCap = 3
          elseif size == 3 then
              earlySmallPartySpawnCap = 4
          end
      end

      if earlySmallPartySpawnCap then
          cap = math.min(cap, earlySmallPartySpawnCap)
      end

      minEnemiesTarget = size + targetAdjustment + targetCountPartyBonus
      minEnemiesTarget = math.max(2, math.min(minEnemiesTarget, cap))

      if level >= 2 and level <= 4 and size >= 3 then
          minEnemiesTarget = math.max(minEnemiesTarget, 3)
      end

      if earlySmallPartySpawnCap then
          minEnemiesTarget = math.min(minEnemiesTarget, earlySmallPartySpawnCap)
      end

      if fodderSwarmCap and fodderSwarmCap > 0 then
          cap = math.max(cap, fodderSwarmCap)
          minEnemiesTarget = math.max(minEnemiesTarget, fodderSwarmCap)
      end
  end
  if EA_GetSettingBool("MCM_DebugMode", false) and targetAdjustment ~= baseTargetAdjustment then
      DebugPrint(string.format(
          "[TargetPreset] tier=%s bias=%s level=%d party=%d baseAdjustment=%d adjusted=%d",
          tostring(topTier),
          tostring(presetHidden.tierBias),
          tonumber(playerLevel) or 1,
          tonumber(partySizeNow) or 1,
          tonumber(baseTargetAdjustment) or 0,
          tonumber(targetAdjustment) or 0
      ))
  end
  local remainingPoints = queueStepMode and (tonumber(queueState.remainingPoints) or adjustedBudget) or adjustedBudget
  local attempts = queueStepMode and (tonumber(queueState.attempts) or 0) or 0
  local maxAttempts = 20 -- Prevent infinite loops
  local spawnedEnemies = (queueStepMode and type(queueState.spawnedEnemies) == "table" and queueState.spawnedEnemies) or {}
  local firstSpawnType = queueStepMode and queueState.firstSpawnType or nil
  local spentPoints = queueStepMode and (tonumber(queueState.spentPoints) or 0) or 0
  local spawnFailures = queueStepMode and (tonumber(queueState.spawnFailures) or 0) or 0
  local useStagger = false
  local staggerMs = queueStepMode and (tonumber(queueState.staggerMs) or 100) or EA_GetSpawnStaggerMsLive()
  local stopReason = queueStepMode and queueState.stopReason or nil
  local onStaggerDone = nil
  local anchorProcessed = queueStepMode and (queueState.anchorProcessed == true) or false
  leaderSpawned = queueStepMode and (queueState.leaderSpawned == true) or leaderSpawned
  if type(spawnOpts) == "table" then
      if spawnOpts.staggerEnabled ~= nil then
          useStagger = spawnOpts.staggerEnabled == true
      end
      if tonumber(spawnOpts.staggerMs) then
          staggerMs = tonumber(spawnOpts.staggerMs)
      end
      if type(spawnOpts.onComplete) == "function" then
          onStaggerDone = spawnOpts.onComplete
      end
  end
  staggerMs = math.floor(math.max(20, math.min(500, tonumber(staggerMs) or 100)))
  local requestedStagger = (useStagger and onStaggerDone ~= nil and not queueStepMode)
  if queueStepMode then
      useStagger = false
  end
  if requestedStagger and EA_GetSettingBool("MCM_DebugMode", false) then
      DebugPrint("[Spawn] Using non-persistent stagger path (debug/runtime only).")
  end

  local diagRecordId = queueStepMode and queueState.diagRecordId or nil
  if not diagRecordId then
      local flowLabel = nil
      if type(spawnOpts) == "table" and type(spawnOpts.flowLabel) == "string" and spawnOpts.flowLabel ~= "" then
          flowLabel = spawnOpts.flowLabel
      elseif type(ambushRoll) == "table" and type(ambushRoll.flowLabel) == "string" and ambushRoll.flowLabel ~= "" then
          flowLabel = ambushRoll.flowLabel
      else
          flowLabel = isLongRest and "LongRest" or "ShortRest"
      end
      diagRecordId = EA_DiagBeginEncounter({
          ambushId = (type(ambushRoll) == "table" and ambushRoll.ambushId) or nil,
          sourceFlow = flowLabel,
          flowLabel = flowLabel,
          character = character,
          isLongRest = isLongRest == true,
          region = spawnRegion,
          rawRegion = spawnRaw,
          partyLevel = playerLevel,
          partySize = partySizeNow,
          rawPartySize = rawPartySizeNow,
          effectivePartySize = partySizeNow,
          realPartyMembers = realPartyMembersNow,
          nonPlayerPartyMembers = nonPlayerPartyMembersNow,
          summonFollowerBonus = summonFollowerBonusNow,
          requestedTier = topTier,
          requestedTheme = ambushTheme,
          placementMode = EA_GetSpawnPlacementModeKey(),
          baseBudget = baseBudget,
          adjustedBudget = adjustedBudget,
          intensity = intensity,
          balanceProfile = balanceProfile,
          preset = tostring(EA_GetSettingRaw("MCM_DifficultyPreset", "")),
          minEnemiesTarget = minEnemiesTarget,
          entityCap = cap,
          queueStep = queueStepMode == true,
          lastRuntimeReadyReason = (type(spawnOpts) == "table" and spawnOpts.lastRuntimeReadyReason)
              or (type(ambushRoll) == "table" and ambushRoll.lastRuntimeReadyReason)
              or "",
      })
      if queueStepMode and type(queueState) == "table" then
          queueState.diagRecordId = diagRecordId
      end
  end
  if type(ambushRoll) == "table" then
      ambushRoll.diagRecordId = diagRecordId
  end

  if EA_GetSettingBool("MCM_DebugMode", false) then
      DebugPrint(string.format(
          "[Budget-Exec] party=%d tier=%s target=%d cap=%d adjustment=%d",
          partySizeNow, tostring(topTier), minEnemiesTarget, cap, targetAdjustment
      ))
      DebugPrint(string.format(
          "[PartyProfile] raw=%d effective=%d real=%d nonPlayer=%d summonBonus=%d",
          tonumber(rawPartySizeNow) or 1,
          tonumber(partySizeNow) or 1,
          tonumber(realPartyMembersNow) or 1,
          tonumber(nonPlayerPartyMembersNow) or 0,
          tonumber(summonFollowerBonusNow) or 0
      ))
      DebugPrint(string.format(
          "[PartyPressure] level=%d effectiveParty=%d tier=%s targetBonus=%d capBase=%d capParty=%d capShift=%d capFinal=%d",
          tonumber(playerLevel) or 1,
          tonumber(partySizeNow) or 1,
          tostring(topTier),
          tonumber(targetCountPartyBonus) or 0,
          tonumber(configuredCapForDebug) or 0,
          tonumber(capByPartyForDebug) or 0,
          tonumber(capTierShiftForDebug) or 0,
          tonumber(cap) or 0
      ))
      DebugPrint(string.format(
          "[PresetMix] tierBias=%s fodderEliteBias=%s tierCaps[V=%d E=%d L=%d]",
          tostring(presetHidden.tierBias),
          tostring(presetHidden.fodderEliteBias),
          tonumber(presetHidden.maxVeteran) or 0,
          tonumber(presetHidden.maxElite) or 0,
          tonumber(presetHidden.maxLegendary) or 0
      ))
      DebugPrint(string.format(
          "[PowerCaps] enabled=%s profile=%s tier=%s level=%d caps[B=%d D=%d A=%d]",
          tostring(useCompositionGuards),
          tostring(balanceProfile),
          tostring(topTier),
          tonumber(playerLevel) or 1,
          tonumber(powerClassCaps.BRUISER) or 0,
          tonumber(powerClassCaps.DREAD) or 0,
          tonumber(powerClassCaps.APEX) or 0
      ))
      if earlyNonFodderMax then
          DebugPrint(string.format(
              "[EarlyComp] enabled=true level=%d nonFodderMax=%d",
              tonumber(playerLevel) or 1,
              tonumber(earlyNonFodderMax) or 1
          ))
      end
      if earlySmallPartySpawnCap then
          DebugPrint(string.format(
              "[EarlyComp] spawn-count cap active: level=%d party=%d cap=%d",
              tonumber(playerLevel) or 1,
              tonumber(partySizeNow) or 1,
              tonumber(earlySmallPartySpawnCap) or 2
          ))
      end
  end

-- Run-once: AFTER the first successful spawn (not before)
local _EA_FirstSpawnCueDone = queueStepMode and (queueState.firstSpawnCueDone == true) or false
local function EA_OnFirstSpawnCue(spawnedEnemy, creatureType)
    if _EA_FirstSpawnCueDone then return end
    _EA_FirstSpawnCueDone = true

    local tier = topTier
    EA_PlayRegionAmbience(character, tier)                 -- Legendary/Champion only
    EA_PlayPostSpawnBark(spawnedEnemy, creatureType, tier) -- Legendary/Champion only
end
  

  -- Ensure the active list (and template index) is ready
  EA_GetPoolActiveSummonList()

  if (not ambushTheme or ambushTheme == "") and seedEnemy then
      ambushTheme = GetAmbushThemeForEnemy(seedEnemy)
  end

  if (not anchorProcessed) and seedEnemy and ValidateEnemyData(seedEnemy) then
    local seedPowerClass = EA_NormalizePowerClass(seedEnemy)
    if EA_IsEarlyNonFodderCapReached(seedPowerClass) then
        if EA_GetSettingBool("MCM_DebugMode", false) then
            DebugPrint(string.format(
                "[EarlyComp] blocked anchor %s class=%s nonFodder=%d/%d",
                tostring(seedEnemy.name or "Unknown"),
                tostring(seedPowerClass),
                tonumber(nonFodderSpawned) or 0,
                tonumber(earlyNonFodderMax) or 1
            ))
        end
    elseif EA_IsPowerClassCapReached(seedPowerClass) then
        powerCapRejects = powerCapRejects + 1
        DebugPrint(string.format(
            "[PowerCaps] blocked anchor %s class=%s used=%d cap=%d",
            tostring(seedEnemy.name or "Unknown"),
            tostring(seedPowerClass),
            tonumber(powerClassSpawned[seedPowerClass]) or 0,
            tonumber(powerClassCaps[seedPowerClass]) or 0
        ))
    else
        local leaderRoll = EA_CopyRollWithTier(ambushRoll, topTier, "leader")
        local leaderTier = EA_SelectSpawnTierForRole(topTier, true)
        if type(leaderRoll) == "table" then
            leaderRoll.tier = leaderTier
            leaderRoll.category = leaderTier
        end
        if type(leaderRoll) == "table" then
            leaderRoll.ambushTheme = ambushTheme
        end
        local spawnedEnemy = SpawnHostileNearPlayer(character, duration, seedEnemy, leaderRoll, ambushTheme)
        if spawnedEnemy then
            leaderSpawned = true
            if not firstSpawnType or firstSpawnType == "" then
                firstSpawnType = seedEnemy.creatureType
            end
            EA_OnFirstSpawnCue(spawnedEnemy, seedEnemy.creatureType)

            local enemyCost, rawCost = EA_GetEffectiveAmbushTemplateCost(seedEnemy, playerLevel)
            spentPoints = spentPoints + enemyCost
            remainingPoints = math.max(remainingPoints - enemyCost, 0)
            EA_RecordSpawnTier(leaderTier)
            EA_RecordPowerClassSpawn(seedPowerClass)
            EA_RecordEarlyNonFodderSpawn(seedPowerClass)
            if earlySmallPartySpawnCap and earlySmallPartySpawnCap >= 3 and seedPowerClass == "FODDER" and enemyCost <= 1 then
                -- Early fairness: avoid trivial all-fodder ambushes when the active hard cap already allows 3+ bodies.
                fodderSwarmCap = math.max(tonumber(fodderSwarmCap) or 0, 3)
                cap = math.max(cap, fodderSwarmCap)
                minEnemiesTarget = math.max(minEnemiesTarget, fodderSwarmCap)
                if EA_GetSettingBool("MCM_DebugMode", false) then
                    DebugPrint(string.format(
                        "[EarlyComp] fodder swarm compensation active: anchor=%s class=%s cost=%d cap=%d target=%d",
                        tostring(seedEnemy.name or "Unknown"),
                        tostring(seedPowerClass),
                        tonumber(enemyCost) or 0,
                        tonumber(cap) or 0,
                        tonumber(minEnemiesTarget) or 0
                    ))
                end
            end
            table.insert(spawnedEnemies, {name = seedEnemy.name, level = enemyCost, powerClass = seedPowerClass})
              DebugPrint(string.format("Anchor spawn %s (cost: %d, templateLv: %d), remaining points: %d",
                  seedEnemy.name or "Unknown", enemyCost, rawCost, remainingPoints))
          else
              DebugPrint("Anchor spawn failed; not spending budget")
              if EA_GetSpawnPlacementModeKey() == "CREATE_OOS_ONLY" then
                  stopReason = "oos_spawn_failed"
                  EA_DiagRecordEncounterFailure(diagRecordId, stopReason, {
                      ambushId = type(ambushRoll) == "table" and ambushRoll.ambushId or nil,
                      name = seedEnemy and seedEnemy.name or nil,
                      template = seedEnemy and seedEnemy.template or nil,
                  })
                  EA_DiagFinalizeEncounter(diagRecordId, {
                      totalSpawned = #spawnedEnemies,
                      totalCost = spentPoints,
                      adjustedBudget = adjustedBudget,
                      remainingPoints = remainingPoints,
                      attempts = attempts,
                      spawnFailures = spawnFailures + 1,
                      stopReason = stopReason,
                      firstSpawnType = firstSpawnType,
                  })
                  if EA_GetSettingBool("MCM_DebugMode", false) then
                      DebugPrint("[Spawn] CREATE_OOS_ONLY aborting ambush after anchor spawn failure.")
                  end
                  return 0
              end
          end
    end
  end
  anchorProcessed = true
  
  if (not queueStepMode) and #spawnedEnemies >= cap then
    print(string.format("[EnemyAmbush] Entity cap reached (%d). Stopping additional spawns.", cap))
    return #spawnedEnemies
end

  local function EA_RunOneSpawnAttempt()
      attempts = attempts + 1
      if #spawnedEnemies >= minEnemiesTarget then
          local intentionalSwarm = (tonumber(fodderSwarmCap) or 0) > 0
          if partySizeNow <= 3 and not intentionalSwarm then
              stopReason = "small_party_target_met"
              return false
          end
      end

      local baseTierForSpawn = leaderSpawned and supportTier or topTier
      local roleForSpawn = leaderSpawned and "support" or "leader"
      local tierForSpawn, enemyData = EA_PickEnemyTemplateForRole(baseTierForSpawn, roleForSpawn)
      if not enemyData then
          stopReason = "no_valid_payload"
          EA_DiagRecordEncounterFailure(diagRecordId, stopReason, {
              ambushId = type(ambushRoll) == "table" and ambushRoll.ambushId or nil,
              tier = baseTierForSpawn,
              role = roleForSpawn,
          })
          return false
      end

      local enemyPowerClass = EA_NormalizePowerClass(enemyData)
      if EA_IsEarlyNonFodderCapReached(enemyPowerClass) then
          powerCapRejects = 0
          if EA_GetSettingBool("MCM_DebugMode", false) then
              DebugPrint(string.format(
                  "[EarlyComp] rejected %s class=%s nonFodder=%d/%d attempt=%d",
                  tostring(enemyData.name or "Unknown"),
                  tostring(enemyPowerClass),
                  tonumber(nonFodderSpawned) or 0,
                  tonumber(earlyNonFodderMax) or 1,
                  attempts
              ))
          end
          return true
      end

      if EA_IsPowerClassCapReached(enemyPowerClass) then
          powerCapRejects = powerCapRejects + 1
          if EA_GetSettingBool("MCM_DebugMode", false) then
              DebugPrint(string.format(
                  "[PowerCaps] rejected %s class=%s used=%d cap=%d attempt=%d",
                  tostring(enemyData.name or "Unknown"),
                  tostring(enemyPowerClass),
                  tonumber(powerClassSpawned[enemyPowerClass]) or 0,
                  tonumber(powerClassCaps[enemyPowerClass]) or 0,
                  attempts
              ))
          end
          if powerCapRejects >= 4 then
              if EA_TryRelaxPowerClassCaps("retry_exhaustion", #spawnedEnemies, minEnemiesTarget) then
                  powerCapRejects = 0
              end
          end
          return true
      end

      powerCapRejects = 0
      local enemyCost, rawCost = EA_GetEffectiveAmbushTemplateCost(enemyData, playerLevel)
      local canAfford = enemyCost <= remainingPoints
      local shouldSpawnMore = (#spawnedEnemies < minEnemiesTarget)

      if canAfford or shouldSpawnMore then
          local spawnRoll = EA_CopyRollWithTier(ambushRoll, tierForSpawn, roleForSpawn)
          if type(spawnRoll) == "table" then
              spawnRoll.ambushTheme = ambushTheme
          end
          local spawnedEnemy = SpawnHostileNearPlayer(character, duration, enemyData, spawnRoll, ambushTheme)
          if spawnedEnemy then
              if not leaderSpawned then
                  leaderSpawned = true
              end
              if not firstSpawnType or firstSpawnType == "" then
                  firstSpawnType = enemyData.creatureType
              end
              EA_OnFirstSpawnCue(spawnedEnemy, enemyData.creatureType)

              if canAfford then
                  remainingPoints = remainingPoints - enemyCost
                  spentPoints = spentPoints + enemyCost
              elseif EA_GetSettingBool("MCM_DebugMode", false) then
                  DebugPrint(string.format(
                      "[Budget] Spawned %s without budget (minimum enemy count): cost=%d remaining=%d",
                      enemyData.name or "Unknown", enemyCost, remainingPoints
                  ))
              end

              EA_RecordSpawnTier(tierForSpawn)
              EA_RecordPowerClassSpawn(enemyPowerClass)
              EA_RecordEarlyNonFodderSpawn(enemyPowerClass)
              table.insert(spawnedEnemies, {name = enemyData.name, level = enemyCost, powerClass = enemyPowerClass})
              DebugPrint(string.format(
                  "Spawned %s (cost: %d, templateLv: %d), remaining points: %d",
                  enemyData.name or "Unknown", enemyCost, rawCost, remainingPoints
              ))
          else
              spawnFailures = spawnFailures + 1
              EA_DiagRecordEncounterFailure(diagRecordId, "spawn_failed", {
                  ambushId = type(ambushRoll) == "table" and ambushRoll.ambushId or nil,
                  name = enemyData.name,
                  template = enemyData.template,
                  tier = tierForSpawn,
                  role = roleForSpawn,
              })
              DebugPrint("Spawn failed; not spending budget")
          end
          return true
      end

      if remainingPoints <= 0 then
          -- Budget exhausted, stop unless we're below minimum count.
          if #spawnedEnemies >= minEnemiesTarget then
              stopReason = "budget_exhausted_target_met"
              return false
          end
          return true
      end

      -- Can't afford current candidate and minimum count already satisfied.
      stopReason = "target_met_candidate_over_budget"
      return false
  end

  local function EA_FinalizeSpawnExecution()
      local totalSpawned = #spawnedEnemies
      local totalCost = spentPoints

      if totalSpawned > 0 and firstSpawnType and firstSpawnType ~= "" then
          if type(EA_RecordRecentAmbushType) == "function" then
              EA_RecordRecentAmbushType(character, firstSpawnType)
          end
          if type(EA_ConsumeTypePressure) == "function" then
              EA_ConsumeTypePressure(character, firstSpawnType, 20)
          end
      end

      if totalSpawned < minEnemiesTarget then
          print(string.format(
              "[EnemyAmbush] Spawn count below target: %d/%d (attempts=%d, spawnFails=%d, reason=%s)",
              totalSpawned, minEnemiesTarget, attempts, spawnFailures, tostring(stopReason or "unspecified")
          ))
      end

      if EA_GetSettingBool("MCM_DebugMode", false) then
          DebugPrint(string.format(
              "[Budget-Exec] result spawned=%d target=%d spent=%d/%d remaining=%d attempts=%d fails=%d",
              totalSpawned, minEnemiesTarget, totalCost, adjustedBudget, remainingPoints, attempts, spawnFailures
          ))
          DebugPrint(string.format(
              "[PowerCaps] enabled=%s result spawned[F=%d S=%d B=%d D=%d A=%d] caps[B=%d D=%d A=%d] relaxSteps=%d",
              tostring(useCompositionGuards),
              tonumber(powerClassSpawned.FODDER) or 0,
              tonumber(powerClassSpawned.STANDARD) or 0,
              tonumber(powerClassSpawned.BRUISER) or 0,
              tonumber(powerClassSpawned.DREAD) or 0,
              tonumber(powerClassSpawned.APEX) or 0,
              tonumber(powerClassCaps.BRUISER) or 0,
              tonumber(powerClassCaps.DREAD) or 0,
              tonumber(powerClassCaps.APEX) or 0,
              tonumber(powerCapRelaxSteps) or 0
          ))
          DebugPrint(string.format(
              "[TierMix] result tiers[C=%d V=%d E=%d L=%d] caps[V=%d E=%d L=%d]",
              tonumber(spawnTierCounts.COMMON) or 0,
              tonumber(spawnTierCounts.VETERAN) or 0,
              tonumber(spawnTierCounts.ELITE) or 0,
              tonumber(spawnTierCounts.LEGENDARY) or 0,
              tonumber(presetHidden.maxVeteran) or 0,
              tonumber(presetHidden.maxElite) or 0,
              tonumber(presetHidden.maxLegendary) or 0
          ))
          if earlyNonFodderMax then
              DebugPrint(string.format(
                  "[EarlyComp] result nonFodder=%d/%d",
                  tonumber(nonFodderSpawned) or 0,
                  tonumber(earlyNonFodderMax) or 1
              ))
          end
      end

      print(string.format("[EnemyAmbush] Ambush complete: %d enemies spawned, %d/%d points used",
          totalSpawned, totalCost, adjustedBudget))
      EA_DiagFinalizeEncounter(diagRecordId, {
          ambushId = type(ambushRoll) == "table" and ambushRoll.ambushId or nil,
          totalSpawned = totalSpawned,
          totalCost = totalCost,
          adjustedBudget = adjustedBudget,
          remainingPoints = remainingPoints,
          attempts = attempts,
          spawnFailures = spawnFailures,
          stopReason = stopReason,
          firstSpawnType = firstSpawnType,
          minEnemiesTarget = minEnemiesTarget,
          entityCap = cap,
      })
      return totalSpawned
  end

  local function EA_StoreQueueState(done)
      if not queueStepMode or type(queueState) ~= "table" then
          return
      end
      queueState.minEnemiesTarget = tonumber(minEnemiesTarget) or 0
      queueState.entityCap = tonumber(cap) or 0
      queueState.adjustedBudget = tonumber(adjustedBudget) or 0
      queueState.remainingPoints = remainingPoints
      queueState.attempts = attempts
      queueState.spawnedEnemies = spawnedEnemies
      queueState.firstSpawnType = firstSpawnType
      queueState.spentPoints = spentPoints
      queueState.spawnFailures = spawnFailures
      queueState.leaderSpawned = (leaderSpawned == true)
      queueState.anchorProcessed = (anchorProcessed == true)
      queueState.firstSpawnCueDone = (_EA_FirstSpawnCueDone == true)
      queueState.powerClassSpawned = powerClassSpawned
      queueState.powerClassCaps = powerClassCaps
      queueState.nonFodderSpawned = nonFodderSpawned
      queueState.powerCapRejects = powerCapRejects
      queueState.powerCapRelaxSteps = powerCapRelaxSteps
      queueState.spawnTierCounts = spawnTierCounts
      queueState.fodderSwarmCap = tonumber(fodderSwarmCap) or 0
      queueState.diagRecordId = diagRecordId
      queueState.staggerMs = staggerMs
      queueState.stopReason = stopReason
      queueState.done = (done == true)
      queueState.updatedAt = (type(EA_NowMs) == "function" and tonumber(EA_NowMs())) or 0
  end

  if queueStepMode then
      if attempts >= maxAttempts or #spawnedEnemies >= cap then
          if attempts >= maxAttempts then
              stopReason = "max_attempts"
          elseif #spawnedEnemies >= cap then
              stopReason = "entity_cap"
          end
          local total = EA_FinalizeSpawnExecution()
          EA_StoreQueueState(true)
          return total
      end

      local shouldContinue = EA_RunOneSpawnAttempt()
      if (not shouldContinue) or attempts >= maxAttempts or #spawnedEnemies >= cap then
          if attempts >= maxAttempts then
              stopReason = "max_attempts"
          elseif #spawnedEnemies >= cap then
              stopReason = "entity_cap"
          elseif not shouldContinue and not stopReason then
              stopReason = "target_met"
          end
          local total = EA_FinalizeSpawnExecution()
          EA_StoreQueueState(true)
          return total
      end

      EA_StoreQueueState(false)
      return -2
  end

  if useStagger then
      local function EA_RunNextStaggerStep()
          if attempts >= maxAttempts or #spawnedEnemies >= cap then
              if attempts >= maxAttempts then
                  stopReason = "max_attempts"
              elseif #spawnedEnemies >= cap then
                  stopReason = "entity_cap"
              end
              local total = EA_FinalizeSpawnExecution()
              pcall(onStaggerDone, total)
              return
          end

          local shouldContinue = EA_RunOneSpawnAttempt()
          if (not shouldContinue) or attempts >= maxAttempts or #spawnedEnemies >= cap then
              if attempts >= maxAttempts then
                  stopReason = "max_attempts"
              elseif #spawnedEnemies >= cap then
                  stopReason = "entity_cap"
              elseif not shouldContinue and not stopReason then
                  stopReason = "target_met"
              end
              local total = EA_FinalizeSpawnExecution()
              pcall(onStaggerDone, total)
              return
          end

          local jitter = EA_RandIntCompat(0, math.max(0, math.floor(staggerMs * 0.20)))
          Ext.Timer.WaitFor(staggerMs + jitter, EA_RunNextStaggerStep)
      end

      EA_RunNextStaggerStep()
      return -1
  end

  while attempts < maxAttempts and #spawnedEnemies < cap do
      if not EA_RunOneSpawnAttempt() then
          if not stopReason then
              stopReason = "target_met"
          end
          break
      end
  end

  if attempts >= maxAttempts then
      stopReason = "max_attempts"
  elseif #spawnedEnemies >= cap then
      stopReason = "entity_cap"
  elseif not stopReason then
      stopReason = "loop_complete"
  end

  return EA_FinalizeSpawnExecution()
end


    return {
        EA_TIER_ORDER = EA_TIER_ORDER,
        EA_TIER_FROM_INDEX = EA_TIER_FROM_INDEX,
        EA_NormalizeTierLabel = EA_NormalizeTierLabel,
        EA_DowngradeTier = EA_DowngradeTier,
        EA_CopyRollWithTier = EA_CopyRollWithTier,
        EA_GetMinAmbushTemplateCostForPartyLevel = EA_GetMinAmbushTemplateCostForPartyLevel,
        EA_GetEffectiveAmbushTemplateCost = EA_GetEffectiveAmbushTemplateCost,
        ExecuteAmbushSpawn = ExecuteAmbushSpawn,
    }
end
EA.SystemsSpawnExecution = M
return M

