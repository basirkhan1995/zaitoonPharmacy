part of 'batch_bloc.dart';

sealed class BatchEvent extends Equatable {
  const BatchEvent();

  @override
  List<Object?> get props => [];
}

/// Load active batches, optionally filtered by search text.
final class BatchLoadRequested extends BatchEvent {
  final String? search;
  const BatchLoadRequested({this.search});

  @override
  List<Object?> get props => [search];
}

/// Reset back to initial (used when a picker closes).
final class BatchClear extends BatchEvent {
  const BatchClear();
}