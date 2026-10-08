import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../Services/api_exception.dart';
import '../../../../../Services/repository.dart';
import '../model/stock_model.dart';

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final Repositories _repo;

  StockBloc(this._repo) : super(const StockInitial()) {
    on<StockLoadRequested>(_onLoad);
    on<StockInvoiceSelectRequested>(_onSelect);
    on<StockCreateRequested>(_onCreate);
    on<StockUpdateRequested>(_onUpdate);
    on<StockDeleteRequested>(_onDelete);
  }

  List<StockInvoice> get _currentItems =>
      state is StockWithItems ? (state as StockWithItems).items : const [];

  Future<void> _onLoad(StockLoadRequested event, Emitter<StockState> emit) async {
    emit(const StockLoading());
    try {
      final items = await _repo.getStockInvoices(
        search:       event.search,
        from:         event.from,
        to:           event.to,
        movementType: event.movementType,
      );
      emit(StockLoaded(items));
    } on ApiException catch (e) {
      emit(StockFailure(e.message));
    }
  }

  Future<void> _onSelect(StockInvoiceSelectRequested event,
      Emitter<StockState> emit) async {
    final items = _currentItems;
    emit(const StockLoading());
    try {
      final inv = await _repo.getStockInvoice(event.invoiceId);
      emit(StockLoaded(items, selected: inv));
    } on ApiException catch (e) {
      emit(StockFailure(e.message));
    }
  }

  Future<void> _onCreate(StockCreateRequested event,
      Emitter<StockState> emit) async {
    emit(StockSaving(_currentItems));
    try {
      await _repo.createStockInvoice(event.request);
      final items = await _repo.getStockInvoices();
      emit(StockLoaded(items));
      emit(StockActionSuccess(items, 'Invoice recorded'));
    } on ApiException catch (e) {
      emit(StockFailure(e.message));
    }
  }

  Future<void> _onUpdate(StockUpdateRequested event,
      Emitter<StockState> emit) async {
    emit(StockSaving(_currentItems));
    try {
      await _repo.updateStockInvoice(event.invoiceId, event.request);
      final items = await _repo.getStockInvoices();
      emit(StockLoaded(items));
      emit(StockActionSuccess(items, 'Invoice updated'));
    } on ApiException catch (e) {
      emit(StockFailure(e.message));
    }
  }

  Future<void> _onDelete(StockDeleteRequested event,
      Emitter<StockState> emit) async {
    emit(StockSaving(_currentItems));
    try {
      await _repo.deleteStockInvoice(event.invoiceId);
      final items = await _repo.getStockInvoices();
      emit(StockLoaded(items));
      emit(StockActionSuccess(items, 'Invoice deleted'));
    } on ApiException catch (e) {
      emit(StockFailure(e.message));
    }
  }
}