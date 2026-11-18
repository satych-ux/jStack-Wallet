const express = require('express');

const { AppError } = require('../models/appError');
const { toTransactionResponse, toTransferResponse } = require('../models/transaction');
const { validateTransfer } = require('../services/transferValidation');
const { performTransfer } = require('../services/transfer');
const { requireKey, fingerprint, findReplay, remember } = require('../services/idempotency');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

// The store keeps transactions newest first, so the list goes out as is
// (API-05).
router.get('/', (req, res) => {
  const { transactions } = req.app.locals.store;
  res.json({ success: true, data: transactions.map(toTransactionResponse) });
});

// POST, so it never collides with GET /:id.
//
// One synchronous block from the key lookup to `remember`: no other request
// can run in between, so one key can never cause two deductions. Keep this
// handler synchronous: in Express 4 an `async` handler's errors never reach
// the error handler.
router.post('/transfer', (req, res) => {
  const { store } = req.app.locals;
  const key = requireKey(req);
  const print = fingerprint(req.body);

  // A used key wins over validation: a different, invalid body is a 409.
  const replay = findReplay(store, key, print);
  if (replay) return res.json(replay);

  // A 400 or 409 thrown here leaves the key unused, free for a retry.
  const transaction = performTransfer(store, validateTransfer(req.body));
  const response = toTransferResponse(transaction, store.wallet.balancePaise);
  remember(store, key, print, response);
  res.json(response);
});

router.get('/:id', (req, res) => {
  const found = req.app.locals.store.transactions.find((t) => t.id === req.params.id);
  if (!found) {
    throw new AppError(404, 'TRANSACTION_NOT_FOUND', 'Transaction not found');
  }
  res.json({ success: true, data: toTransactionResponse(found) });
});

module.exports = router;
