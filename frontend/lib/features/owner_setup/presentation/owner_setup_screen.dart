import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/owner_setup_repository.dart';
import '../domain/owner_setup_models.dart';

class OwnerSetupScreen extends ConsumerStatefulWidget {
  const OwnerSetupScreen({super.key, required this.user});

  final CurrentUser user;

  @override
  ConsumerState<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends ConsumerState<OwnerSetupScreen> {
  final _staffEmailController = TextEditingController(
    text: 'staff@example.com',
  );
  final _staffNameController = TextEditingController(text: 'Staff One');
  final _staffPasswordController = TextEditingController(
    text: 'strong-password',
  );
  final _missionNameController = TextEditingController(text: 'Buy Coffee');
  final _missionPointsController = TextEditingController(text: '1');
  final _campaignNameController = TextEditingController(text: 'Coffee Reward');
  final _campaignThresholdController = TextEditingController(text: '10');
  final _rewardNameController = TextEditingController(text: 'Free Coffee');
  final _giftNameController = TextEditingController(text: 'Free coffee');
  final _validDaysController = TextEditingController(text: '30');

  List<OwnerBusiness> _businesses = [];
  List<OwnerStaffMember> _staffMembers = [];
  List<OwnerMission> _missions = [];
  List<OwnerCampaign> _campaigns = [];
  List<OwnerRewardTemplate> _rewardTemplates = [];
  OwnerBusiness? _selectedBusiness;
  final Set<String> _selectedMissionIds = {};
  String? _selectedCampaignId;
  String? _error;
  String? _success;
  bool _isLoading = true;
  bool _isSaving = false;
  int _selectedIndex = 0;

  static const _tabs = [
    NavItem(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _staffEmailController.dispose();
    _staffNameController.dispose();
    _staffPasswordController.dispose();
    _missionNameController.dispose();
    _missionPointsController.dispose();
    _campaignNameController.dispose();
    _campaignThresholdController.dispose();
    _rewardNameController.dispose();
    _giftNameController.dispose();
    _validDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Owner Dashboard',
        variant: AppTopBarVariant.business,
        onMenu: () {},
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _DashboardScroll(child: _buildHomeView()),
            _DashboardScroll(
              child: _OwnerProfileCard(
                user: widget.user,
                selectedBusiness: _selectedBusiness,
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

  Widget _buildHomeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OwnerHeader(user: widget.user, selectedBusiness: _selectedBusiness),
        const SizedBox(height: 16),
        if (_error != null)
          InlineBanner(message: _error!, tone: BannerTone.error),
        if (_success != null)
          InlineBanner(message: _success!, tone: BannerTone.success),
        if (_error != null || _success != null) const SizedBox(height: 16),
        if (_isLoading)
          const AppCard(child: LoadingState(label: 'Loading owner setup'))
        else if (_businesses.isEmpty)
          const AppCard(
            child: EmptyStateView(
              icon: Icons.store_outlined,
              title: 'No business found',
              message: 'Create the owner business from the backend for now.',
            ),
          )
        else ...[
          _BusinessPicker(
            businesses: _businesses,
            selectedBusiness: _selectedBusiness,
            onChanged: _selectBusiness,
          ),
          const SizedBox(height: 16),
          _StaffSetupCard(
            emailController: _staffEmailController,
            fullNameController: _staffNameController,
            passwordController: _staffPasswordController,
            staffMembers: _staffForSelectedBusiness,
            isSaving: _isSaving,
            onCreate: _createStaff,
          ),
          const SizedBox(height: 16),
          _MissionSetupCard(
            controller: _missionNameController,
            pointsController: _missionPointsController,
            missions: _missions,
            isSaving: _isSaving,
            onCreate: _createMission,
          ),
          const SizedBox(height: 16),
          _CampaignSetupCard(
            controller: _campaignNameController,
            thresholdController: _campaignThresholdController,
            missions: _missions,
            campaigns: _campaigns,
            selectedMissionIds: _selectedMissionIds,
            isSaving: _isSaving,
            onMissionToggled: _toggleMission,
            onCreate: _createCampaign,
          ),
          const SizedBox(height: 16),
          _RewardTemplateSetupCard(
            rewardNameController: _rewardNameController,
            giftNameController: _giftNameController,
            validDaysController: _validDaysController,
            campaigns: _campaigns,
            rewardTemplates: _rewardTemplates,
            selectedCampaignId: _selectedCampaignId,
            isSaving: _isSaving,
            onCampaignChanged: (value) =>
                setState(() => _selectedCampaignId = value),
            onCreate: _createRewardTemplate,
          ),
        ],
      ],
    );
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repository = ref.read(ownerSetupRepositoryProvider);
      final businesses = await repository.listBusinesses();
      final selected = _selectedBusiness == null
          ? (businesses.isEmpty ? null : businesses.first)
          : businesses
                .where((business) => business.id == _selectedBusiness!.id)
                .firstOrNull;
      List<OwnerMission> missions = [];
      List<OwnerCampaign> campaigns = [];
      List<OwnerRewardTemplate> templates = [];
      List<OwnerStaffMember> staffMembers = [];
      if (selected != null) {
        staffMembers = await repository.listStaff();
        missions = await repository.listMissions(selected.id);
        campaigns = await repository.listCampaigns(selected.id);
        templates = await repository.listRewardTemplates(selected.id);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _businesses = businesses;
        _selectedBusiness = selected;
        _staffMembers = staffMembers;
        _missions = missions;
        _campaigns = campaigns;
        _rewardTemplates = templates;
        _selectedMissionIds.removeWhere(
          (id) => !missions.any((mission) => mission.id == id),
        );
        if (_selectedMissionIds.isEmpty && missions.isNotEmpty) {
          _selectedMissionIds.add(missions.first.id);
        }
        _selectedCampaignId = campaigns.isEmpty ? null : campaigns.first.id;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectBusiness(OwnerBusiness? business) async {
    setState(() {
      _selectedBusiness = business;
      _selectedMissionIds.clear();
      _selectedCampaignId = null;
    });
    await _load();
  }

  void _toggleMission(String missionId, bool selected) {
    setState(() {
      if (selected) {
        _selectedMissionIds.add(missionId);
      } else {
        _selectedMissionIds.remove(missionId);
      }
    });
  }

  List<OwnerStaffMember> get _staffForSelectedBusiness {
    final business = _selectedBusiness;
    if (business == null) {
      return const [];
    }
    return _staffMembers
        .where((staffMember) => staffMember.businessId == business.id)
        .toList();
  }

  Future<void> _createStaff() async {
    final business = _selectedBusiness;
    final email = _staffEmailController.text.trim();
    final fullName = _staffNameController.text.trim();
    final password = _staffPasswordController.text;
    if (business == null ||
        email.isEmpty ||
        fullName.isEmpty ||
        password.length < 8) {
      _showError('Enter a valid staff email, name, and password.');
      return;
    }
    await _save(
      () => ref
          .read(ownerSetupRepositoryProvider)
          .createStaff(
            businessId: business.id,
            email: email,
            password: password,
            fullName: fullName,
          ),
      'Staff created.',
    );
  }

  Future<void> _createMission() async {
    final business = _selectedBusiness;
    final points = int.tryParse(_missionPointsController.text.trim());
    final name = _missionNameController.text.trim();
    if (business == null || name.isEmpty || points == null || points <= 0) {
      _showError('Enter a valid mission point value.');
      return;
    }
    await _save(
      () => ref
          .read(ownerSetupRepositoryProvider)
          .createMission(
            businessId: business.id,
            name: name,
            missionType: 'purchase',
            pointValue: points,
          ),
      'Mission created.',
    );
  }

  Future<void> _createCampaign() async {
    final business = _selectedBusiness;
    final threshold = int.tryParse(_campaignThresholdController.text.trim());
    final name = _campaignNameController.text.trim();
    if (business == null ||
        name.isEmpty ||
        _selectedMissionIds.isEmpty ||
        threshold == null ||
        threshold <= 0) {
      _showError('Select a mission and enter a valid threshold.');
      return;
    }
    await _save(
      () => ref
          .read(ownerSetupRepositoryProvider)
          .createCampaign(
            businessId: business.id,
            name: name,
            thresholdPoints: threshold,
            missionIds: _selectedMissionIds.toList(),
          ),
      'Campaign created.',
    );
  }

  Future<void> _createRewardTemplate() async {
    final business = _selectedBusiness;
    final campaignId = _selectedCampaignId;
    final name = _rewardNameController.text.trim();
    final giftName = _giftNameController.text.trim();
    final validDays = int.tryParse(_validDaysController.text.trim());
    if (business == null ||
        campaignId == null ||
        name.isEmpty ||
        giftName.isEmpty ||
        validDays == null ||
        validDays <= 0) {
      _showError('Select a campaign and enter valid reward details.');
      return;
    }
    await _save(
      () => ref
          .read(ownerSetupRepositoryProvider)
          .createGiftRewardTemplate(
            businessId: business.id,
            campaignId: campaignId,
            name: name,
            giftName: giftName,
            validDays: validDays,
          ),
      'Reward template created.',
    );
  }

  Future<void> _save(Future<void> Function() action, String success) async {
    setState(() {
      _isSaving = true;
      _error = null;
      _success = null;
    });
    try {
      await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _success = success;
        _isSaving = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isSaving = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _error = message;
      _success = null;
    });
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
            constraints: const BoxConstraints(maxWidth: 760),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader({required this.user, required this.selectedBusiness});

  final CurrentUser user;
  final OwnerBusiness? selectedBusiness;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Owner Setup', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Signed in as ${user.fullName}'),
          if (selectedBusiness != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetricPill(
                  icon: Icons.storefront_rounded,
                  label: selectedBusiness!.name,
                  color: BrandColors.teal,
                ),
                MetricPill(
                  icon: Icons.payments_rounded,
                  label: selectedBusiness!.currencyCode,
                  color: BrandColors.orange,
                ),
                MetricPill(
                  icon: Icons.verified_rounded,
                  label: selectedBusiness!.status,
                  color: BrandColors.purple,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnerProfileCard extends StatelessWidget {
  const _OwnerProfileCard({
    required this.user,
    required this.selectedBusiness,
    required this.onSignOut,
  });

  final CurrentUser user;
  final OwnerBusiness? selectedBusiness;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Profile',
            subtitle: 'Owner context for the current setup session.',
          ),
          const SizedBox(height: 12),
          AppListRow(
            title: user.fullName,
            subtitle: user.email,
            leadingIcon: Icons.person_rounded,
          ),
          if (selectedBusiness != null) ...[
            const SizedBox(height: 12),
            AppListRow(
              title: selectedBusiness!.name,
              subtitle:
                  '${selectedBusiness!.currencyCode} · ${selectedBusiness!.status}',
              leadingIcon: Icons.storefront_rounded,
            ),
          ],
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

class _BusinessPicker extends StatelessWidget {
  const _BusinessPicker({
    required this.businesses,
    required this.selectedBusiness,
    required this.onChanged,
  });

  final List<OwnerBusiness> businesses;
  final OwnerBusiness? selectedBusiness;
  final ValueChanged<OwnerBusiness?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Business'),
          const SizedBox(height: 12),
          SelectField<String>(
            label: 'Business',
            value: selectedBusiness?.id,
            options: businesses
                .map(
                  (business) => SelectFieldOption(
                    value: business.id,
                    label: business.name,
                  ),
                )
                .toList(),
            onChanged: (value) {
              onChanged(
                businesses
                    .where((business) => business.id == value)
                    .firstOrNull,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SimpleList extends StatelessWidget {
  const _SimpleList({
    required this.emptyTitle,
    required this.emptyMessage,
    required this.items,
    required this.leadingIcon,
  });

  final String emptyTitle;
  final String emptyMessage;
  final List<_SimpleListItem> items;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateView(
        icon: leadingIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppListRow(
                title: item.title,
                subtitle: item.subtitle,
                leadingIcon: leadingIcon,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SimpleListItem {
  const _SimpleListItem({required this.title, this.subtitle});

  final String title;
  final String? subtitle;
}

class _StaffSetupCard extends StatelessWidget {
  const _StaffSetupCard({
    required this.emailController,
    required this.fullNameController,
    required this.passwordController,
    required this.staffMembers,
    required this.isSaving,
    required this.onCreate,
  });

  final TextEditingController emailController;
  final TextEditingController fullNameController;
  final TextEditingController passwordController;
  final List<OwnerStaffMember> staffMembers;
  final bool isSaving;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _SetupCard(
      title: 'Staff',
      subtitle: 'Create staff access for the selected business.',
      children: [
        AppTextField(
          controller: emailController,
          label: 'Staff email',
          hint: 'staff@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: fullNameController,
          label: 'Staff name',
          hint: 'Staff One',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: passwordController,
          label: 'Temporary password',
          obscureText: true,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Create Staff',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: isSaving ? null : onCreate,
          isLoading: isSaving,
        ),
        const SizedBox(height: 12),
        _SimpleList(
          emptyTitle: 'No staff yet',
          emptyMessage: 'Created staff users will appear here.',
          leadingIcon: Icons.person_rounded,
          items: staffMembers
              .map(
                (staffMember) => _SimpleListItem(
                  title: staffMember.user.fullName,
                  subtitle: staffMember.user.email,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _MissionSetupCard extends StatelessWidget {
  const _MissionSetupCard({
    required this.controller,
    required this.pointsController,
    required this.missions,
    required this.isSaving,
    required this.onCreate,
  });

  final TextEditingController controller;
  final TextEditingController pointsController;
  final List<OwnerMission> missions;
  final bool isSaving;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _SetupCard(
      title: 'Missions',
      subtitle: 'Define customer actions that can grant points.',
      children: [
        AppTextField(
          controller: controller,
          label: 'Mission name',
          hint: 'Buy Coffee',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: pointsController,
          label: 'Point value',
          hint: '1',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Create Mission',
          icon: Icons.add_task_rounded,
          onPressed: isSaving ? null : onCreate,
          isLoading: isSaving,
        ),
        const SizedBox(height: 12),
        _SimpleList(
          emptyTitle: 'No missions yet',
          emptyMessage: 'Created missions will appear here.',
          leadingIcon: Icons.task_alt_rounded,
          items: missions
              .map(
                (mission) => _SimpleListItem(
                  title: mission.name,
                  subtitle: '${mission.pointValue} pts',
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CampaignSetupCard extends StatelessWidget {
  const _CampaignSetupCard({
    required this.controller,
    required this.thresholdController,
    required this.missions,
    required this.campaigns,
    required this.selectedMissionIds,
    required this.isSaving,
    required this.onMissionToggled,
    required this.onCreate,
  });

  final TextEditingController controller;
  final TextEditingController thresholdController;
  final List<OwnerMission> missions;
  final List<OwnerCampaign> campaigns;
  final Set<String> selectedMissionIds;
  final bool isSaving;
  final void Function(String missionId, bool selected) onMissionToggled;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _SetupCard(
      title: 'Campaigns',
      subtitle: 'Connect missions to a points threshold.',
      children: [
        AppTextField(
          controller: controller,
          label: 'Campaign name',
          hint: 'Coffee Reward',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: thresholdController,
          label: 'Threshold points',
          hint: '10',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Included missions'),
        const SizedBox(height: 8),
        if (missions.isEmpty)
          const EmptyStateView(
            icon: Icons.task_alt_rounded,
            title: 'No missions available',
            message: 'Create a mission before creating a campaign.',
          )
        else
          ...missions.map(
            (mission) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CheckboxRow(
                title: mission.name,
                subtitle: '${mission.pointValue} pts',
                value: selectedMissionIds.contains(mission.id),
                onChanged: (selected) =>
                    onMissionToggled(mission.id, selected ?? false),
              ),
            ),
          ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Create Campaign',
          icon: Icons.flag_rounded,
          onPressed: isSaving || missions.isEmpty || selectedMissionIds.isEmpty
              ? null
              : onCreate,
          isLoading: isSaving,
        ),
        const SizedBox(height: 12),
        _SimpleList(
          emptyTitle: 'No campaigns yet',
          emptyMessage: 'Created campaigns will appear here.',
          leadingIcon: Icons.campaign_rounded,
          items: campaigns
              .map(
                (campaign) => _SimpleListItem(
                  title: campaign.name,
                  subtitle:
                      '${campaign.thresholdPoints} pts · ${campaign.status}',
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _RewardTemplateSetupCard extends StatelessWidget {
  const _RewardTemplateSetupCard({
    required this.rewardNameController,
    required this.giftNameController,
    required this.validDaysController,
    required this.campaigns,
    required this.rewardTemplates,
    required this.selectedCampaignId,
    required this.isSaving,
    required this.onCampaignChanged,
    required this.onCreate,
  });

  final TextEditingController rewardNameController;
  final TextEditingController giftNameController;
  final TextEditingController validDaysController;
  final List<OwnerCampaign> campaigns;
  final List<OwnerRewardTemplate> rewardTemplates;
  final String? selectedCampaignId;
  final bool isSaving;
  final ValueChanged<String?> onCampaignChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _SetupCard(
      title: 'Reward Templates',
      subtitle: 'Create the gift reward issued after campaign completion.',
      children: [
        AppTextField(
          controller: rewardNameController,
          label: 'Reward name',
          hint: 'Free Coffee',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: giftNameController,
          label: 'Gift name',
          hint: 'Free coffee',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: validDaysController,
          label: 'Valid days',
          hint: '30',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        SelectField<String>(
          label: 'Campaign',
          value: selectedCampaignId,
          options: campaigns
              .map(
                (campaign) =>
                    SelectFieldOption(value: campaign.id, label: campaign.name),
              )
              .toList(),
          onChanged: onCampaignChanged,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Create Gift Reward',
          icon: Icons.card_giftcard_rounded,
          onPressed: isSaving || campaigns.isEmpty ? null : onCreate,
          isLoading: isSaving,
        ),
        const SizedBox(height: 12),
        _SimpleList(
          emptyTitle: 'No reward templates yet',
          emptyMessage: 'Created reward templates will appear here.',
          leadingIcon: Icons.card_giftcard_rounded,
          items: rewardTemplates
              .map(
                (template) => _SimpleListItem(
                  title: template.name,
                  subtitle:
                      '${template.giftName ?? template.rewardType} · ${template.validDays} days',
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
