-- IC Admin schema v1. Apply explicitly with scripts/ic-admin-migrate.py.
-- This file never runs from the FiveM resource and does not modify legacy rows.
CREATE TABLE IF NOT EXISTS ic_admin_schema (
  version INT NOT NULL PRIMARY KEY,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ic_admin_documents (
  doc_key VARCHAR(96) NOT NULL PRIMARY KEY,
  payload LONGTEXT NOT NULL,
  revision INT NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ic_admin_operations (
  operation_key VARCHAR(180) NOT NULL PRIMARY KEY,
  actor_id INT NOT NULL,
  method VARCHAR(96) NOT NULL,
  payload LONGTEXT NOT NULL,
  state VARCHAR(20) NOT NULL,
  result LONGTEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY ic_admin_operations_state (state, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ic_admin_audit (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(96) NOT NULL,
  actor_id INT NULL,
  actor_name VARCHAR(128) NULL,
  target_id INT NULL,
  target_name VARCHAR(128) NULL,
  payload LONGTEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ic_admin_audit_created (created_at),
  KEY ic_admin_audit_action (action, created_at),
  KEY ic_admin_audit_actor (actor_id, created_at),
  KEY ic_admin_audit_target (target_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ic_admin_subjects (
  subject_key VARCHAR(96) NOT NULL PRIMARY KEY,
  user_id INT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY ic_admin_subject_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ic_admin_discipline (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  subject_key VARCHAR(96) NOT NULL,
  user_id INT NOT NULL,
  actor_id INT NOT NULL,
  kind VARCHAR(20) NOT NULL,
  reason TEXT NOT NULL,
  starts_at BIGINT NOT NULL,
  ends_at BIGINT NULL,
  state VARCHAR(20) NOT NULL,
  return_state LONGTEXT NULL,
  KEY ic_admin_discipline_subject (subject_key, starts_at),
  KEY ic_admin_discipline_user (user_id, state),
  KEY ic_admin_discipline_expiry (state, ends_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- These columns are used by the existing vRP.setBanned implementation.
ALTER TABLE mirtin_bans ADD COLUMN IF NOT EXISTS owner TINYINT NOT NULL DEFAULT 0;
ALTER TABLE mirtin_bans ADD COLUMN IF NOT EXISTS staff INT NOT NULL DEFAULT 0;
INSERT IGNORE INTO ic_admin_schema (version) VALUES (1);
