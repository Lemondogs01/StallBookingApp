const jwt = require('jsonwebtoken');
const revokedTokens = new Set(); //  resets when server restarts.

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token || revokedTokens.has(token)) return res.status(401).json({ message: 'Unauthorized' });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    req.token = token;
    next();
  } catch (_) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

function requireAdmin(req, res, next) {
  if (req.user.role !== 'admin') return res.status(403).json({ message: 'Admin only' });
  next();
}

function revokeToken(token) { revokedTokens.add(token); }
module.exports = { requireAuth, requireAdmin, revokeToken };
