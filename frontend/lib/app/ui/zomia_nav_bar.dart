import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

class ZomiaNavItem {
  const ZomiaNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class ZomiaBottomNavBar extends StatelessWidget {
  const ZomiaBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.maxWidth = 530,
  });

  final List<ZomiaNavItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: BrandColors.surface,
            border: Border(top: BorderSide(color: BrandColors.line)),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            currentIndex: selectedIndex,
            onTap: onChanged,
            backgroundColor: BrandColors.surface,
            selectedItemColor: BrandColors.orange,
            unselectedItemColor: BrandColors.textSecondary,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            items: items
                .map(
                  (item) => BottomNavigationBarItem(
                    icon: Icon(item.icon, size: 24),
                    activeIcon: Icon(item.activeIcon, size: 32),
                    label: item.label,
                    tooltip: item.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
