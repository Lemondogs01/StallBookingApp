const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const authMiddleware = require('../middlewares/authMiddleware');
const roleMiddleware = require('../middlewares/roleMiddleware');

router.use(authMiddleware);

router.post('/', roleMiddleware('vendor'), bookingController.createBooking);
router.get('/my', roleMiddleware('vendor'), bookingController.getMyBookings);
router.put('/:id/cancel', roleMiddleware('vendor'), bookingController.cancelBooking);

module.exports = router;
