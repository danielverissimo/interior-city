Config = {}

Config.StaffPermissions = {
    'developer.permissao'
}

Config.mainCommand = 'mdt'
Config.staffCommand = 'mdtadm'

Config.Webhooks = {
    contract = GetConvar("ic_secret_m_mdt_webhook", GetConvar("interior_city_webhook_logs", "")),
    demote = GetConvar("ic_secret_m_mdt_webhook", GetConvar("interior_city_webhook_logs", "")),
    promote = GetConvar("ic_secret_m_mdt_webhook", GetConvar("interior_city_webhook_logs", "")),
    dismiss = GetConvar("ic_secret_m_mdt_webhook", GetConvar("interior_city_webhook_logs", "")),
    prison = GetConvar("ic_secret_m_mdt_webhook", GetConvar("interior_city_webhook_logs", "")),
    arrestVehicles = GetConvar("ic_secret_m_mdt_webhook", GetConvar("interior_city_webhook_logs", "")),
    fine = GetConvar("ic_secret_m_mdt_webhook", GetConvar("interior_city_webhook_logs", "")),
}

Config.prisonCoord = vec3(1716.85,2525.78,45.54)
Config.releaseCoord = vec3(1848.0,2585.86,45.66)
Config.inviteReward = 50000

Config.prisonClothes = {
    ['mp_m_freemode_01'] = {
        {0,0,0}, {0,209,0}, {0,15,0}, {34,0,706}, {0,0,0}, {0,0,-1}, {-1,-1,-1}, {-1,-1,-1}, {-1,-1,-1}, {-1,-1,-1}
    },
    ['mp_f_freemode_01'] = {
        {0,0,0}, {0,207,0}, {14,0,294}, {35,0,821}, {0,0,0}, {0,0,-1}, {-1,-1,-1}, {-1,-1,-1}, {-1,-1,-1}, {-1,-1,-1}
    },
}

Config.ArrestLocations = {
    { coordinate = vec3(-412.77,1085.16,323.85), range = 80.0 }, --cadeia investigativa
    { coordinate = vec3(-2314.47,346.05,178.57), range = 80.0 }, -- CADEIA POLICIA MILITAR
    { coordinate = vec3(1691.15,2452.12,45.83), range = 80.0 },-- CADEIA POLICIA prf
    { coordinate = vec3(2622.84, 5271.62, 45.48), range = 80.0 },
    { coordinate = vec3(-2049.42, -456.93, 8.58), range = 80.0 },
    { coordinate = vec3(-1665.53, 183.87, 61.77), range = 80.0 },
    { coordinate = vec3(607.34, -7.91, 82.78), range = 80.0 },
    { coordinate = vec3(2507.98, -352.15, 105.68), range = 80.0 },
    { coordinate = vec3(482.13, -1165.64, 30.97), range = 80.0 },
    { coordinate = vec3(487.64, -1166.22, 30.97), range = 80.0 },
    { coordinate = vec3(353.87, -1606.78, 29.28), range = 80.0 },
    { coordinate = vec3(-2020.6, 3209.64, 32.84), range = 80.0 },
    { coordinate = vec3(-2019.32, 3210.26, 32.84), range = 80.0 },
    { coordinate = vec3(-2626.37, 2651.35, 17.3), range = 80.0 },
    { coordinate = vec3(456.57, -986.69, 34.2), range = 80.0 },
    { coordinate = vec3(-785.97, -1212.14, 3.56), range = 80.0 },
    { coordinate = vec3(-2626.02, 2652.1, 17.3), range = 80.0 },
    { coordinate = vec3(-1687.42, -765.41, 7.06), range = 80.0 },
    { coordinate = vec3(-804.06,-1356.58,5.16), range = 80.0 },
    { coordinate = vec3(-702.11,-1288.93,5.39), range = 80.0 },
    { coordinate = vec3(455.27,-986.95,34.2), range = 15.0 },
    { coordinate = vec3(-2062.66,3222.88,32.96), range = 80.0 },
    { coordinate = vec3(-556.0,-596.07,30.43), range = 80.0 },
     { coordinate = vec3(440.48,-982.94,30.68), range = 80.0 },
}

Config.crimes = {
    {
        name = "Abuso de Autoridade",
        fine = 300000,
        bail = 0,
        mounths = 50,
    },
    {
        name = "Corrupção Passiva e/ou Ativa",
        fine = 300000,
        bail = 0,
        mounths = 50,
    },
    {
        name = "Desacato",
        fine = 300000,
        bail = 0,
        mounths = 30,
    },
    {
        name = "Impedir Exercício Profissional",
        fine = 150000,
        bail = 300000,
        mounths = 20,
    },
    {
        name = "Prevaricação",
        fine = 300000,
        bail = 0,
        mounths = 50,
    },
    {
        name = "Prisão Disciplinar",
        fine = 100000,
        bail = 0,
        mounths = 30,
    },
    {
        name = "Tráfico de Influência",
        fine = 150000,
        bail = 300000,
        mounths = 30,
    },
    {
        name = "Uso irregular de Função Pública",
        fine = 300000,
        bail = 0,
        mounths = 30,
    },
    {
        name = "Tentativa de Homicídio",
        fine = 200000,
        bail = 0,
        mounths = 30,
    },
    {
        name = "Homicídio Culposo",
        fine = 300000,
        bail = 0,
        mounths = 30,
    },
    {
        name = "Homicídio Doloso",
        fine = 300000,
        bail = 0,
        mounths = 40,
    },
    {
        name = "Homicídio Qualificado",
        fine = 400000,
        bail = 0,
        mounths = 50,
    },
    {
        name = "Latrocínio",
        fine = 400000,
        bail = 0,
        mounths = 60,
    },
    {
        name = "Assédio Moral",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Calúnia",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Difamação",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Injúria",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Importunação Sexual",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Perjúrio",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Abandono de Incapaz",
        fine = 200000,
        bail = 0,
        mounths = 100,
    },
    {
        name = "Adultério",
        fine = 200000,
        bail = 2000000,
        mounths = 50,
    },
    {
        name = "Bigamia",
        fine = 200000,
        bail = 2000000,
        mounths = 50,
    },
    {
        name = "Crime Sexual Intrafamiliar",
        fine = 200000,
        bail = 2000000,
        mounths = 50,
    },
    {
        name = "Ameaça",
        fine = 100000,
        bail = 200000,
        mounths = 20,
    },
    {
        name = "Extorsão",
        fine = 50000,
        bail = 100000,
        mounths = 10,
    },
    {
        name = "Lesão Corporal",
        fine = 100000,
        bail = 200000,
        mounths = 20,
    },
    {
        name = "Sequestro",
        fine = 200000,
        bail = 0,
        mounths = 30,
    },
    {
        name = "Tortura",
        fine = 400000,
        bail = 0,
        mounths = 50,
    },
    {
        name = "Vandalismo",
        fine = 50000,
        bail = 100000,
        mounths = 10,
    },
    {
        name = "Dano de Propriedade do Governo",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Estelionato",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Invasão de Propriedade",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Furto",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Roubo",
        fine = 150000,
        bail = 300000,
        mounths = 20,
    },
    {
        name = "Posse de Produtos Ilegais",
        fine = 50000,
        bail = 100000,
        mounths = 10,
    },
    {
        name = "Tráfico de Produtos Ilegais",
        fine = 100000,
        bail = 200000,
        mounths = 30,
    },
    {
        name = "Posse de Peças de Armas",
        fine = 0,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Posse de Cápsula",
        fine = 0,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Porte de Arma Leve",
        fine = 100000,
        bail = 200000,
        mounths = 20,
    },
    {
        name = "Tráfico de Armas Leve",
        fine = 300000,
        bail = 0,
        mounths = 40,
    },
    {
        name = "Porte de Arma Pesada",
        fine = 200000,
        bail = 400000,
        mounths = 30,
    },
    {
        name = "Tráfico de Armas Pesada",
        fine = 400000,
        bail = 0,
        mounths = 50,
    },
    {
        name = "Porte de Arma Branca",
        fine = 100000,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Porte de Munição (-100)",
        fine = 100000,
        bail = 200000,
        mounths = 20,
    },
    {
        name = "Tráfico de Munição (+100)",
        fine = 200000,
        bail = 400000,
        mounths = 30,
    },
    {
        name = "Posse de Componentes Narcóticos",
        fine = 0,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Posse de Drogas (-100)",
        fine = 100000,
        bail = 200000,
        mounths = 20,
    },
    {
        name = "Tráfico de Drogas (+100)",
        fine = 150000,
        bail = 300000,
        mounths = 30,
    },
    {
        name = "Venda de drogas",
        fine = 150000,
        bail = 300000,
        mounths = 30,
    },
    {
        name = "Dinheiro Sujo Leve",
        fine = 50000,
        bail = 100000,
        mounths = 10,
    },
    {
        name = "Dinheiro Sujo Médio",
        fine = 150000,
        bail = 300000,
        mounths = 20,
    },
    {
        name = "Dinheiro Sujo Grave",
        fine = 300000,
        bail = 600000,
        mounths = 30,
    },
    {
        name = "Apologia ao Crime",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Falsidade Ideológica",
        fine = 200000,
        bail = 400000,
        mounths = 30,
    },
    {
        name = "Formação de Quadrilha",
        fine = 200000,
        bail = 400000,
        mounths = 30,
    },
    {
        name = "Desobediência",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Exercício Ilegal de Profissão",
        fine = 200000,
        bail = 400000,
        mounths = 10,
    },
    {
        name = "Falsa Comunicação de Crime",
        fine = 50000,
        bail = 100000,
        mounths = 10,
    },
    {
        name = "Obstrução de Justiça",
        fine = 50000,
        bail = 100000,
        mounths = 20,
    },
    {
        name = "Ocultação de Provas",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Omissão de Socorro",
        fine = 50000,
        bail = 100000,
        mounths = 10,
    },
    {
        name = "Perturbação da Ordem",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "QRR Ilegal",
        fine = 50000,
        bail = 100000,
        mounths = 10,
    },
    {
        name = "Tentativa de Fuga",
        fine = 100000,
        bail = 200000,
        mounths = 20,
    },
    {
        name = "Tentativa de Suborno",
        fine = 200000,
        bail = 400000,
        mounths = 30,
    },
    {
        name = "Alta Velocidade",
        fine = 20000,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Condução Imprudente",
        fine = 20000,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Corridas Ilegais",
        fine = 100000,
        bail = 200000,
        mounths = 20,
    },
    {
        name = "Dirigir na Contramão",
        fine = 20000,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Poluição Sonora",
        fine = 20000,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Veículo Muito Danificado",
        fine = 20000,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Veículo Ilegalmente Estacionado",
        fine = 20000,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Uso Excessivo de Insulfilm",
        fine = 20000,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Ocultação Facial",
        fine = 50000,
        bail = 100000,
        mounths = 10,
    },
    {
        name = "Uso de Coldre",
        fine = 50000,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Uso de Colete (Roupa)",
        fine = 50000,
        bail = 0,
        mounths = 0,
    },
    {
        name = "Porte de Colete Balístico (equipamento)",
        fine = 100000,
        bail = 200000,
        mounths = 10,
    },
    {
        name = "Tráfico de Colete Balístico (equipamento)",
        fine = 200000,
        bail = 400000,
        mounths = 20,
    },
}

Config.mitigatingFactors = {
    {
        name = "Jurídico Constituído",
        fine = 0,
        mounths = 15,
    },
    {
        name = "Réu Primário",
        fine = 0,
        mounths = 10,
    },
    {
        name = "Réu Confesso",
        fine = 0,
        mounths = 10,
    },
    {
        name = "Colaboração",
        fine = 0,
        mounths = 10,
    },
    {
        name = "Porte de Arma Legal",
        fine = 0,
        mounths = 10,
    },
    {
        name = "Delação Premiada",
        fine = 0,
        mounths = 50,
    },
}

Config.Roles = {
    ['Policia'] = {
        {
            roleName = 'CoronelPM',
            permissions = {
                canHire = true,
                canPromote = true,
                canDemote = true,
                canDismiss = true,
            },
        },
        {
            roleName = 'TenenteCoronelPM',
            permissions = {
                canHire = true,
                canPromote = true,
                canDemote = true,
                canDismiss = true,
            },
        },
        {
            roleName = 'MajorPM',
            permissions = {
                canHire = true,
                canPromote = true,
                canDemote = true,
                canDismiss = true,
            },
        },
        {
            roleName = 'CapitaoPM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'PrimeiroTenentePM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'SegundoTenentePM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'SubTenentePM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'PrimeiroSargentoPM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'SegundoSargentoPM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'TerceiroSargentoPM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'CaboPM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'CadetePM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'AspirantePM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'SoldadoPM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'Speed',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'Rocam',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'Grpae',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
        {
            roleName = 'AlunoPM',
            permissions = {
                canHire = false,
                canPromote = false,
                canDemote = false,
                canDismiss = false,
            },
        },
    },    
}