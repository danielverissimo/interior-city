pedrin = module("vrp","lib/Tunnel").getInterface(GlobalState["svpedrin"])

local wall = false
local walldistance = 500 -- OneSync Infinity Max Distance
local wall_users = {}

local wallSettings = {
    showName = true,
    showUserId = true,
    showSourceId = true,
    showRole = true,
    showAllGroups = false,
    showLines = true,
    showSelf = true
}

local armas = {
    [tostring(GetHashKey('WEAPON_ANIMAL'))] = 'Animal', [tostring(GetHashKey('WEAPON_COUGAR'))] = 'Cougar', [tostring(GetHashKey('WEAPON_ADVANCEDRIFLE'))] = 'Advanced Rifle',
    [tostring(GetHashKey('WEAPON_APPISTOL'))] = 'AP Pistol', [tostring(GetHashKey('WEAPON_ASSAULTRIFLE'))] = 'Assault Rifle', [tostring(GetHashKey('WEAPON_ASSAULTRIFLE_MK2'))] = 'Assault Rifke Mk2',
    [tostring(GetHashKey('WEAPON_ASSAULTSHOTGUN'))] = 'Assault Shotgun', [tostring(GetHashKey('WEAPON_ASSAULTSMG'))] = 'Assault SMG', [tostring(GetHashKey('WEAPON_AUTOSHOTGUN'))] = 'Automatic Shotgun',
    [tostring(GetHashKey('WEAPON_BULLPUPRIFLE'))] = 'Bullpup Rifle', [tostring(GetHashKey('WEAPON_BULLPUPRIFLE_MK2'))] = 'Bullpup Rifle Mk2',[tostring(GetHashKey('WEAPON_BULLPUPSHOTGUN'))] = 'Bullpup Shotgun',
    [tostring(GetHashKey('WEAPON_CARBINERIFLE'))] = 'Carbine Rifle', [tostring(GetHashKey('WEAPON_CARBINERIFLE_MK2'))] = 'Carbine Rifle Mk2', [tostring(GetHashKey('WEAPON_COMBATMG'))] = 'Combat MG',
    [tostring(GetHashKey('WEAPON_COMBATMG_MK2'))] = 'Combat MG Mk2', [tostring(GetHashKey('WEAPON_COMBATPDW'))] = 'Combat PDW', [tostring(GetHashKey('WEAPON_COMBATPISTOL'))] = 'Combat Pistol',
    [tostring(GetHashKey('WEAPON_COMPACTRIFLE'))] = 'Compact Rifle', [tostring(GetHashKey('WEAPON_DBSHOTGUN'))] = 'Double Barrel Shotgun', [tostring(GetHashKey('WEAPON_DOUBLEACTION'))] = 'Double Action Revolver',
    [tostring(GetHashKey('WEAPON_FLAREGUN'))] = 'Flare gun', [tostring(GetHashKey('WEAPON_GUSENBERG'))] = 'Gusenberg', [tostring(GetHashKey('WEAPON_HEAVYPISTOL'))] = 'Heavy Pistol',
    [tostring(GetHashKey('WEAPON_HEAVYSHOTGUN'))] = 'Heavy Shotgun', [tostring(GetHashKey('WEAPON_HEAVYSNIPER'))] = 'Heavy Sniper', [tostring(GetHashKey('WEAPON_HEAVYSNIPER_MK2'))] = 'Heavy Sniper',
    [tostring(GetHashKey('WEAPON_MACHINEPISTOL'))] = 'Machine Pistol', [tostring(GetHashKey('WEAPON_MARKSMANPISTOL'))] = 'Marksman Pistol', [tostring(GetHashKey('WEAPON_MARKSMANRIFLE'))] = 'Marksman Rifle',
    [tostring(GetHashKey('WEAPON_MARKSMANRIFLE_MK2'))] = 'Marksman Rifle Mk2', [tostring(GetHashKey('WEAPON_MG'))] = 'MG', [tostring(GetHashKey('WEAPON_MICROSMG'))] = 'Micro SMG',
    [tostring(GetHashKey('WEAPON_MINIGUN'))] = 'Minigun', [tostring(GetHashKey('WEAPON_MINISMG'))] = 'Mini SMG', [tostring(GetHashKey('WEAPON_MUSKET'))] = 'Musket',
    [tostring(GetHashKey('WEAPON_PISTOL'))] = 'Pistol', [tostring(GetHashKey('WEAPON_PISTOL_MK2'))] = 'Pistol Mk2', [tostring(GetHashKey('WEAPON_PISTOL50'))] = 'Pistol .50',
    [tostring(GetHashKey('WEAPON_PUMPSHOTGUN'))] = 'Pump Shotgun', [tostring(GetHashKey('WEAPON_PUMPSHOTGUN_MK2'))] = 'Pump Shotgun Mk2', [tostring(GetHashKey('WEAPON_RAILGUN'))] = 'Railgun',
    [tostring(GetHashKey('WEAPON_REVOLVER'))] = 'Revolver', [tostring(GetHashKey('WEAPON_REVOLVER_MK2'))] = 'Revolver Mk2', [tostring(GetHashKey('WEAPON_SAWNOFFSHOTGUN'))] = 'Sawnoff Shotgun',
    [tostring(GetHashKey('WEAPON_SMG'))] = 'SMG', [tostring(GetHashKey('WEAPON_SMG_MK2'))] = 'SMG Mk2', [tostring(GetHashKey('WEAPON_SNIPERRIFLE'))] = 'Sniper Rifle',
    [tostring(GetHashKey('WEAPON_SNSPISTOL'))] = 'SNS Pistol', [tostring(GetHashKey('WEAPON_SNSPISTOL_MK2'))] = 'SNS Pistol Mk2', [tostring(GetHashKey('WEAPON_SPECIALCARBINE'))] = 'Special Carbine',
    [tostring(GetHashKey('WEAPON_SPECIALCARBINE_MK2'))] = 'Special Carbine Mk2', [tostring(GetHashKey('WEAPON_STINGER'))] = 'Stinger', [tostring(GetHashKey('WEAPON_STUNGUN'))] = 'Stungun',
    [tostring(GetHashKey('WEAPON_VINTAGEPISTOL'))] = 'Vintage Pistol', [tostring(GetHashKey('VEHICLE_WEAPON_PLAYER_LASER'))] = 'Vehicle Lasers',
    [tostring(GetHashKey('WEAPON_FIRE'))] = 'Fire', [tostring(GetHashKey('WEAPON_FLARE'))] = 'Flare', [tostring(GetHashKey('WEAPON_FLAREGUN'))] = 'Flaregun',
    [tostring(GetHashKey('WEAPON_MOLOTOV'))] = 'Molotov', [tostring(GetHashKey('WEAPON_PETROLCAN'))] = 'Petrol Can', [tostring(GetHashKey('WEAPON_HELI_CRASH'))] = 'Helicopter Crash',
    [tostring(GetHashKey('WEAPON_RAMMED_BY_CAR'))] = 'Rammed by Vehicle', [tostring(GetHashKey('WEAPON_RUN_OVER_BY_CAR'))] = 'Ranover by Vehicle', [tostring(GetHashKey('VEHICLE_WEAPON_SPACE_ROCKET'))] = 'Vehicle Space Rocket',
    [tostring(GetHashKey('VEHICLE_WEAPON_TANK'))] = 'Tank', [tostring(GetHashKey('WEAPON_AIRSTRIKE_ROCKET'))] = 'Airstrike Rocket', [tostring(GetHashKey('WEAPON_AIR_DEFENCE_GUN'))] = 'Air Defence Gun',
    [tostring(GetHashKey('WEAPON_COMPACTLAUNCHER'))] = 'Compact Launcher', [tostring(GetHashKey('WEAPON_EXPLOSION'))] = 'Explosion', [tostring(GetHashKey('WEAPON_FIREWORK'))] = 'Firework',
    [tostring(GetHashKey('WEAPON_GRENADE'))] = 'Grenade', [tostring(GetHashKey('WEAPON_GRENADELAUNCHER'))] = 'Grenade Launcher', [tostring(GetHashKey('WEAPON_HOMINGLAUNCHER'))] = 'Homing Launcher',
    [tostring(GetHashKey('WEAPON_PASSENGER_ROCKET'))] = 'Passenger Rocket', [tostring(GetHashKey('WEAPON_PIPEBOMB'))] = 'Pipe bomb', [tostring(GetHashKey('WEAPON_PROXMINE'))] = 'Proximity Mine',
    [tostring(GetHashKey('WEAPON_RPG'))] = 'RPG', [tostring(GetHashKey('WEAPON_STICKYBOMB'))] = 'Sticky Bomb', [tostring(GetHashKey('WEAPON_VEHICLE_ROCKET'))] = 'Vehicle Rocket',
    [tostring(GetHashKey('WEAPON_BZGAS'))] = 'BZ Gas', [tostring(GetHashKey('WEAPON_FIREEXTINGUISHER'))] = 'Fire Extinguisher', [tostring(GetHashKey('WEAPON_SMOKEGRENADE'))] = 'Smoke Grenade',
    [tostring(GetHashKey('WEAPON_BATTLEAXE'))] = 'Battleaxe', [tostring(GetHashKey('WEAPON_BOTTLE'))] = 'Bottle', [tostring(GetHashKey('WEAPON_KNIFE'))] = 'Knife',
    [tostring(GetHashKey('WEAPON_MACHETE'))] = 'Machete', [tostring(GetHashKey('WEAPON_SWITCHBLADE'))] = 'Switch Blade', [tostring(GetHashKey('OBJECT'))] = 'Object',
    [tostring(GetHashKey('VEHICLE_WEAPON_ROTORS'))] = 'Vehicle Rotors', [tostring(GetHashKey('WEAPON_BALL'))] = 'Ball', [tostring(GetHashKey('WEAPON_BAT'))] = 'Bat',
    [tostring(GetHashKey('WEAPON_CROWBAR'))] = 'Crowbar', [tostring(GetHashKey('WEAPON_FLASHLIGHT'))] = 'Flashlight', [tostring(GetHashKey('WEAPON_GOLFCLUB'))] = 'Golfclub',
    [tostring(GetHashKey('WEAPON_HAMMER'))] = 'Hammer', [tostring(GetHashKey('WEAPON_HATCHET'))] = 'Hatchet', [tostring(GetHashKey('WEAPON_HIT_BY_WATER_CANNON'))] = 'Water Cannon',
    [tostring(GetHashKey('WEAPON_KNUCKLE'))] = 'Knuckle', [tostring(GetHashKey('WEAPON_NIGHTSTICK'))] = 'Night Stick', [tostring(GetHashKey('WEAPON_POOLCUE'))] = 'Pool Cue',
    [tostring(GetHashKey('WEAPON_SNOWBALL'))] = 'Snowball', [tostring(GetHashKey('WEAPON_WRENCH'))] = 'Wrench', [tostring(GetHashKey('WEAPON_DROWNING'))] = 'Drowned',
    [tostring(GetHashKey('WEAPON_DROWNING_IN_VEHICLE'))] = 'Drowned in Vehicle', [tostring(GetHashKey('WEAPON_BARBED_WIRE'))] = 'Barbed Wire', [tostring(GetHashKey('WEAPON_BLEEDING'))] = 'Bleed',
    [tostring(GetHashKey('WEAPON_ELECTRIC_FENCE'))] = 'Electric Fence', [tostring(GetHashKey('WEAPON_EXHAUSTION'))] = 'Exhaustion', [tostring(GetHashKey('WEAPON_FALL'))] = 'Falling'
}

local allowedSettings = {
    showName = true,
    showUserId = true,
    showSourceId = true,
    showRole = true,
    showAllGroups = true,
    showLines = true,
    showSelf = true
}

local function notify(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false,false)
end

local function cleanText(value)
    if value == nil then
        return "N/A"
    end

    value = tostring(value):gsub("~","")
    if value == "" then
        return "N/A"
    end

    return value
end

local function joinGroups(groups)
    if type(groups) ~= "table" or #groups == 0 then
        return "N/A"
    end

    local result = {}
    for i = 1,#groups do
        result[#result + 1] = cleanText(groups[i])
    end

    return table.concat(result,", ")
end

local function getWallUser(src)
    return wall_users[src] or wall_users[tostring(src)]
end

local function openWallMenu()
    SendNUIMessage({
        action = "setVisible",
        visible = true,
        settings = wallSettings
    })
    SetNuiFocus(true,true)
end

local function closeWallMenu()
    SendNUIMessage({ action = "setVisible", visible = false })
    SetNuiFocus(false,false)
end

RegisterNetEvent(GlobalState["pedrin_wall"]..":wall")
AddEventHandler(GlobalState["pedrin_wall"]..":wall",function(val)
    wall = val == true

    -- /wall agora SOMENTE liga/desliga o wall.
    -- O menu só é aberto manualmente através de /wallmenu.
    if wall then
        notify("Wall Ativado!")
    else
        notify("Wall Desativado!")
        closeWallMenu()
    end
end)

RegisterNUICallback("updateSetting",function(data,cb)
    local key = data and data.key
    if key and allowedSettings[key] then
        wallSettings[key] = data.value == true
    end

    if cb then
        cb({ ok = true })
    end
end)

RegisterNUICallback("close",function(_,cb)
    closeWallMenu()
    if cb then
        cb({ ok = true })
    end
end)

-- Permite reabrir somente o painel de opções sem desligar o wall.
RegisterCommand("wallmenu",function()
    if wall then
        openWallMenu()
    end
end,false)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    pedrin.setWallInfos()

    while true do
        local time = 5000
        if wall then
            local infos = pedrin.getWallInfos()
            if type(infos) == "table" then
                wall_users = infos
            end
            time = 2000
        end
        Citizen.Wait(time)
    end
end)

local function DrawWallText(x,y,z,lines)
    if type(lines) ~= "table" or #lines == 0 then
        return
    end

    local onScreen,screenX,screenY = World3dToScreen2d(x,y,z)
    if not onScreen then
        return
    end

    -- Usa o ponto 3D apenas como referência logo acima da cabeça.
    -- O bloco cresce para cima, deixando a ÚLTIMA linha próxima da cabeça
    -- em vez de empurrar todo o texto muito para o alto.
    local lineHeight = 0.0155
    local bottomGap = 0.0060
    local startY = screenY - bottomGap - ((#lines - 1) * lineHeight)

    for index,text in ipairs(lines) do
        SetTextFont(4)
        SetTextProportional(1)
        SetTextScale(0.34,0.34)
        SetTextColour(255,255,255,255)
        SetTextCentre(true)
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(screenX,startY + ((index - 1) * lineHeight))
    end
end

Citizen.CreateThread(function()
    while true do
        local time = 2000

        if wall then
            local ped_id = PlayerPedId()
            local x1,y1,z1 = table.unpack(GetEntityCoords(ped_id,true))
            local camX,camY,camZ = table.unpack(GetGameplayCamCoord())

            for _,id in ipairs(GetActivePlayers()) do
                if NetworkIsPlayerActive(id) then
                    local src = GetPlayerServerId(id)
                    local nped_id = GetPlayerPed(id)
                    local userInfo = getWallUser(src)

                    -- Por padrão o wall também aparece no próprio jogador.
                    -- Se "Mostrar wall em mim" estiver desativado, ignora apenas o ped local.
                    local canShowPlayer = wallSettings.showSelf or nped_id ~= ped_id

                    if canShowPlayer and nped_id ~= -1 and DoesEntityExist(nped_id) and userInfo then
                        local x2,y2,z2 = table.unpack(GetEntityCoords(nped_id,true))
                        local distance = GetDistanceBetweenCoords(x2,y2,z2,camX,camY,camZ,true)

                        if distance <= walldistance then
                            local armour = GetPedArmour(nped_id)
                            local health = math.floor(GetEntityHealth(nped_id))
                            local armahash = GetSelectedPedWeapon(nped_id)
                            local skin = GetEntityModel(nped_id)
                            local arma = nil
                            local linecolour = true
                            local lines = {}

                            if armahash == 0 then
                                arma = "Arma Desconhecida"
                            elseif armas[tostring(armahash)] ~= nil then
                                arma = armas[tostring(armahash)]
                            end

                            if wallSettings.showName then
                                lines[#lines + 1] = "~w~Nome: ~g~"..cleanText(userInfo.name).."~w~"
                            end

                            if wallSettings.showUserId or wallSettings.showSourceId then
                                local ids = {}
                                if wallSettings.showUserId then
                                    ids[#ids + 1] = "~w~User ID: ~g~"..cleanText(userInfo.user_id).."~w~"
                                end
                                if wallSettings.showSourceId then
                                    ids[#ids + 1] = "~w~Source ID: ~g~"..cleanText(src).."~w~"
                                end
                                lines[#lines + 1] = table.concat(ids," ~w~| ")
                            end

                            -- STAFF e ORG são exibidos separadamente.
                            -- A linha Staff só aparece quando o jogador realmente possui cargo de staff.
                            if wallSettings.showRole then
                                local staff = cleanText(userInfo.staff)
                                if staff ~= "N/A" then
                                    lines[#lines + 1] = "~r~Staff: "..staff.."~w~"
                                end

                                lines[#lines + 1] = "~w~Org: ~g~"..cleanText(userInfo.org).."~w~"
                            end

                            -- Mantém a opção de visualizar a lista completa de grupos ativa separadamente.
                            if wallSettings.showAllGroups then
                                lines[#lines + 1] = "~w~Cargos: ~g~"..joinGroups(userInfo.groups).."~w~"
                            end

                            local statusLine = "~w~Health:~g~"..health.." ~w~|| Armour:~b~"..armour.."~w~"
                            if userInfo.wallstats == true then
                                statusLine = statusLine.." ~w~[~g~WALL ON~w~]"
                            end
                            lines[#lines + 1] = statusLine

                            if arma ~= nil then
                                lines[#lines + 1] = "~w~"..cleanText(arma).."~w~"
                            end

                            lines[#lines + 1] = "~w~Multiplicador Dano:~g~"..math.floor(GetPlayerWeaponDamageModifier(id)).."~w~"

                            if not IsEntityVisible(nped_id) then
                                lines[#lines + 1] = "~r~INVISIVEL~w~"
                                linecolour = false
                            end

                            if skin ~= 1885233650 and skin ~= -1667301416 then
                                lines[#lines + 1] = "~w~Model: ~r~"..skin.."~w~"
                                linecolour = false
                            end

                            -- Mantém o texto realmente CENTRALIZADO acima da cabeça.
                            -- Não usamos offset no próprio osso porque o offset é aplicado nos eixos
                            -- locais do bone e, dependendo da rotação/modelo, pode jogar o texto para o lado.
                            local pedCoords = GetEntityCoords(nped_id)
                            local headCoords = GetPedBoneCoords(nped_id,31086,0.0,0.0,0.0)

                            -- Centraliza no eixo X/Y do ped e usa somente a altura da cabeça.
                            -- 0.12 deixa o bloco próximo da cabeça sem encostar no modelo.
                            local labelZ = math.max(headCoords.z,pedCoords.z + 0.90) + 0.12
                            DrawWallText(pedCoords.x,pedCoords.y,labelZ,lines)

                            if wallSettings.showLines and nped_id ~= ped_id then
                                if not linecolour then
                                    DrawLine(x2,y2,z2 + 0.9,x1,y1,z1 + 0.9,255,0,0,255)
                                else
                                    DrawLine(x2,y2,z2 + 0.9,x1,y1,z1 + 0.9,0,120,255,255)
                                end
                            end
                        end
                    end
                end
            end

            time = 2
        end

        Citizen.Wait(time)
    end
end)
