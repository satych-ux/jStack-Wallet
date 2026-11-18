import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/error/failure.dart';
import 'package:j_stack_flutter_app/core/error/result.dart';
import 'package:j_stack_flutter_app/core/network/envelope.dart';
import 'package:j_stack_flutter_app/features/transfer/data/models/transfer_result_model.dart';
import 'package:j_stack_flutter_app/features/transfer/domain/entities/transfer_request.dart';
import 'package:j_stack_flutter_app/features/transfer/domain/entities/transfer_result.dart';
import 'package:j_stack_flutter_app/features/transfer/domain/repositories/transfer_repository.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/bloc/transfer_bloc.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/models/transfer_attempt.dart';
import 'package:j_stack_flutter_app/features/transfer/presentation/models/transfer_draft.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class _MockTransferRepository extends Mock implements TransferRepository {}

const _attempt = TransferAttempt(
  draft: TransferDraft(amount: '1500', beneficiaryName: 'Rahul Sharma', mobileNumber: '9876543210', remarks: 'Dinner split'),
  requestKey: 'key-1',
);

/// The backend's real success answer, from the captured fixture.
final TransferResult _captured = TransferResultModel.fromJson(dataObject(fixture('transfer_success.json'))).toEntity();

void main() {
  late _MockTransferRepository repository;

  setUpAll(() => registerFallbackValue(const TransferRequest(beneficiaryName: '', mobileNumber: '', amount: 0)));
  setUp(() => repository = _MockTransferRepository());

  void answer(Result<TransferResult> result) => when(
    () => repository.transfer(any(), idempotencyKey: any(named: 'idempotencyKey')),
  ).thenAnswer((_) async => result);

  // ---------------------------------------------------------------- TST-03
  blocTest<TransferBloc, TransferState>(
    'TST-03: idle to submitting to failure(InsufficientBalance) on a 409, and no balance is held',
    setUp: () => answer(const Err(InsufficientBalanceFailure())),
    build: () => TransferBloc(repository: repository, attempt: _attempt),
    act: (bloc) => bloc.add(const TransferSubmitted()),
    expect: () => const [
      TransferState(attempt: _attempt, phase: TransferPhase.submitting),
      TransferState(attempt: _attempt, phase: TransferPhase.failed, failure: InsufficientBalanceFailure()),
    ],
    verify: (bloc) {
      // Nothing in state could stand in for a new balance: the wallet is
      // reloaded from the backend, never adjusted here.
      expect(bloc.state.result, isNull);
    },
  );

  // ---------------------------------------------------------------- TST-04
  blocTest<TransferBloc, TransferState>(
    "TST-04: idle to submitting to success, holding exactly the backend's balance",
    setUp: () => answer(Ok(_captured)),
    build: () => TransferBloc(repository: repository, attempt: _attempt),
    act: (bloc) => bloc.add(const TransferSubmitted()),
    expect: () => [
      const TransferState(attempt: _attempt, phase: TransferPhase.submitting),
      TransferState(attempt: _attempt, phase: TransferPhase.succeeded, result: _captured),
    ],
    verify: (bloc) {
      // No Dart arithmetic: the balance in state is the fixture's own value.
      final balance = fixture('transfer_success.json')['data']['availableBalance'] as num;
      expect(bloc.state.result!.availableBalance, balance.toDouble());
    },
  );

  blocTest<TransferBloc, TransferState>(
    'sends the attempt as typed, with its Idempotency-Key',
    setUp: () => answer(Ok(_captured)),
    build: () => TransferBloc(repository: repository, attempt: _attempt),
    act: (bloc) => bloc.add(const TransferSubmitted()),
    verify: (_) => verify(
      () => repository.transfer(
        const TransferRequest(beneficiaryName: 'Rahul Sharma', mobileNumber: '9876543210', amount: 1500, remarks: 'Dinner split'),
        idempotencyKey: 'key-1',
      ),
    ).called(1),
  );

  blocTest<TransferBloc, TransferState>(
    'a retry after a timeout sends the same key',
    setUp: () => answer(const Err(TimeoutFailure())),
    build: () => TransferBloc(repository: repository, attempt: _attempt),
    act: (bloc) async {
      bloc.add(const TransferSubmitted());
      await bloc.stream.firstWhere((s) => s.phase == TransferPhase.failed);
      bloc.add(const TransferSubmitted());
    },
    verify: (_) => verify(() => repository.transfer(any(), idempotencyKey: 'key-1')).called(2),
  );

  // The backend holds its answer until the second tap has arrived, so the
  // first submit is still in flight: an instant answer would let the first
  // finish before the second is handled, and the test would prove nothing.
  late Completer<Result<TransferResult>> pending;
  blocTest<TransferBloc, TransferState>(
    'droppable: two rapid submits produce one repository call',
    setUp: () {
      pending = Completer();
      when(
        () => repository.transfer(any(), idempotencyKey: any(named: 'idempotencyKey')),
      ).thenAnswer((_) => pending.future);
    },
    build: () => TransferBloc(repository: repository, attempt: _attempt),
    act: (bloc) async {
      bloc.add(const TransferSubmitted());
      await bloc.stream.firstWhere((s) => s.phase == TransferPhase.submitting);
      bloc.add(const TransferSubmitted());
      await Future<void>.delayed(Duration.zero);
      pending.complete(Ok(_captured));
    },
    verify: (_) => verify(() => repository.transfer(any(), idempotencyKey: any(named: 'idempotencyKey'))).called(1),
  );
}
