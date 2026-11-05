require('dotenv').config();
const express = require('express');
const app = express();
app.use(express.json());
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/stalls', require('./routes/stallRoutes'));
app.get('/', (req, res) => res.json({ message: 'Campus Market Auth API' }));
module.exports = app;
