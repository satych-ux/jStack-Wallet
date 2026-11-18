const { test } = require('node:test');
const assert = require('node:assert/strict');

const seed = require('../seed.json');
const { createStore } = require('../src/store');

const isNewestFirst = (list) =>
  list.every((t, i) => i === 0 || Date.parse(list[i - 1].createdAt) >= Date.parse(t.createdAt));

test('seed.json itself is sorted newest first', () => {
  assert.ok(isNewestFirst(seed.transactions));
});

test('the store seeds 10 or more transactions, sorted newest first', () => {
  const { transactions } = createStore();

  assert.ok(transactions.length >= 10, `only ${transactions.length} seeded`);
  assert.ok(isNewestFirst(transactions));
});

test('the store sorts newest first even when the seed is not', () => {
  const shuffled = { ...seed, transactions: [...seed.transactions].reverse() };

  assert.ok(isNewestFirst(createStore(shuffled).transactions));
});

test('the seed contains at least one FAILED and one PENDING', () => {
  const statuses = new Set(createStore().transactions.map((t) => t.status));

  assert.ok(statuses.has('FAILED'));
  assert.ok(statuses.has('PENDING'));
});

test('the seed mixes DEBIT and CREDIT', () => {
  const types = new Set(createStore().transactions.map((t) => t.type));

  assert.deepEqual([...types].sort(), ['CREDIT', 'DEBIT']);
});

test('transaction ids are unique and shaped TXN + 5 digits', () => {
  const ids = createStore().transactions.map((t) => t.id);

  assert.equal(new Set(ids).size, ids.length);
  for (const id of ids) assert.match(id, /^TXN\d{5}$/);
});

test('money is held as integer paise', () => {
  const { wallet, transactions } = createStore();

  assert.ok(Number.isSafeInteger(wallet.balancePaise));
  assert.equal(wallet.balancePaise, 2545075); // ₹25,450.75
  for (const t of transactions) {
    assert.ok(Number.isSafeInteger(t.amountPaise) && t.amountPaise > 0, t.id);
  }
});

test('each store is a fresh copy: changing one leaves the seed alone', () => {
  const first = createStore();
  first.wallet.balancePaise = 0;
  first.transactions.length = 0;

  const second = createStore();
  assert.equal(second.wallet.balancePaise, 2545075);
  assert.ok(second.transactions.length >= 10);
});
