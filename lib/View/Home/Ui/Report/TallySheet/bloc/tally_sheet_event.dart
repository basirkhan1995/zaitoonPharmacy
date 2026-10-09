part of 'tally_sheet_bloc.dart';

sealed class TallySheetEvent extends Equatable {
  const TallySheetEvent();

  @override
  List<Object?> get props => [];
}

final class TallySheetLoadRequested extends TallySheetEvent {
  final String from;
  final String to;
  final int? catId;

  const TallySheetLoadRequested({
    required this.from,
    required this.to,
    this.catId,
  });

  @override
  List<Object?> get props => [from, to, catId];
}

final class TallySheetExportRequested extends TallySheetEvent {
  final String from;
  final String to;
  final int? catId;

  const TallySheetExportRequested({
    required this.from,
    required this.to,
    this.catId,
  });

  @override
  List<Object?> get props => [from, to, catId];
}