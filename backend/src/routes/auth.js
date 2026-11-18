const express = require('express');

const { AppError } = require('../models/appError');
const { toUserResponse } = require('../models/user');
const { ACCESS_TOKEN } = require('../middleware/auth');

const router = express.Router();

const isFilledString = (value) => typeof value === 'string' && value.trim() !== '';

router.post('/login', (req, res) => {
  const { email, password } = req.body;

  const fields = {};
  if (!isFilledString(email)) fields.email = 'Email is required';
  if (!isFilledString(password)) fields.password = 'Password is required';
  if (Object.keys(fields).length > 0) {
    throw new AppError(400, 'VALIDATION_ERROR', 'Email and password are required', fields);
  }

  // Email: trimmed, any case. Password: exact.
  const { user } = req.app.locals.store;
  const matches =
    email.trim().toLowerCase() === user.email.toLowerCase() && password === user.password;

  // One message for both cases, so a caller cannot tell which field was wrong.
  if (!matches) {
    throw new AppError(401, 'INVALID_CREDENTIALS', 'Invalid email or password');
  }

  res.json({
    success: true,
    data: { accessToken: ACCESS_TOKEN, user: toUserResponse(user) },
  });
});

module.exports = router;
