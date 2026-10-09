import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../Services/api_exception.dart';
import '../../../../../../Services/repository.dart';
import '../model/tally_sheet_model.dart';

part 'tally_sheet_event.dart';
part 'tally_sheet_state.dart';

class TallySheetBloc extends Bloc<TallySheetEvent, TallySheetState> {
  final Repositories _repo;

  TallySheetBloc(this._repo) : super(const TallySheetInitial()) {
    on<TallySheetLoadRequested>(_onLoad);
    on<TallySheetExportRequested>(_onExport);   // ← NEW
  }

  List<TallySheetRow> get _currentRows =>
      state is TallySheetLoaded
          ? (state as TallySheetLoaded).rows
          : const [];

  // -----------------------------------------------------------------
  // Load
  // -----------------------------------------------------------------
  Future<void> _onLoad(
      TallySheetLoadRequested event,
      Emitter<TallySheetState> emit,
      ) async {
    emit(const TallySheetLoading());
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final rows = await _repo.getTallySheetReport(
        from:  event.from,
        to:    event.to,
        catId: event.catId,
      );
      emit(TallySheetLoaded(rows));
    } on ApiException catch (e) {
      emit(TallySheetFailure(e.message));
    } catch (e) {
      emit(TallySheetFailure(e.toString()));
    }
  }

  // -----------------------------------------------------------------
  // Export
  // -----------------------------------------------------------------
  Future<void> _onExport(
      TallySheetExportRequested event,
      Emitter<TallySheetState> emit,
      ) async {
    final rows = _currentRows;

    // 1. Signal "exporting" so the UI can disable the button
    emit(TallySheetExporting(rows));

    try {
      final bytes = await _repo.exportTallySheetExcel(
        from:  event.from,
        to:    event.to,
        catId: event.catId,
      );

      final fileName = 'tally-sheet_${event.from}_to_${event.to}.xlsx';

      emit(TallySheetExported(
        rows:     rows,
        bytes:    bytes,
        fileName: fileName,
      ));
    } on ApiException catch (e) {
      emit(TallySheetExportFailed(rows, e.message));
    } catch (e) {
      emit(TallySheetExportFailed(rows, e.toString()));
    }
  }
}