import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zomia_frontend/app/router.dart';
import 'package:zomia_frontend/app/ui/app_text_field.dart';
import 'package:zomia_frontend/app/zomia_app.dart';
import 'package:zomia_frontend/core/storage/secure_token_store.dart';
import 'package:zomia_frontend/features/auth/data/auth_repository.dart';
import 'package:zomia_frontend/features/auth/domain/current_user.dart';
import 'package:zomia_frontend/features/customer_qr/data/customer_qr_repository.dart';
import 'package:zomia_frontend/features/customer_qr/domain/customer_status.dart';
import 'package:zomia_frontend/features/customer_qr/domain/customer_qr_token.dart';
import 'package:zomia_frontend/features/owner_setup/data/owner_setup_repository.dart';
import 'package:zomia_frontend/features/owner_setup/domain/owner_setup_models.dart';
import 'package:zomia_frontend/features/staff_service/data/staff_service_repository.dart';
import 'package:zomia_frontend/features/staff_service/domain/qr_token_input.dart';
import 'package:zomia_frontend/features/staff_service/domain/staff_service_models.dart';
import 'package:zomia_frontend/features/staff_context/domain/staff_context.dart';

void main() {
  setUp(() {
    appRouter.go('/');
  });

  Future<void> pumpAppFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
  }

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
    expect(find.text('Version 1.0.29 (30)'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('opens the temporary UI component catalog from version label', (
    tester,
  ) async {
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
    await pumpAppFrames(tester);

    await tester.tap(find.text('Version 1.0.29 (30)'));
    await pumpAppFrames(tester);

    expect(find.text('UI Component Catalog'), findsOneWidget);
    expect(find.text('Zomia Design System'), findsOneWidget);
    expect(find.text('AppCard / normal'), findsOneWidget);
    expect(find.text('ProgressCard / active'), findsOneWidget);
  });

  testWidgets('registers a customer and opens customer dashboard', (
    tester,
  ) async {
    final tokenStore = _MemoryTokenStore();
    final authRepository = _FakeAuthRepository(role: 'customer');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(authRepository),
          customerQrRepositoryProvider.overrideWithValue(
            _FakeCustomerQrRepository(),
          ),
        ],
        child: const ZomiaApp(),
      ),
    );
    await pumpAppFrames(tester);

    await tester.tap(find.text('New here? Create an account'));
    await pumpAppFrames(tester);

    expect(find.text('Get Started'), findsOneWidget);

    await _enterTextByLabel(tester, 'Name', 'Customer One');
    await _enterTextByLabel(tester, 'Email', 'customer@example.com');
    await _enterTextByLabel(tester, 'Password', 'strong-password');
    await _enterTextByLabel(tester, 'Confirm Password', 'strong-password');
    await tester.tap(find.text('Term Accept'));
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.pumpAndSettle();
    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    expect(createButton.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await pumpAppFrames(tester);
    await tester.pumpAndSettle();

    expect(authRepository.registeredCustomer, isTrue);
    expect(await tokenStore.readAccessToken(), 'access-token');
    expect(find.text('Customer Dashboard'), findsOneWidget);
    expect(find.text('Welcome, Customer One'), findsOneWidget);
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
    await pumpAppFrames(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'staff@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await pumpAppFrames(tester);

    expect(await tokenStore.readAccessToken(), 'access-token');
    expect(find.text('Staff Dashboard'), findsOneWidget);
    expect(find.text('Zomia Cafe'), findsWidgets);
    expect(find.text('Signed in as Staff One'), findsOneWidget);
    expect(find.byTooltip('Scan customer QR'), findsOneWidget);
    expect(find.text('Customer QR'), findsNothing);
    expect(find.text('Scan with Camera'), findsNothing);
    expect(find.text('No customer loaded'), findsOneWidget);
    expect(find.text('Buy Coffee'), findsOneWidget);

    await tester.tap(find.text('Recent Actions'));
    await pumpAppFrames(tester);

    expect(find.text('Recent Actions'), findsWidgets);
    expect(find.text('No recent actions'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await pumpAppFrames(tester);

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Staff One'), findsOneWidget);
    expect(find.text('staff@example.com'), findsOneWidget);
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
    await pumpAppFrames(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'customer@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await pumpAppFrames(tester);

    expect(await tokenStore.readAccessToken(), 'access-token');
    expect(find.text('Customer Dashboard'), findsOneWidget);
    expect(find.byTooltip('Show QR code'), findsOneWidget);
    expect(find.text('Welcome, Customer One'), findsOneWidget);
    expect(find.text('1 campaigns'), findsOneWidget);
    expect(find.text('1 active rewards'), findsOneWidget);

    await tester.tap(find.text('Campaign'));
    await pumpAppFrames(tester);

    expect(find.text('Campaign Progress'), findsOneWidget);
    expect(find.text('Coffee Reward'), findsWidgets);
    expect(find.text('2/10 pts · 8 pts to reward'), findsOneWidget);

    await tester.tap(find.text('Reward'));
    await pumpAppFrames(tester);

    expect(find.text('Active Rewards'), findsOneWidget);
    expect(find.text('Free Coffee'), findsWidgets);
    expect(find.text('Zomia Cafe · Free coffee'), findsOneWidget);

    await tester.tap(find.byTooltip('Show QR code'));
    await pumpAppFrames(tester);

    expect(find.text('Ready to Scan'), findsOneWidget);
    expect(find.text('Refresh QR token'), findsOneWidget);
    expect(find.text('qr-token'), findsOneWidget);
  });

  testWidgets('signs in and renders owner setup screen', (tester) async {
    final tokenStore = _MemoryTokenStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(role: 'owner'),
          ),
          ownerSetupRepositoryProvider.overrideWithValue(
            _FakeOwnerSetupRepository(),
          ),
        ],
        child: const ZomiaApp(),
      ),
    );
    await pumpAppFrames(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'owner@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await pumpAppFrames(tester);

    expect(await tokenStore.readAccessToken(), 'access-token');
    expect(find.text('Owner Dashboard'), findsOneWidget);
    expect(find.text('Owner Setup'), findsOneWidget);
    expect(find.text('Signed in as Owner One'), findsOneWidget);
    expect(find.text('Zomia Cafe'), findsWidgets);
    expect(find.byTooltip('Staff recent actions'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await pumpAppFrames(tester);

    expect(find.text('Create Mission'), findsOneWidget);
    expect(find.text('Buy Coffee'), findsWidgets);

    await tester.tap(find.text('Campaigns'));
    await pumpAppFrames(tester);

    expect(find.text('Create Campaign'), findsOneWidget);
    expect(find.text('Coffee Reward'), findsWidgets);
    expect(find.text('10 pts · active'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await pumpAppFrames(tester);

    expect(find.text('Create Gift Reward'), findsOneWidget);
    expect(find.text('Free Coffee'), findsWidgets);
    expect(find.text('Free coffee · 30 days'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await pumpAppFrames(tester);

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.text('Create Staff'), findsOneWidget);
    expect(find.text('Setup Staff'), findsOneWidget);
    expect(find.text('setup-staff@example.com'), findsOneWidget);

    await tester.tap(find.byTooltip('Staff recent actions'));
    await pumpAppFrames(tester);

    expect(find.text('Staff Recent Actions'), findsOneWidget);
    expect(find.text('No staff actions yet'), findsOneWidget);
  });
}

Future<void> _enterTextByLabel(
  WidgetTester tester,
  String label,
  String value,
) async {
  final finder = find.byWidgetPredicate(
    (widget) => widget is AppTextField && widget.label == label,
  );
  final field = find
      .descendant(of: finder, matching: find.byType(TextFormField))
      .last;
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
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

  @override
  Future<CustomerStatus> getStatus() async {
    return CustomerStatus(
      customerId: 'customer-id',
      activeRewardsCount: 1,
      businesses: [
        CustomerBusinessStatus(
          businessId: 'business-id',
          businessName: 'Zomia Cafe',
          rewards: [
            CustomerReward(
              id: 'reward-id',
              title: 'Free Coffee',
              description: null,
              rewardType: 'gift',
              status: 'active',
              giftName: 'Free coffee',
              discountPercent: null,
              discountAmountMinor: null,
              currencyCode: null,
              expiresAt: DateTime(2027),
              usedAt: null,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<List<CustomerCampaignProgress>> getCampaignProgresses() async {
    return const [
      CustomerCampaignProgress(
        businessId: 'business-id',
        businessName: 'Zomia Cafe',
        campaignId: 'campaign-id',
        campaignName: 'Coffee Reward',
        progressPoints: 2,
        thresholdPoints: 10,
        remainingPoints: 8,
        isCompleted: false,
      ),
    ];
  }
}

class _FakeOwnerSetupRepository extends OwnerSetupRepository {
  _FakeOwnerSetupRepository() : super(Dio());

  @override
  Future<List<OwnerBusiness>> listBusinesses() async {
    return const [
      OwnerBusiness(
        id: 'business-id',
        name: 'Zomia Cafe',
        slug: 'zomia-cafe',
        status: 'active',
        currencyCode: 'EUR',
      ),
    ];
  }

  @override
  Future<List<OwnerMission>> listMissions(String businessId) async {
    return const [
      OwnerMission(
        id: 'mission-coffee',
        name: 'Buy Coffee',
        missionType: 'purchase',
        pointValue: 1,
        isActive: true,
      ),
    ];
  }

  @override
  Future<List<OwnerStaffMember>> listStaff() async {
    return const [
      OwnerStaffMember(
        id: 'staff-member-id',
        businessId: 'business-id',
        userId: 'staff-user-id',
        isActive: true,
        user: OwnerStaffUser(
          id: 'staff-user-id',
          email: 'setup-staff@example.com',
          fullName: 'Setup Staff',
          isActive: true,
        ),
      ),
    ];
  }

  @override
  Future<List<OwnerCampaign>> listCampaigns(String businessId) async {
    return [
      OwnerCampaign(
        id: 'campaign-id',
        name: 'Coffee Reward',
        thresholdPoints: 10,
        status: 'active',
        startsAt: DateTime(2026),
        endsAt: DateTime(2027),
      ),
    ];
  }

  @override
  Future<List<OwnerRewardTemplate>> listRewardTemplates(
    String businessId,
  ) async {
    return const [
      OwnerRewardTemplate(
        id: 'template-id',
        name: 'Free Coffee',
        rewardType: 'gift',
        giftName: 'Free coffee',
        validDays: 30,
        isActive: true,
      ),
    ];
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.role = 'staff'}) : super(Dio());

  final String role;
  bool registeredCustomer = false;

  @override
  Future<void> registerCustomer({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    registeredCustomer = true;
  }

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
      fullName: switch (role) {
        'owner' => 'Owner One',
        'staff' => 'Staff One',
        _ => 'Customer One',
      },
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
