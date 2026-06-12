import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label = 'Loading'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BrandColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
