import 'package:dio/dio.dart';

import 'failure.dart';
import 'failure_mapper.dart';
import 'result.dart';

/// Runs one request and turns the outcome into a [Result]: what Dio throws
/// becomes its [Failure]; a 200 whose body isn't the expected shape (the
/// envelope or a model refused it) becomes a [ServerFailure]. Anything else
/// is a bug and is not swallowed.
Future<Result<T>> guard<T>(Future<T> Function() request) async {
  try {
    return Ok(await request());
  } on DioException catch (e) {
    return Err(mapDioException(e));
  } on FormatException {
    return const Err(ServerFailure());
  } on TypeError {
    return const Err(ServerFailure());
  }
}
