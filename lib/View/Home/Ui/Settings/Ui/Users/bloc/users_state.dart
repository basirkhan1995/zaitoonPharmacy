part of 'users_bloc.dart';

sealed class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

final class UsersInitial extends UsersState {
  const UsersInitial();
}

final class UsersLoading extends UsersState {
  const UsersLoading();
}

abstract class UsersWithItems extends UsersState {
  final List<UserAccount> items;
  const UsersWithItems(this.items);

  @override
  List<Object?> get props => [items];
}

final class UsersLoaded extends UsersWithItems {
  final UserAccount? selected;

  const UsersLoaded(super.items, {this.selected});

  @override
  List<Object?> get props => [items, selected];
}

final class UsersSaving extends UsersWithItems {
  const UsersSaving(super.items);
}

final class UsersActionSuccess extends UsersWithItems {
  final String message;

  const UsersActionSuccess(super.items, this.message);

  @override
  List<Object?> get props => [items, message];
}

final class UsersFailure extends UsersState {
  final String message;
  const UsersFailure(this.message);

  @override
  List<Object?> get props => [message];
}