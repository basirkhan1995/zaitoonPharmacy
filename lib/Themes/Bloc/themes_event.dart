part of 'themes_bloc.dart';

@immutable
sealed class ThemeEvent {}

class LoadThemeEvent extends ThemeEvent {}

class ChangeThemeEvent extends ThemeEvent {
  final String mode;

  ChangeThemeEvent(this.mode);
}
