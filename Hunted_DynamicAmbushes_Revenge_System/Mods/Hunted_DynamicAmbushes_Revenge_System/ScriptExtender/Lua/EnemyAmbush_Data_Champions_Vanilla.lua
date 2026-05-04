-- EnemyAmbush_Data_Champions_Vanilla.lua
-- Vanilla champion entries and by-type map.
-- F1 champion gating now uses a conservative threat gate:
-- - minPartyLevel is set against the observed scaled in-game threat, not just the raw template level
-- - maxPartyLevel is used only on the two low-level rare variants so they do not dilute late-game rolls

local Champions = {}

Champions.List = {
    {template = "6708ae4b-8dcf-4812-bdba-fd5fe1c343f6", name = "Planar Ally: Cambion", creatureType = "Fiend", level = 9, weight = 1, minPartyLevel = 8, status = "", championOnly = true},
    {template = "d9889d28-ca01-41f2-973e-275bbc8e2fe1", name = "Wild Magic Cambion", creatureType = "Fiend", level = 6, weight = 0.1, minPartyLevel = 4, maxPartyLevel = 8, status = "WILD_MAGIC", championOnly = true},
    {template = "2337e270-3c93-4088-8439-7c7450b99179", name = "Summon Deva", creatureType = "Celestial", level = 10, weight = 1, minPartyLevel = 8, status = "", championOnly = true},
    {template = "49044a53-3559-4bd5-8a2b-174dff98b0a3", name = "Orthon", creatureType = "Fiend", level = 8, weight = 0.05, minPartyLevel = 6, status = "", championOnly = true},
    {template = "5cbeda78-32f3-43e9-b120-9189afc3db28", name = "Githyanki Gishra Champion", creatureType = "Humanoid", level = 9, weight = 1, minPartyLevel = 9, maxPartyLevel = 18, status = "", championOnly = true, retinueFamily = "githyanki"},
    {template = "303c90c2-035b-4b54-925e-c18b4aeec5b7", name = "Bhaal Cultist Deathshead Champion", creatureType = "Humanoid", level = 8, weight = 0.75, minPartyLevel = 8, maxPartyLevel = 16, status = "", championOnly = true, retinueFamily = "bhaal cultist"},
    {template = "4d62cd88-0fea-4ab4-a679-5290cdd5824d", name = "Bhaal Cultist Invoker Champion", creatureType = "Humanoid", level = 9, weight = 0.55, minPartyLevel = 10, maxPartyLevel = 18, status = "", championOnly = true, retinueFamily = "bhaal cultist"},
    {template = "319efbbe-f9f3-4584-804e-3e17d47d1136", name = "Spectator", creatureType = "Aberration", level = 8, weight = 0.35, minPartyLevel = 7, status = "", championOnly = true},
    {template = "47a6ceac-0788-4a51-a96e-3eabf7c11768", name = "Alioramus Alpha", creatureType = "Beast", level = 9, weight = 1, minPartyLevel = 7, status = "", championOnly = true},
    {template = "26fa3fe9-608c-4113-99a6-727781351ea4", name = "Steel Watcher Titan", creatureType = "Construct", level = 12, weight = 1, minPartyLevel = 12, status = "", championOnly = true},
    {template = "88a6c664-877c-4d6e-81ad-dd377df2634e", name = "Fire Elemental Prime", creatureType = "Elemental", level = 9, weight = 1, minPartyLevel = 8, status = "", championOnly = true},
    {template = "c6ad9c71-43a9-410b-8e3e-219a0a7fddc8", name = "Planar Ally (Djinni)", creatureType = "Elemental", level = 6, weight = 0.1, minPartyLevel = 4, maxPartyLevel = 8, status = "", championOnly = true},
    {template = "d4edf374-6efe-463f-8899-889db26dee4e", name = "Green Hag Matriarch", creatureType = "Fey", level = 9, weight = 1, minPartyLevel = 7, status = "", championOnly = true},
    {template = "bc9fb0ff-18f1-4622-8260-d872e21a5b75", name = "Ogre Brute Champion", creatureType = "Giant", level = 9, weight = 1, minPartyLevel = 7, status = "", championOnly = true},
    {template = "4b3c6cdc-95da-476d-8ac7-c8d012ccf3b2", name = "Ochre Jelly Elder", creatureType = "Ooze", level = 9, weight = 1, minPartyLevel = 7, status = "", championOnly = true},
    {template = "ecfc157f-b689-47ac-8dcb-22fdb6861c01", name = "Shadow-Cursed Shambling Mound", creatureType = "Plant", level = 9, weight = 1, minPartyLevel = 9, status = "SCL_SHADOW_CURSE", championOnly = true},
    {template = "8c7f60a2-c0de-4292-b443-71297cd5d183", name = "Hollyphant", creatureType = "Celestial", level = 9, weight = 1, minPartyLevel = 7, status = "", championOnly = true},
    {template = "368935f0-4a15-4122-b101-9174dee70163", name = "Skeletal Dragon", creatureType = "Dragon", level = 9, weight = 0.03, minPartyLevel = 11, status = "", championOnly = true},
    {template = "64383f18-9830-40c2-8681-657cf36afc05", name = "Red Dragon", creatureType = "Dragon", level = 12, weight = 1, minPartyLevel = 12, status = "", championOnly = true},
    {template = "6047fffd-f7d3-4956-8b7a-ef82c08f8867", name = "Phase Spider Matriarch", creatureType = "Monstrosity", level = 9, weight = 1, minPartyLevel = 8, maxPartyLevel = 14, status = "", championOnly = true},
    {template = "0ae246ad-0b76-4019-b802-8553f42754a7", name = "Oathbreaker Knight Champion", creatureType = "Undead", level = 11, weight = 1, minPartyLevel = 11, status = "", championOnly = true},
}

Champions.ByType = {}
for _, c in ipairs(Champions.List) do
    local ct = c.creatureType or "Humanoid"
    Champions.ByType[ct] = Champions.ByType[ct] or {}
    table.insert(Champions.ByType[ct], c)
end

return Champions
