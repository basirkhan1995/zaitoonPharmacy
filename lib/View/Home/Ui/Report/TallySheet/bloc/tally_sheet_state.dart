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