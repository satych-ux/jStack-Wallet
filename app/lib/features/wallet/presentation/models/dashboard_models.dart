/// Display-ready values for the dashboard. Whoever builds these does the
/// formatting; the screen only lays them out.
library;

class ProfileView {
  const ProfileView({required this.name, required this.initials});

  final String name;

  /// e.g. `DU` for Demo User.
  final String initials;
}

class BalanceView {
  const BalanceView({
    required this.balance,
    required this.walletId,
    required this.maskedAccount,
  });

  /// Formatted with currency, e.g. `₹25,450.75`. From the backend, never
  /// computed in the app.
  final String balance;
  final String walletId;
  final String maskedAccount;
}
