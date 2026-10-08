part of 'batch_bloc.dart';

sealed class BatchState extends Equatable {
  const BatchState();

  @override
  List<Object?> get props => [];
}

final class BatchInitial extends BatchState {
  const BatchInitial();
}

final class BatchLoading extends BatchState {
  const BatchLoading();
}

final class BatchLoaded extends BatchState {
  final List<StockBatchOption> items;
  const BatchLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

final class BatchFailure extends BatchState {
  final String message;
  const BatchFailure(this.message);

  @override
  List<Object?> get props => [message];
}