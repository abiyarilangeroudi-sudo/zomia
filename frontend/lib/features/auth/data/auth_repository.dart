import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import '../domain/current_user.dart';
import '../../staff_context/domain/staff_context.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthTokens.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<AuthTokens> refreshSession({required String refreshToken}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return AuthTokens.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> logout({required String refreshToken}) async {
    try {
      await _dio.post<void>(
        '/auth/logout',
        data: {'refresh_token': refreshToken},
      );
    } on DioException {
      // Local sign-out must still complete if the server session is already gone.
    }
  }

  Future<void> startCustomerRegistration({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/register/customer/start',
        data: {
          'full_name': fullName,
          'email': email,
          'password': password,
          'phone': phone?.isEmpty ?? true ? null : phone,
        },
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<AuthTokens> verifyCustomerRegistration({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register/customer/verify',
        data: {'email': email, 'code': code},
      );
      return AuthTokens.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<void> startOwnerRegistration({
    required String businessName,
    required String? businessCategory,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/register/owner/start',
        data: {
          'full_name': businessName,
          'email': email,
          'password': password,
          'business_name': businessName,
          'business_category': businessCategory?.isEmpty ?? true
              ? null
              : businessCategory,
        },
      );
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<AuthTokens> verifyOwnerRegistration({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register/owner/verify',
        data: {'email': email, 'code': code},
      );
      return AuthTokens.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<StaffContext> getStaffContext() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/staff/me/context',
      );
      return StaffContext.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<CurrentUser> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return CurrentUser.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  Future<CurrentUser> updateCustomerProfile({required String fullName}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/customers/me/profile',
        data: {'full_name': fullName},
      );
      return CurrentUser.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  String _messageFor(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['detail'] is String) {
      return mapAuthErrorDetail(data['detail'] as String);
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

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
}

String mapAuthErrorDetail(String detail) {
  return switch (detail) {
    'Incorrect email or password' => 'Incorrect email or password.',
    'Email already exists' => 'This email is already registered.',
    'Email is not verified' => 'Verify your email before signing in.',
    'Invalid OTP' => 'Enter the correct verification code.',
    'OTP expired' => 'The verification code expired.',
    'OTP not found' => 'Request a new verification code.',
    'Insufficient role' => 'You do not have access to this area.',
    _ => 'Something went wrong. Please try again.',
  };
}
