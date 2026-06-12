import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/ui.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../staff_service/domain/staff_service_models.dart';
import '../../staff_service/presentation/staff_service_panel.dart';
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
  final _servicePanelKey = GlobalKey<StaffServicePanelState>();
  List<StaffRecentAction> _recentActions = const [];
  int _selectedIndex = 0;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Staff Dashboard',
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
            _DashboardScroll(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BusinessHeader(
                    business: widget.business,
                    staff: widget.staff,
                  ),
                  const SizedBox(height: 16),
                  StaffServicePanel(
                    key: _servicePanelKey,
                    business: widget.business,
                    onSummaryChanged: _handleSummaryChanged,
                  ),
                ],
              ),
            ),
            _DashboardScroll(
              child: StaffRecentActionsCard(actions: _recentActions),
            ),
            _DashboardScroll(
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
        onChanged: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  void _handleSummaryChanged(StaffServiceSummary? summary) {
    setState(() => _recentActions = summary?.recentActions ?? const []);
  }
}

class _DashboardScroll extends StatelessWidget {
  const _DashboardScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: child,
          ),
        ),
      ],
    );
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
          const SectionHeader(
            title: 'Profile',
            subtitle: 'Staff context for the current service session.',
          ),
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
          SecondaryButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}
