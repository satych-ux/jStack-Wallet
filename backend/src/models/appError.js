/**
 * An error the API answers on purpose: it carries the HTTP status and the
 * `error` body to send. Anything that is not an AppError is a bug and
 * becomes a 500.
 */
class AppError extends Error {
  /**
   * @param {number} status HTTP status, e.g. 404
   * @param {string} code machine-readable, e.g. 'TRANSACTION_NOT_FOUND'
   * @param {string} message human-readable
   * @param {Record<string, string>} [fields] per-field messages for a 400
   */
  constructor(status, code, message, fields) {
    super(message);
    this.status = status;
    this.code = code;
    this.fields = fields;
  }
}

module.exports = { AppError };
