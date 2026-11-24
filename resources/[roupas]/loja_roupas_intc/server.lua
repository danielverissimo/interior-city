local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vCLIENT = Tunnel.getInterface(GetCurrentResourceName())


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

local editing = {}

local function accessibleRoom(player, name)
    if type(name) ~= 'string' then return nil end
    local _, room = findRoom(name)
    local user = vRP.getUserId(player)
    local ped = GetPlayerPed(player)
    if not room or not user or ped == 0 then return nil end
    local position = GetEntityCoords(ped)
    local coords = room.coords
    if #(position - vector3(coords.x, coords.y, coords.z)) > 2.0 then return nil end
    if room.permission ~= '' and not vRP.hasPermission(user, room.permission) then return nil end
    return room, ped
end

function src.openRoom(name)
    if accessibleRoom(source, name) then return true end
    TriggerClientEvent('Notify', source, 'negado', 'Vestiário indisponível ou sem permissão.', 5000)
    return false
end

function src.equipUniform(name, index)
    local player = source
    if type(index) ~= 'number' or index % 1 ~= 0 or editing[player] then return false end
    local room, ped = accessibleRoom(player, name)
    local uniform = room and room.uniforms and room.uniforms[index]
    if not uniform then return false end

    local model = GetEntityModel(ped)
    local outfit
    if model == GetHashKey('mp_m_freemode_01') then outfit = uniform.masculino
    elseif model == GetHashKey('mp_f_freemode_01') then outfit = uniform.feminino end
    if type(outfit) ~= 'table' or next(outfit) == nil then return false end

    editing[player] = true
    local ok, equipped = pcall(function()
        local current = vRPclient.getCustomization(player)
        if type(current) ~= 'table' or not accessibleRoom(player, name) then return false end
        local customization = vRP.save_idle_custom(player, current)
        if type(customization) ~= 'table' or next(customization) == nil then return false end
        customization.modelhash, customization.pedModel = nil, nil
        for key, value in pairs(outfit) do
            local component = tonumber(key) or key
            if component ~= 2 then customization[component] = value end
        end
        vRPclient._setCustomization(player, customization)
        return true
    end)
    editing[player] = nil
    if not ok then print('[m_cloakroom] Falha ao vestir uniforme: ' .. tostring(equipped)) end
    return ok and equipped == true
end

function src.removeUniform(name)
    local player = source
    if editing[player] or not accessibleRoom(player, name) then return false end
    vRP.removeCloak(player)
    return true
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

local editableParts = {'1','3','4','5','6','7','8','9','10','11','p0','p1','p2','p6','p7'}

local function ownerRoom(player, name)
    local user = vRP.getUserId(player)
    if not user or vRP.hasGroup(user, 'dono') ~= true then return nil end
    return accessibleRoom(player, name)
end

function src.canEditUniforms(name)
    return ownerRoom(source, name) ~= nil
end

function src.getUniformEditor(name)
    local room = ownerRoom(source, name)
    return room and room.uniforms or false
end

function src.saveUniformNumbers(name, index, gender, values)
    local room = ownerRoom(source, name)
    if not room or type(index) ~= 'number' or index % 1 ~= 0
        or (gender ~= 'masculino' and gender ~= 'feminino') or type(values) ~= 'table' then return false end
    local uniform = room.uniforms[index]
    if not uniform then return false end
    local previous = uniform[gender] or {}
    local nextOutfit = {}
    for key, value in pairs(previous) do nextOutfit[key] = value end
    for _, key in ipairs(editableParts) do
        local input = values[key]
        if input ~= nil then
            if type(input) ~= 'table' then return false end
            local model, texture = tonumber(input[1]), tonumber(input[2])
            local minimum = key:sub(1, 1) == 'p' and -1 or 0
            if not model or model % 1 ~= 0 or model < minimum or model > 9999
                or not texture or texture % 1 ~= 0 or texture < 0 or texture > 999 then return false end
            nextOutfit[key] = {model, texture, previous[key] and previous[key][3] or 0}
        end
    end
    uniform[gender] = nextOutfit
    if not saveConfig() then
        uniform[gender] = previous
        return false
    end
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
