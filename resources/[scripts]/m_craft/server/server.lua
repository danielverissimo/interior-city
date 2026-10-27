local Tunnel = module('vrp','lib/Tunnel')
local Proxy = module('vrp','lib/Proxy')
local vRP = Proxy.getInterface('vRP')
local vRPC = Tunnel.getInterface('vRP')

ServerAPI = {}
Tunnel.bindInterface(GetCurrentResourceName(), ServerAPI)
ClientAPI = Tunnel.getInterface(GetCurrentResourceName())

-- ============================================================================
-- INTEGRAÇÃO COM O SISTEMA CENTRAL DE LOGS DO MAGE ADMIN
-- ============================================================================
-- Não existe dependência obrigatória no fxmanifest: se o painel estiver reiniciando,
-- as ocorrências ficam em uma fila curta e são reenviadas quando o export voltar.
local MAGE_LOG_RESOURCE <const> = 'm_paineladm_v2'
local MAGE_LOG_QUEUE_LIMIT <const> = 250
local mageLogQueue = {}

local function mageLogSlug(value)
    value = tostring(value or 'desconhecido'):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_]', ''):gsub('_+', '_')
    value = value:gsub('^_+', ''):gsub('_+$', '')
    return value ~= '' and value or 'desconhecido'
end

local function trySendMageLog(logKey, payload)
    if GetResourceState(MAGE_LOG_RESOURCE) ~= 'started' then
        return false
    end

    local ok, sent, reason = pcall(function()
        return exports[MAGE_LOG_RESOURCE]:sendLog(logKey, payload)
    end)

    if not ok then
        return false
    end

    -- Export executado com sucesso. "Webhook não configurada" não é falha do
    -- resource integrado e não deve ficar sendo reenviada indefinidamente.
    if sent == true or reason == 'Webhook não configurada.' or reason == 'Log não cadastrado no catálogo.' then
        return true
    end

    -- Qualquer outra resposta do export foi processada pelo painel; não trava o script.
    return true
end

local function sendMageLog(logKey, payload)
    payload = type(payload) == 'table' and payload or {}
    payload.occurredAt = tonumber(payload.occurredAt) or os.time()
    if trySendMageLog(logKey, payload) then return end

    if #mageLogQueue >= MAGE_LOG_QUEUE_LIMIT then
        table.remove(mageLogQueue, 1)
    end
    mageLogQueue[#mageLogQueue + 1] = { key = logKey, payload = payload }
end

CreateThread(function()
    while true do
        Wait(5000)
        if #mageLogQueue > 0 and GetResourceState(MAGE_LOG_RESOURCE) == 'started' then
            local pending = mageLogQueue
            mageLogQueue = {}
            for _, entry in ipairs(pending) do
                if not trySendMageLog(entry.key, entry.payload) then
                    if #mageLogQueue < MAGE_LOG_QUEUE_LIMIT then
                        mageLogQueue[#mageLogQueue + 1] = entry
                    end
                end
            end
        end
    end
end)



local CRAFT_CONFIG_FILE = 'shared/config.json'

local function normalizeCraftConfig(data)
    data = type(data) == 'table' and data or {}
    data.coords = type(data.coords) == 'table' and data.coords or {}
    return data
end

local function loadCraftConfig()
    local raw = LoadResourceFile(GetCurrentResourceName(), CRAFT_CONFIG_FILE)
    local ok,data = pcall(json.decode, raw or '{}')
    if not ok then data = {} end
    data = normalizeCraftConfig(data)
    Config = Config or {}
    Config.Coords = data.coords
    return data
end

local function saveCraftConfig()
    local payload = { coords = Config.Coords or {} }
    local encoded = json.encode(payload)
    if not SaveResourceFile(GetCurrentResourceName(), CRAFT_CONFIG_FILE, encoded, -1) then
        return false, 'Não foi possível gravar shared/config.json.'
    end
    TriggerClientEvent('m_craft:configSync', -1, payload)
    return true
end

loadCraftConfig()

-----------------------------------------------------------------------------------------------------------------------------------------
-- FABRICAÇÃO AUTORITATIVA / PERSISTENTE POR BANCADA
-- O tempo é controlado pelo servidor. Fechar a NUI não conclui nem entrega o item.
-----------------------------------------------------------------------------------------------------------------------------------------
local CRAFT_JOBS_KEY = 'm_craft:active_jobs:v2'
local CraftJobs = {}
local BenchLocks = {}

local function readCraftJobs()
    local raw = vRP.getSData(CRAFT_JOBS_KEY)
    local ok, data = pcall(json.decode, raw or '{}')
    if not ok or type(data) ~= 'table' then data = {} end
    CraftJobs = data
end

local function writeCraftJobs()
    vRP.setSData(CRAFT_JOBS_KEY, json.encode(CraftJobs or {}))
end

local function getBenchKey(org)
    if not org or not org.name then return nil end
    return tostring(org.name)
end

local function normalizeJob(job)
    if type(job) ~= 'table' then return nil end
    job.status = tostring(job.status or 'crafting')
    job.startedAt = tonumber(job.startedAt) or os.time()
    job.endAt = tonumber(job.endAt) or job.startedAt
    job.displayAmount = math.max(1, math.floor(tonumber(job.displayAmount) or 1))
    job.resultAmount = math.max(1, math.floor(tonumber(job.resultAmount) or 1))
    job.recipeTime = math.max(1, math.floor(tonumber(job.recipeTime) or 1))
    return job
end

local function publicJob(job)
    job = normalizeJob(job)
    if not job then return nil end
    local now = os.time()
    local status = job.status
    if status == 'crafting' and now >= job.endAt then status = 'ready' end
    return {
        id = job.id,
        status = status,
        name = job.name,
        image = job.image,
        spawn = job.resultSpawn,
        amount = job.displayAmount,
        resultAmount = job.resultAmount,
        startedAt = job.startedAt,
        endAt = job.endAt,
        remaining = math.max(0, job.endAt - now),
        serverNow = now
    }
end

local function buildPublicStates()
    local states = {}
    for key,job in pairs(CraftJobs or {}) do
        local pub = publicJob(job)
        if pub then states[key] = pub end
    end
    return states
end

local function syncAllCraftStates(target)
    TriggerClientEvent('m_craft:stateSync', target or -1, buildPublicStates())
end

local function syncCraftState(key)
    TriggerClientEvent('m_craft:stateUpdate', -1, key, publicJob(CraftJobs[key]))
end

readCraftJobs()
for key,job in pairs(CraftJobs) do
    job = normalizeJob(job)
    if not job then
        CraftJobs[key] = nil
    else
        CraftJobs[key] = job
        if job.status == 'crafting' and os.time() >= job.endAt then
            job.status = 'ready'
        end
    end
end
writeCraftJobs()

CreateThread(function()
    Wait(500)
    TriggerClientEvent('m_craft:configSync', -1, { coords = Config.Coords or {} })
    syncAllCraftStates(-1)
end)

RegisterNetEvent('m_craft:requestConfig', function()
    TriggerClientEvent('m_craft:configSync', source, { coords = Config.Coords or {} })
    syncAllCraftStates(source)
end)

-- Converte automaticamente fabricação em "pronta" no servidor, inclusive se ninguém estiver perto da bancada.
CreateThread(function()
    while true do
        local changed = false
        local now = os.time()
        for key,job in pairs(CraftJobs) do
            job = normalizeJob(job)
            if job and job.status == 'crafting' and now >= job.endAt then
                job.status = 'ready'
                CraftJobs[key] = job
                changed = true
                syncCraftState(key)
            end
        end
        if changed then writeCraftJobs() end
        Wait(1000)
    end
end)

local function validBench(data)
    return type(data)=='table' and type(data.name)=='string' and data.name~='' and type(data.coords)=='table'
end

exports('getCraftBenches', function()
    return Config.Coords or {}
end)

exports('upsertCraftBench', function(originalName, data)
    if not validBench(data) then return false,'Dados da bancada inválidos.' end
    originalName = tostring(originalName or data.name)
    local found=nil
    for i,v in ipairs(Config.Coords or {}) do
        if v.name == originalName then found=i break end
    end

    -- Se a bancada for renomeada durante uma fabricação, o trabalho acompanha a bancada.
    if found and originalName ~= data.name and CraftJobs[originalName] then
        if CraftJobs[data.name] then
            return false, 'Já existe uma fabricação ativa na bancada de destino.'
        end
        CraftJobs[data.name] = CraftJobs[originalName]
        CraftJobs[originalName] = nil
        writeCraftJobs()
        syncCraftState(originalName)
        syncCraftState(data.name)
    end

    if found then Config.Coords[found]=data else table.insert(Config.Coords,data) end
    return saveCraftConfig()
end)

exports('removeCraftBench', function(name)
    if CraftJobs[tostring(name)] then
        return false,'Não é possível remover uma bancada com fabricação pendente.'
    end
    for i=#(Config.Coords or {}),1,-1 do
        if Config.Coords[i].name == name then
            table.remove(Config.Coords,i)
            return saveCraftConfig()
        end
    end
    return false,'Bancada não encontrada.'
end)

exports('reloadCraftConfig', function()
    loadCraftConfig()
    TriggerClientEvent('m_craft:configSync', -1, { coords = Config.Coords or {} })
    return true
end)


local EMPTY_ARRAY = (json and json.decode('[]')) or {}

local function getUserId(source)
	return vRP.getUserId(source)
end

local function ensureNumber(value, default)
	if type(value) == 'number' then return value end
	return default or 0
end

local function getOrgByIndex(index)
	if type(index) ~= 'number' then return nil end
	return Config.Coords[index]
end

local function userHasAnyPermission(source, permissions)
	local userId = getUserId(source)
	if not userId then return false end
	for _,perm in ipairs(permissions) do
		if perm and vRP.hasPermission(userId, perm) then
			return true
		end
	end
	return false
end

local function getStorageKey(orgName)
	return ('m_craft:storage:%s'):format(orgName)
end

local function readStorage(orgName)
	local key = getStorageKey(orgName)
	local raw = vRP.getSData(key)
	local ok, data = pcall(json.decode, raw or '[]')
	if not ok or type(data) ~= 'table' then data = {} end
	return data
end

local function writeStorage(orgName, items)
	local key = getStorageKey(orgName)
	vRP.setSData(key, json.encode(items or {}))
end

local function findStorageItem(items, name)
	for i=1,#items do
		local it = items[i]
		if it and (it.name == name or it.spawn == name) then
			return it, i
		end
	end
	return nil, nil
end

-- Ranking helpers
local function readUserRanking()
    local raw = vRP.getSData('m_craft:ranking:users')
    local ok, data = pcall(json.decode, raw or '{}')
    if not ok or type(data) ~= 'table' then data = {} end
    return data
end

local function writeUserRanking(map)
    vRP.setSData('m_craft:ranking:users', json.encode(map or {}))
end

local function getPlayerDisplayName(userId)
    local identity = (vRP.getUserIdentity and vRP.getUserIdentity(userId)) or nil
    if identity then
        if identity.name and identity.name2 then
            return (identity.name .. ' ' .. identity.name2)
        end
        if identity.firstname and identity.lastname then
            return (identity.firstname .. ' ' .. identity.lastname)
        end
        if identity.nome and identity.sobrenome then
            return (identity.nome .. ' ' .. identity.sobrenome)
        end
    end
    local src = vRP.getUserSource and vRP.getUserSource(userId)
    if src then
        local pname = GetPlayerName(src)
        if pname and pname ~= "" then
            return pname
        end
    end
    return 'ID '..tostring(userId)
end
local function findAllowedItem(allowedList, nameOrSpawn)
    if type(allowedList) ~= 'table' then return nil end
    for _,it in ipairs(allowedList) do
        if it and (it.spawn == nameOrSpawn or it.name == nameOrSpawn) then
            return it
        end
    end
    return nil
end

-- Permissions gate to open menu at a blip
function ServerAPI.hasMinPermission(blipIndex)
	local src = source
	local org = getOrgByIndex(blipIndex)
	if not org then return false end
	return userHasAnyPermission(src, {
		org.craftPermission,
		org.armazemPermission
	})
end


function ServerAPI.getBenchState(blipIndex)
    local src = source
    local org = getOrgByIndex(blipIndex)
    if not org then return nil end
    if not userHasAnyPermission(src, { org.craftPermission, org.armazemPermission }) then return nil end
    local key = getBenchKey(org)
    return key and publicJob(CraftJobs[key]) or nil
end

-- Returns craft list for the organization
function ServerAPI.getProductions(blipIndex)
    local src = source
    local org = getOrgByIndex(blipIndex)
    if not org then return EMPTY_ARRAY end
    if not userHasAnyPermission(src, { org.craftPermission }) then
        return EMPTY_ARRAY
    end
    local items = org.craftItems or EMPTY_ARRAY
    if type(items) ~= 'table' then items = EMPTY_ARRAY end
    return items
end

-- Returns armazem (storage) list with current amounts (persisted)
function ServerAPI.getStorage(blipIndex)
	local src = source
	local org = getOrgByIndex(blipIndex)
	if not org then return nil end
	if not userHasAnyPermission(src, { org.armazemPermission }) then return nil end
	local current = readStorage(org.name)
	-- Merge template items with persisted amounts
	local map = {}
	for _,it in ipairs(current) do
		map[it.spawn or it.name] = ensureNumber(it.amount, 0)
	end
	local result = {}
	for _,tmpl in ipairs(org.armazemItems or {}) do
		local spawn = tmpl.spawn or tmpl.name
		table.insert(result, {
			name = tmpl.name,
			image = tmpl.image,
			spawn = spawn,
			amount = ensureNumber(map[spawn], 0)
		})
	end
	return result
end


local function buildCraftMaterialsDetail(recipe, produceAmount)
    local rows = {}
    for _, req in ipairs(recipe and recipe.requires or {}) do
        local reqName = tostring(req.spawn or req.name or 'item')
        local need = ensureNumber(req.amount, 0) * produceAmount
        if need > 0 then
            rows[#rows + 1] = ('• %s x%d'):format(reqName, need)
        end
    end
    return #rows > 0 and table.concat(rows, '\n') or 'Nenhum material configurado.'
end

local function craftLogKey(orgName, suffix)
    return ('craft_%s_%s'):format(mageLogSlug(orgName), tostring(suffix))
end

local function buildStorageDepositDetail(orgName, deposits, mode)
    local rows = {}
    local total = 0

    for _, entry in ipairs(deposits or {}) do
        local amount = math.max(0, math.floor(tonumber(entry.amount) or 0))
        if amount > 0 then
            total = total + amount
            rows[#rows + 1] = ('• %s [%s] — depositado: %d | saldo no armazém: %d'):format(
                tostring(entry.name or entry.spawn or 'Item'),
                tostring(entry.spawn or entry.name or '-'),
                amount,
                math.max(0, math.floor(tonumber(entry.storageAmount) or amount))
            )
        end
    end

    return (
        'Craft/Facção: %s\nAção: %s\nTotal de unidades depositadas: %d\nItens depositados:\n%s'
    ):format(
        tostring(orgName or 'Desconhecido'),
        tostring(mode or 'Depósito no armazém'),
        total,
        #rows > 0 and table.concat(rows, '\n') or 'Nenhum item depositado.'
    )
end

-- Inicia uma fabricação real e autoritativa no servidor. O resultado só é entregue quando for coletado.
function ServerAPI.produceItem(blipIndex, data)
    local src = source
    local org = getOrgByIndex(blipIndex)
    if not org then return false end
    if not userHasAnyPermission(src, { org.craftPermission }) then return false end

    local benchKey = getBenchKey(org)
    if not benchKey or BenchLocks[benchKey] then return false end
    if CraftJobs[benchKey] then return false end
    BenchLocks[benchKey] = true

    local function unlock(result)
        BenchLocks[benchKey] = nil
        return result
    end

    local recipes = org.craftItems or {}
    local payloadItem = (data and data.item) or data
    local idx = ensureNumber(payloadItem and payloadItem.index or data and data.index, nil)
    local recipe = (idx and recipes[idx]) or nil
    if not recipe then
        local wanted = payloadItem and (payloadItem.spawn or payloadItem.name) or (data and (data.spawn or data.name))
        if wanted then
            for i=1,#recipes do
                if recipes[i].spawn == wanted or recipes[i].name == wanted then
                    recipe = recipes[i]
                    break
                end
            end
        end
    end
    if not recipe then return unlock(false) end

    local userId = getUserId(src)
    if not userId then return unlock(false) end

    local produceAmount = tonumber(data and data.amount) or 1
    produceAmount = math.floor(produceAmount)
    if produceAmount < 1 then produceAmount = 1 end
    if produceAmount > 1000 then produceAmount = 1000 end

    local storageItems = readStorage(org.name)

    -- Primeiro valida tudo. Nenhum material é retirado se faltar qualquer requisito.
    for _,req in ipairs(recipe.requires or {}) do
        local reqName = req.spawn or req.name
        local need = ensureNumber(req.amount, 0) * produceAmount
        if need > 0 then
            local it = select(1, findStorageItem(storageItems, reqName))
            if not it or ensureNumber(it.amount, 0) < need then
                return unlock(false)
            end
        end
    end

    -- Retira os materiais no início da fabricação.
    for _,req in ipairs(recipe.requires or {}) do
        local reqName = req.spawn or req.name
        local need = ensureNumber(req.amount, 0) * produceAmount
        if need > 0 then
            local it, storageIndex = findStorageItem(storageItems, reqName)
            if it then
                it.amount = ensureNumber(it.amount, 0) - need
                if it.amount <= 0 then table.remove(storageItems, storageIndex) end
            end
        end
    end
    writeStorage(org.name, storageItems)

    local recipeTime = math.max(1, math.floor(tonumber(recipe.time) or 1))
    local totalTime = recipeTime * produceAmount
    local resultSpawn = recipe.spawn or recipe.name
    local resultAmount = math.max(1, math.floor(ensureNumber(recipe.amount, 1) * produceAmount))
    local now = os.time()
    local clientId = payloadItem and tonumber(payloadItem.id) or nil

    CraftJobs[benchKey] = {
        id = clientId or math.random(100000, 999999999),
        status = 'crafting',
        name = recipe.name or resultSpawn,
        image = recipe.image,
        resultSpawn = resultSpawn,
        displayAmount = produceAmount,
        resultAmount = resultAmount,
        recipeTime = recipeTime,
        startedAt = now,
        endAt = now + totalTime,
        startedBy = userId
    }
    writeCraftJobs()
    syncCraftState(benchKey)
    -- Se duas pessoas já estavam com a mesma bancada aberta no exato momento do início,
    -- mantém a NUI somente para quem iniciou e fecha a dos demais membros.
    TriggerClientEvent('m_craft:benchStarted', -1, benchKey, src)

    -- Mantém a regra anterior do ranking: contabiliza quando a fabricação é iniciada.
    local rank = readUserRanking()
    rank[tostring(userId)] = ensureNumber(rank[tostring(userId)], 0) + 1
    writeUserRanking(rank)

    sendMageLog(craftLogKey(org.name, 'started'), {
        actorId = userId,
        actorLabel = 'JOGADOR',
        details = (
            'Craft: %s\nItem: %s\nSpawn: %s\nQuantidade produzida: %d\nQuantidade final recebível: %d\nTempo total: %d segundo(s)\nMateriais consumidos:\n%s'
        ):format(
            tostring(org.name or 'Desconhecido'),
            tostring(recipe.name or resultSpawn),
            tostring(resultSpawn),
            produceAmount,
            resultAmount,
            totalTime,
            buildCraftMaterialsDetail(recipe, produceAmount)
        )
    })

    return unlock(true)
end

local function collectCraftJob(src, org, expectedId)
    local benchKey = getBenchKey(org)
    if not benchKey or BenchLocks[benchKey] then return false end
    if not userHasAnyPermission(src, { org.craftPermission, org.armazemPermission }) then return false end

    local job = CraftJobs[benchKey]
    if not job then return false end
    job = normalizeJob(job)
    if not job then return false end

    if job.status == 'crafting' and os.time() >= job.endAt then
        job.status = 'ready'
        CraftJobs[benchKey] = job
        writeCraftJobs()
        syncCraftState(benchKey)
    end
    if job.status ~= 'ready' then return false end
    if expectedId and tonumber(expectedId) and tonumber(job.id) ~= tonumber(expectedId) then return false end

    local userId = getUserId(src)
    if not userId then return false end

    -- Trava antes da entrega para impedir coleta dupla por dois jogadores no mesmo frame.
    BenchLocks[benchKey] = true
    local giveName = job.resultSpawn
    local giveQty = math.max(1, math.floor(tonumber(job.resultAmount) or 1))

    if giveName == 'money' then
        vRP.giveMoney(userId, giveQty)
    else
        vRP.giveInventoryItem(userId, giveName, giveQty, true)
    end

    CraftJobs[benchKey] = nil
    writeCraftJobs()
    BenchLocks[benchKey] = nil
    syncCraftState(benchKey)

    sendMageLog(craftLogKey(org.name, 'collected'), {
        actorId = userId,
        actorLabel = 'JOGADOR',
        details = (
            'Craft: %s\nItem coletado: %s\nSpawn: %s\nQuantidade: %d\nFabricação iniciada pelo ID: %s\nID da fabricação: %s'
        ):format(
            tostring(org.name or 'Desconhecido'),
            tostring(job.name or giveName),
            tostring(giveName),
            giveQty,
            tostring(job.startedBy or '-'),
            tostring(job.id or '-')
        )
    })

    return true
end

-- O botão RESGATAR da própria NUI usa esta função quando o jogador mantém o painel aberto até terminar.
function ServerAPI.removeItemFromQueue(blipIndex, data)
    local src = source
    local org = getOrgByIndex(blipIndex)
    if not org then return false end
    local expectedId = data and data.item and data.item.id or data and data.id
    return collectCraftJob(src, org, expectedId)
end

-- Coleta pelo [E] no mundo quando o painel foi fechado e a produção já terminou.
function ServerAPI.collectBench(blipIndex)
    local src = source
    local org = getOrgByIndex(blipIndex)
    if not org then return false end
    return collectCraftJob(src, org, nil)
end

-- Save all queue (no-op placeholder for compatibility)
function ServerAPI.saveAll(blipIndex)
    local src = source
    local org = getOrgByIndex(blipIndex)
    if not org then return false end
    if not userHasAnyPermission(src, { org.armazemPermission }) then return false end

    local userId = getUserId(src)
    if not userId then return false end

    local items = readStorage(org.name)
    local totalDeposited = 0
    local depositedItems = {}

    for _,allowed in ipairs(org.armazemItems or {}) do
        local spawn = allowed.spawn or allowed.name
        if spawn then
            local have = vRP.getInventoryItemAmount(userId, spawn)
            if have and have > 0 then
                -- Só adiciona ao armazém e registra a log se a retirada do inventário
                -- realmente tiver sido confirmada pela vRP. Evita duplicação/log fantasma.
                if vRP.tryGetInventoryItem(userId, spawn, have, true) then
                    local it = findStorageItem(items, spawn)
                    if it then
                        it.amount = ensureNumber(it.amount, 0) + have
                    else
                        it = {
                            name = allowed.name or spawn,
                            spawn = spawn,
                            image = allowed.image,
                            amount = have
                        }
                        table.insert(items, it)
                    end

                    totalDeposited = totalDeposited + ensureNumber(have, 0)
                    depositedItems[#depositedItems + 1] = {
                        name = allowed.name or spawn,
                        spawn = spawn,
                        amount = have,
                        storageAmount = ensureNumber(it.amount, 0)
                    }

                    -- Registrar entrega no sistema de metas (lotus_orgs_v2)
                    local orgName = vRP.getUserGroupOrg(userId)
                    if orgName and spawn and have > 0 then
                        exports.oxmysql:execute('INSERT INTO mirtin_orgs_goals(organization, user_id, item, amount, `day`, `month`) VALUES(?,?,?,?,?,?) ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount)', {
                            orgName, userId, spawn, have, os.date('%d'), os.date('%m')
                        })
                    end
                end
            end
        end
    end

    writeStorage(org.name, items)

    -- Atualiza ranking por depósito
    if totalDeposited > 0 then
        local rank = readUserRanking()
        rank[tostring(userId)] = ensureNumber(rank[tostring(userId)], 0) + totalDeposited
        writeUserRanking(rank)

        sendMageLog(craftLogKey(org.name, 'storage_deposit'), {
            actorId = userId,
            actorLabel = 'JOGADOR',
            details = buildStorageDepositDetail(org.name, depositedItems, 'Depositou todos os itens disponíveis no armazém')
        })
    end

    return true
end

-- Save single item (no-op placeholder for compatibility)
function ServerAPI.saveItem(blipIndex, data)
    local src = source
    local org = getOrgByIndex(blipIndex)
    if not org then return false end
    if not userHasAnyPermission(src, { org.armazemPermission }) then return false end

    local userId = getUserId(src)
    if not userId then return false end

    local spawn = data and (data.spawn or (data.item and (data.item.spawn or data.item.name)) or data.name)
    local amount = ensureNumber(data and (data.amount or (data.item and data.item.amount)), 0)
    if not spawn then return false end

    -- Validate item is allowed in this org storage
    local allowed = findAllowedItem(org.armazemItems or {}, spawn)
    if not allowed then return false end

    -- Determine amount: if not provided or <=0, deposit all you have
    local have = vRP.getInventoryItemAmount(userId, spawn)
    if amount <= 0 then amount = have end
    if not have or have < amount or amount <= 0 then return false end

    -- Só persiste no armazém depois que a vRP confirmar a retirada do inventário.
    if not vRP.tryGetInventoryItem(userId, spawn, amount, true) then
        return false
    end

    local items = readStorage(org.name)
    local it = findStorageItem(items, spawn)
    if it then
        it.amount = ensureNumber(it.amount, 0) + amount
    else
        it = {
            name = allowed.name or spawn,
            spawn = allowed.spawn or spawn,
            image = allowed.image,
            amount = amount
        }
        table.insert(items, it)
    end
    writeStorage(org.name, items)

    -- Atualiza ranking por depósito unitário
    local rank = readUserRanking()
    rank[tostring(userId)] = ensureNumber(rank[tostring(userId)], 0) + amount
    writeUserRanking(rank)

    -- Registrar entrega unitária no sistema de metas (lotus_orgs_v2)
    local orgName = vRP.getUserGroupOrg(userId)
    if orgName and spawn and amount > 0 then
        exports.oxmysql:execute('INSERT INTO mirtin_orgs_goals(organization, user_id, item, amount, `day`, `month`) VALUES(?,?,?,?,?,?) ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount)', {
            orgName, userId, spawn, amount, os.date('%d'), os.date('%m')
        })
    end

    sendMageLog(craftLogKey(org.name, 'storage_deposit'), {
        actorId = userId,
        actorLabel = 'JOGADOR',
        details = buildStorageDepositDetail(org.name, {
            {
                name = allowed.name or spawn,
                spawn = allowed.spawn or spawn,
                amount = amount,
                storageAmount = ensureNumber(it.amount, 0)
            }
        }, 'Depositou um item no armazém')
    })

    return true
end

-- Ranking placeholder (could be extended to track per-org crafts)
function ServerAPI.getRanking(blipIndex)
    -- Build top list by crafts
    local rank = readUserRanking()
    local arr = {}
    for k,v in pairs(rank) do
        local uid = tonumber(k)
        table.insert(arr, { id = uid, name = getPlayerDisplayName(uid), craft = ensureNumber(v,0) })
    end
    table.sort(arr, function(a,b)
        if a.craft == b.craft then return (a.id or 0) < (b.id or 0) end
        return a.craft > b.craft
    end)
    local top = {}
    for i=1, math.min(10, #arr) do
        table.insert(top, { position = i, id = arr[i].id, name = arr[i].name, craft = arr[i].craft })
    end
    return top
end

-- ORGANIZATION STORAGE MENU (command / events from client)
function ServerAPI.getOrgStorage(orgName)
	local src = source
	if type(orgName) ~= 'string' then return end
	local items = readStorage(orgName)
	TriggerClientEvent('m_craft:showStorageMenu', src, orgName, items)
end

-- Removido: não permitir retirada via menu


