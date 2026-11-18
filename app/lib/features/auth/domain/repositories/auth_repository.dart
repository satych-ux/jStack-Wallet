import '../../../../core/error/result.dart';
import '../entities/user.dart';

abstract interface class AuthRepository {
  /// POST /auth/login. On success the token is stored before this returns.
  Future<Result<User>> login({required String email, required String password});

  /// Checks a stored token with GET /users/profile (AUTH-06).
  ///
  /// - `Ok(null)`: no token stored, so signed out.
  /// - `Ok(user)`: the token is valid.
  /// - `Err(UnauthorizedFailure)`: the token was rejected and has been cleared.
  /// - `Err(other)`: the backend could not be asked (offline, timeout); the
  ///   token is kept, since nothing says it is invalid.
  Future<Result<User?>> restoreSession();

  /// Clears the stored token. Safe to call when already signed out.
  Future<void> logout();
}
