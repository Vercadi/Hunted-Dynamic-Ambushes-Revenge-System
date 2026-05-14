EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

function M.Build(deps)
    deps = deps or {}

    local EnemyAmbush = deps.EnemyAmbush or EA
    local MCMContract = deps.MCMContract or (Ext.Require("EnemyAmbush_MCMContract.lua") or (EA and EA.MCMContract) or {})
    local EnemyData = deps.EnemyData or {}
    local SystemsDataTables = deps.SystemsDataTables or {}
    local DebugPrint = deps.DebugPrint or function() end
    local EA_IsDebugMode = deps.EA_IsDebugMode or function() return false end
    local EA_GetSettingBool = deps.EA_GetSettingBool or function(_, fallback) return fallback == true end
    local EA_GetSettingFromSnapshot = deps.EA_GetSettingFromSnapshot
    if type(EA_GetSettingFromSnapshot) ~= "function" and type(EnemyAmbush) == "table" then
        EA_GetSettingFromSnapshot = EnemyAmbush["EA_GetSettingFromSnapshot"]
    end
    local UpdateMetric = deps.UpdateMetric or function() end
    local EA_RandIntSafe = deps.EA_RandIntSafe or (EA and EA["EA_RandIntSafe"])
    local EA_RandIntCompat = deps.EA_RandIntCompat or function(minVal, maxVal)
        if type(EA_RandIntSafe) == "function" then
            local ok, out = pcall(EA_RandIntSafe, minVal, maxVal)
            if ok and tonumber(out) then
                return tonumber(out)
            end
        end
        local lo = math.floor(tonumber(minVal) or 1)
        local hi = math.floor(tonumber(maxVal) or lo)
        if hi < lo then lo, hi = hi, lo end
        if hi <= lo then
            return lo
        end
        return lo + math.floor((hi - lo) * 0.5)
    end
    local function EA_NormalizeContractValue(id, value, fallback)
        if MCMContract and type(MCMContract.NormalizeValue) == "function" then
            return MCMContract.NormalizeValue(id, value, fallback)
        end
        return fallback
    end
    local EA_NowMs = deps.EA_NowMs or function()
        if Ext and Ext.Utils and Ext.Utils.MonotonicTime then
            local ok, ts = pcall(Ext.Utils.MonotonicTime)
            if ok and tonumber(ts) then
                return tonumber(ts)
            end
        end
        return 0
    end
    local EA_NormalizeUUID = deps.EA_NormalizeUUID or function(v) return v end
    local EA_GetRegionForCharacter = deps.EA_GetRegionForCharacter or function() return "", "" end
    local PlayVFX_OnEntity = deps.PlayVFX_OnEntity or function() end
    local SafeOsiExec = deps.SafeOsiExec or function(fn, ...)
        if type(fn) ~= "function" then
            return false
        end
        local ok = pcall(fn, ...)
        return ok == true
    end
    local StorePendingAmbush = deps.StorePendingAmbush or function() end
    local EffectsDBRuntime = deps.EffectsDBRuntime or {}

    local function TableSize(t)
        if type(t) ~= "table" then
            return 0
        end
        local c = 0
        for _ in pairs(t) do
            c = c + 1
        end
        return c
    end

    local function EA_Clamp(n, lo, hi)
        n = tonumber(n)
        if not n then return lo end
        if n < lo then return lo end
        if n > hi then return hi end
        return n
    end

    local function EA_PickAny(v)
        if type(v) ~= "table" then return v end
        if #v > 0 then
            return v[EA_RandIntCompat(1, #v)]
        end
        return nil
    end

    local function EA_ResolveTierValue(val, tier)
        if val == nil then return nil end
        if type(val) ~= "table" then return val end

        if #val > 0 then
            return val[EA_RandIntCompat(1, #val)]
        end

        local picked = val[tier] or val.COMMON or val.VETERAN or val.ELITE or val.LEGENDARY
        return EA_PickAny(picked)
    end

    local function EA_GetTierFromDelta(delta)
        delta = tonumber(delta) or 0
        if delta >= 4 then return "LEGENDARY" end
        if delta >= 2 then return "ELITE" end
        if delta >= 1 then return "VETERAN" end
        return "COMMON"
    end

    local EA_TIER_TELEGRAPH = {
        VETERAN = "Footsteps-disciplined. Trained.",
        ELITE = "A dangerous presence closes in.",
        LEGENDARY = "Something apex hunts you."
    }

    local function EA_GetWarningDelayMs(tier, spawnDist)
        local base = 1600
        if tier == "VETERAN" then base = 2200 end
        if tier == "ELITE" then base = 3000 end
        if tier == "LEGENDARY" then base = 3800 end

        local dist = tonumber(spawnDist) or 3
        local extra = math.floor(dist * 120)
        return EA_Clamp(base + extra, 1200, 5000)
    end

    local function EA_ParseLocaHandle(rawText)
        if type(rawText) ~= "string" then return nil end
        local s = rawText:match("^%s*(.-)%s*$")
        if not s or s == "" then return nil end
        local full = s:match("^(h[%w]+;%d+)$")
        if full then return full end
        local bare = s:match("^(h[%w]+)$")
        if bare then return bare .. ";1" end
        return nil
    end

    local function EA_LocaHandleNoVersion(rawText)
        if type(rawText) ~= "string" then return nil end
        local s = rawText:match("^%s*(.-)%s*$")
        if not s or s == "" then return nil end
        local bare = s:match("^(h[%w]+);%d+$")
        if bare then return bare end
        bare = s:match("^(h[%w]+)$")
        if bare then return bare end
        return nil
    end

    local function EA_ResolveWarningText(rawText)
        if type(rawText) ~= "string" then return rawText end

        local trimmed = rawText:match("^%s*(.-)%s*$")
        local handle = EA_ParseLocaHandle(trimmed)
        if not handle then
            return rawText
        end

        local probes = {}
        local seen = {}
        local function addProbe(v)
            if not v or v == "" then return end
            if seen[v] then return end
            seen[v] = true
            probes[#probes + 1] = v
        end
        local bareHandle = EA_LocaHandleNoVersion(handle or trimmed or "")

        if bareHandle then addProbe(bareHandle) end
        addProbe(handle)
        if trimmed and trimmed:match("^h[%w]+;%d+$") then addProbe(trimmed) end
        if bareHandle then addProbe(bareHandle .. ";1") end

        for _, probe in ipairs(probes) do
            if Osi and Osi.ResolveTranslatedString then
                local ok, translated = pcall(Osi.ResolveTranslatedString, probe)
                if ok and type(translated) == "string" and translated ~= "" and translated ~= probe and translated ~= handle then
                    return translated
                end
            end

            if Ext and Ext.Loca and Ext.Loca.GetTranslatedString then
                local ok, translated = pcall(Ext.Loca.GetTranslatedString, probe)
                if ok and type(translated) == "string" and translated ~= "" and translated ~= probe and translated ~= handle then
                    return translated
                end
            end
        end

        return rawText
    end

    local function EA_PlaySoundEvent(soundId, target)
        if not soundId or soundId == "" then return end
        if not target or target == "" then return end

        if type(soundId) == "string" and soundId:sub(1, 4) == "VFX_" then
            PlayVFX_OnEntity(target, soundId)
            return
        end

        if Osi and Osi.PlaySound then
            SafeOsiExec(Osi.PlaySound, target, soundId)
        end
    end

    local function EA_TryVoiceBark(barkId, speaker)
        if not barkId or barkId == "" then return false end
        if not speaker or speaker == "" then return false end
        if Osi and Osi.StartVoiceBark then
            return SafeOsiExec(Osi.StartVoiceBark, barkId, speaker)
        end
        return false
    end

    local function EA_TryAnyVoiceBark(barkList, speaker, maxAttempts)
        if type(barkList) ~= "table" or #barkList == 0 then
            return false, nil
        end
        local attempts = math.max(1, math.min(#barkList, math.floor(tonumber(maxAttempts) or #barkList)))
        local used = {}
        local lastTried = nil
        for _ = 1, attempts do
            local barkId = nil
            local guard = 0
            while guard < 32 do
                guard = guard + 1
                local candidate = barkList[EA_RandIntCompat(1, #barkList)]
                if type(candidate) == "string" and candidate ~= "" and not used[candidate] then
                    barkId = candidate
                    break
                end
            end
            if not barkId then
                break
            end
            used[barkId] = true
            lastTried = barkId
            if EA_TryVoiceBark(barkId, speaker) then
                return true, barkId
            end
        end
        return false, lastTried
    end

    local EA_SelectEffectProfileFromDB = nil
    if type(EffectsDBRuntime) == "table" and type(EffectsDBRuntime.SelectEffectProfile) == "function" then
        EA_SelectEffectProfileFromDB = EffectsDBRuntime.SelectEffectProfile
    end

    local function EA_SelectEffectProfile(phase, creatureType, tier, context)
        if type(EA_SelectEffectProfileFromDB) == "function" then
            local ok, out = pcall(EA_SelectEffectProfileFromDB, phase, creatureType, tier, context)
            if ok and type(out) == "table" then
                return out
            end
        end
        return nil
    end

    local function EA_GetArrivalApplyChanceByTier(tier)
        if type(EffectsDBRuntime) == "table" and type(EffectsDBRuntime.GetArrivalApplyChanceByTier) == "function" then
            local ok, out = pcall(EffectsDBRuntime.GetArrivalApplyChanceByTier, tier)
            if ok and tonumber(out) then
                local chance = tonumber(out)
                if chance < 0 then chance = 0 end
                if chance > 1 then chance = 1 end
                return chance
            end
        end
        return 0
    end

    local function EA_GetArrivalCuePolicyStored()
        local raw = "BALANCED"
        if type(EA_GetSettingFromSnapshot) == "function" then
            local ok, out = pcall(EA_GetSettingFromSnapshot, "MCM_ArrivalCuePolicy", raw)
            if ok and type(out) == "string" and out ~= "" then
                raw = out
            end
        end
        return tostring(EA_NormalizeContractValue("MCM_ArrivalCuePolicy", raw, "BALANCED") or "BALANCED")
    end

    local function EA_GetArrivalCueChanceScale()
        -- Chance scaling was removed from the release MCM. Keep this at the
        -- authored tier table value so old hidden settings cannot affect play.
        return 100
    end

    local function EA_GetArrivalCuePolicy()
        local stored = EA_GetArrivalCuePolicyStored()
        local quickTest = EA_GetSettingBool("MCM_QuickTestMode", false)
        if stored ~= "OFF" and quickTest == true then
            return "ALWAYS_ON", stored
        end
        return stored, stored
    end

    local function EA_EvaluateArrivalCue(tier, context)
        local baseChance = EA_GetArrivalApplyChanceByTier(tier)
        local effectivePolicy, storedPolicy = EA_GetArrivalCuePolicy()
        local scalePct = EA_GetArrivalCueChanceScale()
        local decision = {
            tier = tostring(tier or ""),
            policy = effectivePolicy,
            storedPolicy = storedPolicy,
            chanceScale = scalePct,
            baseChance = baseChance,
            scaledChance = 0,
            roll = nil,
            apply = false,
            quickTestForced = (effectivePolicy == "ALWAYS_ON" and storedPolicy ~= "ALWAYS_ON"),
            context = context,
            reason = nil,
        }

        if effectivePolicy == "OFF" then
            decision.reason = "policy_off"
            UpdateMetric("arrivalCueSuppressedByPolicy")
            return decision
        end

        if baseChance <= 0 then
            decision.reason = "no_base_chance"
            UpdateMetric("arrivalCueSuppressedByChance")
            UpdateMetric("arrivalFxSkippedByChance")
            return decision
        end

        if effectivePolicy == "ALWAYS_ON" then
            decision.scaledChance = 1
            decision.apply = true
            decision.reason = "forced_on"
            UpdateMetric("arrivalCueApplied")
            UpdateMetric("arrivalFxApplied")
            return decision
        end

        local scaledChance = baseChance * (scalePct / 100.0)
        if scaledChance < 0 then scaledChance = 0 end
        if scaledChance > 1 then scaledChance = 1 end
        decision.scaledChance = scaledChance
        decision.roll = (EA_RandIntCompat(0, 10000) or 0) / 10000
        UpdateMetric("arrivalCueRolls")
        if decision.roll <= scaledChance then
            decision.apply = true
            decision.reason = "rolled_apply"
            UpdateMetric("arrivalCueApplied")
            UpdateMetric("arrivalFxApplied")
            return decision
        end

        decision.reason = "rolled_skip"
        UpdateMetric("arrivalCueSuppressedByChance")
        UpdateMetric("arrivalFxSkippedByChance")
        return decision
    end

    local function EA_ShouldApplyArrivalCue(tier, context)
        local decision = EA_EvaluateArrivalCue(tier, context)
        return decision.apply == true, decision
    end

    local function EA_SelectArrivalCue(creatureType, tier, context)
        local selected = EA_SelectEffectProfile("ARRIVAL", creatureType, tier, context)
        if type(selected) ~= "table" then
            return nil
        end
        local payload = selected.payload or {}
        return {
            id = selected.id,
            phase = selected.phase,
            tier = selected.tier,
            group = selected.group,
            fallbackUsed = selected.fallbackUsed == true,
            statusId = payload.statusId,
            statusDuration = payload.statusDuration,
            vfx = payload.vfx,
            sfx = payload.sfx,
            bark = payload.bark,
            prepareEffect = payload.prepareEffect,
            castEffect = payload.castEffect,
            spellAnimation = payload.spellAnimation,
            fallbackMode = payload.fallbackMode,
        }
    end

    local function EA_GetEscapeProfileByCreatureType(creatureType, tier, context)
        local selected = EA_SelectEffectProfile("ESCAPE", creatureType, tier, context)
        local payload = (type(selected) == "table" and type(selected.payload) == "table") and selected.payload or {}
        return {
            bonus = tonumber(payload.escapeBonus) or 0,
            statusId = payload.statusId,
            statusDuration = payload.statusDuration,
            vfx = payload.vfx or "b214ce9c-33c2-4dfc-bfc2-3af8e4124714",
            sfx = payload.sfx or "37460014-f738-7e70-11ec-6e8ebfa93cdf",
            fallbackMode = payload.fallbackMode or "misty_step",
            profileId = selected and selected.id or nil,
            fallbackUsed = selected and selected.fallbackUsed or false,
        }
    end

    local EA_DESPAWN_FADE_SOUND = "VFX_Sound_Spell_Impact_Silent"

    local EA_POSTSPAWN_BARK_BY_TYPE = {
        Undead = { "Ghoul_Shout", "FlyingGhoul_Shout" },
        Monstrosity = { "Ettercap_Shout" },
    }

    local function EA_SchedulePostSpawnBark(enemy, creatureType, tier)
        if not enemy or enemy == "" then return end
        if tier ~= "ELITE" and tier ~= "LEGENDARY" and tier ~= "CHAMPION" then return end

        local list = EA_POSTSPAWN_BARK_BY_TYPE[creatureType]
        if not list or #list == 0 then return end

        local bark = EA_PickAny(list)
        if not bark then return end

        Ext.Timer.WaitFor(250, function()
            EA_PlaySoundEvent(bark, enemy)
        end)
    end

    local EA_REGION_AMBIENCE_COOLDOWN_MS = 60000
    EnemyAmbush._lastRegionAmb = EnemyAmbush._lastRegionAmb or {}

    local EA_ENABLE_APPROACH_BEAT = true
    local EA_APPROACH_BEAT_LEAD_MS = 700

    local EA_APPROACH_SOUND_BY_TYPE = SystemsDataTables.APPROACH_SOUND_BY_TYPE or {}
    local EA_TIER_STINGER_BY_TIER = SystemsDataTables.TIER_STINGER_BY_TIER or {}
    local EA_REGION_AMBIENCE = SystemsDataTables.REGION_AMBIENCE or {}

    local function EA_PlayRegionAmbience(player, tier)
        if tier ~= "LEGENDARY" and tier ~= "CHAMPION" then return end
        local region = EA_GetRegionForCharacter(player)
        local entry = EA_REGION_AMBIENCE[region]
        if entry and entry.sound then
            EA_PlaySoundEvent(entry.sound, player)
        end
    end

    local EA_POST_SPAWN_BARK_BY_TYPE = SystemsDataTables.POST_SPAWN_BARK_BY_TYPE or {}

    local function EA_PlayPostSpawnBark(enemy, creatureType, tier)
        if tier ~= "LEGENDARY" and tier ~= "CHAMPION" then return end
        if not enemy or enemy == "" then return end
        if not creatureType or creatureType == "" then return end

        local list = EA_POST_SPAWN_BARK_BY_TYPE[creatureType]
        if not list or #list == 0 then return end

        local bark = EA_PickAny(list)
        EA_TryVoiceBark(bark, enemy)
    end

    local EA_COMBAT_START_BARK_BY_TYPE = SystemsDataTables.COMBAT_START_BARK_BY_TYPE or {}
    local EA_COMBAT_START_FALLBACK_SFX_BY_TIER = SystemsDataTables.COMBAT_START_FALLBACK_SFX_BY_TIER or {}
    local EA_COMBAT_START_CUE_COOLDOWN_MS = 5000
    EnemyAmbush._combatStartCueSeen = EnemyAmbush._combatStartCueSeen or {}
    EnemyAmbush._lastCombatStartCueByPlayer = EnemyAmbush._lastCombatStartCueByPlayer or {}

    local function EA_PruneSeenMap(seenMap, cap)
        if not seenMap then return end
        if TableSize(seenMap) <= (cap or 512) then return end
        local now = EA_NowMs()
        for k, ts in pairs(seenMap) do
            if (now - (tonumber(ts) or now)) > 180000 then
                seenMap[k] = nil
            end
        end
    end

    local function EA_PlayCombatStartVoiceOrSfx(sourceEnemy, player, sourceData, combatGuid)
        if not sourceEnemy or sourceEnemy == "" then return false end

        local seen = EnemyAmbush._combatStartCueSeen
        local perPlayer = EnemyAmbush._lastCombatStartCueByPlayer
        local now = EA_NowMs()
        local ambushId = (type(sourceData) == "table" and tostring(sourceData.ambushId or "")) or ""
        local onceKey = (ambushId ~= "" and ("ambush|" .. ambushId)) or ("combat|" .. tostring(combatGuid or sourceEnemy))

        if seen[onceKey] then
            return false
        end

        local playerKey = EA_NormalizeUUID(player) or tostring(player or "")
        if playerKey ~= "" then
            local last = tonumber(perPlayer[playerKey]) or 0
            if (now - last) < EA_COMBAT_START_CUE_COOLDOWN_MS then
                seen[onceKey] = now
                EA_PruneSeenMap(seen, 1024)
                return false
            end
            perPlayer[playerKey] = now
            EA_PruneSeenMap(perPlayer, 256)
        end

        local creatureType = (type(sourceData) == "table" and sourceData.creatureType) or nil
        local tier = (type(sourceData) == "table" and tostring(sourceData.tier or sourceData.category or "COMMON")) or "COMMON"
        local barkList = nil
        if type(sourceData) == "table" and type(sourceData.combatStartBarks) == "table" and #sourceData.combatStartBarks > 0 then
            barkList = sourceData.combatStartBarks
        else
            barkList = EA_COMBAT_START_BARK_BY_TYPE[creatureType]
        end
        local barkPlayed, barkId = EA_TryAnyVoiceBark(barkList, sourceEnemy, 4)
        if EA_IsDebugMode() then
            DebugPrint("Combat-start bark attempt:", tostring(sourceEnemy), "bark=", tostring(barkId), "played=", tostring(barkPlayed))
        end

        local soundPlayed = false
        local useSoundBackup = false
        local soundList = nil
        if type(sourceData) == "table" and type(sourceData.combatStartSounds) == "table" and #sourceData.combatStartSounds > 0 then
            useSoundBackup = true
            soundList = sourceData.combatStartSounds
        end
        local soundAlways = (type(sourceData) == "table" and sourceData.combatStartSoundAlways == true)
        if useSoundBackup and (soundAlways or (not barkPlayed)) then
            local soundId = EA_PickAny(soundList)
            if soundId and soundId ~= "" then
                EA_PlaySoundEvent(soundId, sourceEnemy or player)
                soundPlayed = true
                if EA_IsDebugMode() then
                    DebugPrint("Combat-start sound backup:", tostring(sourceEnemy), "sound=", tostring(soundId), "always=", tostring(soundAlways))
                end
            end
        end

        if not barkPlayed then
            local skipFallback = (type(sourceData) == "table" and sourceData.combatStartNoFallback == true)
            if not skipFallback then
                local fallback = EA_COMBAT_START_FALLBACK_SFX_BY_TIER[tier]
                    or EA_TIER_STINGER_BY_TIER[tier]
                    or "Set_01_Explo_Light_stinger_01"
                EA_PlaySoundEvent(fallback, sourceEnemy or player)
            elseif EA_IsDebugMode() then
                DebugPrint("Combat-start bark failed and fallback suppressed:", tostring(sourceEnemy), "bark=", tostring(barkId))
            end
        end

        seen[onceKey] = now
        EA_PruneSeenMap(seen, 1024)
        return (barkPlayed or soundPlayed)
    end

    local function EA_GetApproachSound(creatureType)
        local list = EA_APPROACH_SOUND_BY_TYPE[creatureType]
        if not list or #list == 0 then return nil end
        return EA_PickAny(list)
    end

    local function EA_PlayApproachBeatFromData(data)
        if not data then return end
        local player = data.character
        if not player or player == "" then return end

        local approach = EA_GetApproachSound(data.creatureType)
        if approach then EA_PlaySoundEvent(approach, player) end

        if data.tier == "ELITE" or data.tier == "LEGENDARY" or data.tier == "CHAMPION" then
            local stinger = EA_TIER_STINGER_BY_TIER[data.tier]
            if stinger then EA_PlaySoundEvent(stinger, player) end
        end
    end

    local function EA_ScheduleApproachBeat(player, ambushId, creatureType, tier, warningMs)
        if not EA_ENABLE_APPROACH_BEAT then return end

        warningMs = tonumber(warningMs) or 0
        if warningMs <= 0 then return end

        local beatMs = math.max(100, warningMs - EA_APPROACH_BEAT_LEAD_MS)
        if beatMs >= warningMs then return end

        local beatTimer = string.format("EA_AMBUSH_BEAT_%s_%s", player, ambushId)
        local beatData = {
            kind = "BEAT",
            character = player,
            creatureType = creatureType,
            tier = tier,
            ambushId = ambushId,
            warningMs = warningMs,
            beatMs = beatMs,
            timestamp = EA_NowMs(),
        }

        StorePendingAmbush(beatTimer, beatData)
        if Osi and Osi.TimerLaunch then
            Osi.TimerLaunch(beatTimer, beatMs)
        end
    end

    local function EA_TryPlayRegionAmbience(player, region, tier)
        if tier ~= "LEGENDARY" and tier ~= "CHAMPION" then return end
        if not region or region == "" then return end

        for key, payload in pairs(EA_REGION_AMBIENCE) do
            if string.find(region, key, 1, true) then
                local now = EA_NowMs()
                local last = EnemyAmbush._lastRegionAmb[player] or 0
                if (now - last) < EA_REGION_AMBIENCE_COOLDOWN_MS then return end

                EnemyAmbush._lastRegionAmb[player] = now

                if payload.sound then
                    EA_PlaySoundEvent(payload.sound, player)
                end
                if payload.vfx then
                    PlayVFX_OnEntity(player, payload.vfx)
                end
                return
            end
        end
    end

    local EA_WARNING_QUESTMESSAGE_ENABLED = false
    local EA_WARNING_QUESTMESSAGE_EXTRA_MS = 900
    local EA_WARNING_QUESTMESSAGE_MIN_MS = 2200
    local EA_WARNING_QUESTMESSAGE_MAX_MS = 5200

    local function EA_ShouldShowNotificationChannel(channelSettingId)
        -- Retired popup warnings stay unavailable to players until MazzleDocs journal support replaces them.
        if not EA_IsDebugMode() then
            return false
        end
        if not EA_GetSettingBool("MCM_ShowUINotifications", false) then
            return false
        end
        if not channelSettingId or channelSettingId == "" then
            return true
        end
        return EA_GetSettingBool(channelSettingId, true)
    end

    local function EA_ShowTimedWarning(character, text, tier, warningMs, locaKey)
        if not character or character == "" then return false end
        if not text or text == "" then return false end
        if not EA_ShouldShowNotificationChannel("MCM_ShowAmbushWarningNotifications") then
            return false
        end

        local shown = false
        if EA_WARNING_QUESTMESSAGE_ENABLED and Osi and Osi.QuestMessageShow and Osi.QuestMessageHide and locaKey and locaKey ~= "" then
            local nonce = math.floor((Ext and Ext.Utils and Ext.Utils.MonotonicTime and Ext.Utils.MonotonicTime()) or (EA_NowMs() or 0))
            local msgId = string.format("EA_AMB_WARN_%s_%d_%d", tostring(character), nonce, EA_RandIntCompat(1000, 9999))
            local questLocaKey = EA_LocaHandleNoVersion(locaKey) or locaKey
            shown = SafeOsiExec(Osi.QuestMessageShow, msgId, questLocaKey)
            if (not shown) and questLocaKey ~= locaKey then
                shown = SafeOsiExec(Osi.QuestMessageShow, msgId, locaKey)
            end

            if shown then
                local holdMs = EA_Clamp((tonumber(warningMs) or 0) + EA_WARNING_QUESTMESSAGE_EXTRA_MS, EA_WARNING_QUESTMESSAGE_MIN_MS, EA_WARNING_QUESTMESSAGE_MAX_MS)
                if Ext and Ext.Timer and Ext.Timer.WaitFor then
                    Ext.Timer.WaitFor(holdMs, function()
                        SafeOsiExec(Osi.QuestMessageHide, msgId)
                    end)
                else
                    SafeOsiExec(Osi.QuestMessageHide, msgId)
                end
                return true
            end
        end

        if Osi and Osi.ShowNotification then
            return SafeOsiExec(Osi.ShowNotification, character, text)
        end
        return SafeOsiExec(Osi.OpenMessageBox, character, text)
    end

    local EA_AMBUSH_WARNINGS = SystemsDataTables.AMBUSH_WARNINGS or {
        Default = {
            vfx = nil,
            sound = nil,
            textByTier = {
                COMMON = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000001;1" }
            }
        },
        context = {}
    }

    local function ShowAmbushWarning(character, creatureType, tier, spawnDist, warningMs)
        tier = tier or "COMMON"

        local warning = EA_AMBUSH_WARNINGS[creatureType] or EA_AMBUSH_WARNINGS.Default
        local region = EA_GetRegionForCharacter(character)

        local vfx = nil
        local sound = "ae89e287-60cc-031f-a6f4-2640a54b9b50"
        local bark = nil
        local text = nil

        if warning then
            if not text then
                if warning.textByTier then
                    text = EA_ResolveTierValue(warning.textByTier, tier)
                else
                    text = EA_PickAny(warning.text)
                end
            end

            local globalCtx = EA_AMBUSH_WARNINGS.context
            if globalCtx and region ~= "" then
                for contextKey, ctMap in pairs(globalCtx) do
                    if region:find(contextKey, 1, true) then
                        local entry = ctMap and ctMap[creatureType]
                        if entry then
                            local override = EA_ResolveTierValue(entry, tier) or EA_PickAny(entry) or entry
                            if override and override ~= "" then
                                text = override
                            end
                        end
                    end
                end
            end
        end

        local selectedWarningCue = EA_SelectEffectProfile("WARNING", creatureType, tier, { region = region })
        if type(selectedWarningCue) == "table" and type(selectedWarningCue.payload) == "table" then
            local payload = selectedWarningCue.payload
            if payload.vfx ~= nil then
                vfx = payload.vfx
            end
            if payload.sfx ~= nil and payload.sfx ~= "" then
                sound = payload.sfx
            end
            if payload.bark ~= nil and payload.bark ~= "" then
                bark = payload.bark
            end
        end

        local warningTextLoca = EA_ParseLocaHandle(text)
        local rawHadLoca = warningTextLoca ~= nil
        text = EA_ResolveWarningText(text)
        if rawHadLoca and EA_ParseLocaHandle(text) then
            text = nil
        end

        if not text or text == "" then
            local fallbackLoca = "h8a1b2c3dg4e5fg6a7bg8c9dg000000000001;1"
            warningTextLoca = EA_ParseLocaHandle(fallbackLoca)
            text = EA_ResolveWarningText(fallbackLoca)
            if warningTextLoca and EA_ParseLocaHandle(text) then
                text = nil
            end
        end

        if not text or text == "" then
            if EA_IsDebugMode() then
                DebugPrint("Warning text missing localization; skipping notification.")
            end
            return
        end

        if vfx and vfx ~= "" then
            PlayVFX_OnEntity(character, vfx)
        end
        if sound and sound ~= "" then
            EA_PlaySoundEvent(sound, character)
        end
        if bark and bark ~= "" then
            EA_TryVoiceBark(bark, character)
        end
        EA_TryPlayRegionAmbience(character, region, tier)

        EA_ShowTimedWarning(character, text, tier, warningMs, warningTextLoca)
    end

    return {
        EA_Clamp = EA_Clamp,
        EA_PickAny = EA_PickAny,
        EA_ResolveTierValue = EA_ResolveTierValue,
        EA_GetTierFromDelta = EA_GetTierFromDelta,
        EA_GetWarningDelayMs = EA_GetWarningDelayMs,
        EA_ParseLocaHandle = EA_ParseLocaHandle,
        EA_LocaHandleNoVersion = EA_LocaHandleNoVersion,
        EA_ResolveWarningText = EA_ResolveWarningText,
        EA_PlaySoundEvent = EA_PlaySoundEvent,
        EA_TryVoiceBark = EA_TryVoiceBark,
        EA_TryAnyVoiceBark = EA_TryAnyVoiceBark,
        EA_SelectEffectProfile = EA_SelectEffectProfile,
        EA_EvaluateArrivalCue = EA_EvaluateArrivalCue,
        EA_SelectArrivalCue = EA_SelectArrivalCue,
        EA_ShouldApplyArrivalCue = EA_ShouldApplyArrivalCue,
        EA_GetEscapeProfileByCreatureType = EA_GetEscapeProfileByCreatureType,
        EA_SchedulePostSpawnBark = EA_SchedulePostSpawnBark,
        EA_PlayRegionAmbience = EA_PlayRegionAmbience,
        EA_PlayPostSpawnBark = EA_PlayPostSpawnBark,
        EA_PruneSeenMap = EA_PruneSeenMap,
        EA_PlayCombatStartVoiceOrSfx = EA_PlayCombatStartVoiceOrSfx,
        EA_GetApproachSound = EA_GetApproachSound,
        EA_PlayApproachBeatFromData = EA_PlayApproachBeatFromData,
        EA_ScheduleApproachBeat = EA_ScheduleApproachBeat,
        EA_TryPlayRegionAmbience = EA_TryPlayRegionAmbience,
        EA_ShowTimedWarning = EA_ShowTimedWarning,
        ShowAmbushWarning = ShowAmbushWarning,
        EA_DESPAWN_FADE_SOUND = EA_DESPAWN_FADE_SOUND,
        EA_TIER_TELEGRAPH = EA_TIER_TELEGRAPH,
        EA_WARNING_QUESTMESSAGE_ENABLED = EA_WARNING_QUESTMESSAGE_ENABLED,
    }
end

return M
