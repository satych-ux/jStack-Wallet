const { AppError } = require('../models/appError');

/**
 * Moves money out of the wallet (API-07, API-08, API-12).
 *
 * Fully synchronous on purpose: nothing can run between reading the balance
 * and writing it, so two requests can never both pass the check and
 * overdraw. Do not add an `await` in here.
 *
 * Order matters: check, build the record, and only then change the store.
 * The last two lines are the only writes, and neither can throw, so a
 * failure anywhere earlier leaves the balance and the list untouched.
 *
 * @param store the in-memory store
 * @param input validated values from validateTransfer
 * @returns the new transaction, as stored
 */
function performTransfer(store, { beneficiaryName, mobileNumber, amountPaise, remarks }) {
  const { wallet, transactions } = store;

  if (amountPaise > wallet.balancePaise) {
    throw new AppError(409, 'INSUFFICIENT_BALANCE', 'Amount exceeds available balance');
  }

  const transaction = {
    id: nextTransactionId(transactions),
    type: 'DEBIT',
    status: 'SUCCESS',
    amountPaise,
    currency: wallet.currency,
    counterpartyName: beneficiaryName,
    mobileNumber,
    remarks,
    createdAt: new Date().toISOString(),
  };

  wallet.balancePaise -= amountPaise;
  // Newest first: prepending keeps the list sorted without re-sorting.
  transactions.unshift(transaction);
  return transaction;
}

/** One above the highest existing id: TXN10012 → TXN10013. */
function nextTransactionId(transactions) {
  let highest = 0;
  for (const t of transactions) {
    highest = Math.max(highest, Number(t.id.slice(3)));
  }
  return `TXN${highest + 1}`;
}

module.exports = { performTransfer };
