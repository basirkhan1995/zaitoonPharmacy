// bloc/security_questions_state.dart
part of 'security_questions_bloc.dart';

sealed class SecurityQuestionsState extends Equatable {
  const SecurityQuestionsState();

  @override
  List<Object?> get props => [];
}

final class SecurityQuestionsInitial extends SecurityQuestionsState {
  const SecurityQuestionsInitial();
}

/// Catalogue is being fetched.
final class SecurityQuestionsLoading extends SecurityQuestionsState {
  const SecurityQuestionsLoading();
}

/// Catalogue is available.
final class SecurityQuestionsLoaded extends SecurityQuestionsState {
  final List<SecurityQuestion> questions;
  const SecurityQuestionsLoaded(this.questions);

  @override
  List<Object?> get props => [questions];
}

/// Load failed — we keep the message so the UI can show it and offer a retry.
final class SecurityQuestionsFailure extends SecurityQuestionsState {
  final String message;
  const SecurityQuestionsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Save is in flight.
final class SecurityQuestionsSaving extends SecurityQuestionsState {
  final List<SecurityQuestion> questions;
  const SecurityQuestionsSaving(this.questions);

  @override
  List<Object?> get props => [questions];
}

/// Save succeeded — one-shot signal to pop / navigate.
final class SecurityQuestionsSaved extends SecurityQuestionsState {
  final List<SecurityQuestion> questions;
  const SecurityQuestionsSaved(this.questions);

  @override
  List<Object?> get props => [questions];
}

/// Save failed.
final class SecurityQuestionsSaveFailure extends SecurityQuestionsState {
  final List<SecurityQuestion> questions;
  final String message;
  const SecurityQuestionsSaveFailure(this.questions, this.message);

  @override
  List<Object?> get props => [questions, message];
}