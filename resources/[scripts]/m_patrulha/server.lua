local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vCLIENT = Tunnel.getInterface(GetCurrentResourceName())

vRP.prepare("patrulha/ensure_org_ptr",[[
  INSERT INTO m_patrulha (user_id, organization, ptr)
  VALUES (@user_id, @organization, 0)
  ON DUPLICATE KEY UPDATE organization = organization
]])

vRP.prepare("patrulha/add_ptr",[[
  UPDATE m_patrulha
  SET ptr = ptr + 1
  WHERE user_id = @user_id AND organization = @organization
]])

vRP.prepare("patrulha/add_ptr_amount",[[
  UPDATE m_patrulha
  SET ptr = ptr + @amount
  WHERE user_id = @user_id AND organization = @organization
]])


vRP.prepare("patrulha/get_ranking",[[
    SELECT user_id, ptr
    FROM m_patrulha
    WHERE organization = @organization
    ORDER BY ptr DESC
]])

-----------------------------------------------------------------------------
------ FUNCTIONS
-----------------------------------------------------------------------------

local function isVtrPermitida(vehicle)
    if not vehicle or vehicle == 0 then return false end

    local model = GetEntityModel(vehicle)
    return cfg.viaturas_permitidas[model] == true
end

src.checkPerm = function(perm)

    local source = source
    local user_id = vRP.getUserId(source)

    if vRP.hasPermission(user_id,perm) then
        return true
    else
        TriggerClientEvent('Notify',source,'negado','Você não possui permissão!')
        return false
    end

end

local function payUser(uid, amount)
    if not uid or amount <= 0 then return end

    vRP.addBankMoney(uid, amount)

    TriggerClientEvent("Notify", vRP.getUserSource(uid), "sucesso", "Você recebeu R$"..amount.." pela patrulha.",10)
end

RegisterServerEvent('m_patrulha:upgrade_rank')
AddEventHandler('m_patrulha:upgrade_rank', function(org)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end
    if not org or org == "" then return end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return end

    local veh = GetVehiclePedIsIn(ped, false)

    if not isVtrPermitida(veh) then
        TriggerClientEvent('Notify',source,'negado','Você não está em uma viatura permitida pelo Departamento!',15)
        TriggerClientEvent('Notify',source,'negado','Você não ganhou pagamento nem pontos de patrulha!',10)
        return
    end

    local function givePtr(uid, amount)
        if not uid or amount <= 0 then return end

        vRP.execute("patrulha/ensure_org_ptr", {
            user_id = uid,
            organization = org
        })

        vRP.execute("patrulha/add_ptr_amount", {
            user_id = uid,
            organization = org,
            amount = amount
        })
    end

    if not veh or veh == 0 then
        givePtr(user_id, 1)
        return
    end
    
    local PAY_DRIVER = math.random(cfg.pagamento['motorista'].min,cfg.pagamento['motorista'].max)   
    local PAY_PASS = math.random(cfg.pagamento['passageiro'].min,cfg.pagamento['passageiro'].max) 

    for _, ply in ipairs(GetPlayers()) do
        local psrc = tonumber(ply)
        if psrc then
            local pped = GetPlayerPed(psrc)
            if pped and pped ~= 0 then
                local pveh = GetVehiclePedIsIn(pped, false)
                if pveh == veh then
                    local uid = vRP.getUserId(psrc)
                   if uid then
                    local driverPed = GetPedInVehicleSeat(veh, -1)

                    if pped == driverPed then
                        payUser(uid, PAY_DRIVER)
                        givePtr(uid, 2)
                    else
                        payUser(uid, PAY_PASS)
                        givePtr(uid, 1)
                    end
                end
                end
            end
        end
    end
end)

src.checkRanking = function(org)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return {} end
    if not org or org == "" then return {} end

    local ranking = vRP.query("patrulha/get_ranking", {
        organization = org
    })

    local result = {}
    
    for _,v in pairs(ranking) do
       
        local identity = vRP.getUserIdentity(v.user_id)

        if identity then
            result[#result + 1] = {
                id = v.user_id,
                nome = identity.nome or "",
                sobrenome = identity.sobrenome or "",
                pontos = v.ptr
            }
        end
    end

    return result
end