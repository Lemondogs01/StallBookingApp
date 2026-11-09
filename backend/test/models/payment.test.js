const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const db = require('../../config/db');
const Payment = require('../../models/Payment');
const { withMutedConsoleError } = require('../../test-support/controllerHarness');

function makeCreationConnection({ booking, existingPayments = [] }) {
  const calls = [];
  return {
    calls,
    committed: false,
    rolledBack: false,
    released: false,
    async beginTransaction() {},
    async query(sql, parameters) {
      calls.push({ sql, parameters });
      if (sql.includes('SELECT user_id, price, status FROM bookings')) {
        return [booking ? [booking] : []];
      }
      if (sql.includes('SELECT id FROM payments')) return [existingPayments];
      if (sql.startsWith('INSERT INTO payments')) return [{ insertId: 27 }];
      throw new Error(`Unexpected query in creation test: ${sql}`);
    },
    async commit() { this.committed = true; },
    async rollback() { this.rolledBack = true; },
    release() { this.released = true; }
  };
}

function makeConnection({ booking, payment }) {
  const calls = [];
  const connection = {
    calls,
    committed: false,
    rolledBack: false,
    released: false,
    async beginTransaction() {},
    async query(sql, parameters) {
      calls.push({ sql, parameters });
      if (sql.includes('SELECT user_id, status FROM bookings')) {
        return [[booking]];
      }
      if (sql.includes('SELECT id, slip_url FROM payments')) {
        return [payment ? [payment] : []];
      }
      if (sql.startsWith('UPDATE payments')) return [{ affectedRows: 1 }];
      throw new Error(`Unexpected query in unit test: ${sql}`);
    },
    async commit() {
      this.committed = true;
    },
    async rollback() {
      this.rolledBack = true;
    },
    release() {
      this.released = true;
    }
  };

  return connection;
}

async function withFakeConnection(connection, run) {
  const originalGetConnection = db.getConnection;
  db.getConnection = async () => connection;

  try {
    await run();
  } finally {
    db.getConnection = originalGetConnection;
  }
}

describe('Payment.createForPendingBooking', () => {
  it('creates a payment for the booking price and commits', async () => {
    const connection = makeCreationConnection({
      booking: { user_id: 12, price: '250.00', status: 'pending' }
    });

    await withFakeConnection(connection, async () => {
      const payment = await Payment.createForPendingBooking({
        booking_id: 9,
        user_id: 12,
        amount: 250,
        slip_url: '/uploads/slips/new.png'
      });

      assert.deepEqual(payment, { id: 27, amount: 250 });
    });

    assert.equal(connection.committed, true);
    assert.equal(connection.rolledBack, false);
    assert.equal(connection.released, true);
    assert.deepEqual(connection.calls.at(-1).parameters, [
      9, 250, '/uploads/slips/new.png'
    ]);
  });

  it('rejects a missing booking, another vendor, and a non-pending booking', async () => {
    const cases = [
      { booking: undefined, userId: 12, amount: 250, status: 404 },
      { booking: { user_id: 99, price: 250, status: 'pending' }, userId: 12, amount: 250, status: 403 },
      { booking: { user_id: 12, price: 250, status: 'approved' }, userId: 12, amount: 250, status: 409 }
    ];

    for (const { booking, userId, amount, status } of cases) {
      const connection = makeCreationConnection({ booking });
      await withFakeConnection(connection, async () => {
        await assert.rejects(
          Payment.createForPendingBooking({
            booking_id: 9, user_id: userId, amount, slip_url: '/uploads/slips/new.png'
          }),
          (error) => error.status === status
        );
      });
      assert.equal(connection.rolledBack, true);
      assert.equal(connection.committed, false);
      assert.equal(connection.released, true);
    }
  });

  it('requires an exact-enough amount and prevents duplicate payment records', async () => {
    const amountMismatch = makeCreationConnection({
      booking: { user_id: 12, price: 250, status: 'pending' }
    });
    await withFakeConnection(amountMismatch, async () => {
      await assert.rejects(
        Payment.createForPendingBooking({
          booking_id: 9, user_id: 12, amount: 249, slip_url: '/uploads/slips/new.png'
        }),
        (error) => error.status === 400
      );
    });
    assert.equal(amountMismatch.rolledBack, true);

    const duplicate = makeCreationConnection({
      booking: { user_id: 12, price: 250, status: 'pending' },
      existingPayments: [{ id: 6 }]
    });
    await withFakeConnection(duplicate, async () => {
      await assert.rejects(
        Payment.createForPendingBooking({
          booking_id: 9, user_id: 12, amount: 250, slip_url: '/uploads/slips/new.png'
        }),
        (error) => error.status === 409
      );
    });
    assert.equal(duplicate.rolledBack, true);
  });

  it('preserves the original error if transaction rollback also fails', async () => {
    const connection = makeCreationConnection({ booking: undefined });
    connection.rollback = async () => { throw new Error('rollback failed'); };

    await withMutedConsoleError(() => withFakeConnection(connection, async () => {
      await assert.rejects(
        Payment.createForPendingBooking({
          booking_id: 9,
          user_id: 12,
          amount: 250,
          slip_url: '/uploads/slips/new.png'
        }),
        (error) => error.status === 404 && error.message === 'Booking not found.'
      );
    }));

    assert.equal(connection.released, true);
  });
});

describe('Payment.replaceSlipForPendingBooking', () => {
  it('updates the existing slip and commits the transaction', async () => {
    const connection = makeConnection({
      booking: { user_id: 12, status: 'pending' },
      payment: { id: 31, slip_url: '/uploads/slips/old.png' }
    });

    await withFakeConnection(connection, async () => {
      const result = await Payment.replaceSlipForPendingBooking({
        booking_id: 9,
        user_id: 12,
        slip_url: '/uploads/slips/new.png'
      });

      assert.deepEqual(result, { old_slip_url: '/uploads/slips/old.png' });
      assert.equal(connection.committed, true);
      assert.equal(connection.rolledBack, false);
      assert.deepEqual(
        connection.calls.at(-1).parameters,
        ['/uploads/slips/new.png', 31]
      );
    });

    assert.equal(connection.released, true);
  });

  it('rejects another vendor and rolls the transaction back', async () => {
    const connection = makeConnection({
      booking: { user_id: 99, status: 'pending' },
      payment: { id: 31, slip_url: '/uploads/slips/old.png' }
    });

    await withFakeConnection(connection, async () => {
      await assert.rejects(
        Payment.replaceSlipForPendingBooking({
          booking_id: 9,
          user_id: 12,
          slip_url: '/uploads/slips/new.png'
        }),
        (error) => error.status === 403
      );
    });

    assert.equal(connection.committed, false);
    assert.equal(connection.rolledBack, true);
    assert.equal(connection.released, true);
    assert.equal(connection.calls.some(({ sql }) => sql.startsWith('UPDATE')), false);
  });

  it('does not allow slip changes after a booking is approved', async () => {
    const connection = makeConnection({
      booking: { user_id: 12, status: 'approved' },
      payment: { id: 31, slip_url: '/uploads/slips/old.png' }
    });

    await withFakeConnection(connection, async () => {
      await assert.rejects(
        Payment.replaceSlipForPendingBooking({
          booking_id: 9,
          user_id: 12,
          slip_url: '/uploads/slips/new.png'
        }),
        (error) => error.status === 409
      );
    });

    assert.equal(connection.rolledBack, true);
    assert.equal(connection.calls.some(({ sql }) => sql.startsWith('UPDATE')), false);
  });

  it('rejects a missing booking or a booking without an existing slip', async () => {
    const cases = [
      { booking: undefined, payment: undefined, message: 'Booking not found.' },
      {
        booking: { user_id: 12, status: 'pending' },
        payment: undefined,
        message: 'No payment slip exists for this booking.'
      }
    ];

    for (const { booking, payment, message } of cases) {
      const connection = makeConnection({ booking, payment });
      await withFakeConnection(connection, async () => {
        await assert.rejects(
          Payment.replaceSlipForPendingBooking({
            booking_id: 9,
            user_id: 12,
            slip_url: '/uploads/slips/new.png'
          }),
          (error) => error.status === 404 && error.message === message
        );
      });
      assert.equal(connection.rolledBack, true);
      assert.equal(connection.released, true);
    }
  });

  it('preserves the original replacement error if rollback fails', async () => {
    const connection = makeConnection({ booking: undefined, payment: undefined });
    connection.rollback = async () => { throw new Error('rollback failed'); };

    await withMutedConsoleError(() => withFakeConnection(connection, async () => {
      await assert.rejects(
        Payment.replaceSlipForPendingBooking({
          booking_id: 9,
          user_id: 12,
          slip_url: '/uploads/slips/new.png'
        }),
        (error) => error.status === 404 && error.message === 'Booking not found.'
      );
    }));

    assert.equal(connection.released, true);
  });
});
