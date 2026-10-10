part of 'expiry_notify_bloc.dart';

sealed class ExpiryNotifyState extends Equatable {
  const ExpiryNotifyState();

  @override
  List<Object?> get props => [];
}

final class ExpiryNotifyInitial extends ExpiryNotifyState {
  const ExpiryNotifyInitial();
}

final class ExpiryNotifyLoading extends ExpiryNotifyState {
  const ExpiryNotifyLoading();
}

final class ExpiryNotifyLoaded extends ExpiryNotifyState {
  final ExpirySummary summary;
  const ExpiryNotifyLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

final class ExpiryNotifyFailure extends ExpiryNotifyState {
  final String message;
  const ExpiryNotifyFailure(this.message);

  @override
  List<Object?> get props => [message];
}