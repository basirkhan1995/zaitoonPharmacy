part of 'antibiotic_report_bloc.dart';

sealed class AntibioticReportState extends Equatable {
  const AntibioticReportState();

  @override
  List<Object?> get props => [];
}

final class AntibioticReportInitial extends AntibioticReportState {
  const AntibioticReportInitial();
}

final class AntibioticReportLoading extends AntibioticReportState {
  const AntibioticReportLoading();
}

final class AntibioticReportLoaded extends AntibioticReportState {
  final AntibioticReport report;
  const AntibioticReportLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

final class AntibioticReportFailure extends AntibioticReportState {
  final String message;
  const AntibioticReportFailure(this.message);

  @override
  List<Object?> get props => [message];
}

final class AntibioticReportExporting extends AntibioticReportState {
  final AntibioticReport report;
  const AntibioticReportExporting(this.report);

  @override
  List<Object?> get props => [report];
}

final class AntibioticReportExported extends AntibioticReportState {
  final AntibioticReport report;
  final List<int> bytes;
  final String fileName;

  const AntibioticReportExported({
    required this.report,
    required this.bytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [report, bytes, fileName];
}

final class AntibioticReportExportFailed extends AntibioticReportState {
  final AntibioticReport report;
  final String message;

  const AntibioticReportExportFailed(this.report, this.message);

  @override
  List<Object?> get props => [report, message];
}