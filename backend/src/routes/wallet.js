const express = require('express');

const { toWalletResponse } = require('../models/wallet');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

// Read from the store on every request, never cached (API-04).
router.get('/balance', (req, res) => {
  res.json({ success: true, data: toWalletResponse(req.app.locals.store.wallet) });
});

module.exports = router;
