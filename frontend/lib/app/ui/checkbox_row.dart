import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

class CheckboxRow extends StatelessWidget {
  const CheckboxRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
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
          subtitle: Text(subtitle),
          controlAffinity: ListTileControlAffinity.trailing,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}
