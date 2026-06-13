import 'package:flutter/material.dart';

import '../data/owner_setup_repository.dart';
import '../domain/owner_setup_models.dart';

class OwnerSetupController extends ChangeNotifier {
  OwnerSetupController({required this.repository});

  final OwnerSetupRepository repository;

  final staffEmailController = TextEditingController(text: 'staff@example.com');
  final staffNameController = TextEditingController(text: 'Staff One');
  final staffPasswordController = TextEditingController(
    text: 'strong-password',
  );
  final missionNameController = TextEditingController(text: 'Buy Coffee');
  final missionPointsController = TextEditingController(text: '1');
  final campaignNameController = TextEditingController(text: 'Coffee Reward');
  final campaignThresholdController = TextEditingController(text: '10');
  final rewardNameController = TextEditingController(text: 'Free Coffee');
  final giftNameController = TextEditingController(text: 'Free coffee');
  final validDaysController = TextEditingController(text: '30');

  List<OwnerBusiness> businesses = [];
  List<OwnerStaffMember> staffMembers = [];
  List<OwnerMission> missions = [];
  List<OwnerCampaign> campaigns = [];
  List<OwnerRewardTemplate> rewardTemplates = [];
  OwnerBusiness? selectedBusiness;
  final Set<String> selectedMissionIds = {};
  String? selectedCampaignId;
  String? error;
  String? success;
  bool isLoading = true;
  bool isSaving = false;
  bool _isDisposed = false;

  List<OwnerStaffMember> get staffForSelectedBusiness {
    final business = selectedBusiness;
    if (business == null) {
      return const [];
    }
    return staffMembers
        .where((staffMember) => staffMember.businessId == business.id)
        .toList();
  }

  Future<void> load() async {
    _setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final nextBusinesses = await repository.listBusinesses();
      final selected = selectedBusiness == null
          ? (nextBusinesses.isEmpty ? null : nextBusinesses.first)
          : nextBusinesses
                .where((business) => business.id == selectedBusiness!.id)
                .firstOrNull;

      List<OwnerMission> nextMissions = [];
      List<OwnerCampaign> nextCampaigns = [];
      List<OwnerRewardTemplate> nextTemplates = [];
      List<OwnerStaffMember> nextStaffMembers = [];
      if (selected != null) {
        nextStaffMembers = await repository.listStaff();
        nextMissions = await repository.listMissions(selected.id);
        nextCampaigns = await repository.listCampaigns(selected.id);
        nextTemplates = await repository.listRewardTemplates(selected.id);
      }

      _setState(() {
        businesses = nextBusinesses;
        selectedBusiness = selected;
        staffMembers = nextStaffMembers;
        missions = nextMissions;
        campaigns = nextCampaigns;
        rewardTemplates = nextTemplates;
        selectedMissionIds.removeWhere(
          (id) => !nextMissions.any((mission) => mission.id == id),
        );
        if (selectedMissionIds.isEmpty && nextMissions.isNotEmpty) {
          selectedMissionIds.add(nextMissions.first.id);
        }
        selectedCampaignId = nextCampaigns.isEmpty
            ? null
            : nextCampaigns.first.id;
        isLoading = false;
      });
    } catch (loadError) {
      _setState(() {
        error = loadError.toString();
        isLoading = false;
      });
    }
  }

  Future<void> selectBusiness(OwnerBusiness? business) async {
    _setState(() {
      selectedBusiness = business;
      selectedMissionIds.clear();
      selectedCampaignId = null;
    });
    await load();
  }

  void toggleMission(String missionId, bool selected) {
    _setState(() {
      if (selected) {
        selectedMissionIds.add(missionId);
      } else {
        selectedMissionIds.remove(missionId);
      }
    });
  }

  void selectCampaign(String? value) {
    _setState(() => selectedCampaignId = value);
  }

  Future<void> createStaff() async {
    final business = selectedBusiness;
    final email = staffEmailController.text.trim();
    final fullName = staffNameController.text.trim();
    final password = staffPasswordController.text;
    if (business == null ||
        email.isEmpty ||
        fullName.isEmpty ||
        password.length < 8) {
      _showError('Enter a valid staff email, name, and password.');
      return;
    }
    await _save(
      () => repository.createStaff(
        businessId: business.id,
        email: email,
        password: password,
        fullName: fullName,
      ),
      'Staff created.',
    );
  }

  Future<void> setStaffActive(
    OwnerStaffMember staffMember,
    bool isActive,
  ) async {
    await _save(
      () => repository.setStaffActive(
        staffMemberId: staffMember.id,
        isActive: isActive,
      ),
      isActive ? 'Staff activated.' : 'Staff deactivated.',
    );
  }

  Future<void> createMission() async {
    final business = selectedBusiness;
    final points = int.tryParse(missionPointsController.text.trim());
    final name = missionNameController.text.trim();
    if (business == null || name.isEmpty || points == null || points <= 0) {
      _showError('Enter a valid mission point value.');
      return;
    }
    await _save(
      () => repository.createMission(
        businessId: business.id,
        name: name,
        missionType: 'purchase',
        pointValue: points,
      ),
      'Mission created.',
    );
  }

  Future<void> createCampaign() async {
    final business = selectedBusiness;
    final threshold = int.tryParse(campaignThresholdController.text.trim());
    final name = campaignNameController.text.trim();
    if (business == null ||
        name.isEmpty ||
        selectedMissionIds.isEmpty ||
        threshold == null ||
        threshold <= 0) {
      _showError('Select a mission and enter a valid threshold.');
      return;
    }
    await _save(
      () => repository.createCampaign(
        businessId: business.id,
        name: name,
        thresholdPoints: threshold,
        missionIds: selectedMissionIds.toList(),
      ),
      'Campaign created.',
    );
  }

  Future<void> createRewardTemplate() async {
    final business = selectedBusiness;
    final campaignId = selectedCampaignId;
    final name = rewardNameController.text.trim();
    final giftName = giftNameController.text.trim();
    final validDays = int.tryParse(validDaysController.text.trim());
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
      () => repository.createGiftRewardTemplate(
        businessId: business.id,
        campaignId: campaignId,
        name: name,
        giftName: giftName,
        validDays: validDays,
      ),
      'Reward template created.',
    );
  }

  Future<void> _save(Future<void> Function() action, String message) async {
    _setState(() {
      isSaving = true;
      error = null;
      success = null;
    });
    try {
      await action();
      _setState(() {
        success = message;
        isSaving = false;
      });
      await load();
    } catch (saveError) {
      _setState(() {
        error = saveError.toString();
        isSaving = false;
      });
    }
  }

  void _showError(String message) {
    _setState(() {
      error = message;
      success = null;
    });
  }

  void _setState(VoidCallback update) {
    if (_isDisposed) {
      return;
    }
    update();
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    staffEmailController.dispose();
    staffNameController.dispose();
    staffPasswordController.dispose();
    missionNameController.dispose();
    missionPointsController.dispose();
    campaignNameController.dispose();
    campaignThresholdController.dispose();
    rewardNameController.dispose();
    giftNameController.dispose();
    validDaysController.dispose();
    super.dispose();
  }
}
