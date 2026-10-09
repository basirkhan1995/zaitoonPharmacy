part of 'medicine_bloc.dart';

sealed class MedicineEvent extends Equatable {
  const MedicineEvent();

  @override
  List<Object?> get props => [];
}

final class MedicineLoadRequested extends MedicineEvent {
  final String? search;
  const MedicineLoadRequested({this.search});

  @override
  List<Object?> get props => [search];
}

final class MedicineSelectRequested extends MedicineEvent {
  final int medId;
  const MedicineSelectRequested(this.medId);

  @override
  List<Object?> get props => [medId];
}

final class MedicineClearSelection extends MedicineEvent {
  const MedicineClearSelection();
}

final class MedicineCreateRequested extends MedicineEvent {
  final MedicineRequest request;
  const MedicineCreateRequested(this.request);

  @override
  List<Object?> get props => [request];
}

final class MedicineUpdateRequested extends MedicineEvent {
  final int medId;
  final MedicineRequest request;
  const MedicineUpdateRequested(this.medId, this.request);

  @override
  List<Object?> get props => [medId, request];
}

final class MedicineDeleteRequested extends MedicineEvent {
  final int medId;
  const MedicineDeleteRequested(this.medId);

  @override
  List<Object?> get props => [medId];
}

/// Import one Excel file. Path is used for equality.
final class MedicineImportExcelRequested extends MedicineEvent {
  final File file;
  const MedicineImportExcelRequested(this.file);

  @override
  List<Object?> get props => [file.path];
}