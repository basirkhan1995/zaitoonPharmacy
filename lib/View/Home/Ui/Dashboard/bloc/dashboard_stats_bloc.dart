import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../Services/api_exception.dart';
import '../../../../../Services/repository.dart';
import '../model/stats_model.dart';

part 'dashboard_stats_event.dart';
part 'dashboard_stats_state.dart';

class DashboardStatsBloc
    extends Bloc<DashboardStatsEvent, DashboardStatsState> {
  final Repositories _repo;

  DashboardStatsBloc(this._repo) : super(const DashboardStatsInitial()) {
    on<DashboardStatsLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
      DashboardStatsLoadRequested event,
      Emitter<DashboardStatsState> emit,
      ) async {
    // Silent refresh — keep the old data on screen while we reload
    final keepVisible = event.silent && state is DashboardStatsLoaded;

    if (!keepVisible) {
      emit(const DashboardStatsLoading());
    }

    try {
      await Future.delayed(Duration(milliseconds: 500));
      final stats = await _repo.getDashboardStats();
      emit(DashboardStatsLoaded(stats));
    } on ApiException catch (e) {
      emit(DashboardStatsFailure(e.message));
    } catch (e) {
      emit(DashboardStatsFailure(e.toString()));
    }
  }
}