part of 'dashboard_stats_bloc.dart';

sealed class DashboardStatsState extends Equatable {
  const DashboardStatsState();

  @override
  List<Object?> get props => [];
}

final class DashboardStatsInitial extends DashboardStatsState {
  const DashboardStatsInitial();
}

final class DashboardStatsLoading extends DashboardStatsState {
  const DashboardStatsLoading();
}

final class DashboardStatsLoaded extends DashboardStatsState {
  final DashboardStats stats;
  const DashboardStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

final class DashboardStatsFailure extends DashboardStatsState {
  final String message;
  const DashboardStatsFailure(this.message);

  @override
  List<Object?> get props => [message];
}