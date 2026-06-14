import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

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
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle!),
          activeThumbColor: BrandColors.surface,
          activeTrackColor: BrandColors.orange,
          inactiveThumbColor: BrandColors.textSecondary,
          inactiveTrackColor: BrandColors.line,
          trackOutlineColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? BrandColors.orange
                : BrandColors.line,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}
