import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../Services/api_exception.dart';
import '../../../../../Services/repository.dart';
import '../model/prescription_model.dart';

part 'prescription_event.dart';
part 'prescription_state.dart';

class PrescriptionBloc extends Bloc<PrescriptionEvent, PrescriptionState> {
  final Repositories _repo;

  PrescriptionBloc(this._repo) : super(const PrescriptionInitial()) {
    on<PrescriptionLoadRequested>(_onLoad);
    on<PrescriptionSelectRequested>(_onSelect);
    on<PrescriptionClearSelection>(_onClear);
    on<PrescriptionCreateRequested>(_onCreate);
    on<PrescriptionCancelRequested>(_onCancel);
    on<PrescriptionUpdateRequested>(_onUpdate);
  }

  List<Prescription> get _currentItems =>
      state is PrescriptionWithItems
          ? (state as PrescriptionWithItems).items
          : const [];

  Future<void> _onUpdate(PrescriptionUpdateRequested event,
      Emitter<PrescriptionState> emit) async {
    emit(PrescriptionSaving(_currentItems));
    try {
      await _repo.updatePrescription(event.prescriptionId, event.request);
      final items = await _repo.getPrescriptions();
      emit(PrescriptionLoaded(items));
      emit(PrescriptionActionSuccess(items, 'Prescription updated'));
    } on ApiException catch (e) {
      emit(PrescriptionFailure(e.message));
    }
  }
  Future<void> _onLoad(
      PrescriptionLoadRequested event,
      Emitter<PrescriptionState> emit,
      ) async {
    emit(const PrescriptionLoading());

    try {
      await Future.delayed(Duration(milliseconds: 500));
      final items = await _repo.getPrescriptions(
        search: event.search,
        from: event.from,
        to: event.to,
        status: event.status,
        scopeAll: event.scopeAll,
      );

      emit(PrescriptionLoaded(items));
    } on ApiException catch (e) {
      emit(PrescriptionFailure(e.message));
    }
  }

  Future<void> _onSelect(PrescriptionSelectRequested event,
      Emitter<PrescriptionState> emit) async {
    final items = _currentItems;
    emit(const PrescriptionLoading());
    try {
      final p = await _repo.getPrescription(event.prescriptionId);
      emit(PrescriptionLoaded(items, selected: p));
    } on ApiException catch (e) {
      emit(PrescriptionFailure(e.message));
    }
  }

  Future<void> _onClear(PrescriptionClearSelection event,
      Emitter<PrescriptionState> emit) async {
    emit(PrescriptionLoaded(_currentItems));
  }

  Future<void> _onCreate(PrescriptionCreateRequested event,
      Emitter<PrescriptionState> emit) async {
    emit(PrescriptionSaving(_currentItems));
    try {
      await _repo.createPrescription(event.request);
      final items = await _repo.getPrescriptions();
      emit(PrescriptionLoaded(items));
      emit(PrescriptionActionSuccess(items, 'Prescription created'));
    } on ApiException catch (e) {
      emit(PrescriptionFailure(e.message));
    }
  }

  Future<void> _onCancel(PrescriptionCancelRequested event,
      Emitter<PrescriptionState> emit) async {
    emit(PrescriptionSaving(_currentItems));
    try {
      await _repo.cancelPrescription(event.prescriptionId);
      final items = await _repo.getPrescriptions();
      emit(PrescriptionLoaded(items));
      emit(PrescriptionActionSuccess(items, 'Prescription cancelled'));
    } on ApiException catch (e) {
      emit(PrescriptionFailure(e.message));
    }
  }
}