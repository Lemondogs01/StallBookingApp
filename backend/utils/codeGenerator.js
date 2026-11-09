const crypto = require('crypto');
const { bangkokDateString } = require('./dateOnly');

/**
 * Generates a unique Booking Code
 * Format: BK-YYYYMMDD-XXXX (e.g. BK-20261108-A8F2)
 */
const generateBookingCode = () => {
    const today = bangkokDateString().replace(/-/g, '');
    const randomHex = crypto.randomBytes(2).toString('hex').toUpperCase(); // 4 random hex characters
    return `BK-${today}-${randomHex}`;
};

module.exports = { generateBookingCode };
