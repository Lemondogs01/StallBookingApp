const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const paymentController = require('../controllers/paymentController');
const { authenticateToken, authorizeAdmin } = require('../middlewares/authMiddleware');

// 1. ตั้งค่า Storage ของ Multer
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/slips/'); // โฟลเดอร์ปลายทาง
    },
    filename: function (req, file, cb) {
        // 2. ดึง vendor_id จาก Token ที่ถูกถอดรหัสแล้ว
        const vendorId = req.user.id;

        // สร้างชื่อไฟล์: slip_vendor_2_1700000000000.jpg
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname);
        cb(null, `slip_vendor_${vendorId}_${uniqueSuffix}${ext}`);
    }
});

const upload = multer({ storage: storage });

// 3. ใส่ authenticateToken ไว้หน้าสุด เพื่อให้ req.user พร้อมใช้งานใน Multer
router.post(
    '/upload',
    authenticateToken,
    upload.single('slip'),
    paymentController.uploadSlip
);

router.get('/', authenticateToken, authorizeAdmin, paymentController.getAllPayments);
router.put('/:id/verify', authenticateToken, authorizeAdmin, paymentController.verifyPayment);

module.exports = router;