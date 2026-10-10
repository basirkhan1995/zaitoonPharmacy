part of 'expiry_notify_bloc.dart';

sealed class ExpiryNotifyEvent extends Equatable {
  const ExpiryNotifyEvent();

  @override
  List<Object?> get props => [];
}

final class ExpiryNotifyLoadRequested extends ExpiryNotifyEvent {
  const ExpiryNotifyLoadRequested();
}