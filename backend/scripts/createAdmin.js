const path = require('node:path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const argon2 = require('argon2');
const { createInterface } = require('node:readline/promises');
const { stdin, stdout } = require('node:process');
const db = require('../config/db');
const User = require('../models/User');

const main = async () => {
  const password = process.env.ADMIN_PASSWORD;
  if (!password || password.length < 8) {
    throw new Error('Set ADMIN_PASSWORD to a private password of at least 8 characters.');
  }

  const readline = createInterface({ input: stdin, output: stdout });
  try {
    const username = (await readline.question('Admin username: ')).trim();
    const shop_name = (await readline.question('Market/admin display name: ')).trim();
    const real_name = (await readline.question('Admin full name: ')).trim();
    const phone = (await readline.question('Phone: ')).trim();

    if (!username || !shop_name || !real_name || !phone) {
      throw new Error('Username, display name, full name, and phone are required.');
    }

    const existingUser = await User.findByUsername(username);
    if (existingUser && existingUser.role !== 'admin') {
      throw new Error('That username is already used by a non-admin account.');
    }

    const password_hash = await argon2.hash(password, {
      type: argon2.argon2id,
      memoryCost: 2 ** 16,
      timeCost: 3
    });

    if (existingUser) {
      await User.updatePassword(existingUser.id, password_hash);
      await User.updateProfile(existingUser.id, { shop_name, real_name, phone });
      console.log(`Admin account "${username}" was updated.`);
    } else {
      await User.create({
        username,
        password_hash,
        role: 'admin',
        shop_name,
        real_name,
        phone
      });
      console.log(`Admin account "${username}" was created.`);
    }
  } finally {
    readline.close();
    await db.end();
  }
};

main().catch((error) => {
  console.error(`Admin setup failed: ${error.message}`);
  process.exitCode = 1;
});
