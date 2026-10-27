ServerConfig = ServerConfig or {}

-- ============================================================================
-- ACESSO
-- ============================================================================
-- A sua vRP enviada possui "developer.permissao" e "admin.permissao".
-- O painel antigo usava "administrador.permissao", que NÃO existe no groups.json
-- analisado. A V2 já está corrigida para a sua base.
ServerConfig.OpenPermissions = {
    "developer.permissao",
    "admin.permissao"
}

ServerConfig.StaffPermission = "perm.ptr.staff"

-- Contadores exibidos no topo da aba Jogadores.
-- As permissões abaixo foram validadas contra o groups.json da vRP enviada.
ServerConfig.OnlineCounterPermissions = {
    staff = "perm.ptr.staff",
    mechanics = "perm.mecanica",
    police = "perm.countpolicia",
    medics = "perm.unizk",
    illegal = "perm.ilegal"
}


-- Chamados que não pertencem à staff são encaminhados diretamente aos setores.
-- Uma lista é aceita para manter compatibilidade com bases que separam a permissão
-- de serviço da permissão usada apenas em contadores.
ServerConfig.CallDepartments = {
    staff = {
        label = "Staff", panel = true, permissions = { "perm.ptr.staff" },
        unavailableMessage = "Não há nenhum Staff online no momento."
    },
    police = {
        label = "Polícia", permissions = { "perm.policia", "perm.countpolicia" },
        unavailableMessage = "Não há nenhum policial online no momento."
    },
    mechanic = {
        label = "Mecânica", permissions = { "perm.mecanica" },
        unavailableMessage = "Não há nenhum mecânico online no momento."
    },
    hospital = {
        label = "Hospital", permissions = { "perm.unizk" },
        unavailableMessage = "Não há nenhum médico online no momento."
    }
}

-- Na vRP enviada, a carteira usa o item "money".
ServerConfig.MoneyItem = "money"

-- Compatibilidade com versões antigas. O sistema atual NÃO usa uma webhook global:
-- cada log possui sua própria URL cadastrada pela aba Logs do painel.
ServerConfig.Webhook = "none"


-- ============================================================================
-- CATÁLOGO CENTRAL DE LOGS
-- ============================================================================
-- As URLs das webhooks NÃO ficam neste arquivo e nunca são enviadas para clients.
-- Elas são salvas server-side em logs_config.json pela nova aba Logs.
--
-- O catálogo abaixo define somente organização, nome e descrição de cada log.
-- Novos scripts podem ser integrados futuramente adicionando novas categorias/logs
-- e chamando o export server-side `exports["m_paineladm_v2"]:sendLog(...)`.
ServerConfig.LogCatalog = {
    {
        id = "painel_adm",
        label = "PAINEL ADM",
        description = "Logs de todas as ações e sistemas administrativos já disponíveis no Mage Admin.",
        subcategories = {
            {
                id = "servidor", label = "Servidor",
                logs = {
                    { key = "wladd", name = "Whitelist liberada", description = "Liberou a whitelist de um passaporte." },
                    { key = "wlrem", name = "Whitelist removida", description = "Removeu a whitelist de um passaporte." },
                    { key = "unban", name = "Jogador desbanido", description = "Removeu o banimento de um passaporte." },
                    { key = "ban_history_view", name = "Histórico de bans consultado", description = "Consultou o histórico de bans e desbans do painel." },
                    { key = "send_adm", name = "Aviso geral enviado", description = "Enviou um aviso administrativo para todos os jogadores." },
                    { key = "needs_toggle", name = "Fome e sede alteradas", description = "Ativou ou desativou globalmente o sistema de fome e sede." },
                    { key = "needs_settings", name = "Configuração de fome e sede", description = "Alterou velocidade e dano do sistema de fome e sede." },
                    { key = "tpway", name = "Teleportou ao waypoint", description = "Teleportou-se até a marcação atual do mapa." },
                    { key = "tpcds", name = "Teleportou por coordenadas", description = "Teleportou-se para coordenadas informadas manualmente." },
                    { key = "godall", name = "Reviveu todos", description = "Reanimou todos os jogadores online." },
                    { key = "clear_allveh", name = "Limpeza de veículos", description = "Iniciou uma limpeza global de veículos vazios." },
                    { key = "clear_props", name = "Limpeza de props", description = "Removeu objetos dentro do raio administrativo configurado." },
                    { key = "wipe_user_data", name = "Dados de ID apagados", description = "Apagou permanentemente os dados de um passaporte e liberou o ID." }
                }
            },
            {
                id = "jogadores", label = "Jogadores",
                logs = {
                    { key = "inspect_inventory", name = "Inventário inspecionado", description = "Abriu a inspeção do inventário de outro jogador." },
                    { key = "god", name = "Jogador revivido", description = "Restaurou a vida de outro jogador." },
                    { key = "kill", name = "Jogador abatido", description = "Definiu a vida de outro jogador como zero." },
                    { key = "tptome", name = "Jogador puxado", description = "Teleportou outro jogador até o administrador." },
                    { key = "tpto", name = "Teleportou até jogador", description = "Teleportou o administrador até outro jogador." },
                    { key = "freeze", name = "Jogador congelado", description = "Bloqueou a movimentação de outro jogador." },
                    { key = "unfreeze", name = "Jogador descongelado", description = "Liberou novamente a movimentação de outro jogador." },
                    { key = "send_dm", name = "Mensagem privada enviada", description = "Enviou um aviso administrativo diretamente para outro jogador." },
                    { key = "catch_rg", name = "RG consultado", description = "Consultou os dados de identidade de um passaporte." },
                    { key = "warning", name = "Advertência aplicada", description = "Aplicou advertência/castigo temporário a outro jogador." },
                    { key = "ban", name = "Jogador banido", description = "Baniu um passaporte do servidor." },
                    { key = "kick", name = "Jogador expulso", description = "Expulsou um jogador online do servidor." },
                    { key = "givemoney", name = "Dinheiro adicionado", description = "Adicionou dinheiro à carteira ou banco de outro jogador." },
                    { key = "remove_money", name = "Dinheiro removido", description = "Removeu dinheiro da carteira ou banco de outro jogador." },
                    { key = "give_item", name = "Item adicionado", description = "Adicionou item ao inventário de outro jogador." },
                    { key = "remove_item", name = "Item removido", description = "Removeu item do inventário de outro jogador." },
                    { key = "clear_inv", name = "Inventário limpo", description = "Removeu todos os itens do inventário de outro jogador." },
                    { key = "clear_weapons", name = "Armas removidas", description = "Removeu as armas de outro jogador." }
                }
            },
            {
                id = "advertencias", label = "Advertências",
                logs = {
                    { key = "delete_warning", name = "Advertência excluída", description = "Excluiu uma advertência registrada no histórico de um jogador." }
                }
            },
            {
                id = "mapa", label = "Mapa",
                logs = {
                    { key = "map_screen", name = "Tela do jogador monitorada", description = "Iniciou o monitoramento ao vivo da tela de outro jogador." }
                }
            },
            {
                id = "chamados", label = "Chamados",
                logs = {
                    { key = "calls_create", name = "Chamado criado", description = "Um jogador criou um chamado para um setor do servidor." },
                    { key = "calls_accept", name = "Chamado Staff aceito", description = "Um membro da Staff aceitou um chamado administrativo." },
                    { key = "calls_finish", name = "Chamado Staff finalizado", description = "Um membro da Staff finalizou e arquivou um chamado administrativo." },
                    { key = "calls_sector_accept", name = "Chamado de setor aceito", description = "Um membro de Polícia, Mecânica ou Hospital aceitou um chamado." },
                    { key = "calls_rate", name = "Atendimento avaliado", description = "Um jogador avaliou um atendimento Staff concluído." },
                    { key = "calls_history_view", name = "Histórico de chamados consultado", description = "Consultou o histórico de chamados finalizados." },
                    { key = "calls_ranking_view", name = "Ranking Staff consultado", description = "Consultou o ranking de atendimentos da Staff." },
                    { key = "calls_evaluations_view", name = "Avaliações consultadas", description = "Consultou as avaliações dos atendimentos Staff." },
                    { key = "calls_staff_notes_view", name = "Notas da Staff consultadas", description = "Consultou as notas consolidadas da Staff." }
                }
            },
            {
                id = "setagem", label = "Setagem",
                logs = {
                    { key = "set_group", name = "Cargo adicionado", description = "Adicionou um cargo/grupo a outro jogador." },
                    { key = "remove_group", name = "Cargo removido", description = "Removeu um cargo/grupo de outro jogador." }
                }
            },
            {
                id = "alterar_rg", label = "Alterar RG",
                logs = {
                    { key = "edit_identity", name = "Identidade alterada", description = "Alterou um dado de identidade de um passaporte." },
                    { key = "edit_identity_balance", name = "Saldo alterado pelo editor", description = "Substituiu o valor da carteira ou banco pelo editor de identidade." },
                    { key = "change_user_id", name = "Passaporte alterado", description = "Alterou o número de Passaporte/ID de um jogador em todas as tabelas compatíveis." }
                }
            },
            {
                id = "itens", label = "Itens",
                logs = {
                    { key = "spawn_self_item", name = "Item spawnado para Staff", description = "Adicionou um item diretamente ao próprio inventário pelo painel." }
                }
            },
            {
                id = "armas", label = "Armas",
                logs = {
                    { key = "spawn_weapon", name = "Arma spawnada para Staff", description = "Adicionou uma arma e sua munição ao próprio inventário." }
                }
            },
            {
                id = "vips", label = "VIPs",
                logs = {
                    { key = "create_vip", name = "VIP criado", description = "Criou um novo pacote VIP e seu cargo correspondente." },
                    { key = "edit_vip", name = "VIP editado", description = "Alterou configurações e benefícios de um pacote VIP." },
                    { key = "assign_vip", name = "VIP setado", description = "Entregou um VIP temporário e seus benefícios a um jogador." },
                    { key = "delete_vip", name = "VIP excluído", description = "Excluiu um pacote VIP e removeu o cargo dos jogadores afetados." },
                    { key = "vip_vehicle_choose", name = "Veículo VIP resgatado", description = "Um jogador confirmou a escolha de um veículo incluído em seu VIP." },
                    { key = "vip_vehicle_test", name = "Veículo VIP testado", description = "Um jogador iniciou o test-drive opcional de um veículo do VIP." }
                }
            },
            {
                id = "veiculos", label = "Veículos",
                logs = {
                    { key = "spawn_veh", name = "Veículo spawnado", description = "Spawnou um veículo administrativo para o próprio jogador." },
                    { key = "add_vehicle_catalog", name = "Veículo adicionado ao catálogo", description = "Adicionou um novo spawn ao catálogo de veículos do painel." },
                    { key = "give_veh", name = "Veículo entregue", description = "Adicionou um veículo à garagem de outro jogador." },
                    { key = "rem_veh", name = "Veículo removido", description = "Removeu um veículo da garagem de outro jogador." },
                    { key = "fix", name = "Veículo reparado", description = "Solicitou o reparo do veículo atual/próximo." },
                    { key = "tuning", name = "Veículo tunado", description = "Aplicou tuning máximo ao veículo atual." },
                    { key = "hash", name = "Hash de veículo consultado", description = "Consultou nome e hash do veículo atual/próximo." },
                    { key = "dv", name = "Veículo deletado", description = "Removeu o veículo atual/próximo do mundo." }
                }
            },
            {
                id = "radio", label = "Rádio",
                logs = {
                    { key = "radio_save", name = "Rádio privada salva", description = "Criou ou editou uma frequência de rádio privada." },
                    { key = "radio_delete", name = "Rádio privada excluída", description = "Excluiu uma frequência de rádio privada." }
                }
            },
            {
                id = "locais", label = "Locais",
                logs = {
                    { key = "add_location_category", name = "Categoria de locais criada", description = "Criou uma nova categoria para organizar teleportes administrativos." },
                    { key = "add_location", name = "Local cadastrado", description = "Cadastrou um novo local/teleporte administrativo." },
                    { key = "remove_location", name = "Local removido", description = "Removeu um local/teleporte administrativo cadastrado." },
                    { key = "teleport_location", name = "Teleportou para local", description = "Teleportou-se para um local cadastrado no painel." }
                }
            },
            {
                id = "clima", label = "Clima",
                logs = {
                    { key = "weather_set", name = "Clima alterado", description = "Definiu manualmente o clima global do servidor." },
                    { key = "weather_freeze", name = "Congelamento do clima alterado", description = "Congelou ou descongelou a sincronização do clima." },
                    { key = "weather_rotation", name = "Rotação automática do clima", description = "Ativou ou desativou a rotação automática de climas." },
                    { key = "time_set", name = "Horário alterado", description = "Definiu manualmente o horário global do servidor." },
                    { key = "time_freeze", name = "Congelamento do horário alterado", description = "Congelou ou descongelou a passagem do tempo." }
                }
            },
            {
                id = "configuracao", label = "Configuração do Painel",
                logs = {
                    { key = "panel_permissions", name = "Permissões do painel alteradas", description = "Alterou quais cargos de Staff podem acessar uma função do painel." },
                    { key = "logs_manage", name = "Webhooks de logs alteradas", description = "Salvou alterações nas webhooks cadastradas na aba Logs." }
                }
            }
        }
    },
    {
        id = "servidor",
        label = "SERVIDOR",
        description = "Logs automáticas de conexão geradas pela vRP. Não dependem de uma ação administrativa.",
        logs = {
            { key = "vrp_player_join", name = "Entrada no servidor", description = "Registrou a entrada concluída de um jogador no servidor." },
            { key = "vrp_player_leave", name = "Saída do servidor", description = "Registrou a saída de um jogador que estava conectado ao servidor." },
            { key = "vrp_connection_failed", name = "Falha/recusa de conexão", description = "Registrou uma tentativa de conexão que não chegou a entrar no servidor por erro, validação, bloqueio ou interrupção." }
        }
    },
    {
        id = "mortes",
        label = "MORTES",
        description = "Logs automáticas de mortes registradas pelo m_survival, com vítima, responsável, causa e coordenadas.",
        logs = {
            { key = "survival_death", name = "Morte de jogador", description = "Registrou uma morte no m_survival, identificando vítima, assassino quando houver, causa da morte e coordenadas do ocorrido." }
        }
    },
    {
        id = "craft",
        label = "CRAFT",
        description = "Logs de fabricação separadas por cada craft/facção configurada no m_craft.",
        subcategories = {
            {
                id = "mafia",
                label = "Mafia",
                description = "Logs próprias do craft Mafia. Integração associada ao farm Armas.",
                logs = {
                    { key = "craft_mafia_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Mafia, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_mafia_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Mafia, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_mafia_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            },
            {
                id = "verdes",
                label = "Verdes",
                description = "Logs próprias do craft Verdes. Integração associada ao farm Armas.",
                logs = {
                    { key = "craft_verdes_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Verdes, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_verdes_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Verdes, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_verdes_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            },
            {
                id = "cartel",
                label = "Cartel",
                description = "Logs próprias do craft Cartel. Integração associada ao farm Municao.",
                logs = {
                    { key = "craft_cartel_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Cartel, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_cartel_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Cartel, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_cartel_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            },
            {
                id = "vermelhos",
                label = "Vermelhos",
                description = "Logs próprias do craft Vermelhos. Integração associada ao farm Municao.",
                logs = {
                    { key = "craft_vermelhos_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Vermelhos, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_vermelhos_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Vermelhos, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_vermelhos_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            },
            {
                id = "vanilla",
                label = "Vanilla",
                description = "Logs próprias do craft Vanilla. Integração associada ao farm Lavagem.",
                logs = {
                    { key = "craft_vanilla_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Vanilla, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_vanilla_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Vanilla, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_vanilla_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            },
            {
                id = "bahamas",
                label = "Bahamas",
                description = "Logs próprias do craft Bahamas. Integração associada ao farm Lavagem.",
                logs = {
                    { key = "craft_bahamas_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Bahamas, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_bahamas_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Bahamas, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_bahamas_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            },
            {
                id = "motoclube",
                label = "Motoclube",
                description = "Logs próprias do craft Motoclube. Integração associada ao farm Desmanche.",
                logs = {
                    { key = "craft_motoclube_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Motoclube, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_motoclube_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Motoclube, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_motoclube_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            },
            {
                id = "franca",
                label = "Franca",
                description = "Logs próprias do craft Franca. Integração associada ao farm Desmanche.",
                logs = {
                    { key = "craft_franca_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Franca, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_franca_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Franca, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_franca_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            },
            {
                id = "roxos",
                label = "Roxos",
                description = "Logs próprias do craft Roxos. Integração associada ao farm Cocaina.",
                logs = {
                    { key = "craft_roxos_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Roxos, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_roxos_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Roxos, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_roxos_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            },
            {
                id = "laranjas",
                label = "Laranjas",
                description = "Logs próprias do craft Laranjas. Integração associada ao farm Metanfetamina.",
                logs = {
                    { key = "craft_laranjas_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Laranjas, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_laranjas_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Laranjas, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_laranjas_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            },
            {
                id = "colombia",
                label = "Colombia",
                description = "Logs próprias do craft Colombia. Integração associada ao farm Maconha.",
                logs = {
                    { key = "craft_colombia_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Colombia, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_colombia_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Colombia, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_colombia_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            },
            {
                id = "policia",
                label = "Policia",
                description = "Logs próprias do craft Policia.",
                logs = {
                    { key = "craft_policia_started", name = "Fabricação iniciada", description = "Registrou o início de uma fabricação no craft Policia, incluindo item, quantidade, tempo e materiais consumidos." },
                    { key = "craft_policia_collected", name = "Item fabricado coletado", description = "Registrou o resgate de uma fabricação concluída no craft Policia, incluindo item, quantidade e responsável pela coleta." },
                    { key = "craft_policia_storage_deposit", name = "Item depositado no armazém", description = "Registrou um depósito no armazém deste craft, incluindo jogador, item(ns), quantidade(s) depositada(s) e saldo resultante no armazém." }
                }
            }
        }
    },
    {
        id = "farm",
        label = "FARM",
        description = "Uma webhook independente para cada farm/facção configurada. Cada ponto coletado gera uma ocorrência com os itens e quantidades recebidas.",
        logs = {
            { key = "farm_mafia_collect", name = "Farm Mafia — Armas", description = "Registrou uma coleta em um ponto do farm da facção Mafia, incluindo rota, região, ponto e todos os itens efetivamente recebidos." },
            { key = "farm_verdes_collect", name = "Farm Verdes — Armas", description = "Registrou uma coleta em um ponto do farm da facção Verdes, incluindo rota, região, ponto e todos os itens efetivamente recebidos." },
            { key = "farm_cartel_collect", name = "Farm Cartel — Municao", description = "Registrou uma coleta em um ponto do farm da facção Cartel, incluindo rota, região, ponto e todos os itens efetivamente recebidos." },
            { key = "farm_vermelhos_collect", name = "Farm Vermelhos — Municao", description = "Registrou uma coleta em um ponto do farm da facção Vermelhos, incluindo rota, região, ponto e todos os itens efetivamente recebidos." },
            { key = "farm_vanilla_collect", name = "Farm Vanilla — Lavagem", description = "Registrou uma coleta em um ponto do farm da facção Vanilla, incluindo rota, região, ponto e todos os itens efetivamente recebidos." },
            { key = "farm_bahamas_collect", name = "Farm Bahamas — Lavagem", description = "Registrou uma coleta em um ponto do farm da facção Bahamas, incluindo rota, região, ponto e todos os itens efetivamente recebidos." },
            { key = "farm_motoclube_collect", name = "Farm Motoclube — Desmanche", description = "Registrou uma coleta em um ponto do farm da facção Motoclube, incluindo rota, região, ponto e todos os itens efetivamente recebidos." },
            { key = "farm_franca_collect", name = "Farm Franca — Desmanche", description = "Registrou uma coleta em um ponto do farm da facção Franca, incluindo rota, região, ponto e todos os itens efetivamente recebidos." },
            { key = "farm_roxos_collect", name = "Farm Roxos — Cocaina", description = "Registrou uma coleta em um ponto do farm da facção Roxos, incluindo rota, região, ponto e todos os itens efetivamente recebidos." },
            { key = "farm_laranjas_collect", name = "Farm Laranjas — Metanfetamina", description = "Registrou uma coleta em um ponto do farm da facção Laranjas, incluindo rota, região, ponto e todos os itens efetivamente recebidos." },
            { key = "farm_colombia_collect", name = "Farm Colombia — Maconha", description = "Registrou uma coleta em um ponto do farm da facção Colombia, incluindo rota, região, ponto e todos os itens efetivamente recebidos." }
        }
    },

    {
        id = "inventario",
        label = "INVENTÁRIO",
        description = "Auditoria central das movimentações sensíveis do inventário, revista, armas, porta-malas, baús e lojas.",
        subcategories = {
            {
                id = "movimentacoes",
                label = "Movimentações",
                description = "Transferências, uso, drop e coleta de itens controlados diretamente pelo inventário.",
                logs = {
                    { key = "inventory_item_sent", name = "Item enviado para jogador", description = "Registrou um item enviado diretamente para outro jogador pelo inventário." },
                    { key = "inventory_item_received", name = "Item recebido de jogador", description = "Registrou o recebimento de um item enviado diretamente por outro jogador." },
                    { key = "inventory_item_dropped", name = "Item dropado no chão", description = "Registrou a remoção de um item do inventário para criar um drop no chão." },
                    { key = "inventory_item_pickup", name = "Item coletado do chão", description = "Registrou a coleta efetiva de um item que estava dropado no chão." },
                    { key = "inventory_item_used", name = "Item utilizado", description = "Registrou o uso bem-sucedido de um item utilizável do inventário." }
                }
            },
            {
                id = "revista",
                label = "Revista",
                description = "Abertura de revistas e movimentações de itens entre os dois jogadores.",
                logs = {
                    { key = "inventory_inspect_started", name = "Jogador revistado", description = "Registrou o início bem-sucedido de uma revista entre dois jogadores." },
                    { key = "inventory_inspect_staff", name = "Inventário aberto pela Staff", description = "Registrou uma inspeção administrativa de inventário através do comando autorizado." },
                    { key = "inventory_inspect_item_taken", name = "Item pego na revista", description = "Registrou um item retirado do inventário do jogador revistado." },
                    { key = "inventory_inspect_item_given", name = "Item colocado na revista", description = "Registrou um item colocado no inventário do jogador que está sendo revistado." }
                }
            },
            {
                id = "armas",
                label = "Armas e Slots",
                description = "Slots rápidos 1–5, equipagem, coldre, munição e armas temporárias de serviço.",
                logs = {
                    { key = "inventory_weapon_hotbar", name = "Arma movimentada nos slots 1–5", description = "Registrou quando uma arma entrou, saiu ou mudou de posição nos slots rápidos de armas." },
                    { key = "inventory_weapon_equipped", name = "Arma equipada", description = "Registrou quando o jogador efetivamente equipou uma arma da hotbar nas mãos." },
                    { key = "inventory_weapon_holstered", name = "Arma guardada no coldre", description = "Registrou quando uma arma equipada foi guardada/retirada das mãos." },
                    { key = "inventory_weapon_recharged", name = "Arma recarregada", description = "Registrou munição consumida do inventário para recarregar uma arma equipada." },
                    { key = "inventory_weapons_stored", name = "Armas guardadas no inventário", description = "Registrou o uso do sistema de guardar armas, incluindo armas e munições devolvidas ao inventário." },
                    { key = "inventory_duty_weapon_issued", name = "Arma de serviço entregue", description = "Registrou uma arma temporária de serviço inserida em um slot rápido do jogador." },
                    { key = "inventory_duty_weapon_removed", name = "Arma de serviço removida", description = "Registrou a remoção de uma arma temporária de serviço do inventário/hotbar." }
                }
            },
            {
                id = "porta_malas",
                label = "Porta-malas",
                description = "Acesso e movimentação de itens em porta-malas de veículos.",
                logs = {
                    { key = "inventory_trunk_open", name = "Porta-malas aberto", description = "Registrou um acesso bem-sucedido ao porta-malas de um veículo." },
                    { key = "inventory_trunk_store", name = "Item guardado no porta-malas", description = "Registrou um item retirado do jogador e armazenado em um porta-malas." },
                    { key = "inventory_trunk_take", name = "Item retirado do porta-malas", description = "Registrou um item retirado de um porta-malas e entregue ao jogador." }
                }
            },
            {
                id = "baus",
                label = "Baús",
                description = "Baús de facção, casas e armazéns, com identificação do tipo e do baú usado.",
                logs = {
                    { key = "inventory_chest_open", name = "Baú aberto", description = "Registrou um acesso bem-sucedido a baú de facção, casa ou armazém." },
                    { key = "inventory_chest_store", name = "Item guardado no baú", description = "Registrou um item depositado em baú de facção, casa ou armazém." },
                    { key = "inventory_chest_take", name = "Item retirado do baú", description = "Registrou um item retirado de baú de facção, casa ou armazém." }
                }
            },
            {
                id = "lojas",
                label = "Lojas",
                description = "Operações financeiras de compra e venda executadas pelo módulo de lojas do inventário.",
                logs = {
                    { key = "inventory_shop_buy", name = "Item comprado em loja", description = "Registrou uma compra concluída, incluindo loja, item, quantidade e valor total." },
                    { key = "inventory_shop_sell", name = "Item vendido em loja", description = "Registrou uma venda concluída, incluindo loja, item, quantidade e valor recebido." }
                }
            },
            {
                id = "administrativo",
                label = "Acessos Administrativos",
                description = "Acessos de staff a inventários e armazenamentos que exigem auditoria especial.",
                logs = {
                    { key = "inventory_staff_trunk_open", name = "Staff abriu porta-malas", description = "Registrou quando um staff abriu administrativamente o porta-malas de um veículo pertencente a outro jogador." },
                    { key = "inventory_staff_house_chest_open", name = "Staff abriu baú de casa", description = "Registrou quando um staff abriu administrativamente o baú de uma propriedade." },
                    { key = "inventory_staff_faction_chest_open", name = "Staff abriu baú de facção", description = "Registrou quando um staff abriu administrativamente o baú de uma facção/organização." }
                }
            },
            {
                id = "acoes_sensiveis",
                label = "Ações Sensíveis",
                description = "Uso bem-sucedido de itens que alteram jogadores ou veículos e merecem auditoria detalhada além da log geral de uso.",
                logs = {
                    { key = "inventory_masterpick_success", name = "MasterPick utilizado com sucesso", description = "Registrou um veículo de jogador destrancado com MasterPick, incluindo proprietário e localização." },
                    { key = "inventory_lockpick_success", name = "Lockpick utilizado com sucesso", description = "Registrou um veículo de jogador destrancado com Lockpick, incluindo proprietário e localização." },
                    { key = "inventory_handcuff_applied", name = "Jogador algemado", description = "Registrou quando um jogador utilizou algemas com sucesso em outro jogador." },
                    { key = "inventory_handcuff_removed", name = "Algemas removidas", description = "Registrou quando um jogador utilizou a chave de algemas para libertar outro jogador." },
                    { key = "inventory_hood_toggled", name = "Capuz utilizado em jogador", description = "Registrou quando um jogador colocou ou retirou um capuz de outro jogador." },
                    { key = "inventory_plate_changed", name = "Placa própria alterada", description = "Registrou a alteração permanente da placa de um veículo próprio através do item de alteração de placa." },
                    { key = "inventory_plate_cloned", name = "Placa de veículo clonada", description = "Registrou a clonagem de placa de um veículo, incluindo o proprietário afetado e o veículo." }
                }
            },
            {
                id = "sistema_baus",
                label = "Sistema de Baús",
                description = "Falhas e recuperações importantes do carregamento/sincronização dos baús do inventário.",
                logs = {
                    { key = "inventory_chest_sync_error", name = "Falha de sincronização de baú", description = "Registrou uma configuração de baú inválida detectada durante a sincronização com um jogador." },
                    { key = "inventory_chest_manual_sync", name = "Baús recarregados manualmente", description = "Registrou uma sincronização manual de baús e informa se o carregamento automático havia ocorrido corretamente." }
                }
            }
        }
    },
    {
        id = "garagem",
        label = "GARAGEM",
        description = "Auditoria das principais movimentações, negociações, taxas, acessos e tentativas de abuso no sistema de garagens.",
        subcategories = {
            {
                id = "movimentacoes", label = "Movimentações",
                description = "Retirada, armazenamento e remoção de veículos pessoais ou de serviço.",
                logs = {
                    { key = "garage_vehicle_taken", name = "Veículo retirado da garagem", description = "Registrou a retirada bem-sucedida de um veículo pessoal da garagem." },
                    { key = "garage_service_vehicle_taken", name = "Veículo de serviço retirado", description = "Registrou a retirada bem-sucedida de um veículo de serviço/organização." },
                    { key = "garage_vehicle_stored", name = "Veículo guardado", description = "Registrou quando um veículo pessoal foi guardado novamente na garagem." },
                    { key = "garage_service_vehicle_stored", name = "Veículo de serviço guardado", description = "Registrou quando um veículo de serviço/organização foi guardado novamente." },
                    { key = "garage_vehicle_stored_nearby", name = "Veículo próximo guardado", description = "Registrou quando o jogador utilizou a opção de guardar um veículo próximo." },
                    { key = "garage_vehicle_removed_event", name = "Veículo removido pelo sistema", description = "Registrou remoções de veículos executadas pelos eventos internos da garagem." }
                }
            },
            {
                id = "vendas_chaves", label = "Venda, Chaves e Acesso",
                description = "Negociação entre jogadores e ações relacionadas a chaves e travamento do veículo.",
                logs = {
                    { key = "garage_vehicle_sold_player", name = "Veículo vendido para jogador", description = "Registrou uma venda/transferência de veículo entre jogadores, incluindo valor oficial, limite de 30% e valor efetivamente pago." },
                    { key = "garage_vehicle_key_shared", name = "Chave compartilhada", description = "Registrou quando o proprietário entregou uma chave de seu veículo para outro jogador." },
                    { key = "garage_vehicle_lock_changed", name = "Trava do veículo alterada", description = "Registrou o trancamento ou destrancamento de um veículo através do sistema da garagem." }
                }
            },
            {
                id = "taxas_situacao", label = "Taxas e Situação",
                description = "Pagamentos de IPVA, liberação de retenção/detenção e mudanças importantes de situação do veículo.",
                logs = {
                    { key = "garage_ipva_paid", name = "IPVA pago", description = "Registrou o pagamento do IPVA de um veículo." },
                    { key = "garage_vehicle_release_detained", name = "Veículo detido liberado", description = "Registrou o pagamento e a liberação de um veículo que estava detido." },
                    { key = "garage_vehicle_release_retained", name = "Veículo retido liberado", description = "Registrou o pagamento e a liberação de um veículo que estava retido." },
                    { key = "garage_service_vehicle_release", name = "Veículo de serviço liberado", description = "Registrou o pagamento/liberação de um veículo de serviço ou organização retido." },
                    { key = "garage_service_vehicle_marked_retained", name = "Veículo de serviço retido", description = "Registrou quando o sistema marcou um veículo de serviço/organização como retido." }
                }
            },
            {
                id = "seguranca_administracao", label = "Segurança e Administração",
                description = "Comando DV e tentativas anormais de utilizar a garagem com dados, permissões ou veículos inválidos.",
                logs = {
                    { key = "garage_dv_command", name = "Comando /dv", description = "Registrou a remoção de um veículo pelo comando /dv existente no resource da garagem." },
                    { key = "garage_security_invalid_type", name = "Tipo de garagem inválido", description = "Detectou tentativa de retirada utilizando ID/tipo de garagem inexistente ou incompatível com a configuração server-side." },
                    { key = "garage_security_invalid_permission", name = "Permissão de garagem inválida", description = "Detectou tentativa de retirar veículo de uma garagem de serviço sem possuir a permissão exigida." },
                    { key = "garage_security_invalid_vehicle", name = "Veículo de serviço não autorizado", description = "Detectou tentativa de spawnar um modelo que não pertence à lista server-side da garagem de serviço." },
                    { key = "garage_security_delete_spam", name = "Spam de remoção de veículos", description = "Detectou uso anormal/repetido do evento de remoção de veículos da garagem." }
                }
            },
            {
                id = "configuracao", label = "Configuração e Catálogo",
                description = "Alterações server-side nas garagens, tipos e catálogo de veículos feitas por integrações administrativas.",
                logs = {
                    { key = "garage_config_location_changed", name = "Garagem configurada", description = "Registrou criação, edição ou exclusão de um ponto de garagem, incluindo tipo, permissão, coordenadas e resource solicitante." },
                    { key = "garage_config_type_changed", name = "Tipo de garagem configurado", description = "Registrou criação, edição ou exclusão de um tipo de garagem e sua lista de veículos quando aplicável." },
                    { key = "garage_config_reloaded", name = "Configuração recarregada", description = "Registrou recarregamento manual da configuração dinâmica das garagens." },
                    { key = "garage_catalog_vehicle_changed", name = "Veículo do catálogo alterado", description = "Registrou cadastro, edição ou remoção de um veículo do catálogo server-side, incluindo preço e dados principais." },
                    { key = "garage_catalog_vehicle_batch_removed", name = "Veículos removidos em lote", description = "Registrou remoções em lote do catálogo de veículos e os spawns afetados." }
                }
            }
        }
    },
    {
        id = "vrp_admin",
        label = "VRP_ADMIN",
        description = "Auditoria dos comandos administrativos do resource vrp_admin e das detecções críticas de segurança associadas.",
        subcategories = {
            {
                id = "site_logs", label = "Sistema de Logs",
                description = "Comandos administrativos relacionados ao acesso e validação do antigo sistema externo de logs.",
                logs = {
                    { key = "vrp_admin_cmd_criar_usuario", name = "Comando /criar-usuario", description = "Liberou um usuário para acesso ao sistema externo de logs." },
                    { key = "vrp_admin_cmd_deletar_usuario", name = "Comando /deletar-usuario", description = "Removeu um usuário do sistema externo de logs." },
                    { key = "vrp_admin_cmd_listar_usuarios", name = "Comando /listar-usuarios", description = "Consultou os usuários cadastrados no sistema externo de logs." },
                    { key = "vrp_admin_cmd_validar_usuario", name = "Comando /validar-usuario", description = "Solicitou/validou código de acesso de um usuário no sistema externo de logs." },
                }
            },
            {
                id = "seguranca", label = "Segurança",
                description = "Comandos e detecções de alto risco que podem indicar abuso administrativo, exploit ou alteração sensível do servidor.",
                logs = {
                    { key = "vrp_admin_cmd_apzban", name = "Comando /apzban", description = "Executou a rotina especial de banimento /apzban." },
                    { key = "vrp_admin_cmd_biowndwlliiiilllji", name = "Comando /BIOWNDWllIIiiLLljI", description = "Registrou a utilização do comando /BIOWNDWllIIiiLLljI do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_hackperma", name = "Comando /hackperma", description = "Aplicou punição permanente através da rotina administrativa." },
                    { key = "vrp_admin_cmd_safe_mode", name = "Comando /safe_mode", description = "Ativou ou desativou o Safe Mode global do servidor." },
                    { key = "vrp_admin_cmd_spauddimebanir", name = "Comando /SPAUddiMeBanir", description = "Registrou a utilização do comando /SPAUddiMeBanir do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_security_money_inject", name = "Possível injeção de dinheiro", description = "Detectou entrega anormal de dinheiro pelo proxy da vRP, incluindo resource, método e dados disponíveis da ocorrência." },
                    { key = "vrp_admin_security_attach_violation", name = "Violação de entidade anexada", description = "Detectou entidade pertencente a outro jogador anexada indevidamente a um veículo e acionou a rotina de segurança correspondente." },
                    { key = "vrp_admin_security_invalid_taser", name = "Dano de Taser incompatível", description = "Detectou evento de dano de Taser quando o jogador não estava realmente com a arma correspondente equipada." },
                }
            },
            {
                id = "moderacao_jogadores", label = "Jogadores e Moderação",
                description = "Comandos que alteram diretamente o estado, inventário, vida, punição ou acesso de jogadores.",
                logs = {
                    { key = "vrp_admin_cmd_bb", name = "Comando /bb", description = "Registrou a utilização do comando /bb do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_calaboca", name = "Comando /calaboca", description = "Registrou a utilização do comando /calaboca do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_calabocaarea", name = "Comando /calabocaarea", description = "Aplicou silenciamento em jogadores de uma área." },
                    { key = "vrp_admin_cmd_capuz", name = "Comando /capuz", description = "Colocou/retirou capuz de um jogador através do comando administrativo." },
                    { key = "vrp_admin_cmd_clearinv", name = "Comando /clearinv", description = "Limpou o inventário do próprio staff ou de um jogador informado." },
                    { key = "vrp_admin_cmd_clearinvall", name = "Comando /clearinvall", description = "Executou limpeza global de inventários." },
                    { key = "vrp_admin_cmd_clearinvarea", name = "Comando /clearinvarea", description = "Executou limpeza de inventários em uma área." },
                    { key = "vrp_admin_cmd_cuff", name = "Comando /cuff", description = "Algemou/desalgemou um jogador através do comando administrativo." },
                    { key = "vrp_admin_cmd_freezearea", name = "Comando /freezearea", description = "Aplicou congelamento em jogadores de uma área." },
                    { key = "vrp_admin_cmd_garagem", name = "Comando /garagem", description = "Registrou a utilização do comando /garagem do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_god", name = "Comando /god", description = "Restaurou a vida do próprio staff ou de um jogador informado." },
                    { key = "vrp_admin_cmd_godall", name = "Comando /godall", description = "Reviveu todos os jogadores online." },
                    { key = "vrp_admin_cmd_godarea", name = "Comando /godarea", description = "Registrou a utilização do comando /godarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_godd", name = "Comando /godd", description = "Aplicou revive completo e colete através do comando /godd." },
                    { key = "vrp_admin_cmd_godd2", name = "Comando /godd2", description = "Aplicou revive em área através do comando /godd2." },
                    { key = "vrp_admin_cmd_kick_console", name = "Comando /kick_console", description = "Executou expulsão de jogador via rotina de console." },
                    { key = "vrp_admin_cmd_kickbugados", name = "Comando /kickbugados", description = "Registrou a utilização do comando /kickbugados do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_kickbugados2", name = "Comando /kickbugados2", description = "Registrou a utilização do comando /kickbugados2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_kicksrc", name = "Comando /kicksrc", description = "Expulsou um source específico do servidor." },
                    { key = "vrp_admin_cmd_kill", name = "Comando /kill", description = "Abateu o próprio staff ou um jogador informado." },
                    { key = "vrp_admin_cmd_killarea", name = "Comando /killarea", description = "Registrou a utilização do comando /killarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_matar", name = "Comando /matar", description = "Alterou a vida do próprio staff ou de um jogador para o estado definido pelo comando /matar." },
                    { key = "vrp_admin_cmd_nn", name = "Comando /nn", description = "Registrou a utilização do comando /nn do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_notificacaoid", name = "Comando /notificacaoid", description = "Enviou uma notificação administrativa para um ID específico." },
                    { key = "vrp_admin_cmd_parall", name = "Comando /parall", description = "Registrou a utilização do comando /parall do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_rdet", name = "Comando /rdet", description = "Registrou a utilização do comando /rdet do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_remnotify", name = "Comando /remnotify", description = "Registrou a utilização do comando /remnotify do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_removerdetencao", name = "Comando /removerdetencao", description = "Registrou a utilização do comando /removerdetencao do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_remponto", name = "Comando /remponto", description = "Registrou a utilização do comando /remponto do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                }
            },
            {
                id = "teleporte_dimensoes", label = "Teleportes e Dimensões",
                description = "Comandos de teleporte, noclip, coordenadas, spectate, routing bucket e movimentação administrativa.",
                logs = {
                    { key = "vrp_admin_cmd_acao", name = "Comando /acao", description = "Registrou a utilização do comando /acao do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_acaoid", name = "Comando /acaoid", description = "Registrou a utilização do comando /acaoid do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_auroradimensao", name = "Comando /auroradimensao", description = "Registrou a utilização do comando /auroradimensao do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_cds", name = "Comando /cds", description = "Registrou a utilização do comando /cds do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_cds2", name = "Comando /cds2", description = "Registrou a utilização do comando /cds2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_cds3", name = "Comando /cds3", description = "Registrou a utilização do comando /cds3 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_cdsgaragem", name = "Comando /cdsgaragem", description = "Registrou a utilização do comando /cdsgaragem do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_cdsh", name = "Comando /cdsh", description = "Registrou a utilização do comando /cdsh do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_cdsh2", name = "Comando /cdsh2", description = "Registrou a utilização do comando /cdsh2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_dimensaoarea", name = "Comando /dimensaoarea", description = "Registrou a utilização do comando /dimensaoarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_freeze", name = "Comando /freeze", description = "Congelou/descongelou um jogador." },
                    { key = "vrp_admin_cmd_in", name = "Comando /in", description = "Registrou a utilização do comando /in do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_nc", name = "Comando /nc", description = "Ativou ou desativou o noclip administrativo." },
                    { key = "vrp_admin_cmd_rbl2", name = "Comando /rbl2", description = "Registrou a utilização do comando /rbl2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_spec2", name = "Comando /spec2", description = "Registrou a utilização do comando /spec2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_tpall", name = "Comando /tpall", description = "Teleportou todos os jogadores conforme a rotina do comando." },
                    { key = "vrp_admin_cmd_tparea", name = "Comando /tparea", description = "Registrou a utilização do comando /tparea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_tpcds", name = "Comando /tpcds", description = "Teleportou o staff para coordenadas informadas." },
                    { key = "vrp_admin_cmd_tpsrc", name = "Comando /tpsrc", description = "Registrou a utilização do comando /tpsrc do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_tpto", name = "Comando /tpto", description = "Teleportou o staff até outro jogador." },
                    { key = "vrp_admin_cmd_tptome", name = "Comando /tptome", description = "Puxou outro jogador até a posição do staff." },
                    { key = "vrp_admin_cmd_tptosrc", name = "Comando /tptosrc", description = "Registrou a utilização do comando /tptosrc do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_tpway", name = "Comando /tpway", description = "Teleportou o staff para o waypoint do mapa." },
                    { key = "vrp_admin_cmd_vdm", name = "Comando /vdm", description = "Registrou a utilização do comando /vdm do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                }
            },
            {
                id = "inventario_economia", label = "Inventário e Economia",
                description = "Comandos capazes de criar, remover, consultar ou alterar itens, dinheiro, criptomoedas, baús e recompensas.",
                logs = {
                    { key = "vrp_admin_cmd_abrirbaufac", name = "Comando /abrirbaufac", description = "Registrou a utilização do comando /abrirbaufac do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_addinsta", name = "Comando /addinsta", description = "Registrou a utilização do comando /addinsta do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_addmakapoints", name = "Comando /addmakapoints", description = "Registrou a utilização do comando /addmakapoints do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_arrumarportamalas", name = "Comando /arrumarportamalas", description = "Executou correção administrativa de porta-malas." },
                    { key = "vrp_admin_cmd_clearchest", name = "Comando /clearchest", description = "Limpou o conteúdo de um baú conforme a rotina administrativa." },
                    { key = "vrp_admin_cmd_clearmoney", name = "Comando /clearmoney", description = "Executou limpeza/zeragem de dinheiro conforme a rotina administrativa." },
                    { key = "vrp_admin_cmd_delete_money", name = "Comando /delete_money", description = "Removeu dinheiro através do comando administrativo." },
                    { key = "vrp_admin_cmd_entregarcarros", name = "Comando /entregarcarros", description = "Registrou a utilização do comando /entregarcarros do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_impostorenda", name = "Comando /impostorenda", description = "Registrou a utilização do comando /impostorenda do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_item", name = "Comando /item", description = "Criou um item diretamente no inventário do staff." },
                    { key = "vrp_admin_cmd_itemp", name = "Comando /itemp", description = "Entregou um item diretamente a outro jogador." },
                    { key = "vrp_admin_cmd_kitfesta", name = "Comando /kitfesta", description = "Registrou a utilização do comando /kitfesta do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_kitilha", name = "Comando /kitilha", description = "Registrou a utilização do comando /kitilha do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_kobetop1", name = "Comando /kobetop1", description = "Registrou a utilização do comando /kobetop1 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_money", name = "Comando /money", description = "Criou dinheiro para o próprio staff." },
                    { key = "vrp_admin_cmd_reentregarcaixa", name = "Comando /reentregarcaixa", description = "Registrou a utilização do comando /reentregarcaixa do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_reentregarskin", name = "Comando /reentregarskin", description = "Registrou a utilização do comando /reentregarskin do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_removercrypto", name = "Comando /removercrypto", description = "Removeu criptomoedas de um jogador." },
                    { key = "vrp_admin_cmd_removerdinheiro", name = "Comando /removerdinheiro", description = "Removeu dinheiro de um jogador." },
                    { key = "vrp_admin_cmd_topcrypto", name = "Comando /topcrypto", description = "Consultou o ranking de criptomoedas." },
                    { key = "vrp_admin_cmd_topmoney", name = "Comando /topmoney", description = "Consultou o ranking de dinheiro/banco." },
                    { key = "vrp_admin_cmd_topmoney2", name = "Comando /topmoney2", description = "Consultou ranking financeiro alternativo." },
                    { key = "vrp_admin_cmd_topmoney3", name = "Comando /topmoney3", description = "Consultou ranking financeiro alternativo." },
                }
            },
            {
                id = "grupos_permissoes", label = "Grupos e Permissões",
                description = "Comandos que adicionam, removem ou alteram grupos, permissões, blacklist de organizações e cargos administrativos.",
                logs = {
                    { key = "vrp_admin_cmd_addbl", name = "Comando /addbl", description = "Registrou a utilização do comando /addbl do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_addorgblacklist", name = "Comando /addorgblacklist", description = "Registrou a utilização do comando /addorgblacklist do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_addporte", name = "Comando /addporte", description = "Registrou a utilização do comando /addporte do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_bloquearfaccao", name = "Comando /bloquearfaccao", description = "Registrou a utilização do comando /bloquearfaccao do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_blpolicia", name = "Comando /blpolicia", description = "Registrou a utilização do comando /blpolicia do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_groupadd", name = "Comando /groupadd", description = "Adicionou um grupo a um jogador." },
                    { key = "vrp_admin_cmd_grouprem", name = "Comando /grouprem", description = "Removeu um grupo de um jogador." },
                    { key = "vrp_admin_cmd_groupremall", name = "Comando /groupremall", description = "Removeu um grupo de todos os jogadores que o possuíam." },
                    { key = "vrp_admin_cmd_ilegalbl", name = "Comando /ilegalbl", description = "Registrou a utilização do comando /ilegalbl do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_rblpolicia", name = "Comando /rblpolicia", description = "Registrou a utilização do comando /rblpolicia do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_realidadegroup", name = "Comando /realidadegroup", description = "Registrou a utilização do comando /realidadegroup do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_rembl", name = "Comando /rembl", description = "Registrou a utilização do comando /rembl do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_remilegal", name = "Comando /remilegal", description = "Registrou a utilização do comando /remilegal do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_removeorgblacklist", name = "Comando /removeorgblacklist", description = "Registrou a utilização do comando /removeorgblacklist do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_removervigilante", name = "Comando /removervigilante", description = "Registrou a utilização do comando /removervigilante do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_remporte", name = "Comando /remporte", description = "Registrou a utilização do comando /remporte do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_reset_vips", name = "Comando /reset_vips", description = "Executou a rotina global de reset dos grupos VIP." },
                    { key = "vrp_admin_cmd_setdev", name = "Comando /setdev", description = "Alterou grupo/cargo de desenvolvimento conforme a rotina do comando." },
                    { key = "vrp_admin_cmd_staff", name = "Comando /staff", description = "Entrou ou saiu do modo administrativo/cargo de staff." },
                    { key = "vrp_admin_cmd_vporte", name = "Comando /vporte", description = "Registrou a utilização do comando /vporte do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                }
            },
            {
                id = "identidade_personagem", label = "Identidade e Personagem",
                description = "Comandos que modificam whitelist, RG, nome, ID, aparência, roupas, preset, tatuagens e identificadores.",
                logs = {
                    { key = "vrp_admin_cmd_alterarid", name = "Comando /alterarid", description = "Alterou o ID/passaporte de um jogador no banco de dados." },
                    { key = "vrp_admin_cmd_copyface", name = "Comando /copyface", description = "Copiou a aparência facial de outro jogador." },
                    { key = "vrp_admin_cmd_copypreset", name = "Comando /copypreset", description = "Copiou o preset/aparência de outro jogador." },
                    { key = "vrp_admin_cmd_copyroupas", name = "Comando /copyroupas", description = "Copiou as roupas de outro jogador." },
                    { key = "vrp_admin_cmd_deletarid", name = "Comando /deletarid", description = "Excluiu dados vinculados a um ID/passaporte." },
                    { key = "vrp_admin_cmd_listskin", name = "Comando /listskin", description = "Registrou a utilização do comando /listskin do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_mulher", name = "Comando /mulher", description = "Registrou a utilização do comando /mulher do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_ppreset", name = "Comando /ppreset", description = "Registrou a utilização do comando /ppreset do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_rchar", name = "Comando /rchar", description = "Registrou a utilização do comando /rchar do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_renomear", name = "Comando /renomear", description = "Alterou nome/sobrenome de um jogador." },
                    { key = "vrp_admin_cmd_resetarinsta", name = "Comando /resetarinsta", description = "Registrou a utilização do comando /resetarinsta do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_resetidentifiers", name = "Comando /resetidentifiers", description = "Resetou identificadores vinculados a um jogador." },
                    { key = "vrp_admin_cmd_rg2", name = "Comando /rg2", description = "Consultou/alterou dados de RG conforme a rotina administrativa." },
                    { key = "vrp_admin_cmd_rtatuagem", name = "Comando /rtatuagem", description = "Removeu as tatuagens de um jogador." },
                    { key = "vrp_admin_cmd_setface", name = "Comando /setface", description = "Registrou a utilização do comando /setface do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_setpreset", name = "Comando /setpreset", description = "Aplicou um preset/aparência a outro jogador." },
                    { key = "vrp_admin_cmd_setpresetarea", name = "Comando /setpresetarea", description = "Registrou a utilização do comando /setpresetarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_setroupas", name = "Comando /setroupas", description = "Aplicou as roupas do staff em outro jogador." },
                    { key = "vrp_admin_cmd_setroupasarea", name = "Comando /setroupasarea", description = "Registrou a utilização do comando /setroupasarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_wladd", name = "Comando /wladd", description = "Liberou whitelist de um ID." },
                    { key = "vrp_admin_cmd_wlcheck", name = "Comando /wlcheck", description = "Registrou a utilização do comando /wlcheck do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_wlrem", name = "Comando /wlrem", description = "Removeu whitelist de um ID." },
                }
            },
            {
                id = "eventos_areas", label = "Eventos, Áreas e Zonas",
                description = "Comandos administrativos para eventos, perímetros, áreas, zonas, campanhas e limpezas em massa.",
                logs = {
                    { key = "vrp_admin_cmd_addevento", name = "Comando /addevento", description = "Registrou a utilização do comando /addevento do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_addeventoarea", name = "Comando /addeventoarea", description = "Registrou a utilização do comando /addeventoarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_addponto", name = "Comando /addponto", description = "Registrou a utilização do comando /addponto do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_cleararea", name = "Comando /cleararea", description = "Registrou a utilização do comando /cleararea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_encerrarevento", name = "Comando /encerrarevento", description = "Registrou a utilização do comando /encerrarevento do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_evento2", name = "Comando /evento2", description = "Registrou a utilização do comando /evento2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_idarea", name = "Comando /idarea", description = "Registrou a utilização do comando /idarea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_idarea2", name = "Comando /idarea2", description = "Registrou a utilização do comando /idarea2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_iniciarevento", name = "Comando /iniciarevento", description = "Registrou a utilização do comando /iniciarevento do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_iniciarfesta", name = "Comando /iniciarfesta", description = "Registrou a utilização do comando /iniciarfesta do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_liberarzona", name = "Comando /liberarzona", description = "Registrou a utilização do comando /liberarzona do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_limpararea", name = "Comando /limpararea", description = "Registrou a utilização do comando /limpararea do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_perimetro", name = "Comando /perimetro", description = "Registrou a utilização do comando /perimetro do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_rcamp", name = "Comando /rcamp", description = "Registrou a utilização do comando /rcamp do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_remevento", name = "Comando /remevento", description = "Registrou a utilização do comando /remevento do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_resetarchamados", name = "Comando /resetarchamados", description = "Registrou a utilização do comando /resetarchamados do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_resetarremap", name = "Comando /resetarremap", description = "Registrou a utilização do comando /resetarremap do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_scamp", name = "Comando /scamp", description = "Registrou a utilização do comando /scamp do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_scamp2", name = "Comando /scamp2", description = "Registrou a utilização do comando /scamp2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_scamp3", name = "Comando /scamp3", description = "Registrou a utilização do comando /scamp3 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_statuszona", name = "Comando /statuszona", description = "Registrou a utilização do comando /statuszona do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                }
            },
            {
                id = "comunicacao", label = "Comunicação e Avisos",
                description = "Comandos de mensagens administrativas, avisos globais, avisos de serviços e comunicações direcionadas.",
                logs = {
                    { key = "vrp_admin_cmd_aa", name = "Comando /aa", description = "Registrou a utilização do comando /aa do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_aviso69", name = "Comando /aviso69", description = "Registrou a utilização do comando /aviso69 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisoadm", name = "Comando /avisoadm", description = "Enviou um aviso administrativo global." },
                    { key = "vrp_admin_cmd_avisoadm2", name = "Comando /avisoadm2", description = "Registrou a utilização do comando /avisoadm2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisoadm3", name = "Comando /avisoadm3", description = "Registrou a utilização do comando /avisoadm3 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisobombeiro", name = "Comando /avisobombeiro", description = "Registrou a utilização do comando /avisobombeiro do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisobombeiro2", name = "Comando /avisobombeiro2", description = "Registrou a utilização do comando /avisobombeiro2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisocb", name = "Comando /avisocb", description = "Registrou a utilização do comando /avisocb do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisocreche", name = "Comando /avisocreche", description = "Registrou a utilização do comando /avisocreche do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisofac", name = "Comando /avisofac", description = "Registrou a utilização do comando /avisofac do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisohp", name = "Comando /avisohp", description = "Registrou a utilização do comando /avisohp do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisoilegal", name = "Comando /avisoilegal", description = "Registrou a utilização do comando /avisoilegal do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisomec", name = "Comando /avisomec", description = "Registrou a utilização do comando /avisomec do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisopm", name = "Comando /avisopm", description = "Registrou a utilização do comando /avisopm do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_avisostaff", name = "Comando /avisostaff", description = "Enviou uma comunicação destinada à equipe/staff." },
                    { key = "vrp_admin_cmd_avisovip", name = "Comando /avisovip", description = "Registrou a utilização do comando /avisovip do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_instagram", name = "Comando /instagram", description = "Registrou a utilização do comando /instagram do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_pm", name = "Comando /pm", description = "Registrou a utilização do comando /pm do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_pradio", name = "Comando /pradio", description = "Registrou a utilização do comando /pradio do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                }
            },
            {
                id = "veiculos_mundo", label = "Veículos e Mundo",
                description = "Comandos que criam, removem, alteram, reparam ou administram veículos, objetos, NPCs e entidades do mapa.",
                logs = {
                    { key = "vrp_admin_cmd_addallcars", name = "Comando /addallcars", description = "Adicionou o veículo configurado a todos os jogadores online via console." },
                    { key = "vrp_admin_cmd_addcar", name = "Comando /addcar", description = "Adicionou um veículo à garagem de um jogador." },
                    { key = "vrp_admin_cmd_admincv", name = "Comando /admincv", description = "Registrou a utilização do comando /admincv do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_barreira", name = "Comando /barreira", description = "Registrou a utilização do comando /barreira do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_bolinha", name = "Comando /bolinha", description = "Registrou a utilização do comando /bolinha do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_bolinha2", name = "Comando /bolinha2", description = "Registrou a utilização do comando /bolinha2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_car", name = "Comando /car", description = "Spawnou um veículo através do comando administrativo." },
                    { key = "vrp_admin_cmd_carcolor", name = "Comando /carcolor", description = "Alterou a cor de um veículo pela rotina administrativa." },
                    { key = "vrp_admin_cmd_carseat", name = "Comando /carseat", description = "Registrou a utilização do comando /carseat do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_clearallveh", name = "Comando /clearallveh", description = "Executou limpeza global de veículos." },
                    { key = "vrp_admin_cmd_cnitro", name = "Comando /cnitro", description = "Adicionou o veículo de nitro configurado à garagem de um jogador." },
                    { key = "vrp_admin_cmd_cone", name = "Comando /cone", description = "Registrou a utilização do comando /cone do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_deleteall", name = "Comando /deleteall", description = "Registrou a utilização do comando /deleteall do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_delnpcs", name = "Comando /delnpcs", description = "Registrou a utilização do comando /delnpcs do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_delobjs", name = "Comando /delobjs", description = "Registrou a utilização do comando /delobjs do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_donoveiculo", name = "Comando /donoveiculo", description = "Registrou a utilização do comando /donoveiculo do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_dvall", name = "Comando /dvall", description = "Executou remoção global de veículos pela rotina /dvall." },
                    { key = "vrp_admin_cmd_efeitos", name = "Comando /efeitos", description = "Registrou a utilização do comando /efeitos do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_forcedelete", name = "Comando /forcedelete", description = "Registrou a utilização do comando /forcedelete do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_hash", name = "Comando /hash", description = "Registrou a utilização do comando /hash do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_ney", name = "Comando /ney", description = "Registrou a utilização do comando /ney do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_rbarreira", name = "Comando /rbarreira", description = "Registrou a utilização do comando /rbarreira do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_rdesmanche", name = "Comando /rdesmanche", description = "Registrou a utilização do comando /rdesmanche do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_remcar", name = "Comando /remcar", description = "Removeu um veículo da garagem de um jogador via console." },
                    { key = "vrp_admin_cmd_tuning", name = "Comando /tuning", description = "Registrou a utilização do comando /tuning do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_tuning2", name = "Comando /tuning2", description = "Executou a rotina alternativa de tuning administrativo." },
                    { key = "vrp_admin_cmd_tunning", name = "Comando /tunning", description = "Aplicou tuning completo ao veículo próximo." },
                }
            },
            {
                id = "sistema_manutencao", label = "Sistema e Manutenção",
                description = "Comandos de manutenção global, reinício, limpeza, reset e alterações sistêmicas do servidor.",
                logs = {
                    { key = "vrp_admin_cmd_debugceu", name = "Comando /debugceu", description = "Registrou a utilização do comando /debugceu do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_rrcity", name = "Comando /rrcity", description = "Executou o reinício controlado da cidade, salvando dados e desconectando jogadores." },
                    { key = "vrp_admin_cmd_tempo", name = "Comando /tempo", description = "Registrou a utilização do comando /tempo do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                }
            },
            {
                id = "consultas_diagnostico", label = "Consultas e Diagnóstico",
                description = "Comandos de consulta, debug, status e ferramentas técnicas usadas pela equipe administrativa.",
                logs = {
                    { key = "vrp_admin_cmd_checkbugados", name = "Comando /checkbugados", description = "Registrou a utilização do comando /checkbugados do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_checkdriver", name = "Comando /checkdriver", description = "Executou diagnóstico para identificar o motorista de um veículo." },
                    { key = "vrp_admin_cmd_consultar", name = "Comando /consultar", description = "Registrou a utilização do comando /consultar do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_debug", name = "Comando /debug", description = "Registrou a utilização do comando /debug do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_debugid", name = "Comando /debugid", description = "Registrou a utilização do comando /debugid do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_desempregados", name = "Comando /desempregados", description = "Registrou a utilização do comando /desempregados do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_desempregados2", name = "Comando /desempregados2", description = "Registrou a utilização do comando /desempregados2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_desempregados3", name = "Comando /desempregados3", description = "Registrou a utilização do comando /desempregados3 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_display", name = "Comando /display", description = "Registrou a utilização do comando /display do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_flash", name = "Comando /flash", description = "Ativou ou desativou a velocidade administrativa Flash." },
                    { key = "vrp_admin_cmd_flash2", name = "Comando /flash2", description = "Ativou ou desativou a segunda rotina de velocidade administrativa Flash." },
                    { key = "vrp_admin_cmd_hash2", name = "Comando /hash2", description = "Registrou a utilização do comando /hash2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_jump", name = "Comando /jump", description = "Ativou ou desativou o super pulo administrativo." },
                    { key = "vrp_admin_cmd_leads", name = "Comando /leads", description = "Registrou a utilização do comando /leads do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_listgroup", name = "Comando /listgroup", description = "Registrou a utilização do comando /listgroup do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_locdesempregados", name = "Comando /locdesempregados", description = "Registrou a utilização do comando /locdesempregados do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_pfarda", name = "Comando /pfarda", description = "Registrou a utilização do comando /pfarda do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_players", name = "Comando /players", description = "Registrou a utilização do comando /players do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_pon", name = "Comando /pon", description = "Registrou a utilização do comando /pon do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_schack", name = "Comando /schack", description = "Registrou a utilização do comando /schack do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_status2", name = "Comando /status2", description = "Registrou a utilização do comando /status2 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_status3", name = "Comando /status3", description = "Registrou a utilização do comando /status3 do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_verentidades", name = "Comando /verentidades", description = "Consultou as entidades próximas através da ferramenta de diagnóstico." },
                    { key = "vrp_admin_cmd_vmorte", name = "Comando /vmorte", description = "Registrou a utilização do comando /vmorte do vrp_admin, incluindo os argumentos informados pela equipe administrativa." },
                    { key = "vrp_admin_cmd_vozes", name = "Comando /vozes", description = "Ativou ou desativou o diagnóstico de voz/proximidade dos jogadores." },
                }
            },
        }
    },
    {
        id = "empregos",
        label = "EMPREGOS",
        description = "Auditoria completa dos serviços, pagamentos, itens coletados/vendidos, progressão e segurança do m_empregos.",
        subcategories = {
            {
                id = "caminhoneiro", label = "Caminhoneiro",
                logs = {
                    { key = "job_caminhoneiro_payment", name = "Serviço concluído", description = "Registrou uma entrega/serviço de caminhoneiro concluído e o valor exato pago ao jogador." },
                    { key = "job_caminhoneiro_levelup", name = "Nível aumentado", description = "Registrou quando o caminhoneiro avançou de nível no sistema de empregos." }
                }
            },
            {
                id = "motorista", label = "Motorista",
                logs = {
                    { key = "job_motorista_payment", name = "Serviço concluído", description = "Registrou um trecho/serviço de motorista concluído e o valor exato pago ao jogador." },
                    { key = "job_motorista_levelup", name = "Nível aumentado", description = "Registrou quando o motorista avançou de nível no sistema de empregos." }
                }
            },
            {
                id = "taxista", label = "Taxista",
                logs = {
                    { key = "job_taxista_payment", name = "Corrida concluída", description = "Registrou uma corrida de táxi concluída e o valor exato pago ao jogador." },
                    { key = "job_taxista_levelup", name = "Nível aumentado", description = "Registrou quando o taxista avançou de nível no sistema de empregos." },
                    { key = "job_taxista_suspicious_trigger", name = "Trigger suspeito do Taxista", description = "Detectou chamadas repetidas do validador de corrida do Taxista durante o cooldown de segurança." }
                }
            },
            {
                id = "entregador", label = "Entregador",
                logs = {
                    { key = "job_entregador_payment", name = "Entrega concluída", description = "Registrou uma entrega concluída e o valor exato pago ao entregador, inclusive pelo modo legado seguro." },
                    { key = "job_entregador_levelup", name = "Nível aumentado", description = "Registrou quando o entregador avançou de nível no sistema de empregos." }
                }
            },
            {
                id = "lixeiro", label = "Lixeiro",
                logs = {
                    { key = "job_lixeiro_payment", name = "Serviço concluído", description = "Registrou uma coleta/etapa de lixeiro concluída e o valor exato pago ao jogador." },
                    { key = "job_lixeiro_levelup", name = "Nível aumentado", description = "Registrou quando o lixeiro avançou de nível no sistema de empregos." }
                }
            },
            {
                id = "eletricista", label = "Eletricista",
                logs = {
                    { key = "job_eletricista_payment", name = "Serviço concluído", description = "Registrou um reparo/serviço de eletricista concluído e o valor exato pago ao jogador." },
                    { key = "job_eletricista_levelup", name = "Nível aumentado", description = "Registrou quando o eletricista avançou de nível no sistema de empregos." }
                }
            },
            {
                id = "pescador", label = "Pescador",
                logs = {
                    { key = "job_pescador_caught", name = "Peixe pescado", description = "Registrou cada peixe efetivamente recebido pelo pescador e a quantidade entregue." },
                    { key = "job_pescador_sold", name = "Peixe vendido", description = "Registrou cada tipo de peixe vendido, quantidade, valor unitário e total recebido." },
                    { key = "job_pescador_bait_used", name = "Isca utilizada", description = "Registrou a retirada efetiva de uma isca do inventário para iniciar/continuar a pescaria." },
                    { key = "job_pescador_levelup", name = "Nível aumentado", description = "Registrou quando o pescador avançou de nível no sistema de empregos." }
                }
            },
            {
                id = "minerador", label = "Minerador",
                logs = {
                    { key = "job_minerador_collected", name = "Minério coletado", description = "Registrou cada minério efetivamente adicionado ao inventário do minerador." },
                    { key = "job_minerador_sold", name = "Minério vendido", description = "Registrou cada tipo de minério vendido, quantidade, valor unitário e total recebido." },
                    { key = "job_minerador_levelup", name = "Nível aumentado", description = "Registrou quando o minerador avançou de nível no sistema de empregos." }
                }
            },
            {
                id = "sistema", label = "Sistema de Empregos",
                logs = {
                    { key = "jobs_job_changed", name = "Emprego alterado", description = "Registrou quando um jogador assinou a carteira ou trocou de emprego na Central de Empregos." },
                    { key = "jobs_job_resigned", name = "Pedido de demissão", description = "Registrou quando um jogador pediu demissão do emprego atual." },
                    { key = "jobs_level_reset", name = "Nível do emprego resetado", description = "Registrou o reset de nível e experiência do emprego atual pelo comando/rotina de reset." },
                    { key = "jobs_config_job_changed", name = "Configuração de emprego alterada", description = "Registrou alterações server-side nas configurações, níveis, pagamentos e extras de um emprego." },
                    { key = "jobs_config_global_changed", name = "Configuração global alterada", description = "Registrou alterações da Central de Empregos e da posição do NPC." },
                    { key = "jobs_config_uniform_captured", name = "Uniforme capturado", description = "Registrou a captura e salvamento de um uniforme de emprego a partir de um jogador." }
                }
            },
            {
                id = "seguranca", label = "Segurança",
                logs = {
                    { key = "jobs_security_invalid_action", name = "Ação de emprego inválida", description = "Detectou tentativa de coletar, vender ou executar uma ação de emprego sem possuir o cargo correspondente." },
                    { key = "jobs_security_payment_spam", name = "Spam de pagamento bloqueado", description = "Detectou e bloqueou solicitações de pagamento repetidas em intervalo incompatível com um serviço normal." },
                    { key = "jobs_security_progress_spam", name = "Spam de experiência bloqueado", description = "Detectou e bloqueou solicitações repetidas de experiência em intervalo incompatível com um serviço normal." },
                    { key = "jobs_security_invalid_payment", name = "Pagamento inválido bloqueado", description = "Detectou tentativa de pagamento em emprego ou nível sem faixa de remuneração válida configurada." }
                }
            }
        }
    },
    {
        id = "concessionaria",
        label = "CONCESSIONÁRIA",
        description = "Auditoria completa de compras, entregas, revendas, test-drives, estoque, configurações e tentativas sensíveis da m_dealership.",
        subcategories = {
            {
                id = "compras_entregas", label = "Compras e Entregas",
                description = "Transações econômicas e registro efetivo dos veículos na garagem dos jogadores.",
                logs = {
                    { key = "dealership_vehicle_purchase", name = "Veículo comprado", description = "Registrou uma compra concluída na concessionária, incluindo valor de catálogo, desconto, valor pago, cor e estoque restante." },
                    { key = "dealership_vehicle_delivered", name = "Veículo entregue ao comprador", description = "Confirmou que o veículo comprado foi efetivamente registrado na garagem do jogador após o pagamento." },
                    { key = "dealership_vehicle_delivery_failed", name = "Falha na entrega do veículo", description = "Registrou quando o pagamento ocorreu mas o veículo não pôde ser confirmado na garagem, com ressarcimento automático do valor." },
                    { key = "dealership_vehicle_sold", name = "Veículo vendido à concessionária", description = "Registrou a revenda de um veículo próprio para a concessionária, incluindo valor de catálogo, percentual e dinheiro recebido." }
                }
            },
            {
                id = "test_drive", label = "Test-drive",
                description = "Início e encerramento das sessões de teste de veículos.",
                logs = {
                    { key = "dealership_testdrive_started", name = "Test-drive iniciado", description = "Registrou o início validado de um test-drive, veículo, ponto, tempo máximo e distância permitida." },
                    { key = "dealership_testdrive_finished", name = "Test-drive encerrado", description = "Registrou o encerramento de um test-drive, sua duração e o motivo do término." }
                }
            },
            {
                id = "estoque_catalogo", label = "Estoque e Catálogo",
                description = "Entrada, reposição, remoção e indisponibilidade de veículos do estoque da concessionária.",
                logs = {
                    { key = "dealership_stock_vehicle_added", name = "Veículo adicionado ao estoque", description = "Registrou o cadastro/entrada de um novo veículo no estoque da concessionária e sua quantidade inicial." },
                    { key = "dealership_stock_updated", name = "Estoque de veículo alterado", description = "Registrou uma reposição ou alteração manual da quantidade disponível de um veículo na concessionária." },
                    { key = "dealership_stock_vehicle_removed", name = "Veículo removido da concessionária", description = "Registrou a remoção administrativa de um veículo do catálogo/estoque da concessionária." },
                    { key = "dealership_catalog_vehicle_unavailable", name = "Veículo do estoque ficou indisponível", description = "Registrou quando um veículo ainda cadastrado na concessionária foi removido do catálogo principal do m_garage." }
                }
            },
            {
                id = "administracao", label = "Administração",
                description = "Alterações importantes na configuração econômica e operacional da concessionária.",
                logs = {
                    { key = "dealership_settings_updated", name = "Configuração da concessionária alterada", description = "Registrou alterações de vagas, cooldowns, revenda, test-drive, categorias e regras VIP da concessionária." }
                }
            },
            {
                id = "seguranca", label = "Segurança",
                description = "Tentativas manipuladas ou incompatíveis com o fluxo normal da concessionária.",
                logs = {
                    { key = "dealership_security_remote_action", name = "Ação remota bloqueada", description = "Detectou tentativa de comprar ou vender veículo sem o jogador estar fisicamente próximo da concessionária." },
                    { key = "dealership_security_invalid_purchase", name = "Compra inválida bloqueada", description = "Detectou tentativa de comprar spawn inexistente/indisponível ou veículo VIP pelo fluxo comum." },
                    { key = "dealership_security_invalid_sale", name = "Venda inválida bloqueada", description = "Detectou tentativa de vender veículo inexistente, de outro jogador ou veículo VIP para a concessionária." },
                    { key = "dealership_security_invalid_testdrive", name = "Test-drive inválido bloqueado", description = "Detectou tentativa de criar sessão/dimensão de test-drive sem veículo, ponto ou proximidade válidos." },
                    { key = "dealership_security_admin_command_denied", name = "Comando /conce sem permissão", description = "Detectou jogador tentando utilizar o comando administrativo de estoque da concessionária sem a permissão necessária." }
                }
            },
            {
                id = "sistema", label = "Sistema",
                description = "Falhas internas importantes que podem afetar dinheiro, entrega ou persistência do estoque.",
                logs = {
                    { key = "dealership_system_stock_sync_error", name = "Falha ao persistir estoque", description = "Registrou uma compra entregue em que a atualização persistente do estoque retornou falha." },
                    { key = "dealership_system_transaction_error", name = "Erro crítico de transação", description = "Registrou exceções ou falhas críticas durante compra/venda para auxiliar auditoria e recuperação." },
                    { key = "dealership_system_config_error", name = "Erro de configuração", description = "Registrou falhas importantes ao carregar, decodificar ou persistir dealership.json." }
                }
            }
        }
    },
    {
        id = "vrp",
        label = "VRP",
        description = "Auditoria das funções centrais da vRP que alteram dinheiro, inventário, banco, cargos, armas, acesso e outros estados críticos do jogador.",
        subcategories = {
            {
                id = "carteira_pagamentos", label = "Carteira e Pagamentos",
                description = "Créditos, débitos e pagamentos realizados pelas funções centrais da carteira da vRP.",
                logs = {
                    { key = "vrp_wallet_give_money", name = "Dinheiro adicionado à carteira", description = "Registrou uma chamada bem-sucedida de vRP.giveMoney, incluindo valor, saldo anterior, saldo final e resource de origem." },
                    { key = "vrp_wallet_inventory_credit", name = "Dinheiro inserido na carteira via inventário", description = "Registrou quando o item money foi adicionado diretamente através de vRP.giveInventoryItem, sem passar por vRP.giveMoney." },
                    { key = "vrp_wallet_try_remove_money", name = "Dinheiro retirado da carteira via tryGet", description = "Registrou uma remoção confirmada do item money através de vRP.tryGetInventoryItem." },
                    { key = "vrp_wallet_remove_money", name = "Dinheiro removido da carteira", description = "Registrou uma remoção confirmada do item money através de vRP.removeInventoryItem." },
                    { key = "vrp_try_payment", name = "Pagamento realizado (tryPayment)", description = "Registrou um pagamento confirmado por vRP.tryPayment, identificando valor, origem do dinheiro e saldos antes/depois." },
                    { key = "vrp_full_payment", name = "Pagamento realizado (tryFullPayment)", description = "Registrou uma chamada direta e bem-sucedida de vRP.tryFullPayment, identificando se o valor saiu do banco ou carteira." }
                }
            },
            {
                id = "banco_economia", label = "Banco e Economia",
                description = "Alterações de saldo bancário, transferências, saques, depósitos, Makapoints e multas.",
                logs = {
                    { key = "vrp_bank_give_money", name = "Dinheiro adicionado ao banco", description = "Registrou vRP.giveBankMoney com valor adicionado, banco antes/depois e resource de origem." },
                    { key = "vrp_bank_set_balance", name = "Saldo bancário definido diretamente", description = "Registrou chamadas diretas de vRP.setBankMoney, mostrando saldo anterior, novo saldo e diferença." },
                    { key = "vrp_bank_withdraw", name = "Saque bancário", description = "Registrou saque confirmado pelo vRP.tryWithdraw, com movimentação do banco para a carteira." },
                    { key = "vrp_bank_deposit", name = "Depósito bancário", description = "Registrou depósito confirmado pelo vRP.tryDeposit, com movimentação da carteira para o banco." },
                    { key = "vrp_bank_transfer", name = "Transferência bancária", description = "Registrou transferência confirmada entre dois jogadores via vRP.tryTransfer, com saldos de origem/destino." },
                    { key = "vrp_makapoints_give", name = "Makapoints adicionados", description = "Registrou vRP.giveMakapoints, mostrando quantidade adicionada e saldo de pontos antes/depois." },
                    { key = "vrp_makapoints_set", name = "Makapoints definidos diretamente", description = "Registrou chamadas diretas de vRP.setMakapoints e a diferença no saldo de pontos." },
                    { key = "vrp_fines_update", name = "Multas alteradas", description = "Registrou vRP.updateMultas, mostrando valor anterior, valor final e diferença." }
                }
            },
            {
                id = "inventario_mochila", label = "Inventário e Mochila",
                description = "Funções-base que adicionam, removem ou limpam itens e alteram a capacidade de mochila.",
                logs = {
                    { key = "vrp_inventory_give_item", name = "Item adicionado pela vRP", description = "Registrou item efetivamente adicionado por vRP.giveInventoryItem, incluindo spawn, nome, quantidade, slot e resource." },
                    { key = "vrp_inventory_try_remove_item", name = "Item retirado via tryGetInventoryItem", description = "Registrou item efetivamente retirado por vRP.tryGetInventoryItem." },
                    { key = "vrp_inventory_remove_item", name = "Item removido via removeInventoryItem", description = "Registrou item efetivamente removido por vRP.removeInventoryItem." },
                    { key = "vrp_inventory_clear", name = "Inventário limpo", description = "Registrou vRP.clearInventory, incluindo quantidade de slots, itens removidos e resumo do conteúdo anterior." },
                    { key = "vrp_backpack_added", name = "Mochila adicionada", description = "Registrou vRP.addMochila e a quantidade de expansões de mochila antes/depois." },
                    { key = "vrp_backpack_removed", name = "Mochila removida", description = "Registrou vRP.remMochila e a capacidade removida do jogador." },
                    { key = "vrp_backpack_expiration", name = "Expiração da mochila alterada", description = "Registrou vRP.atualizarMochila e a alteração do tempo de expiração da mochila." }
                }
            },
            {
                id = "grupos_permissoes", label = "Grupos e Permissões",
                description = "Setagens de cargos, expirações de VIP e alterações estruturais no catálogo de grupos da vRP.",
                logs = {
                    { key = "vrp_group_added", name = "Cargo adicionado pela vRP", description = "Registrou um cargo realmente adicionado ao jogador através de vRP.addUserGroup." },
                    { key = "vrp_group_removed", name = "Cargo removido pela vRP", description = "Registrou um cargo realmente removido do jogador através de vRP.removeUserGroup." },
                    { key = "vrp_group_expiration_set", name = "Expiração de VIP alterada", description = "Registrou vRP.setUserGroupExpiration, mostrando cargo e expiração anterior/nova." },
                    { key = "vrp_managed_group_saved", name = "Cargo gerenciado criado/alterado", description = "Registrou criação, edição ou renomeação de cargo no sistema dinâmico de groups.json." },
                    { key = "vrp_managed_group_removed", name = "Cargo gerenciado excluído", description = "Registrou exclusão de cargo no sistema dinâmico e remoção correspondente dos usuários." },
                    { key = "vrp_fac_groups_created", name = "Cargos de FAC criados", description = "Registrou criação em lote dos cargos padrão de uma organização/facção." },
                    { key = "vrp_fac_groups_removed", name = "Cargos de FAC removidos", description = "Registrou remoção em lote dos cargos de uma organização/facção." },
                    { key = "vrp_managed_groups_reloaded", name = "Grupos recarregados", description = "Registrou recarga manual do catálogo dinâmico de cargos da vRP." }
                }
            },
            {
                id = "armas", label = "Armas",
                description = "Alterações diretas e persistentes no estado de armas mantido pela vRP.",
                logs = {
                    { key = "vrp_weapon_added", name = "Arma adicionada pela vRP", description = "Registrou vRP.addWeapon, arma, munição definida e estado anterior." },
                    { key = "vrp_weapons_set", name = "Lista de armas definida", description = "Registrou vRP.setWeapons somente quando o conjunto persistente de armas realmente mudou." },
                    { key = "vrp_weapons_cleared", name = "Armas limpas pela vRP", description = "Registrou vRP.clearWeapons e o conjunto de armas efetivamente removido." },
                    { key = "vrp_weapons_data_cleared", name = "Dados de armas zerados", description = "Registrou vRP.limparArmas, uma segunda função da base que zera diretamente as armas persistidas do jogador." }
                }
            },
            {
                id = "dados_persistentes", label = "Dados Persistentes",
                description = "Alterações diretas em chaves persistentes de usuário fora do datatable automático da vRP.",
                logs = {
                    { key = "vrp_userdata_set", name = "UData personalizada gravada", description = "Registrou vRP.setUData para chaves diferentes de vRP:datatable, incluindo chave, tamanho do valor e resource de origem sem expor o conteúdo salvo." },
                    { key = "vrp_userdata_removed", name = "UData removida", description = "Registrou vRP.remUData, identificando a chave persistente removida e o resource responsável." }
                }
            },
            {
                id = "conta_acesso", label = "Conta e Acesso",
                description = "Alterações críticas de whitelist, banimento, expulsão e limpeza completa da conta.",
                logs = {
                    { key = "vrp_whitelist_set", name = "Whitelist alterada pela vRP", description = "Registrou vRP.setWhitelisted quando o estado de whitelist realmente mudou." },
                    { key = "vrp_player_banned", name = "Banimento aplicado pela vRP", description = "Registrou vRP.setBanned, incluindo motivo, expiração, origem e informações de staff disponíveis." },
                    { key = "vrp_ban_ip_removed", name = "IP de ban removido", description = "Registrou vRP.removeBanIp quando um ou mais IPs foram removidos do cache de bloqueio." },
                    { key = "vrp_player_kick", name = "Jogador expulso pela vRP", description = "Registrou vRP.kick antes de desconectar o jogador, incluindo motivo, source e resource de origem." },
                    { key = "vrp_account_cleared", name = "Conta limpa", description = "Registrou vRP.clearAccount com resumo do inventário, armas e mochila existentes antes da limpeza." }
                }
            },
            {
                id = "seguranca", label = "Segurança",
                description = "Ocorrências anormais detectadas dentro das funções centrais da vRP.",
                logs = {
                    { key = "vrp_security_invalid_inventory_amount", name = "Quantidade de inventário inválida bloqueada", description = "Detectou quantidade zero/negativa em funções críticas de adição/remoção de item e bloqueou a operação." },
                    { key = "vrp_security_inventory_overweight", name = "Peso de inventário anormal", description = "Detectou inventário acima do limite de segurança antes da rotina de punição da base." },
                    { key = "vrp_security_ammo_increase", name = "Aumento anormal de munição", description = "Detectou o client reportando mais munição do que a quantidade registrada pela vRP." },
                    { key = "vrp_security_unknown_weapon", name = "Arma não registrada detectada", description = "Detectou arma reportada pelo client que não existia no conjunto persistente de armas do jogador." }
                }
            }
        }
    }
}
-- ============================================================================
-- HIERARQUIA DE STAFF
-- ============================================================================
-- Impede que um cargo inferior adicione/remova um cargo de staff igual ou maior.
-- Cargos não listados têm nível 0 e continuam normalmente gerenciáveis.
ServerConfig.GroupHierarchy = {
    dono = 100,
    developer = 90,
    admin = 80,
    moderador = 60,
    suporte = 40
}


-- ============================================================================
-- PERMISSÕES DINÂMICAS DO PAINEL
-- ============================================================================
-- Cargos reconhecidos pelo gerenciador interno de permissões.
-- dono e developer sempre possuem acesso total e não podem ser desmarcados.
ServerConfig.PanelRoles = {
    "dono",
    "developer",
    "admin",
    "moderador",
    "suporte"
}

ServerConfig.PanelRoleLabels = {
    dono = "Dono",
    developer = "Developer",
    admin = "Admin",
    moderador = "Moderador",
    suporte = "Suporte"
}

-- Mantém o comportamento atual da base para admin e começa moderador/suporte
-- bloqueados até que dono/developer liberem as funções desejadas no painel.
ServerConfig.DefaultPanelRoleAccess = {
    admin = true,
    moderador = false,
    suporte = false
}

-- Todas as opções controláveis do painel. Os itens "view_*" controlam
-- a visibilidade das abas; as demais chaves controlam as ações dentro delas.
ServerConfig.PanelPermissionDefinitions = {
    { key = "view_server", label = "Acessar aba Servidor", category = "Abas" },
    { key = "view_players", label = "Acessar aba Jogadores", category = "Abas" },
    { key = "view_warnings", label = "Acessar aba Advertências", category = "Abas" },
    { key = "view_map", label = "Acessar aba Mapa", category = "Abas" },
    { key = "view_calls", label = "Acessar aba Chamados", category = "Abas" },
    { key = "view_groups", label = "Acessar aba Setagem", category = "Abas" },
    { key = "view_identity_editor", label = "Acessar aba Alterar RG", category = "Abas" },
    { key = "view_items", label = "Acessar aba Itens", category = "Abas" },
    { key = "view_weapons", label = "Acessar aba Armas", category = "Abas" },
    { key = "view_vips", label = "Acessar aba VIPs", category = "Abas" },
    { key = "view_vehicles", label = "Acessar aba Veículos", category = "Abas" },
    { key = "view_radio", label = "Acessar aba Rádio", category = "Abas" },
    { key = "view_locations", label = "Acessar aba Locais", category = "Abas" },
    { key = "view_climate", label = "Acessar aba Clima", category = "Abas" },

    { key = "wladd", label = "Liberar whitelist", category = "Servidor" },
    { key = "wlrem", label = "Remover whitelist", category = "Servidor" },
    { key = "ban", label = "Banir jogador", category = "Servidor / Jogadores" },
    { key = "unban", label = "Desbanir jogador", category = "Servidor" },
    { key = "ban_history", label = "Ver registros de ban e unban", category = "Servidor" },
    { key = "catch_rg", label = "Consultar RG", category = "Servidor / Jogadores" },
    { key = "send_adm", label = "Aviso geral", category = "Servidor" },
    { key = "send_dm", label = "Mensagem privada", category = "Servidor / Jogadores" },
    { key = "warning", label = "Advertência / Castigo", category = "Servidor / Jogadores" },
    { key = "needs_manage", label = "Ligar / desligar fome e sede", category = "Servidor" },
    { key = "delete_warning", label = "Excluir advertência registrada", category = "Advertências" },
    { key = "givemoney", label = "Adicionar dinheiro", category = "Servidor / Jogadores" },
    { key = "remove_money", label = "Remover dinheiro", category = "Servidor / Jogadores" },
    { key = "tpway", label = "Ir ao waypoint", category = "Servidor" },
    { key = "tpcds", label = "Teleportar por coordenadas", category = "Servidor" },
    { key = "godall", label = "Reviver todos", category = "Servidor" },
    { key = "clear_allveh", label = "Limpar veículos", category = "Servidor" },
    { key = "clear_props", label = "Limpar props", category = "Servidor" },

    { key = "tpto", label = "Ir até jogador", category = "Jogadores" },
    { key = "tptome", label = "Puxar jogador", category = "Jogadores" },
    { key = "god", label = "Reviver jogador", category = "Jogadores" },
    { key = "kill", label = "Matar jogador", category = "Jogadores" },
    { key = "freeze", label = "Congelar jogador", category = "Jogadores" },
    { key = "unfreeze", label = "Descongelar jogador", category = "Jogadores" },
    { key = "kick", label = "Expulsar jogador", category = "Jogadores" },
    { key = "clear_weapons", label = "Limpar armas", category = "Jogadores" },
    { key = "inspect_inventory", label = "Inspecionar inventário", category = "Jogadores" },
    { key = "give_item", label = "Adicionar item ao jogador", category = "Jogadores" },
    { key = "remove_item", label = "Remover item do jogador", category = "Jogadores" },
    { key = "clear_inv", label = "Limpar inventário do jogador", category = "Jogadores" },

    { key = "map_screen", label = "Ver tela do jogador", category = "Mapa" },

    { key = "calls_accept", label = "Aceitar chamado Staff", category = "Chamados" },
    { key = "calls_finish", label = "Finalizar chamado Staff", category = "Chamados" },
    { key = "calls_history", label = "Ver histórico de chamados", category = "Chamados" },
    { key = "calls_ranking", label = "Ver ranking da Staff", category = "Chamados" },
    { key = "calls_evaluations", label = "Ver avaliações de atendimentos", category = "Chamados" },
    { key = "calls_staff_notes", label = "Ver notas da Staff", category = "Chamados" },

    { key = "set_group", label = "Adicionar cargo", category = "Setagem" },
    { key = "remove_group", label = "Remover cargo", category = "Setagem" },

    { key = "edit_identity", label = "Editar Nome, Sobrenome, Idade, Telefone e RG", category = "Alterar RG" },
    { key = "edit_identity_balance", label = "Editar Carteira e Banco", category = "Alterar RG" },
    { key = "change_user_id", label = "Alterar Passaporte / ID", category = "Alterar RG" },

    { key = "spawn_self_item", label = "Spawnar item para si", category = "Itens" },
    { key = "spawn_weapon", label = "Puxar arma + munição", category = "Armas" },

    { key = "create_vip", label = "Criar VIP", category = "VIPs" },
    { key = "edit_vip", label = "Editar VIP", category = "VIPs" },
    { key = "assign_vip", label = "Setar VIP em jogador", category = "VIPs" },
    { key = "delete_vip", label = "Excluir VIP", category = "VIPs" },

    { key = "spawn_veh", label = "Spawnar veículo", category = "Veículos" },
    { key = "add_vehicle_catalog", label = "Adicionar veículo ao catálogo", category = "Veículos" },
    { key = "give_veh", label = "Dar veículo", category = "Veículos" },
    { key = "rem_veh", label = "Remover veículo", category = "Veículos" },
    { key = "fix", label = "Reparar veículo", category = "Servidor / Veículos" },
    { key = "tuning", label = "Tunar veículo", category = "Veículos" },
    { key = "hash", label = "Consultar hash do veículo", category = "Servidor / Veículos" },
    { key = "dv", label = "Deletar veículo", category = "Servidor / Veículos" },

    { key = "radio_manage", label = "Criar, editar e excluir rádios privadas", category = "Rádio" },

    { key = "add_location", label = "Cadastrar local", category = "Locais" },
    { key = "remove_location", label = "Remover local cadastrado", category = "Locais" },
    { key = "teleport_location", label = "Teleportar para local cadastrado", category = "Locais" },

    { key = "weather_manage", label = "Gerenciar clima", category = "Clima" },
    { key = "time_manage", label = "Gerenciar horário", category = "Clima" }
}

ServerConfig.HiddenGroupPatterns = {
    "Paisana",
    "%-off$",
    "^off"
}

-- Limites básicos contra payloads abusivos.
ServerConfig.Limits = {
    maxMessage = 500,
    maxAlertSeconds = 300,
    maxPunishmentMinutes = 10080, -- até 7 dias por advertência
    maxReason = 300,
    maxAmount = 1000000000,
    maxString = 80
}


-- ============================================================================
-- INTERFACES VRP/TUNNEL ESTAVEIS (ARQUIVO ABERTO)
-- O server.lua protegido recebe referencias prontas, evitando metaprogramacao
-- do Tunnel/Proxy dentro do chunk virtualizado.
-- ============================================================================
local MG_TUNNEL = module("vrp", "lib/Tunnel")
local MG_PROXY = module("vrp", "lib/Proxy")
local MG_VRP = MG_PROXY["getInterface"]("vRP")
local MG_VRPCLIENT = MG_TUNNEL["getInterface"]("vRP")
local MG_GROUPS = module("vrp", "cfg/groups")
local MG_ITEMS = module("vrp", "cfg/items")
rawset(_G, "MG_PAINEL_SERVER_VRP", MG_VRP)
rawset(_G, "MG_PAINEL_SERVER_VRPCLIENT", MG_VRPCLIENT)
rawset(_G, "MG_PAINEL_SERVER_GROUPS", MG_GROUPS)
rawset(_G, "MG_PAINEL_SERVER_ITEMS", MG_ITEMS)

-- ============================================================================
-- TRANSPORTE SERVER ABERTO / COMPATIVEL COM OFUSCACAO
-- NAO OFUSCAR ESTE ARQUIVO. Ele nao possui AUTH e nao concede permissao.
-- Toda validacao, permissao e logica administrativa permanece em server.lua.
-- ============================================================================
local MG_BRIDGE_RESOURCE = GetCurrentResourceName()
local MG_BRIDGE_REQUEST = MG_BRIDGE_RESOURCE .. ":bridgeRequestOfficial"
local MG_BRIDGE_RESPONSE = MG_BRIDGE_RESOURCE .. ":bridgeResponseOfficial"
local MG_SERVER_BRIDGE_BUILD = "2.90.5-final-obfsafe"

local function mgBridgeError(message)
    return {
        ok = false,
        success = false,
        allowed = false,
        message = tostring(message or "Nao foi possivel concluir a acao.")
    }
end

local function mgBridgeDispatch(method, data)
    method = tostring(method or "")
    if method == "" or #method > 64 then
        return mgBridgeError("Acao de transporte invalida.")
    end

    local core = rawget(_G, "MG_PAINEL_SERVER_CORE")
    local dispatch = type(core) == "table" and core["dispatch"] or nil
    if type(dispatch) ~= "function" then
        return mgBridgeError("O nucleo protegido do painel ainda nao esta disponivel.")
    end

    -- Executado sincronamente dentro do mesmo handler para preservar o `source`
    -- real do player em todas as funcoes administrativas do server.lua.
    local ok, response = pcall(dispatch, method, type(data) == "table" and data or {})
    if not ok then
        print(("^1[m_paineladm_v2] Falha no dispatch '%s': %s^0"):format(method, tostring(response)))
        return mgBridgeError("Erro interno ao processar a solicitacao.")
    end

    if response == nil then
        return mgBridgeError("O servidor nao retornou resposta para esta solicitacao.")
    end

    return response
end

-- Interface Tunnel minima usada apenas pelas rotinas internas do client core.
-- Os nomes sao literais e este arquivo NAO e ofuscado.
local MG_INTERNAL_API = {}
MG_INTERNAL_API["bootstrap"] = function()
    return mgBridgeDispatch("bootstrap", {})
end
MG_INTERNAL_API["stopLiveScreen"] = function()
    return mgBridgeDispatch("liveScreenStop", {})
end
MG_INTERNAL_API["addLocation"] = function(data)
    return mgBridgeDispatch("addLocation", data)
end
MG_INTERNAL_API["vipPlayer"] = function(data)
    return mgBridgeDispatch("vipPlayer", data)
end
MG_TUNNEL["bindInterface"](MG_BRIDGE_RESOURCE, MG_INTERNAL_API)

-- NUI/JS -> servidor. O callback CEF nunca entra no client.lua ofuscado.
RegisterNetEvent(MG_BRIDGE_REQUEST)
AddEventHandler(MG_BRIDGE_REQUEST, function(requestId, method, data)
    local playerSource = tonumber(source)
    requestId = tostring(requestId or "")
    method = tostring(method or "")

    if not playerSource or playerSource <= 0 or requestId == "" or #requestId > 160 or method == "" or #method > 64 then
        return
    end

    local response = mgBridgeDispatch(method, data)
    TriggerClientEvent(MG_BRIDGE_RESPONSE, playerSource, requestId, response)
end)

-- Encerramento do test-drive VIP por eventos fixos. Esta camada aberta apenas
-- transporta a solicitacao; AUTH, estado da sessao e regras continuam no
-- dispatch protegido do server.lua.
local MG_VIP_FINISH_REQUEST_SAFE = MG_BRIDGE_RESOURCE .. ":vipFinishRequestSafe"
local MG_VIP_FINISH_RESPONSE_SAFE = MG_BRIDGE_RESOURCE .. ":vipFinishResponseSafe"
RegisterNetEvent(MG_VIP_FINISH_REQUEST_SAFE)
AddEventHandler(MG_VIP_FINISH_REQUEST_SAFE, function(requestId)
    local playerSource = tonumber(source)
    requestId = tostring(requestId or "")
    if not playerSource or playerSource <= 0 or requestId == "" or #requestId > 160 then return end

    local response = mgBridgeDispatch("vipPlayer", { mode = "finishTest" })
    TriggerClientEvent(MG_VIP_FINISH_RESPONSE_SAFE, playerSource, requestId, response)
end)

-- O client.lua protegido usa Tunnel apenas para suas chamadas internas.
-- O bridge abaixo permanece dedicado exclusivamente aos callbacks CEF/NUI.

CreateThread(function()
    Wait(0)
    print(("^2[m_paineladm_v5] Connection successfully stabilised by </> winchester.^0"):format(MG_SERVER_BRIDGE_BUILD))
end)
