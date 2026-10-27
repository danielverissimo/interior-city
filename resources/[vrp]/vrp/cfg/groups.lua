local cfg = {}

-- Compatibilidade: os cargos são armazenados em cfg/groups.json.
-- Recursos antigos que ainda usam module("cfg/groups") continuam recebendo cfg.groups.
cfg.groups = {}

local raw = LoadResourceFile("vrp","cfg/groups.json")
local ok,data = pcall(json.decode,raw or "{}")

if ok and type(data) == "table" and type(data.groups) == "table" then
    for _,entry in ipairs(data.groups) do
        local name = tostring(entry.name or "")
        if name ~= "" then
            local group = {}
            local groupConfig = type(entry.config) == "table" and entry.config or {}

            if next(groupConfig) ~= nil then
                group._config = groupConfig
            end

            for _,permission in ipairs(type(entry.permissions) == "table" and entry.permissions or {}) do
                group[#group+1] = tostring(permission)
            end

            cfg.groups[name] = group
        end
    end
end

cfg.users = {
	[1] = { "dono" }

}

cfg.selectors = { }


return cfg

