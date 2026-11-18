const { test } = require('node:test');
const assert = require('node:assert/strict');

const { toRupees } = require('../src/models/money');

test('toRupees turns integer paise into rupees', () => {
  assert.equal(toRupees(2545075), 25450.75);
  assert.equal(toRupees(150000), 1500);
  assert.equal(toRupees(1), 0.01);
  assert.equal(toRupees(0), 0);
});

test('every integer paise value prints with at most 2 decimals', () => {
  // The claim in money.js, checked across a wide range rather than assumed.
  const atMost2dp = /^\d+(\.\d{1,2})?$/;
  for (let paise = 0; paise <= 200000; paise++) {
    assert.match(String(toRupees(paise)), atMost2dp, String(paise));
  }
  for (const paise of [2545075, 99999999, 123456789012, 7e15 - 1]) {
    assert.match(String(toRupees(paise)), atMost2dp, String(paise));
  }
});

test('toRupees throws on anything that is not a safe integer', () => {
  for (const bad of [0.5, 1.005, NaN, Infinity, undefined, null, '100', 2 ** 53]) {
    assert.throws(() => toRupees(bad), /integer paise/, String(bad));
  }
});
