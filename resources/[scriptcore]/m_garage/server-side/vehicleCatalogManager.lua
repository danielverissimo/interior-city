local CATALOG_FILE="shared-side/listcars.json"

local function clone(v)
    if type(v)~="table" then return v end
    local out={}
    for k,x in pairs(v) do out[k]=clone(x) end
    return out
end

local function trim(v)
    return tostring(v or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function loadCatalog()
    local raw=LoadResourceFile(GetCurrentResourceName(),CATALOG_FILE)
    local ok,data=pcall(json.decode,raw or "{}")
    if not ok or type(data)~="table" then
        return {}
    end
    return data
end

local function saveCatalog(catalog)
    return SaveResourceFile(GetCurrentResourceName(),CATALOG_FILE,json.encode(catalog),-1)
end

local function normalize(spawn,data)
    spawn=string.lower(trim(spawn))
    if spawn=="" then return nil,"Informe o spawn do veículo." end
    if type(data)~="table" then return nil,"Dados do veículo inválidos." end

    local model=trim(data.model)
    if model=="" then model=spawn end

    local price=tonumber(data.price)
    local trunk=tonumber(data.trunk)
    if not price or price<0 then return nil,"Valor inválido." end
    if not trunk or trunk<0 then return nil,"Peso/porta-malas inválido." end

    local name=trim(data.name)
    if name=="" then name=model end

    local vehicleType=trim(data.type)
    if vehicleType=="" then vehicleType="outros" end

    return {
        model=model,
        price=math.floor(price),
        banned=data.banned==true,
        name=name,
        trunk=math.floor(trunk),
        type=vehicleType
    }
end

exports("getVehicleCatalog",function()
    return clone(vehicleCatalogBySpawn or loadCatalog())
end)

exports("getVehicleCatalogEntry",function(spawn)
    spawn=string.lower(trim(spawn))
    local catalog=vehicleCatalogBySpawn or loadCatalog()
    return catalog[spawn] and clone(catalog[spawn]) or nil
end)

exports("saveVehicleCatalogEntry",function(originalSpawn,spawn,data)
    originalSpawn=string.lower(trim(originalSpawn))
    spawn=string.lower(trim(spawn))

    local entry,err=normalize(spawn,data)
    if not entry then return false,err end

    local catalog=loadCatalog()

    if originalSpawn~=spawn and catalog[spawn] then
        return false,"Já existe outro veículo com este spawn."
    end

    if originalSpawn~="" and originalSpawn~=spawn then
        catalog[originalSpawn]=nil
        RemoveVehicleCatalogEntry(originalSpawn)
        TriggerClientEvent("m_garage:vehicleCatalog:removeEntry",-1,originalSpawn)
    end

    catalog[spawn]=entry

    if not saveCatalog(catalog) then
        return false,"Não foi possível salvar shared-side/listcars.json."
    end

    ApplyVehicleCatalogEntry(spawn,entry)
    TriggerClientEvent("m_garage:vehicleCatalog:setEntry",-1,spawn,entry)
    TriggerEvent("m_garage:vehicleCatalogUpdated",spawn,clone(entry))

    return true,originalSpawn~="" and "Veículo do servidor atualizado em tempo real." or "Veículo cadastrado no servidor em tempo real.",clone(entry)
end)

exports("removeVehicleCatalogEntry",function(spawn)
    spawn=string.lower(trim(spawn))
    local catalog=loadCatalog()
    if not catalog[spawn] then return false,"Veículo não encontrado no catálogo do servidor." end

    catalog[spawn]=nil
    if not saveCatalog(catalog) then
        return false,"Não foi possível salvar shared-side/listcars.json."
    end

    RemoveVehicleCatalogEntry(spawn)
    TriggerClientEvent("m_garage:vehicleCatalog:removeEntry",-1,spawn)
    TriggerEvent("m_garage:vehicleCatalogRemoved",spawn)

    return true,"Veículo removido do catálogo do servidor."
end)


exports("removeVehicleCatalogEntries",function(spawns)
    if type(spawns)~="table" then
        return false,"Lista de veículos inválida.",{}
    end

    local catalog=loadCatalog()
    local removed={}
    local missing={}

    for _,raw in ipairs(spawns) do
        local spawn=string.lower(trim(raw))
        if spawn~="" then
            if catalog[spawn] then
                catalog[spawn]=nil
                removed[#removed+1]=spawn
            else
                missing[#missing+1]=spawn
            end
        end
    end

    if #removed==0 then
        return false,"Nenhum dos veículos selecionados foi encontrado no catálogo.",{removed={},missing=missing}
    end

    -- Salva o JSON apenas UMA vez para toda a exclusão em lote.
    if not saveCatalog(catalog) then
        return false,"Não foi possível salvar shared-side/listcars.json.",{removed={},missing=missing}
    end

    -- Atualiza a estrutura runtime e os clientes sem recarregar o resource.
    for _,spawn in ipairs(removed) do
        RemoveVehicleCatalogEntry(spawn)
        TriggerClientEvent("m_garage:vehicleCatalog:removeEntry",-1,spawn)
        TriggerEvent("m_garage:vehicleCatalogRemoved",spawn)
    end

    local msg=("%d veículo(s) removido(s) do catálogo do servidor."):format(#removed)
    if #missing>0 then
        msg=msg..(" %d já não existiam."):format(#missing)
    end

    return true,msg,{removed=removed,missing=missing}
end)
