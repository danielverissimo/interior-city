local CONFIG_FILE = "safezones.json"
local SafeData = { settings={}, safezones={}, whitelist={} }

local function trim(v)
    return tostring(v or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function clone(v)
    if type(v) ~= "table" then return v end
    local t={}
    for k,x in pairs(v) do t[k]=clone(x) end
    return t
end

local function loadData()
    local raw=LoadResourceFile(GetCurrentResourceName(),CONFIG_FILE)
    local ok,data=pcall(json.decode,raw or "{}")
    if not ok or type(data)~="table" then
        print("^1[PolySafeZone]^7 safezones.json inválido.")
        data={}
    end
    SafeData.settings=type(data.settings)=="table" and data.settings or {}
    SafeData.safezones=type(data.safezones)=="table" and data.safezones or {}
    SafeData.whitelist=type(data.whitelist)=="table" and data.whitelist or {}
end

local function saveData()
    local ok=SaveResourceFile(GetCurrentResourceName(),CONFIG_FILE,json.encode(SafeData),-1)
    if not ok then return false,"Não foi possível salvar safezones.json." end
    TriggerClientEvent("PolySafeZone:syncConfig",-1,SafeData)
    return true
end

local function findZone(name)
    name=trim(name)
    for i,z in ipairs(SafeData.safezones) do
        if tostring(z.name)==name then return i,z end
    end
end

local function normalizeCoords(coords)
    local out={}
    if type(coords)=="table" then
        for _,p in ipairs(coords) do
            local x=tonumber(p.x or p[1])
            local y=tonumber(p.y or p[2])
            if x and y then out[#out+1]={x=x,y=y} end
        end
    end
    return out
end

local function normalizeZone(payload)
    if type(payload)~="table" then return nil,"Dados inválidos." end
    local name=trim(payload.name)
    if name=="" then return nil,"Informe o nome da SafeZone." end

    local zones={}
    for _,poly in ipairs(payload.zones or {}) do
        local minZ=tonumber(poly.minZ)
        local maxZ=tonumber(poly.maxZ)
        local coords=normalizeCoords(poly.coords)
        if not minZ or not maxZ then return nil,"Defina minZ e maxZ de todos os polígonos." end
        if minZ>=maxZ then return nil,"minZ deve ser menor que maxZ." end
        if #coords<3 then return nil,"Cada polígono precisa de pelo menos 3 pontos." end
        zones[#zones+1]={minZ=minZ,maxZ=maxZ,coords=coords}
    end
    if #zones==0 then return nil,"A SafeZone precisa de pelo menos um polígono." end

    return {name=name,debug=payload.debug==true,zones=zones}
end

loadData()

RegisterNetEvent("PolySafeZone:requestConfig",function()
    TriggerClientEvent("PolySafeZone:syncConfig",source,SafeData)
end)

exports("getSafeZoneConfig",function()
    return clone(SafeData)
end)

exports("addSafeZone",function(payload)
    local z,err=normalizeZone(payload)
    if not z then return false,err end
    if findZone(z.name) then return false,"Já existe uma SafeZone com este nome." end
    SafeData.safezones[#SafeData.safezones+1]=z
    table.sort(SafeData.safezones,function(a,b) return tostring(a.name):lower()<tostring(b.name):lower() end)
    local ok,msg=saveData()
    if not ok then
        local i=findZone(z.name)
        if i then table.remove(SafeData.safezones,i) end
        return false,msg
    end
    return true,"SafeZone criada e sincronizada."
end)

exports("updateSafeZone",function(originalName,payload)
    local index=findZone(originalName)
    if not index then return false,"SafeZone não encontrada." end
    local z,err=normalizeZone(payload)
    if not z then return false,err end
    local collision=findZone(z.name)
    if collision and collision~=index then return false,"Já existe outra SafeZone com este nome." end
    local old=clone(SafeData.safezones[index])
    SafeData.safezones[index]=z
    table.sort(SafeData.safezones,function(a,b) return tostring(a.name):lower()<tostring(b.name):lower() end)
    local ok,msg=saveData()
    if not ok then
        local cur=findZone(z.name)
        if cur then SafeData.safezones[cur]=old end
        return false,msg
    end
    return true,"SafeZone atualizada e sincronizada."
end)

exports("removeSafeZone",function(name)
    local index=findZone(name)
    if not index then return false,"SafeZone não encontrada." end
    local old=table.remove(SafeData.safezones,index)
    -- remove referências da whitelist
    for i=#SafeData.whitelist,1,-1 do
        if tostring(SafeData.whitelist[i].zone)==tostring(name) then table.remove(SafeData.whitelist,i) end
    end
    local ok,msg=saveData()
    if not ok then
        table.insert(SafeData.safezones,index,old)
        return false,msg
    end
    return true,"SafeZone excluída e sincronizada."
end)

exports("updateSafeZoneSettings",function(payload)
    payload=type(payload)=="table" and payload or {}
    local loop=tonumber(payload.checkLoopTime)
    if not loop or loop<50 then return false,"CheckLoopTime deve ser no mínimo 50ms." end

    local wl={}
    for _,e in ipairs(payload.whitelist or {}) do
        local job=trim(e.job)
        local zone=trim(e.zone)
        local grade=tonumber(e.minGrade) or 0
        if job~="" and zone~="" then
            wl[#wl+1]={job=job,zone=zone,minGrade=math.floor(grade)}
        end
    end

    SafeData.settings={
        useESX=payload.useESX==true,
        useWhitelist=payload.useWhitelist==true,
        checkLoopTime=math.floor(loop)
    }
    SafeData.whitelist=wl
    local ok,msg=saveData()
    if not ok then return false,msg end
    return true,"Configurações da SafeZone atualizadas."
end)
