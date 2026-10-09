part of 'tally_sheet_bloc.dart';

sealed class TallySheetState extends Equatable {
  const TallySheetState();

  @override
  List<Object?> get props => [];
}

final class TallySheetInitial extends TallySheetState {
  const TallySheetInitial();
}

final class TallySheetLoading extends TallySheetState {
  const TallySheetLoading();
}

final class TallySheetLoaded extends TallySheetState {
  final List<TallySheetRow> rows;
  const TallySheetLoaded(this.rows);

  @override
  List<Object?> get props => [rows];
}

final class TallySheetFailure extends TallySheetState {
  final String message;
  const TallySheetFailure(this.message);

  @override
  List<Object?> get props => [message];
}

final class TallySheetExporting extends TallySheetState {
  final List<TallySheetRow> rows;
  const TallySheetExporting(this.rows);

  @override
  List<Object?> get props => [rows];
}

/// Emitted on success — carries the downloaded bytes + suggested filename.
/// One-shot signal: the UI shows the save dialog, then the state can be reset.
final class TallySheetExported extends TallySheetState {
  final List<TallySheetRow> rows;
  final List<int> bytes;
  final String fileName;

  const TallySheetExported({
    required this.rows,
    required this.bytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [rows, bytes, fileName];
}

/// Export failed — one-shot signal.
final class TallySheetExportFailed extends TallySheetState {
  final List<TallySheetRow> rows;
  final String message;

  const TallySheetExportFailed(this.rows, this.message);

  @override
  List<Object?> get props => [rows, message];
}