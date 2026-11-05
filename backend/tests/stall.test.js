process.env.JWT_SECRET = 'test_secret_for_jwt_at_least_32_characters_long';
jest.mock('../src/models/stallModel');

const jwt = require('jsonwebtoken');
const request = require('supertest');
const stalls = require('../src/models/stallModel');
const app = require('../src/app');

const adminToken = jwt.sign({ user_id: 2, role: 'admin' }, process.env.JWT_SECRET);
const vendorToken = jwt.sign({ user_id: 1, role: 'vendor' }, process.env.JWT_SECRET);
const auth = token => ({ Authorization: `Bearer ${token}` });
const sampleStall = {
  id: 1, code: 'A1', zone: 'A', size: '3x3 m', price_per_day: 180,
  product_type: 'Food', status: 'available',
};
const validDraft = {
  code: ' a2 ', zone: 'A', size: '3x3 m', price_per_day: 180,
  product_type: 'Food', status: 'available',
};

beforeEach(() => jest.resetAllMocks());

test('stall routes require an authenticated admin', async () => {
  expect((await request(app).get('/api/stalls')).status).toBe(401);
  expect((await request(app).get('/api/stalls').set(auth(vendorToken))).status).toBe(403);
});

test('lists stalls and passes frontend filters to model', async () => {
  stalls.findAll.mockResolvedValue([sampleStall]);
  const res = await request(app).get('/api/stalls?zone=A&search=food').set(auth(adminToken));
  expect(res.status).toBe(200);
  expect(res.body.stalls).toEqual([sampleStall]);
  expect(stalls.findAll).toHaveBeenCalledWith({ zone: 'A', search: 'food' });
});

test('rejects invalid zone filter', async () => {
  expect((await request(app).get('/api/stalls?zone=Z').set(auth(adminToken))).status).toBe(400);
  expect(stalls.findAll).not.toHaveBeenCalled();
});

test('creates a stall after validating and normalizing frontend fields', async () => {
  stalls.create.mockResolvedValue({ ...sampleStall, id: 2, code: 'A2' });
  const res = await request(app).post('/api/stalls').set(auth(adminToken)).send(validDraft);
  expect(res.status).toBe(201);
  expect(res.body.stall.code).toBe('A2');
  expect(stalls.create).toHaveBeenCalledWith({
    code: 'A2', zone: 'A', size: '3x3 m', price_per_day: 180,
    product_type: 'Food', status: 'available',
  });
});

test('rejects invalid stall fields', async () => {
  const res = await request(app).post('/api/stalls').set(auth(adminToken))
    .send({ ...validDraft, price_per_day: 0 });
  expect(res.status).toBe(400);
  expect(stalls.create).not.toHaveBeenCalled();
});

test('duplicate stall code returns conflict', async () => {
  stalls.create.mockRejectedValue({ code: 'ER_DUP_ENTRY' });
  const res = await request(app).post('/api/stalls').set(auth(adminToken)).send(validDraft);
  expect(res.status).toBe(409);
});

test('updates an existing stall', async () => {
  stalls.update.mockResolvedValue({ ...sampleStall, code: 'A2' });
  const res = await request(app).put('/api/stalls/1').set(auth(adminToken)).send(validDraft);
  expect(res.status).toBe(200);
  expect(res.body.stall.code).toBe('A2');
  expect(stalls.update).toHaveBeenCalledWith(1, expect.objectContaining({ code: 'A2' }));
});

test('returns not found when updating a missing stall', async () => {
  stalls.update.mockResolvedValue(null);
  expect((await request(app).put('/api/stalls/44').set(auth(adminToken)).send(validDraft)).status).toBe(404);
});

test('deletes stalls and blocks those with upcoming bookings', async () => {
  stalls.remove.mockResolvedValueOnce('deleted').mockResolvedValueOnce('in_use');
  expect((await request(app).delete('/api/stalls/1').set(auth(adminToken))).status).toBe(200);
  expect((await request(app).delete('/api/stalls/2').set(auth(adminToken))).status).toBe(409);
});

test('returns not found when deleting a missing stall', async () => {
  stalls.remove.mockResolvedValue('not_found');
  expect((await request(app).delete('/api/stalls/99').set(auth(adminToken))).status).toBe(404);
});
