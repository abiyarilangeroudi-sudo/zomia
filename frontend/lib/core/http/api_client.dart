import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_token_store.dart';

final sessionExpiredMessageProvider =
    NotifierProvider<SessionExpiredMessageNotifier, String?>(
      SessionExpiredMessageNotifier.new,
    );

class SessionExpiredMessageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setExpired() {
    state = 'Your session expired. Please sign in again.';
  }

  void clear() {
    state = null;
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStore = ref.watch(secureTokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (_shouldTryRefresh(error)) {
          final refreshToken = await tokenStore.readRefreshToken();
          if (refreshToken != null) {
            try {
              final response =
                  await Dio(
                    BaseOptions(
                      baseUrl: config.apiBaseUrl,
                      connectTimeout: const Duration(seconds: 10),
                      receiveTimeout: const Duration(seconds: 20),
                      sendTimeout: const Duration(seconds: 20),
                      headers: const {'Accept': 'application/json'},
                    ),
                  ).post<Map<String, dynamic>>(
                    '/auth/refresh',
                    data: {'refresh_token': refreshToken},
                  );
              final data = response.data ?? <String, dynamic>{};
              final accessToken = data['access_token'] as String;
              final newRefreshToken = data['refresh_token'] as String;
              await tokenStore.writeTokens(
                accessToken: accessToken,
                refreshToken: newRefreshToken,
              );
              error.requestOptions.headers['Authorization'] =
                  'Bearer $accessToken';
              error.requestOptions.extra['zomia_refresh_retried'] = true;
              return handler.resolve(await dio.fetch(error.requestOptions));
            } on DioException {
              await tokenStore.clear();
              ref.read(sessionExpiredMessageProvider.notifier).setExpired();
            }
          } else {
            await tokenStore.clear();
            ref.read(sessionExpiredMessageProvider.notifier).setExpired();
          }
        } else if (_shouldExpireSession(error)) {
          await tokenStore.clear();
          ref.read(sessionExpiredMessageProvider.notifier).setExpired();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

bool _shouldExpireSession(DioException error) {
  if (error.response?.statusCode != 401) {
    return false;
  }
  final path = error.requestOptions.path;
  return path != '/auth/login' && !path.startsWith('/auth/register');
}

bool _shouldTryRefresh(DioException error) {
  if (!_shouldExpireSession(error)) {
    return false;
  }
  final path = error.requestOptions.path;
  if (path == '/auth/refresh' || path == '/auth/logout') {
    return false;
  }
  return error.requestOptions.extra['zomia_refresh_retried'] != true;
}
