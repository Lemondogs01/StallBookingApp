const { afterEach, describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const { randomUUID } = require('node:crypto');
const Payment = require('../../models/Payment');
const paymentController = require('../../controllers/paymentController');
const {
  createResponse,
  withOverrides,
  withMutedConsoleError
} = require('../../test-support/controllerHarness');

const activeFixtures = new Set();

async function makeTemporaryFile(name = 'slip.png') {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'mfu-payment-test-'));
  const filePath = path.join(directory, name);
  await fs.writeFile(filePath, 'temporary payment slip');
  const fixture = {
    filePath,
    path: filePath,
    filename: name,
    async cleanup() {
      await fs.rm(directory, { recursive: true, force: true });
      activeFixtures.delete(fixture);
    }
  };
  activeFixtures.add(fixture);
  return fixture;
}

async function makeStoredSlip() {
  const directory = path.join(__dirname, '../../uploads/slips');
  await fs.mkdir(directory, { recursive: true });
  const filename = `unit-${randomUUID()}.png`;
  const filePath = path.join(directory, filename);
  await fs.writeFile(filePath, 'old payment slip');
  const fixture = {
    filePath,
    url: `/uploads/slips/${filename}`,
    async cleanup() {
      await fs.rm(filePath, { force: true });
      activeFixtures.delete(fixture);
    }
  };
  activeFixtures.add(fixture);
  return fixture;
}

afterEach(async () => {
  await Promise.all([...activeFixtures].map((fixture) => fixture.cleanup()));
});

describe('paymentController.createPayment', () => {
  // กรณีนี้ทดสอบ «validates booking ID and amount, and removes the rejected upload»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('validates booking ID and amount, and removes the rejected upload', async () => {
    const upload = await makeTemporaryFile();
    const response = createResponse();

    await paymentController.createPayment({
      body: { booking_id: '0', amount: '100' },
      file: upload,
      user: { id: 8 }
    }, response);

    assert.equal(response.statusCode, 400);
    await assert.rejects(fs.access(upload.filePath), { code: 'ENOENT' });
    await upload.cleanup();
  });

  // กรณีนี้ทดสอบ «requires a slip image»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('requires a slip image', async () => {
    const response = createResponse();

    await paymentController.createPayment({
      body: { booking_id: '4', amount: '250' },
      user: { id: 8 }
    }, response);

    assert.equal(response.statusCode, 400);
    assert.match(response.body.message, /slip image is required/);
  });

  // กรณีนี้ทดสอบ «creates a payment with the server upload path»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('creates a payment with the server upload path', async () => {
    const upload = await makeTemporaryFile('new-slip.png');
    const response = createResponse();
    let savedPayment;

    try {
      await withOverrides(
        [[Payment, 'createForPendingBooking', async (payment) => {
          savedPayment = payment;
          return { id: 20, amount: 250 };
        }]],
        () => paymentController.createPayment({
          body: { booking_id: '4', amount: '250' },
          file: upload,
          user: { id: 8 }
        }, response)
      );

      assert.equal(response.statusCode, 201);
      assert.deepEqual(savedPayment, {
        booking_id: 4,
        user_id: 8,
        amount: 250,
        slip_url: `/uploads/slips/${upload.filename}`
      });
      assert.equal(response.body.payment.slip_url, savedPayment.slip_url);
    } finally {
      await upload.cleanup();
    }
  });

  // กรณีนี้ทดสอบ «removes the upload and returns model validation errors»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('removes the upload and returns model validation errors', async () => {
    const upload = await makeTemporaryFile();
    const response = createResponse();
    const error = Object.assign(new Error('Booking not found.'), { status: 404 });

    await withOverrides(
      [[Payment, 'createForPendingBooking', async () => { throw error; }]],
      () => paymentController.createPayment({
        body: { booking_id: '4', amount: '250' }, file: upload, user: { id: 8 }
      }, response)
    );

    assert.equal(response.statusCode, 404);
    await assert.rejects(fs.access(upload.filePath), { code: 'ENOENT' });
    await upload.cleanup();
  });

  // กรณีนี้ทดสอบ «maps duplicate payment errors to conflict»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('maps duplicate payment errors to conflict', async () => {
    const upload = await makeTemporaryFile();
    const response = createResponse();
    const duplicateError = Object.assign(new Error('duplicate'), {
      code: 'ER_DUP_ENTRY', errno: 1062
    });

    await withMutedConsoleError(() => withOverrides(
      [[Payment, 'createForPendingBooking', async () => { throw duplicateError; }]],
      () => paymentController.createPayment({
        body: { booking_id: '4', amount: '250' }, file: upload, user: { id: 8 }
      }, response)
    ));

    assert.equal(response.statusCode, 409);
    await assert.rejects(fs.access(upload.filePath), { code: 'ENOENT' });
    await upload.cleanup();
  });

  // กรณีนี้ทดสอบ «returns a server error for an unexpected payment failure»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns a server error for an unexpected payment failure', async () => {
    const upload = await makeTemporaryFile();
    const response = createResponse();

    await withMutedConsoleError(() => withOverrides(
      [[Payment, 'createForPendingBooking', async () => { throw new Error('database down'); }]],
      () => paymentController.createPayment({
        body: { booking_id: '4', amount: '250' }, file: upload, user: { id: 8 }
      }, response)
    ));

    assert.equal(response.statusCode, 500);
    await assert.rejects(fs.access(upload.filePath), { code: 'ENOENT' });
    await upload.cleanup();
  });
});

describe('paymentController.replacePaymentSlip', () => {
  // กรณีนี้ทดสอบ «updates the reference, keeps the new file, and removes the previous slip»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('updates the reference, keeps the new file, and removes the previous slip', async () => {
    const oldSlip = await makeStoredSlip();
    const newSlip = await makeTemporaryFile('replacement.png');
    const response = createResponse();

    try {
      await withOverrides(
        [[Payment, 'replaceSlipForPendingBooking', async ({ slip_url }) => {
          assert.equal(slip_url, `/uploads/slips/${newSlip.filename}`);
          return { old_slip_url: oldSlip.url };
        }]],
        () => paymentController.replacePaymentSlip({
          params: { bookingId: '4' },
          file: newSlip,
          user: { id: 8 }
        }, response)
      );

      assert.equal(response.body.payment.slip_url, `/uploads/slips/${newSlip.filename}`);
      await assert.rejects(fs.access(oldSlip.filePath), { code: 'ENOENT' });
      await fs.access(newSlip.filePath);
    } finally {
      await oldSlip.cleanup();
      await newSlip.cleanup();
    }
  });

  // กรณีนี้ทดสอบ «removes the new upload when the booking cannot be changed»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('removes the new upload when the booking cannot be changed', async () => {
    const newSlip = await makeTemporaryFile('replacement.png');
    const response = createResponse();
    const error = Object.assign(new Error('Booking is already approved.'), { status: 409 });

    await withOverrides(
      [[Payment, 'replaceSlipForPendingBooking', async () => { throw error; }]],
      () => paymentController.replacePaymentSlip({
        params: { bookingId: '4' }, file: newSlip, user: { id: 8 }
      }, response)
    );

    assert.equal(response.statusCode, 409);
    await assert.rejects(fs.access(newSlip.filePath), { code: 'ENOENT' });
    await newSlip.cleanup();
  });

  // กรณีนี้ทดสอบ «rejects an invalid booking ID and requires a new image»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('rejects an invalid booking ID and requires a new image', async () => {
    const upload = await makeTemporaryFile('replacement.png');
    const invalidResponse = createResponse();
    await paymentController.replacePaymentSlip({
      params: { bookingId: 'abc' }, file: upload, user: { id: 8 }
    }, invalidResponse);
    assert.equal(invalidResponse.statusCode, 400);
    await assert.rejects(fs.access(upload.filePath), { code: 'ENOENT' });
    await upload.cleanup();

    const missingResponse = createResponse();
    await paymentController.replacePaymentSlip({
      params: { bookingId: '4' }, user: { id: 8 }
    }, missingResponse);
    assert.equal(missingResponse.statusCode, 400);
  });

  // กรณีนี้ทดสอบ «returns a server error and cleans the new upload on unexpected failure»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns a server error and cleans the new upload on unexpected failure', async () => {
    const upload = await makeTemporaryFile('replacement.png');
    const response = createResponse();

    await withMutedConsoleError(() => withOverrides(
      [[Payment, 'replaceSlipForPendingBooking', async () => { throw new Error('database down'); }]],
      () => paymentController.replacePaymentSlip({
        params: { bookingId: '4' }, file: upload, user: { id: 8 }
      }, response)
    ));

    assert.equal(response.statusCode, 500);
    await assert.rejects(fs.access(upload.filePath), { code: 'ENOENT' });
    await upload.cleanup();
  });
});
