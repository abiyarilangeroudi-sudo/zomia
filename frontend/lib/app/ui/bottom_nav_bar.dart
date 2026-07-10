import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  static const double contentHeight = 72;
  static const double minimumBottomClearance = 16;

  @override
  Widget build(BuildContext context) {
    final reportedBottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomClearance = reportedBottomInset > 0
        ? reportedBottomInset
        : minimumBottomClearance;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BrandColors.surface,
        border: Border(top: BorderSide(color: BrandColors.line)),
      ),
      child: SizedBox(
        height: contentHeight + bottomClearance,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomClearance),
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
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
      ),
    );
  }
}
