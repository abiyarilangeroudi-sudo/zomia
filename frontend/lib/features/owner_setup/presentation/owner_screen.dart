import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/external_url_launcher.dart';
import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../../auth/presentation/account_settings_dialog.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/owner_setup_repository.dart';
import 'owner_setup_controller.dart';
import 'owner_setup_widgets.dart';

class OwnerScreen extends ConsumerStatefulWidget {
  const OwnerScreen({super.key, required this.user});

  final CurrentUser user;

  @override
  ConsumerState<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends ConsumerState<OwnerScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final OwnerSetupController _controller;
  int _selectedIndex = 0;
  int _campaignTabIndex = 0;

  static const _tabs = [
    NavItem(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    NavItem(
      label: 'Loyalty',
      icon: Icons.flag_outlined,
      activeIcon: Icons.flag_rounded,
    ),
    NavItem(
      label: 'Team',
      icon: Icons.group_outlined,
      activeIcon: Icons.group_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = OwnerSetupController(
      repository: ref.read(ownerSetupRepositoryProvider),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
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
            title: _appBarTitle,
            variant: AppTopBarVariant.business,
            onMenu: () => _scaffoldKey.currentState?.openDrawer(),
            actions: [
              IconButton(
                tooltip: 'Recent activity',
                onPressed: _openRecentActionsDialog,
                icon: const Icon(Icons.history_rounded),
              ),
            ],
            bottom: _selectedIndex == 1
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(51),
                    child: SegmentedTabs(
                      items: const ['Active', 'Archive'],
                      selectedIndex: _campaignTabIndex,
                      onChanged: (index) =>
                          setState(() => _campaignTabIndex = index),
                    ),
                  )
                : null,
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                RefreshIndicator(
                  onRefresh: _controller.load,
                  child: DashboardScroll(
                    maxWidth: 760,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: OwnerHomeView(
                      controller: _controller,
                      onCreateMission: () =>
                          openOwnerMissionCreateDialog(context, _controller),
                      onCreateRewardTemplate: () =>
                          openOwnerRewardTemplateCreateDialog(
                            context,
                            _controller,
                          ),
                      onCreateCampaign: () =>
                          openOwnerCampaignCreateDialog(context, _controller),
                      onInviteStaff: _openCreateStaffDialog,
                      onEditBusiness: _openBusinessSettingsDialog,
                    ),
                  ),
                ),
                DashboardScroll(
                  maxWidth: 760,
                  child: OwnerLoyaltyView(
                    controller: _controller,
                    campaignTabIndex: _campaignTabIndex,
                  ),
                ),
                DashboardScroll(
                  maxWidth: 760,
                  child: OwnerTeamView(
                    controller: _controller,
                    onInviteStaff: _openCreateStaffDialog,
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
          floatingActionButton: _selectedIndex == 1 && !_controller.isLoading
              ? FloatingCreateButton(
                  tooltip: 'Create loyalty item',
                  onPressed: () =>
                      openOwnerLoyaltyCreateDialog(context, _controller),
                )
              : _selectedIndex == 2 && !_controller.isLoading
              ? FloatingCreateButton(
                  tooltip: 'Invite staff',
                  onPressed: _openCreateStaffDialog,
                )
              : null,
        );
      },
    );
  }

  String get _appBarTitle {
    return switch (_selectedIndex) {
      0 => 'Owner Dashboard',
      1 => 'Loyalty',
      _ => 'Team',
    };
  }

  void _openRecentActionsDialog() {
    final selectedBusiness = _controller.selectedBusiness;
    if (selectedBusiness == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) =>
            OwnerRecentActionsDialog(businessId: selectedBusiness.id),
      ),
    );
  }

  void _openCreateStaffDialog() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => OwnerInviteStaffDialog(
            emailController: _controller.staffInvitationForm.emailController,
            errorMessage: _controller.error,
            onClearError: _controller.clearError,
            isSaving: _controller.isSaving,
            onSend: _controller.sendStaffInvitation,
          ),
        ),
      ),
    );
  }

  void _openBusinessSettingsDialog() {
    final business = _controller.selectedBusiness;
    if (business == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => OwnerBusinessSettingsDialog(
            business: business,
            errorMessage: _controller.error,
            onClearError: _controller.clearError,
            isSaving: _controller.isSaving,
            onSave: _controller.updateBusinessProfile,
          ),
        ),
      ),
    );
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
          onStartEmailChange:
              ({required String newEmail, required String currentPassword}) =>
                  ref
                      .read(authControllerProvider.notifier)
                      .startEmailChange(
                        newEmail: newEmail,
                        currentPassword: currentPassword,
                      ),
          onVerifyEmailChange:
              ({required String newEmail, required String code}) => ref
                  .read(authControllerProvider.notifier)
                  .verifyEmailChange(newEmail: newEmail, code: code),
        ),
      ),
    );
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
              child: OwnerProfileCard(
                user: widget.user,
                selectedBusiness: _controller.selectedBusiness,
                onOpenBusinessSettings: _controller.selectedBusiness == null
                    ? null
                    : _openBusinessSettingsDialog,
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
