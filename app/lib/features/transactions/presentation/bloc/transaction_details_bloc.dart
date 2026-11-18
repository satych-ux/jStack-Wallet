import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/presentation/failure_message.dart';
import '../../../../core/presentation/section.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../models/transaction_details_view.dart';

sealed class TransactionDetailsEvent {
  const TransactionDetailsEvent();
}

/// Load (or retry) the transaction with the route's id.
final class TransactionDetailsRequested extends TransactionDetailsEvent {
  const TransactionDetailsRequested();
}

/// One transaction (TXN-06/07), always fetched by [id] from the backend,
/// never taken from a list item.
class TransactionDetailsBloc extends Bloc<TransactionDetailsEvent, Section<TransactionDetailsView>> {
  TransactionDetailsBloc({required this._repository, required this.id}) : super(const SectionLoading()) {
    on<TransactionDetailsRequested>(_onRequested, transformer: droppable());
  }

  final TransactionsRepository _repository;
  final String id;

  Future<void> _onRequested(
    TransactionDetailsRequested event,
    Emitter<Section<TransactionDetailsView>> emit,
  ) async {
    emit(const SectionLoading());
    switch (await _repository.getTransaction(id)) {
      case Ok(:final value):
        emit(SectionLoaded(TransactionDetailsView.fromTransaction(value)));
      case Err(failure: UnauthorizedFailure()):
        break;
      case Err(failure: NotFoundFailure()):
        emit(const SectionFailed('This transaction does not exist.'));
      case Err(:final failure):
        emit(SectionFailed(sectionErrorMessage(failure)));
    }
  }
}
