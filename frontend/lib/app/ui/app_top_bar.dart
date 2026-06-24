import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

enum AppTopBarVariant { main, modal, service, business }

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.variant = AppTopBarVariant.main,
    this.onBack,
    this.onMenu,
    this.actions = const [],
  });

  final String title;
  final AppTopBarVariant variant;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final Widget? leading = switch (variant) {
      AppTopBarVariant.modal => IconButton(
        tooltip: 'Close',
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.close_rounded),
      ),
      AppTopBarVariant.service => IconButton(
        tooltip: 'Back',
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      AppTopBarVariant.main || AppTopBarVariant.business =>
        onMenu == null
            ? null
            : IconButton(
                tooltip: 'Menu',
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded),
              ),
    };
    final centerTitle = switch (variant) {
      AppTopBarVariant.modal || AppTopBarVariant.service => true,
      AppTopBarVariant.main || AppTopBarVariant.business => false,
    };
    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: BrandColors.surface,
      foregroundColor: BrandColors.teal,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: BrandColors.teal,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [...actions, const SizedBox(width: 8)],
    );
  }
}
