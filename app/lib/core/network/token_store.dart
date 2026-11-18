/// Where the access token lives. The network layer only reads and clears it;
/// the auth feature implements it with secure storage and also saves it.
abstract interface class TokenStore {
  /// The stored token, or null when signed out.
  Future<String?> read();

  Future<void> clear();
}
