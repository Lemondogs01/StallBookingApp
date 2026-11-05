const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
require('dotenv').config();

// 1. Import Database Connection Pool
const db = require('./config/db'); // Ensure this points to your database config file

const authRoutes = require('./routes/authRoutes');
const stallRoutes = require('./routes/stallRoutes');
const eventRoutes = require('./routes/eventRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const paymentRoutes = require('./routes/paymentRoutes');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// 2. Configure Upload Directory & Multer
const uploadDir = path.join(__dirname, 'uploads/events');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

// Serve uploaded files statically
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/stalls', stallRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);

// Test Route
app.get('/', (req, res) => {
    res.send('MFU Stall Booking API is running...');
});

// GET /api/events (Fetch all events)
app.get('/api/events', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM events ORDER BY id DESC');
        res.json(rows);
    } catch (error) {
        console.error('Error fetching events:', error);
        res.status(500).json({ message: 'Error fetching events' });
    }
});

// POST /api/admin/events (Create event with image upload)
app.post('/api/admin/events', upload.single('image'), async (req, res) => {
    try {
        const { title, description, location, price, stalls_left, start_date, end_date } = req.body;

        if (!req.file) {
            return res.status(400).json({ message: 'กรุณาแนบไฟล์รูปภาพ' });
        }

        // Image URL Path
        const imageUrl = `${req.protocol}://${req.get('host')}/uploads/events/${req.file.filename}`;

        const sql = `
            INSERT INTO events (name, description, location, price, stalls_left, image_url, start_date, end_date, status) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'upcoming')
        `;

        await db.query(sql, [
            title,
            description || '',
            location || 'Chiang Rai',
            price || 0,
            stalls_left || 0,
            imageUrl,
            start_date || new Date(),
            end_date || new Date()
        ]);

        res.status(201).json({
            message: 'สร้าง Event สำเร็จ',
            imageUrl: imageUrl
        });
    } catch (error) {
        console.error('Error adding event:', error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาดในการบันทึกข้อมูล' });
    }
});

// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`🐶🐶🐶 Server running on port ${PORT} 🐶🐶🐶`);
});

module.exports = app;