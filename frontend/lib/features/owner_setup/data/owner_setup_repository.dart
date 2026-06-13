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
    required String name,
    required int thresholdPoints,
    required List<String> missionIds,
  }) async {
    final now = DateTime.now().toUtc();
    try {
      await _dio.post<Map<String, dynamic>>(
        '/owner/campaigns',
        data: {
          'creator_business_id': businessId,
          'name': name,
          'threshold_points': thresholdPoints,
          'starts_at': now.subtract(const Duration(days: 1)).toIso8601String(),
          'ends_at': now.add(const Duration(days: 30)).toIso8601String(),
          'mission_ids': missionIds,
        },
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> createGiftRewardTemplate({
    required String businessId,
    required String campaignId,
    required String name,
    required String giftName,
    required int validDays,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/owner/reward-templates',
        data: {
          'business_id': businessId,
          'campaign_id': campaignId,
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

  String _messageFor(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['detail'] is String) {
      return data['detail'] as String;
    }
    return 'Something went wrong. Please try again.';
  }
}
