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

describe('Payment Module Unit Tests', () => {
    let vendorToken;
    let adminToken;
    let testBookingId;
    let testPaymentId;
    const dummyImagePath = path.join(__dirname, 'dummy_slip.jpg');
    const uploadsDir = path.join(__dirname, '../uploads/slips');

    beforeAll(async () => {
        process.env.JWT_SECRET = 'test_secret';
        vendorToken = jwt.sign({ id: 2, username: 'vendor_test', role: 'vendor' }, 'test_secret');
        adminToken = jwt.sign({ id: 1, username: 'admin', role: 'admin' }, 'test_secret');

        // สร้างโฟลเดอร์ uploads/slips หากยังไม่มี
        if (!fs.existsSync(uploadsDir)) {
            fs.mkdirSync(uploadsDir, { recursive: true });
        }

        // สร้างไฟล์ภาพจำลองสำหรับเทสต์
        fs.writeFileSync(dummyImagePath, 'fake image content');

        // สร้าง Booking เทียมไว้ทดสอบ
        const [result] = await pool.query(
            'INSERT INTO bookings (vendor_id, stall_id, event_id, booking_date, product_type, status) VALUES (2, 1, 1, "2026-12-05", "Food", "pending")'
        );
        testBookingId = result.insertId;
    });

    afterAll(async () => {
        if (testPaymentId) {
            await pool.query('DELETE FROM payments WHERE id = ?', [testPaymentId]);
        }
        if (testBookingId) {
            await pool.query('DELETE FROM bookings WHERE id = ?', [testBookingId]);
        }
        if (fs.existsSync(dummyImagePath)) {
            fs.unlinkSync(dummyImagePath);
        }
        await pool.end();
    });

    test('POST /api/payments/upload - Vendor ควรแนบสลิปโอนเงินได้ (201)', async () => {
        const res = await request(app)
            .post('/api/payments/upload')
            .set('Authorization', `Bearer ${vendorToken}`)
            .field('booking_id', testBookingId)
            .field('amount', '500.00')
            .attach('slip', dummyImagePath);

        expect(res.statusCode).toEqual(201);
        expect(res.body).toHaveProperty('paymentId');
        testPaymentId = res.body.paymentId;
    });

    test('PUT /api/payments/:id/verify - Admin ควรอนุมัติสลิปได้ (200)', async () => {
        const res = await request(app)
            .put(`/api/payments/${testPaymentId}/verify`)
            .set('Authorization', `Bearer ${adminToken}`)
            .send({ status: 'approved' });

        expect(res.statusCode).toEqual(200);
        expect(res.body.message).toContain('approved');
    });
});