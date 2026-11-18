import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/config/app_config.dart';
import 'package:j_stack_flutter_app/core/di/injector.dart';
import 'package:j_stack_flutter_app/core/network/session_expired_signal.dart';
import 'package:j_stack_flutter_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:j_stack_flutter_app/features/auth/presentation/bloc/auth_bloc.dart';

import 'auth_stack.dart';
import 'fake_backend.dart';

/// GetIt set up exactly like `main`, except the network is [backend] and the
/// keychain is in memory. Reset after the test.
///
/// Returns the storage so a test can check the stored token.
MemorySecureStorage configureTestApp({required FakeBackend backend, String? storedToken}) {
  configureDependencies(config: const AppConfig(baseUrl: 'http://test/api/v1'));
  final storage = MemorySecureStorage({'access_token': ?storedToken});
  getIt
    ..unregister<FlutterSecureStorage>()
    ..registerSingleton<FlutterSecureStorage>(storage);
  getIt<Dio>().httpClientAdapter = backend;
  // No dispose: closing streams that blocs still listen to never completes
  // under a widget test's fake clock.
  addTearDown(() => getIt.reset(dispose: false));
  return storage;
}

/// The AuthBloc as `main` builds it: signed in at once when a token is
/// stored, then [AuthStarted] confirms it.
AuthBloc startAuthBloc(MemorySecureStorage storage) {
  final bloc = AuthBloc(
    repository: getIt<AuthRepository>(),
    sessionExpired: getIt<SessionExpiredSignal>(),
    initialState: storage.values['access_token'] != null ? const AuthAuthenticated() : const AuthUnauthenticated(),
  )..add(const AuthStarted());
  // Not awaited: under a widget test's fake clock `close()` never completes.
  // In the app the bloc lives as long as the app.
  addTearDown(() => unawaited(bloc.close()));
  return bloc;
}
