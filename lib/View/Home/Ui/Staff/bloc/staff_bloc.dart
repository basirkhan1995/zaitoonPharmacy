import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/staff_model.dart';

part 'staff_event.dart';
part 'staff_state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final Repositories _repo;

  StaffBloc(this._repo) : super(const StaffInitial()) {
    on<StaffLoadRequested>(_onLoad);
    on<StaffSelectRequested>(_onSelect);
    on<StaffClearSelection>(_onClear);
    on<StaffCreateRequested>(_onCreate);
    on<StaffUpdateRequested>(_onUpdate);
    on<StaffDeleteRequested>(_onDelete);
  }

  List<Staff> get _currentItems =>
      state is StaffWithItems ? (state as StaffWithItems).items : const [];

  Future<void> _onLoad(
      StaffLoadRequested event, Emitter<StaffState> emit) async {
    emit(const StaffLoading());
    try {
      final items = await _repo.getStaffList();
      emit(StaffLoaded(items));
    } on ApiException catch (e) {
      emit(StaffFailure(e.message));
    }
  }

  Future<void> _onSelect(
      StaffSelectRequested event, Emitter<StaffState> emit) async {
    final items = _currentItems;
    emit(const StaffLoading());
    try {
      final staff = await _repo.getStaff(event.staffId);
      emit(StaffLoaded(items, selected: staff));
    } on ApiException catch (e) {
      emit(StaffFailure(e.message));
    }
  }

  Future<void> _onClear(
      StaffClearSelection event, Emitter<StaffState> emit) async {
    emit(StaffLoaded(_currentItems));
  }

  Future<void> _onCreate(
      StaffCreateRequested event, Emitter<StaffState> emit) async {
    emit(StaffSaving(_currentItems));
    try {
      await _repo.createStaff(event.request);
      final items = await _repo.getStaffList();
      emit(StaffActionSuccess(items, 'Staff created'));
    } on ApiException catch (e) {
      emit(StaffFailure(e.message));
    }
  }

  Future<void> _onUpdate(
      StaffUpdateRequested event, Emitter<StaffState> emit) async {
    emit(StaffSaving(_currentItems));
    try {
      await _repo.updateStaff(event.staffId, event.request);
      final items = await _repo.getStaffList();
      emit(StaffActionSuccess(items, 'Staff updated'));
    } on ApiException catch (e) {
      emit(StaffFailure(e.message));
    }
  }

  Future<void> _onDelete(
      StaffDeleteRequested event, Emitter<StaffState> emit) async {
    emit(StaffSaving(_currentItems));
    try {
      await _repo.deleteStaff(event.staffId);
      final items = await _repo.getStaffList();
      emit(StaffActionSuccess(items, 'Staff deleted'));
    } on ApiException catch (e) {
      emit(StaffFailure(e.message));
    }
  }
}