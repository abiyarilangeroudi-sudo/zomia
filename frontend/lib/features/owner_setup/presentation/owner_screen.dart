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
    NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
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
          appBar: AppTopBar(
            title: _appBarTitle,
            variant: AppTopBarVariant.business,
            onMenu: () {},
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
                DashboardScroll(maxWidth: 760, child: _buildProfileView()),
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
                  tooltip: 'Create staff',
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
      2 => 'Team',
      _ => 'Profile',
    };
  }

  Widget _buildHomeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_controller.error != null)
          InlineBanner(message: _controller.error!, tone: BannerTone.error),
        if (_controller.success != null)
          InlineBanner(message: _controller.success!, tone: BannerTone.success),
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
          InlineBanner(message: _controller.error!, tone: BannerTone.error),
        if (_controller.success != null)
          InlineBanner(message: _controller.success!, tone: BannerTone.success),
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

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OwnerProfileCard(
          user: widget.user,
          selectedBusiness: _controller.selectedBusiness,
          onOpenAccountSettings: _openAccountSettingsDialog,
          onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }

  Widget _buildTeamView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_controller.error != null)
          InlineBanner(message: _controller.error!, tone: BannerTone.error),
        if (_controller.success != null)
          InlineBanner(message: _controller.success!, tone: BannerTone.success),
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
          builder: (context, _) => OwnerCreateStaffDialog(
            emailController: _controller.staffEmailController,
            fullNameController: _controller.staffNameController,
            passwordController: _controller.staffPasswordController,
            errorMessage: _controller.error,
            isSaving: _controller.isSaving,
            onCreate: _controller.createStaff,
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
}
