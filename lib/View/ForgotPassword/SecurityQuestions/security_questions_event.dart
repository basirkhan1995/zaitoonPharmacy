// bloc/security_questions_event.dart
part of 'security_questions_bloc.dart';

sealed class SecurityQuestionsEvent extends Equatable {
  const SecurityQuestionsEvent();

  @override
  List<Object?> get props => [];
}

/// Load the catalogue of questions.
final class SecurityQuestionsLoadRequested extends SecurityQuestionsEvent {
  const SecurityQuestionsLoadRequested();
}

/// Save the user's two picks + answers.
final class SecurityQuestionsSaveRequested extends SecurityQuestionsEvent {
  final int q1Id;
  final String a1;
  final int q2Id;
  final String a2;

  const SecurityQuestionsSaveRequested({
    required this.q1Id,
    required this.a1,
    required this.q2Id,
    required this.a2,
  });

  @override
  List<Object?> get props => [q1Id, a1, q2Id, a2];
}