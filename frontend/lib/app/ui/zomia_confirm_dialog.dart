import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

enum ZomiaConfirmTone { standard, destructive }

Future<bool> showZomiaConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  ZomiaConfirmTone tone = ZomiaConfirmTone.standard,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ZomiaConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      tone: tone,
    ),
  );
  return result ?? false;
}

class ZomiaConfirmDialog extends StatelessWidget {
  const ZomiaConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.tone = ZomiaConfirmTone.standard,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final ZomiaConfirmTone tone;

  @override
  Widget build(BuildContext context) {
    final isDestructive = tone == ZomiaConfirmTone.destructive;
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
