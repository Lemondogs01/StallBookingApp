const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { generateBookingCode } = require('../../utils/codeGenerator');

describe('booking code generator', () => {
  // กรณีนี้ทดสอบ «returns a code in the documented format»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns a code in the documented format', () => {
    const bookingCode = generateBookingCode();

    assert.match(bookingCode, /^BK-\d{8}-[A-F0-9]{4}$/);
  });
});
