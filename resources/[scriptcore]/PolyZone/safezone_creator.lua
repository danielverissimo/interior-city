local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

local inCreateMode = false
local points = {}
local blips = {}
local createdZone = nil

local function drawTxt(text, font, x, y, scale, r, g, b, a)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

local function createBlip(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipColour(blip, 2)
    SetBlipDisplay(blip, 8)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    return blip
end

local function clearBlips()
    for _, blip in ipairs(blips) do
        RemoveBlip(blip)
    end
    blips = {}
end

local function drawPolygon()
    if #points < 2 then return end
    local skyZ = 1000.0
    for i = 1, #points do
        local nextIndex = i == #points and 1 or i + 1
        local p1 = points[i]
        local p2 = points[nextIndex]
        local x1, y1, z1 = p1.x, p1.y, p1.z
        local x2, y2, z2 = p2.x, p2.y, p2.z
        local x1t, y1t, z1t = x1, y1, skyZ
        local x2t, y2t, z2t = x2, y2, skyZ
        DrawPoly(x1, y1, z1, x2, y2, z2, x1t, y1t, z1t, 0, 0, 255, 150)
        DrawPoly(x2, y2, z2, x2t, y2t, z2t, x1t, y1t, z1t, 0, 0, 255, 150)
    end
end

RegisterCommand('create_safezone', function()
    TriggerServerEvent("PolyZone:checkPermission")
end)

RegisterNetEvent("PolyZone:startCreation")
AddEventHandler("PolyZone:startCreation", function()
    inCreateMode = true
    points = {}
    clearBlips()
    
    Citizen.CreateThread(function()
        while inCreateMode do
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            
            drawTxt("~g~E~w~ PARA ADICIONAR PONTO", 4, 0.5, 0.8, 0.4, 255, 255, 255, 180)
            drawTxt("~g~F~w~ PARA REMOVER ÚLTIMO PONTO", 4, 0.5, 0.83, 0.4, 255, 255, 255, 180)
            drawTxt("~r~BACKSPACE~w~ PARA CANCELAR", 4, 0.5, 0.86, 0.4, 255, 255, 255, 180)
            drawTxt("~g~ENTER~w~ PARA CRIAR SAFEZONE", 4, 0.5, 0.89, 0.4, 255, 255, 255, 180)
            
            drawPolygon()
            
            if IsControlJustPressed(0, 38) then -- E
                table.insert(points, coords)
                table.insert(blips, createBlip(coords))
                print("^2[SAFEZONE] ^7Ponto adicionado: ^3"..coords.x..", "..coords.y..", "..coords.z.."^7")
            end
            
            if IsControlJustPressed(0, 75) then -- F
                if #points > 0 then
                    table.remove(points)
                    if #blips > 0 then
                        RemoveBlip(table.remove(blips))
                    end
                    print("^2[SAFEZONE] ^7Último ponto removido")
                end
            end
            
            if IsControlJustPressed(0, 177) then -- BACKSPACE
                inCreateMode = false
                points = {}
                clearBlips()
                print("^2[SAFEZONE] ^7Criação cancelada")
                TriggerEvent("Notify", "negado", "Criação de safezone cancelada.")
            end
            
            if IsControlJustPressed(0, 201) then -- ENTER
                if #points >= 3 then
                    inCreateMode = false
                    print("^2[SAFEZONE] ^7Criando safezone com ^3"..#points.."^7 pontos")
                    TriggerServerEvent("PolyZone:createSafeZone", points)
                    points = {}
                    clearBlips()
                else
                    print("^2[SAFEZONE] ^7Você precisa de pelo menos 3 pontos para criar uma safezone")
                    TriggerEvent("Notify", "negado", "Você precisa de pelo menos 3 pontos para criar uma safezone.")
                end
            end
            
            Wait(0)
        end
    end)
end)

RegisterNetEvent("PolyZone:receiveZoneCode")
AddEventHandler("PolyZone:receiveZoneCode", function(zoneCode)
    print("^2[SAFEZONE] ^7Código gerado:")
    print(zoneCode)
end)