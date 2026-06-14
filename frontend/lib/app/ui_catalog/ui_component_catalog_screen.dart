import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';
import '../ui/ui.dart';

class UiComponentCatalogScreen extends StatelessWidget {
  const UiComponentCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      maxWidth: 960,
      appBar: AppTopBar(
        title: 'UI Component Catalog',
        variant: AppTopBarVariant.modal,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CatalogIntro(),
          const SizedBox(height: 16),
          const _CatalogSection(title: 'Brand Palette', child: _PaletteGrid()),
          const SizedBox(height: 16),
          const _CatalogSection(title: 'Typography', child: _TypographyScale()),
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
          const SizedBox(height: 16),
          const _CatalogSection(
            title: 'MVP Workflow',
            child: _MvpWorkflowExamples(),
          ),
        ],
      ),
    );
  }
}

class _CatalogIntro extends StatelessWidget {
  const _CatalogIntro();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Zomia Design System',
            subtitle:
                'Temporary review album for canonical components before dashboard recovery.',
          ),
          SizedBox(height: 12),
          InlineBanner(
            message:
                'Only components approved here should be reused in Login, Customer, Staff, and Owner dashboards.',
            tone: BannerTone.info,
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title),
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

class _TypographyScale extends StatelessWidget {
  const _TypographyScale();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TypeSample('H0', 'Major page headline', textTheme.displaySmall),
        _TypeSample('H1', 'Dashboard title', textTheme.headlineMedium),
        _TypeSample('H2', 'Section title', textTheme.headlineSmall),
        _TypeSample('H3', 'Card title', textTheme.titleLarge),
        _TypeSample('H4', 'Compact title', textTheme.titleMedium),
        _TypeSample('Title', 'Component label', textTheme.labelLarge),
        _TypeSample('Subtitle', 'Supporting context', textTheme.bodyLarge),
        _TypeSample('P1', 'Primary paragraph text', textTheme.bodyMedium),
        _TypeSample('P2', 'Secondary paragraph text', textTheme.bodySmall),
      ],
    );
  }
}

class _TypeSample extends StatelessWidget {
  const _TypeSample(this.token, this.text, this.style);

  final String token;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              token,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: BrandColors.teal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _NavigationExamples extends StatelessWidget {
  const _NavigationExamples();

  static const _navItems = [
    NavItem(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    NavItem(
      label: 'Campaigns',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign_rounded,
    ),
    NavItem(
      label: 'Rewards',
      icon: Icons.card_giftcard_outlined,
      activeIcon: Icons.card_giftcard_rounded,
    ),
    NavItem(
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
        const _ComponentName('AppTopBar / main'),
        _AppBarPreview(
          child: AppTopBar(
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
        const _ComponentName('AppTopBar / business'),
        _AppBarPreview(
          child: AppTopBar(
            title: 'Staff Dashboard',
            variant: AppTopBarVariant.business,
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
        const _ComponentName('BottomNavBar'),
        _PhoneChrome(
          child: BottomNavBar(
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
      child: Padding(
        padding: const EdgeInsets.only(top: 56),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SurfaceExamples extends StatelessWidget {
  const _SurfaceExamples();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComponentName('AppCard / normal'),
        AppCard(child: Text('Default white card for dashboard sections.')),
        SizedBox(height: 12),
        _ComponentName('AppCard / highlight'),
        AppCard(
          variant: AppCardVariant.highlight,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComponentName('AppTextField / email'),
        AppTextField(
          label: 'Email',
          hint: 'customer@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 12),
        _ComponentName('AppTextField / password'),
        AppTextField(label: 'Password', obscureText: true),
        SizedBox(height: 12),
        _ComponentName('PrimaryButton / icon'),
        PrimaryButton(
          label: 'Create campaign',
          icon: Icons.flag_rounded,
          onPressed: _noop,
        ),
        SizedBox(height: 12),
        _ComponentName('SecondaryButton / icon'),
        SecondaryButton(
          label: 'Resolve Customer',
          icon: Icons.search_rounded,
          onPressed: _noop,
        ),
        SizedBox(height: 12),
        _ComponentName('PrimaryButton / scan action'),
        PrimaryButton(
          label: 'Scan with Camera',
          icon: Icons.qr_code_scanner_rounded,
          onPressed: _noop,
        ),
        SizedBox(height: 12),
        _ComponentName('Campaign repeatability controls'),
        AppDateField(
          label: 'Start date',
          value: DateTime(2026, 6, 14),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          onChanged: _noopDate,
        ),
        SizedBox(height: 8),
        AppDateField(
          label: 'End date',
          value: DateTime(2026, 9, 14),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          onChanged: _noopDate,
        ),
        SizedBox(height: 8),
        ToggleRow(
          title: 'Repeatable campaign',
          value: true,
          onChanged: _noopValue,
        ),
        SizedBox(height: 8),
        CheckboxRow(
          title: 'Limit completions',
          value: false,
          onChanged: _noopValue,
        ),
        SizedBox(height: 8),
        AppTextField(
          label: 'Max completions per customer',
          hint: '2',
          keyboardType: TextInputType.number,
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
        _ComponentName('InlineBanner'),
        InlineBanner(message: 'Mission created.', tone: BannerTone.success),
        SizedBox(height: 8),
        InlineBanner(message: 'Something went wrong.', tone: BannerTone.error),
        SizedBox(height: 12),
        _ComponentName('StatusBadge'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusBadge(label: 'Active', tone: BadgeTone.success),
            StatusBadge(label: 'Pending', tone: BadgeTone.warning),
            StatusBadge(label: 'Info', tone: BadgeTone.info),
            StatusBadge(label: 'Neutral'),
          ],
        ),
        SizedBox(height: 12),
        _ComponentName('EmptyStateView'),
        EmptyStateView(
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
        _ComponentName('ProgressCard / active'),
        ProgressCard(
          title: 'Coffee Reward',
          subtitle: 'Zomia Cafe',
          value: 0.6,
          label: '6/10 pts · 4 pts to reward',
        ),
        SizedBox(height: 12),
        _ComponentName('ProgressCard / completed'),
        ProgressCard(
          title: 'Cake Reward',
          subtitle: 'Zomia Cafe',
          value: 1,
          label: '10/10 pts · Completed',
          isCompleted: true,
        ),
        SizedBox(height: 12),
        _ComponentName('RewardCard / customer'),
        RewardCard(
          title: 'Free Coffee',
          subtitle: 'Gift reward',
          expiresLabel: 'Valid until 2026-07-12',
        ),
        SizedBox(height: 12),
        _ComponentName('RewardCard / staff-action'),
        RewardCard(
          title: 'Free Coffee',
          subtitle: 'Use for loaded customer',
          expiresLabel: 'Valid until 2026-07-12',
          variant: RewardCardVariant.staffAction,
          onUse: _noop,
        ),
      ],
    );
  }
}

class _MvpWorkflowExamples extends StatelessWidget {
  const _MvpWorkflowExamples();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ComponentName('QRCard / customer'),
        QRCard(
          title: 'Ready to Scan',
          message: 'Show this QR to staff during service.',
          token: 'J8Gd1wSboWryp_HA22Qc7Q',
          primaryActionLabel: 'Refresh QR token',
          primaryActionIcon: Icons.refresh_rounded,
          onPrimaryAction: _noop,
        ),
        SizedBox(height: 12),
        _ComponentName('QRCard / staff-scan'),
        QRCard(
          title: 'Customer QR',
          message: 'Scan the customer QR with the camera.',
          variant: QRCardVariant.staffScan,
          primaryActionLabel: 'Scan with Camera',
          primaryActionIcon: Icons.qr_code_scanner_rounded,
          onPrimaryAction: _noop,
        ),
        SizedBox(height: 12),
        _ComponentName('MissionRow / quantity'),
        MissionRow(
          title: 'Buy Coffee',
          subtitle: '1 point each',
          quantity: 2,
          onIncrement: _noop,
          onDecrement: _noop,
        ),
        SizedBox(height: 12),
        _ComponentName('MetricPill'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MetricPill(
              icon: Icons.redeem_rounded,
              label: '1 active reward',
              color: BrandColors.purple,
            ),
            MetricPill(
              icon: Icons.flag_rounded,
              label: '2 campaigns',
              color: BrandColors.teal,
            ),
            MetricPill(
              icon: Icons.history_rounded,
              label: '3 recent actions',
              color: BrandColors.info,
            ),
          ],
        ),
        SizedBox(height: 12),
        _ComponentName('AppListRow'),
        AppListRow(
          title: 'Zomia Cafe',
          subtitle: 'EUR · Europe/Berlin',
          leadingIcon: Icons.storefront_rounded,
          onTap: _noop,
        ),
        SizedBox(height: 12),
        _ComponentName('SelectField'),
        SelectField<String>(
          label: 'Business',
          value: 'zomia-cafe',
          options: [
            SelectFieldOption(value: 'zomia-cafe', label: 'Zomia Cafe'),
            SelectFieldOption(value: 'demo-shop', label: 'Demo Shop'),
          ],
          onChanged: _noopValue,
        ),
        SizedBox(height: 12),
        _ComponentName('CheckboxRow'),
        CheckboxRow(
          title: 'Buy Coffee',
          subtitle: '1 point',
          value: true,
          onChanged: _noopValue,
        ),
        SizedBox(height: 12),
        _ComponentName('LoadingState'),
        LoadingState(label: 'Loading service data'),
        SizedBox(height: 12),
        _ComponentName('ScannerSheetFrame'),
        ScannerSheetFrame(),
        SizedBox(height: 12),
        _ComponentName('ConfirmDialog / standard'),
        _DialogPreview(
          title: 'Use this Reward?',
          message: 'This will mark the reward as used for the loaded customer.',
          confirmLabel: 'Use Reward',
        ),
        SizedBox(height: 12),
        _ComponentName('ConfirmDialog / destructive'),
        _DialogPreview(
          title: 'Discard changes?',
          message: 'Unsaved setup changes will be lost.',
          confirmLabel: 'Discard',
          tone: ConfirmTone.destructive,
        ),
      ],
    );
  }
}

class _DialogPreview extends StatelessWidget {
  const _DialogPreview({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.tone = ConfirmTone.standard,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final ConfirmTone tone;

  @override
  Widget build(BuildContext context) {
    final isDestructive = tone == ConfirmTone.destructive;
    final confirmButton = isDestructive
        ? SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: BrandColors.error),
              onPressed: _noop,
              child: Text(confirmLabel),
            ),
          )
        : PrimaryButton(label: confirmLabel, onPressed: _noop);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BrandColors.surface,
            border: Border.all(color: BrandColors.line),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message),
                const SizedBox(height: 16),
                confirmButton,
                const SizedBox(height: 10),
                SecondaryButton(label: 'Cancel', onPressed: _noop),
              ],
            ),
          ),
        ),
      ),
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

void _noopValue(Object? value) {}

void _noopDate(DateTime value) {}
