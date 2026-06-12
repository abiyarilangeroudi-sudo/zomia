import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import '../domain/customer_status.dart';
import '../domain/customer_qr_token.dart';

final customerQrRepositoryProvider = Provider<CustomerQrRepository>((ref) {
  return CustomerQrRepository(ref.watch(dioProvider));
});

class CustomerQrRepository {
  const CustomerQrRepository(this._dio);

  final Dio _dio;

  Future<CustomerQrToken> issueToken() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/customers/me/qr-token',
      );
      return CustomerQrToken.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<CustomerQrToken> rotateToken() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/customers/me/qr-token/rotate',
      );
      return CustomerQrToken.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<CustomerStatus> getStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/customers/me/status',
      );
      return CustomerStatus.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  String _messageFor(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['detail'] is String) {
      return data['detail'] as String;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The server took too long to respond.';
    }
    return 'Something went wrong. Please try again.';
  }
}
