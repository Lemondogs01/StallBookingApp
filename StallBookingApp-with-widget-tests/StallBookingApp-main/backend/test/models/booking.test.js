const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const db = require('../../config/db');
const Booking = require('../../models/Booking');
const { withOverrides, withMutedConsoleError } = require('../../test-support/controllerHarness');

function makeCancellationConnection({ booking, payments = [] }) {
  const calls = [];
  return {
    calls,
    committed: false,
    rolledBack: false,
    released: false,
    async beginTransaction() {},
    async query(sql, params) {
      calls.push({ sql, params });
      if (sql.includes('SELECT user_id, status FROM bookings')) {
        return [booking ? [booking] : []];
      }
      if (sql.includes('SELECT id FROM payments')) return [payments];
      if (sql.includes("UPDATE bookings SET status = 'cancelled'")) return [{ affectedRows: 1 }];
      throw new Error(`Unexpected query in test: ${sql}`);
    },
    async commit() { this.committed = true; },
    async rollback() { this.rolledBack = true; },
    release() { this.released = true; }
  };
}

async function withConnection(connection, run) {
  const originalGetConnection = db.getConnection;
  db.getConnection = async () => connection;
  try {
    await run();
  } finally {
    db.getConnection = originalGetConnection;
  }
}

describe('Booking model queries', () => {
  // กรณีนี้ทดสอบ «creates bookings and reads booking lists and single records»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('creates bookings and reads booking lists and single records', async () => {
    const calls = [];
    const row = { id: 4, status: 'pending' };

    await withOverrides(
      [[db, 'query', async (sql, params) => {
        calls.push({ sql, params });
        if (sql.startsWith('INSERT')) return [{ insertId: 4 }];
        return [[row]];
      }]],
      async () => {
        assert.equal(await Booking.create({
          booking_code: 'BK-20990101-ABCD', user_id: 8, stall_id: 'A1',
          booking_date: '2099-01-01', price: 250
        }), 4);
        assert.equal(await Booking.findById(4), row);
        assert.equal(await Booking.findActiveByStallAndDate('A1', '2099-01-01'), row);
        assert.deepEqual(await Booking.findByUserId(8), [row]);
        assert.deepEqual(await Booking.findPending(), [row]);
      }
    );

    assert.equal(calls.length, 5);
    assert.deepEqual(calls[0].params, [
      'BK-20990101-ABCD', 8, 'A1', '2099-01-01', 250, 'pending'
    ]);
    assert.match(calls[1].sql, /LEFT JOIN payments/);
    assert.match(calls[3].sql, /WHERE b\.user_id = \?/);
    assert.match(calls[4].sql, /WHERE b\.status = 'pending'/);
  });

  // กรณีนี้ทดสอบ «updates the status of a pending booking»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('updates the status of a pending booking', async () => {
    const calls = [];

    await withOverrides(
      [[db, 'query', async (sql, params) => {
        calls.push({ sql, params });
        return [{ affectedRows: 1 }];
      }]],
      async () => {
        assert.equal(await Booking.updatePendingStatus(4, 'approved'), true);
        assert.equal(await Booking.updatePendingStatus(5, 'rejected'), true);
      }
    );

    assert.deepEqual(calls[0].params, ['approved', 4]);
    assert.deepEqual(calls[1].params, ['rejected', 5]);
    assert.match(calls[0].sql, /SET status = \?/);
    assert.doesNotMatch(calls[0].sql, /approved_by_user_id|approved_at/);
  });

  // กรณีนี้ทดสอบ «builds seven daily and twelve monthly revenue points with zero-filled gaps»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('builds seven daily and twelve monthly revenue points with zero-filled gaps', async () => {
    const calls = [];
    const queryResults = [
      [{ revenue: '1200' }],
      [{ revenue: '250' }],
      [{ category: 'food', revenue: '250' }],
      [
        { month: '2025-12-01', revenue: '100' },
        { month: '2026-11-01', revenue: '300' }
      ],
      [
        { date: '2026-11-07', revenue: '50' },
        { date: '2026-11-10', revenue: '250' },
        { date: '2026-11-13', revenue: '300' }
      ]
    ];

    await withOverrides(
      [[db, 'query', async (sql, params) => {
        calls.push({ sql, params });
        return [queryResults.shift()];
      }]],
      async () => {
        const analytics = await Booking.getAnalytics('2026-11-10');

        assert.equal(analytics.totalRevenue, 1200);
        assert.equal(analytics.selectedDateRevenue, 250);
        assert.deepEqual(analytics.categoryRevenue, {
          food: 250, fashion: 0, general: 0
        });
        assert.equal(analytics.dailyBreakdown.length, 7);
        assert.deepEqual(analytics.dailyBreakdown[0], {
          date: '2026-11-07', revenue: 50
        });
        assert.deepEqual(analytics.dailyBreakdown[1], {
          date: '2026-11-08', revenue: 0
        });
        assert.deepEqual(analytics.dailyBreakdown[3], {
          date: '2026-11-10', revenue: 250
        });
        assert.deepEqual(analytics.dailyBreakdown[6], {
          date: '2026-11-13', revenue: 300
        });
        assert.equal(analytics.monthlyBreakdown.length, 12);
        assert.deepEqual(analytics.monthlyBreakdown[0], {
          month: '2025-12-01', revenue: 100
        });
        assert.equal(analytics.monthlyBreakdown.at(-1).revenue, 300);
      }
    );

    assert.equal(calls.length, 5);
    assert.deepEqual(calls[3].params, ['2025-12-01', '2026-12-01']);
    assert.deepEqual(calls[4].params, ['2026-11-07', '2026-11-13']);
  });
});

describe('Booking.cancelPendingOwned', () => {
  // กรณีนี้ทดสอบ «cancels an unpaid pending booking and commits»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('cancels an unpaid pending booking and commits', async () => {
    const connection = makeCancellationConnection({
      booking: { user_id: 8, status: 'pending' }
    });

    await withConnection(connection, async () => {
      assert.equal(await Booking.cancelPendingOwned(4, 8), true);
    });

    assert.equal(connection.committed, true);
    assert.equal(connection.rolledBack, false);
    assert.equal(connection.released, true);
    assert.match(connection.calls.at(-1).sql, /status = 'cancelled'/);
  });

  // กรณีนี้ทดสอบ «rolls back when booking is missing, owned by someone else, or not pending»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('rolls back when booking is missing, owned by someone else, or not pending', async () => {
    const cases = [
      { booking: undefined, userId: 8, statusCode: 404 },
      { booking: { user_id: 9, status: 'pending' }, userId: 8, statusCode: 403 },
      { booking: { user_id: 8, status: 'approved' }, userId: 8, statusCode: 409 },
      { booking: { user_id: 8, status: 'pending' }, userId: 8, payments: [{ id: 20 }], statusCode: 409 }
    ];

    for (const { booking, userId, payments = [], statusCode } of cases) {
      const connection = makeCancellationConnection({ booking, payments });
      await withConnection(connection, async () => {
        await assert.rejects(
          Booking.cancelPendingOwned(4, userId),
          (error) => error.status === statusCode
        );
      });
      assert.equal(connection.rolledBack, true);
      assert.equal(connection.committed, false);
      assert.equal(connection.released, true);
    }
  });

  // กรณีนี้ทดสอบ «releases the connection and keeps the booking error if rollback fails»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('releases the connection and keeps the booking error if rollback fails', async () => {
    const connection = makeCancellationConnection({ booking: undefined });
    connection.rollback = async () => { throw new Error('rollback failed'); };

    await withMutedConsoleError(() => withConnection(connection, async () => {
      await assert.rejects(
        Booking.cancelPendingOwned(4, 8),
        (error) => error.status === 404 && error.message === 'Booking not found.'
      );
    }));

    assert.equal(connection.released, true);
  });
});
