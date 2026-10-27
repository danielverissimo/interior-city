Config = {}

-- Interação
Config.Key = 'N'
Config.PromptText = 'ARROMBAR'
Config.InteractionDistance = 1.65
Config.VehicleSearchDistance = 8.0
Config.RearInteractionOffset = 0.18 -- distância para fora da traseira real do modelo
Config.ServerMaxDistance = 5.5
Config.MaxVehicleSpeed = 0.25 -- m/s. Além do IsVehicleStopped no client, valida que está praticamente zerado.

-- Animação usada enquanto a taskbar de arrombamento estiver ativa.
-- Esta animação simula o personagem manipulando/forçando uma fechadura,
-- ficando bem mais natural para arrombar o porta-malas do veículo.
Config.RobberyAnimation = {
    dict = 'missheistfbisetup1',
    name = 'unlock_loop_janitor',
    flag = 1
}

-- Animação mantida em loop enquanto o porta-malas/inventário estiver aberto.
-- Ao fechar o porta-malas, ela é interrompida automaticamente.
Config.TrunkOpenAnimation = {
    dict = 'amb@prop_human_parking_meter@female@idle_a',
    name = 'idle_a_female',
    flag = 1
}

-- Item necessário. Por padrão a lockpick NÃO é consumida.
Config.LockpickItem = 'lockpick'
Config.ConsumeLockpick = false

-- Integração com o inventário enviado pelo usuário.
Config.InventoryResource = 'inventory'
Config.GarageResource = 'm_garage' -- usado para localizar o chest real dos veículos de jogadores
Config.TrunkWeight = 50
Config.StoragePrefix = 'trunkrobber_'

-- Permite arrombar o próprio veículo.
-- Útil principalmente para testar o sistema de rastreador.
-- Em produção, deixe false para impedir o roubo do próprio carro.
Config.roubar_proprio_veiculo = true

-- Limite para veículos de JOGADORES poderem ser roubados novamente.
-- NPC continua podendo ser roubado apenas uma única vez.
-- true  = depois de um roubo bem-sucedido, aguarda 10 minutos.
-- false = sem limite/cooldown, útil para testar o mesmo veículo várias vezes.
Config.limite_de_tempo = true
Config.tempo_limite_roubo = 10 * 60 -- segundos (10 minutos)

-- Comando administrativo para limpar o histórico/cooldown dos roubos.
-- Útil para testes ou para remover estados antigos de versões anteriores.
-- Executando pelo console do servidor, não exige permissão.
Config.ComandoLimparRoubos = 'limparroubosportamalas'
Config.PermissaoLimparRoubos = 'admin.permissao'

-- Polícia
Config.PolicePermission = 'perm.policia'
Config.PoliceBlipRadius = 85.0
Config.AlertEndDistance = 120.0
Config.PoliceAlertText = 'Roubo a porta-malas em andamento! Verifique a área vermelha marcada no mapa.'
Config.PoliceLeftAreaText = 'O meliante acaba de sair da area do roubo'

-- Alerta sonoro reproduzido somente para os policiais no início do roubo.
-- Usa um som nativo do GTA V, então não precisa de arquivo de áudio externo.
Config.PoliceAlertSound = true
Config.PoliceAlertSoundName = 'Event_Start_Text'
Config.PoliceAlertSoundSet = 'GTAO_FM_Events_Soundset'


-- Radar oculto para veículos de jogadores.
-- O item deve se chamar exatamente "rastreador_carro" e chamar o export
-- useRadarItem deste resource (veja o README). O radar fica salvo de forma
-- persistente no vrp_srv_data e não usa state bag, portanto permanece oculto.
Config.RadarItem = 'rastreador_carro'
Config.RadarInstallRequireStopped = true
Config.RadarStoragePrefix = 'm_robbernpc:radar:'
-- Compatibilidade: radares instalados quando o resource ainda se chamava m_trunkrobber continuam válidos.
Config.LegacyRadarStoragePrefix = 'm_trunkrobber:radar:'
Config.RadarTrackingTime = 90 -- 1 minuto e 30 segundos
Config.RadarUpdateInterval = 1000 -- atualização da posição para a polícia (ms)
Config.RadarTrackerBlipSprite = 1
Config.RadarTrackerBlipColour = 1
Config.RadarTrackerBlipScale = 0.90
Config.RadarTrackerBlipName = 'Meliante rastreado'
Config.RadarInstalledText = 'Radar oculto instalado neste veículo.'
Config.RadarAlreadyInstalledText = 'Este veículo já possui um radar oculto instalado.'
Config.PoliceRadarActivatedText = 'O veículo roubado possui um radar oculto. O meliante será rastreado por 1 minuto e 30 segundos.'

-- Novo comportamento quando um veículo com rastreador é arrombado.
Config.RadarVehicleAlarmDuration = 30000 -- duração do alarme do carro em ms
Config.RadarRecoveredText = 'Você encontrou e removeu o rastreador oculto do veículo.'
Config.RobberTrackedText = 'VOCÊ ESTÁ SENDO RASTREADO,FUJA!'
Config.RobberTrackingEndedText = 'O sinal do rastreador foi perdido. Você não está mais sendo rastreado.'
Config.RadarLockedUseText = 'Você não pode usar este rastreador enquanto estiver sendo rastreado.'

-- ==========================================================================
-- NEGOCIAÇÃO DE DROGAS COM NPCs
-- ==========================================================================
Config.NPCDrugSales = {
    Enabled = true,

    -- Nem todo NPC oferece negociação. A decisão é sorteada uma única vez para
    -- cada ped visto pelo jogador, evitando que a chance fique rerrolando a cada frame.
    EligibilityChance = 30, -- %
    -- A chance é sorteada apenas quando o NPC realmente se aproxima. Se ele sair
    -- da região por alguns segundos, a cache do encontro é reciclada; assim a
    -- cidade nunca fica permanentemente sem compradores depois de muitos NPCs vistos.
    EligibilityRollDistance = 2.75,
    EligibilityResetDistance = 12.0,
    EligibilityResetDelay = 6000, -- ms longe antes de poder virar um novo encontro
    InteractionWatchdog = 9000, -- ms; destrava abordagem se alguma resposta se perder
    SearchDistance = 10.0,
    InteractionDistance = 1.65,
    ServerMaxDistance = 4.0,
    PromptText = 'NEGOCIAR DROGAS',
    InventoryCheckInterval = 1500, -- ms; prompt só aparece se houver droga no inventário

    -- Ao cruzar muito perto de um player com drogas, o NPC para e olha por 2s.
    -- Esta reação acontece uma única vez por ped e não depende dos 30% de negociação.
    AttentionDistance = 2.35,
    AttentionDuration = 2000, -- ms

    -- Animação executada ao confirmar a venda com N.
    ExchangeAnimation = {
        Dict = 'mp_common',
        PlayerAnim = 'givetake1_a',
        NpcAnim = 'givetake1_b',
        Duration = 1600
    },

    -- O NPC sempre demonstra interesse primeiro. O risco só é descoberto quando
    -- o jogador confirma a venda: alguns compradores são oficiais disfarçados.
    UndercoverChance = 25, -- %; ajuste livremente aqui

    -- Quando o comprador é um oficial disfarçado, ele não recebe a droga.
    -- Primeiro liga para a polícia durante 5 segundos; depois foge por 10 segundos
    -- e volta a ser um pedestre ambiente normal, podendo seguir/despawnar normalmente.
    UndercoverDialogue = 'Alo?! Tem um meliante fazendo venda de drogas ilicitas! venham agora!',
    UndercoverPhoneScenario = 'WORLD_HUMAN_STAND_MOBILE',
    UndercoverPhoneDuration = 5000, -- ms
    UndercoverFleeDuration = 10000, -- ms
    UndercoverFleeDistance = 120.0,

    AcceptDialogue = 'Shh, fala baixo... que drogas você tem ai?',
    DialogueDuration = 5000, -- ms; falas ficam visíveis por pelo menos 5 segundos

    -- Depois de uma venda concluída com sucesso, o comprador responde com uma
    -- destas frases aleatoriamente. A fala usa o mesmo balão 3D sobre a cabeça.
    SuccessDialogues = {
        'Se você contar pra alguém, você está morto.',
        'Era disso que eu estava precisando',
        'Tomara que dessa vez a qualidade seja boa',
        'Finalmente agora vou poder dar uma relaxada... mas não conta pra ninguém',
        'Essa é da boa!'
    },

    -- A quantidade final é sorteada pelo SERVIDOR e nunca confiada ao client.
    MinQuantity = 1,
    MaxQuantity = 5,
    OfferTimeout = 18, -- segundos para confirmar a venda

    DirtyMoneyItem = 'dirty_money',

    -- Profissões que não podem usar a negociação clandestina.
    BlockedPermissions = {
        'perm.policia'
    },

    -- Ignora NPCs especiais para não interferir com polícia/forças armadas ou
    -- personagens controlados por outros resources.
    IgnoreMissionPeds = true,
    ExcludedPedTypes = {
        [6] = true,  -- COP
        [27] = true, -- SWAT
        [29] = true  -- ARMY
    },

    -- Valores iguais aos do drogas_entregas enviado. "baseado" foi acrescentado
    -- e pode ser ajustado livremente aqui sem mexer no código.
    Drugs = {
        cocaina = {
            item = 'cocaina',
            label = 'Cocaína',
            minPricePerUnit = 2500,
            maxPricePerUnit = 2500
        },
        metanfetamina = {
            item = 'metanfetamina',
            label = 'Metanfetamina',
            minPricePerUnit = 1000,
            maxPricePerUnit = 1000
        },
        malote_maconha = {
            item = 'malote-maconha',
            label = 'Malote de Maconha',
            minPricePerUnit = 2500,
            maxPricePerUnit = 2500
        },
        baseado = {
            item = 'baseado',
            label = 'Baseado',
            minPricePerUnit = 500,
            maxPricePerUnit = 500
        }
    },

    -- Mesmo NotifyPush/vrp_notifycall usado pelo sistema de venda de drogas.
    Dispatch = {
        Enabled = true,
        Resource = 'vrp_notifycall',
        Event = 'NotifyPush',
        PolicePermission = 'perm.policia',
        Code = '911',
        Title = 'VENDA DE DROGAS',
        Text = 'Um cidadão denunciou uma possível venda de drogas. Verifique a região.',
        Rgba = { 255, 55, 70, 255 },
        BlipSprite = 161,
        BlipColor = 1,
        BlipScale = 0.85,
        BlipDuration = 60000,
        Sound = true
    }
}

-- Quantos itens DIFERENTES entram em cada porta-malas.
Config.LootCount = 4

-- Os IDs abaixo estão em minúsculo porque o inventory/vRP desta base usa
-- os índices do arquivo inventory/config/shared.items.lua em minúsculo.
Config.Loot = {
    { item = 'celular',          min = 1,  max = 1  },
    { item = 'repairkit2',       min = 1,  max = 1  },
    { item = 'weapon_bat',       min = 1,  max = 1  }, -- WEAPON_BAT
    { item = 'weapon_pistol_mk2',min = 1,  max = 1  }, -- WEAPON_PISTOL_MK2
    { item = 'ammo_pistol_mk2',  min = 10, max = 25 }, -- AMMO_PISTOL_MK2
    { item = 'weapon_knife',     min = 1,  max = 1  }, -- WEAPON_KNIFE
    { item = 'energetico',       min = 1,  max = 1  },
    { item = 'baseado',          min = 1,  max = 1  },
    { item = 'radio',            min = 1,  max = 1  },
    { item = 'alianca',          min = 1,  max = 1  },
    { item = 'mochila',          min = 1,  max = 1  },

    { item = 'relogioroubado',       min = 1,  max = 1  },
    { item = 'colarroubado',          min = 1,  max = 1  },
    { item = 'anelroubado',            min = 1,  max = 1  },
    { item = 'brincoroubado',          min = 1,  max = 1  },
    { item = 'pulseiraroubada',          min = 1,  max = 1  }
}
