part of 'expiry_alert_bloc.dart';

sealed class ExpiryAlertState extends Equatable {
  const ExpiryAlertState();

  @override
  List<Object?> get props => [];
}

final class ExpiryAlertInitial extends ExpiryAlertState {
  const ExpiryAlertInitial();
}

final class ExpiryAlertLoading extends ExpiryAlertState {
  const ExpiryAlertLoading();
}

final class ExpiryAlertLoaded extends ExpiryAlertState {
  final ExpiryAlertReport report;
  const ExpiryAlertLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

final class ExpiryAlertFailure extends ExpiryAlertState {
  final String message;
  const ExpiryAlertFailure(this.message);

  @override
  List<Object?> get props => [message];
}

final class ExpiryAlertExporting extends ExpiryAlertState {
  final ExpiryAlertReport report;
  const ExpiryAlertExporting(this.report);

  @override
  List<Object?> get props => [report];
}

final class ExpiryAlertExported extends ExpiryAlertState {
  final ExpiryAlertReport report;
  final List<int> bytes;
  final String fileName;

  const ExpiryAlertExported({
    required this.report,
    required this.bytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [report, bytes, fileName];
}

final class ExpiryAlertExportFailed extends ExpiryAlertState {
  final ExpiryAlertReport report;
  final String message;

  const ExpiryAlertExportFailed(this.report, this.message);

  @override
  List<Object?> get props => [report, message];
}