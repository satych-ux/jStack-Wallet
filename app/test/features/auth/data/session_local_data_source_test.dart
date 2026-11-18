import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/features/auth/data/datasources/session_local_data_source.dart';

import '../../../helpers/auth_stack.dart';

void main() {
  test('save, read and clear the token in secure storage under one key', () async {
    final storage = MemorySecureStorage();
    final session = SessionLocalDataSource(storage);

    expect(await session.read(), isNull);
    await session.save('mock_access_token_123');
    expect(storage.values, {'access_token': 'mock_access_token_123'});
    expect(await session.read(), 'mock_access_token_123');
    await session.clear();
    expect(storage.values, isEmpty);
  });

  test('clearing twice is harmless', () async {
    final session = SessionLocalDataSource(MemorySecureStorage());

    await session.clear();
    await session.clear();

    expect(await session.read(), isNull);
  });
}
