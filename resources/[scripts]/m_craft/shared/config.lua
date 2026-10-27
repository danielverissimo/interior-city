Config = {}

Config.CraftTemplate = {
    armas = {
        {
            name = 'SNS Pistol',
            image = 'weapon_snspistol_mk2',
            spawn = 'weapon_snspistol_mk2',
            amount = 1,
            time = 7,
            requires = {
                { name = 'pecadearma', image = 'pecadearma', amount = 70 },
            },
        },
        {
            name = 'Five Seven',
            image = 'weapon_pistol_mk2',
            spawn = 'weapon_pistol_mk2',
            amount = 1,
            time = 7,
            requires = {
                { name = 'pecadearma', image = 'pecadearma', amount = 135 },
            },
        },
        {
            name = 'Tec-9',
            image = 'weapon_machinepistol',
            spawn = 'weapon_machinepistol',
            amount = 1,
            time = 10,
            requires = {
                { name = 'pecadearma', image = 'pecadearma', amount = 200 },
            },
        },
        {
            name = 'SMG',
            image = 'weapon_assaultsmg',
            spawn = 'weapon_assaultsmg',
            amount = 1,
            time = 10,
            requires = {
                { name = 'pecadearma', image = 'pecadearma', amount = 270 },
            },
        },
        {
            name = 'AK MK2',
            image = 'weapon_assaultrifle_mk2',
            spawn = 'weapon_assaultrifle_mk2',
            amount = 1,
            time = 25,
            requires = {
                { name = 'pecadearma', image = 'pecadearma', amount = 330 },
            },
        },
        {
            name = 'G36',
            image = 'weapon_specialcarbine_mk2',
            spawn = 'weapon_specialcarbine_mk2',
            amount = 1,
            time = 25,
            requires = {
                { name = 'pecadearma', image = 'pecadearma', amount = 490 },
            },
        },
        
    },
    municao = {
        {
            name = 'SNS Pistol',
            image = 'ammo_snspistol_mk2',
            spawn = 'ammo_snspistol_mk2',
            amount = 100,
            time = 7,
            requires = {
                { name = 'polvora',  image = 'polvora',  amount = 85 },
                { name = 'capsulas', image = 'capsulas', amount = 110 },
            },
        },
        
        {
            name = 'Five Seven',
            image = 'ammo_pistol_mk2',
            spawn = 'ammo_pistol_mk2',
            amount = 100,
            time = 7,
            requires = {
                { name = 'polvora',  image = 'polvora',  amount = 165 },
                { name = 'capsulas', image = 'capsulas', amount = 110 },
            },
        },
        {
            name = 'Tec-9',
            image = 'ammo_machinepistol',
            spawn = 'ammo_machinepistol',
            amount = 100,
            time = 10,
            requires = {
                { name = 'polvora',  image = 'polvora',  amount = 165 },
                { name = 'capsulas', image = 'capsulas', amount = 110 },
            },
        },
        {
            name = 'Glock Rajada',
            image = 'ammo_glockrajada',
            spawn = 'ammo_glockrajada',
            amount = 100,
            time = 10,
            requires = {
                { name = 'polvora',  image = 'polvora',  amount = 165 },
                { name = 'capsulas', image = 'capsulas', amount = 110 },
            },
        },
        {
            name = 'SMG',
            image = 'ammo_assaultsmg',
            spawn = 'ammo_assaultsmg',
            amount = 100,
            time = 10,
            requires = {
                { name = 'polvora',  image = 'polvora',  amount = 165 },
                { name = 'capsulas', image = 'capsulas', amount = 110 },
            },
        },
        {
            name = 'AK MK2',
            image = 'ammo_assaultrifle_mk2',
            spawn = 'ammo_assaultrifle_mk2',
            amount = 100,
            time = 25,
            requires = {
                { name = 'polvora',  image = 'polvora',  amount = 220 },
                { name = 'capsulas', image = 'capsulas', amount = 110 },
                { name = 'money',    image = 'money',    amount = 22000 },
            },
        },
        {
            name = 'G36',
            image = 'ammo_specialcarbine_mk2',
            spawn = 'ammo_specialcarbine_mk2',
            amount = 100,
            time = 25,
            requires = {
                { name = 'polvora',  image = 'polvora',  amount = 240 },
                { name = 'capsulas', image = 'capsulas', amount = 110 },
                { name = 'money',    image = 'money',    amount = 33000 },
            },
        },

        {
            name = 'G3 LUNETA',
            image = 'ammo_g3luneta_relikiashop',
            spawn = 'ammo_g3luneta_relikiashop',
            amount = 100,
            time = 25,
            requires = {
                { name = 'polvora',  image = 'polvora',  amount = 240 },
                { name = 'capsulas', image = 'capsulas', amount = 110 },
                { name = 'money',    image = 'money',    amount = 30000 },
            },
        },
        {
            name = 'HK Relikia',
            image = 'ammo_hk_relikiashop',
            spawn = 'ammo_hk_relikiashop',
            amount = 100,
            time = 25,
            requires = {
                { name = 'polvora',  image = 'polvora',  amount = 240 },
                { name = 'capsulas', image = 'capsulas', amount = 110 },
                { name = 'money',    image = 'money',    amount = 33000 },
            },
        },
        {
            name = 'AK CROMO',
            image = 'ammo_akcromo',
            spawn = 'ammo_akcromo',
            amount = 100,
            time = 25,
            requires = {
                { name = 'polvora',  image = 'polvora',  amount = 280 },
                { name = 'capsulas', image = 'capsulas', amount = 130 },
                { name = 'money',    image = 'money',    amount = 40000 },
            },
        },
        {
            name = 'M16',
            image = 'ammo_tacticalrifle',
            spawn = 'ammo_tacticalrifle',
            amount = 100,
            time = 25,
            requires = {
                { name = 'polvora',  image = 'polvora',  amount = 300 },
                { name = 'capsulas', image = 'capsulas', amount = 150 },
                { name = 'money',    image = 'money',    amount = 45000 },
            },
        },
    },
    lavagem = {
        {
            name = 'Dinheiro',
            image = 'money',
            spawn = 'money',
            amount = 180000,
            time = 4,
            requires = {
                { name = 'dirty_money', image = 'dirty_money', amount = 200000 },
                { name = 'l-alvejante', image = 'l-alvejante', amount = 22 },
            },
        },
        {
            name = 'Capuz',
            image = 'capuz',
            spawn = 'capuz',
            amount = 1,
            time = 10,
            requires = {
                { name = 'tecido', image = 'tecido', amount = 30 },
            },
        },
        {
            name = 'Algemas',
            image = 'algemas',
            spawn = 'algemas',
            amount = 1,
            time = 10,
            requires = {
                { name = 'metal', image = 'metal', amount = 50 },
            },
        },
        {
            name = 'C4',
            image = 'c4',
            spawn = 'c4',
            amount = 1,
            time = 10,
            requires = {
                { name = 'contador', image = 'contador', amount = 1 },
                { name = 'linha', image = 'linha', amount = 15 },
                { name = 'metal', image = 'metal', amount = 30 },
            },
        },
        {
            name = 'Colete',
            image = 'body_armor',
            spawn = 'body_armor',
            amount = 1,
            time = 10,
            requires = {
                { name = 'tecido', image = 'tecido', amount = 30 },
                { name = 'metal', image = 'metal', amount = 50 },
            },
        },
    },
    Cocaina = {
        {
            name = "Cocaina",
            image = "cocaina",
            spawn = "cocaina",
            amount = 1,
            time = 3,
            requires = {
                { name = "pastabase", image = "pastabase", amount = 5 },
            },
        },
    },
    Metanfetamina = {
        {
            name = "metanfetamina",
            image = "metanfetamina",
            spawn = "metanfetamina",
            amount = 1,
            time = 3,
            requires = {
                { name = "anfetamina", image = "anfetamina", amount = 5 },
            },
        },
    },
    Maconha = {
        {
            name = "maconha",
            image = "maconha",
            spawn = "maconha",
            amount = 1,
            time = 3,
            requires = {
                { name = "folhamaconha", image = "folhamaconha", amount = 5 },
            },
        },
    },
 motoclubSpecial = {

        {
            name = "lockpick",
            image = "lockpick",
            spawn = "lockpick",
            amount = 1,
            time = 7,
            requires = {
                { name = "ferro",    image = "ferro",    amount = 50 },
                { name = "metal", image = "metal", amount = 50 },
            },
        },
        {
            name = "masterpick",
            image = "masterpick",
            spawn = "masterpick",
            amount = 1,
            time = 7,
            requires = {
                { name = "ferro",    image = "ferro",    amount = 170 },
                { name = "metal", image = "metal", amount = 170 },
            },
        },
    },
    porte = {
        {
            name = "Pistola",
            image = "weapon_pistol",
            spawn = "weapon_pistol",
            amount = 1,
            time = 7,
            requires = {
                { name = "money", image = "money", amount = 100000 },
            },
        },
        {
            name = "Munição Pistola",
            image = "ammo_pistol",
            spawn = "ammo_pistol",
            amount = 50,
            time = 7,
            requires = {
                { name = "money", image = "money", amount = 50000 },
            },
        },
    },
}

Config.ArmazemTemplate = {

    armas = {
        { name = "Peça de Arma", spawn = "pecadearma", image = "pecadearma" },
    },
    municao = {
        { name = "Capsulas", spawn = "capsulas", image = "capsulas" },
        { name = "Polvora",  spawn = "polvora",  image = "polvora" },
    },
    lavagem = {
        { name = "Alvejante", spawn = "l-alvejante", image = "l-alvejante" },
        { name = "Dinheiro Sujo",  spawn = "dirty_money",  image = "dirty_money" },
        { name = "Tecido",  spawn = "tecido",  image = "tecido" },
        { name = "Metal",  spawn = "metal",  image = "metal" },
        { name = "Linha",  spawn = "linha",  image = "linha" },
        { name = "contador",  spawn = "contador",  image = "contador" },
    },
    motoclubSpecial = {
        { name = "Ferro",    spawn = "ferro",    image = "ferro" },
        { name = "metal", spawn = "metal", image = "metal" },
    },
    Cocaina = {
        { name = "Pasta Base", spawn = "pastabase", image = "pastabase" },
    },
    Metanfetamina = {
        { name = "Anfetamina", spawn = "anfetamina", image = "anfetamina" },
    },
    Maconha = {
        { name = "Folha de Maconha", spawn = "folhamaconha", image = "folhamaconha" },
    },
    porte = {
        { name = "Dinheiro", spawn = "money", image = "money" },
    },
}

Config.Coords = {
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Armas
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    {
        name = 'Mafia',
        craftItems = Config.CraftTemplate.armas,
        armazemItems = Config.ArmazemTemplate.armas,
        craftPermission = 'perm.lidermafia',
        armazemPermission = 'perm.mafia',
        coords = {
            vec3(-1870.43,2061.88,135.44),
        },
    },

    {
        name = 'Verdes',
        craftItems = Config.CraftTemplate.armas,
        armazemItems = Config.ArmazemTemplate.armas,
        craftPermission = 'perm.liderverdes',
        armazemPermission = 'perm.verdes',
        coords = {
            vec3(1398.55,-741.49,72.15),
        },
    },

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Municao
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    {
        name = 'Cartel',
        craftItems = Config.CraftTemplate.municao,
        armazemItems = Config.ArmazemTemplate.municao,
        craftPermission = 'perm.lidercartel',
        armazemPermission = 'perm.cartel',
        coords = {
            vec3(1405.68,1137.76,109.74),
        },
    },

    {
        name = 'Vermelhos',
        craftItems = Config.CraftTemplate.municao,
        armazemItems = Config.ArmazemTemplate.municao,
        craftPermission = 'perm.lidervermelhos',
        armazemPermission = 'perm.vermelhos',
        coords = {
            vec3(1266.66,-299.59,87.52),
        },
    },

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Lavagem
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    {
        name = 'Vanilla',
        craftItems = Config.CraftTemplate.lavagem,
        armazemItems = Config.ArmazemTemplate.lavagem,
        craftPermission = 'perm.lidervanilla',
        armazemPermission = 'perm.vanilla',
        coords = {
            vec3(96.84,-1292.33,29.27),
        },
    },

    {
        name = 'Bahamas',
        craftItems = Config.CraftTemplate.lavagem,
        armazemItems = Config.ArmazemTemplate.lavagem,
        craftPermission = 'perm.liderbahamas',
        armazemPermission = 'perm.bahamas',
        coords = {
            vec3(-1367.52,-625.55,30.31),
        },
    },

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Desmanche
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    {
        name = 'Motoclube',
        craftItems = Config.CraftTemplate.motoclubSpecial,
        armazemItems = Config.ArmazemTemplate.motoclubSpecial,
        craftPermission = 'perm.lidermotoclube',
        armazemPermission = 'perm.motoclube',
        coords = {
            vec3(989.45,-136.06,74.05),
        },
    },

    {
        name = 'Franca',
        craftItems = Config.CraftTemplate.motoclubSpecial,
        armazemItems = Config.ArmazemTemplate.motoclubSpecial,
        craftPermission = 'perm.liderfranca',
        armazemPermission = 'perm.franca',
        coords = {
            vec3(-2361.49,1750.69,212.12),
        },
    },

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Drogas
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    {
        name = 'Roxos',
        craftItems = Config.CraftTemplate.Cocaina,
        armazemItems = Config.ArmazemTemplate.Cocaina,
        craftPermission = 'perm.liderroxos',
        armazemPermission = 'perm.roxos',
        coords = {
            vec3(-2212.06,-212.1,65.36),
        },
    },

    {
        name = 'Laranjas',
        craftItems = Config.CraftTemplate.Metanfetamina,
        armazemItems = Config.ArmazemTemplate.Metanfetamina,
        craftPermission = 'perm.liderlaranjas',
        armazemPermission = 'perm.laranjas',
        coords = {
            vec3(1413.29,1492.36,113.87),
        },
    },
    
    {
        name = 'Colombia',
        craftItems = Config.CraftTemplate.Maconha,
        armazemItems = Config.ArmazemTemplate.Maconha,
        craftPermission = 'perm.lidercolombia',
        armazemPermission = 'perm.colombia',
        coords = {
            vec3(-1402.15,1622.68,164.74),
        },
    },

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Porte de Armas Policia
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
   {
        name = 'Policia',
        craftItems = Config.CraftTemplate.porte,
        armazemItems = Config.ArmazemTemplate.porte,
        craftPermission = 'perm.militar',
        armazemPermission = 'perm.militar',
        coords = {
            vec3(447.3,-975.65,30.68),
        },
    },

}







    -- -- DOMINACAO
    -- {
    --     name = 'Dominacao Lavagem',
    --     craftItems = Config.CraftTemplate.dominacaoLavagem,
    --     armazemItems = Config.ArmazemTemplate.lavagem,
    --     craftPermission = 'perm.liderlavagem',
    --     armazemPermission = 'perm.lavagem',
    --     hasDomination = 'Lavagem',
    --     coords = {
    --         vec3(-316.25,-2778.77,5.0),
    --     },
    -- },

    -- {
    --     name = 'Dominacao Geral',
    --     craftItems = Config.CraftTemplate.dominacaoGeral,
    --     armazemItems = Config.ArmazemTemplate.geral,
    --     craftPermission = 'perm.ilegal',
    --     armazemPermission = 'perm.ilegal',
    --     hasDomination = 'Geral',
    --     coords = {
    --         vec3(2760.77,1548.85,30.78),
    --     },
    -- },

 







    --     dominacaoLavagem = {
    --     {
    --         name = 'Dinheiro',
    --         image = 'money',
    --         spawn = 'money',
    --         amount = 190000,
    --         time = 4,
    --         requires = {
    --             { name = 'dirty_money', image = 'dirty_money', amount = 200000 },
    --             { name = 'l-alvejante', image = 'l-alvejante', amount = 20 },
    --         },
    --     },
    --     {
    --         name = 'Adrenalina',
    --         image = 'adrenalina',
    --         spawn = 'adrenalina',
    --         amount = 1,
    --         time = 4,
    --         requires = {
    --             { name = 'money', image = 'money', amount = 100000 },
    --         },
    --     },
    -- },

    -- dominacaoGeral = {
        
    --     {
    --         name = 'Pump Shotgun',
    --         image = 'weapon_pumpshotgun_mk2',
    --         spawn = 'weapon_pumpshotgun_mk2',
    --         amount = 1,
    --         time = 4,
    --         requires = {
    --             { name = 'dirty_money', image = 'dirty_money', amount = 3500000 },
    --         },
    --     },


    --     {
    --         name = 'Ammo Pump Shotgun',
    --         image = 'ammo_pumpshotgun_mk2',
    --         spawn = 'ammo_pumpshotgun_mk2',
    --         amount = 100,
    --         time = 4,
    --         requires = {
    --             { name = 'dirty_money', image = 'dirty_money', amount = 3500000 },
    --         },
    --     },

    --     {
    --         name = 'Munição Glock Barbie',
    --         image = 'ammo_glockrelikiashopfeminino',
    --         spawn = 'ammo_glockrelikiashopfeminino',
    --         amount = 100,
    --         time = 4,
    --         requires = {
    --             { name = 'dirty_money', image = 'dirty_money', amount = 100000 },
    --         },
    --     },
    --     {
    --         name = 'Glock Barbie',
    --         image = 'weapon_glockrelikiashopfeminino',
    --         spawn = 'weapon_glockrelikiashopfeminino',
    --         amount = 1,
    --         time = 4,
    --         requires = {
    --             { name = 'dirty_money', image = 'dirty_money', amount = 1000000 },
    --         },
    --     },        
    --     {
    --         name = 'AR Tambor',
    --         image = 'weapon_artambor',
    --         spawn = 'weapon_artambor',
    --         amount = 1,
    --         time = 4,
    --         requires = {
    --             { name = 'dirty_money', image = 'dirty_money', amount = 1000000 },
    --         },
    --     },

    --     {
    --         name = 'Munição Tambor',
    --         image = 'ammo_artambor',
    --         spawn = 'ammo_artambor',
    --         amount = 100,
    --         time = 4,
    --         requires = {
    --             { name = 'dirty_money', image = 'dirty_money', amount = 100000 },
    --         },
    --     },

    --     {
    --         name = 'Munição Fuzil do Makakero',
    --         image = 'ammo_mgouroo',
    --         spawn = 'ammo_mgouroo',
    --         amount = 100,
    --         time = 4,
    --         requires = {
    --             { name = 'dirty_money', image = 'dirty_money', amount = 100000 },
    --         },
    --     },
    -- },

    