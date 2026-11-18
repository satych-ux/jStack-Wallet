import 'package:flutter/widgets.dart';

import '../../../../core/presentation/section.dart';
import '../../../../core/widgets/balance_panel.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/shimmer/balance_panel_shimmer.dart';
import '../../../../core/widgets/shimmer/shimmer_box.dart';
import '../models/dashboard_models.dart';

/// The dashboard's balance slot: shimmer, the panel, or an error with retry
/// (WAL-02, WAL-06).
class BalanceSection extends StatelessWidget {
  const BalanceSection({super.key, required this.balance, required this.onRetry});

  final Section<BalanceView> balance;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (balance) {
    SectionLoading() => const ShimmerGroup(child: BalancePanelShimmer()),
    SectionLoaded(:final data) => BalancePanel(
      balance: data.balance,
      walletId: data.walletId,
      maskedAccount: data.maskedAccount,
    ),
    SectionFailed(:final message) => ErrorStateView(
      title: 'Could not load your balance',
      message: message,
      onRetry: onRetry,
    ),
  };
}
