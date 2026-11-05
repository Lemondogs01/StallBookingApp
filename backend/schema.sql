CREATE DATABASE IF NOT EXISTS campus_market CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE campus_market;

CREATE TABLE IF NOT EXISTS users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NULL,
  email VARCHAR(100) NULL,
  role ENUM('vendor', 'admin') NOT NULL DEFAULT 'vendor',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stalls (
  stall_id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(20) NOT NULL UNIQUE,
  zone ENUM('A', 'B', 'C', 'D') NOT NULL,
  size VARCHAR(30) NOT NULL,
  price_per_day DECIMAL(10, 2) NOT NULL,
  product_type ENUM('Food', 'Drinks', 'Clothing', 'Accessories', 'Handmade', 'Other') NOT NULL,
  status ENUM('available', 'unavailable') NOT NULL DEFAULT 'available',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CHECK (price_per_day > 0)
);

CREATE TABLE IF NOT EXISTS bookings (
  booking_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  stall_id INT NOT NULL,
  booking_date DATE NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  status ENUM('pending', 'approved', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_bookings_user FOREIGN KEY (user_id) REFERENCES users(user_id),
  CONSTRAINT fk_bookings_stall FOREIGN KEY (stall_id) REFERENCES stalls(stall_id),
  INDEX idx_bookings_stall_date_status (stall_id, booking_date, status)
);
