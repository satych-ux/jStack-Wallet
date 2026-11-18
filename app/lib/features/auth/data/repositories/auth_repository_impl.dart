import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/session_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._session);

  final AuthRemoteDataSource _remote;
  final SessionLocalDataSource _session;

  @override
  Future<Result<User>> login({required String email, required String password}) async {
    try {
      final response = await _remote.login(email: email, password: password);
      await _session.save(response.accessToken);
      return Ok(response.user.toEntity());
    } on DioException catch (e) {
      // Nothing was stored: the token is saved only after a 200.
      return Err(mapDioException(e));
    } on Object catch (_) {
      // A 200 whose body isn't the expected shape.
      return const Err(ServerFailure());
    }
  }

  @override
  Future<Result<User?>> restoreSession() async {
    final token = await _session.read();
    if (token == null || token.isEmpty) return const Ok(null);
    try {
      final profile = await _remote.profile();
      return Ok(profile.toEntity());
    } on DioException catch (e) {
      final failure = mapDioException(e);
      // The interceptor clears it too; clearing here keeps this method's
      // promise without relying on that.
      if (failure is UnauthorizedFailure) await _session.clear();
      return Err(failure);
    } on Object catch (_) {
      return const Err(ServerFailure());
    }
  }

  @override
  Future<void> logout() => _session.clear();
}
