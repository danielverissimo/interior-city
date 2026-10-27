local cfg = {}
-- ITEM | NOME | DESC | TYPE | PESO | FOME | SEDE

cfg.items = {
	["none"] = { "none", "none", 0.0, nil, nil},
	["roupas"] = { "Roupas", "none", 0.0, nil, nil},
	["money"] = { "Dinheiro","none", 0.00001, nil, nil},
	
	-- ITENS VIP
	["alterarplaca"] = { "Alterar Placa", "usarVIP", 0.0, nil, nil},
	["alterarrg"] = { "Alterar RG", "usarVIP", 0.0, nil, nil},
	["alterartelefone"] = { "Alterar Telefone", "usarVIP", 0.0, nil, nil},
	["plastica"] = { "Plastica", "usarVIP", 0.0, nil, nil},
	["valemansao500k"] = { "Vale mansao 500k", "usarVIP", 0.0, nil, nil},
	["valemansao1m"] = { "Vale mansao 1m", "usarVIP", 0.0, nil, nil},
	["valemansao8m"] = { "Vale mansao 8m", "usarVIP", 0.0, nil, nil},
	["valemansao10m"] = { "Vale mansao 10m", "usarVIP", 0.0, nil, nil},
	["valemansao100m"] = { "Vale mansao 100m", "usarVIP", 0.0, nil, nil},

---------------------------------------------------------------
---- ESTAVAM FALTANDO

	["relogioroubado"] = { "Relogio", "none", 0.5, nil, nil},
	["colarroubado"] = { "Colar", "none", 0.1, nil, nil},
	["anelroubado"] = { "Anel", "none", 0.1, nil, nil},
	["brincoroubado"] = { "Brinco", "none", 0.1, nil, nil},
	["pulseiraroubada"] = { "Pulseira", "none", 0.1, nil, nil},

	["keycard"] = { "Keycard", "none", 1.5, nil, nil },
	["cartaovirgem"] = { "Cartão Virgem","none", 0.2, nil, nil},
	["pendrive"] = { "Pendrive Ilegal","none", 0.2, nil, nil},
	["c4"] = { "C4", "usar", 1.0, nil, nil},
	["contador"] = { "Contador", "usar", 0.3, nil, nil},
	["linha"] = { "Linha", "usar", 0.2, nil, nil},

	["rastreador_carro"] = { "Rastreador", "usar", 0.2, nil, nil},


------------------------------------------

	-- Utilitarios
	["mochila"] = { "Mochila", "usar", 2.0, nil, nil},
	-- ["skate"] = { "Skate", "usar", 1.0, nil, nil},
	["algemas"] = { "Algemas", "usar", 2.0, nil, nil},
	["ticket"] = { "Ticket Corrida", "usar", 1.0, nil, nil},
	-- ["ingresso"] = { "Ingresso", "usar", 1.0, nil, nil},
	-- ["plastico"] = { "Plástico", "usar", 1.0, nil, nil},
	-- ["distintivopolicial"] = { "Distintivo Policial", "usar", 0.3, nil, nil},
	["corda"] = { "Corda", "usar", 1.0, nil, nil},
	["chave_algemas"] = { "Chave de algemas", "usar", 0.3, nil, nil},
	["emptybottle"] = { "Garrafa Vazia", "usar", 0.2, nil, nil},
	-- ["attachs"] = { "Attachs", "usar", 0.2, nil, nil},
	["alianca"] = { "Alianca", "usar", 1.0, nil, nil},

	-- Mecanica
	["pneus"] = { "Pneus","usar", 10.0, nil, nil},
	["repairkit"] = { "Jogue Fora", "none", 1.0, nil, nil},
	["repairkit2"] = { "Jogue Fora", "usar", 1.0, nil, nil},
	["repairkit3"] = { "Kit de Reparos", "usar", 1.0, nil, nil},
	-- ["militec"] = { "Militec", "usar", 1.0, nil, nil},
	-- ["suspensaoar"] = { "Suspensaoar", "usar", 1.0, nil, nil},
	-- ["moduloneon"] = { "Moduloneon", "usar", 1.0, nil, nil},
	-- ["moduloxenon"] = { "Moduloxenon", "usar", 1.0, nil, nil},

	-- NITRO
	["kitnitro"] = { "Kit de Nitro", "usar", 1.0, nil, nil},
	["garrafanitro"] = { "Garrafa de Nitro", "usar", 1.0, nil, nil},
	["ferramenta"] = { "Ferramenta", "usar", 1.0, nil, nil},

	-- DIVERSAO
	["fireworks"] = { "Fogos de Artifício", "usar", 0.5, nil, nil},
	["laudoteorico"] = { "Furadeira", "none", 3.0, nil, nil},
	["notepad"] = { "Bloco de Notas", "usar", 0.5, nil, nil},

	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PESCA
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    ["isca"] = { "Isca", "none", 0.25, nil, nil},
    ["dourado"] = { "Dourado", "none", 3.0, nil, nil},
	["corvina"] = { "Corvina", "none", 2.0, nil, nil},
	["salmao"] = { "Salmao", "none", 1.0, nil, nil},

	-- Eletronicos
	["radio"] = { "Radio", "none", 1.0, nil, nil},
    ["celular"] = { "Celular", "none", 1.0, nil, nil},

	-- Itens para Roubar
	["keycard"] = { "Keycard", "none", 1.0, nil, nil},
	["c4"] = { "C4", "none", 5.0, nil, nil},
	["masterpick"] = { "MasterPick", "usar", 1.0, nil, nil},
	["pendrive"] = { "Pendrive", "none", 1.0, nil, nil},
	["lockpick"] = { "Lock Pick", "usar", 1.0, nil, nil},

	-- Itens Mafia
	["metal"] = { "Placa de Metal", "none", 0.3, nil, nil},
	["pecadearma"] = { "Peça de arma", "none", 0.3, nil, nil},
	["molas"] = { "Molas", "none", 0.3, nil, nil},
	["gatilho"] = { "Gatilho", "none", 0.40, nil, nil},
    ["aluminio"] = { "Aluminio", "none", 0.4, nil, nil},
    ["tecido"] = { "Tecido", "none", 0.40, nil, nil},

	-- Itens Cartel
	
	["polvora"] = { "Polvora", "none", 0.05, nil, nil},
	["capsulas"] = { "Cápsulas", "none", 0.05, nil, nil},

	-- Itens Lavagem
	["l-alvejante"] = { "Alvejante", "none", 0.40, nil, nil},

	-- Itens Drogas

	----------- maconha

	["baseado"] = { "Baseado", "usar", 1.0, nil, nil},
	["resinacannabis"] = { "Resina de Cannabis", "none", 0.3, nil, nil},  
	["adubo"] =  { "Adubo de maconha", "none", 0.3, nil, nil},
	["folhamaconha"] = { "Folha de Maconha", "none", 0.3, nil, nil},
    ["maconha"] = { "Maconha", "usar", 1.0, nil, nil},
	["malote-maconha"] = { "Malote de Maconha", "usar", 1.0, nil, nil},

	---------- cocaina

	["folhadecoca"] = { "Folha de Cocaina", "none", 0.3, nil, nil},
	["acido"] = { "Acido", "none", 0.2, nil, nil},
	["podecocaina"] = { "Pó de Cocaina", "none", 0.2, nil, nil},
    ["pastabase"] = { "Pasta Base", "none", 0.3, nil, nil},
    ["cocaina"] = { "Cocaina", "usar", 1.0, nil, nil},

	-------- metanfetamina

	["efedrina"] = { "Efedrina", "none", 0.3, nil, nil},
	["toulene"] = { "Toulene", "none", 0.3, nil, nil},
	["benzoato"] = { "Benzoato", "none", 0.3, nil, nil},
	-- ["acidolsd"] = { "Acido LSD", "none", 0.3, nil, nil},
	["anfetamina"] = { "Anfetamina", "none", 0.3, nil, nil},
	["metanfetamina"] = { "Metanfetamina ", "usar", 1.0, nil, nil},

    -- Ilegal
	["body_armor"] = { "Colete", "usar", 5.0, nil, nil},
    ["capuz"] = { "capuz", "usar", 0.1, nil, nil},
    ["dirty_money"] = { "Dinheiro Sujo", "none", 0.00001, nil, nil},
    ["scubagear"] = { "Kit de Mergulho", "usar", 10.0, nil, nil},

	-- Itens Joalheria
	-- ["relogioroubado"] = { "Relogio", "none", 0.5, nil, nil},
	-- ["colarroubado"] = { "Colar", "none", 0.1, nil, nil},
	-- ["anelroubado"] = { "Anel", "none", 0.1, nil, nil},
	-- ["brincoroubado"] = { "Brinco", "none", 0.1, nil, nil},
	-- ["pulseiraroubada"] = { "Pulseira", "none", 0.1, nil, nil},

	-- Corda e Capuz

	-- ["fibradecarbono"] = { "Fibra de Carbono", "none", 0.3, nil, nil},
	["papel"] = { "Papel", "none", 0.3, nil, nil},
	-- ["poliester"] = { "Poliester", "none", 0.3, nil, nil},

    -- Drogas
	["lsd"] = { "LSD", "usar", 0.3, nil, nil}, 
	-- ["morfina"] = { "Morfina", "none", 0.3, nil, nil},
	-- ["heroina"] = { "Heroina", "usar", 1.0, nil, nil},

	-- ["balinha"] = { "Balinha", "usar", 1.0, nil, nil},
	-- ["lancaperfume"] = {"Lança Perfume", "none", 0.3, nil, nil},
	-- ["podemd"] = { "Pó de MD", "none", 0.3, nil, nil},

    -- Pescaria
    ["isca"] = { "Isca", "none", 0.25, nil, nil},
    ["pacu"] = { "Pacu", "none", 1.5, nil, nil},
    ["tilapia"] = { "Tilapia", "none", 0.50, nil, nil},
    ["tucunare"] = { "Tucunare", "none", 2.0, nil, nil},

    -- -- Lenhador
    -- ["madeira"] = { "Madeira", "none", 2.5, nil, nil},

	-- -- Graos
    -- ["graosimpuros"] = { "Graos", "none", 1.0, nil, nil},
    -- ["tomate"] = { "Tomate", "none", 1.0, nil, nil},

    -- ["goiaba"] = { "Goiaba", "none", 1.0, nil, nil},
    -- ["maracuja"] = { "Maracujá", "none", 1.0, nil, nil},
    -- ["laranja"] = { "Laranja", "none", 1.0, nil, nil},
    -- ["manga"] = { "Manga", "none", 1.0, nil, nil},
    -- ["maca"] = { "Maça", "none", 1.0, nil, nil},
	
	-- Mineracao
	["bronze"] = { "Bronze", "none", 1.0, nil, nil},
	["ferro"] = { "Ferro", "none", 0.4, nil, nil},
	["ouro"] = { "Ouro", "none", 1.0, nil, nil},
	["diamante"] = { "Diamante", "none", 1.0, nil, nil},
	["rubi"] = { "Rubi", "none", 1.0, nil, nil},
	["safira"] = { "Safira", "none", 1.0, nil, nil},

	-- COMIDAS

	["pao"] = { "Pao", "comer", 0.5, -18, nil},
	["sanduiche"] = { "Sanduiche", "comer", 0.5, -32, nil},
	["hamburguer"] = { "Hamburguer", "comer", 0.5, -32, nil},
	["pizza"] = { "Pizza", "comer", 1.5, -38, nil},
	["barrac"] = { "Barra de chocolate", "comer", 0.5, -14, nil},
	["cachorroq"] = { "Cachorro Quente", "comer", 0.5, -30, nil},
	["pipoca"] = { "Pipoca", "comer", 0.3, -12, nil},
	["donut"] = { "Donut", "comer", 0.2, -16, nil},
	["paoq"] = { "Pao de Queijo", "comer", 0.3, -20, nil},
	["marmita"] = { "Marmitex", "comer", 2.0, -50, nil},
	["coxinha"] = { "Coxinha", "comer", 0.5, -24, nil},

	-- BEBIDAS
	["sprunk"] = { "Sprunk", "beber", 0.5, nil, -22},
	["sucol"] = { "Suco de Laranja", "beber", 0.5, nil, -36},
	["sucol2"] = { "Suco de Limao", "beber", 0.5, nil, -34},
	["water"] = { "Agua", "beber", 0.5, nil, -45},
	["cafe"] = { "Cafe", "beber", 0.25, nil, -20},
	["energetico"] = { "Energetico", "beber", 0.25, nil, -28},

	-------------------------------------------------------------------

	-- ALCOLICAS FOME/SEDE
	["vodka"] = { "Vodka", "bebera", 1.0, 10, -7},
	["cerveja"] = { "Cerveja", "bebera", 0.5, 3, -10},
	["corote"] = { "Corote", "bebera", 0.5, 20, -10},
	["pinga"] = { "Pinga", "bebera", 1.0, 15, -10},
	["whisky"] = { "Whisky", "bebera", 1.0, 10, -8}, 
	["absinto"] = { "Absinto", "bebera", 0.5, 10, -10},
	["skolb"] = { "Skol Beats", "bebera", 0.25, 5, -13},

	-- REMEDIOS
	["amoxilina"] = { "Amoxilina", "remedio", 0.05, 5, nil},
	["cataflan"] = { "Cataflan", "remedio", 0.05, 5, nil},
	["cicatricure"] = { "Cicatricure", "remedio", 0.05, 5, nil},
	["clozapina"] = { "Clozapina", "remedio", 0.05, 5, nil},
	["dipirona"] = { "Dipirona", "remedio", 0.05, 5, nil},
	["paracetamol"] = { "Paracetamol", "remedio", 0.05, 5, nil},
	["rivotril"] = { "Rivotril", "remedio", 0.05, 5, nil},
	["riopan"] = { "Riopan", "remedio", 0.05, 5, nil},
	["luftal"] = { "Luftal", "remedio", 0.05, 5, nil},
	["coumadin"] = { "Coumadin", "remedio", 0.05, 5, nil},
	["dorflex"] = { "Dorflex", "remedio", 0.05, 5, nil},
	["anticoncepcional"] = { "Anticoncepcional", "remedio", 0.05, 5, nil},
	["camisinha"] = { "Camisinha", "remedio", 0.05, 5, nil},
	["fluoxetina"] = { "Fluoxetina", "remedio", 0.05, 5, nil},
	["bandagem"] = { "Bandagem", "remedio", 0.5, 5, nil},
	
	-- PISTOLAS
	
	["WEAPON_SNSPISTOL_MK2"] = { "Fajuta", "equipar", 3.0, nil, nil},
	["AMMO_SNSPISTOL_MK2"] = { "M-Fajuta", "recarregar", 0.05, nil, nil},

	["WEAPON_HEAVYPISTOL"] = { "HeavyPistol", "equipar", 3.0, nil, nil},
	["AMMO_HEAVYPISTOL"] = { "M-HeavyPistol", "recarregar", 0.05, nil, nil},
	 
	["WEAPON_PISTOL_MK2"] = { "Five-Seven", "equipar", 3.0, nil, nil},
	["AMMO_PISTOL_MK2"] = { "M-Five-Seven", "recarregar", 0.05, nil, nil},

		 
	["WEAPON_PISTOL"] = { "Pistola", "equipar", 3.0, nil, nil},
	["AMMO_PISTOL"] = { "M-Pistola", "recarregar", 0.05, nil, nil},


	["WEAPON_SNOWBALL"] = { "Bola de Neve", "equipar", 3.0, nil, nil},
	["AMMO_SNOWBALL"] = { "M-Bola de Neve", "recarregar", 0.05, nil, nil},

	["WEAPON_FIREWORK"] = { "Fogos", "equipar", 3.0, nil, nil},
	["WEAPON_SNOWBALL"] = { "Bola de Neve", "equipar", 3.0, nil, nil},
	["WEAPON_BZGAS"] = { "Gas", "equipar", 3.0, nil, nil},
	["WEAPON_REVOLVER_MK2"] = { "Revolver", "equipar", 3.0, nil, nil},

	["AMMO_FIREWORK"] = { "M-Fogos", "recarregar", 0.05, nil, nil},
	["AMMO_SNOWBALL"] = { "M-Bola", "recarregar", 0.05, nil, nil},
	["AMMO_BZGAS"] = { "M-Gas", "recarregar", 0.05, nil, nil},
	["AMMO_REVOLVER_MK2"] = { "M-Revolver", "recarregar", 0.05, nil, nil},



	["WEAPON_GUSENBERG"] = { "Submetralhadora Thompson", "equipar", 3.0, nil, nil},
	["AMMO_GUSENBERG"] = { "M-Thompson", "recarregar", 0.05, nil, nil},

	["WEAPON_PISTOL50"] = { "Desert Eagle", "equipar", 3.0, nil, nil},
	["AMMO_PISTOL50"] = { "M-Desert", "recarregar", 0.05, nil, nil},

	["WEAPON_MILITARYRIFLE"] = { "MilitaryRifle", "equipar", 8.0, nil, nil},
	["AMMO_MILITARYRIFLE"] = { "M-MilitaryRifle", "recarregar", 0.05, nil, nil},

	["WEAPON_COMBATPISTOL"] = { "Glock", "equipar", 3.0, nil, nil},
	["AMMO_COMBATPISTOL"] = { "M-Glock", "recarregar", 0.05, nil, nil},

	["WEAPON_COMBATPDW"] = { "Combat Pdw", "equipar", 3.0, nil, nil},
	["AMMO_COMBATPDW"] = { "M-Pdw", "recarregar", 0.05, nil, nil},

	-- MACHADOS
	["WEAPON_HATCHET"] = { "Machados", "equipar", 3.0, nil, nil},
	["WEAPON_KNIFE"] = { "Faca", "equipar", 3.0, nil, nil},
	["WEAPON_DAGGER"] = { "Dagger", "equipar", 3.0, nil, nil},
	["WEAPON_KNUCKLE"] = { "Knuckle", "equipar", 3.0, nil, nil},
	["WEAPON_MACHETE"] = { "Machete", "equipar", 3.0, nil, nil},
	["WEAPON_SWITCHBLADE"] = { "SwitchBlade", "equipar", 3.0, nil, nil},
	["WEAPON_WRENCH"] = { "Wrench", "equipar", 3.0, nil, nil},
	["WEAPON_HAMMER"] = { "Hammer", "equipar", 3.0, nil, nil},
	["WEAPON_GOLFCLUB"] = { "GolfClub", "equipar", 3.0, nil, nil},
	["WEAPON_CROWBAR"] = { "CrowBar", "equipar", 3.0, nil, nil},
	["WEAPON_FLASHLIGHT"] = { "Lanterna", "equipar", 3.0, nil, nil},
	["WEAPON_BAT"] = { "Bastão de Beisebol", "equipar", 3.0, nil, nil},
	["WEAPON_BOTTLE"] = { "Bottle", "equipar", 3.0, nil, nil},
	["WEAPON_BATTLEAXE"] = { "Battleaxe", "equipar", 3.0, nil, nil},
	["WEAPON_POOLCUE"] = { "Poolcue", "equipar", 3.0, nil, nil},
	["GADGET_PARACHUTE"] = { "Paraquedas", "equipar", 3.0, nil, nil},
	["WEAPON_FLARE"] = { "Sinalizador", "equipar", 3.0, nil, nil},
	
	-- SUBMETRALHADORA
	["WEAPON_MACHINEPISTOL"] = { "Tec-9", "equipar", 6.0, nil, nil},
	["AMMO_MACHINEPISTOL"] = { "M-Tec-9", "recarregar", 0.05, nil, nil},

	["WEAPON_SMG_MK2"] = { "Smg MK2", "equipar", 6.0, nil, nil},
	["AMMO_SMG_MK2"] = { "M-Smg MK2", "recarregar", 0.05, nil, nil},

	["WEAPON_SMG"] = { "SMG", "equipar", 6.0, nil, nil},
	["AMMO_SMG"] = { "M-SMG", "recarregar", 0.05, nil, nil},


	["WEAPON_MICROSMG"] = { "MICROSMG", "equipar", 6.0, nil, nil},
	["AMMO_MICROSMG"] = { "M-MICROSMG", "recarregar", 0.05, nil, nil},

	["WEAPON_ASSAULTSMG"] = { "MTAR", "equipar", 6.0, nil, nil},
	["AMMO_ASSAULTSMG"] = { "M-MTAR", "recarregar", 0.05, nil, nil},

	-- SHOTGUN
	["WEAPON_SAWNOFFSHOTGUN"] = { "Shotgun", "equipar", 8.0, nil, nil},
	["AMMO_SAWNOFFSHOTGUN"] = { "M-Shotgun", "recarregar", 0.05, nil, nil},

	["WEAPON_PUMPSHOTGUN_MK2"] = { "Pump Shotgun", "equipar", 8.0, nil, nil},
	["AMMO_PUMPSHOTGUN_MK2"] = { "M-Pump Shotgun", "recarregar", 0.05, nil, nil},

	-- FUZIL
	["WEAPON_ASSAULTRIFLE"] = { "AK 47", "equipar", 8.0, nil, nil},
	["AMMO_ASSAULTRIFLE"] = { "M-AK-47", "recarregar", 0.05, nil, nil},
	["WEAPON_ASSAULTRIFLE_MK2"] = { "AK MK2", "equipar", 8.0, nil, nil},
	["AMMO_ASSAULTRIFLE_MK2"] = { "M-AK MK2", "recarregar", 0.05, nil, nil},

	["WEAPON_HEAVYSNIPER"] = { "SNIPER", "equipar", 8.0, nil, nil},
	["AMMO_HEAVYSNIPER"] = { "M-SNIPER", "recarregar", 0.05, nil, nil},
	

	["WEAPON_SPECIALCARBINE_MK2"] = { "G3", "equipar", 8.0, nil, nil},
	["AMMO_SPECIALCARBINE_MK2"] = { "M-G3", "recarregar", 0.05, nil, nil},

	["WEAPON_PARAFAL"] = { "PARAFAL", "equipar", 8.0, nil, nil},
	["AMMO_PARAFAL"] = { "M-PARAFAL", "recarregar", 0.05, nil, nil},

	["WEAPON_DOUBLEACTION"] = { "DOUBLEACTION", "equipar", 8.0, nil, nil},
	["AMMO_DOUBLEACTION"] = { "M-DOUBLEACTION", "recarregar", 0.05, nil, nil},

	["WEAPON_CARBINERIFLE"] = { "M4", "equipar", 8.0, nil, nil},
	["AMMO_CARBINERIFLE"] = { "M-M4", "recarregar", 0.05, nil, nil},
	["WEAPON_CARBINERIFLE_MK2"] = { "M4", "equipar", 8.0, nil, nil},
	["AMMO_CARBINERIFLE_MK2"] = { "M-M4", "recarregar", 0.05, nil, nil},

	["WEAPON_SPECIALCARBINE"] = { "Parafal", "equipar", 8.0, nil, nil},
	["AMMO_SPECIALCARBINE"] = { "M-Parafal", "recarregar", 0.05, nil, nil},
	
	-- TAZER
	["WEAPON_STUNGUN"] = { "Tazer", "equipar", 1.0, nil, nil},

	-- GALAO DE GASOLINA
	["WEAPON_PETROLCAN"] = { "Galão de gasolina", "equipar", 1.0, nil, nil},
	["AMMO_PETROLCAN"] = { "Gasolina", "equipar", 0.05, nil, nil},



}

-- GTA_STANDARD_CFG_WEAPONS_BEGIN
local GTA_STANDARD_CFG_WEAPONS = {
    "WEAPON_KNIFE",
    "WEAPON_NIGHTSTICK",
    "WEAPON_HAMMER",
    "WEAPON_BAT",
    "WEAPON_GOLFCLUB",
    "WEAPON_CROWBAR",
    "WEAPON_BOTTLE",
    "WEAPON_DAGGER",
    "WEAPON_HATCHET",
    "WEAPON_KNUCKLE",
    "WEAPON_MACHETE",
    "WEAPON_FLASHLIGHT",
    "WEAPON_SWITCHBLADE",
    "WEAPON_BATTLEAXE",
    "WEAPON_POOLCUE",
    "WEAPON_WRENCH",
    "WEAPON_STONE_HATCHET",
    "WEAPON_CANDYCANE",
    "WEAPON_STUNROD",
    "WEAPON_PISTOL",
    "WEAPON_PISTOL_MK2",
    "WEAPON_COMBATPISTOL",
    "WEAPON_APPISTOL",
    "WEAPON_PISTOL50",
    "WEAPON_SNSPISTOL",
    "WEAPON_SNSPISTOL_MK2",
    "WEAPON_HEAVYPISTOL",
    "WEAPON_VINTAGEPISTOL",
    "WEAPON_FLAREGUN",
    "WEAPON_MARKSMANPISTOL",
    "WEAPON_REVOLVER",
    "WEAPON_REVOLVER_MK2",
    "WEAPON_DOUBLEACTION",
    "WEAPON_RAYPISTOL",
    "WEAPON_CERAMICPISTOL",
    "WEAPON_NAVYREVOLVER",
    "WEAPON_GADGETPISTOL",
    "WEAPON_PISTOLXM3",
    "WEAPON_STUNGUN",
    "WEAPON_STUNGUN_MP",
    "WEAPON_MICROSMG",
    "WEAPON_SMG",
    "WEAPON_SMG_MK2",
    "WEAPON_ASSAULTSMG",
    "WEAPON_COMBATPDW",
    "WEAPON_MACHINEPISTOL",
    "WEAPON_MINISMG",
    "WEAPON_RAYCARBINE",
    "WEAPON_TECPISTOL",
    "WEAPON_MG",
    "WEAPON_COMBATMG",
    "WEAPON_COMBATMG_MK2",
    "WEAPON_GUSENBERG",
    "WEAPON_ASSAULTRIFLE",
    "WEAPON_ASSAULTRIFLE_MK2",
    "WEAPON_CARBINERIFLE",
    "WEAPON_CARBINERIFLE_MK2",
    "WEAPON_ADVANCEDRIFLE",
    "WEAPON_SPECIALCARBINE",
    "WEAPON_SPECIALCARBINE_MK2",
    "WEAPON_BULLPUPRIFLE",
    "WEAPON_BULLPUPRIFLE_MK2",
    "WEAPON_COMPACTRIFLE",
    "WEAPON_MILITARYRIFLE",
    "WEAPON_HEAVYRIFLE",
    "WEAPON_TACTICALRIFLE",
    "WEAPON_BATTLERIFLE",
    "WEAPON_SNIPERRIFLE",
    "WEAPON_HEAVYSNIPER",
    "WEAPON_HEAVYSNIPER_MK2",
    "WEAPON_MARKSMANRIFLE",
    "WEAPON_MARKSMANRIFLE_MK2",
    "WEAPON_PRECISIONRIFLE",
    "WEAPON_PUMPSHOTGUN",
    "WEAPON_PUMPSHOTGUN_MK2",
    "WEAPON_SAWNOFFSHOTGUN",
    "WEAPON_BULLPUPSHOTGUN",
    "WEAPON_ASSAULTSHOTGUN",
    "WEAPON_MUSKET",
    "WEAPON_HEAVYSHOTGUN",
    "WEAPON_DBSHOTGUN",
    "WEAPON_AUTOSHOTGUN",
    "WEAPON_COMBATSHOTGUN",
    "WEAPON_GRENADELAUNCHER",
    "WEAPON_GRENADELAUNCHER_SMOKE",
    "WEAPON_RPG",
    "WEAPON_MINIGUN",
    "WEAPON_FIREWORK",
    "WEAPON_RAILGUN",
    "WEAPON_RAILGUNXM3",
    "WEAPON_HOMINGLAUNCHER",
    "WEAPON_COMPACTLAUNCHER",
    "WEAPON_RAYMINIGUN",
    "WEAPON_EMPLAUNCHER",
    "WEAPON_SNOWLAUNCHER",
    "WEAPON_GRENADE",
    "WEAPON_BZGAS",
    "WEAPON_MOLOTOV",
    "WEAPON_STICKYBOMB",
    "WEAPON_PROXMINE",
    "WEAPON_SNOWBALL",
    "WEAPON_PIPEBOMB",
    "WEAPON_BALL",
    "WEAPON_SMOKEGRENADE",
    "WEAPON_FLARE",
    "WEAPON_FIREEXTINGUISHER",
    "WEAPON_PETROLCAN",
    "WEAPON_HAZARDCAN",
    "WEAPON_FERTILIZERCAN",
    "WEAPON_HACKINGDEVICE",
    "WEAPON_DIGISCANNER",
    "WEAPON_REMOTESNIPER",
    "WEAPON_STINGER",
    "GADGET_PARACHUTE",
}
local GTA_CFG_NO_AMMO = {
    ["GADGET_PARACHUTE"] = true,
    ["WEAPON_BAT"] = true,
    ["WEAPON_BATTLEAXE"] = true,
    ["WEAPON_BOTTLE"] = true,
    ["WEAPON_CANDYCANE"] = true,
    ["WEAPON_CROWBAR"] = true,
    ["WEAPON_DAGGER"] = true,
    ["WEAPON_DIGISCANNER"] = true,
    ["WEAPON_FLASHLIGHT"] = true,
    ["WEAPON_GOLFCLUB"] = true,
    ["WEAPON_HACKINGDEVICE"] = true,
    ["WEAPON_HAMMER"] = true,
    ["WEAPON_HATCHET"] = true,
    ["WEAPON_KNIFE"] = true,
    ["WEAPON_KNUCKLE"] = true,
    ["WEAPON_MACHETE"] = true,
    ["WEAPON_NIGHTSTICK"] = true,
    ["WEAPON_POOLCUE"] = true,
    ["WEAPON_RAYPISTOL"] = true, -- Up-n-Atomizer recarrega sozinho; não usa item de munição.
    ["WEAPON_STONE_HATCHET"] = true,
    ["WEAPON_STUNGUN"] = true,
    ["WEAPON_STUNGUN_MP"] = true,
    ["WEAPON_STUNROD"] = true,
    ["WEAPON_SWITCHBLADE"] = true,
    ["WEAPON_WRENCH"] = true,
 }

local function gtaCfgWeaponName(weaponName)
    local clean = weaponName:gsub("^WEAPON_", ""):gsub("^GADGET_", ""):gsub("_", " "):lower()
    return (clean:gsub("(%a)([%w']*)", function(first, rest) return first:upper() .. rest end))
end

for _, weaponName in ipairs(GTA_STANDARD_CFG_WEAPONS) do
    if not cfg.items[weaponName] then
        cfg.items[weaponName] = { gtaCfgWeaponName(weaponName), "equipar", 3.0, nil, nil }
    end
    if not GTA_CFG_NO_AMMO[weaponName] and weaponName:sub(1, 7) == "WEAPON_" then
        local ammoName = "AMMO_" .. weaponName:gsub("^WEAPON_", "")
        if not cfg.items[ammoName] then
            cfg.items[ammoName] = { "M-" .. gtaCfgWeaponName(weaponName), "recarregar", 0.05, nil, nil }
        end
    end
end
-- GTA_STANDARD_CFG_WEAPONS_END

return cfg

