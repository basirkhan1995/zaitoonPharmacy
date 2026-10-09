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

  MedicineReportBloc(this._repo) : super(const MedicineReportInitial()) {
    on<MedicineReportLoadRequested>(_onLoad);
    on<MedicineReportClear>(_onClear);
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