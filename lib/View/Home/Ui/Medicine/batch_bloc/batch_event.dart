part of 'batch_bloc.dart';

sealed class BatchEvent extends Equatable {
  const BatchEvent();

  @override
  List<Object?> get props => [];
}

final class BatchLoadRequested extends BatchEvent {
  final String? search;
  final bool includeExpired;

  const BatchLoadRequested({
    this.search,
    this.includeExpired = false,
  });

  @override
  List<Object?> get props => [search, includeExpired];
}