import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../Services/api_exception.dart';
import '../../../../../../Services/repository.dart';
import '../model/stock_card_model.dart';

part 'stock_card_event.dart';
part 'stock_card_state.dart';

class StockCardBloc extends Bloc<StockCardEvent, StockCardState> {
  final Repositories _repo;

  StockCardBloc(this._repo) : super(const StockCardInitial()) {
    on<StockCardLoadRequested>(_onLoad);
    on<StockCardClear>(_onClear);
  }

  Future<void> _onLoad(
      StockCardLoadRequested event,
      Emitter<StockCardState> emit,
      ) async {
    emit(const StockCardLoading());
    try {
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