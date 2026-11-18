const { AppError } = require('../models/appError');
const { isNoRemarks } = require('./transferValidation');

/**
 * Idempotency for transfers (API-09, API-10, API-11).
 *
 * The store maps each Idempotency-Key to `{ fingerprint, response }` of the
 * transfer that succeeded with it. Only successes are remembered: a 400 or
 * 409 moved no money, so the key stays free for a corrected retry.
 *
 * No "in progress" state is needed. The transfer route is synchronous from
 * lookup to `remember`, so Node cannot start a second request with the same
 * key in between.
 */

/**
 * The key from the header, or a 400 when it is missing or blank. Node joins
 * a repeated header into "first, second", which would look like a brand-new
 * key and deduct again, so a comma is rejected too (a UUID never has one).
 */
function requireKey(req) {
  const key = req.get('Idempotency-Key');
  if (!key || key.trim() === '') {
    throw new AppError(400, 'IDEMPOTENCY_KEY_REQUIRED', 'Idempotency-Key header is required');
  }
  if (key.includes(',')) {
    throw new AppError(400, 'IDEMPOTENCY_KEY_REQUIRED', 'Send exactly one Idempotency-Key header');
  }
  return key;
}

/**
 * What "the same payload" means: the four transfer fields as sent, in a
 * fixed order. Extra fields and key order don't matter, and "no remarks"
 * follows the validator's rule (isNoRemarks). Other values are compared as
 * sent, so " Rahul" and "Rahul" differ.
 */
function fingerprint(body) {
  const { beneficiaryName, mobileNumber, amount, remarks } = body;
  return JSON.stringify([beneficiaryName, mobileNumber, amount, isNoRemarks(remarks) ? null : remarks]);
}

/**
 * The stored response when this key already succeeded with this payload;
 * null when the key is new; a 409 when it was used with a different payload.
 */
function findReplay(store, key, print) {
  const saved = store.idempotency.get(key);
  if (!saved) return null;
  if (saved.fingerprint !== print) {
    throw new AppError(409, 'IDEMPOTENCY_KEY_REUSED', 'Idempotency-Key was already used with a different payload');
  }
  return saved.response;
}

function remember(store, key, print, response) {
  store.idempotency.set(key, { fingerprint: print, response });
}

module.exports = { requireKey, fingerprint, findReplay, remember };
