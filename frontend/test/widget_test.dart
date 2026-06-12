import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zomia_frontend/app/zomia_app.dart';
import 'package:zomia_frontend/core/storage/secure_token_store.dart';
import 'package:zomia_frontend/features/auth/data/auth_repository.dart';
import 'package:zomia_frontend/features/auth/domain/current_user.dart';
import 'package:zomia_frontend/features/customer_qr/data/customer_qr_repository.dart';
import 'package:zomia_frontend/features/customer_qr/domain/customer_qr_token.dart';
import 'package:zomia_frontend/features/staff_service/data/staff_service_repository.dart';
import 'package:zomia_frontend/features/staff_service/domain/qr_token_input.dart';
import 'package:zomia_frontend/features/staff_service/domain/staff_service_models.dart';
import 'package:zomia_frontend/features/staff_context/domain/staff_context.dart';

void main() {
  test('normalizes raw and deep-link QR token inputs', () {
    expect(normalizeQrTokenInput('raw-token'), 'raw-token');
    expect(normalizeQrTokenInput('zomia://customer/raw-token'), 'raw-token');
    expect(
      normalizeQrTokenInput('  zomia://customer/raw-token  '),
      'raw-token',
    );
  });

  testWidgets('renders the staff login screen when signed out', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
          staffServiceRepositoryProvider.overrideWithValue(
            _FakeStaffServiceRepository(),
          ),
          customerQrRepositoryProvider.overrideWithValue(
            _FakeCustomerQrRepository(),
          ),
        ],
        child: const ZomiaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Version 1.0.3 (4)'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('signs in and renders staff context', (tester) async {
    final tokenStore = _MemoryTokenStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          staffServiceRepositoryProvider.overrideWithValue(
            _FakeStaffServiceRepository(),
          ),
          customerQrRepositoryProvider.overrideWithValue(
            _FakeCustomerQrRepository(),
          ),
        ],
        child: const ZomiaApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'staff@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(await tokenStore.readAccessToken(), 'access-token');
    expect(find.text('Staff Service'), findsOneWidget);
    expect(find.text('Zomia Cafe'), findsOneWidget);
    expect(find.text('Signed in as Staff One'), findsOneWidget);
    expect(find.text('Customer QR'), findsOneWidget);
    expect(find.text('Scan with camera'), findsOneWidget);
    expect(find.text('Buy Coffee'), findsOneWidget);
  });

  testWidgets('signs in and renders customer QR screen', (tester) async {
    final tokenStore = _MemoryTokenStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(role: 'customer'),
          ),
          customerQrRepositoryProvider.overrideWithValue(
            _FakeCustomerQrRepository(),
          ),
        ],
        child: const ZomiaApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'customer@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(await tokenStore.readAccessToken(), 'access-token');
    expect(find.text('Customer QR'), findsOneWidget);
    expect(find.text('Ready to Scan'), findsOneWidget);
    expect(find.text('Refresh QR token'), findsOneWidget);
    expect(find.text('qr-token'), findsOneWidget);
  });
}

class _MemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<void> clear() async {
    _token = null;
  }

  @override
  Future<String?> readAccessToken() async {
    return _token;
  }

  @override
  Future<void> writeAccessToken(String token) async {
    _token = token;
  }
}

class _FakeStaffServiceRepository extends StaffServiceRepository {
  _FakeStaffServiceRepository() : super(Dio());

  @override
  Future<List<StaffServiceMission>> listMissions({
    required String businessId,
  }) async {
    return const [
      StaffServiceMission(
        id: 'mission-coffee',
        name: 'Buy Coffee',
        description: null,
        missionType: 'purchase',
        pointValue: 1,
        isActive: true,
      ),
    ];
  }
}

class _FakeCustomerQrRepository extends CustomerQrRepository {
  _FakeCustomerQrRepository() : super(Dio());

  @override
  Future<CustomerQrToken> issueToken() async {
    return CustomerQrToken(
      token: 'qr-token',
      qrPayload: 'qr-token',
      expiresAt: DateTime(2027),
    );
  }

  @override
  Future<CustomerQrToken> rotateToken() async {
    return issueToken();
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.role = 'staff'}) : super(Dio());

  final String role;

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    return 'access-token';
  }

  @override
  Future<CurrentUser> getCurrentUser() async {
    return CurrentUser(
      id: '$role-id',
      email: '$role@example.com',
      fullName: role == 'staff' ? 'Staff One' : 'Customer One',
      role: role,
      isActive: true,
    );
  }

  @override
  Future<StaffContext> getStaffContext() async {
    return const StaffContext(
      staff: StaffUser(
        id: 'staff-id',
        email: 'staff@example.com',
        fullName: 'Staff One',
        role: 'staff',
        isActive: true,
      ),
      businesses: [
        StaffBusiness(
          id: 'business-id',
          name: 'Zomia Cafe',
          slug: 'zomia-cafe',
          status: 'active',
          timezone: 'Europe/Berlin',
          currencyCode: 'EUR',
          staffMembershipId: 'membership-id',
        ),
      ],
    );
  }
}
