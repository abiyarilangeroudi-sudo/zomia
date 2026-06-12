import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';

enum ZomiaAppBarVariant { main, modal, service }

class ZomiaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ZomiaAppBar({
    super.key,
    required this.title,
    this.variant = ZomiaAppBarVariant.main,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final ZomiaAppBarVariant variant;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final leading = switch (variant) {
      ZomiaAppBarVariant.modal => IconButton(
        tooltip: 'Close',
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.close_rounded),
      ),
      ZomiaAppBarVariant.service => IconButton(
        tooltip: 'Back',
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      ZomiaAppBarVariant.main => null,
    };
    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: BrandColors.teal,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
    );
  }
}
