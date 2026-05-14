EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush
EA.SystemsModules = EA.SystemsModules or {}

local AuthoredAmbushServiceModule = Ext.Require("EnemyAmbush_Systems_AuthoredAmbushService.lua")
local AuthoredAmbushRuntimeModule = Ext.Require("EnemyAmbush_Systems_AuthoredAmbushRuntime.lua")
local InternalAuthoredDefinitions = Ext.Require("EnemyAmbush_AuthoredDefinitions.lua") or {}

local AuthoredAmbushService = (type(AuthoredAmbushServiceModule) == "table" and type(AuthoredAmbushServiceModule.Build) == "function")
    and AuthoredAmbushServiceModule.Build({ EA = EA })
    or nil

if type(AuthoredAmbushService) == "table" and type(AuthoredAmbushService.ReplaceDefinitions) == "function" then
    AuthoredAmbushService.ReplaceDefinitions(type(InternalAuthoredDefinitions) == "table" and InternalAuthoredDefinitions or {})
end

EA.SystemsModules.AuthoredAmbushService = AuthoredAmbushService

local builtRuntime = (type(AuthoredAmbushRuntimeModule) == "table" and type(AuthoredAmbushRuntimeModule.Build) == "function")
    and AuthoredAmbushRuntimeModule.Build({
        EA = EA,
        AuthoredAmbushService = AuthoredAmbushService,
        EA_IsModVarsContainer = EA["EA_IsModVarsContainer"],
    })
    or {}

local AuthoredAmbushRuntime = EA.SystemsModules.AuthoredAmbushRuntime or {}
for key in pairs(AuthoredAmbushRuntime) do
    AuthoredAmbushRuntime[key] = nil
end
for key, value in pairs(type(builtRuntime) == "table" and builtRuntime or {}) do
    AuthoredAmbushRuntime[key] = value
end
EA.SystemsModules.AuthoredAmbushRuntime = AuthoredAmbushRuntime

-- Retained as legacy/compat re-exports. Internal runtime consumers should
-- prefer EA.SystemsModules.AuthoredAmbushRuntime directly.
EA["EA_TryRunScriptedScenario"] = AuthoredAmbushRuntime.TryRunScriptedScenario
EA["EA_RunScriptedScenarioById"] = AuthoredAmbushRuntime.RunScriptedScenarioById
EA["EA_ListScriptedScenarios"] = AuthoredAmbushRuntime.ListScriptedScenarios
EA["EA_GetScriptedScenarioState"] = AuthoredAmbushRuntime.GetScriptedScenarioState
