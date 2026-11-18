import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum StatusKind { success, pending, failed }

/// `SUCCESS` / `PENDING` / `FAILED` in mono caps, coloured by status.
class StatusLabel extends StatelessWidget {
  const StatusLabel({super.key, required this.status, this.large = false});

  final StatusKind status;

  /// Result and details screens use the 12px size; rows use 10px.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (String text, Color color) = switch (status) {
      StatusKind.success => ('SUCCESS', AppColors.success),
      StatusKind.pending => ('PENDING', AppColors.inkFaint),
      StatusKind.failed => ('FAILED', AppColors.brand),
    };
    final style = large
        ? AppTextStyles.monoStatusLarge
        : AppTextStyles.monoStatus;
    return Text(text, style: style.copyWith(color: color));
  }
}
