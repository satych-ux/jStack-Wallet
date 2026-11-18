import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/debug/debug_panel.dart';
import 'core/debug/debug_settings.dart';
import 'core/di/injector.dart';
import 'core/network/session_expired_signal.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/session_local_data_source.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Checked once, before anything is built, so a missing --dart-define
  // stops here with instructions instead of failing later on a request.
  final config = AppConfig.fromEnvironment();
  if (config.baseUrl.isEmpty) throw StateError(AppConfig.missingBaseUrlMessage);
  configureDependencies(config: config);

  // A stored token opens the dashboard at once; AuthStarted then confirms
  // it with /users/profile and a 401 returns to login (AUTH-06).
  final authBloc = AuthBloc(
    repository: getIt<AuthRepository>(),
    sessionExpired: getIt<SessionExpiredSignal>(),
    initialState: await _hasStoredToken() ? const AuthAuthenticated() : const AuthUnauthenticated(),
  )..add(const AuthStarted());

  runApp(JWalletApp(authBloc: authBloc));
}

/// An unreadable keystore counts as signed out rather than a crash.
Future<bool> _hasStoredToken() async {
  try {
    final token = await getIt<SessionLocalDataSource>().read();
    return token != null && token.isNotEmpty;
  } on Object catch (_) {
    return false;
  }
}

/// The app shell: theme plus the router with all seven screens. The router
/// is created once (in [State.initState]) so navigation survives rebuilds.
class JWalletApp extends StatefulWidget {
  const JWalletApp({super.key, required this.authBloc});

  final AuthBloc authBloc;

  @override
  State<JWalletApp> createState() => _JWalletAppState();
}

class _JWalletAppState extends State<JWalletApp> {
  late final GoRouter _router = createAppRouter(authBloc: widget.authBloc);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'jWallet Lite',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: _router,
      // The debug panel sits above every screen, outside the navigator.
      builder: (context, child) => DebugSettings.enabled
          ? DebugPanelOverlay(
              settings: getIt<DebugSettings>(),
              // A token the backend will reject: the next request gets a
              // real 401 and the app signs out the normal way.
              onExpireSession: () => getIt<SessionLocalDataSource>().save('expired-by-debug-panel'),
              child: child!,
            )
          : child!,
    );
  }
}
