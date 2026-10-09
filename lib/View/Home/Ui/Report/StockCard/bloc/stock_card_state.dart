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

final class StockCardExporting extends StockCardState {
  final StockCardReport report;
  const StockCardExporting(this.report);

  @override
  List<Object?> get props => [report];
}

final class StockCardExported extends StockCardState {
  final StockCardReport report;
  final List<int> bytes;
  final String fileName;

  const StockCardExported({
    required this.report,
    required this.bytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [report, bytes, fileName];
}

final class StockCardExportFailed extends StockCardState {
  final StockCardReport report;
  final String message;

  const StockCardExportFailed(this.report, this.message);

  @override
  List<Object?> get props => [report, message];
}