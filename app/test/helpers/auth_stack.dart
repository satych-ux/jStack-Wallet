import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:j_stack_flutter_app/core/network/auth_interceptor.dart';
import 'package:j_stack_flutter_app/core/network/session_expired_signal.dart';
import 'package:j_stack_flutter_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:j_stack_flutter_app/features/auth/data/datasources/session_local_data_source.dart';
import 'package:j_stack_flutter_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:j_stack_flutter_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'fake_backend.dart';

/// Secure storage held in a map. Only read, write and delete are used.
class MemorySecureStorage extends Mock implements FlutterSecureStorage {
  MemorySecureStorage([Map<String, String>? initial]) {
    values.addAll({...?initial});
    when(() => read(key: any(named: 'key'))).thenAnswer((i) async => values[i.namedArguments[#key]]);
    when(() => write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((i) async {
      final value = i.namedArguments[#value] as String?;
      final key = i.namedArguments[#key] as String;
      value == null ? values.remove(key) : values[key] = value;
    });
    when(() => delete(key: any(named: 'key'))).thenAnswer((i) async {
      values.remove(i.namedArguments[#key]);
    });
  }

  final Map<String, String> values = {};
}

/// The real auth stack (interceptor, data sources, repository, bloc) on a
/// [FakeBackend] and [MemorySecureStorage]; only the network and keychain
/// are fake.
class AuthStack {
  AuthStack({required this.backend, String? storedToken})
    : storage = MemorySecureStorage({'access_token': ?storedToken}) {
    session = SessionLocalDataSource(storage);
    dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
      ..httpClientAdapter = backend
      ..interceptors.add(AuthInterceptor(tokenStore: session, onSessionExpired: signal.fire));
    repository = AuthRepositoryImpl(AuthRemoteDataSource(dio), session);
  }

  final FakeBackend backend;
  final MemorySecureStorage storage;
  final SessionExpiredSignal signal = SessionExpiredSignal();
  late final SessionLocalDataSource session;
  late final Dio dio;
  late final AuthRepositoryImpl repository;

  String? get storedToken => storage.values['access_token'];

  /// Mirrors `main`: signed in at once when a token is stored, then
  /// [AuthStarted] confirms it.
  AuthBloc startBloc() => AuthBloc(
    repository: repository,
    sessionExpired: signal,
    initialState: storedToken != null ? const AuthAuthenticated() : const AuthUnauthenticated(),
  )..add(const AuthStarted());
}
