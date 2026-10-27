local CONFIG_FILE = "config.json"
local Data = {
    settings = {},
    desmanches = {}
}

local function trim(value)
    return tostring(value or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k,v in pairs(value) do out[k] = copy(v) end
    return out
end

local function normalizeVec3(value)
    if type(value) ~= "table" then return nil end

    local x = tonumber(value.x or value[1])
    local y = tonumber(value.y or value[2])
    local z = tonumber(value.z or value[3])

    if not x or not y or not z then return nil end

    return { x=x, y=y, z=z }
end

local function normalizeVec4(value)
    local v = normalizeVec3(value)
    if not v then return nil end

    local w = tonumber(value.w or value[4])
    if not w then return nil end

    v.w = w
    return v
end

local function normalizeItems(items)
    local out = {}

    if type(items) == "table" then
        for _,entry in ipairs(items) do
            local item = trim(entry.item)
            local qtd = tonumber(entry.qtd or entry.amount)

            if item ~= "" and qtd and qtd > 0 then
                out[#out+1] = {
                    item = item,
                    qtd = math.floor(qtd)
                }
            end
        end
    end

    -- O client original percorre a lista mesmo quando precisa_de_item=false.
    -- Mantemos uma linha neutra para preservar a lógica original.
    if #out == 0 then
        out[1] = { item="lockpick", qtd=1 }
    end

    return out
end

local function normalizeDesmanche(payload, keepName)
    if type(payload) ~= "table" then
        return nil,"Dados do desmanche inválidos."
    end

    local name = trim(keepName or payload.name)
    local permission = trim(payload.permissao)
    local inicio = normalizeVec3(payload.inicio)
    local vehicle = normalizeVec3(payload.local_veiculo)
    local tools = normalizeVec4(payload.local_ferramentas)
    local finish = normalizeVec3(payload.local_finalizar)

    if name == "" or name == "none" then
        return nil,"Identificador do desmanche inválido."
    end

    if permission == "" then
        return nil,"Informe a permissão do desmanche."
    end

    if not inicio then return nil,"Posição de início inválida." end
    if not vehicle then return nil,"Posição do veículo inválida." end
    if not tools then return nil,"Posição das ferramentas inválida." end
    if not finish then return nil,"Posição de finalização inválida." end

    return {
        name = name,
        precisa_de_item = payload.precisa_de_item == true,
        itens_necessarios = normalizeItems(payload.itens_necessarios),
        permissao = permission,
        inicio = inicio,
        local_veiculo = vehicle,
        local_ferramentas = tools,
        local_finalizar = finish,
        log_webhook = trim(payload.log_webhook)
    }
end

local function normalizeSettings(payload)
    payload = type(payload) == "table" and payload or {}

    local common = tonumber(payload.porcentagem_veiculocomum)
    local vip = tonumber(payload.porcentagem_veiculovip)

    if not common or common < 0 then
        return nil,"Porcentagem de veículo comum inválida."
    end

    if not vip or vip < 0 then
        return nil,"Porcentagem de veículo VIP inválida."
    end

    return {
        porcentagem_veiculocomum = common,
        porcentagem_veiculovip = vip,
        desmanchar_proprio_veiculo = payload.desmanchar_proprio_veiculo == true,
        desmanchar_veiculo_trabalho = payload.desmanchar_veiculo_trabalho == true
    }
end

local function findIndex(name)
    name = tostring(name or "")
    for i,item in ipairs(Data.desmanches or {}) do
        if tostring(item.name) == name then
            return i,item
        end
    end
end

local function applyRuntime()
    local settings = Data.settings or {}

    cfg.porcentagem_veiculocomum = tonumber(settings.porcentagem_veiculocomum) or 0.35
    cfg.porcentagem_veiculovip = tonumber(settings.porcentagem_veiculovip) or 0.50
    cfg.desmanchar_proprio_veiculo = settings.desmanchar_proprio_veiculo == true
    cfg.desmanchar_veiculo_trabalho = settings.desmanchar_veiculo_trabalho == true

    cfg.table = {
        ["none"] = {
            inicio = {0.0,0.0,0.0},
            local_veiculo = {0.0,0.0,0.0},
            local_ferramentas = {0.0,0.0,0.0,0.0},
            local_finalizar = {0.0,0.0,0.0},
            precisa_de_item = false,
            itens_necessarios = {
                { item="lockpick", qtd=1 }
            },
            permissao = "",
            log_webhook = ""
        }
    }

    for _,item in ipairs(Data.desmanches or {}) do
        cfg.table[item.name] = {
            precisa_de_item = item.precisa_de_item == true,
            itens_necessarios = copy(item.itens_necessarios),
            permissao = item.permissao,
            inicio = {item.inicio.x,item.inicio.y,item.inicio.z},
            local_veiculo = {
                item.local_veiculo.x,
                item.local_veiculo.y,
                item.local_veiculo.z
            },
            local_ferramentas = {
                item.local_ferramentas.x,
                item.local_ferramentas.y,
                item.local_ferramentas.z,
                item.local_ferramentas.w
            },
            local_finalizar = {
                item.local_finalizar.x,
                item.local_finalizar.y,
                item.local_finalizar.z
            },
            log_webhook = item.log_webhook or ""
        }
    end
end

local function loadData()
    local raw = LoadResourceFile(GetCurrentResourceName(),CONFIG_FILE)
    local ok,decoded = pcall(json.decode,raw or "{}")

    if not ok or type(decoded) ~= "table" then
        print("^1[m_desmanche]^7 config.json inválido.")
        decoded = {}
    end

    Data.settings = type(decoded.settings) == "table" and decoded.settings or {
        porcentagem_veiculocomum = 0.35,
        porcentagem_veiculovip = 0.50,
        desmanchar_proprio_veiculo = true,
        desmanchar_veiculo_trabalho = false
    }

    Data.desmanches = type(decoded.desmanches) == "table" and decoded.desmanches or {}

    applyRuntime()
end

local function saveData()
    local ok = SaveResourceFile(
        GetCurrentResourceName(),
        CONFIG_FILE,
        json.encode(Data),
        -1
    )

    if not ok then
        return false,"Não foi possível salvar config.json."
    end

    applyRuntime()
    TriggerClientEvent("m_desmanche:syncConfig",-1,Data)
    return true
end

loadData()

RegisterNetEvent("m_desmanche:requestConfig",function()
    TriggerClientEvent("m_desmanche:syncConfig",source,Data)
end)

AddEventHandler("vRP:playerSpawn",function(_,source)
    TriggerClientEvent("m_desmanche:syncConfig",source,Data)
end)

exports("getDesmancheConfig",function()
    return copy(Data)
end)

exports("addDesmanche",function(payload)
    local item,err = normalizeDesmanche(payload)
    if not item then return false,err end

    if findIndex(item.name) then
        return false,"Já existe um desmanche com este identificador."
    end

    Data.desmanches[#Data.desmanches+1] = item

    table.sort(Data.desmanches,function(a,b)
        return tostring(a.name):lower() < tostring(b.name):lower()
    end)

    local ok,msg = saveData()
    if not ok then
        local index = findIndex(item.name)
        if index then table.remove(Data.desmanches,index) end
        return false,msg
    end

    return true,"Desmanche criado e sincronizado."
end)

exports("updateDesmanche",function(originalName,payload)
    originalName = trim(originalName)

    local index = findIndex(originalName)
    if not index then return false,"Desmanche não encontrado." end

    local desiredName = trim(payload and payload.name)
    local item,err = normalizeDesmanche(payload,desiredName)
    if not item then return false,err end

    local collision = findIndex(item.name)
    if collision and collision ~= index then
        return false,"Já existe outro desmanche com este identificador."
    end

    local old = copy(Data.desmanches[index])
    Data.desmanches[index] = item

    table.sort(Data.desmanches,function(a,b)
        return tostring(a.name):lower() < tostring(b.name):lower()
    end)

    local ok,msg = saveData()
    if not ok then
        Data.desmanches = Data.desmanches or {}
        local current = findIndex(item.name)
        if current then
            Data.desmanches[current] = old
        end
        return false,msg
    end

    return true,"Desmanche atualizado e sincronizado."
end)

exports("removeDesmanche",function(name)
    local index = findIndex(trim(name))
    if not index then return false,"Desmanche não encontrado." end

    local old = table.remove(Data.desmanches,index)
    local ok,msg = saveData()

    if not ok then
        table.insert(Data.desmanches,index,old)
        return false,msg
    end

    return true,"Desmanche excluído e sincronizado."
end)

exports("updateDesmancheSettings",function(payload)
    local settings,err = normalizeSettings(payload)
    if not settings then return false,err end

    local old = copy(Data.settings)
    Data.settings = settings

    local ok,msg = saveData()
    if not ok then
        Data.settings = old
        return false,msg
    end

    return true,"Configurações globais atualizadas."
end)
