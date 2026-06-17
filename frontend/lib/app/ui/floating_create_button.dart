import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';
import '../brand/brand_spacing.dart';

class FloatingCreateButton extends StatelessWidget {
  const FloatingCreateButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: tooltip,
      backgroundColor: BrandColors.orange,
      foregroundColor: BrandColors.surface,
      shape: const CircleBorder(),
      onPressed: onPressed,
      child: const Icon(Icons.add_rounded),
    );
  }
}

class CreateActionSheetItem<T> {
  const CreateActionSheetItem({
    required this.value,
    required this.title,
    required this.icon,
    this.subtitle,
  });

  final T value;
  final String title;
  final IconData icon;
  final String? subtitle;
}

Future<T?> showCreateActionSheet<T>({
  required BuildContext context,
  required List<CreateActionSheetItem<T>> items,
  String title = 'Create',
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: BrandColors.surface,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BrandSpacing.screenPadding,
            0,
            BrandSpacing.screenPadding,
            BrandSpacing.screenPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: BrandSpacing.cardSpacing),
              for (final item in items) ...[
                _CreateActionSheetRow<T>(item: item),
                if (item != items.last)
                  const SizedBox(height: BrandSpacing.smallPadding),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _CreateActionSheetRow<T> extends StatelessWidget {
  const _CreateActionSheetRow({required this.item});

  final CreateActionSheetItem<T> item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        border: Border.all(color: BrandColors.line),
        borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: BrandSpacing.cardPadding,
            vertical: BrandSpacing.smallPadding,
          ),
          leading: CircleAvatar(
            backgroundColor: BrandColors.teal.withValues(alpha: 0.12),
            foregroundColor: BrandColors.teal,
            child: Icon(item.icon),
          ),
          title: Text(item.title),
          subtitle: item.subtitle == null ? null : Text(item.subtitle!),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).pop(item.value),
        ),
      ),
    );
  }
}
