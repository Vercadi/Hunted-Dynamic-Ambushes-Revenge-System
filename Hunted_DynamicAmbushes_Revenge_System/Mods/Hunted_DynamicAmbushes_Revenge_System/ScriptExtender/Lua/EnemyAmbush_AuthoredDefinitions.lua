local EA_LOCA_BEACH_POST_COMBAT_MESSAGE = "h5d0fa721g7ae6g41e6g8e2ag11ad39c77921;1"

return {
    {
        id = "EA_SCN_BEACH_WAKEUP",
        label = "Beach Wake-Up",
        enabled = true,
        once = true,
        priority = 100,
        triggerKinds = { "rest", "internal_call" },
        gates = {
            minPartyLevel = 1,
            maxPartyLevel = 3,
            allowedRegions = { "WLD_Main_A" },
            internalMatcherId = "beach_wakeup",
        },
        trigger = {
            rest = {
                allowLongRest = false,
                restTypes = { "short" },
            },
            internal = {
                allowForceRun = true,
            },
        },
        spawn = {
            mode = "fixed_spawn_specs",
            theme = "GOBLIN_BEACH_WAKEUP",
            entries = {
                {
                    template = "844e3c99-ea7e-4a49-8dcd-691c8c050b41",
                    fallback = { name = "Goblin Guard (Female, Basic)", level = 1, creatureType = "Humanoid", status = "" },
                    spawnDist = 6,
                    forceFindValidPosition = true,
                    disableAggressiveAdvance = true,
                    noEscape = true,
                    suppressCombatStartPresentation = true,
                    duration = 75,
                },
                {
                    template = "098202ac-cc63-432b-bff4-6f386ff14f6f",
                    fallback = { name = "Goblin Guard (Male, Basic)", level = 1, creatureType = "Humanoid", status = "" },
                    spawnDist = 6,
                    forceFindValidPosition = true,
                    disableAggressiveAdvance = true,
                    noEscape = true,
                    suppressCombatStartPresentation = true,
                    duration = 75,
                },
            },
        },
        presentation = {
            introText = "",
            completionText = "",
            postCombatMessage = EA_LOCA_BEACH_POST_COMBAT_MESSAGE,
            onboardingAfterCombat = true,
        },
        internal = {
            definitionOwner = "EnemyAmbush_AuthoredDefinitions.lua",
            bootstrapException = "beach_wakeup",
            notes = "Beach wake-up keeps only story-wakeup/timer orchestration in EnemyAmbush_Events_ScenarioBootstrap.lua; authored execution routes through the internal runtime.",
            schemaStability = "internal_unstable",
        },
    },
}
