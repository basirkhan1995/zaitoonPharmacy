import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../Services/api_exception.dart';
import '../../../Services/credential_store.dart';
import '../../../Services/repository.dart';
import '../auth_model.dart';
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Repositories _repo;

  AuthBloc(this._repo) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  // -----------------------------------------------------------------
  // Auto-login check on app start
  // -----------------------------------------------------------------
  Future<void> _onCheck(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    if (!_repo.isLoggedIn) {
      emit(const AuthUnauthenticated());
      return;
    }

    try {
      final user = await _repo.me();
      emit(AuthAuthenticated(user));
    } on ApiException catch (e) {
      if (e.code == 'TOKEN_EXPIRED') {
        emit(AuthUnauthenticated(message: 'Session expired — please log in again'));
      } else {
        emit(const AuthUnauthenticated());
      }
    }
  }

  // -----------------------------------------------------------------
  // Login
  // -----------------------------------------------------------------
  Future<void> _onLogin(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final auth = await _repo.login(
        username:   event.username,
        password:   event.password,
        rememberMe: event.rememberMe,
      );

      // Persist credentials for next login
      await CredentialStore.save(
        username: event.username,
        password: event.password,
        remember: event.rememberMe,
      );

      emit(AuthAuthenticated(auth.user));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    }
  }

  // -----------------------------------------------------------------
  // Register
  // -----------------------------------------------------------------
  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final auth = await _repo.register(event.request);
      emit(AuthAuthenticated(auth.user));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    }
  }

  // -----------------------------------------------------------------
  // Logout
  // -----------------------------------------------------------------
  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repo.logout();
    emit(const AuthUnauthenticated());
  }
}