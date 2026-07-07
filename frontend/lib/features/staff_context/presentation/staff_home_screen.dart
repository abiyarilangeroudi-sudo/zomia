import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/external_url_launcher.dart';
import '../../../app/ui/ui.dart';
import '../../auth/presentation/account_settings_dialog.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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
      key: _scaffoldKey,
      drawer: AppDrawer(
        items: [
          AppDrawerItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            onTap: _openProfileFromDrawer,
          ),
          AppDrawerItem(
            label: 'Setting',
            icon: Icons.settings_outlined,
            onTap: _openAccountSettingsFromDrawer,
          ),
          AppDrawerItem(
            label: 'Legal',
            icon: Icons.policy_outlined,
            onTap: _openLegalFromDrawer,
          ),
          AppDrawerItem(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            onTap: _signOutFromDrawer,
          ),
        ],
      ),
      appBar: AppTopBar(
        title: _selectedIndex == 0
            ? 'Staff Dashboard'
            : _tabs[_selectedIndex].label,
        variant: AppTopBarVariant.business,
        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
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
            RefreshIndicator(
              onRefresh: _loadRecentActions,
              child: DashboardScroll(
                physics: const AlwaysScrollableScrollPhysics(),
                child: StaffRecentActionsCard(
                  actions: _recentActions,
                  isLoading: _isLoadingRecentActions,
                  errorMessage: _recentActionsError,
                  onClearError: _clearRecentActionsError,
                  onRetry: _loadRecentActions,
                ),
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

  void _openAccountSettingsDialog() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => AccountSettingsDialog(
          onChangePassword:
              ({
                required String currentPassword,
                required String newPassword,
              }) => ref
                  .read(authControllerProvider.notifier)
                  .changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                  ),
        ),
      ),
    );
  }

  void _clearRecentActionsError() {
    if (_recentActionsError == null) {
      return;
    }
    setState(() => _recentActionsError = null);
  }

  void _openProfileFromDrawer() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: const AppTopBar(
            title: 'Profile',
            variant: AppTopBarVariant.modal,
          ),
          body: SafeArea(
            child: DashboardScroll(
              maxWidth: 640,
              child: _StaffProfileCard(
                staff: widget.staff,
                business: widget.business,
                onUpdateName: (fullName) => ref
                    .read(authControllerProvider.notifier)
                    .updateStaffProfile(fullName: fullName),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAccountSettingsFromDrawer() {
    Navigator.of(context).pop();
    _openAccountSettingsDialog();
  }

  void _signOutFromDrawer() {
    Navigator.of(context).pop();
    ref.read(authControllerProvider.notifier).signOut();
  }

  void _openLegalFromDrawer() {
    Navigator.of(context).pop();
    openExternalUrl('https://zomia.eu/legal');
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

class _StaffProfileCard extends StatefulWidget {
  const _StaffProfileCard({
    required this.staff,
    required this.business,
    required this.onUpdateName,
  });

  final StaffUser staff;
  final StaffBusiness business;
  final Future<void> Function(String fullName) onUpdateName;

  @override
  State<_StaffProfileCard> createState() => _StaffProfileCardState();
}

class _StaffProfileCardState extends State<_StaffProfileCard> {
  late String _displayName;

  @override
  void initState() {
    super.initState();
    _displayName = widget.staff.fullName;
  }

  @override
  void didUpdateWidget(covariant _StaffProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staff.fullName != widget.staff.fullName) {
      _displayName = widget.staff.fullName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Profile'),
          const SizedBox(height: 12),
          AppListRow(
            title: _displayName,
            subtitle: widget.staff.email,
            leadingIcon: Icons.person_rounded,
            trailing: IconButton(
              tooltip: 'Edit profile',
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _openEditProfile(context),
            ),
            onTap: () => _openEditProfile(context),
          ),
          const SizedBox(height: 12),
          AppListRow(
            title: widget.business.name,
            subtitle:
                '${widget.business.currencyCode} · ${widget.business.timezone}',
            leadingIcon: Icons.storefront_rounded,
          ),
        ],
      ),
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final updatedName = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (context) => _StaffEditProfileDialog(
          currentName: _displayName,
          onUpdateName: widget.onUpdateName,
        ),
      ),
    );
    if (!mounted || updatedName == null) {
      return;
    }
    setState(() => _displayName = updatedName);
  }
}

class _StaffEditProfileDialog extends StatefulWidget {
  const _StaffEditProfileDialog({
    required this.currentName,
    required this.onUpdateName,
  });

  final String currentName;
  final Future<void> Function(String fullName) onUpdateName;

  @override
  State<_StaffEditProfileDialog> createState() =>
      _StaffEditProfileDialogState();
}

class _StaffEditProfileDialogState extends State<_StaffEditProfileDialog> {
  late final TextEditingController _nameController;
  String? _error;
  String? _success;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Edit Profile',
        variant: AppTopBarVariant.service,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                InlineBanner(
                  message: _error!,
                  tone: BannerTone.error,
                  onClose: () => setState(() => _error = null),
                ),
              if (_success != null)
                InlineBanner(
                  message: _success!,
                  tone: BannerTone.success,
                  onClose: () => setState(() => _success = null),
                ),
              if (_error != null || _success != null)
                const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Name',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveName(),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Save profile',
                      icon: Icons.check_rounded,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveName,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    final nextName = _nameController.text.trim();
    if (nextName.length < 2) {
      setState(() {
        _error = 'Name must be at least 2 characters.';
        _success = null;
      });
      return;
    }
    if (nextName == widget.currentName) {
      setState(() {
        _error = null;
        _success = 'Profile is already up to date.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
      _success = null;
    });
    try {
      await widget.onUpdateName(nextName);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(nextName);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _error = error.toString();
      });
    }
  }
}
