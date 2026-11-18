const { AppError } = require('../models/appError');

/** Any route nothing else matched. */
function notFound(req, res, next) {
  next(new AppError(404, 'NOT_FOUND', `No route for ${req.method} ${req.path}`));
}

/**
 * The only place an error response is written, so every error has the same
 * shape: { success: false, error: { code, message, fields? } }.
 * The stack trace goes to the server log, never into the body.
 */
// Express recognises an error handler by its four parameters, so `next`
// must stay even though it is unused.
function errorHandler(err, req, res, next) {
  if (err instanceof AppError) {
    const error = { code: err.code, message: err.message };
    if (err.fields) error.fields = err.fields;
    return res.status(err.status).json({ success: false, error });
  }

  // express.json() could not parse the body.
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({
      success: false,
      error: { code: 'VALIDATION_ERROR', message: 'Request body is not valid JSON' },
    });
  }

  // Any other 4xx raised before our code ran is the client's fault, not a
  // bug, so it is a 400 (the contract's status for bad request data), not a
  // 500. express.json() tags its errors with a `type`: too large, unknown
  // charset or encoding. Untagged ones come from Express itself, e.g. a
  // malformed %-escape in the URL.
  if (err.status >= 400 && err.status < 500) {
    const message = err.type ? 'Request body could not be read' : 'Invalid request';
    return res.status(400).json({
      success: false,
      error: { code: 'VALIDATION_ERROR', message },
    });
  }

  console.error(err);
  return res.status(500).json({
    success: false,
    error: { code: 'INTERNAL_ERROR', message: 'Something went wrong' },
  });
}

module.exports = { notFound, errorHandler };
