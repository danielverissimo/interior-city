-- Schema only: imported data and database deletion commands intentionally omitted.

CREATE TABLE IF NOT EXISTS `m_patrulha` (
  `user_id` int(11) NOT NULL,
  `organization` varchar(50) NOT NULL,
  `ptr` int(11) NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
