const argon2 = require('argon2');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { jwtSecret } = require('../config/jwt');

const register = async (req, res) => {
  try {
    const body = req.body ?? {};
    const username = typeof body.username === 'string' ? body.username.trim() : '';
    const password = typeof body.password === 'string' ? body.password : '';
    const shop_name = typeof body.shop_name === 'string' ? body.shop_name.trim() : '';
    const real_name = typeof body.real_name === 'string' ? body.real_name.trim() : '';
    const phone = typeof body.phone === 'string' ? body.phone.trim() : '';

    if (!username || !password || !shop_name || !real_name || !phone) {
      return res.status(400).json({ message: 'Please provide all required fields.' });
    }
    if (username.length > 50 || shop_name.length > 100 || real_name.length > 100 || phone.length > 20) {
      return res.status(400).json({ message: 'One or more fields exceed the allowed length.' });
    }
    const phoneDigits = phone.replace(/\D/g, '').length;
    if (phoneDigits < 8 || phoneDigits > 15) {
      return res.status(400).json({ message: 'Phone number must contain 8 to 15 digits.' });
    }
    if (password.length < 8 || password.length > 128) {
      return res.status(400).json({ message: 'Password must contain 8 to 128 characters.' });
    }

    const existingUser = await User.findByUsername(username);
    if (existingUser) {
      return res.status(400).json({ message: 'Username is already taken.' });
    }

    // Argon2id Hashing Strategy
    const password_hash = await argon2.hash(password, {
      type: argon2.argon2id,
      memoryCost: 2 ** 16, // 64 MB
      timeCost: 3
    });

    const userId = await User.create({
      username,
      password_hash,
      role: 'vendor',
      shop_name,
      real_name,
      phone
    });

    const user = await User.findById(userId);

    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      jwtSecret,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.status(201).json({
      message: 'Vendor registered successfully',
      token,
      user
    });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY' && error.errno === 1062) {
      return res.status(409).json({ message: 'Username is already taken.' });
    }
    console.error('Register error:', error);
    res.status(500).json({ message: 'Internal server error during registration.' });
  }
};

const login = async (req, res) => {
  try {
    const body = req.body ?? {};
    const username = typeof body.username === 'string' ? body.username.trim() : '';
    const password = typeof body.password === 'string' ? body.password : '';

    if (!username || !password) {
      return res.status(400).json({ message: 'Username and password are required.' });
    }

    const user = await User.findByUsername(username);
    if (!user) {
      return res.status(401).json({ message: 'Invalid username or password.' });
    }

    // Verify Password with Argon2
    const isMatched = await argon2.verify(user.password_hash, password);
    if (!isMatched) {
      return res.status(401).json({ message: 'Invalid username or password.' });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      jwtSecret,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    const { password_hash, ...userProfile } = user;

    res.json({
      message: 'Login successful',
      token,
      user: userProfile
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Internal server error during login.' });
  }
};

module.exports = {
  register,
  login
};
