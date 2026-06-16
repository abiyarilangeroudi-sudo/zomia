import 'package:flutter/material.dart';

class DashboardScroll extends StatelessWidget {
  const DashboardScroll({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ],
    );
  }
}
