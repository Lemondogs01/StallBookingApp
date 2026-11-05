const db = require('../db');

const FIELDS = 'stall_id AS id, code, zone, size, price_per_day, product_type, status';

async function findAll({ zone, search } = {}) {
  const where = [];
  const values = [];
  if (zone) {
    where.push('zone = ?');
    values.push(zone);
  }
  if (search) {
    where.push('(code LIKE ? OR product_type LIKE ?)');
    values.push(`%${search}%`, `%${search}%`);
  }
  const clause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const [rows] = await db.query(`SELECT ${FIELDS} FROM stalls ${clause} ORDER BY zone, code`, values);
  return rows;
}

async function findById(id) {
  const [rows] = await db.query(`SELECT ${FIELDS} FROM stalls WHERE stall_id = ?`, [id]);
  return rows[0] || null;
}

async function create(stall) {
  const [result] = await db.query(
    'INSERT INTO stalls (code, zone, size, price_per_day, product_type, status) VALUES (?, ?, ?, ?, ?, ?)',
    [stall.code, stall.zone, stall.size, stall.price_per_day, stall.product_type, stall.status]
  );
  return findById(result.insertId);
}

async function update(id, stall) {
  const [result] = await db.query(
    'UPDATE stalls SET code = ?, zone = ?, size = ?, price_per_day = ?, product_type = ?, status = ? WHERE stall_id = ?',
    [stall.code, stall.zone, stall.size, stall.price_per_day, stall.product_type, stall.status, id]
  );
  return result.affectedRows ? findById(id) : null;
}

async function remove(id) {
  const [result] = await db.query(
    `DELETE FROM stalls WHERE stall_id = ? AND NOT EXISTS (
      SELECT 1 FROM bookings WHERE bookings.stall_id = stalls.stall_id
        AND bookings.booking_date >= CURDATE() AND bookings.status IN ('pending', 'approved')
    )`, [id]
  );
  if (result.affectedRows) return 'deleted';
  return (await findById(id)) ? 'in_use' : 'not_found';
}

module.exports = { findAll, findById, create, update, remove };
