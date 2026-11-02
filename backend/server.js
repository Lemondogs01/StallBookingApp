require('dotenv').config();
if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
  throw new Error('Set JWT_SECRET to a random string of at least 32 characters in .env');
}
const app = require('./src/app');
const port = Number(process.env.PORT || 3000);
app.listen(port, () => console.log(`API running at http://localhost:${port}`));
