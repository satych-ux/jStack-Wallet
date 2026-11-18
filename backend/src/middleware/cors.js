/**
 * Permissive CORS (backend decision 17). The app doesn't need it, but Bruno,
 * Swagger UI and browsers do. A preflight (OPTIONS) is answered here, before
 * the auth check, because browsers never send the token with it.
 */
function cors(req, res, next) {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type, Idempotency-Key');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
}

module.exports = { cors };
