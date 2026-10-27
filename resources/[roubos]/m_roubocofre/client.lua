-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
func = Tunnel.getInterface("m_roubocofre")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local robberyOngoing = false
local CashPile = nil
local bankBank = ""
local bankX = 0.0
local bankY = 0.0
local bankZ = 0.0
local laptop = nil

BankHeists = {}

-----------------------------------------------------------------------------------------------------------------------------------------
-- START ROBBERY
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    ResetDoors()
    while true do
        local sleep = 1000
        if not robberyOngoing then
            for bank,values in pairs(BankHeists) do
                local StartPosition = values["Start_Robbing"]
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local distanceCheck = GetDistanceBetweenCoords(pedCoords,StartPosition["x"],StartPosition["y"],StartPosition["z"],true)
                if distanceCheck <= 1.0 then
				   sleep = 5
                   DrawText3D(StartPosition["x"], StartPosition["y"], StartPosition["z"], "[~r~E~w~] Para ~r~INICIAR~w~ o roubo.")
                    if distanceCheck <= 1.5 then
						sleep = 5
                        if IsControlJustPressed(0,38) and func.CheckPolice() then
                            if func.KeyCard() and func.CheckRobbery(bank) then
                                HackAnimStart(StartPosition["x"],StartPosition["y"],StartPosition["z"],StartPosition["h"])
                                TriggerEvent("mhacking:show")
                                TriggerEvent("mhacking:start",RobConfig.hackBlocks or 3,RobConfig.hackSeconds or 60, function (success,time) mycallback(bank,success,time) end)
                                bankBank = bank
                                bankX = StartPosition["x"]
                                bankY = StartPosition["y"]
                                bankZ = StartPosition["z"]
                                checkDistanceToCancel()
                            end
                        end
                    end
                end
            end
        end
		Citizen.Wait(sleep)
    end
end)

function checkDistanceToCancel()
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(10)
			if robberyOngoing then
				local ped = PlayerPedId()
				local x,y,z = table.unpack(GetEntityCoords(ped))
				local distance = Vdist(x,y,z,bankX,bankY,bankZ)
				if distance >= (RobConfig.cancelDistance or 30.0) then
					robberyOngoing = false
					func.ResetMoney(bankBank)
					DeleteEntity(CashPile)
					break
				end
			end 
		end
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTION HACKING
-----------------------------------------------------------------------------------------------------------------------------------------
function mycallback(bank,success,time)
    if success then
        TriggerEvent("mhacking:hide")
        func.StartBankRobbery(bank)
        HackAnimStop()
        TriggerEvent('cancelando',false)
	else
        TriggerEvent("mhacking:hide")
        HackAnimStop()
		TriggerEvent('cancelando',false)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTION HACKING ANIM
-----------------------------------------------------------------------------------------------------------------------------------------
function HackAnimStart(x,y,z,h)
    local ped = PlayerPedId()
    vRP._playAnim(false,{{"anim@heists@ornate_bank@hack","hack_enter"}},false)
    Wait(8000)
    vRP._playAnim(false,{{"anim@heists@ornate_bank@hack","hack_loop"}},true)
    laptop = CreateObject(GetHashKey("prop_laptop_01a"),x-0.4,y+0.2,z-1,true,true,true)
    SetEntityHeading(ped,h)
    SetEntityHeading(laptop,h)
end

function HackAnimStop()
    vRP._playAnim(false,{{"anim@heists@money_grab@briefcase","exit"}},true)
    Wait(1500)
    DeleteObject(laptop)
    vRP._stopAnim(false)    
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ROBBERY EVENTS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("bankrobbery:startRobbery")
AddEventHandler("bankrobbery:startRobbery",function(bankId)
    StartRobbery(bankId)
end)

RegisterNetEvent("bankrobbery:deleteEntity")
AddEventHandler("bankrobbery:deleteEntity",function()
    DeleteEntity(CashPile)
    robberyOngoing = false
end)

RegisterNetEvent("bankrobbery:endRobbery")
AddEventHandler("bankrobbery:endRobbery",function(bankId)
    robberyOngoing = false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- START ROBBERY FUNCTION
-----------------------------------------------------------------------------------------------------------------------------------------
function StartRobbery(bankId)
    
    robberyOngoing = true
    local CashPosition = BankHeists[bankId]["Cash_Pile"]
    loadModel("bkr_prop_bkr_cashpile_04")
    loadAnimDict("anim@heists@ornate_bank@grab_cash_heels")
    CashPile = CreateObject(GetHashKey("bkr_prop_bkr_cashpile_04"),CashPosition["x"],CashPosition["y"],CashPosition["z"],false)
    PlaceObjectOnGroundProperly(CashPile)
    SetEntityRotation(CashPile,0,0,CashPosition["h"],2)
    FreezeEntityPosition(CashPile, true)
    SetEntityAsMissionEntity(CashPile,true,true)
    Citizen.CreateThread(function()
        while robberyOngoing do
            Citizen.Wait(1)
            local Cash = BankHeists[bankId]["Money"]
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local distanceCheck = GetDistanceBetweenCoords(pedCoords,CashPosition["x"],CashPosition["y"],CashPosition["z"],false)
            if distanceCheck <= (RobConfig.cashInteractDistance or 6.0) then
                DrawText3D(CashPosition["x"],CashPosition["y"],CashPosition["z"],"[~r~E~w~] Para ~r~Pegar~w~ o dinheiro.")
                if IsControlJustPressed(0,38) then
                    GrabCash(bankId)
                end
			elseif distanceCheck > (RobConfig.cancelDistance or 30.0) then
				break
            end
        end
    end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GRAB CASH
-----------------------------------------------------------------------------------------------------------------------------------------
function GrabCash(bankId)
    TaskPlayAnim(PlayerPedId(),"anim@heists@ornate_bank@grab_cash_heels","grab",8.0,-8.0,-1,1,0,false,false,false)
    Citizen.Wait(RobConfig.cashAnimationMilliseconds or 7500)
    ClearPedTasks(PlayerPedId())
    func.CheckPayment(bankId)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function loadAnimDict(dict)
    Citizen.CreateThread(function()
        while (not HasAnimDictLoaded(dict)) do
            RequestAnimDict(dict)
            Citizen.Wait(10)
        end
    end)
end

function loadModel(model)
    Citizen.CreateThread(function()
        while not HasModelLoaded(model) do
            RequestModel(model)
        Citizen.Wait(10)
        end
    end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOORS EVENTS / FUNCTIONS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("bankrobbery:openDoor")
AddEventHandler("bankrobbery:openDoor", function(bankId)
    ResetDoor(bankId)
    local Bank = BankHeists[bankId]
    local door = GetClosestObjectOfType(Bank['Bank_Vault']['x'],Bank['Bank_Vault']['y'],Bank['Bank_Vault']['z'],3.0,Bank['Bank_Vault']['model'])
    local rotation = GetEntityRotation(door)["z"]
    local dif = Bank['Bank_Vault']['model']
	Citizen.CreateThread(function()
        FreezeEntityPosition(door, false)
        if dif == -1185205679 then
            while rotation <= Bank["Bank_Vault"]["hEnd"] do
                Citizen.Wait(10)
                rotation = rotation + 0.25
                SetEntityRotation(door,0.0,0.0,rotation)
            end
        else
            while rotation >= Bank["Bank_Vault"]["hEnd"] do
                Citizen.Wait(10)
                rotation = rotation - 0.25
                SetEntityRotation(door,0.0,0.0,rotation)
            end
        end
		FreezeEntityPosition(door,true)
    end)
end)

function ResetDoor(bankId)
    local Bank = BankHeists[bankId]
    local door = GetClosestObjectOfType(Bank['Bank_Vault']['x'],Bank['Bank_Vault']['y'],Bank['Bank_Vault']['z'],3.0,Bank['Bank_Vault']['model'])
    SetEntityRotation(door, 0.0, 0.0, Bank["Bank_Vault"]["hStart"], 0.0)
end

function ResetDoors()
    for bank, values in pairs(BankHeists) do
        local door = GetClosestObjectOfType(values['Bank_Vault']['x'],values['Bank_Vault']['y'],values['Bank_Vault']['z'],3.0,values['Bank_Vault']['model'])
        SetEntityRotation(door,0.0,0.0,values["Bank_Vault"]["hStart"],0.0)
        FreezeEntityPosition(door,true)
    end
end

-- [ FUNÇÃO DO TEXTO 3D ] --
function DrawText3D(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.40, 0.40)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end


-----------------------------------------------------------------------------------------------------------------------------------------
-- MARK
-----------------------------------------------------------------------------------------------------------------------------------------
local blip = nil
RegisterNetEvent('blip:criar:banco')
AddEventHandler('blip:criar:banco',function(x,y,z,bankId)
	if not DoesBlipExist(blip) then
		blip = AddBlipForCoord(x,y,z)
		SetBlipScale(blip,0.5)
		SetBlipSprite(blip,1)
		SetBlipColour(blip,59)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Roubo ao banco: ~g~"..bankId)
		EndTextCommandSetBlipName(blip)
		SetBlipAsShortRange(blip,false)
		SetBlipRoute(blip,true)
	end
end)

RegisterNetEvent('blip:remover:banco')
AddEventHandler('blip:remover:banco',function()
	if DoesBlipExist(blip) then
		RemoveBlip(blip)
		blip = nil
	end
end)