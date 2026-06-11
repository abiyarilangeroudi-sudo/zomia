import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import '../domain/staff_service_models.dart';

final staffServiceRepositoryProvider = Provider<StaffServiceRepository>((ref) {
  return StaffServiceRepository(ref.watch(dioProvider));
});

class StaffServiceRepository {
  const StaffServiceRepository(this._dio);

  final Dio _dio;

  Future<List<StaffServiceMission>> listMissions({
    required String businessId,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/staff/service/missions',
        queryParameters: {'business_id': businessId},
      );
      return (response.data ?? [])
          .map(
            (item) =>
                StaffServiceMission.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<StaffServiceSummary> resolveQr({
    required String businessId,
    required String token,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/staff/qr/resolve',
        data: {'business_id': businessId, 'token': token},
      );
      return StaffServiceSummary.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<RegisterActionResult> registerAction({
    required String businessId,
    required String qrToken,
    required String idempotencyKey,
    required List<StaffServiceActionItem> items,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/staff/service/actions',
        data: {
          'business_id': businessId,
          'qr_token': qrToken,
          'idempotency_key': idempotencyKey,
          'items': items.map((item) => item.toJson()).toList(),
        },
      );
      return RegisterActionResult.fromJson(
        response.data ?? <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<UseRewardResult> useReward({
    required String businessId,
    required String qrToken,
    required String rewardId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/staff/service/rewards/$rewardId/use',
        data: {
          'business_id': businessId,
          'qr_token': qrToken,
          'idempotency_key': idempotencyKey,
        },
      );
      return UseRewardResult.fromJson(response.data ?? <String, dynamic>{});
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

class StaffServiceActionItem {
  const StaffServiceActionItem({
    required this.missionId,
    required this.quantity,
  });

  final String missionId;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {'mission_id': missionId, 'quantity': quantity};
  }
}
