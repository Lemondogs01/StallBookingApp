const Stall = require('../models/Stall');
const { bangkokDateString, isValidDateOnly } = require('../utils/dateOnly');

const getStallsStatus = async (req, res) => {
  try {
    const { date } = req.query;
    const targetDate = date || bangkokDateString();
    if (!isValidDateOnly(targetDate)) {
      return res.status(400).json({ message: 'A valid date in YYYY-MM-DD format is required.' });
    }

    const stalls = await Stall.getStallsAvailabilityByDate(targetDate);
    res.json({
      date: targetDate,
      stalls
    });
  } catch (error) {
    console.error('Get stalls status error:', error);
    res.status(500).json({ message: 'Internal server error getting stall availability.' });
  }
};

module.exports = {
  getStallsStatus
};
