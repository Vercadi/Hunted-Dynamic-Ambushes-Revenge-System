EnemyAmbush = EnemyAmbush or {}

-- One module-level container table is intentional.
-- The nested tables below are the actual static datasets consumed by Systems.
-- This extraction keeps SpawnPipeline local-budget pressure down and centralizes
-- ownership of static constants without changing runtime behavior.
local AMBUSH_WARNINGS = {
    Default = {
        vfx = nil,
        sound = nil,
        textByTier = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000001;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000002;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000003;1"
            },
            VETERAN = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000004;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000005;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000006;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000007;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000008;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000009;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000010;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000011;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000012;1"
            }
        }
    },

    Humanoid = {
        vfx = nil,
        sound = nil,
        textByTier = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000013;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000014;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000015;1"
            },
            VETERAN = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000016;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000017;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000018;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000019;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000020;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000021;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000022;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000023;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000024;1"
            }
        }
    },

    Undead = {
        vfx = "80a4c9a2-af28-4ba2-bcab-082c9d2ee0e4",
        sound = "Amb_SV_Underdark_QD",
        textByTier = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000025;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000026;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000027;1"
            },
            VETERAN = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000028;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000029;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000030;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000031;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000032;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000033;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000034;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000035;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000036;1"
            }
        }
    },

    Beast = {
        vfx = nil,
        sound = "Amb_SV_Forest_QD",
        textByTier = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000037;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000038;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000039;1"
            },
            VETERAN = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000040;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000041;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000042;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000043;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000044;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000045;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000046;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000047;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000048;1"
            }
        }
    },

    Fiend = {
        vfx = "0a5e9598-5424-b344-4e70-38cb17e00003",
        sound = "Amb_SV_TUT_ImpFight",
        textByTier = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000049;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000050;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000051;1"
            },
            VETERAN = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000052;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000053;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000054;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000055;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000056;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000057;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000058;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000059;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000060;1"
            }
        }
    },

    Fey = {
        vfx = "238ffa26-ded2-5889-8d49-d3e4e4b69c01",
        sound = "Amb_PS_WoodenShip_Creak",
        textByTier = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000061;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000062;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000063;1"
            },
            VETERAN = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000064;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000065;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000066;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000067;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000068;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000069;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000070;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000071;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000072;1"
            }
        }
    },

    Aberration = {
        vfx = "a3f7c0f1-2c2b-f6f6-ca21-3646d793148e",
        sound = "SE_Amb_CRA_TentacleThrobbing",
        textByTier = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000073;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000074;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000075;1"
            },
            VETERAN = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000076;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000077;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000078;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000079;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000080;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000081;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000082;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000083;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000084;1"
            }
        }
    },

    Monstrosity = {
        vfx = nil,
        sound = "Amb_SV_Underdark_QD",
        textByTier = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000085;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000086;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000087;1"
            },
            VETERAN = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000088;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000089;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000090;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000091;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000092;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000093;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000094;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000095;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000096;1"
            }
        }
    },

    Plant = {
        vfx = nil,
        sound = "Amb_SV_Forest_QD",
        textByTier = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000097;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000098;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000099;1"
            },
            VETERAN = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000100;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000101;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000102;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000103;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000104;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000105;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000106;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000107;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000108;1"
            }
        }
    },

    Ooze = {
        vfx = nil,
        sound = "Amb_SV_Underdark_QD",
        textByTier = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000109;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000110;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000111;1"
            },
            VETERAN = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000112;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000113;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000114;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000115;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000116;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000117;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000118;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000119;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000120;1"
            }
        }
    }
}

-- Optional context-aware warning text by region + creatureType
AMBUSH_WARNINGS.context = AMBUSH_WARNINGS.context or {
    -- Act 1 Wilderness
    ["WLD_Main_A"] = {
        Plant = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000121;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000122;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000123;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000124;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000125;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000126;1"
            }
        }
    },

    -- Goblin Camp
    ["GOB_Main_A"] = {
        Humanoid = {
            COMMON = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000127;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000128;1"
            },
            VETERAN = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000129;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000130;1"
            },
            ELITE = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000131;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000132;1"
            },
            LEGENDARY = {
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000133;1",
                "h8a1b2c3dg4e5fg6a7bg8c9dg000000000134;1"
            }
        }
    },

    -- Underdark
    ["UND_Main_A"] = {
        Aberration = {
            COMMON = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000135;1" },
            ELITE = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000136;1" },
            LEGENDARY = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000137;1" }
        },
        Ooze = {
            COMMON = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000138;1" },
            ELITE = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000139;1" },
            LEGENDARY = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000140;1" }
        },
        Monstrosity = {
            COMMON = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000141;1" },
            ELITE = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000142;1" },
            LEGENDARY = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000143;1" }
        }
    },

    -- Shadow-Cursed Lands
    ["SCL_Main_A"] = {
        Undead = {
            COMMON = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000144;1" },
            ELITE = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000145;1" },
            LEGENDARY = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000146;1" }
        }
    },

    -- Moonrise area
    ["MOO_Main_A"] = {
        Humanoid = {
            COMMON = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000147;1" },
            ELITE = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000148;1" },
            LEGENDARY = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000149;1" }
        },
        Undead = {
            COMMON = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000150;1" },
            LEGENDARY = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000151;1" }
        },
        Fiend = {
            COMMON = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000152;1" },
            LEGENDARY = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000153;1" }
        }
    },

    -- Lower City underbelly
    ["BGO_Under_A"] = {
        Ooze = {
            COMMON = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000154;1" },
            ELITE = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000155;1" },
            LEGENDARY = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000156;1" }
        },
        Monstrosity = {
            COMMON = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000157;1" },
            ELITE = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000158;1" },
            LEGENDARY = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000159;1" }
        },
        Undead = {
            COMMON = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000160;1" },
            ELITE = { "h8a1b2c3dg4e5fg6a7bg8c9dg000000000161;1" }
        }
    }
}

local DataTables = {
    REST_DEFAULTS = {
        AMBUSH_PRESSURE_MAX = 100,
        LONG_REST_SAFETY_DELAY_S = 30,
        LONG_REST_RETRY_MAX = 6,
        SHORT_REST_RETRY_MAX = 6,
        DELAYED_AMBUSH_RETRY_MAX = 8,
        REHYDRATE_READY_RETRY_MAX = 30,
        REHYDRATE_READY_RETRY_MS = 1000,
        STAGGER_STEP_MS_MIN = 20,
        STAGGER_STEP_MS_DEFAULT = 100,
        STAGGER_STEP_MS_MAX = 500,
        STAGGER_QUEUE_INITIAL_DELAY_MIN_MS = 50,
        RETRY_LOG_EVERY = 5,
    },

    TRIGGER_REST_DEFAULTS = {
        DEFAULT_RANDOM_SECONDS = 60,
        ENEMY_DURATION_MIN_SECONDS = 300,
        ENEMY_DURATION_MAX_SECONDS = 600,
        TIER_SPAWN_DISTANCE_DEFAULT = 12,
        WARNING_DELAY_MIN_MS = 50,
    },

    TIMER_PREFIXES = {
        OWNED = "EA_",
        APPROACH_BEAT = "EA_AMBUSH_BEAT_",
        SHORT_REST = "EA_SR_",
        LONG_REST = "EA_LR_",
        SHORT_REST_RETRY = "EA_SR_RETRY_",
        LONG_REST_RETRY = "EA_LR_RETRY_",
        REST_DEFER = "EA_REST_DEFER_",
        SPAWN_QUEUE = "EA_SPAWNQ_",
        AMBUSH_DELAYED = "EA_AMBUSH_DELAYED_",
        DESPAWN = "EA_Despawn_",
        DELETE = "EA_Delete_",
    },

    TIER_SPAWN_DISTANCE = {
        COMMON = 12,
        VETERAN = 12,
        ELITE = 16,
        LEGENDARY = 19,
    },

    MAX_SPAWN_HEIGHT_DELTA = 4.0,

    BAD_CHAMPION_TEMPLATES = {
        -- Safety deny-list: known problematic story/shell/visual candidates for champion flow.
        ["44b9e114-b5ab-4d64-bb91-eb9114d2fd3a"] = true, -- Dark Justiciar Giant shell template
        ["80db81be-27d4-42a8-a2b0-4b7fbfd74f01"] = true, -- Skeletal Dragon (Undead variant) broken body rig at runtime
        ["2751f474-424e-4693-85dc-cb5bebbba259"] = true, -- Beholder Tyrant visual/name failure in generic champion flow
    },

    ENTRY_BAND_ORDER = {
        COMMON = 1,
        VETERAN = 2,
        ELITE = 3,
        LEGENDARY = 4,
        CHAMPION = 5,
        CHAMPION_ONLY = 5,
    },

    CHAMPION_TYPE_STATUS_BY_TYPE = {
        Aberration  = "EA_CHAMPION_ABERRATION",
        Beast       = "EA_CHAMPION_BEAST",
        Celestial   = "EA_CHAMPION_CELESTIAL",
        Construct   = "EA_CHAMPION_CONSTRUCT",
        Dragon      = "EA_CHAMPION_DRAGON",
        Elemental   = "EA_CHAMPION_ELEMENTAL",
        Fey         = "EA_CHAMPION_FEY",
        Fiend       = "EA_CHAMPION_FIEND",
        Giant       = "EA_CHAMPION_GIANT",
        Humanoid    = "EA_CHAMPION_HUMANOID",
        Monstrosity = "EA_CHAMPION_MONSTROSITY",
        Ooze        = "EA_CHAMPION_OOZE",
        Plant       = "EA_CHAMPION_PLANT",
        Undead      = "EA_CHAMPION_UNDEAD",
    },

    APPROACH_SOUND_BY_TYPE = {
        Humanoid = { "FLT_UTIL_Use_Dig_UnSheathe",  "Items_Armor_Smaller_Equip", "Items_Armor_Equip", "Whoosh_Armor" },
        Undead = { "Ghoul_Shout", "FlyingGhoul_Shout" },
        Monstrosity = { "Ettercap_Shout" },
        Plant = { "Dark_Vine_Blight_Foley_Bodyfall" },
        Ooze = { "Ooze_Attack" },
    },

    TIER_STINGER_BY_TIER = {
        ELITE = "Set_01_Explo_Light_stinger_01",
        LEGENDARY = "Set_06_Fight_Stinger_04",
        CHAMPION = "Set_07_Explo_Glob_dark_Stinger_01",
    },

    REGION_AMBIENCE = {
        WLD_Main_A = { sound = "Set_01_Explo_Light_stinger_01" },
        UND_Main_A = { sound = "Set_01_Explo_Stinger_psy_06" },
        SCL_Main_A = { sound = "Hell_reveal_stinger" },
        BGO_Main_A = { sound = "Set_06_Fight_Stinger_04" },
        CRE_Astral_A = { sound = "Set_01_Explo_Stinger_psy_06" },
        AVE_Main_A = { sound = "Set_01_Explo_Dark_stinger_01" },
    },

    POST_SPAWN_BARK_BY_TYPE = {
        Humanoid = { "Player_Races_Voice_Combat_Shout" },
        Undead = { "Ghoul_Shout" },
        Monstrosity = { "Ettercap_Shout" },
        Plant = { "Dark_Vine_Blight_Foley_Bodyfall" },
        Ooze = { "Ooze_Attack" },
        Beast = { "DEN_DruidPet_002_Wolf_Voice_Growl_A" },
    },

    COMBAT_START_BARK_BY_TYPE = {
        Humanoid = { "Player_Races_Voice_Combat_Shout" },
        Undead = { "Ghoul_Shout", "FlyingGhoul_Shout" },
        Monstrosity = { "Ettercap_Shout" },
        Beast = { "DEN_DruidPet_002_Wolf_Voice_Growl_A" },
    },

    COMBAT_START_FALLBACK_SFX_BY_TIER = {
        COMMON = "Set_01_Explo_Light_stinger_01",
        VETERAN = "Set_01_Explo_Light_stinger_01",
        ELITE = "Set_06_Fight_Stinger_04",
        LEGENDARY = "Set_07_Explo_Glob_dark_Stinger_01",
        CHAMPION = "Set_07_Explo_Glob_dark_Stinger_01",
    },

    AMBUSH_WARNINGS = AMBUSH_WARNINGS,
}

EnemyAmbush.SystemsDataTables = DataTables
return DataTables
