const { test } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { v4: uuid } = require('uuid');

const { createApp } = require('../src/app');
const { createStore } = require('../src/store');
const express = require('express');
const { latencyMs, simulateLatency, MAX_LATENCY_MS } = require('../src/middleware/latency');
const { errorHandler } = require('../src/middleware/errorHandler');

const AUTH = { Authorization: 'Bearer mock_access_token_123' };
const VALID = { beneficiaryName: 'Rahul Sharma', mobileNumber: '9876543210', amount: 1500 };
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function setup() {
  const store = createStore();
  return { store, server: createApp({ store }) };
}

/** Runs a request and returns it with how long it took. */
async function timed(req) {
  const started = Date.now();
  const res = await req;
  return { res, ms: Date.now() - started };
}

const transfer = (server, key, latency) =>
  request(server)
    .post(`/api/v1/transactions/transfer${latency ? `?simulateLatencyMs=${latency}` : ''}`)
    .set(AUTH)
    .set('Idempotency-Key', key)
    .send(VALID);

// --- Parsing the parameter ---

test('latencyMs reads a whole number of milliseconds', () => {
  assert.equal(latencyMs('500'), 500);
  assert.equal(latencyMs('0'), 0);
});

test('latencyMs treats missing or invalid values as 0', () => {
  for (const value of [
    undefined, '', 'abc', '-5', '1.5', '500ms', ['100', '200'], 'Infinity', 'NaN',
    // Number() would accept these; the documented rule is digits only.
    '1e3', '0x10', '0b11', '500.0', '+500', ' 500',
  ]) {
    assert.equal(latencyMs(value), 0, JSON.stringify(value));
  }
});

test(`latencyMs caps the delay at ${MAX_LATENCY_MS} ms`, () => {
  assert.equal(MAX_LATENCY_MS, 30000);
  assert.equal(latencyMs('999999'), 30000);
});

// --- API-15 ---

test('simulateLatencyMs=500 delays the response by roughly 500ms', async () => {
  const { res, ms } = await timed(
    request(setup().server).get('/api/v1/wallet/balance?simulateLatencyMs=500').set(AUTH),
  );

  assert.equal(res.status, 200);
  assert.equal(res.body.data.availableBalance, 25450.75);
  assert.ok(ms >= 490, `took ${ms}ms`);
  assert.ok(ms < 1500, `took ${ms}ms`);
});

test('without the parameter there is no delay', async () => {
  const { res, ms } = await timed(request(setup().server).get('/api/v1/wallet/balance').set(AUTH));

  assert.equal(res.status, 200);
  assert.ok(ms < 200, `took ${ms}ms`);
});

test('an invalid value means no delay', async () => {
  const { ms } = await timed(request(setup().server).get('/api/v1/wallet/balance?simulateLatencyMs=abc').set(AUTH));

  assert.ok(ms < 200, `took ${ms}ms`);
});

test('error responses are delayed too, and keep their shape', async () => {
  const { res, ms } = await timed(request(setup().server).get('/api/v1/wallet/balance?simulateLatencyMs=300'));

  assert.equal(res.status, 401);
  assert.equal(res.body.error.code, 'UNAUTHORIZED');
  assert.ok(ms >= 290, `took ${ms}ms`);
});

test('a slow transfer still answers 400 and 409: the handler stays synchronous', async () => {
  const { server } = setup();

  const bad = await transfer(server, uuid(), 100).send({ ...VALID, mobileNumber: '1' });
  const tooMuch = await transfer(server, uuid(), 100).send({ ...VALID, amount: 99999 });

  assert.equal(bad.status, 400);
  assert.equal(bad.body.error.code, 'VALIDATION_ERROR');
  assert.equal(tooMuch.status, 409);
  assert.equal(tooMuch.body.error.code, 'INSUFFICIENT_BALANCE');
});

// --- The point of it: the money moves at once, only the answer is late ---

/** Polls until `check()` is true; fails after `ms`. No fixed sleeps, so a slow machine can't flake it. */
async function waitUntil(check, ms = 2000) {
  const deadline = Date.now() + ms;
  while (!check()) {
    if (Date.now() > deadline) throw new Error('condition never became true');
    await sleep(5);
  }
}

test('a slow transfer deducts immediately; only the response waits', async () => {
  const { store, server } = setup();
  let answered = false;

  const pending = transfer(server, uuid(), 1000).then((r) => {
    answered = true;
    return r;
  });
  await waitUntil(() => store.wallet.balancePaise !== 2545075);

  // The money has moved and the history has the row, but no answer yet.
  assert.equal(answered, false);
  assert.equal(store.wallet.balancePaise, 2545075 - 150000);
  assert.equal(store.transactions.length, 13);

  const res = await pending;
  assert.equal(res.status, 200);
  assert.equal(res.body.data.availableBalance, 23950.75);
});

test('a retry sent while the slow original is still pending replays it, with no second deduction', async () => {
  const { store, server } = setup();
  const key = uuid();
  const order = [];

  const slow = transfer(server, key, 1000).then((r) => {
    order.push('original');
    return r;
  });
  await waitUntil(() => store.wallet.balancePaise !== 2545075); // the original has been handled
  const retry = await transfer(server, key).then((r) => {
    order.push('retry');
    return r;
  });
  const original = await slow;

  assert.deepEqual(order, ['retry', 'original']); // the retry overtook the slow answer
  assert.equal(retry.status, 200);
  assert.deepEqual(retry.body, original.body);
  assert.equal(store.wallet.balancePaise, 2545075 - 150000);
  assert.equal(store.transactions.length, 13);
});

// --- A delayed answer must never turn a route bug into a crash ---

test('a route that answers and then throws still gets its first answer, and the server lives on', async (t) => {
  const logged = t.mock.method(console, 'error', () => {});
  const app = express();
  app.use(simulateLatency);
  app.get('/buggy', (req, res) => {
    res.json({ first: true });
    throw new Error('bug after answering');
  });
  app.get('/ok', (req, res) => res.json({ ok: true }));
  app.use(errorHandler);

  const res = await request(app).get('/buggy?simulateLatencyMs=20');
  await sleep(50); // long enough for any second, delayed send to fire

  assert.equal(res.status, 200);
  assert.deepEqual(res.body, { first: true });
  assert.ok(logged.mock.callCount() >= 1, 'the bug is logged');
  assert.deepEqual((await request(app).get('/ok?simulateLatencyMs=20')).body, { ok: true });
});
