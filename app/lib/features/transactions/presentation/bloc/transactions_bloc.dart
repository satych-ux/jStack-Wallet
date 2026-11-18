import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/presentation/failure_message.dart';
import '../../../../core/presentation/section.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../models/history_view.dart';

sealed class TransactionsEvent {
  const TransactionsEvent();
}

/// Load (or, after an error, retry) the full history.
final class TransactionsRequested extends TransactionsEvent {
  const TransactionsRequested();
}

/// The history list (TXN-01). Kept in the backend's newest-first order;
/// search and filter are applied by the pure `groupHistory`, not here.
class TransactionsBloc extends Bloc<TransactionsEvent, Section<List<HistoryEntry>>> {
  TransactionsBloc({required this._repository}) : super(const SectionLoading()) {
    on<TransactionsRequested>(_onRequested, transformer: droppable());
  }

  final TransactionsRepository _repository;

  Future<void> _onRequested(TransactionsRequested event, Emitter<Section<List<HistoryEntry>>> emit) async {
    emit(const SectionLoading());
    switch (await _repository.getTransactions()) {
      case Ok(:final value):
        emit(SectionLoaded([for (final t in value) HistoryEntry.fromTransaction(t)]));
      // A 401 ends the session; AuthBloc is already returning to login.
      case Err(failure: UnauthorizedFailure()):
        break;
      case Err(:final failure):
        emit(SectionFailed(sectionErrorMessage(failure)));
    }
  }
}
