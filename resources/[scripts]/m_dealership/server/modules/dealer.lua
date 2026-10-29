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

-- Uma única fonte: o provider selecionado na configuração operacional.
local function getPanelVipGarageSlots(user_id)
    local provider = GetConvar("ic_admin_service_resource", "ic_admin")
    if GetResourceState(provider) == "started" then
        local ok, slots = pcall(function()
            return exports[provider]:getVipGarageSlotsForUser(user_id)
        end)
        if ok and type(slots) == "number" then
            vipSlotsSourceWarned = false
            return math.max(0, math.floor(slots))
        end
    end
    if not vipSlotsSourceWarned then
        vipSlotsSourceWarned = true
        print("^3[m_dealership]^7 Provider de vagas VIP indisponível; mantendo somente as vagas padrão.")
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
    local deliveryConfirmed = false
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
        if #query > 0 then
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

        if carBuy.vip == true or carBuy.category == "vips" then
            DealershipAudit.Log("dealership_security_invalid_purchase", {
                actorId = user_id,
                details = DealershipAudit.VehicleDetails(vehicle, carBuy, {
                    "Tentativa bloqueada: compra direta de veículo VIP pela concessionária comum.",
                    DealershipAudit.CoordsLine(source)
                })
            })
            local message = "Veículos VIP não podem ser comprados por esta concessionária."
            notify(source, "negado", message)
            return response(false, message)
        end

        local highestDiscount = getHighestDiscount(user_id)
        local basePrice = math.max(0, tonumber(carBuy.price) or 0)
        local price = parseInt(basePrice - (basePrice * highestDiscount / 100))

        if not vRP.tryFullPayment(user_id, price) then
            local message = "Você não possui dinheiro suficiente."
            notify(source, "negado", message)
            return response(false, message)
        end
        chargedAmount = price

        local tunagem = createTunagem(rgba)
        vRP.execute("bm_module/dealership/addUserVehicleTuning", {
            user_id = user_id,
            vehicle = vehicle,
            ipva = os.time(),
            tunagem = json.encode(tunagem)
        })

        -- Confirma a entrega no banco antes de considerar a compra concluída. Se
        -- a inserção falhar, o jogador é ressarcido e o estoque não é consumido.
        local delivered = vRP.query("bm_module/dealership/getVehicle", { user_id = user_id, vehicle = vehicle }) or {}
        if not next(delivered) then
            vRP.giveMoney(user_id, price)
            chargedAmount = 0
            DealershipAudit.Log("dealership_vehicle_delivery_failed", {
                actorId = user_id,
                details = DealershipAudit.VehicleDetails(vehicle, carBuy, {
                    ("Valor ressarcido: **R$ %s**"):format(price),
                    "Falha: o veículo não foi localizado em `vrp_user_veiculos` após a inserção.",
                    DealershipAudit.CoordsLine(source)
                })
            })
            local message = "Não foi possível entregar o veículo. O valor da compra foi devolvido."
            notify(source, "negado", message)
            return response(false, message)
        end

        deliveryConfirmed = true
        local newStock = math.max(0, stock - 1)
        local newAmountSell = math.max(0, (tonumber(carBuy.amountSell) or 0) + 1)
        local stateSaved = self:updateVehicleState(vehicle, {
            stock = newStock,
            amountSell = newAmountSell
        })

        exports['vrp']:setCooldown(user_id, "dealership:buy", math.max(0, tonumber(Default.purchaseCooldown) or 5))

        local purchaseDetails = DealershipAudit.VehicleDetails(vehicle, carBuy, {
            ("Valor de catálogo: **R$ %s**"):format(parseInt(basePrice)),
            ("Desconto aplicado: **%s%%**"):format(highestDiscount),
            ("Valor efetivamente pago: **R$ %s**"):format(price),
            ("Estoque: **%s → %s**"):format(stock, newStock),
            ("Total de vendas contabilizadas: **%s**"):format(newAmountSell),
            ("Cor escolhida: `%s`"):format(tostring(rgba or "padrão")),
            DealershipAudit.CoordsLine(source)
        })
        DealershipAudit.Log("dealership_vehicle_purchase", { actorId = user_id, details = purchaseDetails })
        DealershipAudit.Log("dealership_vehicle_delivered", {
            actorId = user_id,
            details = DealershipAudit.VehicleDetails(vehicle, carBuy, {
                "Entrega confirmada: veículo registrado em `vrp_user_veiculos`.",
                ("IPVA inicial: `%s`"):format(os.time()),
                ("Estoque restante: **%s**"):format(newStock)
            })
        })

        if stateSaved ~= true then
            DealershipAudit.Log("dealership_system_stock_sync_error", {
                actorId = user_id,
                details = DealershipAudit.VehicleDetails(vehicle, carBuy, {
                    ("A compra foi entregue, porém a persistência do estoque retornou falha. Estoque esperado: **%s**."):format(newStock)
                })
            })
        end

        notify(source, "sucesso", "Parabéns pela compra! Você comprou um <b>" .. tostring(carBuy.name or vehicle) .. "</b>.")
        return response(true, "Compra realizada com sucesso.", {
            price = price,
            stock = newStock,
            vehicle = vehicle
        })
    end, debug.traceback)

    releaseLocks(user_id, vehicle)

    if not ok then
        local refunded = false
        if chargedAmount > 0 and not deliveryConfirmed then
            local refundOk = pcall(function() vRP.giveMoney(user_id, chargedAmount) end)
            refunded = refundOk == true
            if refunded then chargedAmount = 0 end
        end
        DealershipAudit.Log("dealership_system_transaction_error", {
            actorId = user_id,
            details = ("Erro interno durante compra do spawn `%s`.\nEntrega confirmada: **%s**\nRessarcimento de segurança: **%s**\nErro: `%s`"):format(
                tostring(vehicle), deliveryConfirmed and "SIM" or "NÃO", refunded and "SIM" or "NÃO", tostring(result):sub(1, 700)
            )
        })
        print(("^1[m_dealership]^7 Erro ao comprar '%s' para o ID %s:\n%s"):format(tostring(vehicle), tostring(user_id), tostring(result)))
        local message = "Ocorreu um erro ao concluir a compra. Tente novamente."
        notify(source, "negado", message)
        return response(false, message)
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

        vRP.execute("bm_module/dealership/removeUserVehicle", {
            user_id = user_id,
            vehicle = vehicle
        })

        local stillOwned = vRP.query("bm_module/dealership/getVehicle", { user_id = user_id, vehicle = vehicle }) or {}
        if next(stillOwned) then
            DealershipAudit.Log("dealership_system_transaction_error", {
                actorId = user_id,
                details = DealershipAudit.VehicleDetails(vehicle, car, {
                    "A venda foi interrompida porque o veículo continuou registrado após a tentativa de remoção.",
                    DealershipAudit.CoordsLine(source)
                })
            })
            local message = "Não foi possível remover o veículo da sua garagem. Nenhum valor foi pago."
            notify(source, "negado", message)
            return response(false, message)
        end

        vRP.giveMoney(user_id, price)
        exports['vrp']:setCooldown(user_id, "dealership:sell", math.max(0, tonumber(Default.sellCooldown) or 10))

        local basePrice = math.max(0, tonumber(car.price) or 0)
        local receivePercent = math.max(0, 100 - (tonumber(Default.sellVehicle) or 99))
        DealershipAudit.Log("dealership_vehicle_sold", {
            actorId = user_id,
            details = DealershipAudit.VehicleDetails(vehicle, car, {
                ("Valor de catálogo: **R$ %s**"):format(parseInt(basePrice)),
                ("Percentual de revenda configurado: **%s%%**"):format(receivePercent),
                ("Valor efetivamente recebido: **R$ %s**"):format(price),
                "Veículo removido de `vrp_user_veiculos` antes do pagamento.",
                DealershipAudit.CoordsLine(source)
            })
        })

        notify(source, "sucesso", "Você vendeu seu veículo <b>" .. tostring(car.name or vehicle) .. "</b> e recebeu R$ " .. price .. ".")

        return response(true, "Venda realizada com sucesso.", {
            price = price,
            vehicle = vehicle
        })
    end, debug.traceback)

    releaseLocks(user_id)

    if not ok then
        DealershipAudit.Log("dealership_system_transaction_error", {
            actorId = user_id,
            details = ("Erro interno durante venda do spawn `%s`.\nErro: `%s`"):format(tostring(vehicle), tostring(result):sub(1, 700))
        })
        print(("^1[m_dealership]^7 Erro ao vender '%s' do ID %s:\n%s"):format(tostring(vehicle), tostring(user_id), tostring(result)))
        local message = "Ocorreu um erro ao concluir a venda. Tente novamente."
        notify(source, "negado", message)
        return response(false, message)
    end

    return result
end
