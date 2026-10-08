part of 'stock_card_bloc.dart';

sealed class StockCardState extends Equatable {
  const StockCardState();

  @override
  List<Object?> get props => [];
}

final class StockCardInitial extends StockCardState {
  const StockCardInitial();
}

final class StockCardLoading extends StockCardState {
  const StockCardLoading();
}

final class StockCardLoaded extends StockCardState {
  final StockCardReport report;
  const StockCardLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

final class StockCardFailure extends StockCardState {
  final String message;
  const StockCardFailure(this.message);

  @override
  List<Object?> get props => [message];
}