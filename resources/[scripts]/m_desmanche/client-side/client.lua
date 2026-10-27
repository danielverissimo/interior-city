local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")

sun = {}
Tunnel.bindInterface(GetCurrentResourceName(), sun)
vSERVER = Tunnel.getInterface(GetCurrentResourceName())

---------------------------------------------------------------------
-- VAR
---------------------------------------------------------------------

local type_desmanche = 'none'

local desmanche = nil

local blips = {}
local desmanchando = false
local etapa = 0 
local PosVeh = {}
local PecasRemovidas = {}
local TipoVeh = ''
local qtdPecasRemovidas = 0
local PecasVeh = 0

-- O painel pode excluir/renomear o local enquanto o client está em execução.
local function validConfig(config)
    if type(config) ~= 'table' then return false end
    for _,field in ipairs({'inicio','local_veiculo','local_ferramentas','local_finalizar'}) do
        local point = config[field]
        if type(point) ~= 'table' then return false end
        for axis=1,(field == 'local_ferramentas' and 4 or 3) do
            if type(point[axis]) ~= 'number' then return false end
        end
    end
    return true
end

local function currentConfig()
    local config = cfg and cfg.table and cfg.table[type_desmanche]
    if type_desmanche ~= 'none' and validConfig(config) then return config end
    if desmanchando then
        if veh and DoesEntityExist(veh) then
            FreezeEntityPosition(veh, false)
            SetVehicleDoorsLocked(veh, 1)
        end
        FreezeEntityPosition(PlayerPedId(), false)
        ClearPedTasks(PlayerPedId())
        TriggerEvent('Notify', 'aviso', 'Este desmanche foi removido ou teve sua configuração alterada. Inicie novamente.')
    end
    type_desmanche = 'none'
    desmanche = nil
    desmanchando = false
    etapa = 0
    PosVeh = {}
    PecasRemovidas = {}
    TipoVeh = ''
    qtdPecasRemovidas = 0
    PecasVeh = 0
    return nil
end

---------------------------------------------------------------------
-- MAIN THREAD / INICIO
---------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        currentConfig()
        for k,v in pairs((cfg and cfg.table) or {}) do
            if k ~= 'none' and validConfig(v) then
                local ped = PlayerPedId()

                local coords = GetEntityCoords(ped)

                local distance = #(vector3(coords[1],coords[2],coords[3]) - vector3(v.inicio[1], v.inicio[2], v.inicio[3]))

                if not desmanchando then

                    if distance <= 5.0 then
                        idle = 1
                        type_desmanche = k
                        DrawMarker(21, v.inicio[1], v.inicio[2], v.inicio[3]-0.5, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)
                        if distance < 3.0 then
                            idle = 1
                            text3D(v.inicio[1], v.inicio[2], v.inicio[3]+0.1, '~y~[E] ~w~PARA COMEÇAR O DESMANCHE')
                            if IsControlJustPressed(0,38) then

                                if vSERVER.CheckPerm(v.permissao) then
                                   
                                    veh = CheckVeiculo(v.local_veiculo[1], v.local_veiculo[2], v.local_veiculo[3])
                                    
                                    if veh then 
                                      
                                        local VehPermitido, ClasseVeh = CheckClasse(veh)

                                        placa = GetVehicleNumberPlateText(veh):gsub(" ", "")
                                        vehmodel = vSERVER.getVehicleModel(GetEntityModel(veh))
                                        modeloCarro = vSERVER.getVehicleName(vehmodel)
                                        precoveiculo = vSERVER.getVehiclePrice(vehmodel)
                                        typevehicle = vSERVER.getVehicleType(vehmodel)

                                        if checkservice() then
                                            
                                                
                                                    if placa ~= vSERVER.checkdono() then
                                                        
                                                            if vSERVER.chkdm() then
                                                                    
                                                                    for x,d in pairs(v.itens_necessarios) do
                                                                            
                                                                        if vSERVER.CheckItem(v.precisa_de_item,d.item,d.qtd) then
                                                                                    
                                                                                if ClasseVeh == 8 then
                                                                                    TipoVeh = 'moto'
                                                                                else
                                                                                    TipoVeh = 'carro'
                                                                                end

                                                                                TriggerEvent('Notify', 'sucesso','Veículo identificado: <br>Veículo: <b>' .. modeloCarro .. ' (' .. vehmodel.. ')</b><br>Placa: <b>'..placa..'</b><br><br>Continue. Pegue as ferramentas para desmanchar o veículo.')
                                                                                
                                                                                etapa = 1

                                                                                desmanchando = true

                                                                                desmanche = type_desmanche

                                                                                FreezeEntityPosition(veh, true)
                                                                                SetVehicleDoorsLocked(veh, 4)
                                                
                                                                        end
                                                                    end

                                                            else
                                                                TriggerEvent('Notify', 'negado', 'Desmanche sendo utilizado no momento!.')
                                                            end
                                                
                                                    else
                                                        TriggerEvent('Notify', 'negado', 'Você não pode desmanchar o próprio veículo!.')
                                                    end

                                        end
                                    else 
                                        TriggerEvent('Notify', 'negado', 'Não há nenhum veiculo no local de desmanche.')
                                    end
                                else 
                                    TriggerEvent('Notify', 'negado', 'Voce nao deveria estar aqui.')
                                end


                            end
                        end
                    end
                end    
            end
        end
        Citizen.Wait(idle)
    end
end)

---------------------------------------------------------------------
-- THREAD / ETAPA 1
---------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do

        local idle = 1000

        local ped = PlayerPedId()

        local coords = GetEntityCoords(ped)

        local config = currentConfig()

        if etapa == 1 and config then
            local point = config.local_ferramentas
            local distance = #(vector3(coords[1],coords[2],coords[3]) - vector3(point[1],point[2],point[3]))

            if distance <= 10.0 then
                idle = 1

                DrawMarker(21, config.local_ferramentas[1], config.local_ferramentas[2], config.local_ferramentas[3]-0.5, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)
                        
                if distance <= 5.0 then
                    idle = 1
                    text3D(config.local_ferramentas[1], config.local_ferramentas[2], config.local_ferramentas[3]-0.5, '~y~[E] ~w~PARA REUNIR AS ~y~FERRAMENTAS')

                            if distance <= 1.5 and IsControlJustPressed(0,38) then

                                if TipoVeh == 'carro' then
                                    PosVeh['Porta_Direita'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"handle_dside_f"))
                                    PosVeh['Porta_Esquerda'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"handle_pside_f"))
                                    PosVeh['Roda_EsquerdaFrente'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_lf"))
                                    PosVeh['Roda_DireitaFrente'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_rf"))
                                    PosVeh['Roda_EsquerdaTras'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_lr"))
                                    PosVeh['Roda_DireitaTras'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_rr"))
                                    -- PosVeh['Capo'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"bumper_f"))
                                    PecasVeh = 6
                                else
                                    PosVeh['Roda_Frente'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_lf"))
                                    PosVeh['Roda_Tras'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_lr"))
                                    PosVeh['Banco'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"chassis_dummy"))
                                    PecasVeh = 3
                                end
                                FreezeEntityPosition(ped, true)
                                SetEntityHeading(ped, config.local_ferramentas[4])
                                vRP.playAnim(false, {{"amb@medic@standing@kneel@idle_a", "idle_a"}}, true)
                                TriggerEvent('progress', 2, 'REUNINDO FERRAMENTAS')

                                Wait(2000)  

                                if currentConfig() and desmanchando then
                                    etapa = 2
                                    TriggerEvent('Notify', 'sucesso','Você pegou todas as ferramentas, vá e desmanche o veículo.')
                                end
                                FreezeEntityPosition(ped, false)
                                ClearPedTasks(ped)

                            end

                end

            end

        end

        Citizen.Wait(idle)
    end
end)

---------------------------------------------------------------------
-- THREAD / ETAPA 2
---------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do

        local idle = 1000

        local ped = PlayerPedId()

        local coords = GetEntityCoords(ped)

        local config = currentConfig()

        if etapa == 2 and config then
            local heading = GetEntityHeading(veh)

            if qtdPecasRemovidas == PecasVeh then
                etapa = 3
                TriggerEvent('Notify', 'sucesso','Vá até a bancada para finalizar.')
            end

            for k , v in pairs(PosVeh) do
                local x,y,z = table.unpack(v)
                if not PecasRemovidas[k] then
                    local distance = #(vector3(coords[1],coords[2],coords[3]) - vector3(x,y,z))
                    if distance <= 15 then
                        idle = 1
                        DrawMarker(20, x, y, z+1, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)
                        if distance <= 5.0 then
                            idle = 1
                            text3D(x, y, z+0.5, '~y~[E] ~w~PARA DESMANCHAR')
                            if distance <= 2.0 and IsControlJustPressed(0, 38) then
                                if k == 'Capo' or k == 'pMalas' then
                                    vRP.playAnim(false, {{"mini@repair" , "fixing_a_player"}}, true)
                                elseif k == 'Porta_Direita' or k == 'Porta_Esquerda' or k == 'Banco' then
                                    vRP._playAnim(false,{task='WORLD_HUMAN_WELDING'},true)
                                else
                                    vRP.playAnim(false, {{"amb@medic@standing@tendtodead@idle_a" , "idle_a"}}, true)
                                end
                                Wait(5000)
                                ClearPedTasks(ped)
                                PecasRemovidas[k] = true
                                qtdPecasRemovidas = qtdPecasRemovidas + 1
                                if TipoVeh == 'carro' then
                                    if k == 'Roda_EsquerdaFrente' then
                                        SetVehicleTyreBurst(veh, 0, true, 1000)
                                    elseif k == 'Roda_DireitaFrente' then
                                        SetVehicleTyreBurst(veh, 1, true, 1000)
                                    elseif k == 'Roda_EsquerdaTras' then
                                        SetVehicleTyreBurst(veh, 4, true, 1000)
                                    elseif k == 'Roda_DireitaTras' then
                                        SetVehicleTyreBurst(veh, 5, true, 1000)
                                    elseif k == 'Porta_Direita' then
                                        SetVehicleDoorBroken(veh, 0, true)
                                    elseif k == 'Porta_Esquerda' then
                                        SetVehicleDoorBroken(veh, 1, true)
                                    elseif k == 'Capo' then
                                        SetVehicleDoorBroken(veh, 4, true)
                                    end
                                else
                                    if k == 'Roda_Frente' then
                                        SetVehicleTyreBurst(veh, 0, true, 1000)
                                    elseif k == 'Roda_Tras' then
                                        SetVehicleTyreBurst(veh, 4, true, 1000)
                                    end
                                end
                            end
                        end
                    end
                end
            end

        end

        Citizen.Wait(idle)
    end
end)

---------------------------------------------------------------------
-- THREAD / ETAPA 3 / FINAL
---------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do

        local idle = 1000

        local ped = PlayerPedId()

        local coords = GetEntityCoords(ped)

        local config = currentConfig()

        if etapa == 3 and config then
            local point = config.local_finalizar
            local distance = #(vector3(coords[1],coords[2],coords[3]) - vector3(point[1],point[2],point[3]))

            if distance <= 10.0 then
                idle = 1
                DrawMarker(21, config.local_finalizar[1], config.local_finalizar[2], config.local_finalizar[3]-0.5, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)
                
                if distance <= 2.0 then
                    idle = 1

                    text3D(config.local_finalizar[1], config.local_finalizar[2], config.local_finalizar[3]-0.5, '~y~[E] ~w~PARA FINALIZAR O ~y~DESMANCHE')
                    
                    if IsControlJustPressed(0,38) then
                        ClearPedTasks(ped)

                    if (typevehicle == "vip" or typevehicle == "exclusive") then
                        porcentagem = cfg.porcentagem_veiculovip
                    else
                        porcentagem = cfg.porcentagem_veiculocomum
                    end

                        pagamento = (precoveiculo * porcentagem)

                        tipo = type_desmanche
                        if vSERVER.GerarPagamento(placa, vehmodel, modeloCarro, pagamento,tipo) then
                        DeleteEntity(veh)
                        desmanchando = false
                        etapa = 0 
                        PosVeh = {}
                        PecasRemovidas = {}
                        TipoVeh = ''
                        qtdPecasRemovidas = 0
                        PecasVeh = 0
                        end
                    end

                end
            end

        end

        Citizen.Wait(idle)
    end
end)


---------------------------------------------------------------------
-- FUNCTIONS
---------------------------------------------------------------------

function CheckClasse(veh)
    local classe = GetVehicleClass(veh)
    if classe ~= 0 and classe ~= 1 and classe ~= 2 and classe ~= 3 and classe ~= 4 and classe ~= 5 and classe ~= 6 and classe ~= 7 and classe ~= 8 and classe ~= 9 and classe ~= 11 and classe ~= 12 then
        return false, 0
    else
        return true, classe
    end
end

function checkservice()
    if cfg.desmanchar_veiculo_trabalho then
        return true
    else
        if typevehicle ~= 'work' and typevehicle ~= 'service' then
            return true
        else
            TriggerEvent('Notify', 'negado', 'Veiculos de serviço não podem ser desmanchados!.')
        end
    end
end

function CheckVeiculo(x,y,z)
    local check = GetClosestVehicle(x,y,z,5.001,0,71)
    if DoesEntityExist(check) then
        return check
    end
    return false
end

function sun.checkdesmancheut()

    if desmanchando then
        return false
    else
        return true
    end

end

function sun.getVehicleInfo(vehicle)
    return nationcfg.getVehicleInfo(vehicle)
end


function text3D(x,y,z,text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)

	SetTextFont(4)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,150)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text))/370
	DrawRect(_x,_y+0.0125,0.01+factor,0.03,0,0,0,80)
end

function drawTxt(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

