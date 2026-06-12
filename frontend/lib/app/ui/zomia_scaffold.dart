import 'package:flutter/material.dart';

import '../brand/brand_spacing.dart';

enum ZomiaScaffoldVariant { scroll, fixed }

class ZomiaScaffold extends StatelessWidget {
  const ZomiaScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.variant = ZomiaScaffoldVariant.scroll,
    this.maxWidth = 860,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final ZomiaScaffoldVariant variant;
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
        child: variant == ZomiaScaffoldVariant.scroll
            ? ListView(children: [content])
            : content,
      ),
    );
  }
}
