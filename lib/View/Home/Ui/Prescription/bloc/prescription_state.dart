part of 'prescription_bloc.dart';

sealed class PrescriptionState extends Equatable {
  const PrescriptionState();

  @override
  List<Object?> get props => [];
}

final class PrescriptionInitial extends PrescriptionState {
  const PrescriptionInitial();
}

final class PrescriptionLoading extends PrescriptionState {
  const PrescriptionLoading();
}

abstract class PrescriptionWithItems extends PrescriptionState {
  final List<Prescription> items;
  const PrescriptionWithItems(this.items);

  @override
  List<Object?> get props => [items];
}

final class PrescriptionLoaded extends PrescriptionWithItems {
  final Prescription? selected;
  const PrescriptionLoaded(super.items, {this.selected});

  @override
  List<Object?> get props => [items, selected];
}

final class PrescriptionSaving extends PrescriptionWithItems {
  const PrescriptionSaving(super.items);
}

final class PrescriptionActionSuccess extends PrescriptionWithItems {
  final String message;
  const PrescriptionActionSuccess(super.items, this.message);

  @override
  List<Object?> get props => [items, message];
}

final class PrescriptionFailure extends PrescriptionState {
  final String message;
  const PrescriptionFailure(this.message);

  @override
  List<Object?> get props => [message];
}