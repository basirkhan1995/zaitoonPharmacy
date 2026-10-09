import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../Services/api_exception.dart';
import '../../../../../../Services/repository.dart';
import '../model/medicine_model.dart';

part 'medicine_event.dart';
part 'medicine_state.dart';

class MedicineBloc extends Bloc<MedicineEvent, MedicineState> {
  final Repositories _repo;

  MedicineBloc(this._repo) : super(const MedicineInitial()) {
    on<MedicineLoadRequested>(_onLoad);
    on<MedicineSelectRequested>(_onSelect);
    on<MedicineClearSelection>(_onClear);
    on<MedicineCreateRequested>(_onCreate);
    on<MedicineUpdateRequested>(_onUpdate);
    on<MedicineDeleteRequested>(_onDelete);
  }

  // -----------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------
  List<Medicine> get _currentItems =>
      state is MedicineLoaded ? (state as MedicineLoaded).items : const [];


  // -----------------------------------------------------------------
  // Load list
  // -----------------------------------------------------------------
  Future<void> _onLoad(MedicineLoadRequested event, Emitter<MedicineState> emit) async {
    emit(const MedicineLoading());
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final items = await _repo.getMedicines(search: event.search);
      emit(MedicineLoaded(items));
    } on ApiException catch (e) {
      emit(MedicineFailure(e.message));
    }
  }

  // -----------------------------------------------------------------
  // Select one
  // -----------------------------------------------------------------
  Future<void> _onSelect(
      MedicineSelectRequested event, Emitter<MedicineState> emit) async {
    // Keep the list while loading the detail
    final items = _currentItems;
    emit(MedicineLoading());
    try {
      final medicine = await _repo.getMedicine(event.medId);
      emit(MedicineLoaded(items, selected: medicine));
    } on ApiException catch (e) {
      emit(MedicineFailure(e.message));
    }
  }

  Future<void> _onClear(
      MedicineClearSelection event, Emitter<MedicineState> emit) async {
    emit(MedicineLoaded(_currentItems));
  }

  // -----------------------------------------------------------------
  // Create
  // -----------------------------------------------------------------
  Future<void> _onCreate(MedicineCreateRequested event, Emitter<MedicineState> emit) async {
    emit(MedicineSaving(_currentItems));
    try {
      await _repo.createMedicine(event.request);
      final items = await _repo.getMedicines();
      emit(MedicineLoaded(items));
      emit(MedicineActionSuccess(items, 'Medicine created'));   // ← items added
    } on ApiException catch (e) {
      emit(MedicineFailure(e.message));
    }
  }

  Future<void> _onUpdate(MedicineUpdateRequested event, Emitter<MedicineState> emit) async {
    emit(MedicineSaving(_currentItems));
    try {
      await _repo.updateMedicine(event.medId, event.request);
      final items = await _repo.getMedicines();
      emit(MedicineLoaded(items));
      emit(MedicineActionSuccess(items, 'Medicine updated'));   // ← items added
    } on ApiException catch (e) {
      emit(MedicineFailure(e.message));
    }
  }

  Future<void> _onDelete(MedicineDeleteRequested event, Emitter<MedicineState> emit) async {
    emit(MedicineSaving(_currentItems));
    try {
      await _repo.deleteMedicine(event.medId);
      final items = await _repo.getMedicines();
      emit(MedicineLoaded(items));
      emit(MedicineActionSuccess(items, 'Medicine deleted'));   // ← items added
    } on ApiException catch (e) {
      emit(MedicineFailure(e.message));
    }
  }
}