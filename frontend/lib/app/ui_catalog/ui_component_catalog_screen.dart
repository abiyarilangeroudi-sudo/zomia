import 'package:flutter/material.dart';

import '../ui/zomia_ui.dart';

class UiComponentCatalogScreen extends StatelessWidget {
  const UiComponentCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZomiaScaffold(
      appBar: ZomiaAppBar(
        title: 'UI Component Catalog',
        variant: ZomiaAppBarVariant.modal,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _CatalogIntro(),
          SizedBox(height: 16),
          _CatalogSection(title: 'Surface', child: _SurfaceExamples()),
          SizedBox(height: 16),
          _CatalogSection(title: 'Forms', child: _FormExamples()),
          SizedBox(height: 16),
          _CatalogSection(title: 'Feedback', child: _FeedbackExamples()),
          SizedBox(height: 16),
          _CatalogSection(title: 'Loyalty', child: _LoyaltyExamples()),
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
      variant: ZomiaCardVariant.highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZomiaSectionHeader(
            title: 'Zomia Design System',
            subtitle:
                'Temporary album for reviewing canonical UI components before dashboard recovery.',
          ),
          SizedBox(height: 12),
          ZomiaBanner(
            message:
                'This page is temporary and linked from the Login version label.',
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

class _SurfaceExamples extends StatelessWidget {
  const _SurfaceExamples();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _ComponentName('ZomiaCard / normal'),
        ZomiaCard(child: Text('Default card for dashboard sections.')),
        SizedBox(height: 12),
        _ComponentName('ZomiaCard / highlight'),
        ZomiaCard(
          variant: ZomiaCardVariant.highlight,
          child: Text(
            'Highlight card for primary context or important states.',
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
      children: const [
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
        _ComponentName('ZomiaPrimaryButton / loading'),
        ZomiaPrimaryButton(
          label: 'Create campaign',
          icon: Icons.flag,
          onPressed: null,
          isLoading: true,
        ),
        SizedBox(height: 12),
        _ComponentName('ZomiaSecondaryButton / icon'),
        ZomiaSecondaryButton(
          label: 'Scan with camera',
          icon: Icons.qr_code_scanner,
          onPressed: null,
        ),
      ],
    );
  }
}

class _FeedbackExamples extends StatelessWidget {
  const _FeedbackExamples();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
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
