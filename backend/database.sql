-- Database Schema & Seed Data for MFU Stall Booking System
CREATE DATABASE IF NOT EXISTS mfu_stall_booking DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mfu_stall_booking;

-- Drop tables if exists (for reset purposes)
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS stalls;
DROP TABLE IF EXISTS users;

-- 1. Users, administrators, and vendor profiles
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('vendor', 'admin') NOT NULL DEFAULT 'vendor',
    shop_name VARCHAR(100) NOT NULL,
    real_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    profile_image VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. Stalls (30 market stalls)
CREATE TABLE stalls (
    id VARCHAR(10) PRIMARY KEY, -- 'A1'-'A20', 'B1'-'B5', 'C1'-'C5'
    category ENUM('food', 'fashion', 'general') NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

-- 3. Bookings and review status
CREATE TABLE bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_code VARCHAR(30) NOT NULL UNIQUE, -- e.g. 'BK-20261108-A8F2'
    user_id INT NOT NULL,
    stall_id VARCHAR(10) NOT NULL,
    booking_date DATE NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'approved', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
    approved_by_user_id INT NULL,
    approved_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    active_slot TINYINT GENERATED ALWAYS AS (
        IF(status IN ('pending', 'approved'), 1, NULL)
    ) STORED,
    UNIQUE KEY uq_no_double_booking (stall_id, booking_date, active_slot),
    KEY idx_bookings_approved_by_user_id (approved_by_user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (stall_id) REFERENCES stalls(id) ON DELETE CASCADE
);

-- 4. Payments and uploaded payment slips
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    slip_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_one_payment_per_booking (booking_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
);

-- Seed Data: 30 Stalls
INSERT INTO stalls (id, category, price) VALUES
-- Food zone (20 stalls: A1-A20)
('A1', 'food', 150.00), ('A2', 'food', 150.00), ('A3', 'food', 150.00), ('A4', 'food', 150.00),
('A5', 'food', 150.00), ('A6', 'food', 150.00), ('A7', 'food', 150.00), ('A8', 'food', 150.00),
('A9', 'food', 150.00), ('A10', 'food', 150.00), ('A11', 'food', 150.00), ('A12', 'food', 150.00),
('A13', 'food', 150.00), ('A14', 'food', 150.00), ('A15', 'food', 150.00), ('A16', 'food', 150.00),
('A17', 'food', 150.00), ('A18', 'food', 150.00), ('A19', 'food', 150.00), ('A20', 'food', 150.00),

-- Fashion zone (5 stalls: B1-B5)
('B1', 'fashion', 180.00), ('B2', 'fashion', 180.00), ('B3', 'fashion', 180.00), ('B4', 'fashion', 180.00),
('B5', 'fashion', 180.00),

-- General goods zone (5 stalls: C1-C5)
('C1', 'general', 120.00), ('C2', 'general', 120.00), ('C3', 'general', 120.00), ('C4', 'general', 120.00),
('C5', 'general', 120.00);

-- Provision an Admin account from the backend terminal with `npm run admin:create`.
-- That command hashes the password with Argon2id and does not expose a public
-- Admin registration endpoint.
