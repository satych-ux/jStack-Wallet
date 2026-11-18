import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/presentation/failure_message.dart';
import '../../../../core/presentation/formatters.dart';
import '../../../../core/presentation/section.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';

/// The balance strip on Send Money: the backend's balance, formatted. Shown
/// for information only; the app never pre-rejects a transfer on it (the
/// backend's 409 decides).
class AvailableBalanceCubit extends Cubit<Section<String>> {
  AvailableBalanceCubit({required this._wallet})
    : super(const SectionLoading());

  final WalletRepository _wallet;

  Future<void> load() async {
    emit(const SectionLoading());
    switch (await _wallet.getWallet()) {
      case Ok(:final value):
        emit(SectionLoaded(Formatters.rupees(value.availableBalance)));
      case Err(failure: UnauthorizedFailure()):
        break;
      case Err(:final failure):
        emit(SectionFailed(sectionErrorMessage(failure)));
    }
  }
}
