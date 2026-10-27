-- Schema only: imported data and database deletion commands intentionally omitted.

CREATE TABLE IF NOT EXISTS `bench_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item` varchar(50) NOT NULL DEFAULT '0',
  `user_id` int(11) NOT NULL DEFAULT 0,
  `machine` varchar(50) NOT NULL DEFAULT '0',
  `amount` int(10) unsigned NOT NULL DEFAULT 0,
  `value` int(10) unsigned NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `bench_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT 0,
  `machine` varchar(50) DEFAULT NULL,
  `log` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `blocked_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `expireAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `bm_chamados` (
  `user_id` int(11) NOT NULL,
  `qtd` int(11) NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `bm_daily` (
  `user_id` int(11) NOT NULL DEFAULT 0,
  `time` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `bm_dealership` (
  `vehicle` varchar(50) NOT NULL,
  `stock` int(11) DEFAULT 0,
  PRIMARY KEY (`vehicle`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `bm_registration` (
  `user_id` int(11) DEFAULT NULL,
  `nome` varchar(100) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `telefone` varchar(50) DEFAULT NULL,
  `nascimento` varchar(50) DEFAULT NULL,
  `sexo` varchar(50) DEFAULT NULL,
  `social` varchar(50) DEFAULT NULL,
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `cdm_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) DEFAULT NULL,
  `passaporte` varchar(50) DEFAULT NULL,
  `cargo` varchar(100) DEFAULT NULL,
  `bau` varchar(100) DEFAULT NULL,
  `item` varchar(100) DEFAULT NULL,
  `qtd` int(11) DEFAULT NULL,
  `acao` varchar(100) DEFAULT NULL,
  `data` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `cdm_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bau` varchar(100) NOT NULL,
  `acao` varchar(100) NOT NULL,
  `data` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `cdm_org` (
  `org` varchar(50) NOT NULL,
  `membros` text NOT NULL DEFAULT '{}',
  `maxMembros` int(11) NOT NULL DEFAULT 0,
  `anotacao` text DEFAULT NULL,
  `bau` varchar(50) NOT NULL,
  `banco` int(11) NOT NULL DEFAULT 0,
  `bancoHistorico` text DEFAULT NULL,
  `farme` text DEFAULT '{}',
  `dias` text DEFAULT '{}',
  `recrutados` text DEFAULT '{}',
  `logrecrutados` text DEFAULT '{}',
  `diasrank` text DEFAULT '{}',
  `logentregafarme` text DEFAULT '{}',
  PRIMARY KEY (`org`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `cdm_orgtemp` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `tempo` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `clothes` (
  `name` varchar(50) DEFAULT NULL,
  `permiss` varchar(50) DEFAULT NULL,
  `service` varchar(50) DEFAULT NULL,
  `custom` text DEFAULT NULL,
  `sexo` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `dismantle_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `vehicle` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_vehicle_idx` (`user_id`,`vehicle`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `dm_ranks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `wins` int(11) DEFAULT 0,
  `losses` int(11) DEFAULT 0,
  `kills` int(11) DEFAULT 0,
  `deaths` int(11) DEFAULT 0,
  `score` int(11) DEFAULT 0,
  `last_played` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `dm_ranks_geral` (
  `org` varchar(100) DEFAULT NULL,
  `points` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `dm_ranks_pistol` (
  `org` varchar(100) NOT NULL,
  `orgType` varchar(100) DEFAULT NULL,
  `boostFarmTS` varchar(100) DEFAULT '0',
  `points` int(11) DEFAULT 0,
  `wins` int(11) DEFAULT 0,
  PRIMARY KEY (`org`),
  UNIQUE KEY `org` (`org`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `drg_warrant` (
  `user_id` int(11) NOT NULL,
  `reason` longtext DEFAULT NULL,
  `timeCreated` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `early_access` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `added_by` varchar(50) DEFAULT NULL,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `flow_attachs` (
  `user_id` int(11) NOT NULL,
  `attachs` text DEFAULT NULL,
  PRIMARY KEY (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `fstore_appointments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `command` varchar(512) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `m_barbershop` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `coords` varchar(255) NOT NULL,
  `blip` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `m_chests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `weight` int(11) NOT NULL,
  `coords` varchar(255) NOT NULL,
  `permission` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `m_hub` (
  `user_id` int(11) NOT NULL,
  `service` varchar(150) NOT NULL DEFAULT '',
  `name` varchar(150) NOT NULL DEFAULT '',
  `calls` int(11) NOT NULL DEFAULT 0,
  `hours` float NOT NULL DEFAULT 0,
  `stars` float NOT NULL DEFAULT 0,
  `totalstars` float DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `m_pass_v2` (
  `user_id` int(11) DEFAULT NULL,
  `pass_type` varchar(255) DEFAULT NULL,
  `redeemed_levels` text DEFAULT NULL,
  UNIQUE KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `m_ponto` (
  `user_id` int(11) NOT NULL,
  `identity` varchar(100) NOT NULL,
  `service_time` int(11) NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `m_raffle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item` text NOT NULL,
  `initial_number` int(11) NOT NULL,
  `final_number` int(11) NOT NULL,
  `prices` text NOT NULL,
  `end_at` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `m_raffle_buyed` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `number` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `m_roberry_points` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `reward` int(11) DEFAULT 0,
  `cooldown` int(11) DEFAULT 300,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `m_shops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `coords` varchar(255) NOT NULL,
  `blip` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `m_skinshops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `coords` varchar(255) NOT NULL,
  `blip` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `m_tattooshops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `coords` varchar(255) NOT NULL,
  `blip` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `history` (
  `user_id` int(11) NOT NULL,
  `video_id` varchar(255) NOT NULL,
  `played_at` timestamp NOT NULL DEFAULT current_timestamp(),
  KEY `video_id` (`video_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `hooka_credits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `credits` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `hydrus_credits` (
  `player_id` varchar(100) NOT NULL,
  `name` varchar(100) NOT NULL,
  `amount` int(11) DEFAULT 0,
  `updated_at` int(11) DEFAULT unix_timestamp(),
  PRIMARY KEY (`player_id`,`name`),
  KEY `player_id` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `hydrus_scheduler` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `player_id` varchar(100) NOT NULL,
  `command` varchar(255) NOT NULL,
  `args` varchar(4096) NOT NULL,
  `execute_at` bigint(20) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `player_id` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `items_seized` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `org` tinytext NOT NULL,
  `amount` bigint(20) NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL DEFAULT curdate(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `likes` (
  `user_id` int(11) NOT NULL,
  `video_id` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`,`video_id`),
  KEY `likes_video_idx` (`video_id`),
  KEY `likes_user_idx` (`user_id`),
  CONSTRAINT `likes_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `likes_video_fk` FOREIGN KEY (`video_id`) REFERENCES `videos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mbox_hours` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `time` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `mdt_criminal_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `officer_id` int(11) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `date` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `mdt_incidents_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `involved` int(11) DEFAULT NULL,
  `officer_id` int(11) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `date` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `mdt_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `organization` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `date` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `mdt_organizations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `organization` varchar(255) DEFAULT NULL,
  `permissions` text DEFAULT '{}',
  `image` varchar(255) DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `organization` (`organization`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `mdt_staff_criminal_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `officer_id` int(11) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `date` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `mdt_users_rewards` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `organization` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `mdt_vehicle_apprehensions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `officer_id` int(11) DEFAULT NULL,
  `vehicle` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `date` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `mirtin_bans` (
  `user_id` int(11) NOT NULL,
  `motivo` text NOT NULL,
  `banimento` tinytext NOT NULL,
  `desbanimento` tinytext NOT NULL,
  `time` int(11) NOT NULL,
  `hwid` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `mirtin_bans_hwid` (
  `token` varchar(120) NOT NULL,
  `id` int(11) NOT NULL,
  PRIMARY KEY (`token`),
  KEY `user_id` (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `mirtin_bans_ip` (
  `user_id` int(11) DEFAULT NULL,
  `ip` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `mirtin_chamados` (
  `user_id` int(11) NOT NULL,
  `total` int(11) NOT NULL,
  `historico` text NOT NULL DEFAULT '{}',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `mirtin_homes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tipo` varchar(15) NOT NULL,
  `price` int(11) NOT NULL,
  `coords` varchar(50) NOT NULL,
  `garagem` text DEFAULT '{}',
  `chaves` int(11) DEFAULT NULL,
  `minBau` int(11) NOT NULL,
  `maxMoradores` int(11) DEFAULT 3,
  `permissao` varchar(50) NOT NULL,
  `interior` int(11) DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `mirtin_organization_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID único',
  `user_id` int(11) NOT NULL COMMENT 'ID do jogador',
  `group_type` varchar(50) NOT NULL COMMENT 'Tipo do grupo',
  `member_data` varchar(244) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '' COMMENT 'Dados do membro',
  `item` varchar(50) NOT NULL COMMENT 'Item relacionado',
  `amount` int(11) NOT NULL COMMENT 'Quantidade',
  `day` varchar(2) NOT NULL COMMENT 'Dia',
  `month` varchar(2) NOT NULL COMMENT 'Mês',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Data de criação',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_group_type` (`group_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Membros das organizações';

CREATE TABLE IF NOT EXISTS `mirtin_orgs_chat` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID único',
  `organization` varchar(100) NOT NULL COMMENT 'Nome da organização',
  `user_id` int(11) NOT NULL COMMENT 'ID do jogador',
  `message` text NOT NULL COMMENT 'Mensagem enviada',
  `author` varchar(100) NOT NULL COMMENT 'Nome do autor',
  `author_avatar` text DEFAULT NULL COMMENT 'Avatar do autor',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Data de criação',
  PRIMARY KEY (`id`),
  KEY `idx_organization` (`organization`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Chat das organizações';

CREATE TABLE IF NOT EXISTS `mirtin_orgs_claimrewards` (
  `user_id` int(11) NOT NULL COMMENT 'ID do jogador',
  `metatotal` int(11) DEFAULT 0 COMMENT 'Total de metas resgatadas',
  `farmtotal` int(11) DEFAULT 0 COMMENT 'Total de farm resgatado',
  `last_claim_date` timestamp NULL DEFAULT NULL COMMENT 'Data do último resgate',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Data de criação',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Data de atualização',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Controle de recompensas resgatadas';

CREATE TABLE IF NOT EXISTS `mirtin_orgs_facs_invite` (
  `organization` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `day` int(11) NOT NULL DEFAULT 0,
  `month` int(11) NOT NULL DEFAULT 0,
  `reward` int(11) DEFAULT 0,
  UNIQUE KEY `organization_day` (`organization`,`day`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `mirtin_orgs_goals` (
  `user_id` int(11) NOT NULL COMMENT 'ID do jogador',
  `organization` varchar(50) NOT NULL COMMENT 'Nome da organização',
  `item` varchar(100) NOT NULL COMMENT 'Item da meta',
  `amount` int(11) NOT NULL DEFAULT 0 COMMENT 'Quantidade coletada',
  `day` int(11) NOT NULL COMMENT 'Dia da meta',
  `month` int(11) NOT NULL COMMENT 'Mês da meta',
  `step` int(11) DEFAULT 1 COMMENT 'Etapa da meta',
  `reward_step` int(11) DEFAULT 0 COMMENT 'Recompensa da etapa',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Data de criação',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Data de atualização',
  UNIQUE KEY `user_id_organization_item_day` (`user_id`,`organization`,`item`,`day`),
  KEY `idx_organization` (`organization`),
  KEY `idx_day_month` (`day`,`month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Metas diárias dos jogadores';

CREATE TABLE IF NOT EXISTS `mirtin_orgs_goalss` (
  `user_id` int(11) NOT NULL COMMENT 'ID do jogador',
  `status` varchar(255) DEFAULT NULL COMMENT 'Status das metas',
  `last_reset` timestamp NULL DEFAULT NULL COMMENT 'Data do último reset',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Data de criação',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Data de atualização',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Status das metas dos jogadores';

CREATE TABLE IF NOT EXISTS `mirtin_orgs_info` (
  `organization` varchar(50) NOT NULL COMMENT 'Nome da organização',
  `alerts` text DEFAULT '{}' COMMENT 'Alertas da organização (JSON)',
  `logo` text DEFAULT NULL COMMENT 'URL do logo da organização',
  `discord` varchar(150) DEFAULT '' COMMENT 'Link do Discord da organização',
  `bank` bigint(20) DEFAULT 0,
  `bank_historic` text DEFAULT '{}' COMMENT 'Histórico de transações bancárias (JSON)',
  `permissions` text DEFAULT '{}' COMMENT 'Permissões dos cargos (JSON)',
  `config_goals` text DEFAULT '{}' COMMENT 'Configuração de metas (JSON)',
  `salary` int(11) DEFAULT 0 COMMENT 'Salário padrão da organização',
  `frequency` int(11) DEFAULT 0 COMMENT 'Frequência de pagamento de salário',
  `radio` int(11) DEFAULT 0 COMMENT 'Frequência de rádio da organização',
  `presets` text DEFAULT '{}' COMMENT 'Presets de roupas (JSON)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Data de criação',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Data de atualização',
  PRIMARY KEY (`organization`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Informações das organizações';

CREATE TABLE IF NOT EXISTS `mirtin_orgs_invite_rewards` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID único',
  `user_id` int(11) NOT NULL COMMENT 'ID do jogador que convidou',
  `organization` varchar(50) NOT NULL COMMENT 'Nome da organização',
  `invite_userid` int(11) NOT NULL COMMENT 'ID do jogador convidado',
  `reward_amount` int(11) DEFAULT 0 COMMENT 'Valor da recompensa',
  `claimed` tinyint(1) DEFAULT 0 COMMENT 'Se a recompensa foi resgatada',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Data de criação',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_invite` (`user_id`,`invite_userid`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_organization` (`organization`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Recompensas por convites';

CREATE TABLE IF NOT EXISTS `mirtin_orgs_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID único',
  `organization` varchar(50) DEFAULT NULL COMMENT 'Nome da organização',
  `user_id` int(11) DEFAULT NULL COMMENT 'ID do jogador',
  `role` varchar(50) DEFAULT NULL COMMENT 'Cargo do jogador',
  `name` varchar(50) DEFAULT NULL COMMENT 'Nome do jogador',
  `description` varchar(200) DEFAULT NULL COMMENT 'Descrição da ação',
  `action_type` varchar(50) DEFAULT NULL COMMENT 'Tipo da ação',
  `date` varchar(50) DEFAULT NULL COMMENT 'Data da ação',
  `expire_at` int(11) DEFAULT NULL COMMENT 'Data de expiração (timestamp)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Data de criação',
  PRIMARY KEY (`id`),
  KEY `idx_organization` (`organization`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_action_type` (`action_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Logs de atividades das organizações';

CREATE TABLE IF NOT EXISTS `mirtin_orgs_partners` (
  `organization` varchar(50) NOT NULL,
  `partner` varchar(50) NOT NULL,
  `cds` varchar(50) DEFAULT NULL,
  `note` int(11) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `icon` varchar(50) DEFAULT NULL,
  `Coluna 6` int(11) DEFAULT NULL,
  UNIQUE KEY `organization_partner` (`organization`,`partner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `mirtin_orgs_player_infos` (
  `user_id` int(11) NOT NULL COMMENT 'ID do jogador',
  `organization` varchar(50) DEFAULT NULL COMMENT 'Nome da organização',
  `joindate` int(11) DEFAULT 0 COMMENT 'Data de entrada (timestamp)',
  `lastlogin` int(11) DEFAULT 0 COMMENT 'Último login (timestamp)',
  `timeplayed` int(11) DEFAULT 0 COMMENT 'Tempo jogado em minutos',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Data de criação',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Data de atualização',
  PRIMARY KEY (`user_id`),
  KEY `idx_organization` (`organization`),
  KEY `idx_joindate` (`joindate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Informações dos jogadores nas organizações';

CREATE TABLE IF NOT EXISTS `mirtin_partner` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID único',
  `organization` varchar(255) NOT NULL COMMENT 'Nome da organização',
  `partner_name` varchar(255) DEFAULT NULL COMMENT 'Nome do parceiro',
  `joined_at` datetime DEFAULT current_timestamp() COMMENT 'Data de entrada',
  `status` varchar(50) DEFAULT 'active' COMMENT 'Status da parceria',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Data de criação',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_org` (`organization`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Relacionamento organização-parceiro';

CREATE TABLE IF NOT EXISTS `mirtin_partners` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID único',
  `cds` text DEFAULT NULL COMMENT 'Coordenadas',
  `name` varchar(100) DEFAULT NULL COMMENT 'Nome do parceiro',
  `note` int(11) DEFAULT 0 COMMENT 'Nota do parceiro',
  `description` text DEFAULT NULL COMMENT 'Descrição do parceiro',
  `keyword` text DEFAULT NULL COMMENT 'Palavra-chave',
  `icon` text DEFAULT NULL COMMENT 'Ícone do parceiro',
  `groups` text DEFAULT NULL COMMENT 'Grupos permitidos (JSON)',
  `active` tinyint(1) DEFAULT 1 COMMENT 'Se o parceiro está ativo',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Data de criação',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Data de atualização',
  PRIMARY KEY (`id`),
  KEY `idx_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Parceiros das organizações';

CREATE TABLE IF NOT EXISTS `mirtin_users_homes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tipo` varchar(50) NOT NULL,
  `houseID` int(11) NOT NULL,
  `proprietario` int(11) NOT NULL,
  `moradores` text DEFAULT '{}',
  `bau` text DEFAULT '{}',
  `armario` text DEFAULT '{}',
  `interior` int(11) NOT NULL,
  `iptu` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `m_bank` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned DEFAULT NULL,
  `para` int(11) DEFAULT NULL,
  `valor` bigint(20) DEFAULT NULL,
  `tipo` varchar(50) DEFAULT NULL,
  `store` varchar(50) DEFAULT NULL,
  `data` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `m_empregos` (
  `user_id` int(11) NOT NULL,
  `dvalue` text DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `nation_concessionaria` (
  `vehicle` text NOT NULL,
  `estoque` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`vehicle`(765))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `phone_backups` (
  `id` varchar(100) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_backups_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_clock_alarms` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `hours` int(2) NOT NULL DEFAULT 0,
  `minutes` int(2) NOT NULL DEFAULT 0,
  `label` varchar(50) DEFAULT NULL,
  `enabled` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`,`phone_number`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_clock_alarms_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_crypto` (
  `id` varchar(100) NOT NULL,
  `coin` varchar(15) NOT NULL,
  `amount` double NOT NULL DEFAULT 0,
  `invested` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`,`coin`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_darkchat_accounts` (
  `phone_number` varchar(15) NOT NULL,
  `username` varchar(20) NOT NULL,
  `password` varchar(100) NOT NULL,
  PRIMARY KEY (`username`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_darkchat_accounts_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_darkchat_channels` (
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_darkchat_members` (
  `channel_name` varchar(50) NOT NULL,
  `username` varchar(20) NOT NULL,
  PRIMARY KEY (`channel_name`,`username`),
  KEY `username` (`username`),
  CONSTRAINT `phone_darkchat_members_ibfk_1` FOREIGN KEY (`channel_name`) REFERENCES `phone_darkchat_channels` (`name`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_darkchat_members_ibfk_2` FOREIGN KEY (`username`) REFERENCES `phone_darkchat_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_darkchat_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel` varchar(50) NOT NULL,
  `sender` varchar(20) NOT NULL,
  `content` varchar(1000) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `channel` (`channel`),
  KEY `sender` (`sender`),
  CONSTRAINT `phone_darkchat_messages_ibfk_1` FOREIGN KEY (`channel`) REFERENCES `phone_darkchat_channels` (`name`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_darkchat_messages_ibfk_2` FOREIGN KEY (`sender`) REFERENCES `phone_darkchat_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_accounts` (
  `display_name` varchar(30) NOT NULL,
  `username` varchar(20) NOT NULL,
  `password` varchar(100) NOT NULL,
  `profile_image` varchar(500) DEFAULT NULL,
  `bio` varchar(100) DEFAULT NULL,
  `post_count` int(11) NOT NULL DEFAULT 0,
  `story_count` int(11) NOT NULL DEFAULT 0,
  `follower_count` int(11) NOT NULL DEFAULT 0,
  `following_count` int(11) NOT NULL DEFAULT 0,
  `phone_number` varchar(15) NOT NULL,
  `private` tinyint(1) DEFAULT 0,
  `verified` tinyint(1) DEFAULT 0,
  `date_joined` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`username`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_instagram_accounts_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_comments` (
  `id` varchar(10) NOT NULL,
  `post_id` varchar(50) NOT NULL,
  `username` varchar(20) NOT NULL,
  `comment` varchar(500) NOT NULL DEFAULT '',
  `like_count` int(11) NOT NULL DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `post_id` (`post_id`),
  KEY `username` (`username`),
  CONSTRAINT `phone_instagram_comments_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `phone_instagram_posts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `phone_instagram_comments_ibfk_2` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_follows` (
  `followed` varchar(20) NOT NULL,
  `follower` varchar(20) NOT NULL,
  PRIMARY KEY (`followed`,`follower`),
  KEY `follower` (`follower`),
  CONSTRAINT `phone_instagram_follows_ibfk_1` FOREIGN KEY (`followed`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_instagram_follows_ibfk_2` FOREIGN KEY (`follower`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_follow_requests` (
  `requester` varchar(20) NOT NULL,
  `requestee` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`requester`,`requestee`),
  KEY `requestee` (`requestee`),
  CONSTRAINT `phone_instagram_follow_requests_ibfk_1` FOREIGN KEY (`requester`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_instagram_follow_requests_ibfk_2` FOREIGN KEY (`requestee`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_likes` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `is_comment` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`,`username`),
  KEY `username` (`username`),
  CONSTRAINT `phone_instagram_likes_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_messages` (
  `id` varchar(10) NOT NULL,
  `sender` varchar(20) NOT NULL,
  `recipient` varchar(20) NOT NULL,
  `content` varchar(1000) DEFAULT NULL,
  `attachments` text DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `sender` (`sender`),
  KEY `recipient` (`recipient`),
  CONSTRAINT `phone_instagram_messages_ibfk_1` FOREIGN KEY (`sender`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_instagram_messages_ibfk_2` FOREIGN KEY (`recipient`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_notifications` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `from` varchar(20) NOT NULL,
  `type` varchar(20) NOT NULL,
  `post_id` varchar(50) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `username` (`username`),
  KEY `from` (`from`),
  CONSTRAINT `phone_instagram_notifications_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_instagram_notifications_ibfk_2` FOREIGN KEY (`from`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_posts` (
  `id` varchar(10) NOT NULL,
  `media` text DEFAULT NULL,
  `caption` varchar(500) NOT NULL DEFAULT '',
  `location` varchar(50) DEFAULT NULL,
  `like_count` int(11) NOT NULL DEFAULT 0,
  `comment_count` int(11) NOT NULL DEFAULT 0,
  `username` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `username` (`username`),
  CONSTRAINT `phone_instagram_posts_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_stories` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `image` varchar(500) NOT NULL,
  `metadata` longtext DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `username` (`username`),
  CONSTRAINT `phone_instagram_stories_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_stories_views` (
  `story_id` varchar(50) NOT NULL,
  `viewer` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`story_id`,`viewer`),
  KEY `viewer` (`viewer`),
  CONSTRAINT `phone_instagram_stories_views_ibfk_1` FOREIGN KEY (`story_id`) REFERENCES `phone_instagram_stories` (`id`) ON DELETE CASCADE,
  CONSTRAINT `phone_instagram_stories_views_ibfk_2` FOREIGN KEY (`viewer`) REFERENCES `phone_instagram_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_last_phone` (
  `id` varchar(100) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_last_phone_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_logged_in_accounts` (
  `phone_number` varchar(15) NOT NULL,
  `app` varchar(50) NOT NULL,
  `username` varchar(100) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`phone_number`,`app`,`username`),
  CONSTRAINT `phone_logged_in_accounts_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_mail_accounts` (
  `address` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL,
  PRIMARY KEY (`address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_mail_deleted` (
  `message_id` int(10) unsigned NOT NULL,
  `address` varchar(100) NOT NULL,
  PRIMARY KEY (`message_id`,`address`),
  KEY `address` (`address`),
  CONSTRAINT `phone_mail_deleted_ibfk_1` FOREIGN KEY (`message_id`) REFERENCES `phone_mail_messages` (`id`) ON DELETE CASCADE,
  CONSTRAINT `phone_mail_deleted_ibfk_2` FOREIGN KEY (`address`) REFERENCES `phone_mail_accounts` (`address`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_mail_messages` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `recipient` varchar(100) NOT NULL,
  `sender` varchar(100) NOT NULL,
  `subject` varchar(100) NOT NULL,
  `content` text NOT NULL,
  `attachments` longtext DEFAULT NULL,
  `actions` longtext DEFAULT NULL,
  `read` tinyint(1) NOT NULL DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_recipient` (`recipient`),
  KEY `idx_sender` (`sender`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_maps_locations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `name` varchar(50) NOT NULL,
  `x_pos` float NOT NULL,
  `y_pos` float NOT NULL,
  PRIMARY KEY (`id`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_maps_locations_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_marketplace_posts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `title` varchar(50) NOT NULL,
  `description` varchar(1000) NOT NULL,
  `attachments` text DEFAULT NULL,
  `price` int(11) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_marketplace_posts_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_message_channels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `is_group` tinyint(1) NOT NULL DEFAULT 0,
  `name` varchar(50) DEFAULT NULL,
  `last_message` varchar(50) NOT NULL DEFAULT '',
  `last_message_timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_message_members` (
  `channel_id` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `is_owner` tinyint(1) NOT NULL DEFAULT 0,
  `deleted` tinyint(1) NOT NULL DEFAULT 0,
  `unread` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`channel_id`,`phone_number`),
  KEY `idx_members_phone_number` (`phone_number`),
  CONSTRAINT `phone_message_members_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `phone_message_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_message_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel_id` int(11) NOT NULL,
  `sender` varchar(15) NOT NULL,
  `content` varchar(1000) DEFAULT NULL,
  `attachments` text DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `channel_id` (`channel_id`),
  CONSTRAINT `phone_message_messages_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `phone_message_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_music_playlists` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `name` varchar(50) NOT NULL,
  `cover` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_music_playlists_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_music_saved_playlists` (
  `playlist_id` int(10) unsigned NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  PRIMARY KEY (`playlist_id`,`phone_number`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_music_saved_playlists_ibfk_1` FOREIGN KEY (`playlist_id`) REFERENCES `phone_music_playlists` (`id`) ON DELETE CASCADE,
  CONSTRAINT `phone_music_saved_playlists_ibfk_2` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_music_songs` (
  `song_id` varchar(100) NOT NULL,
  `playlist_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`song_id`,`playlist_id`),
  KEY `playlist_id` (`playlist_id`),
  CONSTRAINT `phone_music_songs_ibfk_1` FOREIGN KEY (`playlist_id`) REFERENCES `phone_music_playlists` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_notes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `title` varchar(50) NOT NULL,
  `content` longtext DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_notes_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `app` varchar(50) NOT NULL,
  `title` varchar(50) DEFAULT NULL,
  `content` varchar(500) DEFAULT NULL,
  `thumbnail` varchar(500) DEFAULT NULL,
  `avatar` varchar(500) DEFAULT NULL,
  `show_avatar` tinyint(1) DEFAULT 0,
  `custom_data` text DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_notifications_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_phones` (
  `id` varchar(100) NOT NULL,
  `owner_id` varchar(100) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `name` varchar(50) DEFAULT NULL,
  `pin` varchar(4) DEFAULT NULL,
  `face_id` varchar(100) DEFAULT NULL,
  `settings` longtext DEFAULT NULL,
  `is_setup` tinyint(1) DEFAULT 0,
  `assigned` tinyint(1) DEFAULT 0,
  `battery` int(11) NOT NULL DEFAULT 100,
  `last_seen` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone_number` (`phone_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_phone_blocked_numbers` (
  `phone_number` varchar(15) NOT NULL,
  `blocked_number` varchar(15) NOT NULL,
  PRIMARY KEY (`phone_number`,`blocked_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_phone_calls` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `caller` varchar(15) NOT NULL,
  `callee` varchar(15) NOT NULL,
  `duration` int(11) NOT NULL DEFAULT 0,
  `answered` tinyint(1) DEFAULT 0,
  `hide_caller_id` tinyint(1) DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_calls_missed` (`callee`,`answered`),
  KEY `idx_calls_callee_id` (`callee`),
  KEY `idx_calls_caller_id` (`caller`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_phone_contacts` (
  `contact_phone_number` varchar(15) NOT NULL,
  `firstname` varchar(50) NOT NULL DEFAULT '',
  `lastname` varchar(50) NOT NULL DEFAULT '',
  `profile_image` varchar(500) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `address` varchar(50) DEFAULT NULL,
  `favourite` tinyint(1) DEFAULT 0,
  `phone_number` varchar(15) NOT NULL,
  PRIMARY KEY (`contact_phone_number`,`phone_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_phone_voicemail` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `caller` varchar(15) NOT NULL,
  `callee` varchar(15) NOT NULL,
  `url` varchar(500) NOT NULL,
  `duration` int(11) NOT NULL,
  `hide_caller_id` tinyint(1) DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_photos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `link` varchar(500) NOT NULL,
  `is_video` tinyint(1) DEFAULT 0,
  `size` float NOT NULL DEFAULT 0,
  `metadata` varchar(20) DEFAULT NULL,
  `is_favourite` tinyint(1) DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_photos_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_photo_albums` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `title` varchar(100) NOT NULL,
  `shared` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_photo_albums_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_photo_album_members` (
  `album_id` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  PRIMARY KEY (`album_id`,`phone_number`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_photo_album_members_ibfk_1` FOREIGN KEY (`album_id`) REFERENCES `phone_photo_albums` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_photo_album_members_ibfk_2` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_photo_album_photos` (
  `album_id` int(11) NOT NULL,
  `photo_id` int(11) NOT NULL,
  PRIMARY KEY (`album_id`,`photo_id`),
  KEY `photo_id` (`photo_id`),
  CONSTRAINT `phone_photo_album_photos_ibfk_1` FOREIGN KEY (`album_id`) REFERENCES `phone_photo_albums` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_photo_album_photos_ibfk_2` FOREIGN KEY (`photo_id`) REFERENCES `phone_photos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_services_channels` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `company` varchar(50) NOT NULL,
  `last_message` varchar(100) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_services_messages` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `channel_id` int(10) unsigned NOT NULL,
  `sender` varchar(15) NOT NULL,
  `message` varchar(1000) NOT NULL,
  `x_pos` int(11) DEFAULT NULL,
  `y_pos` int(11) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `channel_id` (`channel_id`),
  CONSTRAINT `phone_services_messages_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `phone_services_channels` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_accounts` (
  `name` varchar(30) NOT NULL,
  `bio` varchar(100) DEFAULT NULL,
  `avatar` varchar(500) DEFAULT NULL,
  `username` varchar(20) NOT NULL,
  `password` varchar(100) NOT NULL,
  `verified` tinyint(1) DEFAULT 0,
  `follower_count` int(11) NOT NULL DEFAULT 0,
  `following_count` int(11) NOT NULL DEFAULT 0,
  `like_count` int(11) NOT NULL DEFAULT 0,
  `video_count` int(11) NOT NULL DEFAULT 0,
  `twitter` varchar(20) DEFAULT NULL,
  `instagram` varchar(20) DEFAULT NULL,
  `show_likes` tinyint(1) DEFAULT 1,
  `phone_number` varchar(15) NOT NULL,
  `date_joined` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`username`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_tiktok_accounts_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_channels` (
  `id` varchar(10) NOT NULL,
  `last_message` varchar(50) NOT NULL,
  `member_1` varchar(20) NOT NULL,
  `member_2` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `member_1` (`member_1`,`member_2`),
  KEY `member_2` (`member_2`),
  CONSTRAINT `phone_tiktok_channels_ibfk_1` FOREIGN KEY (`member_1`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_channels_ibfk_2` FOREIGN KEY (`member_2`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_comments` (
  `id` varchar(10) NOT NULL,
  `reply_to` varchar(10) DEFAULT NULL,
  `video_id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `comment` varchar(550) NOT NULL,
  `likes` int(11) NOT NULL DEFAULT 0,
  `replies` int(11) NOT NULL DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `video_id` (`video_id`),
  KEY `username` (`username`),
  KEY `reply_to` (`reply_to`),
  CONSTRAINT `phone_tiktok_comments_ibfk_1` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_comments_ibfk_2` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_comments_ibfk_3` FOREIGN KEY (`reply_to`) REFERENCES `phone_tiktok_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_comments_likes` (
  `username` varchar(20) NOT NULL,
  `comment_id` varchar(10) NOT NULL,
  PRIMARY KEY (`username`,`comment_id`),
  KEY `comment_id` (`comment_id`),
  CONSTRAINT `phone_tiktok_comments_likes_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_comments_likes_ibfk_2` FOREIGN KEY (`comment_id`) REFERENCES `phone_tiktok_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_follows` (
  `followed` varchar(20) NOT NULL,
  `follower` varchar(20) NOT NULL,
  PRIMARY KEY (`followed`,`follower`),
  KEY `follower` (`follower`),
  CONSTRAINT `phone_tiktok_follows_ibfk_1` FOREIGN KEY (`followed`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_follows_ibfk_2` FOREIGN KEY (`follower`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_likes` (
  `username` varchar(20) NOT NULL,
  `video_id` varchar(10) NOT NULL,
  PRIMARY KEY (`username`,`video_id`),
  KEY `video_id` (`video_id`),
  CONSTRAINT `phone_tiktok_likes_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_likes_ibfk_2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_messages` (
  `id` varchar(10) NOT NULL,
  `channel_id` varchar(10) NOT NULL,
  `sender` varchar(20) NOT NULL,
  `content` varchar(500) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `channel_id` (`channel_id`),
  KEY `sender` (`sender`),
  CONSTRAINT `phone_tiktok_messages_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `phone_tiktok_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_messages_ibfk_2` FOREIGN KEY (`sender`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(20) NOT NULL,
  `from` varchar(20) NOT NULL,
  `type` varchar(20) NOT NULL,
  `video_id` varchar(10) DEFAULT NULL,
  `comment_id` varchar(10) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `username` (`username`),
  KEY `from` (`from`),
  KEY `video_id` (`video_id`),
  KEY `comment_id` (`comment_id`),
  CONSTRAINT `phone_tiktok_notifications_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_notifications_ibfk_2` FOREIGN KEY (`from`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_notifications_ibfk_3` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_notifications_ibfk_4` FOREIGN KEY (`comment_id`) REFERENCES `phone_tiktok_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_pinned_videos` (
  `username` varchar(20) NOT NULL,
  `video_id` varchar(10) NOT NULL,
  PRIMARY KEY (`username`,`video_id`),
  KEY `video_id` (`video_id`),
  CONSTRAINT `phone_tiktok_pinned_videos_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_pinned_videos_ibfk_2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_saves` (
  `username` varchar(20) NOT NULL,
  `video_id` varchar(10) NOT NULL,
  PRIMARY KEY (`username`,`video_id`),
  KEY `video_id` (`video_id`),
  CONSTRAINT `phone_tiktok_saves_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_saves_ibfk_2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_unread_messages` (
  `username` varchar(20) NOT NULL,
  `channel_id` varchar(10) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`username`,`channel_id`),
  KEY `channel_id` (`channel_id`),
  CONSTRAINT `phone_tiktok_unread_messages_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_unread_messages_ibfk_2` FOREIGN KEY (`channel_id`) REFERENCES `phone_tiktok_channels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_videos` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `src` varchar(500) NOT NULL,
  `caption` varchar(100) DEFAULT NULL,
  `metadata` longtext DEFAULT NULL,
  `music` text DEFAULT NULL,
  `likes` int(11) NOT NULL DEFAULT 0,
  `comments` int(11) NOT NULL DEFAULT 0,
  `views` int(11) NOT NULL DEFAULT 0,
  `saves` int(11) NOT NULL DEFAULT 0,
  `pinned_comment` varchar(10) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `username` (`username`),
  CONSTRAINT `phone_tiktok_videos_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_views` (
  `username` varchar(20) NOT NULL,
  `video_id` varchar(10) NOT NULL,
  PRIMARY KEY (`username`,`video_id`),
  KEY `video_id` (`video_id`),
  CONSTRAINT `phone_tiktok_views_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tiktok_views_ibfk_2` FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tinder_accounts` (
  `name` varchar(50) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `photos` text DEFAULT NULL,
  `bio` varchar(500) DEFAULT NULL,
  `dob` date NOT NULL,
  `is_male` tinyint(1) NOT NULL,
  `interested_men` tinyint(1) NOT NULL,
  `interested_women` tinyint(1) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `last_seen` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`phone_number`),
  CONSTRAINT `phone_tinder_accounts_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tinder_matches` (
  `phone_number_1` varchar(15) NOT NULL,
  `phone_number_2` varchar(15) NOT NULL,
  `latest_message` varchar(1000) DEFAULT NULL,
  `latest_message_timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`phone_number_1`,`phone_number_2`),
  KEY `phone_number_2` (`phone_number_2`),
  CONSTRAINT `phone_tinder_matches_ibfk_1` FOREIGN KEY (`phone_number_1`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tinder_matches_ibfk_2` FOREIGN KEY (`phone_number_2`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tinder_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sender` varchar(15) NOT NULL,
  `recipient` varchar(15) NOT NULL,
  `content` varchar(1000) DEFAULT NULL,
  `attachments` text DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `sender` (`sender`),
  KEY `recipient` (`recipient`),
  CONSTRAINT `phone_tinder_messages_ibfk_1` FOREIGN KEY (`sender`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tinder_messages_ibfk_2` FOREIGN KEY (`recipient`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tinder_swipes` (
  `swiper` varchar(15) NOT NULL,
  `swipee` varchar(15) NOT NULL,
  `liked` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`swiper`,`swipee`),
  KEY `swipee` (`swipee`),
  CONSTRAINT `phone_tinder_swipes_ibfk_1` FOREIGN KEY (`swiper`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_tinder_swipes_ibfk_2` FOREIGN KEY (`swipee`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_accounts` (
  `display_name` varchar(30) NOT NULL,
  `username` varchar(20) NOT NULL,
  `password` varchar(100) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `bio` varchar(100) DEFAULT NULL,
  `profile_image` varchar(500) DEFAULT NULL,
  `profile_header` varchar(500) DEFAULT NULL,
  `pinned_tweet` varchar(50) DEFAULT NULL,
  `verified` tinyint(1) DEFAULT 0,
  `follower_count` int(11) NOT NULL DEFAULT 0,
  `following_count` int(11) NOT NULL DEFAULT 0,
  `private` tinyint(1) DEFAULT 0,
  `date_joined` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`username`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_twitter_accounts_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_follows` (
  `followed` varchar(20) NOT NULL,
  `follower` varchar(20) NOT NULL,
  `notifications` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`followed`,`follower`),
  KEY `follower` (`follower`),
  CONSTRAINT `phone_twitter_follows_ibfk_1` FOREIGN KEY (`followed`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_twitter_follows_ibfk_2` FOREIGN KEY (`follower`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_follow_requests` (
  `requester` varchar(20) NOT NULL,
  `requestee` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`requester`,`requestee`),
  KEY `requestee` (`requestee`),
  CONSTRAINT `phone_twitter_follow_requests_ibfk_1` FOREIGN KEY (`requester`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_twitter_follow_requests_ibfk_2` FOREIGN KEY (`requestee`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_hashtags` (
  `hashtag` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `last_used` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`hashtag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_likes` (
  `tweet_id` varchar(50) NOT NULL,
  `username` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`tweet_id`,`username`),
  KEY `username` (`username`),
  CONSTRAINT `phone_twitter_likes_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_messages` (
  `id` varchar(10) NOT NULL,
  `sender` varchar(20) NOT NULL,
  `recipient` varchar(20) NOT NULL,
  `content` varchar(1000) DEFAULT NULL,
  `attachments` text DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `sender` (`sender`),
  KEY `recipient` (`recipient`),
  CONSTRAINT `phone_twitter_messages_ibfk_1` FOREIGN KEY (`sender`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_twitter_messages_ibfk_2` FOREIGN KEY (`recipient`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_notifications` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `from` varchar(20) NOT NULL,
  `type` varchar(20) NOT NULL,
  `tweet_id` varchar(50) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `username` (`username`),
  KEY `from` (`from`),
  CONSTRAINT `phone_twitter_notifications_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `phone_twitter_notifications_ibfk_2` FOREIGN KEY (`from`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_promoted` (
  `tweet_id` varchar(50) NOT NULL,
  `promotions` int(11) NOT NULL DEFAULT 0,
  `views` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`tweet_id`),
  CONSTRAINT `phone_twitter_promoted_ibfk_1` FOREIGN KEY (`tweet_id`) REFERENCES `phone_twitter_tweets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_retweets` (
  `tweet_id` varchar(50) NOT NULL,
  `username` varchar(20) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`tweet_id`,`username`),
  KEY `username` (`username`),
  CONSTRAINT `phone_twitter_retweets_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_tweets` (
  `id` varchar(10) NOT NULL,
  `username` varchar(20) NOT NULL,
  `content` varchar(280) DEFAULT NULL,
  `attachments` text DEFAULT NULL,
  `reply_to` varchar(50) DEFAULT NULL,
  `like_count` int(11) DEFAULT 0,
  `reply_count` int(11) DEFAULT 0,
  `retweet_count` int(11) DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `username` (`username`),
  CONSTRAINT `phone_twitter_tweets_ibfk_1` FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_voice_memos_recordings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `file_name` varchar(50) NOT NULL,
  `file_url` varchar(500) NOT NULL,
  `file_length` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_voice_memos_recordings_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_wallet_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `amount` int(11) NOT NULL,
  `company` varchar(50) NOT NULL,
  `logo` varchar(200) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `phone_number` (`phone_number`),
  CONSTRAINT `phone_wallet_transactions_ibfk_1` FOREIGN KEY (`phone_number`) REFERENCES `phone_phones` (`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_yellow_pages_posts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(15) NOT NULL,
  `title` varchar(50) NOT NULL,
  `description` varchar(1000) NOT NULL,
  `attachment` varchar(500) DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `player_playtime` (
  `user_id` int(11) DEFAULT NULL,
  `playtime` int(11) NOT NULL DEFAULT 0,
  UNIQUE KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `playlists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id_index` (`user_id`),
  CONSTRAINT `playlists_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `playlist_videos` (
  `playlist_id` int(11) NOT NULL,
  `video_id` varchar(255) NOT NULL,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`playlist_id`,`video_id`),
  KEY `pv_video_idx` (`video_id`),
  KEY `pv_playlist_idx` (`playlist_id`),
  CONSTRAINT `pv_playlist_fk` FOREIGN KEY (`playlist_id`) REFERENCES `playlists` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pv_video_fk` FOREIGN KEY (`video_id`) REFERENCES `videos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ponto_presets` (
  `org` varchar(100) NOT NULL,
  `group` varchar(100) NOT NULL,
  `preset` text NOT NULL,
  PRIMARY KEY (`org`,`group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartbank_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `amount` double DEFAULT NULL,
  UNIQUE KEY `id` (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

CREATE TABLE IF NOT EXISTS `smartbank_cards` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) DEFAULT NULL,
  `holder` varchar(50) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `number` varchar(50) DEFAULT NULL,
  `pin` varchar(50) DEFAULT NULL,
  `hold` int(11) DEFAULT 0,
  `data` text DEFAULT NULL,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartbank_statements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pix` varchar(50) NOT NULL DEFAULT '0',
  `from` varchar(50) NOT NULL DEFAULT '0',
  `source` varchar(50) NOT NULL DEFAULT '0',
  `type` varchar(50) NOT NULL DEFAULT '0',
  `amount` double NOT NULL DEFAULT 0,
  `reason` varchar(50) NOT NULL DEFAULT '0',
  `time` int(255) DEFAULT NULL,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_bank_invoices` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `payee_id` int(11) NOT NULL,
  `payer_id` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL DEFAULT '',
  `value` int(11) NOT NULL,
  `paid` tinyint(4) NOT NULL DEFAULT 0,
  `created_at` int(11) NOT NULL,
  `updated_at` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_blocks` (
  `user_id` int(11) NOT NULL,
  `phone` varchar(255) NOT NULL,
  PRIMARY KEY (`user_id`,`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_calls` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `initiator` varchar(255) NOT NULL,
  `target` varchar(255) NOT NULL,
  `duration` int(11) NOT NULL DEFAULT 0,
  `status` varchar(255) NOT NULL,
  `video` tinyint(4) NOT NULL DEFAULT 0,
  `anonymous` tinyint(4) NOT NULL DEFAULT 0,
  `created_at` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `initiator_index` (`initiator`),
  KEY `target_index` (`target`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_casino` (
  `user_id` int(11) NOT NULL,
  `balance` bigint(20) NOT NULL DEFAULT 0,
  `double` bigint(20) NOT NULL DEFAULT 0,
  `crash` bigint(20) NOT NULL DEFAULT 0,
  `mine` bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_contacts` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `owner` varchar(255) NOT NULL,
  `phone` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `owner_index` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_gallery` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `folder` varchar(255) NOT NULL DEFAULT '/',
  `url` varchar(255) NOT NULL,
  `created_at` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id_index` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_ifood_orders` (
  `id` varchar(10) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `worker_id` int(11) DEFAULT NULL,
  `store_id` int(11) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `fee` int(11) DEFAULT NULL,
  `rate` tinyint(4) DEFAULT 0,
  `created_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_instagram` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `username` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `bio` varchar(255) NOT NULL,
  `avatarURL` varchar(255) DEFAULT NULL,
  `verified` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `user_id_index` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_instagram_followers` (
  `follower_id` bigint(20) NOT NULL,
  `profile_id` bigint(20) NOT NULL,
  PRIMARY KEY (`follower_id`,`profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_instagram_likes` (
  `post_id` bigint(20) NOT NULL,
  `profile_id` bigint(20) NOT NULL,
  PRIMARY KEY (`post_id`,`profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_instagram_notifications` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) NOT NULL,
  `author_id` int(11) NOT NULL,
  `content` varchar(512) NOT NULL,
  `saw` tinyint(4) NOT NULL DEFAULT 0,
  `created_at` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `profile_id_index` (`profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_instagram_posts` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `profile_id` bigint(20) NOT NULL,
  `post_id` bigint(20) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `content` varchar(255) DEFAULT NULL,
  `created_at` bigint(20) NOT NULL,
  `comments` int(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `profile_id_index` (`profile_id`),
  KEY `post_id_index` (`post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_olx` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `category` varchar(255) NOT NULL,
  `price` int(11) NOT NULL,
  `description` varchar(1024) NOT NULL,
  `images` varchar(1024) NOT NULL,
  `created_at` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id_index` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_paypal_transactions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `target` bigint(20) NOT NULL,
  `type` varchar(255) NOT NULL DEFAULT 'payment',
  `description` varchar(255) DEFAULT NULL,
  `value` bigint(20) NOT NULL,
  `created_at` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id_index` (`user_id`),
  KEY `target_index` (`target`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_tinder` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `image` varchar(255) NOT NULL,
  `bio` varchar(1024) NOT NULL,
  `age` tinyint(4) NOT NULL,
  `gender` varchar(255) NOT NULL,
  `show_gender` tinyint(4) NOT NULL,
  `tags` varchar(255) NOT NULL,
  `show_tags` tinyint(4) NOT NULL,
  `target` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_tinder_messages` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `sender` int(11) NOT NULL,
  `target` int(11) NOT NULL,
  `content` varchar(255) NOT NULL,
  `liked` tinyint(4) NOT NULL DEFAULT 0,
  `created_at` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sender_index` (`sender`),
  KEY `target_index` (`target`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_tinder_rating` (
  `profile_id` int(11) NOT NULL,
  `rated_id` int(11) NOT NULL,
  `rating` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`profile_id`,`rated_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_tor_messages` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `channel` varchar(24) NOT NULL DEFAULT 'geral',
  `sender` varchar(255) NOT NULL,
  `image` varchar(512) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `content` varchar(500) DEFAULT NULL,
  `created_at` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `channel_index` (`channel`),
  KEY `sender_index` (`sender`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_tor_payments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `sender` bigint(20) NOT NULL,
  `target` bigint(20) NOT NULL,
  `amount` int(11) NOT NULL,
  `created_at` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sender_index` (`sender`),
  KEY `target_index` (`target`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_twitter_followers` (
  `follower_id` bigint(20) NOT NULL,
  `profile_id` bigint(20) NOT NULL,
  KEY `profile_id_index` (`profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_twitter_likes` (
  `tweet_id` bigint(20) NOT NULL,
  `profile_id` bigint(20) NOT NULL,
  KEY `tweet_id_index` (`tweet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_twitter_profiles` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `username` varchar(255) NOT NULL,
  `avatarURL` varchar(255) NOT NULL,
  `bannerURL` varchar(255) NOT NULL,
  `bio` varchar(255) DEFAULT NULL,
  `verified` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `user_id_index` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_twitter_tweets` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) NOT NULL,
  `tweet_id` bigint(20) DEFAULT NULL,
  `content` varchar(280) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `profile_id_index` (`profile_id`),
  KEY `tweet_id_index` (`tweet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_uber_trips` (
  `id` varchar(10) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `driver_id` int(11) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `from` varchar(255) DEFAULT NULL,
  `to` varchar(255) DEFAULT NULL,
  `user_rate` tinyint(4) DEFAULT 0,
  `driver_rate` tinyint(4) DEFAULT 0,
  `created_at` int(11) DEFAULT NULL,
  `finished_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_weazel` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `author` varchar(255) NOT NULL,
  `tag` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` varchar(4096) NOT NULL,
  `imageURL` varchar(255) DEFAULT NULL,
  `videoURL` varchar(255) DEFAULT NULL,
  `views` int(11) NOT NULL DEFAULT 0,
  `created_at` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_whatsapp` (
  `owner` varchar(255) NOT NULL,
  `avatarURL` varchar(255) DEFAULT NULL,
  `read_receipts` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_whatsapp_channels` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `sender` varchar(50) NOT NULL,
  `target` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sender_index` (`sender`),
  KEY `target_index` (`target`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_whatsapp_groups` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `avatarURL` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `members` varchar(2048) NOT NULL,
  `created_at` bigint(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `smartphone_whatsapp_messages` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `channel_id` bigint(20) unsigned NOT NULL,
  `sender` varchar(255) NOT NULL,
  `image` varchar(512) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `content` varchar(500) DEFAULT NULL,
  `deleted_by` varchar(255) DEFAULT NULL,
  `readed` tinyint(4) NOT NULL DEFAULT 0,
  `saw_at` bigint(20) NOT NULL DEFAULT 0,
  `created_at` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sender_index` (`sender`),
  KEY `channel_id_index` (`channel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `stancetuning` (
  `stance` varchar(100) NOT NULL,
  `tuning` text DEFAULT NULL,
  `car` varchar(100) NOT NULL DEFAULT 'stance',
  `name` varchar(100) NOT NULL DEFAULT 'stance',
  `type` varchar(10) NOT NULL DEFAULT 'stance',
  PRIMARY KEY (`stance`),
  KEY `stance` (`stance`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `trafico` (
  `user_id` text NOT NULL,
  PRIMARY KEY (`user_id`(765))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_clothes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `custom` longtext NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `velocity_chests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `weight` int(11) NOT NULL,
  `coords` varchar(255) NOT NULL,
  `permission` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `velocity_pass_v2` (
  `user_id` int(11) DEFAULT NULL,
  `pass_type` varchar(255) DEFAULT NULL,
  `redeemed_levels` text DEFAULT NULL,
  UNIQUE KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `velocity_ponto` (
  `user_id` int(11) NOT NULL,
  `identity` varchar(100) NOT NULL,
  `service_time` int(11) NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `velocity_raffle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item` text NOT NULL,
  `initial_number` int(11) NOT NULL,
  `final_number` int(11) NOT NULL,
  `prices` text NOT NULL,
  `end_at` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `velocity_raffle_buyed` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `number` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `velocity_shops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `coords` varchar(255) NOT NULL,
  `blip` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `velocity_skinshops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `coords` varchar(255) NOT NULL,
  `blip` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `velocity_tattooshops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `coords` varchar(255) NOT NULL,
  `blip` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `veloctiy_barbershop` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `coords` varchar(255) NOT NULL,
  `blip` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `videos` (
  `id` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `thumbnail` varchar(500) DEFAULT NULL,
  `duration` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vrp_banco` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL DEFAULT 0,
  `extrato` varchar(255) NOT NULL,
  `data` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `vrp_colect` (
  `user_id` int(11) DEFAULT NULL,
  `tempoOn` int(11) DEFAULT 0,
  `tempoTotalOn` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `vrp_srv_data` (
  `dkey` varchar(100) NOT NULL,
  `dvalue` text DEFAULT NULL,
  PRIMARY KEY (`dkey`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `vrp_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ultimo_login` varchar(255) DEFAULT NULL,
  `ip` varchar(255) DEFAULT NULL,
  `whitelist` tinyint(1) DEFAULT NULL,
  `paypal` int(11) DEFAULT 0,
  `Motivo_BAN` varchar(255) DEFAULT NULL,
  `Motivo_UNBAN` varchar(255) DEFAULT NULL,
  `discord` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `vrp_users_infos` (
  `user_id` int(11) NOT NULL,
  `controller` int(11) DEFAULT 0,
  `rosto` text DEFAULT '{}',
  `roupas` text DEFAULT '{}',
  `tattos` text DEFAULT '{}',
  `garagem` int(11) DEFAULT 3,
  `vip` text DEFAULT '{}',
  `bonus` text DEFAULT '{}',
  `coins` int(11) DEFAULT 3,
  `tempo_jogado` int(11) DEFAULT 0,
  `prioridade` int(11) DEFAULT 0,
  `license` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `vrp_user_data` (
  `user_id` int(11) NOT NULL,
  `dkey` varchar(100) NOT NULL,
  `dvalue` text DEFAULT NULL,
  PRIMARY KEY (`user_id`,`dkey`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `vrp_user_identities` (
  `user_id` int(11) NOT NULL,
  `registro` varchar(50) DEFAULT NULL,
  `telefone` varchar(20) DEFAULT NULL,
  `nome` varchar(50) DEFAULT NULL,
  `sobrenome` varchar(50) DEFAULT NULL,
  `idade` int(11) DEFAULT NULL,
  `banco` int(11) DEFAULT 25000,
  `multas` int(11) DEFAULT 0,
  `criminal` text DEFAULT '{}',
  `signo` varchar(50) DEFAULT 'Nenhum',
  `data_nascimento` varchar(50) DEFAULT '17/03/2001',
  `relacionamento` varchar(255) DEFAULT '{}',
  `total_hour` int(11) DEFAULT 0,
  `chavePix` varchar(255) DEFAULT NULL,
  `makapoints` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  KEY `registro` (`registro`),
  KEY `telefone` (`telefone`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `vrp_user_ids` (
  `identifier` varchar(150) NOT NULL,
  `user_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `vrp_user_vehicles` (
  `user_id` int(11) NOT NULL,
  `veiculo` varchar(50) NOT NULL,
  `placa` varchar(50) DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `motor` int(11) DEFAULT 1000,
  `lataria` int(11) DEFAULT 1000,
  `gasolina` int(11) DEFAULT 15,
  `ipva` int(11) DEFAULT 7,
  `portamalas` text DEFAULT '{}',
  `tunagem` text DEFAULT '{}',
  `favorite` int(11) DEFAULT 0,
  `alugado` tinyint(4) NOT NULL DEFAULT 0,
  `data_alugado` text DEFAULT NULL,
  `expired` text DEFAULT NULL,
  PRIMARY KEY (`user_id`,`veiculo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `vrp_user_veiculos` (
  `user_id` int(11) NOT NULL,
  `veiculo` varchar(50) NOT NULL,
  `placa` varchar(50) DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `motor` int(11) DEFAULT 1000,
  `lataria` int(11) DEFAULT 1000,
  `gasolina` int(11) DEFAULT 15,
  `ipva` int(11) DEFAULT 7,
  `portamalas` text DEFAULT '{}',
  `tunagem` text DEFAULT '{}',
  `favorite` int(11) DEFAULT 0,
  `alugado` tinyint(4) NOT NULL DEFAULT 0,
  `data_alugado` text DEFAULT NULL,
  `expired` text DEFAULT NULL,
  `nitro` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`,`veiculo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `warehouses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `tax` decimal(10,2) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `user_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `core_homes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(200) NOT NULL DEFAULT 'Homes0001',
  `interior` varchar(255) NOT NULL DEFAULT 'Middle',
  `user_id` int(11) NOT NULL DEFAULT 0,
  `price` int(11) NOT NULL DEFAULT 0,
  `residents` int(11) NOT NULL DEFAULT 1,
  `vault` int(11) NOT NULL DEFAULT 1,
  `owner` int(1) NOT NULL DEFAULT 0,
  `tax` int(11) NOT NULL DEFAULT 0,
  `number` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `id` (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `core_residences` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL DEFAULT 'Homes0001',
  `x` varchar(50) DEFAULT NULL,
  `y` varchar(50) DEFAULT NULL,
  `z` varchar(50) DEFAULT NULL,
  `interiorType` varchar(50) NOT NULL DEFAULT 'Mansion',
  `intPrice` int(11) NOT NULL DEFAULT 0,
  `slot` int(11) NOT NULL DEFAULT 0,
  `trade` int(11) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `zo_attachs` (
  `user_id` int(11) NOT NULL,
  `attachs` text DEFAULT NULL,
  PRIMARY KEY (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
