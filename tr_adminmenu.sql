CREATE TABLE IF NOT EXISTS `admin_bans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(255) NOT NULL,
    `name` VARCHAR(255) DEFAULT 'Unknown',
    `banner` VARCHAR(255) NOT NULL,
    `banner_name` VARCHAR(255) DEFAULT 'Console',
    `reason` TEXT NOT NULL,
    `expire` DATETIME DEFAULT NULL,
    `tokens` TEXT DEFAULT NULL,
    `ip` VARCHAR(50) DEFAULT NULL,
    `hwid` VARCHAR(255) DEFAULT NULL,
    `unbanned_by` VARCHAR(255) DEFAULT NULL,
    `unban_date` DATETIME DEFAULT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `admin_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin` VARCHAR(255) NOT NULL,
    `admin_name` VARCHAR(255) DEFAULT 'Unknown',
    `action` VARCHAR(100) NOT NULL,
    `category` VARCHAR(50) NOT NULL,
    `details` TEXT,
    `target` VARCHAR(255) DEFAULT NULL,
    `target_name` VARCHAR(255) DEFAULT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `admin_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` INT NOT NULL,
    `player_name` VARCHAR(255) NOT NULL,
    `player_identifier` VARCHAR(255) NOT NULL,
    `category` VARCHAR(100) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `status` VARCHAR(50) NOT NULL DEFAULT 'open',
    `assigned_admin` VARCHAR(255) DEFAULT NULL,
    `assigned_admin_name` VARCHAR(255) DEFAULT NULL,
    `close_reason` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `closed_at` TIMESTAMP NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `admin_report_messages` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT NOT NULL,
    `sender_id` INT NOT NULL,
    `sender_name` VARCHAR(255) NOT NULL,
    `sender_type` VARCHAR(20) NOT NULL DEFAULT 'player',
    `message` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`report_id`) REFERENCES `admin_reports`(`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `admin_warnings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `target_identifier` VARCHAR(50) NOT NULL,
    `target_name` VARCHAR(255) DEFAULT NULL,
    `admin_name` VARCHAR(255) DEFAULT NULL,
    `reason` TEXT NOT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
