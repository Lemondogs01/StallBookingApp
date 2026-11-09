const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { generateBookingCode } = require('../../utils/codeGenerator');

describe('booking code generator', () => {
  it('returns a code in the documented format', () => {
    const bookingCode = generateBookingCode();

    assert.match(bookingCode, /^BK-\d{8}-[A-F0-9]{4}$/);
  });
});
