const request = require('supertest');
const express = require('express');
const eventRoutes = require('../routes/eventRoutes');
const pool = require('../config/db');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

app.use('/api/events', (req, res, next) => {
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
}, eventRoutes);

describe('Event Controller Unit Tests', () => {
    let adminToken;
    let testEventId;
    const testEventName = `MFU Night Market ${Date.now()}`;

    beforeAll(() => {
        process.env.JWT_SECRET = 'test_secret';
        adminToken = jwt.sign({ id: 1, username: 'admin', role: 'admin' }, 'test_secret');
    });

    afterAll(async () => {
        try {
            // Use the test event's unique name as a fallback if creation succeeded but the test failed early.
            await pool.query('DELETE FROM events WHERE name = ?', [testEventName]);
            if (testEventId) {
                await pool.query('DELETE FROM events WHERE id = ?', [testEventId]);
            }
        } finally {
            await pool.end();
        }
    });

    test('POST /api/events - Admin ควรสร้าง Event ใหม่ได้ (201)', async () => {
        const res = await request(app)
            .post('/api/events')
            .set('Authorization', `Bearer ${adminToken}`)
            .send({
                name: testEventName,
                description: 'ตลาดนัดยามเย็น',
                start_date: '2026-12-01',
                end_date: '2026-12-03'
            });

        expect(res.statusCode).toEqual(201);
        expect(res.body).toHaveProperty('eventId');
        testEventId = res.body.eventId;
    });

    test('GET /api/events - ควรดึงรายการ Event ทั้งหมดได้ (200)', async () => {
        const res = await request(app)
            .get('/api/events')
            .set('Authorization', `Bearer ${adminToken}`);

        expect(res.statusCode).toEqual(200);
        expect(Array.isArray(res.body)).toBeTruthy();
    });
});
