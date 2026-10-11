import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../Services/api_exception.dart';
import '../../../../../../Services/repository.dart';
import '../model/security_model.dart';


part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final Repositories _repo;

  ForgotPasswordBloc(this._repo) : super(const ForgotPasswordInitial()) {
    on<ForgotPasswordStartRequested>(_onStart);
    on<ForgotPasswordVerifyRequested>(_onVerify);
    on<ForgotPasswordReset>(_onReset);
  }

  // =================================================================
  // Step 1 — username → questions
  // =================================================================
  Future<void> _onStart(
      ForgotPasswordStartRequested event,
      Emitter<ForgotPasswordState> emit,
      ) async {
    emit(const ForgotPasswordLoading());
    try {
      final data = await _repo.startPasswordReset(event.username);
      final d = Map<String, dynamic>.from(data['data'] as Map);

      final questions = (d['questions'] as List)
          .map((e) =>
          SecurityQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      emit(ForgotPasswordQuestionsLoaded(
        userId:    (d['userId'] as num).toInt(),
        questions: questions,
      ));
    } on ApiException catch (e) {
      emit(ForgotPasswordFailure(e.message));
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString()));
    }
  }

  // =================================================================
  // Step 2 — answers + new password
  // =================================================================
  Future<void> _onVerify(
      ForgotPasswordVerifyRequested event,
      Emitter<ForgotPasswordState> emit,
      ) async {
    emit(const ForgotPasswordLoading());
    try {
      await _repo.verifyPasswordReset(
        userId:      event.userId,
        answer1:     event.answer1,
        answer2:     event.answer2,
        newPassword: event.newPassword,
      );

      emit(const ForgotPasswordSuccess(
        'Password updated. You can now log in.',
      ));
    } on ApiException catch (e) {
      emit(ForgotPasswordFailure(e.message));
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString()));
    }
  }

  // =================================================================
  // Reset the flow back to step 1
  // =================================================================
  Future<void> _onReset(
      ForgotPasswordReset event,
      Emitter<ForgotPasswordState> emit,
      ) async {
    emit(const ForgotPasswordInitial());
  }
}