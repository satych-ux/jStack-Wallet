// TEMPORARY presentation scaffolding. Delete when the data slice lands.

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Returns a fixed demo user so the login screen can be built before the
/// backend is wired. No validation, no network.
class FakeAuthRepository implements AuthRepository {
  const FakeAuthRepository();

  static const User sampleUser = User(
    id: 'USR001',
    name: 'Aditi Verma',
    email: 'demo@jstack.co',
  );

  @override
  Future<User> login({required String email, required String password}) async =>
      sampleUser;

  @override
  Future<void> logout() async {}
}
