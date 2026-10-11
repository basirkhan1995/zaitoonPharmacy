import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../Services/api_exception.dart';
import '../../../../../../Services/repository.dart';
import '../model/security_model.dart';

part 'security_questions_event.dart';
part 'security_questions_state.dart';

class SecurityQuestionsBloc
    extends Bloc<SecurityQuestionsEvent, SecurityQuestionsState> {
  final Repositories _repo;

  SecurityQuestionsBloc(this._repo)
      : super(const SecurityQuestionsInitial()) {
    on<SecurityQuestionsLoadRequested>(_onLoad);
    on<SecurityQuestionsSaveRequested>(_onSave);
  }

  Future<void> _onLoad(
      SecurityQuestionsLoadRequested event,
      Emitter<SecurityQuestionsState> emit,
      ) async {
    emit(const SecurityQuestionsLoading());
    try {
      final list = await _repo.getSecurityQuestions();
      emit(SecurityQuestionsLoaded(list));
    } on ApiException catch (e) {
      emit(SecurityQuestionsFailure(e.message));
    } catch (e) {
      emit(SecurityQuestionsFailure(e.toString()));
    }
  }

  Future<void> _onSave(
      SecurityQuestionsSaveRequested event,
      Emitter<SecurityQuestionsState> emit,
      ) async {
    // Preserve the catalogue across the save so the UI can keep rendering it.
    final current =
    state is SecurityQuestionsLoaded ? (state as SecurityQuestionsLoaded).questions
        : state is SecurityQuestionsSaving ? (state as SecurityQuestionsSaving).questions
        : state is SecurityQuestionsSaved ? (state as SecurityQuestionsSaved).questions
        : state is SecurityQuestionsSaveFailure ? (state as SecurityQuestionsSaveFailure).questions
        : <SecurityQuestion>[];

    emit(SecurityQuestionsSaving(current));
    try {
      await _repo.saveSecurityQuestions(
        q1Id: event.q1Id,
        a1:   event.a1,
        q2Id: event.q2Id,
        a2:   event.a2,
      );
      emit(SecurityQuestionsSaved(current));
    } on ApiException catch (e) {
      emit(SecurityQuestionsSaveFailure(current, e.message));
    } catch (e) {
      emit(SecurityQuestionsSaveFailure(current, e.toString()));
    }
  }
}