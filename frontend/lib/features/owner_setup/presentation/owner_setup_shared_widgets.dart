import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';

class OwnerSetupCard extends StatelessWidget {
  const OwnerSetupCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class OwnerSimpleList extends StatelessWidget {
  const OwnerSimpleList({
    super.key,
    required this.emptyTitle,
    required this.items,
    required this.leadingIcon,
    this.emptyMessage,
  });

  final String emptyTitle;
  final String? emptyMessage;
  final List<OwnerSimpleListItem> items;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateView(
        icon: leadingIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppListRow(
                title: item.title,
                subtitle: item.subtitle,
                leadingIcon: leadingIcon,
              ),
            ),
          )
          .toList(),
    );
  }
}

class OwnerSimpleListItem {
  const OwnerSimpleListItem({required this.title, this.subtitle});

  final String title;
  final String? subtitle;
}

class OwnerStatusBanners extends StatelessWidget {
  const OwnerStatusBanners({
    super.key,
    required this.error,
    required this.success,
    required this.onClearError,
    required this.onClearSuccess,
  });

  final String? error;
  final String? success;
  final VoidCallback onClearError;
  final VoidCallback onClearSuccess;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null)
          InlineBanner(
            message: error!,
            tone: BannerTone.error,
            onClose: onClearError,
          ),
        if (success != null)
          InlineBanner(
            message: success!,
            tone: BannerTone.success,
            onClose: onClearSuccess,
          ),
        if (error != null || success != null) const SizedBox(height: 16),
      ],
    );
  }
}

class OwnerNoBusinessCard extends StatelessWidget {
  const OwnerNoBusinessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: EmptyStateView(
        icon: Icons.store_outlined,
        title: 'No business found',
        message: 'Business setup will appear here when it is ready.',
      ),
    );
  }
}
