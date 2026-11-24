local busy = {}
local categories = {vips=true, exclusivos=true, brasileiros=true, som=true, motos=true, blindados=true}
local pack = module('vrp', 'cfg/carros_som')
local decoded, addons = pcall(json.decode, LoadResourceFile(GetCurrentResourceName(), 'addon_catalog.json') or '{}')
addons = decoded and type(addons) == 'table' and addons or {}

local function installed(spawn)
    local entry = addons[spawn]
    return entry and GetResourceState(entry.resource) == 'started'
end

local function owner(player)
    local user = vRP.getUserId(player)
    return user and vRP.hasGroup(user, 'dono') == true, user
end

function Server.getShowroomEditor()
    local allowed = owner(source)
    if not allowed then return {canManage=false} end
    local catalog = exports.m_garage:getVehicleCatalog()
    local result = {}
    for spawn, addon in pairs(addons) do
        if installed(spawn) then
            local entry = catalog[spawn] or {}
            local store = DealershipConfig.vehicles[spawn] or {}
            result[spawn] = {
                name=store.displayName or entry.name or addon.name or spawn, price=entry.price or 0, trunk=entry.trunk or 0,
                currency=store.currency or 'cash', diamondPrice=store.diamondPrice,
                stock=store.stock, category=store.category, inStore=store.stock ~= nil,
                registered=catalog[spawn] ~= nil, image=addon.image
            }
        end
    end
    return {canManage=true, catalog=result}
end

local function number(value, maximum)
    value = tonumber(value)
    if not value or value ~= value or value < 0 or value > maximum or value % 1 ~= 0 then return nil end
    return value
end

function Server.addShowroomVehicle(payload)
    local player = source
    local allowed, user = owner(player)
    if not allowed then return {ok=false, message='Somente o cargo dono pode adicionar veiculos.'} end
    if type(payload) ~= 'table' or type(payload.spawn) ~= 'string' then return {ok=false, message='Cadastro invalido.'} end
    local spawn = pack.resolve(payload.spawn)
    local stock = number(payload.stock, 10000)
    local displayName = tostring(payload.name or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if displayName == '' or #displayName > 160 or displayName:find('%c') then
        return {ok=false, message='Informe o nome que aparecera na loja (ate 160 bytes).'}
    end
    local currency = payload.currency or 'cash'
    local diamondPrice = currency == 'diamonds' and number(payload.diamondPrice, 1000000000) or nil
    if #spawn > 50 or not spawn:match('^[a-z0-9_%.%-]+$') or not stock or not categories[payload.category] then
        return {ok=false, message='Confira o modelo, a categoria e o estoque (0 a 10000).'}
    end
    if not installed(spawn) then return {ok=false, message='Escolha um veiculo personalizado instalado e iniciado na cidade.'} end
    local mode=payload.mode or 'add'
    if mode~='add' and mode~='edit' then return {ok=false,message='Operacao invalida.'} end
    if mode=='add' and DealershipConfig.vehicles[spawn] then return {ok=false,message='Este veiculo ja foi adicionado ao painel. Use Editar veiculo.'} end
    if mode=='edit' and not DealershipConfig.vehicles[spawn] then return {ok=false,message='Este veiculo nao esta mais na loja. Atualize o painel.'} end
    if currency ~= 'cash' and currency ~= 'diamonds' or currency == 'diamonds' and (not diamondPrice or diamondPrice < 1) then
        return {ok=false, message='Informe uma moeda e um preco em diamantes validos.'}
    end
    if busy[spawn] then return {ok=false, message='Este veiculo ja esta sendo cadastrado.'} end
    busy[spawn] = true
    local ok, response = xpcall(function()
        local existing = exports.m_garage:getVehicleCatalogEntry(spawn)
        local created = false
        if not existing then
            local price, trunk = number(payload.price, 1000000000000), number(payload.trunk, 100000)
            local name = tostring(payload.name or ''):gsub('^%s+', ''):gsub('%s+$', '')
            if not price or not trunk or name == '' or #name > 80 then
                return {ok=false, message='Informe nome, preco e porta-malas validos para o novo modelo.'}
            end
            local saved, message = exports.m_garage:saveVehicleCatalogEntry('', spawn, {
                model=spawn, name=name, price=price, trunk=trunk, banned=false,
                type=payload.category == 'vips' and 'vip' or payload.category == 'brasileiros' and 'brasileiros' or 'outros'
            })
            if not saved then return {ok=false, message=message} end
            created = true
        end
        local saved, message = exports[GetCurrentResourceName()]:saveDealershipVehicle(spawn, stock, {
            actorId=user, origin='Cadastro pelo showroom Luxury Motors'
        }, payload.category, {currency=currency, diamondPrice=diamondPrice, displayName=displayName})
        if not saved and created then exports.m_garage:removeVehicleCatalogEntry(spawn) end
        return {ok=saved == true, message=message, category=payload.category}
    end, debug.traceback)
    busy[spawn] = nil
    if not ok then
        print('[luxurymotors] Falha no cadastro: ' .. tostring(response))
        return {ok=false, message='Nao foi possivel concluir o cadastro.'}
    end
    return response
end

function Server.removeShowroomVehicle(payload)
    local allowed,user=owner(source)
    if not allowed then return {ok=false,message='Somente o cargo dono pode remover veiculos.'} end
    if type(payload)~='table' or type(payload.spawn)~='string' then return {ok=false,message='Veiculo invalido.'} end
    local spawn=payload.spawn:lower()
    if #spawn>50 or not spawn:match('^[a-z0-9_%.%-]+$') then return {ok=false,message='Veiculo invalido.'} end
    if not DealershipConfig.vehicles[spawn] then return {ok=false,message='Este veiculo nao esta mais na loja.'} end
    if busy[spawn] then return {ok=false,message='Este veiculo ja esta sendo alterado.'} end
    busy[spawn]=true
    local ok,saved,message=pcall(function()
        return exports[GetCurrentResourceName()]:removeDealershipVehicle(spawn,{
            actorId=user,origin='Remocao pelo showroom Luxury Motors'
        })
    end)
    busy[spawn]=nil
    if not ok then
        print('[luxurymotors] Falha ao remover '..spawn..': '..tostring(saved))
        return {ok=false,message='Nao foi possivel remover o veiculo.'}
    end
    return {ok=saved==true,message=message}
end
