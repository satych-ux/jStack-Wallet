/**
 * The store keeps money as integer paise. This is the one place it becomes
 * rupees, on the way out. An integer divided by 100 always prints with at
 * most 2 decimals (2545075 → 25450.75), so no rounding is needed.
 *
 * That only holds for integers, so anything else throws: a bug that put
 * 0.5 paise in the store becomes a loud 500, never a wrong amount.
 */
function toRupees(paise) {
  if (!Number.isSafeInteger(paise)) {
    throw new Error(`Expected integer paise, got ${paise}`);
  }
  return paise / 100;
}

module.exports = { toRupees };
