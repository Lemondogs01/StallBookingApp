const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { randomUUID } = require('node:crypto');
const removeUploadedFileUrl = require('../../utils/removeUploadedFileUrl');

const uploadsRoot = path.join(__dirname, '../../uploads');

async function makeUploadFixture(folder) {
  const directory = path.join(uploadsRoot, folder);
  let directoryExisted = true;

  try {
    await fs.access(directory);
  } catch {
    directoryExisted = false;
  }

  await fs.mkdir(directory, { recursive: true });
  const filename = `unit-${randomUUID()}.png`;
  const filePath = path.join(directory, filename);
  await fs.writeFile(filePath, 'temporary test image');

  return {
    filePath,
    url: `/uploads/${folder}/${filename}`,
    async cleanup() {
      await fs.rm(filePath, { force: true });
      if (!directoryExisted) {
        await fs.rmdir(directory).catch(() => {});
      }
    }
  };
}

describe('removeUploadedFileUrl', () => {
  // กรณีนี้ทดสอบ «deletes the old profile image referenced by its local upload URL»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('deletes the old profile image referenced by its local upload URL', async () => {
    const fixture = await makeUploadFixture('profiles');

    try {
      await removeUploadedFileUrl(fixture.url, 'profiles');

      await assert.rejects(fs.access(fixture.filePath), { code: 'ENOENT' });
    } finally {
      await fixture.cleanup();
    }
  });

  // กรณีนี้ทดสอบ «deletes the old payment slip referenced by its local upload URL»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('deletes the old payment slip referenced by its local upload URL', async () => {
    const fixture = await makeUploadFixture('slips');

    try {
      await removeUploadedFileUrl(fixture.url, 'slips');

      await assert.rejects(fs.access(fixture.filePath), { code: 'ENOENT' });
    } finally {
      await fixture.cleanup();
    }
  });

  // กรณีนี้ทดสอบ «keeps files when a URL is outside the allowed folder or is not local»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('keeps files when a URL is outside the allowed folder or is not local', async () => {
    const fixture = await makeUploadFixture('profiles');

    try {
      await removeUploadedFileUrl(fixture.url, 'slips');
      await removeUploadedFileUrl(`https://example.test${fixture.url}`, 'profiles');
      await removeUploadedFileUrl(
        fixture.url.replace('/profiles/', '/profiles/../profiles/'),
        'profiles'
      );

      await fs.access(fixture.filePath);
    } finally {
      await fixture.cleanup();
    }
  });
});
