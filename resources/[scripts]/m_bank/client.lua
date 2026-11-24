local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local cFG = module("m_bank", "config")

vRP = Proxy.getInterface("vRP")
eGServer = Tunnel.getInterface("m_bank")

eG = {}
Tunnel.bindInterface("m_bank",eG)
-----------------------------------------------------------------------------------------------------------------------------------------
--[ VARIÁVEIS ]--------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
local bancos = cFG.bancos
local atms = cFG.atms
local roubando = false
local cooldown = 0
local data = {}
local cache = false
local cachePix = false
local cacheGraph = false
local configNames = {}
local bankOpen = false
-----------------------------------------------------------------------------------------------------------------------------------------
--[ THREAD ]-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
local function toggleNuiFrame(shouldShow)
    bankOpen = shouldShow == true
    SetNuiFocus(shouldShow, shouldShow)
    SendReactMessage('setVisible', shouldShow)
end

RegisterNUICallback('hideFrame', function(_, cb)
    toggleNuiFrame(false)
    cb({})
end)
RegisterNetEvent('m_bank:closeForRobbery',function() toggleNuiFrame(false) end)

RegisterNUICallback('showFrame', function(_, cb)
    toggleNuiFrame(true)
    cb({})
end)

function SendReactMessage(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

function valueToNui()
    data[1] = cFG.nomeBanco
    data[2] = cFG.imgBanco
    if not cache then
        data[3],data[4],data[9],data[10],data[11],data[12],data[13] = eGServer.getTransacoes()
        cache = true
    end
    if not cachePix then
        data[6],data[7],data[8] = eGServer.getIdentity()
        cachePix = true
    end
    if not cacheGraph then
        local retorno = eGServer.getGraph()
        local somaGanhos = retorno[1]
        local somaPerdas = retorno[2]
        local multas = retorno[3]
        local aux = multas + somaGanhos + somaPerdas

        multas = multas/aux
        multas = multas * 100
        multas = parseInt(multas)

        somaGanhos = somaGanhos/aux
        somaGanhos = somaGanhos * 100
        somaGanhos = parseInt(somaGanhos)
        
        somaPerdas = somaPerdas/aux
        somaPerdas = somaPerdas*100
        somaPerdas = parseInt(somaPerdas)

        local array = {}
        array[1] = somaGanhos
        array[2] = somaPerdas
        array[3] = multas
        data[5] = array
        cacheGraph = true
    end
    SendReactMessage('setInformation',data)
    SendReactMessage('setDashboardInformation',data)
end

RegisterNUICallback("depositar", function(data)
    cache = false
    eGServer.depositar(data.amount)
end)
RegisterNUICallback("sacar", function(data)
    cache = false
    eGServer.sacar(data.amount)
end)
RegisterNUICallback("transferir", function(data)
    cache = false
    eGServer.transferir(data.transferTo,data.amount)
end)
RegisterNUICallback("multas", function(data)
    cache = false
    eGServer.pagarMultas(data.amount)
    toggleNuiFrame(false)
end)
RegisterNUICallback("pix", function(data)
    cache = false
    eGServer.pix(data.pixTo,data.amount)
end)
RegisterNUICallback("cadastrarPix", function(data)
    cachePix = false
    eGServer.cadastrarPix(data.value)
end)
RegisterNUICallback("editarPix", function(data)
    cachePix = false
    eGServer.editarPix(data.value)
end)


-- Detecta os objetos carregados do mapa, inclusive ATMs de interiores.
local atmModels = {}
for _,model in ipairs(cFG.atmModels or {'prop_atm_01','prop_atm_02','prop_atm_03','prop_fleeca_atm'}) do
    atmModels[#atmModels+1] = GetHashKey(model)
end
local nearbyAtm = nil
local atmDistance = tonumber(cFG.atmInteractionDistance) or 2.0
local function findNearbyAtm(position)
    local nearest, distance = nil, atmDistance
    for _,model in ipairs(atmModels) do
        local entity = GetClosestObjectOfType(position.x,position.y,position.z,atmDistance,model,false,false,false)
        if entity ~= 0 and DoesEntityExist(entity) then
            local d = #(position-GetEntityCoords(entity))
            if d <= distance then nearest, distance = entity, d end
        end
    end
    return nearest
end
Citizen.CreateThread(function()
    while true do
        nearbyAtm = findNearbyAtm(GetEntityCoords(PlayerPedId()))
        Wait(500)
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 750
        local ped = PlayerPedId()
        local position=GetEntityCoords(ped)
        local blocked=false
        if GetResourceState('m_roubos')=='started' then
            local ok,result=pcall(function() return exports.m_roubos:isAtmUnavailable(position.x,position.y,position.z) end)
            blocked=ok and result==true
        end
        if bankOpen and blocked then toggleNuiFrame(false) end
        if not blocked and not bankOpen and not roubando and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped,false)
            and GetSelectedPedWeapon(ped) == GetHashKey('WEAPON_UNARMED') then
            local position = GetEntityCoords(ped)
            local bank, bankDistance = nil, 5.0
            for _,point in pairs(bancos) do
                local distance = Vdist(position.x,position.y,position.z,point.x,point.y,point.z)
                if distance < bankDistance then bank, bankDistance = point, distance end
            end
            local atmAvailable = nearbyAtm and DoesEntityExist(nearbyAtm)
                and #(position-GetEntityCoords(nearbyAtm)) <= atmDistance
            if not atmAvailable then
                for _,point in pairs(atms) do
                    if Vdist(position.x,position.y,position.z,point.x,point.y,point.z) <= atmDistance then
                        atmAvailable = true
                        break
                    end
                end
            end
            if bank or atmAvailable then
                sleep = 0
                if bank then
                    mBMarker({bank.x,bank.y,bank.z},1.0,1.0,1.0,'cash','banco')
                end
                local ui = GetMinimapAnchor()
                drawTxt(ui.right_x+0.25,ui.bottom_y-0.100,
                    atmAvailable and 'PRESSIONE ~g~E~w~ PARA ABRIR O CAIXA ELETRONICO' or 'PRESSIONE ~g~E~w~ PARA ABRIR O BANCO')
                if IsControlJustPressed(0,38) then
                    cache, cachePix, cacheGraph = false, false, false
                    valueToNui()
                    toggleNuiFrame(true)
                end
            end
        end
        Wait(sleep)
    end
end)
function mBMarker(vector, sizex, sizey, sizez, src, id)
    if not HasStreamedTextureDictLoaded(src) then
        RequestStreamedTextureDict(src, true)
        while not HasStreamedTextureDictLoaded(src) do
            Wait(1)
        end
    else
        local x,y,z = table.unpack(vector)
        DrawMarker(9, x, y, z, 0.0, 0.0, 0.0, tonumber('90.0'), tonumber('90.0'), 0.0, sizex, sizey, sizez, 255, 255, 255, 255,false, true, 2, true, src, id, false)
    end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- [ FUNÇÕES DO SERVER ] ----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------


RegisterNetEvent('EG:blip:remover:caixaeletronico')
AddEventHandler('EG:blip:remover:caixaeletronico',function()
	if DoesBlipExist(blip) then
		RemoveBlip(blip)
		blip = nil
	end
end)


-----------------------------------------------------------------------------------------------------------------------------------------
--[ FUNÇÕES ]----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------


function drawTxt(x,y,text,r,g,b)
	SetTextFont(4)
	SetTextScale(0.48,0.48)
	SetTextColour(255,255,255,190)
	SetTextEdge(2,0,0,0,255)
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

function GetMinimapAnchor()
	local safezone = GetSafeZoneSize()
	local safezone_x = 1.0 / 20.0
	local safezone_y = 1.0 / 20.0
	local aspect_ratio = GetAspectRatio(0)
	local res_x, res_y = GetActiveScreenResolution()
	local xscale = 1.0 / res_x
	local yscale = 1.0 / res_y
	local Minimap = {}
	Minimap.width = xscale * (res_x / (4 * aspect_ratio))
	Minimap.height = yscale * (res_y / 5.674)
	Minimap.left_x = xscale * (res_x * (safezone_x * ((math.abs(safezone - 1.0)) * 10)))
	Minimap.bottom_y = 1.0 - yscale * (res_y * (safezone_y * ((math.abs(safezone - 1.0)) * 10)))
	Minimap.right_x = Minimap.left_x + Minimap.width
	Minimap.top_y = Minimap.bottom_y - Minimap.height
	Minimap.x = Minimap.left_x
	Minimap.y = Minimap.top_y
	Minimap.xunit = xscale
	Minimap.yunit = yscale
	return Minimap
end
