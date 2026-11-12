const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../../config/jwt');
const authMiddleware = require('../../middlewares/authMiddleware');
const roleMiddleware = require('../../middlewares/roleMiddleware');
const { createResponse } = require('../../test-support/controllerHarness');

describe('authMiddleware', () => {
  // กรณีนี้ทดสอบ «rejects a missing token and a non-Bearer authorization header»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('rejects a missing token and a non-Bearer authorization header', () => {
    for (const authorization of [undefined, 'Basic abc']) {
      const response = createResponse();
      authMiddleware({ headers: { authorization } }, response, () => {
        assert.fail('next should not run without a Bearer token');
      });
      assert.equal(response.statusCode, 401);
    }
  });

  // กรณีนี้ทดสอบ «rejects an invalid or expired token»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('rejects an invalid or expired token', () => {
    const response = createResponse();

    authMiddleware({ headers: { authorization: 'Bearer invalid-token' } }, response, () => {
      assert.fail('next should not run for an invalid token');
    });

    assert.equal(response.statusCode, 401);
    assert.match(response.body.message, /Invalid or expired/);
  });

  // กรณีนี้ทดสอบ «attaches a verified user and continues the request»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('attaches a verified user and continues the request', () => {
    const response = createResponse();
    const decoded = { id: 8, username: 'vendor8', role: 'vendor' };
    const token = jwt.sign(decoded, jwtSecret, { expiresIn: '1m' });
    const request = { headers: { authorization: `Bearer ${token}` } };
    let continued = false;

    authMiddleware(request, response, () => { continued = true; });

    assert.equal(request.user.id, decoded.id);
    assert.equal(request.user.username, decoded.username);
    assert.equal(request.user.role, decoded.role);
    assert.equal(typeof request.user.iat, 'number');
    assert.equal(typeof request.user.exp, 'number');
    assert.equal(continued, true);
  });
});

describe('roleMiddleware', () => {
  // กรณีนี้ทดสอบ «allows an authorized role and blocks missing or unauthorized roles»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('allows an authorized role and blocks missing or unauthorized roles', () => {
    const allowResponse = createResponse();
    let continued = false;
    roleMiddleware('admin')({ user: { role: 'admin' } }, allowResponse, () => {
      continued = true;
    });
    assert.equal(continued, true);

    for (const user of [undefined, { role: 'vendor' }]) {
      const response = createResponse();
      roleMiddleware('admin')({ user }, response, () => {
        assert.fail('next should not run for an unauthorized role');
      });
      assert.equal(response.statusCode, 403);
    }
  });
});
