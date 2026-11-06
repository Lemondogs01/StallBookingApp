const request = require('supertest');
const express = require('express');
const path = require('path');
const fs = require('fs');
const paymentRoutes = require('../routes/paymentRoutes');
const pool = require('../config/db');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Mock Auth Middleware สำหรับการทดสอบ
app.use('/api/payments', (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (token) {
        try {
            req.user = jwt.verify(token, process.env.JWT_SECRET || 'test_secret');
        } catch (err) {
            return res.status(403).json({ message: 'Invalid token' });
        }
    }
    next();
}, paymentRoutes);

describe('Payment Module Unit Tests (Vendor Slip Filename)', () => {
    let vendorToken;
    let adminToken;
    let testBookingId;
    let testPaymentId;
    let testEventId;
    let testStallId;
    let testVendorId;
    let uploadedSlipPath;
    const dummyImagePath = path.join(__dirname, 'dummy_slip.jpg');
    const uploadsDir = path.join(__dirname, '../uploads/slips');

    beforeAll(async () => {
        process.env.JWT_SECRET = 'test_secret';
        const suffix = Date.now();
        const [vendorResult] = await pool.query(
            'INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)',
            [`payment_test_${suffix}`, 'test-hash', 'vendor']
        );
        testVendorId = vendorResult.insertId;
        vendorToken = jwt.sign({ id: testVendorId, username: `payment_test_${suffix}`, role: 'vendor' }, 'test_secret');
        adminToken = jwt.sign({ id: 1, username: 'admin', role: 'admin' }, 'test_secret');

        if (!fs.existsSync(uploadsDir)) {
            fs.mkdirSync(uploadsDir, { recursive: true });
        }

        fs.writeFileSync(dummyImagePath, 'fake image content');

        const [eventResult] = await pool.query(
            'INSERT INTO events (name, price, stalls_left, start_date, end_date) VALUES (?, ?, ?, ?, ?)',
            [`Payment test ${suffix}`, 500, 1, '2099-12-30', '2099-12-31']
        );
        testEventId = eventResult.insertId;
        const [stallResult] = await pool.query(
            'INSERT INTO stalls (code, zone, size, price_per_day, status) VALUES (?, ?, ?, ?, ?)',
            [`P${suffix}`, 'Test', '2x2', 500, 'available']
        );
        testStallId = stallResult.insertId;

        // สร้าง Booking เทียมใหม่
        const [result] = await pool.query(
            'INSERT INTO bookings (vendor_id, stall_id, event_id, booking_date, product_type, status) VALUES (?, ?, ?, "2099-12-31", "Food", "pending")',
            [testVendorId, testStallId, testEventId]
        );
        testBookingId = result.insertId;
    });

    afterAll(async () => {
        try {
            // Clean by fixture relationships as well as IDs in case a test failed before recording a response ID.
            if (testBookingId) {
                await pool.query('DELETE FROM payments WHERE booking_id = ?', [testBookingId]);
                await pool.query('DELETE FROM bookings WHERE id = ?', [testBookingId]);
            }
            if (testVendorId && testStallId && testEventId) {
                await pool.query(
                    'DELETE p FROM payments p JOIN bookings b ON p.booking_id = b.id WHERE b.vendor_id = ? AND b.stall_id = ? AND b.event_id = ?',
                    [testVendorId, testStallId, testEventId]
                );
                await pool.query(
                    'DELETE FROM bookings WHERE vendor_id = ? AND stall_id = ? AND event_id = ?',
                    [testVendorId, testStallId, testEventId]
                );
            }
            if (testPaymentId) await pool.query('DELETE FROM payments WHERE id = ?', [testPaymentId]);
            if (testStallId) await pool.query('DELETE FROM stalls WHERE id = ?', [testStallId]);
            if (testEventId) await pool.query('DELETE FROM events WHERE id = ?', [testEventId]);
            if (testVendorId) await pool.query('DELETE FROM users WHERE id = ?', [testVendorId]);
        } finally {
            if (fs.existsSync(dummyImagePath)) {
                fs.unlinkSync(dummyImagePath);
            }
            if (uploadedSlipPath && fs.existsSync(uploadedSlipPath)) {
                fs.unlinkSync(uploadedSlipPath);
            }
            await pool.end();
        }
    });

    test('POST /api/payments/upload - Vendor ควรแนบสลิปและได้ชื่อไฟล์ที่มี vendor_id ฝังอยู่ (201)', async () => {
        const res = await request(app)
            .post('/api/payments/upload')
            .set('Authorization', `Bearer ${vendorToken}`)
            .field('booking_id', testBookingId)
            .field('amount', '500.00')
            .attach('slip', dummyImagePath);

        expect(res.statusCode).toEqual(201);
        expect(res.body).toHaveProperty('paymentId');
        expect(res.body.slipUrl).toContain(`slip_vendor_${testVendorId}_`);

        testPaymentId = res.body.paymentId;
        uploadedSlipPath = path.join(__dirname, '..', res.body.slipUrl);
    });

    test('GET /api/payments - Admin ควรดึงรายการชำระเงินทั้งหมดได้ (200)', async () => {
        const res = await request(app)
            .get('/api/payments')
            .set('Authorization', `Bearer ${adminToken}`);

        expect(res.statusCode).toEqual(200);
        expect(Array.isArray(res.body)).toBe(true);
    });

    test('PUT /api/payments/:id/verify - Admin ควรอนุมัติสลิปและอัปเดตสถานะการจองได้ (200)', async () => {
        const res = await request(app)
            .put(`/api/payments/${testPaymentId}/verify`)
            .set('Authorization', `Bearer ${adminToken}`)
            .send({ status: 'approved' });

        expect(res.statusCode).toEqual(200);
        expect(res.body.message).toContain('approved');
    });
});
