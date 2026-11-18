const { test } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');

const { createApp } = require('../src/app');
const { createStore } = require('../src/store');

const AUTH = { Authorization: 'Bearer mock_access_token_123' };
const app = () => createApp({ store: createStore() });
const get = (server, path) => request(server).get(`/api/v1${path}`).set(AUTH);

/** True when n is a number with at most 2 decimal places. */
const isMoney = (n) => typeof n === 'number' && Number.isFinite(n) && /^-?\d+(\.\d{1,2})?$/.test(String(n));

const TRANSACTION_KEYS = [
  'amount', 'counterpartyName', 'createdAt', 'currency', 'id', 'mobileNumber', 'remarks', 'status', 'type',
];

function assertTransactionShape(t) {
  assert.deepEqual(Object.keys(t).sort(), TRANSACTION_KEYS, t.id);
  assert.ok(isMoney(t.amount) && t.amount > 0, `${t.id} amount ${t.amount}`);
  assert.ok(['DEBIT', 'CREDIT'].includes(t.type), t.id);
  assert.ok(['SUCCESS', 'FAILED', 'PENDING'].includes(t.status), t.id);
  assert.equal(t.currency, 'INR');
  assert.ok(t.remarks === null || typeof t.remarks === 'string', t.id);
  assert.equal(new Date(t.createdAt).toISOString(), t.createdAt, t.id);
}

// --- Auth on every endpoint ---

for (const path of ['/wallet/balance', '/transactions', '/transactions/TXN10001', '/transactions/NOPE']) {
  test(`GET ${path} returns 401 without a token`, async () => {
    const res = await request(app()).get(`/api/v1${path}`);

    assert.equal(res.status, 401);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'UNAUTHORIZED');
  });

  test(`GET ${path} returns 401 with a wrong token`, async () => {
    const res = await request(app()).get(`/api/v1${path}`).set('Authorization', 'Bearer wrong');

    assert.equal(res.status, 401);
    assert.equal(res.body.error.code, 'UNAUTHORIZED');
  });
}

// --- GET /wallet/balance (API-04) ---

test('balance returns walletId, currency, availableBalance, maskedAccountNumber', async () => {
  const res = await get(app(), '/wallet/balance');

  assert.equal(res.status, 200);
  assert.deepEqual(res.body, {
    success: true,
    data: {
      walletId: 'WAL-7F3K-2291',
      currency: 'INR',
      availableBalance: 25450.75,
      maskedAccountNumber: 'XXXX XXXX 4821',
    },
  });
});

test('availableBalance is a number with at most 2 decimal places', async () => {
  const { body } = await get(app(), '/wallet/balance');

  assert.ok(isMoney(body.data.availableBalance), String(body.data.availableBalance));
});

test('a non-integer balance in the store fails loudly with 500, never a wrong number', async (t) => {
  t.mock.method(console, 'error', () => {});
  const store = createStore();
  const server = createApp({ store });
  store.wallet.balancePaise = 0.5; // what `amount * 100` without rounding could leave

  const res = await get(server, '/wallet/balance');

  assert.equal(res.status, 500);
  assert.equal(res.body.error.code, 'INTERNAL_ERROR');
});

test('the balance is never answered with an empty 304', async () => {
  const server = app();
  const first = await get(server, '/wallet/balance');
  assert.equal(first.headers.etag, undefined);

  // What a cache would resend if the server had ever given it an ETag.
  const again = await get(server, '/wallet/balance').set('If-None-Match', 'W/"8a-abc"');
  assert.equal(again.status, 200);
  assert.equal(again.body.data.availableBalance, 25450.75);
});

test('balance reflects the store, not a constant: deduct in the store, read again', async () => {
  const store = createStore();
  const server = createApp({ store });

  const before = await get(server, '/wallet/balance');
  store.wallet.balancePaise -= 150000; // ₹1,500.00
  const after = await get(server, '/wallet/balance');

  assert.equal(before.body.data.availableBalance, 25450.75);
  assert.equal(after.body.data.availableBalance, 23950.75);
});

test('balance does not leak internal fields', async () => {
  const { body } = await get(app(), '/wallet/balance');

  assert.doesNotMatch(JSON.stringify(body), /Paise/);
});

// --- GET /transactions (API-05) ---

test('the list returns 10 or more transactions, sorted by createdAt descending', async () => {
  const res = await get(app(), '/transactions');

  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  const list = res.body.data;
  assert.ok(Array.isArray(list));
  assert.ok(list.length >= 10, `only ${list.length}`);
  for (let i = 1; i < list.length; i++) {
    assert.ok(Date.parse(list[i - 1].createdAt) >= Date.parse(list[i].createdAt), list[i].id);
  }
});

test('the list mixes DEBIT and CREDIT', async () => {
  const types = new Set((await get(app(), '/transactions')).body.data.map((t) => t.type));

  assert.deepEqual([...types].sort(), ['CREDIT', 'DEBIT']);
});

test('every listed transaction has the contract shape, amounts in rupees', async () => {
  const { body } = await get(app(), '/transactions');

  for (const t of body.data) assertTransactionShape(t);
  const refund = body.data.find((t) => t.id === 'TXN10008');
  assert.equal(refund.amount, 2250.5);
});

test('the list reflects the store: a transaction added to the store appears first', async () => {
  const store = createStore();
  const server = createApp({ store });
  store.transactions.unshift({
    ...store.transactions[0],
    id: 'TXN10013',
    createdAt: '2026-11-18T00:00:00.000Z',
  });

  const { body } = await get(server, '/transactions');
  assert.equal(body.data[0].id, 'TXN10013');
});

test('the list is read from the store in paise and sent in rupees', async () => {
  const store = createStore();
  const server = createApp({ store });
  store.transactions[0].amountPaise = 45075;

  const { body } = await get(server, '/transactions');
  assert.equal(body.data.length, store.transactions.length);
  assert.equal(body.data[0].amount, 450.75);
});

// --- GET /transactions/:id (API-13) ---

test('GET /transactions/TXN10001 returns that transaction', async () => {
  const res = await get(app(), '/transactions/TXN10001');

  assert.equal(res.status, 200);
  assert.deepEqual(res.body, {
    success: true,
    data: {
      id: 'TXN10001',
      type: 'DEBIT',
      status: 'SUCCESS',
      amount: 600,
      currency: 'INR',
      counterpartyName: 'Farhan Qureshi',
      mobileNumber: '9311223344',
      remarks: 'Groceries',
      createdAt: '2026-10-25T12:05:00.000Z',
    },
  });
});

test('a transaction with no remarks returns remarks: null', async () => {
  const { body } = await get(app(), '/transactions/TXN10004');

  assert.equal(body.data.remarks, null);
});

test('GET /transactions/NOPE returns 404 TRANSACTION_NOT_FOUND', async () => {
  const res = await get(app(), '/transactions/NOPE');

  assert.equal(res.status, 404);
  assert.deepEqual(res.body, {
    success: false,
    error: { code: 'TRANSACTION_NOT_FOUND', message: 'Transaction not found' },
  });
});

test('a malformed id in the URL is 400 with an honest message, not a body error', async (t) => {
  const logged = t.mock.method(console, 'error', () => {});
  const res = await get(app(), '/transactions/%E0%A4%A');

  assert.equal(res.status, 400);
  assert.deepEqual(res.body, {
    success: false,
    error: { code: 'VALIDATION_ERROR', message: 'Invalid request' },
  });
  assert.equal(logged.mock.callCount(), 0);
});

test('ids are matched exactly: a lowercase id is 404', async () => {
  const res = await get(app(), '/transactions/txn10001');

  assert.equal(res.status, 404);
  assert.equal(res.body.error.code, 'TRANSACTION_NOT_FOUND');
});
