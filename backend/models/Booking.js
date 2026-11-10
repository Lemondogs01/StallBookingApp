const db = require('../config/db');

const formatDate = (date) => date.toISOString().slice(0, 10);
const formatMonth = (date) => `${date.toISOString().slice(0, 7)}-01`;

class Booking {
  static async create({ booking_code, user_id, stall_id, booking_date, price }) {
    const [result] = await db.query(
      'INSERT INTO bookings (booking_code, user_id, stall_id, booking_date, price, status) VALUES (?, ?, ?, ?, ?, ?)',
      [booking_code, user_id, stall_id, booking_date, price, 'pending']
    );
    return result.insertId;
  }

  static async findById(id) {
    const sql = `
      SELECT b.*, s.category AS stall_category, p.slip_url, p.amount AS payment_amount,
             u.shop_name, u.real_name, u.phone
      FROM bookings b
      JOIN stalls s ON b.stall_id = s.id
      JOIN users u ON b.user_id = u.id
      LEFT JOIN payments p ON b.id = p.booking_id
      WHERE b.id = ?
    `;
    const [rows] = await db.query(sql, [id]);
    return rows[0];
  }

  static async findActiveByStallAndDate(stall_id, booking_date) {
    const sql = `
      SELECT * FROM bookings
      WHERE stall_id = ? AND booking_date = ? AND status IN ('pending', 'approved')
      LIMIT 1
    `;
    const [rows] = await db.query(sql, [stall_id, booking_date]);
    return rows[0];
  }

  static async findByUserId(user_id) {
    const sql = `
      SELECT
        b.id,
        b.booking_code,
        b.stall_id,
        s.category,
        b.booking_date,
        b.price,
        b.status,
        b.created_at,
        p.slip_url,
        p.amount AS paid_amount,
        p.updated_at AS payment_date
      FROM bookings b
      JOIN stalls s ON b.stall_id = s.id
      LEFT JOIN payments p ON b.id = p.booking_id
      WHERE b.user_id = ?
      ORDER BY b.created_at DESC
    `;
    const [rows] = await db.query(sql, [user_id]);
    return rows;
  }

  static async findPending() {
    const sql = `
      SELECT
        b.id,
        b.booking_code,
        b.stall_id,
        s.category,
        b.booking_date,
        b.price,
        b.status,
        b.created_at,
        u.id AS user_id,
        u.shop_name,
        u.real_name,
        u.phone,
        p.slip_url,
        p.amount AS paid_amount
      FROM bookings b
      JOIN stalls s ON b.stall_id = s.id
      JOIN users u ON b.user_id = u.id
      LEFT JOIN payments p ON b.id = p.booking_id
      WHERE b.status = 'pending'
      ORDER BY b.created_at ASC
    `;
    const [rows] = await db.query(sql);
    return rows;
  }

  static async cancelPendingOwned(id, userId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [bookingRows] = await connection.query(
        'SELECT user_id, status FROM bookings WHERE id = ? FOR UPDATE',
        [id]
      );
      const booking = bookingRows[0];
      if (!booking) {
        const error = new Error('Booking not found.');
        error.status = 404;
        throw error;
      }
      if (Number(booking.user_id) !== Number(userId)) {
        const error = new Error('You are not allowed to cancel this booking.');
        error.status = 403;
        throw error;
      }
      if (booking.status !== 'pending') {
        const error = new Error('Only pending bookings can be cancelled.');
        error.status = 409;
        throw error;
      }

      const [payments] = await connection.query(
        'SELECT id FROM payments WHERE booking_id = ? LIMIT 1',
        [id]
      );
      if (payments.length > 0) {
        const error = new Error('A payment slip has been submitted. Contact the market administrator to cancel.');
        error.status = 409;
        throw error;
      }

      await connection.query(
        "UPDATE bookings SET status = 'cancelled' WHERE id = ? AND status = 'pending'",
        [id]
      );
      await connection.commit();
      return true;
    } catch (error) {
      try {
        await connection.rollback();
      } catch (rollbackError) {
        console.error('Booking cancellation rollback failed:', rollbackError.message);
      }
      throw error;
    } finally {
      connection.release();
    }
  }

  static async updatePendingStatus(id, status, approved_by_user_id = null) {
    const [result] = await db.query(
      `UPDATE bookings
       SET status = ?,
           approved_by_user_id = ?,
           approved_at = IF(? = 'approved', CURRENT_TIMESTAMP, NULL)
       WHERE id = ? AND status = 'pending'`,
      [status, status === 'approved' ? approved_by_user_id : null, status, id]
    );
    return result.affectedRows > 0;
  }

  static async getAnalytics(asOfDate) {
    const [totalRows] = await db.query(
      "SELECT COALESCE(SUM(price), 0) AS revenue FROM bookings WHERE status = 'approved'"
    );
    const [selectedDayRows] = await db.query(
      `SELECT COALESCE(SUM(price), 0) AS revenue
       FROM bookings WHERE status = 'approved' AND booking_date = ?`,
      [asOfDate]
    );
    const [categoryRows] = await db.query(
      `SELECT s.category, COALESCE(SUM(b.price), 0) AS revenue
       FROM bookings b
       JOIN stalls s ON b.stall_id = s.id
       WHERE b.status = 'approved' AND b.booking_date = ?
       GROUP BY s.category`,
      [asOfDate]
    );

    const selected = new Date(`${asOfDate}T00:00:00.000Z`);
    const year = selected.getUTCFullYear();
    const monthIndex = selected.getUTCMonth();
    const day = selected.getUTCDate();
    const firstMonth = new Date(Date.UTC(year, monthIndex - 11, 1));
    const nextMonth = new Date(Date.UTC(year, monthIndex + 1, 1));
    const [monthlyRows] = await db.query(
      `SELECT DATE_FORMAT(booking_date, '%Y-%m-01') AS month,
              COALESCE(SUM(price), 0) AS revenue
       FROM bookings
       WHERE status = 'approved' AND booking_date >= ? AND booking_date < ?
       GROUP BY DATE_FORMAT(booking_date, '%Y-%m-01')
       ORDER BY month ASC`,
      [formatDate(firstMonth), formatDate(nextMonth)]
    );

    // Keep the selected day in the center of the seven-day dashboard trend.
    const firstDay = new Date(Date.UTC(year, monthIndex, day - 3));
    const lastDay = new Date(Date.UTC(year, monthIndex, day + 3));
    const [dailyRows] = await db.query(
      `SELECT booking_date AS date, COALESCE(SUM(price), 0) AS revenue
       FROM bookings
       WHERE status = 'approved' AND booking_date BETWEEN ? AND ?
       GROUP BY booking_date
       ORDER BY booking_date ASC`,
      [formatDate(firstDay), formatDate(lastDay)]
    );

    const categoryRevenue = { food: 0, fashion: 0, general: 0 };
    for (const row of categoryRows) {
      categoryRevenue[row.category] = Number(row.revenue) || 0;
    }

    const dailyRevenueByDate = new Map(
      dailyRows.map((row) => [String(row.date).slice(0, 10), Number(row.revenue) || 0])
    );
    const dailyBreakdown = Array.from({ length: 7 }, (_, index) => {
      const date = new Date(Date.UTC(year, monthIndex, day - 3 + index));
      const dateString = formatDate(date);
      return { date: dateString, revenue: dailyRevenueByDate.get(dateString) || 0 };
    });

    const monthlyRevenueByMonth = new Map(
      monthlyRows.map((row) => [String(row.month).slice(0, 7), Number(row.revenue) || 0])
    );
    const monthlyBreakdown = Array.from({ length: 12 }, (_, index) => {
      const date = new Date(Date.UTC(year, monthIndex - 11 + index, 1));
      const monthString = formatMonth(date);
      return {
        month: monthString,
        revenue: monthlyRevenueByMonth.get(monthString.slice(0, 7)) || 0
      };
    });

    return {
      asOfDate,
      totalRevenue: Number(totalRows[0].revenue) || 0,
      selectedDateRevenue: Number(selectedDayRows[0].revenue) || 0,
      categoryRevenue,
      dailyBreakdown,
      monthlyBreakdown
    };
  }
}

module.exports = Booking;
