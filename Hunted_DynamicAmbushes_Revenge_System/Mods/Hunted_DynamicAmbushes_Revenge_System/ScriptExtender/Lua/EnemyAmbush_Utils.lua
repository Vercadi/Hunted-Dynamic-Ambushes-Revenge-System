EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

-- Legacy globals are opt-in for old dev/console habits only.
-- Normal runtime must boot without them.
local function EA_ShouldLoadLegacyCompatGlobals()
    if rawget(_G, "EA_ENABLE_LEGACY_COMPAT_GLOBALS") == true then
        return true
    end
    if EA and EA.EnableLegacyCompatGlobals == true then
        return true
    end
    return false
end

Ext.Require("EnemyAmbush_Utils_Core.lua")
Ext.Require("EnemyAmbush_Utils_Settings.lua")
Ext.Require("EnemyAmbush_Utils_StateTime.lua")
Ext.Require("EnemyAmbush_Systems_ChampionState.lua")
Ext.Require("EnemyAmbush_Systems_RegionPolicy.lua")
Ext.Require("EnemyAmbush_Systems_SupportJoinService.lua")
Ext.Require("EnemyAmbush_Systems_HostilityService.lua")
Ext.Require("EnemyAmbush_Utils_HostilityRegion.lua")
Ext.Require("EnemyAmbush_Utils_Telemetry.lua")
Ext.Require("EnemyAmbush_Utils_Exports.lua")

EA.LegacyCompatGlobalsEnabled = false
if EA_ShouldLoadLegacyCompatGlobals() then
    EA.LegacyCompatGlobalsEnabled = true
    Ext.Require("EnemyAmbush_Utils_Compat.lua")
end
