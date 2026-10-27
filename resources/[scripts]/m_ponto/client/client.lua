local nearestOrg = nil
local userGroup = nil
local clothes = {}

local userData = {}
function table.map(t, f)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = f(k, v)
    end
    return t2
end

local function dbg(t)
    if(type(t) == "table") then
    else
    end
end


local function findNearestOrg(coords)
    local distance = 10000
    local org = nil
    local resultCoords = nil
    for k,v in pairs(Config.Orgs) do
        for i = 1, #v.coords do
            local dist = #(coords - v.coords[i])
            if dist < distance then
                distance = dist
                org = k
                resultCoords = v.coords[i]
            end
        end
    end
    return org, distance, resultCoords
end

CreateThread(function()
	while true do
        local sleep = 3000
		local coords = GetEntityCoords(PlayerPedId())
        local org, distance, resultCoords = findNearestOrg(coords)
        if org and distance < 5 then
            sleep = 3
            local orgData = Config.Orgs[org]
            DrawText3D(resultCoords, "~g~[E]~w~ Ponto - "..org)
            if IsControlJustPressed(0, 38) then
                local success, group, startTime, userInfo = Remote.checkOrgData(org)
                userData = userInfo
                if success then
                    nearestOrg = org
                    userGroup = group
                    SendNUIMessage({ action = 'open', data = {
                        point = startTime
                    }})
                    SetNuiFocus(true, true)
                else
                    TriggerEvent("Notify", "negado", "Você não faz parte da organização "..org)
                    Wait(2000)
                end
            end
        end
        Wait(sleep)
	end
end)

RegisterNUICallback('getUser', function(data, cb)
  cb(userData)
end)

RegisterNUICallback('hideFrame', function(data, cb)
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNUICallback('point', function(data, cb)
    if not nearestOrg then
        return cb({ success = false, error = "Organização não identificada." })
    end

    local response
    if data.status then
        response = Remote.startService(nearestOrg)
    else
        response = Remote.stopService(nearestOrg)
        if response and response.success then
            -- Ao sair de serviço, também sai do rádio operacional.
            pcall(function()
                exports["pma-voice"]:setRadioChannel(0)
                exports["pma-voice"]:setVoiceProperty("radioEnabled", false)
            end)
            TriggerEvent("lotus-hud:setRadioFrequency", 0)
        end
    end

    cb(response or { success = false, error = "Sem resposta do servidor." })
end)

RegisterNUICallback('equip', function(data, cb)
    if not nearestOrg then
        return cb({ success = false, error = "Organização não identificada." })
    end

    local response = Remote.equip(nearestOrg)
    if response and response.success then
        local orgConfig = Config.Orgs[nearestOrg]
        if orgConfig then
            local newChannel = orgConfig.radioChannel
            TriggerEvent("InteractSound_CL:PlayOnOne","radioclick",0.6)
            TriggerEvent("lotus-hud:setRadioFrequency", parseInt(newChannel))
            pcall(function()
                exports["pma-voice"]:setRadioChannel(parseInt(newChannel))
                exports["pma-voice"]:setVoiceProperty('radioEnabled',true)
            end)
        end
    end
    cb(response or { success = false, error = "Sem resposta do servidor." })
end)

RegisterNUICallback('takeWeapon', function(data, cb)
    if not nearestOrg or not data or not data.weapon then
        return cb({ success = false, error = "Arma inválida." })
    end
    local response = Remote.takeWeapon(nearestOrg, data.weapon)
    cb(response or { success = false, error = "Sem resposta do servidor." })
end)

RegisterNUICallback('getEquipments', function(_, cb)
    local payload = {}
    if not nearestOrg or not userGroup then
        return cb(payload)
    end

    local orgConfig = Config.Orgs[nearestOrg]
    local groupConfig = orgConfig and orgConfig.groups[userGroup]
    if not groupConfig then
        return cb(payload)
    end

    for _, weaponKey in ipairs(groupConfig.WeaponsKit or {}) do
        local kit = Config.WeaponsKit[weaponKey]
        if kit then
            payload[#payload + 1] = {
                image = "nui://lotus_hud/web-side/assets/weapons/"..GetHashKey(kit.name)..".png",
                name = weaponKey,
                weapon = weaponKey,
            }
        end
    end
    cb(payload)
end)

RegisterNUICallback('getUniforms', function(data, cb)
    local payload = Remote.getClothes(nearestOrg)
    dbg(payload)
    cb(payload)
end)

RegisterNUICallback('getRanking', function(data, cb)
    local payload = Remote.getRanking(nearestOrg) or {}
    cb(payload)
end)
RegisterNUICallback('editUniform', function(data, cb)
    -- text = json.encode(json.decode(json.encode(data.text)))
    -- for k,v in pairs(data) do
    --     print(v)
    -- end
    local response = Remote.updateUniform(nearestOrg, data.uniform.group, data.text)
    if response then
        cb(true)
    else
        TriggerEvent("Notify", "negado", "Uniforme inválido!")
        cb(false)
    end
end)



-- Segurança para restart/stop do resource: nunca deixa foco NUI ou rádio presos.
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    pcall(function()
        exports["pma-voice"]:setRadioChannel(0)
        exports["pma-voice"]:setVoiceProperty("radioEnabled", false)
    end)
    TriggerEvent("lotus-hud:setRadioFrequency", 0)
end)
