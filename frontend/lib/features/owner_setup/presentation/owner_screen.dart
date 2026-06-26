import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                label: 'MStV',
                icon: Icons.article_outlined,
                onTap: () => _openDrawerInfoDialog(
                  title: 'MStV',
                  message:
                      'MStV information will be completed before production.',
                ),
              ),
              AppDrawerItem(
                label: 'Impressum',
                icon: Icons.info_outline_rounded,
                onTap: () => _openDrawerInfoDialog(
                  title: 'Impressum',
                  message:
                      'Impressum information will be completed before production.',
                ),
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
                tooltip: 'Staff recent actions',
                onPressed: _openRecentActionsDialog,
                icon: const Icon(Icons.history_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                DashboardScroll(maxWidth: 760, child: _buildHomeView()),
                DashboardScroll(maxWidth: 760, child: _buildCampaignView()),
                DashboardScroll(maxWidth: 760, child: _buildTeamView()),
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

  Widget _buildHomeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_controller.error != null)
          InlineBanner(
            message: _controller.error!,
            tone: BannerTone.error,
            onClose: _controller.clearError,
          ),
        if (_controller.success != null)
          InlineBanner(
            message: _controller.success!,
            tone: BannerTone.success,
            onClose: _controller.clearSuccess,
          ),
        if (_controller.error != null || _controller.success != null)
          const SizedBox(height: 16),
        if (_controller.isLoading)
          const AppCard(child: LoadingState(label: 'Loading owner setup'))
        else if (_controller.businesses.isEmpty)
          const AppCard(
            child: EmptyStateView(
              icon: Icons.store_outlined,
              title: 'No business found',
              message: 'Create the owner business from the backend for now.',
            ),
          )
        else ...[
          OwnerBusinessPicker(
            businesses: _controller.businesses,
            selectedBusiness: _controller.selectedBusiness,
            onChanged: _controller.selectBusiness,
          ),
        ],
      ],
    );
  }

  Widget _buildCampaignView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_controller.error != null)
          InlineBanner(
            message: _controller.error!,
            tone: BannerTone.error,
            onClose: _controller.clearError,
          ),
        if (_controller.success != null)
          InlineBanner(
            message: _controller.success!,
            tone: BannerTone.success,
            onClose: _controller.clearSuccess,
          ),
        if (_controller.error != null || _controller.success != null)
          const SizedBox(height: 16),
        if (_controller.isLoading)
          const AppCard(child: LoadingState(label: 'Loading campaigns'))
        else if (_controller.businesses.isEmpty)
          const AppCard(
            child: EmptyStateView(
              icon: Icons.store_outlined,
              title: 'No business found',
              message: 'Create the owner business from the backend for now.',
            ),
          )
        else ...[
          OwnerMissionListCard(missions: _controller.missions),
          const SizedBox(height: 16),
          OwnerRewardTemplateListCard(
            rewardTemplates: _controller.rewardTemplates,
          ),
          const SizedBox(height: 16),
          OwnerCampaignListCard(campaigns: _controller.campaigns),
        ],
      ],
    );
  }

  Widget _buildTeamView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_controller.error != null)
          InlineBanner(
            message: _controller.error!,
            tone: BannerTone.error,
            onClose: _controller.clearError,
          ),
        if (_controller.success != null)
          InlineBanner(
            message: _controller.success!,
            tone: BannerTone.success,
            onClose: _controller.clearSuccess,
          ),
        if (_controller.error != null || _controller.success != null)
          const SizedBox(height: 16),
        if (_controller.isLoading)
          const AppCard(child: LoadingState(label: 'Loading staff'))
        else if (_controller.businesses.isEmpty)
          const AppCard(
            child: EmptyStateView(
              icon: Icons.store_outlined,
              title: 'No business found',
              message: 'Create the owner business from the backend for now.',
            ),
          )
        else
          OwnerStaffListCard(
            staffMembers: _controller.staffForSelectedBusiness,
            isSaving: _controller.isSaving,
            onSetStaffActive: _controller.setStaffActive,
          ),
      ],
    );
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
            emailController: _controller.staffEmailController,
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
                onOpenAccountSettings: _openAccountSettingsDialog,
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

  void _openDrawerInfoDialog({required String title, required String message}) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) =>
            AppDrawerInfoDialog(title: title, message: message),
      ),
    );
  }
}
