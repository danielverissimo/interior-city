--[[
    Toca do Mago - AUTH V2 integrada ao server-side.
    Este bloco faz parte do próprio código protegido do produto.
]]
local __tdmAuth = {
    endpoint = "http://104.234.65.115/auth.php",
    product = "mansoesv1",
    state = {
        authorized = false,
        ready = false,
        serverName = nil,
        productName = "mansoesv1",
        reason = "not_checked"
    }
}

function __tdmAuth.encode(value)
    return tostring(value):gsub("([^%w%-_%.~])", function(char)
        return string.format("%%%02X", string.byte(char))
    end)
end

function __tdmAuth.setState(authorized, reason, serverName, productName)
    local state = __tdmAuth.state
    state.authorized = authorized == true
    state.ready = true
    state.reason = reason or (state.authorized and "authorized" or "unknown")
    state.serverName = serverName
    state.productName = productName or __tdmAuth.product
end

function __tdmAuth.check(silent)
    local product = __tdmAuth.product
    local url = __tdmAuth.endpoint .. "?index=" .. __tdmAuth.encode(product)

    PerformHttpRequest(url, function(statusCode, body)
        local state = __tdmAuth.state
        if statusCode ~= 200 or type(body) ~= "string" or body == "" then
            local wasAuthorized = state.authorized
            __tdmAuth.setState(false, "http_" .. tostring(statusCode))
            if not silent or wasAuthorized then
                print(("^1[Toca do Mago] AUTH indisponível para [%s]. HTTP: %s^0"):format(product, tostring(statusCode)))
            end
            return
        end

        local ok, data = pcall(json["decode"], body)
        if not ok or type(data) ~= "table" then
            local wasAuthorized = state.authorized
            __tdmAuth.setState(false, "invalid_response")
            if not silent or wasAuthorized then
                print(("^1[Toca do Mago] Resposta inválida da AUTH para [%s].^0"):format(product))
            end
            return
        end

        if data.authorized == true then
            local serverName = data.server and data.server.name or "Servidor autorizado"
            local productName = data.product and data.product.name or product
            local wasAuthorized = state.authorized
            __tdmAuth.setState(true, "authorized", serverName, productName)
            if not silent or not wasAuthorized then
                print(("^2[Toca do Mago] %s [%s] autenticado com sucesso para: %s^0"):format(productName, product, serverName))
            end
            return
        end

        local wasAuthorized = state.authorized
        __tdmAuth.setState(false, data.reason or "not_authorized")
        if not silent or wasAuthorized then
            print(("^1[Toca do Mago] Script [%s] NÃO autenticado. Motivo: %s^0"):format(product, state.reason))
        end
    end, "GET", "", {
        ["Accept"] = "application/json",
        ["User-Agent"] = "TDM-FiveM-Auth/2",
        ["Cache-Control"] = "no-cache"
    })
end

function __tdmAuth.ready()
    return __tdmAuth.state.ready == true
end

function __tdmAuth.authorized()
    return __tdmAuth.state.ready == true and __tdmAuth.state.authorized == true
end

function __tdmAuth.snapshot()
    local state = __tdmAuth.state
    return {
        authorized = state.authorized,
        ready = state.ready,
        serverName = state.serverName,
        productName = state.productName,
        productIndex = __tdmAuth.product,
        reason = state.reason
    }
end

CreateThread(function()
    __tdmAuth.check(false)
    while true do
        Wait(15 * 60 * 1000)
        __tdmAuth.check(true)
    end
end)

local vRP = MG_MANSIONS_VRP
local vRPclient = MG_MANSIONS_VRPCLIENT
local API = MG_MANSIONS_API

if type(vRP) ~= "table" or type(vRPclient) ~= "table" or type(API) ~= "table" then
    error("m_mansions stable server bridge was not initialised before the protected core.")
end

local function authAllowed()
    return __tdmAuth.ready() and __tdmAuth.authorized()
end

local function notifyAuthDenied(src)
    src = tonumber(src)
    if src and src > 0 then
        TriggerClientEvent('Notify',src,'negado','SCRIPT NÃO AUTENTICADO!',6000)
    end
end

local DATA = { version = 1, mansions = {} }
local purchaseLocks = {}
local syncFurniture

local function trim(v)
    return tostring(v or ''):gsub('^%s+',''):gsub('%s+$','')
end

local function slugify(v)
    local value = trim(v):lower()
    value = value:gsub('[áàâãä]','a'):gsub('[éèêë]','e'):gsub('[íìîï]','i')
    value = value:gsub('[óòôõö]','o'):gsub('[úùûü]','u'):gsub('ç','c')
    value = value:gsub('[^%w]+','_'):gsub('^_+',''):gsub('_+$','')
    return value
end

local function copy(value)
    if type(value) ~= 'table' then return value end
    local out = {}
    for k,v in pairs(value) do out[k] = copy(v) end
    return out
end

local function validCoords(c)
    return type(c) == 'table'
        and tonumber(c.x) ~= nil
        and tonumber(c.y) ~= nil
        and tonumber(c.z) ~= nil
end

local function normalCoords(c)
    return { x = tonumber(c.x), y = tonumber(c.y), z = tonumber(c.z) }
end

local function normalSpawn(c)
    return {
        x = tonumber(c.x), y = tonumber(c.y), z = tonumber(c.z),
        w = tonumber(c.w or c.h or c.heading) or 0.0
    }
end

local function safeExport(resource, exportName, ...)
    if not authAllowed() then return false, 'SCRIPT NÃO AUTENTICADO!' end
    if GetResourceState(resource) ~= 'started' then
        return false, ('O resource %s não está iniciado.'):format(resource)
    end
    local args = {...}
    local ok,a,b,c = pcall(function()
        local proxy = exports[resource]
        local fn = proxy[exportName]
        if not fn then error(('Export %s não encontrado em %s'):format(exportName,resource)) end
        return fn(proxy, table.unpack(args))
    end)
    if not ok then
        print(('^1[m_mansions]^7 %s:%s -> %s'):format(resource,exportName,tostring(a)))
        return false, ('Falha ao comunicar com %s.'):format(resource)
    end
    return a,b,c
end

local function loadData()
    local raw = MG_MANSIONS_STORAGE_READ and MG_MANSIONS_STORAGE_READ(Config["DataFile"]) or nil
    if raw and raw ~= '' then
        local ok,decoded = pcall(json["decode"],raw)
        if ok and type(decoded) == 'table' then
            DATA = decoded
        end
    end
    DATA.version = 1
    DATA.mansions = type(DATA.mansions) == 'table' and DATA.mansions or {}
end

local function saveData()
    if not authAllowed() then return false end
    local encoded = json["encode"](DATA,{indent=true})
    if not encoded or encoded == '' then
        print('^1[m_mansions]^7 Falha ao codificar mansions.json.')
        return false
    end

    if type(MG_MANSIONS_STORAGE_WRITE) ~= 'function' then
        print('^1[m_mansions]^7 Bridge de persistência indisponível.')
        return false
    end

    local ok, reason = MG_MANSIONS_STORAGE_WRITE(Config["DataFile"], encoded)
    if not ok then
        print(('^1[m_mansions]^7 Falha ao persistir %s: %s'):format(Config["DataFile"], tostring(reason or 'erro desconhecido')))
        return false
    end

    return true
end

local function findMansion(id)
    id = tostring(id or '')
    for index,m in ipairs(DATA.mansions) do
        if tostring(m.id) == id then return m,index end
    end
end

local function identityLabel(userId)
    local identity = vRP["getUserIdentity"] and vRP["getUserIdentity"](tonumber(userId)) or nil
    if not identity then return ('ID %s'):format(userId) end
    local first = trim(identity.nome or identity.name)
    local last = trim(identity.sobrenome or identity.firstname or identity.name2)
    local name = trim(first..' '..last)
    return name ~= '' and name or ('ID %s'):format(userId)
end

local function membersInfo(mansion)
    local out = {}
    if tonumber(mansion.ownerId) then
        out[#out+1] = { id=tonumber(mansion.ownerId), name=identityLabel(mansion.ownerId), owner=true }
    end
    for _,id in ipairs(mansion.members or {}) do
        id = tonumber(id)
        if id and id ~= tonumber(mansion.ownerId) then
            out[#out+1] = { id=id, name=identityLabel(id), owner=false }
        end
    end
    return out
end

local function publicMansions()
    local out = {}
    for _,m in ipairs(DATA.mansions) do
        out[#out+1] = {
            id=m.id,
            name=m.name,
            price=tonumber(m.price) or 0,
            iptuValue=tonumber(m.iptuValue) or 0,
            iptuPaidUntil=tonumber(m.iptuPaidUntil) or 0,
            maxResidents=tonumber(m.maxResidents) or 1,
            purchaseCoords=copy(m.purchaseCoords),
            occupied=tonumber(m.ownerId) ~= nil
        }
    end
    return out
end

local function syncClients(target)
    TriggerClientEvent('m_mansions:sync',target or -1,publicMansions())
end

local function isCleanupStaff(userId)
    userId = tonumber(userId)
    if not userId then return false end
    for group in pairs(Config["CleanupStaffGroups"] or {}) do
        if vRP["hasGroup"] and vRP["hasGroup"](userId,group) then return true end
    end
    return false
end

local function normalizeMansion(payload,existing)
    if type(payload) ~= 'table' then return nil,'Dados da mansão inválidos.' end

    local name = trim(payload.name)
    local group = trim(payload.group)
    if name == '' then return nil,'Informe o nome da mansão.' end
    if group == '' then return nil,'Informe o cargo da mansão.' end

    local id = existing and tostring(existing.id) or slugify(name)
    if id == '' then return nil,'Não foi possível gerar o identificador da mansão.' end

    local permission = 'perm.'..slugify(group):gsub('_','')
    if permission == 'perm.' then return nil,'Cargo da mansão inválido.' end

    local price = tonumber(payload.price)
    if not price or price < 0 then return nil,'Informe um valor válido para a mansão.' end

    local iptuValue = tonumber(payload.iptuValue)
    if not iptuValue or iptuValue <= 0 then return nil,'Informe um valor válido para o IPTU.' end

    local voucher = trim(payload.voucher)
    if not Config["AllowedVouchers"][voucher] then return nil,'Selecione um vale mansão válido.' end

    local maxResidents = math.floor(tonumber(payload.maxResidents) or 0)
    if maxResidents < 1 then return nil,'A mansão precisa permitir ao menos 1 morador.' end
    if existing then
        local occupied = (existing.ownerId and 1 or 0) + #(existing.members or {})
        if maxResidents < occupied then
            return nil,('Esta mansão possui %d morador(es). O limite não pode ser menor que a ocupação atual.'):format(occupied)
        end
    end

    if not validCoords(payload.purchaseCoords) then return nil,'Defina corretamente o local de compra da mansão.' end

    local chest = payload.chest or {}
    local normalizedChest = { enabled = chest.enabled == true }
    if normalizedChest.enabled then
        if not validCoords(chest.coords) then return nil,'Defina corretamente a posição do baú.' end
        local weight = tonumber(chest.weight)
        if not weight or weight <= 0 then return nil,'Informe um peso válido para o baú.' end
        normalizedChest.coords = normalCoords(chest.coords)
        normalizedChest.weight = weight
        normalizedChest.name = existing and existing.chest and existing.chest.name or ('Mansao_'..id)
    end

    local garage = payload.garage or {}
    local normalizedGarage = { enabled = garage.enabled == true }
    if normalizedGarage.enabled then
        if not validCoords(garage.coords) then return nil,'Defina corretamente o marker da garagem.' end
        if trim(garage.type) == '' then return nil,'Selecione o tipo da garagem.' end
        local spawns = {}
        for _,s in ipairs(garage.spawnCoords or {}) do
            if validCoords(s) and tonumber(s.w or s.h or s.heading) ~= nil then
                spawns[#spawns+1] = normalSpawn(s)
            end
        end
        if #spawns == 0 then return nil,'Cadastre ao menos uma posição de veículo para a garagem.' end
        normalizedGarage.id = existing and existing.garage and existing.garage.id or ('Mansao_'..id)
        normalizedGarage.type = trim(garage.type)
        normalizedGarage.blipDistance = tonumber(garage.blipDistance) or 5.0
        normalizedGarage.coords = normalCoords(garage.coords)
        normalizedGarage.spawnCoords = spawns
    end

    local doors = {}
    for _,door in ipairs(payload.doors or {}) do
        if type(door) == 'table' and tonumber(door.hash) and validCoords(door) then
            doors[#doors+1] = {
                hash=tonumber(door.hash), x=tonumber(door.x), y=tonumber(door.y), z=tonumber(door.z),
                dist=tonumber(door.dist) or 5.0, text=door.text ~= false,
                isGate=door.isGate == true, lock=true
            }
        end
    end

    return {
        id=id,
        name=name,
        group=group,
        permission=permission,
        price=math.floor(price),
        iptuValue=math.floor(iptuValue),
        iptuPaidUntil=existing and tonumber(existing.iptuPaidUntil) or nil,
        lastIptuPaidAt=existing and tonumber(existing.lastIptuPaidAt) or nil,
        voucher=voucher,
        maxResidents=maxResidents,
        purchaseCoords=normalCoords(payload.purchaseCoords),
        chest=normalizedChest,
        garage=normalizedGarage,
        doors=doors,
        ownerId=existing and existing.ownerId or nil,
        members=existing and copy(existing.members or {}) or {},
        furniture=existing and copy(existing.furniture or {}) or {},
        createdAt=existing and existing.createdAt or os.time(),
        updatedAt=os.time()
    }
end

local function ensureMansionGroup(mansion)
    if not mansion then return false,'Mansão inválida.' end
    -- O cargo da mansão é parte obrigatória do cadastro. Usamos um export
    -- idempotente da vRP para criar/reparar o cargo e a permissão no JSON +
    -- runtime, inclusive para mansões antigas cujo cargo tenha sido apagado.
    local ok,msg = safeExport(Config["VrpResource"],'ensureManagedGroup',
        mansion.group,
        mansion.permission,
        { title=mansion.name }
    )
    return ok,msg
end

local function applyGroup(existing,mansion)
    local original = existing and existing.group or ''

    -- Se o cargo foi renomeado, preserva o fluxo normal do gerenciador de
    -- cargos para migrar jogadores e depois garante o novo registro.
    if original ~= '' and original ~= mansion.group then
        local ok,msg = safeExport(Config["VrpResource"],'saveManagedGroup',original,{
            name=mansion.group,
            permissions={mansion.permission},
            config={title=mansion.name}
        })
        if not ok then return false,msg end
    end

    return ensureMansionGroup(mansion)
end

local function applyChest(existing,mansion)
    local old = existing and existing.chest or nil
    local new = mansion.chest

    if old and old.enabled and (not new.enabled or old.name ~= new.name) then
        local ok,msg = safeExport(Config["InventoryResource"],'removeChest',old.name)
        if not ok then return false,msg end
    end

    if not new.enabled then return true end

    if old and old.enabled and old.name == new.name then
        return safeExport(Config["InventoryResource"],'updateChest',new.name,new.weight,new.coords,mansion.permission)
    end

    return safeExport(Config["InventoryResource"],'addChest',new.name,new.weight,mansion.permission,new.coords)
end

local function garagePayload(mansion)
    return {
        id=mansion.garage.id,
        type=mansion.garage.type,
        blipDistance=mansion.garage.blipDistance,
        permiss=mansion.permission,
        coords=mansion.garage.coords,
        spawnCoords=mansion.garage.spawnCoords
    }
end

local function applyGarage(existing,mansion)
    local old = existing and existing.garage or nil
    local new = mansion.garage

    if old and old.enabled and (not new.enabled or old.id ~= new.id) then
        local ok,msg = safeExport(Config["GarageResource"],'removeGarage',old.id)
        if not ok then return false,msg end
    end

    if not new.enabled then return true end

    if old and old.enabled and old.id == new.id then
        return safeExport(Config["GarageResource"],'updateGarage',old.id,garagePayload(mansion))
    end

    return safeExport(Config["GarageResource"],'addGarage',garagePayload(mansion))
end

local function applyDoors(existing,mansion)
    local newDoors = mansion.doors or {}
    local oldDoors = existing and existing.doors or {}

    -- Mansão sem porta/tranca é válida. Para um cadastro novo não fazemos nem
    -- chamada ao doorsv2 quando a lista está vazia, então a mansão pode ser
    -- salva normalmente mesmo sem nenhuma tranca cadastrada.
    if #newDoors == 0 then
        if existing and #oldDoors > 0 then
            return safeExport(Config["DoorsResource"],'removeMansionDoors',mansion.id)
        end
        return true,'Mansão sem trancas.'
    end

    return safeExport(Config["DoorsResource"],'replaceMansionDoors',mansion.id,mansion.permission,newDoors)
end

local function rollbackIntegrations(old,new)
    if old then
        -- Restaura o cargo inclusive se ele tiver sido renomeado.
        pcall(function()
            safeExport(Config["VrpResource"],'saveManagedGroup',new.group,{
                name=old.group,
                permissions={old.permission},
                config={title=old.name}
            })
        end)

        pcall(function()
            if new.chest and new.chest.enabled and (not old.chest or not old.chest.enabled or new.chest.name~=old.chest.name) then
                safeExport(Config["InventoryResource"],'removeChest',new.chest.name)
            end
            if old.chest and old.chest.enabled then
                safeExport(Config["InventoryResource"],'removeChest',old.chest.name)
                safeExport(Config["InventoryResource"],'addChest',old.chest.name,old.chest.weight,old.permission,old.chest.coords)
            end
        end)

        pcall(function()
            if new.garage and new.garage.enabled and (not old.garage or not old.garage.enabled or new.garage.id~=old.garage.id) then
                safeExport(Config["GarageResource"],'removeGarage',new.garage.id)
            end
            if old.garage and old.garage.enabled then
                safeExport(Config["GarageResource"],'removeGarage',old.garage.id)
                safeExport(Config["GarageResource"],'addGarage',garagePayload(old))
            end
        end)

        pcall(function() safeExport(Config["DoorsResource"],'replaceMansionDoors',old.id,old.permission,old.doors or {}) end)
    else
        pcall(function()
            if new.chest and new.chest.enabled then safeExport(Config["InventoryResource"],'removeChest',new.chest.name) end
        end)
        pcall(function()
            if new.garage and new.garage.enabled then safeExport(Config["GarageResource"],'removeGarage',new.garage.id) end
        end)
        pcall(function() safeExport(Config["DoorsResource"],'removeMansionDoors',new.id) end)
        pcall(function() safeExport(Config["VrpResource"],'removeManagedGroup',new.group) end)
    end
end


local iptuPromptLocks = {}

local function findMansionByPermission(permission)
    permission = trim(permission)
    if permission == '' then return nil end
    for _,m in ipairs(DATA.mansions or {}) do
        if tostring(m.permission or '') == permission then return m end
    end
end

local function mansionResident(mansion,userId)
    userId = tonumber(userId)
    if not mansion or not userId then return false end
    if tonumber(mansion.ownerId) == userId then return true end
    for _,id in ipairs(mansion.members or {}) do
        if tonumber(id) == userId then return true end
    end
    return false
end

local function formatMoney(value)
    local s = tostring(math.floor(tonumber(value) or 0))
    local out = s:reverse():gsub('(%d%d%d)','%1.'):reverse()
    if out:sub(1,1) == '.' then out = out:sub(2) end
    return out
end

local function checkIptuAccess(source,userId,mansion)
    if not mansion or not mansion.ownerId then return true end
    if not mansionResident(mansion,userId) then return true end

    local cycleSeconds = (tonumber(Config["IptuCycleDays"]) or 20) * 86400
    local dueAt = tonumber(mansion.iptuPaidUntil) or 0
    if dueAt <= 0 then
        mansion.lastIptuPaidAt = os.time()
        mansion.iptuPaidUntil = os.time() + cycleSeconds
        saveData()
        return true
    end

    if os.time() < dueAt then return true end

    local key = ('%s:%s'):format(tostring(userId),tostring(mansion.id))
    if iptuPromptLocks[key] then return false end
    iptuPromptLocks[key] = true

    local value = math.max(0,math.floor(tonumber(mansion.iptuValue) or 0))
    if value <= 0 then
        iptuPromptLocks[key] = nil
        TriggerClientEvent('Notify',source,'negado','O IPTU desta residência não está configurado corretamente.',6000)
        return false
    end

    local confirm = vRP["request"](source,('Deseja pagar o IPTU no valor de <b>R$ %s</b> desta residência?'):format(formatMoney(value)),30)
    if not confirm then
        TriggerClientEvent('Notify',source,'negado','Você não poderá acessar nada nesta residência enquanto não pagar o IPTU',6000)
        iptuPromptLocks[key] = nil
        return false
    end

    if not vRP["tryFullPayment"](userId,value) then
        TriggerClientEvent('Notify',source,'negado',('Você não possui R$ %s para pagar o IPTU desta residência.'):format(formatMoney(value)),6000)
        iptuPromptLocks[key] = nil
        return false
    end

    local oldPaidAt,oldPaidUntil = mansion.lastIptuPaidAt,mansion.iptuPaidUntil
    mansion.lastIptuPaidAt = os.time()
    mansion.iptuPaidUntil = os.time() + cycleSeconds

    if not saveData() then
        mansion.lastIptuPaidAt,mansion.iptuPaidUntil = oldPaidAt,oldPaidUntil
        if vRP["giveBankMoney"] then vRP["giveBankMoney"](userId,value) else vRP["giveMoney"](userId,value) end
        TriggerClientEvent('Notify',source,'negado','Não foi possível salvar o pagamento do IPTU. O valor foi devolvido.',7000)
        iptuPromptLocks[key] = nil
        return false
    end

    TriggerClientEvent('Notify',source,'sucesso',('IPTU da %s pago com sucesso. Próximo vencimento em %d dias.'):format(tostring(mansion.name or 'residência'),tonumber(Config["IptuCycleDays"]) or 20),7000)
    iptuPromptLocks[key] = nil
    return true
end

MG_MANSIONS_REGISTER_EXPORT('checkAccessByPermission',function(source,permission)
    if not authAllowed() then return false end
    source = tonumber(source)
    if not source then return true end
    local userId = vRP["getUserId"](source)
    if not userId then return false end
    local mansion = findMansionByPermission(permission)
    if not mansion then return true end
    return checkIptuAccess(source,userId,mansion)
end)

MG_MANSIONS_REGISTER_EXPORT('checkAccessByMansionId',function(source,mansionId)
    if not authAllowed() then return false end
    source = tonumber(source)
    if not source then return true end
    local userId = vRP["getUserId"](source)
    if not userId then return false end
    local mansion = findMansion(mansionId)
    if not mansion then return true end
    return checkIptuAccess(source,userId,mansion)
end)

MG_MANSIONS_REGISTER_EXPORT('getMansions',function()
    if not authAllowed() then return { version = 1, mansions = {} } end
    local out = copy(DATA)
    for _,m in ipairs(out.mansions or {}) do
        m.residents = membersInfo(m)
        m.occupiedCount = (m.ownerId and 1 or 0) + #(m.members or {})
    end
    return out
end)

MG_MANSIONS_REGISTER_EXPORT('saveMansion',function(originalId,payload)
    if not authAllowed() then return false,'SCRIPT NÃO AUTENTICADO!' end
    local existing,index = findMansion(originalId)
    local mansion,err = normalizeMansion(payload,existing)
    if not mansion then return false,err end

    for _,other in ipairs(DATA.mansions) do
        if other ~= existing then
            if tostring(other.id) == mansion.id then return false,'Já existe uma mansão com este nome.' end
            if tostring(other.group):lower() == mansion.group:lower() then return false,'Este cargo já está vinculado a outra mansão.' end
        end
    end

    local old = existing and copy(existing) or nil

    local ok,msg = applyGroup(existing,mansion)
    if not ok then
        return false,('Falha no cargo: %s'):format(msg or 'Não foi possível criar o cargo da mansão.')
    end

    ok,msg = applyChest(existing,mansion)
    if not ok then
        rollbackIntegrations(old,mansion)
        return false,('Falha no baú: %s'):format(msg or 'Não foi possível configurar o baú da mansão.')
    end

    ok,msg = applyGarage(existing,mansion)
    if not ok then
        rollbackIntegrations(old,mansion)
        return false,('Falha na garagem: %s'):format(msg or 'Não foi possível configurar a garagem da mansão.')
    end

    ok,msg = applyDoors(existing,mansion)
    if not ok then
        rollbackIntegrations(old,mansion)
        return false,('Falha nas trancas: %s'):format(msg or 'Não foi possível configurar as trancas da mansão.')
    end

    if index then DATA.mansions[index] = mansion else DATA.mansions[#DATA.mansions+1] = mansion end

    if not saveData() then
        if index then DATA.mansions[index] = old else table.remove(DATA.mansions,#DATA.mansions) end
        rollbackIntegrations(old,mansion)
        return false,'Não foi possível salvar mansions.json.'
    end

    syncClients(-1)
    return true, existing and 'Mansão atualizada com sucesso.' or 'Mansão cadastrada com sucesso.'
end)

local function alreadyMissing(message)
    local m = tostring(message or ''):lower()
    return m:find('não existe',1,true) ~= nil
        or m:find('nao existe',1,true) ~= nil
        or m:find('não encontrado',1,true) ~= nil
        or m:find('nao encontrado',1,true) ~= nil
        or m:find('não encontrada',1,true) ~= nil
        or m:find('nao encontrada',1,true) ~= nil
        or m:find('inexistente',1,true) ~= nil
end

MG_MANSIONS_REGISTER_EXPORT('removeMansion',function(id)
    if not authAllowed() then return false,'SCRIPT NÃO AUTENTICADO!' end
    local mansion,index = findMansion(id)
    if not mansion then return false,'Mansão não encontrada.' end
    if mansion.ownerId then return false,'Esta mansão possui dono. Use /limparmansao antes de excluí-la.' end

    local snapshot = copy(mansion)
    local chestRemoved,garageRemoved,doorsRemoved,groupRemoved = false,false,false,false

    local function rollbackDelete()
        if groupRemoved then
            safeExport(Config["VrpResource"],'saveManagedGroup','',{
                name=snapshot.group,
                permissions={snapshot.permission},
                config={title=snapshot.name}
            })
        end
        if chestRemoved and snapshot.chest and snapshot.chest.enabled then
            safeExport(Config["InventoryResource"],'addChest',snapshot.chest.name,snapshot.chest.weight,snapshot.permission,snapshot.chest.coords)
        end
        if garageRemoved and snapshot.garage and snapshot.garage.enabled then
            safeExport(Config["GarageResource"],'addGarage',garagePayload(snapshot))
        end
        if doorsRemoved then
            safeExport(Config["DoorsResource"],'replaceMansionDoors',snapshot.id,snapshot.permission,snapshot.doors or {})
        end
    end

    if mansion.chest and mansion.chest.enabled then
        local ok,msg = safeExport(Config["InventoryResource"],'removeChest',mansion.chest.name)
        if not ok and not alreadyMissing(msg) then return false,msg end
        chestRemoved=ok == true
    end

    if mansion.garage and mansion.garage.enabled then
        local ok,msg = safeExport(Config["GarageResource"],'removeGarage',mansion.garage.id)
        if not ok and not alreadyMissing(msg) then rollbackDelete(); return false,msg end
        garageRemoved=ok == true
    end

    local ok,msg = safeExport(Config["DoorsResource"],'removeMansionDoors',mansion.id)
    if not ok and not alreadyMissing(msg) then rollbackDelete(); return false,msg end
    doorsRemoved=ok == true

    ok,msg = safeExport(Config["VrpResource"],'removeManagedGroup',mansion.group)
    if not ok and not alreadyMissing(msg) then rollbackDelete(); return false,msg end
    groupRemoved=ok == true

    table.remove(DATA.mansions,index)
    if not saveData() then
        table.insert(DATA.mansions,index,snapshot)
        rollbackDelete()
        return false,'Não foi possível salvar mansions.json. A exclusão foi revertida.'
    end

    syncClients(-1)
    syncFurniture(-1)
    return true,'Mansão removida com sucesso.'
end)

API["getPublicMansions"] = function()
    if not authAllowed() then return {} end
    return publicMansions()
end

API["requestPurchase"] = function(id)
    if not authAllowed() then return {ok=false,message='SCRIPT NÃO AUTENTICADO!'} end
    local source = source
    local userId = vRP["getUserId"](source)
    local mansion = findMansion(id)
    if not userId or not mansion then return {ok=false,message='Mansão não encontrada.'} end
    if mansion.ownerId then return {ok=false,message='Esta mansão já possui dono.'} end

    local amount = vRP["getInventoryItemAmount"](userId,mansion.voucher) or 0
    if tonumber(amount) < 1 then
        return {ok=false,message=('Você não possui o %s necessário para comprar esta mansão.'):format(Config["AllowedVouchers"][mansion.voucher] or mansion.voucher)}
    end

    return {
        ok=true,
        id=mansion.id,
        name=mansion.name,
        price=mansion.price,
        voucher=mansion.voucher,
        voucherLabel=Config["AllowedVouchers"][mansion.voucher],
        maxResidents=mansion.maxResidents
    }
end

API["confirmPurchase"] = function(id)
    if not authAllowed() then return {ok=false,message='SCRIPT NÃO AUTENTICADO!'} end
    local source = source
    local userId = vRP["getUserId"](source)
    if not userId then return {ok=false,message='Usuário inválido.'} end

    id = tostring(id or '')
    if purchaseLocks[id] then return {ok=false,message='Esta mansão está sendo processada. Tente novamente.'} end

    local mansion = findMansion(id)
    if not mansion or mansion.ownerId then
        return {ok=false,message='Esta mansão já foi comprada.'}
    end

    local question = ('Deseja usar o seu <b>%s</b> para comprar a mansão <b>%s</b>?<br><br>Valor: <b>R$ %s</b><br>Moradores: <b>%d</b>'):format(
        Config["AllowedVouchers"][mansion.voucher] or mansion.voucher, mansion.name, tostring(mansion.price), tonumber(mansion.maxResidents) or 1
    )
    if not vRP["request"](source,question,30) then
        return {ok=false,cancelled=true,message='Compra cancelada.'}
    end

    if purchaseLocks[id] then return {ok=false,message='Esta mansão está sendo processada. Tente novamente.'} end
    purchaseLocks[id] = true

    mansion = findMansion(id)
    if not mansion or mansion.ownerId then
        purchaseLocks[id] = nil
        return {ok=false,message='Esta mansão já foi comprada.'}
    end

    local amount = vRP["getInventoryItemAmount"](userId,mansion.voucher) or 0
    if tonumber(amount) < 1 then
        purchaseLocks[id] = nil
        return {ok=false,message='Você não possui o vale necessário.'}
    end

    -- Nunca consome o vale antes de garantir que o cargo/permissão da mansão
    -- existem de fato na vRP. Isto também repara automaticamente cadastros
    -- antigos que ficaram sem o cargo.
    local groupOk,groupMsg = ensureMansionGroup(mansion)
    if not groupOk then
        purchaseLocks[id] = nil
        return {ok=false,message=('Não foi possível preparar o cargo da mansão: %s'):format(groupMsg or 'erro desconhecido')}
    end

    if not vRP["tryGetInventoryItem"](userId,mansion.voucher,1,true) then
        purchaseLocks[id] = nil
        return {ok=false,message='Não foi possível consumir o vale mansão.'}
    end

    local ok,msg = safeExport(Config["VrpResource"],'addManagedUserGroup',userId,mansion.group)
    if not ok then
        vRP["giveInventoryItem"](userId,mansion.voucher,1,true)
        purchaseLocks[id] = nil
        return {ok=false,message=msg or 'Não foi possível entregar o cargo da mansão.'}
    end

    mansion.ownerId = tonumber(userId)
    mansion.members = {}
    mansion.purchasedAt = os.time()
    mansion.lastIptuPaidAt = os.time()
    mansion.iptuPaidUntil = os.time() + ((tonumber(Config["IptuCycleDays"]) or 20) * 86400)

    if not saveData() then
        safeExport(Config["VrpResource"],'removeManagedUserGroup',userId,mansion.group)
        vRP["giveInventoryItem"](userId,mansion.voucher,1,true)
        mansion.ownerId = nil
        mansion.members = {}
        mansion.purchasedAt = nil
        mansion.lastIptuPaidAt = nil
        mansion.iptuPaidUntil = nil
        purchaseLocks[id] = nil
        return {ok=false,message='Falha ao salvar a compra. O vale foi devolvido.'}
    end

    purchaseLocks[id] = nil
    syncClients(-1)
    TriggerClientEvent('Notify',source,'sucesso',('Você comprou a mansão %s!'):format(mansion.name),8000)
    return {ok=true,message=('Mansão %s comprada com sucesso.'):format(mansion.name)}
end

local function getOwnedMansionForManagement(source,userId)
    local owned = {}
    for _,m in ipairs(DATA.mansions) do
        if tonumber(m.ownerId) == tonumber(userId) then owned[#owned+1] = m end
    end
    if #owned == 0 then return nil,'Você não possui nenhuma mansão.' end
    if #owned == 1 then return owned[1] end

    local x,y,z = vRPclient["getPosition"](source)
    if not x then return nil,'Vá até a mansão que deseja administrar.' end
    local nearest,best
    for _,m in ipairs(owned) do
        local c=m.purchaseCoords
        local dist=math.sqrt((x-c.x)^2+(y-c.y)^2+(z-c.z)^2)
        if not best or dist<best then nearest,best=m,dist end
    end
    if nearest and best <= Config["ManagementNearestDistance"] then return nearest end
    return nil,'Você possui mais de uma mansão. Vá até a mansão que deseja administrar.'
end

MG_MANSIONS_REGISTER_COMMAND('addmorador',function(source)
    if not authAllowed() then notifyAuthDenied(source); return end
    local userId = vRP["getUserId"](source)
    if not userId then return end
    local mansion,err = getOwnedMansionForManagement(source,userId)
    if not mansion then return TriggerClientEvent('Notify',source,'negado',err,5000) end

    local current = 1 + #(mansion.members or {})
    if current >= tonumber(mansion.maxResidents or 1) then
        return TriggerClientEvent('Notify',source,'negado','Esta mansão já atingiu o limite máximo de moradores.',5000)
    end

    local text = vRP["prompt"](source,'Digite o ID do morador que deseja adicionar:','')
    local targetId = tonumber(text)
    if not targetId then return TriggerClientEvent('Notify',source,'negado','ID inválido.',5000) end
    if targetId == tonumber(userId) then return TriggerClientEvent('Notify',source,'negado','Você já é o dono desta mansão.',5000) end

    for _,id in ipairs(mansion.members or {}) do
        if tonumber(id)==targetId then return TriggerClientEvent('Notify',source,'negado','Este jogador já é morador desta mansão.',5000) end
    end

    if not vRP["getUserIdentity"](targetId) then
        return TriggerClientEvent('Notify',source,'negado','Este ID não existe.',5000)
    end

    local ok,msg = safeExport(Config["VrpResource"],'addManagedUserGroup',targetId,mansion.group)
    if not ok then return TriggerClientEvent('Notify',source,'negado',msg or 'Não foi possível adicionar o morador.',5000) end

    mansion.members = mansion.members or {}
    mansion.members[#mansion.members+1] = targetId
    if not saveData() then
        table.remove(mansion.members,#mansion.members)
        safeExport(Config["VrpResource"],'removeManagedUserGroup',targetId,mansion.group)
        return TriggerClientEvent('Notify',source,'negado','Falha ao salvar o novo morador.',5000)
    end

    TriggerClientEvent('Notify',source,'sucesso',('%s (ID %d) agora é morador da %s.'):format(identityLabel(targetId),targetId,mansion.name),7000)
    local targetSource = vRP["getUserSource"](targetId)
    if targetSource then TriggerClientEvent('Notify',targetSource,'sucesso',('Você foi adicionado como morador da %s.'):format(mansion.name),7000) end
end,false)

MG_MANSIONS_REGISTER_COMMAND('tirarmorador',function(source)
    if not authAllowed() then notifyAuthDenied(source); return end
    local userId = vRP["getUserId"](source)
    if not userId then return end
    local mansion,err = getOwnedMansionForManagement(source,userId)
    if not mansion then return TriggerClientEvent('Notify',source,'negado',err,5000) end
    if #(mansion.members or {}) == 0 then return TriggerClientEvent('Notify',source,'negado','Esta mansão não possui moradores adicionais.',5000) end

    local menu = { name=('Moradores - %s'):format(mansion.name) }
    for _,residentId in ipairs(mansion.members or {}) do
        local rid = tonumber(residentId)
        local label = ('%s [ID %d]'):format(identityLabel(rid),rid)
        menu[label] = {function(player)
            vRP["closeMenu"](player)
            local confirm = vRP["request"](player,('Deseja remover <b>%s</b> (ID %d) da mansão <b>%s</b>?'):format(identityLabel(rid),rid,mansion.name),30)
            if not confirm then return end

            local live = findMansion(mansion.id)
            if not live or tonumber(live.ownerId) ~= tonumber(userId) then return end
            local found
            for i,id in ipairs(live.members or {}) do
                if tonumber(id)==rid then found=i break end
            end
            if not found then return TriggerClientEvent('Notify',player,'negado','Este jogador não é mais morador.',5000) end

            local ok,msg=safeExport(Config["VrpResource"],'removeManagedUserGroup',rid,live.group)
            if not ok then return TriggerClientEvent('Notify',player,'negado',msg or 'Falha ao remover cargo.',5000) end
            table.remove(live.members,found)
            if not saveData() then
                safeExport(Config["VrpResource"],'addManagedUserGroup',rid,live.group)
                table.insert(live.members,rid)
                return TriggerClientEvent('Notify',player,'negado','Falha ao salvar a remoção.',5000)
            end
            TriggerClientEvent('Notify',player,'sucesso','Morador removido com sucesso.',5000)
            local ts=vRP["getUserSource"](rid)
            if ts then TriggerClientEvent('Notify',ts,'aviso',('Você foi removido da mansão %s.'):format(live.name),6000) end
        end,('Remover %s da mansão.'):format(identityLabel(rid))}
    end
    vRP["openMenu"](source,menu)
end,false)

MG_MANSIONS_REGISTER_COMMAND('limparmansao',function(source)
    if not authAllowed() then notifyAuthDenied(source); return end
    local userId = vRP["getUserId"](source)
    if not userId or not isCleanupStaff(userId) then
        return TriggerClientEvent('Notify',source,'negado','Você não possui permissão para usar este comando.',5000)
    end

    local x,y,z = vRPclient["getPosition"](source)
    if not x then return end
    local mansion,best
    for _,m in ipairs(DATA.mansions) do
        local c=m.purchaseCoords
        local dist=math.sqrt((x-c.x)^2+(y-c.y)^2+(z-c.z)^2)
        if not best or dist<best then mansion,best=m,dist end
    end

    if not mansion or best > Config["CleanupDistance"] then
        return TriggerClientEvent('Notify',source,'negado','Você não está perto de nenhuma mansão!',5000)
    end
    if not mansion.ownerId then
        return TriggerClientEvent('Notify',source,'aviso','Esta mansão já está livre para compra.',5000)
    end

    local residents=membersInfo(mansion)
    local lines={}
    for _,r in ipairs(residents) do
        lines[#lines+1]=('%s - ID %d%s'):format(r.name,r.id,r.owner and ' (Dono)' or '')
    end
    local text=('Você deseja despejar todos moradores desta mansão?<br><br><b>%s</b><br>%s'):format(mansion.name,table.concat(lines,'<br>'))
    local confirm=vRP["request"](source,text,45)
    if not confirm then return end

    local live=findMansion(mansion.id)
    if not live or not live.ownerId then return end
    local ids={tonumber(live.ownerId)}
    for _,id in ipairs(live.members or {}) do ids[#ids+1]=tonumber(id) end

    local removed={}
    for _,id in ipairs(ids) do
        if id then
            local ok,msg=safeExport(Config["VrpResource"],'removeManagedUserGroup',id,live.group)
            if not ok then
                for _,rollbackId in ipairs(removed) do safeExport(Config["VrpResource"],'addManagedUserGroup',rollbackId,live.group) end
                return TriggerClientEvent('Notify',source,'negado',msg or 'Falha ao despejar os moradores.',6000)
            end
            removed[#removed+1]=id
        end
    end

    local oldOwner=live.ownerId
    local oldMembers=copy(live.members or {})
    local oldPurchasedAt=live.purchasedAt
    local oldLastIptuPaidAt=live.lastIptuPaidAt
    local oldIptuPaidUntil=live.iptuPaidUntil
    local oldFurniture=copy(live.furniture or {})
    live.ownerId=nil
    live.members={}
    live.purchasedAt=nil
    live.lastIptuPaidAt=nil
    live.iptuPaidUntil=nil
    live.furniture={}

    if not saveData() then
        live.ownerId=oldOwner
        live.members=oldMembers
        live.purchasedAt=oldPurchasedAt
        live.lastIptuPaidAt=oldLastIptuPaidAt
        live.iptuPaidUntil=oldIptuPaidUntil
        live.furniture=oldFurniture
        for _,id in ipairs(removed) do safeExport(Config["VrpResource"],'addManagedUserGroup',id,live.group) end
        return TriggerClientEvent('Notify',source,'negado','Falha ao salvar a limpeza da mansão.',6000)
    end

    syncClients(-1)
    syncFurniture(-1)
    for _,id in ipairs(removed) do
        local ts=vRP["getUserSource"](id)
        if ts then TriggerClientEvent('Notify',ts,'aviso',('Você foi despejado da mansão %s.'):format(live.name),7000) end
    end
    TriggerClientEvent('Notify',source,'sucesso',('Todos os moradores foram despejados. %s voltou a ficar disponível.'):format(live.name),8000)
end,false)



-- ============================================================
-- CATÁLOGO / SISTEMA DE MOBÍLIAS
-- ============================================================
local FURNITURE_CATALOG = { version=1, items={} }
local furnitureById = {}

local function loadFurnitureCatalog()
    local raw = MG_MANSIONS_STORAGE_READ and MG_MANSIONS_STORAGE_READ(Config["FurnitureCatalogFile"]) or nil
    local ok,decoded = pcall(json["decode"],raw or '')
    if ok and type(decoded)=='table' then FURNITURE_CATALOG=decoded end
    FURNITURE_CATALOG.items = type(FURNITURE_CATALOG.items)=='table' and FURNITURE_CATALOG.items or {}
    furnitureById={}
    for _,item in ipairs(FURNITURE_CATALOG.items) do
        item.id=trim(item.id or item.model)
        item.model=trim(item.model)
        item.name=trim(item.name)
        item.category=trim(item.category)
        item.price=math.max(0,math.floor(tonumber(item.price) or tonumber(Config["FurnitureDefaultPrice"]) or 500))
        if item.id~='' and item.model~='' then furnitureById[item.id]=item end
    end
end

local function saveFurnitureCatalog()
    local encoded=json["encode"](FURNITURE_CATALOG,{indent=true})
    if not encoded or encoded == '' or type(MG_MANSIONS_STORAGE_WRITE) ~= 'function' then return false end
    local ok = MG_MANSIONS_STORAGE_WRITE(Config["FurnitureCatalogFile"], encoded)
    return ok == true
end

local function isFurnitureStaff(userId)
    userId=tonumber(userId)
    if not userId then return false end
    for group in pairs(Config["FurnitureConfigGroups"] or {}) do
        if vRP["hasGroup"] and vRP["hasGroup"](userId,group) then return true end
    end
    return false
end

local function playerPosition(source)
    local x,y,z=vRPclient["getPosition"](source)
    if not x then return nil end
    return {x=x+0.0,y=y+0.0,z=z+0.0}
end

local function distance3(a,b)
    return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end

local function ownedMansionNear(source,userId)
    local pos=playerPosition(source)
    if not pos then return nil,'Não foi possível obter sua posição.' end
    local nearest,best
    for _,m in ipairs(DATA.mansions or {}) do
        if tonumber(m.ownerId)==tonumber(userId) and m.purchaseCoords then
            local d=distance3(pos,m.purchaseCoords)
            if not best or d<best then nearest,best=m,d end
        end
    end
    if not nearest then return nil,'Você não possui nenhuma mansão.' end
    if best>(tonumber(Config["FurnitureAccessRadius"]) or 80.0) then
        return nil,'Você precisa estar dentro ou próximo da sua mansão para usar o catálogo de mobílias.'
    end
    return nearest
end

local function furniturePublicData()
    local out={}
    for _,m in ipairs(DATA.mansions or {}) do
        for _,f in ipairs(m.furniture or {}) do
            out[#out+1]={
                id=f.id,mansionId=m.id,model=f.model,
                x=tonumber(f.x),y=tonumber(f.y),z=tonumber(f.z),
                heading=tonumber(f.heading) or 0.0
            }
        end
    end
    return out
end

syncFurniture = function(target)
    TriggerClientEvent('m_mansions:furnitureSync',target or -1,furniturePublicData())
end

local function furnitureCatalogFor(source)
    local userId=vRP["getUserId"](source)
    local out=copy(FURNITURE_CATALOG)
    out.canConfigure=isFurnitureStaff(userId)
    return out
end

local function findFurniture(mansion,id)
    id=tostring(id or '')
    for i,f in ipairs(mansion and mansion.furniture or {}) do
        if tostring(f.id)==id then return f,i end
    end
end

local function validFurniturePlacement(mansion,coords)
    if not mansion or not mansion.purchaseCoords or not validCoords(coords) then return false end
    return distance3(mansion.purchaseCoords,coords) <= (tonumber(Config["FurniturePlacementRadius"]) or 100.0)
end

API["getFurnitureContext"] = function()
    if not authAllowed() then return {ok=false,message='SCRIPT NÃO AUTENTICADO!'} end
    local source=source
    local userId=vRP["getUserId"](source)
    if not userId then return {ok=false,message='Usuário inválido.'} end
    local mansion,err=ownedMansionNear(source,userId)
    if not mansion then return {ok=false,message=err} end
    if not checkIptuAccess(source,userId,mansion) then return {ok=false,message='O IPTU desta residência está pendente.'} end
    return {
        ok=true, mansionId=mansion.id, mansionName=mansion.name,
        catalog=furnitureCatalogFor(source), furniture=copy(mansion.furniture or {})
    }
end

API["beginFurniturePurchase"] = function(mansionId,itemId)
    if not authAllowed() then return {ok=false,message='SCRIPT NÃO AUTENTICADO!'} end
    local source=source
    local userId=vRP["getUserId"](source)
    local mansion=findMansion(mansionId)
    local item=furnitureById[tostring(itemId or '')]
    if not userId or not mansion or tonumber(mansion.ownerId)~=tonumber(userId) then return {ok=false,message='Você não é o dono desta mansão.'} end
    if not item then return {ok=false,message='Mobília não encontrada no catálogo.'} end
    local near=ownedMansionNear(source,userId)
    if not near or tostring(near.id)~=tostring(mansion.id) then return {ok=false,message='Você precisa estar dentro ou próximo desta mansão.'} end
    if not checkIptuAccess(source,userId,mansion) then return {ok=false,message='O IPTU desta residência está pendente.'} end
    return {ok=true,item=copy(item),mansionId=mansion.id}
end

API["confirmFurniturePlacement"] = function(mansionId,itemId,coords,heading)
    if not authAllowed() then return {ok=false,message='SCRIPT NÃO AUTENTICADO!'} end
    local source=source
    local userId=vRP["getUserId"](source)
    local mansion=findMansion(mansionId)
    local item=furnitureById[tostring(itemId or '')]
    if not userId or not mansion or tonumber(mansion.ownerId)~=tonumber(userId) then return {ok=false,message='Você não é o dono desta mansão.'} end
    if not item then return {ok=false,message='Mobília não encontrada.'} end
    if not validFurniturePlacement(mansion,coords) then return {ok=false,message='A mobília precisa ficar dentro ou próxima da área desta mansão.'} end
    if not checkIptuAccess(source,userId,mansion) then return {ok=false,message='O IPTU desta residência está pendente.'} end
    local price=math.max(0,math.floor(tonumber(item.price) or 0))
    if price>0 and not vRP["tryFullPayment"](userId,price) then return {ok=false,message=('Você não possui R$ %s para comprar esta mobília.'):format(formatMoney(price))} end
    mansion.furniture=mansion.furniture or {}
    local fid=('%s_%d_%04d'):format(tostring(mansion.id),os.time(),math.random(0,9999))
    local record={id=fid,itemId=item.id,model=item.model,name=item.name,paidPrice=price,x=tonumber(coords.x),y=tonumber(coords.y),z=tonumber(coords.z),heading=tonumber(heading) or 0.0,placedBy=tonumber(userId),createdAt=os.time()}
    mansion.furniture[#mansion.furniture+1]=record
    if not saveData() then
        table.remove(mansion.furniture,#mansion.furniture)
        if price>0 then if vRP["giveBankMoney"] then vRP["giveBankMoney"](userId,price) else vRP["giveMoney"](userId,price) end end
        return {ok=false,message='Não foi possível salvar a mobília. O valor foi devolvido.'}
    end
    syncFurniture(-1)
    return {ok=true,message=('Você comprou %s por R$ %s.'):format(item.name,formatMoney(price)),furniture=copy(record)}
end

API["updateFurniture"] = function(mansionId,furnitureId,coords,heading)
    if not authAllowed() then return {ok=false,message='SCRIPT NÃO AUTENTICADO!'} end
    local source=source
    local userId=vRP["getUserId"](source)
    local mansion=findMansion(mansionId)
    if not userId or not mansion or tonumber(mansion.ownerId)~=tonumber(userId) then return {ok=false,message='Você não é o dono desta mansão.'} end
    if not validFurniturePlacement(mansion,coords) then return {ok=false,message='A mobília precisa ficar dentro ou próxima da área desta mansão.'} end
    if not checkIptuAccess(source,userId,mansion) then return {ok=false,message='O IPTU desta residência está pendente.'} end
    local f=findFurniture(mansion,furnitureId)
    if not f then return {ok=false,message='Mobília não encontrada.'} end
    local old=copy(f)
    f.x,f.y,f.z=tonumber(coords.x),tonumber(coords.y),tonumber(coords.z)
    f.heading=tonumber(heading) or 0.0
    f.updatedAt=os.time()
    if not saveData() then
        for k in pairs(f) do f[k]=nil end for k,v in pairs(old) do f[k]=v end
        return {ok=false,message='Não foi possível salvar a nova posição.'}
    end
    syncFurniture(-1)
    return {ok=true,message='Mobília atualizada com sucesso.'}
end

API["sellFurniture"] = function(mansionId,furnitureId)
    if not authAllowed() then return {ok=false,message='SCRIPT NÃO AUTENTICADO!'} end
    local source=source
    local userId=vRP["getUserId"](source)
    local mansion=findMansion(mansionId)
    if not userId or not mansion or tonumber(mansion.ownerId)~=tonumber(userId) then return {ok=false,message='Você não é o dono desta mansão.'} end
    if not checkIptuAccess(source,userId,mansion) then return {ok=false,message='O IPTU desta residência está pendente.'} end
    local f,index=findFurniture(mansion,furnitureId)
    if not f then return {ok=false,message='Mobília não encontrada.'} end
    local refund=math.floor((tonumber(f.paidPrice) or 0)*((tonumber(Config["FurnitureSellPercent"]) or 15)/100))
    local snapshot=copy(f)
    table.remove(mansion.furniture,index)
    if not saveData() then table.insert(mansion.furniture,index,snapshot); return {ok=false,message='Não foi possível vender esta mobília.'} end
    if refund>0 then if vRP["giveBankMoney"] then vRP["giveBankMoney"](userId,refund) else vRP["giveMoney"](userId,refund) end end
    syncFurniture(-1)
    return {ok=true,message=('Mobília vendida. Você recebeu R$ %s (15%%).'):format(formatMoney(refund)),refund=refund}
end

API["saveFurniturePrices"] = function(prices)
    if not authAllowed() then return {ok=false,message='SCRIPT NÃO AUTENTICADO!'} end
    local source=source
    local userId=vRP["getUserId"](source)
    if not userId or not isFurnitureStaff(userId) then return {ok=false,message='Você não possui permissão para configurar os valores.'} end
    if type(prices)~='table' then return {ok=false,message='Valores inválidos.'} end
    local changed=0
    for id,value in pairs(prices) do
        local item=furnitureById[tostring(id)]
        local price=tonumber(value)
        if item and price and price>=0 then item.price=math.floor(price); changed=changed+1 end
    end
    if changed==0 then return {ok=false,message='Nenhum valor válido foi informado.'} end
    if not saveFurnitureCatalog() then loadFurnitureCatalog(); return {ok=false,message='Não foi possível salvar furniture_catalog.json.'} end
    loadFurnitureCatalog()
    return {ok=true,message=('%d valor(es) atualizado(s) com sucesso.'):format(changed),catalog=furnitureCatalogFor(source)}
end

MG_MANSIONS_REGISTER_COMMAND(Config["FurnitureCommand"] or 'mobilias',function(source)
    if not authAllowed() then notifyAuthDenied(source); return end
    local userId=vRP["getUserId"](source)
    if not userId then return end
    local mansion,err=ownedMansionNear(source,userId)
    if not mansion then return TriggerClientEvent('Notify',source,'negado',err,6000) end
    if not checkIptuAccess(source,userId,mansion) then return end
    TriggerClientEvent('m_mansions:openFurniture',source)
end,false)

MG_MANSIONS_REGISTER_NET_EVENT('m_mansions:requestFurnitureSync',function()
    if not authAllowed() then return end
    syncFurniture(source)
end)

MG_MANSIONS_REGISTER_NET_EVENT('m_mansions:requestSync',function()
    if not authAllowed() then return end
    syncClients(source)
    syncFurniture(source)
end)

MG_MANSIONS_ADD_EVENT_HANDLER('vRP:playerSpawn',function(userId,source)
    SetTimeout(1500,function()
        if not authAllowed() then return end
        syncClients(source)
        syncFurniture(source)
    end)
end)

math.randomseed(os.time())
loadFurnitureCatalog()
loadData()
for _,m in ipairs(DATA.mansions or {}) do m.furniture=type(m.furniture)=='table' and m.furniture or {} end
CreateThread(function()
    -- Não toca em cargos/baús/garagens/portas até a AUTH terminar.
    while not __tdmAuth.ready() do Wait(250) end
    if not __tdmAuth.authorized() then return end

    Wait(1200)
    -- Auto-reparo: qualquer mansão já existente no JSON passa a ter seu cargo
    -- e permissão garantidos na vRP ao iniciar o resource. Assim, cadastros
    -- feitos por versões anteriores não ficam impossíveis de comprar.
    for _,mansion in ipairs(DATA.mansions or {}) do
        local ok,msg = ensureMansionGroup(mansion)
        if not ok then
            print(('^1[m_mansions]^7 Falha ao garantir cargo da mansão %s (%s): %s'):format(
                tostring(mansion.name), tostring(mansion.group), tostring(msg)
            ))
        end
    end
    syncClients(-1)
end)
