const request = require('supertest');
const express = require('express');
const authRoutes = require('../routes/authRoutes');
const pool = require('../config/db');

const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);

describe('Auth Controller Unit Tests', () => {
    // ปิด DB Pool Connection หลังทดสอบเสร็จทั้งหมด
    afterAll(async () => {
        try {
            await pool.query('DELETE FROM users WHERE username = ?', [testUser.username]);
        } finally {
            await pool.end();
        }
    });

    const testUser = {
        username: `testuser_${Date.now()}`,
        password: 'password123',
        role: 'vendor'
    };

    test('POST /api/auth/register - ควรสร้างบัญชีผู้ใช้ใหม่สำเร็จ (201)', async () => {
        const res = await request(app)
            .post('/api/auth/register')
            .send(testUser);

        expect(res.statusCode).toEqual(201);
        expect(res.body).toHaveProperty('message', 'Vendor registered successfully');
        expect(res.body).toHaveProperty('userId');
    });

    test('POST /api/auth/register - ควรปฏิเสธการลงทะเบียนถ้า Username ซ้ำ (400)', async () => {
        const res = await request(app)
            .post('/api/auth/register')
            .send(testUser);

        expect(res.statusCode).toEqual(400);
        expect(res.body).toHaveProperty('message', 'Username is already taken.');
    });

    test('POST /api/auth/login - ควรเข้าสู่ระบบสำเร็จและคืนค่า JWT Token (200)', async () => {
        const res = await request(app)
            .post('/api/auth/login')
            .send({
                username: testUser.username,
                password: testUser.password
            });

        expect(res.statusCode).toEqual(200);
        expect(res.body).toHaveProperty('token');
        expect(res.body.user).toHaveProperty('username', testUser.username);
    });

    test('POST /api/auth/login - ควรปฏิเสธถ้าใส่ Password ผิด (400)', async () => {
        const res = await request(app)
            .post('/api/auth/login')
            .send({
                username: testUser.username,
                password: 'wrongpassword'
            });

        expect(res.statusCode).toEqual(400);
        expect(res.body).toHaveProperty('message', 'Invalid username or password.');
    });
});
