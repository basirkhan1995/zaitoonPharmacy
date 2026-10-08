part of 'stock_bloc.dart';

sealed class StockEvent extends Equatable {
  const StockEvent();
  @override
  List<Object?> get props => [];
}

final class StockLoadRequested extends StockEvent {
  final String? search;
  final String? from;
  final String? to;
  final String? movementType;

  const StockLoadRequested({
    this.search,
    this.from,
    this.to,
    this.movementType,
  });

  @override
  List<Object?> get props => [search, from, to, movementType];
}

final class StockInvoiceSelectRequested extends StockEvent {
  final int invoiceId;
  const StockInvoiceSelectRequested(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

final class StockCreateRequested extends StockEvent {
  final StockInvoiceRequest request;
  const StockCreateRequested(this.request);
  @override
  List<Object?> get props => [request];
}

final class StockUpdateRequested extends StockEvent {
  final int invoiceId;
  final StockInvoiceRequest request;
  const StockUpdateRequested(this.invoiceId, this.request);
  @override
  List<Object?> get props => [invoiceId, request];
}

final class StockDeleteRequested extends StockEvent {
  final int invoiceId;
  const StockDeleteRequested(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}