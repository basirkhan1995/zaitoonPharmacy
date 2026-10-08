part of 'medicine_report_bloc.dart';

sealed class MedicineReportEvent extends Equatable {
  const MedicineReportEvent();

  @override
  List<Object?> get props => [];
}

final class MedicineReportLoadRequested extends MedicineReportEvent {
  final String from;
  final String to;
  final String? search;

  const MedicineReportLoadRequested({
    required this.from,
    required this.to,
    this.search,
  });

  @override
  List<Object?> get props => [from, to, search];
}

final class MedicineReportClear extends MedicineReportEvent {
  const MedicineReportClear();
}