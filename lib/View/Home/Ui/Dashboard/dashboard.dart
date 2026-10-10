import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zpharmacy/Features/Widgets/digital_clock.dart';
import 'package:zpharmacy/View/Home/Ui/Dashboard/stats_view.dart';
import '../../bloc/menu_bloc.dart';
import 'bloc/dashboard_stats_bloc.dart';
import '../Report/ExpiryNotification/expiry_notify.dart';
import '../Report/ExpiryNotification/bloc/expiry_notify_bloc.dart';

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

  /// Refresh stats + expiry without showing the shimmer when data already
  /// exists (silent). If there's no data yet, this becomes a normal load.
  void _refreshSilentlyIfReady() {
    final statsBloc  = context.read<DashboardStatsBloc>();
    final notifyBloc = context.read<ExpiryNotifyBloc>();

    final hasStats  = statsBloc.state  is DashboardStatsLoaded;
    final hasNotify = notifyBloc.state is ExpiryNotifyLoaded;

    statsBloc.add(DashboardStatsLoadRequested(silent: hasStats));

    if (!hasNotify) {
      notifyBloc.add(const ExpiryNotifyLoadRequested());
    }
    // If you want the notify card to silently refresh too, add a silent
    // flag to ExpiryNotifyLoadRequested and mirror this pattern.
  }

  void _manualRefresh() {
    context
        .read<DashboardStatsBloc>()
        .add(const DashboardStatsLoadRequested());  // non-silent
    context
        .read<ExpiryNotifyBloc>()
        .add(const ExpiryNotifyLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<MenuBloc, MenuState>(
      // Fires each time the user switches BACK to the Dashboard tab
      listenWhen: (prev, curr) =>
      prev.tabs != curr.tabs && curr.tabs == MenuName.dashboard,
      listener: (_, _) => _refreshSilentlyIfReady(),
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: RefreshIndicator(
          onRefresh: () async => _manualRefresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DigitalClock(),
                const SizedBox(height: 20),
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