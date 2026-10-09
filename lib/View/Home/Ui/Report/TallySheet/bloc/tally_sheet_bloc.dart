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
  }

  Future<void> _onLoad(
      TallySheetLoadRequested event, Emitter<TallySheetState> emit) async {
    emit(const TallySheetLoading());
    try {
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
}