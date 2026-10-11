part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

/// User submitted the username on step 1.
final class ForgotPasswordStartRequested extends ForgotPasswordEvent {
  final String username;
  const ForgotPasswordStartRequested(this.username);

  @override
  List<Object?> get props => [username];
}

/// User submitted answers + new password on step 2.
final class ForgotPasswordVerifyRequested extends ForgotPasswordEvent {
  final int userId;
  final String answer1;
  final String answer2;
  final String newPassword;
  const ForgotPasswordVerifyRequested({
    required this.userId,
    required this.answer1,
    required this.answer2,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [userId, answer1, answer2, newPassword];
}

/// Reset the flow back to step 1.
final class ForgotPasswordReset extends ForgotPasswordEvent {
  const ForgotPasswordReset();
}