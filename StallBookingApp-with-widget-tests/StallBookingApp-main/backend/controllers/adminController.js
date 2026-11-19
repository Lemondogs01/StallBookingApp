const argon2 = require('argon2');
const Booking = require('../models/Booking');
const User = require('../models/User');
const { bangkokDateString, isValidDateOnly } = require('../utils/dateOnly');

const getPendingBookings = async (req, res) => {
  try {
    const pendingBookings = await Booking.findPending();
    res.json(pendingBookings);
  } catch (error) {
    console.error('Get pending bookings error:', error);
    res.status(500).json({ message: 'Internal server error getting pending bookings.' });
  }
};

const verifyBooking = async (req, res) => {
  try {
    const bookingId = Number(req.params.id);
    const { status } = req.body; // 'approved' or 'rejected'

    if (!Number.isInteger(bookingId) || bookingId < 1) {
      return res.status(400).json({ message: 'A valid booking ID is required.' });
    }

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status. Status must be "approved" or "rejected".' });
    }

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ message: 'Booking not found.' });
    }

    if (booking.status !== 'pending') {
      return res.status(409).json({ message: 'Only pending bookings can be reviewed.' });
    }

    if (status === 'approved') {
      if (!booking.slip_url) {
        return res.status(409).json({ message: 'A payment slip must be submitted before approval.' });
      }
      const paidAmount = Number(booking.payment_amount);
      const bookingPrice = Number(booking.price);
      if (!Number.isFinite(paidAmount) || !Number.isFinite(bookingPrice) || Math.abs(paidAmount - bookingPrice) > 0.01) {
        return res.status(409).json({ message: 'The submitted payment amount does not match the booking price.' });
      }
    }

    const updated = await Booking.updatePendingStatus(bookingId, status);
    if (!updated) {
      return res.status(409).json({ message: 'The booking changed before it could be reviewed. Refresh and try again.' });
    }

    res.json({
      message: `Booking has been ${status}.`,
      bookingId,
      status
    });
  } catch (error) {
    console.error('Verify booking error:', error);
    res.status(500).json({ message: 'Internal server error verifying booking.' });
  }
};

const getAnalytics = async (req, res) => {
  try {
    const date = req.query.date || bangkokDateString();
    if (!isValidDateOnly(date)) {
      return res.status(400).json({ message: 'A valid date in YYYY-MM-DD format is required.' });
    }
    const analytics = await Booking.getAnalytics(date);
    res.json(analytics);
  } catch (error) {
    console.error('Get analytics error:', error);
    res.status(500).json({ message: 'Internal server error fetching analytics.' });
  }
};

const getUsers = async (req, res) => {
  try {
    const { query } = req.query;
    const users = await User.findAll(query || '');
    res.json(users);
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ message: 'Internal server error fetching vendor users.' });
  }
};

const resetUserPassword = async (req, res) => {
  try {
    const userId = Number(req.params.id);
    if (!Number.isInteger(userId) || userId < 1) {
      return res.status(400).json({ message: 'A valid user ID is required.' });
    }
    const newPassword = req.body.password || '123456';

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }
    if (user.role !== 'vendor') {
      return res.status(400).json({ message: 'Only vendor passwords can be reset from user management.' });
    }

    const password_hash = await argon2.hash(newPassword, {
      type: argon2.argon2id,
      memoryCost: 2 ** 16,
      timeCost: 3
    });

    await User.updatePassword(userId, password_hash);

    res.json({
      message: `Password for user ${user.username} has been reset to default.`
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ message: 'Internal server error resetting password.' });
  }
};

module.exports = {
  getPendingBookings,
  verifyBooking,
  getAnalytics,
  getUsers,
  resetUserPassword
};
