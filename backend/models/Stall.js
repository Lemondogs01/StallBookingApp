const db = require('../config/db');

class Stall {
  static async findAll() {
    const [rows] = await db.query('SELECT * FROM stalls ORDER BY id ASC');
    return rows;
  }

  static async findById(id) {
    const [rows] = await db.query('SELECT * FROM stalls WHERE id = ?', [id]);
    return rows[0];
  }

  static async getStallsAvailabilityByDate(dateStr) {
    const query = `
      SELECT 
        s.id AS stall_id,
        s.category,
        s.price,
        b.id AS booking_id,
        b.status AS booking_status,
        b.booking_code,
        b.booking_date,
        b.price AS booking_price,
        u.shop_name,
        u.real_name,
        u.phone,
        p.slip_url,
        p.amount AS paid_amount
      FROM stalls s
      LEFT JOIN bookings b ON s.id = b.stall_id 
        AND b.booking_date = ? 
        AND b.status IN ('pending', 'approved')
      LEFT JOIN users u ON b.user_id = u.id
      LEFT JOIN payments p ON b.id = p.booking_id
      ORDER BY s.id ASC
    `;

    const [rows] = await db.query(query, [dateStr]);
    
    return rows.map(row => {
      let status = 'available';
      if (row.booking_status === 'pending') {
        status = 'pending';
      } else if (row.booking_status === 'approved') {
        status = 'approved';
      }

      return {
        id: row.stall_id,
        category: row.category,
        price: parseFloat(row.price),
        status: status,
        booking: row.booking_id ? {
          id: row.booking_id,
          status: row.booking_status,
          bookingCode: row.booking_code,
          bookingDate: row.booking_date,
          price: row.booking_price == null ? null : parseFloat(row.booking_price),
          shopName: row.shop_name,
          vendorName: row.real_name,
          vendorPhone: row.phone,
          slipUrl: row.slip_url,
          paidAmount: row.paid_amount == null ? null : parseFloat(row.paid_amount)
        } : null
      };
    });
  }
}

module.exports = Stall;
