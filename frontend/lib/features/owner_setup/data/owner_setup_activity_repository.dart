part of 'owner_setup_repository.dart';

mixin _OwnerSetupActivityRepository on _OwnerSetupRepositoryBase {
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
}
