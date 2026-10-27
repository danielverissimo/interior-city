-- Schema only: imported data and database deletion commands intentionally omitted.

CREATE TABLE IF NOT EXISTS `m_empregos` (
  `user_id` int(11) NOT NULL,
  `dvalue` text DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
