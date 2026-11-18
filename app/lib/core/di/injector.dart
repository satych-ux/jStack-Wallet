import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/session_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/transactions/data/datasources/transactions_remote_data_source.dart';
import '../../features/transfer/data/datasources/transfer_remote_data_source.dart';
import '../../features/transfer/data/repositories/transfer_repository_impl.dart';
import '../../features/transfer/domain/repositories/transfer_repository.dart';
import '../../features/transactions/data/repositories/transactions_repository_impl.dart';
import '../../features/transactions/domain/repositories/transactions_repository.dart';
import '../../features/wallet/data/datasources/wallet_remote_data_source.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../config/app_config.dart';
import '../debug/debug_interceptor.dart';
import '../debug/debug_settings.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../network/session_expired_signal.dart';
import '../network/token_store.dart';

final GetIt getIt = GetIt.instance;

/// Registers the app's services. Called once from `main()`, which checks the
/// base URL first. Each feature adds its data sources and repository here
/// as it is wired (W1–W4). Everything is lazy: built on first use.
void configureDependencies({AppConfig? config}) {
  getIt
    ..registerSingleton<AppConfig>(config ?? AppConfig.fromEnvironment())
    // The debug panel's switches (only used when DebugSettings.enabled).
    ..registerSingleton<DebugSettings>(DebugSettings())
    ..registerSingleton<SessionExpiredSignal>(
      SessionExpiredSignal(),
      dispose: (signal) => signal.dispose(),
    )
    // --- Session: one instance, reachable as both types (the interceptor
    // reads and clears it as a TokenStore; the auth repository also saves).
    ..registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage())
    ..registerLazySingleton<SessionLocalDataSource>(() => SessionLocalDataSource(getIt()))
    ..registerLazySingleton<TokenStore>(() => getIt<SessionLocalDataSource>())
    // --- Network
    ..registerLazySingleton<Dio>(
      () => createDio(
        getIt<AppConfig>(),
        interceptors: [
          AuthInterceptor(
            tokenStore: getIt<TokenStore>(),
            onSessionExpired: getIt<SessionExpiredSignal>().fire,
          ),
          // After the auth interceptor, so it sees each request as sent.
          if (DebugSettings.enabled) DebugInterceptor(getIt<DebugSettings>()),
        ],
      ),
    )
    // --- Auth (W1)
    ..registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(getIt()))
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt(), getIt()))
    // --- Wallet (W2)
    ..registerLazySingleton<WalletRemoteDataSource>(() => WalletRemoteDataSource(getIt()))
    ..registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(getIt()))
    // --- Transactions (W2 dashboard, W3 history and details)
    ..registerLazySingleton<TransactionsRemoteDataSource>(() => TransactionsRemoteDataSource(getIt()))
    ..registerLazySingleton<TransactionsRepository>(() => TransactionsRepositoryImpl(getIt()))
    // --- Transfer (W4)
    ..registerLazySingleton<TransferRemoteDataSource>(() => TransferRemoteDataSource(getIt()))
    ..registerLazySingleton<TransferRepository>(() => TransferRepositoryImpl(getIt()));
}
