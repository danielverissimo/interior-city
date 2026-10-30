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

local GARAGES_FILE,TYPES_FILE="shared-side/garages.json","shared-side/typeGarages.json"
local quarantined=GetResourceKvpString('ic_config:garage_config_quarantined')=='1'
local activeSnapshot
local function readRaw(path)
    local ok,value=pcall(LoadResourceFile,GetCurrentResourceName(),path)
    return ok and type(value)=='string' and value or nil
end
local function writeExact(path,raw)
    if readRaw(path)==raw then return true end
    pcall(SaveResourceFile,GetCurrentResourceName(),path,raw,#raw)
    -- Some artifact versions do not return a reliable boolean. Bytes decide.
    return readRaw(path)==raw
end
local function quarantine()
    quarantined=true
    SetResourceKvp('ic_config:garage_config_quarantined','1')
end
local function restoreFiles(snapshot)
    local garageOk=writeExact(GARAGES_FILE,snapshot.garagesRaw)
    local typeOk=writeExact(TYPES_FILE,snapshot.typesRaw)
    if not garageOk or not typeOk then quarantine();return false end
    return true
end
local function registerMutation(name,fn)
    exports(name,function(...)
        if quarantined then return false,'Configuração em quarentena: confira os dois JSONs e recarregue antes de gravar.' end
        if activeSnapshot then return false,'Outra configuração está sendo gravada.' end
        local snapshot={garages=clone(GarageConfigRaw),types=clone(GarageTypesRaw),garagesRaw=readRaw(GARAGES_FILE),typesRaw=readRaw(TYPES_FILE)}
        if not snapshot.garagesRaw or not snapshot.typesRaw then return false,'Não foi possível ler os dois arquivos antes da alteração.' end
        activeSnapshot=snapshot
        local result=table.pack(pcall(fn,...))
        if not result[1] or result[2]~=true then
            local restored=restoreFiles(snapshot)
            GarageConfigRaw=clone(snapshot.garages);GarageTypesRaw=clone(snapshot.types)
            if snapshot.applyAttempted then
                if not pcall(ApplyGarageDynamicConfig,GarageConfigRaw,GarageTypesRaw) then quarantine();restored=false end
            end
            activeSnapshot=nil
            if not restored then return false,'A restauração dos arquivos não foi confirmada; gravações bloqueadas até conferência e recarga.' end
            if not result[1] then return false,'A alteração não foi confirmada; o estado anterior foi restaurado.' end
            return table.unpack(result,2,result.n)
        end
        activeSnapshot=nil
        return table.unpack(result,2,result.n)
    end)
end

local function saveAll(sync)
    local snapshot=activeSnapshot
    if not snapshot then return false,'Gravação sem snapshot recusada.' end
    local garagesRaw,typesRaw=json.encode(GarageConfigRaw),json.encode(GarageTypesRaw)
    if not writeExact(GARAGES_FILE,garagesRaw) or not writeExact(TYPES_FILE,typesRaw) then
        return false,'Não foi possível confirmar os dois arquivos de configuração.'
    end
    snapshot.applyAttempted=true
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

local function normalizeGarage(data, keepId, typeDefinitions)
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
    if garageType == "" or not (typeDefinitions or GarageTypesRaw)[garageType] then return nil, "Selecione um tipo de garagem válido." end
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

registerMutation("addGarage", function(data)
    local garage,err = normalizeGarage(data)
    if not garage then return false,err end
    if findGarageIndex(garage.id) then return false,"Já existe uma garagem com esse identificador." end
    GarageConfigRaw[#GarageConfigRaw+1] = garage
    local saved,message=saveAll(true);if not saved then return false,message end
    return true,"Garagem criada com sucesso."
end)

registerMutation("updateGarage", function(originalId, data)
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
    local saved,message=saveAll(true);if not saved then return false,message end

    if garage.id ~= originalId then
        return true,("Garagem renomeada de %s para %s com sucesso."):format(originalId,garage.id)
    end

    return true,"Garagem atualizada com sucesso."
end)

registerMutation("removeGarage", function(id)
    local index = findGarageIndex(id)
    if not index then return false,"Garagem não encontrada." end
    table.remove(GarageConfigRaw,index)
    local saved,message=saveAll(true);if not saved then return false,message end
    return true,"Garagem excluída com sucesso."
end)

registerMutation("addGarageType", function(name,data)
    name = trim(name)
    if name == "" or not name:match("^[%w_%-]+$") then return false,"Nome do tipo inválido." end
    if GarageTypesRaw[name] then return false,"Já existe um tipo com esse nome." end
    local item,err = normalizeType(data)
    if not item then return false,err end
    GarageTypesRaw[name] = item
    local saved,message=saveAll(true);if not saved then return false,message end
    return true,"Tipo de garagem criado com sucesso."
end)

registerMutation("updateGarageType", function(name,data)
    name = trim(name)
    if not GarageTypesRaw[name] then return false,"Tipo de garagem não encontrado." end
    local item,err = normalizeType(data)
    if not item then return false,err end
    GarageTypesRaw[name] = item
    local saved,message=saveAll(true);if not saved then return false,message end
    return true,"Tipo de garagem atualizado com sucesso."
end)

registerMutation("removeGarageType", function(name)
    name = trim(name)
    if not GarageTypesRaw[name] then return false,"Tipo de garagem não encontrado." end
    for _,garage in ipairs(GarageConfigRaw or {}) do
        if garage.type == name then return false,"Esse tipo ainda está sendo usado por uma ou mais garagens." end
    end
    GarageTypesRaw[name] = nil
    local saved,message=saveAll(true);if not saved then return false,message end
    return true,"Tipo de garagem excluído com sucesso."
end)

exports("reloadGarageConfig", function()
    if activeSnapshot then return false,'Outra configuração está sendo gravada.' end
    local garageOk,garages=pcall(json.decode,readRaw(GARAGES_FILE) or '')
    local typesOk,types=pcall(json.decode,readRaw(TYPES_FILE) or '')
    if not garageOk or not typesOk or type(garages)~='table' or type(types)~='table' then return false,'Confira os dois JSONs antes de recarregar.' end
    for _,definition in pairs(types) do
        local valid=normalizeType(definition)
        if not valid then return false,'Um tipo de garagem está inválido; a quarentena permanece.' end
    end
    local seen={}
    for _,garage in ipairs(garages) do
        local valid=normalizeGarage(garage,nil,types)
        if not valid or seen[valid.id] then return false,'Uma garagem está inválida; a quarentena permanece.' end
        seen[valid.id]=true
    end
    local oldGarages,oldTypes=GarageConfigRaw,GarageTypesRaw
    GarageConfigRaw=garages;GarageTypesRaw=types
    if not pcall(ApplyGarageDynamicConfig,GarageConfigRaw,GarageTypesRaw) then
        GarageConfigRaw=oldGarages;GarageTypesRaw=oldTypes;quarantine()
        return false,'A recarga não foi confirmada; confira a configuração.'
    end
    SetResourceKvp('ic_config:garage_config_quarantined','0')
    if GetResourceKvpString('ic_config:garage_config_quarantined')~='0' then quarantine();return false,'Não foi possível liberar a quarentena persistente.' end
    quarantined=false
    TriggerClientEvent("m_garage:syncConfig", -1, GarageConfigRaw, GarageTypesRaw)
    return true,"Configuração recarregada."
end)
