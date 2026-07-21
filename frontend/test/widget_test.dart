import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zomia_frontend/app/app_version.dart';
import 'package:zomia_frontend/app/router.dart';
import 'package:zomia_frontend/app/ui/app_text_field.dart';
import 'package:zomia_frontend/app/ui/bottom_nav_bar.dart';
import 'package:zomia_frontend/app/ui/confirm_dialog.dart';
import 'package:zomia_frontend/app/ui/reward_card.dart';
import 'package:zomia_frontend/app/ui/status_badge.dart';
import 'package:zomia_frontend/app/zomia_app.dart';
import 'package:zomia_frontend/core/http/api_client.dart';
import 'package:zomia_frontend/core/http/token_refresh_coordinator.dart';
import 'package:zomia_frontend/core/storage/secure_token_store.dart';
import 'package:zomia_frontend/features/auth/data/auth_repository.dart';
import 'package:zomia_frontend/features/auth/domain/current_user.dart';
import 'package:zomia_frontend/features/auth/presentation/auth_controller.dart';
import 'package:zomia_frontend/features/customer_qr/data/customer_qr_repository.dart';
import 'package:zomia_frontend/features/customer_qr/data/customer_qr_token_store.dart';
import 'package:zomia_frontend/features/customer_qr/domain/customer_status.dart';
import 'package:zomia_frontend/features/customer_qr/domain/customer_qr_token.dart';
import 'package:zomia_frontend/features/customer_qr/presentation/customer_presenter.dart';
import 'package:zomia_frontend/features/owner_setup/data/owner_setup_repository.dart';
import 'package:zomia_frontend/features/owner_setup/domain/owner_setup_models.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_onboarding_presenter.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_presenter.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_setup_checklist.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_setup_controller.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_setup_assets_card.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_profile_widgets.dart';
import 'package:zomia_frontend/features/staff_service/data/staff_service_repository.dart';
import 'package:zomia_frontend/features/staff_service/domain/qr_token_input.dart';
import 'package:zomia_frontend/features/staff_service/domain/staff_service_attempt_keys.dart';
import 'package:zomia_frontend/features/staff_service/domain/staff_service_models.dart';
import 'package:zomia_frontend/features/staff_service/presentation/staff_service_cards.dart';
import 'package:zomia_frontend/features/staff_service/presentation/staff_service_presenter.dart';
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

  testWidgets('bottom navigation keeps clearance below its content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            items: const [
              NavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
              ),
              NavItem(
                label: 'Rewards',
                icon: Icons.card_giftcard_outlined,
                activeIcon: Icons.card_giftcard_rounded,
              ),
            ],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(BottomNavBar)).height,
      BottomNavBar.contentHeight + BottomNavBar.minimumBottomClearance,
    );
  });

  testWidgets('bottom navigation honors a reported device safe area', (
    tester,
  ) async {
    const deviceBottomInset = 28.0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: deviceBottomInset),
          ),
          child: Scaffold(
            bottomNavigationBar: BottomNavBar(
              items: const [
                NavItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                ),
                NavItem(
                  label: 'Rewards',
                  icon: Icons.card_giftcard_outlined,
                  activeIcon: Icons.card_giftcard_rounded,
                ),
              ],
              selectedIndex: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(BottomNavBar)).height,
      BottomNavBar.contentHeight + deviceBottomInset,
    );
  });

  test('coalesces concurrent refresh token requests', () async {
    final coordinator = TokenRefreshCoordinator();
    final response = Completer<RefreshedTokenPair>();
    var refreshCount = 0;

    Future<RefreshedTokenPair> refresh() {
      refreshCount += 1;
      return response.future;
    }

    final first = coordinator.run(refresh);
    final second = coordinator.run(refresh);
    expect(refreshCount, 1);

    response.complete(
      const RefreshedTokenPair(
        accessToken: 'next-access',
        refreshToken: 'next-refresh',
      ),
    );
    final results = await Future.wait([first, second]);
    expect(results.map((result) => result.accessToken), [
      'next-access',
      'next-access',
    ]);
  });

  test('reuses an idempotency key only for the same pending attempt', () {
    var sequence = 0;
    final keys = StaffServiceAttemptKeys(
      (prefix) => '$prefix-${sequence += 1}',
    );

    final first = keys.keyFor(
      scope: 'action',
      signature: 'customer-a|mission-a:1',
      prefix: 'action',
    );
    final retry = keys.keyFor(
      scope: 'action',
      signature: 'customer-a|mission-a:1',
      prefix: 'action',
    );
    final changed = keys.keyFor(
      scope: 'action',
      signature: 'customer-a|mission-a:2',
      prefix: 'action',
    );

    expect(retry, first);
    expect(changed, isNot(first));
    keys.resolve('action');
    expect(
      keys.keyFor(
        scope: 'action',
        signature: 'customer-a|mission-a:2',
        prefix: 'action',
      ),
      isNot(changed),
    );
  });

  test('maps staff service backend errors to user-facing messages', () {
    expect(
      mapStaffServiceErrorDetail('QR token is not active'),
      'Scan the current QR.',
    );
    expect(
      mapStaffServiceErrorDetail('Reward is already used'),
      'This reward was already used.',
    );
    expect(
      mapStaffServiceErrorDetail('Concurrent loyalty update. Please retry'),
      'Another loyalty update happened. Please try again.',
    );
    expect(
      mapStaffServiceErrorDetail('Custom backend detail'),
      'Service action could not be completed. Please try again.',
    );
  });

  test('maps customer QR backend errors to user-facing messages', () {
    expect(
      mapCustomerQrErrorDetail('QR token is expired'),
      'This QR code has expired. Refresh your QR code.',
    );
    expect(
      mapCustomerQrErrorDetail('QR token is not active'),
      'This QR code is no longer active. Refresh your QR code.',
    );
    expect(
      mapCustomerQrErrorDetail('Custom customer detail'),
      'QR code is unavailable. Please try again.',
    );
  });

  test('maps owner setup backend errors to user-facing messages', () {
    expect(
      mapOwnerSetupErrorDetail('Business not found'),
      'Business not found or you do not have access.',
    );
    expect(
      mapOwnerSetupErrorDetail('One or more missions were not found'),
      'One or more selected missions are no longer available.',
    );
    expect(
      mapOwnerSetupErrorDetail('Staff invitation is not pending'),
      'This staff invitation can no longer be cancelled.',
    );
    expect(
      mapOwnerSetupErrorDetail('Custom owner detail'),
      'Setup action could not be completed. Please try again.',
    );
  });

  test('maps auth backend errors to user-facing messages', () {
    expect(
      mapAuthErrorDetail('Incorrect email or password'),
      'Incorrect email or password.',
    );
    expect(
      mapAuthErrorDetail('Email already exists'),
      'This email is already registered.',
    );
    expect(
      mapAuthErrorDetail('Business slug already exists'),
      'A business with this name already exists. Try a more specific business name.',
    );
    expect(
      mapAuthErrorDetail('Custom auth detail'),
      'Something went wrong. Please try again.',
    );
  });

  test('auth controller refreshes session from stored refresh token', () async {
    final tokenStore = _MemoryTokenStore();
    await tokenStore.writeTokens(
      accessToken: 'stale-access-token',
      refreshToken: 'stored-refresh-token',
    );
    final authRepository = _FakeAuthRepository(role: 'customer');
    final container = ProviderContainer(
      overrides: [
        secureTokenStoreProvider.overrideWithValue(tokenStore),
        authRepositoryProvider.overrideWithValue(authRepository),
        customerQrRepositoryProvider.overrideWithValue(
          _FakeCustomerQrRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(authControllerProvider.future);

    expect(state.isAuthenticated, isTrue);
    expect(authRepository.refreshCount, 1);
    expect(await tokenStore.readAccessToken(), 'refreshed-access-token');
    expect(await tokenStore.readRefreshToken(), 'refreshed-refresh-token');
  });

  test('auth controller revokes refresh token on sign out', () async {
    final tokenStore = _MemoryTokenStore();
    await tokenStore.writeTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final authRepository = _FakeAuthRepository(role: 'customer');
    final container = ProviderContainer(
      overrides: [
        secureTokenStoreProvider.overrideWithValue(tokenStore),
        authRepositoryProvider.overrideWithValue(authRepository),
        customerQrRepositoryProvider.overrideWithValue(
          _FakeCustomerQrRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    await container.read(authControllerProvider.notifier).signOut();

    expect(authRepository.loggedOutRefreshToken, 'refreshed-refresh-token');
    expect(await tokenStore.readAccessToken(), isNull);
    expect(await tokenStore.readRefreshToken(), isNull);
  });

  test('parses staff service customer without email', () {
    final summary = StaffServiceSummary.fromJson({
      'business_id': 'business-id',
      'customer': {
        'id': 'customer-id',
        'full_name': 'Customer One',
        'role': 'customer',
        'is_active': true,
      },
      'points': 0,
      'active_rewards': [],
      'recent_actions': [],
    });

    expect(summary.customer.fullName, 'Customer One');
  });

  test('staff presenter calculates selected action points', () {
    expect(
      selectedActionPoints(
        missions: const [
          StaffServiceMission(
            id: 'coffee',
            name: 'Coffee',
            description: null,
            missionType: 'purchase',
            pointValue: 1,
            isActive: true,
          ),
          StaffServiceMission(
            id: 'cake',
            name: 'Cake',
            description: null,
            missionType: 'purchase',
            pointValue: 5,
            isActive: true,
          ),
        ],
        quantities: const {'coffee': 2, 'cake': 1},
      ),
      7,
    );
  });

  test('staff presenter describes registered actions', () {
    final result = RegisterActionResult(
      pointsGranted: 1,
      idempotencyReplayed: false,
      summary: StaffServiceSummary(
        businessId: 'business-id',
        customer: const StaffServiceCustomer(
          id: 'customer-id',
          fullName: 'Customer One',
          role: 'customer',
          isActive: true,
        ),
        points: 1,
        activeRewards: [
          GeneratedReward(
            id: 'reward-new',
            title: 'Free Coffee',
            description: null,
            rewardType: 'gift',
            status: 'active',
            giftName: 'Free Coffee',
            discountPercent: null,
            discountAmountMinor: null,
            currencyCode: null,
            expiresAt: DateTime(2027),
          ),
        ],
        recentActions: const [],
      ),
    );

    expect(
      actionRegisteredMessage(result: result, activeRewardIdsBefore: const {}),
      'Action registered. Reward unlocked.',
    );
    expect(shouldShowActiveRewards(result.summary), isTrue);
    expect(
      shouldShowActiveRewards(
        StaffServiceSummary(
          businessId: result.summary.businessId,
          customer: result.summary.customer,
          points: result.summary.points,
          activeRewards: const [],
          recentActions: const [],
        ),
      ),
      isFalse,
    );
  });

  test(
    'customer presenter returns active reward entries with business name',
    () {
      final status = CustomerStatus(
        customerId: 'customer-id',
        activeRewardsCount: 1,
        hasEarnedFirstPoint: true,
        hasEarnedFirstReward: true,
        hasUsedFirstReward: true,
        businesses: [
          CustomerBusinessStatus(
            businessId: 'business-id',
            businessName: 'Zomia Cafe',
            rewards: [
              CustomerReward(
                id: 'reward-active',
                title: 'Free Coffee',
                description: null,
                rewardType: 'gift',
                status: 'active',
                giftName: 'Free Coffee',
                discountPercent: null,
                discountAmountMinor: null,
                currencyCode: null,
                expiresAt: DateTime(2027),
                usedAt: null,
              ),
              CustomerReward(
                id: 'reward-used',
                title: 'Used Coffee',
                description: null,
                rewardType: 'gift',
                status: 'used',
                giftName: 'Used Coffee',
                discountPercent: null,
                discountAmountMinor: null,
                currencyCode: null,
                expiresAt: DateTime(2027),
                usedAt: DateTime(2026),
              ),
            ],
          ),
        ],
      );

      final entries = customerActiveRewardEntries(status);

      expect(entries, hasLength(1));
      expect(entries.first.businessName, 'Zomia Cafe');
      expect(entries.first.reward.id, 'reward-active');
      expect(customerRewardBadgeLabel(entries.first.reward), 'Ready to use');
      expect(
        customerRewardExpiresLabel(entries.first.reward),
        'Show your QR to staff before 2027-01-01 00:00',
      );
    },
  );

  test('customer presenter maps backend badge tone tokens', () {
    expect(customerBadgeTone('success'), BadgeTone.success);
    expect(customerBadgeTone('warning'), BadgeTone.warning);
    expect(customerBadgeTone('neutral'), BadgeTone.neutral);
    expect(customerBadgeTone('unknown'), BadgeTone.info);
  });

  test('customer presenter builds first loyalty step state', () {
    CustomerCampaignProgress progressWithPoints(int points) {
      return CustomerCampaignProgress(
        businessId: 'business-id',
        businessName: 'Zomia Cafe',
        campaignId: 'campaign-id',
        campaignName: 'Coffee Reward',
        startsAt: DateTime.utc(2026, 6, 14),
        endsAt: DateTime.utc(2026, 9, 14),
        progressPoints: points,
        thresholdPoints: 10,
        remainingPoints: 10 - points,
        isCompleted: false,
        isRepeatable: false,
        completedCycles: 0,
        currentCycleNumber: 1,
        maxCompletionsPerCustomer: null,
        campaignTimeStatus: 'active',
        progressState: 'in_progress',
        displayLabel: '$points/10 pts',
        badgeLabel: 'Active',
        badgeTone: 'info',
      );
    }

    CustomerReward rewardWithStatus(String status) {
      return CustomerReward(
        id: 'reward-$status',
        title: 'Free Coffee',
        description: null,
        rewardType: 'gift',
        status: status,
        giftName: 'Free Coffee',
        discountPercent: null,
        discountAmountMinor: null,
        currencyCode: null,
        expiresAt: DateTime(2027),
        usedAt: status == 'used' ? DateTime(2026) : null,
      );
    }

    CustomerStatus statusWithRewards(
      List<CustomerReward> rewards, {
      bool hasEarnedFirstPoint = false,
      bool hasEarnedFirstReward = false,
      bool hasUsedFirstReward = false,
    }) {
      return CustomerStatus(
        customerId: 'customer-id',
        activeRewardsCount: rewards
            .where((reward) => reward.status == 'active')
            .length,
        hasEarnedFirstPoint: hasEarnedFirstPoint,
        hasEarnedFirstReward: hasEarnedFirstReward,
        hasUsedFirstReward: hasUsedFirstReward,
        businesses: [
          CustomerBusinessStatus(
            businessId: 'business-id',
            businessName: 'Zomia Cafe',
            rewards: rewards,
          ),
        ],
      );
    }

    final emptyState = customerLoyaltyStepsState(
      status: const CustomerStatus(
        customerId: 'customer-id',
        activeRewardsCount: 0,
        hasEarnedFirstPoint: false,
        hasEarnedFirstReward: false,
        hasUsedFirstReward: false,
        businesses: [],
      ),
      campaignProgresses: const [],
    );

    expect(emptyState.isComplete, isFalse);
    expect(emptyState.completedCount, 0);
    expect(emptyState.taskCount, 3);
    expect(emptyState.nextStep?.title, 'Earn your first point');
    expect(emptyState.steps.map((step) => step.isDone), [
      isFalse,
      isFalse,
      isFalse,
    ]);

    final earnedPointState = customerLoyaltyStepsState(
      status: statusWithRewards(const [], hasEarnedFirstPoint: true),
      campaignProgresses: [progressWithPoints(0)],
    );

    expect(earnedPointState.isComplete, isFalse);
    expect(earnedPointState.completedCount, 1);
    expect(earnedPointState.nextStep?.title, 'Earn your first reward');

    final earnedRewardState = customerLoyaltyStepsState(
      status: statusWithRewards(
        [rewardWithStatus('active')],
        hasEarnedFirstPoint: true,
        hasEarnedFirstReward: true,
      ),
      campaignProgresses: [progressWithPoints(0)],
    );

    expect(earnedRewardState.isComplete, isFalse);
    expect(earnedRewardState.completedCount, 2);
    expect(earnedRewardState.nextStep?.title, 'Use your first reward');

    final completeState = customerLoyaltyStepsState(
      status: statusWithRewards(
        [rewardWithStatus('used')],
        hasEarnedFirstPoint: true,
        hasEarnedFirstReward: true,
        hasUsedFirstReward: true,
      ),
      campaignProgresses: [progressWithPoints(0)],
    );

    expect(completeState.isComplete, isTrue);
    expect(completeState.completedCount, 3);
    expect(completeState.nextStep, isNull);
    expect(completeState.steps.map((step) => step.isDone), [
      isTrue,
      isTrue,
      isTrue,
    ]);
  });

  test('owner presenter describes campaign repeatability', () {
    expect(
      ownerCampaignSubtitle(
        OwnerCampaign(
          id: 'campaign-id',
          rewardTemplateId: 'template-id',
          name: 'Coffee Reward',
          thresholdPoints: 10,
          isRepeatable: true,
          maxCompletionsPerCustomer: null,
          status: 'active',
          startsAt: DateTime(2026, 6, 14),
          endsAt: DateTime(2026, 9, 14),
          timeStatus: 'active',
          displayStatus: 'Active',
          badgeTone: 'info',
          dateRangeLabel: '2026-06-14 - 2026-09-14',
        ),
      ),
      '10 pts · repeatable · unlimited within dates',
    );
  });

  test('owner presenter maps activity badge', () {
    final presentation = ownerActivityPresentation(
      OwnerActivity(
        actionId: 'action-id',
        businessId: 'business-id',
        actionType: 'reward_use',
        staffName: 'Staff One',
        staffEmail: 'staff@example.com',
        customerName: 'Customer One',
        customerEmail: 'customer@example.com',
        pointsGranted: 0,
        summary: 'Reward used',
        createdAt: DateTime(2026, 1, 1, 10, 30),
      ),
    );

    expect(presentation.badgeLabel, 'Reward used');
    expect(presentation.badgeTone, BadgeTone.success);
    expect(presentation.subtitle, contains('Customer One · Staff One'));
  });

  test('owner presenter maps staff toggle confirmation', () {
    final presentation = ownerStaffTogglePresentation(false);

    expect(presentation.title, 'Deactivate Staff?');
    expect(presentation.confirmLabel, 'Deactivate');
    expect(presentation.tone, ConfirmTone.destructive);
  });

  test('owner onboarding requires an active campaign', () {
    final inactiveState = OwnerOnboardingState.fromData(
      missions: const [
        OwnerMission(
          id: 'mission-id',
          name: 'Buy Coffee',
          missionType: 'purchase',
          pointValue: 1,
          isActive: true,
          canEdit: false,
          canDelete: false,
          canArchive: false,
        ),
      ],
      rewardTemplates: const [
        OwnerRewardTemplate(
          id: 'template-id',
          name: 'Coffee Reward',
          rewardType: 'gift',
          giftName: 'Free coffee',
          validDays: 30,
          isActive: true,
          canEdit: false,
          canDelete: false,
          canArchive: false,
        ),
      ],
      campaigns: [
        OwnerCampaign(
          id: 'expired-campaign',
          rewardTemplateId: 'template-id',
          name: 'Expired Campaign',
          thresholdPoints: 10,
          isRepeatable: true,
          maxCompletionsPerCustomer: null,
          status: 'active',
          startsAt: DateTime(2026, 1, 1),
          endsAt: DateTime(2026, 1, 31),
          timeStatus: 'expired',
          displayStatus: 'Expired',
          badgeTone: 'warning',
          dateRangeLabel: '2026-01-01 - 2026-01-31',
        ),
        OwnerCampaign(
          id: 'ended-campaign',
          rewardTemplateId: 'template-id',
          name: 'Ended Campaign',
          thresholdPoints: 10,
          isRepeatable: true,
          maxCompletionsPerCustomer: null,
          status: 'ended',
          startsAt: DateTime(2026, 1, 1),
          endsAt: DateTime(2026, 12, 31),
          timeStatus: 'ended',
          displayStatus: 'Ended',
          badgeTone: 'neutral',
          dateRangeLabel: '2026-01-01 - 2026-12-31',
        ),
      ],
      staffMembers: const [],
      recentActivities: const [],
    );

    final activeState = OwnerOnboardingState.fromData(
      missions: inactiveState.hasMission
          ? const [
              OwnerMission(
                id: 'mission-id',
                name: 'Buy Coffee',
                missionType: 'purchase',
                pointValue: 1,
                isActive: true,
                canEdit: false,
                canDelete: false,
                canArchive: false,
              ),
            ]
          : const [],
      rewardTemplates: const [
        OwnerRewardTemplate(
          id: 'template-id',
          name: 'Coffee Reward',
          rewardType: 'gift',
          giftName: 'Free coffee',
          validDays: 30,
          isActive: true,
          canEdit: false,
          canDelete: false,
          canArchive: false,
        ),
      ],
      campaigns: [
        OwnerCampaign(
          id: 'active-campaign',
          rewardTemplateId: 'template-id',
          name: 'Active Campaign',
          thresholdPoints: 10,
          isRepeatable: true,
          maxCompletionsPerCustomer: null,
          status: 'active',
          startsAt: DateTime(2026, 1, 1),
          endsAt: DateTime(2026, 12, 31),
          timeStatus: 'active',
          displayStatus: 'Active',
          badgeTone: 'info',
          dateRangeLabel: '2026-01-01 - 2026-12-31',
        ),
      ],
      staffMembers: const [],
      recentActivities: const [],
    );

    expect(inactiveState.hasActiveCampaign, isFalse);
    expect(inactiveState.firstSetupCompletedCount, 2);
    expect(activeState.hasActiveCampaign, isTrue);
    expect(activeState.firstSetupCompletedCount, 3);
  });

  testWidgets(
    'owner setup checklist locks campaign until prerequisites exist',
    (tester) async {
      var campaignTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OwnerSetupChecklist(
                state: const OwnerOnboardingState(
                  hasMission: false,
                  hasRewardTemplate: false,
                  hasActiveCampaign: false,
                  hasStaff: false,
                  hasActiveStaff: false,
                  hasMissionProgressActivity: false,
                ),
                onCreateMission: () {},
                onCreateRewardTemplate: () {},
                onCreateCampaign: () => campaignTapCount++,
                onInviteStaff: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('First setup'), findsOneWidget);
      expect(find.text('0 of 4 steps complete'), findsOneWidget);
      expect(find.text('Activate your first campaign'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);

      await tester.tap(find.text('Activate your first campaign'));
      await tester.pump();

      expect(campaignTapCount, 0);
    },
  );

  testWidgets(
    'owner setup checklist keeps card padding when historical pilot tasks are complete',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OwnerSetupChecklist(
                state: const OwnerOnboardingState(
                  hasMission: true,
                  hasRewardTemplate: false,
                  hasActiveCampaign: false,
                  hasStaff: true,
                  hasActiveStaff: true,
                  hasMissionProgressActivity: true,
                ),
                onCreateMission: () {},
                onCreateRewardTemplate: () {},
                onCreateCampaign: () {},
                onInviteStaff: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('First setup'), findsOneWidget);
      expect(find.text('2 of 4 steps complete'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('First setup')).dx,
        greaterThanOrEqualTo(16),
      );
    },
  );

  testWidgets('owner setup checklist shows completion state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OwnerSetupChecklist(
              state: const OwnerOnboardingState(
                hasMission: true,
                hasRewardTemplate: true,
                hasActiveCampaign: true,
                hasStaff: true,
                hasActiveStaff: true,
                hasMissionProgressActivity: true,
              ),
              loyaltySummary: const OwnerLoyaltySummary(
                participatingCustomerCount: 2,
                rewardsIssuedCount: 5,
                rewardsReadyToUseCount: 1,
                rewardsUsedCount: 4,
                rewardsExpiredCount: 0,
              ),
              onCreateMission: () {},
              onCreateRewardTemplate: () {},
              onCreateCampaign: () {},
              onInviteStaff: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Loyalty is active'), findsOneWidget);
    expect(find.text('Your first workflow is live.'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Rewards issued'), findsOneWidget);
    expect(find.text('Ready to use'), findsOneWidget);
    expect(find.text('Used'), findsOneWidget);
    expect(find.text('Create your first mission'), findsNothing);
    expect(find.text('Staff accepts invitation'), findsNothing);
    expect(find.text('First setup complete'), findsNothing);
    expect(find.text('Pilot tasks complete'), findsNothing);
  });

  testWidgets('owner loyalty summary handles narrow scaled text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.6),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: OwnerSetupChecklist(
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
                  rewardsUsedCount: 6,
                  rewardsExpiredCount: 0,
                ),
                onCreateMission: () {},
                onCreateRewardTemplate: () {},
                onCreateCampaign: () {},
                onInviteStaff: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Rewards issued'), findsOneWidget);
    expect(find.text('Ready to use'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('owner loyalty summary reports temporary unavailability', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OwnerSetupChecklist(
              state: const OwnerOnboardingState(
                hasMission: true,
                hasRewardTemplate: true,
                hasActiveCampaign: true,
                hasStaff: true,
                hasActiveStaff: true,
                hasMissionProgressActivity: true,
              ),
              onCreateMission: () {},
              onCreateRewardTemplate: () {},
              onCreateCampaign: () {},
              onInviteStaff: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Activity summary is temporarily unavailable. Pull to refresh.',
      ),
      findsOneWidget,
    );
    expect(find.text('Rewards issued'), findsNothing);
  });

  testWidgets('owner setup checklist shows pilot task statuses', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OwnerSetupChecklist(
              state: const OwnerOnboardingState(
                hasMission: true,
                hasRewardTemplate: true,
                hasActiveCampaign: true,
                hasStaff: true,
                hasActiveStaff: true,
                hasMissionProgressActivity: false,
              ),
              onCreateMission: () {},
              onCreateRewardTemplate: () {},
              onCreateCampaign: () {},
              onInviteStaff: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pilot tasks'), findsOneWidget);
    expect(find.text('First setup complete'), findsOneWidget);
    expect(find.text('Staff accepts invitation'), findsOneWidget);
    expect(find.text('Staff registers first action'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Create your first mission'), findsNothing);
    expect(find.text('Done'), findsNWidgets(2));
  });

  testWidgets('owner setup assets open detailed management separately', (
    tester,
  ) async {
    String? error;
    String? success;
    var missions = const [
      OwnerMission(
        id: 'mission-coffee',
        name: 'Buy Coffee',
        missionType: 'purchase',
        pointValue: 1,
        isActive: true,
        canEdit: true,
        canDelete: true,
        canArchive: false,
      ),
    ];
    const rewardTemplates = [
      OwnerRewardTemplate(
        id: 'template-coffee',
        name: 'Coffee Reward',
        rewardType: 'gift',
        giftName: 'Free coffee',
        validDays: 30,
        isActive: true,
        canEdit: true,
        canDelete: true,
        canArchive: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OwnerSetupAssetsCard(
            missions: missions,
            rewardTemplates: rewardTemplates,
            currentMissions: () => missions,
            currentRewardTemplates: () => rewardTemplates,
            currentError: () => error,
            currentSuccess: () => success,
            onClearError: () => error = null,
            onClearSuccess: () => success = null,
            isSaving: false,
            onEditMission: (_) async {},
            onDeleteMission: (_) async {
              missions = const [];
              success = 'Mission deleted.';
            },
            onArchiveMission: (_) async {},
            onEditRewardTemplate: (_) async {},
            onDeleteRewardTemplate: (_) async {},
            onArchiveRewardTemplate: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Setup assets'), findsOneWidget);
    expect(find.text('1 mission · 1 reward template'), findsOneWidget);
    expect(find.text('Buy Coffee'), findsNothing);
    expect(find.text('Free coffee · 30 days'), findsNothing);

    await tester.tap(find.text('Setup assets'));
    await tester.pumpAndSettle();

    expect(find.text('Buy Coffee'), findsOneWidget);
    expect(
      find.text(
        'Staff can use these only when they belong to an active campaign.',
      ),
      findsOneWidget,
    );
    expect(find.text('Gift'), findsOneWidget);
    expect(
      find.text('Campaigns use these to create customer rewards.'),
      findsOneWidget,
    );
    expect(find.text('Free coffee · 30 days'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete mission'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete mission'));
    await tester.pumpAndSettle();

    expect(find.text('Buy Coffee'), findsNothing);
    expect(find.text('No missions yet'), findsOneWidget);
    expect(find.text('Mission deleted.'), findsOneWidget);
  });

  test('owner campaign creation defaults to repeatable unlimited', () async {
    final repository = _FakeOwnerSetupRepository();
    final controller = OwnerSetupController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();
    controller.campaignForm.nameController.text = 'Coffee Reward';
    controller.campaignForm.thresholdController.text = '10';
    await controller.createCampaign();

    expect(repository.createdCampaignIsRepeatable, isTrue);
    expect(repository.createdCampaignMaxCompletions, isNull);
    expect(repository.createdCampaignStartsAt, isNotNull);
    expect(repository.createdCampaignEndsAt, isNotNull);
    expect(repository.createdCampaignStartsAt!.isUtc, isFalse);
    expect(repository.createdCampaignStartsAt!.hour, 0);
    expect(repository.createdCampaignStartsAt!.minute, 0);
    expect(repository.createdCampaignEndsAt!.isUtc, isFalse);
    expect(repository.createdCampaignEndsAt!.hour, 23);
    expect(repository.createdCampaignEndsAt!.minute, 59);
    expect(
      repository.createdCampaignStartsAt!.isBefore(
        repository.createdCampaignEndsAt!,
      ),
      isTrue,
    );
  });

  test('owner campaign can be set to non-repeatable', () async {
    final repository = _FakeOwnerSetupRepository();
    final controller = OwnerSetupController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();
    controller.campaignForm.nameController.text = 'Coffee Reward';
    controller.campaignForm.thresholdController.text = '10';
    controller.setCampaignRepeatable(false);
    await controller.createCampaign();

    expect(repository.createdCampaignIsRepeatable, isFalse);
    expect(repository.createdCampaignMaxCompletions, isNull);
  });

  test('owner repeatable campaign validates completion limit', () async {
    final repository = _FakeOwnerSetupRepository();
    final controller = OwnerSetupController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();
    controller.campaignForm.nameController.text = 'Coffee Reward';
    controller.campaignForm.thresholdController.text = '10';
    controller.setCampaignCompletionLimit(true);
    controller.campaignForm.maxCompletionsController.text = '1';
    await controller.createCampaign();

    expect(controller.error, 'Completion limit must be at least 2.');
    expect(repository.createdCampaignIsRepeatable, isNull);

    controller.campaignForm.maxCompletionsController.text = '2';
    await controller.createCampaign();

    expect(repository.createdCampaignIsRepeatable, isTrue);
    expect(repository.createdCampaignMaxCompletions, 2);
  });

  test('owner campaign creation validates date range', () async {
    final repository = _FakeOwnerSetupRepository();
    final controller = OwnerSetupController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();
    controller.campaignForm.nameController.text = 'Coffee Reward';
    controller.campaignForm.thresholdController.text = '10';
    controller.setCampaignStartDate(DateTime(2026, 9, 14));
    controller.setCampaignEndDate(DateTime(2026, 6, 14));
    await controller.createCampaign();

    expect(controller.error, 'End date must be after start date.');
    expect(repository.createdCampaignStartsAt, isNull);
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
    expect(find.text(AppVersion.label), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Register your business'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('renders session expired message on login screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
          sessionExpiredMessageProvider.overrideWith(
            _ExpiredSessionMessageNotifier.new,
          ),
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

    expect(
      find.text('Your session expired. Please sign in again.'),
      findsOneWidget,
    );
  });

  testWidgets('keeps the UI component catalog hidden by default', (
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

    expect(find.text(AppVersion.label), findsOneWidget);
    expect(find.text('UI Component Catalog'), findsNothing);
    expect(find.text('Zomia Design System'), findsNothing);
  });

  testWidgets('recovers password and returns to login', (tester) async {
    final authRepository = _FakeAuthRepository(role: 'customer');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
          authRepositoryProvider.overrideWithValue(authRepository),
          customerQrRepositoryProvider.overrideWithValue(
            _FakeCustomerQrRepository(),
          ),
        ],
        child: const ZomiaApp(),
      ),
    );
    await pumpAppFrames(tester);

    await tester.tap(find.text('Forgot password?'));
    await pumpAppFrames(tester);

    expect(find.text('Forgot Password'), findsOneWidget);
    await _enterTextByLabel(tester, 'Email', 'customer@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await pumpAppFrames(tester);

    expect(authRepository.startedPasswordRecovery, isTrue);
    expect(find.text('Verify Reset Code'), findsOneWidget);
    await _enterTextByLabel(tester, 'Verification code', '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify code'));
    await pumpAppFrames(tester);

    expect(authRepository.verifiedPasswordRecovery, isTrue);
    expect(find.text('Set New Password'), findsOneWidget);
    await _enterTextByLabel(tester, 'Password', 'new-strong-password');
    await _enterTextByLabel(tester, 'Confirm Password', 'new-strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Save password'));
    await pumpAppFrames(tester);
    await tester.pumpAndSettle();

    expect(authRepository.completedPasswordRecovery, isTrue);
    expect(authRepository.completedNewPassword, 'new-strong-password');
    expect(find.text('Welcome back'), findsOneWidget);
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

    await tester.tap(find.text('Create account'));
    await pumpAppFrames(tester);

    expect(find.text('Get Started'), findsOneWidget);

    await _enterTextByLabel(tester, 'Name', 'Customer One');
    await _enterTextByLabel(tester, 'Email', 'customer@example.com');
    await _enterTextByLabel(tester, 'Password', 'strong-password');
    await _enterTextByLabel(tester, 'Confirm Password', 'strong-password');
    expect(find.text('Terms'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
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

    expect(authRepository.startedCustomerRegistration, isTrue);
    expect(find.text('Verify Email'), findsOneWidget);
    expect(find.text('Back to registration'), findsOneWidget);
    await _enterTextByLabel(tester, 'Verification code', '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify email'));
    await pumpAppFrames(tester);
    await tester.pumpAndSettle();

    expect(authRepository.verifiedCustomerRegistration, isTrue);
    expect(await tokenStore.readAccessToken(), 'access-token');
    expect(await tokenStore.readRefreshToken(), 'refresh-token');
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Hi, Customer One'), findsOneWidget);
  });

  testWidgets('registers a business owner and opens owner dashboard', (
    tester,
  ) async {
    final tokenStore = _MemoryTokenStore();
    final authRepository = _FakeAuthRepository(role: 'owner');

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(authRepository),
          ownerSetupRepositoryProvider.overrideWithValue(
            _FakeOwnerSetupRepository(),
          ),
        ],
        child: const ZomiaApp(),
      ),
    );
    await pumpAppFrames(tester);
    appRouter.go('/register/business');
    await pumpAppFrames(tester);

    expect(find.text('Register Business'), findsOneWidget);
    expect(find.text('Cafe'), findsNothing);

    await _enterTextByLabel(tester, 'Business name', 'Zomia Cafe');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbershops').last);
    await tester.pumpAndSettle();
    await _enterTextByLabel(tester, 'Email', 'owner@example.com');
    await _enterTextByLabel(tester, 'Password', 'strong-password');
    await _enterTextByLabel(tester, 'Confirm Password', 'strong-password');
    expect(find.text('Business Terms'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Register business'),
    );
    await tester.pumpAndSettle();
    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Register business'),
    );
    expect(createButton.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Register business'));
    await pumpAppFrames(tester);
    await tester.pumpAndSettle();

    expect(authRepository.startedOwnerRegistration, isTrue);
    expect(authRepository.ownerBusinessName, 'Zomia Cafe');
    expect(authRepository.ownerBusinessCategory, 'barbershops');
    expect(find.text('Verify Email'), findsOneWidget);
    expect(find.text('Back to registration'), findsOneWidget);
    await _enterTextByLabel(tester, 'Verification code', '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify email'));
    await pumpAppFrames(tester);
    await tester.pumpAndSettle();

    expect(authRepository.verifiedOwnerRegistration, isTrue);
    expect(await tokenStore.readAccessToken(), 'access-token');
    expect(await tokenStore.readRefreshToken(), 'refresh-token');
    expect(find.text('Owner Dashboard'), findsOneWidget);
  });

  testWidgets('signs in and renders staff context', (tester) async {
    final tokenStore = _MemoryTokenStore();
    final authRepository = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(authRepository),
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
    expect(await tokenStore.readRefreshToken(), 'refresh-token');
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Zomia Cafe'), findsWidgets);
    expect(find.text('Signed in as Staff One'), findsOneWidget);
    expect(find.byTooltip('Scan customer QR'), findsNothing);
    expect(find.text('Customer QR'), findsNothing);
    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('No customer loaded'), findsOneWidget);
    expect(find.text('Buy Coffee'), findsNothing);
    expect(find.text('Use active reward'), findsNothing);
    expect(find.text('Register mission action'), findsNothing);

    await tester.tap(find.text('Recent Actions'));
    await pumpAppFrames(tester);

    expect(find.text('Recent Actions'), findsWidgets);
    expect(find.text('Staff recent actions'), findsOneWidget);
    expect(find.text('No staff actions yet'), findsOneWidget);

    tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
    await pumpAppFrames(tester);
    await tester.tap(find.text('Profile'));
    await pumpAppFrames(tester);

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Staff One'), findsOneWidget);
    expect(find.text('staff@example.com'), findsOneWidget);
    expect(find.byTooltip('Edit profile'), findsOneWidget);
    expect(find.text('Account Settings'), findsNothing);

    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
    await pumpAppFrames(tester);
    await tester.tap(find.text('Setting'));
    await pumpAppFrames(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Change Email'), findsNothing);
    expect(find.text('Remove Account'), findsNothing);

    await tester.tap(find.text('Change Password'));
    await pumpAppFrames(tester);
    await _enterTextByLabel(tester, 'Current Password', 'strong-password');
    await _enterTextByLabel(tester, 'New Password', 'new-strong-password');
    await _enterTextByLabel(tester, 'Confirm Password', 'new-strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Save password'));
    await pumpAppFrames(tester);

    expect(authRepository.changedPassword, isTrue);
    expect(authRepository.changedCurrentPassword, 'strong-password');
    expect(authRepository.changedNewPassword, 'new-strong-password');
    expect(await tokenStore.readAccessToken(), isNull);
    expect(await tokenStore.readRefreshToken(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Password changed. Please sign in again.'),
      findsOneWidget,
    );
  });

  testWidgets('signs in and renders customer QR screen', (tester) async {
    final tokenStore = _MemoryTokenStore();
    final qrRepository = _FakeCustomerQrRepository();
    final authRepository = _FakeAuthRepository(role: 'customer');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(authRepository),
          customerQrRepositoryProvider.overrideWithValue(qrRepository),
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
    expect(await tokenStore.readRefreshToken(), 'refresh-token');
    expect(find.text('Home'), findsWidgets);
    expect(find.byTooltip('Show QR code'), findsOneWidget);
    expect(find.text('Hi, Customer One'), findsOneWidget);
    expect(find.text('Ready for your next visit'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Show QR'), findsOneWidget);
    expect(find.text('1 active campaigns'), findsNothing);
    expect(find.text('1 active rewards'), findsNothing);
    expect(find.text('First loyalty flow complete'), findsOneWidget);
    expect(
      find.text('Keep showing your QR on each visit to earn more rewards.'),
      findsOneWidget,
    );
    expect(find.text('Earn your first point'), findsNothing);
    expect(qrRepository.issueCount, 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(authRepository),
          customerQrRepositoryProvider.overrideWithValue(qrRepository),
        ],
        child: const ZomiaApp(),
      ),
    );
    await pumpAppFrames(tester);

    expect(find.text('Home'), findsWidgets);
    expect(qrRepository.issueCount, 1);

    await tester.tap(find.text('Campaign'));
    await pumpAppFrames(tester);

    expect(find.text('Campaign'), findsWidgets);
    expect(find.text('All'), findsWidgets);
    expect(find.text('Archive'), findsWidgets);
    expect(find.text('Campaign Progress'), findsNothing);
    expect(find.text('Coffee Reward'), findsWidgets);
    expect(find.text('Completed Coffee'), findsNothing);
    expect(find.text('2/10 pts · 8 pts to reward'), findsOneWidget);
    expect(find.text('2026-06-14 - 2026-09-14'), findsOneWidget);

    await tester.tap(find.text('Archive'));
    await pumpAppFrames(tester);

    expect(find.text('Coffee Reward'), findsNothing);
    expect(find.text('Completed Coffee'), findsOneWidget);
    expect(find.text('10/10 pts · Completed'), findsOneWidget);

    await tester.tap(find.text('Reward'));
    await pumpAppFrames(tester);

    expect(find.text('Reward'), findsWidgets);
    expect(find.text('Active Rewards'), findsNothing);
    expect(find.text('Free Coffee'), findsWidgets);
    expect(find.text('Used Coffee'), findsNothing);
    expect(find.text('Zomia Cafe'), findsOneWidget);
    expect(find.text('Free coffee'), findsOneWidget);
    expect(find.text('Ready to use'), findsOneWidget);
    expect(
      find.text('Show your QR to staff before 2027-01-01 00:00'),
      findsOneWidget,
    );

    await tester.tap(find.text('Archive'));
    await pumpAppFrames(tester);

    expect(find.text('Free Coffee'), findsNothing);
    expect(find.text('Used Coffee'), findsOneWidget);
    expect(find.text('Used'), findsOneWidget);
    expect(find.text('Used 2026-01-02 00:00'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await pumpAppFrames(tester);

    expect(find.text('Customer One'), findsNothing);
    expect(find.text('customer@example.com'), findsNothing);
    expect(find.text('Setting'), findsOneWidget);
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(find.text('Setting'));
    await pumpAppFrames(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Change Email'), findsOneWidget);
    expect(find.text('Remove Account'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await pumpAppFrames(tester);

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await pumpAppFrames(tester);
    await tester.tap(find.text('Profile'));
    await pumpAppFrames(tester);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Customer One'), findsWidgets);
    expect(find.text('Edit Profile'), findsNothing);
    expect(find.byTooltip('Edit profile'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit profile'));
    await pumpAppFrames(tester);

    expect(find.byTooltip('Back'), findsOneWidget);
    await _enterTextByLabel(tester, 'Name', 'Customer Updated');
    await tester.tap(find.widgetWithText(FilledButton, 'Save profile'));
    await pumpAppFrames(tester);
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsNothing);
    expect(find.text('Customer Updated'), findsWidgets);
    expect(authRepository.updatedCustomerName, 'Customer Updated');

    await tester.binding.handlePopRoute();
    await pumpAppFrames(tester);

    await tester.tap(find.byTooltip('Show QR code'));
    await pumpAppFrames(tester);

    expect(find.text('Ready to Scan'), findsOneWidget);
    expect(find.text('Refresh QR'), findsOneWidget);
    expect(find.text('qr-token'), findsOneWidget);

    await tester.tap(find.text('Refresh QR'));
    await pumpAppFrames(tester);

    expect(find.text('rotated-qr-token'), findsOneWidget);
    expect(find.text('qr-token'), findsNothing);
    expect(find.text('Old QR is invalid.'), findsOneWidget);
  });

  testWidgets('changes customer password and returns to login', (tester) async {
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

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'customer@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await pumpAppFrames(tester);

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await pumpAppFrames(tester);
    await tester.tap(find.text('Setting'));
    await pumpAppFrames(tester);
    await tester.tap(find.text('Change Password'));
    await pumpAppFrames(tester);

    await _enterTextByLabel(tester, 'Current Password', 'strong-password');
    await _enterTextByLabel(tester, 'New Password', 'new-strong-password');
    await _enterTextByLabel(tester, 'Confirm Password', 'new-strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Save password'));
    await pumpAppFrames(tester);
    await tester.pumpAndSettle();

    expect(authRepository.changedPassword, isTrue);
    expect(authRepository.changedCurrentPassword, 'strong-password');
    expect(authRepository.changedNewPassword, 'new-strong-password');
    expect(await tokenStore.readAccessToken(), isNull);
    expect(await tokenStore.readRefreshToken(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Password changed. Please sign in again.'),
      findsOneWidget,
    );
  });

  testWidgets('changes customer email and keeps the session active', (
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

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'customer@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await pumpAppFrames(tester);

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await pumpAppFrames(tester);
    await tester.tap(find.text('Setting'));
    await pumpAppFrames(tester);
    await tester.tap(find.text('Change Email'));
    await pumpAppFrames(tester);

    await _enterTextByLabel(tester, 'New Email', 'new-customer@example.com');
    await _enterTextByLabel(tester, 'Current Password', 'strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await pumpAppFrames(tester);

    expect(authRepository.startedEmailChange, isTrue);
    expect(authRepository.emailChangeNewEmail, 'new-customer@example.com');
    expect(find.text('Code sent to new-customer@example.com.'), findsOneWidget);

    await _enterTextByLabel(tester, 'Verification code', '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify email'));
    await pumpAppFrames(tester);
    await tester.pumpAndSettle();

    expect(authRepository.verifiedEmailChange, isTrue);
    expect(await tokenStore.readAccessToken(), 'access-token');
    expect(await tokenStore.readRefreshToken(), 'refresh-token');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Email changed.'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await pumpAppFrames(tester);
    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await pumpAppFrames(tester);
    await tester.tap(find.text('Profile'));
    await pumpAppFrames(tester);

    expect(find.text('new-customer@example.com'), findsOneWidget);
  });

  testWidgets('removes customer account and returns to login', (tester) async {
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

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'customer@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await pumpAppFrames(tester);

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await pumpAppFrames(tester);
    await tester.tap(find.text('Setting'));
    await pumpAppFrames(tester);
    await tester.tap(find.text('Remove Account'));
    await pumpAppFrames(tester);

    await _enterTextByLabel(tester, 'Current Password', 'strong-password');
    await tester.tap(find.text('I understand this cannot be undone.'));
    await pumpAppFrames(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove account'));
    await pumpAppFrames(tester);
    await tester.pumpAndSettle();

    expect(authRepository.removedAccount, isTrue);
    expect(authRepository.removedAccountCurrentPassword, 'strong-password');
    expect(await tokenStore.readAccessToken(), isNull);
    expect(await tokenStore.readRefreshToken(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Account removed.'), findsOneWidget);
  });

  testWidgets('signs in and renders owner setup screen', (tester) async {
    final tokenStore = _MemoryTokenStore();
    final authRepository = _FakeAuthRepository(role: 'owner');
    final ownerRepository = _FakeOwnerSetupRepository();
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(tokenStore),
          authRepositoryProvider.overrideWithValue(authRepository),
          ownerSetupRepositoryProvider.overrideWithValue(ownerRepository),
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
    expect(await tokenStore.readRefreshToken(), 'refresh-token');
    expect(find.text('Owner Dashboard'), findsOneWidget);
    expect(find.text('Zomia Cafe'), findsWidgets);
    expect(find.byTooltip('Recent activity'), findsOneWidget);
    expect(find.text('Create Mission'), findsNothing);
    expect(find.text('Buy Coffee'), findsNothing);
    expect(find.text('Edit business'), findsOneWidget);

    await tester.tap(find.text('Edit business'));
    await pumpAppFrames(tester);

    expect(find.text('Business Settings'), findsOneWidget);
    expect(find.text('Business profile'), findsOneWidget);
    expect(find.text('Public contact'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    await _enterTextByLabel(tester, 'Business name', 'Updated Cafe');
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bakery').last);
    await tester.pumpAndSettle();
    await _enterTextByLabel(tester, 'Public email', 'hello@updated.example');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Save business'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save business'));
    await pumpAppFrames(tester);

    expect(ownerRepository.businessName, 'Updated Cafe');
    expect(ownerRepository.updatedBusinessCategory, 'bakery');
    expect(ownerRepository.updatedBusinessPublicEmail, 'hello@updated.example');
    expect(find.text('Business updated.'), findsOneWidget);
    expect(find.text('Updated Cafe'), findsWidgets);

    await tester.tap(find.text('Loyalty'));
    await pumpAppFrames(tester);

    expect(find.text('Active'), findsWidgets);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Setup assets'), findsOneWidget);
    expect(find.text('1 mission · 1 reward template'), findsOneWidget);
    expect(find.text('Coffee Reward'), findsWidgets);
    expect(find.text('10 pts · non-repeatable'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('2026-01-01 - 2027-01-01'), findsOneWidget);
    expect(find.text('Buy Coffee'), findsNothing);
    expect(find.text('Gift'), findsNothing);
    expect(find.text('Free coffee · 30 days'), findsNothing);

    await tester.tap(find.byTooltip('Create loyalty item'));
    await pumpAppFrames(tester);

    expect(find.text('Create'), findsOneWidget);
    await tester.tap(find.text('Create Campaign'));
    await pumpAppFrames(tester);

    expect(find.text('Repeatable campaign'), findsOneWidget);

    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Team'));
    await pumpAppFrames(tester);

    expect(find.text('Create Staff'), findsNothing);
    expect(find.text('Pending invitations'), findsOneWidget);
    expect(
      find.text('Waiting for staff to accept the invitation email.'),
      findsOneWidget,
    );
    expect(find.text('Staff members'), findsOneWidget);
    expect(find.text('People who can scan customer QR codes.'), findsOneWidget);
    expect(find.text('Setup Staff'), findsOneWidget);
    expect(find.text('setup-staff@example.com'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('pending-staff@example.com'), findsWidgets);
    expect(
      find.text('Invitation sent to pending-staff@example.com'),
      findsOneWidget,
    );
    expect(find.text('Pending'), findsOneWidget);
    expect(find.byTooltip('Deactivate staff'), findsOneWidget);
    expect(find.byTooltip('Cancel invitation'), findsOneWidget);
    expect(find.byTooltip('Invite staff'), findsOneWidget);

    await tester.tap(find.byTooltip('Invite staff'));
    await pumpAppFrames(tester);

    expect(find.text('Invite Staff'), findsWidgets);
    expect(find.text('Staff email'), findsOneWidget);

    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byTooltip('Deactivate staff'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Deactivate staff'));
    await pumpAppFrames(tester);

    expect(find.text('Deactivate Staff?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
    await pumpAppFrames(tester);

    expect(find.text('Staff deactivated.'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
    expect(find.byTooltip('Activate staff'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byTooltip('Cancel invitation'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Cancel invitation'));
    await pumpAppFrames(tester);

    expect(find.text('Cancel invitation?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel invitation'));
    await pumpAppFrames(tester);

    expect(find.text('Staff invitation cancelled.'), findsOneWidget);
    expect(find.text('pending-staff@example.com'), findsNothing);

    tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
    await pumpAppFrames(tester);
    await tester.tap(find.text('Profile'));
    await pumpAppFrames(tester);

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('Create Staff'), findsNothing);

    await tester.tap(find.text('Account Settings'));
    await pumpAppFrames(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Change Email'), findsOneWidget);
    expect(find.text('Remove Account'), findsNothing);

    await tester.tap(find.text('Change Email'));
    await pumpAppFrames(tester);
    await _enterTextByLabel(tester, 'New Email', 'owner-new@example.com');
    await _enterTextByLabel(tester, 'Current Password', 'strong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await pumpAppFrames(tester);
    await _enterTextByLabel(tester, 'Verification code', '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify email'));
    await pumpAppFrames(tester);

    expect(authRepository.startedEmailChange, isTrue);
    expect(authRepository.verifiedEmailChange, isTrue);
    expect(authRepository.emailChangeNewEmail, 'owner-new@example.com');

    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Recent activity'));
    await pumpAppFrames(tester);

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Staff Recent Actions'), findsNothing);
    expect(find.text('Latest staff actions for this business.'), findsNothing);
    expect(find.text('Buy Coffee x2'), findsOneWidget);
    expect(find.text('Customer One · Staff One · 01/01 10:30'), findsOneWidget);
    expect(find.text('+2 pts'), findsOneWidget);
  });

  testWidgets('renders empty owner recent activity dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownerSetupRepositoryProvider.overrideWithValue(
            _EmptyOwnerSetupRepository(),
          ),
        ],
        child: const MaterialApp(
          home: OwnerRecentActionsDialog(businessId: 'business-id'),
        ),
      ),
    );
    await pumpAppFrames(tester);

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Staff Recent Actions'), findsNothing);
    expect(find.text('No staff actions yet'), findsOneWidget);
    expect(find.text('Close'), findsNothing);
  });

  testWidgets('renders staff customer card without customer email', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StaffCustomerSummaryCard(
            isLoading: false,
            isConfirmed: false,
            onScan: _noop,
            onConfirm: _noop,
            onReject: _noop,
            onCancelService: _noop,
            summary: StaffServiceSummary(
              businessId: 'business-id',
              customer: StaffServiceCustomer(
                id: 'customer-id',
                fullName: 'Customer One',
                role: 'customer',
                isActive: true,
              ),
              points: 2,
              activeRewards: [],
              recentActions: [],
            ),
          ),
        ),
      ),
    );
    await pumpAppFrames(tester);

    expect(find.text('Customer One'), findsOneWidget);
    expect(find.text('customer@example.com'), findsNothing);
    expect(find.text('Confirm'), findsWidgets);
    expect(find.text('Confirm customer'), findsNothing);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('0 active rewards'), findsOneWidget);
    expect(find.text('0 recent actions'), findsNothing);
    expect(find.text('No customer actions yet'), findsNothing);
  });

  testWidgets('renders staff customer recent actions card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StaffCustomerRecentActionsCard(
            actions: [
              StaffRecentAction(
                id: 'action-id',
                actionType: 'mission_progress',
                customerName: 'Customer One',
                pointsGranted: 2,
                summary: 'Buy Coffee x2',
                occurredAt: DateTime(2026, 1, 1, 10, 30),
                createdAt: DateTime(2026, 1, 1, 10, 30),
              ),
              StaffRecentAction(
                id: 'reward-use-id',
                actionType: 'reward_use',
                customerName: 'Customer One',
                pointsGranted: 0,
                summary: 'Reward used',
                occurredAt: DateTime(2026, 1, 1, 11, 30),
                createdAt: DateTime(2026, 1, 1, 11, 30),
              ),
            ],
          ),
        ),
      ),
    );
    await pumpAppFrames(tester);

    expect(find.text('Customer recent actions'), findsOneWidget);
    expect(find.text('Buy Coffee x2'), findsOneWidget);
    expect(find.text('+2 pts'), findsOneWidget);
    expect(find.text('Reward used'), findsWidgets);
  });

  testWidgets('renders empty staff customer recent actions card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StaffCustomerRecentActionsCard(actions: [])),
      ),
    );
    await pumpAppFrames(tester);

    expect(find.text('Customer recent actions'), findsOneWidget);
    expect(find.text('No customer actions yet'), findsOneWidget);
  });

  testWidgets('renders compact staff mission card copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StaffMissionCard(
            missions: [
              StaffServiceMission(
                id: 'coffee',
                name: 'Buy Coffee',
                description: null,
                missionType: 'purchase',
                pointValue: 1,
                isActive: true,
              ),
              StaffServiceMission(
                id: 'cake',
                name: 'Buy Cake',
                description: null,
                missionType: 'purchase',
                pointValue: 5,
                isActive: true,
              ),
            ],
            quantities: {},
            isLoading: false,
            isEnabled: true,
            selectedPoints: 0,
            onIncrement: _noopMission,
            onDecrement: _noopMission,
            onSubmit: _noop,
            isSubmitting: false,
          ),
        ),
      ),
    );
    await pumpAppFrames(tester);

    expect(find.text('Register mission action'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('0 pts'), findsOneWidget);
    expect(find.text('1 point'), findsOneWidget);
    expect(find.text('5 points'), findsOneWidget);
    expect(find.text('1 points each'), findsNothing);
  });

  testWidgets('renders compact staff reward action copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RewardCard(
            title: 'Free Coffee',
            subtitle: 'Free coffee',
            expiresLabel: 'Valid until 2027-01-01',
            variant: RewardCardVariant.staffAction,
            onUse: _noop,
          ),
        ),
      ),
    );
    await pumpAppFrames(tester);

    expect(find.text('Use'), findsOneWidget);
    expect(find.text('Use Reward'), findsNothing);
  });
}

void _noop() {}

void _noopMission(StaffServiceMission mission) {}

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
  String? _refreshToken;

  @override
  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
  }

  @override
  Future<String?> readAccessToken() async {
    return _token;
  }

  @override
  Future<String?> readRefreshToken() async {
    return _refreshToken;
  }

  @override
  Future<void> writeAccessToken(String token) async {
    _token = token;
  }

  @override
  Future<void> writeRefreshToken(String token) async {
    _refreshToken = token;
  }

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _token = accessToken;
    _refreshToken = refreshToken;
  }
}

class _ExpiredSessionMessageNotifier extends SessionExpiredMessageNotifier {
  @override
  String? build() => 'Your session expired. Please sign in again.';
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

  @override
  Future<List<StaffRecentAction>> listRecentActions({
    required String businessId,
  }) async {
    return const [];
  }
}

class _FakeCustomerQrRepository extends CustomerQrRepository {
  _FakeCustomerQrRepository() : super(Dio(), _MemoryCustomerQrTokenStore());

  CustomerQrToken? _cachedToken;
  int issueCount = 0;

  @override
  Future<CustomerQrToken?> readCachedToken() async {
    return _cachedToken;
  }

  @override
  Future<CustomerQrToken> issueToken() async {
    issueCount += 1;
    _cachedToken = CustomerQrToken(
      token: 'qr-token',
      qrPayload: 'qr-token',
      expiresAt: DateTime(2027),
    );
    return _cachedToken!;
  }

  @override
  Future<CustomerQrToken> rotateToken() async {
    _cachedToken = CustomerQrToken(
      token: 'rotated-qr-token',
      qrPayload: 'rotated-qr-token',
      expiresAt: DateTime(2027),
    );
    return _cachedToken!;
  }

  @override
  Future<void> clearCachedToken() async {
    _cachedToken = null;
  }

  @override
  Future<CustomerStatus> getStatus() async {
    return CustomerStatus(
      customerId: 'customer-id',
      activeRewardsCount: 1,
      hasEarnedFirstPoint: true,
      hasEarnedFirstReward: true,
      hasUsedFirstReward: true,
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
            CustomerReward(
              id: 'used-reward-id',
              title: 'Used Coffee',
              description: null,
              rewardType: 'gift',
              status: 'used',
              giftName: 'Used coffee',
              discountPercent: null,
              discountAmountMinor: null,
              currencyCode: null,
              expiresAt: DateTime(2027),
              usedAt: DateTime(2026, 1, 2),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<List<CustomerCampaignProgress>> getCampaignProgresses() async {
    return [
      CustomerCampaignProgress(
        businessId: 'business-id',
        businessName: 'Zomia Cafe',
        campaignId: 'campaign-id',
        campaignName: 'Coffee Reward',
        startsAt: DateTime.utc(2026, 6, 14),
        endsAt: DateTime.utc(2026, 9, 14),
        progressPoints: 2,
        thresholdPoints: 10,
        remainingPoints: 8,
        isCompleted: false,
        isRepeatable: false,
        completedCycles: 0,
        currentCycleNumber: 1,
        maxCompletionsPerCustomer: null,
        campaignTimeStatus: 'active',
        progressState: 'in_progress',
        displayLabel: '2/10 pts · 8 pts to reward',
        badgeLabel: 'Active',
        badgeTone: 'info',
      ),
      CustomerCampaignProgress(
        businessId: 'business-id',
        businessName: 'Zomia Cafe',
        campaignId: 'completed-campaign-id',
        campaignName: 'Completed Coffee',
        startsAt: DateTime.utc(2026, 6, 14),
        endsAt: DateTime.utc(2026, 9, 14),
        progressPoints: 10,
        thresholdPoints: 10,
        remainingPoints: 0,
        isCompleted: true,
        isRepeatable: false,
        completedCycles: 1,
        currentCycleNumber: 1,
        maxCompletionsPerCustomer: null,
        campaignTimeStatus: 'active',
        progressState: 'completed',
        displayLabel: '10/10 pts · Completed',
        badgeLabel: 'Completed',
        badgeTone: 'success',
      ),
    ];
  }
}

class _MemoryCustomerQrTokenStore implements CustomerQrTokenStore {
  CustomerQrToken? _token;

  @override
  Future<void> clear() async {
    _token = null;
  }

  @override
  Future<CustomerQrToken?> readToken() async {
    return _token;
  }

  @override
  Future<void> writeToken(CustomerQrToken token) async {
    _token = token;
  }
}

class _FakeOwnerSetupRepository extends OwnerSetupRepository {
  _FakeOwnerSetupRepository() : super(Dio());

  bool _staffIsActive = true;
  bool _hasPendingInvitation = true;
  bool? createdCampaignIsRepeatable;
  int? createdCampaignMaxCompletions;
  DateTime? createdCampaignStartsAt;
  DateTime? createdCampaignEndsAt;
  String businessName = 'Zomia Cafe';
  String? updatedBusinessCategory;
  String? updatedBusinessPublicEmail;

  @override
  Future<List<OwnerBusiness>> listBusinesses() async {
    return [
      OwnerBusiness(
        id: 'business-id',
        ownerId: 'owner-id',
        name: businessName,
        legalName: null,
        slug: 'zomia-cafe',
        category: updatedBusinessCategory ?? 'cafe',
        publicEmail: updatedBusinessPublicEmail ?? 'hello@zomia.example',
        publicPhone: '+491234567',
        websiteUrl: 'https://zomia.example',
        addressLine1: 'Main Street 1',
        addressLine2: null,
        city: 'Berlin',
        region: 'Berlin',
        postalCode: '10115',
        countryCode: 'DE',
        timezone: 'Europe/Berlin',
        status: 'active',
        currencyCode: 'EUR',
      ),
    ];
  }

  @override
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
    businessName = name;
    updatedBusinessCategory = category;
    updatedBusinessPublicEmail = publicEmail;
    return (await listBusinesses()).first;
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
        canEdit: true,
        canDelete: true,
        canArchive: false,
      ),
    ];
  }

  @override
  Future<List<OwnerStaffMember>> listStaff() async {
    return [
      OwnerStaffMember(
        id: 'staff-member-id',
        businessId: 'business-id',
        userId: 'staff-user-id',
        staffMemberId: 'staff-member-id',
        invitationId: null,
        email: 'setup-staff@example.com',
        fullName: 'Setup Staff',
        status: _staffIsActive ? 'active' : 'inactive',
        isActive: _staffIsActive,
      ),
      if (_hasPendingInvitation)
        const OwnerStaffMember(
          id: 'staff-invitation-id',
          businessId: 'business-id',
          userId: null,
          staffMemberId: null,
          invitationId: 'staff-invitation-id',
          email: 'pending-staff@example.com',
          fullName: null,
          status: 'pending',
          isActive: false,
        ),
    ];
  }

  @override
  Future<void> setStaffActive({
    required String staffMemberId,
    required bool isActive,
  }) async {
    _staffIsActive = isActive;
  }

  @override
  Future<void> cancelStaffInvitation({required String invitationId}) async {
    _hasPendingInvitation = false;
  }

  @override
  Future<List<OwnerCampaign>> listCampaigns(String businessId) async {
    return [
      OwnerCampaign(
        id: 'campaign-id',
        rewardTemplateId: 'template-id',
        name: 'Coffee Reward',
        thresholdPoints: 10,
        isRepeatable: false,
        maxCompletionsPerCustomer: null,
        status: 'active',
        startsAt: DateTime(2026),
        endsAt: DateTime(2027),
        timeStatus: 'active',
        displayStatus: 'Active',
        badgeTone: 'info',
        dateRangeLabel: '2026-01-01 - 2027-01-01',
      ),
    ];
  }

  @override
  Future<OwnerLoyaltySummary> getLoyaltySummary(String businessId) async {
    return const OwnerLoyaltySummary(
      participatingCustomerCount: 1,
      rewardsIssuedCount: 0,
      rewardsReadyToUseCount: 0,
      rewardsUsedCount: 0,
      rewardsExpiredCount: 0,
    );
  }

  @override
  Future<void> createCampaign({
    required String businessId,
    required String rewardTemplateId,
    required String name,
    required int thresholdPoints,
    required DateTime startsAt,
    required DateTime endsAt,
    required List<String> missionIds,
    required bool isRepeatable,
    int? maxCompletionsPerCustomer,
  }) async {
    createdCampaignIsRepeatable = isRepeatable;
    createdCampaignMaxCompletions = maxCompletionsPerCustomer;
    createdCampaignStartsAt = startsAt;
    createdCampaignEndsAt = endsAt;
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
        canEdit: true,
        canDelete: true,
        canArchive: false,
      ),
    ];
  }

  @override
  Future<List<OwnerActivity>> listRecentActivity({
    required String businessId,
    int limit = 20,
  }) async {
    return [
      OwnerActivity(
        actionId: 'action-id',
        businessId: businessId,
        actionType: 'mission_progress',
        staffName: 'Staff One',
        staffEmail: 'staff@example.com',
        customerName: 'Customer One',
        customerEmail: 'customer@example.com',
        pointsGranted: 2,
        summary: 'Buy Coffee x2',
        createdAt: DateTime(2026, 1, 1, 10, 30),
      ),
    ];
  }
}

class _EmptyOwnerSetupRepository extends _FakeOwnerSetupRepository {
  @override
  Future<List<OwnerActivity>> listRecentActivity({
    required String businessId,
    int limit = 20,
  }) async {
    return const [];
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.role = 'staff'}) : super(Dio());

  final String role;
  bool startedCustomerRegistration = false;
  bool verifiedCustomerRegistration = false;
  bool startedOwnerRegistration = false;
  bool verifiedOwnerRegistration = false;
  bool startedPasswordRecovery = false;
  bool verifiedPasswordRecovery = false;
  bool completedPasswordRecovery = false;
  bool changedPassword = false;
  bool startedEmailChange = false;
  bool verifiedEmailChange = false;
  bool removedAccount = false;
  String? ownerBusinessName;
  String? ownerBusinessCategory;
  String? updatedCustomerName;
  String? completedNewPassword;
  String? changedCurrentPassword;
  String? changedNewPassword;
  String? emailChangeNewEmail;
  String? emailChangeCurrentPassword;
  String? currentEmail;
  String? removedAccountCurrentPassword;
  int refreshCount = 0;
  String? loggedOutRefreshToken;

  @override
  Future<void> startCustomerRegistration({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    startedCustomerRegistration = true;
  }

  @override
  Future<AuthTokens> verifyCustomerRegistration({
    required String email,
    required String code,
  }) async {
    verifiedCustomerRegistration = true;
    return const AuthTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
  }

  @override
  Future<void> startOwnerRegistration({
    required String businessName,
    required String? businessCategory,
    required String email,
    required String password,
  }) async {
    startedOwnerRegistration = true;
    ownerBusinessName = businessName;
    ownerBusinessCategory = businessCategory;
  }

  @override
  Future<AuthTokens> verifyOwnerRegistration({
    required String email,
    required String code,
  }) async {
    verifiedOwnerRegistration = true;
    return const AuthTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
  }

  @override
  Future<void> startPasswordRecovery({required String email}) async {
    startedPasswordRecovery = true;
  }

  @override
  Future<String> verifyPasswordRecovery({
    required String email,
    required String code,
  }) async {
    verifiedPasswordRecovery = true;
    return 'reset-token';
  }

  @override
  Future<void> completePasswordRecovery({
    required String resetToken,
    required String newPassword,
  }) async {
    completedPasswordRecovery = true;
    completedNewPassword = newPassword;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changedPassword = true;
    changedCurrentPassword = currentPassword;
    changedNewPassword = newPassword;
  }

  @override
  Future<void> startEmailChange({
    required String newEmail,
    required String currentPassword,
  }) async {
    startedEmailChange = true;
    emailChangeNewEmail = newEmail;
    emailChangeCurrentPassword = currentPassword;
  }

  @override
  Future<CurrentUser> verifyEmailChange({
    required String newEmail,
    required String code,
  }) async {
    verifiedEmailChange = true;
    currentEmail = newEmail;
    return CurrentUser(
      id: '$role-id',
      email: newEmail,
      fullName: switch (role) {
        'owner' => 'Owner One',
        'staff' => 'Staff One',
        _ => updatedCustomerName ?? 'Customer One',
      },
      role: role,
      isActive: true,
    );
  }

  @override
  Future<void> removeAccount({required String currentPassword}) async {
    removedAccount = true;
    removedAccountCurrentPassword = currentPassword;
  }

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    return const AuthTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
  }

  @override
  Future<AuthTokens> refreshSession({required String refreshToken}) async {
    refreshCount += 1;
    return const AuthTokens(
      accessToken: 'refreshed-access-token',
      refreshToken: 'refreshed-refresh-token',
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    loggedOutRefreshToken = refreshToken;
  }

  @override
  Future<CurrentUser> updateCustomerProfile({required String fullName}) async {
    updatedCustomerName = fullName;
    return CurrentUser(
      id: '$role-id',
      email: currentEmail ?? '$role@example.com',
      fullName: fullName,
      role: role,
      isActive: true,
    );
  }

  @override
  Future<CurrentUser> getCurrentUser() async {
    return CurrentUser(
      id: '$role-id',
      email: currentEmail ?? '$role@example.com',
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
