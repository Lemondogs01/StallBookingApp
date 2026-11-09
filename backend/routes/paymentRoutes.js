const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const authMiddleware = require('../middlewares/authMiddleware');
const roleMiddleware = require('../middlewares/roleMiddleware');
const createUploadMiddleware = require('../middlewares/uploadMiddleware');
const slipUpload = createUploadMiddleware('slips');

router.use(authMiddleware);

router.post('/', roleMiddleware('vendor'), slipUpload.single('slip'), paymentController.createPayment);
router.put('/:bookingId/slip', roleMiddleware('vendor'), slipUpload.single('slip'), paymentController.replacePaymentSlip);

module.exports = router;
