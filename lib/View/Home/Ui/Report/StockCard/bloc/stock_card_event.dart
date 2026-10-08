part of 'stock_card_bloc.dart';

sealed class StockCardEvent extends Equatable {
  const StockCardEvent();

  @override
  List<Object?> get props => [];
}

/// Load the stock card for a medicine in a date range.
final class StockCardLoadRequested extends StockCardEvent {
  final int medId;
  final String from;
  final String to;

  const StockCardLoadRequested({
    required this.medId,
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [medId, from, to];
}

/// Clear the report back to the prompt state.
final class StockCardClear extends StockCardEvent {
  const StockCardClear();
}