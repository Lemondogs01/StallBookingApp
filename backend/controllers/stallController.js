const pool = require('../config/db');

// ดึงรายการแผงค้าทั้งหมด (รองรับ Filter ตาม zone และ status)
exports.getAllStalls = async (req, res) => {
    const { zone, status } = req.query;
    try {
        let query = 'SELECT * FROM stalls WHERE 1=1';
        const params = [];

        if (zone) {
            query += ' AND zone = ?';
            params.push(zone);
        }
        if (status) {
            query += ' AND status = ?';
            params.push(status);
        }

        const [stalls] = await pool.query(query, params);
        res.json(stalls);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// [Admin] สร้างแผงค้าใหม่
exports.createStall = async (req, res) => {
    const { code, zone, size, price_per_day, status } = req.body;
    if (!code || !zone || !size || !price_per_day) {
        return res.status(400).json({ message: 'Missing required stall fields' });
    }
    try {
        const [result] = await pool.query(
            'INSERT INTO stalls (code, zone, size, price_per_day, status) VALUES (?, ?, ?, ?, ?)',
            [code, zone, size, price_per_day, status || 'available']
        );
        res.status(201).json({ message: 'Stall created successfully', stallId: result.insertId });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// [Admin] แก้ไขข้อมูลแผงค้า
exports.updateStall = async (req, res) => {
    const { id } = req.params;
    const { code, zone, size, price_per_day, status } = req.body;
    try {
        const [result] = await pool.query(
            'UPDATE stalls SET code = ?, zone = ?, size = ?, price_per_day = ?, status = ? WHERE id = ?',
            [code, zone, size, price_per_day, status, id]
        );
        if (result.affectedRows === 0) return res.status(404).json({ message: 'Stall not found' });
        res.json({ message: 'Stall updated successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// [Admin] ลบแผงค้า
exports.deleteStall = async (req, res) => {
    const { id } = req.params;
    try {
        const [result] = await pool.query('DELETE FROM stalls WHERE id = ?', [id]);
        if (result.affectedRows === 0) return res.status(404).json({ message: 'Stall not found' });
        res.json({ message: 'Stall deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};