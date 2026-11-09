const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const removeUploadedFile = require('../../utils/removeUploadedFile');

describe('removeUploadedFile', () => {
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

  it('does nothing when no file was uploaded', async () => {
    await assert.doesNotReject(removeUploadedFile(undefined));
  });

  it('does not fail if the temporary file is already gone', async () => {
    const missingFile = path.join(os.tmpdir(), `missing-${Date.now()}.png`);

    await assert.doesNotReject(removeUploadedFile({ path: missingFile }));
  });

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
