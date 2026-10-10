part of 'expiry_notify_bloc.dart';

sealed class ExpiryNotifyEvent extends Equatable {
  const ExpiryNotifyEvent();

  @override
  List<Object?> get props => [];
}

final class ExpiryNotifyLoadRequested extends ExpiryNotifyEvent {
  /// When true and data already exists, `Loading` is not emitted —
  /// the old data stays visible while we refresh in the background.
  final bool silent;

  const ExpiryNotifyLoadRequested({this.silent = false});

  @override
  List<Object?> get props => [silent];
}