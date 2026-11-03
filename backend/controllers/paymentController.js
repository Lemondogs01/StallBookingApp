const pool = require('../config/db');

// 1. Vendor อัปโหลดสลิป
exports.uploadSlip = async (req, res) => {
    const { booking_id, amount } = req.body;
    const vendorId = req.user.id;

    if (!req.file) {
        return res.status(400).json({ message: 'Please upload a payment slip image.' });
    }

    const slip_url = `/uploads/slips/${req.file.filename}`;

    try {
        const [result] = await pool.query(
            'INSERT INTO payments (booking_id, amount, slip_url, status) VALUES (?, ?, ?, "pending")',
            [booking_id, amount, slip_url]
        );

        await pool.query(
            'UPDATE bookings SET status = "pending" WHERE id = ?',
            [booking_id]
        );

        res.status(201).json({
            message: 'Slip uploaded successfully',
            paymentId: result.insertId,
            slipUrl: slip_url
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// 2. Admin ดึงรายการชำระเงินทั้งหมดเพื่อตรวจสอบ (เพิ่มส่วนนี้)
exports.getAllPayments = async (req, res) => {
    try {
        const [payments] = await pool.query(
            `SELECT p.*, b.vendor_id, b.stall_id, b.event_id 
             FROM payments p 
             JOIN bookings b ON p.booking_id = b.id 
             ORDER BY p.uploaded_at DESC`
        );
        res.json(payments);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// 3. Admin อนุมัติหรือปฏิเสธการชำระเงิน (เพิ่มส่วนนี้)
exports.verifyPayment = async (req, res) => {
    const { id } = req.params;
    const { status } = req.body; // 'approved' หรือ 'rejected'

    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ message: 'Invalid status. Must be approved or rejected.' });
    }

    try {
        const [result] = await pool.query('UPDATE payments SET status = ? WHERE id = ?', [status, id]);
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Payment record not found' });
        }

        const [[payment]] = await pool.query('SELECT booking_id FROM payments WHERE id = ?', [id]);
        const bookingStatus = status === 'approved' ? 'approved' : 'rejected';

        await pool.query('UPDATE bookings SET status = ? WHERE id = ?', [bookingStatus, payment.booking_id]);

        res.json({ message: `Payment ${status} successfully. Booking status updated.` });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};