local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function plainCoords(c, withHeading)
    if type(c) ~= "table" then return nil end
    local x,y,z = tonumber(c.x or c[1]), tonumber(c.y or c[2]), tonumber(c.z or c[3])
    if not x or not y or not z then return nil end
    local out = { x=x, y=y, z=z }
    if withHeading then out.w = tonumber(c.w or c[4]) or 0.0 end
    return out
end

local function clone(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k,v in pairs(value) do out[k] = clone(v) end
    return out
end

local function saveAll(sync)
    SaveResourceFile(GetCurrentResourceName(), "shared-side/garages.json", json.encode(GarageConfigRaw), -1)
    SaveResourceFile(GetCurrentResourceName(), "shared-side/typeGarages.json", json.encode(GarageTypesRaw), -1)
    ApplyGarageDynamicConfig(GarageConfigRaw, GarageTypesRaw)
    if sync ~= false then TriggerClientEvent("m_garage:syncConfig", -1, GarageConfigRaw, GarageTypesRaw) end
    return true
end

local function findGarageIndex(id)
    id = tostring(id or "")
    for i,g in ipairs(GarageConfigRaw or {}) do
        if tostring(g.id or "") == id then return i end
    end
end

local function normalizeGarage(data, keepId)
    if type(data) ~= "table" then return nil, "Dados da garagem inválidos." end
    local id = trim(data.id)
    local garageType = trim(data.type)
    local distance = tonumber(data.blipDistance) or 5.0
    local coords = plainCoords(data.coords, false)
    local spawns = {}
    for _,spawn in ipairs(data.spawnCoords or {}) do
        local c = plainCoords(spawn, true)
        if c then spawns[#spawns+1] = c end
    end
    local permission = trim(data.permiss)

    if id == "" then return nil, "Informe um identificador para a garagem." end
    if not id:match("^[%w_%-]+$") then return nil, "O identificador aceita apenas letras, números, _ e -." end
    if garageType == "" or not GarageTypesRaw[garageType] then return nil, "Selecione um tipo de garagem válido." end
    if not coords then return nil, "Coordenadas da garagem inválidas." end
    if #spawns == 0 then return nil, "Adicione pelo menos uma vaga de spawn." end
    if distance <= 0 then return nil, "A distância do marker deve ser maior que zero." end

    return {
        id = keepId or id,
        type = garageType,
        blipDistance = distance,
        permiss = permission ~= "" and permission or nil,
        coords = coords,
        spawnCoords = spawns
    }
end

local function normalizeType(data)
    if type(data) ~= "table" then return nil, "Dados do tipo inválidos." end
    local mode = trim(data.type):lower()
    if mode ~= "public" and mode ~= "service" then return nil, "O tipo deve ser public ou service." end
    local blip = data.blip or {}
    local out = {
        type = mode,
        blip = {
            showBlip = blip.showBlip == true,
            name = trim(blip.name) ~= "" and trim(blip.name) or "Garagem",
            blipId = tonumber(blip.blipId) or 357,
            blipColor = tonumber(blip.blipColor) or 0,
            blipScale = tonumber(blip.blipScale) or 0.5
        }
    }
    if mode == "service" then
        out.vehicles = {}
        for _,veh in ipairs(data.vehicles or {}) do
            local name = trim(type(veh)=="table" and veh.vehicle or veh)
            if name ~= "" then
                local item = { vehicle = name }
                if type(veh)=="table" and veh.livery ~= nil and tostring(veh.livery) ~= "" then item.livery = tonumber(veh.livery) or veh.livery end
                out.vehicles[#out.vehicles+1] = item
            end
        end
        if #out.vehicles == 0 then return nil, "Garagem de serviço precisa de pelo menos um veículo." end
    else
        out.listCars = clone(data.listCars or { vehicle=true, boat=true, heli=true })
    end
    return out
end

exports("getGarages", function() return clone(GarageConfigRaw or {}) end)
exports("getGarageTypes", function() return clone(GarageTypesRaw or {}) end)

exports("addGarage", function(data)
    local garage,err = normalizeGarage(data)
    if not garage then return false,err end
    if findGarageIndex(garage.id) then return false,"Já existe uma garagem com esse identificador." end
    GarageConfigRaw[#GarageConfigRaw+1] = garage
    saveAll(true)
    return true,"Garagem criada com sucesso."
end)

exports("updateGarage", function(originalId, data)
    originalId = tostring(originalId or "")
    local index = findGarageIndex(originalId)

    if not index then
        return false,"Garagem não encontrada."
    end

    -- Ao editar, o ID enviado em data.id passa a ser o novo identificador.
    local garage,err = normalizeGarage(data)
    if not garage then
        return false,err
    end

    -- Se houve renomeação, impede colisão com outra garagem existente.
    if garage.id ~= originalId then
        local existingIndex = findGarageIndex(garage.id)
        if existingIndex and existingIndex ~= index then
            return false,"Já existe uma garagem com esse identificador."
        end
    end

    GarageConfigRaw[index] = garage
    saveAll(true)

    if garage.id ~= originalId then
        return true,("Garagem renomeada de %s para %s com sucesso."):format(originalId,garage.id)
    end

    return true,"Garagem atualizada com sucesso."
end)

exports("removeGarage", function(id)
    local index = findGarageIndex(id)
    if not index then return false,"Garagem não encontrada." end
    table.remove(GarageConfigRaw,index)
    saveAll(true)
    return true,"Garagem excluída com sucesso."
end)

exports("addGarageType", function(name,data)
    name = trim(name)
    if name == "" or not name:match("^[%w_%-]+$") then return false,"Nome do tipo inválido." end
    if GarageTypesRaw[name] then return false,"Já existe um tipo com esse nome." end
    local item,err = normalizeType(data)
    if not item then return false,err end
    GarageTypesRaw[name] = item
    saveAll(true)
    return true,"Tipo de garagem criado com sucesso."
end)

exports("updateGarageType", function(name,data)
    name = trim(name)
    if not GarageTypesRaw[name] then return false,"Tipo de garagem não encontrado." end
    local item,err = normalizeType(data)
    if not item then return false,err end
    GarageTypesRaw[name] = item
    saveAll(true)
    return true,"Tipo de garagem atualizado com sucesso."
end)

exports("removeGarageType", function(name)
    name = trim(name)
    if not GarageTypesRaw[name] then return false,"Tipo de garagem não encontrado." end
    for _,garage in ipairs(GarageConfigRaw or {}) do
        if garage.type == name then return false,"Esse tipo ainda está sendo usado por uma ou mais garagens." end
    end
    GarageTypesRaw[name] = nil
    saveAll(true)
    return true,"Tipo de garagem excluído com sucesso."
end)

exports("reloadGarageConfig", function()
    LoadGarageDynamicConfig()
    TriggerClientEvent("m_garage:syncConfig", -1, GarageConfigRaw, GarageTypesRaw)
    return true,"Configuração recarregada."
end)
