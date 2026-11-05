const router = require('express').Router();
const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');
const stalls = require('../controllers/stallController');

router.use(requireAuth, requireAdmin);
router.get('/', stalls.list);
router.post('/', stalls.create);
router.put('/:id', stalls.update);
router.delete('/:id', stalls.remove);

module.exports = router;
