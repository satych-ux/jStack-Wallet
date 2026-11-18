import 'transfer_draft.dart';

/// One attempt at a transfer: what the user entered plus the
/// Idempotency-Key for it (TRF-04).
///
/// The key is created once, when the user moves from Send money to
/// Confirmation, and every retry of this attempt reuses it. Editing the
/// details starts a new attempt with a new key, because the payload changed.
class TransferAttempt {
  const TransferAttempt({required this.draft, required this.requestKey});

  final TransferDraft draft;
  final String requestKey;
}
