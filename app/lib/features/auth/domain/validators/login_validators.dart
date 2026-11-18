/// Login form checks (AUTH-02). Each returns an error message, or null when
/// the value is acceptable. They only check shape; whether the credentials
/// are right is the backend's call.
library;

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Something@something.something, no spaces. Outer spaces are ignored.
String? validateEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return 'Enter your email';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
  return null;
}

/// Not trimmed: a password may legitimately contain spaces.
String? validatePassword(String value) {
  if (value.isEmpty) return 'Enter your password';
  return null;
}
