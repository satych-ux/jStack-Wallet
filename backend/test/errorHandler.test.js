const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const request = require('supertest');

const { errorHandler } = require('../src/middleware/errorHandler');
const { AppError } = require('../src/models/appError');

// A bare app with one throwing route, so the handler is tested on its own.
function appThatThrows(error) {
  const app = express();
  app.get('/boom', () => {
    throw error;
  });
  app.use(errorHandler);
  return app;
}

test('an unexpected error returns 500 with no stack trace in the body', async (t) => {
  t.mock.method(console, 'error', () => {}); // keep the test output quiet
  const res = await request(appThatThrows(new Error('secret detail'))).get('/boom');

  assert.equal(res.status, 500);
  assert.equal(res.body.success, false);
  assert.equal(res.body.error.code, 'INTERNAL_ERROR');
  assert.equal(res.body.error.stack, undefined);
  assert.equal(res.body.stack, undefined);
  assert.doesNotMatch(JSON.stringify(res.body), /secret detail|at .*\.js/);
});

test('an AppError keeps its status, code, message and fields', async () => {
  const error = new AppError(400, 'VALIDATION_ERROR', 'Invalid request', {
    amount: 'Must be greater than 0',
  });
  const res = await request(appThatThrows(error)).get('/boom');

  assert.equal(res.status, 400);
  assert.deepEqual(res.body, {
    success: false,
    error: {
      code: 'VALIDATION_ERROR',
      message: 'Invalid request',
      fields: { amount: 'Must be greater than 0' },
    },
  });
});

test('an AppError without fields leaves fields out', async () => {
  const res = await request(
    appThatThrows(new AppError(404, 'TRANSACTION_NOT_FOUND', 'Not found')),
  ).get('/boom');

  assert.equal(res.status, 404);
  assert.deepEqual(res.body, {
    success: false,
    error: { code: 'TRANSACTION_NOT_FOUND', message: 'Not found' },
  });
});
