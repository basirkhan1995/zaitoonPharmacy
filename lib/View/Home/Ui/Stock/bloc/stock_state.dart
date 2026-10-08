part of 'stock_bloc.dart';

sealed class StockState extends Equatable {
  const StockState();
}

final class StockInitial extends StockState {
  @override
  List<Object> get props => [];
}
