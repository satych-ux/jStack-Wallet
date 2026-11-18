const { toRupees } = require('./money');

/** The wallet as GET /wallet/balance returns it. */
function toWalletResponse(wallet) {
  return {
    walletId: wallet.walletId,
    currency: wallet.currency,
    availableBalance: toRupees(wallet.balancePaise),
    maskedAccountNumber: wallet.maskedAccountNumber,
  };
}

module.exports = { toWalletResponse };
