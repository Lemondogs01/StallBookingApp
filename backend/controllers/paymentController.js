const pool = require('../config/db');

// Vendor อัปโหลดสลิป
exports.uploadSlip = async (req, res) => {
    const { booking_id, amount } = req.body;

    if (!req.file) {
        return res.status(400).json({ message: 'Please upload a payment slip image.' });
    }

    if (!booking_id || !amount) {
        return res.status(400).json({ message: 'Missing booking_id or amount' });
    }

    const slip_url = `/uploads/slips/${req.file.filename}`;

    try {
        // 1. บันทึกข้อมูลการชำระเงินลงตาราง payments
        const [result] = await pool.query(
            'INSERT INTO payments (booking_id, amount, slip_url, status) VALUES (?, ?, ?, "pending")',
            [booking_id, amount, slip_url]
        );

        // 2. อัปเดตสถานะการจองในตาราง bookings เป็น pending
        await pool.query(
            'UPDATE bookings SET status = "pending" WHERE id = ?',
            [booking_id]
        );

        res.status(201).json({
            message: 'Slip uploaded successfully. Awaiting admin verification.',
            paymentId: result.insertId,
            slipUrl: slip_url
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Admin ดึงรายการชำระเงินทั้งหมดเพื่อตรวจสอบ
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
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Admin อนุมัติหรือปฏิเสธการชำระเงิน
exports.verifyPayment = async (req, res) => {
    const { id } = req.params;
    const { status } = req.body; // 'approved' หรือ 'rejected'

    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ message: 'Invalid status. Must be approved or rejected.' });
    }

    try {
        // 1. อัปเดตสถานะในตาราง payments
        const [result] = await pool.query('UPDATE payments SET status = ? WHERE id = ?', [status, id]);
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Payment record not found' });
        }

        // 2. ดึง booking_id ที่เกี่ยวข้อง
        const [[payment]] = await pool.query('SELECT booking_id FROM payments WHERE id = ?', [id]);

        // 3. อัปเดตสถานะในตาราง bookings ตามผลการตรวจสลิป
        const bookingStatus = status === 'approved' ? 'approved' : 'rejected';
        await pool.query('UPDATE bookings SET status = ? WHERE id = ?', [bookingStatus, payment.booking_id]);

        res.json({ message: `Payment ${status} successfully. Booking status updated.` });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};