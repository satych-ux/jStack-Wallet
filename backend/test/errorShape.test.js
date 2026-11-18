const { test } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { v4: uuid } = require('uuid');

const { createApp } = require('../src/app');
const { createStore } = require('../src/store');

// API-14: one error shape everywhere. Every code the API can send, with the
// HTTP status it belongs to (SPEC.md section 4 status list).
const CODES = {
  VALIDATION_ERROR: 400,
  IDEMPOTENCY_KEY_REQUIRED: 400,
  INVALID_CREDENTIALS: 401,
  UNAUTHORIZED: 401,
  NOT_FOUND: 404,
  TRANSACTION_NOT_FOUND: 404,
  INSUFFICIENT_BALANCE: 409,
  IDEMPOTENCY_KEY_REUSED: 409,
  INTERNAL_ERROR: 500,
};

const AUTH = { Authorization: 'Bearer mock_access_token_123' };
const VALID = { beneficiaryName: 'Rahul Sharma', mobileNumber: '9876543210', amount: 1500 };

/** Every error path in the API, each producing one error response. */
const errorCases = {
  'login, missing fields': (s) => request(s).post('/api/v1/auth/login').send({}),
  'login, wrong password': (s) => request(s).post('/api/v1/auth/login').send({ email: 'demo@jstack.co', password: 'x' }),
  'profile, no token': (s) => request(s).get('/api/v1/users/profile'),
  'balance, wrong token': (s) => request(s).get('/api/v1/wallet/balance').set('Authorization', 'Bearer x'),
  'list, no token': (s) => request(s).get('/api/v1/transactions'),
  'details, unknown id': (s) => request(s).get('/api/v1/transactions/NOPE').set(AUTH),
  'details, malformed URL': (s) => request(s).get('/api/v1/transactions/%E0%A4%A').set(AUTH),
  'unknown route': (s) => request(s).get('/api/v1/nope'),
  'malformed JSON': (s) =>
    request(s).post('/api/v1/auth/login').set('Content-Type', 'application/json').send('{"email":'),
  'body too large': (s) =>
    request(s).post('/api/v1/auth/login').set('Content-Type', 'application/json').send(`{"p":"${'x'.repeat(200000)}"}`),
  'transfer, no key': (s) => request(s).post('/api/v1/transactions/transfer').set(AUTH).send(VALID),
  'transfer, two keys': (s) =>
    request(s).post('/api/v1/transactions/transfer').set(AUTH).set('Idempotency-Key', [uuid(), uuid()]).send(VALID),
  'transfer, invalid body': (s) =>
    request(s).post('/api/v1/transactions/transfer').set(AUTH).set('Idempotency-Key', uuid()).send({ amount: -1 }),
  'transfer, insufficient balance': (s) =>
    request(s).post('/api/v1/transactions/transfer').set(AUTH).set('Idempotency-Key', uuid()).send({ ...VALID, amount: 99999 }),
  'transfer, key reused': async (s) => {
    const key = uuid();
    await request(s).post('/api/v1/transactions/transfer').set(AUTH).set('Idempotency-Key', key).send(VALID);
    return request(s).post('/api/v1/transactions/transfer').set(AUTH).set('Idempotency-Key', key).send({ ...VALID, amount: 1 });
  },
  'unexpected server error': (s, store) => {
    store.wallet.balancePaise = 0.5; // a corrupted store: toRupees throws
    return request(s).get('/api/v1/wallet/balance').set(AUTH);
  },
};

// SPEC.md section 9: field validation answers 400 VALIDATION_ERROR *with* fields.
const MUST_NAME_FIELDS = ['login, missing fields', 'transfer, invalid body'];

for (const [name, run] of Object.entries(errorCases)) {
  test(`error shape: ${name}`, async (t) => {
    t.mock.method(console, 'error', () => {});
    const store = createStore();
    const res = await run(createApp({ store }), store);

    assert.deepEqual(Object.keys(res.body).sort(), ['error', 'success']);
    assert.equal(res.body.success, false);
    const { code, message, fields, ...rest } = res.body.error;
    assert.deepEqual(rest, {}, 'error has only code, message and fields');
    assert.ok(code in CODES, `unknown code ${code}`);
    assert.equal(res.status, CODES[code], `${code} must be ${CODES[code]}`);
    assert.ok(typeof message === 'string' && message.length > 0);
    if (MUST_NAME_FIELDS.includes(name)) {
      assert.ok(fields && Object.keys(fields).length > 0, 'field errors must name the fields');
    }
    if (fields !== undefined) {
      assert.equal(code, 'VALIDATION_ERROR', 'only validation errors carry fields');
      for (const value of Object.values(fields)) assert.equal(typeof value, 'string');
    }
    assert.match(res.headers['content-type'], /application\/json/);
    assert.doesNotMatch(JSON.stringify(res.body), /\bat .+\.js:\d+/, 'no stack trace');
  });
}

test('every code is reached by at least one error path', async (t) => {
  t.mock.method(console, 'error', () => {});
  const seen = new Set();
  for (const run of Object.values(errorCases)) {
    const store = createStore();
    seen.add((await run(createApp({ store }), store)).body.error.code);
  }

  assert.deepEqual([...seen].sort(), Object.keys(CODES).sort());
});
