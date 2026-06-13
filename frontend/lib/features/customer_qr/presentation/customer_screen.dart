import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/customer_qr_repository.dart';
import '../domain/customer_qr_token.dart';
import '../domain/customer_status.dart';
import 'customer_qr_dialog.dart';
import 'customer_views.dart';

class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key, required this.user});

  final CurrentUser user;

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
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
            DashboardScroll(
              child: CustomerHomeView(
                user: widget.user,
                status: _status,
                campaignProgresses: _campaignProgresses,
                isLoadingStatus: _isLoadingStatus,
                statusError: _statusError,
                onRefreshStatus: _loadStatus,
              ),
            ),
            DashboardScroll(
              child: CustomerCampaignView(
                campaignProgresses: _campaignProgresses,
                isLoadingStatus: _isLoadingStatus,
                statusError: _statusError,
              ),
            ),
            DashboardScroll(
              child: CustomerRewardView(
                status: _status,
                isLoadingStatus: _isLoadingStatus,
                statusError: _statusError,
              ),
            ),
            DashboardScroll(
              child: CustomerProfileView(
                user: widget.user,
                onSignOut: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
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
        builder: (context) => CustomerQrDialog(
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
}
