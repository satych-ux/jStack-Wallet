import 'dart:convert';
import 'dart:io';

/// Every file `scripts/capture-fixtures.sh` writes. Captured from the running
/// backend, never hand-written.
const fixtureNames = [
  'login_success.json',
  'login_401.json',
  'login_400_validation.json',
  'profile.json',
  'profile_401.json',
  'balance.json',
  'balance_whole_rupees.json',
  'transactions.json',
  'transaction_details.json',
  'transfer_success.json',
  'transfer_409_insufficient.json',
  'transfer_400_validation.json',
  'transfer_409_idempotency_reuse.json',
  'transfer_400_missing_key.json',
  'transaction_404.json',
  'route_404.json',
];

/// The error responses among them.
const errorFixtureNames = [
  'login_401.json',
  'login_400_validation.json',
  'profile_401.json',
  'transaction_404.json',
  'route_404.json',
  'transfer_409_insufficient.json',
  'transfer_400_validation.json',
  'transfer_400_missing_key.json',
  'transfer_409_idempotency_reuse.json',
];

/// A captured response body, decoded. `flutter test` runs from `app/`.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;
