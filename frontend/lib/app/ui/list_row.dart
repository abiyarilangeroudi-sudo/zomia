import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        border: Border.all(color: BrandColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: leadingIcon == null
              ? null
              : CircleAvatar(
                  backgroundColor: BrandColors.teal.withValues(alpha: 0.12),
                  foregroundColor: BrandColors.teal,
                  child: Icon(leadingIcon),
                ),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing:
              trailing ??
              (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
          onTap: onTap,
        ),
      ),
    );
  }
}
