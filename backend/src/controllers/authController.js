const argon2 = require('argon2');
const jwt = require('jsonwebtoken');
const users = require('../models/userModel');
const { revokeToken } = require('../middleware/authMiddleware');

function safeUser(user) {
  const { password_hash, ...safe } = user;
  return safe;
}

async function register(req, res) {
  try {
    const { username, password, full_name } = req.body;
    if (typeof username !== 'string' || !username.trim() ||
        typeof full_name !== 'string' || !full_name.trim() ||
        typeof password !== 'string' || password.length < 8) {
      return res.status(400).json({ message: 'Username, full name and password (8+ chars) required' });
    }
    if (await users.findByUsername(username.trim())) {
      return res.status(409).json({ message: 'Username already exists' });
    }
    const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
    const id = await users.createUser({ username: username.trim(), passwordHash, fullName: full_name.trim() });
    return res.status(201).json({ message: 'Registered', user: { user_id: id, username: username.trim(), full_name: full_name.trim(), role: 'vendor' } });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ message: 'Username already exists' });
    console.error(err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function login(req, res) {
  try {
    const { username, password } = req.body;
    if (typeof username !== 'string' || typeof password !== 'string') {
      return res.status(400).json({ message: 'Username and password required' });
    }
    const user = await users.findByUsername(username);
    if (!user || !(await argon2.verify(user.password_hash, password))) {
      return res.status(401).json({ message: 'Wrong username or password' });
    }
    const token = jwt.sign({ user_id: user.user_id, role: user.role }, process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '1h' });
    return res.json({ token, user: safeUser(user) });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function profile(req, res) {
  try {
    const user = await users.findById(req.user.user_id);
    if (!user) return res.status(404).json({ message: 'User not found' });
    return res.json({ user: safeUser(user) });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function updateProfile(req, res) {
  try {
    const current = await users.findById(req.user.user_id);
    if (!current) return res.status(404).json({ message: 'User not found' });
    const fullName = req.body.full_name === undefined ? current.full_name : req.body.full_name;
    const phone = req.body.phone === undefined ? current.phone : req.body.phone;
    const email = req.body.email === undefined ? current.email : req.body.email;
    if (typeof fullName !== 'string' || !fullName.trim() ||
        (phone !== null && typeof phone !== 'string') ||
        (email !== null && typeof email !== 'string')) {
      return res.status(400).json({ message: 'Invalid profile data' });
    }
    const user = await users.updateProfile(req.user.user_id, { fullName: fullName.trim(), phone, email });
    return res.json({ user: safeUser(user) });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Server error' });
  }
}

function logout(req, res) {
  revokeToken(req.token);
  return res.json({ message: 'Logged out' });
}

module.exports = { register, login, profile, updateProfile, logout };
