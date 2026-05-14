EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

local EffectsDB = {
    VERSION = 1,
    ENUM = {
        PHASE = { ARRIVAL = true, ESCAPE = true, WARNING = true },
        TIER = { COMMON = true, VETERAN = true, ELITE = true, LEGENDARY = true, CHAMPION = true },
        CREATURE_TYPE = {
            Aberration = true, Beast = true, Celestial = true, Construct = true, Dragon = true, Elemental = true, Fey = true,
            Fiend = true, Giant = true, Humanoid = true, Monstrosity = true, Ooze = true, Plant = true, Undead = true,
        },
        GROUP = { ARCANE = true, PREDATOR = true, SHADOW = true, ELDRITCH = true, ELEMENTAL = true },
    },
    CREATURE_TYPE_TO_GROUP = {
        Aberration  = "ELDRITCH",
        Beast       = "PREDATOR",
        Celestial   = "ARCANE",
        Construct   = "ARCANE",
        Dragon      = "ELEMENTAL",
        Elemental   = "ELEMENTAL",
        Fey         = "ARCANE",
        Fiend       = "ELEMENTAL",
        Giant       = "PREDATOR",
        Humanoid    = "ARCANE",
        Monstrosity = "PREDATOR",
        Ooze        = "SHADOW",
        Plant       = "SHADOW",
        Undead      = "SHADOW",
    },
    DEFAULT_PROFILE_ID_BY_PHASE = {
        ARRIVAL = "arrive_misty_step",
        ESCAPE = "escape_dimension_door",
        WARNING = "warn_default",
    },
    PROFILES = {
        arrive_misty_step = {
            id = "arrive_misty_step",
            phase = "ARRIVAL",
            enabled = true,
            allowedGroups = { ARCANE = true, PREDATOR = true, SHADOW = true, ELDRITCH = true, ELEMENTAL = true },
            payload = {
                prepareEffect = "7121a488-7c9a-4ba1-a585-f79aaa77e97c",
                castEffect = "71859b27-bdda-44c3-8c65-7f142a1a2f60",
                spellAnimation = "dd86aa43-8189-4d9f-9a5c-454b5fe4a197,,;,,;39daf365-ec06-49a8-81f3-9032640699d7,,;5c400e93-0266-499c-a2e1-75d53358460f,,;cc5b0caf-3ed1-4711-a50d-11dc3f1fdc6a,,;,,;1715b877-4512-472e-9bd0-fd568a112e90,,;,,;,,",
                statusId = "EA_CUE_ARRIVE_MISTY",
                vfx = "71859b27-bdda-44c3-8c65-7f142a1a2f60",
                sfx = "Spell_Impact_Utility_MistyStep_L1to3",
                fallbackMode = "misty_step",
            },
        },
        arrive_shadow_step = {
            id = "arrive_shadow_step",
            phase = "ARRIVAL",
            enabled = true,
            allowedGroups = { PREDATOR = true, SHADOW = true, ELDRITCH = true },
            payload = {
                castEffect = "52af7a1d-37c8-4ec3-b8d4-6a56b6b4b6bb",
                statusId = "EA_CUE_ARRIVE_SHADOW",
                vfx = "0c0fa825-b0bd-4306-ce79-fa735b90cf99",
                sfx = "Set_01_Explo_Stinger_psy_06",
                fallbackMode = "shadow_step",
            },
        },
        arrive_dimension_door = {
            id = "arrive_dimension_door",
            phase = "ARRIVAL",
            enabled = true,
            allowedGroups = { ARCANE = true, ELEMENTAL = true, ELDRITCH = true, SHADOW = true },
            payload = {
                castEffect = "4d65f0dd-6ad8-4f1d-b1c5-7b4d9e3cfb3f",
                statusId = "EA_CUE_ARRIVE_DIMENSION",
                vfx = "4d65f0dd-6ad8-4f1d-b1c5-7b4d9e3cfb3f",
                sfx = "Set_06_Fight_Stinger_04",
                fallbackMode = "dimension_door",
            },
        },
        arrive_arcane_gate = {
            id = "arrive_arcane_gate",
            phase = "ARRIVAL",
            enabled = true,
            allowedGroups = { ARCANE = true, ELEMENTAL = true },
            payload = {
                castEffect = "518bc78f-57c9-4ea2-99d0-87ac3f6f0d86",
                statusId = "EA_CUE_ARRIVE_ARCANE_GATE",
                vfx = "5ea9dc03-ecb0-4865-a041-1f96f9ce5069",
                sfx = "Spell_Impact_Utility_ArcaneGate_L4",
                fallbackMode = "arcane_gate",
            },
        },
        arrive_feral_burst = {
            id = "arrive_feral_burst",
            phase = "ARRIVAL",
            enabled = true,
            allowedGroups = { PREDATOR = true },
            payload = {
                statusId = "EA_CUE_ARRIVE_FERAL",
                vfx = "2bef4483-2bbf-ef2f-f189-515686dbdbce",
                sfx = "DEN_DruidPet_002_Wolf_Voice_Growl_A",
                fallbackMode = "feral_break",
            },
        },
        arrive_necrotic_rise = {
            id = "arrive_necrotic_rise",
            phase = "ARRIVAL",
            enabled = true,
            allowedGroups = { SHADOW = true },
            payload = {
                statusId = "EA_CUE_ARRIVE_NECROTIC",
                vfx = "d7608877-20e6-483b-28e9-2d73f71ecb29",
                sfx = "Set_07_Explo_Glob_dark_Stinger_01",
                fallbackMode = "grave_rise",
            },
        },
        arrive_psionic_shift = {
            id = "arrive_psionic_shift",
            phase = "ARRIVAL",
            enabled = true,
            allowedGroups = { ELDRITCH = true },
            payload = {
                statusId = "EA_CUE_ARRIVE_PSIONIC",
                vfx = "0c0fa825-b0bd-4306-ce79-fa735b90cf99",
                sfx = "Set_01_Explo_Stinger_psy_06",
                fallbackMode = "psionic_shift",
            },
        },
        arrive_infernal_blink = {
            id = "arrive_infernal_blink",
            phase = "ARRIVAL",
            enabled = true,
            allowedGroups = { ELEMENTAL = true },
            payload = {
                statusId = "EA_CUE_ARRIVE_INFERNAL",
                vfx = "23031a1c-0ccf-73f5-d05e-9fb57c6cc618",
                sfx = "Set_07_Explo_Glob_dark_Stinger_01",
                fallbackMode = "infernal_shift",
            },
        },
        escape_misty_step = {
            id = "escape_misty_step",
            phase = "ESCAPE",
            enabled = true,
            allowedGroups = { ARCANE = true, PREDATOR = true },
            payload = {
                statusId = "EA_CUE_ESCAPE_MISTY",
                vfx = "71859b27-bdda-44c3-8c65-7f142a1a2f60",
                sfx = "37460014-f738-7e70-11ec-6e8ebfa93cdf",
                fallbackMode = "misty_step",
                escapeBonus = 1,
            },
        },
        escape_dimension_door = {
            id = "escape_dimension_door",
            phase = "ESCAPE",
            enabled = true,
            allowedGroups = { ARCANE = true, ELEMENTAL = true, ELDRITCH = true, SHADOW = true },
            payload = {
                statusId = "EA_CUE_ESCAPE_DIMENSION",
                vfx = "b214ce9c-33c2-4dfc-bfc2-3af8e4124714",
                sfx = "Set_06_Fight_Stinger_04",
                fallbackMode = "dimension_door",
                escapeBonus = 1,
            },
        },
        escape_shadow_jaunt = {
            id = "escape_shadow_jaunt",
            phase = "ESCAPE",
            enabled = true,
            allowedGroups = { SHADOW = true, ELDRITCH = true, PREDATOR = true },
            payload = {
                castEffect = "02477f0f-1be2-4dc7-8fd1-0e86da8961ad",
                statusId = "EA_CUE_ESCAPE_SHADOW",
                vfx = "0c0fa825-b0bd-4306-ce79-fa735b90cf99",
                sfx = "Set_01_Explo_Stinger_psy_06",
                fallbackMode = "shadow_jaunt",
                escapeBonus = 2,
            },
        },
        escape_ethereal_jaunt = {
            id = "escape_ethereal_jaunt",
            phase = "ESCAPE",
            enabled = true,
            allowedGroups = { ARCANE = true, ELEMENTAL = true, ELDRITCH = true },
            payload = {
                castEffect = "931dc1d5-fbfe-4d17-88d4-050e7f0c6d50",
                statusId = "EA_CUE_ESCAPE_ETHEREAL",
                vfx = "3a0197d3-3103-8b7a-685b-d3ca16a779da",
                sfx = "Set_01_Explo_Light_stinger_01",
                fallbackMode = "ethereal_jaunt",
                escapeBonus = 1,
            },
        },
        escape_feral_break = {
            id = "escape_feral_break",
            phase = "ESCAPE",
            enabled = true,
            allowedGroups = { PREDATOR = true },
            payload = {
                statusId = "EA_CUE_ESCAPE_FERAL",
                vfx = "2bef4483-2bbf-ef2f-f189-515686dbdbce",
                sfx = "DEN_DruidPet_002_Wolf_Voice_Growl_A",
                fallbackMode = "feral_break",
                escapeBonus = 3,
            },
        },
        escape_grave_fade = {
            id = "escape_grave_fade",
            phase = "ESCAPE",
            enabled = true,
            allowedGroups = { SHADOW = true },
            payload = {
                statusId = "EA_CUE_ESCAPE_GRAVE",
                vfx = "d7608877-20e6-483b-28e9-2d73f71ecb29",
                sfx = "Set_07_Explo_Glob_dark_Stinger_01",
                fallbackMode = "grave_fade",
                escapeBonus = 2,
            },
        },
        escape_infernal_shift = {
            id = "escape_infernal_shift",
            phase = "ESCAPE",
            enabled = true,
            allowedGroups = { ELEMENTAL = true },
            payload = {
                statusId = "EA_CUE_ESCAPE_INFERNAL",
                vfx = "23031a1c-0ccf-73f5-d05e-9fb57c6cc618",
                sfx = "Set_07_Explo_Glob_dark_Stinger_01",
                fallbackMode = "infernal_shift",
                escapeBonus = 1,
            },
        },
        warn_default = {
            id = "warn_default",
            phase = "WARNING",
            enabled = true,
            allowedGroups = { ARCANE = true, PREDATOR = true, SHADOW = true, ELDRITCH = true, ELEMENTAL = true },
            payload = { vfx = nil, sfx = "ae89e287-60cc-031f-a6f4-2640a54b9b50", bark = nil },
        },
        warn_arcane = {
            id = "warn_arcane",
            phase = "WARNING",
            enabled = true,
            allowedGroups = { ARCANE = true },
            payload = { vfx = nil, sfx = "Set_01_Explo_Light_stinger_01", bark = "Player_Races_Voice_Combat_Shout" },
        },
        warn_nature = {
            id = "warn_nature",
            phase = "WARNING",
            enabled = true,
            allowedGroups = { PREDATOR = true },
            payload = { vfx = nil, sfx = "Amb_SV_Forest_QD", bark = "DEN_DruidPet_002_Wolf_Voice_Growl_A" },
        },
        warn_shadow = {
            id = "warn_shadow",
            phase = "WARNING",
            enabled = true,
            allowedGroups = { SHADOW = true },
            payload = { vfx = nil, sfx = "Set_07_Explo_Glob_dark_Stinger_01", bark = "Ghoul_Shout" },
        },
        warn_psionic = {
            id = "warn_psionic",
            phase = "WARNING",
            enabled = true,
            allowedGroups = { ELDRITCH = true },
            payload = { vfx = nil, sfx = "Set_01_Explo_Stinger_psy_06", bark = nil },
        },
        warn_infernal = {
            id = "warn_infernal",
            phase = "WARNING",
            enabled = true,
            allowedGroups = { ELEMENTAL = true },
            payload = { vfx = nil, sfx = "Set_07_Explo_Glob_dark_Stinger_01", bark = nil },
        },
    },
    ROUTING = {
        ARRIVAL = {
            ARCANE = {
                COMMON = { { id = "arrive_misty_step", weight = 65 }, { id = "arrive_shadow_step", weight = 15 }, { id = "arrive_dimension_door", weight = 15 }, { id = "arrive_arcane_gate", weight = 5 } },
                VETERAN = { { id = "arrive_misty_step", weight = 45 }, { id = "arrive_shadow_step", weight = 20 }, { id = "arrive_dimension_door", weight = 25 }, { id = "arrive_arcane_gate", weight = 10 } },
                ELITE = { { id = "arrive_misty_step", weight = 25 }, { id = "arrive_shadow_step", weight = 20 }, { id = "arrive_dimension_door", weight = 35 }, { id = "arrive_arcane_gate", weight = 20 } },
                LEGENDARY = { { id = "arrive_misty_step", weight = 10 }, { id = "arrive_shadow_step", weight = 20 }, { id = "arrive_dimension_door", weight = 35 }, { id = "arrive_arcane_gate", weight = 35 } },
                CHAMPION = { { id = "arrive_shadow_step", weight = 20 }, { id = "arrive_dimension_door", weight = 30 }, { id = "arrive_arcane_gate", weight = 50 } },
            },
            PREDATOR = {
                COMMON = { { id = "arrive_feral_burst", weight = 60 }, { id = "arrive_shadow_step", weight = 20 }, { id = "arrive_misty_step", weight = 20 } },
                VETERAN = { { id = "arrive_feral_burst", weight = 45 }, { id = "arrive_shadow_step", weight = 30 }, { id = "arrive_misty_step", weight = 15 }, { id = "arrive_dimension_door", weight = 10 } },
                ELITE = { { id = "arrive_feral_burst", weight = 25 }, { id = "arrive_shadow_step", weight = 40 }, { id = "arrive_dimension_door", weight = 25 }, { id = "arrive_misty_step", weight = 10 } },
                LEGENDARY = { { id = "arrive_feral_burst", weight = 15 }, { id = "arrive_shadow_step", weight = 40 }, { id = "arrive_dimension_door", weight = 35 }, { id = "arrive_arcane_gate", weight = 10 } },
                CHAMPION = { { id = "arrive_feral_burst", weight = 10 }, { id = "arrive_shadow_step", weight = 35 }, { id = "arrive_dimension_door", weight = 40 }, { id = "arrive_arcane_gate", weight = 15 } },
            },
            SHADOW = {
                COMMON = { { id = "arrive_necrotic_rise", weight = 45 }, { id = "arrive_shadow_step", weight = 35 }, { id = "arrive_misty_step", weight = 20 } },
                VETERAN = { { id = "arrive_necrotic_rise", weight = 45 }, { id = "arrive_shadow_step", weight = 35 }, { id = "arrive_dimension_door", weight = 20 } },
                ELITE = { { id = "arrive_necrotic_rise", weight = 35 }, { id = "arrive_shadow_step", weight = 40 }, { id = "arrive_dimension_door", weight = 25 } },
                LEGENDARY = { { id = "arrive_necrotic_rise", weight = 30 }, { id = "arrive_shadow_step", weight = 35 }, { id = "arrive_dimension_door", weight = 20 }, { id = "arrive_arcane_gate", weight = 15 } },
                CHAMPION = { { id = "arrive_necrotic_rise", weight = 25 }, { id = "arrive_shadow_step", weight = 35 }, { id = "arrive_dimension_door", weight = 25 }, { id = "arrive_arcane_gate", weight = 15 } },
            },
            ELDRITCH = {
                COMMON = { { id = "arrive_psionic_shift", weight = 55 }, { id = "arrive_shadow_step", weight = 25 }, { id = "arrive_misty_step", weight = 20 } },
                VETERAN = { { id = "arrive_psionic_shift", weight = 55 }, { id = "arrive_shadow_step", weight = 20 }, { id = "arrive_dimension_door", weight = 25 } },
                ELITE = { { id = "arrive_psionic_shift", weight = 45 }, { id = "arrive_shadow_step", weight = 20 }, { id = "arrive_dimension_door", weight = 35 } },
                LEGENDARY = { { id = "arrive_psionic_shift", weight = 35 }, { id = "arrive_shadow_step", weight = 15 }, { id = "arrive_dimension_door", weight = 35 }, { id = "arrive_arcane_gate", weight = 15 } },
                CHAMPION = { { id = "arrive_psionic_shift", weight = 30 }, { id = "arrive_shadow_step", weight = 20 }, { id = "arrive_dimension_door", weight = 35 }, { id = "arrive_arcane_gate", weight = 15 } },
            },
            ELEMENTAL = {
                COMMON = { { id = "arrive_infernal_blink", weight = 50 }, { id = "arrive_misty_step", weight = 25 }, { id = "arrive_dimension_door", weight = 25 } },
                VETERAN = { { id = "arrive_infernal_blink", weight = 45 }, { id = "arrive_misty_step", weight = 15 }, { id = "arrive_dimension_door", weight = 30 }, { id = "arrive_arcane_gate", weight = 10 } },
                ELITE = { { id = "arrive_infernal_blink", weight = 35 }, { id = "arrive_dimension_door", weight = 40 }, { id = "arrive_arcane_gate", weight = 25 } },
                LEGENDARY = { { id = "arrive_infernal_blink", weight = 25 }, { id = "arrive_dimension_door", weight = 35 }, { id = "arrive_arcane_gate", weight = 40 } },
                CHAMPION = { { id = "arrive_infernal_blink", weight = 20 }, { id = "arrive_dimension_door", weight = 30 }, { id = "arrive_arcane_gate", weight = 50 } },
            },
        },
        ESCAPE = {
            ARCANE = {
                COMMON = { { id = "escape_misty_step", weight = 65 }, { id = "escape_dimension_door", weight = 20 }, { id = "escape_ethereal_jaunt", weight = 15 } },
                VETERAN = { { id = "escape_misty_step", weight = 45 }, { id = "escape_dimension_door", weight = 30 }, { id = "escape_ethereal_jaunt", weight = 25 } },
                ELITE = { { id = "escape_misty_step", weight = 25 }, { id = "escape_dimension_door", weight = 40 }, { id = "escape_ethereal_jaunt", weight = 35 } },
                LEGENDARY = { { id = "escape_misty_step", weight = 10 }, { id = "escape_dimension_door", weight = 45 }, { id = "escape_ethereal_jaunt", weight = 45 } },
                CHAMPION = { { id = "escape_dimension_door", weight = 50 }, { id = "escape_ethereal_jaunt", weight = 50 } },
            },
            PREDATOR = {
                COMMON = { { id = "escape_feral_break", weight = 60 }, { id = "escape_misty_step", weight = 25 }, { id = "escape_shadow_jaunt", weight = 15 } },
                VETERAN = { { id = "escape_feral_break", weight = 45 }, { id = "escape_shadow_jaunt", weight = 30 }, { id = "escape_misty_step", weight = 25 } },
                ELITE = { { id = "escape_feral_break", weight = 30 }, { id = "escape_shadow_jaunt", weight = 40 }, { id = "escape_misty_step", weight = 30 } },
                LEGENDARY = { { id = "escape_feral_break", weight = 20 }, { id = "escape_shadow_jaunt", weight = 45 }, { id = "escape_dimension_door", weight = 35 } },
                CHAMPION = { { id = "escape_feral_break", weight = 10 }, { id = "escape_shadow_jaunt", weight = 45 }, { id = "escape_dimension_door", weight = 45 } },
            },
            SHADOW = {
                COMMON = { { id = "escape_grave_fade", weight = 55 }, { id = "escape_shadow_jaunt", weight = 30 }, { id = "escape_dimension_door", weight = 15 } },
                VETERAN = { { id = "escape_grave_fade", weight = 50 }, { id = "escape_shadow_jaunt", weight = 35 }, { id = "escape_dimension_door", weight = 15 } },
                ELITE = { { id = "escape_grave_fade", weight = 40 }, { id = "escape_shadow_jaunt", weight = 40 }, { id = "escape_dimension_door", weight = 20 } },
                LEGENDARY = { { id = "escape_grave_fade", weight = 30 }, { id = "escape_shadow_jaunt", weight = 45 }, { id = "escape_dimension_door", weight = 25 } },
                CHAMPION = { { id = "escape_grave_fade", weight = 25 }, { id = "escape_shadow_jaunt", weight = 45 }, { id = "escape_dimension_door", weight = 30 } },
            },
            ELDRITCH = {
                COMMON = { { id = "escape_shadow_jaunt", weight = 50 }, { id = "escape_dimension_door", weight = 30 }, { id = "escape_ethereal_jaunt", weight = 20 } },
                VETERAN = { { id = "escape_shadow_jaunt", weight = 45 }, { id = "escape_dimension_door", weight = 30 }, { id = "escape_ethereal_jaunt", weight = 25 } },
                ELITE = { { id = "escape_shadow_jaunt", weight = 35 }, { id = "escape_dimension_door", weight = 35 }, { id = "escape_ethereal_jaunt", weight = 30 } },
                LEGENDARY = { { id = "escape_shadow_jaunt", weight = 30 }, { id = "escape_dimension_door", weight = 35 }, { id = "escape_ethereal_jaunt", weight = 35 } },
                CHAMPION = { { id = "escape_shadow_jaunt", weight = 25 }, { id = "escape_dimension_door", weight = 40 }, { id = "escape_ethereal_jaunt", weight = 35 } },
            },
            ELEMENTAL = {
                COMMON = { { id = "escape_infernal_shift", weight = 55 }, { id = "escape_dimension_door", weight = 30 }, { id = "escape_ethereal_jaunt", weight = 15 } },
                VETERAN = { { id = "escape_infernal_shift", weight = 50 }, { id = "escape_dimension_door", weight = 30 }, { id = "escape_ethereal_jaunt", weight = 20 } },
                ELITE = { { id = "escape_infernal_shift", weight = 40 }, { id = "escape_dimension_door", weight = 35 }, { id = "escape_ethereal_jaunt", weight = 25 } },
                LEGENDARY = { { id = "escape_infernal_shift", weight = 30 }, { id = "escape_dimension_door", weight = 40 }, { id = "escape_ethereal_jaunt", weight = 30 } },
                CHAMPION = { { id = "escape_infernal_shift", weight = 25 }, { id = "escape_dimension_door", weight = 40 }, { id = "escape_ethereal_jaunt", weight = 35 } },
            },
        },
        WARNING = {
            ARCANE = {
                COMMON = { { id = "warn_default", weight = 40 }, { id = "warn_arcane", weight = 60 } },
                VETERAN = { { id = "warn_default", weight = 30 }, { id = "warn_arcane", weight = 70 } },
                ELITE = { { id = "warn_default", weight = 20 }, { id = "warn_arcane", weight = 80 } },
                LEGENDARY = { { id = "warn_default", weight = 10 }, { id = "warn_arcane", weight = 90 } },
                CHAMPION = { { id = "warn_arcane", weight = 100 } },
            },
            PREDATOR = {
                COMMON = { { id = "warn_default", weight = 35 }, { id = "warn_nature", weight = 65 } },
                VETERAN = { { id = "warn_default", weight = 25 }, { id = "warn_nature", weight = 75 } },
                ELITE = { { id = "warn_default", weight = 20 }, { id = "warn_nature", weight = 80 } },
                LEGENDARY = { { id = "warn_default", weight = 10 }, { id = "warn_nature", weight = 90 } },
                CHAMPION = { { id = "warn_nature", weight = 100 } },
            },
            SHADOW = {
                COMMON = { { id = "warn_default", weight = 30 }, { id = "warn_shadow", weight = 70 } },
                VETERAN = { { id = "warn_default", weight = 20 }, { id = "warn_shadow", weight = 80 } },
                ELITE = { { id = "warn_default", weight = 15 }, { id = "warn_shadow", weight = 85 } },
                LEGENDARY = { { id = "warn_default", weight = 10 }, { id = "warn_shadow", weight = 90 } },
                CHAMPION = { { id = "warn_shadow", weight = 100 } },
            },
            ELDRITCH = {
                COMMON = { { id = "warn_default", weight = 30 }, { id = "warn_psionic", weight = 70 } },
                VETERAN = { { id = "warn_default", weight = 20 }, { id = "warn_psionic", weight = 80 } },
                ELITE = { { id = "warn_default", weight = 15 }, { id = "warn_psionic", weight = 85 } },
                LEGENDARY = { { id = "warn_default", weight = 10 }, { id = "warn_psionic", weight = 90 } },
                CHAMPION = { { id = "warn_psionic", weight = 100 } },
            },
            ELEMENTAL = {
                COMMON = { { id = "warn_default", weight = 30 }, { id = "warn_infernal", weight = 70 } },
                VETERAN = { { id = "warn_default", weight = 20 }, { id = "warn_infernal", weight = 80 } },
                ELITE = { { id = "warn_default", weight = 15 }, { id = "warn_infernal", weight = 85 } },
                LEGENDARY = { { id = "warn_default", weight = 10 }, { id = "warn_infernal", weight = 90 } },
                CHAMPION = { { id = "warn_infernal", weight = 100 } },
            },
        },
    },
    ARRIVAL_APPLY_CHANCE_BY_TIER = { COMMON = 0.35, VETERAN = 0.45, ELITE = 0.60, LEGENDARY = 0.75, CHAMPION = 0.90 },
}

local function CloneTable(src)
    if type(src) ~= "table" then
        return src
    end
    local out = {}
    for k, v in pairs(src) do
        out[k] = v
    end
    return out
end

local function NormalizePhase(phase)
    local p = string.upper(tostring(phase or ""))
    if not EffectsDB.ENUM.PHASE[p] then
        return "ARRIVAL"
    end
    return p
end

local function NormalizeTier(tier)
    local t = string.upper(tostring(tier or "COMMON"))
    if not EffectsDB.ENUM.TIER[t] then
        return "COMMON"
    end
    return t
end

local function ResolveGroup(creatureType)
    local key = tostring(creatureType or "")
    local group = EffectsDB.CREATURE_TYPE_TO_GROUP[key]
    if EffectsDB.ENUM.GROUP[group] then
        return group
    end
    return "ARCANE"
end

local function BuildWeightPool(routeList, group, updateMetric)
    if type(routeList) ~= "table" then
        return {}
    end
    local pool = {}
    for _, row in ipairs(routeList) do
        local id = tostring(row and row.id or "")
        local weight = tonumber(row and row.weight) or 0
        local profile = EffectsDB.PROFILES[id]
        local valid = true
        if id == "" or type(profile) ~= "table" then
            valid = false
        elseif profile.enabled ~= true then
            valid = false
        elseif type(profile.allowedGroups) ~= "table" or profile.allowedGroups[group] ~= true then
            valid = false
        elseif weight <= 0 then
            valid = false
        end
        if valid then
            pool[#pool + 1] = { profile = profile, weight = weight }
        elseif type(updateMetric) == "function" then
            updateMetric("effectsProfileInvalidFiltered")
        end
    end
    return pool
end

local function PickWeighted(pool, randIntFn)
    if type(pool) ~= "table" or #pool == 0 then
        return nil
    end
    local total = 0
    for _, row in ipairs(pool) do
        total = total + (tonumber(row.weight) or 0)
    end
    if total <= 0 then
        return nil
    end
    local pick = randIntFn(1, total)
    local cursor = 0
    for _, row in ipairs(pool) do
        cursor = cursor + (tonumber(row.weight) or 0)
        if pick <= cursor then
            return row.profile
        end
    end
    return pool[#pool].profile
end

local function ValidateEffectsDB(debugPrint)
    local errors = 0
    local warnings = 0
    local function warn(msg)
        warnings = warnings + 1
        if type(debugPrint) == "function" then
            debugPrint("[EffectsDB] " .. tostring(msg))
        end
    end
    local function err(msg)
        errors = errors + 1
        if type(debugPrint) == "function" then
            debugPrint("[EffectsDB][ERROR] " .. tostring(msg))
        end
    end

    for phase, defaultId in pairs(EffectsDB.DEFAULT_PROFILE_ID_BY_PHASE) do
        local p = EffectsDB.PROFILES[defaultId]
        if type(p) ~= "table" then
            err("Missing default profile for phase " .. tostring(phase) .. ": " .. tostring(defaultId))
        elseif p.phase ~= phase then
            warn("Default profile phase mismatch: " .. tostring(defaultId))
        end
    end

    for phase, groups in pairs(EffectsDB.ROUTING) do
        if not EffectsDB.ENUM.PHASE[phase] then
            warn("Unknown phase routing key: " .. tostring(phase))
        end
        for group, tiers in pairs(groups) do
            if not EffectsDB.ENUM.GROUP[group] then
                warn("Unknown group routing key: " .. tostring(group))
            end
            for tier, rows in pairs(tiers) do
                if not EffectsDB.ENUM.TIER[tier] then
                    warn("Unknown tier routing key: " .. tostring(tier))
                end
                if type(rows) ~= "table" or #rows == 0 then
                    warn("Empty route list: " .. tostring(phase) .. "/" .. tostring(group) .. "/" .. tostring(tier))
                end
                for _, row in ipairs(rows or {}) do
                    local id = tostring(row and row.id or "")
                    local weight = tonumber(row and row.weight) or 0
                    if type(EffectsDB.PROFILES[id]) ~= "table" then
                        err("Route references missing profile: " .. tostring(id))
                    end
                    if weight <= 0 then
                        err("Route has non-positive weight: " .. tostring(phase) .. "/" .. tostring(group) .. "/" .. tostring(tier) .. " -> " .. tostring(id))
                    end
                end
            end
        end
    end

    for creatureType, group in pairs(EffectsDB.CREATURE_TYPE_TO_GROUP) do
        if not EffectsDB.ENUM.CREATURE_TYPE[creatureType] then
            warn("Unknown creature-type mapping key: " .. tostring(creatureType))
        end
        if not EffectsDB.ENUM.GROUP[group] then
            err("Invalid group mapping for " .. tostring(creatureType) .. ": " .. tostring(group))
        end
    end

    return errors == 0, errors, warnings
end

function M.Build(deps)
    deps = deps or {}

    local DebugPrint = deps.DebugPrint or function() end
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
        if hi <= lo then return lo end
        return lo + math.floor((hi - lo) * 0.5)
    end

    if M._validated ~= true then
        local ok, errors, warnings = ValidateEffectsDB(function(msg)
            DebugPrint(msg)
        end)
        if not ok then
            print(string.format("[EnemyAmbush][EffectsDB] Validation failed: errors=%s warnings=%s", tostring(errors), tostring(warnings)))
        else
            print(string.format("[EnemyAmbush][EffectsDB] Validation OK: warnings=%s", tostring(warnings)))
        end
        M._validated = true
    end

    local function SelectEffectProfile(phase, creatureType, tier, _context)
        local phaseKey = NormalizePhase(phase)
        local tierKey = NormalizeTier(tier)
        local group = ResolveGroup(creatureType)

        local function ResolveRoute(groupKey, tierValue)
            local byPhase = EffectsDB.ROUTING[phaseKey]
            local byGroup = byPhase and byPhase[groupKey]
            return byGroup and byGroup[tierValue] or nil
        end

        local candidates = BuildWeightPool(ResolveRoute(group, tierKey), group, UpdateMetric)
        local fallbackUsed = false

        if #candidates == 0 then
            fallbackUsed = true
            candidates = BuildWeightPool(ResolveRoute(group, "COMMON"), group, UpdateMetric)
        end
        if #candidates == 0 then
            fallbackUsed = true
            candidates = BuildWeightPool(ResolveRoute("ARCANE", tierKey), group, UpdateMetric)
        end

        local profile = PickWeighted(candidates, EA_RandIntCompat)
        if not profile then
            fallbackUsed = true
            local fallbackId = EffectsDB.DEFAULT_PROFILE_ID_BY_PHASE[phaseKey]
            profile = EffectsDB.PROFILES[fallbackId]
        end

        if not profile then
            return nil
        end

        UpdateMetric("effectsProfileSelected")
        if fallbackUsed then
            UpdateMetric("effectsProfileFallbackUsed")
        end

        return {
            id = profile.id,
            phase = phaseKey,
            tier = tierKey,
            group = group,
            payload = CloneTable(profile.payload or {}),
            fallbackUsed = fallbackUsed,
        }
    end

    local function GetArrivalApplyChanceByTier(tier)
        local key = NormalizeTier(tier)
        local chance = tonumber(EffectsDB.ARRIVAL_APPLY_CHANCE_BY_TIER[key]) or 0
        if chance < 0 then chance = 0 end
        if chance > 1 then chance = 1 end
        return chance
    end

    return {
        EffectsDB = EffectsDB,
        SelectEffectProfile = SelectEffectProfile,
        GetArrivalApplyChanceByTier = GetArrivalApplyChanceByTier,
        ResolveGroup = ResolveGroup,
    }
end

EA.SystemsEffectsDB = EffectsDB
return M
