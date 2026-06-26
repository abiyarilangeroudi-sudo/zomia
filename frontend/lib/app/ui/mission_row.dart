import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

class MissionRow extends StatelessWidget {
  const MissionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.isEnabled = true,
  });

  final String title;
  final String subtitle;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease',
          onPressed: isEnabled && quantity > 0 ? onDecrement : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Increase',
          onPressed: isEnabled ? onIncrement : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        border: Border.all(color: BrandColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            );
            if (constraints.maxWidth < 380) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: controls),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: content),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }
}
