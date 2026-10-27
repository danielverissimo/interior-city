-- print('[DEBUG]: Client Entregador Init Sucess')

-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local check_em_servico = false -- Booleana para saber se player está em serviõ.
local object = nil -- Variavel para guardar objeto que player pegou (encomenda).
local pegou_pacote = false -- Para saber se player pegou encomenda. Quando pega vira true, quando entrega retorna para false.
local trava = false -- Variável auxiliar para PARAR loop while (caso o user aperte F7(para cancelar a rota), ou entregue a comida).
local encomenda_guardada = false -- Para saber se a encomenda está guardada ou não na moto do ifood.
local nome_moto_ifood = 'cg160' -- Nome de spawn da moto do ifood usada. ( aviso !!!! ). Se você trocar o modelo de sua moto de ifood e não alterar nesta variável, não estará mais habilitado a
-- ... pegar ou guardar encomendas no caixote do ifood.
local moto = nil
local indexAntigo = 0

local escondeu = false

-----------------------------------------------------------------------------------------------------------------------------------------
-- GERANDO LOCAIS PARA PEGAR/ENTREGAR O PACOTE
-----------------------------------------------------------------------------------------------------------------------------------------

-- COORDENADAS/LOCAL DE AQUISIÇÃO DA ENCOMENDA --
local pegarlocal = {
	------ cfg.list["Motorista"]["inicio"][1],cfg.list["Motorista"]["inicio"][2],cfg.list["Motorista"]["inicio"][3]
	[1] = {x=-1816.49, y=-1193.59, z=14.31},

}

-- COORDENADAS/LOCAIS DE ENTREGA --
-- Se alterar A QUANTIDADE de locais na lista, altere o valor de r_max abaixo também --
local r_max = 11 -- QUANTIDADE DE LOCAIS LISTADOS ABAIXO
local entregalocal = {
	[1] = {x=-521.92,y=-11.35,z=44.38},
	[2] = {x=-242.13,y=279.0,z=92.04}, 
	[3] = {x=494.31,y=-1541.85,z=29.29}, 
	[4] = {x=-785.83,y=-1044.96,z=12.98}, 
	[5] = {x=-636.83,y=105.64,z=57.03}, 
	[6] = {x=132.19,y=-1461.88,z=29.36}, 
	[7] = {x=416.39,y=-1107.41,z=30.06},
	[8] = {x=117.77,y=-1305.62,z=29.23},
	[9] = {x=243.06,y=-44.73,z=69.9},
	[10] = {x=-430.37,y=260.64,z=83.01},
	[11] = {x=1209.41,y=-470.87,z=66.21} -- Dentro (barbearia)     
}

-- ENCOMENDAS/OBJETOS A SEREM PEGOS (ALEATÓRIO DENTRE OS LISTADOS ABAIXO) --
-- Se alterar A QUANTIDADE de objetos na lista, altere o número máximo da variável abaixo também -- [ aviso !!! ]
obj_rand_max = 3
local objNomes = {
	"prop_paper_bag_01",
	"prop_food_cb_bag_01",
	"prop_food_bs_bag_01",
}

-----------------------------------------------------------------------------------------------------------------------------------------
-- INICIANDO TRABALHO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('vrp_ifood:permissao')
AddEventHandler('vrp_ifood:permissao',function()
	if not check_em_servico then
		TriggerEvent("Notify","aviso","Voce iniciou seu <b>trabalho</b>. Entregue a encomenda no local marcado!")
		check_em_servico = true
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- NÃO APARECER ENCOMENDA QUANDO ENTRA EM VEÍCULO
-----------------------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()

	while true do
		local idle = 1000
		local ped = PlayerPedId()
    	local x,y,z = table.unpack(GetEntityCoords(ped))

		if (IsPedInAnyVehicle(ped, false)) and (not escondeu) and (check_em_servico) and (pegou_pacote) and (object) and (not encomenda_guardada) then
			idle = 1
			DeleteObject(object)
			ClearPedTasks(ped)
			escondeu = true

			TriggerEvent("Notify","aviso","A encomenda foi guardada.")

			Citizen.Wait(1000)

		elseif (not IsPedInAnyVehicle(ped, false)) and (escondeu) and (not encomenda_guardada) then
			idle = 1
			-- CRIAR OBJETO NOVAMENTE --
			local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
			object = CreateObject(GetHashKey(objNomes[indexAntigo]),coords.x,coords.y,coords.z,true,true,true)
			SetEntityCollision(object,true,true)
			AttachEntityToEntity(object,ped,GetPedBoneIndex(ped,28422),0.25,0.0,0.06,65.0,-130.0,-65.0,true,true,false,true,0,true)
			SetEntityAsMissionEntity(object,true,true)

			escondeu = false

			TriggerEvent("Notify","aviso","Você pegou a encomenda.")

			Citizen.Wait(1000)

		end



		Citizen.Wait(idle)

	end

end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- GUARDAR NA MOTO
-----------------------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()

	while true do
		local idle = 1000
		local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped))

		moto = GetClosestVehicle(x,y,z, 100.0, GetHashKey(nome_moto_ifood), 70);

		local trunkpos = GetWorldPositionOfEntityBone(moto, GetEntityBoneIndexByName(moto, "exhaust"))
		local playerpos = GetEntityCoords(GetPlayerPed(-1), 1)
		local distanceToTrunk = GetDistanceBetweenCoords(trunkpos, playerpos, 1)

		--print(moto)

		if (check_em_servico) and (pegou_pacote) and (not encomenda_guardada) and (not escondeu) then
			idle = 1
        	if (distanceToTrunk <= 1) and (DoesEntityExist(moto)) and (IsEntityAVehicle(moto)) then
				idle = 1
				SetTextFont(0)
				SetTextProportional(1)
				SetTextScale(0.0, 0.5)
				SetTextColour(128, 128, 128, 255)
				SetTextDropshadow(0, 0, 0, 0, 255)
				SetTextEdge(0, 0, 0, 1, 255)
				SetTextDropShadow()
				SetTextOutline()
				SetTextEntry("STRING")
				AddTextComponentString("~w~APERTE ~r~E ~w~PARA GUARDAR A ENCOMENDA")
				DrawText(0.35, 0.83)

				if IsControlJustPressed(0,38) then


					-- ANIMAÇÃO --
					RequestAnimDict('mp_common')
										
					while not HasAnimDictLoaded('mp_common') do
					Citizen.Wait(1)
					end

					TaskPlayAnim(ped, "mp_common", "givetake1_a",2.0, -2.0, -1, 50, 0, false, false, false )

					Citizen.Wait(idle)


					encomenda_guardada = true -- Setar encomenda como guardada
					DeleteObject(object) -- Tirar objeto da mão do player
					ClearPedTasks(ped)

					TriggerEvent("Notify","aviso","Você guardou a encomenda.")

					Citizen.Wait(idle)

				end

			end

		end



		if (distanceToTrunk <= 1) and (DoesEntityExist(moto)) and (IsEntityAVehicle(moto)) and (encomenda_guardada) and (not escondeu) then
			idle = 1
			SetTextFont(0)
			SetTextProportional(1)
			SetTextScale(0.0, 0.5)
			SetTextColour(128, 128, 128, 255)
			SetTextDropshadow(0, 0, 0, 0, 255)
			SetTextEdge(0, 0, 0, 1, 255)
			SetTextDropShadow()
			SetTextOutline()
			SetTextEntry("STRING")
			AddTextComponentString("~w~APERTE ~g~E ~w~PARA PEGAR A ENCOMENDA")
			DrawText(0.35, 0.83)

			if IsControlJustPressed(0,38) and vSERVER.checkEmp('Entregador') then


				-- ANIMAÇÃO --
				RequestAnimDict('mp_common')
										
				while not HasAnimDictLoaded('mp_common') do
				Citizen.Wait(1)
				end

				TaskPlayAnim(ped, "mp_common", "givetake1_a",2.0, -2.0, -1, 50, 0, false, false, false )

				Citizen.Wait(idle)

				ClearPedTasks(ped)


				-- CRIAR OBJETO NOVAMENTE --
				local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
				object = CreateObject(GetHashKey(objNomes[indexAntigo]),coords.x,coords.y,coords.z,true,true,true)
				SetEntityCollision(object,true,true)
				vRP.playSound("Object_Collect_Player", "GTAO_FM_Events_Soundset") -- Som, pegando objeto
				AttachEntityToEntity(object,ped,GetPedBoneIndex(ped,28422),0.25,0.0,0.06,65.0,-130.0,-65.0,true,true,false,true,0,true)
				SetEntityAsMissionEntity(object,true,true)

				encomenda_guardada = false

				TriggerEvent("Notify","aviso","Você pegou a encomenda.")

			end

		end

		Citizen.Wait(idle)
	end

end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- GERANDO ENTREGA
-----------------------------------------------------------------------------------------------------------------------------------------
-- COORDENADA PEGAR COMIDA: -63.84,-791.54,44.23

Citizen.CreateThread(function()

	CriandoBlipIF()

	destinoantigo = destino
	destino = math.random(7,r_max) -- RANDOM DE LOCAIS DE DESTINO //// GERA LOCAL DE ENTREGA ALEATÓRIO (entre 1 e 7 poque existem 7 coordenadas possíveis na linha 29 do código)

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped))
        if Vdist(x,y,z,cfg.list["Entregador"]["inicio"][1],cfg.list["Entregador"]["inicio"][2],cfg.list["Entregador"]["inicio"][3]) <= 10  then
        	sleep = 1
             DrawMarker(27,cfg.list["Entregador"]["inicio"][1],cfg.list["Entregador"]["inicio"][2],cfg.list["Entregador"]["inicio"][3] - 0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
			if  Vdist(x,y,z,cfg.list["Entregador"]["inicio"][1],cfg.list["Entregador"]["inicio"][2],cfg.list["Entregador"]["inicio"][3]) <= 5 and not  check_em_servico then
				DrawText3D(cfg.list["Entregador"]["inicio"][1],cfg.list["Entregador"]["inicio"][2],cfg.list["Entregador"]["inicio"][3], "Bem-Vindo a Central de Entrega\n")
			end

            if Vdist(x,y,z,cfg.list["Entregador"]["inicio"][1],cfg.list["Entregador"]["inicio"][2],cfg.list["Entregador"]["inicio"][3]) <= 1.0 then
				sleep = 1
              if IsControlJustPressed(0,38) and vSERVER.checkEmp('Entregador') and not iniciandoServico and not pegou_pacote then
    
    iniciandoServico = true -- TRAVA IMEDIATA (anti spam)
    trava = true -- bloqueia outras ações

    if DoesBlipExist(blip) then
        RemoveBlip(blip) -- REMOVE O BLIP NA HORA
    end

    destinoantigo = destino
    destino = math.random(7,r_max)

    while destinoantigo == destino do
        destino = math.random(7,r_max)
        Citizen.Wait(1)
    end

    local indexObj = math.random(1,obj_rand_max)
    indexAntigo = indexObj

    RequestModel(GetHashKey(objNomes[indexObj]))
    while not HasModelLoaded(GetHashKey(objNomes[indexObj])) do
        Citizen.Wait(10)
    end

    local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
    object = CreateObject(GetHashKey(objNomes[indexObj]),coords.x,coords.y,coords.z,true,true,true)

    SetEntityCollision(object,true,true)
    vRP.playSound("Object_Collect_Player", "GTAO_FM_Events_Soundset")

    AttachEntityToEntity(object,ped,GetPedBoneIndex(ped,28422),0.25,0.0,0.06,65.0,-130.0,-65.0,true,true,false,true,0,true)
    SetEntityAsMissionEntity(object,true,true)

    pegou_pacote = true

    -- Libera depois de um pequeno delay (evita spam extremo)
    SetTimeout(1000,function()
        iniciandoServico = false
        trava = false
    end)

    CriandoBlipIFEntrega(entregalocal,destino)
end
            end
        end
        --end	
        
       Citizen.Wait(sleep)

	   --------------------------- POR AQUI: ENTREGA NO PONTO MARCADO -----------------
	   if pegou_pacote then -- APARECE SE (E SOMENTE SE) PLAYER TIVER PEGADO A ENCOMENDA

			while true and not trava do
				local sleep = 1000

				local pagamento = math.random(500,1000)
				local ped = PlayerPedId()
				local x,y,z = table.unpack(GetEntityCoords(ped))

				if Vdist(x,y,z,entregalocal[destino].x,entregalocal[destino].y,entregalocal[destino].z) <= 50 then
					sleep = 1
					DrawMarker(27,entregalocal[destino].x,entregalocal[destino].y,entregalocal[destino].z-0.9,0,0,0,0.0,0,0,1.5,1.5,1.2,255,0,0,70,0,1,0,1) -- Desenha a marker no chão de ENTREGAR COMIDA
					DrawMarker(3,entregalocal[destino].x,entregalocal[destino].y,entregalocal[destino].z-0.1,0,0,0,0.0,0,0,1.0,1.0,1.3,255,0,0,70,1,1,0,0) -- Desenha a flutuante de ENTREGAR COMIDA
					if Vdist(x,y,z,entregalocal[destino].x,entregalocal[destino].y,entregalocal[destino].z) <= 3 then
						if IsControlJustPressed(0,38) and not IsPedInAnyVehicle(ped) and not encomenda_guardada then
							-- FINALIZA A ENTREGA AQUI --
							ClearPedTasksImmediately(ped)
							-- TriggerServerEvent("vrp_ifood:receber",pagamento) -- Chamar o server-side(server.lua na pasta) para entregar o dinheiro
							vRP.playSound("PEYOTE_COMPLETED","HUD_AWARDS") -- Som ao ganhar dinheiro
							-- TriggerEvent("Notify","sucesso","<b>Comida</b> entregue, voce ganhou <b>$"..pagamento.."</b>!") -- Mensagem de entrega
							TriggerServerEvent('m_empregos:upgrade_level')
							TriggerServerEvent('m_empregos:payment')
							DeleteObject(object) --DELETAR OBJETO DA MAO
							pegou_pacote = false
							check_em_servico = false
							trava = true
							object = nil
							RemoveBlip(blip)
							break
						end
					end
				end	
				Citizen.Wait(sleep)
			end
		end

    end
end)


-----------------------------------------------------------------------------------------------------------------------------------------
-- CANCELANDO ENTREGA
-----------------------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	while true do
		local idle = 1000
		if check_em_servico then
			idle = 1
            drawTxtIF("~y~PRESSIONE ~r~F7 ~w~SE DESEJA CANCELAR A ENTREGA ",4,0.270,0.905,0.45,255,255,255,200)
			if IsControlJustPressed(0,168) then
				check_em_servico = false
				pegou_pacote = false
				trava = true
				TriggerEvent('cancelando',false)
				RemoveBlip(blip)
				vRP.playSound("Oneshot_Final","MP_MISSION_COUNTDOWN_SOUNDSET") -- SOM de cancelamento pelo F7
				TriggerEvent("Notify","aviso","Voce pressionou <b>F7</b>. A rota foi CANCELADA.") -- Mensagem de cancelamento da entrega
				DeleteObject(object) --DELETAR OBJETO DA MAO
			end
		end
		Citizen.Wait(idle)
	end
end)



-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNÇÕES
-----------------------------------------------------------------------------------------------------------------------------------------
function CriandoBlipIFEntrega(entregalocal,destino)
	blip = AddBlipForCoord(entregalocal[destino].x,entregalocal[destino].y,entregalocal[destino].z)
	SetBlipSprite(blip,501) -- O icone que aparece no mapa no destino da entrega
	SetBlipColour(blip,5) -- Escolhendo a cor do icone: cor 5 (cores disponiveis em: https://docs.fivem.net/docs/game-references/blips/ no final da pagina.) 
	SetBlipScale(blip,0.7) -- Set do TAMANHO do blip que aparece no mapa
	SetBlipAsShortRange(blip,false)
	SetBlipRoute(blip,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Entrega de Comida")
	EndTextCommandSetBlipName(blip)
end

function CriandoBlipIF()
	blip = AddBlipForCoord(cfg.list["Entregador"]["inicio"][1],cfg.list["Entregador"]["inicio"][2],cfg.list["Entregador"]["inicio"][3])
	SetBlipSprite(blip,494) -- O icone que aparece no mapa
	SetBlipColour(blip,1) -- Escolhendo a cor do icone: cor 75 (cores disponiveis em: https://docs.fivem.net/docs/game-references/blips/ no final da pagina.) 
	SetBlipScale(blip,0.6) -- Set do TAMANHO do blip que aparece no mapa
	SetBlipAsShortRange(blip,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Central | Entregador")
	EndTextCommandSetBlipName(blip)
end

-- PARA DESENHAR O TEXTO 3D
function DrawText3DIF(x,y,z, text, scl, font) 
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local px,py,pz=table.unpack(GetGameplayCamCoords())
	local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)

	local scale = (1/dist)*scl
	local fov = (1/GetGameplayCamFov())*100
	local scale = scale*fov
	if onScreen then
		SetTextScale(0.0*scale, 1.1*scale)
        SetTextFont(font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
	end
end

function drawTxtIF(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end