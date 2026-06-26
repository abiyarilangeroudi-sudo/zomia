import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_presenter.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerRewardTemplateListCard extends StatelessWidget {
  const OwnerRewardTemplateListCard({super.key, required this.rewardTemplates});

  final List<OwnerRewardTemplate> rewardTemplates;

  @override
  Widget build(BuildContext context) {
    return OwnerSetupCard(
      title: 'Reward Templates',
      children: [
        OwnerSimpleList(
          emptyTitle: 'No reward templates yet',
          leadingIcon: Icons.card_giftcard_rounded,
          items: rewardTemplates
              .map(
                (template) => OwnerSimpleListItem(
                  title: template.name,
                  subtitle: ownerRewardTemplateSubtitle(template),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class OwnerRewardTemplateCreateDialog extends StatelessWidget {
  const OwnerRewardTemplateCreateDialog({
    super.key,
    required this.rewardNameController,
    required this.giftNameController,
    required this.validDaysController,
    this.errorMessage,
    this.onClearError,
    required this.isSaving,
    required this.onCreate,
  });

  final TextEditingController rewardNameController;
  final TextEditingController giftNameController;
  final TextEditingController validDaysController;
  final String? errorMessage;
  final VoidCallback? onClearError;
  final bool isSaving;
  final Future<bool> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Create Reward Template',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: OwnerSetupCard(
            title: 'Reward Template',
            children: [
              if (errorMessage != null) ...[
                InlineBanner(
                  message: errorMessage!,
                  tone: BannerTone.error,
                  onClose: onClearError,
                ),
                const SizedBox(height: 12),
              ],
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
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Create Reward Template',
                icon: Icons.card_giftcard_rounded,
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
