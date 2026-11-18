import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_spacing.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/jwallet_button.dart';
import 'app_routes.dart';

/// Shown by the router's `errorBuilder` for any path it does not know.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.screenTopAppBar,
            AppSpacing.screenHorizontal,
            AppSpacing.screenBottom,
          ),
          child: Column(
            children: [
              const EmptyStateView(
                title: 'Page not found',
                message: 'This link does not lead anywhere in jWallet Lite.',
              ),
              const Spacer(),
              JWalletButton(
                label: 'Back to dashboard',
                onPressed: () => context.go(AppRoutes.dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
