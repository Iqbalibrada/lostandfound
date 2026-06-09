-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 05, 2026 at 03:53 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `lostandfound`
--

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL,
  `code` varchar(50) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `code`, `created_at`, `updated_at`) VALUES
(1, 'Dompet', 'wallet', '2026-05-26 07:37:37', '2026-05-26 07:37:37'),
(2, 'Kunci', 'key', '2026-05-26 07:37:37', '2026-05-26 07:37:37'),
(3, 'Handphone', 'phone', '2026-05-26 07:37:37', '2026-05-26 07:37:37');

-- --------------------------------------------------------

--
-- Table structure for table `category_fields`
--

CREATE TABLE `category_fields` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `category_id` bigint(20) UNSIGNED NOT NULL,
  `field_key` varchar(50) NOT NULL,
  `field_label` varchar(100) NOT NULL,
  `field_type` enum('text','number','select','textarea') NOT NULL DEFAULT 'text',
  `is_required` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `category_fields`
--

INSERT INTO `category_fields` (`id`, `category_id`, `field_key`, `field_label`, `field_type`, `is_required`, `sort_order`, `created_at`, `updated_at`) VALUES
(1, 1, 'warna', 'Warna dompet', 'text', 1, 1, '2026-05-26 07:37:37', '2026-05-26 07:37:37'),
(2, 1, 'bahan', 'Bahan', 'text', 1, 2, '2026-05-26 07:37:37', '2026-05-26 07:37:37'),
(3, 1, 'ciri', 'Ciri khusus', 'textarea', 1, 3, '2026-05-26 07:37:37', '2026-05-26 07:37:37'),
(4, 2, 'merk_motor', 'Merk motor', 'text', 1, 1, '2026-05-26 07:37:37', '2026-05-26 07:37:37'),
(5, 2, 'tipe_motor', 'Tipe motor', 'text', 1, 2, '2026-05-26 07:37:37', '2026-05-26 07:37:37'),
(6, 2, 'gantungan', 'Gantungan kunci', 'text', 1, 3, '2026-05-26 07:37:37', '2026-05-26 07:37:37'),
(7, 3, 'merk', 'Merk handphone', 'text', 1, 1, '2026-05-26 07:37:37', '2026-05-26 07:37:37'),
(8, 3, 'tipe', 'Tipe handphone', 'text', 1, 2, '2026-05-26 07:37:37', '2026-05-26 07:37:37'),
(9, 3, 'warna', 'Warna', 'text', 1, 3, '2026-05-26 07:37:37', '2026-05-26 07:37:37');

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `category_id` bigint(20) UNSIGNED NOT NULL,
  `type` enum('lost','found') NOT NULL,
  `photo_url` varchar(255) DEFAULT NULL,
  `status` enum('open','claimed','returned','rejected') NOT NULL DEFAULT 'open',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reports`
--

INSERT INTO `reports` (`id`, `user_id`, `category_id`, `type`, `photo_url`, `status`, `created_at`, `updated_at`) VALUES
(3, 2, 2, 'found', 'https://example.com/kunci.jpg', 'open', '2026-05-26 07:38:31', '2026-05-26 07:38:31'),
(4, 3, 1, 'lost', '', 'open', '2026-05-26 08:03:32', '2026-05-26 08:03:32'),
(5, 4, 3, 'found', '', 'open', '2026-05-26 08:04:38', '2026-05-26 08:04:38'),
(6, 4, 3, 'found', '', 'open', '2026-05-26 08:09:09', '2026-05-26 08:09:09'),
(7, 5, 2, 'lost', '', 'open', '2026-05-26 08:59:47', '2026-05-26 08:59:47'),
(8, 1, 2, 'lost', '', 'open', '2026-05-26 09:36:16', '2026-05-26 09:36:16'),
(9, 5, 3, 'lost', '', 'open', '2026-05-26 11:38:51', '2026-05-26 11:38:51'),
(10, 5, 2, 'lost', '', 'open', '2026-06-03 01:04:50', '2026-06-03 01:04:50'),
(11, 5, 1, 'lost', '', 'open', '2026-06-03 01:05:01', '2026-06-03 01:05:01'),
(12, 5, 3, 'lost', '', 'open', '2026-06-03 01:32:35', '2026-06-03 01:32:35'),
(13, 5, 3, 'lost', 'uploads/reports/report_1780575753_4086.png', 'open', '2026-06-04 12:22:33', '2026-06-04 12:22:33'),
(14, 4, 1, 'found', NULL, 'open', '2026-06-04 12:47:22', '2026-06-04 12:47:22'),
(32, 6, 3, 'lost', NULL, 'open', '2026-06-05 00:07:32', '2026-06-05 00:07:32'),
(33, 6, 3, 'lost', NULL, 'open', '2026-06-05 00:07:51', '2026-06-05 00:07:51'),
(34, 6, 3, 'lost', NULL, 'open', '2026-06-05 00:19:13', '2026-06-05 00:19:13'),
(35, 6, 2, 'lost', NULL, 'open', '2026-06-05 00:21:01', '2026-06-05 00:21:01');

-- --------------------------------------------------------

--
-- Table structure for table `report_details`
--

CREATE TABLE `report_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `report_id` bigint(20) UNSIGNED NOT NULL,
  `field_key` varchar(50) NOT NULL,
  `field_label` varchar(100) NOT NULL,
  `field_value` text NOT NULL,
  `is_public` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `report_details`
--

INSERT INTO `report_details` (`id`, `report_id`, `field_key`, `field_label`, `field_value`, `is_public`, `created_at`, `updated_at`) VALUES
(4, 3, 'merk_motor', 'Merk motor', 'Honda', 0, '2026-05-26 07:38:31', '2026-05-26 07:38:31'),
(5, 3, 'tipe_motor', 'Tipe motor', 'Vario 125', 0, '2026-05-26 07:38:31', '2026-05-26 07:38:31'),
(6, 3, 'gantungan', 'Gantungan kunci', 'Biru', 0, '2026-05-26 07:38:31', '2026-05-26 07:38:31'),
(7, 4, 'warna', 'Warna dompet', 'coklat', 1, '2026-05-26 08:03:32', '2026-05-26 08:03:32'),
(8, 4, 'bahan', 'Bahan', 'kulit', 1, '2026-05-26 08:03:32', '2026-05-26 08:03:32'),
(9, 4, 'ciri', 'Ciri khusus', 'berisi ktp', 1, '2026-05-26 08:03:32', '2026-05-26 08:03:32'),
(10, 5, 'merk', 'Merk handphone', 'Apple', 0, '2026-05-26 08:04:38', '2026-05-26 08:04:38'),
(11, 5, 'tipe', 'Tipe handphone', 'Iphone 13', 0, '2026-05-26 08:04:38', '2026-05-26 08:04:38'),
(12, 5, 'warna', 'Warna', 'midnight', 0, '2026-05-26 08:04:38', '2026-05-26 08:04:38'),
(13, 6, 'merk', 'Merk handphone', 'Samsung', 0, '2026-05-26 08:09:09', '2026-05-26 08:09:09'),
(14, 6, 'tipe', 'Tipe handphone', 'S24', 0, '2026-05-26 08:09:09', '2026-05-26 08:09:09'),
(15, 6, 'warna', 'Warna', 'Hitam', 0, '2026-05-26 08:09:09', '2026-05-26 08:09:09'),
(16, 7, 'merk_motor', 'Merk motor', 'yamaha', 1, '2026-05-26 08:59:47', '2026-05-26 08:59:47'),
(17, 7, 'tipe_motor', 'Tipe motor', 'r15', 1, '2026-05-26 08:59:47', '2026-05-26 08:59:47'),
(18, 7, 'gantungan', 'Gantungan kunci', 'kunci lagi', 1, '2026-05-26 08:59:47', '2026-05-26 08:59:47'),
(19, 8, 'merk_motor', 'Merk motor', 'Honda', 1, '2026-05-26 09:36:16', '2026-05-26 09:36:16'),
(20, 8, 'tipe_motor', 'Tipe motor', 'Vario 125', 1, '2026-05-26 09:36:16', '2026-05-26 09:36:16'),
(21, 8, 'gantungan', 'Gantungan kunci', 'Biru', 1, '2026-05-26 09:36:16', '2026-05-26 09:36:16'),
(22, 9, 'merk', 'Merk handphone', 'Apple', 1, '2026-05-26 11:38:51', '2026-05-26 11:38:51'),
(23, 9, 'tipe', 'Tipe handphone', 'Iphone', 1, '2026-05-26 11:38:51', '2026-05-26 11:38:51'),
(24, 9, 'warna', 'Warna', 'midnight', 1, '2026-05-26 11:38:51', '2026-05-26 11:38:51'),
(25, 10, 'merk_motor', 'Merk motor', 'Honda', 1, '2026-06-03 01:04:50', '2026-06-03 01:04:50'),
(26, 10, 'tipe_motor', 'Tipe motor', 'R15', 1, '2026-06-03 01:04:50', '2026-06-03 01:04:50'),
(27, 10, 'gantungan', 'Gantungan kunci', 'gaada', 1, '2026-06-03 01:04:50', '2026-06-03 01:04:50'),
(28, 11, 'warna', 'Warna dompet', 'hitam', 1, '2026-06-03 01:05:01', '2026-06-03 01:05:01'),
(29, 11, 'bahan', 'Bahan', 'kulit', 1, '2026-06-03 01:05:01', '2026-06-03 01:05:01'),
(30, 11, 'ciri', 'Ciri khusus', 'ada kartu', 1, '2026-06-03 01:05:01', '2026-06-03 01:05:01'),
(31, 12, 'merk', 'Merk handphone', 'Samsung', 1, '2026-06-03 01:32:35', '2026-06-03 01:32:35'),
(32, 12, 'tipe', 'Tipe handphone', 'S24', 1, '2026-06-03 01:32:35', '2026-06-03 01:32:35'),
(33, 12, 'warna', 'Warna', 'Hitam', 1, '2026-06-03 01:32:35', '2026-06-03 01:32:35'),
(34, 13, 'merk', 'Merk handphone', 'hanaang ', 1, '2026-06-04 12:22:33', '2026-06-04 12:22:33'),
(35, 13, 'tipe', 'Tipe handphone', 'hanaang 13', 1, '2026-06-04 12:22:33', '2026-06-04 12:22:33'),
(36, 13, 'warna', 'Warna', 'kuning', 1, '2026-06-04 12:22:33', '2026-06-04 12:22:33'),
(37, 14, 'warna', 'Warna dompet', 'Hijau', 1, '2026-06-04 12:47:22', '2026-06-04 12:47:22'),
(38, 14, 'bahan', 'Bahan', 'Plastik', 1, '2026-06-04 12:47:22', '2026-06-04 12:47:22'),
(39, 14, 'ciri', 'Ciri khusus', 'Ada emoney mandiri', 1, '2026-06-04 12:47:22', '2026-06-04 12:47:22'),
(91, 32, 'merk', 'Merk handphone', 'Apple', 1, '2026-06-05 00:07:32', '2026-06-05 00:07:32'),
(92, 32, 'tipe', 'Tipe handphone', 'Iphone 11', 1, '2026-06-05 00:07:32', '2026-06-05 00:07:32'),
(93, 32, 'warna', 'Warna', 'Hijau', 1, '2026-06-05 00:07:32', '2026-06-05 00:07:32'),
(94, 33, 'merk', 'Merk handphone', 'apple', 1, '2026-06-05 00:07:51', '2026-06-05 00:07:51'),
(95, 33, 'tipe', 'Tipe handphone', 'iphone 13', 1, '2026-06-05 00:07:51', '2026-06-05 00:07:51'),
(96, 33, 'warna', 'Warna', 'hitam', 1, '2026-06-05 00:07:51', '2026-06-05 00:07:51'),
(97, 34, 'merk', 'Merk handphone', 'samsung', 1, '2026-06-05 00:19:13', '2026-06-05 00:19:13'),
(98, 34, 'tipe', 'Tipe handphone', 's24', 1, '2026-06-05 00:19:13', '2026-06-05 00:19:13'),
(99, 34, 'warna', 'Warna', 'hitam', 1, '2026-06-05 00:19:13', '2026-06-05 00:19:13'),
(100, 35, 'merk_motor', 'Merk motor', 'yamaha', 1, '2026-06-05 00:21:01', '2026-06-05 00:21:01'),
(101, 35, 'tipe_motor', 'Tipe motor', 'r15', 1, '2026-06-05 00:21:01', '2026-06-05 00:21:01'),
(102, 35, 'gantungan', 'Gantungan kunci', 'gada', 1, '2026-06-05 00:21:01', '2026-06-05 00:21:01');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('user','admin') NOT NULL DEFAULT 'user',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`, `created_at`, `updated_at`) VALUES
(1, 'Codex Test User', 'codex_test_user@example.com', 'f2b14f68eb995facb3a1c35287b778d5bd785511', 'user', '2026-05-26 07:37:49', '2026-05-26 07:37:49'),
(2, 'Codex Admin', 'codex_admin@example.com', 'f865b53623b121fd34ee5426c792e5c33af8c227', 'admin', '2026-05-26 07:38:22', '2026-05-26 07:38:22'),
(3, 'nafian', 'rifkinafian@gmail.com', '666439f63b77b5ec29afda71ce690f8dc2a156a3', 'user', '2026-05-26 08:01:02', '2026-05-26 08:01:02'),
(4, 'admin', 'admin@gmail.com', 'f865b53623b121fd34ee5426c792e5c33af8c227', 'admin', '2026-05-26 08:04:11', '2026-05-26 08:04:11'),
(5, 'giega', 'giega@gmail.com', '9f1afec40429d323b2d1667fcfee0ba95d09039a', 'user', '2026-05-26 08:09:51', '2026-05-26 08:09:51'),
(6, 'Ilham Ganteng', 'ilham@gmail.com', '$2y$10$WMO5ziDsKW.yJqi2duK2SuvbCsRNxKd4S.7h57eWkX5/0pcmshl6.', 'user', NULL, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `category_fields`
--
ALTER TABLE `category_fields`
  ADD PRIMARY KEY (`id`),
  ADD KEY `category_id` (`category_id`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `category_id` (`category_id`);

--
-- Indexes for table `report_details`
--
ALTER TABLE `report_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `report_id` (`report_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `category_fields`
--
ALTER TABLE `category_fields`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT for table `report_details`
--
ALTER TABLE `report_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=103;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `category_fields`
--
ALTER TABLE `category_fields`
  ADD CONSTRAINT `category_fields_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`);

--
-- Constraints for table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `reports_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`);

--
-- Constraints for table `report_details`
--
ALTER TABLE `report_details`
  ADD CONSTRAINT `report_details_ibfk_1` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
