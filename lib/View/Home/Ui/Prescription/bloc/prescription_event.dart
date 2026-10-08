part of 'prescription_bloc.dart';

sealed class PrescriptionEvent extends Equatable {
  const PrescriptionEvent();

  @override
  List<Object?> get props => [];
}
final class PrescriptionLoadRequested extends PrescriptionEvent {
  final String? search;
  final String? from;
  final String? to;
  final String? status;
  final bool scopeAll;

  const PrescriptionLoadRequested({
    this.search,
    this.from,
    this.to,
    this.status,
    this.scopeAll = false,
  });

  @override
  List<Object?> get props => [search, from, to, status, scopeAll];
}

final class PrescriptionSelectRequested extends PrescriptionEvent {
  final int prescriptionId;
  const PrescriptionSelectRequested(this.prescriptionId);

  @override
  List<Object?> get props => [prescriptionId];
}

final class PrescriptionClearSelection extends PrescriptionEvent {
  const PrescriptionClearSelection();
}

final class PrescriptionCreateRequested extends PrescriptionEvent {
  final PrescriptionRequest request;
  const PrescriptionCreateRequested(this.request);

  @override
  List<Object?> get props => [request];
}

final class PrescriptionCancelRequested extends PrescriptionEvent {
  final int prescriptionId;
  const PrescriptionCancelRequested(this.prescriptionId);

  @override
  List<Object?> get props => [prescriptionId];
}

final class PrescriptionUpdateRequested extends PrescriptionEvent {
  final int prescriptionId;
  final PrescriptionRequest request;

  const PrescriptionUpdateRequested(this.prescriptionId, this.request);

  @override
  List<Object?> get props => [prescriptionId, request];
}