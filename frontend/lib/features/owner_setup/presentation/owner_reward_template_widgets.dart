import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_presenter.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerRewardTemplateListCard extends StatelessWidget {
  const OwnerRewardTemplateListCard({
    super.key,
    required this.rewardTemplates,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
    required this.onArchive,
  });

  final List<OwnerRewardTemplate> rewardTemplates;
  final bool isSaving;
  final ValueChanged<OwnerRewardTemplate> onEdit;
  final Future<void> Function(OwnerRewardTemplate template) onDelete;
  final Future<void> Function(OwnerRewardTemplate template) onArchive;

  @override
  Widget build(BuildContext context) {
    return OwnerSetupCard(
      title: 'Reward Templates',
      children: [
        OwnerRewardTemplateListContent(
          rewardTemplates: rewardTemplates,
          isSaving: isSaving,
          onEdit: onEdit,
          onDelete: onDelete,
          onArchive: onArchive,
        ),
      ],
    );
  }
}

class OwnerRewardTemplateListContent extends StatelessWidget {
  const OwnerRewardTemplateListContent({
    super.key,
    required this.rewardTemplates,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
    required this.onArchive,
  });

  final List<OwnerRewardTemplate> rewardTemplates;
  final bool isSaving;
  final ValueChanged<OwnerRewardTemplate> onEdit;
  final Future<void> Function(OwnerRewardTemplate template) onDelete;
  final Future<void> Function(OwnerRewardTemplate template) onArchive;

  @override
  Widget build(BuildContext context) {
    return OwnerSimpleList(
      emptyTitle: 'No reward templates yet',
      leadingIcon: Icons.card_giftcard_rounded,
      items: rewardTemplates
          .map(
            (template) => OwnerSimpleListItem(
              title: ownerRewardTemplateTypeLabel(template),
              subtitle: ownerRewardTemplateSubtitle(template),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (template.canEdit)
                    IconButton(
                      tooltip: 'Edit reward template',
                      onPressed: isSaving ? null : () => onEdit(template),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  if (template.canDelete)
                    IconButton(
                      tooltip: 'Delete reward template',
                      onPressed: isSaving
                          ? null
                          : () => _confirmDelete(context, template),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  if (template.canArchive)
                    IconButton(
                      tooltip: 'Archive reward template',
                      onPressed: isSaving
                          ? null
                          : () => _confirmArchive(context, template),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OwnerRewardTemplate template,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete reward template?',
      message:
          'This only works for reward templates that are not used in a campaign or generated reward.',
      confirmLabel: 'Delete template',
      tone: ConfirmTone.destructive,
    );
    if (!confirmed) {
      return;
    }
    await onDelete(template);
  }

  Future<void> _confirmArchive(
    BuildContext context,
    OwnerRewardTemplate template,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Archive reward template?',
      message:
          'This reward template will be hidden from Loyalty setup and new Campaigns. Existing rewards and history remain unchanged.',
      confirmLabel: 'Archive template',
    );
    if (!confirmed) {
      return;
    }
    await onArchive(template);
  }
}

class OwnerRewardTemplateCreateDialog extends StatelessWidget {
  const OwnerRewardTemplateCreateDialog({
    super.key,
    required this.giftNameController,
    required this.validDaysController,
    required this.title,
    required this.actionLabel,
    required this.actionIcon,
    this.errorMessage,
    this.onClearError,
    required this.isSaving,
    required this.onCreate,
  });

  final TextEditingController giftNameController;
  final TextEditingController validDaysController;
  final String title;
  final String actionLabel;
  final IconData actionIcon;
  final String? errorMessage;
  final VoidCallback? onClearError;
  final bool isSaving;
  final Future<bool> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: title, variant: AppTopBarVariant.modal),
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
              const _TemplateTypeField(),
              const SizedBox(height: 12),
              AppTextField(
                controller: giftNameController,
                label: 'Reward item',
                hint: 'Free Coffee',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: validDaysController,
                label: 'Valid for Days',
                hint: '30',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: actionLabel,
                icon: actionIcon,
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

class _TemplateTypeField extends StatelessWidget {
  const _TemplateTypeField();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextFormField(
        initialValue: 'Gift',
        enabled: false,
        decoration: const InputDecoration(labelText: 'Template type'),
      ),
    );
  }
}
