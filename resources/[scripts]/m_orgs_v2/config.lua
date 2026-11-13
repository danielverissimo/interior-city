Config = {}

Config.Main = {
    cmd = 'painelfac', -- Comando para abrir Painel
    cmdAdm = 'painelfacadm', -- Comando para abrir Painel ADM
    createAutomaticOrganizations = true,
    storeUrl = '', -- Link da Sua Loja
    serverLogo = "https://cdn.discordapp.com/attachments/995209318448238682/1441893036530339882/Logo_TocadoMago_Delux_Azul.png?ex=696b4cc8&is=6969fb48&hm=a4d86a5ad3073b94f2f404a47e7fa09cc04462822219e11a93bfd42a3ed93cf0&",
    blackList = 0,
    ImgLink = 'http://104.234.65.115/images/',
    clearChestLogs = 7 -- Dias para manter os logs de baú
}

Config.weebhooks = {
    Withdraw = (IsDuplicityVersion() and GetConvar("ic_secret_m_orgs_v2_webhook", GetConvar("interior_city_webhook_logs", "")) or ""),
    Deposit = (IsDuplicityVersion() and GetConvar("ic_secret_m_orgs_v2_webhook", GetConvar("interior_city_webhook_logs", "")) or ""),
}

Config.defaultPermissions = { 
    invite = { -- Permissao Para Convidar
        name = "Convidar",
        description = "Esta permissao permite vc convidar as pessoas para sua facção."
    },
    demote = { -- Permissao Para Rebaixar
        name = "Rebaixar",
        description = "Essa permissão permite que o cargo selecionado rebaixe um cargo inferior."
    }, 
    promote = { -- Permissao Para Promover
        name = "Promover",
        description = "Essa permissão permite que o cargo selecionado promova um cargo."
    }, 
    dismiss = { -- Permissao Para Rebaixar
        name = "Demitir",
        description = "Essa permissão permite que o cargo selecionado demita um cargo inferior."
    }, 
    withdraw = { -- Permissao Para Sacar Dinheiro
        name = "Sacar dinheiro",
        description = "Permite que esse cargo selecionado possa sacar dinheiro do banco da facção."
    }, 
    deposit = { -- Permissao Para Depositar Dinheiro
        name = "Depositar dinheiro",
        description = "Permite que esse cargo selecionado possa depositar dinheiro no banco da facção."
    }, 
    message = { -- Permissao para Escrever nas anotaçoes
        name = "Escrever anotações",
        description = "Permite que esse cargo selecionado possa escrever anotações."
    },
    alerts = { -- Permissao para enviar alertas
        name = "Escrever Alertas",
        description = "Permite que esse cargo selecionado possa enviar alertas para todos jogadores."
    },
    chat = { -- Permissao para Falar no chat
        name = "Escrever no chat",
        description = "Permite que esse cargo selecionado possa se comunicar no chat da facção"
    },
}

Config.ItemsTemplate = {
    armas = {
        ["pecadearma"] = 10,
    },
    municao = {
        ['money'] = 1000000,
        ["capsulas"] = 50,
        ["polvora"] = 50,
    },
    lavagem = {
        ['dirty_money'] = 1000000,
        ['l-alvejante'] = 50,
        ['money'] = 50,
    },
    drogasAzul = {
        ['anfetamina'] = 1000000,
        ['ferro'] = 1000000,
        ['aluminio'] = 1000000,
    },
    drogasVermelha = {
        ['morfina'] = 1000000,
        ['ferro'] = 1000000,
        ['aluminio'] = 1000000,
    },
    drogasPreta = {
        ['pastabase'] = 1000000,
        ['ferro'] = 1000000,
        ['aluminio'] = 1000000,
    },
    drogasAmarela = {
        ['podemd'] = 1000000,
        ['ferro'] = 1000000,
        ['aluminio'] = 1000000,
    },
    drogasVerde = {
        ['folhamaconha'] = 1000000,
        ['ferro'] = 1000000,
        ['aluminio'] = 1000000,
    },
    legal = {
        ['money'] = 1000000,
    }
}

Config.DefaultSallary = {
    active = false,
    amount = 2000,
    time = 30,
}
Config.Groups = {
    ['Mafia'] = {
        Config = {
            Salary = { -- SALARIO FAC
                active = false, -- Se vai esta ativo ou nao
                amount = 2000, -- Valor que vai receber
                time = 30, -- tempo em tempo que vai receber salario em minuto(s)
            },

            Goals = { -- METAS
                defaultReward = 300, -- Valor Padrão da recompensa ( obs Lider consegue alterar in-game )
                itens = {
                    ["pecadearma"] = 500,
                }
            }
        },

        List = {
            ['LiderMafia'] = {
                prefix = 'LiderMafia',
                tier = 1,
            },
            ['SubLiderMafia'] = {
                prefix = 'SubLiderMafia',
                tier = 2,
            },
            ['GerenteMafia'] = {
                prefix = 'GerenteMafia',
                tier = 3,
            },
            ['RecrutadorMafia'] = {
                prefix = 'GerenteMafia',
                tier = 6,
            },
            ['MembroMafia'] = {
                prefix = 'MembroMafia',
                tier = 7,
            },
            ['RecrutadorMafia'] = {
                prefix = 'RecrutadorMafia',
                tier = 8,
            },


        }
    },
    ['Cartel'] = {
        Config = {
            Salary = { -- SALARIO FAC
                active = false, -- Se vai esta ativo ou nao
                amount = 2000, -- Valor que vai receber
                time = 30, -- tempo em tempo que vai receber salario em minuto(s)
            },

            Goals = { -- METAS
                defaultReward = 300, -- Valor Padrão da recompensa ( obs Lider consegue alterar in-game )
                itens = {
                    ["capsulas"] = 500,
                }
            }
        },

        List = {
            ['LiderCartel'] = {
                prefix = 'LiderCartel',
                tier = 1,
            },
            ['SubLiderCartel'] = {
                prefix = 'SubLiderCartel',
                tier = 2,
            },
            ['GerenteCartel'] = {
                prefix = 'GerenteCartel',
                tier = 3,
            },
            ['RecrutadorCartel'] = {
                prefix = 'GerenteCartel',
                tier = 6,
            },
            ['MembroCartel'] = {
                prefix = 'MembroCartel',
                tier = 7,
            },
            ['RecrutadorCartel'] = {
                prefix = 'RecrutadorCartel',
                tier = 8,
            },


        }
    },
    ['Motoclube'] = {
        Config = {
            Salary = { -- SALARIO FAC
                active = false, -- Se vai esta ativo ou nao
                amount = 2000, -- Valor que vai receber
                time = 30, -- tempo em tempo que vai receber salario em minuto(s)
            },

            Goals = { -- METAS
                defaultReward = 300, -- Valor Padrão da recompensa ( obs Lider consegue alterar in-game )
                itens = {
                    ["ferro"] = 500,
                }
            }
        },

        List = {
            ['LiderMotoclube'] = {
                prefix = 'LiderMotoclube',
                tier = 1,
            },
            ['SubLiderMotoclube'] = {
                prefix = 'SubLiderMotoclube',
                tier = 2,
            },
            ['GerenteMotoclube'] = {
                prefix = 'GerenteMotoclube',
                tier = 3,
            },
            ['RecrutadorMotoclube'] = {
                prefix = 'GerenteMotoclube',
                tier = 6,
            },
            ['MembroMotoclube'] = {
                prefix = 'MembroMotoclube',
                tier = 7,
            },
            ['RecrutadorMotoclube'] = {
                prefix = 'RecrutadorMotoclube',
                tier = 8,
            },


        }
    },
    ['Vanilla'] = {
        Config = {
            Salary = { -- SALARIO FAC
                active = false, -- Se vai esta ativo ou nao
                amount = 2000, -- Valor que vai receber
                time = 30, -- tempo em tempo que vai receber salario em minuto(s)
            },

            Goals = { -- METAS
                defaultReward = 300, -- Valor Padrão da recompensa ( obs Lider consegue alterar in-game )
                itens = {
                    ["l-alvejante"] = 500,
                }
            }
        },

        List = {
            ['LiderVanilla'] = {
                prefix = 'LiderVanilla',
                tier = 1,
            },
            ['SubLiderVanilla'] = {
                prefix = 'SubLiderVanilla',
                tier = 2,
            },
            ['GerenteVanilla'] = {
                prefix = 'GerenteVanilla',
                tier = 3,
            },
            ['RecrutadorVanilla'] = {
                prefix = 'GerenteVanilla',
                tier = 6,
            },
            ['MembroVanilla'] = {
                prefix = 'MembroVanilla',
                tier = 7,
            },
            ['RecrutadorVanilla'] = {
                prefix = 'RecrutadorVanilla',
                tier = 8,
            },


        }
    },
    ['Bahamas'] = {
        Config = {
            Salary = { -- SALARIO FAC
                active = false, -- Se vai esta ativo ou nao
                amount = 2000, -- Valor que vai receber
                time = 30, -- tempo em tempo que vai receber salario em minuto(s)
            },

            Goals = { -- METAS
                defaultReward = 300, -- Valor Padrão da recompensa ( obs Lider consegue alterar in-game )
                itens = {
                    ["l-alvejante"] = 500,
                }
            }
        },

        List = {
            ['LiderBahamas'] = {
                prefix = 'LiderBahamas',
                tier = 1,
            },
            ['SubLiderBahamas'] = {
                prefix = 'SubLiderBahamas',
                tier = 2,
            },
            ['GerenteBahamas'] = {
                prefix = 'GerenteBahamas',
                tier = 3,
            },
            ['RecrutadorBahamas'] = {
                prefix = 'GerenteBahamas',
                tier = 6,
            },
            ['MembroBahamas'] = {
                prefix = 'MembroBahamas',
                tier = 7,
            },
            ['RecrutadorBahamas'] = {
                prefix = 'RecrutadorBahamas',
                tier = 8,
            },


        }
    },
    ['Vermelhos'] = {
        Config = {
            Salary = { -- SALARIO FAC
                active = false, -- Se vai esta ativo ou nao
                amount = 2000, -- Valor que vai receber
                time = 30, -- tempo em tempo que vai receber salario em minuto(s)
            },

            Goals = { -- METAS
                defaultReward = 300, -- Valor Padrão da recompensa ( obs Lider consegue alterar in-game )
                itens = {
                    ["capsulas"] = 500,
                }
            }
        },

        List = {
            ['LiderVermelhos'] = {
                prefix = 'LiderVermelhos',
                tier = 1,
            },
            ['SubLiderVermelhos'] = {
                prefix = 'SubLiderVermelhos',
                tier = 2,
            },
            ['GerenteVermelhos'] = {
                prefix = 'GerenteVermelhos',
                tier = 3,
            },
            ['RecrutadorVermelhos'] = {
                prefix = 'GerenteVermelhos',
                tier = 6,
            },
            ['MembroVermelhos'] = {
                prefix = 'MembroVermelhos',
                tier = 7,
            },
            ['RecrutadorVermelhos'] = {
                prefix = 'RecrutadorVermelhos',
                tier = 8,
            },


        }
    },
    ['Verdes'] = {
        Config = {
            Salary = { -- SALARIO FAC
                active = false, -- Se vai esta ativo ou nao
                amount = 2000, -- Valor que vai receber
                time = 30, -- tempo em tempo que vai receber salario em minuto(s)
            },

            Goals = { -- METAS
                defaultReward = 300, -- Valor Padrão da recompensa ( obs Lider consegue alterar in-game )
                itens = {
                    ["pecadearma"] = 500,
                }
            }
        },

        List = {
            ['LiderVerdes'] = {
                prefix = 'LiderVerdes',
                tier = 1,
            },
            ['SubLiderVerdes'] = {
                prefix = 'SubLiderVerdes',
                tier = 2,
            },
            ['GerenteVerdes'] = {
                prefix = 'GerenteVerdes',
                tier = 3,
            },
            ['RecrutadorVerdes'] = {
                prefix = 'GerenteVerdes',
                tier = 6,
            },
            ['MembroVerdes'] = {
                prefix = 'MembroVerdes',
                tier = 7,
            },
            ['RecrutadorVerdes'] = {
                prefix = 'RecrutadorVerdes',
                tier = 8,
            },


        }
    },
    ['Franca'] = {
        Config = {
            Salary = { -- SALARIO FAC
                active = false, -- Se vai esta ativo ou nao
                amount = 2000, -- Valor que vai receber
                time = 30, -- tempo em tempo que vai receber salario em minuto(s)
            },

            Goals = { -- METAS
                defaultReward = 300, -- Valor Padrão da recompensa ( obs Lider consegue alterar in-game )
                itens = {
                    ["ferro"] = 500,
                }
            }
        },

        List = {
            ['LiderFranca'] = {
                prefix = 'LiderFranca',
                tier = 1,
            },
            ['SubLiderFranca'] = {
                prefix = 'SubLiderFranca',
                tier = 2,
            },
            ['GerenteFranca'] = {
                prefix = 'GerenteFranca',
                tier = 3,
            },
            ['RecrutadorFranca'] = {
                prefix = 'GerenteFranca',
                tier = 6,
            },
            ['MembroFranca'] = {
                prefix = 'MembroFranca',
                tier = 7,
            },
            ['RecrutadorFranca'] = {
                prefix = 'RecrutadorFranca',
                tier = 8,
            },


        }
    },
    ['Roxos'] = {
        Config = {
            Salary = { -- SALARIO FAC
                active = false, -- Se vai esta ativo ou nao
                amount = 2000, -- Valor que vai receber
                time = 30, -- tempo em tempo que vai receber salario em minuto(s)
            },

            Goals = { -- METAS
                defaultReward = 300, -- Valor Padrão da recompensa ( obs Lider consegue alterar in-game )
                itens = {
                    ["pastabase"] = 500,
                }
            }
        },

        List = {
            ['LiderRoxos'] = {
                prefix = 'LiderRoxos',
                tier = 1,
            },
            ['SubLiderRoxos'] = {
                prefix = 'SubLiderRoxos',
                tier = 2,
            },
            ['GerenteRoxos'] = {
                prefix = 'GerenteRoxos',
                tier = 3,
            },
            ['RecrutadorRoxos'] = {
                prefix = 'GerenteRoxos',
                tier = 6,
            },
            ['MembroRoxos'] = {
                prefix = 'MembroRoxos',
                tier = 7,
            },
            ['RecrutadorRoxos'] = {
                prefix = 'RecrutadorRoxos',
                tier = 8,
            },


        }
    },
    ['Laranjas'] = {
        Config = {
            Salary = { -- SALARIO FAC
                active = false, -- Se vai esta ativo ou nao
                amount = 2000, -- Valor que vai receber
                time = 30, -- tempo em tempo que vai receber salario em minuto(s)
            },

            Goals = { -- METAS
                defaultReward = 300, -- Valor Padrão da recompensa ( obs Lider consegue alterar in-game )
                itens = {
                    ["anfetamina"] = 500,
                }
            }
        },

        List = {
            ['LiderLaranjas'] = {
                prefix = 'LiderLaranjas',
                tier = 1,
            },
            ['SubLiderLaranjas'] = {
                prefix = 'SubLiderLaranjas',
                tier = 2,
            },
            ['GerenteLaranjas'] = {
                prefix = 'GerenteLaranjas',
                tier = 3,
            },
            ['RecrutadorLaranjas'] = {
                prefix = 'GerenteLaranjas',
                tier = 6,
            },
            ['MembroLaranjas'] = {
                prefix = 'MembroLaranjas',
                tier = 7,
            },
            ['RecrutadorLaranjas'] = {
                prefix = 'RecrutadorLaranjas',
                tier = 8,
            },


        }
    },
    ['Colombia'] = {
        Config = {
            Salary = { -- SALARIO FAC
                active = false, -- Se vai esta ativo ou nao
                amount = 2000, -- Valor que vai receber
                time = 30, -- tempo em tempo que vai receber salario em minuto(s)
            },

            Goals = { -- METAS
                defaultReward = 300, -- Valor Padrão da recompensa ( obs Lider consegue alterar in-game )
                itens = {
                    ["folhamaconha"] = 500,
                }
            }
        },

        List = {
            ['LiderColombia'] = {
                prefix = 'LiderColombia',
                tier = 1,
            },
            ['SubLiderColombia'] = {
                prefix = 'SubLiderColombia',
                tier = 2,
            },
            ['GerenteColombia'] = {
                prefix = 'GerenteColombia',
                tier = 3,
            },
            ['RecrutadorColombia'] = {
                prefix = 'GerenteColombia',
                tier = 6,
            },
            ['MembroColombia'] = {
                prefix = 'MembroColombia',
                tier = 7,
            },
            ['RecrutadorColombia'] = {
                prefix = 'RecrutadorColombia',
                tier = 8,
            },


        }
    },
}

Config.Langs = {
    ['offlinePlayer'] = function(source) TriggerClientEvent("Notify", source,"negado","Este jogador não está online.",5000) end,
    ['alreadyFaction'] = function(source) TriggerClientEvent("Notify", source,"negado","Este jogador já esta em uma organização.",5000)  end,
    ['alreadyBlacklist'] = function(source) TriggerClientEvent("Notify", source,"negado","Você está na black-list, não pode receber convites.",5000)  end,
    ['alreadyUserBlacklist'] = function(source) TriggerClientEvent("Notify",source,"negado","Este jogador está em black-list.",5000)  end,
    ['sendInvite'] = function(source) TriggerClientEvent("Notify",source,"sucesso","Você enviou o convite.",5000)  end,
    ['acceptInvite'] = function(source) TriggerClientEvent("Notify",source,"sucesso","Você aceitou o convite.",5000) end,
    ['acceptedInvite'] = function(source, ply_id) TriggerClientEvent("Notify",source,"sucesso","O "..ply_id.." aceitou o convite. ",5000) end,
    ['bestTier'] = function(source) TriggerClientEvent("Notify",source,"negado","Você não pode fazer isso com alguem com um cargo igual ou maior que o seu.",5000)   end,
    ['youPromoved'] = function(source) TriggerClientEvent("Notify",source,"sucesso","Você foi promovido.",5000)  end,
    ['youPromovedUser'] = function(source, ply_id, group) TriggerClientEvent("Notify",source,"sucesso","Você promoveu o ID: "..ply_id.." para "..group..".",5000) end,
    ['youDemote'] = function(source) TriggerClientEvent("Notify",source,"sucesso","Você foi rebaixado.",5000)  end,
    ['youDemoteUser'] = function(source, ply_id, group) TriggerClientEvent("Notify",source,"sucesso","Você rebaixou o ID: "..ply_id.." para ".. group ..".",5000) end,
    ['youDismiss'] = function(source) TriggerClientEvent("Notify",source,"sucesso","Você foi demitido de sua organização .",5000)  end,
    ['youDismissUser'] = function(source, ply_id) TriggerClientEvent("Notify", source,"sucesso","Você demitiu o ID "..ply_id.." .",5000)  end,
    ['waitCooldown'] = function(source) TriggerClientEvent("Notify",source,"negado","Aguarde para fazer isso..",5000) end,
    ['bankNotMoney'] = function(source) TriggerClientEvent("Notify",source,"negado","O Banco da organização não possui essa quantia.",5000)  end,
    ['rewardedGoal'] = function(source, amount) TriggerClientEvent("Notify",source,"sucesso","Você resgatou sua meta diaria e recebeu <b>R$ "..amount.."</b> por isso.",5000) end,
    ['notPermission'] = function(source) TriggerClientEvent("Notify",source,"negado","Você não possui permissão.",5000)  end,
    ['notMoneyDeposit'] = function(source) TriggerClientEvent("Notify",source,"negado","Você não possui dinheiro para depositar.",5000)  end

}

if SERVER then
    -- CUSTOM QUERYS
    vRP.prepare('m_orgs_v2/GetUsersGroup', " SELECT user_id,dvalue FROM vrp_user_data WHERE dkey = 'vRP:datatable' ")
    vRP.prepare("m_orgs_v2/getUserGroup", "SELECT user_id,dvalue FROM vrp_user_data WHERE dkey = 'vRP:datatable' and user_id = @user_id")
    vRP.prepare("m_orgs_v2/updateUserGroup", "UPDATE vrp_user_data SET dvalue = @dvalue WHERE user_id = @user_id and dkey = 'vRP:datatable'")

    -- CAPTURAR GRUPOS COM JOGADOR OFFLINE
    function getUserGroups(user_id)
        local rows = vRP.query("m_orgs_v2/getUserGroup", { user_id = user_id })
        local data = json.decode(rows[1].dvalue) or {}

        if #rows == 0 then 
            return 
        end

        return data.groups
    end

    -- SETAR GRUPO COM JOGADOR OFFLINE
    function updateUserGroups(user_id, groups)
        local rows = vRP.query("m_orgs_v2/getUserGroup", { user_id = user_id })
        local data = json.decode(rows[1].dvalue) or {}

        if #rows == 0 then 
            return 
        end

        if not groups then
            groups = {}
        end

        data.groups = groups

        vRP.execute("m_orgs_v2/updateUserGroup", { user_id = user_id, dvalue = json.encode(data) })
    end

    -- PEGAR DINHEIRO DO BANCO DO JOGADOR
    function getBankMoney(user_id)
        return vRP.getBankMoney(user_id)
    end

    -- IDENTIDADE
function getUserIdentity(user_id)
    if not user_id then
        return nil
    end

    local identity = vRP.getUserIdentity(user_id)
    if not identity then
        return nil
    end

    -- Compatibilidade com nomes diferentes
    if identity.nome then
        identity.name = identity.nome
        identity.firstname = identity.sobrenome
    end

    if identity.name2 then
        identity.firstname = identity.name2
    end

    return identity
end


    function getUserSource(user_id)
        return vRP.getUserSource(user_id)
    end

    function getUserId(source)
        return vRP.getUserId(source)
    end

    function getUsers()
        --user_id,source
        return vRP.getUsers()
    end

    function getUserMyGroups(user_id)
        return vRP.getUserGroups(user_id)
    end

    function hasGroup(user_id, group)
        return vRP.hasGroup(user_id, group)
    end

    function addUserGroup(user_id, group)
        return vRP.addUserGroup(user_id, group)
    end

    function tryFullPayment(user_id, amount)
        return vRP.tryFullPayment(user_id, amount)
    end

    function giveBankMoney(user_id, amount)
        if user_id and amount and tonumber(amount) then 
            return vRP.giveBankMoney(user_id, amount)
        end
    end

    function getBankMoney(user_id)
        return vRP.getBankMoney(user_id)
    end

    function getItemName(item)
        return vRP.getItemName(item) or item
    end

    function request(source, text, time)
        return vRP.request(source, text, time)
    end

    function removeUserGroup(user_id, group)
        return vRP.removeUserGroup(user_id, group)
    end

    -- REMOVER BLACKLIST
    RegisterCommand('blacklist', function(source,args)
        local user_id = getUserId(source)
        if not user_id then return end

        local ply_id = tonumber(args[1])
        if not ply_id then return end

        if vRP.hasPermission(user_id,"admin.permissao") then
            TriggerClientEvent("Notify", source, "sucesso","Você removeu a blacklist do ID: "..ply_id..".",5000) 
            BLACKLIST:remUser(ply_id)
        end
    end)

    AddEventHandler('vRP:playerSpawn', function(user_id, source)
        TriggerEvent('m_orgs_v2:playerSpawn', user_id, source)
    end)

    AddEventHandler('vRP:playerLeave', function(user_id)
        TriggerEvent('m_orgs_v2:playerLeave', user_id)
    end)
end


--[[ 
    Como Utilizar EXPORT de Guardar / Retirar Item no Bau:
    ( Colocar Esse EXPORT na função de retirar/guardar item de seu inventario)
    
    user_id: user_id, -- ID Do Jogador,
    action: withdraw or deposit, -- Ação que foi feita Retirou/Depositou
    item: item, -- Spawn do item que foi retirado/guardado.
    amount: quantidade, -- Quantidade do item que foi depositada/retirada

    EXPORT: 
    exports.m_orgs_v2:addLogChest(user_id, action, item, amount)
]]

--[[ 
    Como Utilizar EXPORT De METAS DIARIAS:
    ( Colocar esse EXPORT na função de Guardar Itens no Armazem ou Coletar Itens no Farm )

    user_id: user_id, -- ID Do Jogador,
    item: item, -- Spawn do item que foi guardado/farmado.
    amount: quantidade, -- Quantidade do item que foi guardada/farmada.

    EXPORT: 
    exports.m_orgs_v2:addGoal(user_id, item, amount)
]]