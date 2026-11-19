const db = require('../config/db');

class Payment {
  static async createForPendingBooking({ booking_id, user_id, amount, slip_url }) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [bookingRows] = await connection.query(
        'SELECT user_id, price, status FROM bookings WHERE id = ? FOR UPDATE',
        [booking_id]
      );
      const booking = bookingRows[0];
      if (!booking) {
        const error = new Error('Booking not found.');
        error.status = 404;
        throw error;
      }
      if (Number(booking.user_id) !== Number(user_id)) {
        const error = new Error('You are not allowed to submit payment for this booking.');
        error.status = 403;
        throw error;
      }
      if (booking.status !== 'pending') {
        const error = new Error('Payment can only be submitted for a pending booking.');
        error.status = 409;
        throw error;
      }

      const bookingAmount = Number(booking.price);
      if (!Number.isFinite(bookingAmount) || Math.abs(Number(amount) - bookingAmount) > 0.01) {
        const error = new Error('The payment amount must match the stall price.');
        error.status = 400;
        throw error;
      }

      const [existingPayments] = await connection.query(
        'SELECT id FROM payments WHERE booking_id = ? LIMIT 1',
        [booking_id]
      );
      if (existingPayments.length > 0) {
        const error = new Error('A payment slip has already been submitted for this booking.');
        error.status = 409;
        throw error;
      }

      const [result] = await connection.query(
        'INSERT INTO payments (booking_id, amount, slip_url) VALUES (?, ?, ?)',
        [booking_id, bookingAmount, slip_url]
      );
      await connection.commit();
      return { id: result.insertId, amount: bookingAmount };
    } catch (error) {
      try {
        await connection.rollback();
      } catch (rollbackError) {
        console.error('Payment transaction rollback failed:', rollbackError.message);
      }
      throw error;
    } finally {
      connection.release();
    }
  }

  static async replaceSlipForPendingBooking({ booking_id, user_id, slip_url }) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();
      const [bookingRows] = await connection.query(
        'SELECT user_id, status FROM bookings WHERE id = ? FOR UPDATE',
        [booking_id]
      );
      const booking = bookingRows[0];
      if (!booking) {
        const error = new Error('Booking not found.');
        error.status = 404;
        throw error;
      }
      if (Number(booking.user_id) !== Number(user_id)) {
        const error = new Error('You are not allowed to edit this payment slip.');
        error.status = 403;
        throw error;
      }
      if (booking.status !== 'pending') {
        const error = new Error('A payment slip can only be changed while the booking is pending.');
        error.status = 409;
        throw error;
      }

      const [paymentRows] = await connection.query(
        'SELECT id, slip_url FROM payments WHERE booking_id = ? FOR UPDATE',
        [booking_id]
      );
      const payment = paymentRows[0];
      if (!payment) {
        const error = new Error('No payment slip exists for this booking.');
        error.status = 404;
        throw error;
      }

      await connection.query(
        'UPDATE payments SET slip_url = ? WHERE id = ?',
        [slip_url, payment.id]
      );
      await connection.commit();
      return { old_slip_url: payment.slip_url };
    } catch (error) {
      try {
        await connection.rollback();
      } catch (rollbackError) {
        console.error('Payment slip replacement rollback failed:', rollbackError.message);
      }
      throw error;
    } finally {
      connection.release();
    }
  }
}

module.exports = Payment;
