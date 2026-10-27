local Tunnel=module("vrp","lib/Tunnel")
local Proxy=module("vrp","lib/Proxy")
local vRPConfig=Proxy.getInterface("vRP")

local FILE="residences.json"
ResidencesData={settings={},interiors={},residences={}}
ResidencesInteriors={}
ResidenceHomes={}
ResidenceTypes={}

local function clone(v)
    if type(v)~="table" then return v end
    local o={} for k,x in pairs(v) do o[k]=clone(x) end return o
end

local function trim(v)
    return tostring(v or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function v3(v)
    if type(v)~="table" then return vector3(0.0,0.0,0.0) end
    return vector3(tonumber(v[1]) or 0.0,tonumber(v[2]) or 0.0,tonumber(v[3]) or 0.0)
end

local function rebuild()
    ResidenceHomes={}
    ResidenceTypes={}

    for _,r in ipairs(ResidencesData.residences or {}) do
        local name=tostring(r.name or "")
        if name~="" then
            ResidenceHomes[name]={
                tonumber(r.x) or 0.0,
                tonumber(r.y) or 0.0,
                tonumber(r.z) or 0.0,
                tostring(r.interior or "Basic"),
                math.floor(tonumber(r.price) or 0),
                math.max(1,math.floor(tonumber(r.slot) or 1)),
                math.floor(tonumber(r.trade) or 0),
                tostring(r.type or "Casa")
            }
            ResidenceTypes[name]=tostring(r.type or "Casa")
        end
    end

    ResidencesInteriors={}
    for name,i in pairs(ResidencesData.interiors or {}) do
        ResidencesInteriors[name]={
            valor=math.floor(tonumber(i.valor) or 0),
            interior=v3(i.interior),
            vaultCoords=v3(i.vaultCoords),
            wardobeCoords=v3(i.wardobeCoords),
            residents=math.max(1,math.floor(tonumber(i.residents) or 1)),
            vault=math.max(0,math.floor(tonumber(i.vault) or 0)),
            fridge=math.max(0,math.floor(tonumber(i.fridge) or 0))
        }
    end
end

local function saveFile()
    if not SaveResourceFile(GetCurrentResourceName(),FILE,json.encode(ResidencesData),-1) then
        return false,"Não foi possível salvar residences.json."
    end
    rebuild()
    TriggerEvent("residences:panelConfigUpdated",ResidenceHomes,ResidencesInteriors,ResidenceTypes,ResidencesData.settings or {})
    return true
end

local function loadFile()
    local raw=LoadResourceFile(GetCurrentResourceName(),FILE)
    local ok,data=pcall(json.decode,raw or "{}")
    if ok and type(data)=="table" then
        ResidencesData=data
    else
        print("^1[residences]^7 residences.json inválido.")
        ResidencesData={settings={},interiors={},residences={}}
    end
    ResidencesData.settings=type(ResidencesData.settings)=="table" and ResidencesData.settings or {}
    ResidencesData.interiors=type(ResidencesData.interiors)=="table" and ResidencesData.interiors or {}
    ResidencesData.residences=type(ResidencesData.residences)=="table" and ResidencesData.residences or {}
    rebuild()
end

local function findResidence(name)
    for i,r in ipairs(ResidencesData.residences or {}) do
        if tostring(r.name)==tostring(name) then return i,r end
    end
end

local function normalizeResidence(r)
    if type(r)~="table" then return nil,"Residência inválida." end
    local name=trim(r.name)
    local tp=tostring(r.type or "Casa")
    local interior=trim(r.interior)
    local x,y,z=tonumber(r.x),tonumber(r.y),tonumber(r.z)
    local price=tonumber(r.price)
    if name=="" then return nil,"Informe o nome da residência." end
    if tp~="Casa" and tp~="Apartamento" then return nil,"Tipo inválido." end
    if interior=="" or not ResidencesData.interiors[interior] then return nil,"Interior inválido." end
    if not x or not y or not z then return nil,"Local da residência inválido." end
    if not price or price<0 then return nil,"Valor inválido." end

    return {
        name=name,type=tp,interior=interior,
        price=math.floor(price),
        x=x,y=y,z=z,
        slot=math.max(1,math.floor(tonumber(r.slot) or 1)),
        trade=math.max(0,math.floor(tonumber(r.trade) or 0))
    }
end

local function mirrorResidence(r,oldName)
    if oldName and oldName~=r.name then
        vRPConfig.execute("residences/renameHomes",{oldName=oldName,newName=r.name})
        vRPConfig.execute("residences/renameGarage",{oldName=oldName,newName=r.name})
        vRPConfig.execute("vRP/deleteHouse",{name=oldName})
    else
        vRPConfig.execute("vRP/deleteHouse",{name=r.name})
    end

    vRPConfig.execute("vRP/insertHouses",{
        name=r.name,x=r.x,y=r.y,z=r.z,
        interiorType=r.interior,intPrice=r.price,slot=r.slot,trade=r.trade
    })
end

loadFile()

CreateThread(function()
    Wait(500)

    -- Primeira instalação: importa automaticamente as residências já existentes
    -- na core_residences para o JSON, sem apagar dados.
    if #(ResidencesData.residences or {})==0 then
        local ok,rows=pcall(function() return vRPConfig.query("vRP/selectAll") end)
        if ok and type(rows)=="table" and #rows>0 then
            for _,v in ipairs(rows) do
                ResidencesData.residences[#ResidencesData.residences+1]={
                    name=tostring(v.name),
                    type=tostring(v.name):find("Apartamento") and "Apartamento" or "Casa",
                    interior=tostring(v.interiorType or "Basic"),
                    price=math.floor(tonumber(v.intPrice) or 0),
                    x=tonumber(v.x) or 0.0,
                    y=tonumber(v.y) or 0.0,
                    z=tonumber(v.z) or 0.0,
                    slot=math.max(1,math.floor(tonumber(v.slot) or 1)),
                    trade=math.max(0,math.floor(tonumber(v.trade) or 0))
                }
            end
            saveFile()
            print(("^2[residences]^7 %d residências migradas da core_residences para residences.json."):format(#rows))
        end
    end

    TriggerEvent("residences:panelConfigUpdated",ResidenceHomes,ResidencesInteriors,ResidenceTypes,ResidencesData.settings or {})
end)

exports("getResidencesConfig",function()
    return clone(ResidencesData)
end)

exports("saveResidence",function(originalName,payload)
    local r,err=normalizeResidence(payload)
    if not r then return false,err end

    originalName=trim(originalName)
    local idx=originalName~="" and findResidence(originalName) or nil
    local collision=findResidence(r.name)
    if collision and collision~=idx then
        return false,"Já existe uma residência com este nome."
    end

    if idx then
        ResidencesData.residences[idx]=r
    else
        ResidencesData.residences[#ResidencesData.residences+1]=r
    end

    table.sort(ResidencesData.residences,function(a,b)
        return tostring(a.name):lower()<tostring(b.name):lower()
    end)

    mirrorResidence(r,idx and originalName or nil)
    local ok,msg=saveFile()
    if not ok then return false,msg end
    return true,idx and "Residência atualizada em tempo real." or "Residência criada em tempo real."
end)

exports("removeResidence",function(name)
    name=trim(name)
    local idx=findResidence(name)
    if not idx then return false,"Residência não encontrada." end

    table.remove(ResidencesData.residences,idx)
    vRPConfig.execute("vRP/deleteHouse",{name=name})
    vRPConfig.execute("homes/selling",{name=name})
    vRPConfig.execute("homes/removeGarages",{name=name})
    vRPConfig.remSrvdata("wardrobe:"..name)
    vRPConfig.remSrvdata("fridge:"..name)
    vRPConfig.remSrvdata("vault:"..name)

    local ok,msg=saveFile()
    if not ok then return false,msg end
    return true,"Residência excluída."
end)

exports("saveInteriorTemplate",function(originalName,name,payload)
    originalName=trim(originalName)
    name=trim(name)
    if name=="" or type(payload)~="table" then return false,"Interior inválido." end
    if originalName~=name and ResidencesData.interiors[name] then return false,"Já existe um interior com este nome." end

    local function coords(v)
        if type(v)~="table" then return nil end
        local x,y,z=tonumber(v[1]),tonumber(v[2]),tonumber(v[3])
        if not x or not y or not z then return nil end
        return {x,y,z}
    end

    local interior=coords(payload.interior)
    local vault=coords(payload.vaultCoords)
    local wardrobe=coords(payload.wardobeCoords)
    if not interior or not vault or not wardrobe then return false,"Coordenadas do interior inválidas." end

    local data={
        type=(payload.type=="Apartamento") and "Apartamento" or "Casa",
        valor=math.max(0,math.floor(tonumber(payload.valor) or 0)),
        interior=interior,
        vaultCoords=vault,
        wardobeCoords=wardrobe,
        residents=math.max(1,math.floor(tonumber(payload.residents) or 1)),
        vault=math.max(0,math.floor(tonumber(payload.vault) or 0)),
        fridge=math.max(0,math.floor(tonumber(payload.fridge) or 0))
    }

    if originalName~="" and originalName~=name then
        ResidencesData.interiors[originalName]=nil
        for _,r in ipairs(ResidencesData.residences) do
            if r.interior==originalName then
                r.interior=name
                mirrorResidence(r,nil)
            end
        end
    end
    ResidencesData.interiors[name]=data

    local ok,msg=saveFile()
    if not ok then return false,msg end
    return true,"Interior atualizado em tempo real."
end)

exports("removeInteriorTemplate",function(name)
    name=trim(name)
    if not ResidencesData.interiors[name] then return false,"Interior não encontrado." end
    for _,r in ipairs(ResidencesData.residences or {}) do
        if r.interior==name then
            return false,"Este interior está sendo usado por uma residência."
        end
    end
    ResidencesData.interiors[name]=nil
    local ok,msg=saveFile()
    if not ok then return false,msg end
    return true,"Interior excluído."
end)

exports("saveResidencesSettings",function(payload)
    ResidencesData.settings=type(payload)=="table" and clone(payload) or {}
    local ok,msg=saveFile()
    if not ok then return false,msg end
    return true,"Configurações atualizadas."
end)
