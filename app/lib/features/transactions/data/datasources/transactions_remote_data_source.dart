import 'package:dio/dio.dart';

import '../../../../core/network/envelope.dart';
import '../models/transaction_model.dart';

/// The transactions endpoints. Throws whatever Dio throws.
class TransactionsRemoteDataSource {
  const TransactionsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<TransactionModel>> list() async {
    final response = await _dio.get<Object?>('/transactions');
    return [
      for (final item in dataList(response.data)) TransactionModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// The id goes into the path escaped, so an odd id can't change the route.
  Future<TransactionModel> details(String id) async {
    final response = await _dio.get<Object?>('/transactions/${Uri.encodeComponent(id)}');
    return TransactionModel.fromJson(dataObject(response.data));
  }
}
