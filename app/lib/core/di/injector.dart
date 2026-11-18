import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../network/session_expired_signal.dart';
import '../network/token_store.dart';

final GetIt getIt = GetIt.instance;

/// Registers the app's shared services. Called once from `main()`.
///
/// Each feature adds its own data sources, repositories and blocs here as it
/// is wired (W1–W4). [TokenStore] is registered by the auth feature (W1);
/// `Dio` is lazy, so nothing asks for the token store before then.
void configureDependencies({AppConfig? config}) {
  getIt
    ..registerSingleton<AppConfig>(config ?? AppConfig.fromEnvironment())
    ..registerSingleton<SessionExpiredSignal>(
      SessionExpiredSignal(),
      dispose: (signal) => signal.dispose(),
    )
    ..registerLazySingleton<Dio>(
      () => createDio(
        getIt<AppConfig>(),
        interceptors: [
          AuthInterceptor(
            tokenStore: getIt<TokenStore>(),
            onSessionExpired: getIt<SessionExpiredSignal>().fire,
          ),
        ],
      ),
    );
}
