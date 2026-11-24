-- Schema only: imported data and database deletion commands intentionally omitted.

SET @IC_PREVIOUS_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `m_patrulha` (
  `user_id` int(11) NOT NULL,
  `organization` varchar(50) NOT NULL,
  `ptr` int(11) NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
;

SET FOREIGN_KEY_CHECKS = @IC_PREVIOUS_FOREIGN_KEY_CHECKS;
