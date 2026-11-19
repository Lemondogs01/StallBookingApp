const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const argon2 = require('argon2');
const jwt = require('jsonwebtoken');
const User = require('../../models/User');
const authController = require('../../controllers/authController');
const {
  createResponse,
  withOverrides,
  withMutedConsoleError
} = require('../../test-support/controllerHarness');

describe('authController.register', () => {
  // กรณีนี้ทดสอบ «rejects missing fields, invalid phone numbers, and short passwords»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('rejects missing fields, invalid phone numbers, and short passwords', async () => {
    const cases = [
      [{ username: 'vendor' }, 'Please provide all required fields.'],
      [{ username: 'vendor', password: 'password', shop_name: 'Tea', real_name: 'A', phone: '123' }, 'Phone number must contain 8 to 15 digits.'],
      [{ username: 'vendor', password: 'short', shop_name: 'Tea', real_name: 'A', phone: '0800000000' }, 'Password must contain 8 to 128 characters.']
    ];

    for (const [body, expectedMessage] of cases) {
      const response = createResponse();
      await authController.register({ body }, response);
      assert.equal(response.statusCode, 400);
      assert.equal(response.body.message, expectedMessage);
    }
  });

  // กรณีนี้ทดสอบ «rejects fields longer than the database limits»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('rejects fields longer than the database limits', async () => {
    const response = createResponse();

    await authController.register({
      body: {
        username: 'u'.repeat(51),
        password: 'password123',
        shop_name: 'Tea',
        real_name: 'Vendor',
        phone: '0800000000'
      }
    }, response);

    assert.equal(response.statusCode, 400);
    assert.match(response.body.message, /exceed the allowed length/);
  });

  // กรณีนี้ทดสอบ «does not create an already registered username»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('does not create an already registered username', async () => {
    const response = createResponse();

    await withOverrides(
      [[User, 'findByUsername', async () => ({ id: 1 })]],
      () => authController.register({
        body: {
          username: ' vendor ', password: 'password123', shop_name: 'Tea',
          real_name: 'Vendor', phone: '0800000000'
        }
      }, response)
    );

    assert.equal(response.statusCode, 400);
    assert.equal(response.body.message, 'Username is already taken.');
  });

  // กรณีนี้ทดสอบ «creates a vendor with an Argon2id hash and returns a token»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('creates a vendor with an Argon2id hash and returns a token', async () => {
    const response = createResponse();
    let createdFields;
    let hashOptions;
    const user = { id: 4, username: 'vendor', role: 'vendor' };

    await withOverrides(
      [
        [User, 'findByUsername', async () => undefined],
        [User, 'create', async (fields) => { createdFields = fields; return 4; }],
        [User, 'findById', async () => user],
        [argon2, 'hash', async (_password, options) => { hashOptions = options; return 'argon-hash'; }],
        [jwt, 'sign', () => 'test-token']
      ],
      () => authController.register({
        body: {
          username: ' vendor ', password: 'password123', shop_name: ' Tea Shop ',
          real_name: ' Vendor Name ', phone: '0800000000'
        }
      }, response)
    );

    assert.equal(response.statusCode, 201);
    assert.equal(createdFields.username, 'vendor');
    assert.equal(createdFields.password_hash, 'argon-hash');
    assert.equal(createdFields.role, 'vendor');
    assert.equal(createdFields.shop_name, 'Tea Shop');
    assert.equal(hashOptions.type, argon2.argon2id);
    assert.equal(response.body.token, 'test-token');
    assert.equal(response.body.user, user);
  });

  // กรณีนี้ทดสอบ «returns conflict when the database reports a duplicate username»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns conflict when the database reports a duplicate username', async () => {
    const response = createResponse();
    const duplicateError = Object.assign(new Error('duplicate'), {
      code: 'ER_DUP_ENTRY', errno: 1062
    });

    await withMutedConsoleError(() => withOverrides(
      [
        [User, 'findByUsername', async () => undefined],
        [argon2, 'hash', async () => 'hash'],
        [User, 'create', async () => { throw duplicateError; }]
      ],
      () => authController.register({
        body: {
          username: 'vendor', password: 'password123', shop_name: 'Tea',
          real_name: 'Vendor', phone: '0800000000'
        }
      }, response)
    ));

    assert.equal(response.statusCode, 409);
  });

  // กรณีนี้ทดสอบ «returns a server error when registration storage fails unexpectedly»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns a server error when registration storage fails unexpectedly', async () => {
    const response = createResponse();

    await withMutedConsoleError(() => withOverrides(
      [
        [User, 'findByUsername', async () => undefined],
        [argon2, 'hash', async () => 'hash'],
        [User, 'create', async () => { throw new Error('database down'); }]
      ],
      () => authController.register({
        body: {
          username: 'vendor', password: 'password123', shop_name: 'Tea',
          real_name: 'Vendor', phone: '0800000000'
        }
      }, response)
    ));

    assert.equal(response.statusCode, 500);
  });
});

describe('authController.login', () => {
  // กรณีนี้ทดสอบ «requires both username and password»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('requires both username and password', async () => {
    const response = createResponse();

    await authController.login({ body: { username: 'vendor' } }, response);

    assert.equal(response.statusCode, 400);
  });

  // กรณีนี้ทดสอบ «uses the same error for an unknown username and a wrong password»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('uses the same error for an unknown username and a wrong password', async () => {
    const expectedMessage = 'Invalid username or password.';

    for (const user of [undefined, { id: 2, password_hash: 'hash' }]) {
      const response = createResponse();
      await withOverrides(
        [
          [User, 'findByUsername', async () => user],
          [argon2, 'verify', async () => false]
        ],
        () => authController.login({ body: { username: ' vendor ', password: 'wrong' } }, response)
      );
      assert.equal(response.statusCode, 401);
      assert.equal(response.body.message, expectedMessage);
    }
  });

  // กรณีนี้ทดสอบ «returns the signed-in user without exposing the password hash»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns the signed-in user without exposing the password hash', async () => {
    const response = createResponse();
    const user = {
      id: 2, username: 'vendor', role: 'vendor', password_hash: 'private-hash'
    };

    await withOverrides(
      [
        [User, 'findByUsername', async () => user],
        [argon2, 'verify', async () => true],
        [jwt, 'sign', () => 'test-token']
      ],
      () => authController.login({ body: { username: 'vendor', password: 'correct' } }, response)
    );

    assert.equal(response.body.token, 'test-token');
    assert.equal(response.body.user.username, 'vendor');
    assert.equal('password_hash' in response.body.user, false);
  });

  // กรณีนี้ทดสอบ «returns a server error when authentication dependencies fail»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns a server error when authentication dependencies fail', async () => {
    const response = createResponse();

    await withMutedConsoleError(() => withOverrides(
      [[User, 'findByUsername', async () => { throw new Error('database down'); }]],
      () => authController.login({ body: { username: 'vendor', password: 'password123' } }, response)
    ));

    assert.equal(response.statusCode, 500);
  });
});
