cfg = {}

cfg.open = "F2"
cfg.maxBillingValue = 500000
cfg.reviveReward = 1500
cfg.objectClearRadius = 30.0
cfg.maxPlacedObjects = 150
cfg.maxObjectsPerOfficer = 25

cfg.blockedFullRepairModels = {
    "wrarmoredcayenne",
    "wrarmoredm3g80c",
    "wrarmoredm5",
    "wrarmoredmacan",
    "wrarmoredrs7",
    "wrarmoredx7m60i",
    "wrbb64"
}

cfg.permissions = {
    medic = "perm.unizk",
    mecanic = "perm.mecanica",
    police = "perm.policia"
}

cfg.roleInfo = {
    medic = {
        title = "HOSPITAL",
        subtitle = "Atendimento e suporte médico",
        accent = "#ef476f"
    },
    mecanic = {
        title = "MECÂNICA",
        subtitle = "Reparos e atendimento veicular",
        accent = "#f6ad55"
    },
    police = {
        title = "DEPARTAMENTO POLICIAL",
        subtitle = "Ações operacionais e abordagem",
        accent = "#4ea8ff"
    }
}

-- Avisos públicos dos setores. O visual é renderizado pela própria NUI do
-- m_aux, então funciona mesmo com o painel F2 fechado.
cfg.announcements = {
    medic = {
        title = "AVISO HOSPITAL",
        accent = "#ef476f",
        prompt = "Mensagem do hospital:",
        duration = 15,
        cooldown = 120,
        maxLength = 300
    },
    mecanic = {
        title = "AVISO MECÂNICA",
        accent = "#f6ad55",
        prompt = "Mensagem da mecânica:",
        duration = 15,
        cooldown = 120,
        maxLength = 300,
        -- Mantém a regra que já existia no resource antigo.
        permission = "perm.avisomc"
    },
    police = {
        title = "AVISO POLICIA",
        accent = "#4ea8ff",
        prompt = "Mensagem da polícia:",
        duration = 15,
        cooldown = 120,
        maxLength = 300
    }
}

cfg.table = {
    medic_options = {
        {
            nome = "Tratamento Rápido",
            descricao = "Aplica tratamento gradual ao cidadão mais próximo.",
            quantidade_de_vida = 290,
            valor_tratamento = 1500,
            valor_fixo = false,
            pede_valor = true,
            func_ = "quick_treatment",
            icon = "medical"
        },
        {
            nome = "Tratamento Completo",
            descricao = "Recupera o cidadão até a vida máxima configurada.",
            quantidade_de_vida = 400,
            valor_tratamento = 3000,
            valor_fixo = false,
            pede_valor = true,
            func_ = "complete_treatment",
            icon = "heart"
        },
        {
            nome = "Reanimar",
            descricao = "Reanima o cidadão em coma que estiver próximo.",
            func_ = "revive",
            icon = "revive"
        },
        {
            nome = "Colocar na ambulância",
            descricao = "Coloca o cidadão próximo no veículo mais próximo.",
            func_ = "m_cv",
            icon = "vehicle"
        },
        {
            nome = "Retirar da ambulância",
            descricao = "Retira o cidadão próximo do veículo.",
            func_ = "m_rv",
            icon = "exit"
        },
        {
            nome = "Aviso Hospital",
            descricao = "Publica um aviso oficial do hospital para toda a cidade.",
            func_ = "m_aviso",
            icon = "announce"
        }
    },

    mecanic_options = {
        {
            nome = "Reparar Motor",
            descricao = "Restaura o funcionamento do motor do veículo próximo.",
            func_ = "r_motor",
            icon = "engine"
        },
        {
            nome = "Reparar Pneus",
            descricao = "Consome 1 pneu e restaura todos os pneus do veículo.",
            func_ = "r_pneu",
            icon = "tire"
        },
        {
            nome = "Reparo Completo",
            descricao = "Restaura motor, lataria e condições gerais do veículo.",
            func_ = "r_full",
            icon = "repair"
        },
        {
            nome = "Cobrar",
            descricao = "Envia uma cobrança ao cidadão mais próximo.",
            pede_valor = true,
            func_ = "r_cobrar",
            icon = "money"
        },
        {
            nome = "Aviso Mecânica",
            descricao = "Publica um aviso oficial da mecânica para toda a cidade.",
            func_ = "r_avisomec",
            icon = "announce"
        }
    },

    police_options = {
        {
            nome = "Aviso Polícia",
            descricao = "Publica um aviso oficial da polícia para toda a cidade.",
            func_ = "p_aviso",
            icon = "announce"
        },
        {
            nome = "Apreender Itens Ilegais",
            descricao = "Revista o cidadão mais próximo e remove itens configurados como ilegais.",
            func_ = "apdr_itens",
            icon = "seize"
        },
        {
            nome = "Deter Veículo",
            descricao = "Apreende o veículo próximo e registra o status no banco.",
            func_ = "detido",
            icon = "tow"
        },
        {
            nome = "Puxar Placa",
            descricao = "Consulta o proprietário e os dados vinculados à placa próxima.",
            func_ = "plate",
            icon = "plate"
        },
        {
            nome = "Puxar RG",
            descricao = "Consulta os dados do cidadão mais próximo.",
            func_ = "p_rg",
            icon = "id"
        },
        {
            nome = "Colocar na Viatura",
            descricao = "Coloca o cidadão próximo no banco de passageiro do veículo.",
            func_ = "p_cv",
            icon = "vehicle"
        },
        {
            nome = "Retirar da Viatura",
            descricao = "Retira o cidadão próximo do veículo.",
            func_ = "p_rv",
            icon = "exit"
        },
        {
            nome = "Retirar Máscara",
            descricao = "Remove a máscara do cidadão mais próximo.",
            func_ = "p_rmsc",
            icon = "mask"
        },
        {
            nome = "Cone",
            descricao = "Posicione um cone em 3D, movendo e girando antes de confirmar.",
            func_ = "p_cone",
            placement = "cone",
            icon = "cone"
        },
        {
            nome = "Pregos / Spike",
            descricao = "Posicione uma faixa de pregos funcional que fura pneus.",
            func_ = "p_spike",
            placement = "spike",
            icon = "spike"
        },
        {
            nome = "Barreira",
            descricao = "Posicione uma barreira operacional em 3D.",
            func_ = "p_barrier",
            placement = "barrier",
            icon = "barrier"
        },
        {
            nome = "Remover Objeto Próximo",
            descricao = "Remove o objeto operacional mais próximo colocado por este painel.",
            func_ = "p_removeobject",
            icon = "remove"
        },
        {
            nome = "Limpar Área",
            descricao = "Remove objetos operacionais colocados pelo painel em um raio de 30 metros.",
            func_ = "p_cleararea",
            icon = "clear"
        }
    }
}

cfg.policeObjects = {
    cone = {
        label = "Cone",
        model = "prop_roadcone02a",
        groundOffset = 0.0
    },
    spike = {
        label = "Faixa de Pregos",
        model = "p_ld_stinger_s",
        groundOffset = 0.02
    },
    barrier = {
        label = "Barreira",
        model = "prop_mp_barrier_02b",
        groundOffset = 0.0
    }
}

-- Lista compatível com o inventário atual. Entradas antigas também ficam aqui
-- para não deixar itens legados escaparem da apreensão.
cfg.illegalItems = {
    "dirty_money", "dinheirosujo", "maconha", "cocaina", "lsd", "lockpick", "acido", "acidoc",
    "pacote_componentes", "componenteq", "capuz", "algemas", "adubo", "capsulas", "polvora",
    "tecido", "placa-metal", "placa-clonada", "gatilho", "relogioroubado", "pulseiraroubada",
    "colarroubado", "brincoroubado", "anelroubado", "perfumeroubado", "carteiraroubada",
    "tabletroubado", "keycard", "cartaovirgem", "pendrive", "papel", "ticket", "ticketcorrida",
    "c4", "contador", "linha", "pecadearma",

    "weapon_snspistol_mk2", "ammo_snspistol_mk2", "weapon_pistol_mk2", "ammo_pistol_mk2",
    "weapon_gusenberg", "ammo_gusenberg", "weapon_pistol50", "ammo_pistol50", "weapon_hatchet",
    "weapon_combatpistol", "ammo_combatpistol", "weapon_combatpdw", "ammo_combatpdw",
    "weapon_machinepistol", "ammo_machinepistol", "weapon_smg_mk2", "ammo_smg_mk2",
    "weapon_smg", "ammo_smg", "weapon_assaultsmg", "ammo_assaultsmg",
    "weapon_sawnoffshotgun", "ammo_sawnoffshotgun", "weapon_pumpshotgun_mk2", "ammo_pumpshotgun_mk2",
    "weapon_assaultrifle_mk2", "ammo_assaultrifle_mk2", "weapon_specialcarbine_mk2", "ammo_specialcarbine_mk2",
    "weapon_carbinerifle", "ammo_carbinerifle", "weapon_specialcarbine", "ammo_specialcarbine",
    "weapon_petrolcan", "ammo_petrolcan"
}
