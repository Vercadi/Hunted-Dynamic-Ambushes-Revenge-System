EnemyAmbush = EnemyAmbush or {}
local EA = EnemyAmbush

local M = {}

function M.BindExports(map)
    if type(map) ~= "table" then
        return EA
    end
    for k, v in pairs(map) do
        if type(k) == "string" and k ~= "" and v ~= nil then
            EA[k] = v
        end
    end
    return EA
end

EA.SystemsExports = M
return M
