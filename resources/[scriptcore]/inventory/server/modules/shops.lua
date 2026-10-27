---@param permission string
---@return boolean
function API.checkPermission(permission)
    local source = source
    local user_id = vRP.getUserId(source)
    return vRP.hasPermission(user_id, permission)
end

local SHOPS_FILE <const> = "config/shared.shops.json"

local function trim(v)
    return tostring(v or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function plainPoint(point)
    if type(point) ~= "table" then return nil end
    local c = point.coords or point
    local x,y,z = tonumber(c.x or c[1]), tonumber(c.y or c[2]), tonumber(c.z or c[3])
    if not x or not y or not z then return nil end
    return { coords={x=x,y=y,z=z}, blip=point.blip == true }
end

local function shopForClient(data)
    local out = {
        items = {},
        mode = data.mode or "buy",
        coords = {}
    }

    for item,price in pairs(data.items or {}) do
        out.items[item] = tonumber(price) or 0
    end

    if data.perm and data.perm ~= "" then out.perm = data.perm end
    if data.onlyWalletPayment == true then out.onlyWalletPayment = true end

    if type(data.blip) == "table" then
        out.blip = {
            text = tostring(data.blip.text or "Loja"),
            index = tonumber(data.blip.index) or 52,
            color = tonumber(data.blip.color) or 0,
            scale = tonumber(data.blip.scale) or 0.5
        }
    end

    for _,p in pairs(data.coords or {}) do
        local point = plainPoint(p)
        if point then out.coords[#out.coords+1] = point end
    end

    return out
end

local function serializeShops()
    local out = {}
    for name,data in pairs(Shops or {}) do
        out[name] = shopForClient(data)
    end
    return out
end

local function countEntries(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

local function saveShops()
    -- Gera um snapshot simples, sem vector3/userdata, antes de escrever.
    local snapshot = serializeShops()
    local encoded = json.encode(snapshot)

    if not encoded or encoded == "" then
        return false, "Falha ao gerar o JSON dos shops."
    end

    local ok = SaveResourceFile(GetCurrentResourceName(), SHOPS_FILE, encoded, -1)
    if not ok then
        return false, "Não foi possível salvar " .. SHOPS_FILE .. "."
    end

    -- Confirma que o arquivo realmente foi escrito e continua sendo um JSON válido.
    local raw = LoadResourceFile(GetCurrentResourceName(), SHOPS_FILE)
    if not raw or raw == "" then
        return false, "O arquivo de shops foi salvo, mas não pôde ser relido."
    end

    local decodeOk, decoded = pcall(json.decode, raw)
    if not decodeOk or type(decoded) ~= "table" then
        return false, "O arquivo de shops ficou inválido após a gravação."
    end

    -- Verificação mínima para impedir que o painel confirme uma gravação truncada.
    if countEntries(decoded) ~= countEntries(snapshot) then
        return false, "A validação do arquivo de shops falhou após salvar."
    end

    return true
end

local function syncAll(target)
    TriggerClientEvent("inventory:shops:fullSync", target or -1, serializeShops())
end

local function normalizeShop(name,data)
    name = trim(name)
    if name == "" then return nil, "Informe o nome da loja." end
    if #name > 80 or name:find("[%c]") then return nil, "Nome da loja inválido." end
    if type(data) ~= "table" then return nil, "Dados da loja inválidos." end

    local mode = trim(data.mode):lower()
    if mode ~= "buy" and mode ~= "sell" then
        return nil, "O modo deve ser buy ou sell."
    end

    local shop = { items = {}, mode = mode, coords = {} }

    for item,price in pairs(data.items or {}) do
        local itemName = trim(item)
        local value = tonumber(price)
        if itemName ~= "" and value and value >= 0 then
            shop.items[itemName] = value
        end
    end

    if not next(shop.items) then
        return nil, "Adicione pelo menos um item à loja."
    end

    local perm = trim(data.perm)
    if perm ~= "" then shop.perm = perm end
    if data.onlyWalletPayment == true then shop.onlyWalletPayment = true end

    if type(data.blip) == "table" and data.blip.enabled ~= false then
        shop.blip = {
            text = trim(data.blip.text) ~= "" and trim(data.blip.text) or name,
            index = tonumber(data.blip.index) or 52,
            color = tonumber(data.blip.color) or 0,
            scale = tonumber(data.blip.scale) or 0.5
        }
    end

    for _,point in pairs(data.coords or {}) do
        local p = plainPoint(point)
        if p then shop.coords[#shop.coords+1] = p end
    end

    return shop
end

function API.shopAction(store_index, item, amount, slot)
    local source = source
    local user_id = vRP.getUserId(source)
    local shopData = Shops[store_index]
    amount = tonumber(amount) or 0

    if shopData and shopData.items and shopData.items[item] and amount > 0 then
        if shopData.mode == "buy" then
            if not (vRP.computeInvWeight(user_id) + vRP.getItemWeight(item) * amount <= vRP.getInventoryMaxWeight(user_id)) then
                return { error = "Sem espaço suficiente!" }
            end

            local total = shopData.items[item] * amount

            if shopData.onlyWalletPayment then
                if not vRP.tryPayment(user_id,total) then
                    return { error = "Você precisa ter dinheiro em mãos para comprar isso." }
                end
            else
                if not vRP.tryFullPayment(user_id,total) then
                    return { error = "Dinheiro insuficiente" }
                end
            end

            vRP.giveInventoryItem(user_id,item,amount,slot)

            if InventoryAudit then
                InventoryAudit.Log("inventory_shop_buy", {
                    actorId = user_id,
                    details = ("**Loja:** %s\n%s\n**Valor total:** R$ %s\n**Pagamento:** %s"):format(
                        tostring(store_index),
                        InventoryAudit.ItemDetails(item, amount),
                        tostring(total),
                        shopData.onlyWalletPayment and "Carteira" or "Carteira/Banco"
                    )
                })
            end

            return { notify = "Compra realizada com sucesso!", money = total }
        elseif shopData.mode == "sell" then
            if HotbarWeapons and HotbarWeapons.IsDutyWeaponSlot(user_id, tostring(slot), item) then
                return { error = "Você não pode vender uma arma temporária de serviço." }
            end
            if HotbarWeapons then
                local active = HotbarWeapons.GetActive(user_id)
                if active and tostring(active.slot) == tostring(slot) then
                    HotbarWeapons.ForceHolster(source, user_id)
                end
            end

            if vRP.tryGetInventoryItem(user_id,item,amount,true,tostring(slot)) then
                local total = shopData.items[item] * amount
                vRP.giveMoney(user_id,total)

                if InventoryAudit then
                    InventoryAudit.Log("inventory_shop_sell", {
                        actorId = user_id,
                        details = ("**Loja:** %s\n%s\n**Valor recebido:** R$ %s"):format(
                            tostring(store_index),
                            InventoryAudit.ItemDetails(item, amount),
                            tostring(total)
                        )
                    })
                end

                return { notify = "Você recebeu R$" .. total, money = total }
            end

            return { error = "Você não tem o item à ser vendido!" }
        end
    end

    return { error = "Loja indisponível" }
end

RegisterNetEvent("inventory:shops:requestSync",function()
    syncAll(source)
end)

AddEventHandler("vRP:playerSpawn",function(_,src)
    syncAll(src)
end)

exports("getShopConfigs",function()
    local out = {}
    for name,data in pairs(Shops or {}) do
        out[#out+1] = { name = name, data = shopForClient(data) }
    end

    table.sort(out,function(a,b)
        return a.name:lower() < b.name:lower()
    end)

    return out
end)

exports("createShopConfig",function(name,data)
    name = trim(name)

    if Shops[name] then
        return false, "Já existe uma loja com esse nome."
    end

    local shop,err = normalizeShop(name,data)
    if not shop then return false,err end

    Shops[name] = shop
    local ok,msg = saveShops()

    if not ok then
        Shops[name] = nil
        return false,msg
    end

    syncAll(-1)
    return true, "Loja criada com sucesso."
end)

exports("updateShopConfig",function(originalName,name,data)
    originalName = trim(originalName)
    name = trim(name)

    if not Shops[originalName] then
        return false, "Loja não encontrada."
    end

    if name ~= originalName and Shops[name] then
        return false, "Já existe uma loja com esse nome."
    end

    local shop,err = normalizeShop(name,data)
    if not shop then return false,err end

    local old = Shops[originalName]
    Shops[originalName] = nil
    Shops[name] = shop

    local ok,msg = saveShops()
    if not ok then
        Shops[name] = nil
        Shops[originalName] = old
        return false,msg
    end

    -- Mantém a tabela runtime exatamente igual ao que acabou de ser persistido.
    -- Isso evita divergência entre memória, JSON e clients após uma edição.
    syncAll(-1)
    print(("^2[inventory]^7 Shop '%s' atualizado e persistido em %s (%s itens)."):format(name, SHOPS_FILE, countEntries(shop.items)))
    return true, "Loja atualizada e salva no JSON com sucesso."
end)

exports("removeShopConfig",function(name)
    name = trim(name)

    if not Shops[name] then
        return false, "Loja não encontrada."
    end

    local old = Shops[name]
    Shops[name] = nil

    local ok,msg = saveShops()
    if not ok then
        Shops[name] = old
        return false,msg
    end

    syncAll(-1)
    return true, "Loja excluída com sucesso."
end)

exports("reloadShops",function()
    if not LoadShopsFromJson() then
        return false, "Falha ao recarregar o JSON."
    end

    syncAll(-1)
    return true, "Lojas recarregadas."
end)

-- Compatibilidade com integrações antigas que usavam somente os pontos do Mercado.
exports("getShops",function()
    local shops = {}
    for id,data in ipairs((Shops["Mercado"] and Shops["Mercado"].coords) or {}) do
        shops[#shops+1] = {
            id = id,
            coords = data.coords,
            blip = data.blip == true
        }
    end
    return shops
end)

exports("addShop",function(coords,blip)
    if not Shops["Mercado"] then
        return false, "Loja Mercado não encontrada."
    end

    local point = plainPoint({ coords = coords, blip = blip })
    if not point then
        return false, "Coordenadas inválidas."
    end

    Shops["Mercado"].coords[#Shops["Mercado"].coords+1] = {
        coords = vec3(point.coords.x,point.coords.y,point.coords.z),
        blip = point.blip
    }

    local ok,msg = saveShops()
    if not ok then return false,msg end

    syncAll(-1)
    return true, "Ponto do Mercado adicionado."
end)

exports("removeShop",function(id)
    if not Shops["Mercado"] then
        return false, "Loja Mercado não encontrada."
    end

    id = tonumber(id)
    if not id or not Shops["Mercado"].coords[id] then
        return false, "Ponto não encontrado."
    end

    table.remove(Shops["Mercado"].coords,id)

    local ok,msg = saveShops()
    if not ok then return false,msg end

    syncAll(-1)
    return true, "Ponto do Mercado removido."
end)
