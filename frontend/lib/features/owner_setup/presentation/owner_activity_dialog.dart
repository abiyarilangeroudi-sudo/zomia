import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/ui.dart';
import '../data/owner_setup_repository.dart';
import '../domain/owner_setup_models.dart';
import 'owner_presenter.dart';

class OwnerRecentActionsDialog extends ConsumerStatefulWidget {
  const OwnerRecentActionsDialog({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<OwnerRecentActionsDialog> createState() =>
      _OwnerRecentActionsDialogState();
}

class _OwnerRecentActionsDialogState
    extends ConsumerState<OwnerRecentActionsDialog> {
  late Future<List<OwnerActivity>> _activityFuture;
  bool _isErrorDismissed = false;

  @override
  void initState() {
    super.initState();
    _activityFuture = _loadActivity();
  }

  Future<List<OwnerActivity>> _loadActivity() {
    return ref
        .read(ownerSetupRepositoryProvider)
        .listRecentActivity(businessId: widget.businessId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Staff Recent Actions',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 760,
          child: FutureBuilder<List<OwnerActivity>>(
            future: _activityFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const AppCard(
                  child: LoadingState(label: 'Loading staff actions'),
                );
              }
              if (snapshot.hasError) {
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_isErrorDismissed) ...[
                        InlineBanner(
                          message: snapshot.error.toString(),
                          tone: BannerTone.error,
                          onClose: () =>
                              setState(() => _isErrorDismissed = true),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SecondaryButton(
                        label: 'Try again',
                        icon: Icons.refresh_rounded,
                        onPressed: () {
                          setState(() {
                            _isErrorDismissed = false;
                            _activityFuture = _loadActivity();
                          });
                        },
                      ),
                    ],
                  ),
                );
              }
              final activities = snapshot.data ?? [];
              if (activities.isEmpty) {
                return const AppCard(
                  child: EmptyStateView(
                    icon: Icons.history_rounded,
                    title: 'No staff actions yet',
                    message:
                        'Staff activity will appear here after actions are registered.',
                  ),
                );
              }
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      title: 'Recent activity',
                      subtitle: 'Latest staff actions for this business.',
                    ),
                    const SizedBox(height: 12),
                    ...activities.map((activity) {
                      final presentation = ownerActivityPresentation(activity);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppListRow(
                          title: activity.summary,
                          subtitle: presentation.subtitle,
                          leadingIcon: Icons.history_rounded,
                          trailing: StatusBadge(
                            label: presentation.badgeLabel,
                            tone: presentation.badgeTone,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
