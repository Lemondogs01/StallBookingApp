const Booking = require('../models/Booking');
const Stall = require('../models/Stall');
const { bangkokDateString, isValidDateOnly } = require('../utils/dateOnly');
const { generateBookingCode } = require('../utils/codeGenerator');

const createBooking = async (req, res) => {
  try {
    const stall_id = typeof req.body.stall_id === 'string' ? req.body.stall_id.trim() : '';
    const booking_date = req.body.booking_date;
    const user_id = req.user.id;

    if (!stall_id || !isValidDateOnly(booking_date)) {
      return res.status(400).json({ message: 'A valid stall ID and booking date are required.' });
    }
    if (booking_date < bangkokDateString()) {
      return res.status(400).json({ message: 'Bookings cannot be made for a past date.' });
    }

    const stall = await Stall.findById(stall_id);
    if (!stall) {
      return res.status(404).json({ message: 'Stall not found.' });
    }

    const existingBooking = await Booking.findActiveByStallAndDate(stall_id, booking_date);
    if (existingBooking) {
      return res.status(409).json({ message: 'This stall is already reserved for the selected date.' });
    }

    const bookingId = await Booking.create({
      booking_code: generateBookingCode(),
      user_id,
      stall_id,
      booking_date,
      price: stall.price
    });

    const newBooking = await Booking.findById(bookingId);
    res.status(201).json({ message: 'Booking created successfully.', booking: newBooking });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY' && error.errno === 1062) {
      return res.status(409).json({ message: 'This stall is already reserved for the selected date.' });
    }
    console.error('Create booking error:', error);
    res.status(500).json({ message: 'Internal server error creating booking.' });
  }
};

const getMyBookings = async (req, res) => {
  try {
    const bookings = await Booking.findByUserId(req.user.id);
    res.json(bookings);
  } catch (error) {
    console.error('Get my bookings error:', error);
    res.status(500).json({ message: 'Internal server error fetching user bookings.' });
  }
};

const cancelBooking = async (req, res) => {
  try {
    const bookingId = Number(req.params.id);
    if (!Number.isInteger(bookingId) || bookingId < 1) {
      return res.status(400).json({ message: 'A valid booking ID is required.' });
    }

    await Booking.cancelPendingOwned(bookingId, req.user.id);
    res.json({ message: 'Booking cancelled successfully.' });
  } catch (error) {
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    console.error('Cancel booking error:', error);
    res.status(500).json({ message: 'Internal server error cancelling booking.' });
  }
};

module.exports = { createBooking, getMyBookings, cancelBooking };
