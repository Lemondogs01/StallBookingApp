const express = require('express');
const router = express.Router();
const eventController = require('../controllers/eventController');
const { authenticateToken, authorizeAdmin } = require('../middlewares/authMiddleware');

// Public Route: ให้ทุกคนดูรายการ Events ได้โดยไม่ต้องเช็ค Token
router.get('/', eventController.getAllEvents);

// Admin Only: สิทธิ์ Admin เท่านั้นสำหรับสร้าง Event
router.post('/', authenticateToken, authorizeAdmin, eventController.createEvent);

module.exports = router;