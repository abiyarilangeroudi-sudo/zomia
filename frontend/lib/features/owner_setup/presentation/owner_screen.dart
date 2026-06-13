import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
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
      label: 'Campaigns',
      icon: Icons.flag_outlined,
      activeIcon: Icons.flag_rounded,
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
            title: 'Owner Dashboard',
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
                DashboardScroll(maxWidth: 760, child: _buildProfileView()),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            items: _tabs,
            selectedIndex: _selectedIndex,
            onChanged: (index) => setState(() => _selectedIndex = index),
          ),
        );
      },
    );
  }

  Widget _buildHomeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OwnerHeader(
          user: widget.user,
          selectedBusiness: _controller.selectedBusiness,
        ),
        const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          OwnerMissionSetupCard(
            controller: _controller.missionNameController,
            pointsController: _controller.missionPointsController,
            missions: _controller.missions,
            isSaving: _controller.isSaving,
            onCreate: _controller.createMission,
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
          OwnerCampaignSetupCard(
            controller: _controller.campaignNameController,
            thresholdController: _controller.campaignThresholdController,
            missions: _controller.missions,
            campaigns: _controller.campaigns,
            selectedMissionIds: _controller.selectedMissionIds,
            isSaving: _controller.isSaving,
            onMissionToggled: _controller.toggleMission,
            onCreate: _controller.createCampaign,
          ),
          const SizedBox(height: 16),
          OwnerRewardTemplateSetupCard(
            rewardNameController: _controller.rewardNameController,
            giftNameController: _controller.giftNameController,
            validDaysController: _controller.validDaysController,
            campaigns: _controller.campaigns,
            rewardTemplates: _controller.rewardTemplates,
            selectedCampaignId: _controller.selectedCampaignId,
            isSaving: _controller.isSaving,
            onCampaignChanged: _controller.selectCampaign,
            onCreate: _controller.createRewardTemplate,
          ),
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
          onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
        const SizedBox(height: 16),
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
          OwnerStaffSetupCard(
            emailController: _controller.staffEmailController,
            fullNameController: _controller.staffNameController,
            passwordController: _controller.staffPasswordController,
            staffMembers: _controller.staffForSelectedBusiness,
            isSaving: _controller.isSaving,
            onCreate: _controller.createStaff,
          ),
      ],
    );
  }

  void _openRecentActionsDialog() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => const OwnerRecentActionsDialog(),
      ),
    );
  }
}
