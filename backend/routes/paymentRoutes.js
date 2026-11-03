const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticateToken, authorizeAdmin } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

// Vendor อัปโหลดสลิป (ต้องใช้ upload.single('slip') เพื่อรับไฟล์)
router.post('/upload', authenticateToken, upload.single('slip'), paymentController.uploadSlip);

// Admin ดึงรายการและกดยืนยัน
router.get('/', authenticateToken, authorizeAdmin, paymentController.getAllPayments);
router.put('/:id/verify', authenticateToken, authorizeAdmin, paymentController.verifyPayment);

module.exports = router;