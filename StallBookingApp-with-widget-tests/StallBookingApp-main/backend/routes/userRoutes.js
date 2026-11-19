const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middlewares/authMiddleware');
const createUploadMiddleware = require('../middlewares/uploadMiddleware');
const profileUpload = createUploadMiddleware('profiles');

router.use(authMiddleware);

router.get('/profile', userController.getProfile);
router.put('/profile', profileUpload.single('profile_image'), userController.updateProfile);
router.put('/password', userController.changePassword);

module.exports = router;
