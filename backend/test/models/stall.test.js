const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const db = require('../../config/db');
const Stall = require('../../models/Stall');
const { withOverrides } = require('../../test-support/controllerHarness');

describe('Stall model', () => {
  it('lists stalls and finds a stall by ID', async () => {
    const calls = [];
    const rows = [{ id: 'A1', price: 250 }];

    await withOverrides(
      [[db, 'query', async (sql, params) => {
        calls.push({ sql, params });
        return [rows];
      }]],
      async () => {
        assert.deepEqual(await Stall.findAll(), rows);
        assert.equal(await Stall.findById('A1'), rows[0]);
      }
    );

    assert.match(calls[0].sql, /ORDER BY id ASC/);
    assert.deepEqual(calls[1].params, ['A1']);
  });

  it('maps booking details for available, pending, and approved stalls', async () => {
    const rows = [
      { stall_id: 'A1', category: 'food', price: '250.00', booking_id: null },
      {
        stall_id: 'A2', category: 'fashion', price: '300.00', booking_id: 12,
        booking_status: 'pending', booking_code: 'BK-20990101-A1B2',
        booking_price: '300.00', paid_amount: '300.00'
      },
      {
        stall_id: 'A3', category: 'general', price: '200.00', booking_id: 13,
        booking_status: 'approved', booking_code: 'BK-20990101-A1B3',
        booking_price: null, paid_amount: null
      }
    ];

    await withOverrides(
      [[db, 'query', async (sql, params) => {
        assert.doesNotMatch(sql, /approved_by_user_id|approved_at/);
        assert.deepEqual(params, ['2099-01-01']);
        return [rows];
      }]],
      async () => {
        const stalls = await Stall.getStallsAvailabilityByDate('2099-01-01');

        assert.equal(stalls[0].status, 'available');
        assert.equal(stalls[0].booking, null);
        assert.equal(stalls[1].status, 'pending');
        assert.equal(stalls[1].booking.price, 300);
        assert.equal(stalls[1].booking.paidAmount, 300);
        assert.equal(stalls[2].status, 'approved');
        assert.equal(stalls[2].booking.price, null);
      }
    );
  });
});
