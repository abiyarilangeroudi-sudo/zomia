part of 'owner_setup_repository.dart';

mixin _OwnerSetupSummaryRepository on _OwnerSetupRepositoryBase {
  Future<OwnerLoyaltySummary> getLoyaltySummary(String businessId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/owner/loyalty-summary',
        queryParameters: {'business_id': businessId},
      );
      return OwnerLoyaltySummary.fromJson(response.data!);
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }
}
