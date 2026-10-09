part of 'medicine_report_bloc.dart';

sealed class MedicineReportState extends Equatable {
  const MedicineReportState();

  @override
  List<Object?> get props => [];
}

final class MedicineReportInitial extends MedicineReportState {
  const MedicineReportInitial();
}

final class MedicineReportLoading extends MedicineReportState {
  const MedicineReportLoading();
}

final class MedicineReportLoaded extends MedicineReportState {
  final MedicineReport report;
  const MedicineReportLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

final class MedicineReportFailure extends MedicineReportState {
  final String message;
  const MedicineReportFailure(this.message);

  @override
  List<Object?> get props => [message];
}

final class MedicineReportExporting extends MedicineReportState {
  final MedicineReport report;
  const MedicineReportExporting(this.report);

  @override
  List<Object?> get props => [report];
}

final class MedicineReportExported extends MedicineReportState {
  final MedicineReport report;
  final List<int> bytes;
  final String fileName;

  const MedicineReportExported({
    required this.report,
    required this.bytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [report, bytes, fileName];
}

final class MedicineReportExportFailed extends MedicineReportState {
  final MedicineReport report;
  final String message;

  const MedicineReportExportFailed(this.report, this.message);

  @override
  List<Object?> get props => [report, message];
}