const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const argon2 = require('argon2');
const Booking = require('../../models/Booking');
const User = require('../../models/User');
const adminController = require('../../controllers/adminController');
const {
  createResponse,
  withOverrides,
  withMutedConsoleError
} = require('../../test-support/controllerHarness');

describe('adminController.getPendingBookings and verifyBooking', () => {
  it('returns pending bookings', async () => {
    const response = createResponse();
    const bookings = [{ id: 4, status: 'pending' }];

    await withOverrides(
      [[Booking, 'findPending', async () => bookings]],
      () => adminController.getPendingBookings({}, response)
    );

    assert.deepEqual(response.body, bookings);
  });

  it('validates booking ID and requested decision', async () => {
    const cases = [
      [{ id: '0' }, { status: 'approved' }],
      [{ id: '4' }, { status: 'pending' }]
    ];

    for (const [params, body] of cases) {
      const response = createResponse();
      await adminController.verifyBooking({ params, body }, response);
      assert.equal(response.statusCode, 400);
    }
  });

  it('rejects missing and already reviewed bookings', async () => {
    for (const { booking, statusCode } of [
      { booking: undefined, statusCode: 404 },
      { booking: { id: 4, status: 'approved' }, statusCode: 409 }
    ]) {
      const response = createResponse();
      await withOverrides(
        [[Booking, 'findById', async () => booking]],
        () => adminController.verifyBooking({
          params: { id: '4' }, body: { status: 'approved' }
        }, response)
      );
      assert.equal(response.statusCode, statusCode);
    }
  });

  it('requires a slip and matching amount before approval', async () => {
    for (const { booking, expectedMessage } of [
      {
        booking: { id: 4, status: 'pending', slip_url: null, price: 250, payment_amount: 250 },
        expectedMessage: 'A payment slip must be submitted before approval.'
      },
      {
        booking: { id: 4, status: 'pending', slip_url: '/uploads/slips/a.png', price: 250, payment_amount: 240 },
        expectedMessage: 'The submitted payment amount does not match the booking price.'
      }
    ]) {
      const response = createResponse();
      await withOverrides(
        [[Booking, 'findById', async () => booking]],
        () => adminController.verifyBooking({
          params: { id: '4' }, body: { status: 'approved' }
        }, response)
      );
      assert.equal(response.statusCode, 409);
      assert.equal(response.body.message, expectedMessage);
    }
  });

  it('approves an eligible booking without storing approval metadata', async () => {
    const response = createResponse();
    let updateArguments;
    const booking = {
      id: 4,
      status: 'pending',
      slip_url: '/uploads/slips/a.png',
      price: '250.00',
      payment_amount: '250.00'
    };

    await withOverrides(
      [
        [Booking, 'findById', async () => booking],
        [Booking, 'updatePendingStatus', async (...args) => { updateArguments = args; return true; }]
      ],
      () => adminController.verifyBooking({
        params: { id: '4' }, body: { status: 'approved' }, user: { id: 99 }
      }, response)
    );

    assert.deepEqual(updateArguments, [4, 'approved']);
    assert.deepEqual(response.body, {
      message: 'Booking has been approved.', bookingId: 4, status: 'approved'
    });
  });

  it('can reject a pending booking and handles a concurrent update', async () => {
    const rejectedResponse = createResponse();
    const booking = { id: 4, status: 'pending', slip_url: null };

    await withOverrides(
      [
        [Booking, 'findById', async () => booking],
        [Booking, 'updatePendingStatus', async () => true]
      ],
      () => adminController.verifyBooking({
        params: { id: '4' }, body: { status: 'rejected' }, user: { id: 99 }
      }, rejectedResponse)
    );
    assert.equal(rejectedResponse.body.status, 'rejected');

    const conflictResponse = createResponse();
    await withOverrides(
      [
        [Booking, 'findById', async () => booking],
        [Booking, 'updatePendingStatus', async () => false]
      ],
      () => adminController.verifyBooking({
        params: { id: '4' }, body: { status: 'rejected' }, user: { id: 99 }
      }, conflictResponse)
    );
    assert.equal(conflictResponse.statusCode, 409);
  });
});

describe('adminController analytics and user management', () => {
  it('validates and returns analytics for the requested date', async () => {
    const invalidResponse = createResponse();
    await adminController.getAnalytics({ query: { date: '2026-02-30' } }, invalidResponse);
    assert.equal(invalidResponse.statusCode, 400);

    const response = createResponse();
    const analytics = { totalRevenue: 500 };
    let requestedDate;
    await withOverrides(
      [[Booking, 'getAnalytics', async (date) => { requestedDate = date; return analytics; }]],
      () => adminController.getAnalytics({ query: { date: '2099-01-02' } }, response)
    );
    assert.equal(requestedDate, '2099-01-02');
    assert.deepEqual(response.body, analytics);
  });

  it('passes the optional vendor search query to the user model', async () => {
    const response = createResponse();
    const users = [{ id: 7, username: 'vendor7' }];
    let query;

    await withOverrides(
      [[User, 'findAll', async (value) => { query = value; return users; }]],
      () => adminController.getUsers({ query: { query: 'tea' } }, response)
    );

    assert.equal(query, 'tea');
    assert.deepEqual(response.body, users);
  });

  it('validates user ID and only resets vendor accounts', async () => {
    const invalidId = createResponse();
    await adminController.resetUserPassword({ params: { id: '0' }, body: {} }, invalidId);
    assert.equal(invalidId.statusCode, 400);

    const missingUser = createResponse();
    await withOverrides(
      [[User, 'findById', async () => undefined]],
      () => adminController.resetUserPassword({ params: { id: '8' }, body: {} }, missingUser)
    );
    assert.equal(missingUser.statusCode, 404);

    const adminUser = createResponse();
    await withOverrides(
      [[User, 'findById', async () => ({ role: 'admin' })]],
      () => adminController.resetUserPassword({ params: { id: '8' }, body: {} }, adminUser)
    );
    assert.equal(adminUser.statusCode, 400);
  });

  it('hashes and saves the requested vendor password', async () => {
    const response = createResponse();
    let receivedHash;
    let receivedPassword;

    await withOverrides(
      [
        [User, 'findById', async () => ({ username: 'vendor8', role: 'vendor' })],
        [User, 'updatePassword', async (_id, hash) => { receivedHash = hash; }],
        [argon2, 'hash', async (password, options) => {
          receivedPassword = password;
          assert.equal(options.type, argon2.argon2id);
          return 'new-hash';
        }]
      ],
      () => adminController.resetUserPassword({
        params: { id: '8' }, body: { password: 'new-password-123' }
      }, response)
    );

    assert.equal(receivedPassword, 'new-password-123');
    assert.equal(receivedHash, 'new-hash');
    assert.match(response.body.message, /vendor8/);
  });

  it('uses the reset command default when no password is provided', async () => {
    const response = createResponse();
    let hashedPassword;

    await withOverrides(
      [
        [User, 'findById', async () => ({ username: 'vendor8', role: 'vendor' })],
        [User, 'updatePassword', async () => true],
        [argon2, 'hash', async (password) => { hashedPassword = password; return 'hash'; }]
      ],
      () => adminController.resetUserPassword({
        params: { id: '8' }, body: {}
      }, response)
    );

    assert.equal(hashedPassword, '123456');
    assert.equal(response.statusCode, 200);
  });

  it('returns server errors when admin lookups fail', async () => {
    const response = createResponse();

    await withMutedConsoleError(() => withOverrides(
      [[Booking, 'findPending', async () => { throw new Error('database down'); }]],
      () => adminController.getPendingBookings({}, response)
    ));

    assert.equal(response.statusCode, 500);
  });

  it('returns server errors for analytics, user search, verification, and reset failures', async () => {
    const scenarios = [
      {
        overrides: [[Booking, 'getAnalytics', async () => { throw new Error('query failed'); }]],
        action: (response) => adminController.getAnalytics({ query: { date: '2099-01-01' } }, response)
      },
      {
        overrides: [[User, 'findAll', async () => { throw new Error('query failed'); }]],
        action: (response) => adminController.getUsers({ query: {} }, response)
      },
      {
        overrides: [[Booking, 'findById', async () => { throw new Error('query failed'); }]],
        action: (response) => adminController.verifyBooking({
          params: { id: '4' }, body: { status: 'rejected' }
        }, response)
      },
      {
        overrides: [[User, 'findById', async () => { throw new Error('query failed'); }]],
        action: (response) => adminController.resetUserPassword({
          params: { id: '8' }, body: {}
        }, response)
      }
    ];

    for (const scenario of scenarios) {
      const response = createResponse();
      await withMutedConsoleError(() => withOverrides(
        scenario.overrides,
        () => scenario.action(response)
      ));
      assert.equal(response.statusCode, 500);
    }
  });
});
