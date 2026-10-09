import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../Services/api_exception.dart';
import '../../../../../../Services/repository.dart';
import '../model/antibiotic_model.dart';

part 'antibiotic_report_event.dart';
part 'antibiotic_report_state.dart';

class AntibioticReportBloc
    extends Bloc<AntibioticReportEvent, AntibioticReportState> {
  final Repositories _repo;

  AntibioticReportBloc(this._repo) : super(const AntibioticReportInitial()) {
    on<AntibioticReportLoadRequested>(_onLoad);
    on<AntibioticReportExportRequested>(_onExport);
  }

  AntibioticReport? get _currentReport => switch (state) {
    AntibioticReportLoaded s          => s.report,
    AntibioticReportExporting s       => s.report,
    AntibioticReportExported s        => s.report,
    AntibioticReportExportFailed s    => s.report,
    _                                 => null,
  };

  Future<void> _onLoad(
      AntibioticReportLoadRequested event,
      Emitter<AntibioticReportState> emit,
      ) async {
    emit(const AntibioticReportLoading());
    try {
      final report = await _repo.getAntibioticReport(
        from: event.from,
        to:   event.to,
      );
      emit(AntibioticReportLoaded(report));
    } on ApiException catch (e) {
      emit(AntibioticReportFailure(e.message));
    } catch (e) {
      emit(AntibioticReportFailure(e.toString()));
    }
  }

  Future<void> _onExport(
      AntibioticReportExportRequested event,
      Emitter<AntibioticReportState> emit,
      ) async {
    final report = _currentReport;
    if (report == null) return;

    emit(AntibioticReportExporting(report));

    try {
      final bytes = await _repo.exportAntibioticReportExcel(
        from: event.from,
        to:   event.to,
      );

      final fileName = 'antibiotic-form_${event.from}_to_${event.to}.xlsx';

      emit(AntibioticReportExported(
        report:   report,
        bytes:    bytes,
        fileName: fileName,
      ));
    } on ApiException catch (e) {
      emit(AntibioticReportExportFailed(report, e.message));
    } catch (e) {
      emit(AntibioticReportExportFailed(report, e.toString()));
    }
  }
}