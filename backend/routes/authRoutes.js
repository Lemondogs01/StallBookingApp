const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// นำ Middleware ตรวจสิทธิ์ของคุณมาใช้งาน
const { authenticateToken, authorizeAdmin } = require('../middlewares/authMiddleware');

// คนทั่วไปสมัครสมาชิก (ได้ role vendor เสมอ)
router.post('/register', authController.register);
// ล็อกอิน
router.post('/login', authController.login);
// Admin สร้าง Admin ใหม่ (ต้องแนบ Token และผู้เรียกต้องเป็น Admin)
router.post('/create-admin', authenticateToken, authorizeAdmin, authController.createAdmin);

module.exports = router;