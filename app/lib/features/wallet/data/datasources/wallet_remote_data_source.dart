import 'package:dio/dio.dart';

import '../../../../core/network/envelope.dart';
import '../models/profile_model.dart';
import '../models/wallet_model.dart';

/// The dashboard's own endpoints. Throws whatever Dio throws.
class WalletRemoteDataSource {
  const WalletRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ProfileModel> profile() async {
    final response = await _dio.get<Object?>('/users/profile');
    return ProfileModel.fromJson(dataObject(response.data));
  }

  Future<WalletModel> balance() async {
    final response = await _dio.get<Object?>('/wallet/balance');
    return WalletModel.fromJson(dataObject(response.data));
  }
}
