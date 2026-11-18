import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/core/error/failure.dart';
import 'package:j_stack_flutter_app/core/error/failure_mapper.dart';

import '../../helpers/fixtures.dart';

/// A DioException as Dio throws it for a non-2xx answer with this body.
DioException badResponse(int status, Object? body) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<Object?>(requestOptions: options, statusCode: status, data: body),
  );
}

DioException ofType(DioExceptionType type) =>
    DioException(requestOptions: RequestOptions(path: '/x'), type: type);

void main() {
  group('status codes, from captured backend responses', () {
    test('400 maps to ValidationFailure carrying the field names the backend sent', () {
      final failure = mapDioException(badResponse(400, fixture('transfer_400_validation.json')));

      expect(failure, isA<ValidationFailure>());
      final fields = (failure as ValidationFailure).fields;
      expect(fields.keys, containsAll(['beneficiaryName', 'mobileNumber', 'amount', 'remarks']));
      expect(fields['mobileNumber'], 'Mobile number must be exactly 10 digits');
    });

    test('a login 400 carries the email and password fields', () {
      final failure = mapDioException(badResponse(400, fixture('login_400_validation.json')));

      expect((failure as ValidationFailure).fields.keys, unorderedEquals(['email', 'password']));
    });

    test('a 400 without fields (missing Idempotency-Key) is a ValidationFailure with none', () {
      expect(
        mapDioException(badResponse(400, fixture('transfer_400_missing_key.json'))),
        const ValidationFailure(),
      );
    });

    test('401 maps to UnauthorizedFailure: wrong password and missing token alike', () {
      expect(mapDioException(badResponse(401, fixture('login_401.json'))), const UnauthorizedFailure());
      expect(mapDioException(badResponse(401, fixture('profile_401.json'))), const UnauthorizedFailure());
    });

    test('404 maps to NotFoundFailure: unknown transaction and unknown route alike', () {
      expect(mapDioException(badResponse(404, fixture('transaction_404.json'))), const NotFoundFailure());
      expect(mapDioException(badResponse(404, fixture('route_404.json'))), const NotFoundFailure());
    });

    test('409 with INSUFFICIENT_BALANCE maps to InsufficientBalanceFailure', () {
      expect(
        mapDioException(badResponse(409, fixture('transfer_409_insufficient.json'))),
        const InsufficientBalanceFailure(),
      );
    });

    test('409 with IDEMPOTENCY_KEY_REUSED maps to its own failure, not to insufficient balance', () {
      final failure = mapDioException(badResponse(409, fixture('transfer_409_idempotency_reuse.json')));

      expect(failure, const IdempotencyKeyReusedFailure());
      expect(failure, isNot(isA<InsufficientBalanceFailure>()));
    });

    test('409 with an unknown or missing code is a ServerFailure, never a guess', () {
      expect(mapDioException(badResponse(409, null)), const ServerFailure());
      expect(
        mapDioException(badResponse(409, {'success': false, 'error': {'code': 'OTHER', 'message': 'x'}})),
        const ServerFailure(),
      );
    });

    test('500 maps to ServerFailure, whatever the body', () {
      // The backend can't be made to fail on purpose, so this one body is
      // written by hand; it mirrors errorHandler.js.
      for (final body in <Object?>[
        null,
        'Internal Server Error',
        {'success': false, 'error': {'code': 'INTERNAL_ERROR', 'message': 'Something went wrong'}},
      ]) {
        expect(mapDioException(badResponse(500, body)), const ServerFailure(), reason: '$body');
      }
    });

    test('an unexpected status (e.g. 502 from a proxy) maps to ServerFailure', () {
      expect(mapDioException(badResponse(502, 'Bad Gateway')), const ServerFailure());
    });
  });

  group('no answer', () {
    test('connectionTimeout and receiveTimeout map to TimeoutFailure', () {
      expect(mapDioException(ofType(DioExceptionType.connectionTimeout)), const TimeoutFailure());
      expect(mapDioException(ofType(DioExceptionType.receiveTimeout)), const TimeoutFailure());
    });

    test('sendTimeout and transformTimeout map to TimeoutFailure too', () {
      expect(mapDioException(ofType(DioExceptionType.sendTimeout)), const TimeoutFailure());
      expect(mapDioException(ofType(DioExceptionType.transformTimeout)), const TimeoutFailure());
    });

    test('connectionError maps to NetworkFailure', () {
      expect(mapDioException(ofType(DioExceptionType.connectionError)), const NetworkFailure());
    });

    test('cancel, badCertificate and unknown map to NetworkFailure', () {
      for (final type in [DioExceptionType.cancel, DioExceptionType.badCertificate, DioExceptionType.unknown]) {
        expect(mapDioException(ofType(type)), const NetworkFailure(), reason: '$type');
      }
    });

  });
}
