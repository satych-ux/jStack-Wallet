/// What the result screen shows: a success or a failure. Values are
/// display-ready; whoever builds them does the formatting.
sealed class TransferResultView {
  const TransferResultView({required this.beneficiaryName});

  final String beneficiaryName;
}

final class TransferSucceededView extends TransferResultView {
  const TransferSucceededView({
    required this.amount,
    required super.beneficiaryName,
    required this.reference,
    required this.dateTime,
    required this.updatedBalance,
  });

  /// e.g. `₹1,500.00`.
  final String amount;
  final String reference;

  /// e.g. `20 Oct 2026, 16:04`.
  final String dateTime;

  /// The `availableBalance` the transfer response returned. Never computed
  /// in the app.
  final String updatedBalance;
}

final class TransferFailedView extends TransferResultView {
  const TransferFailedView({
    required this.reason,
    required this.explanation,
    required super.beneficiaryName,
    this.subtitle = 'Your wallet was not debited. Nothing has changed.',
    this.statusCode,
    this.balance,
    this.canRetry = false,
  });

  /// True only when the outcome is unknown or temporary (timeout, no
  /// connection, server error): resending the same request, with the same
  /// key, can then succeed or return the original result. A definite refusal
  /// (insufficient balance, invalid details, key reused) would only be
  /// refused again, so the screen offers to edit the transfer instead.
  final bool canRetry;

  /// Uppercase headline of the banner, e.g. `INSUFFICIENT BALANCE`.
  final String reason;

  /// One or two sentences under it.
  final String explanation;

  /// Under the title. The default is only true when the server answered
  /// with an error; after a timeout the outcome is unknown, so the caller
  /// must say so instead.
  final String subtitle;

  /// e.g. `409`. Null when there was no response (timeout, no network).
  final String? statusCode;

  /// Current balance from the backend, if known. Null hides the row.
  final String? balance;
}
