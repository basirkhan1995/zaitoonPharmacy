part of 'organization_bloc.dart';

sealed class OrganizationEvent extends Equatable {
  const OrganizationEvent();

  @override
  List<Object?> get props => [];
}

final class OrganizationLoadRequested extends OrganizationEvent {
  const OrganizationLoadRequested();
}

final class OrganizationSelectRequested extends OrganizationEvent {
  final int orgId;
  const OrganizationSelectRequested(this.orgId);

  @override
  List<Object?> get props => [orgId];
}

final class OrganizationClearSelection extends OrganizationEvent {
  const OrganizationClearSelection();
}

final class OrganizationCreateRequested extends OrganizationEvent {
  final OrganizationRequest request;
  const OrganizationCreateRequested(this.request);

  @override
  List<Object?> get props => [request];
}

final class OrganizationUpdateRequested extends OrganizationEvent {
  final int orgId;
  final OrganizationRequest request;
  const OrganizationUpdateRequested(this.orgId, this.request);

  @override
  List<Object?> get props => [orgId, request];
}

final class OrganizationDeleteRequested extends OrganizationEvent {
  final int orgId;
  const OrganizationDeleteRequested(this.orgId);

  @override
  List<Object?> get props => [orgId];
}

final class OrganizationDeleteLogoRequested extends OrganizationEvent {
  final int orgId;
  const OrganizationDeleteLogoRequested(this.orgId);

  @override
  List<Object?> get props => [orgId];
}