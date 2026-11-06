const path = require('path');
const multer = require('multer');
const pool = require('../config/db');

// Config การจัดเก็บไฟล์รูปภาพ Upload
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

exports.upload = multer({ storage });

// 1. ดึงข้อมูล Analytics สถิติภาพรวม
exports.getAnalytics = async (req, res) => {
    try {
        const [revenueResult] = await pool.query(
            "SELECT COALESCE(SUM(amount), 0) AS total_revenue FROM payments WHERE status = 'approved'"
        );

        const [bookingsResult] = await pool.query(
            "SELECT COUNT(*) AS total_bookings FROM bookings"
        );

        const [eventsResult] = await pool.query(
            "SELECT COUNT(*) AS total_events FROM events"
        );

        const [vendorsResult] = await pool.query(
            "SELECT COUNT(*) AS total_vendors FROM users WHERE role = 'vendor'"
        );

        const [pendingResult] = await pool.query(
            "SELECT COUNT(*) AS pending_requests FROM bookings WHERE status = 'pending'"
        );

        res.json({
            totalRevenue: Number(revenueResult[0]?.total_revenue || 0),
            totalBookings: Number(bookingsResult[0]?.total_bookings || 0),
            totalEvents: Number(eventsResult[0]?.total_events || 0),
            activeVendors: Number(vendorsResult[0]?.total_vendors || 0),
            pendingRequests: Number(pendingResult[0]?.pending_requests || 0),
        });
    } catch (error) {
        console.error('Get Analytics Error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// 2. ดึงรายการคำขอจองพื้นที่ (Booking Requests)
exports.getBookingRequests = async (req, res) => {
    try {
        const [requests] = await pool.query(`
            SELECT 
                b.id AS booking_id,
                u.username AS vendor_name,
                s.code AS stall_code,
                s.zone AS stall_zone,
                e.name AS event_name,
                b.status,
                b.created_at
            FROM bookings b
            JOIN users u ON b.vendor_id = u.id
            JOIN stalls s ON b.stall_id = s.id
            JOIN events e ON b.event_id = e.id
            ORDER BY b.created_at DESC
        `);

        res.json(requests);
    } catch (error) {
        console.error('Get Requests Error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// 3. อัปเดตสถานะการจอง (อนุมัติ / ปฏิเสธ)
exports.updateBookingStatus = async (req, res) => {
    const { bookingId } = req.params;
    const { status } = req.body;

    try {
        await pool.query('UPDATE bookings SET status = ? WHERE id = ?', [status, bookingId]);
        res.json({ message: `Booking ${status} successfully` });
    } catch (error) {
        console.error('Update Status Error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// 4. สร้าง Event ใหม่
exports.createEvent = async (req, res) => {
    let connection;
    try {
        const { name, title, location, price, stalls_left } = req.body;
        const eventName = name || title;
        const stallCount = Number(stalls_left);
        const stallPrice = Number(price);

        if (!eventName) {
            return res.status(400).json({ message: 'Event name is required' });
        }

        if (!Number.isInteger(stallCount) || stallCount < 0 || stallCount > 1000) {
            return res.status(400).json({ message: 'Stall count must be an integer from 0 to 1000' });
        }

        if (!Number.isFinite(stallPrice) || stallPrice < 0) {
            return res.status(400).json({ message: 'Event price must be a valid non-negative number' });
        }

        // สร้าง Full Image URL สอดคล้องกับพอร์ตที่ใช้
        const imageUrl = req.file
            ? `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`
            : null;

        const startDate = new Date().toISOString().split('T')[0];
        const endDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

        connection = await pool.getConnection();
        await connection.beginTransaction();

        const [result] = await connection.query(
            `INSERT INTO events (name, location, price, stalls_left, image_url, start_date, end_date) 
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [
                eventName,
                location || 'Chiang Rai',
                stallPrice,
                stallCount,
                imageUrl,
                startDate,
                endDate
            ]
        );

        if (stallCount > 0) {
            const stalls = Array.from({ length: stallCount }, (_, index) => [
                `E${result.insertId}-S${String(index + 1).padStart(4, '0')}`,
                'A',
                'Standard',
                stallPrice,
                'available',
                result.insertId,
            ]);

            await connection.query(
                `INSERT INTO stalls (code, zone, size, price_per_day, status, event_id)
                 VALUES ?`,
                [stalls]
            );
        }

        await connection.commit();

        res.status(201).json({
            message: 'Event created successfully',
            eventId: result.insertId,
            stallsCreated: stallCount,
            imageUrl: imageUrl
        });
    } catch (error) {
        if (connection) {
            try {
                await connection.rollback();
            } catch (rollbackError) {
                console.error('Create Event Rollback Error:', rollbackError);
            }
        }
        console.error('Create Event Error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    } finally {
        if (connection) connection.release();
    }
};
