const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const Booking = require('../../models/Booking');
const Stall = require('../../models/Stall');
const bookingController = require('../../controllers/bookingController');
const {
  createResponse,
  withOverrides,
  withMutedConsoleError
} = require('../../test-support/controllerHarness');

const validRequest = {
  user: { id: 8 },
  body: { stall_id: 'A1', booking_date: '2099-01-02' }
};

describe('bookingController.createBooking', () => {
  it('requires a stall ID and a real calendar date', async () => {
    for (const body of [{}, { stall_id: 'A1', booking_date: '2099-02-30' }]) {
      const response = createResponse();
      await bookingController.createBooking({ ...validRequest, body }, response);
      assert.equal(response.statusCode, 400);
    }
  });

  it('does not allow a booking for a past date', async () => {
    const response = createResponse();

    await bookingController.createBooking({
      ...validRequest,
      body: { stall_id: 'A1', booking_date: '2000-01-01' }
    }, response);

    assert.equal(response.statusCode, 400);
    assert.match(response.body.message, /past date/);
  });

  it('returns not found when the requested stall does not exist', async () => {
    const response = createResponse();

    await withOverrides(
      [[Stall, 'findById', async () => undefined]],
      () => bookingController.createBooking(validRequest, response)
    );

    assert.equal(response.statusCode, 404);
  });

  it('rejects a stall that already has an active booking for that date', async () => {
    const response = createResponse();

    await withOverrides(
      [
        [Stall, 'findById', async () => ({ id: 'A1', price: 250 })],
        [Booking, 'findActiveByStallAndDate', async () => ({ id: 15 })]
      ],
      () => bookingController.createBooking(validRequest, response)
    );

    assert.equal(response.statusCode, 409);
  });

  it('creates a pending booking at the stall price', async () => {
    const response = createResponse();
    let createFields;
    const booking = { id: 15, booking_code: 'BK-20990102-ABCD' };

    await withOverrides(
      [
        [Stall, 'findById', async () => ({ id: 'A1', price: 250 })],
        [Booking, 'findActiveByStallAndDate', async () => undefined],
        [Booking, 'create', async (fields) => { createFields = fields; return 15; }],
        [Booking, 'findById', async () => booking]
      ],
      () => bookingController.createBooking(validRequest, response)
    );

    assert.equal(response.statusCode, 201);
    assert.equal(createFields.user_id, 8);
    assert.equal(createFields.stall_id, 'A1');
    assert.equal(createFields.booking_date, '2099-01-02');
    assert.equal(createFields.price, 250);
    assert.match(createFields.booking_code, /^BK-\d{8}-[A-F0-9]{4}$/);
    assert.equal(response.body.booking, booking);
  });

  it('maps a database duplicate booking error to conflict', async () => {
    const response = createResponse();
    const duplicateError = Object.assign(new Error('duplicate'), {
      code: 'ER_DUP_ENTRY', errno: 1062
    });

    await withMutedConsoleError(() => withOverrides(
      [
        [Stall, 'findById', async () => ({ id: 'A1', price: 250 })],
        [Booking, 'findActiveByStallAndDate', async () => undefined],
        [Booking, 'create', async () => { throw duplicateError; }]
      ],
      () => bookingController.createBooking(validRequest, response)
    ));

    assert.equal(response.statusCode, 409);
  });

  it('returns a server error for an unexpected booking failure', async () => {
    const response = createResponse();

    await withMutedConsoleError(() => withOverrides(
      [[Stall, 'findById', async () => { throw new Error('database down'); }]],
      () => bookingController.createBooking(validRequest, response)
    ));

    assert.equal(response.statusCode, 500);
  });
});

describe('bookingController.getMyBookings and cancelBooking', () => {
  it('returns only the current vendor bookings', async () => {
    const response = createResponse();
    const bookings = [{ id: 15, status: 'pending' }];
    let requestedUser;

    await withOverrides(
      [[Booking, 'findByUserId', async (userId) => { requestedUser = userId; return bookings; }]],
      () => bookingController.getMyBookings({ user: { id: 8 } }, response)
    );

    assert.equal(requestedUser, 8);
    assert.deepEqual(response.body, bookings);
  });

  it('returns an error when the bookings query fails', async () => {
    const response = createResponse();

    await withMutedConsoleError(() => withOverrides(
      [[Booking, 'findByUserId', async () => { throw new Error('database down'); }]],
      () => bookingController.getMyBookings({ user: { id: 8 } }, response)
    ));

    assert.equal(response.statusCode, 500);
  });

  it('rejects an invalid booking ID before attempting cancellation', async () => {
    const response = createResponse();

    await bookingController.cancelBooking({ params: { id: '0' }, user: { id: 8 } }, response);

    assert.equal(response.statusCode, 400);
  });

  it('returns a success response after cancellation', async () => {
    const response = createResponse();
    let cancellation;

    await withOverrides(
      [[Booking, 'cancelPendingOwned', async (id, userId) => { cancellation = [id, userId]; }]],
      () => bookingController.cancelBooking({ params: { id: '15' }, user: { id: 8 } }, response)
    );

    assert.deepEqual(cancellation, [15, 8]);
    assert.equal(response.body.message, 'Booking cancelled successfully.');
  });

  it('returns the model status and message for a rejected cancellation', async () => {
    const response = createResponse();
    const error = Object.assign(new Error('A payment slip has been submitted.'), { status: 409 });

    await withOverrides(
      [[Booking, 'cancelPendingOwned', async () => { throw error; }]],
      () => bookingController.cancelBooking({ params: { id: '15' }, user: { id: 8 } }, response)
    );

    assert.equal(response.statusCode, 409);
    assert.equal(response.body.message, error.message);
  });

  it('returns a server error for an unexpected cancellation failure', async () => {
    const response = createResponse();

    await withMutedConsoleError(() => withOverrides(
      [[Booking, 'cancelPendingOwned', async () => { throw new Error('database down'); }]],
      () => bookingController.cancelBooking({ params: { id: '15' }, user: { id: 8 } }, response)
    ));

    assert.equal(response.statusCode, 500);
  });
});
