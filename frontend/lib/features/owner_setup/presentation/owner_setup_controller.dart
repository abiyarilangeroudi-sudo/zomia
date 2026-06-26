import 'package:flutter/material.dart';

import '../data/owner_setup_repository.dart';
import '../domain/owner_setup_models.dart';

class OwnerSetupController extends ChangeNotifier {
  OwnerSetupController({required this.repository});

  final OwnerSetupRepository repository;

  final staffEmailController = TextEditingController();
  final missionNameController = TextEditingController();
  final missionPointsController = TextEditingController();
  final DateTime _today = DateTime.now();
  final campaignNameController = TextEditingController();
  final campaignThresholdController = TextEditingController();
  final campaignMaxCompletionsController = TextEditingController(text: '2');
  final rewardNameController = TextEditingController();
  final giftNameController = TextEditingController();
  final validDaysController = TextEditingController();

  List<OwnerBusiness> businesses = [];
  List<OwnerStaffMember> staffMembers = [];
  List<OwnerMission> missions = [];
  List<OwnerCampaign> campaigns = [];
  List<OwnerRewardTemplate> rewardTemplates = [];
  OwnerBusiness? selectedBusiness;
  final Set<String> selectedMissionIds = {};
  String? selectedRewardTemplateId;
  String? error;
  String? success;
  late DateTime campaignStartDate = DateTime(
    _today.year,
    _today.month,
    _today.day,
  );
  late DateTime campaignEndDate = _addMonths(campaignStartDate, 3);
  bool campaignIsRepeatable = true;
  bool campaignHasCompletionLimit = false;
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
        selectedRewardTemplateId = nextTemplates.isEmpty
            ? null
            : nextTemplates.first.id;
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
      selectedRewardTemplateId = null;
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

  void selectRewardTemplate(String? value) {
    _setState(() => selectedRewardTemplateId = value);
  }

  void setCampaignRepeatable(bool value) {
    _setState(() {
      campaignIsRepeatable = value;
      if (!value) {
        campaignHasCompletionLimit = false;
        campaignMaxCompletionsController.text = '2';
      }
    });
  }

  void setCampaignCompletionLimit(bool value) {
    _setState(() {
      campaignHasCompletionLimit = value;
      if (!value) {
        campaignMaxCompletionsController.text = '2';
      }
    });
  }

  void setCampaignStartDate(DateTime value) {
    _setState(() {
      campaignStartDate = DateTime(value.year, value.month, value.day);
      if (!campaignStartDate.isBefore(campaignEndDate)) {
        campaignEndDate = _addMonths(campaignStartDate, 3);
      }
    });
  }

  void setCampaignEndDate(DateTime value) {
    _setState(() {
      campaignEndDate = DateTime(value.year, value.month, value.day);
    });
  }

  void clearError() {
    if (error == null) {
      return;
    }
    _setState(() => error = null);
  }

  void clearSuccess() {
    if (success == null) {
      return;
    }
    _setState(() => success = null);
  }

  Future<bool> sendStaffInvitation() async {
    final business = selectedBusiness;
    final email = staffEmailController.text.trim();
    if (business == null || email.isEmpty || !email.contains('@')) {
      _showError('Enter a valid staff email.');
      return false;
    }
    final saved = await _save(
      () =>
          repository.sendStaffInvitation(businessId: business.id, email: email),
      'Staff invitation sent.',
    );
    if (saved) {
      staffEmailController.clear();
    }
    return saved;
  }

  Future<void> setStaffActive(
    OwnerStaffMember staffMember,
    bool isActive,
  ) async {
    await _save(
      () => repository.setStaffActive(
        staffMemberId: staffMember.staffMemberId ?? staffMember.id,
        isActive: isActive,
      ),
      isActive ? 'Staff activated.' : 'Staff deactivated.',
    );
  }

  Future<bool> updateBusinessProfile({
    required String name,
    required String? category,
    required String? publicEmail,
    required String? publicPhone,
    required String? websiteUrl,
    required String? addressLine1,
    required String? addressLine2,
    required String? city,
    required String? region,
    required String? postalCode,
    required String countryCode,
    required String timezone,
  }) async {
    final business = selectedBusiness;
    if (business == null) {
      _showError('Select a business first.');
      return false;
    }
    if (name.trim().length < 2) {
      _showError('Business name is required.');
      return false;
    }
    if (countryCode.trim().length != 2 || timezone.trim().isEmpty) {
      _showError('Enter valid country and timezone values.');
      return false;
    }
    return _save(() async {
      await repository.updateBusiness(
        businessId: business.id,
        name: name.trim(),
        category: category,
        publicEmail: publicEmail,
        publicPhone: publicPhone,
        websiteUrl: websiteUrl,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        region: region,
        postalCode: postalCode,
        countryCode: countryCode.trim().toUpperCase(),
        timezone: timezone.trim(),
      );
    }, 'Business updated.');
  }

  Future<bool> createMission() async {
    final business = selectedBusiness;
    final points = int.tryParse(missionPointsController.text.trim());
    final name = missionNameController.text.trim();
    if (business == null) {
      _showError('Select a business first.');
      return false;
    }
    if (name.isEmpty) {
      _showError('Enter a mission name.');
      return false;
    }
    if (points == null || points <= 0) {
      _showError('Enter points greater than 0.');
      return false;
    }
    final saved = await _save(
      () => repository.createMission(
        businessId: business.id,
        name: name,
        missionType: 'purchase',
        pointValue: points,
      ),
      'Mission created.',
    );
    if (saved) {
      missionNameController.clear();
      missionPointsController.clear();
    }
    return saved;
  }

  Future<bool> createCampaign() async {
    final business = selectedBusiness;
    final rewardTemplateId = selectedRewardTemplateId;
    final threshold = int.tryParse(campaignThresholdController.text.trim());
    final maxCompletions = int.tryParse(
      campaignMaxCompletionsController.text.trim(),
    );
    final name = campaignNameController.text.trim();
    if (business == null) {
      _showError('Select a business first.');
      return false;
    }
    if (name.isEmpty) {
      _showError('Enter a campaign name.');
      return false;
    }
    if (rewardTemplateId == null) {
      _showError('Select a reward template.');
      return false;
    }
    if (selectedMissionIds.isEmpty) {
      _showError('Select at least one mission.');
      return false;
    }
    if (threshold == null || threshold <= 0) {
      _showError('Enter points needed greater than 0.');
      return false;
    }
    if (!campaignStartDate.isBefore(campaignEndDate)) {
      _showError('End date must be after start date.');
      return false;
    }
    if (campaignIsRepeatable &&
        campaignHasCompletionLimit &&
        (maxCompletions == null || maxCompletions < 2)) {
      _showError('Completion limit must be at least 2.');
      return false;
    }
    final saved = await _save(
      () => repository.createCampaign(
        businessId: business.id,
        rewardTemplateId: rewardTemplateId,
        name: name,
        thresholdPoints: threshold,
        startsAt: _startOfLocalDay(campaignStartDate),
        endsAt: _endOfLocalDay(campaignEndDate),
        missionIds: selectedMissionIds.toList(),
        isRepeatable: campaignIsRepeatable,
        maxCompletionsPerCustomer:
            campaignIsRepeatable && campaignHasCompletionLimit
            ? maxCompletions
            : null,
      ),
      'Campaign created.',
    );
    if (saved) {
      campaignNameController.clear();
      campaignThresholdController.clear();
      campaignMaxCompletionsController.text = '2';
      campaignIsRepeatable = true;
      campaignHasCompletionLimit = false;
    }
    return saved;
  }

  Future<bool> createRewardTemplate() async {
    final business = selectedBusiness;
    final name = rewardNameController.text.trim();
    final giftName = giftNameController.text.trim();
    final validDays = int.tryParse(validDaysController.text.trim());
    if (business == null) {
      _showError('Select a business first.');
      return false;
    }
    if (name.isEmpty) {
      _showError('Enter a template name.');
      return false;
    }
    if (giftName.isEmpty) {
      _showError('Enter a reward item.');
      return false;
    }
    if (validDays == null || validDays <= 0) {
      _showError('Enter valid days greater than 0.');
      return false;
    }
    final saved = await _save(
      () => repository.createGiftRewardTemplate(
        businessId: business.id,
        name: name,
        giftName: giftName,
        validDays: validDays,
      ),
      'Reward template created.',
    );
    if (saved) {
      rewardNameController.clear();
      giftNameController.clear();
      validDaysController.clear();
    }
    return saved;
  }

  Future<bool> _save(Future<void> Function() action, String message) async {
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
      return true;
    } catch (saveError) {
      _setState(() {
        error = saveError.toString();
        isSaving = false;
      });
      return false;
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
    missionNameController.dispose();
    missionPointsController.dispose();
    campaignNameController.dispose();
    campaignThresholdController.dispose();
    campaignMaxCompletionsController.dispose();
    rewardNameController.dispose();
    giftNameController.dispose();
    validDaysController.dispose();
    super.dispose();
  }

  static DateTime _addMonths(DateTime value, int months) {
    return DateTime(value.year, value.month + months, value.day);
  }

  static DateTime _startOfLocalDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime _endOfLocalDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59);
  }
}
