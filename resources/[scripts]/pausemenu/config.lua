Config = {
    websiteUrl = 'https://seusite/',
    
    Info = {
        main = {
            name = function(user_id, source, identity) 
                return identity.nome .. " " .. identity.sobrenome
            end,

            genre = function(user_id, source) 
                return (GetEntityModel(GetPlayerPed(source)) == GetHashKey('mp_m_freemode_01') and "HOMEM" or "MULHER")
            end,

            image = function(user_id, source)
                --local rows = vRP.query("identity/getImagem", { user_id = user_id })
 
                return "nao-encontrado.png" --[[ (#rows > 0 and rows[1].avatarURL or "nao-encontrado.png" ) ]]
            end,

            wallet = function(user_id, source) 
                return vRP.getMoney(user_id)
            end,

            bank = function(user_id, source) 
                return vRP.getBankMoney(user_id)
            end,
        },

        others = {
            ['VIP'] = function(user_id, source, identity) 
                local Vips = { -- Coloque aqui o nome do seus VIPS
                    "Bronze",
                    "Prata",
                    "Ouro",
                    "Platina",
                }

                local FormatVips = {}
                for index in pairs(Vips) do
                    if vRP.hasGroup(user_id, Vips[index]) then
                        FormatVips[#FormatVips + 1] = Vips[index]
                    end
                end           

                return (#FormatVips == 0 and "Nenhum" or FormatVips)
            end,
    
            ['TRABALHO'] = function(user_id, source, identity) 
                return vRP.getUserGroupByType(user_id, "job")
            end,
    
            ['IDENTIDADE'] = function(user_id, source, identity) 
                return identity.registro or "Nenhum"
            end,
    
            ['IDADE'] = function(user_id, source, identity) 
                return identity.idade
            end,
    
            ['TELEFONE'] = function(user_id, source, identity) 
                return identity.telefone
            end,
        }
    },

    Social = { -- REDES SOCIAIS
        ['INSTAGRAM'] = {
            active = true,
            url = 'https://www.instagram.com/seuinstagram/', -- LINK QUE SERA REDERICIONADO APOS CLICAR
            image = 'images/instagram.svg'
        },

        ['TIKTOK'] = {
            active = true,
            url = 'https://www.tiktok.com/@seutiktok', -- LINK QUE SERA REDERICIONADO APOS CLICAR
            image = 'images/tiktok.svg'
        },

        ['SITE VIP'] = {
            active = true,
            url = 'https://seusite/', -- LINK QUE SERA REDERICIONADO APOS CLICAR
            image = 'images/donate.svg'
        },

        ['DISCORD'] = {
            active = true,
            url = 'https://discord.gg/seudiscord', -- LINK QUE SERA REDERICIONADO APOS CLICAR
            image = 'images/discord.svg'
        }
    },

    Status = {
        func = vRP.getUsersByPermission, -- SUA FUNCAO DE CONTAR AS PERMISSOES

        list = {
            ['Policiais'] = "policia.permissao",
            ['Ilegal'] = "ilegal.permissao",
            ['Mecanicos'] = "mecanicostatus.permissao",
            ['Paramedicos'] = "paramedicostatus.permissao",
            ['Bombeiros'] = "bombeirosstatus.permissao",
            ['Jornalistas'] = "jornalstatus.permissao",
            ['Motoristas'] = "uberstatus.permissao",
            ['Administradores'] = "staff.permissao",
        }
    }
}

if SERVER then
    vRP._prepare("identity/getImagem", "SELECT avatarURL from smartphone_instagram WHERE user_id = @user_id ")

    function Identity(user_id)
        return vRP.getUserIdentity(user_id)
    end

    function UserId(source)
        return vRP.getUserId(source)
    end
end