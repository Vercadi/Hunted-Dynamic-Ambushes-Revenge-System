-- Enemy Ambush Data Module
-- Entrypoint/registration only. Data payloads live in split files.

EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local EnemyData = {}

-- ========= VFX DEFAULTS =========
EnemyData.DEFAULT_SPAWN_VFX = "71859b27-bdda-44c3-8c65-7f142a1a2f60"
EnemyData.DEFAULT_DESPAWN_VFX = "b214ce9c-33c2-4dfc-bfc2-3af8e4124714"

local function EA_TryRequireOptional(path)
    if not (Ext and type(Ext.Require) == "function") then
        return nil
    end
    local ok, result = pcall(Ext.Require, path)
    if ok then
        return result
    end
    return nil
end

-- ========= IMPORT VANILLA DATA =========
local Summons = Ext.Require("EnemyAmbush_Data_Summons_Vanilla.lua") or {}
local Champions = Ext.Require("EnemyAmbush_Data_Champions_Vanilla.lua") or {}
local RawXPCloneMap = EA_TryRequireOptional("Generated/EnemyAmbush_Data_XPCloneMap.lua") or {}

-- Keep exported names stable for systems code.
EnemyData.SummonBands_Vanilla = Summons.Bands or {}
EnemyData.ChampionList_Vanilla = Champions.List or {}
EnemyData.ChampionsByType_Vanilla = Champions.ByType or {}

local function EA_DataLog(message)
    print("[EnemyAmbush][Data] " .. tostring(message))
end

local function EA_ListCount(t)
    local n = 0
    for _ in ipairs(t or {}) do
        n = n + 1
    end
    return n
end

local EA_AUDIT_BAND_ORDER = {
    "COMMON",
    "VETERAN",
    "ELITE",
    "LEGENDARY",
    "CHAMPION_ONLY",
}

local function EA_NormalizeAuditText(text)
    local normalized = string.lower(tostring(text or ""))
    normalized = normalized:gsub("%b()", " ")
    normalized = normalized:gsub("[:/]", " ")
    normalized = normalized:gsub("[^%w%s%-']", " ")
    normalized = normalized:gsub("%s+", " ")
    normalized = normalized:match("^%s*(.-)%s*$") or ""
    return normalized
end

local function EA_GetAuditFamilyKey(entry)
    local normalizedName = EA_NormalizeAuditText(entry and entry.name or "")
    if normalizedName == "" then
        return string.lower(tostring(entry and entry.creatureType or "unknown")) .. ":unnamed"
    end

    local firstToken, secondToken = normalizedName:match("^(%S+)%s+(%S+)")
    firstToken = firstToken or normalizedName

    if normalizedName:find("^animate dead%s+") then
        local rest = normalizedName:gsub("^animate dead%s+", "", 1)
        local token = rest:match("^(%S+)")
        if token and token ~= "" then
            return "animate dead:" .. token
        end
    end

    if normalizedName:find("^ranger'?s companion%s+") then
        local rest = normalizedName:gsub("^ranger'?s companion%s+", "", 1)
        local token = rest:match("^(%S+)")
        if token and token ~= "" then
            return "ranger companion:" .. token
        end
    end

    if normalizedName:find("^shadow%-cursed%s+") then
        local rest = normalizedName:gsub("^shadow%-cursed%s+", "", 1)
        local token = rest:match("^(%S+)")
        if token and token ~= "" then
            return "shadow-cursed:" .. token
        end
    end

    if firstToken == "dark" and secondToken == "justiciar" then
        return "dark justiciar"
    end
    if firstToken == "bhaal" and secondToken == "cultist" then
        return "bhaal cultist"
    end

    return firstToken
end

local function EA_GetAuditBucketRow(bucket, key)
    local normalizedKey = tostring(key or "UNKNOWN")
    local row = bucket[normalizedKey]
    if not row then
        row = {
            key = normalizedKey,
            count = 0,
            weight = 0,
        }
        bucket[normalizedKey] = row
    end
    return row
end

local function EA_GetAuditFamilyRow(bucket, key, entry)
    local row = bucket[key]
    if not row then
        row = {
            key = key,
            count = 0,
            weight = 0,
            sampleName = tostring(entry and entry.name or key),
            powerClasses = {},
            creatureTypes = {},
        }
        bucket[key] = row
    end
    return row
end

local function EA_SortAuditRows(bucket, totalWeight)
    local rows = {}
    for _, row in pairs(bucket or {}) do
        row.sharePct = (tonumber(totalWeight) or 0) > 0 and ((tonumber(row.weight) or 0) / totalWeight) * 100 or 0
        rows[#rows + 1] = row
    end
    table.sort(rows, function(a, b)
        local aWeight = tonumber(a and a.weight) or 0
        local bWeight = tonumber(b and b.weight) or 0
        if aWeight == bWeight then
            return tostring(a and a.key or "") < tostring(b and b.key or "")
        end
        return aWeight > bWeight
    end)
    return rows
end

local function EA_FormatAuditRows(rows, limit, includeCount)
    local parts = {}
    local maxRows = math.min(tonumber(limit) or 0, #rows)
    for i = 1, maxRows do
        local row = rows[i]
        if includeCount then
            parts[#parts + 1] = string.format(
                "%s=%.1f%%(%d)",
                tostring(row and row.key or ""),
                tonumber(row and row.sharePct or 0),
                tonumber(row and row.count or 0)
            )
        else
            parts[#parts + 1] = string.format(
                "%s=%.1f%%",
                tostring(row and row.key or ""),
                tonumber(row and row.sharePct or 0)
            )
        end
    end
    return table.concat(parts, "  ")
end

local function EA_FormatFamilyBreakdown(map, totalWeight, limit)
    local rows = {}
    for key, weight in pairs(map or {}) do
        rows[#rows + 1] = {
            key = key,
            weight = tonumber(weight) or 0,
        }
    end
    table.sort(rows, function(a, b)
        if a.weight == b.weight then
            return tostring(a.key or "") < tostring(b.key or "")
        end
        return a.weight > b.weight
    end)

    local parts = {}
    local maxRows = math.min(tonumber(limit) or 0, #rows)
    local denom = tonumber(totalWeight) or 0
    if denom <= 0 then
        denom = 1
    end
    for i = 1, maxRows do
        local row = rows[i]
        parts[#parts + 1] = string.format(
            "%s=%.1f%%",
            tostring(row.key or ""),
            (tonumber(row.weight) or 0) / denom * 100
        )
    end
    return table.concat(parts, "  ")
end

local function EA_BuildLevelBuckets(entries)
    local buckets = {
        L1_3 = {},
        L4_5 = {},
        L6_9 = {},
    }

    for _, entry in ipairs(entries or {}) do
        local level = tonumber(entry and entry.level) or 1
        if level <= 3 then
            buckets.L1_3[#buckets.L1_3 + 1] = entry
        elseif level <= 5 then
            buckets.L4_5[#buckets.L4_5 + 1] = entry
        else
            buckets.L6_9[#buckets.L6_9 + 1] = entry
        end
    end

    return buckets
end

local function EA_CopyEntry(entry)
    local copy = {}
    for key, value in pairs(entry or {}) do
        copy[key] = value
    end
    if copy.template ~= nil then
        copy.template = string.lower(tostring(copy.template))
    end
    return copy
end

local function EA_NormalizeXPCloneMap(rawMap)
    local normalized = {}
    local count = 0

    if type(rawMap) ~= "table" then
        return normalized, count
    end

    for templateId, row in pairs(rawMap) do
        local key = string.lower(tostring(templateId or ""))
        if key ~= "" and type(row) == "table" then
            local copy = {}
            for field, value in pairs(row) do
                copy[field] = value
            end
            copy.originalTemplate = string.lower(tostring(copy.originalTemplate or key))
            if copy.cloneTemplate ~= nil and tostring(copy.cloneTemplate) ~= "" then
                copy.cloneTemplate = string.lower(tostring(copy.cloneTemplate))
            else
                copy.cloneTemplate = nil
            end
            if copy.originalRewardGuid ~= nil and tostring(copy.originalRewardGuid) == "" then
                copy.originalRewardGuid = nil
            end
            if type(copy.rewardLevels) ~= "table" then
                copy.rewardLevels = {}
            end
            normalized[key] = copy
            count = count + 1
        end
    end

    return normalized, count
end

local normalizedXPCloneMap, xpCloneCount = EA_NormalizeXPCloneMap(RawXPCloneMap)
EnemyData.XPCloneMap = normalizedXPCloneMap or {}
EnemyData.XPCloneCount = tonumber(xpCloneCount) or 0

local function EA_GetXPCloneRecord(templateId)
    local key = string.lower(tostring(templateId or ""))
    if key == "" then
        return nil
    end
    return EnemyData.XPCloneMap[key]
end

local function EA_HasXPCloneCoverage(templateId)
    local row = EA_GetXPCloneRecord(templateId)
    return type(row) == "table" and type(row.cloneTemplate) == "string" and row.cloneTemplate ~= ""
end

local function EA_GetXPCloneTemplate(templateId)
    local row = EA_GetXPCloneRecord(templateId)
    if type(row) == "table" and type(row.cloneTemplate) == "string" and row.cloneTemplate ~= "" then
        return row.cloneTemplate
    end
    return nil
end

EnemyData.GetXPCloneRecord = EA_GetXPCloneRecord
EnemyData.HasXPCloneCoverage = EA_HasXPCloneCoverage
EnemyData.GetXPCloneTemplate = EA_GetXPCloneTemplate
EA.EnemyData = EnemyData
EA["EA_GetXPCloneRecord"] = EA_GetXPCloneRecord
EA["EA_HasXPCloneCoverage"] = EA_HasXPCloneCoverage
EA["EA_GetXPCloneTemplate"] = EA_GetXPCloneTemplate
if EnemyData.XPCloneCount > 0 then
    EA_DataLog(string.format("XP clone map loaded: %d templates", EnemyData.XPCloneCount))
end

local function EA_ProfileKey(entry)
    if type(entry) ~= "table" then
        return ""
    end
    local parts = {}
    for key, value in pairs(entry) do
        if key ~= "weight" and key ~= "name" then
            local normalized = value
            if key == "template" then
                normalized = string.lower(tostring(value or ""))
            end
            parts[#parts + 1] = tostring(key) .. "=" .. tostring(normalized)
        end
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

local function EA_CurateSummonList(entries, verbose)
    local curated = {}
    local byProfile = {}
    local mergedExactCount = 0
    local mergedExactWeight = 0

    for _, entry in ipairs(entries or {}) do
        if type(entry) == "table" then
            local key = EA_ProfileKey(entry)
            local target = (key ~= "" and byProfile[key]) or nil
            if target then
                local addWeight = tonumber(entry.weight) or 1
                target.weight = (tonumber(target.weight) or 1) + addWeight
                mergedExactCount = mergedExactCount + 1
                mergedExactWeight = mergedExactWeight + addWeight
                if verbose then
                    EA_DataLog(string.format(
                        "Merged exact summon profile duplicate: template=%s +weight=%.3f",
                        tostring(target.template or ""),
                        addWeight
                    ))
                end
            else
                local copy = EA_CopyEntry(entry)
                curated[#curated + 1] = copy
                if key ~= "" then
                    byProfile[key] = copy
                end
            end
        end
    end

    return curated, mergedExactCount, mergedExactWeight
end

local curatedSummons, curatedExactMergedCount, curatedExactMergedWeight = EA_CurateSummonList(Summons.List or {}, false)
local curatedBuckets = EA_BuildLevelBuckets(curatedSummons)
EnemyData.SummonList_Vanilla = curatedSummons or {}
EnemyData.SummonBuckets_Vanilla = curatedBuckets or {}
EnemyData.SummonList_L1_3 = (curatedBuckets and curatedBuckets.L1_3) or {}
EnemyData.SummonList_L4_5 = (curatedBuckets and curatedBuckets.L4_5) or {}
EnemyData.SummonList_L6_9 = (curatedBuckets and curatedBuckets.L6_9) or {}
EnemyData.SummonCuratedMergeCount = tonumber(curatedExactMergedCount) or 0
EnemyData.SummonCuratedMergeWeight = tonumber(curatedExactMergedWeight) or 0

local function EA_RunDataAudit(verbose)
    local bands = EnemyData.SummonBands_Vanilla or {}
    local bandCounts = {
        COMMON = EA_ListCount(bands.COMMON),
        VETERAN = EA_ListCount(bands.VETERAN),
        ELITE = EA_ListCount(bands.ELITE),
        LEGENDARY = EA_ListCount(bands.LEGENDARY),
        CHAMPION_ONLY = EA_ListCount(bands.CHAMPION_ONLY),
    }

    local seenByTemplate = {}
    local duplicateCount = 0
    local conflictCount = 0
    local intentionalVariantCount = 0
    local exactDuplicateCount = 0
    local championOnlyInSummon = 0
    local explicitBandCount = 0
    local templateWeightTotals = {}
    local templateEntryCounts = {}
    local totalWeight = 0
    local bandWeightAudit = {}

    for _, entry in ipairs(EnemyData.SummonList_Vanilla or {}) do
        local template = string.lower(tostring(entry and entry.template or ""))
        local entryType = tostring(entry and entry.creatureType or "")
        local entryWeight = tonumber(entry and entry.weight) or 1
        if entryWeight < 0 then
            entryWeight = 0
        end

        if entry and entry.championOnly == true then
            championOnlyInSummon = championOnlyInSummon + 1
        end
        if entry and entry.spawnBand ~= nil and tostring(entry.spawnBand) ~= "" then
            explicitBandCount = explicitBandCount + 1
        end

        if template ~= "" then
            templateWeightTotals[template] = (tonumber(templateWeightTotals[template]) or 0) + entryWeight
            templateEntryCounts[template] = (tonumber(templateEntryCounts[template]) or 0) + 1
            totalWeight = totalWeight + entryWeight
            local prev = seenByTemplate[template]
            if prev then
                duplicateCount = duplicateCount + 1
                local prevType = tostring(prev.creatureType or "")
                local prevBand = tostring(prev.spawnBand or "")
                local entryBand = tostring(entry and entry.spawnBand or "")
                local prevLevel = tonumber(prev.level) or -1
                local entryLevel = tonumber(entry and entry.level) or -1
                local prevStatus = tostring(prev.status or "")
                local entryStatus = tostring(entry and entry.status or "")
                local prevChampionOnly = (prev.championOnly == true)
                local entryChampionOnly = (entry and entry.championOnly == true)
                local sameProfile = (
                    prevType == entryType
                    and prevBand == entryBand
                    and prevLevel == entryLevel
                    and prevStatus == entryStatus
                    and prevChampionOnly == entryChampionOnly
                )

                if prevType ~= "" and entryType ~= "" and prevType ~= entryType then
                    conflictCount = conflictCount + 1
                    if verbose then
                        EA_DataLog(string.format(
                            "Template creatureType conflict: %s (%s vs %s)",
                            template, prevType, entryType
                        ))
                    end
                elseif sameProfile then
                    exactDuplicateCount = exactDuplicateCount + 1
                    if verbose then
                        EA_DataLog(string.format("Template exact duplicate profile: %s", template))
                    end
                else
                    intentionalVariantCount = intentionalVariantCount + 1
                end
            else
                seenByTemplate[template] = entry
            end
        end
    end

    for _, bandName in ipairs(EA_AUDIT_BAND_ORDER) do
        local bandEntries = bands[bandName] or {}
        local bandSummary = {
            name = bandName,
            entryCount = 0,
            totalWeight = 0,
            creatureTypes = {},
            powerClasses = {},
            families = {},
        }

        for _, entry in ipairs(bandEntries) do
            if type(entry) == "table" then
                local entryWeight = tonumber(entry.weight) or 1
                if entryWeight < 0 then
                    entryWeight = 0
                end

                bandSummary.entryCount = bandSummary.entryCount + 1
                bandSummary.totalWeight = bandSummary.totalWeight + entryWeight

                local typeKey = tostring(entry.creatureType or "UNKNOWN")
                local powerClassKey = string.upper(tostring(entry.powerClass or "UNKNOWN"))
                local familyKey = EA_GetAuditFamilyKey(entry)

                local typeRow = EA_GetAuditBucketRow(bandSummary.creatureTypes, typeKey)
                typeRow.count = typeRow.count + 1
                typeRow.weight = typeRow.weight + entryWeight

                local classRow = EA_GetAuditBucketRow(bandSummary.powerClasses, powerClassKey)
                classRow.count = classRow.count + 1
                classRow.weight = classRow.weight + entryWeight

                local familyRow = EA_GetAuditFamilyRow(bandSummary.families, familyKey, entry)
                familyRow.count = familyRow.count + 1
                familyRow.weight = familyRow.weight + entryWeight
                familyRow.powerClasses[powerClassKey] = (tonumber(familyRow.powerClasses[powerClassKey]) or 0) + entryWeight
                familyRow.creatureTypes[typeKey] = (tonumber(familyRow.creatureTypes[typeKey]) or 0) + entryWeight
            end
        end

        bandSummary.creatureTypeRows = EA_SortAuditRows(bandSummary.creatureTypes, bandSummary.totalWeight)
        bandSummary.powerClassRows = EA_SortAuditRows(bandSummary.powerClasses, bandSummary.totalWeight)
        bandSummary.familyRows = EA_SortAuditRows(bandSummary.families, bandSummary.totalWeight)
        bandWeightAudit[bandName] = bandSummary
    end

    local overlapCount = 0
    local championTemplates = {}
    local championSeenByTemplate = {}
    local championDuplicateCount = 0
    local championConflictCount = 0
    local championVariantCount = 0
    for _, c in ipairs(EnemyData.ChampionList_Vanilla or {}) do
        local t = string.lower(tostring(c and c.template or ""))
        if t ~= "" then
            championTemplates[t] = true
            local prev = championSeenByTemplate[t]
            if prev then
                championDuplicateCount = championDuplicateCount + 1
                local prevType = tostring(prev.creatureType or "")
                local curType = tostring(c and c.creatureType or "")
                if prevType ~= "" and curType ~= "" and prevType ~= curType then
                    championConflictCount = championConflictCount + 1
                    if verbose then
                        EA_DataLog(string.format(
                            "Champion template creatureType conflict: %s (%s vs %s)",
                            t, prevType, curType
                        ))
                    end
                else
                    championVariantCount = championVariantCount + 1
                end
            else
                championSeenByTemplate[t] = c
            end
        end
    end
    for template, _ in pairs(seenByTemplate) do
        if championTemplates[template] then
            overlapCount = overlapCount + 1
            if verbose then
                EA_DataLog(string.format("Summon/champion overlap template: %s", template))
            end
        end
    end

    EA_DataLog(string.format(
        "Summon bands (grouped): COMMON=%d VETERAN=%d ELITE=%d LEGENDARY=%d CHAMPION_ONLY=%d",
        bandCounts.COMMON,
        bandCounts.VETERAN,
        bandCounts.ELITE,
        bandCounts.LEGENDARY,
        bandCounts.CHAMPION_ONLY
    ))

    EA_DataLog(string.format(
        "Summon buckets: L1_3=%d L4_5=%d L6_9=%d merged=%d champions=%d",
        #(EnemyData.SummonList_L1_3 or {}),
        #(EnemyData.SummonList_L4_5 or {}),
        #(EnemyData.SummonList_L6_9 or {}),
        #(EnemyData.SummonList_Vanilla or {}),
        #(EnemyData.ChampionList_Vanilla or {})
    ))

    EA_DataLog(string.format(
        "Summon metadata: explicitSpawnBand=%d championOnly=%d overlapWithChampion=%d",
        explicitBandCount,
        championOnlyInSummon,
        overlapCount
    ))

    if championOnlyInSummon > 0 then
        EA_DataLog(string.format(
            "WARNING: summon pool still contains championOnly entries (%d). Champion entries should live only in champion providers.",
            championOnlyInSummon
        ))
    end

    if overlapCount > 0 then
        EA_DataLog(string.format(
            "WARNING: summon pool overlaps champion templates (%d). Champion templates should be champion-provider only.",
            overlapCount
        ))
    end

    if duplicateCount > 0 then
        EA_DataLog(string.format(
            "Summon duplicate templates: %d (intentional_variant=%d exact_profile=%d creatureType_conflicts=%d)",
            duplicateCount,
            intentionalVariantCount,
            exactDuplicateCount,
            conflictCount
        ))
        if conflictCount > 0 or exactDuplicateCount > 0 then
            EA_DataLog(string.format(
                "WARNING: summon duplicate issues detected (exact=%d, conflicts=%d).",
                exactDuplicateCount,
                conflictCount
            ))
        end
    end

    local curatedMergeCount = tonumber(EnemyData.SummonCuratedMergeCount) or 0
    local curatedMergeWeight = tonumber(EnemyData.SummonCuratedMergeWeight) or 0
    if curatedMergeCount > 0 then
        EA_DataLog(string.format(
            "Summon curation merged exact-profile rows: %d (weight_recovered=%.3f)",
            curatedMergeCount,
            curatedMergeWeight
        ))
    end

    if totalWeight > 0 then
        local duplicateWeightRows = {}
        for template, entryCount in pairs(templateEntryCounts) do
            local count = tonumber(entryCount) or 0
            if count > 1 then
                local weight = tonumber(templateWeightTotals[template]) or 0
                duplicateWeightRows[#duplicateWeightRows + 1] = {
                    template = template,
                    count = count,
                    weight = weight,
                    sharePct = (weight / totalWeight) * 100
                }
            end
        end

        if #duplicateWeightRows > 0 then
            table.sort(duplicateWeightRows, function(a, b)
                if a.sharePct == b.sharePct then
                    return tostring(a.template) < tostring(b.template)
                end
                return a.sharePct > b.sharePct
            end)

            local topRow = duplicateWeightRows[1]
            EA_DataLog(string.format(
                "Summon duplicate weight concentration: templates=%d totalWeight=%.3f max=%s(%.2f%%)",
                #duplicateWeightRows,
                totalWeight,
                tostring(topRow and topRow.template or ""),
                tonumber(topRow and topRow.sharePct or 0)
            ))

            if verbose then
                local maxRows = math.min(5, #duplicateWeightRows)
                for i = 1, maxRows do
                    local row = duplicateWeightRows[i]
                    EA_DataLog(string.format(
                        "Duplicate weight #%d: template=%s entries=%d weight=%.3f share=%.2f%%",
                        i,
                        tostring(row.template or ""),
                        tonumber(row.count or 0),
                        tonumber(row.weight or 0),
                        tonumber(row.sharePct or 0)
                    ))
                end
            end

            local concentrationWarnThresholdPct = 5.0
            local concentrationWarningCount = 0
            for _, row in ipairs(duplicateWeightRows) do
                if (tonumber(row.sharePct) or 0) >= concentrationWarnThresholdPct then
                    concentrationWarningCount = concentrationWarningCount + 1
                end
            end
            if concentrationWarningCount > 0 then
                EA_DataLog(string.format(
                    "WARNING: duplicate templates with high pool share: %d (threshold=%.1f%%)",
                    concentrationWarningCount,
                    concentrationWarnThresholdPct
                ))
            end
        end
    end

    for _, bandName in ipairs(EA_AUDIT_BAND_ORDER) do
        local bandSummary = bandWeightAudit[bandName]
        if bandSummary and bandSummary.entryCount > 0 then
            local topFamily = bandSummary.familyRows[1]
            local topType = bandSummary.creatureTypeRows[1]
            local topClass = bandSummary.powerClassRows[1]
            EA_DataLog(string.format(
                "[WeightAudit] %s entries=%d totalWeight=%.3f topFamily=%s(%.2f%%/%d) topType=%s(%.2f%%) topClass=%s(%.2f%%)",
                tostring(bandName),
                tonumber(bandSummary.entryCount) or 0,
                tonumber(bandSummary.totalWeight) or 0,
                tostring(topFamily and topFamily.key or "(none)"),
                tonumber(topFamily and topFamily.sharePct or 0),
                tonumber(topFamily and topFamily.count or 0),
                tostring(topType and topType.key or "(none)"),
                tonumber(topType and topType.sharePct or 0),
                tostring(topClass and topClass.key or "(none)"),
                tonumber(topClass and topClass.sharePct or 0)
            ))

            if verbose then
                EA_DataLog(string.format(
                    "[WeightAudit] %s powerClasses: %s",
                    tostring(bandName),
                    EA_FormatAuditRows(bandSummary.powerClassRows, 5, true)
                ))
                EA_DataLog(string.format(
                    "[WeightAudit] %s creatureTypes: %s",
                    tostring(bandName),
                    EA_FormatAuditRows(bandSummary.creatureTypeRows, 5, true)
                ))
                local familyLimit = math.min(5, #bandSummary.familyRows)
                for i = 1, familyLimit do
                    local familyRow = bandSummary.familyRows[i]
                    EA_DataLog(string.format(
                        "[WeightAudit] %s family #%d: %s entries=%d weight=%.3f share=%.2f%% classes=%s types=%s sample=%s",
                        tostring(bandName),
                        i,
                        tostring(familyRow and familyRow.key or ""),
                        tonumber(familyRow and familyRow.count or 0),
                        tonumber(familyRow and familyRow.weight or 0),
                        tonumber(familyRow and familyRow.sharePct or 0),
                        EA_FormatFamilyBreakdown(familyRow and familyRow.powerClasses or {}, tonumber(familyRow and familyRow.weight or 0), 3),
                        EA_FormatFamilyBreakdown(familyRow and familyRow.creatureTypes or {}, tonumber(familyRow and familyRow.weight or 0), 2),
                        tostring(familyRow and familyRow.sampleName or "")
                    ))
                end
            end
        end
    end

    if championDuplicateCount > 0 then
        EA_DataLog(string.format(
            "Champion duplicate templates: %d (intentional_variant=%d creatureType_conflicts=%d)",
            championDuplicateCount,
            championVariantCount,
            championConflictCount
        ))
        if championConflictCount > 0 then
            EA_DataLog(string.format(
                "WARNING: champion duplicate conflicts detected (%d).",
                championConflictCount
            ))
        end
    end
end

EA.RunDataAudit = EA.RunDataAudit or function(verbose)
    EA_RunDataAudit(verbose == true)
end
EA["EA_RunDataAudit"] = EA.RunDataAudit

-- Startup audit should stay lightweight and independent of MCM load order.
EA_RunDataAudit(false)

-- ========= API PROVIDER REGISTRATION =========
-- Register regular summons as "vanilla"
local _vanillaOpts = {
    priority = 0,
    enabledVar = "MCM_EnableVanillaSummons",
    enabledDefault = true,
}

if EnemyAmbush
    and type(EnemyAmbush.RegisterEnemyProvider) == "function"
    and type(EnemyAmbush.RegisterChampionProvider) == "function"
then
    EnemyAmbush.RegisterEnemyProvider("vanilla", EnemyData.SummonList_Vanilla, _vanillaOpts)
    EnemyAmbush.RegisterChampionProvider("vanilla_champions", EnemyData.ChampionsByType_Vanilla, {
        priority = 0,
        enabledVar = "MCM_EnableVanillaSummons",
    })
else
    print("[EnemyAmbush][Data] Provider registration unavailable (API not initialized). Vanilla providers not registered.")
end

return EnemyData
