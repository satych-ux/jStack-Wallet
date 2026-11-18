import 'package:dio/dio.dart';

import '../../../../core/network/envelope.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

/// The auth endpoints. Throws whatever Dio throws; the repository maps it.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<LoginResponseModel> login({required String email, required String password}) async {
    final response = await _dio.post<Object?>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return LoginResponseModel.fromJson(dataObject(response.data));
  }

  Future<UserModel> profile() async {
    final response = await _dio.get<Object?>('/users/profile');
    return UserModel.fromJson(dataObject(response.data));
  }
}
