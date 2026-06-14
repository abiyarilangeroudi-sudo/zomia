import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

class CheckboxRow extends StatelessWidget {
  const CheckboxRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        border: Border.all(
          color: value ? BrandColors.orange : BrandColors.line,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: CheckboxListTile(
          value: value,
          onChanged: onChanged,
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle!),
          controlAffinity: ListTileControlAffinity.trailing,
          activeColor: BrandColors.orange,
          checkColor: BrandColors.surface,
          side: const BorderSide(color: BrandColors.textSecondary, width: 1.6),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}
