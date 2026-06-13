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
        if (_shouldExpireSession(error)) {
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
