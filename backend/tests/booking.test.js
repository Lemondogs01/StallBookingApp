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

    beforeAll(() => {
        process.env.JWT_SECRET = 'test_secret';
        vendorToken = jwt.sign({ id: 2, username: 'vendor_test', role: 'vendor' }, 'test_secret');
        adminToken = jwt.sign({ id: 1, username: 'admin', role: 'admin' }, 'test_secret');
    });

    afterAll(async () => {
        if (testBookingId) {
            await pool.query('DELETE FROM bookings WHERE id = ?', [testBookingId]);
        }
        await pool.end();
    });

    test('POST /api/bookings - Vendor ควรส่งคำขอจองแผงได้ (201)', async () => {
        const res = await request(app)
            .post('/api/bookings')
            .set('Authorization', `Bearer ${vendorToken}`)
            .send({
                stall_id: 1,
                event_id: 1,
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