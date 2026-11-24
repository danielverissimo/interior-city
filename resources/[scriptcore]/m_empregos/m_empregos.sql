-- Schema only: imported data and database deletion commands intentionally omitted.

SET @IC_PREVIOUS_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `m_empregos` (
  `user_id` int(11) NOT NULL,
  `dvalue` text DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci
;

SET FOREIGN_KEY_CHECKS = @IC_PREVIOUS_FOREIGN_KEY_CHECKS;
