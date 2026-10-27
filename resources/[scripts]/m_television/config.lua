Config = {}

Config.Models = { -- Any TV Models used on the map or in locations must be defined here.
    [`des_tvsmash_start`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-92.58,94.58,72.27)
    },
    [`prop_flatscreen_overlay`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 1.5,
        Offset = vector3(-92.65,91.14,71.95)
    },
    [`prop_laptop_lester2`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-90.6,86.62,71.75)
    },
    [`prop_monitor_02`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-92.09,97.28,72.52)
    },
    [`prop_trev_tv_01`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-91.8,101.12,72.96)
    },
    [`prop_tv_02`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`prop_tv_03_overlay`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`prop_tv_06`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`prop_tv_flat_01`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`prop_tv_flat_01_screen`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`prop_tv_flat_02b`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`prop_tv_flat_03`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`prop_tv_flat_03b`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`prop_tv_flat_michael`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`prop_monitor_w_large`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`prop_tv_03`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`prop_tv_flat_02`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen", -- Only use if prop has render-target name.
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04)
    },
    [`v_ilev_cin_screen`] = {
        DefaultVolume = 0.5,
        Range = 30.0,
        Target = "cinscreen",
        Scale = 0.085,
        Offset = vector3(-114.89,96.97,71.81)
    },
    [`xm_prop_x17_tv_scrn_01`] = {
        DefaultVolume = 0.5,
        Range = 30.0,
        Target = "tvscreen", -- Render target padrão
        Scale = 2.0,
        Offset = vector3(-1.0, 0.0, 1.0)
    },
    [`gr_trailer_monitor_01`] = {
        DefaultVolume = 0.5,
        Range = 25.0,
        Target = "tvscreen",
        Scale = 1.5,
        Offset = vector3(-92.62, 93.96, 72.22)
    },
    [`gr_trailerTV_01`] = {
        DefaultVolume = 0.5,
        Range = 25.0,
        Target = "tvscreen",
        Scale = 1.5,
        Offset = vector3(0.0, 0.0, 1.0)
    },

    -- TVs integradas aos móveis dos apartamentos / interiores do GTA Online.
    -- Estes modelos possuem render target nativo e devem ser cadastrados
    -- mesmo quando a televisão faz parte do móvel inteiro.
    [`apa_mp_h_str_avunitl_01_b`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen"
    },
    [`apa_mp_h_str_avunitl_04`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen"
    },
    [`apa_mp_h_str_avunitm_01`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen"
    },
    [`apa_mp_h_str_avunitm_03`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen"
    },
    [`apa_mp_h_str_avunits_01`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen"
    },
    [`apa_mp_h_str_avunits_04`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen"
    },
    [`hei_heist_str_avunitl_03`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Target = "tvscreen"
    },
    [`vw_prop_vw_cinema_tv_01`] = {
        DefaultVolume = 0.5,
        Range = 25.0,
        Target = "tvscreen"
    },
    [`ch_prop_ch_tv_rt_01a`] = {
        DefaultVolume = 0.5,
        Range = 25.0,
        Target = "ch_tv_rt_01a"
    },
    [`xs_prop_arena_screen_tv_01`] = {
        DefaultVolume = 0.5,
        Range = 30.0,
        Target = "screen_tv_01"
    },
}

Config.Locations = { -- REMOVE ALL IF NOT USING ONESYNC, OR IT SHALL BREAK.
    {
        Model = `v_ilev_cin_screen`,
        Position = vector4(-114.89,96.97,71.81, 0.0), -- 0.0 é o heading, ajuste se quiser virar a TV
    },
    {
        Model = `prop_flatscreen_overlay`,
        Position = vector4(-92.65,91.14,71.95, 0.0), -- 0.0 é o heading, ajuste se quiser virar a TV
    },
    {
        Model = `prop_laptop_lester2`,
        Position = vector4(-90.6,86.62,71.75, 0.0), -- 0.0 é o heading, ajuste se quiser virar a TV
    },
    {
        Model = `prop_monitor_02`,
        Position = vector4(-92.09,97.28,72.52, 0.0), -- 0.0 é o heading, ajuste se quiser virar a TV
    },
    {
        Model = `prop_trev_tv_01`,
        Position = vector4(-91.8,101.12,72.96, 0.0), -- 0.0 é o heading, ajuste se quiser virar a TV
    },
    {
        Model = `prop_tv_flat_01`,
        Position = vector4(144.3038, -1037.4647, 29.4173, 70.81),
    },
    {
        Model = 1194029334,
        Position = vector4(-947.8378, -2051.6443, 10.4049, 134.72), -- Coordenadas e rotação da TV
    },
    {
        Model = `prop_tv_flat_michael`,
        Position = vector4(-945.8309, -2053.6511, 10.4049, 134.63),
    },
}

Config.Channels = { -- These channels are default channels and cannot be overriden.
    {name = "Twitch", url = "twitch.tv/coreano"},
}

Config.BannedWords = {
    "google",
}

-- ============================================================
-- m_television - configurações da versão adaptada
-- ============================================================

Config.Commands = {
    Television = "tv",
    Broadcast = "broadcast",
    AddTelevision = "addtv"
}

Config.Dui = {
    Width = 1280,
    Height = 720,
    ScanInterval = 1200,
    FarScanInterval = 2500
}

Config.Security = {
    MaxUrlLength = 700,
    InteractionDistanceBuffer = 3.0,
    AllowedProtocols = { "http://", "https://" }
}

-- Por padrão qualquer jogador pode usar uma televisão próxima.
-- Broadcast e /addtv ficam restritos a staff. A checagem é compatível
-- tanto com Creative (Passport/HasGroup/HasPermission) quanto com vRP antiga.
Config.Permissions = {
    Use = {
        Everyone = true,
        Groups = {},
        Permissions = {}
    },
    Broadcast = {
        Everyone = false,
        Groups = { "dono", "developer", "owner" },
        Permissions = { "owner.permissao" }
    },
    AddTelevision = {
        Everyone = false,
        Groups = { "dono", "developer", "owner" },
        Permissions = { "owner.permissao" }
    }
}

Config.PlaceableModels = {
    { label = "TV Plana Grande", model = `prop_tv_flat_01` },
    { label = "TV Plana Michael", model = `prop_tv_flat_michael` },
    { label = "TV Plana 02", model = `prop_tv_flat_02` },
    { label = "TV Plana 03", model = `prop_tv_flat_03` },
    { label = "Monitor Grande", model = `prop_monitor_w_large` },
    { label = "TV Cinema", model = `v_ilev_cin_screen` },
    { label = "TV Moderna", model = `xm_prop_x17_tv_scrn_01` },
    { label = "TV Trailer", model = `gr_trailerTV_01` }
}

-- Hooks opcionais. Chame cb(true) para aprovar ou cb(false) para negar.
-- A validação de URL, distância e permissão já é feita pelo servidor.
Config.Events = {
    ScreenInteract = function(source, payload, cb)
        cb(true)
    end,
    Broadcast = function(source, payload, cb)
        cb(true)
    end
}
