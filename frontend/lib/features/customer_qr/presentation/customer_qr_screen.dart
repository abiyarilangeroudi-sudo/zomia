import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/customer_qr_repository.dart';
import '../domain/customer_qr_token.dart';
import '../domain/customer_status.dart';

class CustomerQrScreen extends ConsumerStatefulWidget {
  const CustomerQrScreen({super.key, required this.user});

  final CurrentUser user;

  @override
  ConsumerState<CustomerQrScreen> createState() => _CustomerQrScreenState();
}

class _CustomerQrScreenState extends ConsumerState<CustomerQrScreen> {
  CustomerQrToken? _token;
  CustomerStatus? _status;
  List<CustomerCampaignProgress> _campaignProgresses = [];
  String? _qrError;
  String? _statusError;
  bool _isLoadingQr = true;
  bool _isLoadingStatus = true;
  bool _isRotating = false;
  int _selectedIndex = 0;

  static const _tabs = [
    NavItem(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    NavItem(
      label: 'Campaign',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign_rounded,
    ),
    NavItem(
      label: 'Reward',
      icon: Icons.card_giftcard_outlined,
      activeIcon: Icons.card_giftcard_rounded,
    ),
    NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _issueToken();
      _loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Customer Dashboard',
        onMenu: () {},
        actions: [
          IconButton(
            tooltip: 'Show QR code',
            onPressed: _openQrDialog,
            icon: const Icon(Icons.qr_code_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _DashboardScroll(child: _buildHomeView()),
            _DashboardScroll(child: _buildCampaignView()),
            _DashboardScroll(child: _buildRewardView()),
            _DashboardScroll(child: _buildProfileView()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        items: _tabs,
        selectedIndex: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildHomeView() {
    final activeRewardsCount = _status?.activeRewardsCount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${widget.user.fullName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(widget.user.email),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MetricPill(
                    icon: Icons.campaign_rounded,
                    label: '${_campaignProgresses.length} campaigns',
                    color: BrandColors.teal,
                  ),
                  MetricPill(
                    icon: Icons.card_giftcard_rounded,
                    label: '$activeRewardsCount active rewards',
                    color: BrandColors.purple,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingStatus)
          const AppCard(child: LoadingState(label: 'Loading status'))
        else if (_statusError != null)
          InlineBanner(message: _statusError!, tone: BannerTone.error)
        else if (_campaignProgresses.isEmpty && activeRewardsCount == 0)
          const AppCard(
            child: EmptyStateView(
              icon: Icons.loyalty_outlined,
              title: 'No loyalty activity yet',
              message: 'Campaign progress and active rewards will appear here.',
            ),
          )
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'Current Status',
                  subtitle: 'Refresh after staff registers an action.',
                  trailing: IconButton(
                    tooltip: 'Refresh status',
                    onPressed: _isLoadingStatus ? null : _loadStatus,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                if (_campaignProgresses.isNotEmpty)
                  ProgressCard(
                    title: _campaignProgresses.first.campaignName,
                    subtitle: _campaignProgresses.first.businessName,
                    value: _campaignProgresses.first.progressRatio,
                    label: _progressLabel(_campaignProgresses.first),
                    isCompleted: _campaignProgresses.first.isCompleted,
                  ),
                if (activeRewardsCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$activeRewardsCount active rewards available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCampaignView() {
    if (_isLoadingStatus) {
      return const AppCard(child: LoadingState(label: 'Loading campaigns'));
    }
    if (_statusError != null) {
      return InlineBanner(message: _statusError!, tone: BannerTone.error);
    }
    if (_campaignProgresses.isEmpty) {
      return const AppCard(
        child: EmptyStateView(
          icon: Icons.campaign_outlined,
          title: 'No campaign progress',
          message: 'Progress appears after staff registers matching actions.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Campaign Progress',
          subtitle: 'Only campaign-based progress is shown here.',
        ),
        const SizedBox(height: 12),
        ..._campaignProgresses.map(
          (progress) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProgressCard(
              title: progress.campaignName,
              subtitle: progress.businessName,
              value: progress.progressRatio,
              label: _progressLabel(progress),
              isCompleted: progress.isCompleted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardView() {
    if (_isLoadingStatus) {
      return const AppCard(child: LoadingState(label: 'Loading rewards'));
    }
    if (_statusError != null) {
      return InlineBanner(message: _statusError!, tone: BannerTone.error);
    }
    final rewards = _activeRewards();
    if (rewards.isEmpty) {
      return const AppCard(
        child: EmptyStateView(
          icon: Icons.card_giftcard_outlined,
          title: 'No active rewards',
          message: 'Rewards will appear after campaign completion.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Active Rewards',
          subtitle: 'Show available rewards to staff during service.',
        ),
        const SizedBox(height: 12),
        ...rewards.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RewardCard(
              title: entry.reward.title,
              subtitle: '${entry.businessName} · ${entry.reward.displayValue}',
              expiresLabel:
                  'Expires ${_formatDateTime(entry.reward.expiresAt)}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'Profile',
                subtitle: 'Customer account for this MVP session.',
              ),
              const SizedBox(height: 12),
              AppListRow(
                title: widget.user.fullName,
                subtitle: widget.user.email,
                leadingIcon: Icons.person_rounded,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Sign out',
                icon: Icons.logout_rounded,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _issueToken() async {
    setState(() {
      _isLoadingQr = true;
      _qrError = null;
    });
    try {
      final token = await ref.read(customerQrRepositoryProvider).issueToken();
      if (!mounted) {
        return;
      }
      setState(() {
        _token = token;
        _isLoadingQr = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _qrError = error.toString();
        _isLoadingQr = false;
      });
    }
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoadingStatus = true;
      _statusError = null;
    });
    try {
      final repository = ref.read(customerQrRepositoryProvider);
      final status = await repository.getStatus();
      final campaignProgresses = await repository.getCampaignProgresses();
      if (!mounted) {
        return;
      }
      setState(() {
        _status = status;
        _campaignProgresses = campaignProgresses;
        _isLoadingStatus = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusError = error.toString();
        _isLoadingStatus = false;
      });
    }
  }

  Future<void> _rotateToken() async {
    setState(() {
      _isRotating = true;
      _qrError = null;
    });
    try {
      final token = await ref.read(customerQrRepositoryProvider).rotateToken();
      if (!mounted) {
        return;
      }
      setState(() {
        _token = token;
        _isRotating = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _qrError = error.toString();
        _isRotating = false;
      });
    }
  }

  void _openQrDialog() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _CustomerQrDialog(
          token: _token,
          isLoading: _isLoadingQr,
          isRotating: _isRotating,
          error: _qrError,
          onRefresh: _isLoadingQr || _isRotating ? null : _rotateToken,
          onRetry: _issueToken,
        ),
      ),
    );
  }

  List<_RewardEntry> _activeRewards() {
    final status = _status;
    if (status == null) {
      return const [];
    }
    return [
      for (final business in status.businesses)
        for (final reward in business.activeRewards)
          _RewardEntry(businessName: business.businessName, reward: reward),
    ];
  }
}

class _DashboardScroll extends StatelessWidget {
  const _DashboardScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _CustomerQrDialog extends StatelessWidget {
  const _CustomerQrDialog({
    required this.token,
    required this.isLoading,
    required this.isRotating,
    required this.error,
    required this.onRefresh,
    required this.onRetry,
  });

  final CustomerQrToken? token;
  final bool isLoading;
  final bool isRotating;
  final String? error;
  final VoidCallback? onRefresh;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Customer QR', variant: AppTopBarVariant.modal),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 530),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final token = this.token;
    if (isLoading && token == null) {
      return const AppCard(child: LoadingState(label: 'Loading QR code'));
    }
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InlineBanner(message: error!, tone: BannerTone.error),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      );
    }
    if (token == null) {
      return const AppCard(
        child: EmptyStateView(
          icon: Icons.qr_code_rounded,
          title: 'QR code unavailable',
          message: 'Try again before service.',
        ),
      );
    }
    return QRCard(
      title: 'Ready to Scan',
      message:
          'Show this QR to staff. Expires ${_formatDateTime(token.expiresAt)}.',
      token: token.token,
      primaryActionLabel: isRotating ? 'Refreshing' : 'Refresh QR token',
      primaryActionIcon: Icons.refresh_rounded,
      onPrimaryAction: onRefresh,
    );
  }
}

class _RewardEntry {
  const _RewardEntry({required this.businessName, required this.reward});

  final String businessName;
  final CustomerReward reward;
}

String _progressLabel(CustomerCampaignProgress progress) {
  final label = progress.isCompleted
      ? 'Completed'
      : '${progress.remainingPoints} pts to reward';
  return '${progress.progressPoints}/${progress.thresholdPoints} pts · $label';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
