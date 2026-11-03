const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { authenticateToken, authorizeAdmin } = require('../middlewares/authMiddleware');

router.post('/', authenticateToken, bookingController.createBooking);
router.put('/:id/status', authenticateToken, authorizeAdmin, bookingController.updateBookingStatus);

module.exports = router;