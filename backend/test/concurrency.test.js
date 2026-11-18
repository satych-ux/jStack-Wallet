const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { v4: uuid } = require('uuid');

const { createApp } = require('../src/app');
const { createStore } = require('../src/store');

// One real HTTP server for the whole file, hit with `fetch` + `Promise.all`.
// Each test swaps in a fresh store.
//
// Fresh connections arrive staggered (each needs its own TCP handshake), so
// the first batch would reach the server one request at a time and prove
// nothing about concurrency. `before` therefore opens a pool of connections
// first; after that, a batch's requests are inside the server together.
let app;
let server;
let baseUrl;
let store;

before(async () => {
  app = createApp({ store: createStore() });
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}/api/v1`;

  // Warm-up: open the connections every test below will reuse.
  await Promise.all(Array.from({ length: 20 }, () => fetch(`${baseUrl}/health`).then((r) => r.text())));
});

after(() => new Promise((resolve) => server.close(resolve)));

// Every route reads the store from app.locals, so swapping it there gives
// each test a fresh wallet on the same server.
beforeEach(() => {
  store = createStore();
  app.locals.store = store;
});

const START_PAISE = 2545075; // ₹25,450.75

async function transfer(amount, key = uuid()) {
  const res = await fetch(`${baseUrl}/transactions/transfer`, {
    method: 'POST',
    headers: {
      Authorization: 'Bearer mock_access_token_123',
      'Content-Type': 'application/json',
      'Idempotency-Key': key,
    },
    body: JSON.stringify({ beneficiaryName: 'Rahul Sharma', mobileNumber: '9876543210', amount }),
  });
  return { status: res.status, body: await res.json() };
}

async function balance() {
  const res = await fetch(`${baseUrl}/wallet/balance`, {
    headers: { Authorization: 'Bearer mock_access_token_123' },
  });
  return (await res.json()).data.availableBalance;
}

// --- API-12: no overdraft under concurrent requests ---

test('10 parallel transfers of ₹5,000 against ₹25,450.75: at most 5 succeed, the rest are 409, never negative', async () => {
  const results = await Promise.all(Array.from({ length: 10 }, () => transfer(5000)));

  const ok = results.filter((r) => r.status === 200);
  const rejected = results.filter((r) => r.status === 409);
  assert.equal(ok.length, 5); // 5 × 5000 = 25,000 fits; a 6th would need 30,000
  assert.equal(rejected.length, 5);
  for (const r of rejected) assert.equal(r.body.error.code, 'INSUFFICIENT_BALANCE');
  assert.ok(store.wallet.balancePaise >= 0);
  assert.equal(await balance(), 450.75);
});

test('successful amounts plus the final balance equal the starting balance', async () => {
  // Mixed amounts, more than the wallet holds in total.
  const amounts = [5000, 7500.25, 3000, 9999.99, 1200.5, 8000, 0.01, 4500, 2500.75, 6000];
  const results = await Promise.all(amounts.map((amount) => transfer(amount)));

  const sentPaise = results
    .filter((r) => r.status === 200)
    .reduce((sum, r) => sum + Math.round(r.body.data.amount * 100), 0);
  const rejected = results.filter((r) => r.status !== 200);
  assert.ok(rejected.length > 0, 'the total must exceed the balance');
  for (const r of rejected) {
    assert.equal(r.status, 409);
    assert.equal(r.body.error.code, 'INSUFFICIENT_BALANCE');
  }
  assert.ok(store.wallet.balancePaise >= 0);
  assert.equal(sentPaise + store.wallet.balancePaise, START_PAISE);

  // The history agrees: one new DEBIT per success, none per rejection.
  const okCount = results.filter((r) => r.status === 200).length;
  assert.equal(store.transactions.length, 12 + okCount);
});

test('every successful response reports a balance the wallet really passed through', async () => {
  // 10 × ₹3,000 = ₹30,000, more than ₹25,450.75: exactly 8 fit.
  const results = await Promise.all(Array.from({ length: 10 }, () => transfer(3000)));

  const ok = results.filter((r) => r.status === 200);
  const rejected = results.filter((r) => r.status === 409);
  assert.equal(ok.length, 8);
  assert.equal(rejected.length, 2);
  for (const r of rejected) assert.equal(r.body.error.code, 'INSUFFICIENT_BALANCE');

  // Each success saw its own step down: 22450.75, 19450.75, …, 1450.75.
  const balances = ok.map((r) => r.body.data.availableBalance).sort((a, b) => b - a);
  const expected = [1, 2, 3, 4, 5, 6, 7, 8].map((n) => (START_PAISE - n * 300000) / 100);
  assert.deepEqual(balances, expected);
});

test('5 parallel requests sharing one idempotency key produce exactly one deduction', async () => {
  const key = uuid();
  const results = await Promise.all(Array.from({ length: 5 }, () => transfer(1500, key)));

  for (const r of results) {
    assert.equal(r.status, 200);
    assert.deepEqual(r.body, results[0].body); // same id, same balance, same everything
  }
  assert.equal(store.wallet.balancePaise, START_PAISE - 150000);
  assert.equal(store.transactions.length, 13);
});

test('parallel requests with one key but different payloads: one 200, the rest 409, one deduction', async () => {
  const key = uuid();
  const results = await Promise.all([1500, 1501, 1502, 1503, 1504].map((amount) => transfer(amount, key)));

  assert.equal(results.filter((r) => r.status === 200).length, 1);
  for (const r of results.filter((r) => r.status !== 200)) {
    assert.equal(r.status, 409);
    assert.equal(r.body.error.code, 'IDEMPOTENCY_KEY_REUSED');
  }
  assert.equal(store.transactions.length, 13);
});

test('transaction ids stay unique under parallel transfers', async () => {
  const results = await Promise.all(Array.from({ length: 20 }, () => transfer(1)));

  const ids = results.map((r) => r.body.data.transactionId);
  assert.equal(new Set(ids).size, 20);
});

// --- No floating-point drift ---

test('1000 sequential ₹0.01 transfers leave the balance exactly ₹10.00 lower', async () => {
  for (let i = 0; i < 1000; i++) {
    const r = await transfer(0.01);
    assert.equal(r.status, 200, `transfer ${i}`);
  }

  assert.equal(store.wallet.balancePaise, START_PAISE - 1000);
  assert.ok(Number.isSafeInteger(store.wallet.balancePaise));
  assert.equal(await balance(), 25440.75);
});
