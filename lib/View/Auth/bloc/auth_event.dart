part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Ask the bloc to check the saved token on app startup.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User submitted the login form.
final class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  final bool rememberMe;

  const AuthLoginRequested({
    required this.username,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [username, password, rememberMe];
}

/// User submitted the register form.
final class AuthRegisterRequested extends AuthEvent {
  final RegisterRequest request;

  const AuthRegisterRequested(this.request);

  @override
  List<Object?> get props => [request];
}

/// User tapped Logout.
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}