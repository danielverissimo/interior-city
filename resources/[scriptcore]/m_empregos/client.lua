local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vSERVER = Tunnel.getInterface(GetCurrentResourceName())

-- print('[DEBUG]: Client Init Sucess')

local nui = false

-----------------------------------------------------------------------------
------ MAIN THREAD NUI
-----------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(vec3(coords[1],coords[2],coords[3]) - vec3(cfg.central[1],cfg.central[2],cfg.central[3]))

        if distance <= 10.0 then
            idle = 1
            DrawMarker(27,cfg.central[1],cfg.central[2],cfg.central[3] - 0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
            if distance <= 3.0 then
                DrawText3D(cfg.central[1],cfg.central[2],cfg.central[3], "Bem-Vindo a Central de Empregos \n")
                if distance <= 5.0 and IsControlJustPressed(0, 38) and not nui then
                    
                    -- vSERVER.getInitCache()

                    if not nui then
                        
                        SetNuiFocus(true,true)
                        -- TransitionToBlurred(1000)
                        SendNUIMessage({ 
                            showCENTRAL = "central",
                            emp_infos = cfg.list,
                            emp_data = vSERVER.getInitCache(),
                            at_emprego = vSERVER.get_at_emprego()
                        })
                        nui = true
                        
                    end                  

                end
            end
        end
        
        Citizen.Wait(idle)
    end
end)

RegisterNUICallback("set_at_emprego", function(data, callback)

    at_emprego = data.at_emprego
    set_emprego = data.index
    
    if data.loc then loc = data.loc else loc = "" end

    vSERVER.set_at_emprego(at_emprego,set_emprego,loc)

end)

RegisterNUICallback("colocar_uniforme", function(data, callback)
    vSERVER.give_un(data.emprego)
end)

RegisterNUICallback("retirar_uniforme", function(data, callback)
    vSERVER.remove_un()
end)

RegisterNUICallback("pedir_demissao", function(data, callback)

    at_emprego = data.emprego

    vSERVER.demissao(at_emprego)

end)

RegisterNUICallback("close_central", function(data, callback)
    SetNuiFocus(false,false)
    TransitionFromBlurred(1000)            
    nui = false 
end)


src.setRoute = function(x,y)
    SetNewWaypoint(x,y)
end

src.getCustomization = function(source)
    return vRP.getCustomization(source)
end


RegisterCommand("emp", function(_, args, rawCommand)

    if vSERVER.get_at_emprego() == "Nenhum" then
        TriggerEvent("Notify","negado","Você não está em nenhum emprego!",10)
        return
    end

    if not nui then
        SetNuiFocus(true,true)
        -- TransitionToBlurred(1000)
        SendNUIMessage({ 
            showCENTRAL = "status",
            emp_infos = cfg.list,
            emp_data = vSERVER.getInitCache(),
            at_emprego = vSERVER.get_at_emprego()
        })
        nui = true
    end            
end)

-----------------------------------------------------------------------------
------ OTHER GERAL CLIENT FUNCTIONS
-----------------------------------------------------------------------------

function DrawText3D(x,y,z,text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	SetTextFont(4)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,100)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text)) / 400
	DrawRect(_x,_y+0.0125,0.03+factor,0.04,0,0,0,100)
end

local centralNpc=nil

local function spawnCentralNpc()
    if centralNpc and DoesEntityExist(centralNpc) then
        DeleteEntity(centralNpc)
        centralNpc=nil
    end

    local model=GetHashKey('u_m_m_jewelsec_01')
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(10)
    end

    local p=cfg.npcloc or {549.72,-180.63,54.48,92.70}
    centralNpc=CreatePed(4,model,p[1],p[2],p[3]-1,p[4] or 0.0,false,true)
    FreezeEntityPosition(centralNpc,true)
    SetEntityInvincible(centralNpc,true)
    SetBlockingOfNonTemporaryEvents(centralNpc,true)
    SetModelAsNoLongerNeeded(model)
end

Citizen.CreateThread(function()
    Citizen.Wait(700)
    spawnCentralNpc()
end)

AddEventHandler("m_empregos:clientConfigUpdated",function()
    spawnCentralNpc()
end)