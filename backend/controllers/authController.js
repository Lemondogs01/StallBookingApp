const pool = require('../config/db');
const argon2 = require('argon2');
const jwt = require('jsonwebtoken');

// Register
exports.register = async (req, res) => {
    const { username, password, role } = req.body;

    if (!username || !password) {
        return res.status(400).json({ message: 'Username and password are required.' });
    }

    try {
        // เช็คว่า username ซ้ำหรือไม่
        const [existingUser] = await pool.query('SELECT * FROM users WHERE username = ?', [username]);
        if (existingUser.length > 0) {
            return res.status(400).json({ message: 'Username is already taken.' });
        }

        // แฮช password ด้วย argon2id
        const passwordHash = await argon2.hash(password, { type: argon2.argon2id });

        // บันทึกลง DB
        const userRole = role === 'admin' ? 'admin' : 'vendor';
        const [result] = await pool.query(
            'INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)',
            [username, passwordHash, userRole]
        );

        res.status(201).json({
            message: 'User registered successfully',
            userId: result.insertId
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Login
exports.login = async (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ message: 'Username and password are required.' });
    }

    try {
        // ค้นหา user จาก DB
        const [users] = await pool.query('SELECT * FROM users WHERE username = ?', [username]);
        if (users.length === 0) {
            return res.status(400).json({ message: 'Invalid username or password.' });
        }

        const user = users[0];

        // ถอดรหัส/เช็ค password ด้วย argon2
        const validPassword = await argon2.verify(user.password_hash, password);
        if (!validPassword) {
            return res.status(400).json({ message: 'Invalid username or password.' });
        }

        // สร้าง JWT Token
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