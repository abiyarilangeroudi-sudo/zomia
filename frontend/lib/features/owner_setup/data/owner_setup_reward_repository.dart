part of 'owner_setup_repository.dart';

mixin _OwnerSetupRewardRepository on _OwnerSetupRepositoryBase {
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

  Future<void> updateGiftRewardTemplate({
    required String businessId,
    required String rewardTemplateId,
    required String giftName,
    required int validDays,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/owner/reward-templates/$rewardTemplateId',
        queryParameters: {'business_id': businessId},
        data: {
          'name': giftName,
          'gift_name': giftName,
          'valid_days': validDays,
        },
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> deleteRewardTemplate({
    required String businessId,
    required String rewardTemplateId,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/owner/reward-templates/$rewardTemplateId',
        queryParameters: {'business_id': businessId},
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> archiveRewardTemplate({
    required String businessId,
    required String rewardTemplateId,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/owner/reward-templates/$rewardTemplateId/active',
        queryParameters: {'business_id': businessId},
        data: {'is_active': false},
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }
}
