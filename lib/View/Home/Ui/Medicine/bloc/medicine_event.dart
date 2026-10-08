part of 'medicine_bloc.dart';

sealed class MedicineEvent extends Equatable {
  const MedicineEvent();

  @override
  List<Object?> get props => [];
}

/// Load the list
final class MedicineLoadRequested extends MedicineEvent {
  final String? search;
  const MedicineLoadRequested({this.search});

  @override
  List<Object?> get props => [search];
}

/// Load a single medicine (with batches)
final class MedicineSelectRequested extends MedicineEvent {
  final int medId;
  const MedicineSelectRequested(this.medId);

  @override
  List<Object?> get props => [medId];
}

/// Clear selection
final class MedicineClearSelection extends MedicineEvent {
  const MedicineClearSelection();
}

/// Create
final class MedicineCreateRequested extends MedicineEvent {
  final MedicineRequest request;
  const MedicineCreateRequested(this.request);

  @override
  List<Object?> get props => [request];
}

/// Update
final class MedicineUpdateRequested extends MedicineEvent {
  final int medId;
  final MedicineRequest request;
  const MedicineUpdateRequested(this.medId, this.request);

  @override
  List<Object?> get props => [medId, request];
}

/// Delete
final class MedicineDeleteRequested extends MedicineEvent {
  final int medId;
  const MedicineDeleteRequested(this.medId);

  @override
  List<Object?> get props => [medId];
}