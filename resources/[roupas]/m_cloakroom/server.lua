local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vCLIENT = Tunnel.getInterface(GetCurrentResourceName())


RegisterServerEvent("mg-cloack:give_un")
AddEventHandler("mg-cloack:give_un",function(fardas)

    local source = source
    local user_id = vRP.getUserId(source)
    local custom = fardas

    if custom then

        local old_custom = vRPclient.getCustomization(source)
        local idle_copy = {}
        
        local masc = 1885233650
        local fem = -1667301416

        ped = GetPlayerPed(source)
        local getmd = GetEntityModel(ped)
       
        idle_copy = vRP.save_idle_custom(source,old_custom)
        idle_copy.modelhash = nil

        if getmd == masc then
            for k,v in pairs(custom.masculino or {}) do
                local component = tonumber(k) or k

                -- Componente 2 = cabelo. Fardamento nunca altera cabelo.
                if component ~= 2 then
                    idle_copy[component] = v
                end
            end
        elseif getmd == fem then
            for k,v in pairs(custom.feminino or {}) do
                local component = tonumber(k) or k

                -- Componente 2 = cabelo. Fardamento nunca altera cabelo.
                if component ~= 2 then
                    idle_copy[component] = v
                end
            end
        end

        vRPclient._setCustomization(source,idle_copy)
    end
end)


RegisterServerEvent("mg-cloack:off_un")
AddEventHandler("mg-cloack:off_un",function()
    local user_id = vRP.getUserId(source)
    vRP.removeCloak(source)
end)

function src.checkPerm(perm)

    local source = source
    local user_id = vRP.getUserId(source)

    if user_id then
        if vRP.hasPermission(user_id, perm) then
            return true
        else
            TriggerClientEvent('Notify', source, 'negado','Você não possui permissão',5000)
            return false
        end
    end


end








-------------------------------------------------------------------------------------------
---- CONFIG MANAGER JSON
-------------------------------------------------------------------------------------------
local CONFIG_FILE = "config.json"
local CloakroomConfig = { cloakrooms = {} }

local function normalizeCoords(c)
    if type(c) ~= "table" then return nil end
    local x,y,z = tonumber(c.x or c[1]),tonumber(c.y or c[2]),tonumber(c.z or c[3])
    if not x or not y or not z then return nil end
    return { x=x,y=y,z=z }
end

local function sanitizeOutfit(outfit)
    local out = {}
    for k,v in pairs(type(outfit) == "table" and outfit or {}) do
        if type(v) == "table" then
            out[tostring(k)] = v
        end
    end
    return out
end

local function sanitizeRoom(room)
    if type(room) ~= "table" then return nil,"Dados inválidos." end
    local name = tostring(room.name or ""):gsub("^%s+",""):gsub("%s+$","")
    if name == "" then return nil,"Informe o nome do Blip Fardamento." end
    local coords = normalizeCoords(room.coords)
    if not coords then return nil,"Coordenadas inválidas." end

    local uniforms = {}
    for _,u in ipairs(type(room.uniforms) == "table" and room.uniforms or {}) do
        local uname = tostring(u.name or ""):gsub("^%s+",""):gsub("%s+$","")
        if uname ~= "" then
            uniforms[#uniforms+1] = {
                name = uname,
                masculino = sanitizeOutfit(u.masculino),
                feminino = sanitizeOutfit(u.feminino)
            }
        end
    end

    return {
        name=name,
        permission=tostring(room.permission or ""),
        coords=coords,
        uniforms=uniforms
    }
end

local function loadConfig()
    local raw = LoadResourceFile(GetCurrentResourceName(),CONFIG_FILE)
    local ok,data = pcall(json.decode,raw or "{}")
    CloakroomConfig = ok and type(data)=="table" and data or {cloakrooms={}}
    if type(CloakroomConfig.cloakrooms) ~= "table" then CloakroomConfig.cloakrooms = {} end
end

local function findRoom(name)
    for i,room in ipairs(CloakroomConfig.cloakrooms) do
        if tostring(room.name) == tostring(name) then return i,room end
    end
end

local function sync(target)
    TriggerClientEvent("m_cloakroom:fullSync",target,CloakroomConfig.cloakrooms)
end

local function saveConfig()
    if not SaveResourceFile(GetCurrentResourceName(),CONFIG_FILE,json.encode(CloakroomConfig),-1) then
        return false,"Não foi possível salvar config.json."
    end
    sync(-1)
    return true
end

loadConfig()

RegisterNetEvent("m_cloakroom:requestSync",function()
    sync(source)
end)

AddEventHandler("vRP:playerSpawn",function(userId,nSource)
    sync(nSource)
end)

exports("getCloakrooms",function()
    return CloakroomConfig.cloakrooms
end)

exports("upsertCloakroom",function(originalName,data)
    local room,err = sanitizeRoom(data)
    if not room then return false,err end

    originalName = tostring(originalName or "")
    local index = originalName ~= "" and findRoom(originalName) or nil
    local duplicate = findRoom(room.name)

    if duplicate and duplicate ~= index then
        return false,"Já existe um Blip Fardamento com esse nome."
    end

    if index then
        CloakroomConfig.cloakrooms[index] = room
    else
        CloakroomConfig.cloakrooms[#CloakroomConfig.cloakrooms+1] = room
    end

    table.sort(CloakroomConfig.cloakrooms,function(a,b)
        return tostring(a.name):lower() < tostring(b.name):lower()
    end)

    local ok,msg = saveConfig()
    if not ok then loadConfig(); return false,msg end
    return true,index and "Blip Fardamento atualizado." or "Blip Fardamento criado."
end)

exports("removeCloakroom",function(name)
    local index = findRoom(name)
    if not index then return false,"Blip Fardamento não encontrado." end
    table.remove(CloakroomConfig.cloakrooms,index)
    local ok,msg=saveConfig()
    if not ok then loadConfig(); return false,msg end
    return true,"Blip Fardamento removido."
end)

exports("reloadCloakrooms",function()
    loadConfig()
    sync(-1)
    return true
end)
