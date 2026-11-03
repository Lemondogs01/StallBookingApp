const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const stallRoutes = require('./routes/stallRoutes');
const eventRoutes = require('./routes/eventRoutes');
const bookingRoutes = require('./routes/bookingRoutes');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);

// Test Route
app.get('/', (req, res) => {
    res.send('MFU Stall Booking API is running...');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`🐶🐶🐶 Server running on port ${PORT} 🐶🐶🐶`);
});

// Stall Routes
app.use('/api/stalls', stallRoutes);

// Event Routes
app.use('/api/events', eventRoutes);

// Booking Routes
app.use('/api/bookings', bookingRoutes);

module.exports = app;