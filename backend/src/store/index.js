const seed = require('../../seed.json');

const newestFirst = (a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt);

/**
 * The in-memory state: one user, one wallet, its transactions, and the
 * idempotency keys of transfers that succeeded.
 *
 * Money is integer paise (₹25,450.75 is 2545075) so arithmetic never drifts;
 * it becomes rupees only when a response is written.
 *
 * Every call returns a fresh deep copy of the seed, so each test (and each
 * server start) begins from the same state. Nothing is written to disk.
 */
function createStore(source = seed) {
  const { user, wallet, transactions } = structuredClone(source);
  return {
    user,
    wallet,
    transactions: transactions.sort(newestFirst),
    // Idempotency-Key → { fingerprint, response } of a successful transfer.
    idempotency: new Map(),
  };
}

module.exports = { createStore };
