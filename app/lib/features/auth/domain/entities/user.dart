// TEMPORARY presentation scaffolding. Delete when the data slice lands.

/// The signed-in user, as returned by POST /auth/login.
class User {
  const User({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;
}
