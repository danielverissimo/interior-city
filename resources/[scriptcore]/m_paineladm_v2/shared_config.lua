Config = Config or {}

-- ============================================================================
-- M PAINEL ADM V2 - CONFIGURAÇÃO COMPARTILHADA
-- ============================================================================

Config.Command = "padm"
Config.Key = "INSERT"

Config.Brand = {
    name = "MAGE ADMIN",
    subtitle = "Central de Administração",
    version = "2.90.1"
}

Config.ClickSound = {
    enabled = true,
    name = "CONFIRM_BEEP",
    set = "HUD_MINI_GAME_SOUNDSET"
}


-- ============================================================================
-- SISTEMA DE CHAMADOS
-- ============================================================================
Config.Calls = {
    key = "F5",
    maxMessage = 500,
    createCooldownSeconds = 12,
    departments = {
        staff = { label = "Staff", action = "Chamar Staff" },
        police = { label = "Polícia", action = "Chamar Polícia" },
        mechanic = { label = "Mecânica", action = "Chamar Mecânica" },
        hospital = { label = "Hospital", action = "Chamar Hospital" }
    }
}

-- Mantém compatibilidade com o servidor local de imagens usado no painel antigo.
Config.Images = {
    items = "http://127.0.0.1/images/",
    vehicles = "http://127.0.0.1/vrp_images/"
}

-- Se true, após usar "Ir até" o painel chama o noclip da sua vRP.
-- Atenção: a função da sua vRP é um toggle, então deixe false se sua staff
-- costuma já estar em noclip ao usar o painel.
Config.ToggleNoclipAfterTeleport = false

-- Quantos segundos avisar antes da limpeza global de veículos.
Config.VehicleCleanupDelay = 60

-- Raio usado pela limpeza de props.
Config.PropCleanupRadius = 2000.0

-- ============================================================================
-- MAPA AO VIVO / MONITORAMENTO
-- ============================================================================
-- Bounds aproximados do mapa padrão do GTA V usados para converter as
-- coordenadas do mundo em posição percentual sobre a imagem da NUI.
Config.LiveMap = {
    updateIntervalMs = 5000,

    -- Preview local leve para abrir a aba sem congelar o CEF. A imagem HD é
    -- carregada sob demanda somente quando o ADM realmente começa a aproximar.
    mapPreviewUrl = "imgs/gta-map-preview.jpg?v=237",
    mapImageUrl = "https://www.bragitoff.com/wp-content/uploads/2015/11/GTAV-HD-MAP-roadmap.jpg",
    mapFallbackUrl = "imgs/gta-map-sharp.png?v=237",

    -- CRS usado pelos mapas oficiais GTA V/Leaflet. Estes valores alinham as
    -- coordenadas do GetEntityCoords diretamente ao mapa quadrado 8192x8192.
    crsCenterX = 117.3,
    crsCenterY = 172.8,
    crsScaleX = 0.02072,
    crsScaleY = 0.0205,

    minScale = 0.55,
    maxScale = 8.0,

    -- Ver Tela v2.56: streaming P2P por WebRTC. A tela do jogo é amostrada
    -- diretamente do render target do FiveM pela NUI/WebGL e enviada como vídeo,
    -- sem screenshot-basic, JPG, base64 ou fila de screenshots no servidor.
    screenWidth = 960,
    screenHeight = 540,
    screenFps = 12,
    screenBitrate = 1200000, -- bits/s; 1.2 Mbps é um bom equilíbrio para 540p/12fps
    screenConnectTimeoutMs = 12000,

    -- Fallback automático quando WebRTC P2P não consegue atravessar NAT/CGNAT.
    -- Nesse modo os frames passam pelo FXServer com qualidade/FPS reduzidos,
    -- garantindo que a telagem continue funcionando mesmo sem um servidor TURN.
    screenRelayFallback = true,
    screenRelayWidth = 960,
    screenRelayHeight = 540,
    screenRelayFps = 8,
    screenRelayQuality = 0.65,
    screenRelayBandwidth = 2500000, -- bytes/s usados pelos eventos latentes
    screenRelayMaxFrameBytes = 900000,

    -- STUN só participa da negociação P2P; o vídeo não passa por ele.
    -- Em redes com NAT muito restritivo pode ser necessário adicionar um TURN próprio.
    screenIceServers = {
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302"
    }
}


-- ============================================================================
-- CLIMA E HORÁRIO GLOBAL
-- ============================================================================
-- O m_paineladm_v2 é a fonte única de clima/horário do servidor.
-- CLEAR congelado é usado somente na primeira execução. Depois disso, o último estado é restaurado automaticamente pela persistência do resource (KVP + backup JSON).
Config.Weather = {
    default = "CLEAR",
    defaultHour = 12,
    defaultMinute = 0,
    defaultWeatherFrozen = true,
    defaultTimeFrozen = false,

    -- Relógio: +2 minutos do jogo a cada 10 segundos reais (mesmo ritmo da HUD antiga).
    timeAdvanceMinutes = 2,
    timeAdvanceEveryMs = 10000,

    -- Clima rotativo: troca sincronizada com transição suave nativa.
    rotationIntervalMinutes = 5,
    transitionSeconds = 30.0,

    -- Backup periódico do estado. Em restart, o estado também é salvo no onResourceStop.
    persistEveryMs = 60000,

    -- Sincronização autoritativa. O client reaplica o clima escolhido periodicamente
    -- para impedir que o GTA, respawn ou outro estado local deixe jogadores com climas diferentes.
    clientEnforceEveryMs = 750,

    -- Reenvio periódico do estado oficial para todos os jogadores. Também cobre
    -- joins/reconexões em momentos em que o GlobalState ainda está sendo replicado.
    serverResyncEveryMs = 15000,

    -- Todos os weather types que já existiam na sua HUD / GTA V.
    types = {
        { name = "EXTRASUNNY", label = "Muito ensolarado" },
        { name = "CLEAR", label = "Limpo" },
        { name = "NEUTRAL", label = "Neutro" },
        { name = "SMOG", label = "Smog" },
        { name = "FOGGY", label = "Neblina" },
        { name = "OVERCAST", label = "Nublado fechado" },
        { name = "CLOUDS", label = "Nuvens" },
        { name = "CLEARING", label = "Abrindo" },
        { name = "RAIN", label = "Chuva" },
        { name = "THUNDER", label = "Tempestade" },
        { name = "SNOW", label = "Neve" },
        { name = "BLIZZARD", label = "Nevasca" },
        { name = "SNOWLIGHT", label = "Neve leve" },
        { name = "XMAS", label = "Natal" },
        { name = "HALLOWEEN", label = "Halloween" }
    },

    -- Rotação natural: evita eventos sazonais/neve no ciclo automático normal.
    rotation = {
        "EXTRASUNNY", "CLEAR", "CLOUDS", "OVERCAST", "CLEARING",
        "RAIN", "THUNDER", "SMOG", "FOGGY", "CLEAR"
    }
}

Config.Locations = {}
-- Os teleportes agora são cadastrados pelo próprio painel e persistidos em locations.json.
-- Esta tabela permanece vazia de propósito para não restaurar os locais antigos.

Config.Vehicles = {

    { spawn = "t20", nome = "T20" },
    { spawn = "baller", nome = "BALLER" },
    { spawn = "sultan", nome = "Sultan" },
    { spawn = "akuma", nome = "akuma" },
    { spawn = "avarus", nome = "avarus" },
    { spawn = "baller", nome = "baller" },
    { spawn = "baller4", nome = "baller4" },
    { spawn = "bati", nome = "bati" },
    { spawn = "bf400", nome = "bf400" },
    { spawn = "bfinjection", nome = "bfinjection" },
    { spawn = "bifta", nome = "bifta" },
    { spawn = "blade", nome = "blade" },
    { spawn = "blazer4", nome = "blazer4" },
    { spawn = "blista", nome = "blista" },
    { spawn = "blista3", nome = "blista3" },
    { spawn = "brawler", nome = "brawler" },
    { spawn = "brioso", nome = "brioso" },
    { spawn = "buffalo3", nome = "buffalo3" },
    { spawn = "bullet", nome = "bullet" },
    { spawn = "burrito", nome = "burrito" },
    { spawn = "burrito3", nome = "burrito3" },
    { spawn = "burrito4", nome = "burrito4" },
    { spawn = "carbonizzare", nome = "carbonizzare" },
    { spawn = "carbonrs", nome = "carbonrs" },
    { spawn = "casco", nome = "casco" },
    { spawn = "cheetah", nome = "cheetah" },
    { spawn = "chimera", nome = "chimera" },
    { spawn = "cliffhanger", nome = "cliffhanger" },
    { spawn = "comet3", nome = "comet3" },
    { spawn = "comet5", nome = "comet5" },
    { spawn = "coquette", nome = "coquette" },
    { spawn = "coquette3", nome = "coquette3" },
    { spawn = "daemon2", nome = "daemon2" },
    { spawn = "defiler", nome = "defiler" },
    { spawn = "deveste", nome = "deveste" },
    { spawn = "diablous2", nome = "diablous2" },
    { spawn = "dominator", nome = "dominator" },
    { spawn = "dominator2", nome = "dominator2" },
    { spawn = "dominator3", nome = "dominator3" },
    { spawn = "double", nome = "double" },
    { spawn = "dubsta3", nome = "dubsta3" },
    { spawn = "elegy2", nome = "elegy2" },
    { spawn = "dukes", nome = "dukes" },
    { spawn = "emperor", nome = "emperor" },
    { spawn = "entity2", nome = "entity2" },
    { spawn = "entityxf", nome = "entityxf" },
    { spawn = "f620", nome = "f620" },
    { spawn = "faggio", nome = "faggio" },
    { spawn = "felon2", nome = "felon2" },
    { spawn = "feltzer2", nome = "feltzer2" },
    { spawn = "flashgt", nome = "flashgt" },
    { spawn = "fmj", nome = "fmj" },
    { spawn = "furoregt", nome = "furoregt" },
    { spawn = "gp1", nome = "gp1" },
    { spawn = "guardian", nome = "guardian" },
    { spawn = "hakuchou", nome = "hakuchou" },
    { spawn = "impaler", nome = "impaler" },
    { spawn = "infernus", nome = "infernus" },
    { spawn = "issi2", nome = "issi2" },
    { spawn = "italigtb", nome = "italigtb" },
    { spawn = "italigtb2", nome = "italigtb2" },
    { spawn = "italigto", nome = "italigto" },
    { spawn = "kamacho", nome = "kamacho" },
    { spawn = "khamelion", nome = "khamelion" },
    { spawn = "kuruma", nome = "kuruma" },
    { spawn = "lynx", nome = "lynx" },
    { spawn = "manchez", nome = "manchez" },
    { spawn = "massacro", nome = "massacro" },
    { spawn = "mesa3", nome = "mesa3" },
    { spawn = "michelli", nome = "michelli" },
    { spawn = "minivan2", nome = "minivan2" },
    { spawn = "neon", nome = "neon" },
    { spawn = "nero", nome = "nero" },
    { spawn = "nero2", nome = "nero2" },
    { spawn = "nightshade", nome = "nightshade" },
    { spawn = "ninef", nome = "ninef" },
    { spawn = "omnis", nome = "omnis" },
    { spawn = "osiris", nome = "osiris" },
    { spawn = "panto", nome = "panto" },
    { spawn = "paradise", nome = "paradise" },
    { spawn = "patriot", nome = "patriot" },
    { spawn = "patriot2", nome = "patriot2" },
    { spawn = "pcj", nome = "pcj" },
    { spawn = "phoenix", nome = "phoenix" },
    { spawn = "prototipo", nome = "prototipo" },
    { spawn = "reaper", nome = "reaper" },
    { spawn = "retinue", nome = "retinue" },
    { spawn = "rhapsody", nome = "rhapsody" },
    { spawn = "rocoto", nome = "rocoto" },
    { spawn = "ruffian", nome = "ruffian" },
    { spawn = "ruston", nome = "ruston" },
    { spawn = "saddler", nome = "saddler" },
    { spawn = "sanchez", nome = "sanchez" },
    { spawn = "sanchez2", nome = "sanchez2" },
    { spawn = "sanctus", nome = "sanctus" },
    { spawn = "sandking", nome = "sandking" },
    { spawn = "sc1", nome = "sc1" },
    { spawn = "schafter3", nome = "schafter3" },
    { spawn = "schlagen", nome = "schlagen" },
    { spawn = "sheava", nome = "sheava" },
    { spawn = "shotaro", nome = "shotaro" },
    { spawn = "slamvan3", nome = "slamvan3" },
    { spawn = "sovereign", nome = "sovereign" },
    { spawn = "specter2", nome = "specter2" },
    { spawn = "stretch", nome = "stretch" },
    { spawn = "sultansr", nome = "sultansr" },
    { spawn = "surfer", nome = "surfer" },
    { spawn = "surge", nome = "surge" },
    { spawn = "tempesta", nome = "tempesta" },
    { spawn = "tezeract", nome = "tezeract" },
    { spawn = "trophytruck", nome = "trophytruck" },
    { spawn = "tulip", nome = "tulip" },
    { spawn = "tyrant", nome = "tyrant" },
    { spawn = "vacca", nome = "vacca" },
    { spawn = "visione", nome = "visione" },
    { spawn = "windsor2", nome = "windsor2" },
    { spawn = "xa21", nome = "xa21" },
    { spawn = "xls2", nome = "xls2" },
    { spawn = "zentorno", nome = "zentorno" },




}
