import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../Services/api_exception.dart';
import '../../../../../../Services/repository.dart';
import '../model/stock_card_model.dart';

part 'stock_card_event.dart';
part 'stock_card_state.dart';

class StockCardBloc extends Bloc<StockCardEvent, StockCardState> {
  final Repositories _repo;
  StockCardReport? get _currentReport =>
      state is StockCardLoaded
          ? (state as StockCardLoaded).report
          : state is StockCardExporting
          ? (state as StockCardExporting).report
          : state is StockCardExported
          ? (state as StockCardExported).report
          : state is StockCardExportFailed
          ? (state as StockCardExportFailed).report
          : null;

  StockCardBloc(this._repo) : super(const StockCardInitial()) {
    on<StockCardLoadRequested>(_onLoad);
    on<StockCardClear>(_onClear);
    on<StockCardExportRequested>(_onExport);
  }

  Future<void> _onExport(
      StockCardExportRequested event,
      Emitter<StockCardState> emit,
      ) async {
    final report = _currentReport;
    if (report == null) return;

    emit(StockCardExporting(report));

    try {
      final bytes = await _repo.exportStockCardExcel(
        medId:   event.medId,
        from:    event.from,
        to:      event.to,
        batchNo: event.batchNo,
      );

      final medName = (report.medicine['med_name'] ?? 'medicine')
          .toString()
          .replaceAll(RegExp(r'\s+'), '_');
      final fileName = 'stock-card_${medName}_${event.from}_to_${event.to}.xlsx';

      emit(StockCardExported(
        report:   report,
        bytes:    bytes,
        fileName: fileName,
      ));
    } on ApiException catch (e) {
      emit(StockCardExportFailed(report, e.message));
    } catch (e) {
      emit(StockCardExportFailed(report, e.toString()));
    }
  }
  Future<void> _onLoad(
      StockCardLoadRequested event,
      Emitter<StockCardState> emit,
      ) async {
    emit(const StockCardLoading());
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final report = await _repo.getStockCardReport(
        medId:   event.medId,
        from:    event.from,
        to:      event.to,
        batchNo: event.batchNo,
      );
      emit(StockCardLoaded(report));
    } on ApiException catch (e) {
      emit(StockCardFailure(e.message));
    }
  }

  Future<void> _onClear(
      StockCardClear event,
      Emitter<StockCardState> emit,
      ) async {
    emit(const StockCardInitial());
  }
}