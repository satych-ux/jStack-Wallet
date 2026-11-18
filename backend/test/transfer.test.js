const { test } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { v4: uuid } = require('uuid');

const { createApp } = require('../src/app');
const { createStore } = require('../src/store');

const AUTH = { Authorization: 'Bearer mock_access_token_123' };
const VALID = { beneficiaryName: 'Rahul Sharma', mobileNumber: '9876543210', amount: 1500, remarks: 'Dinner split' };

/** A fresh store and an app on it, so a test can look inside the store. */
function setup() {
  const store = createStore();
  return { store, server: createApp({ store }) };
}

// Every transfer carries its own Idempotency-Key, as B4 will require.
const transfer = (server, body) =>
  request(server).post('/api/v1/transactions/transfer').set(AUTH).set('Idempotency-Key', uuid()).send(body);
const get = (server, path) => request(server).get(`/api/v1${path}`).set(AUTH);
const balanceOf = async (server) => (await get(server, '/wallet/balance')).body.data.availableBalance;

/** Asserts a 400 VALIDATION_ERROR naming exactly these fields. */
function assertFieldErrors(res, fields) {
  assert.equal(res.status, 400, JSON.stringify(res.body));
  assert.equal(res.body.success, false);
  assert.equal(res.body.error.code, 'VALIDATION_ERROR');
  assert.equal(typeof res.body.error.message, 'string');
  assert.deepEqual(Object.keys(res.body.error.fields).sort(), [...fields].sort());
  for (const message of Object.values(res.body.error.fields)) {
    assert.ok(typeof message === 'string' && message.length > 0);
  }
}

// --- Happy path (API-08) ---

test('a valid transfer returns 200 with transactionId, status, amount, currency, availableBalance', async () => {
  const res = await transfer(setup().server, VALID);

  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  const { createdAt, ...rest } = res.body.data;
  assert.deepEqual(rest, {
    transactionId: 'TXN10013',
    status: 'SUCCESS',
    amount: 1500,
    currency: 'INR',
    availableBalance: 23950.75,
  });
  assert.equal(new Date(createdAt).toISOString(), createdAt);
});

test('the returned balance equals the old balance minus the amount, and the balance endpoint agrees', async () => {
  const { server } = setup();
  const before = await balanceOf(server);

  const res = await transfer(server, { ...VALID, amount: 450.75 });

  assert.equal(before, 25450.75);
  assert.equal(res.body.data.availableBalance, 25000);
  assert.equal(await balanceOf(server), 25000);
});

test('the store keeps integer paise after a transfer', async () => {
  const { store, server } = setup();

  await transfer(server, { ...VALID, amount: 0.07 });

  assert.equal(store.wallet.balancePaise, 2545075 - 7);
  assert.ok(Number.isSafeInteger(store.transactions[0].amountPaise));
  assert.equal(store.transactions[0].amountPaise, 7);
});

test('amounts that are inexact as floats deduct exactly', async () => {
  const { server } = setup();

  for (const amount of [0.07, 1.1, 0.29, 2250.5]) {
    const res = await transfer(server, { ...VALID, amount });
    assert.equal(res.status, 200, String(amount));
    assert.equal(res.body.data.amount, amount);
  }
  // 25450.75 - (0.07 + 1.10 + 0.29 + 2250.50) = 23198.79
  assert.equal(await balanceOf(server), 23198.79);
});

test('a new DEBIT with status SUCCESS appears at the head of the list', async () => {
  const { server } = setup();
  const before = (await get(server, '/transactions')).body.data;

  const res = await transfer(server, VALID);
  const after = (await get(server, '/transactions')).body.data;

  assert.equal(after.length, before.length + 1);
  const { createdAt, ...head } = after[0];
  assert.deepEqual(head, {
    id: res.body.data.transactionId,
    type: 'DEBIT',
    status: 'SUCCESS',
    amount: 1500,
    currency: 'INR',
    counterpartyName: 'Rahul Sharma',
    mobileNumber: '9876543210',
    remarks: 'Dinner split',
  });
  assert.equal(createdAt, res.body.data.createdAt);
});

test('the list stays sorted newest first after transfers', async () => {
  const { server } = setup();
  await transfer(server, VALID);
  await transfer(server, VALID);

  const list = (await get(server, '/transactions')).body.data;
  for (let i = 1; i < list.length; i++) {
    assert.ok(Date.parse(list[i - 1].createdAt) >= Date.parse(list[i].createdAt), list[i].id);
  }
});

test('ids continue from the highest seeded id: TXN10013, then TXN10014', async () => {
  const { server } = setup();

  const first = await transfer(server, VALID);
  const second = await transfer(server, VALID);

  assert.equal(first.body.data.transactionId, 'TXN10013');
  assert.equal(second.body.data.transactionId, 'TXN10014');
});

test('the new transaction can be fetched by its id', async () => {
  const { server } = setup();
  const { transactionId } = (await transfer(server, VALID)).body.data;

  const res = await get(server, `/transactions/${transactionId}`);

  assert.equal(res.status, 200);
  assert.equal(res.body.data.id, transactionId);
  assert.equal(res.body.data.type, 'DEBIT');
});

test('the whole balance can be sent, leaving exactly 0', async () => {
  const { server } = setup();

  const res = await transfer(server, { ...VALID, amount: 25450.75 });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.availableBalance, 0);
});

test('beneficiary name and remarks are stored trimmed', async () => {
  const { server } = setup();

  await transfer(server, { ...VALID, beneficiaryName: '  Rahul Sharma ', remarks: ' Dinner ' });
  const head = (await get(server, '/transactions')).body.data[0];

  assert.equal(head.counterpartyName, 'Rahul Sharma');
  assert.equal(head.remarks, 'Dinner');
});

test('unknown extra fields in the body are ignored', async () => {
  const res = await transfer(setup().server, { ...VALID, availableBalance: 999999, fee: 10 });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.availableBalance, 23950.75);
});

// --- Remarks (API-06) ---

test('remarks absent is valid and stored as null', async () => {
  const { server } = setup();
  const { remarks, ...noRemarks } = VALID;

  const res = await transfer(server, noRemarks);

  assert.equal(res.status, 200);
  assert.equal((await get(server, '/transactions')).body.data[0].remarks, null);
});

test('remarks null, empty or only spaces is valid and stored as null', async () => {
  const { server } = setup();

  for (const remarks of [null, '', '   ']) {
    const res = await transfer(server, { ...VALID, remarks });
    assert.equal(res.status, 200, JSON.stringify(remarks));
    assert.equal((await get(server, '/transactions')).body.data[0].remarks, null);
  }
});

test('remarks of exactly 100 characters is valid', async () => {
  const res = await transfer(setup().server, { ...VALID, remarks: 'x'.repeat(100) });

  assert.equal(res.status, 200);
});

test('the 100-character cap applies after trimming', async () => {
  const res = await transfer(setup().server, { ...VALID, remarks: `  ${'x'.repeat(100)}  ` });

  assert.equal(res.status, 200);
});

test('remarks are counted in characters: 100 emoji are valid, 101 are not', async () => {
  const { server } = setup();

  const hundred = await transfer(server, { ...VALID, remarks: '🎉'.repeat(100) });
  assert.equal(hundred.status, 200);
  assert.equal((await get(server, '/transactions')).body.data[0].remarks, '🎉'.repeat(100));

  assertFieldErrors(await transfer(server, { ...VALID, remarks: '🎉'.repeat(101) }), ['remarks']);
});

test('remarks over 100 characters is 400', async () => {
  assertFieldErrors(await transfer(setup().server, { ...VALID, remarks: 'x'.repeat(101) }), ['remarks']);
});

test('remarks that are not a string is 400', async () => {
  assertFieldErrors(await transfer(setup().server, { ...VALID, remarks: 42 }), ['remarks']);
});

// --- Validation (API-06) ---

const invalid = [
  ['missing beneficiary', { beneficiaryName: undefined }, 'beneficiaryName'],
  ['blank beneficiary', { beneficiaryName: '   ' }, 'beneficiaryName'],
  ['non-string beneficiary', { beneficiaryName: 7 }, 'beneficiaryName'],
  ['missing mobile', { mobileNumber: undefined }, 'mobileNumber'],
  ['9-digit mobile', { mobileNumber: '987654321' }, 'mobileNumber'],
  ['11-digit mobile', { mobileNumber: '98765432100' }, 'mobileNumber'],
  ['non-numeric mobile', { mobileNumber: '98765abcde' }, 'mobileNumber'],
  ['mobile with spaces', { mobileNumber: '98765 43210' }, 'mobileNumber'],
  ['mobile as a number', { mobileNumber: 9876543210 }, 'mobileNumber'],
  ['missing amount', { amount: undefined }, 'amount'],
  ['amount 0', { amount: 0 }, 'amount'],
  ['negative amount', { amount: -100 }, 'amount'],
  ['non-numeric amount', { amount: 'abc' }, 'amount'],
  ['amount as a numeric string', { amount: '1500' }, 'amount'],
  ['3-decimal amount', { amount: 10.123 }, 'amount'],
  ['3-decimal amount that looks like 2 in float', { amount: 1.005 }, 'amount'],
  ['amount below one paisa', { amount: 0.001 }, 'amount'],
  ['amount too large to hold in paise', { amount: 1e16 }, 'amount'],
  ['amount as a boolean', { amount: true }, 'amount'],
];

for (const [name, change, field] of invalid) {
  test(`${name} is 400 naming ${field}`, async () => {
    assertFieldErrors(await transfer(setup().server, { ...VALID, ...change }), [field]);
  });
}

test('every invalid field is reported at once', async () => {
  const res = await transfer(setup().server, {
    beneficiaryName: '',
    mobileNumber: '123',
    amount: -1,
    remarks: 'x'.repeat(101),
  });

  assertFieldErrors(res, ['beneficiaryName', 'mobileNumber', 'amount', 'remarks']);
});

test('an empty body is 400 naming the three required fields', async () => {
  const res = await request(setup().server)
    .post('/api/v1/transactions/transfer')
    .set(AUTH)
    .set('Idempotency-Key', uuid());

  assertFieldErrors(res, ['beneficiaryName', 'mobileNumber', 'amount']);
});

test('a rejected transfer changes nothing', async () => {
  const { store, server } = setup();
  const count = store.transactions.length;

  for (const change of [{ mobileNumber: '1' }, { amount: 10.123 }, { amount: '1500' }, { beneficiaryName: '' }]) {
    const res = await transfer(server, { ...VALID, ...change });
    assert.equal(res.status, 400, JSON.stringify(change));
  }

  assert.equal(store.wallet.balancePaise, 2545075);
  assert.equal(store.transactions.length, count);
});

test('if building the record fails, no money moves (record first, deduct last)', async (t) => {
  t.mock.method(console, 'error', () => {});
  const { store, server } = setup();
  const count = store.transactions.length;
  t.mock.method(Date.prototype, 'toISOString', () => {
    throw new Error('clock broke');
  });

  const res = await transfer(server, VALID);

  assert.equal(res.status, 500);
  assert.equal(store.wallet.balancePaise, 2545075);
  assert.equal(store.transactions.length, count);
});

test('the next id works with a very long history', async () => {
  const { store, server } = setup();
  const filler = store.transactions[0];
  for (let i = 0; i < 200000; i++) store.transactions.push({ ...filler, id: `TXN${20000 + i}` });

  const res = await transfer(server, VALID);

  assert.equal(res.status, 200);
  assert.equal(res.body.data.transactionId, 'TXN220000');
});

// --- Insufficient balance (API-07) ---

test('one paisa above the balance is 409 INSUFFICIENT_BALANCE', async () => {
  const res = await transfer(setup().server, { ...VALID, amount: 25450.76 });

  assert.equal(res.status, 409);
  assert.deepEqual(res.body, {
    success: false,
    error: { code: 'INSUFFICIENT_BALANCE', message: 'Amount exceeds available balance' },
  });
});

test('after that 409 the balance is unchanged and no transaction was added', async () => {
  const { store, server } = setup();
  const listBefore = (await get(server, '/transactions')).body.data;

  await transfer(server, { ...VALID, amount: 25450.76 });

  assert.equal(await balanceOf(server), 25450.75);
  assert.deepEqual((await get(server, '/transactions')).body.data, listBefore);
  assert.equal(store.wallet.balancePaise, 2545075);
});

test('validation runs before the balance check: an invalid huge amount is 400, not 409', async () => {
  const res = await transfer(setup().server, { ...VALID, amount: 99999999.999 });

  assertFieldErrors(res, ['amount']);
});

// --- Auth ---

test('a transfer without a token is 401 and changes nothing', async () => {
  const { store, server } = setup();

  const res = await request(server)
    .post('/api/v1/transactions/transfer')
    .set('Idempotency-Key', uuid())
    .send(VALID);

  assert.equal(res.status, 401);
  assert.equal(res.body.error.code, 'UNAUTHORIZED');
  assert.equal(store.wallet.balancePaise, 2545075);
});

test('the token is checked before the body: no token and a bad body is 401', async () => {
  const res = await request(setup().server).post('/api/v1/transactions/transfer').send({});

  assert.equal(res.status, 401);
});
