const db = require('../db');

async function findByUsername(username) {
  const [rows] = await db.query('SELECT * FROM users WHERE username = ?', [username]);
  return rows[0] || null;
}

async function findById(id) {
  const [rows] = await db.query(
    'SELECT user_id, username, full_name, phone, email, role FROM users WHERE user_id = ?', [id]
  );
  return rows[0] || null;
}

async function createUser({ username, passwordHash, fullName }) {
  const [result] = await db.query(
    'INSERT INTO users (username, password_hash, full_name, role) VALUES (?, ?, ?, ?)',
    [username, passwordHash, fullName, 'vendor']
  );
  return result.insertId;
}

async function updateProfile(id, { fullName, phone, email }) {
  await db.query('UPDATE users SET full_name = ?, phone = ?, email = ? WHERE user_id = ?',
    [fullName, phone, email, id]);
  return findById(id);
}

module.exports = { findByUsername, findById, createUser, updateProfile };
