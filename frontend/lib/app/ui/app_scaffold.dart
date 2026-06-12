import 'package:flutter/material.dart';

import '../brand/brand_spacing.dart';

enum AppScaffoldVariant { scroll, fixed }

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.variant = AppScaffoldVariant.scroll,
    this.maxWidth = 860,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final AppScaffoldVariant variant;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(BrandSpacing.screenPadding),
          child: body,
        ),
      ),
    );
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: variant == AppScaffoldVariant.scroll
            ? ListView(children: [content])
            : content,
      ),
    );
  }
}
