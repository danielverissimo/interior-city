Config = {}

-- ============================================================================
-- PONTO INICIAL / PAINEL
-- ============================================================================
Config.Start = {
    coords = { x = 1289.37, y = -1711.09, z = 55.48 },
    drawDistance = 12.0,
    interactDistance = 1.5,
    marker = {
        type = 31,
        scale = { x = 0.50, y = 0.50, z = 0.40 },
        color = { r = 108, g = 54, b = 255, a = 115 }
    }
}

-- Pasta htdocs/images. Se o seu servidor de imagens usar domínio/CDN,
-- troque apenas esta URL. Ex.: https://cdn.seuservidor.com/images/
Config.ImageBaseUrl = "http://127.0.0.1/images/"

-- ============================================================================
-- NPC DO PONTO INICIAL
-- ============================================================================
Config.NPC = {
    enabled = true,
    coords = { x = 1289.14, y = -1710.55, z = 55.48 },
    heading = 201.08,
    model = "u_m_o_tramp_01"
}

-- ============================================================================
-- BLIP NO MAPA
-- ============================================================================
Config.MapBlip = {
    enabled = true,
    coords = { x = 1290.77, y = -1714.57, z = 55.0 },
    sprite = 310,
    color = 1,
    scale = 0.70,
    text = "Zona Perigosa | Venda Drogas"
}

-- ============================================================================
-- ROTA / VENDAS
-- ============================================================================
Config.Route = {
    interactDistance = 2.5,
    serverValidationDistance = 5.0,
    clientDrawDistance = 15.0,
    interactionCooldownMs = 1200,

    -- Item entregue ao jogador como pagamento.
    dirtyMoneyItem = "dirty_money",

    -- Permissões impedidas de iniciar rota.
    blockedPermissions = {
        "perm.policia"
    },

    routeBlip = {
        sprite = 207,
        color = 1,
        scale = 0.50,
        text = "Venda de Drogas"
    },

    marker = {
        type = 21,
        scale = { x = 1.25, y = 1.25, z = 0.85 },
        color = { r = 139, g = 92, b = 246, a = 135 }
    }
}

-- ============================================================================
-- DROGAS DISPONÍVEIS
-- minQuantity / maxQuantity = quantidade vendida em CADA ponto.
-- minPricePerUnit / maxPricePerUnit = dinheiro sujo recebido POR UNIDADE.
-- refusalChance = chance (%) do comprador recusar e chamar a polícia.
-- Para valor fixo, deixe minPricePerUnit e maxPricePerUnit iguais.
-- ============================================================================
Config.DrugOrder = { "cocaina", "metanfetamina", "malote_maconha" }

Config.Drugs = {
    cocaina = {
        item = "cocaina",
        label = "Cocaína",
        description = "Venda de cocaína nas rotas clandestinas.",
        image = "cocaina",
        minQuantity = 1,
        maxQuantity = 3,
        minPricePerUnit = 2500,
        maxPricePerUnit = 2500,
        refusalChance = 25
    },

    metanfetamina = {
        item = "metanfetamina",
        label = "Metanfetamina",
        description = "Venda de metanfetamina nas rotas clandestinas.",
        image = "metanfetamina",
        minQuantity = 1,
        maxQuantity = 3,
        minPricePerUnit = 1000,
        maxPricePerUnit = 1000,
        refusalChance = 25
    },

    malote_maconha = {
        item = "malote-maconha",
        label = "Malote de Maconha",
        description = "Venda de malotes de maconha nas rotas clandestinas.",
        image = "malote-maconha",
        minQuantity = 1,
        maxQuantity = 3,
        minPricePerUnit = 2500,
        maxPricePerUnit = 2500,
        refusalChance = 25
    }
}

-- ============================================================================
-- SISTEMA DE REPUTAÇÃO
-- ============================================================================
-- A reputação é individual e persistente no banco de dados.
-- paymentPercent = porcentagem do valor normal recebida em cada venda.
-- arrestsToDrop = quantas prisões por venda/tráfico de drogas são necessárias
--                 para cair para o próximo nível. A contagem zera ao cair.
-- salesToRecover = quantas vendas CONCLUÍDAS sem nova prisão são necessárias
--                  para recuperar um nível. A recuperação é sempre nível a nível.
--
-- Fluxo padrão:
-- INTACTA --1 prisão--> MEDIA --2 prisões--> BAIXA --2 prisões--> HORRÍVEL
-- HORRÍVEL --10 vendas--> BAIXA --10 vendas--> MEDIA --5 vendas--> INTACTA
-- ============================================================================
Config.Reputation = {
    enabled = true,
    defaultLevel = "intacta",

    -- Evita contar a mesma prisão duas vezes caso o MDT receba duplo clique/callback.
    duplicateArrestProtectionSeconds = 15,

    -- O MDT enviado neste pacote possui "Venda de drogas". Mantemos também
    -- o nome antigo da base para compatibilidade com prisões já configuradas.
    mdtCrimeNames = {
        "Venda de drogas",
        "Tráfico de Drogas (+100)"
    },

    levels = {
        intacta = {
            label = "INTACTA",
            color = "#55d98b",
            paymentPercent = 100,
            arrestsToDrop = 1,
            dropTo = "media",
            salesToRecover = 0
        },

        media = {
            label = "MEDIA",
            color = "#e7c75d",
            paymentPercent = 85,
            arrestsToDrop = 2,
            dropTo = "baixa",
            salesToRecover = 5,
            recoverTo = "intacta"
        },

        baixa = {
            label = "BAIXA",
            color = "#e58b4b",
            paymentPercent = 65,
            arrestsToDrop = 2,
            dropTo = "horrivel",
            salesToRecover = 10,
            recoverTo = "media"
        },

        horrivel = {
            label = "HORRÍVEL",
            color = "#e05252",
            paymentPercent = 45,
            arrestsToDrop = 0,
            salesToRecover = 10,
            recoverTo = "baixa"
        }
    }
}

-- ============================================================================
-- VRP_NOTIFYCALL / POLÍCIA
-- Todo alerta policial deste resource passa EXCLUSIVAMENTE pelo NotifyPush.
-- ============================================================================
Config.Dispatch = {
    enabled = true,
    resource = "vrp_notifycall",
    event = "NotifyPush",
    policePermission = "perm.policia",

    code = "911",
    title = "VENDA DE DROGAS",
    text = "Um cidadão denunciou uma possível venda de drogas. Verifique a região.",
    rgba = { 255, 55, 70, 255 },

    blipSprite = 161,
    blipColor = 1,
    blipScale = 0.85,
    blipDuration = 60000,
    sound = true
}

-- ============================================================================
-- PONTOS DAS VENDAS
-- Adicione/remova pontos livremente. O servidor escolhe os destinos.
-- ============================================================================
Config.RoutePoints = {
    { x = 879.86, y = -205.07, z = 71.98 },
    { x = 862.52, y = -138.65, z = 79.22 },
    { x = 474.96, y = -635.79, z = 25.65 },
    { x = 1170.09, y = -402.72, z = 71.98 },
    { x = 1308.47, y = -661.17, z = 67.51 },
    { x = -2.07, y = -1442.08, z = 30.97 },
    { x = -64.52, y = -1449.60, z = 32.53 },
    { x = 115.71, y = -271.62, z = 50.52 },
    { x = 8.58, y = -243.14, z = 51.87 },
    { x = -9.88, y = -200.57, z = 57.09 },
    { x = -333.03, y = 101.02, z = 71.22 },
    { x = -105.75, y = 33.02, z = 71.44 },
    { x = 143.55, y = -113.42, z = 62.30 },
    { x = 371.69, y = 72.51, z = 98.18 },
    { x = 115.98, y = 170.79, z = 112.46 },
    { x = -155.04, y = 214.65, z = 98.33 },
    { x = -1492.59, y = -149.92, z = 52.51 },
    { x = -1039.10, y = -1353.40, z = 5.56 },
    { x = -882.79, y = -1155.46, z = 5.17 },
    { x = -1269.96, y = -1296.37, z = 4.01 },
    { x = -1381.26, y = -940.87, z = 10.18 },
    { x = -1750.47, y = -697.47, z = 10.18 },
    { x = -1487.10, y = -909.97, z = 10.03 },
    { x = -1027.72, y = -1575.45, z = 5.27 },
    { x = -1208.49, y = -1384.21, z = 4.09 },
    { x = -1097.40, y = -1673.04, z = 8.40 },
    { x = -699.64, y = -1315.87, z = 5.11 },
    { x = -604.34, y = -802.52, z = 25.41 },
    { x = -32.35, y = -1446.44, z = 31.90 },
    { x = 415.78, y = -1485.57, z = 30.15 },
    { x = 1286.60, y = -1604.32, z = 54.83 },
    { x = 1185.20, y = -1620.31, z = 45.03 },
    { x = 1354.85, y = -1690.61, z = 60.50 },
    { x = 1437.53, y = -1491.87, z = 63.63 },
    { x = 1451.19, y = -1720.56, z = 68.76 },
    { x = 368.58, y = -1896.02, z = 25.18 },
    { x = 367.46, y = -1802.29, z = 29.07 },
    { x = 149.88, y = -1864.60, z = 24.60 },
    { x = -4.74, y = -1872.06, z = 24.16 },
    { x = -80.89, y = -1326.10, z = 29.27 },
    { x = 368.42, y = -1107.38, z = 29.41 },
    { x = 328.42, y = -994.57, z = 29.32 },
    { x = 479.18, y = -106.69, z = 63.16 },
    { x = 167.00, y = -1709.63, z = 29.30 },
    { x = -1328.05, y = -402.57, z = 36.61 },
    { x = -1426.24, y = -99.59, z = 51.77 },
    { x = -21.49, y = -1001.98, z = 29.50 },
    { x = 978.17, y = -1466.22, z = 31.52 },
    { x = -850.83, y = -252.29, z = 39.66 },
    { x = -1023.52, y = -1614.41, z = 5.09 },
    { x = -102.94, y = 397.50, z = 112.43 },
    { x = -1965.37, y = -296.92, z = 41.10 },
    { x = -105.77, y = 32.88, z = 71.44 }
}
