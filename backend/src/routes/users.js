const express = require('express');

const { toUserResponse } = require('../models/user');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.get('/profile', requireAuth, (req, res) => {
  res.json({ success: true, data: toUserResponse(req.app.locals.store.user) });
});

module.exports = router;
