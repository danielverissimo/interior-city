-- IC Config organization deletion journal and late-writer guards (MariaDB 10.11).
-- Apply explicitly with the migration tool; runtime never installs schema.
CREATE TABLE IF NOT EXISTS ic_config_schema (
  version INT NOT NULL PRIMARY KEY
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS ic_config_org_deletions (
  org_name VARCHAR(160) NOT NULL PRIMARY KEY,
  operation_id VARCHAR(96) NOT NULL UNIQUE,
  phase VARCHAR(24) NOT NULL,
  actor_id INT NOT NULL,
  payload LONGTEXT NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS ic_config_deleted_groups (
  group_name VARCHAR(160) NOT NULL PRIMARY KEY,
  operation_id VARCHAR(96) NOT NULL,
  KEY(operation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- Same owning definition as m_orgs_v2/server/main.lua CreateTable3. The imported
-- schema omits this table; creating it is additive and matches the runtime owner.
CREATE TABLE IF NOT EXISTS sjr_logs (
  organization VARCHAR(50) DEFAULT NULL,
  user_id INT DEFAULT NULL,
  role VARCHAR(50) DEFAULT NULL,
  name VARCHAR(50) DEFAULT NULL,
  description VARCHAR(200) DEFAULT NULL,
  date VARCHAR(50) DEFAULT NULL,
  expire_at INT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
DELIMITER $$
CREATE TRIGGER IF NOT EXISTS ic_config_org_1_insert BEFORE INSERT ON mirtin_orgs_goals FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.organization AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_org_1_update BEFORE UPDATE ON mirtin_orgs_goals FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.organization AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_org_2_insert BEFORE INSERT ON mirtin_orgs_player_infos FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.organization AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_org_2_update BEFORE UPDATE ON mirtin_orgs_player_infos FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.organization AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_org_3_insert BEFORE INSERT ON mirtin_orgs_chat FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.organization AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_org_3_update BEFORE UPDATE ON mirtin_orgs_chat FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.organization AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_org_4_insert BEFORE INSERT ON sjr_logs FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.organization AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_org_4_update BEFORE UPDATE ON sjr_logs FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.organization AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_org_5_insert BEFORE INSERT ON mirtin_organization_members FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.group_type AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_org_5_update BEFORE UPDATE ON mirtin_organization_members FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.group_type AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_org_6_insert BEFORE INSERT ON mirtin_orgs_info FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.organization AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_org_6_update BEFORE UPDATE ON mirtin_orgs_info FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=NEW.organization AND phase IN ('prepared','sql_committed','complete')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IC_CONFIG_ORGANIZATION_DELETED';
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_userdata_insert BEFORE INSERT ON vrp_user_data FOR EACH ROW
BEGIN
  DECLARE finished INT DEFAULT 0;
  DECLARE deleted_group VARCHAR(160);
  DECLARE selected_groups CURSOR FOR
    SELECT g.group_name FROM ic_config_deleted_groups g JOIN ic_config_org_deletions d ON d.operation_id=g.operation_id
    WHERE d.phase IN ('prepared','sql_committed','complete');
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished=1;
  IF NEW.dkey='vRP:datatable' AND JSON_VALID(NEW.dvalue) THEN
    OPEN selected_groups;
    read_groups: LOOP
      FETCH selected_groups INTO deleted_group;
      IF finished=1 THEN LEAVE read_groups; END IF;
      SET NEW.dvalue=JSON_REMOVE(NEW.dvalue,CONCAT('$.groups.',JSON_QUOTE(deleted_group)),CONCAT('$.vip_group_expirations.',JSON_QUOTE(deleted_group)));
    END LOOP;
    CLOSE selected_groups;
  END IF;
END$$
CREATE TRIGGER IF NOT EXISTS ic_config_userdata_update BEFORE UPDATE ON vrp_user_data FOR EACH ROW
BEGIN
  DECLARE finished INT DEFAULT 0;
  DECLARE deleted_group VARCHAR(160);
  DECLARE selected_groups CURSOR FOR
    SELECT g.group_name FROM ic_config_deleted_groups g JOIN ic_config_org_deletions d ON d.operation_id=g.operation_id
    WHERE d.phase IN ('prepared','sql_committed','complete');
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished=1;
  IF NEW.dkey='vRP:datatable' AND JSON_VALID(NEW.dvalue) THEN
    OPEN selected_groups;
    read_groups: LOOP
      FETCH selected_groups INTO deleted_group;
      IF finished=1 THEN LEAVE read_groups; END IF;
      SET NEW.dvalue=JSON_REMOVE(NEW.dvalue,CONCAT('$.groups.',JSON_QUOTE(deleted_group)),CONCAT('$.vip_group_expirations.',JSON_QUOTE(deleted_group)));
    END LOOP;
    CLOSE selected_groups;
  END IF;
END$$
DELIMITER ;
INSERT IGNORE INTO ic_config_schema(version) VALUES(1);
