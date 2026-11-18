import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/transfer_request.dart';
import '../../domain/entities/transfer_result.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../models/transfer_attempt.dart';

sealed class TransferEvent {
  const TransferEvent();
}

/// Send the attempt, or resend it after a failure. Always with the
/// attempt's own key, so a retry can never deduct twice.
final class TransferSubmitted extends TransferEvent {
  const TransferSubmitted();
}

enum TransferPhase { idle, submitting, succeeded, failed }

/// One transfer attempt and where it stands. The [attempt] (draft plus its
/// Idempotency-Key) is fixed for the bloc's life; a new transfer from the
/// form is a new attempt with a new key and a new bloc.
class TransferState extends Equatable {
  const TransferState({
    required this.attempt,
    this.phase = TransferPhase.idle,
    this.result,
    this.failure,
  });

  final TransferAttempt attempt;
  final TransferPhase phase;

  /// Set when [phase] is succeeded: the backend's answer, balance included.
  final TransferResult? result;

  /// Set when [phase] is failed.
  final Failure? failure;

  @override
  List<Object?> get props => [attempt.requestKey, phase, result, failure];
}

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  /// [resumeFrom] continues an attempt that already ran: the result screen
  /// retries the same attempt, with the same key, from where it stopped.
  TransferBloc({
    required this._repository,
    required TransferAttempt attempt,
    TransferState? resumeFrom,
  }) : super(resumeFrom ?? TransferState(attempt: attempt)) {
    // A second tap while a submit runs is dropped, not queued (no double send).
    on<TransferSubmitted>(_onSubmitted, transformer: droppable());
  }

  final TransferRepository _repository;

  Future<void> _onSubmitted(
    TransferSubmitted event,
    Emitter<TransferState> emit,
  ) async {
    final attempt = state.attempt;
    // A retry keeps the last failure, so the result screen can keep showing
    // it (with its retry spinner) until the new answer arrives.
    emit(
      TransferState(
        attempt: attempt,
        phase: TransferPhase.submitting,
        failure: state.failure,
      ),
    );
    final draft = attempt.draft;
    final request = TransferRequest(
      beneficiaryName: draft.beneficiaryName,
      mobileNumber: draft.mobileNumber,
      amount: num.parse(draft.amount),
      remarks: draft.remarks,
    );
    switch (await _repository.transfer(
      request,
      idempotencyKey: attempt.requestKey,
    )) {
      case Ok(:final value):
        emit(
          TransferState(
            attempt: attempt,
            phase: TransferPhase.succeeded,
            result: value,
          ),
        );
      case Err(:final failure):
        emit(
          TransferState(
            attempt: attempt,
            phase: TransferPhase.failed,
            failure: failure,
          ),
        );
    }
  }
}
