import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';
import '../ui/zomia_ui.dart';

class UiComponentCatalogScreen extends StatelessWidget {
  const UiComponentCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZomiaScaffold(
      maxWidth: 960,
      appBar: ZomiaAppBar(
        title: 'UI Component Catalog',
        variant: ZomiaAppBarVariant.modal,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CatalogIntro(),
          const SizedBox(height: 16),
          const _CatalogSection(title: 'Brand Palette', child: _PaletteGrid()),
          const SizedBox(height: 16),
          _CatalogSection(title: 'Navigation', child: _NavigationExamples()),
          const SizedBox(height: 16),
          const _CatalogSection(title: 'Surface', child: _SurfaceExamples()),
          const SizedBox(height: 16),
          const _CatalogSection(title: 'Forms', child: _FormExamples()),
          const SizedBox(height: 16),
          const _CatalogSection(title: 'Feedback', child: _FeedbackExamples()),
          const SizedBox(height: 16),
          const _CatalogSection(title: 'Loyalty', child: _LoyaltyExamples()),
        ],
      ),
    );
  }
}

class _CatalogIntro extends StatelessWidget {
  const _CatalogIntro();

  @override
  Widget build(BuildContext context) {
    return const ZomiaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZomiaSectionHeader(
            title: 'Zomia Design System',
            subtitle:
                'Temporary review album for canonical components before dashboard recovery.',
          ),
          SizedBox(height: 12),
          ZomiaBanner(
            message:
                'Only components approved here should be reused in Login, Customer, Staff, and Owner dashboards.',
            tone: ZomiaBannerTone.info,
          ),
        ],
      ),
    );
  }
}

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ZomiaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ZomiaSectionHeader(title: title),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PaletteGrid extends StatelessWidget {
  const _PaletteGrid();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _PaletteSwatch('Primary Orange', BrandColors.orange, '#FFA100'),
        _PaletteSwatch('Secondary Teal', BrandColors.teal, '#18AA99'),
        _PaletteSwatch('Tertiary Purple', BrandColors.purple, '#827AE1'),
        _PaletteSwatch('Alternate Red', BrandColors.red, '#FF5963'),
        _PaletteSwatch('Background', BrandColors.background, '#F4F6FC'),
        _PaletteSwatch('Surface', BrandColors.surface, '#FFFFFF'),
        _PaletteSwatch('Line', BrandColors.line, '#DBE2E7'),
        _PaletteSwatch('Text', BrandColors.textPrimary, '#101213'),
      ],
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch(this.name, this.color, this.hex);

  final String name;
  final Color color;
  final String hex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.surface,
          border: Border.all(color: BrandColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: BrandColors.line),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox(width: double.infinity, height: 44),
              ),
              const SizedBox(height: 10),
              Text(name, style: textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(
                hex,
                style: textTheme.bodySmall?.copyWith(
                  color: BrandColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationExamples extends StatelessWidget {
  const _NavigationExamples();

  static const _navItems = [
    ZomiaNavItem(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    ZomiaNavItem(
      label: 'Campaigns',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign_rounded,
    ),
    ZomiaNavItem(
      label: 'Rewards',
      icon: Icons.card_giftcard_outlined,
      activeIcon: Icons.card_giftcard_rounded,
    ),
    ZomiaNavItem(
      label: 'Groups',
      icon: Icons.group_outlined,
      activeIcon: Icons.group_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ComponentName('ZomiaAppBar / main'),
        _AppBarPreview(
          child: ZomiaAppBar(
            title: 'Customer Dashboard',
            onMenu: () {},
            actions: [
              IconButton(
                tooltip: 'QR',
                onPressed: () {},
                icon: const Icon(Icons.qr_code_rounded),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _ComponentName('ZomiaAppBar / business'),
        _AppBarPreview(
          child: ZomiaAppBar(
            title: 'Staff Dashboard',
            variant: ZomiaAppBarVariant.business,
            onMenu: () {},
            actions: [
              IconButton(
                tooltip: 'Scan',
                onPressed: () {},
                icon: const Icon(Icons.qr_code_scanner_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _ComponentName('ZomiaBottomNavBar'),
        _PhoneChrome(
          child: ZomiaBottomNavBar(
            items: _navItems,
            selectedIndex: 1,
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}

class _AppBarPreview extends StatelessWidget {
  const _AppBarPreview({required this.child});

  final PreferredSizeWidget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: BrandColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: child.preferredSize.height, child: child),
      ),
    );
  }
}

class _PhoneChrome extends StatelessWidget {
  const _PhoneChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.background,
        border: Border.all(color: BrandColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: const EdgeInsets.only(top: 56), child: child),
    );
  }
}

class _SurfaceExamples extends StatelessWidget {
  const _SurfaceExamples();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComponentName('ZomiaCard / normal'),
        ZomiaCard(child: Text('Default white card for dashboard sections.')),
        SizedBox(height: 12),
        _ComponentName('ZomiaCard / highlight'),
        ZomiaCard(
          variant: ZomiaCardVariant.highlight,
          child: Text(
            'Teal accent card for primary context without muddy color mixing.',
          ),
        ),
      ],
    );
  }
}

class _FormExamples extends StatelessWidget {
  const _FormExamples();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComponentName('ZomiaTextField / email'),
        ZomiaTextField(
          label: 'Email',
          hint: 'customer@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 12),
        _ComponentName('ZomiaTextField / password'),
        ZomiaTextField(label: 'Password', obscureText: true),
        SizedBox(height: 12),
        _ComponentName('ZomiaPrimaryButton / icon'),
        ZomiaPrimaryButton(
          label: 'Create campaign',
          icon: Icons.flag_rounded,
          onPressed: _noop,
        ),
        SizedBox(height: 12),
        _ComponentName('ZomiaSecondaryButton / icon'),
        ZomiaSecondaryButton(
          label: 'Scan with camera',
          icon: Icons.qr_code_scanner_rounded,
          onPressed: _noop,
        ),
      ],
    );
  }
}

void _noop() {}

class _FeedbackExamples extends StatelessWidget {
  const _FeedbackExamples();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComponentName('ZomiaBanner'),
        ZomiaBanner(message: 'Mission created.', tone: ZomiaBannerTone.success),
        SizedBox(height: 8),
        ZomiaBanner(
          message: 'Something went wrong.',
          tone: ZomiaBannerTone.error,
        ),
        SizedBox(height: 12),
        _ComponentName('ZomiaBadge'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ZomiaBadge(label: 'Active', tone: ZomiaBadgeTone.success),
            ZomiaBadge(label: 'Pending', tone: ZomiaBadgeTone.warning),
            ZomiaBadge(label: 'Info', tone: ZomiaBadgeTone.info),
            ZomiaBadge(label: 'Neutral'),
          ],
        ),
        SizedBox(height: 12),
        _ComponentName('ZomiaEmptyState'),
        ZomiaEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No rewards yet',
          message: 'Rewards will appear after campaign completion.',
        ),
      ],
    );
  }
}

class _LoyaltyExamples extends StatelessWidget {
  const _LoyaltyExamples();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComponentName('ZomiaProgressCard / active'),
        ZomiaProgressCard(
          title: 'Coffee Reward',
          subtitle: 'Zomia Cafe',
          value: 0.6,
          label: '6/10 pts · 4 pts to reward',
        ),
        SizedBox(height: 12),
        _ComponentName('ZomiaProgressCard / completed'),
        ZomiaProgressCard(
          title: 'Cake Reward',
          subtitle: 'Zomia Cafe',
          value: 1,
          label: '10/10 pts · Completed',
          isCompleted: true,
        ),
      ],
    );
  }
}

class _ComponentName extends StatelessWidget {
  const _ComponentName(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(name, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
