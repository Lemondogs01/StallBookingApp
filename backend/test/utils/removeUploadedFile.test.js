const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const removeUploadedFile = require('../../utils/removeUploadedFile');

describe('removeUploadedFile', () => {
  // กรณีนี้ทดสอบ «deletes the file provided by the upload middleware»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('deletes the file provided by the upload middleware', async () => {
    const folder = await fs.mkdtemp(path.join(os.tmpdir(), 'mfu-upload-test-'));
    const filePath = path.join(folder, 'sample.png');

    try {
      await fs.writeFile(filePath, 'temporary test image');
      await removeUploadedFile({ path: filePath });

      await assert.rejects(fs.access(filePath), { code: 'ENOENT' });
    } finally {
      await fs.rm(folder, { recursive: true, force: true });
    }
  });

  // กรณีนี้ทดสอบ «does nothing when no file was uploaded»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('does nothing when no file was uploaded', async () => {
    await assert.doesNotReject(removeUploadedFile(undefined));
  });

  // กรณีนี้ทดสอบ «does not fail if the temporary file is already gone»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('does not fail if the temporary file is already gone', async () => {
    const missingFile = path.join(os.tmpdir(), `missing-${Date.now()}.png`);

    await assert.doesNotReject(removeUploadedFile({ path: missingFile }));
  });

  // กรณีนี้ทดสอบ «logs and tolerates an operating-system error during cleanup»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('logs and tolerates an operating-system error during cleanup', async () => {
    const folder = await fs.mkdtemp(path.join(os.tmpdir(), 'mfu-upload-test-'));
    const originalConsoleError = console.error;
    let loggedFailure = false;
    console.error = () => { loggedFailure = true; };

    try {
      await removeUploadedFile({ path: folder });
      assert.equal(loggedFailure, true);
    } finally {
      console.error = originalConsoleError;
      await fs.rm(folder, { recursive: true, force: true });
    }
  });
});
