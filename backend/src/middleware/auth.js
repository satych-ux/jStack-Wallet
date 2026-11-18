const { AppError } = require('../models/appError');

/** The only token the mock accepts (SPEC.md section 4). No expiry, no signing. */
const ACCESS_TOKEN = 'mock_access_token_123';

/** Guards a protected route: the header must be exactly `Bearer <token>`. */
function requireAuth(req, res, next) {
  if (req.get('Authorization') !== `Bearer ${ACCESS_TOKEN}`) {
    return next(new AppError(401, 'UNAUTHORIZED', 'Missing or invalid access token'));
  }
  next();
}

module.exports = { ACCESS_TOKEN, requireAuth };
