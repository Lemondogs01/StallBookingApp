const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { bangkokDateString, isValidDateOnly } = require('../../utils/dateOnly');

describe('date-only helpers', () => {
  // กรณีนี้ทดสอบ «formats a timestamp in the Bangkok time zone»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('formats a timestamp in the Bangkok time zone', () => {
    const justAfterMidnightInBangkok = new Date('2026-11-10T17:00:00.000Z');

    assert.equal(bangkokDateString(justAfterMidnightInBangkok), '2026-11-11');
  });

  // กรณีนี้ทดสอบ «accepts a real calendar date in YYYY-MM-DD format»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('accepts a real calendar date in YYYY-MM-DD format', () => {
    assert.equal(isValidDateOnly('2024-02-29'), true);
  });

  // กรณีนี้ทดสอบ «rejects impossible dates and other input formats»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('rejects impossible dates and other input formats', () => {
    assert.equal(isValidDateOnly('2025-02-29'), false);
    assert.equal(isValidDateOnly('11/10/2026'), false);
    assert.equal(isValidDateOnly(null), false);
  });
});
