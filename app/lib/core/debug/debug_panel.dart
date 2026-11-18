import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'debug_settings.dart';

/// A small bug button on the left edge, over every screen, that opens the
/// debug options. Not a screen or a route: an overlay above the navigator,
/// so it is reachable anywhere and never changes the back stack. Nothing in
/// it may need an Overlay (tooltips, menus, dialogs): there is none up here.
class DebugPanelOverlay extends StatefulWidget {
  const DebugPanelOverlay({
    super.key,
    required this.settings,
    required this.onExpireSession,
    required this.child,
  });

  final DebugSettings settings;

  /// Stores an invalid token, so the next request is genuinely rejected.
  final Future<void> Function() onExpireSession;
  final Widget child;

  @override
  State<DebugPanelOverlay> createState() => _DebugPanelOverlayState();
}

class _DebugPanelOverlayState extends State<DebugPanelOverlay> {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_open) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: const ColoredBox(color: AppColors.scrim),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _Panel(
              settings: widget.settings,
              onExpireSession: widget.onExpireSession,
              onClose: _toggle,
            ),
          ),
        ],
        // Hidden while the panel is open: it would cover the panel's text,
        // and the panel has its own close button.
        if (!_open)
          Positioned(
            left: 0,
            top: MediaQuery.sizeOf(context).height * 0.45,
            child: ListenableBuilder(
              listenable: widget.settings,
              builder: (context, _) =>
                  _BugButton(active: widget.settings.isActive, onTap: _toggle),
            ),
          ),
      ],
    );
  }
}

class _BugButton extends StatelessWidget {
  const _BugButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  static const double _width = 34;
  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Debug options',
      child: Material(
        color: active ? AppColors.brand : AppColors.ink,
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(AppSpacing.radiusButton),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(AppSpacing.radiusButton),
          ),
          child: const SizedBox(
            width: _width,
            height: _height,
            child: Icon(
              Icons.bug_report_outlined,
              size: 18,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.settings,
    required this.onExpireSession,
    required this.onClose,
  });

  final DebugSettings settings;
  final Future<void> Function() onExpireSession;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusPanel),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.s16,
            AppSpacing.screenHorizontal,
            AppSpacing.s12,
          ),
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Debug options',
                        style: AppTextStyles.headline.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    // No tooltip: the panel sits above the navigator, where
                    // there is no Overlay for a tooltip to show in.
                    Semantics(
                      button: true,
                      label: 'Close',
                      child: IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Each option changes the real request, so the error you see is the backend\'s own.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.s14),
                const _Label('NEXT TRANSFER ONLY'),
                _Choice(
                  title: 'Normal',
                  selected: settings.nextTransfer == null,
                  onTap: () => settings.nextTransfer = null,
                ),
                _Choice(
                  title: 'Slow server (timeout)',
                  subtitle: 'Times out, but the money moves. "Try again" reuses the key: one deduction.',
                  selected: settings.nextTransfer == TransferFault.slowServer,
                  onTap: () => settings.nextTransfer = TransferFault.slowServer,
                ),
                _Choice(
                  title: 'Reuse the last transfer\'s key',
                  subtitle: settings.lastSuccessfulKey == null
                      ? 'Make one successful transfer first.'
                      : 'Use a different amount: 409 IDEMPOTENCY_KEY_REUSED.',
                  selected: settings.nextTransfer == TransferFault.reuseLastKey,
                  onTap: settings.lastSuccessfulKey == null
                      ? null
                      : () =>
                            settings.nextTransfer = TransferFault.reuseLastKey,
                ),
                _Choice(
                  title: 'Drop the Idempotency-Key',
                  subtitle: '400: the request is incomplete.',
                  selected: settings.nextTransfer == TransferFault.dropKey,
                  onTap: () => settings.nextTransfer = TransferFault.dropKey,
                ),
                const SizedBox(height: AppSpacing.s10),
                const _Label('SESSION AND NETWORK'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.brand,
                  title: Text(
                    'Offline',
                    style: AppTextStyles.rowTitle.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Every request fails until switched off.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  value: settings.offline,
                  onChanged: (value) => settings.offline = value,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      await onExpireSession();
                      onClose();
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: AppColors.brand,
                      size: 18,
                    ),
                    label: Text(
                      'Expire my session (then pull to refresh)',
                      style: AppTextStyles.link.copyWith(
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                const _Label('NO SWITCH NEEDED'),
                Text(
                  'Insufficient balance: send more than your balance (e.g. 99999).\n'
                  'Form validation: amount 10.123, or mobile 98765.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s4),
    child: Text(
      text,
      style: AppTextStyles.monoLabel.copyWith(color: AppColors.inkFaint),
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;

  /// Null disables the option.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final subtitle = this.subtitle;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: enabled
                  ? (selected ? AppColors.brand : AppColors.inkMuted)
                  : AppColors.inkFaint,
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.rowTitle.copyWith(
                      color: enabled ? AppColors.ink : AppColors.inkFaint,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
