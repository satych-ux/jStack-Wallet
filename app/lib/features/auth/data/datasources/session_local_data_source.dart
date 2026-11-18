import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/token_store.dart';

/// The access token, kept in the platform's secure storage (Keychain /
/// Keystore), never in shared preferences. The network layer reads and
/// clears it through [TokenStore]; the auth repository also saves it.
class SessionLocalDataSource implements TokenStore {
  const SessionLocalDataSource(this._storage);

  static const _tokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> save(String token) => _storage.write(key: _tokenKey, value: token);

  /// Deleting a key that isn't there is fine, so this is safe to repeat.
  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);
}
