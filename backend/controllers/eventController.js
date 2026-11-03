const pool = require('../config/db');

exports.getAllEvents = async (req, res) => {
    try {
        const [events] = await pool.query('SELECT * FROM events ORDER BY start_date DESC');
        res.json(events);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

exports.createEvent = async (req, res) => {
    const { name, description, start_date, end_date, status } = req.body;
    if (!name || !start_date || !end_date) {
        return res.status(400).json({ message: 'Missing required event fields' });
    }
    try {
        const [result] = await pool.query(
            'INSERT INTO events (name, description, start_date, end_date, status) VALUES (?, ?, ?, ?, ?)',
            [name, description, start_date, end_date, status || 'upcoming']
        );
        res.status(201).json({ message: 'Event created successfully', eventId: result.insertId });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};