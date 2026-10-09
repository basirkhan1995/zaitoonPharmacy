part of 'medicine_bloc.dart';

sealed class MedicineState extends Equatable {
  const MedicineState();

  @override
  List<Object?> get props => [];
}

final class MedicineInitial extends MedicineState {
  const MedicineInitial();
}

final class MedicineLoading extends MedicineState {
  const MedicineLoading();
}

abstract class MedicineWithItems extends MedicineState {
  final List<Medicine> items;
  const MedicineWithItems(this.items);

  @override
  List<Object?> get props => [items];
}

final class MedicineLoaded extends MedicineWithItems {
  final Medicine? selected;

  const MedicineLoaded(super.items, {this.selected});

  @override
  List<Object?> get props => [items, selected];
}

final class MedicineSaving extends MedicineWithItems {
  const MedicineSaving(super.items);
}

final class MedicineActionSuccess extends MedicineWithItems {
  final String message;

  const MedicineActionSuccess(super.items, this.message);

  @override
  List<Object?> get props => [items, message];
}

final class MedicineFailure extends MedicineState {
  final String message;
  const MedicineFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// One-shot signal fired after an Excel import completes.
/// Carries the fresh list so the UI keeps rendering items under the dialog.
final class MedicineExcelUploadedState extends MedicineWithItems {
  final int inserted;
  final List<Map<String, dynamic>> skipped;
  final List<Map<String, dynamic>> errors;

  const MedicineExcelUploadedState(
      super.items, {
        required this.inserted,
        required this.skipped,
        required this.errors,
      });

  @override
  List<Object?> get props => [items, inserted, skipped, errors];
}