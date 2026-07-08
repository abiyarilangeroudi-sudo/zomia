import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import '../domain/owner_setup_models.dart';

part 'owner_setup_activity_repository.dart';
part 'owner_setup_business_repository.dart';
part 'owner_setup_campaign_repository.dart';
part 'owner_setup_mission_repository.dart';
part 'owner_setup_reward_repository.dart';
part 'owner_setup_staff_repository.dart';

final ownerSetupRepositoryProvider = Provider<OwnerSetupRepository>((ref) {
  return OwnerSetupRepository(ref.watch(dioProvider));
});

abstract class _OwnerSetupRepositoryBase {
  const _OwnerSetupRepositoryBase(this._dio);

  final Dio _dio;

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

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

class OwnerSetupRepository extends _OwnerSetupRepositoryBase
    with
        _OwnerSetupActivityRepository,
        _OwnerSetupBusinessRepository,
        _OwnerSetupCampaignRepository,
        _OwnerSetupMissionRepository,
        _OwnerSetupRewardRepository,
        _OwnerSetupStaffRepository {
  const OwnerSetupRepository(super.dio);
}

String mapOwnerSetupErrorDetail(String detail) {
  return switch (detail) {
    'Business not found' => 'Business not found or you do not have access.',
    'Campaign not found' => 'Campaign not found for this business.',
    'Campaign is already ended' => 'This campaign is already ended.',
    'Unsupported campaign status' => 'This campaign status is not supported.',
    'Mission not found' => 'Mission not found for this business.',
    'Mission is already used' =>
      'This mission is already used in a campaign or customer action.',
    'Mission is used by an active campaign' =>
      'End the related campaign before archiving this mission.',
    'Reward template not found' =>
      'Reward template not found or no longer available.',
    'Reward template is already used' =>
      'This reward template is already used in a campaign or generated reward.',
    'Reward template is used by an active campaign' =>
      'End the related campaign before archiving this reward template.',
    'One or more missions were not found' =>
      'One or more selected missions are no longer available.',
    'Email already exists' => 'This email is already registered.',
    'Staff already exists' => 'This staff member already exists.',
    'Staff invitation already pending' =>
      'A staff invitation is already pending for this email.',
    'Staff invitation not found' =>
      'Staff invitation not found or you do not have access.',
    'Staff invitation is not pending' =>
      'This staff invitation can no longer be cancelled.',
    'Insufficient role' => 'You do not have access to this area.',
    _ => 'Setup action could not be completed. Please try again.',
  };
}
