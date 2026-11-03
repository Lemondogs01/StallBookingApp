const pool = require('../config/db');

exports.createBooking = async (req, res) => {
    const { stall_id, event_id, booking_date, product_type } = req.body;
    const vendor_id = req.user.id;

    if (!stall_id || !event_id || !booking_date) {
        return res.status(400).json({ message: 'Missing required booking fields' });
    }

    try {
        const [existing] = await pool.query(
            'SELECT * FROM bookings WHERE stall_id = ? AND event_id = ? AND booking_date = ? AND status IN ("pending", "approved")',
            [stall_id, event_id, booking_date]
        );

        if (existing.length > 0) {
            return res.status(400).json({ message: 'Stall is already booked for this date.' });
        }

        const [result] = await pool.query(
            'INSERT INTO bookings (vendor_id, stall_id, event_id, booking_date, product_type, status) VALUES (?, ?, ?, ?, ?, "pending")',
            [vendor_id, stall_id, event_id, booking_date, product_type]
        );

        res.status(201).json({ message: 'Booking requested successfully', bookingId: result.insertId });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

exports.updateBookingStatus = async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;

    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ message: 'Invalid status' });
    }

    try {
        const [result] = await pool.query('UPDATE bookings SET status = ? WHERE id = ?', [status, id]);
        if (result.affectedRows === 0) return res.status(404).json({ message: 'Booking not found' });
        res.json({ message: `Booking status updated to ${status}` });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};