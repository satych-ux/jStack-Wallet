import 'package:flutter/material.dart';

import '../../../../core/presentation/section.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/filter_pill.dart';
import '../../../../core/widgets/shimmer/shimmer_box.dart';
import '../../../../core/widgets/shimmer/transaction_row_shimmer.dart';
import '../../../../core/widgets/transaction_rail.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../models/history_view.dart';
import '../widgets/history_search_field.dart';

/// Transaction history (TXN-01..06).
///
/// Search and the Credit/Debit filter run client-side over the fetched list
/// (the API has no query parameters). The grouped result is recomputed by
/// [groupHistory] only when the data, the query or the filter changes, never
/// in `build`. Search and pills stay usable while the list loads.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    this.transactions = const SectionLoading(),
    required this.onBack,
    required this.onOpen,
    required this.onRetry,
  });

  final Section<List<HistoryEntry>> transactions;
  final VoidCallback onBack;

  /// Called with the tapped row's reference (its id).
  final void Function(String reference) onOpen;
  final VoidCallback onRetry;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _query = TextEditingController();
  HistoryFilter _filter = HistoryFilter.all;
  List<HistoryGroup> _groups = const [];

  static const int _shimmerRows = 6;
  static const double _groupGap = 18;
  static const double _headerGap = AppSpacing.s8;

  @override
  void initState() {
    super.initState();
    _regroup();
    _query.addListener(() => setState(_regroup));
  }

  @override
  void didUpdateWidget(TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions) _regroup();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _regroup() {
    final transactions = widget.transactions;
    _groups = transactions is SectionLoaded<List<HistoryEntry>>
        ? groupHistory(transactions.data, query: _query.text, filter: _filter)
        : const [];
  }

  void _select(HistoryFilter filter) {
    setState(() {
      _filter = filter;
      _regroup();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.screenTopAppBar,
            AppSpacing.screenHorizontal,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopBar(title: 'Transactions', onBack: widget.onBack),
              const SizedBox(height: AppSpacing.s12),
              HistorySearchField(controller: _query),
              // Pills carry 4px of invisible touch padding top and bottom,
              // so this gap is DESIGN's 14 minus 4.
              const SizedBox(height: AppSpacing.s10),
              Row(
                children: [
                  for (final (filter, label) in const [
                    (HistoryFilter.all, 'All'),
                    (HistoryFilter.credit, 'Credit'),
                    (HistoryFilter.debit, 'Debit'),
                  ]) ...[
                    FilterPill(
                      label: label,
                      selected: _filter == filter,
                      onTap: () => _select(filter),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                  ],
                ],
              ),
              // DESIGN gives no value here; the between-group gap (18) reads
              // right next to the reference.
              const SizedBox(height: _groupGap),
              Expanded(child: _list()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list() {
    return switch (widget.transactions) {
      SectionLoading() => const _HistoryShimmer(rows: _shimmerRows),
      SectionFailed(:final message) => Align(
        alignment: Alignment.topCenter,
        child: ErrorStateView(
          title: 'Could not load transactions',
          message: message,
          onRetry: widget.onRetry,
        ),
      ),
      SectionLoaded(:final data) when data.isEmpty => const Align(
        alignment: Alignment.topCenter,
        child: EmptyStateView(
          title: 'No transactions yet',
          message: 'Your first transfer will appear here.',
        ),
      ),
      SectionLoaded() when _groups.isEmpty => const Align(
        alignment: Alignment.topCenter,
        child: EmptyStateView(
          title: 'No matching transactions',
          message: 'Try a different name, reference or filter.',
        ),
      ),
      SectionLoaded() => ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.screenBottom),
        itemCount: _groups.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : _groupGap),
          child: _DayGroup(group: _groups[index], onOpen: widget.onOpen),
        ),
      ),
    };
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.group, required this.onOpen});

  final HistoryGroup group;
  final void Function(String reference) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          group.title,
          style: AppTextStyles.monoLabel.copyWith(color: AppColors.inkFaint),
        ),
        const SizedBox(height: _TransactionsScreenState._headerGap),
        TransactionRail(
          itemCount: group.rows.length,
          itemBuilder: (context, index) {
            final row = group.rows[index];
            return TransactionRow(
              data: row,
              density: RailDensity.history,
              onTap: () => onOpen(row.reference),
            );
          },
        ),
      ],
    );
  }
}

/// A shimmering date header over [rows] shimmering history rows, under one
/// controller.
class _HistoryShimmer extends StatelessWidget {
  const _HistoryShimmer({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return ShimmerGroup(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ShimmerLine(
              style: AppTextStyles.monoLabel,
              box: ShimmerBox(width: 110, height: 9),
            ),
            const SizedBox(height: _TransactionsScreenState._headerGap),
            TransactionRail(
              itemCount: rows,
              itemBuilder: (context, index) =>
                  const TransactionRowShimmer(density: RailDensity.history),
            ),
          ],
        ),
      ),
    );
  }
}
