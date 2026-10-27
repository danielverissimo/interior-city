local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

local src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)

local VIP_GROUP = "vipinicial"
local VIP_TITLE = "Vip Inicial"
local VIP_DURATION_SECONDS = 7 * 24 * 60 * 60
local VIP_MARKER_KEY = "vipinicial"
local CHARACTER_CREATED_KEY = "creator:character_created"
local RESET_PENDING_KEY = "creator:reset_pending"
local HOSPITAL_SPAWN = { x = 1155.67, y = -1547.43, z = 34.85, h = 0.0 }

local inCreator = {}
local WhitelistPending = {}
local userlogin = {}

local cars = {
    ["t20"] = true,
    ["osiris"] = true,
    ["speedo"] = true,
}

local function notify(playerSource, notifyType, message, time)
    if playerSource then
        TriggerClientEvent("Notify", playerSource, notifyType, message, time or 5)
    end
end

local function deleteUData(user_id, key)
    exports.oxmysql:executeSync(
        "DELETE FROM vrp_user_data WHERE user_id = ? AND dkey = ?",
        { user_id, key }
    )
end

local function persistUserData(user_id)
    local data = vRP.getUserDataTable(user_id)
    if data then
        vRP.setUData(user_id, "vRP:datatable", json.encode(data))
    end
end

local function isResetPending(user_id)
    return vRP.getUData(user_id, RESET_PENDING_KEY) ~= ""
end

local function ensureVipTable()
    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS `temporary_vips` (
            `user_id` INT NOT NULL,
            `expiration_date` DATETIME NOT NULL,
            PRIMARY KEY (`user_id`),
            KEY `idx_temporary_vips_expiration` (`expiration_date`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local function ensureVipGroup()
    local ok, managedGroups = pcall(function()
        return exports["vrp"]:getManagedGroups()
    end)

    if not ok or type(managedGroups) ~= "table" then
        print("^1[vrp_creator]^7 Não foi possível consultar os cargos da vRP para validar o Vip Inicial.")
        return false
    end

    for _, group in ipairs(managedGroups) do
        if tostring(group.name or "") == VIP_GROUP then
            return true
        end
    end

    local created, message = exports["vrp"]:saveManagedGroup("", {
        name = VIP_GROUP,
        config = {
            title = VIP_TITLE,
        },
        permissions = {
            "perm.vipinicial",
        },
    })

    if not created then
        print(("^1[vrp_creator]^7 Falha ao criar o cargo '%s': %s"):format(VIP_GROUP, tostring(message)))
        return false
    end

    print(("^2[vrp_creator]^7 Cargo '%s' (%s) criado automaticamente."):format(VIP_GROUP, VIP_TITLE))
    return true
end

local function removeVipFromOfflineUser(user_id)
    local row = exports.oxmysql:singleSync(
        "SELECT dvalue FROM vrp_user_data WHERE user_id = ? AND dkey = ? LIMIT 1",
        { user_id, "vRP:datatable" }
    )

    if not row or not row.dvalue then
        return
    end

    local ok, data = pcall(json.decode, row.dvalue)
    if not ok or type(data) ~= "table" then
        return
    end

    if type(data.groups) == "table" and data.groups[VIP_GROUP] ~= nil then
        data.groups[VIP_GROUP] = nil
        exports.oxmysql:executeSync(
            "UPDATE vrp_user_data SET dvalue = ? WHERE user_id = ? AND dkey = ?",
            { json.encode(data), user_id, "vRP:datatable" }
        )
    end
end

local function expireVip(user_id, removeTracking)
    user_id = tonumber(user_id)
    if not user_id then return end

    local playerSource = vRP.getUserSource(user_id)
    if playerSource and vRP.getUserDataTable(user_id) then
        if vRP.hasGroup(user_id, VIP_GROUP) then
            vRP.removeUserGroup(user_id, VIP_GROUP)
            persistUserData(user_id)
            notify(playerSource, "importante", "Seu Vip Inicial de 7 dias expirou.", 7)
        end
    else
        removeVipFromOfflineUser(user_id)
    end

    if removeTracking ~= false then
        exports.oxmysql:executeSync(
            "DELETE FROM temporary_vips WHERE user_id = ?",
            { user_id }
        )
    end
end

local function reconcileVip(user_id)
    user_id = tonumber(user_id)
    if not user_id then return end

    local row = exports.oxmysql:singleSync(
        "SELECT UNIX_TIMESTAMP(expiration_date) AS expires_at FROM temporary_vips WHERE user_id = ? LIMIT 1",
        { user_id }
    )

    if not row then
        return
    end

    local expiresAt = tonumber(row.expires_at) or 0
    if expiresAt <= os.time() then
        expireVip(user_id, true)
        return
    end

    if ensureVipGroup() and not vRP.hasGroup(user_id, VIP_GROUP) then
        vRP.addUserGroup(user_id, VIP_GROUP)
        persistUserData(user_id)
    end
end

local function grantInitialVip(user_id, playerSource)
    -- Este marcador nunca é apagado. Assim, reset de personagem não renova o VIP.
    if vRP.getUData(user_id, VIP_MARKER_KEY) ~= "" then
        return false
    end

    if not ensureVipGroup() then
        return false
    end

    local expiration = os.time() + VIP_DURATION_SECONDS
    exports.oxmysql:executeSync([[
        INSERT INTO temporary_vips (user_id, expiration_date)
        VALUES (?, FROM_UNIXTIME(?))
        ON DUPLICATE KEY UPDATE expiration_date = VALUES(expiration_date)
    ]], { user_id, expiration })

    vRP.addUserGroup(user_id, VIP_GROUP)
    persistUserData(user_id)
    vRP.setUData(user_id, VIP_MARKER_KEY, "1")

    notify(playerSource, "sucesso", "Você recebeu o Vip Inicial por 7 dias.", 7)
    return true
end

local function resetAppearanceState(user_id)
    exports.oxmysql:executeSync([[
        UPDATE vrp_users_infos
        SET controller = 0, rosto = '{}', roupas = '{}', tattos = '{}'
        WHERE user_id = ?
    ]], { user_id })

    if vRP.getUserApparence(user_id) then
        vRP.updateUserApparence(user_id, "controller", 0)
        vRP.updateUserApparence(user_id, "rosto", {})
        vRP.updateUserApparence(user_id, "clothes", {})
        vRP.updateUserApparence(user_id, "tattos", {})
    end
end

local function startCharacterReset(user_id, requestedBy, reason)
    user_id = tonumber(user_id)
    if not user_id then
        return false, "ID inválido."
    end

    local targetSource = vRP.getUserSource(user_id)
    if not targetSource then
        return false, "O player precisa estar online para ser resetado."
    end

    if inCreator[user_id] then
        return false, "Este player já está na criação de personagem."
    end

    -- Marca o personagem como já criado ANTES de zerar o controller.
    -- Isso impede kit inicial, carro, indicação e Vip Inicial novamente mesmo
    -- se o jogador desconectar no meio da recriação.
    vRP.setUData(user_id, CHARACTER_CREATED_KEY, "1")
    vRP.setUData(user_id, RESET_PENDING_KEY, json.encode({
        created_at = os.time(),
        reason = tostring(reason or "reset"),
    }))

    resetAppearanceState(user_id)

    inCreator[user_id] = true
    userlogin[user_id] = true
    SetPlayerRoutingBucket(targetSource, user_id)

    TriggerClientEvent("inventory:forceClose", targetSource)
    TriggerClientEvent("character:characterCreate", targetSource, {
        reset = true,
        spawn = HOSPITAL_SPAWN,
    })

    print(("[vrp_creator] ID %s iniciou reset de personagem. Solicitante: %s | Motivo: %s"):format(
        user_id,
        tostring(requestedBy or user_id),
        tostring(reason or "reset")
    ))

    return true, "Reset iniciado com sucesso."
end

exports("requestCharacterReset", function(user_id, requestedBy, reason)
    return startCharacterReset(user_id, requestedBy, reason)
end)

src.getUserId = function()
    local playerSource = source
    local user_id = vRP.getUserId(playerSource)
    if user_id then
        WhitelistPending[user_id] = playerSource
    end
    return user_id
end

src.checkWhitelist = function()
    local playerSource = source
    local user_id = vRP.getUserId(playerSource)

    if user_id then
        local query = exports.oxmysql:query_async(
            "SELECT whitelist FROM vrp_users WHERE id = ?",
            { user_id }
        )

        if #query > 0 and query[1].whitelist then
            WhitelistPending[user_id] = nil
            return true
        end
    end

    return false
end

src.finishWhitelist = function(data)
    local playerSource = source
    local user_id = vRP.getUserId(playerSource)
    if not user_id or not inCreator[user_id] or type(data) ~= "table" then
        return false
    end

    local name = tostring(data.name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local surname = tostring(data.surname or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local age = tonumber(data.age)

    if name == "" or surname == "" or #name > 25 or #surname > 25 or not age or age < 18 or age > 99 then
        notify(playerSource, "negado", "Dados do personagem inválidos.", 5)
        return false
    end

    local nameStr = (name .. surname):lower()
    if nameStr:find("iframe", 1, true) or nameStr:find("<", 1, true) or nameStr:find(">", 1, true) then
        DropPlayer(playerSource, ":)")
        vRP.setBanned(user_id, true, "IFRAME INJECT")
        return false
    end

    local resetPending = isResetPending(user_id)

    -- A NUI usa este marcador apenas no fluxo de reset/plástica.
    -- O servidor confirma o estado persistente para impedir que um primeiro acesso
    -- force artificialmente o modo de recriação e pule etapas do onboarding.
    if data.resetIdentityOnly == true and not resetPending then
        notify(playerSource, "negado", "Fluxo de recriação inválido.", 5)
        return false
    end

    -- Dados de marketing/recompensa só são processados na criação original.
    if not resetPending then
        local findType = tostring(data.find or "")
        local allowedFindTypes = {
            instagram = true,
            youtube = true,
            tiktok = true,
            facebook = true,
            amigo = true,
            outros = true,
        }

        if allowedFindTypes[findType] then
            exports.oxmysql:executeSync(
                "INSERT INTO leads_new (user_id, type, created_at) VALUES (?, ?, ?)",
                { user_id, findType, os.date("%Y-%m-%d %H:%M:%S") }
            )
            exports.oxmysql:executeSync(
                ("UPDATE leads SET `%s` = `%s` + 1"):format(findType, findType),
                {}
            )
        end
    end

    vRP.execute("vRP/update_user_first_spawn", {
        user_id = user_id,
        nome = name,
        sobrenome = surname,
        idade = age,
    })
    vRP.updateIdentity(user_id)

    if not resetPending then
        local rewardCar = vRP.getUData(user_id, "rewardCar")
        if rewardCar == "" then
            if data.vehicle and cars[data.vehicle] then
                local placa = vRP.gerarPlaca()
                vRP.execute("vRP/inserir_veh", {
                    veiculo = data.vehicle,
                    user_id = user_id,
                    placa = placa,
                    ipva = os.time(),
                    expired = "{}",
                })
            elseif data.vehicle then
                print("Veiculo não encontrado na criacao " .. tostring(data.vehicle))
            end

            vRP.setUData(user_id, "rewardCar", "1")

            local recommendation = tonumber(data.recomendation or data.recommendation)
            if recommendation and recommendation ~= user_id then
                vRP.giveBankMoney(recommendation, 50000)
            end
        end

        grantInitialVip(user_id, playerSource)
    end

    return true
end

local function finalizeCharacterCreation(playerSource, currentCharacterMode, Clothes)
    local user_id = vRP.getUserId(playerSource)
    if not user_id or not inCreator[user_id] then
        return { ok = false, error = "Sessão de criação inválida ou expirada." }
    end

    if type(currentCharacterMode) ~= "table" or type(Clothes) ~= "table" then
        return { ok = false, error = "Dados do personagem inválidos." }
    end

    -- Cabelo nunca é persistido dentro de "clothes".
    Clothes[2] = nil
    Clothes["2"] = nil

    local query = vRP.query("vRP/get_controller", { user_id = user_id })
    if not query or #query == 0 then
        return { ok = false, error = "Não foi possível localizar o controller do personagem." }
    end

    local resetPending = isResetPending(user_id)
    local alreadyCreated = vRP.getUData(user_id, CHARACTER_CREATED_KEY) ~= ""

    vRP.execute("vRP/set_controller", {
        user_id = user_id,
        controller = 1,
        rosto = json.encode(currentCharacterMode),
        roupas = json.encode(Clothes),
    })

    vRP.updateUserApparence(user_id, "controller", 1)
    vRP.updateUserApparence(user_id, "clothes", Clothes)
    vRP.updateUserApparence(user_id, "rosto", currentCharacterMode)

    -- Kit inicial é entregue uma única vez e sem forçar slots 1-5,
    -- pois estes slots são a hotbar de armas do inventário atual.
    if not resetPending and not alreadyCreated then
        vRP.giveInventoryItem(user_id, "money", 40000, false)
        vRP.giveInventoryItem(user_id, "celular", 1, false)
        vRP.giveInventoryItem(user_id, "mochila", 3, false)
        vRP.giveInventoryItem(user_id, "radio", 1, false)
        vRP.setUData(user_id, CHARACTER_CREATED_KEY, "1")
    end

    inCreator[user_id] = nil
    SetPlayerRoutingBucket(playerSource, 0)

    if resetPending then
        deleteUData(user_id, RESET_PENDING_KEY)
    end

    TriggerEvent("barbershop:init", user_id)

    return {
        ok = true,
        reset = resetPending,
        spawn = resetPending and HOSPITAL_SPAWN or nil,
    }
end

src.finishCharacter = function(currentCharacterMode, Clothes)
    return finalizeCharacterCreation(source, currentCharacterMode, Clothes)
end

-- Compatibilidade com versões anteriores do client.
RegisterServerEvent("character:finishedCharacter")
AddEventHandler("character:finishedCharacter", function(currentCharacterMode, Clothes)
    local result = finalizeCharacterCreation(source, currentCharacterMode, Clothes)
    TriggerClientEvent("character:finishResult", source, result)
end)

function doSpawnPlayer(playerSource, user_id, firstspawn)
    if playerSource then
        TriggerClientEvent("character:normalSpawn", playerSource, firstspawn)
    end
end

function processSpawnController(playerSource, statusSent, user_id)
    statusSent = tonumber(statusSent) or 0

    if statusSent >= 1 then
        if not userlogin[user_id] then
            userlogin[user_id] = true
            doSpawnPlayer(playerSource, user_id, false)
        else
            doSpawnPlayer(playerSource, user_id, true)
        end
        return
    end

    inCreator[user_id] = true
    userlogin[user_id] = true
    SetPlayerRoutingBucket(playerSource, user_id)

    local resetPending = isResetPending(user_id)
    TriggerClientEvent("character:characterCreate", playerSource, {
        reset = resetPending,
        spawn = resetPending and HOSPITAL_SPAWN or nil,
    })
end

local discordAuthEnabled = GetResourceState("realidade_access") == "started"

CreateThread(function()
    Wait(1000)
    ensureVipTable()

    -- A vRP pode terminar de carregar os exports de grupos alguns instantes depois.
    for _ = 1, 10 do
        if ensureVipGroup() then break end
        Wait(1000)
    end

    -- Remove imediatamente VIPs que expiraram enquanto o resource estava parado.
    local expired = exports.oxmysql:query_async(
        "SELECT user_id FROM temporary_vips WHERE expiration_date <= NOW()",
        {}
    ) or {}
    for _, row in ipairs(expired) do
        expireVip(row.user_id, true)
    end

    Wait(4000)
    discordAuthEnabled = GetResourceState("realidade_access") == "started"
end)

CreateThread(function()
    while true do
        Wait(60 * 1000)
        local expired = exports.oxmysql:query_async(
            "SELECT user_id FROM temporary_vips WHERE expiration_date <= NOW()",
            {}
        ) or {}

        for _, row in ipairs(expired) do
            expireVip(row.user_id, true)
        end
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == "realidade_access" then
        discordAuthEnabled = false
        for _, player in pairs(GetPlayers()) do
            if Player(player).state.waitDiscordAuth then
                local user_id = vRP.getUserId(player)
                if user_id then
                    local rows = vRP.query("vRP/get_controller", { user_id = user_id }) or false
                    if rows and rows[1] and rows[1].controller ~= nil then
                        Player(player).state:set("waitDiscordAuth", false)
                        processSpawnController(player, rows[1].controller, user_id)
                    end
                else
                    DropPlayer(player, "Relogando...")
                end
            end
        end
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == "realidade_access" then
        discordAuthEnabled = true
    end
end)

AddEventHandler("realidade_access:authorized", function(user_id, playerSource, first_spawn)
    if not first_spawn then return end
    local rows = vRP.query("vRP/get_controller", { user_id = user_id }) or false
    if rows and rows[1] and rows[1].controller ~= nil then
        processSpawnController(playerSource, rows[1].controller, user_id)
    end
end)

AddEventHandler("vRP:playerSpawn", function(user_id, playerSource, first_spawn)
    CreateThread(function()
        Wait(1000)
        reconcileVip(user_id)
    end)

    if discordAuthEnabled then return end
    if first_spawn then
        local rows = vRP.query("vRP/get_controller", { user_id = user_id }) or false
        if rows and rows[1] and rows[1].controller ~= nil then
            processSpawnController(playerSource, rows[1].controller, user_id)
        end
    end
end)

RegisterCommand("resetplayer", function(playerSource, args)
    if playerSource == 0 then
        print("[vrp_creator] O comando /resetplayer deve ser usado por um staff dentro do servidor.")
        return
    end

    local staffId = vRP.getUserId(playerSource)
    if not staffId or not vRP.hasPermission(staffId, "admin.permissao") then
        notify(playerSource, "negado", "Você não possui permissão para usar este comando.", 5)
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        notify(playerSource, "negado", "Use: /resetplayer ID", 5)
        return
    end

    local targetSource = vRP.getUserSource(targetId)
    if not targetSource then
        notify(playerSource, "negado", "O player informado não está online.", 5)
        return
    end

    if inCreator[targetId] then
        notify(playerSource, "negado", "Este player já está na criação de personagem.", 5)
        return
    end

    local confirmed = vRP.request(
        playerSource,
        ('Você deseja mesmo resetar o player com ID "%s"?'):format(targetId),
        30
    )

    if not confirmed then
        return
    end

    local ok, message = startCharacterReset(targetId, staffId, "comando_resetplayer")
    if ok then
        notify(playerSource, "sucesso", ("O personagem do ID %s foi enviado para recriação."):format(targetId), 6)
        if targetSource ~= playerSource then
            notify(targetSource, "importante", "Seu personagem foi resetado por um administrador. Refaça sua aparência.", 7)
        end
    else
        notify(playerSource, "negado", message or "Não foi possível resetar este player.", 6)
    end
end)

RegisterCommand("verroupas", function(playerSource)
    local user_id = vRP.getUserId(playerSource)
    if user_id then
        local clothes = vRPclient.getCustom(playerSource)
        if clothes then
            vRP.prompt(playerSource, "Código da Roupa", json.encode(clothes))
        end
    end
end)

AddEventHandler("vRP:playerLeave", function(user_id)
    WhitelistPending[user_id] = nil
    userlogin[user_id] = nil
    inCreator[user_id] = nil
end)

CreateThread(function()
    while true do
        for user_id, playerSource in pairs(WhitelistPending) do
            local bucket = GetPlayerRoutingBucket(playerSource)
            if bucket == 0 then
                if vRP.isWhitelisted(user_id) then
                    WhitelistPending[user_id] = nil
                else
                    SetPlayerRoutingBucket(playerSource, playerSource)
                    print("UID: " .. user_id .. " | PULANDO WL (bucket: " .. bucket .. ")")
                    TriggerEvent("AC:ForceBan", playerSource, {
                        reason = "SKIP_WL_3",
                        additionalData = "Pulou Whitelist!",
                        forceBan = true,
                    })
                end
            end
        end
        Wait(5000)
    end
end)
