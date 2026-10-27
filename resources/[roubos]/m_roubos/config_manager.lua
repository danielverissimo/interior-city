local FILE="roubos.json"
local RobData={name="Roubos de Comércio",locations={},setups={},webhooks={},settings={}}

local function clone(v)
    if type(v)~="table" then return v end
    local o={} for k,x in pairs(v) do o[k]=clone(x) end return o
end

local function trim(v) return tostring(v or ""):gsub("^%s+",""):gsub("%s+$","") end

local function apply()
    Config.roubos=clone(RobData.locations or {})
    Config.setup=clone(RobData.setups or {})
    Config.webhooks=clone(RobData.webhooks or {})
    Config.settings=clone(RobData.settings or {})
end

local function loadData()
    local raw=LoadResourceFile(GetCurrentResourceName(),FILE)
    local ok,data=pcall(json.decode,raw or "{}")
    if not ok or type(data)~="table" then
        print("^1[m_roubos]^7 roubos.json inválido.")
        data={}
    end
    RobData.name=data.name or "Roubos de Comércio"
    RobData.locations=type(data.locations)=="table" and data.locations or {}
    RobData.setups=type(data.setups)=="table" and data.setups or {}
    RobData.webhooks=type(data.webhooks)=="table" and data.webhooks or {}
    RobData.settings=type(data.settings)=="table" and data.settings or {}
    apply()
end

local function saveData()
    if not SaveResourceFile(GetCurrentResourceName(),FILE,json.encode(RobData),-1) then
        return false,"Não foi possível salvar roubos.json."
    end
    apply()
    TriggerClientEvent("m_roubos:syncConfig",-1,RobData)
    TriggerEvent("m_roubos:serverConfigUpdated",RobData)
    return true
end

local function findLocation(typeName,id)
    id=tonumber(id)
    for i,v in ipairs(RobData.locations) do
        if tostring(v.type)==tostring(typeName) and tonumber(v.id)==id then return i,v end
    end
end

local function normalizeLocation(v)
    if type(v)~="table" then return nil,"Local inválido." end
    local typeName=trim(v.type)
    local id=tonumber(v.id)
    local x,y,z,h=tonumber(v.x),tonumber(v.y),tonumber(v.z),tonumber(v.h)
    if typeName=="" then return nil,"Informe o tipo do roubo." end
    if not id or id<1 then return nil,"ID inválido." end
    if not x or not y or not z or not h then return nil,"Coordenadas inválidas." end
    return {type=typeName,id=math.floor(id),x=x,y=y,z=z,h=h}
end

loadData()

RegisterNetEvent("m_roubos:requestConfig",function()
    TriggerClientEvent("m_roubos:syncConfig",source,RobData)
end)

exports("getRoubosConfig",function() return clone(RobData) end)

exports("saveRobberySetup",function(typeName,payload)
    typeName=trim(typeName)
    if typeName=="" then return false,"Tipo inválido." end
    payload=type(payload)=="table" and payload or {}

    local setup={
        items=type(payload.items)=="table" and clone(payload.items) or {},
        itemsNecessarios=type(payload.itemsNecessarios)=="table" and clone(payload.itemsNecessarios) or {},
        tempo=math.max(1,math.floor(tonumber(payload.tempo) or 1)),
        tempoEspera=math.max(0,math.floor(tonumber(payload.tempoEspera) or 0)),
        qntditem=math.max(0,math.floor(tonumber(payload.qntditem) or 0)),
        lspd=math.max(0,math.floor(tonumber(payload.lspd) or 0))
    }
    RobData.setups[typeName]=setup
    RobData.webhooks[typeName]=tostring(payload.webhook or RobData.webhooks[typeName] or "")
    return saveData()
end)

exports("addRobberyLocation",function(payload)
    local v,err=normalizeLocation(payload)
    if not v then return false,err end
    if findLocation(v.type,v.id) then return false,"Já existe um local deste tipo com este ID." end
    RobData.locations[#RobData.locations+1]=v
    return saveData()
end)

exports("updateRobberyLocation",function(originalType,originalId,payload)
    local i=findLocation(originalType,originalId)
    if not i then return false,"Local não encontrado." end
    local v,err=normalizeLocation(payload)
    if not v then return false,err end
    local other=findLocation(v.type,v.id)
    if other and other~=i then return false,"Já existe outro local com este tipo e ID." end
    RobData.locations[i]=v
    return saveData()
end)

exports("removeRobberyLocation",function(typeName,id)
    local i=findLocation(typeName,id)
    if not i then return false,"Local não encontrado." end
    table.remove(RobData.locations,i)
    return saveData()
end)

exports("saveRobberyGlobalSettings",function(payload)
    payload=type(payload)=="table" and payload or {}
    local policePermission=trim(payload.policePermission)
    if policePermission=="" then policePermission="perm.policia" end
    RobData.settings={
        policePermission=policePermission,
        blockedPermissions=type(payload.blockedPermissions)=="table" and clone(payload.blockedPermissions) or {},
        policeBlipSeconds=math.max(1,math.floor(tonumber(payload.policeBlipSeconds) or 45))
    }
    return saveData()
end)

exports("findRobberyRuntime",function(typeName,id)
    local _,loc=findLocation(typeName,id)
    if not loc then return nil,nil end
    return clone(loc),clone(RobData.setups[typeName])
end)
