const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const { Readable } = require('node:stream');
const createUploadMiddleware = require('../../middlewares/uploadMiddleware');
const removeUploadedFile = require('../../utils/removeUploadedFile');

function makeMultipartRequest({ filename, mimeType, bytes }) {
  const boundary = 'unit-test-boundary';
  const body = Buffer.concat([
    Buffer.from(
      `--${boundary}\r\n` +
      `Content-Disposition: form-data; name="slip"; filename="${filename}"\r\n` +
      `Content-Type: ${mimeType}\r\n\r\n`
    ),
    bytes,
    Buffer.from(`\r\n--${boundary}--\r\n`)
  ]);
  const request = Readable.from([body]);
  request.headers = {
    'content-type': `multipart/form-data; boundary=${boundary}`,
    'content-length': String(body.length)
  };
  request.method = 'POST';
  request.url = '/';
  request.body = {};
  return request;
}

function runSingleUpload(request) {
  const middleware = createUploadMiddleware('slips').single('slip');
  return new Promise((resolve) => {
    middleware(request, {}, (error) => resolve({ error, file: request.file }));
  });
}

describe('upload middleware', () => {
  // กรณีนี้ทดสอบ «only creates upload middleware for slips and profiles»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('only creates upload middleware for slips and profiles', () => {
    assert.throws(
      () => createUploadMiddleware('avatars'),
      /Unsupported upload folder/
    );
    assert.equal(typeof createUploadMiddleware('slips').single, 'function');
    assert.equal(typeof createUploadMiddleware('profiles').single, 'function');
  });

  // กรณีนี้ทดสอบ «accepts a supported image and writes it to the selected folder»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('accepts a supported image and writes it to the selected folder', async () => {
    const request = makeMultipartRequest({
      filename: 'receipt.PNG',
      mimeType: 'image/png',
      bytes: Buffer.from([0x89, 0x50, 0x4E, 0x47])
    });
    let uploadedFile;

    try {
      const result = await runSingleUpload(request);
      uploadedFile = result.file;
      assert.equal(result.error, undefined);
      assert.match(uploadedFile.filename, /\.png$/);
      assert.match(uploadedFile.path, /uploads\/slips\//);
      assert.deepEqual(await fs.readFile(uploadedFile.path), Buffer.from([0x89, 0x50, 0x4E, 0x47]));
    } finally {
      await removeUploadedFile(uploadedFile);
    }
  });

  // กรณีนี้ทดสอบ «rejects a file when its MIME type or extension is not an image»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('rejects a file when its MIME type or extension is not an image', async () => {
    const request = makeMultipartRequest({
      filename: 'document.pdf',
      mimeType: 'application/pdf',
      bytes: Buffer.from('not an image')
    });

    const result = await runSingleUpload(request);

    assert.equal(result.error.status, 415);
    assert.match(result.error.message, /Only JPEG, PNG/);
    assert.equal(result.file, undefined);
  });

  // กรณีนี้ทดสอบ «enforces the five-megabyte upload limit»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('enforces the five-megabyte upload limit', async () => {
    const request = makeMultipartRequest({
      filename: 'large.png',
      mimeType: 'image/png',
      bytes: Buffer.alloc(5 * 1024 * 1024 + 1, 0x01)
    });

    const result = await runSingleUpload(request);

    assert.equal(result.error.code, 'LIMIT_FILE_SIZE');
  });
});
