import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/jwallet_button.dart';
import '../../../../core/widgets/jwallet_text_field.dart';
import '../../domain/validators/login_validators.dart';
import '../widgets/demo_credentials_card.dart';

/// Sign-in screen (AUTH-01..04).
///
/// It validates input and reports a valid submission through [onSubmit].
/// It never signs in or navigates by itself: the caller runs the request,
/// passes [isLoading] while it is in flight, and [errorMessage] if it failed.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Called with the trimmed email and the password, only when both pass
  /// validation and no request is running.
  final void Function(String email, String password) onSubmit;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;

  static const double _brandGap = 16;
  static const double _headlineGap = 36;
  static const double _headlineMaxWidth = 260;
  static const double _bodyMaxWidth = 280;
  static const double _buttonGap = 6;
  static const double _bottomPadding = 28;

  @override
  void initState() {
    super.initState();
    // An error goes away as soon as the user edits the field it is about.
    _email.addListener(() {
      if (_emailError != null) setState(() => _emailError = null);
    });
    _password.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final emailError = validateEmail(_email.text);
    final passwordError = validatePassword(_password.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (emailError == null && passwordError == null) {
      widget.onSubmit(_email.text.trim(), _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = widget.errorMessage;
    return Scaffold(
      body: SafeArea(
        // The form scrolls (small screens, open keyboard); the footer line
        // stays pinned at the bottom.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontalLogin,
            0,
            AppSpacing.screenHorizontalLogin,
            _bottomPadding,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.screenTopLogin,
                    bottom: AppSpacing.s22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandMark(),
                      const SizedBox(height: _brandGap),
                      Text(
                        'jWallet Lite',
                        style: AppTextStyles.wordmark.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: _headlineGap),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _headlineMaxWidth,
                        ),
                        child: Text(
                          'Sign in to move money.',
                          style: AppTextStyles.display.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _bodyMaxWidth,
                        ),
                        child: Text(
                          'Wallet balance and history load from the jWallet '
                          'API once you are signed in.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s34),
                      JWalletTextField(
                        label: 'EMAIL',
                        hint: 'name@example.com',
                        controller: _email,
                        errorText: _emailError,
                        kind: JWalletFieldKind.email,
                      ),
                      const SizedBox(height: AppSpacing.s18),
                      JWalletTextField(
                        label: 'PASSWORD',
                        controller: _password,
                        errorText: _passwordError,
                        kind: JWalletFieldKind.password,
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.s14),
                        Text(
                          errorMessage,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                      const SizedBox(height: _buttonGap),
                      JWalletButton(
                        label: widget.isLoading ? 'Signing in' : 'Sign in',
                        onPressed: _submit,
                        variant: widget.isLoading
                            ? JWalletButtonVariant.loading
                            : JWalletButtonVariant.primary,
                      ),
                      const SizedBox(height: AppSpacing.s22),
                      const DemoCredentialsCard(),
                    ],
                  ),
                ),
              ),
              Text(
                'Mock environment. No real funds move.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
