import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import '../domain/owner_setup_models.dart';

final ownerSetupRepositoryProvider = Provider<OwnerSetupRepository>((ref) {
  return OwnerSetupRepository(ref.watch(dioProvider));
});

class OwnerSetupRepository {
  const OwnerSetupRepository(this._dio);

  final Dio _dio;

  Future<List<OwnerBusiness>> listBusinesses() async {
    try {
      final response = await _dio.get<List<dynamic>>('/owner/businesses');
      return (response.data ?? [])
          .map((item) => OwnerBusiness.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<List<OwnerMission>> listMissions(String businessId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/owner/missions',
        queryParameters: {'business_id': businessId},
      );
      return (response.data ?? [])
          .map((item) => OwnerMission.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<List<OwnerStaffMember>> listStaff() async {
    try {
      final response = await _dio.get<List<dynamic>>('/owner/staff');
      return (response.data ?? [])
          .map(
            (item) => OwnerStaffMember.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<List<OwnerCampaign>> listCampaigns(String businessId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/owner/campaigns',
        queryParameters: {'business_id': businessId},
      );
      return (response.data ?? [])
          .map((item) => OwnerCampaign.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<List<OwnerRewardTemplate>> listRewardTemplates(
    String businessId,
  ) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/owner/reward-templates',
        queryParameters: {'business_id': businessId},
      );
      return (response.data ?? [])
          .map(
            (item) =>
                OwnerRewardTemplate.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<List<OwnerActivity>> listRecentActivity({
    required String businessId,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/owner/activity/recent',
        queryParameters: {'business_id': businessId, 'limit': limit},
      );
      return (response.data ?? [])
          .map((item) => OwnerActivity.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<OwnerBusiness> updateBusiness({
    required String businessId,
    required String name,
    required String? category,
    required String? publicEmail,
    required String? publicPhone,
    required String? websiteUrl,
    required String? addressLine1,
    required String? addressLine2,
    required String? city,
    required String? region,
    required String? postalCode,
    required String countryCode,
    required String timezone,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/owner/businesses/$businessId',
        data: {
          'name': name,
          'category': _blankToNull(category),
          'public_email': _blankToNull(publicEmail),
          'public_phone': _blankToNull(publicPhone),
          'website_url': _blankToNull(websiteUrl),
          'address_line1': _blankToNull(addressLine1),
          'address_line2': _blankToNull(addressLine2),
          'city': _blankToNull(city),
          'region': _blankToNull(region),
          'postal_code': _blankToNull(postalCode),
          'country_code': countryCode,
          'timezone': timezone,
        },
      );
      return OwnerBusiness.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> createMission({
    required String businessId,
    required String name,
    required String missionType,
    required int pointValue,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/owner/missions',
        data: {
          'business_id': businessId,
          'name': name,
          'mission_type': missionType,
          'point_value': pointValue,
        },
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> createStaff({
    required String businessId,
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/owner/staff',
        data: {
          'business_id': businessId,
          'email': email,
          'password': password,
          'full_name': fullName,
        },
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> setStaffActive({
    required String staffMemberId,
    required bool isActive,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/owner/staff/$staffMemberId',
        data: {'is_active': isActive},
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> createCampaign({
    required String businessId,
    required String rewardTemplateId,
    required String name,
    required int thresholdPoints,
    required DateTime startsAt,
    required DateTime endsAt,
    required List<String> missionIds,
    required bool isRepeatable,
    int? maxCompletionsPerCustomer,
  }) async {
    final payload = <String, dynamic>{
      'creator_business_id': businessId,
      'reward_template_id': rewardTemplateId,
      'name': name,
      'threshold_points': thresholdPoints,
      'is_repeatable': isRepeatable,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'mission_ids': missionIds,
    };
    if (isRepeatable) {
      payload['max_completions_per_customer'] = maxCompletionsPerCustomer;
    }
    try {
      await _dio.post<Map<String, dynamic>>('/owner/campaigns', data: payload);
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> createGiftRewardTemplate({
    required String businessId,
    required String name,
    required String giftName,
    required int validDays,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/owner/reward-templates',
        data: {
          'business_id': businessId,
          'name': name,
          'reward_type': 'gift',
          'gift_name': giftName,
          'valid_days': validDays,
        },
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _messageFor(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['detail'] is String) {
      return mapOwnerSetupErrorDetail(data['detail'] as String);
    }
    if (data is Map<String, dynamic> && data['detail'] is List<dynamic>) {
      return 'Please check the form and try again.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The server took too long to respond.';
    }
    return 'Something went wrong. Please try again.';
  }
}

String mapOwnerSetupErrorDetail(String detail) {
  return switch (detail) {
    'Business not found' => 'Business not found or you do not have access.',
    'Campaign not found' => 'Campaign not found for this business.',
    'One or more missions were not found' =>
      'One or more selected missions are no longer available.',
    'Email already exists' => 'This email is already registered.',
    'Insufficient role' => 'You do not have access to this area.',
    _ => 'Setup action could not be completed. Please try again.',
  };
}
