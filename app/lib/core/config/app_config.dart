/// Build-time settings. Nothing here is hard-coded per environment: the base
/// URL comes from `--dart-define=API_BASE_URL=...` (see README).
class AppConfig {
  const AppConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
  });

  /// Reads `API_BASE_URL` from `--dart-define`. Empty when it was not given;
  /// `main` then stops with [missingBaseUrlMessage].
  factory AppConfig.fromEnvironment() =>
      const AppConfig(baseUrl: String.fromEnvironment('API_BASE_URL'));

  /// Says how to set the base URL, for every target.
  static const missingBaseUrlMessage =
      'API_BASE_URL is not set. Run with --dart-define=API_BASE_URL=<url>, e.g. '
      'http://10.0.2.2:3000/api/v1 (Android emulator), '
      'http://<your-computer-LAN-IP>:3000/api/v1 (physical device), '
      'http://localhost:3000/api/v1 (iOS simulator).';

  /// e.g. `http://10.0.2.2:3000/api/v1` for the Android emulator.
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}
