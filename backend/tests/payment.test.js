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
    let uploadedSlipPath;
    const dummyImagePath = path.join(__dirname, 'dummy_slip.jpg');
    const uploadsDir = path.join(__dirname, '../uploads/slips');

    beforeAll(async () => {
        process.env.JWT_SECRET = 'test_secret';
        vendorToken = jwt.sign({ id: 2, username: 'vendor_test', role: 'vendor' }, 'test_secret');
        adminToken = jwt.sign({ id: 1, username: 'admin', role: 'admin' }, 'test_secret');

        if (!fs.existsSync(uploadsDir)) {
            fs.mkdirSync(uploadsDir, { recursive: true });
        }

        fs.writeFileSync(dummyImagePath, 'fake image content');

        // เคลียร์ข้อมูลที่อาจตกค้างจากการเทสต์รอบก่อน
        await pool.query('DELETE FROM bookings WHERE stall_id = 1 AND event_id = 1 AND booking_date = "2099-12-31"');

        // สร้าง Booking เทียมใหม่
        const [result] = await pool.query(
            'INSERT INTO bookings (vendor_id, stall_id, event_id, booking_date, product_type, status) VALUES (2, 1, 1, "2099-12-31", "Food", "pending")'
        );
        testBookingId = result.insertId;
    });

    afterAll(async () => {
        // ล้างข้อมูลการชำระเงินและไฟล์สลิปที่อัปโหลดจริง
        if (testPaymentId) {
            await pool.query('DELETE FROM payments WHERE id = ?', [testPaymentId]);
        }
        if (testBookingId) {
            await pool.query('DELETE FROM bookings WHERE id = ?', [testBookingId]);
        }
        if (fs.existsSync(dummyImagePath)) {
            fs.unlinkSync(dummyImagePath);
        }
        if (uploadedSlipPath && fs.existsSync(uploadedSlipPath)) {
            fs.unlinkSync(uploadedSlipPath);
        }
        await pool.end();
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
        expect(res.body.slipUrl).toContain('slip_vendor_2_'); // ตรวจสอบว่ามี vendor_2 ในชื่อไฟล์

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