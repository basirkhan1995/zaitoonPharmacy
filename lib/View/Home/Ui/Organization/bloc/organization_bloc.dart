import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../Services/api_exception.dart';
import '../../../../../Services/repository.dart';
import '../model/org_model.dart';

part 'organization_event.dart';
part 'organization_state.dart';

class OrganizationBloc extends Bloc<OrganizationEvent, OrganizationState> {
  final Repositories _repo;

  OrganizationBloc(this._repo) : super(const OrganizationInitial()) {
    on<OrganizationLoadRequested>(_onLoad);
    on<OrganizationSelectRequested>(_onSelect);
    on<OrganizationClearSelection>(_onClear);
    on<OrganizationCreateRequested>(_onCreate);
    on<OrganizationUpdateRequested>(_onUpdate);
    on<OrganizationDeleteRequested>(_onDelete);
    on<OrganizationDeleteLogoRequested>(_onDeleteLogo);
  }

  List<Organization> get _currentItems => state is OrganizationWithItems
      ? (state as OrganizationWithItems).items
      : const [];

  Future<void> _onLoad(OrganizationLoadRequested event,
      Emitter<OrganizationState> emit) async {
    emit(const OrganizationLoading());
    try {
      final items = await _repo.getOrganizations();
      emit(OrganizationLoaded(items));
    } on ApiException catch (e) {
      emit(OrganizationFailure(e.message));
    }
  }

  Future<void> _onSelect(OrganizationSelectRequested event,
      Emitter<OrganizationState> emit) async {
    final items = _currentItems;
    emit(const OrganizationLoading());
    try {
      final org = await _repo.getOrganization(event.orgId);
      emit(OrganizationLoaded(items, selected: org));
    } on ApiException catch (e) {
      emit(OrganizationFailure(e.message));
    }
  }

  Future<void> _onClear(OrganizationClearSelection event,
      Emitter<OrganizationState> emit) async {
    emit(OrganizationLoaded(_currentItems));
  }

  Future<void> _onCreate(OrganizationCreateRequested event,
      Emitter<OrganizationState> emit) async {
    emit(OrganizationSaving(_currentItems));
    try {
      await _repo.createOrganization(event.request);
      final items = await _repo.getOrganizations();
      emit(OrganizationLoaded(items));
      emit(OrganizationActionSuccess(items, 'Organization created'));
    } on ApiException catch (e) {
      emit(OrganizationFailure(e.message));
    }
  }

  Future<void> _onUpdate(OrganizationUpdateRequested event,
      Emitter<OrganizationState> emit) async {
    emit(OrganizationSaving(_currentItems));
    try {
      await _repo.updateOrganization(event.orgId, event.request);
      final items = await _repo.getOrganizations();
      emit(OrganizationLoaded(items));
      emit(OrganizationActionSuccess(items, 'Organization updated'));
    } on ApiException catch (e) {
      emit(OrganizationFailure(e.message));
    }
  }

  Future<void> _onDelete(OrganizationDeleteRequested event,
      Emitter<OrganizationState> emit) async {
    emit(OrganizationSaving(_currentItems));
    try {
      await _repo.deleteOrganization(event.orgId);
      final items = await _repo.getOrganizations();
      emit(OrganizationLoaded(items));
      emit(OrganizationActionSuccess(items, 'Organization deleted'));
    } on ApiException catch (e) {
      emit(OrganizationFailure(e.message));
    }
  }

  Future<void> _onDeleteLogo(OrganizationDeleteLogoRequested event,
      Emitter<OrganizationState> emit) async {
    emit(OrganizationSaving(_currentItems));
    try {
      await _repo.deleteOrganizationLogo(event.orgId);
      final items = await _repo.getOrganizations();
      emit(OrganizationLoaded(items));
      emit(OrganizationActionSuccess(items, 'Logo removed'));
    } on ApiException catch (e) {
      emit(OrganizationFailure(e.message));
    }
  }
}