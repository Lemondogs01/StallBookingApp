const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticateToken, authorizeAdmin } = require('../middlewares/authMiddleware');

router.get('/analytics', authenticateToken, authorizeAdmin, adminController.getAnalytics);
router.get('/requests', authenticateToken, authorizeAdmin, adminController.getBookingRequests);
router.put('/requests/:bookingId', authenticateToken, authorizeAdmin, adminController.updateBookingStatus);

// Route สำหรับสร้าง Event + อัปโหลดรูปภาพ
router.post('/events', authenticateToken, authorizeAdmin, adminController.upload.single('image'), adminController.createEvent);

module.exports = router;
