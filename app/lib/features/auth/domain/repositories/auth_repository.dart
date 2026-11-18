// TEMPORARY presentation scaffolding. Delete when the data slice lands.

import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});

  Future<void> logout();
}
