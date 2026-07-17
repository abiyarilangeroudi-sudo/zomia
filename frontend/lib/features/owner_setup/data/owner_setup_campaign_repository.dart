part of 'owner_setup_repository.dart';

mixin _OwnerSetupCampaignRepository on _OwnerSetupRepositoryBase {
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

  Future<void> updateCampaignStatus({
    required String businessId,
    required String campaignId,
    required String status,
    int? expectedSettlementCustomerCount,
  }) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (expectedSettlementCustomerCount != null) {
        data['expected_settlement_customer_count'] =
            expectedSettlementCustomerCount;
      }
      await _dio.patch<Map<String, dynamic>>(
        '/owner/campaigns/$campaignId/status',
        queryParameters: {'business_id': businessId},
        data: data,
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<OwnerCampaignEndPreview> previewCampaignEnd({
    required String businessId,
    required String campaignId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/owner/campaigns/$campaignId/end-preview',
        queryParameters: {'business_id': businessId},
      );
      return OwnerCampaignEndPreview.fromJson(response.data!);
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }
}
