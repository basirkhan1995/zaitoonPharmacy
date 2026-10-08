part of 'organization_bloc.dart';

sealed class OrganizationState extends Equatable {
  const OrganizationState();

  @override
  List<Object?> get props => [];
}

final class OrganizationInitial extends OrganizationState {
  const OrganizationInitial();
}

final class OrganizationLoading extends OrganizationState {
  const OrganizationLoading();
}

abstract class OrganizationWithItems extends OrganizationState {
  final List<Organization> items;
  const OrganizationWithItems(this.items);

  @override
  List<Object?> get props => [items];
}

final class OrganizationLoaded extends OrganizationWithItems {
  final Organization? selected;
  const OrganizationLoaded(super.items, {this.selected});

  @override
  List<Object?> get props => [items, selected];
}

final class OrganizationSaving extends OrganizationWithItems {
  const OrganizationSaving(super.items);
}

final class OrganizationActionSuccess extends OrganizationWithItems {
  final String message;
  const OrganizationActionSuccess(super.items, this.message);

  @override
  List<Object?> get props => [items, message];
}

final class OrganizationFailure extends OrganizationState {
  final String message;
  const OrganizationFailure(this.message);

  @override
  List<Object?> get props => [message];
}