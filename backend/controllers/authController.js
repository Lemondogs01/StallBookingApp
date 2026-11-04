const pool = require('../config/db');
const argon2 = require('argon2');
const jwt = require('jsonwebtoken');

// 1. Register (สำหรับคนทั่วไป -> เป็น Vendor เสมอ)
exports.register = async (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ message: 'Username and password are required.' });
    }

    try {
        const [existingUser] = await pool.query('SELECT * FROM users WHERE username = ?', [username]);
        if (existingUser.length > 0) {
            return res.status(400).json({ message: 'Username is already taken.' });
        }

        const passwordHash = await argon2.hash(password, { type: argon2.argon2id });

        // ล็อค role เป็น 'vendor' เสมอ
        const userRole = 'vendor';
        const [result] = await pool.query(
            'INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)',
            [username, passwordHash, userRole]
        );

        res.status(201).json({
            message: 'Vendor registered successfully',
            userId: result.insertId
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// 2. Create Admin (สร้าง Admin ใหม่ -> สำหรับ Admin เท่านั้น)
exports.createAdmin = async (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ message: 'Username and password are required.' });
    }

    try {
        const [existingUser] = await pool.query('SELECT * FROM users WHERE username = ?', [username]);
        if (existingUser.length > 0) {
            return res.status(400).json({ message: 'Username is already taken.' });
        }

        const passwordHash = await argon2.hash(password, { type: argon2.argon2id });

        // กำหนด role เป็น 'admin'
        const [result] = await pool.query(
            'INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)',
            [username, passwordHash, 'admin']
        );

        res.status(201).json({
            message: 'Admin account created successfully',
            adminId: result.insertId
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// 3. Login (เหมือนเดิม)
exports.login = async (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ message: 'Username and password are required.' });
    }

    try {
        const [users] = await pool.query('SELECT * FROM users WHERE username = ?', [username]);
        if (users.length === 0) {
            return res.status(400).json({ message: 'Invalid username or password.' });
        }

        const user = users[0];

        const validPassword = await argon2.verify(user.password_hash, password);
        if (!validPassword) {
            return res.status(400).json({ message: 'Invalid username or password.' });
        }

        const token = jwt.sign(
            { id: user.id, username: user.username, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '1d' }
        );

        res.json({
            message: 'Login successful',
            token,
            user: {
                id: user.id,
                username: user.username,
                role: user.role
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};