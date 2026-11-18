import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/error/api_error.dart';

import '../../helpers/fixtures.dart';

void main() {
  test('every fixture file exists and is valid JSON', () {
    for (final name in fixtureNames) {
      final file = File('test/fixtures/$name');
      expect(file.existsSync(), isTrue, reason: '$name missing: run scripts/capture-fixtures.sh');
      expect(() => jsonDecode(file.readAsStringSync()), returnsNormally, reason: name);
    }
  });

  test('no stray fixture files: the folder holds exactly what the script captures', () {
    final onDisk = Directory('test/fixtures')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.json'))
        .toSet();

    expect(onDisk, fixtureNames.toSet());
  });

  test('success fixtures use the success envelope', () {
    for (final name in fixtureNames.where((n) => !errorFixtureNames.contains(n))) {
      final body = fixture(name);
      expect(body['success'], isTrue, reason: name);
      expect(body.containsKey('data'), isTrue, reason: name);
    }
  });

  test('every error fixture parses into the shared error shape', () {
    for (final name in errorFixtureNames) {
      final body = fixture(name);
      expect(body['success'], isFalse, reason: name);

      final error = ApiError.tryParse(body);
      expect(error, isNotNull, reason: name);
      expect(error!.code, isNotEmpty, reason: name);
      expect(error.message, isNotEmpty, reason: name);
    }
  });

  test('error codes are the ones the backend actually sent', () {
    String codeOf(String name) => ApiError.tryParse(fixture(name))!.code;

    expect(codeOf('login_401.json'), 'INVALID_CREDENTIALS');
    expect(codeOf('login_400_validation.json'), 'VALIDATION_ERROR');
    expect(codeOf('profile_401.json'), 'UNAUTHORIZED');
    expect(codeOf('transaction_404.json'), 'TRANSACTION_NOT_FOUND');
    expect(codeOf('route_404.json'), 'NOT_FOUND');
    expect(codeOf('transfer_400_missing_key.json'), 'IDEMPOTENCY_KEY_REQUIRED');
    expect(codeOf('transfer_409_insufficient.json'), 'INSUFFICIENT_BALANCE');
    expect(codeOf('transfer_400_validation.json'), 'VALIDATION_ERROR');
    expect(codeOf('transfer_409_idempotency_reuse.json'), 'IDEMPOTENCY_KEY_REUSED');
  });

  test('only field validation errors carry fields', () {
    const withFields = {'transfer_400_validation.json', 'login_400_validation.json'};
    for (final name in errorFixtureNames) {
      final fields = ApiError.tryParse(fixture(name))!.fields;
      if (withFields.contains(name)) {
        expect(fields, isNotEmpty, reason: name);
      } else {
        expect(fields, isEmpty, reason: name);
      }
    }
  });

  test('balance_whole_rupees.json really holds a bare integer, as JSON sends whole rupees', () {
    final balance = fixture('balance_whole_rupees.json')['data']['availableBalance'];

    expect(balance, isA<int>());
  });

  test('ApiError.tryParse returns null for anything that is not the error shape', () {
    for (final body in <Object?>[
      null,
      'Bad Gateway',
      <String, dynamic>{},
      fixture('balance.json'),
      <String, dynamic>{'error': 'boom'},
      <String, dynamic>{'error': <String, dynamic>{'code': 1, 'message': 'x'}},
    ]) {
      expect(ApiError.tryParse(body), isNull, reason: '$body');
    }
  });
}
