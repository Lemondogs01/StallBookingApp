const express = require('express');
const router = express.Router();
const eventController = require('../controllers/eventController');
const { authenticateToken, authorizeAdmin } = require('../middlewares/authMiddleware');

router.get('/', authenticateToken, eventController.getAllEvents);
router.post('/', authenticateToken, authorizeAdmin, eventController.createEvent);

module.exports = router;