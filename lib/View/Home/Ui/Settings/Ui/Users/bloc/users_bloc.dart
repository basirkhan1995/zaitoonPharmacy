import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/users_model.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final Repositories _repo;

  UsersBloc(this._repo) : super(const UsersInitial()) {
    on<UsersLoadRequested>(_onLoad);
    on<UsersSelectRequested>(_onSelect);
    on<UsersClearSelection>(_onClear);
    on<UsersCreateRequested>(_onCreate);
    on<UsersUpdateRequested>(_onUpdate);
    on<UsersDeleteRequested>(_onDelete);
  }

  List<UserAccount> get _currentItems =>
      state is UsersWithItems ? (state as UsersWithItems).items : const [];

  Future<void> _onLoad(
      UsersLoadRequested event, Emitter<UsersState> emit) async {
    emit(const UsersLoading());
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final items = await _repo.getUsers();
      emit(UsersLoaded(items));
    } on ApiException catch (e) {
      emit(UsersFailure(e.message));
    }
  }

  Future<void> _onSelect(
      UsersSelectRequested event, Emitter<UsersState> emit) async {
    final items = _currentItems;
    emit(const UsersLoading());
    try {
      final user = await _repo.getUser(event.userId);
      emit(UsersLoaded(items, selected: user));
    } on ApiException catch (e) {
      emit(UsersFailure(e.message));
    }
  }

  Future<void> _onClear(
      UsersClearSelection event, Emitter<UsersState> emit) async {
    emit(UsersLoaded(_currentItems));
  }

  Future<void> _onCreate(
      UsersCreateRequested event, Emitter<UsersState> emit) async {
    emit(UsersSaving(_currentItems));
    try {
      await _repo.createUser(event.request);
      final items = await _repo.getUsers();
      emit(UsersActionSuccess(items, 'User created'));
    } on ApiException catch (e) {
      emit(UsersFailure(e.message));
    }
  }

  Future<void> _onUpdate(
      UsersUpdateRequested event, Emitter<UsersState> emit) async {
    emit(UsersSaving(_currentItems));
    try {
      await _repo.updateUser(event.userId, event.request);
      final items = await _repo.getUsers();
      emit(UsersActionSuccess(items, 'User updated'));
    } on ApiException catch (e) {
      emit(UsersFailure(e.message));
    }
  }

  Future<void> _onDelete(
      UsersDeleteRequested event, Emitter<UsersState> emit) async {
    emit(UsersSaving(_currentItems));
    try {
      await _repo.deleteUser(event.userId);
      final items = await _repo.getUsers();
      emit(UsersActionSuccess(items, 'User deleted'));
    } on ApiException catch (e) {
      emit(UsersFailure(e.message));
    }
  }
}