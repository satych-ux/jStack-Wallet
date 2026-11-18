import '../../../../core/error/failure.dart';
import '../../../../core/presentation/formatters.dart';
import '../bloc/transfer_bloc.dart';
import 'transfer_result_view.dart';

const _notDebited = 'Your wallet was not debited. Nothing has changed.';
const _unknown =
    'We could not confirm the transfer. Try again: it will not be charged twice.';

/// What the result screen shows for a finished attempt. Success shows the
/// backend's own balance; nothing here computes money.
TransferResultView transferResultView(TransferState state) {
  final name = state.attempt.draft.beneficiaryName;
  final result = state.result;
  if (result != null) {
    return TransferSucceededView(
      amount: Formatters.rupees(result.amount),
      beneficiaryName: name,
      reference: result.transactionId,
      dateTime: Formatters.dateTime(result.createdAt),
      updatedBalance: Formatters.rupees(result.availableBalance),
    );
  }
  return switch (state.failure ?? const ServerFailure()) {
    InsufficientBalanceFailure() => TransferFailedView(
      reason: 'INSUFFICIENT BALANCE',
      explanation: 'The amount is more than your available balance. Edit the amount and try again.',
      beneficiaryName: name,
      statusCode: '409',
    ),
    // The request may have reached the wallet: say so, and offer the retry
    // that reuses the same key.
    TimeoutFailure() => TransferFailedView(
      reason: 'NOT CONFIRMED',
      explanation: 'The wallet did not answer in time.',
      beneficiaryName: name,
      subtitle: _unknown,
      canRetry: true,
    ),
    NetworkFailure() => TransferFailedView(
      reason: 'NO CONNECTION',
      explanation: 'Could not reach the wallet. Check your connection.',
      beneficiaryName: name,
      subtitle: _unknown,
      canRetry: true,
    ),
    // A 400 without fields (missing key) is an app bug, not user input.
    ValidationFailure(:final fields) => TransferFailedView(
      reason: 'INVALID DETAILS',
      explanation: fields.isEmpty
          ? 'The transfer request was incomplete. Start a new transfer.'
          : fields.values.join(' '),
      beneficiaryName: name,
      statusCode: '400',
      subtitle: _notDebited,
    ),
    IdempotencyKeyReusedFailure() => TransferFailedView(
      reason: 'REQUEST CONFLICT',
      explanation: 'This request was already used for a different transfer. Start a new transfer.',
      beneficiaryName: name,
      statusCode: '409',
      subtitle: _notDebited,
    ),
    UnauthorizedFailure() => TransferFailedView(
      reason: 'SIGNED OUT',
      explanation: 'Your session ended. Sign in again.',
      beneficiaryName: name,
      statusCode: '401',
      subtitle: _notDebited,
    ),
    NotFoundFailure() || ServerFailure() => TransferFailedView(
      reason: 'SERVER ERROR',
      explanation: 'Something went wrong on the wallet server.',
      beneficiaryName: name,
      subtitle: _unknown,
      canRetry: true,
    ),
  };
}
