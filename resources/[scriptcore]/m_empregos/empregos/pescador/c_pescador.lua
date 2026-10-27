-- print('[DEBUG]: Client Pescador Init Sucess')

-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
-- configpesca = module("emp_pescador","configpesca")
local processo = false
local inpesca = false
local segundos = 0
local vez = 1
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROCESSO
-----------------------------------------------------------------------------------------------------------------------------------------

configpesca = {}

configpesca.fishDuration = 10

configpesca.locais = {
    { 1109.33, -637.33, 56.82, 105.18 },
    { 1108.88, -635.27, 56.82, 107.12 },
    { 1108.44, -633.04, 56.82, 103.16 },
    { 1107.97, -630.56, 56.82, 108.75 }
}

configpesca.venda = { 1112.09,-645.37,56.85 }

-----------------------------------------------------------------------------
------ MAIN THREAD NUI
-----------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(vec3(coords[1],coords[2],coords[3]) - vec3(configpesca.venda[1],configpesca.venda[2],configpesca.venda[3]))

        if distance <= 10.0 and not inpesca then
            idle = 1
            DrawMarker(27,configpesca.venda[1],configpesca.venda[2],configpesca.venda[3] - 0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
            if distance <= 3.0 then
                DrawText3D(configpesca.venda[1],configpesca.venda[2],configpesca.venda[3], "PRESSIONE  ~b~E~w~  PARA ~g~VENDER~w~ SEUS ~b~PEIXES")
                
                if distance <= 1.2  and IsControlJustPressed(0, 38) and vSERVER.checkEmp('Pescador') then
                    vSERVER.sellFish()
                end

            end
        end
        
        Citizen.Wait(idle)
    end
end)


Citizen.CreateThread(function()
	while true do
		local idle = 1000
		if not processo then
			local ped = PlayerPedId()
			local x,y,z = table.unpack(GetEntityCoords(ped))
            -- if inpesca then
                for k,v in pairs(configpesca.locais) do
                    local distance = Vdist(x,y,z,v[1],v[2],v[3])
                    if distance <= 10 and not inpesca then
                        idle = 1
                        DrawMarker(27,v[1],v[2],v[3]- 0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
                        if distance <= 3.0 then
                            idle = 1
                            DrawText3D(v[1],v[2],v[3], "PRESSIONE  ~b~E~w~  PARA ~y~PESCAR ~b~( REQ.: 1x ISCA )")
                            if IsControlJustPressed(0,38) and not IsPedInAnyVehicle(ped) and vSERVER.checkEmp('Pescador') then
                                
                                    if vSERVER.checkItem() then

                                        SetEntityCoords(ped,v[1],v[2],v[3]-1)
                                        SetEntityHeading(ped,v[4])
                                        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_FISHING", 0, true)
                                        pescando()
                                        
                                    end
                                
                            end
                        end
                    end
                end
            -- end
		end
	Citizen.Wait(idle)
	end
end)

function pescando()
    if inpesca then return end

    inpesca = true
    segundos = configpesca.fishDuration
end

Citizen.CreateThread(function()
    while true do
        if inpesca then
            segundos = segundos - 1
            if segundos <= 0 then

                if vez == 2 then
                    if not vSERVER.checkItem() then
                        noIsca()
                    end
                end

                if inpesca then
                    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
                    if vSERVER.taskcheck() then                       
                        vSERVER.catchFish()
                        vez = 2
                        TriggerServerEvent('m_empregos:upgrade_level')
                        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)  
                    else                 
                        PlaySoundFrontend(-1, "CHALLENGE_UNLOCKED", "HUD_AWARDS", true)     
                        TriggerEvent("Notify","negado","Você deixou o peixe escapar! Tente novamente.", 5000)
                    end
                end

                segundos = configpesca.fishDuration
            end
        end

        Citizen.Wait(1000)
    end
end)


RegisterNetEvent('countDown')
AddEventHandler('countDown',function(segundos)
	repeat
		Citizen.Wait(1000)
		segundos = segundos - 1
		if segundos == 0 then
			TriggerEvent('cancelando',false)
			ClearPedTasks(PlayerPedId())
			vRP._DeletarObjeto()
			processo = false
		end
	until segundos == 0
end)

Citizen.CreateThread(function()
    local ped = PlayerPedId()
	while true do
      local trava = 1000
      if inpesca then
		trava = 1
        drawTxtPC("~y~Próximo peixe em: ~r~"..segundos.." ~w~ Fique atento!",4,0.251,0.865,0.45,255,255,255,200)
		drawTxtPC("~y~PRESSIONE ~r~F6 ~w~SE DESEJA FINALIZAR A PESCARIA ",4,0.270,0.905,0.45,255,255,255,200)

        if IsControlJustPressed(0,167) then

            segundos = configpesca.fishDuration
            TriggerEvent("Notify", "aviso", "Você saiu de serviço! Venda seus peixes ao lado.")
            inpesca = false
            segundos = 0
            vez = 1

            ClearPedTasksImmediately(ped)
            -- Aguarda 1 frame para o prop spawnar no chão
            Wait(0)
            -- Posição do player
            local coords = GetEntityCoords(ped)
            -- Procura a vara perto do player
            local obj = GetClosestObjectOfType(
                coords.x, coords.y, coords.z,
                2.0,
                GetHashKey("prop_fishing_rod_01"),
                false, false, false
            )
            if DoesEntityExist(obj) then
                NetworkRequestControlOfEntity(obj)
                SetEntityAsMissionEntity(obj, true, true)
                DeleteEntity(obj)
            end
            
		end

      end
	  Citizen.Wait(trava)
	end
end)

function noIsca()
    segundos = configpesca.fishDuration
    TriggerEvent("Notify", "aviso", "Suas iscas acabaram.")
    inpesca = false
    segundos = 0
    vez = 1

    local ped = PlayerPedId()

    ClearPedTasksImmediately(ped)
    -- Aguarda 1 frame para o prop spawnar no chão
    Wait(0)
    -- Posição do player
    local coords = GetEntityCoords(ped)
    -- Procura a vara perto do player
    local obj = GetClosestObjectOfType(
        coords.x, coords.y, coords.z,
        2.0,
        GetHashKey("prop_fishing_rod_01"),
        false, false, false
    )
    if DoesEntityExist(obj) then
        NetworkRequestControlOfEntity(obj)
        SetEntityAsMissionEntity(obj, true, true)
        DeleteEntity(obj)
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNÇÕES
-----------------------------------------------------------------------------------------------------------------------------------------

function drawTxtPC(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

function drawTxtPC(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end