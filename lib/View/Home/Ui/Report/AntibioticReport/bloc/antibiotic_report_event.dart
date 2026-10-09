part of 'antibiotic_report_bloc.dart';

sealed class AntibioticReportEvent extends Equatable {
  const AntibioticReportEvent();

  @override
  List<Object?> get props => [];
}

final class AntibioticReportLoadRequested extends AntibioticReportEvent {
  final String from;
  final String to;
  const AntibioticReportLoadRequested({
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [from, to];
}

final class AntibioticReportExportRequested extends AntibioticReportEvent {
  final String from;
  final String to;
  const AntibioticReportExportRequested({
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [from, to];
}