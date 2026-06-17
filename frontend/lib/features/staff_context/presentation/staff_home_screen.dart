import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../staff_service/data/staff_service_repository.dart';
import '../../staff_service/domain/staff_service_models.dart';
import '../../staff_service/presentation/staff_panel.dart';
import '../../staff_service/presentation/staff_service_cards.dart';
import '../domain/staff_context.dart';

class StaffHomeScreen extends ConsumerStatefulWidget {
  const StaffHomeScreen({
    super.key,
    required this.staff,
    required this.business,
  });

  final StaffUser staff;
  final StaffBusiness business;

  @override
  ConsumerState<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends ConsumerState<StaffHomeScreen> {
  final _servicePanelKey = GlobalKey<StaffPanelState>();
  List<StaffRecentAction> _recentActions = const [];
  int _selectedIndex = 0;
  bool _isLoadingRecentActions = true;
  String? _recentActionsError;

  static const _tabs = [
    NavItem(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    NavItem(
      label: 'Recent Actions',
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
    ),
    NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecentActions());
  }

  @override
  void didUpdateWidget(covariant StaffHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id) {
      _recentActions = const [];
      _loadRecentActions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: _selectedIndex == 0
            ? 'Staff Dashboard'
            : _tabs[_selectedIndex].label,
        variant: AppTopBarVariant.business,
        onMenu: () {},
        actions: [
          IconButton(
            tooltip: 'Scan customer QR',
            onPressed: () => _servicePanelKey.currentState?.scanQrFromTopBar(),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            DashboardScroll(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BusinessHeader(
                    business: widget.business,
                    staff: widget.staff,
                  ),
                  const SizedBox(height: 16),
                  StaffPanel(
                    key: _servicePanelKey,
                    business: widget.business,
                    onServiceActivityChanged: _loadRecentActions,
                  ),
                ],
              ),
            ),
            DashboardScroll(
              child: StaffRecentActionsCard(
                actions: _recentActions,
                isLoading: _isLoadingRecentActions,
                errorMessage: _recentActionsError,
                onRetry: _loadRecentActions,
              ),
            ),
            DashboardScroll(
              child: _StaffProfileCard(
                staff: widget.staff,
                business: widget.business,
                onSignOut: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        items: _tabs,
        selectedIndex: _selectedIndex,
        onChanged: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            _loadRecentActions();
          }
        },
      ),
    );
  }

  Future<void> _loadRecentActions() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingRecentActions = true;
      _recentActionsError = null;
    });
    try {
      final actions = await ref
          .read(staffServiceRepositoryProvider)
          .listRecentActions(businessId: widget.business.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _recentActions = actions;
        _isLoadingRecentActions = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _recentActionsError = error.toString();
        _isLoadingRecentActions = false;
      });
    }
  }
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({required this.business, required this.staff});

  final StaffBusiness business;
  final StaffUser staff;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(business.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Signed in as ${staff.fullName}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetricPill(
                icon: Icons.storefront_rounded,
                label: business.currencyCode,
                color: Theme.of(context).colorScheme.primary,
              ),
              MetricPill(
                icon: Icons.schedule_rounded,
                label: business.timezone,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffProfileCard extends StatelessWidget {
  const _StaffProfileCard({
    required this.staff,
    required this.business,
    required this.onSignOut,
  });

  final StaffUser staff;
  final StaffBusiness business;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Profile'),
          const SizedBox(height: 12),
          AppListRow(
            title: staff.fullName,
            subtitle: staff.email,
            leadingIcon: Icons.person_rounded,
          ),
          const SizedBox(height: 12),
          AppListRow(
            title: business.name,
            subtitle: '${business.currencyCode} · ${business.timezone}',
            leadingIcon: Icons.storefront_rounded,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
              style: TextButton.styleFrom(
                foregroundColor: BrandColors.textSecondary,
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
