part of 'dashboard_stats_bloc.dart';

sealed class DashboardStatsEvent extends Equatable {
  const DashboardStatsEvent();

  @override
  List<Object?> get props => [];
}

final class DashboardStatsLoadRequested extends DashboardStatsEvent {
  /// When true and the bloc already has data, the loading state is
  /// not emitted — the old data stays on screen while we refresh.
  final bool silent;

  const DashboardStatsLoadRequested({this.silent = false});

  @override
  List<Object?> get props => [silent];
}