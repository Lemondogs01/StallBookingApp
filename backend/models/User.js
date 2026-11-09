const db = require('../config/db');

class User {
  static async findByUsername(username) {
    const [rows] = await db.query('SELECT * FROM users WHERE username = ?', [username]);
    return rows[0];
  }

  static async findById(id) {
    const [rows] = await db.query('SELECT id, username, role, shop_name, real_name, phone, profile_image, created_at, updated_at FROM users WHERE id = ?', [id]);
    return rows[0];
  }

  static async findPasswordHashById(id) {
    const [rows] = await db.query('SELECT id, password_hash FROM users WHERE id = ?', [id]);
    return rows[0];
  }

  static async create({ username, password_hash, role = 'vendor', shop_name, real_name, phone, profile_image = null }) {
    const [result] = await db.query(
      'INSERT INTO users (username, password_hash, role, shop_name, real_name, phone, profile_image) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [username, password_hash, role, shop_name, real_name, phone, profile_image]
    );
    return result.insertId;
  }

  static async updateProfile(id, { shop_name, real_name, phone, profile_image }) {
    const fields = { shop_name, real_name, phone, profile_image };
    const updates = Object.entries(fields).filter(([, value]) => value !== undefined);
    if (updates.length === 0) return false;

    const sql = `UPDATE users SET ${updates.map(([field]) => `${field} = ?`).join(', ')} WHERE id = ?`;
    const params = updates.map(([, value]) => value);
    params.push(id);

    const [result] = await db.query(sql, params);
    return result.affectedRows > 0;
  }

  static async updatePassword(id, password_hash) {
    const [result] = await db.query('UPDATE users SET password_hash = ? WHERE id = ?', [password_hash, id]);
    return result.affectedRows > 0;
  }

  static async findAll(searchQuery = '') {
    let sql = "SELECT id, username, role, shop_name, real_name, phone, profile_image, created_at FROM users WHERE role = 'vendor'";
    const params = [];

    if (searchQuery) {
      sql += ' AND (username LIKE ? OR shop_name LIKE ? OR real_name LIKE ? OR phone LIKE ?)';
      const q = `%${searchQuery}%`;
      params.push(q, q, q, q);
    }

    sql += ' ORDER BY created_at DESC';

    const [rows] = await db.query(sql, params);
    return rows;
  }
}

module.exports = User;
