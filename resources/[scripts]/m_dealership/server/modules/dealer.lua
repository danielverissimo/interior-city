Dealership = {
    list = {}
}

local userActionLocks = {}
local vehiclePurchaseLocks = {}

local function response(ok, message, extra)
    local data = extra or {}
    data.ok = ok == true
    if message then data.message = message end
    return data
end

local function notify(source, notifyType, message)
    TriggerClientEvent("Notify", source, notifyType, message, 5)
end

local function acquireLocks(user_id, vehicle)
    if userActionLocks[user_id] then
        return false, "Você já possui uma operação em andamento."
    end

    if vehicle and vehiclePurchaseLocks[vehicle] then
        return false, "Este veículo está sendo processado por outro comprador. Tente novamente."
    end

    userActionLocks[user_id] = true
    if vehicle then vehiclePurchaseLocks[vehicle] = true end
    return true
end

local function releaseLocks(user_id, vehicle)
    userActionLocks[user_id] = nil
    if vehicle then vehiclePurchaseLocks[vehicle] = nil end
end

function Dealership:addCar(index, value, insert)
    self.list[index] = value

    if insert then
        vRP.execute("bm_module/dealership/addVehicle", {
            vehicle = index,
            stock = self.list[index].stock
        })
    end
end

function Dealership:remCar(index)
    if not self.list[index] then return end

    self.list[index] = nil
    vRP.execute("bm_module/dealership/removeVehicle", { vehicle = index })
end

function Dealership:getCar(index)
    if not index or not self.list[index] then return false end
    return self.list[index]
end

function Dealership:getUserVehicles(user_id)
    local query = vRP.query("bm_module/garages/getAllUserVehicles", { user_id = user_id })
    local listCars = {}

    if type(query) ~= "table" or not next(query) then
        return listCars
    end

    for i = 1, #query do
        local vehicle = tostring(query[i].veiculo or "")
        if vehicle ~= "" then
            local carDetails = Dealership:getCar(vehicle)

            listCars[vehicle] = {
                name = (carDetails and carDetails.name) or 'Carro não encontrado',
                price = parseInt(carDetails and (carDetails.price - (carDetails.price * Default.sellVehicle / 100)) or 0),
                type = 'meus-veiculos',
                category = 'meus-veiculos',
                trunk = carDetails and carDetails.trunk or 0,
                vip = carDetails and carDetails.vip or false,
                amountSell = carDetails and carDetails.amountSell or 0,
                stock = 0
            }
        end
    end

    return listCars
end

function Dealership:updateVehicleState(index, fields)
    local car = self.list[index]
    if not car or type(fields) ~= "table" then return false end

    local runtimeFields = {}

    if fields.stock ~= nil then
        car.stock = math.max(0, math.floor(tonumber(fields.stock) or 0))
        runtimeFields.stock = car.stock
        vRP.execute("bm_module/dealership/updateStock", {
            vehicle = index,
            stock = car.stock
        })
    end

    if fields.amountSell ~= nil then
        car.amountSell = math.max(0, math.floor(tonumber(fields.amountSell) or 0))
        runtimeFields.amountSell = car.amountSell
    end

    if next(runtimeFields) then
        local ok = exports[GetCurrentResourceName()]:syncDealershipVehicleRuntime(index, runtimeFields)
        return ok == true
    end

    return true
end

function Dealership:updateStock(index, amount)
    return self:updateVehicleState(index, { stock = amount })
end

function Dealership:updateAmountSell(index, amountSell)
    return self:updateVehicleState(index, { amountSell = amountSell })
end

local vipSlotsSourceWarned = false

local function getStoredPanelVipGarageSlots(user_id)
    local raw = LoadResourceFile("m_paineladm_v2", "vip_packages.json")
    if type(raw) ~= "string" or raw == "" then return nil end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= "table" or type(decoded.packages) ~= "table" then
        return nil
    end

    local total = 0
    for groupName, package in pairs(decoded.packages) do
        if type(package) == "table" and vRP.hasGroup(user_id, tostring(groupName)) then
            total = total + math.max(0, math.floor(tonumber(package.garageSlots) or 0))
        end
    end

    return total
end

-- Fonte única das vagas VIP: o pacote criado/editado no m_paineladm_v2.
-- Com o painel ligado usamos o export em memória; se ele estiver reiniciando,
-- lemos o vip_packages.json diretamente. Assim a concessionária nunca depende
-- da antiga tabela de maxCars por permissão e não existe risco de somar duas vezes.
local function getPanelVipGarageSlots(user_id)
    if GetResourceState("m_paineladm_v2") == "started" then
        local ok, slots = pcall(function()
            return exports["m_paineladm_v2"]:getVipGarageSlotsForUser(user_id)
        end)

        if ok then
            vipSlotsSourceWarned = false
            return math.max(0, math.floor(tonumber(slots) or 0))
        end
    end

    local storedSlots = getStoredPanelVipGarageSlots(user_id)
    if storedSlots ~= nil then
        vipSlotsSourceWarned = false
        return storedSlots
    end

    if not vipSlotsSourceWarned then
        vipSlotsSourceWarned = true
        print("^3[m_dealership]^7 Não foi possível consultar vip_packages.json do m_paineladm_v2; aplicando somente as 5 vagas padrão até a integração ficar disponível.")
    end
    return 0
end

function Dealership:getUserAmountCars(user_id)
    if not user_id then return tonumber(Default.maxCars) or 5, 0 end

    local query = vRP.query("bm_module/dealership/totalVehicles", { user_id = user_id })
    local totalCars = 0
    if type(query) == "table" and query[1] then
        totalCars = tonumber(query[1].qtd) or 0
    end

    local baseCars = math.max(0, math.floor(tonumber(Default.maxCars) or 5))
    local vipExtraSlots = getPanelVipGarageSlots(user_id)

    return baseCars + vipExtraSlots, totalCars
end

function Dealership:getTopSoldVehicles()
    local vehicles = {}
    for index, data in pairs(self.list) do
        vehicles[#vehicles + 1] = { index = index, data = data }
    end

    local allZero = true
    for _, vehicle in ipairs(vehicles) do
        if (tonumber(vehicle.data.amountSell) or 0) > 0 then
            allZero = false
            break
        end
    end

    local topVehicles = {}

    if allZero then
        if type(Default.notTop4Vehicles) == "table" then
            for _, vehicle in ipairs(Default.notTop4Vehicles) do
                if self.list[vehicle] then
                    topVehicles[#topVehicles + 1] = { index = vehicle, data = self.list[vehicle] }
                    if #topVehicles >= 4 then break end
                end
            end
        end
        return topVehicles
    end

    table.sort(vehicles, function(a, b)
        return (tonumber(a.data.amountSell) or 0) > (tonumber(b.data.amountSell) or 0)
    end)

    for i = 1, math.min(4, #vehicles) do
        topVehicles[#topVehicles + 1] = vehicles[i]
    end

    if type(Default.notTop4Vehicles) == "table" and #topVehicles < 4 then
        for _, vehicle in ipairs(Default.notTop4Vehicles) do
            local alreadyInTop = false
            for _, topVehicle in ipairs(topVehicles) do
                if topVehicle.index == vehicle then
                    alreadyInTop = true
                    break
                end
            end

            if not alreadyInTop and self.list[vehicle] then
                topVehicles[#topVehicles + 1] = { index = vehicle, data = self.list[vehicle] }
            end

            if #topVehicles >= 4 then break end
        end
    end

    return topVehicles
end

local function parseRGBA(rgbaString)
    if type(rgbaString) ~= "string" then
        return { r = 255, g = 255, b = 255, a = 1 }
    end

    local r, g, b, a = rgbaString:match("rgba%((%d+),%s*(%d+),%s*(%d+),%s*(%d+%.?%d*)%)")
    return {
        r = math.max(0, math.min(255, tonumber(r) or 255)),
        g = math.max(0, math.min(255, tonumber(g) or 255)),
        b = math.max(0, math.min(255, tonumber(b) or 255)),
        a = tonumber(a) or 1
    }
end

local function createTunagem(colorString)
    local color = parseRGBA(colorString)
    local tunagem = {
        extracolor = { 0, 0 },
        wheeltype = 0,
        mods = {},
        customPcolor = { color.r, color.g, color.b },
        customScolor = { color.r, color.g, color.b },
        pcolortype = "metálico",
        scolortype = "metálico",
        color = { 0, 0 },
        neoncolor = { 0, 0, 0 },
        neon = false,
        smokecolor = { 255, 255, 255 },
        xenoncolor = 0,
        windowtint = 1,
        bulletProofTyres = false,
        damage = 0.0
    }

    for i = 0, 48 do
        if i == 23 or i == 24 then
            tunagem.mods[tostring(i)] = { mod = -1, variation = false }
        else
            tunagem.mods[tostring(i)] = { mod = -1 }
        end
    end

    return tunagem
end

local function getHighestDiscount(user_id)
    local highestDiscount = 0
    if type(Vips) ~= "table" then return highestDiscount end

    for i = 1, #Vips do
        local vip = Vips[i]
        if type(vip) == "table" and vip.permission and vRP.hasPermission(user_id, vip.permission) then
            highestDiscount = math.max(highestDiscount, tonumber(vip.discount) or 0)
        end
    end

    return math.max(0, math.min(100, highestDiscount))
end

-- Formatação apenas para as notificações (a moeda da vRP usa valores inteiros).
local function formatReais(amount)
    local n = math.max(0, math.floor(tonumber(amount) or 0))
    local value = tostring(n):reverse():gsub("(%d%d%d)", "%1."):reverse()
    return value:gsub("^%.", "")
end

-- A vRP desta base implementa vRP.execute usando query() ASSÍNCRONO.
-- Para registrar/remover veículos é obrigatório aguardar o MySQL confirmar a gravação.
local function insertOwnedVehicle(user_id, vehicle, ipva, tuning)
    local params = { user_id = user_id, vehicle = vehicle, ipva = ipva, tunagem = tuning }
    local ok, affected = pcall(function()
        return exports["oxmysql"]:update_async([[
            INSERT INTO vrp_user_veiculos (user_id, veiculo, ipva, tunagem)
            SELECT @user_id, @vehicle, @ipva, @tunagem
            WHERE NOT EXISTS (
                SELECT 1 FROM vrp_user_veiculos WHERE user_id = @user_id AND veiculo = @vehicle
            )
        ]], params)
    end)

    if ok and (tonumber(affected) or 0) > 0 then
        return true, "inserido"
    end

    -- Em falhas de comunicação pode ocorrer: a inserção foi confirmada pelo
    -- MySQL, mas a resposta não chegou ao script. Consulte a posse antes de
    -- considerar qualquer reembolso; jamais dê dinheiro e carro ao mesmo tempo.
    local verified, owned = pcall(function()
        local rows = vRP.query("bm_module/dealership/getVehicle", { user_id = user_id, vehicle = vehicle })
        assert(type(rows) == "table", "Falha ao consultar a posse")
        return next(rows) ~= nil
    end)
    if verified and owned then
        if ok then
            return false, "veiculo_ja_possuido"
        end
        return true, "confirmado_apos_erro_mysql"
    end
    if verified then
        return false, ok and "nenhuma_linha_inserida" or tostring(affected)
    end
    -- Erro ao inserir E erro ao consultar: resultado indeterminado.
    -- Não é seguro efetuar um reembolso automático nessa situação.
    return nil, ("Inserção: %s | Consulta: %s"):format(tostring(affected), tostring(owned))
end

function Dealership:buyVehicle(user_id, source, vehicle, rgba)
    local nearDealership = DealershipAudit.IsNearDealership(source, 8.0)
    if not nearDealership then
        DealershipAudit.Log("dealership_security_remote_action", {
            actorId = user_id,
            details = ("Tentou comprar o veículo `%s` sem estar próximo de uma concessionária.\n%s"):format(
                tostring(vehicle), DealershipAudit.CoordsLine(source) or "Coordenadas indisponíveis."
            )
        })
        local message = "Você precisa estar na concessionária para realizar uma compra."
        notify(source, "negado", message)
        return response(false, message)
    end

    local cooldownOk, remaining = exports['vrp']:getCooldown(user_id, "dealership:buy")
    if not cooldownOk then
        local message = ("Aguarde %d segundo(s) para realizar outra compra."):format(math.max(1, tonumber(remaining) or 1))
        notify(source, "negado", message)
        return response(false, message)
    end

    local locked, lockMessage = acquireLocks(user_id, vehicle)
    if not locked then
        notify(source, "negado", lockMessage)
        return response(false, lockMessage)
    end

    local chargedAmount = 0
    local paymentMethod = nil
    local deliveryConfirmed = false
    local deliveryUncertain = false
    local paidNotificationSent = false
    local purchasedPrice, purchasedStock = nil, nil

    local function paidMessage()
        local origin = paymentMethod == "bank" and "o dinheiro do banco" or "dinheiro da carteira"
        return ("Pago com %s no valor de R$ %s."):format(origin, formatReais(chargedAmount))
    end

    local function refundOriginalAccount()
        if chargedAmount <= 0 then return true end
        local amount = chargedAmount
        local ok, refunded = pcall(function()
            if paymentMethod == "bank" then
                local before = tonumber(vRP.getBankMoney(user_id)) or 0
                vRP.giveBankMoney(user_id, amount)
                return (tonumber(vRP.getBankMoney(user_id)) or 0) >= before + amount
            elseif paymentMethod == "wallet" then
                return vRP.giveMoney(user_id, amount) == true
            end
            return false
        end)
        if ok and refunded then
            chargedAmount = 0
            return true
        end
        DealershipAudit.Log("dealership_system_transaction_error", {
            actorId = user_id,
            details = ("ATENÇÃO: falha ao ressarcir compra de `%s`. Origem: %s | Valor: R$ %s | Erro: %s")
                :format(tostring(vehicle), tostring(paymentMethod), formatReais(amount), tostring(refunded))
        })
        print(("^1[m_dealership]^7 REEMBOLSO NÃO CONFIRMADO: ID %s | veículo %s | origem %s | R$ %s")
            :format(tostring(user_id), tostring(vehicle), tostring(paymentMethod), formatReais(amount)))
        return false
    end

    local ok, result = xpcall(function()
        local carBuy = self:getCar(vehicle)
        if not carBuy then
            DealershipAudit.Log("dealership_security_invalid_purchase", {
                actorId = user_id,
                details = ("Solicitou compra de um spawn inexistente/indisponível: `%s`.\n%s"):format(
                    tostring(vehicle), DealershipAudit.CoordsLine(source) or "Coordenadas indisponíveis."
                )
            })
            local message = "Este veículo não está disponível na concessionária."
            notify(source, "negado", message)
            return response(false, message)
        end

        local stock = math.max(0, parseInt(carBuy.stock))
        if stock <= 0 then
            local message = "Veículo sem estoque."
            notify(source, "negado", message)
            return response(false, message)
        end

        local query = vRP.query("bm_module/dealership/getVehicle", { user_id = user_id, vehicle = vehicle }) or {}
        if next(query) then
            local message = "Você já possui esse veículo em sua garagem."
            notify(source, "negado", message)
            return response(false, message)
        end

        local maxCars, totalCars = self:getUserAmountCars(user_id)
        if totalCars >= maxCars then
            local message = ("Você atingiu o limite de veículos da garagem (%d/%d). VIPs ativos podem liberar vagas adicionais."):format(totalCars, maxCars)
            notify(source, "negado", message)
            return response(false, message, { totalCars = totalCars, maxCars = maxCars })
        end

        if GetResourceState('m_garage') ~= 'started' then
            local message = "A garagem está indisponível no momento."
            notify(source, "negado", message)
            return response(false, message)
        end

        -- A categoria VIP é apenas classificatória: qualquer veículo
        -- cadastrado com estoque e preço válidos pode ser comprado.
        -- Continuam ativas as verificações de propriedade, garagem e pagamento.

        local highestDiscount = getHighestDiscount(user_id)
        local basePrice = math.max(0, tonumber(carBuy.price) or 0)
        local price = parseInt(basePrice - (basePrice * highestDiscount / 100))
        if price <= 0 then
            local message = "Este veículo está sem preço válido para compra. Avise a administração."
            notify(source, "negado", message)
            return response(false, message)
        end

        -- A vRP fornecida implementa tryFullPayment com a ordem exata:
        -- banco integral primeiro; só se faltar no banco, carteira integral.
        -- Não divide a compra entre as duas contas.
        local bankBalance = tonumber(vRP.getBankMoney(user_id)) or 0
        local walletBalance = tonumber(vRP.getMoney(user_id)) or 0
        if bankBalance < price and walletBalance < price then
            local message = "Você não possui saldo suficiente no banco nem na carteira."
            notify(source, "negado", message)
            return response(false, message)
        end
        if not vRP.tryFullPayment(user_id, price) then
            local message = "Não foi possível processar o pagamento. Verifique seu saldo."
            notify(source, "negado", message)
            return response(false, message)
        end
        paymentMethod = (tonumber(vRP.getBankMoney(user_id)) or 0) < bankBalance and "bank" or "wallet"
        chargedAmount = price
        purchasedPrice = price

        local tunagem = createTunagem(rgba)
        local ipva = os.time()
        local inserted, reason = insertOwnedVehicle(user_id, vehicle, ipva, json.encode(tunagem))
        if inserted == nil then
            deliveryUncertain = true
            local message = "A confirmação do MySQL está indisponível. Não repita a compra; contate o suporte para verificar a entrega e o pagamento."
            DealershipAudit.Log("dealership_system_transaction_error", {
                actorId = user_id,
                details = DealershipAudit.VehicleDetails(vehicle, carBuy, {
                    "RESULTADO INDETERMINADO: nenhum reembolso automático para evitar veículo grátis.",
                    ("Valor: R$ %s | Origem: %s"):format(formatReais(price), tostring(paymentMethod)),
                    ("Diagnóstico: %s"):format(tostring(reason):sub(1, 600))
                })
            })
            print(("^1[m_dealership]^7 COMPRA PENDENTE DE CONFERÊNCIA: ID %s, spawn %s, %s")
                :format(tostring(user_id), tostring(vehicle), tostring(reason)))
            notify(source, "aviso", message)
            return response(false, message, { pendingVerification = true })
        end
        if inserted == false then
            local refunded = refundOriginalAccount()
            local message = refunded and
                (reason == "veiculo_ja_possuido" and "Você já possui esse veículo. O pagamento foi devolvido para a conta utilizada." or "Não foi possível registrar o veículo. O pagamento foi devolvido para a conta utilizada.") or
                "Não foi possível registrar o veículo e o reembolso não foi confirmado. Contate o suporte."
            DealershipAudit.Log("dealership_vehicle_delivery_failed", {
                actorId = user_id,
                details = DealershipAudit.VehicleDetails(vehicle, carBuy, {
                    ("Valor: **R$ %s** | Origem: **%s**"):format(formatReais(price), tostring(paymentMethod)),
                    ("Reembolso confirmado: **%s**"):format(refunded and "SIM" or "NÃO"),
                    ("Motivo: %s"):format(tostring(reason)),
                    DealershipAudit.CoordsLine(source)
                })
            })
            notify(source, "negado", message)
            return response(false, message)
        end

        -- A confirmação veio da gravação aguardada pelo MySQL; uma consulta
        -- imediata não deve mais decidir se o pagamento será reembolsado.
        deliveryConfirmed = true
        local newStock = math.max(0, stock - 1)
        local newAmountSell = math.max(0, (tonumber(carBuy.amountSell) or 0) + 1)
        purchasedStock = newStock
        local stateSaved = self:updateVehicleState(vehicle, { stock = newStock, amountSell = newAmountSell })
        exports['vrp']:setCooldown(user_id, "dealership:buy", math.max(0, tonumber(Default.purchaseCooldown) or 5))

        DealershipAudit.Log("dealership_vehicle_purchase", {
            actorId = user_id,
            details = DealershipAudit.VehicleDetails(vehicle, carBuy, {
                ("Valor de catálogo: **R$ %s**"):format(formatReais(basePrice)),
                ("Desconto aplicado: **%s%%**"):format(highestDiscount),
                ("Valor pago: **R$ %s** | Origem: **%s**"):format(formatReais(price), paymentMethod == "bank" and "Banco" or "Carteira"),
                ("Estoque: **%s → %s**"):format(stock, newStock),
                ("Vendas contabilizadas: **%s**"):format(newAmountSell),
                ("Cor: `%s` | Confirmação: `%s`"):format(tostring(rgba or "padrão"), tostring(reason)),
                DealershipAudit.CoordsLine(source)
            })
        })
        DealershipAudit.Log("dealership_vehicle_delivered", {
            actorId = user_id,
            details = DealershipAudit.VehicleDetails(vehicle, carBuy, {
                "Entrega confirmada pelo MySQL em `vrp_user_veiculos`.",
                ("IPVA inicial: `%s`"):format(ipva),
                ("Estoque restante: **%s**"):format(newStock)
            })
        })
        if stateSaved ~= true then
            DealershipAudit.Log("dealership_system_stock_sync_error", {
                actorId = user_id,
                details = DealershipAudit.VehicleDetails(vehicle, carBuy, {
                    ("Veículo entregue, mas houve falha na persistência do estoque. Esperado: **%s**."):format(newStock)
                })
            })
        end

        notify(source, "sucesso", "Parabéns pela compra! Você comprou um <b>" .. tostring(carBuy.name or vehicle) .. "</b>.")
        notify(source, "sucesso", paidMessage())
        paidNotificationSent = true
        return response(true, "Compra realizada com sucesso.", {
            price = price, stock = newStock, vehicle = vehicle,
            paymentMethod = paymentMethod
        })
    end, debug.traceback)

    releaseLocks(user_id, vehicle)

    if not ok then
        -- Se o INSERT já foi confirmado, falhas posteriores (log/estoque/
        -- notificação) nunca podem transformar a compra em 'falha de entrega'.
        if deliveryConfirmed then
            DealershipAudit.Log("dealership_system_transaction_error", {
                actorId = user_id,
                details = ("Veículo `%s` ENTREGUE, mas ocorreu falha pós-entrega: %s"):format(vehicle, tostring(result):sub(1, 700))
            })
            print(("^3[m_dealership]^7 Falha após entrega confirmada de '%s' ao ID %s:\n%s")
                :format(tostring(vehicle), tostring(user_id), tostring(result)))
            if not paidNotificationSent then
                notify(source, "sucesso", "Veículo registrado na garagem com sucesso.")
                notify(source, "sucesso", paidMessage())
            end
            return response(true, "Veículo entregue com sucesso.", {
                price = purchasedPrice, stock = purchasedStock, vehicle = vehicle,
                paymentMethod = paymentMethod
            })
        end

        -- Erro antes da confirmação: não ressarcir se a operação SQL ficou
        -- indeterminada. A conferência manual evita dar o carro gratuitamente.
        local refunded = false
        if not deliveryUncertain and chargedAmount > 0 then
            -- Um erro inesperado após o débito pode ter ocorrido durante INSERT.
            -- Verifique a posse antes de decidir o reembolso.
            local verified, owned = pcall(function()
                local rows = vRP.query("bm_module/dealership/getVehicle", { user_id = user_id, vehicle = vehicle })
                assert(type(rows) == "table", "Consulta de posse indisponível")
                return next(rows) ~= nil
            end)
            if not verified then
                deliveryUncertain = true
            elseif owned then
                deliveryConfirmed = true
            else
                refunded = refundOriginalAccount()
            end
        end

        DealershipAudit.Log("dealership_system_transaction_error", {
            actorId = user_id,
            details = ("Erro interno na compra de `%s`. Entrega confirmada: %s | Indeterminado: %s | Reembolso confirmado: %s | Erro: %s")
                :format(tostring(vehicle), deliveryConfirmed and "SIM" or "NÃO", deliveryUncertain and "SIM" or "NÃO", refunded and "SIM" or "NÃO", tostring(result):sub(1, 700))
        })
        print(("^1[m_dealership]^7 Erro ao comprar '%s' para o ID %s:\n%s"):format(tostring(vehicle), tostring(user_id), tostring(result)))

        if deliveryConfirmed then
            notify(source, "sucesso", "Veículo registrado na garagem com sucesso.")
            notify(source, "sucesso", paidMessage())
            return response(true, "Veículo entregue com sucesso.", { price = purchasedPrice, vehicle = vehicle, paymentMethod = paymentMethod })
        end
        local message = deliveryUncertain and "Não foi possível conferir o resultado da compra. Contate o suporte antes de tentar novamente." or
            (chargedAmount > 0 and "Erro na compra; reembolso não confirmado. Contate o suporte." or "Ocorreu um erro ao concluir a compra. Tente novamente.")
        notify(source, "negado", message)
        return response(false, message, { pendingVerification = deliveryUncertain })
    end

    return result
end

function Dealership:sellVehicle(user_id, source, vehicle)
    local nearDealership = DealershipAudit.IsNearDealership(source, 8.0)
    if not nearDealership then
        DealershipAudit.Log("dealership_security_remote_action", {
            actorId = user_id,
            details = ("Tentou vender o veículo `%s` sem estar próximo de uma concessionária.\n%s"):format(
                tostring(vehicle), DealershipAudit.CoordsLine(source) or "Coordenadas indisponíveis."
            )
        })
        local message = "Você precisa estar na concessionária para vender um veículo."
        notify(source, "negado", message)
        return response(false, message)
    end

    local cooldownOk, remaining = exports['vrp']:getCooldown(user_id, "dealership:sell")
    if not cooldownOk then
        local message = ("Aguarde %d segundo(s) para realizar outra venda."):format(math.max(1, tonumber(remaining) or 1))
        notify(source, "negado", message)
        return response(false, message)
    end

    local locked, lockMessage = acquireLocks(user_id)
    if not locked then
        notify(source, "negado", lockMessage)
        return response(false, lockMessage)
    end

    local saleRemoved, salePaid, salePaymentAccount, salePrice = false, false, nil, 0
    local saleUncertain = false
    local ok, result = xpcall(function()
        local car = self:getCar(vehicle)
        if not car then
            DealershipAudit.Log("dealership_security_invalid_sale", {
                actorId = user_id,
                details = ("Solicitou venda de um spawn inexistente/indisponível: `%s`.\n%s"):format(
                    tostring(vehicle), DealershipAudit.CoordsLine(source) or "Coordenadas indisponíveis."
                )
            })
            local message = "Este veículo não pode ser vendido nesta concessionária."
            notify(source, "negado", message)
            return response(false, message)
        end

        local query = vRP.query("bm_module/dealership/getVehicle", { user_id = user_id, vehicle = vehicle }) or {}
        if not next(query) then
            DealershipAudit.Log("dealership_security_invalid_sale", {
                actorId = user_id,
                details = DealershipAudit.VehicleDetails(vehicle, car, {
                    "Tentativa bloqueada: o veículo não pertence ao jogador.",
                    DealershipAudit.CoordsLine(source)
                })
            })
            local message = "Você não possui esse veículo em sua garagem."
            notify(source, "negado", message)
            return response(false, message)
        end

        if GetResourceState('m_garage') ~= 'started' then
            local message = "A garagem está indisponível no momento."
            notify(source, "negado", message)
            return response(false, message)
        end

        if car.vip == true or car.category == "vips" then
            DealershipAudit.Log("dealership_security_invalid_sale", {
                actorId = user_id,
                details = DealershipAudit.VehicleDetails(vehicle, car, {
                    "Tentativa bloqueada: venda de veículo VIP para a concessionária.",
                    DealershipAudit.CoordsLine(source)
                })
            })
            local message = "Veículos VIP não podem ser vendidos para a concessionária."
            notify(source, "negado", message)
            return response(false, message)
        end

        local price = parseInt((tonumber(car.price) or 0) - ((tonumber(car.price) or 0) * (tonumber(Default.sellVehicle) or 99) / 100))

        -- DELETE aguardado: a versão antiga consultava a garagem enquanto
        -- o vRP.execute ainda não havia concluído a remoção no MySQL.
        local removedOk, removedResult = pcall(function()
            return exports["oxmysql"]:update_async(
                "DELETE FROM vrp_user_veiculos WHERE veiculo = @vehicle AND user_id = @user_id",
                { user_id = user_id, vehicle = vehicle }
            )
        end)
        if removedOk then
            saleRemoved = (tonumber(removedResult) or 0) > 0
        else
            -- Pode haver falha na resposta do MySQL depois do DELETE ser aplicado.
            local verified, owned = pcall(function()
                local rows = vRP.query("bm_module/dealership/getVehicle", { user_id = user_id, vehicle = vehicle })
                assert(type(rows) == "table", "Consulta de posse indisponível")
                return next(rows) ~= nil
            end)
            if verified then
                saleRemoved = not owned
            else
                saleUncertain = true
            end
        end
        if saleUncertain then
            local message = "Não foi possível conferir o resultado da venda. Contate o suporte antes de tentar novamente."
            DealershipAudit.Log("dealership_system_transaction_error", {
                actorId = user_id,
                details = ("Venda de `%s` com estado de remoção INDETERMINADO: %s"):format(vehicle, tostring(removedResult))
            })
            notify(source, "aviso", message)
            return response(false, message, { pendingVerification = true })
        end
        if not saleRemoved then
            local message = "Não foi possível confirmar a remoção do veículo. Nenhum pagamento foi realizado."
            notify(source, "negado", message)
            return response(false, message)
        end

        -- Credita a carteira como antes; caso o inventário não aceite o item
        -- dinheiro, credita no banco para não deixar a venda sem pagamento.
        salePrice = price
        salePaymentAccount = "carteira"
        if price > 0 and vRP.giveMoney(user_id, price) ~= true then
            local bankBefore = tonumber(vRP.getBankMoney(user_id)) or 0
            vRP.giveBankMoney(user_id, price)
            if (tonumber(vRP.getBankMoney(user_id)) or 0) < bankBefore + price then
                error("Pagamento da venda não confirmado no banco")
            end
            salePaymentAccount = "banco"
        end
        salePaid = true
        exports['vrp']:setCooldown(user_id, "dealership:sell", math.max(0, tonumber(Default.sellCooldown) or 10))

        local basePrice = math.max(0, tonumber(car.price) or 0)
        local receivePercent = math.max(0, 100 - (tonumber(Default.sellVehicle) or 99))
        DealershipAudit.Log("dealership_vehicle_sold", {
            actorId = user_id,
            details = DealershipAudit.VehicleDetails(vehicle, car, {
                ("Valor de catálogo: **R$ %s**"):format(parseInt(basePrice)),
                ("Percentual de revenda configurado: **%s%%**"):format(receivePercent),
                ("Valor efetivamente recebido: **R$ %s**"):format(price),
                ("Veículo removido do MySQL antes do pagamento. Crédito realizado em: **%s**"):format(salePaymentAccount),
                DealershipAudit.CoordsLine(source)
            })
        })

        notify(source, "sucesso", "Você vendeu seu veículo <b>" .. tostring(car.name or vehicle) .. "</b> e recebeu R$ " .. formatReais(price) .. " na " .. salePaymentAccount .. ".")

        return response(true, "Venda realizada com sucesso.", {
            price = price,
            vehicle = vehicle
        })
    end, debug.traceback)

    releaseLocks(user_id)

    if not ok then
        DealershipAudit.Log("dealership_system_transaction_error", {
            actorId = user_id,
            details = ("Erro interno durante venda do spawn `%s`. Removido: %s | Pago: %s | Erro: `%s`")
                :format(tostring(vehicle), saleRemoved and "SIM" or "NÃO", salePaid and "SIM" or "NÃO", tostring(result):sub(1, 700))
        })
        print(("^1[m_dealership]^7 Erro ao vender '%s' do ID %s:\n%s"):format(tostring(vehicle), tostring(user_id), tostring(result)))
        if saleRemoved and salePaid then
            notify(source, "sucesso", "Veículo vendido e pagamento realizado na " .. tostring(salePaymentAccount) .. ".")
            return response(true, "Venda concluída com sucesso.", { price = salePrice, vehicle = vehicle })
        end
        local message = saleRemoved and "Veículo removido, mas o pagamento não foi confirmado. Contate o suporte; não tente repetir a operação." or
            "Ocorreu um erro ao concluir a venda. Tente novamente."
        notify(source, "negado", message)
        return response(false, message, { pendingVerification = saleRemoved })
    end

    return result
end
