import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import '../domain/customer_status.dart';
import '../domain/customer_qr_token.dart';
import 'customer_qr_token_store.dart';

final customerQrRepositoryProvider = Provider<CustomerQrRepository>((ref) {
  return CustomerQrRepository(
    ref.watch(dioProvider),
    ref.watch(customerQrTokenStoreProvider),
  );
});

class CustomerQrRepository {
  const CustomerQrRepository(this._dio, this._tokenStore);

  final Dio _dio;
  final CustomerQrTokenStore _tokenStore;

  Future<CustomerQrToken?> readCachedToken() {
    return _tokenStore.readToken();
  }

  Future<CustomerQrToken> issueToken() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/customers/me/qr-token',
      );
      final token = CustomerQrToken.fromJson(
        response.data ?? <String, dynamic>{},
      );
      await _tokenStore.writeToken(token);
      return token;
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<CustomerQrToken> rotateToken() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/customers/me/qr-token/rotate',
      );
      final token = CustomerQrToken.fromJson(
        response.data ?? <String, dynamic>{},
      );
      await _tokenStore.writeToken(token);
      return token;
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> clearCachedToken() {
    return _tokenStore.clear();
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

  Future<List<CustomerCampaignProgress>> getCampaignProgresses() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/customers/me/campaigns/progress',
      );
      return (response.data ?? [])
          .map(
            (item) =>
                CustomerCampaignProgress.fromJson(item as Map<String, dynamic>),
          )
          .toList();
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
