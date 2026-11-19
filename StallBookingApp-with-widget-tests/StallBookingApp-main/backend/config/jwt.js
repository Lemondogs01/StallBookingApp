const path = require('node:path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const jwtSecret = process.env.JWT_SECRET;

if (!jwtSecret) {
  throw new Error('JWT_SECRET must be configured in the backend environment.');
}

module.exports = { jwtSecret };
