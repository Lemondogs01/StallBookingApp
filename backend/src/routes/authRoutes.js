const router = require('express').Router();
const auth = require('../controllers/authController');
const { requireAuth, requireAdmin } = require('../middleware/authMiddleware');

router.post('/register', auth.register);
router.post('/login', auth.login);
router.get('/profile', requireAuth, auth.profile);
router.put('/profile', requireAuth, auth.updateProfile);
router.post('/logout', requireAuth, auth.logout);
router.get('/admin-only', requireAuth, requireAdmin, (req, res) => res.json({ message: 'Welcome admin' }));
module.exports = router;
