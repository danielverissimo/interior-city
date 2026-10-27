RANKING_UPDATE_INTERVAL = 15 --[[seconds]]
ADMIN_PERMISSION = "admin.permissao"

Config = {}

Config.Clothes = {}

Config.WeaponsKit = {
	["M4A4"] = {
		name = "WEAPON_CARBINERIFLE_MK2",
		ammo = 250,
		item = "weapon_carbinerifle_mk2",
		clip = 30,
	},
	["Parafal"] = {
		name = "WEAPON_PARAFAL",
		ammo = 250,
		item = "weapon_parafal",
		clip = 30,
	},
	["Mtar"] = {
		name = "WEAPON_ASSAULTSMG",
		ammo = 250,
		item = "weapon_assaultsmg",
		clip = 30,
	},
	["Pdw"] = {
		name = "WEAPON_COMBATPDW",
		ammo = 250,
		item = "weapon_combatpdw",
		clip = 30,
	},
	["Smg"] = {
		name = "WEAPON_SMG",
		ammo = 250,
		item = "weapon_smg",
		clip = 30,
	},
	["Glock"] = {
		name = "WEAPON_COMBATPISTOL",
		ammo = 250,
		item = "weapon_combatpistol",
		clip = 12,
	},
	["Taser"] = {
		name = "WEAPON_STUNGUN",
		ammo = 1,
		item = "weapon_stungun",
		clip = 1,
	},
	["Lanterna"] = {
		name = "WEAPON_FLASHLIGHT",
		ammo = 0,
		item = "weapon_flashlight",
		clip = 0,
	},
	["Cassetete"] = {
		name = "WEAPON_NIGHTSTICK",
		ammo = 0,
		item = "weapon_nightstick",
		clip = 0,
	},
}

Config.Orgs = {
	["PoliciaCivil"] = {
		coords = {
			vec3(-719.2, -2243.86, 13.45),
		},
		radioChannel = 1,
		groups = {
			["ComandanteGeralCivil"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["DelegadoGeral"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Delegado"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["investigador"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["ComandoInvestigativa"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["SubComandoInvestigativa"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["SubComandoDraco"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["AgenteDraco"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["EstagiarioDraco"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Perito"] = {
				WeaponsKit = { "Glock", "Lanterna", "Cassetete" },
			},
			["Agente"] = {
				WeaponsKit = { "Glock", "Lanterna", "Cassetete" },
			},
		},
	},
	["Bope"] = {
		coords = {
			vec3(-626.25, -2331.0, 13.82),
		},
		radioChannel = 2,
		groups = {
			["ComandanteGeralbope"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["SubComandantebope"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["TenenteCoronelbope"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Majorbope"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Capitaobope"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna", "Parafal", "Cassetete", "Pdw" },
			},
			["PrimeiroTenentebope"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["SegundoTenentebope"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["SubTenentebope"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["PrimeiroSargentobope"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["SegundoSargentobope"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["TerceiroSargentobope"] = {
				WeaponsKit = { "Glock", "Lanterna" },
			},
			["Cabobope"] = {
				WeaponsKit = { "Glock", "Lanterna" },
			},
			["Soldadobope"] = {
				WeaponsKit = { "Glock" },
			},
		},
	},
	["Policia"] = {
		coords = {
			vec3(441.02, -978.35, 30.68),
		},
		radioChannel = 7,
		offDutyGroup = "Paisana",
		offDutyTitle = "Paisana",
		autoCreateOffDuty = true,
		groups = {
			["CoronelPM"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["TenenteCoronelPM"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["MajorPM"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["CapitaoPM"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["PrimeiroTenentePM"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["SegundoTenentePM"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["SubTenentePM"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna", "Parafal", "Cassetete", "Pdw" },
			},
			["PrimeiroSargentoPM"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna", "Parafal", "Cassetete" },
			},
			["SegundoSargentoPM"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["TerceiroSargentoPM"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["CaboPM"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["CadetePM"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["AspirantePM"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["SoldadoPM"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["AlunoPM"] = {
				WeaponsKit = { "Glock", "Lanterna", "Cassetete" },
			},
			["Speed"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["Rocam"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["Grpae"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
		},
	},
	["Rota"] = {
		coords = {
			vec3(-947.89, -2040.6, 9.4),
		},
		radioChannel = 4,
		groups = {
			["Comando [ROTA]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["SubComando [ROTA]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Coronel [ROTA]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["TenenteCoronel [ROTA]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Major [ROTA]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Capitao [ROTA]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["PrimeiroTenente [ROTA]"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna", "Parafal", "Cassetete", "Pdw" },
			},
			["SegundoTenente [ROTA]"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna", "Parafal", "Cassetete" },
			},
			["Aspirante [ROTA]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["SubTenente [ROTA]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["PrimeiroSargento [ROTA]"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["SegundoSargento [ROTA]"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["TerceiroSargento [ROTA]"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["Cabo [ROTA]"] = {
				WeaponsKit = { "Smg", "Glock", "Lanterna", "Cassetete" },
			},
			["Soldado [ROTA]"] = {
				WeaponsKit = { "Smg", "Glock", "Lanterna", "Cassetete" },
			},
			["Aluno [ROTA]"] = {
				WeaponsKit = { "Glock", "Lanterna", "Cassetete" },
			},
		},
	},
	["Prf"] = {
		coords = {
			vec3(-440.3, 5996.77, 31.71),
		},
		radioChannel = 5,
		groups = {
			["DiretorGeral [PRF]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Diretor [PRF]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["SubDiretor [PRF]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Parafal", "Cassetete", "Pdw" },
			},
			["DelegadoGeral [PRF]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Delegado [PRF]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["CorregedorGeral [PRF]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Corregedor [PRF]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["SupervisorGeral [PRF]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["InspetorGeral [PRF]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Supervisor [PRF]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["Inspetor [PRF]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete" },
			},
			["AgenteOperacional [PRF]"] = {
				WeaponsKit = { "Glock", "Lanterna", "Cassetete" },
			},
			["AgentePrimeiraClasse [PRF]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete", "Pdw" },
			},
			["AgenteSegundaClasse [PRF]"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete" },
			},
			["AgenteTerceiraClasse [PRF]"] = {
				WeaponsKit = { "Smg", "Glock", "Lanterna" },
			},
			["Estagiario [PRF]"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna", "Cassetete" },
			},
		},
	},
	["Exercito"] = {
		coords = {
			vec3(-2214.93, 3180.69, 32.87),
			vec3(-594.14, -1059.56, 22.43),
		},
		radioChannel = 3,
		groups = {
			["Marechal [EXERCITO]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete", "Smg" },
			},
			["General [EXERCITO]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete", "Smg" },
			},
			["Coronel [EXERCITO]"] = {
				WeaponsKit = { "Parafal", "Pdw", "Glock", "Taser", "Lanterna", "Cassetete", "Smg" },
			},
			["TenenteCoronel [EXERCITO]"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna", "Parafal", "Cassetete", "Pdw", "Smg" },
			},
			["Major [EXERCITO]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete", "Smg" },
			},
			["Capitao [EXERCITO]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete", "Smg" },
			},
			["Tenente [EXERCITO]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete", "Smg" },
			},
			["Subtenente [EXERCITO]"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete", "Taser", "Smg" },
			},
			["Aspirante [EXERCITO]"] = {
				WeaponsKit = { "Parafal", "Glock", "Lanterna", "Cassetete", "Taser", "Smg" },
			},
			["Sargento [EXERCITO]"] = {
				WeaponsKit = { "Parafal", "Glock", "Taser", "Lanterna", "Cassetete", "Smg" },
			},
			["Cabo [EXERCITO]"] = {
				WeaponsKit = { "Smg", "Glock", "Lanterna", "Cassetete" },
			},
			["Soldado [EXERCITO]"] = {
				WeaponsKit = { "Smg", "Glock", "Lanterna", "Cassetete" },
			},
			["Recruta [EXERCITO]"] = {
				WeaponsKit = { "Glock", "Lanterna", "Cassetete" },
			},
		},
	},
	["Driftking"] = {
		coords = {
			vec3(918.93, -2043.33, 30.62),
		},
		radioChannel = 21,
		groups = {
			["Lider [DRIFTKING]"] = {
				WeaponsKit = {},
			},
			["Sub-Lider [DRIFTKING]"] = {
				WeaponsKit = {},
			},
			["Gerente [DRIFTKING]"] = {
				WeaponsKit = {},
			},
			["Recrutador [DRIFTKING]"] = {
				WeaponsKit = {},
			},
			["Mecanico [DRIFTKING]"] = {
				WeaponsKit = {},
			},
			["Novato [DRIFTKING]"] = {
				WeaponsKit = {},
			},
		},
	},
	["LSCustoms"] = {
		coords = {
			vec3(-338.72, -157.70, 44.58),
		},
		radioChannel = 20,
		offDutyGroup = "PaisanaLSCustoms",
		offDutyTitle = "Paisana - LS Customs",
		autoCreateOffDuty = true,
		groups = {
			["LiderLSCustoms"] = { WeaponsKit = {} },
			["SubLiderLSCustoms"] = { WeaponsKit = {} },
			["GerenteGeralLSCustoms"] = { WeaponsKit = {} },
			["GerenteLSCustoms"] = { WeaponsKit = {} },
			["SupervisorLSCustoms"] = { WeaponsKit = {} },
			["MecanicoLSCustoms"] = { WeaponsKit = {} },
			["EstagiarioLSCustoms"] = { WeaponsKit = {} },
		},
	},
	["RedLine"] = {
		coords = {
			vec3(2746.63, 3505.09, 55.25),
		},
		radioChannel = 22,
		offDutyGroup = "PaisanaRedLine",
		offDutyTitle = "Paisana - RedLine",
		autoCreateOffDuty = true,
		groups = {
			["LiderRedLine"] = { WeaponsKit = {} },
			["SubLiderRedLine"] = { WeaponsKit = {} },
			["GerenteRedLine"] = { WeaponsKit = {} },
			["RecrutadorRedLine"] = { WeaponsKit = {} },
			["MembroRedLine"] = { WeaponsKit = {} },
			["NovatoRedLine"] = { WeaponsKit = {} },
		},
	},
	["SportRacer"] = {
		coords = {
			vec3(917.41, -950.55, 44.25),
		},
		radioChannel = 23,
		offDutyGroup = "PaisanaSportRacer",
		offDutyTitle = "Paisana - Sport Racer",
		autoCreateOffDuty = true,
		groups = {
			["LiderSPORTRACER"] = { WeaponsKit = {} },
			["SubLiderSPORTRACER"] = { WeaponsKit = {} },
			["GerenteSPORTRACER"] = { WeaponsKit = {} },
			["RecrutadorSPORTRACER"] = { WeaponsKit = {} },
			["MembroSPORTRACER"] = { WeaponsKit = {} },
			["NovatoSPORTRACER"] = { WeaponsKit = {} },
		},
	},
	["Hospital"] = {
		coords = {
			vec3(1138.69, -1543.80, 35.38),
			vec3(-533.23, 7377.54, 12.84),
			vec3(-2794.95, -68.87, 18.11),
		},
		radioChannel = 192,
		offDutyGroup = "PaisanaHospital",
		offDutyTitle = "Paisana - Hospital",
		autoCreateOffDuty = true,
		groups = {
			["Diretor"] = { WeaponsKit = {} },
			["ViceDiretor"] = { WeaponsKit = {} },
			["Gestao"] = { WeaponsKit = {} },
			["Psiquiatra"] = { WeaponsKit = {} },
			["Medico"] = { WeaponsKit = {} },
			["Enfermeiro"] = { WeaponsKit = {} },
			["Socorrista"] = { WeaponsKit = {} },
		},
	},
	["Jornal"] = {
		coords = {
			vec3(-594.77, -933.56, 28.83),
		},
		radioChannel = 139,
		groups = {
			["DiretorJornal"] = {
				WeaponsKit = {},
			},
			["SubDiretorJornal"] = {
				WeaponsKit = {},
			},
			["ProdutorJornal"] = {
				WeaponsKit = {},
			},
			["Reporter"] = {
				WeaponsKit = {},
			},
			["EstagiarioJornal"] = {
				WeaponsKit = {},
			},
		},
	},
	["Bombeiro"] = {
		coords = {
			vec3(1569.26, 829.34, 82.04),
		},
		radioChannel = 193,
		groups = {
			["ComandoGeralBombeiro"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna" },
			},
			["SubComandoBombeiro"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna" },
			},
			["CoronelBombeiro"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna" },
			},
			["TenenteCoronelBombeiro"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna" },
			},
			["MajorBombeiro"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna" },
			},
			["CapitaoBombeiro"] = {
				WeaponsKit = { "Glock", "Taser", "Lanterna" },
			},
			["TenenteBombeiro"] = {
				WeaponsKit = { "Taser", "Lanterna" },
			},
			["SubtenenteBombeiro"] = {
				WeaponsKit = { "Taser", "Lanterna" },
			},
			["SargentoBombeiro"] = {
				WeaponsKit = { "Taser", "Lanterna" },
			},
			["CaboBombeiro"] = {
				WeaponsKit = { "Taser", "Lanterna" },
			},
			["SoldadoBombeiro"] = {
				WeaponsKit = { "Taser", "Lanterna" },
			},
			["AspiranteBombeiro"] = {
				WeaponsKit = { "Taser", "Lanterna" },
			},
			["CadeteBombeiro"] = {
				WeaponsKit = { "Taser", "Lanterna" },
			},
		},
	},
	["Judiciario"] = {
		coords = {
			vec3(233.48, -417.71, 48.09),
		},
		radioChannel = 113,
		groups = {
			["Juiz"] = {
				WeaponsKit = { "Glock", "Taser", "Cassetete" },
			},
			["Procurador"] = {
				WeaponsKit = { "Glock", "Taser", "Cassetete" },
			},
			["Promotor"] = {
				WeaponsKit = { "Glock", "Taser", "Cassetete" },
			},
			["Advogado"] = {
				WeaponsKit = {},
			},
			["Desembargador"] = {
				WeaponsKit = { "Glock", "Taser", "Cassetete" },
			},
			["Supervisor"] = {
				WeaponsKit = {},
			},
			["PresidenteOab"] = {
				WeaponsKit = {},
			},
			["SegurancaForum"] = {
				WeaponsKit = { "Glock", "Taser", "Cassetete" },
			},
			["RepresentanteDp"] = {
				WeaponsKit = {},
			},
			["EstagiarioJudiciario"] = {
				WeaponsKit = {},
			},
		},
	},
}
