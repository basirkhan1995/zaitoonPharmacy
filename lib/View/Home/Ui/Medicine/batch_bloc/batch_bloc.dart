import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../Services/api_exception.dart';
import '../../../../../Services/repository.dart';
import '../../Stock/model/stock_model.dart';

part 'batch_event.dart';
part 'batch_state.dart';

class BatchBloc extends Bloc<BatchEvent, BatchState> {
  final Repositories _repo;

  BatchBloc(this._repo) : super(const BatchInitial()) {
    on<BatchLoadRequested>(_onLoad);
    on<BatchClear>(_onClear);
  }

  Future<void> _onLoad(BatchLoadRequested event, Emitter<BatchState> emit) async {
    emit(const BatchLoading());
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final items = await _repo.getActiveBatches(search: event.search);
      emit(BatchLoaded(items));
    } on ApiException catch (e) {
      emit(BatchFailure(e.message));
    }
  }

  Future<void> _onClear(BatchClear event, Emitter<BatchState> emit) async {
    emit(const BatchInitial());
  }
}