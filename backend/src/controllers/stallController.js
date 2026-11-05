const stalls = require('../models/stallModel');

const ZONES = new Set(['A', 'B', 'C', 'D']);
const PRODUCT_TYPES = new Set(['Food', 'Drinks', 'Clothing', 'Accessories', 'Handmade', 'Other']);
const STATUSES = new Set(['available', 'unavailable']);

function normalizeStall(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return null;
  const { code, zone, size, price_per_day, product_type, status } = body;
  const price = typeof price_per_day === 'number' ? price_per_day : Number(price_per_day);
  if (typeof code !== 'string' || !code.trim() || code.trim().length > 20 ||
      typeof zone !== 'string' || !ZONES.has(zone) ||
      typeof size !== 'string' || !size.trim() || size.trim().length > 30 ||
      !Number.isFinite(price) || price <= 0 ||
      typeof product_type !== 'string' || !PRODUCT_TYPES.has(product_type) ||
      typeof status !== 'string' || !STATUSES.has(status)) return null;
  return {
    code: code.trim().toUpperCase(), zone,
    size: size.trim(), price_per_day: price,
    product_type, status,
  };
}

function validId(value) {
  return /^\d+$/.test(String(value)) && Number(value) > 0;
}

async function list(req, res) {
  try {
    const { zone, search } = req.query;
    if (zone !== undefined && !ZONES.has(zone)) return res.status(400).json({ message: 'Invalid zone' });
    const items = await stalls.findAll({ zone, search: typeof search === 'string' ? search.trim() : undefined });
    return res.json({ stalls: items });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function create(req, res) {
  const stall = normalizeStall(req.body);
  if (!stall) return res.status(400).json({ message: 'Invalid stall data' });
  try {
    return res.status(201).json({ stall: await stalls.create(stall) });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ message: 'Stall code already exists' });
    console.error(err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function update(req, res) {
  if (!validId(req.params.id)) return res.status(400).json({ message: 'Invalid stall id' });
  const stall = normalizeStall(req.body);
  if (!stall) return res.status(400).json({ message: 'Invalid stall data' });
  try {
    const updated = await stalls.update(Number(req.params.id), stall);
    if (!updated) return res.status(404).json({ message: 'Stall not found' });
    return res.json({ stall: updated });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ message: 'Stall code already exists' });
    console.error(err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function remove(req, res) {
  if (!validId(req.params.id)) return res.status(400).json({ message: 'Invalid stall id' });
  try {
    const result = await stalls.remove(Number(req.params.id));
    if (result === 'not_found') return res.status(404).json({ message: 'Stall not found' });
    if (result === 'in_use') return res.status(409).json({ message: 'Stall has upcoming bookings' });
    return res.json({ message: 'Stall deleted' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Server error' });
  }
}

module.exports = { list, create, update, remove };
