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

  Future<List<StaffRecentAction>> listRecentActions({
    required String businessId,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/staff/service/recent-actions',
        queryParameters: {'business_id': businessId},
      );
      return (response.data ?? [])
          .map(
            (item) => StaffRecentAction.fromJson(item as Map<String, dynamic>),
          )
          .toList();
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
      throw AppException(
        _messageFor(error),
        isAmbiguousRetry: _isAmbiguousWriteFailure(error),
      );
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
      throw AppException(
        _messageFor(error),
        isAmbiguousRetry: _isAmbiguousWriteFailure(error),
      );
    }
  }

  String _messageFor(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['detail'] is String) {
      return mapStaffServiceErrorDetail(data['detail'] as String);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The server took too long to respond.';
    }
    return 'Something went wrong. Please try again.';
  }

  bool _isAmbiguousWriteFailure(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError;
  }
}

String mapStaffServiceErrorDetail(String detail) {
  return switch (detail) {
    'QR token not found' =>
      'QR code not found. Please scan the customer QR again.',
    'QR token is not active' => 'Scan the current QR.',
    'QR token is expired' =>
      'This QR code has expired. Ask the customer to refresh it.',
    'Staff does not belong to this business' =>
      'You do not have access to this business.',
    'Customer not found' => 'Customer not found. Please scan again.',
    'One or more missions are not available for staff action' =>
      'This mission is no longer available. Refresh the service screen.',
    'Concurrent loyalty update. Please retry' =>
      'Another loyalty update happened. Please try again.',
    'Reward not found' => 'Reward not found. Refresh the customer session.',
    'Reward does not belong to resolved customer' =>
      'This reward does not belong to the scanned customer.',
    'Reward is expired' => 'This reward has expired.',
    'Reward is already used' => 'This reward was already used.',
    'Reward is not active' => 'This reward is no longer active.',
    _ => 'Service action could not be completed. Please try again.',
  };
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
