part of 'staff_bloc.dart';

sealed class StaffEvent extends Equatable {
  const StaffEvent();

  @override
  List<Object?> get props => [];
}

final class StaffLoadRequested extends StaffEvent {
  const StaffLoadRequested();
}

final class StaffSelectRequested extends StaffEvent {
  final int staffId;
  const StaffSelectRequested(this.staffId);

  @override
  List<Object?> get props => [staffId];
}

final class StaffClearSelection extends StaffEvent {
  const StaffClearSelection();
}

final class StaffCreateRequested extends StaffEvent {
  final StaffRequest request;
  const StaffCreateRequested(this.request);

  @override
  List<Object?> get props => [request];
}

final class StaffUpdateRequested extends StaffEvent {
  final int staffId;
  final StaffRequest request;
  const StaffUpdateRequested(this.staffId, this.request);

  @override
  List<Object?> get props => [staffId, request];
}

final class StaffDeleteRequested extends StaffEvent {
  final int staffId;
  const StaffDeleteRequested(this.staffId);

  @override
  List<Object?> get props => [staffId];
}