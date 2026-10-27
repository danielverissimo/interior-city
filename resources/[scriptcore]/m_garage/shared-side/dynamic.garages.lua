garagesLocs = garagesLocs or {}
typeGarages = typeGarages or {}

local function copyTable(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k,v in pairs(value) do out[k] = copyTable(v) end
    return out
end

local function makeVec3(c)
    if type(c) ~= "table" then return vector3(0.0,0.0,0.0) end
    return vector3(tonumber(c.x or c[1]) or 0.0, tonumber(c.y or c[2]) or 0.0, tonumber(c.z or c[3]) or 0.0)
end

local function makeVec4(c)
    if type(c) ~= "table" then return vector4(0.0,0.0,0.0,0.0) end
    return vector4(tonumber(c.x or c[1]) or 0.0, tonumber(c.y or c[2]) or 0.0, tonumber(c.z or c[3]) or 0.0, tonumber(c.w or c[4]) or 0.0)
end

function ApplyGarageDynamicConfig(rawGarages, rawTypes)
    local parsedGarages = {}
    for i,garage in ipairs(rawGarages or {}) do
        parsedGarages[i] = {
            id = tostring(garage.id or ("garage_%03d"):format(i)),
            type = tostring(garage.type or ""),
            blipDistance = tonumber(garage.blipDistance) or 5.0,
            permiss = (garage.permiss ~= nil and tostring(garage.permiss) ~= "") and tostring(garage.permiss) or nil,
            coords = makeVec3(garage.coords),
            spawnCoords = {}
        }
        for j,spawn in ipairs(garage.spawnCoords or {}) do
            parsedGarages[i].spawnCoords[j] = makeVec4(spawn)
        end
    end

    garagesLocs = parsedGarages
    typeGarages = copyTable(rawTypes or {})

    if not IsDuplicityVersion() then
        garages = garagesLocs
        types = typeGarages
        nearestGarages = {}
        TriggerEvent("m_garage:configUpdated")
    end
end

if IsDuplicityVersion() then
    GarageConfigRaw = GarageConfigRaw or {}
    GarageTypesRaw = GarageTypesRaw or {}

    function LoadGarageDynamicConfig()
        local garagesText = LoadResourceFile(GetCurrentResourceName(), "shared-side/garages.json")
        local typesText = LoadResourceFile(GetCurrentResourceName(), "shared-side/typeGarages.json")
        GarageConfigRaw = garagesText and json.decode(garagesText) or {}
        GarageTypesRaw = typesText and json.decode(typesText) or {}
        ApplyGarageDynamicConfig(GarageConfigRaw, GarageTypesRaw)
        print(("^2[m_garage]^7 Config carregada: %d garagens e %d tipos."):format(#GarageConfigRaw, (function() local n=0 for _ in pairs(GarageTypesRaw) do n=n+1 end return n end)()))
    end

    RegisterNetEvent("m_garage:requestConfig", function()
        TriggerClientEvent("m_garage:syncConfig", source, GarageConfigRaw, GarageTypesRaw)
    end)

    LoadGarageDynamicConfig()
else
    RegisterNetEvent("m_garage:syncConfig", function(rawGarages, rawTypes)
        ApplyGarageDynamicConfig(rawGarages or {}, rawTypes or {})
    end)

    CreateThread(function()
        Wait(800)
        TriggerServerEvent("m_garage:requestConfig")
    end)
end
