-- Additive schema. Data promotion and version marker are applied by the explicit Python command.
CREATE TABLE IF NOT EXISTS ic_admin_calls (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  owner_id INT NULL, subject_key VARCHAR(96) NULL,
  actor_id INT NULL, actor_subject VARCHAR(96) NULL,
  state VARCHAR(20) NOT NULL, department VARCHAR(80) NOT NULL DEFAULT '',
  created_at BIGINT NOT NULL DEFAULT 0, expires_at BIGINT NOT NULL DEFAULT 0,
  payload LONGTEXT NOT NULL, revision INT NOT NULL DEFAULT 1,
  KEY ic_calls_owner (subject_key, created_at),
  KEY ic_calls_queue (department, state, created_at),
  KEY ic_calls_actor (actor_subject, state, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS ic_admin_ratings LIKE ic_admin_calls;
CREATE TABLE IF NOT EXISTS ic_admin_vip_assignments (
  id VARCHAR(96) NOT NULL PRIMARY KEY,
  owner_id INT NULL, subject_key VARCHAR(96) NULL,
  actor_id INT NULL, actor_subject VARCHAR(96) NULL,
  state VARCHAR(20) NOT NULL, department VARCHAR(80) NOT NULL DEFAULT '',
  created_at BIGINT NOT NULL DEFAULT 0, expires_at BIGINT NOT NULL DEFAULT 0,
  payload LONGTEXT NOT NULL, revision INT NOT NULL DEFAULT 1,
  KEY ic_vip_owner (subject_key, state, expires_at),
  KEY ic_vip_pending (state, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
