const express = require('express');
const router = express.Router();
const stallController = require('../controllers/stallController');
const authMiddleware = require('../middlewares/authMiddleware');

router.use(authMiddleware);

router.get('/status', stallController.getStallsStatus);

module.exports = router;
