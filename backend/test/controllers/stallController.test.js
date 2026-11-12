const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const Stall = require('../../models/Stall');
const stallController = require('../../controllers/stallController');
const {
  createResponse,
  withOverrides,
  withMutedConsoleError
} = require('../../test-support/controllerHarness');

describe('stallController.getStallsStatus', () => {
  // กรณีนี้ทดสอบ «rejects an invalid date without querying stalls»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('rejects an invalid date without querying stalls', async () => {
    const response = createResponse();

    await stallController.getStallsStatus({ query: { date: '2026-02-30' } }, response);

    assert.equal(response.statusCode, 400);
  });

  // กรณีนี้ทดสอบ «uses the requested date and returns the stall list»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('uses the requested date and returns the stall list', async () => {
    const response = createResponse();
    const stalls = [{ id: 'A1', status: 'available' }];
    let queriedDate;

    await withOverrides(
      [[Stall, 'getStallsAvailabilityByDate', async (date) => { queriedDate = date; return stalls; }]],
      () => stallController.getStallsStatus({ query: { date: '2099-01-02' } }, response)
    );

    assert.equal(queriedDate, '2099-01-02');
    assert.deepEqual(response.body, { date: '2099-01-02', stalls });
  });

  // กรณีนี้ทดสอบ «returns a server error when the stall lookup fails»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns a server error when the stall lookup fails', async () => {
    const response = createResponse();

    await withMutedConsoleError(() => withOverrides(
      [[Stall, 'getStallsAvailabilityByDate', async () => { throw new Error('database down'); }]],
      () => stallController.getStallsStatus({ query: { date: '2099-01-02' } }, response)
    ));

    assert.equal(response.statusCode, 500);
  });
});
