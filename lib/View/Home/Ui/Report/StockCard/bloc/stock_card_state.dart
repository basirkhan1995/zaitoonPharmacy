part of 'stock_card_bloc.dart';

sealed class StockCardState extends Equatable {
  const StockCardState();

  @override
  List<Object?> get props => [];
}

/// Nothing loaded yet — show the "pick a medicine" prompt.
final class StockCardInitial extends StockCardState {
  const StockCardInitial();
}

/// Report is being fetched.
final class StockCardLoading extends StockCardState {
  const StockCardLoading();
}

/// Report ready.
final class StockCardLoaded extends StockCardState {
  final StockCardReport report;
  const StockCardLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

/// Something failed.
final class StockCardFailure extends StockCardState {
  final String message;
  const StockCardFailure(this.message);

  @override
  List<Object?> get props => [message];
}