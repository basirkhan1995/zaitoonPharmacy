part of 'staff_bloc.dart';

sealed class StaffState extends Equatable {
  const StaffState();

  @override
  List<Object?> get props => [];
}

final class StaffInitial extends StaffState {
  const StaffInitial();
}

final class StaffLoading extends StaffState {
  const StaffLoading();
}

abstract class StaffWithItems extends StaffState {
  final List<Staff> items;
  const StaffWithItems(this.items);

  @override
  List<Object?> get props => [items];
}

final class StaffLoaded extends StaffWithItems {
  final Staff? selected;

  const StaffLoaded(super.items, {this.selected});

  @override
  List<Object?> get props => [items, selected];
}

final class StaffSaving extends StaffWithItems {
  const StaffSaving(super.items);
}

final class StaffActionSuccess extends StaffWithItems {
  final String message;

  const StaffActionSuccess(super.items, this.message);

  @override
  List<Object?> get props => [items, message];
}

final class StaffFailure extends StaffState {
  final String message;
  const StaffFailure(this.message);

  @override
  List<Object?> get props => [message];
}