import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/error/failure.dart';
import 'package:j_stack_flutter_app/core/error/failure_mapper.dart';
import 'package:j_stack_flutter_app/core/network/envelope.dart';
import 'package:j_stack_flutter_app/features/auth/data/models/login_response_model.dart';
import 'package:j_stack_flutter_app/features/auth/data/models/user_model.dart';
import 'package:j_stack_flutter_app/features/auth/domain/entities/user.dart';

import '../../../helpers/fixtures.dart';

void main() {
  test('LoginResponseModel.fromJson parses login_success.json: accessToken, user id, name, email', () {
    final model = LoginResponseModel.fromJson(dataObject(fixture('login_success.json')));

    expect(model.accessToken, 'mock_access_token_123');
    expect(model.user.id, 'USR1001');
    expect(model.user.name, 'Aditi Verma');
    expect(model.user.email, 'demo@jstack.co');
  });

  test('UserModel.fromJson parses profile.json and maps to the User entity', () {
    final user = UserModel.fromJson(dataObject(fixture('profile.json'))).toEntity();

    expect(user, const User(id: 'USR1001', name: 'Aditi Verma', email: 'demo@jstack.co'));
  });

  test('login and profile describe the same user', () {
    final fromLogin = LoginResponseModel.fromJson(dataObject(fixture('login_success.json'))).user.toEntity();
    final fromProfile = UserModel.fromJson(dataObject(fixture('profile.json'))).toEntity();

    expect(fromLogin, fromProfile);
  });

  test('parsing login_401.json as an error yields UnauthorizedFailure', () {
    expect(mapErrorResponse(401, fixture('login_401.json')), const UnauthorizedFailure());
  });

  test('an error body is not a success envelope', () {
    expect(() => dataObject(fixture('login_401.json')), throwsFormatException);
  });

  test('a body missing a field fails to parse instead of yielding nulls', () {
    final broken = {...dataObject(fixture('login_success.json'))}..remove('accessToken');

    expect(() => LoginResponseModel.fromJson(broken), throwsA(isA<TypeError>()));
  });
}
