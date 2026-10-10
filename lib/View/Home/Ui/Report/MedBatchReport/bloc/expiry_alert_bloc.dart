import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/med_batch_model.dart';

part 'expiry_alert_event.dart';
part 'expiry_alert_state.dart';

class ExpiryAlertBloc extends Bloc<ExpiryAlertEvent, ExpiryAlertState> {
  final Repositories _repo;

  ExpiryAlertBloc(this._repo) : super(const ExpiryAlertInitial()) {
    on<ExpiryAlertLoadRequested>(_onLoad);
    on<ExpiryAlertExportRequested>(_onExport);
  }

  ExpiryAlertReport? get _currentReport => switch (state) {
    ExpiryAlertLoaded s        => s.report,
    ExpiryAlertExporting s     => s.report,
    ExpiryAlertExported s      => s.report,
    ExpiryAlertExportFailed s  => s.report,
    _                          => null,
  };

  Future<void> _onLoad(
      ExpiryAlertLoadRequested event,
      Emitter<ExpiryAlertState> emit,
      ) async {
    emit(const ExpiryAlertLoading());
    try {
      final report = await _repo.getExpiryAlert(
        from: event.from,
        to: event.to,
        onlyExpiring: event.onlyExpiring,
      );
      emit(ExpiryAlertLoaded(report));
    } on ApiException catch (e) {
      emit(ExpiryAlertFailure(e.message));
    } catch (e) {
      emit(ExpiryAlertFailure(e.toString()));
    }
  }

  Future<void> _onExport(
      ExpiryAlertExportRequested event,
      Emitter<ExpiryAlertState> emit,
      ) async {
    final report = _currentReport;
    if (report == null) return;

    emit(ExpiryAlertExporting(report));

    try {
      final bytes = await _repo.exportExpiryAlertExcel(
        from: event.from,
        to: event.to,
        onlyExpiring: event.onlyExpiring,
      );

      final fileName = event.onlyExpiring
          ? 'expiry-alert_${event.from ?? 'start'}_to_${event.to ?? 'end'}.xlsx'
          : 'all-batches.xlsx';

      emit(ExpiryAlertExported(
        report:   report,
        bytes:    bytes,
        fileName: fileName,
      ));
    } on ApiException catch (e) {
      emit(ExpiryAlertExportFailed(report, e.message));
    } catch (e) {
      emit(ExpiryAlertExportFailed(report, e.toString()));
    }
  }
}