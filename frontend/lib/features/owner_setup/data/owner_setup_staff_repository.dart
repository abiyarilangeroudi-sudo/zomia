part of 'owner_setup_repository.dart';

mixin _OwnerSetupStaffRepository on _OwnerSetupRepositoryBase {
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

  Future<void> sendStaffInvitation({
    required String businessId,
    required String email,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/owner/staff/invitations',
        data: {'business_id': businessId, 'email': email},
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

  Future<void> cancelStaffInvitation({required String invitationId}) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/owner/staff/invitations/$invitationId',
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }
}
