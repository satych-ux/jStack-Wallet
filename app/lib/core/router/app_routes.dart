/// Every route path and name. Call sites use these, never string literals.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String transfer = '/transfer';
  static const String transferConfirm = '/transfer/confirm';
  static const String transferResult = '/transfer/result';
  static const String transactions = '/transactions';
  static const String transactionDetails = '/transactions/:$idParam';

  static const String loginName = 'login';
  static const String dashboardName = 'dashboard';
  static const String transferName = 'transfer';
  static const String transferConfirmName = 'transferConfirm';
  static const String transferResultName = 'transferResult';
  static const String transactionsName = 'transactions';
  static const String transactionDetailsName = 'transactionDetails';

  /// Path parameter for a transaction id in [transactionDetails].
  static const String idParam = 'id';

  /// All seven routes, in screen order. The router test walks this list to
  /// prove every route resolves; add a route here when you add one there.
  static const List<({String name, String path})> all = [
    (name: loginName, path: login),
    (name: dashboardName, path: dashboard),
    (name: transferName, path: transfer),
    (name: transferConfirmName, path: transferConfirm),
    (name: transferResultName, path: transferResult),
    (name: transactionsName, path: transactions),
    (name: transactionDetailsName, path: transactionDetails),
  ];
}
