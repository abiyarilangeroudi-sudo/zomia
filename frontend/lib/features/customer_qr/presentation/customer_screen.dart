import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/external_url_launcher.dart';
import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../../auth/presentation/account_settings_dialog.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/customer_qr_repository.dart';
import '../domain/customer_qr_token.dart';
import '../domain/customer_status.dart';
import 'customer_home_view.dart';
import 'customer_qr_dialog.dart';
import 'customer_views.dart';

class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key, required this.user});

  final CurrentUser user;

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  CustomerQrToken? _token;
  CustomerStatus? _status;
  List<CustomerCampaignProgress> _campaignProgresses = [];
  String? _qrError;
  String? _statusError;
  bool _isLoadingQr = true;
  bool _isLoadingStatus = true;
  int _selectedIndex = 0;
  int _campaignTabIndex = 0;
  int _rewardTabIndex = 0;

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
  ];

  static const _titles = ['Home', 'Campaign', 'Reward'];

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
      key: _scaffoldKey,
      drawer: AppDrawer(
        items: [
          AppDrawerItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            onTap: _openProfileDialogFromDrawer,
          ),
          AppDrawerItem(
            label: 'Setting',
            icon: Icons.settings_outlined,
            onTap: _openSettingsDialogFromDrawer,
          ),
          AppDrawerItem(
            label: 'Legal',
            icon: Icons.policy_outlined,
            onTap: _openLegalFromDrawer,
          ),
          AppDrawerItem(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            onTap: _signOutFromDrawer,
          ),
        ],
      ),
      appBar: AppTopBar(
        title: _titles[_selectedIndex],
        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
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
            RefreshIndicator(
              onRefresh: _loadStatus,
              child: DashboardScroll(
                physics: const AlwaysScrollableScrollPhysics(),
                child: CustomerHomeView(
                  user: widget.user,
                  status: _status,
                  campaignProgresses: _campaignProgresses,
                  onShowQr: _openQrDialog,
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: _loadStatus,
              child: DashboardScroll(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                child: CustomerCampaignView(
                  campaignProgresses: _campaignProgresses,
                  isLoadingStatus: _isLoadingStatus,
                  statusError: _statusError,
                  onClearStatusError: _clearStatusError,
                  selectedTabIndex: _campaignTabIndex,
                  onTabChanged: (index) =>
                      setState(() => _campaignTabIndex = index),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: _loadStatus,
              child: DashboardScroll(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                child: CustomerRewardView(
                  status: _status,
                  isLoadingStatus: _isLoadingStatus,
                  statusError: _statusError,
                  onClearStatusError: _clearStatusError,
                  selectedTabIndex: _rewardTabIndex,
                  onTabChanged: (index) =>
                      setState(() => _rewardTabIndex = index),
                ),
              ),
            ),
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

  Future<void> _issueToken() async {
    setState(() {
      _isLoadingQr = true;
      _qrError = null;
    });
    try {
      final repository = ref.read(customerQrRepositoryProvider);
      final cachedToken = await repository.readCachedToken();
      if (cachedToken != null &&
          cachedToken.expiresAt.isAfter(DateTime.now())) {
        if (!mounted) {
          return;
        }
        setState(() {
          _token = cachedToken;
          _isLoadingQr = false;
        });
        return;
      }
      final token = await repository.issueToken();
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

  void _clearStatusError() {
    if (_statusError == null) {
      return;
    }
    setState(() => _statusError = null);
  }

  void _openQrDialog() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => CustomerQrDialog(
          token: _token,
          isLoading: _isLoadingQr,
          error: _qrError,
          onTokenChanged: (token) {
            if (!mounted) {
              return;
            }
            setState(() => _token = token);
          },
          onRetry: _issueToken,
        ),
      ),
    );
  }

  void _openProfileDialogFromDrawer() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => CustomerProfileDialog(
          user: widget.user,
          onUpdateName: (fullName) => ref
              .read(authControllerProvider.notifier)
              .updateCustomerProfile(fullName: fullName),
        ),
      ),
    );
  }

  void _openSettingsDialogFromDrawer() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => AccountSettingsDialog(
          onChangePassword:
              ({
                required String currentPassword,
                required String newPassword,
              }) => ref
                  .read(authControllerProvider.notifier)
                  .changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                  ),
          onStartEmailChange:
              ({required String newEmail, required String currentPassword}) =>
                  ref
                      .read(authControllerProvider.notifier)
                      .startEmailChange(
                        newEmail: newEmail,
                        currentPassword: currentPassword,
                      ),
          onVerifyEmailChange:
              ({required String newEmail, required String code}) => ref
                  .read(authControllerProvider.notifier)
                  .verifyEmailChange(newEmail: newEmail, code: code),
          onRemoveAccount: ({required String currentPassword}) => ref
              .read(authControllerProvider.notifier)
              .removeAccount(currentPassword: currentPassword),
        ),
      ),
    );
  }

  void _signOutFromDrawer() {
    Navigator.of(context).pop();
    ref.read(authControllerProvider.notifier).signOut();
  }

  void _openLegalFromDrawer() {
    Navigator.of(context).pop();
    openExternalUrl('https://zomia.eu/legal');
  }
}
