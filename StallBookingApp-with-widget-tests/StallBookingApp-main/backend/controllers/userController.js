const argon2 = require('argon2');
const User = require('../models/User');
const removeUploadedFile = require('../utils/removeUploadedFile');
const removeUploadedFileUrl = require('../utils/removeUploadedFileUrl');

const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found.' });
    res.json(user);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ message: 'Internal server error getting profile.' });
  }
};

const updateProfile = async (req, res) => {
  let profileSaved = false;
  try {
    const body = req.body ?? {};
    const currentUser = await User.findById(req.user.id);
    if (!currentUser) {
      await removeUploadedFile(req.file);
      return res.status(404).json({ message: 'User not found.' });
    }

    const profile = {};
    for (const [requestField, userField] of [
      ['shop_name', 'shop_name'],
      ['real_name', 'real_name'],
      ['phone', 'phone']
    ]) {
      if (body[requestField] !== undefined) {
        if (typeof body[requestField] !== 'string') {
          await removeUploadedFile(req.file);
          return res.status(400).json({ message: `${requestField} must be text.` });
        }
        const value = body[requestField].trim();
        if (!value) {
          await removeUploadedFile(req.file);
          return res.status(400).json({ message: `${requestField} cannot be empty.` });
        }
        profile[userField] = value;
      }
    }

    if ((profile.shop_name?.length ?? 0) > 100 || (profile.real_name?.length ?? 0) > 100 || (profile.phone?.length ?? 0) > 20) {
      await removeUploadedFile(req.file);
      return res.status(400).json({ message: 'One or more fields exceed the allowed length.' });
    }
    if (profile.phone !== undefined) {
      const phoneDigits = profile.phone.replace(/\D/g, '').length;
      if (phoneDigits < 8 || phoneDigits > 15) {
        await removeUploadedFile(req.file);
        return res.status(400).json({ message: 'Phone number must contain 8 to 15 digits.' });
      }
    }

    if (req.file) profile.profile_image = `/uploads/profiles/${req.file.filename}`;
    if (Object.keys(profile).length === 0) {
      return res.status(400).json({ message: 'Provide at least one profile field or image to update.' });
    }

    await User.updateProfile(req.user.id, profile);
    profileSaved = true;
    if (req.file && currentUser.profile_image !== profile.profile_image) {
      await removeUploadedFileUrl(currentUser.profile_image, 'profiles');
    }
    const updatedUser = await User.findById(req.user.id);
    res.json({ message: 'Profile updated successfully.', user: updatedUser });
  } catch (error) {
    if (!profileSaved) await removeUploadedFile(req.file);
    console.error('Update profile error:', error);
    res.status(500).json({ message: 'Internal server error updating profile.' });
  }
};

const changePassword = async (req, res) => {
  try {
    const currentPassword = typeof req.body?.current_password === 'string'
      ? req.body.current_password
      : '';
    const newPassword = typeof req.body?.new_password === 'string'
      ? req.body.new_password
      : '';

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Current password and new password are required.' });
    }
    if (newPassword.length < 8 || newPassword.length > 128) {
      return res.status(400).json({ message: 'New password must contain 8 to 128 characters.' });
    }

    const user = await User.findPasswordHashById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found.' });

    const matches = await argon2.verify(user.password_hash, currentPassword);
    if (!matches) {
      return res.status(401).json({ message: 'Current password is incorrect.' });
    }
    if (currentPassword === newPassword) {
      return res.status(400).json({ message: 'Choose a new password different from the current password.' });
    }

    const password_hash = await argon2.hash(newPassword, {
      type: argon2.argon2id,
      memoryCost: 2 ** 16,
      timeCost: 3
    });
    await User.updatePassword(req.user.id, password_hash);

    res.json({ message: 'Password changed successfully.' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ message: 'Internal server error changing password.' });
  }
};

module.exports = { getProfile, updateProfile, changePassword };
