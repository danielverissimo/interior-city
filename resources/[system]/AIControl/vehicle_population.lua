-- Bloqueia somente a geracao ambiental. Nao apaga entidades de jogadores.
local suppressed = {}

local function suppress(model)
    if type(model) ~= 'string' or model == '' then return end
    local hash = GetHashKey(model:lower())
    suppressed[hash] = true
    SetVehicleModelIsSuppressed(hash, true)
end

local function suppressCatalog(catalog)
    for spawn, entry in pairs(type(catalog) == 'table' and catalog or {}) do
        local category = type(entry) == 'table' and tostring(entry.type or ''):lower() or ''
        if category == 'vip' or category == 'vips' or category == 'brasileiros' or category == 'som' then
            suppress(spawn)
            if type(entry.model) == 'string' then suppress(entry.model) end
        end
    end
end

for _, model in ipairs(RestrictedVehicleModels or {}) do suppress(model) end

RegisterNetEvent('m_garage:vehicleCatalog:setEntry', function(spawn, entry)
    suppressCatalog({ [spawn] = entry })
end)
RegisterNetEvent('m_garage:vehicleCatalog:replace', suppressCatalog)

CreateThread(function()
    while true do
        for hash in pairs(suppressed) do SetVehicleModelIsSuppressed(hash, true) end
        Wait(5000)
    end
end)
