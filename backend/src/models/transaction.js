const { toRupees } = require('./money');

/** A transaction as the API returns it: amount in rupees, field by field. */
function toTransactionResponse(t) {
  return {
    id: t.id,
    type: t.type,
    status: t.status,
    amount: toRupees(t.amountPaise),
    currency: t.currency,
    counterpartyName: t.counterpartyName,
    mobileNumber: t.mobileNumber,
    remarks: t.remarks,
    createdAt: t.createdAt,
  };
}

/**
 * The 200 body of POST /transactions/transfer. Built once and stored, so a
 * retry with the same key gets exactly this, balance included.
 */
function toTransferResponse(transaction, balancePaise) {
  return {
    success: true,
    data: {
      transactionId: transaction.id,
      status: transaction.status,
      amount: toRupees(transaction.amountPaise),
      currency: transaction.currency,
      availableBalance: toRupees(balancePaise),
      createdAt: transaction.createdAt,
    },
  };
}

module.exports = { toTransactionResponse, toTransferResponse };
