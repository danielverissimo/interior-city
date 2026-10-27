-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ENTRA AI BB: https://discord.gg/DQswMRDMVV  Toca do Mago FiveM
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vSERVER = Tunnel.getInterface(GetCurrentResourceName())

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BOOLEANS / VARIABLES
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local fov_min = 5.0
local fov_max = 70.0
local binoculos = false
local camera = false
local fov = (fov_max+fov_min)*0.5
local activenui = false

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CALLBACKS / COMMANDS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterCommand('anim', function(_, args, rawCommand) 
    if not activenui then
        SendNUIMessage({
            showNUI = true,
            table = cfg.animacoes
        })
        SetNuiFocus(true,true)      
        activenui = true
    end
end)

RegisterNUICallback("close", function(data, callback)
    SetNuiFocus(false,false)        
    activenui = false
end)

RegisterNUICallback("confirm", function(data, callback)
	local ped = PlayerPedId()
    nome = data

    SetNuiFocus(false,false)            
    activenui = false

	if GetEntityHealth(ped) > 100 then
		vRP.DeletarObjeto()
		for _,emote in pairs(cfg.animacoes) do
			if not IsPedInAnyVehicle(ped) and not emote.carros then
				if nome == emote.nome then
					if emote.extra then emote.extra() end
					if emote.pos1 then
						vRP.CarregarObjeto("","",emote.prop,emote.flag,emote.hand,emote.pos1,emote.pos2,emote.pos3,emote.pos4,emote.pos5,emote.pos6)
					elseif emote.prop then
						vRP.CarregarObjeto(emote.dict,emote.anim,emote.prop,emote.flag,emote.hand)
					elseif emote.dict then
						vRP._playAnim(emote.andar,{{emote.dict,emote.anim}},emote.loop)
					else
						vRP._playAnim(false,{task=emote.anim},false)
					end
				end
			else
				if IsPedInAnyVehicle(ped) and emote.carros then
					local vehicle = GetVehiclePedIsIn(ped,false)
					if nome == emote.nome then
						if (GetPedInVehicleSeat(vehicle,-1) == ped or GetPedInVehicleSeat(vehicle,1) == ped) and emote.nome == "sexo4" then
							vRP._playAnim(emote.andar,{{emote.dict,emote.anim}},emote.loop)
						elseif (GetPedInVehicleSeat(vehicle,0) == ped or GetPedInVehicleSeat(vehicle,2) == ped) and (emote.nome == "sexo5" or emote.nome == "sexo6") then
							vRP._playAnim(emote.andar,{{emote.dict,emote.anim}},emote.loop)
						end
					end
				end
			end
		end
	end
end)

RegisterNetEvent('m_anim:emotes')
AddEventHandler('m_anim:emotes',function(nome)
	local ped = PlayerPedId()
	if GetEntityHealth(ped) > 100 then
		vRP.DeletarObjeto()
		for _,emote in pairs(cfg.animacoes) do
			if not IsPedInAnyVehicle(ped) and not emote.carros then
				if nome == emote.nome then
					if emote.extra then emote.extra() end
					if emote.pos1 then
						vRP.CarregarObjeto("","",emote.prop,emote.flag,emote.hand,emote.pos1,emote.pos2,emote.pos3,emote.pos4,emote.pos5,emote.pos6)
					elseif emote.prop then
						vRP.CarregarObjeto(emote.dict,emote.anim,emote.prop,emote.flag,emote.hand)
					elseif emote.dict then
						vRP._playAnim(emote.andar,{{emote.dict,emote.anim}},emote.loop)
					else
						vRP._playAnim(false,{task=emote.anim},false)
					end
				end
			else
				if IsPedInAnyVehicle(ped) and emote.carros then
					local vehicle = GetVehiclePedIsIn(ped,false)
					if nome == emote.nome then
						if (GetPedInVehicleSeat(vehicle,-1) == ped or GetPedInVehicleSeat(vehicle,1) == ped) and emote.nome == "sexo4" then
							vRP._playAnim(emote.andar,{{emote.dict,emote.anim}},emote.loop)
						elseif (GetPedInVehicleSeat(vehicle,0) == ped or GetPedInVehicleSeat(vehicle,2) == ped) and (emote.nome == "sexo5" or emote.nome == "sexo6") then
							vRP._playAnim(emote.andar,{{emote.dict,emote.anim}},emote.loop)
						end
					end
				end
			end
		end
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- BINOCULOS E CAMERA / THREADS 
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        local idle = 1000
        if binoculos then
            idle = 1
            local scaleform = RequestScaleformMovie("BINOCULARS")
            while not HasScaleformMovieLoaded(scaleform) do
                Citizen.Wait(10)
            end
 
            local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA",true)
            AttachCamToEntity(cam,PlayerPedId(),0.0,0.0,1.0,true)
            SetCamRot(cam,0.0,0.0,GetEntityHeading(PlayerPedId()))
            SetCamFov(cam,fov)
            RenderScriptCams(true,false,0,1,0)
 
            while binoculos and true do
                idle = 1
                BlockWeaponWheelThisFrame()
                local zoomvalue = (1.0/(fov_max-fov_min))*(fov-fov_min)
                CheckInputRotation(cam,zoomvalue)
                HandleZoom(cam)
                DrawScaleformMovieFullscreen(scaleform,255,255,255,255)
            end
 
            fov = (fov_max+fov_min)*0.5
            RenderScriptCams(false,false,0,1,0)
            SetScaleformMovieAsNoLongerNeeded(scaleform)
            DestroyCam(cam,false)
            SetNightvision(false)
            SetSeethrough(false)
        end
        if IsControlJustPressed(0,38) then
            if IsEntityPlayingAnim(PlayerPedId(),"missfinale_c2mcs_1","fin_c2_mcs_1_camman",3) then
                camera = true
            end
            if camera then
                local scaleform = RequestScaleformMovie("breaking_news")
                local scaleform2 = RequestScaleformMovie("security_camera")
                while not HasScaleformMovieLoaded(scaleform) do
                    idle = 10
                end
                while not HasScaleformMovieLoaded(scaleform2) do
                    idle = 10
                end
 
                local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA",true)
                AttachCamToEntity(cam,PlayerPedId(),0.0,0.0,1.0,true)
                SetCamRot(cam,0.0,0.0,GetEntityHeading(PlayerPedId()))
                SetCamFov(cam,fov)
                RenderScriptCams(true,false,0,1,0)
 
                while camera and true do
                    idle = 1
                    BlockWeaponWheelThisFrame()
                    local zoomvalue = (1.0/(fov_max-fov_min))*(fov-fov_min)
                    CheckInputRotation(cam,zoomvalue)
                    HandleZoom(cam)
                    DrawScaleformMovieFullscreen(scaleform,255,255,255,255)
                    DrawScaleformMovieFullscreen(scaleform2,255,255,255,255)
                    --Breaking("DISNEYLANDIA NEWS")
                    if IsControlJustPressed(0,38) then
                        camera = false
                    end
                end
 
                fov = (fov_max+fov_min)*0.5
                RenderScriptCams(false,false,0,1,0)
                SetScaleformMovieAsNoLongerNeeded(scaleform)
                SetScaleformMovieAsNoLongerNeeded(scaleform2)
                DestroyCam(cam,false)
                SetNightvision(false)
                SetSeethrough(false)
            end
        end
        Citizen.Wait(idle)
    end
end)
 
RegisterNetEvent('binoculos')
AddEventHandler('binoculos',function()
    if IsEntityPlayingAnim(PlayerPedId(),"amb@world_human_binoculars@male@enter","enter",3) then
        binoculos = true
        camera = true
    else
        binoculos = false
        camera = false
    end
end)
 
function CheckInputRotation(cam,zoomvalue)
    local rightAxisX = GetDisabledControlNormal(0,220)
    local rightAxisY = GetDisabledControlNormal(0,221)
    local rotation = GetCamRot(cam,2)
    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        new_z = rotation.z+rightAxisX*-1.0*(8.0)*(zoomvalue+0.1)
        new_x = math.max(math.min(20.0,rotation.x+rightAxisY*-1.0*(8.0)*(zoomvalue+0.1)),-89.5)
        SetCamRot(cam,new_x,0.0,new_z,2)
    end
end
 
function HandleZoom(cam)
    if IsControlJustPressed(0,241) then
        fov = math.max(fov-10.0,fov_min)
    end
 
    if IsControlJustPressed(0,242) then
        fov = math.min(fov+10.0,fov_max)
    end
 
    local current_fov = GetCamFov(cam)
    if math.abs(fov-current_fov) < 0.1 then
        fov = current_fov
    end
    SetCamFov(cam,current_fov+(fov-current_fov)*0.05)
end
 
function Breaking(text)
    SetTextColour(255,255,255,255)
    SetTextFont(8)
    SetTextScale(1.2,1.2)
    SetTextWrap(0.0,1.0)
    SetTextCentre(false)
    SetTextDropshadow(0,0,0,0,255)
    SetTextEdge(1,0,0,0,205)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.2,0.85)
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ENTRA AI BB: https://discord.gg/DQswMRDMVV  Toca do Mago FiveM
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


