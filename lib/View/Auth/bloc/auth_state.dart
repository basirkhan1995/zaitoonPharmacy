part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Nothing has happened yet — before any event.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Request in flight — show a spinner.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Logged in.
final class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Not logged in — send to login screen.
final class AuthUnauthenticated extends AuthState {
  final String? message;

  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

/// Action failed — show a snackbar but stay on the current screen.
final class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}