--[[
    m_garage - catálogo de veículos
    Fonte persistente: shared-side/listcars.json

    Compatibilidade:
    - mantém a global listCars no MESMO formato antigo, indexada por GetHashKey(model);
    - getVehiclePrice/getVehicleTrunk/getVehicleName/getVehicleType continuam funcionando;
    - outros resources que usam exports do m_garage não precisam ser alterados.
]]

listCars = listCars or {}
vehicleCatalogBySpawn = vehicleCatalogBySpawn or {}

local function normalizeEntry(spawn,data)
    data=type(data)=="table" and data or {}
    local model=tostring(data.model or spawn or "")
    return {
        model=model,
        price=math.floor(tonumber(data.price) or 0),
        banned=data.banned==true,
        name=tostring(data.name or model),
        trunk=math.floor(tonumber(data.trunk) or 0),
        type=tostring(data.type or "outros")
    }
end

function ApplyVehicleCatalog(catalog)
    listCars={}
    vehicleCatalogBySpawn={}

    if type(catalog)~="table" then return end

    for spawn,data in pairs(catalog) do
        local key=string.lower(tostring(spawn))
        local entry=normalizeEntry(key,data)
        if entry.model~="" then
            vehicleCatalogBySpawn[key]=entry
            listCars[GetHashKey(entry.model)]=entry
        end
    end
end

function ApplyVehicleCatalogEntry(spawn,data)
    spawn=string.lower(tostring(spawn or ""))
    if spawn=="" then return end

    local old=vehicleCatalogBySpawn[spawn]
    if old and old.model then
        listCars[GetHashKey(old.model)]=nil
    end

    local entry=normalizeEntry(spawn,data)
    vehicleCatalogBySpawn[spawn]=entry
    listCars[GetHashKey(entry.model)]=entry
end

function RemoveVehicleCatalogEntry(spawn)
    spawn=string.lower(tostring(spawn or ""))
    local old=vehicleCatalogBySpawn[spawn]
    if old and old.model then
        listCars[GetHashKey(old.model)]=nil
    end
    vehicleCatalogBySpawn[spawn]=nil
end

local raw=LoadResourceFile(GetCurrentResourceName(),"shared-side/listcars.json")
if raw and raw~="" then
    local ok,data=pcall(json.decode,raw)
    if ok and type(data)=="table" then
        ApplyVehicleCatalog(data)
    else
        print("^1[m_garage]^7 shared-side/listcars.json inválido.")
    end
else
    print("^1[m_garage]^7 shared-side/listcars.json não encontrado.")
end

RegisterNetEvent("m_garage:vehicleCatalog:setEntry",function(spawn,data)
    ApplyVehicleCatalogEntry(spawn,data)
end)

RegisterNetEvent("m_garage:vehicleCatalog:removeEntry",function(spawn)
    RemoveVehicleCatalogEntry(spawn)
end)

RegisterNetEvent("m_garage:vehicleCatalog:replace",function(catalog)
    ApplyVehicleCatalog(catalog)
end)
