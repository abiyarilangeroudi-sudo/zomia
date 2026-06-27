import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../brand/brand_colors.dart';
import '../brand/brand_spacing.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.items,
    this.title,
    this.subtitle,
    this.footer,
  });

  final String? title;
  final String? subtitle;
  final List<AppDrawerItem> items;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 16,
      backgroundColor: BrandColors.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BrandSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 70,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(
                    'assets/brand/zomia_logo.svg',
                    width: 140,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (title != null || subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      if (title != null && subtitle != null)
                        const SizedBox(height: 2),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: BrandColors.textSecondary),
                        ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DrawerAction(item: item),
                      ),
                    ),
                  ],
                ),
              ),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerAction extends StatelessWidget {
  const _DrawerAction({required this.item});

  final AppDrawerItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(item.icon, color: BrandColors.textSecondary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppDrawerItem {
  const AppDrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}
