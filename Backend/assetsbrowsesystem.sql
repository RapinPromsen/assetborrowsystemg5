-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Nov 06, 2025 at 04:34 AM
-- Server version: 8.4.3
-- PHP Version: 8.3.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `assetsbrowsesystem`
--

-- --------------------------------------------------------

--
-- Table structure for table `assets`
--

CREATE TABLE `assets` (
  `id` int NOT NULL,
  `code` varchar(50) NOT NULL,
  `name` varchar(120) NOT NULL,
  `description` text,
  `status` enum('available','pending','borrowed','disabled') DEFAULT 'available',
  `image_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `assets`
--

INSERT INTO `assets` (`id`, `code`, `name`, `description`, `status`, `image_url`, `created_at`) VALUES
(2, 'AS-002', 'Camera', NULL, 'disabled', '/uploads/1761809104954.png', '2025-10-30 07:25:04'),
(3, 'AS-003', 'Camera', NULL, 'available', '/uploads/1761809105815.png', '2025-10-30 07:25:05'),
(4, 'AS-004', 'Camera', NULL, 'available', '/uploads/1761809106627.png', '2025-10-30 07:25:06'),
(5, 'AS-005', 'Router', 'TEST', 'available', '/uploads/1762105726451.png', '2025-10-30 07:25:07');

-- --------------------------------------------------------

--
-- Table structure for table `borrow_requests`
--

CREATE TABLE `borrow_requests` (
  `id` int NOT NULL,
  `requester_id` int NOT NULL,
  `asset_id` int NOT NULL,
  `borrow_date` date NOT NULL,
  `return_date` date NOT NULL,
  `status` enum('pending','approved','rejected','returned') DEFAULT 'pending',
  `decided_by` int DEFAULT NULL,
  `got_back_by` int DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `decision_note` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `borrow_requests`
--

INSERT INTO `borrow_requests` (`id`, `requester_id`, `asset_id`, `borrow_date`, `return_date`, `status`, `decided_by`, `got_back_by`, `decided_at`, `decision_note`, `created_at`) VALUES
(4, 3, 3, '2025-11-06', '2025-11-06', 'returned', 2, 1, '2025-11-06 03:23:36', 'Very Good', '2025-11-05 20:21:52');

-- --------------------------------------------------------

--
-- Table structure for table `request_history`
--

CREATE TABLE `request_history` (
  `id` int NOT NULL,
  `request_id` int NOT NULL,
  `old_status` varchar(20) NOT NULL,
  `new_status` varchar(20) NOT NULL,
  `changed_by_id` int DEFAULT NULL,
  `changed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `note` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `request_history`
--

INSERT INTO `request_history` (`id`, `request_id`, `old_status`, `new_status`, `changed_by_id`, `changed_at`, `note`) VALUES
(2, 4, 'approved', 'returned', 1, '2025-11-05 20:23:36', 'Returned by staff');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `username` varchar(60) NOT NULL,
  `password` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `role` enum('STUDENT','STAFF','LECTURER') NOT NULL DEFAULT 'STUDENT',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `full_name`, `username`, `password`, `role`, `created_at`) VALUES
(1, 'Staff One', 'staff1', '$2b$10$j0CVcBRiwROpT.iKiZ.mRu9sjTSaG/co1zGjx1ZPxBC5Z3SYgxoYi', 'STAFF', '2025-10-30 06:50:03'),
(2, 'Lecture One', 'lecture1', '$2b$10$3cqgFSAj5a6jH6JQLjcT6uQ/zxKBhkv5Oop8Us2F.KiaVYsPFIvei', 'LECTURER', '2025-10-30 07:23:25'),
(3, 'Student One', 'student1', '$2b$10$rnvjbIPhm0toUKEkPF0IaOoPfp2pWX1/E.733/gaN4Yl14DdiYS/S', 'STUDENT', '2025-10-30 07:24:12'),
(4, 'test', 'test123', '$2b$10$oziqJ99L3O6F92fPx2h3seM3sHk/oPIhcwvSGg4cDHStxYSDFEBM2', 'STUDENT', '2025-10-31 02:06:35'),
(5, 'test123123', 'test2222', '$2b$10$6dnUZaC8gPQyk423TzIrieCevyMhcDQyX3RfD.W6/lITY9jqCxYqC', 'STUDENT', '2025-10-31 03:19:38'),
(6, 'test1231', 'test2', '$2b$10$0YWZiykrWEBk24qRMUkQPussjIt/FSGnb8bajMgYAfSHIiHRj.myy', 'STUDENT', '2025-10-31 03:43:49');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `assets`
--
ALTER TABLE `assets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `borrow_requests`
--
ALTER TABLE `borrow_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `requester_id` (`requester_id`),
  ADD KEY `asset_id` (`asset_id`),
  ADD KEY `decided_by` (`decided_by`);

--
-- Indexes for table `request_history`
--
ALTER TABLE `request_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `request_id` (`request_id`),
  ADD KEY `changed_by_id` (`changed_by_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `assets`
--
ALTER TABLE `assets`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `borrow_requests`
--
ALTER TABLE `borrow_requests`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `request_history`
--
ALTER TABLE `request_history`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `borrow_requests`
--
ALTER TABLE `borrow_requests`
  ADD CONSTRAINT `borrow_requests_ibfk_1` FOREIGN KEY (`requester_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `borrow_requests_ibfk_2` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `borrow_requests_ibfk_3` FOREIGN KEY (`decided_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `request_history`
--
ALTER TABLE `request_history`
  ADD CONSTRAINT `request_history_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `borrow_requests` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `request_history_ibfk_2` FOREIGN KEY (`changed_by_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
