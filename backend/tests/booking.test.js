const request = require('supertest');
const express = require('express');
const bookingRoutes = require('../routes/bookingRoutes');
const pool = require('../config/db');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

app.use('/api/bookings', (req, res, next) => {
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
}, bookingRoutes);

describe('Booking Controller Unit Tests', () => {
    let vendorToken;
    let adminToken;
    let testBookingId;
    let testEventId;
    let testStallId;
    let testVendorId;

    beforeAll(async () => {
        process.env.JWT_SECRET = 'test_secret';
        const suffix = Date.now();
        const [vendorResult] = await pool.query(
            'INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)',
            [`booking_test_${suffix}`, 'test-hash', 'vendor']
        );
        testVendorId = vendorResult.insertId;
        const [eventResult] = await pool.query(
            'INSERT INTO events (name, price, stalls_left, start_date, end_date) VALUES (?, ?, ?, ?, ?)',
            [`Booking test ${suffix}`, 150, 1, '2099-12-30', '2099-12-31']
        );
        testEventId = eventResult.insertId;
        const [stallResult] = await pool.query(
            'INSERT INTO stalls (code, zone, size, price_per_day, status) VALUES (?, ?, ?, ?, ?)',
            [`B${suffix}`, 'Test', '2x2', 150, 'available']
        );
        testStallId = stallResult.insertId;

        vendorToken = jwt.sign({ id: testVendorId, username: `booking_test_${suffix}`, role: 'vendor' }, 'test_secret');
        adminToken = jwt.sign({ id: 1, username: 'admin', role: 'admin' }, 'test_secret');
    });

    afterAll(async () => {
        try {
            if (testBookingId) {
                await pool.query('DELETE FROM bookings WHERE id = ?', [testBookingId]);
            }
            if (testVendorId && testStallId && testEventId) {
                await pool.query(
                    'DELETE FROM bookings WHERE vendor_id = ? AND stall_id = ? AND event_id = ?',
                    [testVendorId, testStallId, testEventId]
                );
            }
            if (testStallId) await pool.query('DELETE FROM stalls WHERE id = ?', [testStallId]);
            if (testEventId) await pool.query('DELETE FROM events WHERE id = ?', [testEventId]);
            if (testVendorId) await pool.query('DELETE FROM users WHERE id = ?', [testVendorId]);
        } finally {
            await pool.end();
        }
    });

    test('POST /api/bookings - Vendor ควรส่งคำขอจองแผงได้ (201)', async () => {
        const res = await request(app)
            .post('/api/bookings')
            .set('Authorization', `Bearer ${vendorToken}`)
            .send({
                stall_id: testStallId,
                event_id: testEventId,
                booking_date: '2026-12-01',
                product_type: 'Clothing'
            });

        expect(res.statusCode).toEqual(201);
        expect(res.body).toHaveProperty('bookingId');
        testBookingId = res.body.bookingId;
    });

    test('PUT /api/bookings/:id/status - Admin ควรอบุมัติคำขอจองได้ (200)', async () => {
        const res = await request(app)
            .put(`/api/bookings/${testBookingId}/status`)
            .set('Authorization', `Bearer ${adminToken}`)
            .send({ status: 'approved' });

        expect(res.statusCode).toEqual(200);
        expect(res.body.message).toContain('approved');
    });
});
