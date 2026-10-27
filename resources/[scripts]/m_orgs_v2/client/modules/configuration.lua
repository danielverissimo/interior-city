----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CALLBACKS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback('GetPermissions', function(data, cb)
    local permissions = vTunnel.getPermissions(data.roleEdit)
    local t = {}
    for perm, status in pairs(permissions) do
        if Config.defaultPermissions[perm] then
            t[perm] = {
                name = Config.defaultPermissions[perm].name,
                description = Config.defaultPermissions[perm].description,
                status = status
            }
        end
    end
    cb(t)
end)

RegisterNUICallback('SetPermissions', function(data, cb)
    local t = {}
    for perm, v in pairs(data.permissions) do
        t[perm] = v.status
    end

    cb(vTunnel.updatePermissions(data.role, t))
end)

RegisterNUICallback('SetConfig', function(data, cb)

    if (data.discord and not data.discord:find('https://')) then
        return print('Discord: Insira um URL Valido Insira um URL Valido Exemplo: https://discord.gg/MPm3Pptfn5.')
    end

    if (data.logo and not data.logo:find('https://')) then
        return print('Logo: Insira um URL Valido Exemplo: https://mirtin-store.com/imagem.png.')
    end

    cb(vTunnel.updateConfig(data))
end)

RegisterNUICallback('UpdateAvatar', function(data, cb)

    if (data.url and not data.url:find('https://')) then
        return print('Logo: Insira um URL Valido Exemplo: https://mirtin-store.com/imagem.png.')
    end

    cb(vTunnel.updateAvatar(data))
end)

RegisterNUICallback('SetRadio', function(data, cb)
    if (not tonumber(data.frequency)) then
        return print('Radio: Insira um Numero não uma STRING.')
    end

    cb(vTunnel.updateFrequency(data.frequency))
end)

RegisterNUICallback('SetPreset', function(data, cb)
    cb(vTunnel.updateSex(data))
end)