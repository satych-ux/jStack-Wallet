import 'package:dio/dio.dart';

import '../../../../core/network/envelope.dart';
import '../../domain/entities/transfer_request.dart';
import '../models/transfer_request_model.dart';
import '../models/transfer_result_model.dart';

/// POST /transactions/transfer. Every call carries the attempt's
/// Idempotency-Key (rule 3). Throws whatever Dio throws.
class TransferRemoteDataSource {
  const TransferRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TransferResultModel> transfer(
    TransferRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _dio.post<Object?>(
      '/transactions/transfer',
      data: TransferRequestModel(request).toJson(),
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return TransferResultModel.fromJson(dataObject(response.data));
  }
}
