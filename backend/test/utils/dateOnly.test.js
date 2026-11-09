const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { bangkokDateString, isValidDateOnly } = require('../../utils/dateOnly');

describe('date-only helpers', () => {
  it('formats a timestamp in the Bangkok time zone', () => {
    const justAfterMidnightInBangkok = new Date('2026-11-10T17:00:00.000Z');

    assert.equal(bangkokDateString(justAfterMidnightInBangkok), '2026-11-11');
  });

  it('accepts a real calendar date in YYYY-MM-DD format', () => {
    assert.equal(isValidDateOnly('2024-02-29'), true);
  });

  it('rejects impossible dates and other input formats', () => {
    assert.equal(isValidDateOnly('2025-02-29'), false);
    assert.equal(isValidDateOnly('11/10/2026'), false);
    assert.equal(isValidDateOnly(null), false);
  });
});
