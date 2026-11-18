import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/router/temporary_fake_wiring.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const JWalletApp());
}

/// The app shell: theme plus the router with all seven screens.
///
/// It owns the sign-in flag the router guards on, and creates the router
/// once (in [State.initState]) so navigation state survives rebuilds.
class JWalletApp extends StatefulWidget {
  const JWalletApp({
    super.key,
    this.fakeLatency = const Duration(milliseconds: 700),
  });

  /// TEMPORARY: how long the fake repositories take to answer. Tests pass
  /// zero.
  final Duration fakeLatency;

  @override
  State<JWalletApp> createState() => _JWalletAppState();
}

class _JWalletAppState extends State<JWalletApp> {
  final _isAuthenticated = ValueNotifier(false);
  late final GoRouter _router = createAppRouter(
    isAuthenticated: _isAuthenticated,
    // TEMPORARY presentation scaffolding. Delete when the data slice lands.
    // Any input that passes the form's validation signs in, so the screens
    // can be walked end to end. The auth slice replaces this with AuthBloc
    // calling POST /auth/login and storing the token.
    onLoginSubmitted: (_, _) => _isAuthenticated.value = true,
    // TEMPORARY: sample data from the fake repositories.
    fakeData: FakeData(latency: widget.fakeLatency),
  );

  @override
  void dispose() {
    _router.dispose();
    _isAuthenticated.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'jWallet Lite',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: _router,
    );
  }
}
