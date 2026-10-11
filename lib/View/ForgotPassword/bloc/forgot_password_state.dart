part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

/// Nothing has happened yet.
final class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

/// A request is in flight.
final class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

/// Step 1 succeeded — we have the two questions to show.
final class ForgotPasswordQuestionsLoaded extends ForgotPasswordState {
  final int userId;
  final List<SecurityQuestion> questions;

  const ForgotPasswordQuestionsLoaded({
    required this.userId,
    required this.questions,
  });

  @override
  List<Object?> get props => [userId, questions];
}

/// Password was reset successfully — one-shot signal to close the screen.
final class ForgotPasswordSuccess extends ForgotPasswordState {
  final String message;
  const ForgotPasswordSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Something went wrong.
final class ForgotPasswordFailure extends ForgotPasswordState {
  final String message;
  const ForgotPasswordFailure(this.message);

  @override
  List<Object?> get props => [message];
}