-- =============================================================================
-- Clean N Ride CRM & Detailing Platform - Database Schema
-- Charset: utf8mb4, Collation: utf8mb4_unicode_ci
-- =============================================================================

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

-- -----------------------------------------------------------------------------
-- Table: sys_config (System & Migration Versioning)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sys_config` (
  `key_name` VARCHAR(50) NOT NULL,
  `key_value` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`key_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `sys_config` (`key_name`, `key_value`) VALUES
('schema_version', '1')
ON DUPLICATE KEY UPDATE `key_value` = VALUES(`key_value`);

-- -----------------------------------------------------------------------------
-- Table: users (Admin authentication with bcrypt password verification)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `login` VARCHAR(100) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Default credentials:
-- Login: admin
-- Password: admin123 (Change upon production deployment!)
INSERT INTO `users` (`id`, `login`, `password_hash`) VALUES
(1, 'admin', '$2y$12$cwhmmtpO4B5SYwk.O1xhwO8FGWG1jhpHWLifg8VaSkB4Jc7VXLCLu')
ON DUPLICATE KEY UPDATE `login` = VALUES(`login`);

-- -----------------------------------------------------------------------------
-- Table: customers (CRM Client records & LTV tracking)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `customers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `phone` VARCHAR(50) NULL,
  `email` VARCHAR(255) NULL,
  `car_brand` VARCHAR(80) NULL,
  `car_model` VARCHAR(80) NULL,
  `car_year` SMALLINT NULL,
  `car_plate` VARCHAR(20) NULL,
  `notes` TEXT NULL,
  `ltv` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: customer_cars (Client multi-vehicle fleet)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `customer_cars` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NOT NULL,
  `brand` VARCHAR(80) NULL,
  `model` VARCHAR(80) NULL,
  `year` SMALLINT NULL,
  `plate` VARCHAR(30) NULL,
  `vin` VARCHAR(30) NULL,
  `notes` TEXT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_customer` (`customer_id`),
  CONSTRAINT `fk_customer_cars_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: orders (Detailing Orders Lifecycle)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `orders` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NOT NULL,
  `car_brand` VARCHAR(80) NULL,
  `car_model` VARCHAR(80) NULL,
  `services` TEXT NULL,
  `notes` TEXT NULL,
  `total_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `status` ENUM('pending','in_progress','ready','completed') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `finished_at` DATE NULL,
  PRIMARY KEY (`id`),
  KEY `idx_customer` (`customer_id`),
  CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: appointments (Calendar booking management)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `appointments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT UNSIGNED NOT NULL,
  `car_string` VARCHAR(150) NULL,
  `appt_date` DATE NOT NULL,
  `appt_time` TIME NOT NULL DEFAULT '09:00:00',
  `services` TEXT NOT NULL,
  `total_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `notes` TEXT NULL,
  `status` ENUM('scheduled','done','cancelled') NOT NULL DEFAULT 'scheduled',
  `order_id` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_customer` (`customer_id`),
  KEY `idx_date` (`appt_date`),
  CONSTRAINT `fk_appointments_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: service_reminders (Automated post-service maintenance pipeline)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `service_reminders` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` INT UNSIGNED NULL,
  `customer_id` INT UNSIGNED NOT NULL,
  `reminder_type` ENUM(
    'ceramic_review_6m',
    'ceramic_review_12m',
    'wax_refresh_3m',
    'wax_refresh_4m',
    'detail_wash',
    'leather_care_6m',
    'glass_coating_6m',
    'interior_detox_12m'
  ) NOT NULL,
  `scheduled_date` DATE NOT NULL,
  `status` ENUM('pending','sent','done','cancelled') NOT NULL DEFAULT 'pending',
  `cancel_reason` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_customer` (`customer_id`),
  KEY `idx_scheduled` (`scheduled_date`),
  CONSTRAINT `fk_reminders_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: notifications (Web leads & Booking submissions)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `car` VARCHAR(255) NULL,
  `services` TEXT NULL,
  `total` VARCHAR(50) NULL,
  `client_name` VARCHAR(255) NULL,
  `client_phone` VARCHAR(50) NULL,
  `client_email` VARCHAR(255) NULL,
  `preferred_date` DATE NULL,
  `notes` TEXT NULL,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: calc_categories (Service categories for interactive calculator)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `calc_categories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `slug` VARCHAR(80) NOT NULL UNIQUE,
  `name` VARCHAR(150) NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `calc_categories` (`id`, `slug`, `name`, `sort_order`) VALUES
(1, 'packages', 'Pakiety Kompleksowe', 1),
(2, 'exterior', 'Korekta Lakieru & Mycie', 2),
(3, 'coatings', 'Zabezpieczenia & Powłoki', 3),
(4, 'interior', 'Detailing Wnętrza', 4),
(5, 'addons',   'Usługi Dodatkowe', 5)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- -----------------------------------------------------------------------------
-- Table: calc_services (Dynamic pricing matrix by car segment 0/1/2)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `calc_services` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `has_variants` TINYINT(1) DEFAULT 0,
  `price_0` DECIMAL(10,2) DEFAULT 0.00,
  `price_1` DECIMAL(10,2) DEFAULT 0.00,
  `price_2` DECIMAL(10,2) DEFAULT 0.00,
  `time_h` DECIMAL(4,1) DEFAULT 0.0,
  `variants_json` TEXT NULL,
  `rules_excludes` VARCHAR(255) DEFAULT '',
  `rules_requires` VARCHAR(255) DEFAULT '',
  `rules_requires_or` VARCHAR(255) DEFAULT '',
  `requires_mode` ENUM('AND','OR') NOT NULL DEFAULT 'AND',
  `sort_order` INT DEFAULT 0,
  `reminder_type` VARCHAR(50) NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sample starter services for instant testing
INSERT INTO `calc_services` (`id`, `category`, `name`, `description`, `has_variants`, `price_0`, `price_1`, `price_2`, `time_h`, `sort_order`, `reminder_type`) VALUES
(1, 'exterior', 'One-Step Korekta Lakieru', 'Jednoetapowe polerowanie odświeżające usuwające do 60-70% zarysowań.', 0, 800.00, 1000.00, 1200.00, 8.0, 1, 'wax_refresh_4m'),
(2, 'coatings', 'Powłoka Ceramiczna 3-letnia 9H', 'Zaawansowana ochrona ceramiczna lakieru o twardości 9H z hydrofobowością.', 0, 1500.00, 1800.00, 2200.00, 6.0, 2, 'ceramic_review_12m'),
(3, 'interior', 'Kompleksowy Detailing Wnętrza', 'Pranie ekstrakcyjne tapicerki, czyszczenie i konserwacja skór oraz plastików.', 0, 500.00, 650.00, 800.00, 5.0, 3, 'interior_detox_12m'),
(4, 'packages', 'Pakiet Full Motorsport Shield', 'Pełna wieloetapowa korekta + ceramika 9H + detailing wnętrza z impregnacją.', 0, 2800.00, 3300.00, 3900.00, 20.0, 4, 'ceramic_review_6m')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- -----------------------------------------------------------------------------
-- Table: projects (Portfolio showcase items)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `projects` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `car_name` VARCHAR(255) NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `category` VARCHAR(100) NULL,
  `cover_image` VARCHAR(255) NULL,
  `description` TEXT NULL,
  `customer_id` INT UNSIGNED NULL,
  `order_id` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Table: project_pairs (Interactive Before/After comparison images)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `project_pairs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` INT UNSIGNED NOT NULL,
  `label` VARCHAR(255) NOT NULL,
  `before_image` VARCHAR(255) NOT NULL,
  `after_image` VARCHAR(255) NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  CONSTRAINT `fk_project_pairs_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET foreign_key_checks = 1;
