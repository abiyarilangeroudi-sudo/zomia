import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerMissionListCard extends StatelessWidget {
  const OwnerMissionListCard({super.key, required this.missions});

  final List<OwnerMission> missions;

  @override
  Widget build(BuildContext context) {
    return OwnerSetupCard(
      title: 'Missions',
      children: [
        OwnerSimpleList(
          emptyTitle: 'No missions yet',
          emptyMessage: 'Created missions will appear here.',
          leadingIcon: Icons.task_alt_rounded,
          items: missions
              .map(
                (mission) => OwnerSimpleListItem(
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

class OwnerMissionCreateDialog extends StatelessWidget {
  const OwnerMissionCreateDialog({
    super.key,
    required this.controller,
    required this.pointsController,
    this.errorMessage,
    required this.isSaving,
    required this.onCreate,
  });

  final TextEditingController controller;
  final TextEditingController pointsController;
  final String? errorMessage;
  final bool isSaving;
  final Future<bool> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Create Mission',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: OwnerSetupCard(
            title: 'Mission',
            children: [
              if (errorMessage != null) ...[
                InlineBanner(message: errorMessage!, tone: BannerTone.error),
                const SizedBox(height: 12),
              ],
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
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Create Mission',
                icon: Icons.add_task_rounded,
                isLoading: isSaving,
                onPressed: isSaving
                    ? null
                    : () async {
                        final saved = await onCreate();
                        if (saved && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
