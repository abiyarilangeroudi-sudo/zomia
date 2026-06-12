import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/brand/brand_spacing.dart';
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
  final _missionNameController = TextEditingController(text: 'Buy Coffee');
  final _missionPointsController = TextEditingController(text: '1');
  final _campaignNameController = TextEditingController(text: 'Coffee Reward');
  final _campaignThresholdController = TextEditingController(text: '10');
  final _rewardNameController = TextEditingController(text: 'Free Coffee');
  final _giftNameController = TextEditingController(text: 'Free coffee');
  final _validDaysController = TextEditingController(text: '30');

  List<OwnerBusiness> _businesses = [];
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
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
      appBar: AppBar(
        title: const Text('Owner Setup'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(BrandSpacing.screenPadding),
        children: [
          _OwnerHeader(user: widget.user),
          const SizedBox(height: 16),
          if (_error != null) _MessageBanner(message: _error!, isError: true),
          if (_success != null)
            _MessageBanner(message: _success!, isError: false),
          if (_error != null || _success != null) const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_businesses.isEmpty)
            const _EmptyState(
              title: 'No business found',
              message: 'Create the owner business from the backend for now.',
            )
          else ...[
            _BusinessPicker(
              businesses: _businesses,
              selectedBusiness: _selectedBusiness,
              onChanged: _selectBusiness,
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
      ),
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
      if (selected != null) {
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

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader({required this.user});

  final CurrentUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BrandSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minimal Setup',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text('Signed in as ${user.fullName}'),
          ],
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BrandSpacing.cardPadding),
        child: DropdownButtonFormField<String>(
          initialValue: selectedBusiness?.id,
          decoration: const InputDecoration(labelText: 'Business'),
          items: businesses
              .map(
                (business) => DropdownMenuItem(
                  value: business.id,
                  child: Text(business.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            onChanged(
              businesses.where((business) => business.id == value).firstOrNull,
            );
          },
        ),
      ),
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
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Mission name'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: pointsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Point value'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: isSaving ? null : onCreate,
          icon: const Icon(Icons.add_task),
          label: const Text('Create mission'),
        ),
        const SizedBox(height: 12),
        _SimpleList(
          emptyText: 'No missions yet',
          children: missions
              .map((mission) => '${mission.name} · ${mission.pointValue} pts')
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
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Campaign name'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: thresholdController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Threshold points'),
        ),
        const SizedBox(height: 8),
        Text(
          'Included missions',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        if (missions.isEmpty)
          const Text('No missions available')
        else
          ...missions.map(
            (mission) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: selectedMissionIds.contains(mission.id),
              onChanged: (selected) =>
                  onMissionToggled(mission.id, selected ?? false),
              title: Text(mission.name),
              subtitle: Text('${mission.pointValue} pts'),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: isSaving || missions.isEmpty || selectedMissionIds.isEmpty
              ? null
              : onCreate,
          icon: const Icon(Icons.flag),
          label: const Text('Create campaign'),
        ),
        const SizedBox(height: 12),
        _SimpleList(
          emptyText: 'No campaigns yet',
          children: campaigns
              .map(
                (campaign) =>
                    '${campaign.name} · ${campaign.thresholdPoints} pts',
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
      children: [
        TextField(
          controller: rewardNameController,
          decoration: const InputDecoration(labelText: 'Reward name'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: giftNameController,
          decoration: const InputDecoration(labelText: 'Gift name'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: validDaysController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Valid days'),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedCampaignId,
          decoration: const InputDecoration(labelText: 'Campaign'),
          items: campaigns
              .map(
                (campaign) => DropdownMenuItem(
                  value: campaign.id,
                  child: Text(campaign.name),
                ),
              )
              .toList(),
          onChanged: onCampaignChanged,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: isSaving || campaigns.isEmpty ? null : onCreate,
          icon: const Icon(Icons.card_giftcard),
          label: const Text('Create gift reward'),
        ),
        const SizedBox(height: 12),
        _SimpleList(
          emptyText: 'No reward templates yet',
          children: rewardTemplates
              .map(
                (template) =>
                    '${template.name} · ${template.giftName ?? template.rewardType}',
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BrandSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SimpleList extends StatelessWidget {
  const _SimpleList({required this.emptyText, required this.children});

  final String emptyText;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Text(
        emptyText,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: BrandColors.textSecondary),
      );
    }
    return Column(
      children: children
          .map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.circle, size: 10),
              title: Text(item),
            ),
          )
          .toList(),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? BrandColors.error : BrandColors.success;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(BrandSpacing.smallRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: TextStyle(color: color)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BrandSpacing.cardPadding),
        child: Column(
          children: [
            const Icon(Icons.store_outlined),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
