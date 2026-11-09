const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();
require('./config/jwt');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const stallRoutes = require('./routes/stallRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve Static Uploads Folder
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/stalls', stallRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/admin', adminRoutes);

// Health Check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    system: 'MFU Stall Booking System API',
    timestamp: new Date()
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Unhandled Error:', err);
  const status = err.status || (
    err.code === 'LIMIT_FILE_SIZE' ? 413 :
    err.name === 'MulterError' ? 400 :
    500
  );
  res.status(status).json({
    message: err.message || 'Internal Server Error'
  });
});

// Start Server
app.listen(PORT, () => {
  console.log(`🚀 MFU Stall Booking API Server running on port ${PORT}`);
});
