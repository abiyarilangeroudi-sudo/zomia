import 'package:flutter/material.dart';

class OwnerStaffInvitationForm {
  final emailController = TextEditingController();

  String get email => emailController.text.trim();

  String? validate() {
    if (email.isEmpty || !email.contains('@')) {
      return 'Enter a valid staff email.';
    }
    return null;
  }

  void reset() => emailController.clear();

  void dispose() => emailController.dispose();
}

class OwnerMissionForm {
  final nameController = TextEditingController();
  final pointsController = TextEditingController();

  String get name => nameController.text.trim();

  int? get points => int.tryParse(pointsController.text.trim());

  String? validate() {
    if (name.isEmpty) {
      return 'Enter a mission name.';
    }
    final parsedPoints = points;
    if (parsedPoints == null || parsedPoints <= 0) {
      return 'Enter points greater than 0.';
    }
    return null;
  }

  void setValues({required String name, required int points}) {
    nameController.text = name;
    pointsController.text = points.toString();
  }

  void reset() {
    nameController.clear();
    pointsController.clear();
  }

  void dispose() {
    nameController.dispose();
    pointsController.dispose();
  }
}

class OwnerCampaignForm {
  OwnerCampaignForm() {
    final today = DateTime.now();
    startDate = DateTime(today.year, today.month, today.day);
    endDate = addMonths(startDate, 3);
  }

  final nameController = TextEditingController();
  final thresholdController = TextEditingController();
  final maxCompletionsController = TextEditingController(text: '2');
  final Set<String> selectedMissionIds = {};

  String? selectedRewardTemplateId;
  late DateTime startDate;
  late DateTime endDate;
  bool isRepeatable = true;
  bool hasCompletionLimit = false;

  String get name => nameController.text.trim();

  int? get threshold => int.tryParse(thresholdController.text.trim());

  int? get maxCompletions {
    return int.tryParse(maxCompletionsController.text.trim());
  }

  String? validate() {
    if (name.isEmpty) {
      return 'Enter a campaign name.';
    }
    if (selectedRewardTemplateId == null) {
      return 'Select a reward template.';
    }
    if (selectedMissionIds.isEmpty) {
      return 'Select at least one mission.';
    }
    final parsedThreshold = threshold;
    if (parsedThreshold == null || parsedThreshold <= 0) {
      return 'Enter points needed greater than 0.';
    }
    if (!startDate.isBefore(endDate)) {
      return 'End date must be after start date.';
    }
    final parsedMaxCompletions = maxCompletions;
    if (isRepeatable &&
        hasCompletionLimit &&
        (parsedMaxCompletions == null || parsedMaxCompletions < 2)) {
      return 'Completion limit must be at least 2.';
    }
    return null;
  }

  void syncOptions({
    required List<String> missionIds,
    required List<String> rewardTemplateIds,
  }) {
    selectedMissionIds.removeWhere((id) => !missionIds.contains(id));
    if (selectedMissionIds.isEmpty && missionIds.isNotEmpty) {
      selectedMissionIds.add(missionIds.first);
    }
    selectedRewardTemplateId = rewardTemplateIds.isEmpty
        ? null
        : rewardTemplateIds.first;
  }

  void clearSelection() {
    selectedMissionIds.clear();
    selectedRewardTemplateId = null;
  }

  void toggleMission(String missionId, bool selected) {
    if (selected) {
      selectedMissionIds.add(missionId);
    } else {
      selectedMissionIds.remove(missionId);
    }
  }

  void selectRewardTemplate(String? value) {
    selectedRewardTemplateId = value;
  }

  void setRepeatable(bool value) {
    isRepeatable = value;
    if (!value) {
      hasCompletionLimit = false;
      maxCompletionsController.text = '2';
    }
  }

  void setCompletionLimit(bool value) {
    hasCompletionLimit = value;
    if (!value) {
      maxCompletionsController.text = '2';
    }
  }

  void setStartDate(DateTime value) {
    startDate = DateTime(value.year, value.month, value.day);
    if (!startDate.isBefore(endDate)) {
      endDate = addMonths(startDate, 3);
    }
  }

  void setEndDate(DateTime value) {
    endDate = DateTime(value.year, value.month, value.day);
  }

  void resetAfterSave() {
    nameController.clear();
    thresholdController.clear();
    maxCompletionsController.text = '2';
    isRepeatable = true;
    hasCompletionLimit = false;
  }

  void dispose() {
    nameController.dispose();
    thresholdController.dispose();
    maxCompletionsController.dispose();
  }

  static DateTime addMonths(DateTime value, int months) {
    return DateTime(value.year, value.month + months, value.day);
  }
}

class OwnerRewardTemplateForm {
  final giftNameController = TextEditingController();
  final validDaysController = TextEditingController();

  String get giftName => giftNameController.text.trim();

  String get name => giftName;

  int? get validDays => int.tryParse(validDaysController.text.trim());

  String? validate() {
    if (giftName.isEmpty) {
      return 'Enter a reward item.';
    }
    final parsedValidDays = validDays;
    if (parsedValidDays == null || parsedValidDays <= 0) {
      return 'Enter valid days greater than 0.';
    }
    return null;
  }

  void reset() {
    giftNameController.clear();
    validDaysController.clear();
  }

  void dispose() {
    giftNameController.dispose();
    validDaysController.dispose();
  }
}
