import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client.dart';
import '../../../core/storage/secure_token_store.dart';
import '../../customer_qr/data/customer_qr_repository.dart';
import '../../staff_context/domain/staff_context.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token = await ref.read(secureTokenStoreProvider).readAccessToken();
    if (token == null) {
      return const AuthState.unauthenticated();
    }

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.getCurrentUser();
      if (!user.isStaff) {
        return AuthState.authenticated(user: user);
      }
      final context = await repository.getStaffContext();
      return AuthState.authenticated(
        user: user,
        context: context,
        selectedBusiness: _defaultBusiness(context),
      );
    } catch (_) {
      await ref.read(secureTokenStoreProvider).clear();
      return const AuthState.unauthenticated();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading<AuthState>();
    state = await AsyncValue.guard(() async {
      return _authenticate(email: email, password: password);
    });
  }

  Future<void> registerCustomer({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AsyncLoading<AuthState>();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.registerCustomer(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      return _authenticate(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    ref.read(sessionExpiredMessageProvider.notifier).clear();
    await ref.read(secureTokenStoreProvider).clear();
    await ref.read(customerQrRepositoryProvider).clearCachedToken();
    state = const AsyncData(AuthState.unauthenticated());
  }

  Future<void> expireSession() async {
    await ref.read(secureTokenStoreProvider).clear();
    await ref.read(customerQrRepositoryProvider).clearCachedToken();
    state = const AsyncData(AuthState.unauthenticated());
  }

  void selectBusiness(StaffBusiness business) {
    final value = state.asData?.value;
    if (value == null || !value.isAuthenticated) {
      return;
    }
    state = AsyncData(value.copyWith(selectedBusiness: business));
  }

  StaffBusiness? _defaultBusiness(StaffContext context) {
    if (context.businesses.length == 1) {
      return context.businesses.first;
    }
    return null;
  }

  Future<AuthState> _authenticate({
    required String email,
    required String password,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    final token = await repository.login(email: email, password: password);
    ref.read(sessionExpiredMessageProvider.notifier).clear();
    await ref.read(secureTokenStoreProvider).writeAccessToken(token);
    final user = await repository.getCurrentUser();
    if (!user.isStaff) {
      return AuthState.authenticated(user: user);
    }
    final context = await repository.getStaffContext();
    return AuthState.authenticated(
      user: user,
      context: context,
      selectedBusiness: _defaultBusiness(context),
    );
  }
}
