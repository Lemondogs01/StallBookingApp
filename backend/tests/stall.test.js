const request = require('supertest');
const express = require('express');
const stallRoutes = require('../routes/stallRoutes');
const pool = require('../config/db');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

// จำลอง Middleware สำหรับผ่าน Token ในการทดสอบ
app.use('/api/stalls', (req, res, next) => {
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
}, stallRoutes);

describe('Stall Controller Unit Tests', () => {
    let adminToken;
    let testStallId;

    beforeAll(() => {
        process.env.JWT_SECRET = 'test_secret';
        // สร้าง Token ของ Admin ลำลองสำหรับทดสอบ
        adminToken = jwt.sign({ id: 1, username: 'admin', role: 'admin' }, 'test_secret');
    });

    afterAll(async () => {
        if (testStallId) {
            await pool.query('DELETE FROM stalls WHERE id = ?', [testStallId]);
        }
        await pool.end();
    });

    test('POST /api/stalls - Admin ควรสร้างแผงค้าใหม่ได้ (201)', async () => {
        const res = await request(app)
            .post('/api/stalls')
            .set('Authorization', `Bearer ${adminToken}`)
            .send({
                code: 'A99',
                zone: 'Food',
                size: '2x2',
                price_per_day: 150.00
            });

        expect(res.statusCode).toEqual(201);
        expect(res.body).toHaveProperty('message', 'Stall created successfully');
        expect(res.body).toHaveProperty('stallId');
        testStallId = res.body.stallId;
    });

    test('POST /api/stalls - ควรปฏิเสธหากส่งข้อมูลไม่ครบ (400)', async () => {
        const res = await request(app)
            .post('/api/stalls')
            .set('Authorization', `Bearer ${adminToken}`)
            .send({
                zone: 'Food'
            });

        expect(res.statusCode).toEqual(400);
    });

    test('GET /api/stalls - ควรดึงรายการแผงค้าทั้งหมดได้ (200)', async () => {
        const res = await request(app)
            .get('/api/stalls')
            .set('Authorization', `Bearer ${adminToken}`);

        expect(res.statusCode).toEqual(200);
        expect(Array.isArray(res.body)).toBeTruthy();
    });

    test('DELETE /api/stalls/:id - Admin ควรลบแผงค้าได้ (200)', async () => {
        const res = await request(app)
            .delete(`/api/stalls/${testStallId}`)
            .set('Authorization', `Bearer ${adminToken}`);

        expect(res.statusCode).toEqual(200);
        expect(res.body).toHaveProperty('message', 'Stall deleted successfully');
        testStallId = null;
    });
});