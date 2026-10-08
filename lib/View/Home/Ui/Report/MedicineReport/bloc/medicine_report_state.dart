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