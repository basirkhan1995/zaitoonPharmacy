part of 'stock_card_bloc.dart';

sealed class StockCardEvent extends Equatable {
  const StockCardEvent();

  @override
  List<Object?> get props => [];
}

/// Load the stock card for a medicine in a date range.
/// Optionally filter to a single batch number.
final class StockCardLoadRequested extends StockCardEvent {
  final int medId;
  final String from;
  final String to;
  final String? batchNo;

  const StockCardLoadRequested({
    required this.medId,
    required this.from,
    required this.to,
    this.batchNo,
  });

  @override
  List<Object?> get props => [medId, from, to, batchNo];
}

/// Clear the report back to the prompt state.
final class StockCardClear extends StockCardEvent {
  const StockCardClear();
}