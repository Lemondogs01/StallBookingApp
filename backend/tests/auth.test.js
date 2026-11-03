process.env.JWT_SECRET = 'test_secret_for_jwt_at_least_32_characters_long';
process.env.JWT_EXPIRES_IN = '1h';
jest.mock('../src/models/userModel');
const users = require('../src/models/userModel');
const argon2 = require('argon2');
const request = require('supertest');
const app = require('../src/app');
let vendor, admin;

beforeAll(async () => {
  const password_hash = await argon2.hash('CorrectPassword123!', { type: argon2.argon2id });
  vendor = { user_id: 1, username: 'vendor1', full_name: 'Vendor One', phone: null, email: null, role: 'vendor', password_hash };
  admin = { ...vendor, user_id: 2, username: 'admin1', role: 'admin' };
});

beforeEach(() => {
  jest.resetAllMocks();
  users.findByUsername.mockImplementation(async username => ({ vendor1: vendor, admin1: admin })[username] || null);
  users.findById.mockImplementation(async id => {
    const user = String(id) === '1' ? vendor : String(id) === '2' ? admin : null;
    if (!user) return null;
    const { password_hash, ...safe } = user;
    return safe;
  });
  users.createUser.mockResolvedValue(3);
  users.updateProfile.mockImplementation(async (id, fields) => ({ ...vendor, full_name: fields.fullName, phone: fields.phone, email: fields.email }));
});

async function tokenFor(username) {
  const res = await request(app).post('/api/auth/login').send({ username, password: 'CorrectPassword123!' });
  expect(res.status).toBe(200);
  return res.body.token;
}

test('register creates vendor even if role admin is requested', async () => {
  const res = await request(app).post('/api/auth/register').send({ username: 'newvendor', password: 'StrongPass123!', full_name: 'New Vendor', role: 'admin' });
  expect(res.status).toBe(201);
  expect(res.body.user.role).toBe('vendor');
  expect(users.createUser.mock.calls[0][0].passwordHash).toMatch(/^\$argon2id\$/);
});

test('duplicate username returns 409', async () => {
  const res = await request(app).post('/api/auth/register').send({ username: 'vendor1', password: 'StrongPass123!', full_name: 'Test' });
  expect(res.status).toBe(409);
});

test('short password returns 400', async () => {
  const res = await request(app).post('/api/auth/register').send({ username: 'someone', password: '123', full_name: 'Test' });
  expect(res.status).toBe(400);
});

test('login returns JWT', async () => {
  const res = await request(app).post('/api/auth/login').send({ username: 'vendor1', password: 'CorrectPassword123!' });
  expect(res.status).toBe(200);
  expect(res.body.token).toEqual(expect.any(String));
  expect(res.body.user.password_hash).toBeUndefined();
});

test('wrong password returns 401', async () => {
  const res = await request(app).post('/api/auth/login').send({ username: 'vendor1', password: 'wrong' });
  expect(res.status).toBe(401);
});

test('profile without token returns 401', async () => {
  expect((await request(app).get('/api/auth/profile')).status).toBe(401);
});

test('profile returns safe user', async () => {
  const token = await tokenFor('vendor1');
  const res = await request(app).get('/api/auth/profile').set('Authorization', `Bearer ${token}`);
  expect(res.status).toBe(200);
  expect(res.body.user.username).toBe('vendor1');
  expect(res.body.user.password_hash).toBeUndefined();
});

test('vendor cannot access admin endpoint', async () => {
  const token = await tokenFor('vendor1');
  expect((await request(app).get('/api/auth/admin-only').set('Authorization', `Bearer ${token}`)).status).toBe(403);
});

test('admin can access admin endpoint', async () => {
  const token = await tokenFor('admin1');
  expect((await request(app).get('/api/auth/admin-only').set('Authorization', `Bearer ${token}`)).status).toBe(200);
});

test('update profile', async () => {
  const token = await tokenFor('vendor1');
  const res = await request(app).put('/api/auth/profile').set('Authorization', `Bearer ${token}`)
    .send({ full_name: 'Updated Vendor', phone: '0812345678' });
  expect(res.status).toBe(200);
  expect(res.body.user.full_name).toBe('Updated Vendor');
});

test('logout revokes token', async () => {
  const token = await tokenFor('vendor1');
  expect((await request(app).post('/api/auth/logout').set('Authorization', `Bearer ${token}`)).status).toBe(200);
  expect((await request(app).get('/api/auth/profile').set('Authorization', `Bearer ${token}`)).status).toBe(401);
});
