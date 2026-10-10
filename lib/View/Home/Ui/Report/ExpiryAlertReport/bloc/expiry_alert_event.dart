part of 'expiry_alert_bloc.dart';

sealed class ExpiryAlertEvent extends Equatable {
  const ExpiryAlertEvent();

  @override
  List<Object?> get props => [];
}

final class ExpiryAlertLoadRequested extends ExpiryAlertEvent {
  final String? from;
  final String? to;
  final bool onlyExpiring;

  const ExpiryAlertLoadRequested({
    this.from,
    this.to,
    this.onlyExpiring = true,
  });

  @override
  List<Object?> get props => [from, to, onlyExpiring];
}

final class ExpiryAlertExportRequested extends ExpiryAlertEvent {
  final String? from;
  final String? to;
  final bool onlyExpiring;

  const ExpiryAlertExportRequested({
    this.from,
    this.to,
    this.onlyExpiring = true,
  });

  @override
  List<Object?> get props => [from, to, onlyExpiring];
}