import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

enum ConfirmTone { standard, destructive }

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  ConfirmTone tone = ConfirmTone.standard,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      tone: tone,
    ),
  );
  return result ?? false;
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.tone = ConfirmTone.standard,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final ConfirmTone tone;

  @override
  Widget build(BuildContext context) {
    final isDestructive = tone == ConfirmTone.destructive;
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(backgroundColor: BrandColors.error)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
