
function RegisterTunnel.closePainel(data)
    vTunnel._close()

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
	ClearPedTasks(GetPlayerPed(-1))
	vRP._DeletarObjeto()
end

RegisterNUICallback('MarkLocal', function(data, cb)
    local cds = data.cds
    local formatCds = cds:match("^(-?%d+%.?%d*),(-?%d+%.?%d*)$")
    if type(cds) == 'string' and formatCds then
        local x, y = cds:match("^(-?%d+%.?%d*),(-?%d+%.?%d*)$")
        SetNewWaypoint(x+0.0001,y+0.0001)
        cb(true)
    else
        print("Formato de cds inválido!")
        cb(false)
    end
end)

RegisterNuiCallback('GetCDS', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    cb(coords.x..','..coords.y) -- cds em strig
end)

RegisterNuiCallback('GetFarms', function(data, cb)
    cb(vTunnel.GetStorageLogs())
end) 

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TUNNELS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function RegisterTunnel.OpenPainel(data)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    ExecuteCommand("e tablet")
    -- CarregarObjeto("amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_b", "prop_cs_tablet", 49, 60309)
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENTS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('updateChatMessage', function(data)
    SendNUIMessage({ action = 'Create:Message', data = data })
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CALLBACKS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNuiCallback('GetPainelInfos', function(data, cb)
    cb(vTunnel.getFaction())
end)

RegisterNuiCallback('getLeaders', function(data, cb)
    cb(vTunnel.getLeaders())
end)

RegisterNuiCallback('NewWarn', function(data, cb)
    cb(vTunnel.addWarn(data))
end)

RegisterNUICallback('DeleteWarning', function(data, cb)
    vTunnel.deleteWarning(data.index + 1)
    cb({ ok = true })
end)

RegisterNUICallback('ConnectRadio', function(data, cb)
    local playerHealth = GetEntityHealth(PlayerPedId()) 
    if playerHealth <= 101 then return end 

    local codeOrg = data.radio
    if not codeOrg or codeOrg == 0 then
        return TriggerEvent("Notify","negado","Nenhuma frequencia configurada.",5)
    end
    TriggerEvent("Notify","sucesso","Você entrou na frequencia <b>".. codeOrg .."</b>",5)
    exports.radio:joinChannel(codeOrg)

    cb(true)
end)

RegisterNUICallback('SetCostume', function(data, cb)
    local preset = data.preset[GetEntityModel(PlayerPedId()) == `MP_M_FREEMODE_01` and 'male' or 'female']
    for command in string.gmatch(preset, "[^;]+") do
        command = string.match(command, "^%s*(.-)%s*$")
        if command and command ~= "" then
            ExecuteCommand(command)
        end
    end

    cb(true)
end)

RegisterNUICallback('SetLocation', function(_, cb)
    cb(vTunnel.setLocation())
end)

RegisterNuiCallback('GetMessages', function(data, cb) -- Requisita todas as mensagens
    cb(vTunnel.getChatMessages())
end)

RegisterNuiCallback('New:Message', function(data, cb) -- Recebe a mensagem digitada pelo usuário
    cb(vTunnel.sendMessage(data.message))
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
	vRP._DeletarObjeto()
	ClearPedTasks(GetPlayerPed(-1))

    vTunnel._close()
    cb(true)
end)

RegisterNUICallback('getRanking', function(data, cb)
    local serverResponse = vTunnel.getRanking()
    if serverResponse then 
        if not next(serverResponse) or json.encode(serverResponse) == "[]" then 
            serverResponse = {}
        end


        cb(serverResponse or {})
        return 
    end
    cb({})
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- OTHERS FUNCTIONS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local object
function CarregarAnim(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
    end
end

function CarregarObjeto(dict,anim,prop,flag,mao,altura,pos1,pos2,pos3)
    local ped = PlayerPedId()

    RequestModel(GetHashKey(prop))
    while not HasModelLoaded(GetHashKey(prop)) do
        Citizen.Wait(10)
    end

    if altura then
        local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
        object = CreateObject(GetHashKey(prop),coords.x,coords.y,coords.z,true,true,true)
        SetEntityCollision(object,false,false)

        AttachEntityToEntity(object,ped,GetPedBoneIndex(ped,mao),altura,pos1,pos2,pos3,260.0,60.0,true,true,false,true,1,true)
    else
        CarregarAnim(dict)
        TaskPlayAnim(ped,dict,anim,3.0,3.0,-1,flag,0,0,0,0)
        local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
        object = CreateObject(GetHashKey(prop),coords.x,coords.y,coords.z,true,true,true)
        SetEntityCollision(object,false,false)
        AttachEntityToEntity(object,ped,GetPedBoneIndex(ped,mao),0.0,0.0,0.0,0.0,0.0,0.0,false,false,false,false,2,true)
    end
    SetEntityAsMissionEntity(object,true,true)
end