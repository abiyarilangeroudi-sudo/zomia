part of 'owner_setup_repository.dart';

mixin _OwnerSetupBusinessRepository on _OwnerSetupRepositoryBase {
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
}
