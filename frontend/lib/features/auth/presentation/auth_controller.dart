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
    final tokenStore = ref.read(secureTokenStoreProvider);
    final token = await tokenStore.readAccessToken();
    final refreshToken = await tokenStore.readRefreshToken();
    if (token == null && refreshToken == null) {
      return const AuthState.unauthenticated();
    }

    try {
      if (refreshToken != null) {
        final tokens = await ref
            .read(authRepositoryProvider)
            .refreshSession(refreshToken: refreshToken);
        await tokenStore.writeTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
      }
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
      await tokenStore.clear();
      await ref.read(customerQrRepositoryProvider).clearCachedToken();
      ref.read(sessionExpiredMessageProvider.notifier).setExpired();
      return const AuthState.unauthenticated();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading<AuthState>();
    state = await AsyncValue.guard(() async {
      return _authenticate(email: email, password: password);
    });
  }

  Future<void> startCustomerRegistration({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AsyncLoading<AuthState>();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.startCustomerRegistration(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      return const AuthState.unauthenticated();
    });
  }

  Future<void> verifyCustomerRegistration({
    required String email,
    required String code,
  }) async {
    state = const AsyncLoading<AuthState>();
    state = await AsyncValue.guard(() async {
      final tokens = await ref
          .read(authRepositoryProvider)
          .verifyCustomerRegistration(email: email, code: code);
      return _authenticateWithTokens(tokens);
    });
  }

  Future<void> startOwnerRegistration({
    required String businessName,
    required String? businessCategory,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading<AuthState>();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.startOwnerRegistration(
        businessName: businessName,
        businessCategory: businessCategory,
        email: email,
        password: password,
      );
      return const AuthState.unauthenticated();
    });
  }

  Future<void> verifyOwnerRegistration({
    required String email,
    required String code,
  }) async {
    state = const AsyncLoading<AuthState>();
    state = await AsyncValue.guard(() async {
      final tokens = await ref
          .read(authRepositoryProvider)
          .verifyOwnerRegistration(email: email, code: code);
      return _authenticateWithTokens(tokens);
    });
  }

  Future<void> signOut() async {
    ref.read(sessionExpiredMessageProvider.notifier).clear();
    final tokenStore = ref.read(secureTokenStoreProvider);
    final refreshToken = await tokenStore.readRefreshToken();
    if (refreshToken != null) {
      await ref.read(authRepositoryProvider).logout(refreshToken: refreshToken);
    }
    await tokenStore.clear();
    await ref.read(customerQrRepositoryProvider).clearCachedToken();
    state = const AsyncData(AuthState.unauthenticated());
  }

  Future<void> expireSession() async {
    await ref.read(secureTokenStoreProvider).clear();
    await ref.read(customerQrRepositoryProvider).clearCachedToken();
    state = const AsyncData(AuthState.unauthenticated());
  }

  Future<void> updateCustomerProfile({required String fullName}) async {
    final value = state.asData?.value;
    final user = value?.user;
    if (value == null || user == null || !user.isCustomer) {
      return;
    }

    final updatedUser = await ref
        .read(authRepositoryProvider)
        .updateCustomerProfile(fullName: fullName);
    state = AsyncData(value.copyWith(user: updatedUser));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
    await ref.read(secureTokenStoreProvider).clear();
    await ref.read(customerQrRepositoryProvider).clearCachedToken();
    state = const AsyncData(AuthState.unauthenticated());
  }

  Future<void> startEmailChange({
    required String newEmail,
    required String currentPassword,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .startEmailChange(newEmail: newEmail, currentPassword: currentPassword);
  }

  Future<void> verifyEmailChange({
    required String newEmail,
    required String code,
  }) async {
    final value = state.asData?.value;
    if (value == null || value.user == null) {
      return;
    }
    final updatedUser = await ref
        .read(authRepositoryProvider)
        .verifyEmailChange(newEmail: newEmail, code: code);
    state = AsyncData(value.copyWith(user: updatedUser));
  }

  Future<void> removeAccount({required String currentPassword}) async {
    await ref
        .read(authRepositoryProvider)
        .removeAccount(currentPassword: currentPassword);
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
    final tokens = await repository.login(email: email, password: password);
    return _authenticateWithTokens(tokens);
  }

  Future<AuthState> _authenticateWithTokens(AuthTokens tokens) async {
    final repository = ref.read(authRepositoryProvider);
    ref.read(sessionExpiredMessageProvider.notifier).clear();
    await ref
        .read(secureTokenStoreProvider)
        .writeTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
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
