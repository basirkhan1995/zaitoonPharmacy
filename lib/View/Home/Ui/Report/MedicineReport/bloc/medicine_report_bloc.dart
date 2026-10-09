import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../Services/api_exception.dart';
import '../../../../../../Services/repository.dart';
import '../model/medicine_report_model.dart';
part 'medicine_report_event.dart';
part 'medicine_report_state.dart';

class MedicineReportBloc
    extends Bloc<MedicineReportEvent, MedicineReportState> {
  final Repositories _repo;
  MedicineReport? get _currentReport => switch (state) {
    MedicineReportLoaded s         => s.report,
    MedicineReportExporting s      => s.report,
    MedicineReportExported s       => s.report,
    MedicineReportExportFailed s   => s.report,
    _                              => null,
  };
  MedicineReportBloc(this._repo) : super(const MedicineReportInitial()) {
    on<MedicineReportLoadRequested>(_onLoad);
    on<MedicineReportClear>(_onClear);
    on<MedicineReportExportRequested>(_onExport);
  }

  Future<void> _onExport(
      MedicineReportExportRequested event,
      Emitter<MedicineReportState> emit,
      ) async {
    final report = _currentReport;
    if (report == null) return;

    emit(MedicineReportExporting(report));

    try {
      final bytes = await _repo.exportMedicineReportExcel(
        from:   event.from,
        to:     event.to,
        search: event.search,
      );

      final fileName = 'medicines-report_${event.from}_to_${event.to}.xlsx';

      emit(MedicineReportExported(
        report:   report,
        bytes:    bytes,
        fileName: fileName,
      ));
    } on ApiException catch (e) {
      emit(MedicineReportExportFailed(report, e.message));
    } catch (e) {
      emit(MedicineReportExportFailed(report, e.toString()));
    }
  }
  Future<void> _onLoad(
      MedicineReportLoadRequested event,
      Emitter<MedicineReportState> emit,
      ) async {
    emit(const MedicineReportLoading());
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final report = await _repo.getMedicineReport(
        from:   event.from,
        to:     event.to,
        search: event.search,
      );
      emit(MedicineReportLoaded(report));
    } on ApiException catch (e) {
      emit(MedicineReportFailure(e.message));
    }
  }

  Future<void> _onClear(
      MedicineReportClear event,
      Emitter<MedicineReportState> emit,
      ) async {
    emit(const MedicineReportInitial());
  }
}