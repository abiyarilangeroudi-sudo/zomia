import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zomia_frontend/app/theme.dart';
import 'package:zomia_frontend/core/storage/secure_token_store.dart';
import 'package:zomia_frontend/features/auth/domain/current_user.dart';
import 'package:zomia_frontend/features/auth/presentation/login_screen.dart';
import 'package:zomia_frontend/features/customer_qr/domain/customer_status.dart';
import 'package:zomia_frontend/features/customer_qr/presentation/customer_home_view.dart';
import 'package:zomia_frontend/features/owner_setup/domain/owner_setup_models.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_campaign_widgets.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_onboarding_presenter.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_setup_checklist.dart';
import 'package:zomia_frontend/features/staff_service/domain/staff_service_models.dart';
import 'package:zomia_frontend/features/staff_service/presentation/staff_service_cards.dart';

const _mobileSize = Size(320, 740);

void main() {
  testWidgets('login remains usable on narrow screens with scaled text', (
    tester,
  ) async {
    await _setMobileSurface(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(_EmptyTokenStore()),
        ],
        child: _scaledApp(home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'Sign in')).height,
      greaterThanOrEqualTo(48),
    );
    _expectNoFlutterException(tester);
  });

  testWidgets('customer home handles long content at mobile text scale', (
    tester,
  ) async {
    await _setMobileSurface(tester);

    await tester.pumpWidget(
      _scaledScrollable(
        CustomerHomeView(
          user: const CurrentUser(
            id: 'customer-id',
            email: 'customer@example.com',
            fullName: 'Alexandra Montgomery Customer',
            role: 'customer',
            isActive: true,
          ),
          status: const CustomerStatus(
            customerId: 'customer-id',
            activeRewardsCount: 0,
            hasEarnedFirstPoint: true,
            hasEarnedFirstReward: false,
            hasUsedFirstReward: false,
            businesses: [],
          ),
          campaignProgresses: const [],
          onShowQr: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ready for your next visit'), findsOneWidget);
    expect(find.text('Earn your first reward'), findsOneWidget);
    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'Show QR')).height,
      greaterThanOrEqualTo(48),
    );
    _expectNoFlutterException(tester);
  });

  testWidgets('staff service controls remain usable at mobile text scale', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    const mission = StaffServiceMission(
      id: 'mission-id',
      name: 'Purchase one participating seasonal specialty coffee',
      description: null,
      missionType: 'purchase',
      pointValue: 2,
      isActive: true,
    );

    await tester.pumpWidget(
      _scaledScrollable(
        Column(
          children: [
            StaffCustomerSummaryCard(
              summary: const StaffServiceSummary(
                businessId: 'business-id',
                customer: StaffServiceCustomer(
                  id: 'customer-id',
                  fullName: 'Alexandra Montgomery Customer',
                  role: 'customer',
                  isActive: true,
                ),
                points: 12,
                activeRewards: [],
                recentActions: [],
              ),
              isLoading: false,
              isConfirmed: false,
              onScan: () {},
              onConfirm: () {},
              onReject: () {},
              onCancelService: () {},
            ),
            const SizedBox(height: 12),
            StaffMissionCard(
              missions: const [mission],
              quantities: const {'mission-id': 1},
              isLoading: false,
              isEnabled: true,
              selectedPoints: 2,
              onIncrement: (_) {},
              onDecrement: (_) {},
              onSubmit: () {},
              isSubmitting: false,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confirm'), findsWidgets);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Register mission action'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(
      tester.getSize(find.widgetWithText(OutlinedButton, 'Reject')).height,
      greaterThanOrEqualTo(48),
    );
    for (final label in ['Confirm', 'Register']) {
      expect(
        tester.getSize(find.widgetWithText(FilledButton, label)).height,
        greaterThanOrEqualTo(48),
      );
    }
    _expectNoFlutterException(tester);
  });

  testWidgets('owner campaign and live summary fit narrow scaled layouts', (
    tester,
  ) async {
    await _setMobileSurface(tester);
    final campaign = OwnerCampaign(
      id: 'campaign-id',
      rewardTemplateId: 'reward-template-id',
      name: 'Seasonal specialty coffee loyalty campaign',
      thresholdPoints: 10,
      isRepeatable: true,
      maxCompletionsPerCustomer: null,
      status: 'active',
      startsAt: DateTime(2026, 7, 1),
      endsAt: DateTime(2026, 10, 1),
      timeStatus: 'active',
      displayStatus: 'Active',
      badgeTone: 'info',
      dateRangeLabel: '2026-07-01 - 2026-10-01',
      activitySummary: const OwnerCampaignActivitySummary(
        participatingCustomerCount: 12,
        rewardsIssuedCount: 10,
        rewardsReadyToUseCount: 4,
        rewardsUsedCount: 5,
        rewardsExpiredCount: 1,
      ),
    );

    await tester.pumpWidget(
      _scaledScrollable(
        Column(
          children: [
            OwnerCampaignListCard(
              campaigns: [campaign],
              selectedTabIndex: 0,
              isSaving: false,
              onPreviewEnd: (_) async => null,
              onEndCampaign: (_, _) async {},
            ),
            const SizedBox(height: 12),
            OwnerSetupChecklist(
              state: const OwnerOnboardingState(
                hasMission: true,
                hasRewardTemplate: true,
                hasActiveCampaign: true,
                hasStaff: true,
                hasActiveStaff: true,
                hasMissionProgressActivity: true,
              ),
              loyaltySummary: const OwnerLoyaltySummary(
                participatingCustomerCount: 12,
                rewardsIssuedCount: 10,
                rewardsReadyToUseCount: 4,
                rewardsUsedCount: 5,
                rewardsExpiredCount: 1,
              ),
              onCreateMission: () {},
              onCreateRewardTemplate: () {},
              onCreateCampaign: () {},
              onInviteStaff: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsNothing);
    expect(find.text('Loyalty is active'), findsOneWidget);
    expect(find.byTooltip('End campaign'), findsOneWidget);
    expect(
      tester.getSize(find.byTooltip('End campaign')).shortestSide,
      greaterThanOrEqualTo(48),
    );
    _expectNoFlutterException(tester);
  });
}

Future<void> _setMobileSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(_mobileSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _scaledApp({required Widget home}) {
  return MaterialApp(
    theme: buildZomiaTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.6)),
      child: child!,
    ),
    home: home,
  );
}

Widget _scaledScrollable(Widget child) {
  return _scaledApp(
    home: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    ),
  );
}

void _expectNoFlutterException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

class _EmptyTokenStore implements TokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> writeAccessToken(String token) async {}

  @override
  Future<void> writeRefreshToken(String token) async {}

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
}
