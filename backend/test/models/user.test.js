const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const db = require('../../config/db');
const User = require('../../models/User');
const { withOverrides } = require('../../test-support/controllerHarness');

describe('User model queries', () => {
  it('looks up a user by username, ID, and password hash', async () => {
    const calls = [];
    const row = { id: 3, username: 'vendor3' };

    await withOverrides(
      [[db, 'query', async (sql, params) => {
        calls.push({ sql, params });
        return [[row]];
      }]],
      async () => {
        assert.equal(await User.findByUsername('vendor3'), row);
        assert.equal(await User.findById(3), row);
        assert.equal(await User.findPasswordHashById(3), row);
      }
    );

    assert.equal(calls.length, 3);
    assert.deepEqual(calls.map(({ params }) => params), [['vendor3'], [3], [3]]);
  });

  it('creates a vendor with the default role and no profile image', async () => {
    let received;

    await withOverrides(
      [[db, 'query', async (sql, params) => {
        received = { sql, params };
        return [{ insertId: 21 }];
      }]],
      async () => {
        assert.equal(await User.create({
          username: 'vendor', password_hash: 'hash', shop_name: 'Tea',
          real_name: 'Vendor', phone: '0800000000'
        }), 21);
      }
    );

    assert.match(received.sql, /INSERT INTO users/);
    assert.deepEqual(received.params, [
      'vendor', 'hash', 'vendor', 'Tea', 'Vendor', '0800000000', null
    ]);
  });

  it('updates only provided profile fields and skips an empty update', async () => {
    const calls = [];

    await withOverrides(
      [[db, 'query', async (sql, params) => {
        calls.push({ sql, params });
        return [{ affectedRows: 1 }];
      }]],
      async () => {
        assert.equal(await User.updateProfile(3, {}), false);
        assert.equal(await User.updateProfile(3, {
          profile_image: '/uploads/profiles/new.png'
        }), true);
        assert.equal(await User.updatePassword(3, 'new-hash'), true);
      }
    );

    assert.equal(calls.length, 2);
    assert.match(calls[0].sql, /profile_image = \?/);
    assert.deepEqual(calls[0].params, ['/uploads/profiles/new.png', 3]);
    assert.deepEqual(calls[1].params, ['new-hash', 3]);
  });

  it('searches vendor fields only when a query is provided', async () => {
    const calls = [];

    await withOverrides(
      [[db, 'query', async (sql, params) => {
        calls.push({ sql, params });
        return [[{ id: 3, username: 'vendor3' }]];
      }]],
      async () => {
        await User.findAll();
        await User.findAll('tea');
      }
    );

    assert.equal(calls.length, 2);
    assert.deepEqual(calls[0].params, []);
    assert.doesNotMatch(calls[0].sql, /LIKE/);
    assert.deepEqual(calls[1].params, ['%tea%', '%tea%', '%tea%', '%tea%']);
    assert.match(calls[1].sql, /phone LIKE \?/);
  });
});
