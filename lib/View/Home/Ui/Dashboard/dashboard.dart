import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/digital_clock.dart';
import 'package:zpharmacy/View/Auth/bloc/auth_bloc.dart';
import 'package:zpharmacy/View/Home/Ui/Dashboard/stats_view.dart';

import '../../bloc/menu_bloc.dart';
import 'bloc/dashboard_stats_bloc.dart';
import '../Report/ExpiryNotify/expiry_notify.dart';
import '../Report/ExpiryNotify/bloc/expiry_notify_bloc.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshSilentlyIfReady();
    });
  }

  void _refreshSilentlyIfReady() {
    final statsBloc  = context.read<DashboardStatsBloc>();
    final notifyBloc = context.read<ExpiryNotifyBloc>();

    final hasStats  = statsBloc.state  is DashboardStatsLoaded;
    final hasNotify = notifyBloc.state is ExpiryNotifyLoaded;

    statsBloc.add(DashboardStatsLoadRequested(silent: hasStats));
    notifyBloc.add(ExpiryNotifyLoadRequested(silent: hasNotify));
  }

  void _manualRefresh() {
    context
        .read<DashboardStatsBloc>()
        .add(const DashboardStatsLoadRequested());
    context
        .read<ExpiryNotifyBloc>()
        .add(const ExpiryNotifyLoadRequested());
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          icon: Icon(Icons.logout_rounded, color: scheme.error, size: 28),
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MenuBloc, MenuState>(
      listenWhen: (prev, curr) =>
      prev.tabs != curr.tabs && curr.tabs == MenuName.dashboard,
      listener: (_, _) => _refreshSilentlyIfReady(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () async => _manualRefresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header + clock — fixed 118px so stretch works
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _DashboardHeader(onLogout: _confirmLogout),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        flex: 2,
                        child: DigitalClock(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Expiry card — full width
                const ExpiryNotifyCard(),

                const SizedBox(height: 24),
                const DashboardStatsView(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Greeting header
// =====================================================================
class _DashboardHeader extends StatelessWidget {
  final VoidCallback onLogout;

  const _DashboardHeader({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authState = context.select((AuthBloc b) => b.state);
    if (authState is! AuthAuthenticated) return const SizedBox();

    final user = authState.user;
    final initial = user.fullName.isNotEmpty
        ? user.fullName[0].toUpperCase()
        : '?';

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // ── Greeting + name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.2,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        user.role,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.orgName}  ·  @${user.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            height: 32,
            width: 1,
            color: scheme.outline.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 8),
          _LogoutButton(onTap: onLogout),
        ],
      ),
    );
  }
}

// =====================================================================
// Logout button — subtle ghost style
// =====================================================================
class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: _hovered
            ? scheme.error.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 17,
                  color: _hovered
                      ? scheme.error
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: _hovered
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}