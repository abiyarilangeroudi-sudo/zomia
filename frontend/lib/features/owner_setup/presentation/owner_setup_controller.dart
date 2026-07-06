import 'package:flutter/material.dart';

import '../data/owner_setup_repository.dart';
import '../domain/owner_setup_models.dart';
import 'owner_setup_forms.dart';

class OwnerSetupController extends ChangeNotifier {
  OwnerSetupController({required this.repository});

  final OwnerSetupRepository repository;

  final staffInvitationForm = OwnerStaffInvitationForm();
  final missionForm = OwnerMissionForm();
  final campaignForm = OwnerCampaignForm();
  final rewardTemplateForm = OwnerRewardTemplateForm();

  List<OwnerBusiness> businesses = [];
  List<OwnerStaffMember> staffMembers = [];
  List<OwnerMission> missions = [];
  List<OwnerCampaign> campaigns = [];
  List<OwnerRewardTemplate> rewardTemplates = [];
  List<OwnerActivity> recentActivities = [];
  OwnerBusiness? selectedBusiness;
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
      List<OwnerActivity> nextRecentActivities = [];
      if (selected != null) {
        nextStaffMembers = await repository.listStaff();
        nextMissions = await repository.listMissions(selected.id);
        nextCampaigns = await repository.listCampaigns(selected.id);
        nextTemplates = await repository.listRewardTemplates(selected.id);
        try {
          nextRecentActivities = await repository.listRecentActivity(
            businessId: selected.id,
          );
        } catch (_) {
          nextRecentActivities = [];
        }
      }

      _setState(() {
        businesses = nextBusinesses;
        selectedBusiness = selected;
        staffMembers = nextStaffMembers;
        missions = nextMissions;
        campaigns = nextCampaigns;
        rewardTemplates = nextTemplates;
        recentActivities = nextRecentActivities;
        campaignForm.syncOptions(
          missionIds: nextMissions.map((mission) => mission.id).toList(),
          rewardTemplateIds: nextTemplates
              .map((rewardTemplate) => rewardTemplate.id)
              .toList(),
        );
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
      campaignForm.clearSelection();
    });
    await load();
  }

  void toggleMission(String missionId, bool selected) {
    _setState(() => campaignForm.toggleMission(missionId, selected));
  }

  void selectRewardTemplate(String? value) {
    _setState(() => campaignForm.selectRewardTemplate(value));
  }

  void setCampaignRepeatable(bool value) {
    _setState(() => campaignForm.setRepeatable(value));
  }

  void setCampaignCompletionLimit(bool value) {
    _setState(() => campaignForm.setCompletionLimit(value));
  }

  void setCampaignStartDate(DateTime value) {
    _setState(() => campaignForm.setStartDate(value));
  }

  void setCampaignEndDate(DateTime value) {
    _setState(() => campaignForm.setEndDate(value));
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
    final email = staffInvitationForm.email;
    final validationError = staffInvitationForm.validate();
    if (business == null) {
      _showError('Select a business first.');
      return false;
    }
    if (validationError != null) {
      _showError(validationError);
      return false;
    }
    final saved = await _save(
      () =>
          repository.sendStaffInvitation(businessId: business.id, email: email),
      'Staff invitation sent.',
    );
    if (saved) {
      staffInvitationForm.reset();
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
    final name = missionForm.name;
    final points = missionForm.points;
    final validationError = missionForm.validate();
    if (business == null) {
      _showError('Select a business first.');
      return false;
    }
    if (validationError != null || points == null) {
      _showError(validationError ?? 'Enter points greater than 0.');
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
      missionForm.reset();
    }
    return saved;
  }

  Future<bool> createCampaign() async {
    final business = selectedBusiness;
    final rewardTemplateId = campaignForm.selectedRewardTemplateId;
    final threshold = campaignForm.threshold;
    final maxCompletions = campaignForm.maxCompletions;
    final name = campaignForm.name;
    final validationError = campaignForm.validate();
    if (business == null) {
      _showError('Select a business first.');
      return false;
    }
    if (validationError != null ||
        rewardTemplateId == null ||
        threshold == null) {
      _showError(validationError ?? 'Please check the campaign form.');
      return false;
    }
    final saved = await _save(
      () => repository.createCampaign(
        businessId: business.id,
        rewardTemplateId: rewardTemplateId,
        name: name,
        thresholdPoints: threshold,
        startsAt: _startOfLocalDay(campaignForm.startDate),
        endsAt: _endOfLocalDay(campaignForm.endDate),
        missionIds: campaignForm.selectedMissionIds.toList(),
        isRepeatable: campaignForm.isRepeatable,
        maxCompletionsPerCustomer:
            campaignForm.isRepeatable && campaignForm.hasCompletionLimit
            ? maxCompletions
            : null,
      ),
      'Campaign created.',
    );
    if (saved) {
      campaignForm.resetAfterSave();
    }
    return saved;
  }

  Future<bool> createRewardTemplate() async {
    final business = selectedBusiness;
    final name = rewardTemplateForm.name;
    final giftName = rewardTemplateForm.giftName;
    final validDays = rewardTemplateForm.validDays;
    final validationError = rewardTemplateForm.validate();
    if (business == null) {
      _showError('Select a business first.');
      return false;
    }
    if (validationError != null || validDays == null) {
      _showError(validationError ?? 'Enter valid days greater than 0.');
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
      rewardTemplateForm.reset();
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
    staffInvitationForm.dispose();
    missionForm.dispose();
    campaignForm.dispose();
    rewardTemplateForm.dispose();
    super.dispose();
  }

  static DateTime _startOfLocalDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime _endOfLocalDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59);
  }
}
