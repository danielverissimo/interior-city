-- ============================================================================
-- VRP_ADMIN -> MAGE ADMIN CENTRAL AUDIT LOGS
-- ============================================================================
-- Camada única de auditoria para comandos administrativos do vrp_admin.
-- Não altera as permissões nem a lógica dos comandos: apenas registra o uso
-- por staff/console e envia para o catálogo central do m_paineladm_v2.
-- ============================================================================

AdminAudit = AdminAudit or {}

local PANEL_RESOURCE <const> = "m_paineladm_v2"
local MAX_PENDING <const> = 400
local FLUSH_INTERVAL <const> = 10000
local pendingLogs = {}
local NativeRegisterCommand = RegisterCommand

AdminAudit.CommandCatalog = {
    ["aa"] = { key = "vrp_admin_cmd_aa", description = "Registrou a utilização do comando /aa do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["abrirbaufac"] = { key = "vrp_admin_cmd_abrirbaufac", description = "Registrou a utilização do comando /abrirbaufac do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["acao"] = { key = "vrp_admin_cmd_acao", description = "Registrou a utilização do comando /acao do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["acaoid"] = { key = "vrp_admin_cmd_acaoid", description = "Registrou a utilização do comando /acaoid do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["addallcars"] = { key = "vrp_admin_cmd_addallcars", description = "Adicionou o veículo configurado a todos os jogadores online via console." },
    ["addbl"] = { key = "vrp_admin_cmd_addbl", description = "Registrou a utilização do comando /addbl do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["addcar"] = { key = "vrp_admin_cmd_addcar", description = "Adicionou um veículo à garagem de um jogador.", targetArg = 1 },
    ["addevento"] = { key = "vrp_admin_cmd_addevento", description = "Registrou a utilização do comando /addevento do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["addeventoarea"] = { key = "vrp_admin_cmd_addeventoarea", description = "Registrou a utilização do comando /addeventoarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["addinsta"] = { key = "vrp_admin_cmd_addinsta", description = "Registrou a utilização do comando /addinsta do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["addmakapoints"] = { key = "vrp_admin_cmd_addmakapoints", description = "Registrou a utilização do comando /addmakapoints do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["addorgblacklist"] = { key = "vrp_admin_cmd_addorgblacklist", description = "Registrou a utilização do comando /addorgblacklist do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["addponto"] = { key = "vrp_admin_cmd_addponto", description = "Registrou a utilização do comando /addponto do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["addporte"] = { key = "vrp_admin_cmd_addporte", description = "Registrou a utilização do comando /addporte do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["admincv"] = { key = "vrp_admin_cmd_admincv", description = "Registrou a utilização do comando /admincv do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["alterarid"] = { key = "vrp_admin_cmd_alterarid", description = "Alterou o ID/passaporte de um jogador no banco de dados.", targetArg = 1 },
    ["apzban"] = { key = "vrp_admin_cmd_apzban", description = "Executou a rotina especial de banimento /apzban." },
    ["arrumarportamalas"] = { key = "vrp_admin_cmd_arrumarportamalas", description = "Executou correção administrativa de porta-malas." },
    ["auroradimensao"] = { key = "vrp_admin_cmd_auroradimensao", description = "Registrou a utilização do comando /auroradimensao do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["aviso69"] = { key = "vrp_admin_cmd_aviso69", description = "Registrou a utilização do comando /aviso69 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisoadm"] = { key = "vrp_admin_cmd_avisoadm", description = "Enviou um aviso administrativo global." },
    ["avisoadm2"] = { key = "vrp_admin_cmd_avisoadm2", description = "Registrou a utilização do comando /avisoadm2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisoadm3"] = { key = "vrp_admin_cmd_avisoadm3", description = "Registrou a utilização do comando /avisoadm3 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisobombeiro"] = { key = "vrp_admin_cmd_avisobombeiro", description = "Registrou a utilização do comando /avisobombeiro do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisobombeiro2"] = { key = "vrp_admin_cmd_avisobombeiro2", description = "Registrou a utilização do comando /avisobombeiro2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisocb"] = { key = "vrp_admin_cmd_avisocb", description = "Registrou a utilização do comando /avisocb do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisocreche"] = { key = "vrp_admin_cmd_avisocreche", description = "Registrou a utilização do comando /avisocreche do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisofac"] = { key = "vrp_admin_cmd_avisofac", description = "Registrou a utilização do comando /avisofac do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisohp"] = { key = "vrp_admin_cmd_avisohp", description = "Registrou a utilização do comando /avisohp do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisoilegal"] = { key = "vrp_admin_cmd_avisoilegal", description = "Registrou a utilização do comando /avisoilegal do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisomec"] = { key = "vrp_admin_cmd_avisomec", description = "Registrou a utilização do comando /avisomec do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisopm"] = { key = "vrp_admin_cmd_avisopm", description = "Registrou a utilização do comando /avisopm do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["avisostaff"] = { key = "vrp_admin_cmd_avisostaff", description = "Enviou uma comunicação destinada à equipe/staff." },
    ["avisovip"] = { key = "vrp_admin_cmd_avisovip", description = "Registrou a utilização do comando /avisovip do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["barreira"] = { key = "vrp_admin_cmd_barreira", description = "Registrou a utilização do comando /barreira do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["bb"] = { key = "vrp_admin_cmd_bb", description = "Registrou a utilização do comando /bb do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["BIOWNDWllIIiiLLljI"] = { key = "vrp_admin_cmd_biowndwlliiiilllji", description = "Registrou a utilização do comando /BIOWNDWllIIiiLLljI do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["bloquearfaccao"] = { key = "vrp_admin_cmd_bloquearfaccao", description = "Registrou a utilização do comando /bloquearfaccao do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["blpolicia"] = { key = "vrp_admin_cmd_blpolicia", description = "Registrou a utilização do comando /blpolicia do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["bolinha"] = { key = "vrp_admin_cmd_bolinha", description = "Registrou a utilização do comando /bolinha do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["bolinha2"] = { key = "vrp_admin_cmd_bolinha2", description = "Registrou a utilização do comando /bolinha2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["calaboca"] = { key = "vrp_admin_cmd_calaboca", description = "Registrou a utilização do comando /calaboca do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["calabocaarea"] = { key = "vrp_admin_cmd_calabocaarea", description = "Aplicou silenciamento em jogadores de uma área." },
    ["capuz"] = { key = "vrp_admin_cmd_capuz", description = "Colocou/retirou capuz de um jogador através do comando administrativo.", targetArg = 1 },
    ["car"] = { key = "vrp_admin_cmd_car", description = "Spawnou um veículo através do comando administrativo." },
    ["carcolor"] = { key = "vrp_admin_cmd_carcolor", description = "Alterou a cor de um veículo pela rotina administrativa." },
    ["carseat"] = { key = "vrp_admin_cmd_carseat", description = "Registrou a utilização do comando /carseat do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["cds"] = { key = "vrp_admin_cmd_cds", description = "Registrou a utilização do comando /cds do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["cds2"] = { key = "vrp_admin_cmd_cds2", description = "Registrou a utilização do comando /cds2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["cds3"] = { key = "vrp_admin_cmd_cds3", description = "Registrou a utilização do comando /cds3 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["cdsgaragem"] = { key = "vrp_admin_cmd_cdsgaragem", description = "Registrou a utilização do comando /cdsgaragem do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["cdsh"] = { key = "vrp_admin_cmd_cdsh", description = "Registrou a utilização do comando /cdsh do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["cdsh2"] = { key = "vrp_admin_cmd_cdsh2", description = "Registrou a utilização do comando /cdsh2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["checkbugados"] = { key = "vrp_admin_cmd_checkbugados", description = "Registrou a utilização do comando /checkbugados do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["checkdriver"] = { key = "vrp_admin_cmd_checkdriver", description = "Executou diagnóstico para identificar o motorista de um veículo.", client = true },
    ["clearallveh"] = { key = "vrp_admin_cmd_clearallveh", description = "Executou limpeza global de veículos." },
    ["cleararea"] = { key = "vrp_admin_cmd_cleararea", description = "Registrou a utilização do comando /cleararea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["clearchest"] = { key = "vrp_admin_cmd_clearchest", description = "Limpou o conteúdo de um baú conforme a rotina administrativa." },
    ["clearinv"] = { key = "vrp_admin_cmd_clearinv", description = "Limpou o inventário do próprio staff ou de um jogador informado.", targetArg = 1 },
    ["clearinvall"] = { key = "vrp_admin_cmd_clearinvall", description = "Executou limpeza global de inventários." },
    ["clearinvarea"] = { key = "vrp_admin_cmd_clearinvarea", description = "Executou limpeza de inventários em uma área." },
    ["clearmoney"] = { key = "vrp_admin_cmd_clearmoney", description = "Executou limpeza/zeragem de dinheiro conforme a rotina administrativa." },
    ["cnitro"] = { key = "vrp_admin_cmd_cnitro", description = "Adicionou o veículo de nitro configurado à garagem de um jogador.", targetArg = 1 },
    ["cone"] = { key = "vrp_admin_cmd_cone", description = "Registrou a utilização do comando /cone do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["consultar"] = { key = "vrp_admin_cmd_consultar", description = "Registrou a utilização do comando /consultar do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["copyface"] = { key = "vrp_admin_cmd_copyface", description = "Copiou a aparência facial de outro jogador.", targetArg = 1 },
    ["copypreset"] = { key = "vrp_admin_cmd_copypreset", description = "Copiou o preset/aparência de outro jogador.", targetArg = 1 },
    ["copyroupas"] = { key = "vrp_admin_cmd_copyroupas", description = "Copiou as roupas de outro jogador.", targetArg = 1 },
    ["criar-usuario"] = { key = "vrp_admin_cmd_criar_usuario", description = "Liberou um usuário para acesso ao sistema externo de logs." },
    ["cuff"] = { key = "vrp_admin_cmd_cuff", description = "Algemou/desalgemou um jogador através do comando administrativo.", targetArg = 1 },
    ["debug"] = { key = "vrp_admin_cmd_debug", description = "Registrou a utilização do comando /debug do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["debugceu"] = { key = "vrp_admin_cmd_debugceu", description = "Registrou a utilização do comando /debugceu do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["debugid"] = { key = "vrp_admin_cmd_debugid", description = "Registrou a utilização do comando /debugid do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["deletar-usuario"] = { key = "vrp_admin_cmd_deletar_usuario", description = "Removeu um usuário do sistema externo de logs." },
    ["deletarid"] = { key = "vrp_admin_cmd_deletarid", description = "Excluiu dados vinculados a um ID/passaporte.", targetArg = 1 },
    ["delete_money"] = { key = "vrp_admin_cmd_delete_money", description = "Removeu dinheiro através do comando administrativo." },
    ["deleteall"] = { key = "vrp_admin_cmd_deleteall", description = "Registrou a utilização do comando /deleteall do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["delnpcs"] = { key = "vrp_admin_cmd_delnpcs", description = "Registrou a utilização do comando /delnpcs do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["delobjs"] = { key = "vrp_admin_cmd_delobjs", description = "Registrou a utilização do comando /delobjs do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["desempregados"] = { key = "vrp_admin_cmd_desempregados", description = "Registrou a utilização do comando /desempregados do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["desempregados2"] = { key = "vrp_admin_cmd_desempregados2", description = "Registrou a utilização do comando /desempregados2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["desempregados3"] = { key = "vrp_admin_cmd_desempregados3", description = "Registrou a utilização do comando /desempregados3 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["dimensaoarea"] = { key = "vrp_admin_cmd_dimensaoarea", description = "Registrou a utilização do comando /dimensaoarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["display"] = { key = "vrp_admin_cmd_display", description = "Registrou a utilização do comando /display do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["donoveiculo"] = { key = "vrp_admin_cmd_donoveiculo", description = "Registrou a utilização do comando /donoveiculo do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["dvall"] = { key = "vrp_admin_cmd_dvall", description = "Executou remoção global de veículos pela rotina /dvall." },
    ["efeitos"] = { key = "vrp_admin_cmd_efeitos", description = "Registrou a utilização do comando /efeitos do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["encerrarevento"] = { key = "vrp_admin_cmd_encerrarevento", description = "Registrou a utilização do comando /encerrarevento do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["entregarcarros"] = { key = "vrp_admin_cmd_entregarcarros", description = "Registrou a utilização do comando /entregarcarros do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["evento2"] = { key = "vrp_admin_cmd_evento2", description = "Registrou a utilização do comando /evento2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["flash"] = { key = "vrp_admin_cmd_flash", description = "Ativou ou desativou a velocidade administrativa Flash.", client = true },
    ["flash2"] = { key = "vrp_admin_cmd_flash2", description = "Ativou ou desativou a segunda rotina de velocidade administrativa Flash.", client = true },
    ["forcedelete"] = { key = "vrp_admin_cmd_forcedelete", description = "Registrou a utilização do comando /forcedelete do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["freeze"] = { key = "vrp_admin_cmd_freeze", description = "Congelou/descongelou um jogador.", targetArg = 1 },
    ["freezearea"] = { key = "vrp_admin_cmd_freezearea", description = "Aplicou congelamento em jogadores de uma área." },
    ["garagem"] = { key = "vrp_admin_cmd_garagem", description = "Registrou a utilização do comando /garagem do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["god"] = { key = "vrp_admin_cmd_god", description = "Restaurou a vida do próprio staff ou de um jogador informado.", targetArg = 1 },
    ["godall"] = { key = "vrp_admin_cmd_godall", description = "Reviveu todos os jogadores online." },
    ["godarea"] = { key = "vrp_admin_cmd_godarea", description = "Registrou a utilização do comando /godarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["godd"] = { key = "vrp_admin_cmd_godd", description = "Aplicou revive completo e colete através do comando /godd.", targetArg = 1 },
    ["godd2"] = { key = "vrp_admin_cmd_godd2", description = "Aplicou revive em área através do comando /godd2." },
    ["groupadd"] = { key = "vrp_admin_cmd_groupadd", description = "Adicionou um grupo a um jogador.", targetArg = 1 },
    ["grouprem"] = { key = "vrp_admin_cmd_grouprem", description = "Removeu um grupo de um jogador.", targetArg = 1 },
    ["groupremall"] = { key = "vrp_admin_cmd_groupremall", description = "Removeu um grupo de todos os jogadores que o possuíam." },
    ["hackperma"] = { key = "vrp_admin_cmd_hackperma", description = "Aplicou punição permanente através da rotina administrativa." },
    ["hash"] = { key = "vrp_admin_cmd_hash", description = "Registrou a utilização do comando /hash do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["hash2"] = { key = "vrp_admin_cmd_hash2", description = "Registrou a utilização do comando /hash2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["idarea"] = { key = "vrp_admin_cmd_idarea", description = "Registrou a utilização do comando /idarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["idarea2"] = { key = "vrp_admin_cmd_idarea2", description = "Registrou a utilização do comando /idarea2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["ilegalbl"] = { key = "vrp_admin_cmd_ilegalbl", description = "Registrou a utilização do comando /ilegalbl do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["impostorenda"] = { key = "vrp_admin_cmd_impostorenda", description = "Registrou a utilização do comando /impostorenda do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["in"] = { key = "vrp_admin_cmd_in", description = "Registrou a utilização do comando /in do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["iniciarevento"] = { key = "vrp_admin_cmd_iniciarevento", description = "Registrou a utilização do comando /iniciarevento do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["iniciarfesta"] = { key = "vrp_admin_cmd_iniciarfesta", description = "Registrou a utilização do comando /iniciarfesta do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["instagram"] = { key = "vrp_admin_cmd_instagram", description = "Registrou a utilização do comando /instagram do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["item"] = { key = "vrp_admin_cmd_item", description = "Criou um item diretamente no inventário do staff." },
    ["itemp"] = { key = "vrp_admin_cmd_itemp", description = "Entregou um item diretamente a outro jogador.", targetArg = 1 },
    ["jump"] = { key = "vrp_admin_cmd_jump", description = "Ativou ou desativou o super pulo administrativo.", client = true },
    ["kick_console"] = { key = "vrp_admin_cmd_kick_console", description = "Executou expulsão de jogador via rotina de console." },
    ["kickbugados"] = { key = "vrp_admin_cmd_kickbugados", description = "Registrou a utilização do comando /kickbugados do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["kickbugados2"] = { key = "vrp_admin_cmd_kickbugados2", description = "Registrou a utilização do comando /kickbugados2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["kicksrc"] = { key = "vrp_admin_cmd_kicksrc", description = "Expulsou um source específico do servidor." },
    ["kill"] = { key = "vrp_admin_cmd_kill", description = "Abateu o próprio staff ou um jogador informado.", targetArg = 1 },
    ["killarea"] = { key = "vrp_admin_cmd_killarea", description = "Registrou a utilização do comando /killarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["kitfesta"] = { key = "vrp_admin_cmd_kitfesta", description = "Registrou a utilização do comando /kitfesta do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["kitilha"] = { key = "vrp_admin_cmd_kitilha", description = "Registrou a utilização do comando /kitilha do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["kobetop1"] = { key = "vrp_admin_cmd_kobetop1", description = "Registrou a utilização do comando /kobetop1 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["leads"] = { key = "vrp_admin_cmd_leads", description = "Registrou a utilização do comando /leads do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["liberarzona"] = { key = "vrp_admin_cmd_liberarzona", description = "Registrou a utilização do comando /liberarzona do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["limpararea"] = { key = "vrp_admin_cmd_limpararea", description = "Registrou a utilização do comando /limpararea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["listar-usuarios"] = { key = "vrp_admin_cmd_listar_usuarios", description = "Consultou os usuários cadastrados no sistema externo de logs." },
    ["listgroup"] = { key = "vrp_admin_cmd_listgroup", description = "Registrou a utilização do comando /listgroup do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["listskin"] = { key = "vrp_admin_cmd_listskin", description = "Registrou a utilização do comando /listskin do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["locdesempregados"] = { key = "vrp_admin_cmd_locdesempregados", description = "Registrou a utilização do comando /locdesempregados do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["matar"] = { key = "vrp_admin_cmd_matar", description = "Alterou a vida do próprio staff ou de um jogador para o estado definido pelo comando /matar.", targetArg = 1 },
    ["money"] = { key = "vrp_admin_cmd_money", description = "Criou dinheiro para o próprio staff." },
    ["mulher"] = { key = "vrp_admin_cmd_mulher", description = "Registrou a utilização do comando /mulher do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["nc"] = { key = "vrp_admin_cmd_nc", description = "Ativou ou desativou o noclip administrativo." },
    ["ney"] = { key = "vrp_admin_cmd_ney", description = "Registrou a utilização do comando /ney do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["nn"] = { key = "vrp_admin_cmd_nn", description = "Registrou a utilização do comando /nn do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["notificacaoid"] = { key = "vrp_admin_cmd_notificacaoid", description = "Enviou uma notificação administrativa para um ID específico.", targetArg = 1 },
    ["parall"] = { key = "vrp_admin_cmd_parall", description = "Registrou a utilização do comando /parall do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["perimetro"] = { key = "vrp_admin_cmd_perimetro", description = "Registrou a utilização do comando /perimetro do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["pfarda"] = { key = "vrp_admin_cmd_pfarda", description = "Registrou a utilização do comando /pfarda do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["players"] = { key = "vrp_admin_cmd_players", description = "Registrou a utilização do comando /players do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["pm"] = { key = "vrp_admin_cmd_pm", description = "Registrou a utilização do comando /pm do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["pon"] = { key = "vrp_admin_cmd_pon", description = "Registrou a utilização do comando /pon do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["ppreset"] = { key = "vrp_admin_cmd_ppreset", description = "Registrou a utilização do comando /ppreset do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["pradio"] = { key = "vrp_admin_cmd_pradio", description = "Registrou a utilização do comando /pradio do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["rbarreira"] = { key = "vrp_admin_cmd_rbarreira", description = "Registrou a utilização do comando /rbarreira do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["rbl2"] = { key = "vrp_admin_cmd_rbl2", description = "Registrou a utilização do comando /rbl2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["rblpolicia"] = { key = "vrp_admin_cmd_rblpolicia", description = "Registrou a utilização do comando /rblpolicia do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["rcamp"] = { key = "vrp_admin_cmd_rcamp", description = "Registrou a utilização do comando /rcamp do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["rchar"] = { key = "vrp_admin_cmd_rchar", description = "Registrou a utilização do comando /rchar do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["rdesmanche"] = { key = "vrp_admin_cmd_rdesmanche", description = "Registrou a utilização do comando /rdesmanche do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["rdet"] = { key = "vrp_admin_cmd_rdet", description = "Registrou a utilização do comando /rdet do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["realidadegroup"] = { key = "vrp_admin_cmd_realidadegroup", description = "Registrou a utilização do comando /realidadegroup do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["reentregarcaixa"] = { key = "vrp_admin_cmd_reentregarcaixa", description = "Registrou a utilização do comando /reentregarcaixa do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["reentregarskin"] = { key = "vrp_admin_cmd_reentregarskin", description = "Registrou a utilização do comando /reentregarskin do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["rembl"] = { key = "vrp_admin_cmd_rembl", description = "Registrou a utilização do comando /rembl do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["remcar"] = { key = "vrp_admin_cmd_remcar", description = "Removeu um veículo da garagem de um jogador via console." },
    ["remevento"] = { key = "vrp_admin_cmd_remevento", description = "Registrou a utilização do comando /remevento do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["remilegal"] = { key = "vrp_admin_cmd_remilegal", description = "Registrou a utilização do comando /remilegal do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["remnotify"] = { key = "vrp_admin_cmd_remnotify", description = "Registrou a utilização do comando /remnotify do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["removeorgblacklist"] = { key = "vrp_admin_cmd_removeorgblacklist", description = "Registrou a utilização do comando /removeorgblacklist do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["removercrypto"] = { key = "vrp_admin_cmd_removercrypto", description = "Removeu criptomoedas de um jogador.", targetArg = 1 },
    ["removerdetencao"] = { key = "vrp_admin_cmd_removerdetencao", description = "Registrou a utilização do comando /removerdetencao do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["removerdinheiro"] = { key = "vrp_admin_cmd_removerdinheiro", description = "Removeu dinheiro de um jogador.", targetArg = 1 },
    ["removervigilante"] = { key = "vrp_admin_cmd_removervigilante", description = "Registrou a utilização do comando /removervigilante do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["remponto"] = { key = "vrp_admin_cmd_remponto", description = "Registrou a utilização do comando /remponto do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["remporte"] = { key = "vrp_admin_cmd_remporte", description = "Registrou a utilização do comando /remporte do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["renomear"] = { key = "vrp_admin_cmd_renomear", description = "Alterou nome/sobrenome de um jogador.", targetArg = 1 },
    ["reset_vips"] = { key = "vrp_admin_cmd_reset_vips", description = "Executou a rotina global de reset dos grupos VIP." },
    ["resetarchamados"] = { key = "vrp_admin_cmd_resetarchamados", description = "Registrou a utilização do comando /resetarchamados do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["resetarinsta"] = { key = "vrp_admin_cmd_resetarinsta", description = "Registrou a utilização do comando /resetarinsta do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["resetarremap"] = { key = "vrp_admin_cmd_resetarremap", description = "Registrou a utilização do comando /resetarremap do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["resetidentifiers"] = { key = "vrp_admin_cmd_resetidentifiers", description = "Resetou identificadores vinculados a um jogador.", targetArg = 1 },
    ["rg2"] = { key = "vrp_admin_cmd_rg2", description = "Consultou/alterou dados de RG conforme a rotina administrativa.", targetArg = 1 },
    ["rrcity"] = { key = "vrp_admin_cmd_rrcity", description = "Executou o reinício controlado da cidade, salvando dados e desconectando jogadores." },
    ["rtatuagem"] = { key = "vrp_admin_cmd_rtatuagem", description = "Removeu as tatuagens de um jogador.", targetArg = 1 },
    ["safe_mode"] = { key = "vrp_admin_cmd_safe_mode", description = "Ativou ou desativou o Safe Mode global do servidor." },
    ["scamp"] = { key = "vrp_admin_cmd_scamp", description = "Registrou a utilização do comando /scamp do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["scamp2"] = { key = "vrp_admin_cmd_scamp2", description = "Registrou a utilização do comando /scamp2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["scamp3"] = { key = "vrp_admin_cmd_scamp3", description = "Registrou a utilização do comando /scamp3 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["schack"] = { key = "vrp_admin_cmd_schack", description = "Registrou a utilização do comando /schack do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["setdev"] = { key = "vrp_admin_cmd_setdev", description = "Alterou grupo/cargo de desenvolvimento conforme a rotina do comando.", targetArg = 1 },
    ["setface"] = { key = "vrp_admin_cmd_setface", description = "Registrou a utilização do comando /setface do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["setpreset"] = { key = "vrp_admin_cmd_setpreset", description = "Aplicou um preset/aparência a outro jogador.", targetArg = 1 },
    ["setpresetarea"] = { key = "vrp_admin_cmd_setpresetarea", description = "Registrou a utilização do comando /setpresetarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["setroupas"] = { key = "vrp_admin_cmd_setroupas", description = "Aplicou as roupas do staff em outro jogador.", targetArg = 1 },
    ["setroupasarea"] = { key = "vrp_admin_cmd_setroupasarea", description = "Registrou a utilização do comando /setroupasarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["SPAUddiMeBanir"] = { key = "vrp_admin_cmd_spauddimebanir", description = "Registrou a utilização do comando /SPAUddiMeBanir do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["spec2"] = { key = "vrp_admin_cmd_spec2", description = "Registrou a utilização do comando /spec2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["staff"] = { key = "vrp_admin_cmd_staff", description = "Entrou ou saiu do modo administrativo/cargo de staff." },
    ["status2"] = { key = "vrp_admin_cmd_status2", description = "Registrou a utilização do comando /status2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["status3"] = { key = "vrp_admin_cmd_status3", description = "Registrou a utilização do comando /status3 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["statuszona"] = { key = "vrp_admin_cmd_statuszona", description = "Registrou a utilização do comando /statuszona do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["tempo"] = { key = "vrp_admin_cmd_tempo", description = "Registrou a utilização do comando /tempo do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["topcrypto"] = { key = "vrp_admin_cmd_topcrypto", description = "Consultou o ranking de criptomoedas." },
    ["topmoney"] = { key = "vrp_admin_cmd_topmoney", description = "Consultou o ranking de dinheiro/banco." },
    ["topmoney2"] = { key = "vrp_admin_cmd_topmoney2", description = "Consultou ranking financeiro alternativo." },
    ["topmoney3"] = { key = "vrp_admin_cmd_topmoney3", description = "Consultou ranking financeiro alternativo." },
    ["tpall"] = { key = "vrp_admin_cmd_tpall", description = "Teleportou todos os jogadores conforme a rotina do comando." },
    ["tparea"] = { key = "vrp_admin_cmd_tparea", description = "Registrou a utilização do comando /tparea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["tpcds"] = { key = "vrp_admin_cmd_tpcds", description = "Teleportou o staff para coordenadas informadas." },
    ["tpsrc"] = { key = "vrp_admin_cmd_tpsrc", description = "Registrou a utilização do comando /tpsrc do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["tpto"] = { key = "vrp_admin_cmd_tpto", description = "Teleportou o staff até outro jogador.", targetArg = 1 },
    ["tptome"] = { key = "vrp_admin_cmd_tptome", description = "Puxou outro jogador até a posição do staff.", targetArg = 1 },
    ["tptosrc"] = { key = "vrp_admin_cmd_tptosrc", description = "Registrou a utilização do comando /tptosrc do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["tpway"] = { key = "vrp_admin_cmd_tpway", description = "Teleportou o staff para o waypoint do mapa." },
    ["tuning"] = { key = "vrp_admin_cmd_tuning", description = "Registrou a utilização do comando /tuning do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["tuning2"] = { key = "vrp_admin_cmd_tuning2", description = "Executou a rotina alternativa de tuning administrativo." },
    ["tunning"] = { key = "vrp_admin_cmd_tunning", description = "Aplicou tuning completo ao veículo próximo." },
    ["validar-usuario"] = { key = "vrp_admin_cmd_validar_usuario", description = "Solicitou/validou código de acesso de um usuário no sistema externo de logs." },
    ["vdm"] = { key = "vrp_admin_cmd_vdm", description = "Registrou a utilização do comando /vdm do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["verentidades"] = { key = "vrp_admin_cmd_verentidades", description = "Consultou as entidades próximas através da ferramenta de diagnóstico.", client = true },
    ["vmorte"] = { key = "vrp_admin_cmd_vmorte", description = "Registrou a utilização do comando /vmorte do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["vozes"] = { key = "vrp_admin_cmd_vozes", description = "Ativou ou desativou o diagnóstico de voz/proximidade dos jogadores.", client = true },
    ["vporte"] = { key = "vrp_admin_cmd_vporte", description = "Registrou a utilização do comando /vporte do vrp_admin, incluindo os argumentos informados pela equipe administrativa.", targetArg = 1 },
    ["wladd"] = { key = "vrp_admin_cmd_wladd", description = "Liberou whitelist de um ID.", targetArg = 1 },
    ["wlcheck"] = { key = "vrp_admin_cmd_wlcheck", description = "Registrou a utilização do comando /wlcheck do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
    ["wlrem"] = { key = "vrp_admin_cmd_wlrem", description = "Removeu whitelist de um ID.", targetArg = 1 },
}

local STAFF_PERMISSIONS = {
    "developer.permissao", "diretor.permissao", "admin.permissao", "moderador.permissao",
    "suporte.permissao", "ticket.permissao", "player.noclip", "perm.respstaff",
    "perm.resplog", "perm.respilegal", "perm.resppolicia", "perm.ptr.staff",
    "respeventos.permissao", "respstreamer.permissao", "ponto.dono", "ponto.admin",
    "ponto.moderador", "ponto.suporte", "off.dono", "off.admin", "off.moderador", "off.suporte"
}

local STAFF_GROUPS = {
    "dono", "developerrealidade", "respstaffrealidade", "respilegalrealidade",
    "resppoliciarealidade", "resplogrealidade", "respeventosrealidade"
}

local function copyData(data)
    local out = {}
    if type(data) == "table" then
        for k, v in pairs(data) do out[k] = v end
    end
    out.occurredAt = tonumber(out.occurredAt) or os.time()
    return out
end

local function panelStarted()
    return GetResourceState(PANEL_RESOURCE) == "started"
end

local function trySend(entry)
    if not panelStarted() then return false, true end
    local ok, sent, reason = pcall(function()
        return exports[PANEL_RESOURCE]:sendLog(entry.key, entry.data)
    end)
    if not ok then return false, true end
    return sent == true, false, reason
end

local function enqueue(key, data)
    if #pendingLogs >= MAX_PENDING then table.remove(pendingLogs, 1) end
    pendingLogs[#pendingLogs + 1] = { key = tostring(key or ""), data = copyData(data) }
end

function AdminAudit.Log(key, data)
    key = tostring(key or "")
    if key == "" then return false end
    local entry = { key = key, data = copyData(data) }
    local sent, shouldRetry = trySend(entry)
    if shouldRetry then enqueue(key, entry.data) end
    return sent
end

function AdminAudit.IsStaff(userId)
    userId = tonumber(userId)
    if not userId then return false end
    for _, permission in ipairs(STAFF_PERMISSIONS) do
        local ok, has = pcall(vRP.hasPermission, userId, permission)
        if ok and has then return true end
    end
    if type(vRP.hasGroup) == "function" then
        for _, group in ipairs(STAFF_GROUPS) do
            local ok, has = pcall(vRP.hasGroup, userId, group)
            if ok and has then return true end
        end
    end
    return false
end

local function sanitizeArguments(args)
    if type(args) ~= "table" or #args == 0 then return "Nenhum" end
    local out = {}
    for i = 1, math.min(#args, 20) do
        local value = tostring(args[i] or "")
        if #value > 180 then value = value:sub(1, 177) .. "..." end
        out[#out + 1] = value
    end
    local text = table.concat(out, " ")
    if #text > 800 then text = text:sub(1, 797) .. "..." end
    return text ~= "" and text or "Nenhum"
end

local function auditCommand(name, source, args, rawCommand, occurredAt)
    local meta = AdminAudit.CommandCatalog[tostring(name or "")]
    if not meta then return end

    source = tonumber(source) or 0
    local actorId = source > 0 and vRP.getUserId(source) or nil
    if source > 0 and not AdminAudit.IsStaff(actorId) then return end

    local targetId = nil
    if meta.targetArg and type(args) == "table" then
        targetId = tonumber(args[meta.targetArg])
        if targetId and targetId <= 0 then targetId = nil end
    end

    local details = ("**Comando:** `/%s`\n**Argumentos:** %s\n**Source:** %s"):format(
        tostring(name), sanitizeArguments(args), tostring(source)
    )

    AdminAudit.Log(meta.key, {
        actorId = actorId,
        actorName = source == 0 and "Console / RCON" or nil,
        actorLabel = source == 0 and "ORIGEM" or nil,
        targetId = targetId,
        details = details,
        occurredAt = occurredAt or os.time()
    })
end

function AdminAudit.RegisterCommand(name, handler, restricted)
    return NativeRegisterCommand(name, function(source, args, rawCommand)
        local occurredAt = os.time()
        local packed = table.pack(handler(source, args, rawCommand))
        auditCommand(name, source, args, rawCommand, occurredAt)
        return table.unpack(packed, 1, packed.n)
    end, restricted or false)
end

RegisterNetEvent("vrp_admin:auditClientCommand", function(commandName, args)
    local playerSource = source
    local meta = AdminAudit.CommandCatalog[tostring(commandName or "")]
    if not meta or not meta.client then return end
    local userId = vRP.getUserId(playerSource)
    if not AdminAudit.IsStaff(userId) then return end
    auditCommand(commandName, playerSource, type(args) == "table" and args or {}, nil, os.time())
end)

local function flushPending()
    if not panelStarted() or #pendingLogs == 0 then return end
    local remaining = {}
    for i = 1, #pendingLogs do
        local entry = pendingLogs[i]
        local _, shouldRetry = trySend(entry)
        if shouldRetry then remaining[#remaining + 1] = entry end
    end
    pendingLogs = remaining
end

CreateThread(function()
    while true do
        Wait(FLUSH_INTERVAL)
        flushPending()
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == PANEL_RESOURCE then SetTimeout(1500, flushPending) end
end)
