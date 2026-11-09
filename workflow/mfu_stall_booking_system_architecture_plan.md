# 📌 เอกสารวางแผนสถาปัตยกรรมระบบ (System Architecture & Technical Specification)

**ชื่อระบบ:** MFU Stall Booking System (ระบบจองแผงลอยตลาดนัด MFU)

**สถาปัตยกรรม:** Model-View-Controller (MVC) Pattern

## 🛠️ 1. Technical Stack Overview

| Layer | Technology / Tools | 
| ----- | ----- | 
| **Frontend Mobile** | Flutter (Dart) — Controller-Service Pattern | 
| **Backend API** | Node.js + Express.js (JavaScript) | 
| **Database** | MySQL (ผ่าน XAMPP / `mysql2` driver) | 
| **Password Hashing** | Argon2id (`argon2` npm package) | 
| **Authentication & Auth** | JSON Web Token (JWT) with Role-Based Access Control (RBAC) | 
| **API Testing** | Postman / Insomnia / REST Client | 

## 🏗️ 2. Structure & Directory Organization (MVC Concept)

### 2.1 Backend Project Structure (Node.js + Express)

```
backend/
├── config/
│   └── db.js                 # Database Connection Pool (MySQL)
├── controllers/
│   ├── authController.js     # Register, Login, Reset Password
│   ├── bookingController.js  # Stall Booking CRUD & Status Updates (Booking Code Generator)
│   ├── paymentController.js  # Payment Slip Upload
│   ├── stallController.js    # Stalls Daily Availability Status
│   ├── userController.js     # Profile & Self-service Password Change
│   └── adminController.js    # Analytics & Vendor Management
├── middlewares/
│   ├── authMiddleware.js     # JWT Verify token
│   ├── roleMiddleware.js     # RBAC (Vendor / Admin check)
│   └── uploadMiddleware.js   # Multer for slip & profile image uploads
├── models/
│   ├── User.js               # SQL queries for Users table
│   ├── Stall.js              # SQL queries for Stalls table
│   ├── Booking.js            # SQL queries for Bookings table
│   └── Payment.js            # SQL queries for Payments table
├── routes/
│   ├── authRoutes.js
│   ├── bookingRoutes.js
│   ├── adminRoutes.js
│   ├── paymentRoutes.js
│   ├── stallRoutes.js
│   └── userRoutes.js
├── utils/
│   └── codeGenerator.js      # Utility helper for generating unique booking_code
├── uploads/                  # Storage folder for Payment Slips & Profile Images
├── .env                      # Environment Variables (DB_HOST, JWT_SECRET, etc.)
├── server.js                 # Express App entry point
└── package.json
```

### 2.2 Frontend Project Structure (Flutter)

```
lib/
├── controllers/              # Controller (State & Business Logic)
│   ├── auth_controller.dart
│   ├── booking_controller.dart
│   ├── payment_controller.dart
│   ├── profile_controller.dart
│   └── admin_controller.dart
├── models/                   # Data Models (JSON Serializers)
│   ├── user_model.dart
│   ├── stall_model.dart
│   ├── booking_model.dart
│   └── payment_model.dart
├── services/                 # API Services (HTTP / Dio)
│   ├── api_service.dart
│   └── storage_service.dart  # Secure Token Storage (flutter_secure_storage)
├── views/                    # Views (UI Screens & Widgets)
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── change_password_dialog.dart
│   ├── vendor/
│   │   ├── category_select_screen.dart
│   │   ├── market_map_screen.dart
│   │   ├── payment_upload_screen.dart
│   │   ├── booking_history_screen.dart
│   │   └── profile_screen.dart
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart
│   │   └── user_management_screen.dart
│   └── widgets/              # Reusable UI Widgets
│       ├── stall_grid_item.dart
│       └── slip_viewer_dialog.dart
└── main.dart
```

## 🗄️ 3. Database Schema (MySQL - 4 Main Tables)

```sql
CREATE DATABASE IF NOT EXISTS mfu_stall_booking DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mfu_stall_booking;

-- 1. Table: Users (เก็บข้อมูลผู้ใช้งาน, Admin และ User Profile)
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

-- 2. Table: Stalls (30 แผงลอย)
CREATE TABLE stalls (
    id VARCHAR(10) PRIMARY KEY, -- 'A1'-'A20', 'B1'-'B5', 'C1'-'C5'
    category ENUM('food', 'fashion', 'general') NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

-- 3. Table: Bookings (ข้อมูลการจองแผงลอยประจำวัน และจัดการสถานะการอนุมัติ)
CREATE TABLE bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_code VARCHAR(30) NOT NULL UNIQUE, -- e.g. 'BK-20261108-X89A'
    user_id INT NOT NULL,
    stall_id VARCHAR(10) NOT NULL,
    booking_date DATE NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'approved', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- [แก้] กันจองซ้ำ: active_slot = 1 เมื่อ pending/approved, NULL เมื่อ rejected/cancelled
    --       แผงเดียวกัน วันเดียวกัน จึงมีการจองที่ยังใช้งานได้ครั้งเดียว (จองซ้ำได้ error 1062)
    active_slot TINYINT AS (IF(status IN ('pending', 'approved'), 1, NULL)) STORED,
    UNIQUE KEY uq_no_double_booking (stall_id, booking_date, active_slot),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (stall_id) REFERENCES stalls(id) ON DELETE CASCADE
);

-- 4. Table: Payments (เก็บสลิปหลักฐานการโอนเงิน)
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE, -- [แก้] 1 การจองแนบสลิปได้ 1 รายการ (ส่งซ้ำได้ error 1062)
    amount DECIMAL(10,2) NOT NULL,
    slip_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
);

-- Seed Data: 30 Stalls
INSERT INTO stalls (id, category, price) VALUES
-- Food Zone (20 แผง: A1 - A20)
('A1', 'food', 150.00), ('A2', 'food', 150.00), ('A3', 'food', 150.00), ('A4', 'food', 150.00),
('A5', 'food', 150.00), ('A6', 'food', 150.00), ('A7', 'food', 150.00), ('A8', 'food', 150.00),
('A9', 'food', 150.00), ('A10', 'food', 150.00), ('A11', 'food', 150.00), ('A12', 'food', 150.00),
('A13', 'food', 150.00), ('A14', 'food', 150.00), ('A15', 'food', 150.00), ('A16', 'food', 150.00),
('A17', 'food', 150.00), ('A18', 'food', 150.00), ('A19', 'food', 150.00), ('A20', 'food', 150.00),

-- Fashion Zone (5 แผง: B1 - B5)
('B1', 'fashion', 180.00), ('B2', 'fashion', 180.00), ('B3', 'fashion', 180.00), ('B4', 'fashion', 180.00),
('B5', 'fashion', 180.00),

-- General Zone (5 แผง: C1 - C5)
('C1', 'general', 120.00), ('C2', 'general', 120.00), ('C3', 'general', 120.00), ('C4', 'general', 120.00),
('C5', 'general', 120.00);
```

## 🔑 4. Booking Code Generation Logic (Backend Helper)

ในไฟล์ `backend/utils/codeGenerator.js` เราจะสร้างฟังก์ชันสำหรับสร้าง `booking_code` อัตโนมัติในฝั่ง Node.js ก่อนทำการบันทึก (`INSERT`) ลง Database:

```javascript
// backend/utils/codeGenerator.js
const crypto = require('crypto');

/**
 * สร้าง Booking Code แบบยูนีค
 * รูปแบบ: BK-YYYYMMDD-XXXX (เช่น BK-20261108-A8F2)
 */
const generateBookingCode = () => {
    // [แก้] ใช้วันที่ตามเวลาไทย (toISOString เป็น UTC ช่วง 00:00-06:59 จะได้วันของเมื่อวาน)
    const today = new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Bangkok' }).replace(/-/g, '');
    const randomHex = crypto.randomBytes(2).toString('hex').toUpperCase(); // 4 ตัวอักษรสุ่ม
    return `BK-${today}-${randomHex}`;
};

module.exports = { generateBookingCode };
```

## 🔐 5. Authentication & RBAC Authorization Design

### 5.1 Argon2id Password Hashing Strategy

* ใช้แพ็กเกจ `argon2` ใน Node.js

* **การสมัครสมาชิก/สร้างผู้ใช้:**
  ```javascript
  const argon2 = require('argon2');
  const hashedPassword = await argon2.hash(plainPassword, {
      type: argon2.argon2id,
      memoryCost: 2 ** 16, // 64 MB
      timeCost: 3
  });
  ```

* **การเข้าสู่ระบบ:**
  ```javascript
  const isMatched = await argon2.verify(user.password_hash, plainPassword);
  ```

### 5.2 Role-Based Access Control (RBAC Matrix)

| Endpoint / Feature | Public | Vendor | Admin | 
| ----- | ----- | ----- | ----- | 
| `POST /api/auth/register` | ✅ | ❌ | ❌ | 
| `POST /api/auth/login` | ✅ | ✅ | ✅ | 
| `GET /api/stalls/status?date=YYYY-MM-DD` | ❌ | ✅ | ✅ | 
| `POST /api/bookings` (สร้างการจองแผง) | ❌ | ✅ | ❌ | 
| `PUT /api/users/password` (เปลี่ยนรหัสผ่านบัญชีตัวเอง) | ❌ | ✅ | ✅ |
| `POST /api/payments` (แนบสลิปโอนเงิน) | ❌ | ✅ | ❌ | 
| `GET /api/bookings/my` (ดูประวัติการจองตัวเอง) | ❌ | ✅ | ❌ | 
| `PUT /api/bookings/:id/cancel` (ยกเลิกการจอง) | ❌ | ✅ | ❌ | 
| `GET /api/users/profile` (ดึงข้อมูลโปรไฟล์) | ❌ | ✅ | ✅ | 
| `PUT /api/users/profile` (แก้ไขโปรไฟล์/อัปโหลดรูปโปรไฟล์) | ❌ | ✅ | ✅ | 
| `GET /api/admin/bookings/pending` (ดูรายการสลิปและคำขอที่รอตรวจ) | ❌ | ❌ | ✅ | 
| `PUT /api/admin/bookings/:id/verify` (อนุมัติ/ปฏิเสธคำขอการจอง) | ❌ | ❌ | ✅ | 
| `GET /api/admin/analytics` (สรุปกราฟและรายได้) | ❌ | ❌ | ✅ | 
| `GET /api/admin/users` (ค้นหาพ่อค้าแม่ค้า) | ❌ | ❌ | ✅ | 
| `PUT /api/admin/users/:id/reset-password` (รีเซ็ตรหัสผ่าน) | ❌ | ❌ | ✅ | 

## 📡 6. CRUD Operations API Endpoint Specifications

### Auth Endpoints
* `POST /api/auth/register` — **[Create User]** สมัครสมาชิก (สร้าง Vendor)
* `POST /api/auth/login` — **[Read/Verify & Issue Token]** เข้าสู่ระบบ

### User Profile Endpoints
* `GET /api/users/profile` — **[Read Profile]** ดึงข้อมูลส่วนตัว (ชื่อร้าน, ชื่อจริง, เบอร์, รูปโปรไฟล์)
* `PUT /api/users/profile` — **[Update Profile]** แก้ไขข้อมูลส่วนตัวและอัปโหลดรูปโปรไฟล์ (`profile_image`)
* `PUT /api/users/password` — **[Change Password]** เปลี่ยนรหัสผ่านของบัญชีที่ล็อกอิน โดยตรวจรหัสผ่านปัจจุบันก่อนบันทึก Argon2id hash ใหม่

### Vendor Endpoints
* `GET /api/stalls/status?date=YYYY-MM-DD` — **[Read Stalls]** ดึงสถานะแผง 30 แผงตามวันที่เลือก
* `POST /api/bookings` — **[Create Booking]** สร้างรายการจองแผงลอย (ใช้ `generateBookingCode()`)
  * [แก้] ถ้าได้ error 1062 จาก `uq_no_double_booking` ให้ตอบ 409 "แผงนี้ถูกจองแล้วในวันนั้น"
* `POST /api/payments` — **[Create Payment]** แนบสลิปโอนเงินพร้อม `booking_id`
* `GET /api/bookings/my` — **[Read Bookings]** ดึงประวัติการจอง + ข้อมูลการชำระเงินของตนเอง
* `PUT /api/bookings/:id/cancel` — **[Update Booking Status]** ยกเลิกคำขอจอง (กรณีสถานะ pending)
  * [แก้] ต้องเช็กว่าเป็นการจองของผู้ใช้ที่ล็อกอิน (`user_id` จาก JWT) ไม่อย่างนั้นเปลี่ยน `:id` แล้วยกเลิกของคนอื่นได้

### Admin Endpoints
* `GET /api/admin/bookings/pending` — **[Read Pending Bookings]** รายการคำขอจองและสลิปที่รอตรวจสอบ
* `PUT /api/admin/bookings/:id/verify` — **[Update Booking Status]** อนุมัติ (`approved`) หรือปฏิเสธ (`rejected`) การจอง
* `GET /api/admin/analytics` — **[Read Analytics]** สรุปรายได้รวม, รายได้ประจำวันแยกตามหมวดสินค้า, สรุปรายเดือน
* `GET /api/admin/users?query=xxx` — **[Read Users]** ค้นหาและดูรายชื่อพ่อค้าแม่ค้าทั้งหมด
* `PUT /api/admin/users/:id/reset-password` — **[Update User Password]** รีเซ็ตรหัสผ่านเป็น `123456`

## 📱 7. Navigation Flow (Flutter App)

```
[Screen 1: Login / Register Screen]
         │
         ├── (Login as Vendor) ────────► [Screen 2: Vendor Navigation Shell]
         │                                       ├── Tab 1: Category Select -> Market Map Grid (Daily Booking) -> Payment Upload Screen
         │                                       ├── Tab 2: Booking History (Cancel Booking / View Slip)
         │                                       └── Tab 3: Edit Profile Screen (Edit Shop Name, Real Name, Phone & Profile Image)
         │
         └── (Login as Admin)  ────────► [Screen 3: Admin Navigation Shell]
                                                 ├── Tab 1: Dashboard (Revenue Analytics + Daily Market Map + Pending Slips Verification)
                                                 └── Tab 2: User Management Screen (Search Users + Reset Password Modal)
```

## 8. UX/UI and Account Requirements from `mfu_market_app.tsx`

The Flutter app should follow the reference flow while using the real API and database:

- **Vendor flow:** choose a stall category, select a booking date, view the daily stall map, upload a payment slip, review booking history, and edit the profile. Use the reference's clear status colors and date-specific availability. Do not copy its mock user or booking data.
- **Admin flow:** show revenue and booking analytics, a daily stall map, pending slip reviews, and vendor management. Tapping an approved stall opens its booking and vendor details, payment slip, approval timestamp, and approving administrator.
- **Approval audit:** save the approving administrator's user ID and approval time with each newly approved booking. Existing approvals without those values must display as unrecorded; do not infer an approver.
- **Payment slip corrections:** vendors can replace a submitted slip from a pending booking's history card. Keep slip replacement disabled once a booking is approved or rejected.
- **Uploaded-file replacement:** when a vendor replaces a payment slip or profile photo, update the database to the new upload and remove the old local file after the database update succeeds. If the update fails, remove the new unreferenced upload and keep the old file.
- **No email fields:** account identity and sign-in use only `username`, `phone`, and `password`. Do not add an email field, database column, validation, or API property.

### 8.1 Password Changes and Resets

- Vendors can open **Change password** from their profile. Do not show a password-change button in the administrator header.
- Ask for the current password, new password, and confirmation. Require 8–128 characters and verify the current password on the server before updating it.
- Store only an Argon2id hash. Use `PUT /api/users/password` with `current_password` and `new_password`; the authenticated user may change only their own password.
- Keep administrator password reset as a separate admin-only action in vendor management.
