const { AppError } = require('../models/appError');

const REMARKS_MAX_LENGTH = 100;
const MOBILE_PATTERN = /^[0-9]{10}$/; // any 10 digits (backend decision 10)

// A number written the shortest way JS prints it (1500.50 prints "1500.5")
// with at most 2 decimals. Exponent forms like 1e-7 or 1e+21 never match.
const AT_MOST_2_DECIMALS = /^\d+(\.\d{1,2})?$/;

/**
 * Checks a transfer body (API-06). Returns clean values, with the amount as
 * integer paise, or throws one 400 that names every bad field at once.
 */
function validateTransfer(body) {
  const { beneficiaryName, mobileNumber, amount, remarks } = body;
  const fields = {};

  if (typeof beneficiaryName !== 'string' || beneficiaryName.trim() === '') {
    fields.beneficiaryName = 'Beneficiary name is required';
  }

  if (typeof mobileNumber !== 'string' || !MOBILE_PATTERN.test(mobileNumber)) {
    fields.mobileNumber = 'Mobile number must be exactly 10 digits';
  }

  const amountError = checkAmount(amount);
  if (amountError) fields.amount = amountError;

  let cleanRemarks = null;
  if (isNoRemarks(remarks)) {
    // stays null
  } else if (typeof remarks !== 'string') {
    fields.remarks = 'Remarks must be text';
  } else {
    cleanRemarks = remarks.trim();
    // Count characters, not UTF-16 units: an emoji is one character but
    // `.length` 2. Spreading a string splits it into characters.
    if ([...cleanRemarks].length > REMARKS_MAX_LENGTH) {
      fields.remarks = `Remarks must be ${REMARKS_MAX_LENGTH} characters or fewer`;
    }
  }

  if (Object.keys(fields).length > 0) {
    throw new AppError(400, 'VALIDATION_ERROR', 'Invalid transfer details', fields);
  }

  return {
    beneficiaryName: beneficiaryName.trim(),
    mobileNumber,
    amountPaise: Math.round(amount * 100),
    remarks: cleanRemarks,
  };
}

/**
 * Absent, null, empty and spaces-only all mean "no remarks" (stored as
 * null). Shared with the idempotency check, so both agree on it.
 */
function isNoRemarks(remarks) {
  return remarks === undefined || remarks === null || (typeof remarks === 'string' && remarks.trim() === '');
}

/**
 * The error message for a bad amount, or null when it is valid.
 *
 * Once an amount has at most 2 decimals, `Math.round(amount * 100)` gives its
 * exact paise (0.07 × 100 = 7.000000000000001 rounds to 7). That holds up to
 * about ₹35 trillion; above it a float can be a paisa off, but any such
 * amount is far beyond a balance and gets a 409 anyway.
 */
function checkAmount(amount) {
  if (typeof amount !== 'number') return 'Amount must be a number';
  if (!(amount > 0)) return 'Amount must be greater than 0';
  if (!AT_MOST_2_DECIMALS.test(String(amount))) return 'Amount can have at most 2 decimal places';
  if (!Number.isSafeInteger(Math.round(amount * 100))) return 'Amount is too large';
  return null;
}

module.exports = { validateTransfer, isNoRemarks, REMARKS_MAX_LENGTH };
