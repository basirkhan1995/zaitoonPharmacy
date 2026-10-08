part of 'stock_bloc.dart';

sealed class StockState extends Equatable {
  const StockState();
  @override
  List<Object?> get props => [];
}

final class StockInitial extends StockState {
  const StockInitial();
}

final class StockLoading extends StockState {
  const StockLoading();
}

abstract class StockWithItems extends StockState {
  final List<StockInvoice> items;
  const StockWithItems(this.items);
  @override
  List<Object?> get props => [items];
}

final class StockLoaded extends StockWithItems {
  final StockInvoice? selected;
  const StockLoaded(super.items, {this.selected});
  @override
  List<Object?> get props => [items, selected];
}

final class StockSaving extends StockWithItems {
  const StockSaving(super.items);
}

final class StockActionSuccess extends StockWithItems {
  final String message;
  const StockActionSuccess(super.items, this.message);
  @override
  List<Object?> get props => [items, message];
}

final class StockFailure extends StockState {
  final String message;
  const StockFailure(this.message);
  @override
  List<Object?> get props => [message];
}