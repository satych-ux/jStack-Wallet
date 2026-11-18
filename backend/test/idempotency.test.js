const { test } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { v4: uuid } = require('uuid');

const { createApp } = require('../src/app');
const { createStore } = require('../src/store');

const AUTH = { Authorization: 'Bearer mock_access_token_123' };
const VALID = { beneficiaryName: 'Rahul Sharma', mobileNumber: '9876543210', amount: 1500, remarks: 'Dinner split' };

function setup() {
  const store = createStore();
  return { store, server: createApp({ store }) };
}

const send = (server, key, body) => {
  const req = request(server).post('/api/v1/transactions/transfer').set(AUTH);
  return (key === undefined ? req : req.set('Idempotency-Key', key)).send(body);
};

/** The store's balance and history length, to prove nothing moved. */
const snapshot = (store) => ({ balancePaise: store.wallet.balancePaise, count: store.transactions.length });

// --- Missing key (API-09) ---

test('no Idempotency-Key header is 400 IDEMPOTENCY_KEY_REQUIRED and changes nothing', async () => {
  const { store, server } = setup();
  const before = snapshot(store);

  const res = await send(server, undefined, VALID);

  assert.equal(res.status, 400);
  assert.deepEqual(res.body, {
    success: false,
    error: { code: 'IDEMPOTENCY_KEY_REQUIRED', message: 'Idempotency-Key header is required' },
  });
  assert.deepEqual(snapshot(store), before);
});

test('an empty Idempotency-Key is treated as missing', async () => {
  // (Node strips spaces around header values, so "   " arrives as "" too.)
  const res = await send(setup().server, '', VALID);

  assert.equal(res.status, 400);
  assert.equal(res.body.error.code, 'IDEMPOTENCY_KEY_REQUIRED');
});

test('two Idempotency-Key headers are 400, not a new joined key', async () => {
  const { store, server } = setup();
  const key = uuid();
  await send(server, key, VALID);
  const before = snapshot(store);

  // Node joins repeated headers into "first, second".
  const res = await send(server, [key, uuid()], VALID);

  assert.equal(res.status, 400);
  assert.deepEqual(res.body, {
    success: false,
    error: { code: 'IDEMPOTENCY_KEY_REQUIRED', message: 'Send exactly one Idempotency-Key header' },
  });
  assert.deepEqual(snapshot(store), before);
});

test('a key containing a comma is rejected the same way', async () => {
  const res = await send(setup().server, 'abc,def', VALID);

  assert.equal(res.status, 400);
  assert.equal(res.body.error.code, 'IDEMPOTENCY_KEY_REQUIRED');
});

test('the key is checked before the body: no key and a bad body is the key error', async () => {
  const res = await send(setup().server, undefined, { amount: -1 });

  assert.equal(res.status, 400);
  assert.equal(res.body.error.code, 'IDEMPOTENCY_KEY_REQUIRED');
  assert.equal(res.body.error.fields, undefined);
});

test('the token is checked before the key: no token and no key is 401', async () => {
  const res = await request(setup().server).post('/api/v1/transactions/transfer').send(VALID);

  assert.equal(res.status, 401);
});

// --- Same key, same payload (API-10) ---

test('same key and identical payload twice: same response, one deduction, one new row', async () => {
  const { store, server } = setup();
  const key = uuid();
  const before = snapshot(store);

  const first = await send(server, key, VALID);
  const second = await send(server, key, VALID);

  assert.equal(first.status, 200);
  assert.equal(second.status, 200);
  assert.deepEqual(second.body, first.body);
  assert.equal(second.body.data.transactionId, first.body.data.transactionId);
  assert.deepEqual(snapshot(store), { balancePaise: before.balancePaise - 150000, count: before.count + 1 });
});

test('any number of retries still deducts once', async () => {
  const { store, server } = setup();
  const key = uuid();

  for (let i = 0; i < 5; i++) assert.equal((await send(server, key, VALID)).status, 200);

  assert.equal(store.wallet.balancePaise, 2545075 - 150000);
  assert.equal(store.transactions.length, 13);
});

test('a replay returns the original balance, even after other transfers', async () => {
  const { server } = setup();
  const key = uuid();

  const first = await send(server, key, VALID);
  await send(server, uuid(), { ...VALID, amount: 100 });
  const replay = await send(server, key, VALID);

  assert.equal(first.body.data.availableBalance, 23950.75);
  assert.equal(replay.body.data.availableBalance, 23950.75);
});

test('the payload is the same whatever the key order or extra fields', async () => {
  const { store, server } = setup();
  const key = uuid();

  await send(server, key, VALID);
  const reordered = await send(server, key, {
    remarks: 'Dinner split', amount: 1500, mobileNumber: '9876543210', beneficiaryName: 'Rahul Sharma', extra: true,
  });

  assert.equal(reordered.status, 200);
  assert.equal(store.transactions.length, 13);
});

test('remarks absent, null, empty and only spaces all count as the same payload', async () => {
  const { store, server } = setup();
  const key = uuid();
  const { remarks, ...noRemarks } = VALID;

  await send(server, key, noRemarks);
  for (const remarks of [null, '', '   ']) {
    const res = await send(server, key, { ...noRemarks, remarks });
    assert.equal(res.status, 200, JSON.stringify(remarks));
  }
  assert.equal(store.transactions.length, 13);
});

// --- Same key, different payload (API-11) ---

const changes = {
  amount: { amount: 1500.01 },
  mobileNumber: { mobileNumber: '9876543211' },
  beneficiaryName: { beneficiaryName: 'Rahul S' },
  remarks: { remarks: 'Lunch' },
  'name with a space (compared as sent)': { beneficiaryName: ' Rahul Sharma' },
};

for (const [name, change] of Object.entries(changes)) {
  test(`same key with a different ${name} is 409 IDEMPOTENCY_KEY_REUSED and changes nothing`, async () => {
    const { store, server } = setup();
    const key = uuid();
    await send(server, key, VALID);
    const before = snapshot(store);

    const res = await send(server, key, { ...VALID, ...change });

    assert.equal(res.status, 409);
    assert.deepEqual(res.body, {
      success: false,
      error: {
        code: 'IDEMPOTENCY_KEY_REUSED',
        message: 'Idempotency-Key was already used with a different payload',
      },
    });
    assert.deepEqual(snapshot(store), before);
  });
}

test('an amount sent as 1500.0 (as Dart encodes it) is the same payload as 1500', async () => {
  const { store, server } = setup();
  const key = uuid();
  const raw = (amount) =>
    request(server)
      .post('/api/v1/transactions/transfer')
      .set(AUTH)
      .set('Idempotency-Key', key)
      .set('Content-Type', 'application/json')
      .send(`{"beneficiaryName":"Rahul Sharma","mobileNumber":"9876543210","amount":${amount}}`);

  const first = await raw('1500.0');
  const second = await raw('1500');
  const third = await raw('1.5e3');

  assert.equal(first.status, 200);
  assert.deepEqual(second.body, first.body);
  assert.deepEqual(third.body, first.body);
  assert.equal(store.transactions.length, 13);
});

test('a used key with a different, invalid body is 409, not 400: the key conflict wins', async () => {
  const { store, server } = setup();
  const key = uuid();
  await send(server, key, VALID);
  const before = snapshot(store);

  const res = await send(server, key, { ...VALID, amount: -1 });

  assert.equal(res.status, 409);
  assert.equal(res.body.error.code, 'IDEMPOTENCY_KEY_REUSED');
  assert.deepEqual(snapshot(store), before);
});

test('a replay still needs the token', async () => {
  const { server } = setup();
  const key = uuid();
  await send(server, key, VALID);

  const res = await request(server).post('/api/v1/transactions/transfer').set('Idempotency-Key', key).send(VALID);

  assert.equal(res.status, 401);
});

test('after a 409 for reuse, the original payload still replays', async () => {
  const { server } = setup();
  const key = uuid();
  const first = await send(server, key, VALID);
  await send(server, key, { ...VALID, amount: 1 });

  const replay = await send(server, key, VALID);

  assert.deepEqual(replay.body, first.body);
});

// --- Different keys ---

test('different keys with identical payloads both succeed and deduct twice', async () => {
  const { store, server } = setup();

  const a = await send(server, uuid(), VALID);
  const b = await send(server, uuid(), VALID);

  assert.equal(a.status, 200);
  assert.equal(b.status, 200);
  assert.notEqual(a.body.data.transactionId, b.body.data.transactionId);
  assert.equal(store.wallet.balancePaise, 2545075 - 2 * 150000);
  assert.equal(store.transactions.length, 14);
});

// --- Failed attempts do not hold the key ---

test('a key whose first request failed validation does not block a corrected retry', async () => {
  const { store, server } = setup();
  const key = uuid();

  const bad = await send(server, key, { ...VALID, mobileNumber: '123' });
  const fixed = await send(server, key, VALID);
  const again = await send(server, key, VALID);

  assert.equal(bad.status, 400);
  assert.equal(fixed.status, 200);
  assert.deepEqual(again.body, fixed.body);
  assert.equal(store.transactions.length, 13);
  assert.equal(store.wallet.balancePaise, 2545075 - 150000);
});

test('a key whose first request was 409 INSUFFICIENT_BALANCE is not held either', async () => {
  const { store, server } = setup();
  const key = uuid();

  const tooMuch = await send(server, key, { ...VALID, amount: 30000 });
  const sameAgain = await send(server, key, { ...VALID, amount: 30000 });
  const smaller = await send(server, key, VALID);

  assert.equal(tooMuch.status, 409);
  assert.equal(tooMuch.body.error.code, 'INSUFFICIENT_BALANCE');
  assert.equal(sameAgain.body.error.code, 'INSUFFICIENT_BALANCE');
  assert.equal(smaller.status, 200);
  assert.equal(store.wallet.balancePaise, 2545075 - 150000);
});
