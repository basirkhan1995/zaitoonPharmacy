import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../Services/api_exception.dart';
import '../../../../../../Services/repository.dart';
import '../../Stock/model/stock_model.dart';


part 'batch_event.dart';
part 'batch_state.dart';

class BatchBloc extends Bloc<BatchEvent, BatchState> {
  final Repositories _repo;

  BatchBloc(this._repo) : super(const BatchInitial()) {
    on<BatchLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
      BatchLoadRequested event,
      Emitter<BatchState> emit,
      ) async {
    emit(const BatchLoading());
    try {
      final items = await _repo.getActiveBatches(
        search:         event.search,
        includeExpired: event.includeExpired,
      );
      emit(BatchLoaded(items));
    } on ApiException catch (e) {
      emit(BatchFailure(e.message));
    }
  }
}