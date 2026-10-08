part of 'medicine_bloc.dart';

sealed class MedicineState extends Equatable {
  const MedicineState();

  @override
  List<Object?> get props => [];
}

/// Nothing loaded yet
final class MedicineInitial extends MedicineState {
  const MedicineInitial();
}

/// List is loading (nothing to show yet)
final class MedicineLoading extends MedicineState {
  const MedicineLoading();
}

/// Base for any state that carries the current list.
/// The UI can render items from any of these.
abstract class MedicineWithItems extends MedicineState {
  final List<Medicine> items;
  const MedicineWithItems(this.items);

  @override
  List<Object?> get props => [items];
}

/// List loaded (may be empty); optionally one selected
final class MedicineLoaded extends MedicineWithItems {
  final Medicine? selected;

  const MedicineLoaded(super.items, {this.selected});

  @override
  List<Object?> get props => [items, selected];
}

/// A create / update / delete is in flight
final class MedicineSaving extends MedicineWithItems {
  const MedicineSaving(super.items);
}

/// Operation succeeded — one-shot signal for the UI (toast, close dialog, …)
/// Also carries the up-to-date list so the UI can keep rendering it.
final class MedicineActionSuccess extends MedicineWithItems {
  final String message;

  const MedicineActionSuccess(super.items, this.message);

  @override
  List<Object?> get props => [items, message];
}

/// Something failed
final class MedicineFailure extends MedicineState {
  final String message;
  const MedicineFailure(this.message);

  @override
  List<Object?> get props => [message];
}