const express = require('express');
const router = express.Router();
const stallController = require('../controllers/stallController');
const { authenticateToken, authorizeAdmin } = require('../middlewares/authMiddleware');

router.get('/', authenticateToken, stallController.getAllStalls);
router.post('/', authenticateToken, authorizeAdmin, stallController.createStall);
router.put('/:id', authenticateToken, authorizeAdmin, stallController.updateStall);
router.delete('/:id', authenticateToken, authorizeAdmin, stallController.deleteStall);

module.exports = router;