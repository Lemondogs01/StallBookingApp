const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const authMiddleware = require('../middlewares/authMiddleware');
const roleMiddleware = require('../middlewares/roleMiddleware');

router.use(authMiddleware, roleMiddleware('admin'));

router.get('/bookings/pending', adminController.getPendingBookings);
router.put('/bookings/:id/verify', adminController.verifyBooking);
router.get('/analytics', adminController.getAnalytics);
router.get('/users', adminController.getUsers);
router.put('/users/:id/reset-password', adminController.resetUserPassword);

module.exports = router;
