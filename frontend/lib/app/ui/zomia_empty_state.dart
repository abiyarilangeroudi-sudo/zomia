import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

enum ZomiaEmptyStateSize { small, large }

class ZomiaEmptyState extends StatelessWidget {
  const ZomiaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.size = ZomiaEmptyStateSize.small,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final ZomiaEmptyStateSize size;

  @override
  Widget build(BuildContext context) {
    final large = size == ZomiaEmptyStateSize.large;
    return Padding(
      padding: EdgeInsets.all(large ? 32 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: BrandColors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(large ? 18 : 12),
              child: Icon(icon, size: large ? 44 : 28, color: BrandColors.teal),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BrandColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
