EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

function M.Build(deps)
    deps = deps or {}
    local EnemyAmbush = deps.EnemyAmbush or EA
    local EA = deps.EA or EnemyAmbush or {}
    local EA_Vars = deps.EA_Vars or function() return {} end
    local EA_IsModVarsContainer = deps.EA_IsModVarsContainer
    local EA_Dirty = deps.EA_Dirty or function() end
    local EA_IsDebugMode = deps.EA_IsDebugMode or function() return false end
    local DebugPrint = deps.DebugPrint or function() end
    local CreatureReputation = deps.CreatureReputation or {}
    local EA_NowMs = deps.EA_NowMs or function() return 0 end
    local EA_LogChampionDiagnostics = deps.EA_LogChampionDiagnostics or function() end
    local EA_GetGuaranteedChampionArmed = deps.EA_GetGuaranteedChampionArmed or function() return nil end
    local EA_SetGuaranteedChampionArmed = deps.EA_SetGuaranteedChampionArmed or function() end
    local GetLocationAppropriateEnemies = deps.GetLocationAppropriateEnemies or function() return {} end
    local GetSpawnChampionNow = deps.GetSpawnChampionNow or function() return deps.SpawnChampionNow end
    local GetResolveChampionSpawnData = deps.GetResolveChampionSpawnData
        or function() return deps.EA_ResolveChampionSpawnData or deps.ResolveChampionSpawnData end
    local EA_CHAMPION_TYPE_COOLDOWN_REST_CYCLES = tonumber(deps.EA_CHAMPION_TYPE_COOLDOWN_REST_CYCLES) or 1

    local runtime = {}
    local EA_GetGuaranteedChampionQueueSafeFn = deps.EA_GetGuaranteedChampionQueueSafeFn
        or (EA and EA["EA_GetGuaranteedChampionQueueSafe"])

    local function EA_GetRestCycleCounter()
        local ok, v = pcall(EA_Vars)
        if not ok or not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(v)) or type(v) == "table")) then
            EnemyAmbush._RestCycleCounterFallback = tonumber(EnemyAmbush._RestCycleCounterFallback) or 0
            return EnemyAmbush._RestCycleCounterFallback
        end
        local current = tonumber(v.EA_RestCycleCounter)
        if current == nil then
            current = tonumber(EnemyAmbush._RestCycleCounterFallback) or 0
            v.EA_RestCycleCounter = current
        end
        EnemyAmbush._RestCycleCounterFallback = current
        return current
    end

    local function EA_ChampionCooldownCycleByType()
        local ok, v = pcall(EA_Vars)
        if not ok or not (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(v)) or type(v) == "table")) then
            EnemyAmbush._ChampionCooldownCycleByTypeFallback = EnemyAmbush._ChampionCooldownCycleByTypeFallback or {}
            return EnemyAmbush._ChampionCooldownCycleByTypeFallback
        end
        if type(v.EA_ChampionCooldownCycleByType) ~= "table" then
            v.EA_ChampionCooldownCycleByType = {}
        end
        return v.EA_ChampionCooldownCycleByType
    end

    local function EA_GetChampionCooldownCycleDelta(creatureType)
        local map = EA_ChampionCooldownCycleByType()
        local currentCycle = tonumber(EA_GetRestCycleCounter()) or 0
        local lastCycle = tonumber(map[creatureType])
        if lastCycle == nil then
            return 999999, currentCycle, 0
        end
        return (currentCycle - lastCycle), currentCycle, lastCycle
    end

    local function EA_CanSpawnChampionForType(creatureType)
        if not creatureType or creatureType == "" then return true end
        if tonumber(EA_CHAMPION_TYPE_COOLDOWN_REST_CYCLES) <= 0 then return true end
        local delta, currentCycle, lastCycle = EA_GetChampionCooldownCycleDelta(creatureType)
        local allowed = delta >= tonumber(EA_CHAMPION_TYPE_COOLDOWN_REST_CYCLES)
        if EA_IsDebugMode() then
            DebugPrint(string.format(
                "Champion cooldown check: type=%s cycle=%s lastCycle=%s delta=%s required=%s allowed=%s",
                tostring(creatureType),
                tostring(currentCycle),
                tostring(lastCycle),
                tostring(delta),
                tostring(EA_CHAMPION_TYPE_COOLDOWN_REST_CYCLES),
                tostring(allowed)
            ))
        end
        return allowed
    end

    local function EA_StampChampionSpawn(creatureType)
        if not creatureType or creatureType == "" then return end
        local cycle = tonumber(EA_GetRestCycleCounter()) or 0
        EA_ChampionCooldownCycleByType()[creatureType] = cycle
        EA_Dirty(true)
    end

    local function EA_IncrementRestCycleCounter(reason)
        local nextCycle = (tonumber(EA_GetRestCycleCounter()) or 0) + 1
        local ok, v = pcall(EA_Vars)
        if ok and (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(v)) or type(v) == "table")) then
            v.EA_RestCycleCounter = nextCycle
        else
            EnemyAmbush._RestCycleCounterFallback = nextCycle
        end
        EA_Dirty(true)
        if EA_IsDebugMode() then
            DebugPrint(string.format("[RestFlow] Rest cycle incremented: cycle=%d reason=%s", nextCycle, tostring(reason or "unspecified")))
        end
        return nextCycle
    end

    local function EA_GetRestCycleCounterValue()
        return tonumber(EA_GetRestCycleCounter()) or 0
    end

    local function EA_ResetChampionCooldowns()
        local ok, v = pcall(EA_Vars)
        if ok and (((type(EA_IsModVarsContainer) == "function" and EA_IsModVarsContainer(v)) or type(v) == "table")) then
            v.EA_ChampionCooldownCycleByType = {}
        end
        EnemyAmbush._ChampionCooldownCycleByTypeFallback = {}
        EA_Dirty(true)
        if EA_IsDebugMode() then
            DebugPrint("Champion cooldowns reset: cleared per-type rest-cycle gate")
        end
    end

    local function EA_GetGuaranteedChampionQueue()
        if type(EA_GetGuaranteedChampionQueueSafeFn) ~= "function" and EA and type(EA["EA_GetGuaranteedChampionQueueSafe"]) == "function" then
            EA_GetGuaranteedChampionQueueSafeFn = EA["EA_GetGuaranteedChampionQueueSafe"]
        end
        if type(EA_GetGuaranteedChampionQueueSafeFn) == "function" then
            local ok, out = pcall(EA_GetGuaranteedChampionQueueSafeFn)
            if ok and type(out) == "table" then
                return out
            end
        end
        return {}
    end

    local function EA_IsLegacyChampionQueueJunkEntry(entry)
        if type(entry) ~= "table" then
            return false
        end
        local kind = tostring(entry.kind or "")
        local reason = tostring(entry.reason or "")
        if reason == "first_world_kill" then
            return true
        end
        if kind ~= "" and kind ~= "CHAMPION_GUARANTEE" then
            return true
        end
        return false
    end

    local function EA_PickGuaranteedChampionType(character)
        local q = EA_GetGuaranteedChampionQueue()
        local bestType = nil
        local bestRep = nil
        local bestTs = nil
        local dirtyQueue = false
        local purgeTypes = nil

        for creatureType, entry in pairs(q) do
            if type(entry) == "table" then
                if EA_IsLegacyChampionQueueJunkEntry(entry) then
                    purgeTypes = purgeTypes or {}
                    purgeTypes[#purgeTypes + 1] = creatureType
                elseif EA_CanSpawnChampionForType(creatureType) then
                    local repScore = entry.repAtSet
                    if repScore == nil then repScore = CreatureReputation[creatureType] or 0 end
                    local ts = entry.ts or 0
                    if bestType == nil or repScore < bestRep or (repScore == bestRep and ts < bestTs) then
                        bestType = creatureType
                        bestRep = repScore
                        bestTs = ts
                    end
                end
            end
        end

        if type(purgeTypes) == "table" and #purgeTypes > 0 then
            for _, creatureType in ipairs(purgeTypes) do
                q[creatureType] = nil
            end
            dirtyQueue = true
            print(string.format(
                "[EnemyAmbush] Removed %d legacy champion-queue junk entr%s from save data.",
                #purgeTypes,
                (#purgeTypes == 1) and "y" or "ies"
            ))
        end

        if dirtyQueue then
            EA_Dirty()
        end

        return bestType
    end

    local function EA_ArmGuaranteedChampion(character)
        local armed = EA_GetGuaranteedChampionArmed()
        if armed then return end

        local creatureType = EA_PickGuaranteedChampionType(character)
        if not creatureType then return end

        local queue = EA_GetGuaranteedChampionQueue()
        local entry = queue[creatureType] or {}
        local armedState = {
            creatureType = creatureType,
            ts = entry.ts or EA_NowMs(),
            repAtSet = entry.repAtSet,
            tries = 0
        }
        if EA_SetGuaranteedChampionArmed(armedState) ~= true then
            EA_LogChampionDiagnostics(
                "Guaranteed champion arm failed: type=%s",
                tostring(creatureType)
            )
            return
        end
        DebugPrint("Guaranteed champion ARMED for:", creatureType)
    end

    local function EA_TrySpawnArmedChampion(player)
        local armed = EA_GetGuaranteedChampionArmed()
        if not armed or not armed.creatureType then
            return false, {
                reason = "none_armed",
                context = "armed_queue",
                pathKind = "forced_or_queued",
            }
        end

        local appropriate = GetLocationAppropriateEnemies(player)
        local okHere = false
        for _, t in ipairs(appropriate or {}) do
            if t == armed.creatureType then okHere = true break end
        end
        if not okHere then
            EA_LogChampionDiagnostics(
                "Armed champion deferred: type=%s not in region-appropriate set [%s]",
                tostring(armed.creatureType),
                tostring(table.concat(appropriate or {}, ","))
            )
            return false, {
                reason = "not_appropriate",
                creatureType = armed.creatureType,
                context = "armed_queue",
                pathKind = "forced_or_queued",
            }
        end

        armed.tries = (armed.tries or 0) + 1
        EA_SetGuaranteedChampionArmed(armed)

        local resolutionContext = {
            context = "armed_queue",
            pathKind = "forced_or_queued",
        }
        local resolveChampionSpawnData = GetResolveChampionSpawnData and GetResolveChampionSpawnData() or nil
        local resolution = nil
        if type(resolveChampionSpawnData) == "function" then
            resolution = resolveChampionSpawnData(player, armed.creatureType, resolutionContext)
        end

        local spawnChampionNow = GetSpawnChampionNow and GetSpawnChampionNow() or nil
        if type(spawnChampionNow) == "function" and spawnChampionNow(player, armed.creatureType, resolution, resolutionContext) then
            local queue = EA_GetGuaranteedChampionQueue()
            queue[armed.creatureType] = nil
            EA_SetGuaranteedChampionArmed(nil)
            EA_Dirty()
            EA_LogChampionDiagnostics(
                "Armed champion spawned: type=%s tries=%d",
                tostring(armed.creatureType),
                tonumber(armed.tries) or 0
            )
            return true, {
                reason = "spawned",
                creatureType = armed.creatureType,
                tries = tonumber(armed.tries) or 0,
                source = type(resolution) == "table" and resolution.source or nil,
                resolveReason = type(resolution) == "table" and resolution.reason or nil,
                providerId = type(resolution) == "table" and resolution.providerId or nil,
                policy = type(resolution) == "table" and resolution.policy or nil,
                champion = type(resolution) == "table" and resolution.champion or nil,
                context = "armed_queue",
                pathKind = "forced_or_queued",
            }
        end

        if armed.tries >= 10 then
            DebugPrint("Guaranteed champion kept failing; disarming for now:", armed.creatureType)
            EA_SetGuaranteedChampionArmed(nil)
            EA_LogChampionDiagnostics(
                "Armed champion disarmed after repeated failures: type=%s tries=%d",
                tostring(armed.creatureType),
                tonumber(armed.tries) or 0
            )
        end

        EA_LogChampionDiagnostics(
            "Armed champion spawn failed: type=%s try=%d",
            tostring(armed.creatureType),
            tonumber(armed.tries) or 0
        )
        return false, {
            reason = (type(resolution) == "table" and resolution.champion) and "spawn_failed" or "no_resolution",
            creatureType = armed.creatureType,
            tries = tonumber(armed.tries) or 0,
            source = type(resolution) == "table" and resolution.source or nil,
            resolveReason = type(resolution) == "table" and resolution.reason or nil,
            providerId = type(resolution) == "table" and resolution.providerId or nil,
            policy = type(resolution) == "table" and resolution.policy or nil,
            champion = type(resolution) == "table" and resolution.champion or nil,
            context = "armed_queue",
            pathKind = "forced_or_queued",
        }
    end

    runtime.EA_GetRestCycleCounter = EA_GetRestCycleCounter
    runtime.EA_ChampionCooldownCycleByType = EA_ChampionCooldownCycleByType
    runtime.EA_GetChampionCooldownCycleDelta = EA_GetChampionCooldownCycleDelta
    runtime.EA_CanSpawnChampionForType = EA_CanSpawnChampionForType
    runtime.EA_StampChampionSpawn = EA_StampChampionSpawn
    runtime.EA_IncrementRestCycleCounter = EA_IncrementRestCycleCounter
    runtime.EA_GetRestCycleCounterValue = EA_GetRestCycleCounterValue
    runtime.EA_ResetChampionCooldowns = EA_ResetChampionCooldowns
    runtime.EA_GetGuaranteedChampionQueue = EA_GetGuaranteedChampionQueue
    runtime.EA_PickGuaranteedChampionType = EA_PickGuaranteedChampionType
    runtime.EA_ArmGuaranteedChampion = EA_ArmGuaranteedChampion
    runtime.EA_TrySpawnArmedChampion = EA_TrySpawnArmedChampion

    return runtime
end

return M
