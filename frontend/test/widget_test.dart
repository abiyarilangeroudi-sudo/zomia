import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zomia_frontend/app/router.dart';
import 'package:zomia_frontend/app/ui/app_text_field.dart';
import 'package:zomia_frontend/app/ui/confirm_dialog.dart';
import 'package:zomia_frontend/app/ui/status_badge.dart';
import 'package:zomia_frontend/app/zomia_app.dart';
import 'package:zomia_frontend/core/http/api_client.dart';
import 'package:zomia_frontend/core/storage/secure_token_store.dart';
import 'package:zomia_frontend/features/auth/data/auth_repository.dart';
import 'package:zomia_frontend/features/auth/domain/current_user.dart';
import 'package:zomia_frontend/features/customer_qr/data/customer_qr_repository.dart';
import 'package:zomia_frontend/features/customer_qr/data/customer_qr_token_store.dart';
import 'package:zomia_frontend/features/customer_qr/domain/customer_status.dart';
import 'package:zomia_frontend/features/customer_qr/domain/customer_qr_token.dart';
import 'package:zomia_frontend/features/customer_qr/presentation/customer_presenter.dart';
import 'package:zomia_frontend/features/owner_setup/data/owner_setup_repository.dart';
import 'package:zomia_frontend/features/owner_setup/domain/owner_setup_models.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_presenter.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_setup_controller.dart';
import 'package:zomia_frontend/features/owner_setup/presentation/owner_profile_widgets.dart';
import 'package:zomia_frontend/features/staff_service/data/staff_service_repository.dart';
import 'package:zomia_frontend/features/staff_service/domain/qr_token_input.dart';
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
      mapStaffServiceErrorDetail('Custom backend detail'),
      'Custom backend detail',
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
      'Custom customer detail',
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
      mapOwnerSetupErrorDetail('Custom owner detail'),
      'Custom owner detail',
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
    expect(mapAuthErrorDetail('Custom auth detail'), 'Custom auth detail');
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
      'Action registered.',
    );
  });

  test(
    'customer presenter returns active reward entries with business name',
    () {
      final status = CustomerStatus(
        customerId: 'customer-id',
        activeRewardsCount: 1,
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
    },
  );

  test('customer presenter maps backend badge tone tokens', () {
    expect(customerBadgeTone('success'), BadgeTone.success);
    expect(customerBadgeTone('warning'), BadgeTone.warning);
    expect(customerBadgeTone('neutral'), BadgeTone.neutral);
    expect(customerBadgeTone('unknown'), BadgeTone.info);
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
        ),
      ),
      '10 pts · repeatable · unlimited within dates · active',
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

    expect(presentation.badgeLabel, 'reward use');
    expect(presentation.badgeTone, BadgeTone.neutral);
    expect(presentation.subtitle, contains('Customer One · Staff One'));
  });

  test('owner presenter maps staff toggle confirmation', () {
    final presentation = ownerStaffTogglePresentation(false);

    expect(presentation.title, 'Deactivate Staff?');
    expect(presentation.confirmLabel, 'Deactivate');
    expect(presentation.tone, ConfirmTone.destructive);
  });

  test('owner campaign creation defaults to repeatable unlimited', () async {
    final repository = _FakeOwnerSetupRepository();
    final controller = OwnerSetupController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();
    await controller.createCampaign();

    expect(repository.createdCampaignIsRepeatable, isTrue);
    expect(repository.createdCampaignMaxCompletions, isNull);
    expect(repository.createdCampaignStartsAt, isNotNull);
    expect(repository.createdCampaignEndsAt, isNotNull);
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
    controller.setCampaignCompletionLimit(true);
    controller.campaignMaxCompletionsController.text = '1';
    await controller.createCampaign();

    expect(controller.error, 'Completion limit must be at least 2.');
    expect(repository.createdCampaignIsRepeatable, isNull);

    controller.campaignMaxCompletionsController.text = '2';
    await controller.createCampaign();

    expect(repository.createdCampaignIsRepeatable, isTrue);
    expect(repository.createdCampaignMaxCompletions, 2);
  });

  test('owner campaign creation validates date range', () async {
    final repository = _FakeOwnerSetupRepository();
    final controller = OwnerSetupController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();
    controller.setCampaignStartDate(DateTime(2026, 9, 14));
    controller.setCampaignEndDate(DateTime(2026, 6, 14));
    await controller.createCampaign();

    expect(controller.error, 'Enter a valid campaign date range.');
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
    expect(find.text('Version 1.0.70 (71)'), findsOneWidget);
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

    await tester.tap(find.text('Version 1.0.70 (71)'));
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
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Hi, Customer One'), findsOneWidget);
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
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Zomia Cafe'), findsWidgets);
    expect(find.text('Signed in as Staff One'), findsOneWidget);
    expect(find.byTooltip('Scan customer QR'), findsOneWidget);
    expect(find.text('Customer QR'), findsNothing);
    expect(find.text('Scan with Camera'), findsNothing);
    expect(find.text('No customer loaded'), findsOneWidget);
    expect(find.text('Buy Coffee'), findsNothing);
    expect(find.text('Active Rewards'), findsNothing);
    expect(find.text('Register Action'), findsNothing);

    await tester.tap(find.text('Recent Actions'));
    await pumpAppFrames(tester);

    expect(find.text('Recent Actions'), findsWidgets);
    expect(find.text('Staff recent actions'), findsOneWidget);
    expect(find.text('No staff actions yet'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await pumpAppFrames(tester);

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Staff One'), findsOneWidget);
    expect(find.text('staff@example.com'), findsOneWidget);
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
    expect(find.text('Home'), findsWidgets);
    expect(find.byTooltip('Show QR code'), findsOneWidget);
    expect(find.text('Hi, Customer One'), findsOneWidget);
    expect(find.text('1 active campaigns'), findsOneWidget);
    expect(find.text('1 active rewards'), findsOneWidget);
    expect(find.text('Ready for your next visit'), findsOneWidget);
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
    expect(find.text('Active'), findsWidgets);

    await tester.tap(find.text('Archive'));
    await pumpAppFrames(tester);

    expect(find.text('Free Coffee'), findsNothing);
    expect(find.text('Used Coffee'), findsOneWidget);
    expect(find.text('Used'), findsOneWidget);

    await tester.tap(find.byTooltip('Menu'));
    await pumpAppFrames(tester);

    expect(find.text('Customer One'), findsNothing);
    expect(find.text('customer@example.com'), findsNothing);
    expect(find.text('Setting'), findsOneWidget);
    expect(find.text('MStV'), findsOneWidget);
    expect(find.text('Impressum'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

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
    expect(find.text('Refresh QR token'), findsOneWidget);
    expect(find.text('qr-token'), findsOneWidget);

    await tester.tap(find.text('Refresh QR token'));
    await pumpAppFrames(tester);

    expect(find.text('rotated-qr-token'), findsOneWidget);
    expect(find.text('qr-token'), findsNothing);
    expect(find.text('Old QR is invalid.'), findsOneWidget);
  });

  testWidgets('signs in and renders owner setup screen', (tester) async {
    final tokenStore = _MemoryTokenStore();
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
    expect(find.text('Zomia Cafe'), findsWidgets);
    expect(find.byTooltip('Staff recent actions'), findsOneWidget);
    expect(find.text('Create Mission'), findsNothing);
    expect(find.text('Buy Coffee'), findsNothing);

    await tester.tap(find.text('Loyalty'));
    await pumpAppFrames(tester);

    expect(find.text('Missions'), findsOneWidget);
    expect(find.text('Campaigns'), findsOneWidget);
    expect(find.text('Reward Templates'), findsOneWidget);
    expect(find.text('Coffee Reward'), findsWidgets);
    expect(find.text('10 pts · non-repeatable · active'), findsOneWidget);
    expect(find.text('Free Coffee'), findsWidgets);
    expect(find.text('Free coffee · 30 days'), findsOneWidget);

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
    expect(find.text('Setup Staff'), findsOneWidget);
    expect(find.text('setup-staff@example.com'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.byTooltip('Deactivate staff'), findsOneWidget);
    expect(find.byTooltip('Create staff'), findsOneWidget);

    await tester.tap(find.byTooltip('Create staff'));
    await pumpAppFrames(tester);

    expect(find.text('Create Staff'), findsWidgets);
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

    await tester.tap(find.text('Profile'));
    await pumpAppFrames(tester);

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.text('Create Staff'), findsNothing);

    await tester.tap(find.byTooltip('Staff recent actions'));
    await pumpAppFrames(tester);

    expect(find.text('Staff Recent Actions'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
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

    expect(find.text('Staff Recent Actions'), findsOneWidget);
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
            onConfirm: _noop,
            onReject: _noop,
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
    expect(find.text('Confirm customer'), findsWidgets);
    expect(find.text('Reject'), findsOneWidget);
  });
}

void _noop() {}

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
  bool? createdCampaignIsRepeatable;
  int? createdCampaignMaxCompletions;
  DateTime? createdCampaignStartsAt;
  DateTime? createdCampaignEndsAt;

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
    return [
      OwnerStaffMember(
        id: 'staff-member-id',
        businessId: 'business-id',
        userId: 'staff-user-id',
        isActive: _staffIsActive,
        user: const OwnerStaffUser(
          id: 'staff-user-id',
          email: 'setup-staff@example.com',
          fullName: 'Setup Staff',
          isActive: true,
        ),
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
      ),
    ];
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
  bool registeredCustomer = false;
  String? updatedCustomerName;

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
  Future<CurrentUser> updateCustomerProfile({required String fullName}) async {
    updatedCustomerName = fullName;
    return CurrentUser(
      id: '$role-id',
      email: '$role@example.com',
      fullName: fullName,
      role: role,
      isActive: true,
    );
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
