part of 'owner_setup_controller.dart';

extension OwnerSetupControllerLoyaltyActions on OwnerSetupController {
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

  Future<bool> updateMission(OwnerMission mission) async {
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
      () => repository.updateMission(
        businessId: business.id,
        missionId: mission.id,
        name: name,
        pointValue: points,
      ),
      'Mission updated.',
    );
    if (saved) {
      missionForm.reset();
    }
    return saved;
  }

  Future<void> deleteMission(OwnerMission mission) async {
    final business = selectedBusiness;
    if (business == null) {
      _showError('Select a business first.');
      return;
    }
    await _save(
      () => repository.deleteMission(
        businessId: business.id,
        missionId: mission.id,
      ),
      'Mission deleted.',
    );
  }

  Future<void> archiveMission(OwnerMission mission) async {
    final business = selectedBusiness;
    if (business == null) {
      _showError('Select a business first.');
      return;
    }
    await _save(
      () => repository.archiveMission(
        businessId: business.id,
        missionId: mission.id,
      ),
      'Mission archived.',
    );
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

  Future<bool> updateRewardTemplate(OwnerRewardTemplate template) async {
    final business = selectedBusiness;
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
      () => repository.updateGiftRewardTemplate(
        businessId: business.id,
        rewardTemplateId: template.id,
        giftName: giftName,
        validDays: validDays,
      ),
      'Reward template updated.',
    );
    if (saved) {
      rewardTemplateForm.reset();
    }
    return saved;
  }

  Future<void> deleteRewardTemplate(OwnerRewardTemplate template) async {
    final business = selectedBusiness;
    if (business == null) {
      _showError('Select a business first.');
      return;
    }
    await _save(
      () => repository.deleteRewardTemplate(
        businessId: business.id,
        rewardTemplateId: template.id,
      ),
      'Reward template deleted.',
    );
  }

  Future<void> archiveRewardTemplate(OwnerRewardTemplate template) async {
    final business = selectedBusiness;
    if (business == null) {
      _showError('Select a business first.');
      return;
    }
    await _save(
      () => repository.archiveRewardTemplate(
        businessId: business.id,
        rewardTemplateId: template.id,
      ),
      'Reward template archived.',
    );
  }

  Future<void> updateCampaignStatus(
    OwnerCampaign campaign,
    String status,
  ) async {
    final business = selectedBusiness;
    if (business == null) {
      _showError('Select a business first.');
      return;
    }
    await _save(
      () => repository.updateCampaignStatus(
        businessId: business.id,
        campaignId: campaign.id,
        status: status,
      ),
      switch (status) {
        'ended' => 'Campaign ended.',
        _ => 'Campaign updated.',
      },
    );
  }
}

DateTime _startOfLocalDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _endOfLocalDay(DateTime value) {
  return DateTime(value.year, value.month, value.day, 23, 59, 59);
}
