part of 'users_bloc.dart';

sealed class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

final class UsersLoadRequested extends UsersEvent {
  const UsersLoadRequested();
}

final class UsersSelectRequested extends UsersEvent {
  final int userId;
  const UsersSelectRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

final class UsersClearSelection extends UsersEvent {
  const UsersClearSelection();
}

final class UsersCreateRequested extends UsersEvent {
  final UserAccountRequest request;
  const UsersCreateRequested(this.request);

  @override
  List<Object?> get props => [request];
}

final class UsersUpdateRequested extends UsersEvent {
  final int userId;
  final UserAccountRequest request;
  const UsersUpdateRequested(this.userId, this.request);

  @override
  List<Object?> get props => [userId, request];
}

final class UsersDeleteRequested extends UsersEvent {
  final int userId;
  const UsersDeleteRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}