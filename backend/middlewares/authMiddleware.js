const jwt = require('jsonwebtoken');
require('dotenv').config();

// ตรวจสอบว่ามี Token หรือไม่ และ Token ถูกต้องหรือไม่
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return res.status(401).json({ message: 'Access denied. No token provided.' });
    }

    try {
        const verified = jwt.verify(token, process.env.JWT_SECRET);
        req.user = verified; // { id, username, role }
        next();
    } catch (error) {
        res.status(403).json({ message: 'Invalid or expired token.' });
    }
};

// ตรวจสอบสิทธิ์ว่าเป็น Admin หรือไม่
const authorizeAdmin = (req, res, next) => {
    if (req.user && req.user.role === 'admin') {
        next();
    } else {
        res.status(403).json({ message: 'Access denied. Require Admin role.' });
    }
};

module.exports = { authenticateToken, authorizeAdmin };