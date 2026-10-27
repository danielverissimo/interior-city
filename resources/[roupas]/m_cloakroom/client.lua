local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vSERVER = Tunnel.getInterface(GetCurrentResourceName())


-------------------------------------------------------------------------------------------
---- CONFIG JSON / SINCRONIZAÇÃO
-------------------------------------------------------------------------------------------
cfg = cfg or { geral = {} }

local function normalizeOutfit(outfit)
    local normalized = {}
    for k,v in pairs(type(outfit) == "table" and outfit or {}) do
        local key = tonumber(k) or k
        normalized[key] = v
    end
    return normalized
end

local function applyCloakroomConfig(list)
    cfg.geral = {}

    for _,room in ipairs(type(list) == "table" and list or {}) do
        local name = tostring(room.name or "")
        local c = room.coords or {}
        local uniforms = {}

        for i,u in ipairs(type(room.uniforms) == "table" and room.uniforms or {}) do
            uniforms[i] = {
                tipo = tostring(u.name or ("Fardamento "..i)),
                fardas = {
                    masculino = normalizeOutfit(u.masculino),
                    feminino = normalizeOutfit(u.feminino)
                }
            }
        end

        if name ~= "" then
            cfg.geral[name] = {
                blip = vec3(tonumber(c.x) or 0.0, tonumber(c.y) or 0.0, tonumber(c.z) or 0.0),
                permissao = tostring(room.permission or ""),
                geral = uniforms
            }
        end
    end
end

local function loadLocalCloakroomConfig()
    local raw = LoadResourceFile(GetCurrentResourceName(),"config.json")
    local ok,data = pcall(json.decode,raw or "{}")
    if ok and type(data) == "table" then
        applyCloakroomConfig(data.cloakrooms or {})
    end
end

RegisterNetEvent("m_cloakroom:fullSync",function(list)
    applyCloakroomConfig(list)
end)

loadLocalCloakroomConfig()

CreateThread(function()
    Wait(700)
    TriggerServerEvent("m_cloakroom:requestSync")
end)


-------------------------------------------------------------------------------------------
---- VARS
-------------------------------------------------------------------------------------------

local activenui = false

-------------------------------------------------------------------------------------------
---- MAIN THREAD
-------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        for k,v in pairs(cfg.geral) do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local distance = #(vec3(coords[1],coords[2],coords[3]) - vec3(v.blip[1],v.blip[2],v.blip[3]))

            if distance <= 7.0 then
                idle = 1
                DrawMarker(27,v.blip[1],v.blip[2],v.blip[3]-0.97,0,0,0,0,0,0,0.7,0.7,0.3,0, 191, 255,155,0,0,0,1)
                if distance <= 4.0 then
                    DrawText3D(v.blip[1],v.blip[2],v.blip[3], " ~y~ Fardas "..k.." ~w~\n [~b~E~w~] Para se trocar~w~.")
                    if distance <= 1.0 and IsControlJustPressed(0, 38) and vSERVER.checkPerm(v.permissao) then
                        SendNUIMessage({
                            showNUI = true,
                            table = v.geral
                        })
                        SetNuiFocus(true,true)      
                        activenui = true
                    end
                end
            end
        end
        Citizen.Wait(idle)
    end
end)

RegisterNUICallback("ButtonClick",function(data,cb)

    local fardas = data

    TriggerServerEvent('mg-cloack:give_un',fardas)

end)

RegisterNUICallback("rmv_un",function(data,cb)

    local fardas = data

    TriggerServerEvent('mg-cloack:off_un')

end)

RegisterNUICallback("close", function(data, callback)
    SetNuiFocus(false,false)            
    activenui = false
end)

-------------------------------------------------------------------------------------------
---- FUNCTIONS
-------------------------------------------------------------------------------------------


function DrawText3D(x, y, z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.50, 0.50)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370

end



























