const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { randomUUID } = require('node:crypto');
const argon2 = require('argon2');
const User = require('../../models/User');
const userController = require('../../controllers/userController');
const { withOverrides, withMutedConsoleError } = require('../../test-support/controllerHarness');

const profileDirectory = path.join(__dirname, '../../uploads/profiles');

async function makeProfileImage() {
  await fs.mkdir(profileDirectory, { recursive: true });
  const filename = `unit-${randomUUID()}.png`;
  const filePath = path.join(profileDirectory, filename);
  await fs.writeFile(filePath, 'temporary test image');

  return {
    filename,
    filePath,
    url: `/uploads/profiles/${filename}`,
    async cleanup() {
      await fs.rm(filePath, { force: true });
    }
  };
}

function makeResponse() {
  return {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    }
  };
}

async function withFakeUserModel({ findById, updateProfile }, run) {
  const originalFindById = User.findById;
  const originalUpdateProfile = User.updateProfile;
  User.findById = findById;
  User.updateProfile = updateProfile;

  try {
    await run();
  } finally {
    User.findById = originalFindById;
    User.updateProfile = originalUpdateProfile;
  }
}

describe('userController.updateProfile', () => {
  // กรณีนี้ทดสอบ «removes a new upload when the profile is missing or submitted fields are invalid»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('removes a new upload when the profile is missing or submitted fields are invalid', async () => {
    const invalidBodies = [
      { shop_name: 4 },
      { shop_name: '   ' },
      { shop_name: 's'.repeat(101) },
      { real_name: 'r'.repeat(101) },
      { phone: '123' },
      { phone: '1'.repeat(21) }
    ];

    for (const body of invalidBodies) {
      const upload = await makeProfileImage();
      const response = makeResponse();
      try {
        await withFakeUserModel(
          {
            findById: async () => ({ id: 5, profile_image: null }),
            updateProfile: async () => assert.fail('invalid values should not be saved')
          },
          () => userController.updateProfile({
            user: { id: 5 }, body,
            file: { path: upload.filePath, filename: upload.filename }
          }, response)
        );

        assert.equal(response.statusCode, 400);
        await assert.rejects(fs.access(upload.filePath), { code: 'ENOENT' });
      } finally {
        await upload.cleanup();
      }
    }
  });

  // กรณีนี้ทดสอบ «removes an upload when the user is missing and rejects an empty update»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('removes an upload when the user is missing and rejects an empty update', async () => {
    const upload = await makeProfileImage();
    const missingUserResponse = makeResponse();

    try {
      await withFakeUserModel(
        {
          findById: async () => undefined,
          updateProfile: async () => assert.fail('a missing account cannot be updated')
        },
        () => userController.updateProfile({
          user: { id: 5 }, body: {},
          file: { path: upload.filePath, filename: upload.filename }
        }, missingUserResponse)
      );

      assert.equal(missingUserResponse.statusCode, 404);
      await assert.rejects(fs.access(upload.filePath), { code: 'ENOENT' });
    } finally {
      await upload.cleanup();
    }

    const emptyResponse = makeResponse();
    await withFakeUserModel(
      {
        findById: async () => ({ id: 5, profile_image: null }),
        updateProfile: async () => assert.fail('an empty update should not be saved')
      },
      () => userController.updateProfile({ user: { id: 5 }, body: {} }, emptyResponse)
    );
    assert.equal(emptyResponse.statusCode, 400);
  });

  // กรณีนี้ทดสอบ «uses the new profile image and removes the old image after saving»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('uses the new profile image and removes the old image after saving', async () => {
    const oldImage = await makeProfileImage();
    const newImage = await makeProfileImage();
    let savedUser = { id: 5, profile_image: oldImage.url };
    const response = makeResponse();

    try {
      await withFakeUserModel(
        {
          findById: async () => ({ ...savedUser }),
          updateProfile: async (_id, changes) => {
            savedUser = { ...savedUser, ...changes };
          }
        },
        async () => {
          await userController.updateProfile(
            {
              user: { id: 5 },
              body: {},
              file: { path: newImage.filePath, filename: newImage.filename }
            },
            response
          );
        }
      );

      assert.equal(response.statusCode, 200);
      assert.equal(savedUser.profile_image, newImage.url);
      assert.equal(response.body.user.profile_image, newImage.url);
      await assert.rejects(fs.access(oldImage.filePath), { code: 'ENOENT' });
      await fs.access(newImage.filePath);
    } finally {
      await oldImage.cleanup();
      await newImage.cleanup();
    }
  });

  // กรณีนี้ทดสอบ «keeps the old image and removes the new upload if saving fails»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('keeps the old image and removes the new upload if saving fails', async () => {
    const oldImage = await makeProfileImage();
    const newImage = await makeProfileImage();
    const response = makeResponse();
    const originalConsoleError = console.error;
    console.error = () => {};

    try {
      await withFakeUserModel(
        {
          findById: async () => ({ id: 5, profile_image: oldImage.url }),
          updateProfile: async () => {
            throw new Error('Database unavailable');
          }
        },
        async () => {
          await userController.updateProfile(
            {
              user: { id: 5 },
              body: {},
              file: { path: newImage.filePath, filename: newImage.filename }
            },
            response
          );
        }
      );

      assert.equal(response.statusCode, 500);
      await fs.access(oldImage.filePath);
      await assert.rejects(fs.access(newImage.filePath), { code: 'ENOENT' });
    } finally {
      console.error = originalConsoleError;
      await oldImage.cleanup();
      await newImage.cleanup();
    }
  });
});

describe('userController.getProfile', () => {
  // กรณีนี้ทดสอบ «returns the current user profile»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns the current user profile', async () => {
    const response = makeResponse();
    const user = { id: 5, username: 'vendor5', role: 'vendor' };

    await withOverrides(
      [[User, 'findById', async () => user]],
      () => userController.getProfile({ user: { id: 5 } }, response)
    );

    assert.equal(response.body, user);
  });

  // กรณีนี้ทดสอบ «returns not found for a deleted user»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns not found for a deleted user', async () => {
    const response = makeResponse();

    await withOverrides(
      [[User, 'findById', async () => undefined]],
      () => userController.getProfile({ user: { id: 5 } }, response)
    );

    assert.equal(response.statusCode, 404);
  });

  // กรณีนี้ทดสอบ «returns a server error when profile lookup fails»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns a server error when profile lookup fails', async () => {
    const response = makeResponse();

    await withMutedConsoleError(() => withOverrides(
      [[User, 'findById', async () => { throw new Error('database down'); }]],
      () => userController.getProfile({ user: { id: 5 } }, response)
    ));

    assert.equal(response.statusCode, 500);
  });
});

describe('userController.changePassword', () => {
  // กรณีนี้ทดสอบ «validates required fields and password length»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('validates required fields and password length', async () => {
    for (const { body, expectedStatus } of [
      { body: {}, expectedStatus: 400 },
      { body: { current_password: 'old', new_password: 'short' }, expectedStatus: 400 }
    ]) {
      const response = makeResponse();
      await userController.changePassword({ user: { id: 5 }, body }, response);
      assert.equal(response.statusCode, expectedStatus);
    }
  });

  // กรณีนี้ทดสอบ «returns not found if the account no longer exists»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns not found if the account no longer exists', async () => {
    const response = makeResponse();

    await withOverrides(
      [[User, 'findPasswordHashById', async () => undefined]],
      () => userController.changePassword({
        user: { id: 5 }, body: { current_password: 'old-password', new_password: 'new-password' }
      }, response)
    );

    assert.equal(response.statusCode, 404);
  });

  // กรณีนี้ทดสอบ «rejects a wrong current password and reusing the current password»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('rejects a wrong current password and reusing the current password', async () => {
    const wrongPasswordResponse = makeResponse();
    await withOverrides(
      [
        [User, 'findPasswordHashById', async () => ({ password_hash: 'hash' })],
        [argon2, 'verify', async () => false]
      ],
      () => userController.changePassword({
        user: { id: 5 }, body: { current_password: 'wrong-password', new_password: 'new-password' }
      }, wrongPasswordResponse)
    );
    assert.equal(wrongPasswordResponse.statusCode, 401);

    const samePasswordResponse = makeResponse();
    await withOverrides(
      [
        [User, 'findPasswordHashById', async () => ({ password_hash: 'hash' })],
        [argon2, 'verify', async () => true]
      ],
      () => userController.changePassword({
        user: { id: 5 }, body: { current_password: 'same-password', new_password: 'same-password' }
      }, samePasswordResponse)
    );
    assert.equal(samePasswordResponse.statusCode, 400);
  });

  // กรณีนี้ทดสอบ «hashes and saves a different password»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('hashes and saves a different password', async () => {
    const response = makeResponse();
    let savedHash;

    await withOverrides(
      [
        [User, 'findPasswordHashById', async () => ({ password_hash: 'old-hash' })],
        [argon2, 'verify', async () => true],
        [argon2, 'hash', async (_password, options) => {
          assert.equal(options.type, argon2.argon2id);
          return 'new-hash';
        }],
        [User, 'updatePassword', async (_id, hash) => { savedHash = hash; }]
      ],
      () => userController.changePassword({
        user: { id: 5 }, body: { current_password: 'old-password', new_password: 'new-password' }
      }, response)
    );

    assert.equal(savedHash, 'new-hash');
    assert.match(response.body.message, /changed successfully/);
  });

  // กรณีนี้ทดสอบ «returns a server error when password storage fails»: ดูข้อมูลจำลองที่เตรียมไว้ในตัวกรณี และตรวจ assertions ด้านล่างเพื่อยืนยันผลลัพธ์หรือข้อผิดพลาดที่คาดหวัง
  it('returns a server error when password storage fails', async () => {
    const response = makeResponse();

    await withMutedConsoleError(() => withOverrides(
      [[User, 'findPasswordHashById', async () => { throw new Error('database down'); }]],
      () => userController.changePassword({
        user: { id: 5 }, body: { current_password: 'old-password', new_password: 'new-password' }
      }, response)
    ));

    assert.equal(response.statusCode, 500);
  });
});
