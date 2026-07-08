part of 'owner_setup_repository.dart';

mixin _OwnerSetupMissionRepository on _OwnerSetupRepositoryBase {
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

  Future<void> updateMission({
    required String businessId,
    required String missionId,
    required String name,
    required int pointValue,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/owner/missions/$missionId',
        queryParameters: {'business_id': businessId},
        data: {'name': name, 'point_value': pointValue},
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> deleteMission({
    required String businessId,
    required String missionId,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/owner/missions/$missionId',
        queryParameters: {'business_id': businessId},
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> archiveMission({
    required String businessId,
    required String missionId,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/owner/missions/$missionId/active',
        queryParameters: {'business_id': businessId},
        data: {'is_active': false},
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }
}
