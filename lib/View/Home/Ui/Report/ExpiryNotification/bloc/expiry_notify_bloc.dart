import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/expiry_notify_model.dart';

part 'expiry_notify_event.dart';
part 'expiry_notify_state.dart';

class ExpiryNotifyBloc extends Bloc<ExpiryNotifyEvent, ExpiryNotifyState> {
  final Repositories _repo;

  ExpiryNotifyBloc(this._repo) : super(const ExpiryNotifyInitial()) {
    on<ExpiryNotifyLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
      ExpiryNotifyLoadRequested event,
      Emitter<ExpiryNotifyState> emit,
      ) async {
    emit(const ExpiryNotifyLoading());
    try {
      final summary = await _repo.getExpirySummary();
      emit(ExpiryNotifyLoaded(summary));
    } on ApiException catch (e) {
      emit(ExpiryNotifyFailure(e.message));
    } catch (e) {
      emit(ExpiryNotifyFailure(e.toString()));
    }
  }
}